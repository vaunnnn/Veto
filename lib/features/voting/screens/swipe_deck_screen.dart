import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:veto/core/themes/app_colors.dart';
import 'package:veto/features/voting/widgets/movie_card_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veto/core/data/repositories/firebase_room_repository.dart';
import 'package:veto/features/rooms/screens/landing_screen.dart';

class SwipeDeckScreen extends StatefulWidget {
  final Set<String> selectedGenres;
  final String roomCode;
  final String playerDeviceId;

  const SwipeDeckScreen({
    super.key,
    required this.selectedGenres,
    required this.roomCode,
    required this.playerDeviceId,
  });

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  // --- VARIABLES ---
  final CardSwiperController controller = CardSwiperController();
  StreamSubscription<DocumentSnapshot>? _matchSubscription;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  String? _lastMatchedMovieId;
  bool _isHost = false;
  bool _navigatedAway = false;
  List<Map<String, dynamic>> movies = [];
  bool isLoading = true;
  int currentPage = 1;
  bool _isMatchOverlayOpen = false;
  int _lastKeepSwipingTrigger = 0;
  bool _isLeaving = false;

  final Map<String, String> tmdbGenreIds = {
    'Action': '28',
    'Adventure': '12',
    'Animation': '16',
    'Biography': '36',
    'Comedy': '35',
    'Documentary': '99',
    'Drama': '18',
    'Family': '10751',
    'Fantasy': '14',
    'History': '36',
    'Horror': '27',
    'Musical': '10402',
    'Mystery': '9648',
    'Romance': '10749',
    'Sci-Fi': '878',
    'Sport': '99',
    'Thriller': '53',
    'Western': '37',
  };

  // --- INIT & DISPOSE ---
  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _listenForMatches();
    _listenToRoom();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _roomSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  // --- FIREBASE & API LOGIC ---
  void _listenForMatches() {
    _matchSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          if (!snapshot.exists) {
            // Room deleted, navigate to landing screen
            if (!_navigatedAway) {
              _navigatedAway = true;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            }
            return;
          }

          final data = snapshot.data() as Map<String, dynamic>;

          // --- NEW: THE "KEEP SWIPING" SYNC LOGIC ---
          // If the latestMatch field is gone, but our overlay is open, someone cleared it!
          if (!data.containsKey('latestMatch') && _isMatchOverlayOpen) {
            if (mounted) {
              Navigator.pop(context); // Drop the overlay for everyone!
            }

            _isMatchOverlayOpen = false;
            _lastMatchedMovieId = null; // Reset so the next match works

            // Check if we should show the notification
            final currentTrigger = data['keepSwipingTrigger'] ?? 0;
            if (currentTrigger > _lastKeepSwipingTrigger) {
              _lastKeepSwipingTrigger = currentTrigger;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Someone voted to keep swiping! Back to the deck 🍿',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
          // ------------------------------------------

          if (data.containsKey('latestMatch')) {
            final match = data['latestMatch'];
            final String matchId = match['id'].toString();

            if (_lastMatchedMovieId != matchId && !_isMatchOverlayOpen) {
              _lastMatchedMovieId = matchId;
              _isMatchOverlayOpen = true; // Mark the overlay as open!
              _showMatchOverlay(match);
            }
          }
        });
  }

  void _listenToRoom() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            // Room deleted, navigate to landing screen
            if (!_navigatedAway && mounted) {
              _navigatedAway = true;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            }
            return;
          }
          final data = snapshot.data() as Map<String, dynamic>;
          final String? hostId = data['hostId']?.toString();
          final bool isHost = hostId == widget.playerDeviceId;
          if (_isHost != isHost && mounted) {
            setState(() {
              _isHost = isHost;
            });
          }
        });
  }

  Future<void> _fetchMovies() async {
    final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';

    Set<String> combinedGenres = {};
    // NEW: Variables to hold our host's filters
    Map<String, dynamic> filters = {};

    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .get();

      if (roomDoc.exists) {
        final data = roomDoc.data()!;
        final Map<String, dynamic> profiles = data['playerProfiles'] ?? {};

        // NEW: Grab the filter settings from the database
        filters = data['filterSettings'] ?? {};

        profiles.forEach((deviceId, profile) {
          final List dynamicGenres = profile['genres'] ?? [];
          combinedGenres.addAll(dynamicGenres.map((g) => g.toString()));
        });
      }
    } catch (e) {
      debugPrint("Error fetching room data");
    }

    if (combinedGenres.isEmpty) {
      combinedGenres.addAll(widget.selectedGenres);
    }

    String mappedIds = combinedGenres
        .map((g) => tmdbGenreIds[g])
        .where((id) => id != null)
        .join('|');

    // --- NEW: APPLYING THE HOST FILTERS TO THE URL ---
    int minYear = filters['minYear'] ?? 1970;
    int maxYear = filters['maxYear'] ?? DateTime.now().year;
    double minScore = (filters['minScore'] ?? 6.0).toDouble();
    String runtime = filters['maxRuntime'] ?? 'Any Length';
    bool familyFriendly = filters['familyFriendly'] ?? false;

    // THE FIX: safely extract the list of languages
    List<dynamic> rawLanguages = filters['languages'] ?? [];
    List<String> selectedLanguages = rawLanguages
        .map((e) => e.toString())
        .toList();

    // Build the base URL
    String urlStr =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=$mappedIds&sort_by=popularity.desc&page=$currentPage';

    urlStr += '&vote_count.gte=150&vote_average.gte=$minScore';
    urlStr +=
        '&primary_release_date.gte=$minYear-01-01&primary_release_date.lte=$maxYear-12-31';

    if (runtime != 'Any Length') {
      int minutes = runtime == 'Under 90 Mins'
          ? 90
          : runtime == 'Under 2 Hours'
          ? 120
          : 150;
      urlStr += '&with_runtime.lte=$minutes';
    }

    if (familyFriendly) {
      urlStr += '&certification_country=US&certification.lte=PG-13';
    }

    // 5. Spoken Language (Multi-Select Logic)
    final Map<String, String> tmdbLanguageCodes = {
      'Arabic': 'ar',
      'Chinese': 'zh',
      'English': 'en',
      'French': 'fr',
      'German': 'de',
      'Hindi': 'hi',
      'Italian': 'it',
      'Japanese': 'ja',
      'Korean': 'ko',
      'Portuguese': 'pt',
      'Russian': 'ru',
      'Spanish': 'es',
    };

    if (selectedLanguages.isNotEmpty) {
      // Convert their selected words ('French', 'Korean') into TMDB codes ('fr', 'ko')
      List<String> codes = selectedLanguages
          .where((lang) => tmdbLanguageCodes.containsKey(lang))
          .map((lang) => tmdbLanguageCodes[lang]!)
          .toList();

      if (codes.isNotEmpty) {
        // Joins them with a pipe character for the API (e.g., fr|ko|en)
        urlStr += '&with_original_language=${codes.join('|')}';
      }
    }

    // --- FETCH FROM TMDB ---
    try {
      final url = Uri.parse(urlStr);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            final newMovies = List<Map<String, dynamic>>.from(data['results']);
            // Deterministic shuffle based on room code and page number
            final random = Random(widget.roomCode.hashCode + currentPage);
            newMovies.shuffle(random);
            movies.addAll(newMovies);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching TMDB movies");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _castVote(Map<String, dynamic> movie, bool isLike) async {
    final String movieId = movie['id'].toString();
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode);

    // NEW: We create a specific document just for THIS movie's votes!
    // Path: rooms/{roomCode}/votes/{movieId}
    final movieVoteRef = roomRef.collection('votes').doc(movieId);

    if (!isLike) {
      // ❌ TRUE VETO: We only update the movie's private document. Zero lag.
      await movieVoteRef.set({
        'vetoes': FieldValue.arrayUnion([widget.playerDeviceId]),
      }, SetOptions(merge: true));
      return;
    }

    // 💚 LIKE: We run the transaction on the MOVIE document, NOT the main room!
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Check the main room to see how many players are connected
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) return;
      final int totalPlayers =
          (roomSnapshot.data()!['connectedPlayers'] as List?)?.length ?? 0;

      // 2. Check the movie's specific vote document
      final movieSnapshot = await transaction.get(movieVoteRef);
      List likes = [];
      List vetoes = [];

      if (movieSnapshot.exists) {
        likes = List.from(movieSnapshot.data()!['likes'] ?? []);
        vetoes = List.from(movieSnapshot.data()!['vetoes'] ?? []);
      }

      // If someone already vetoed it, abort!
      if (vetoes.isNotEmpty) return;

      // 3. Add our like
      if (!likes.contains(widget.playerDeviceId)) {
        likes.add(widget.playerDeviceId);
      }

      // Save the like to the movie's private document
      transaction.set(movieVoteRef, {'likes': likes}, SetOptions(merge: true));

      // 🏆 THE 100% CONSENSUS CHECK
      if (likes.length == totalPlayers && totalPlayers > 0) {
        // ONLY if it's a perfect match do we update the main room document
        // This is what instantly triggers the pop-up for everyone!
        transaction.update(roomRef, {
          'latestMatch': movie,
          'matchedMovies': FieldValue.arrayUnion([movie]),
        });
      }
    });
  }

  // --- UI ACTIONS ---
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (_isMatchOverlayOpen) return false;

    bool isLike = direction == CardSwiperDirection.right;
    _castVote(movies[previousIndex], isLike);

    if (currentIndex != null && currentIndex >= movies.length - 3) {
      currentPage++;
      _fetchMovies();
    }

    return true;
  }

  void _onEnd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Voting Finished!"),
        content: const Text("Waiting for other players to finish..."),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("Back to Home"),
          ),
        ],
      ),
    );
  }

  void _showMatchOverlay(Map<String, dynamic> movie) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: false,
      // 1. Give the animation a nice, snappy duration
      transitionDuration: const Duration(milliseconds: 400),
      // 2. THE FIX: The custom float-up animation builder
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Start at the bottom (y = 1.0) and end exactly in the center (y = 0.0)
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        // easeOutQuart gives it a fast initial slide that softly slows down at the end
        const curve = Curves.easeOutQuart;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      pageBuilder: (context, anim1, anim2) {
        // THE FIX: PopScope prevents the Android hardware back button from closing
        // the dialog locally without telling Firebase, which breaks the sync!
        return PopScope(
          canPop: false,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Blurred background
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40.0,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "THE JURY HAS DECIDED...",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                            children: [
                              TextSpan(text: "It's a "),
                              TextSpan(
                                text: "Match!",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Expanded(child: MovieCard(movie: movie)),

                        const SizedBox(height: 30),

                        // --- NEW: KEEP SWIPING BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                // Deleting 'latestMatch' triggers the listener to close the overlay for everyone
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(widget.roomCode)
                                    .update({
                                      'latestMatch': FieldValue.delete(),
                                      'keepSwipingTrigger':
                                          DateTime.now().millisecondsSinceEpoch,
                                    });
                              } catch (e) {
                                debugPrint("Error keeping swiping");
                              }
                            },
                            icon: const Icon(
                              Icons.swipe_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              "KEEP SWIPING",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // --------------------------------

                        // --- EXISTING END SESSION BUTTON ---
                         SizedBox(
                           width: double.infinity,
                           height: 56,
                           child: ElevatedButton.icon(
                             style: ElevatedButton.styleFrom(
                               backgroundColor: _isLeaving
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                   : AppColors.primary,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(30),
                               ),
                             ),
                             onPressed: _isLeaving ? null : _leaveRoom,
                             icon: Icon(
                               Icons.home,
                               color: _isLeaving
                        ? Colors.white.withValues(alpha: 0.7)
                                   : Colors.white,
                               size: 20,
                             ),
                             label: Text(
                               _isLeaving ? "LEAVING..." : "END SESSION & GO HOME",
                               style: TextStyle(
                                 color: _isLeaving
                                     ? Colors.white.withValues(alpha: 0.7)
                                     : Colors.white,
                                 fontSize: 15,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 1.0,
                               ),
                             ),
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _leaveRoom() async {
    if (_isLeaving) return;
    
    setState(() {
      _isLeaving = true;
    });
    
    _matchSubscription?.cancel();
    _roomSubscription?.cancel();

    try {
      final repository = FirebaseRoomRepository();
      
      if (_isHost) {
        await repository.deleteRoom(widget.roomCode);
      } else {
        await repository.leaveRoom(widget.roomCode, widget.playerDeviceId);
      }

      if (mounted) {
        _navigatedAway = true;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LandingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error leaving room: $e");
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to leave room. Please try again.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (_isHost) {
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('End Session?'),
              content: const Text(
                'This will delete the room for all players. Are you sure?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete Room & Leave'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _leaveRoom();
          }
        } else {
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Leave Room?'),
              content: const Text('This will remove you from the room.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Leave Room'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _leaveRoom();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : movies.isEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Image.asset('assets/images/veto-logo.webp', height: 32),
                        ),
                      ),
                      _buildEmptyState(),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Image.asset('assets/images/veto-logo.webp', height: 32),
                      ),
                    ),
                    // 1. Reduced top spacing to lift the card up slightly
                    const SizedBox(height: 8),

                    Expanded(
                      child: CardSwiper(
                      controller: controller,
                      cardsCount: movies.length,
                      onSwipe: _onSwipe,
                      onEnd: _onEnd,
                      // 2. Added bottom padding to shrink the height of the card
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        bottom: 32.0,
                      ),
                      allowedSwipeDirection:
                          const AllowedSwipeDirection.symmetric(
                            horizontal: true,
                          ),
                      numberOfCardsDisplayed: 2,
                      scale: 0.95,
                      backCardOffset: const Offset(0, -15),
                      cardBuilder:
                          (
                            context,
                            index,
                            percentThresholdX,
                            percentThresholdY,
                          ) {
                            return MovieCard(
                              key: ValueKey(movies[index]['id']),
                              movie: movies[index],
                            );
                          },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Reduced bottom padding from 40.0 to 20.0
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircularButton(
                          icon: Icons.close,
                          iconColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          size: 76, // Shaved down from 80
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          onTap: () =>
                              controller.swipe(CardSwiperDirection.left),
                        ),
                        const SizedBox(width: 42),
                        _buildCircularButton(
                          icon: Icons.favorite,
                          iconColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          size: 76, // Shaved down from 80
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          onTap: () =>
                              controller.swipe(CardSwiperDirection.right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required double size,
    required VoidCallback onTap,
    bool hasShadow = true,
    Color? shadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: shadowColor ?? Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    spreadRadius: shadowColor != null ? 2 : 0,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: size * 0.45),
        ),
      ),
    );
  }

  // --- 🎬 EMPTY STATE UI ---
  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.movie_filter_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "THE VAULT IS EMPTY",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Your group's genres combined with the room's filters resulted in zero matches.\n\nTry to loosen the rules!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),

            // Escape Hatch Button
            SizedBox(
              width: double.infinity,
              height: 56,
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: _isLeaving
                        ? AppColors.primary.withValues(alpha: 0.5)
                       : AppColors.primary,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(30),
                   ),
                   elevation: 0,
                 ),
                 onPressed: _isLeaving ? null : _leaveRoom,
                 icon: Icon(
                   _isHost ? Icons.refresh_rounded : Icons.exit_to_app_rounded,
                    color: _isLeaving
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white,
                   size: 20,
                 ),
                 label: Text(
                   _isLeaving
                       ? "LEAVING..."
                       : _isHost ? "END SESSION & RESTART" : "LEAVE ROOM",
                   style: TextStyle(
                     color: _isLeaving
                          ? Colors.white.withValues(alpha: 0.7)
                         : Colors.white,
                     fontSize: 14,
                     fontWeight: FontWeight.w900,
                     letterSpacing: 1.0,
                   ),
                 ),
               ),
            ),
          ],
        ),
      ),
    );
  }
}

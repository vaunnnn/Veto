import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:veto/core/themes/app_colors.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui'; 
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _lastMatchedMovieId;
  List<Map<String, dynamic>> movies = [];
  bool isLoading = true;
  int currentPage = 1; 

  final Map<String, String> tmdbGenreIds = {
    'Action': '28', 'Adventure': '12', 'Animation': '16', 'Biography': '36', 
    'Comedy': '35', 'Documentary': '99', 'Drama': '18', 'Family': '10751', 
    'Fantasy': '14', 'History': '36', 'Horror': '27', 'Musical': '10402', 
    'Mystery': '9648', 'Romance': '10749', 'Sci-Fi': '878', 'Sport': '99', 
    'Thriller': '53', 'Western': '37',
  };

  // --- INIT & DISPOSE ---
  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _listenForMatches(); 
  }

  @override
  void dispose() {
    _matchSubscription?.cancel(); 
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
      if (!snapshot.exists || !mounted) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      
      if (data.containsKey('latestMatch')) {
        final match = data['latestMatch'];
        final String matchId = match['id'].toString();

        if (_lastMatchedMovieId != matchId) {
          _lastMatchedMovieId = matchId;
          _showMatchOverlay(match);
        }
      }
    });
  }

  Future<void> _fetchMovies() async {
    final String apiKey = dotenv.env['TMDB_API_KEY'] ?? ''; 
    
    // --- NEW: THE GROUP GENRE MIXER ---
    Set<String> combinedGenres = {};

    try {
      // 1. Ask Firebase what everyone in the room picked
      final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).get();
      
      if (roomDoc.exists) {
        final data = roomDoc.data()!;
        final Map<String, dynamic> profiles = data['playerProfiles'] ?? {};

        // 2. Dump every single genre into our Set (which automatically removes duplicates!)
        profiles.forEach((deviceId, profile) {
          final List dynamicGenres = profile['genres'] ?? [];
          combinedGenres.addAll(dynamicGenres.map((g) => g.toString()));
        });
      }
    } catch (e) {
      debugPrint("Error fetching room genres: $e");
    }

    // 3. Fallback: If Firebase was too slow or empty, use the local user's genres just to be safe
    if (combinedGenres.isEmpty) {
      combinedGenres.addAll(widget.selectedGenres);
    }

    // 4. Translate the massive group list into TMDB IDs separated by a PIPE (|) for "OR"
    String mappedIds = combinedGenres.map((g) => tmdbGenreIds[g]).where((id) => id != null).join('|');

    // --- FETCH FROM TMDB ---
    try {
      final url = Uri.parse(
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=$mappedIds&sort_by=popularity.desc&page=$currentPage'
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // FIX: Check if the widget is still alive before updating the UI
        if (mounted) {
          setState(() {
            movies.addAll(List<Map<String, dynamic>>.from(data['results']));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching TMDB movies: $e");
      
      // FIX: Check if the widget is still alive before updating the UI
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _castVote(Map<String, dynamic> movie, bool isLike) async {
    final String movieId = movie['id'].toString();
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode);
    
    // NEW: We create a specific document just for THIS movie's votes!
    // Path: rooms/{roomCode}/votes/{movieId}
    final movieVoteRef = roomRef.collection('votes').doc(movieId);

    if (!isLike) {
      // ❌ TRUE VETO: We only update the movie's private document. Zero lag.
      await movieVoteRef.set({
        'vetoes': FieldValue.arrayUnion([widget.playerDeviceId])
      }, SetOptions(merge: true));
      return; 
    }

    // 💚 LIKE: We run the transaction on the MOVIE document, NOT the main room!
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Check the main room to see how many players are connected
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) return;
      final int totalPlayers = (roomSnapshot.data()!['connectedPlayers'] as List?)?.length ?? 0;

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
      transaction.set(movieVoteRef, {
        'likes': likes
      }, SetOptions(merge: true));

      // 🏆 THE 100% CONSENSUS CHECK
      if (likes.length == totalPlayers && totalPlayers > 0) {
        // ONLY if it's a perfect match do we update the main room document
        // This is what instantly triggers the pop-up for everyone!
        transaction.update(roomRef, {
          'latestMatch': movie, 
          'matchedMovies': FieldValue.arrayUnion([movie]) 
        });
      }
    });
  }

  // --- UI ACTIONS ---
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
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
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("Back to Home"),
          ),
        ],
      ),
    );
  }

  void _showMatchOverlay(Map<String, dynamic> movie) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9), 
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                children: [
                  const Text("CINEMA SELECTION", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0),
                      children: [
                        TextSpan(text: "It's a "),
                        TextSpan(text: "Match!", style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // --- THE MAGIC ONE-LINER ---
                  // This entirely replaces the old Container, Gradient, and Column!
                  Expanded(
                    child: _ScrollableMovieCard(movie: movie),
                  ),
                  // ---------------------------
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).delete();
                        } catch (e) {
                          debugPrint("Error deleting room: $e");
                        }
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LandingScreen()), 
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text("End Session & Go Home", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
          onPressed: () {}, 
        ),
        title: const Text(
          "VETO",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.brightness == Brightness.light ? const Color(0xFF1A1A1A) : Colors.white,
              child: Icon(
                Icons.person, 
                size: 20, 
                color: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : movies.isEmpty 
            ? const Center(child: Text("No movies found. Check your API key!"))
            : Column(
                children: [
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: movies.length,
                      onSwipe: _onSwipe,
                      onEnd: _onEnd,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        return _ScrollableMovieCard(movie: movies[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Column(
                    children: [
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        "SCROLL FOR MORE INFO",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircularButton(
                          icon: Icons.close,
                          iconColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          size: 80,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4), 
                          onTap: () => controller.swipe(CardSwiperDirection.left),
                        ),
                        const SizedBox(width: 30),
                        _buildCircularButton(
                          icon: Icons.favorite,
                          iconColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          size: 80,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4), 
                          onTap: () => controller.swipe(CardSwiperDirection.right),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon, required Color iconColor, required Color backgroundColor,
    required double size, required VoidCallback onTap, bool hasShadow = true, Color? shadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: backgroundColor, shape: BoxShape.circle,
          boxShadow: hasShadow ? [
            BoxShadow(
              color: shadowColor ?? Colors.black.withValues(alpha: 0.08), 
              blurRadius: 15, 
              spreadRadius: shadowColor != null ? 2 : 0, 
              offset: const Offset(0, 5)
            )
          ] : [],
        ),
        child: Center(child: Icon(icon, color: iconColor, size: size * 0.45)),
      ),
    );
  }
}

// --- STATEFUL WIDGET FOR SCROLLABLE CARD ---
class _ScrollableMovieCard extends StatefulWidget {
  final Map<String, dynamic> movie;

  const _ScrollableMovieCard({required this.movie});

  @override
  State<_ScrollableMovieCard> createState() => _ScrollableMovieCardState();
}

class _ScrollableMovieCardState extends State<_ScrollableMovieCard> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    double offset = _scrollController.offset;
    double progress = (offset / 150.0).clamp(0.0, 1.0);
    
    if (_scrollProgress != progress) {
      setState(() {
        _scrollProgress = progress;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String posterUrl = widget.movie['poster_path'] != null 
        ? 'https://image.tmdb.org/t/p/w500${widget.movie['poster_path']}' 
        : 'https://via.placeholder.com/800x1200?text=No+Poster';
        
    final Map<int, String> tmdbReverseGenres = {
      28: 'ACTION', 12: 'ADVENTURE', 16: 'ANIMATION', 35: 'COMEDY', 80: 'CRIME', 
      99: 'DOCUMENTARY', 18: 'DRAMA', 10751: 'FAMILY', 14: 'FANTASY', 36: 'HISTORY', 
      27: 'HORROR', 10402: 'MUSICAL', 9648: 'MYSTERY', 10749: 'ROMANCE', 878: 'SCI-FI', 
      53: 'THRILLER', 37: 'WESTERN'
    };
    
    String mainGenre = 'CINEMA';
    if (widget.movie['genre_ids'] != null && (widget.movie['genre_ids'] as List).isNotEmpty) {
      int firstId = widget.movie['genre_ids'][0];
      mainGenre = tmdbReverseGenres[firstId] ?? 'CINEMA';
    }

    final String title = widget.movie['title'] ?? 'Unknown Title';
    final String overview = widget.movie['overview'] ?? 'No plot available.';
    final String releaseDate = widget.movie['release_date'] ?? '';
    final String year = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
    final String rating = (widget.movie['vote_average'] ?? 0.0).toStringAsFixed(1);
    final String language = (widget.movie['original_language'] ?? '').toString().toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(posterUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox.shrink()),
                ),
                
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: _scrollProgress * 12.0, sigmaY: _scrollProgress * 12.0),
                    child: Container(color: Colors.black.withValues(alpha: _scrollProgress * 0.75)),
                  ),
                ),

                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: constraints.maxHeight - 200),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  _buildBadge('$rating / 10', AppColors.primary),
                                  _buildBadge(mainGenre, Colors.white.withValues(alpha: 0.2)),
                                  _buildBadge(year, Colors.white.withValues(alpha: 0.2)),
                                  _buildBadge(language, Colors.white.withValues(alpha: 0.2)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                title.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                overview,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5),
                              ),
                              
                              const SizedBox(height: 60),
                            ],
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
      }
    );
  }

  Widget _buildBadge(String text, Color color) {
    if (text.isEmpty || text == "N/A") return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
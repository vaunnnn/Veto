import 'dart:async';
import 'package:flutter/material.dart';
import 'package:veto/core/themes/app_colors.dart'; // Adjust if your package name is different
import 'package:veto/features/rooms/screens/landing_screen.dart';
import 'swipe_deck_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenreSelectionScreen extends StatefulWidget {
  final String roomCode;
  final String playerDeviceId;

  const GenreSelectionScreen({
    super.key,
    required this.roomCode,
    required this.playerDeviceId,
  });

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  bool _isHost = false;
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
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

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> _leaveRoom() async {
    _roomSubscription?.cancel();

    if (_isHost) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({
            'connectedPlayers': FieldValue.arrayRemove([widget.playerDeviceId]),
            'playerProfiles.${widget.playerDeviceId}': FieldValue.delete(),
          });
    }

    if (mounted) {
      _navigatedAway = true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  final List<Map<String, String>> genres = [
    {'name': 'Action', 'image': 'assets/images/action.webp'},
    {'name': 'Adventure', 'image': 'assets/images/adventure.webp'},
    {'name': 'Animation', 'image': 'assets/images/animation.webp'},
    {'name': 'Biography', 'image': 'assets/images/biography.webp'},
    {'name': 'Comedy', 'image': 'assets/images/comedy.webp'},
    {'name': 'Documentary', 'image': 'assets/images/documentary.webp'},
    {'name': 'Drama', 'image': 'assets/images/drama.webp'},
    {'name': 'Family', 'image': 'assets/images/family.webp'},
    {'name': 'Fantasy', 'image': 'assets/images/fantasy.webp'},
    {'name': 'History', 'image': 'assets/images/history.webp'},
    {'name': 'Horror', 'image': 'assets/images/horror.webp'},
    {'name': 'Musical', 'image': 'assets/images/musical.webp'},
    {'name': 'Mystery', 'image': 'assets/images/mystery.webp'},
    {'name': 'Romance', 'image': 'assets/images/romance.webp'},
    {'name': 'Sci-Fi', 'image': 'assets/images/sci-fi.webp'},
    {'name': 'Sport', 'image': 'assets/images/sport.webp'},
    {'name': 'Thriller', 'image': 'assets/images/thriller.webp'},
    {'name': 'Western', 'image': 'assets/images/western.webp'},
  ];

  final Set<String> selectedGenres = {};

  void _toggleGenre(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        // Always allow them to deselect a genre
        selectedGenres.remove(genre);
      } else {
        // If they haven't hit the limit yet, add it!
        if (selectedGenres.length < 3) {
          selectedGenres.add(genre);
        } else {
          // If they are already at 3, show a friendly warning
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only select up to 3 genres!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _showWaitingDialog() {
    // 1. Capture the theme to dynamically adjust colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          // 2. WIDEN THE DIALOG: Reduces the default horizontal margins
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          // Adapts background color based on Light/Dark mode
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomCode)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final List<dynamic> connectedPlayers =
                  data['connectedPlayers'] ?? [];
              final Map<String, dynamic> profiles =
                  data['playerProfiles'] ?? {};

              int readyCount = 0;
              List<Widget> playerStatusWidgets = [];

              for (String deviceId in connectedPlayers) {
                final profile = profiles[deviceId] ?? {};
                final String name = profile['name'] ?? 'Guest';
                final String avatar =
                    profile['avatar'] ?? 'assets/images/default-pic-1.webp';
                final bool isReady =
                    profile.containsKey('genres') &&
                    (profile['genres'] as List).isNotEmpty;

                if (isReady) readyCount++;

                String subtitleText = 'Selecting...';
                if (isReady) {
                  final List<dynamic> userGenres = profile['genres'];
                  subtitleText = userGenres.join(', ');
                }

                playerStatusWidgets.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    // 3. OPTIMIZED LAYOUT: Reduced horizontal padding to give text more room
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      // Adapts inner card color
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20, // Slightly smaller avatar
                          backgroundColor: Colors.grey.shade800,
                          onBackgroundImageError: (exception, stackTrace) {
                            // Log the error for debugging
                            debugPrint('Failed to load image: $exception');
                          },
                          // THE FIX: Switch between NetworkImage and AssetImage automatically
                          backgroundImage: avatar.startsWith('http')
                              ? NetworkImage(avatar) as ImageProvider
                              : AssetImage(avatar),
                        ),
                        const SizedBox(
                          width: 12,
                        ), // Tighter spacing to maximize text width
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87, // Adapts text color
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // Adapts subtitle text color
                                  color: isReady
                                      ? (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600)
                                      : Colors.red.shade400,
                                  fontSize:
                                      11.5, // LOWERED text size to fit 3 genres
                                  fontWeight: isReady
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        isReady
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF10B981),
                                size: 24,
                              )
                            : Icon(
                                Icons.more_horiz,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey,
                                size: 24,
                              ),
                      ],
                    ),
                  ),
                );
              }

              // --- TELEPORTATION LOGIC ---
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (data['status'] == 'swiping') {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SwipeDeckScreen(
                        selectedGenres: selectedGenres,
                        roomCode: widget.roomCode,
                        playerDeviceId: widget.playerDeviceId,
                      ),
                    ),
                  );
                } else if (readyCount == connectedPlayers.length &&
                    connectedPlayers.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomCode)
                      .update({'status': 'swiping'});
                }
              });

              int waitingFor = connectedPlayers.length - readyCount;

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Waiting for $waitingFor more...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isDark
                            ? Colors.white
                            : Colors.black87, // Adapts text
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sit tight, your group is making their picks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600, // Adapts text
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    ...playerStatusWidgets,

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          // Adapts button color
                          backgroundColor: isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .update({
                                'playerProfiles.${widget.playerDeviceId}.genres':
                                    [],
                              });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel Selection',
                          style: TextStyle(
                            // Adapts button text color
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isLightMode ? Colors.black : Colors.white,
                          fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                        ),
                        children: const [
                          TextSpan(text: "What's the "),
                          TextSpan(
                            text: "Vibe?",
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Select up to 3 genres you're in the mood for.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLightMode ? Colors.black54 : Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: genres.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    final isSelected = selectedGenres.contains(genre['name']);
                    return _buildGenreCard(genre, isSelected);
                  },
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: selectedGenres.isEmpty
                          ? null
                          : () async {
                              // 1. Fetch the room data to see how many people are playing
                              final roomDoc = await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .get();

                              final connectedPlayers =
                                  (roomDoc.data()?['connectedPlayers']
                                      as List?) ??
                                  [];

                              // 2. Save their selected genres to the database
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .update({
                                    'playerProfiles.${widget.playerDeviceId}.genres':
                                        selectedGenres.toList(),
                                  });

                              // 3. THE FIX: Are they playing solo? Skip the dialog entirely!
                              if (connectedPlayers.length <= 1) {
                                // Tell the database we are moving to the swiping phase
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(widget.roomCode)
                                    .update({'status': 'swiping'});

                                // Instantly teleport the solo player
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SwipeDeckScreen(
                                        selectedGenres: selectedGenres,
                                        roomCode: widget.roomCode,
                                        playerDeviceId: widget.playerDeviceId,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                // 4. Playing with friends? Show the normal waiting dialog!
                                _showWaitingDialog();
                              }
                            },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'START VETOING',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.play_arrow_rounded, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreCard(Map<String, String> genre, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleGenre(genre['name']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 200,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.black],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,

                  // CHANGE HERE: Update Image.network to Image.asset
                  child: Image.asset(
                    genre['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              // NEW CODE: Wrapping the Padding in an Align widget
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Enforces vertical centering
                    children: [
                      Text(
                        genre['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 14,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
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
      ),
    );
  }
}

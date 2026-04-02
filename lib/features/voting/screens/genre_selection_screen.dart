import 'package:flutter/material.dart';
import 'package:veto/core/themes/app_colors.dart'; // Adjust if your package name is different
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
  final List<Map<String, String>> genres = [
    {
      'name': 'Action',
      'image':
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Adventure',
      'image':
          'https://images.unsplash.com/photo-1536697246787-1f27c65a56c7?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Animation',
      'image':
          'https://images.unsplash.com/photo-1524253482453-3fed8d2fe12b?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Biography',
      'image':
          'https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Comedy',
      'image':
          'https://images.unsplash.com/photo-1543584756-8f40a802e14f?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Documentary',
      'image':
          'https://images.unsplash.com/photo-1552508744-1696d4464960?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Drama',
      'image':
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Family',
      'image':
          'https://images.unsplash.com/photo-1484642055655-f8fc513b2ce4?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Fantasy',
      'image':
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'History',
      'image':
          'https://images.unsplash.com/photo-1461360228754-6e81c478b882?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Horror',
      'image':
          'https://images.unsplash.com/photo-1505635552518-3448ff116af3?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Musical',
      'image':
          'https://images.unsplash.com/photo-1503095396549-807759245b35?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Mystery',
      'image':
          'https://images.unsplash.com/photo-1514355315815-2b64b0216b14?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Romance',
      'image':
          'https://images.unsplash.com/photo-1518199266791-5375a83190b7?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Sci-Fi',
      'image':
          'https://images.unsplash.com/photo-1614729939124-032f0b56c9ce?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Sport',
      'image':
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Thriller',
      'image':
          'https://images.unsplash.com/photo-1509347528160-9a9e33742cdb?q=80&w=800&auto=format&fit=crop',
    },
    {
      'name': 'Western',
      'image':
          'https://images.unsplash.com/photo-1534346875952-441865c3b174?q=80&w=800&auto=format&fit=crop',
    },
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
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents them from tapping outside to close it early
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Waiting for party...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomCode)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox(
                  height: 100,
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

              // Loop through everyone to see who is ready
              for (String deviceId in connectedPlayers) {
                final profile = profiles[deviceId] ?? {};
                final String name = profile['name'] ?? 'Guest';
                final String avatar =
                    profile['avatar'] ??
                    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=200&auto=format&fit=crop';
                final bool isReady =
                    profile.containsKey('genres') &&
                    (profile['genres'] as List).isNotEmpty;

                if (isReady) readyCount++;

                String subtitleText = 'Choosing...';
                if (isReady) {
                  // Show the specific genres this person picked!
                  final List<dynamic> userGenres = profile['genres'];
                  subtitleText = userGenres.join(', ');
                }

                playerStatusWidgets.add(
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(avatar),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isReady ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: isReady
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                  ),
                );
              }

              // --- TELEPORTATION LOGIC ---
              // addPostFrameCallback ensures we don't try to navigate while the dialog is still drawing itself
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (data['status'] == 'swiping') {
                  // The status flipped! Close dialog and teleport!
                  // The status flipped! Close dialog and teleport!
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SwipeDeckScreen(
                        selectedGenres: selectedGenres,
                        roomCode: widget.roomCode,             // <-- NEW: Pass the room code!
                        playerDeviceId: widget.playerDeviceId, // <-- NEW: Pass the player ID!
                      ), 
                    ),
                  );
                } else if (readyCount == connectedPlayers.length &&
                    connectedPlayers.isNotEmpty) {
                  // Everyone is ready! Tell Firebase to flip the status to 'swiping'
                  FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomCode)
                      .update({'status': 'swiping'});
                }
              });

              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$readyCount / ${connectedPlayers.length} Players Ready',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...playerStatusWidgets,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.iconTheme.color),
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
              backgroundColor: AppColors.secondary,
              radius: 18,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "STEP 1: THE CURATED LIST",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey,
                  ),
                ),
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
                  "Select genres to tailor your experience. More bars fit on screen for faster browsing.",
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: genres.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                child: ElevatedButton(
                  onPressed: selectedGenres.isEmpty
                      ? null
                      : () async {
                          // 1. Immediately pop up the "Waiting" dialog
                          _showWaitingDialog();

                          // 2. Save their selected genres to their specific profile in the database
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .update({
                                'playerProfiles.${widget.playerDeviceId}.genres':
                                    selectedGenres.toList(),
                              });
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
                  child: Image.network(
                    genre['image']!,
                    fit: BoxFit.cover,
                    // NEW: If the image is broken, gracefully show nothing!
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink(); // An invisible, zero-size box
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

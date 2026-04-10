import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veto/features/voting/screens/genre_selection_screen.dart';
import 'landing_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String playerDeviceId;

  const WaitingRoomScreen({
    super.key,
    required this.roomCode,
    required this.playerDeviceId,
    this.isHost = false,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  // This is our background listener that watches for kicks and teleports
  StreamSubscription<DocumentSnapshot>? _roomSubscription;

  @override
  void initState() {
    super.initState();
    _listenToRoomEvents();

  }

  // --- THE MAGIC TELEPORT & KICK LOGIC ---
  void _listenToRoomEvents() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomCode)
        .snapshots()
        .listen((snapshot) {
          // 1. IF THE ROOM NO LONGER EXISTS (Host Deleted It)
          if (!snapshot.exists) {
            // We only show the error to the guests (the host knows they left!)
            if (mounted && !widget.isHost) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The host has closed the session.'),
                  backgroundColor: Colors.red,
                ),
              );
              // Kick them back to the landing screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            }
          }
          // 2. IF THE ROOM EXISTS, CHECK THE STATUS AND ROSTER
          else {
            final data = snapshot.data() as Map<String, dynamic>;
            final List<dynamic> connectedPlayers =
                data['connectedPlayers'] ?? [];

            // NEW: Check if this specific user was kicked!
            if (!widget.isHost &&
                !connectedPlayers.contains(widget.playerDeviceId)) {
              if (mounted) {
                _roomSubscription?.cancel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have been removed from the session.'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandingScreen(),
                  ),
                  (route) => false,
                );
              }
              return; // Stop running the rest of the listener
            }

            // Existing logic: Teleport everyone if the host starts the session
            if (data['status'] == 'voting') {
              if (mounted) {
                _roomSubscription?.cancel();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenreSelectionScreen(
                      roomCode: widget.roomCode,
                      playerDeviceId: widget.playerDeviceId,
                    ),
                  ),
                );
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();

    super.dispose();
  }

  // 1. A fun list of pre-made avatars
  final List<String> availableAvatars = [
    'assets/images/default-pic-1.png',
    'assets/images/default-pic-2.png',
    'assets/images/default-pic-3.png',
    'assets/images/default-pic-4.png',
    'assets/images/default-pic-5.png',
    'assets/images/default-pic-6.png',
  ];

  // 2. The Pop-up Dialog
  // 2. The Pop-up Dialog
  void _showEditProfileDialog(String currentName, String currentAvatar) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    String newAvatar = currentAvatar;

    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final avatarBgColor = isDarkMode ? Colors.white : Colors.grey.shade300;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                      controller: nameController,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableAvatars.map((url) {
                        bool isSelected = newAvatar == url;
                        return GestureDetector(
                          onTap: () => setDialogState(() => newAvatar = url),
                          child: Container(
                            // NEW: Adds a 3-pixel gap between the avatar and the selection ring!
                            padding: const EdgeInsets.all(3), 
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary // The red selection color
                                    : Colors.transparent,
                                width: 2.0, // A thin, clean outline
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              // NEW: Applies your grey/white background behind the transparent PNGs
                              backgroundColor: avatarBgColor,
                              backgroundImage: AssetImage(url),
                              radius: 36,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // Makes the Cancel splash a very soft, clean version of your primary color
                    overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.white.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    final String finalName = nameController.text.trim();
                    
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomCode)
                        .set({
                          'playerProfiles': {
                            widget.playerDeviceId: {
                              'name': finalName.isEmpty ? 'Guest' : finalName,
                              'avatar': newAvatar,
                            },
                          },
                        }, SetOptions(merge: true));

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bgColor = theme.brightness == Brightness.light
        ? const Color(0xFFF8F9FA)
        : colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'VETO',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 1.5, 
              ),
            ),
          ],
        ),
      ),
      // We still use StreamBuilder to draw the UI live
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> connectedPlayers = data['connectedPlayers'] ?? [];
          final int playerCount = connectedPlayers.length;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // MOVED BACK: PEOPLE WAITING COUNT IS ON TOP
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded, 
                              color: colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$playerCount People Waiting',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ROOM CODE CARD (Now sits below the count)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.white
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ROOM CODE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              widget.roomCode,
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.copy,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // PLAYER GRID
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: playerCount,
                          itemBuilder: (context, index) {
                            final String targetDeviceId =
                                connectedPlayers[index];

                            final Map<String, dynamic> playerProfiles =
                                data['playerProfiles'] ?? {};
                            
                            final Map<String, dynamic> currentProfile =
                                playerProfiles[targetDeviceId] ??
                                {
                                  'name': 'Player ${index + 1}',
                                  'avatar':
                                      availableAvatars[index %
                                          availableAvatars.length],
                                };

                            bool isCurrentUser =
                                targetDeviceId == widget.playerDeviceId;
                            String status = index == 2
                                ? 'CHOOSING SNACKS...'
                                : 'READY TO VETO';

                            return _buildPlayerCard(
                              currentProfile['name']!, 
                              currentProfile['avatar']!, 
                              status,
                              isCurrentUser,
                              widget.isHost,
                              targetDeviceId,
                              colorScheme,
                              theme.brightness,
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // FOOTER CONTROLS
                Container(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 32,
                    top: 16,
                  ),
                  decoration: BoxDecoration(color: bgColor),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isHost
                                ? colorScheme.primary
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: widget.isHost
                              ? () async {
                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(widget.roomCode)
                                      .update({'status': 'voting'});
                                }
                              : null,
                          child: Text(
                            widget.isHost
                                ? 'START SESSION'
                                : 'WAITING FOR HOST...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            side: BorderSide(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () async {
                            _roomSubscription?.cancel();

                            if (widget.isHost) {
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .delete();
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .update({
                                'connectedPlayers': FieldValue.arrayRemove([
                                  widget.playerDeviceId,
                                ]),
                                'playerProfiles.${widget.playerDeviceId}':
                                    FieldValue.delete(), 
                              });
                            }

                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LandingScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            'LEAVE ROOM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(
    String name,
    String imageUrl,
    String status,
    bool isYou,
    bool isHostView, // NEW
    String targetDeviceId, // NEW
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),

                  // THE NEW KICK BUTTON
                  if (isHostView && !isYou)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          // Instantly removes them from the array AND deletes their profile data
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .update({
                            'connectedPlayers': FieldValue.arrayRemove([
                              targetDeviceId,
                            ]),
                            'playerProfiles.$targetDeviceId':
                                FieldValue.delete(), 
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6), // Slightly larger touch area
                          decoration: BoxDecoration(
                            // A sleek, semi-transparent dark background instead of bright red
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_remove_rounded, // Matches your reference image!
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                  if (isYou)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isYou)
              Text(
                'DISPLAY NAME',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
            if (!isYou) const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isYou)
                  GestureDetector(
                    // Calls our new pop-up and passes in their current name/avatar
                    onTap: () => _showEditProfileDialog(name, imageUrl),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async'; // Added to allow background listening
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
                    builder: (context) => const GenreSelectionScreen(),
                  ),
                );
              }
            }
          }
        });
  }

  @override
  void dispose() {
    // Always clean up listeners to prevent memory leaks!
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bgColor = theme.brightness == Brightness.light
        ? const Color(0xFFF8F9FA)
        : colorScheme.surface;

    final List<Map<String, String>> dummyProfiles = [
      {
        'name': 'Movie Critic',
        'image':
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'CinemaFan_99',
        'image':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'DirectorCut',
        'image':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'TheAuteur',
        'image':
            'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?q=80&w=200&auto=format&fit=crop',
      },
      {
        'name': 'ClassicCine',
        'image':
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=200&auto=format&fit=crop',
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Icon(Icons.menu, color: colorScheme.onSurface),
        title: Text(
          'VETO',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(dummyProfiles[0]['image']!),
            ),
          ),
        ],
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
                        const SizedBox(height: 10),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: colorScheme.primary,
                              size: 16,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                        const SizedBox(height: 30),

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
                          itemCount:
                              playerCount, // Removed the +1 for the invite card
                          itemBuilder: (context, index) {
                            final profile =
                                dummyProfiles[index % dummyProfiles.length];

                            // Get the actual device ID of the player for this specific card
                            final String targetDeviceId =
                                connectedPlayers[index];

                            // A much smarter way to check if this card belongs to YOU
                            bool isCurrentUser =
                                targetDeviceId == widget.playerDeviceId;
                            String status = index == 2
                                ? 'CHOOSING SNACKS...'
                                : 'READY TO VETO';

                            return _buildPlayerCard(
                              profile['name']!,
                              profile['image']!,
                              status,
                              isCurrentUser,
                              widget.isHost, // Pass whether YOU are the host
                              targetDeviceId, // Pass the ID of the person on the card
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
                                  // Instead of navigating, the Host just tells Firebase "We are starting!"
                                  // The background listener will catch this and teleport EVERYONE.
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
                            // IF HOST: Delete the entire room
                            if (widget.isHost) {
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .delete();
                            }
                            // IF GUEST: Just remove yourself
                            else {
                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(widget.roomCode)
                                  .update({
                                    'connectedPlayers': FieldValue.arrayRemove([
                                      widget.playerDeviceId,
                                    ]),
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
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // THE NEW KICK BUTTON
                  if (isHostView && !isYou)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () async {
                          // Instantly removes them from Firebase
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .update({
                                'connectedPlayers': FieldValue.arrayRemove([
                                  targetDeviceId,
                                ]),
                              });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
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
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
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

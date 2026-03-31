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
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _listenToRoomEvents();
    
    // NEW: Start the 10-minute countdown the second the screen loads
    _expirationTimer = Timer(const Duration(minutes: 10), _handleRoomExpiration);
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

// --- THE 10 MINUTE EXPIRATION LOGIC ---
  void _handleRoomExpiration() async {
    if (!mounted) return;

    // 1. Put on earmuffs
    _roomSubscription?.cancel();

    // 2. Tell the user what happened
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room expired due to inactivity.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );

    // 3. THE FIX: We removed the "if (widget.isHost)" rule!
    // Now, if ANY player's timer hits 10 minutes, their phone acts as the 
    // garbage collector and completely nukes the room from the database.
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode).delete();
    } catch (e) {
      debugPrint("Error deleting expired room: $e");
    }

    // 4. Teleport back to start
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    
    // NEW: Cancel the stopwatch if we leave the screen early (e.g. game starts)
    _expirationTimer?.cancel(); 
    
    super.dispose();
  }

  // 1. A fun list of pre-made avatars
  final List<String> availableAvatars = [
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?q=80&w=200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200&auto=format&fit=crop',
  ];

  // 2. The Pop-up Dialog
  void _showEditProfileDialog(String currentName, String currentAvatar) {
    String newName = currentName;
    String newAvatar = currentAvatar;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder allows the dialog to update instantly when you tap an avatar
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
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                      onChanged: (value) => newName = value,
                      controller: TextEditingController(text: currentName),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose Avatar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableAvatars.map((url) {
                        bool isSelected = newAvatar == url;
                        return GestureDetector(
                          onTap: () => setDialogState(() => newAvatar = url),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(url),
                              radius: 25,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update Firebase with the new profile using merge: true so we don't overwrite the room!
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomCode)
                        .set({
                          'playerProfiles': {
                            widget.playerDeviceId: {
                              'name': newName.isEmpty ? 'Guest' : newName,
                              'avatar': newAvatar,
                            },
                          },
                        }, SetOptions(merge: true));

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
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
                            final String targetDeviceId =
                                connectedPlayers[index];

                            // NEW: Grab the profiles dictionary from Firebase
                            final Map<String, dynamic> playerProfiles =
                                data['playerProfiles'] ?? {};
                            // NEW: Find this specific player's data, or give them a default if they haven't set one yet
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
                              currentProfile['name']!, // Updated!
                              currentProfile['avatar']!, // Updated!
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
                            // NEW: Put on earmuffs! Cancel the background listener right now
                            // so you don't trigger your own "kicked" notification.
                            _roomSubscription?.cancel();

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
                                    'playerProfiles.${widget.playerDeviceId}':
                                        FieldValue.delete(), // <-- NEW: Nukes your profile!
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
                          // Instantly removes them from the array AND deletes their profile data
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .update({
                                'connectedPlayers': FieldValue.arrayRemove([
                                  targetDeviceId,
                                ]),
                                'playerProfiles.$targetDeviceId':
                                    FieldValue.delete(), // <-- NEW: Nukes the profile!
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard access
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veto/features/voting/screens/genre_selection_screen.dart';
import 'package:veto/features/rooms/screens/landing_screen.dart';

class WaitingRoomScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Color bgColor = theme.brightness == Brightness.light 
        ? const Color(0xFFF8F9FA) 
        : colorScheme.surface;

    final List<Map<String, String>> dummyProfiles = [
      {'name': 'Movie Critic', 'image': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=200&auto=format&fit=crop'},
      {'name': 'CinemaFan_99', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop'},
      {'name': 'DirectorCut', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop'},
      {'name': 'TheAuteur', 'image': 'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?q=80&w=200&auto=format&fit=crop'},
      {'name': 'ClassicCine', 'image': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=200&auto=format&fit=crop'},
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
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').doc(roomCode).snapshots(),
        builder: (context, snapshot) {
          
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("Room no longer exists."));
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
                        
                        const SizedBox(height: 24),

                        Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light ? Colors.white : colorScheme.surfaceContainerHighest,
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
                                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              roomCode,
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Make the copy icon interactive
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(text: roomCode));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Room code copied!'),
                                                    backgroundColor: colorScheme.primary,
                                                    behavior: SnackBarBehavior.floating,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                              child: Icon(
                                                Icons.copy, 
                                                color: colorScheme.onSurface.withValues(alpha: 0.5), 
                                                size: 20
                                              ),
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
                        
                        const SizedBox(height: 16), 

                        Row(
                          children: [
                            Icon(Icons.people, color: colorScheme.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '$playerCount People Waiting',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24), 

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: playerCount + 1, 
                          itemBuilder: (context, index) {
                            if (index == playerCount) {
                              return _buildInviteCard(colorScheme);
                            }
                            
                            final profile = dummyProfiles[index % dummyProfiles.length];
                            bool isCurrentUser = (index == 0 && isHost) || (index == connectedPlayers.length - 1 && !isHost);
                            String status = index == 2 ? 'CHOOSING SNACKS...' : 'READY TO VETO';

                            return _buildPlayerCard(
                              profile['name']!, 
                              profile['image']!, 
                              status, 
                              isCurrentUser, 
                              colorScheme, 
                              theme.brightness
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
                  decoration: BoxDecoration(color: bgColor),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isHost ? colorScheme.primary : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: isHost 
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GenreSelectionScreen()),
                                );
                              }
                            : null, 
                          child: Text(
                            isHost ? 'START SESSION' : 'WAITING FOR HOST...',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                            side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () async {
                            // 1. Tell Firebase to remove this specific player from the room
                            await FirebaseFirestore.instance.collection('rooms').doc(roomCode).update({
                              'connectedPlayers': FieldValue.arrayRemove([playerDeviceId])
                            });

                            // 2. Navigate away safely
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LandingScreen()),
                                (route) => false, 
                              );
                            }
                          },
                          child: const Text(
                            'LEAVE ROOM',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildPlayerCard(String name, String imageUrl, String status, bool isYou, ColorScheme colorScheme, Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        color: brightness == Brightness.light ? Colors.white : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                    child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                  if (isYou) 
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isYou)
              Text('DISPLAY NAME', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1.0)),
            if (!isYou) const SizedBox(height: 10), 
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    name, 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: colorScheme.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isYou) Icon(Icons.edit, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 2),
            Text(status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1), width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_alt_1, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            'INVITE FRIEND',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:veto/core/themes/app_colors.dart';
import 'join_room_screen.dart';
import 'waiting_room_screen.dart';
import '../services/room_service.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roomService = RoomService();
    // For now, we will use a dummy device ID until we build authentication
    final String myDeviceId = "device_${DateTime.now().millisecondsSinceEpoch}";
    final size = MediaQuery.of(context).size;

    // NEW: Detect if the phone is in Dark Mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white, // Adapts to mode
      body: Stack(
        children: [
          // 1. THE BACKGROUND GIF (Adapts to Light/Dark Mode)
          Positioned.fill(
            child: Image.asset(
              isDark
                  ? 'assets/images/bg-dark.png' // <-- Update this to your exact dark GIF filename
                  : 'assets/images/bg-light.png', // <-- Update this to your exact light GIF filename
              fit: BoxFit.cover,
            ),
          ),

          // 2. THE CONTRAST OVERLAY (Keeps text readable)
          Positioned.fill(
            child: Container(
              // A dark wash for dark mode, and a frosted white wash for light mode
              color: isDark
                  ? Colors.black.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.85),
            ),
          ),

          // 3. YOUR EXISTING UI
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // SECTION 1: HERO (Matches Image 1)
                  // ==========================================
                  Container(
                    constraints: BoxConstraints(minHeight: size.height * 0.85),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize:
                                    68, // Keeps your massive, premium size for large phones
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -1.5,
                                fontFamily: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.fontFamily,
                              ),
                              children: [
                                TextSpan(
                                  text: 'LESS\nCHOOSING\n',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'MORE\nWATCHING',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Turn the 45-minute debate into a 5-minute game. Match on a movie before the popcorn gets cold.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600, // Adapts to mode
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Button 1: Create Room (Red)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () async {
                              // 1. Create the room in the database
                              String newRoomCode = await roomService.createRoom(
                                myDeviceId,
                              );

                              // 2. Navigate to the Waiting Room and pass the code
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WaitingRoomScreen(
                                      roomCode: newRoomCode,
                                      isHost: true,
                                      playerDeviceId: myDeviceId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'CREATE ROOM',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Button 2: Join Room (Adapts to mode)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // Lighter grey in dark mode so it doesn't blend into the black background
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const JoinRoomScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_alt_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'JOIN ROOM',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        Text(
                          'SEE HOW IT WORKS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // SECTION 2: WHAT IS VETO?
                  // ==========================================
                  Container(
                    constraints: BoxConstraints(
                      minHeight:
                          size.height *
                          0.85, // Forces this section to take up the whole screen
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Centers everything vertically
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize:
                                  32, // Slightly larger to command the empty space
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              fontFamily: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.fontFamily,
                            ),
                            children: [
                              TextSpan(
                                text: 'WHAT IS ',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const TextSpan(
                                text: 'VETO?',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 32,
                        ), // Increased spacing for breathing room
                        Text(
                          'Veto is the ultimate group decision-making tool for your next movie night. Think "Tinder for movies"—you and your friends swipe through curated lists of titles, liking what you want to watch and vetoing what you don\'t.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            height:
                                1.7, // Increased line height for better readability
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No more 45-minute debates or scrolling through thousands of options on Netflix. When everyone in your room likes the same movie, it\'s a match!',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // NEW: A stylized highlight box to fill space and add a premium touch
                        Container(
                          width: double
                              .infinity, // Ensures the box still stretches across the screen
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.3 : 0.15,
                              ),
                            ),
                          ),
                          child: Text(
                            "The average person spends over 100 hours a year just deciding what to watch. Take that time back.",
                            textAlign:
                                TextAlign.center, // Centers the text nicely
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight
                                  .w600, // Slightly bolder to make it pop
                              color: isDark
                                  ? Colors.grey.shade300
                                  : AppColors.primary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // SECTION 3: HOW IT WORKS (Matches Image 3)
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              fontFamily: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.fontFamily,
                            ),
                            children: [
                              TextSpan(
                                text: 'HOW IT ',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ), // Adapts to mode
                              ),
                              const TextSpan(
                                text: 'WORKS',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildStepCard(
                          icon: Icons.meeting_room_rounded,
                          title: '1. Create or Join',
                          description:
                              'Start a new room and share the code, or jump into a friend\'s session instantly.',
                          isDark: isDark, // Pass the mode down
                        ),
                        const SizedBox(height: 16),
                        _buildStepCard(
                          icon: Icons.swipe_rounded,
                          title: '2. Swipe on Movies',
                          description:
                              'Everyone swipes independently on the same deck of films. Right for yes, left for no.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildStepCard(
                          icon: Icons.celebration_rounded,
                          title: '3. Find a Winner',
                          description:
                              'As soon as there\'s a group consensus, we\'ll notify everyone. Pop the popcorn!',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // SECTION 4: FOOTER
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.only(top: 60.0, bottom: 40.0),
                    child: Center(
                      child: Column(
                        children: [
                          const Text(
                            'VETO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '© ${DateTime.now().year} VETO. All rights reserved.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // TMDB API Legal Attribution
                          SizedBox(
                            width:
                                280, // This locks the logo and text into a single, perfectly centered block
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/tmdb-logo.png',
                                  width: 36,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the "How it Works" cards
  Widget _buildStepCard({required IconData icon, required String title, required String description, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A1A1A).withValues(alpha: 0.4) // 40% opacity in dark mode
            : Colors.white.withValues(alpha: 0.7),           // 70% opacity in light mode
        borderRadius: BorderRadius.circular(20),
        
        // Lowered the border opacity as well so it doesn't look too harsh against the GIF
        border: Border.all(
          color: isDark 
              ? Colors.grey.shade800.withValues(alpha: 0.5) 
              : Colors.grey.shade300.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87, 
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, 
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

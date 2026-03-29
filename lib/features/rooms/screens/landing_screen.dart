import 'package:flutter/material.dart';
import 'package:veto/core/themes/app_colors.dart'; 
import 'join_room_screen.dart';
import 'waiting_room_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return Scaffold(
      body: Container(
        width: double.infinity,
        // Removed the radial gradient decoration. 
        // It now automatically uses the crisp, solid scaffold background!
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              const Text(
                "PREMIERE ACCESS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                "LESS\nCHOOSING.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 68, 
                  fontWeight: FontWeight.w900,
                  height: 0.9, 
                  letterSpacing: -3.0, 
                  color: isLightMode ? const Color(0xFF1A1A1A) : Colors.white,
                ),
              ),
              const Text(
                "MORE\nWATCHING.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  letterSpacing: -3.0,
                  color: AppColors.primary, 
                ),
              ),

              const Spacer(flex: 2),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    // Create Room Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.resolveWith<double>((states) {
                            if (states.contains(MaterialState.hovered)) return 6;
                            if (states.contains(MaterialState.pressed)) return 0;
                            return 0; 
                          }),
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.pressed)) return const Color(0xFFB0060E); 
                            if (states.contains(MaterialState.hovered)) return const Color(0xFFFF2430); 
                            return AppColors.primary;
                          }),
                          overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WaitingRoomScreen(),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'CREATE ROOM',
                              style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Join Room Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.resolveWith<double>((states) {
                            if (states.contains(MaterialState.hovered)) return 6;
                            if (states.contains(MaterialState.pressed)) return 0;
                            return 0; 
                          }),
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (isLightMode) {
                              if (states.contains(MaterialState.pressed)) return const Color(0xFFCCCCCC);
                              if (states.contains(MaterialState.hovered)) return const Color(0xFFDCDCDC);
                              return const Color(0xFFE5E5E5); 
                            } else {
                              if (states.contains(MaterialState.pressed)) return const Color(0xFF1A1A1A);
                              if (states.contains(MaterialState.hovered)) return const Color(0xFF333333);
                              return const Color(0xFF262626); 
                            }
                          }),
                          overlayColor: MaterialStateProperty.all(
                            isLightMode ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05)
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            isLightMode ? const Color(0xFF1A1A1A) : Colors.white
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                              style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Footer Features
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureItem(Icons.movie_creation_outlined, "CINEMA\nMODE"),
                    _buildDivider(),
                    _buildFeatureItem(Icons.speed_rounded, "ZERO\nLATENCY"),
                    _buildDivider(),
                    _buildFeatureItem(Icons.hd_outlined, "ULTRA\nHD"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 26),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 35,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }
}
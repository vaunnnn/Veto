import 'package:flutter/material.dart';
import 'package:veto/core/themes/app_colors.dart';
import 'package:veto/features/rooms/screens/join_room_screen.dart';
import 'package:veto/features/rooms/screens/waiting_room_screen.dart';
import 'package:veto/features/rooms/services/room_service.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    
    // Initialize backend services from your partner's code
    final roomService = RoomService();
    final String myDeviceId = "device_${DateTime.now().millisecondsSinceEpoch}";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: isLightMode ? Colors.black87 : Colors.white),
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
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Faint cinematic background texture
          image: DecorationImage(
            image: const NetworkImage('https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=800&auto=format&fit=crop'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              theme.scaffoldBackgroundColor.withOpacity(0.96), // Blends heavily into background
              BlendMode.srcOver,
            ),
          ),
        ),
        child: Container(
          // Subtle radial glow centered strictly behind the catchphrase
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.20), 
              radius: 0.40, 
              colors: isLightMode
                  ? [
                      AppColors.primary.withOpacity(0.06),
                      Colors.transparent,
                    ]
                  : [
                      AppColors.primary.withOpacity(0.10),
                      Colors.transparent,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                      fontSize: 54, 
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
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      height: 0.9,
                      letterSpacing: -3.0,
                      color: AppColors.primary, 
                    ),
                  ),

                  const SizedBox(height: 24),

                  // New Subtext
                  Text(
                    "Stop the endless scrolling. Decide together\nin minutes and get back to the story.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isLightMode ? Colors.grey.shade700 : Colors.grey.shade400,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Action Buttons
                  Column(
                    children: [
                      // Create Room Button (Async with Firebase)
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.resolveWith<double>((states) {
                              if (states.contains(MaterialState.hovered)) return 6;
                              if (states.contains(MaterialState.pressed)) return 0;
                              return 4; // Soft resting shadow
                            }),
                            shadowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.4)),
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
                          onPressed: () async {
                            // 1. Create the room in the database using partner's logic
                            String newRoomCode = await roomService.createRoom(
                              myDeviceId,
                            );

                            // 2. Navigate to the Waiting Room and pass the new data
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
                              return 4; 
                            }),
                            shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.1)),
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
                  
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
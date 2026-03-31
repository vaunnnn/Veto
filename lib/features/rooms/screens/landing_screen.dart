import 'package:flutter/material.dart';
import 'join_room_screen.dart';
import 'waiting_room_screen.dart';
import '../services/room_service.dart'; // Import your new service!

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roomService = RoomService();
    // For now, we will use a dummy device ID until we build authentication
    final String myDeviceId = "device_${DateTime.now().millisecondsSinceEpoch}";

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'VETO',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 50),

              // Button 1: Join Room
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JoinRoomScreen(),
                      ),
                    );
                  },
                  child: const Text('Join Room'),
                ),
              ),
              const SizedBox(height: 20),

              // Button 2: Create Room
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  // Make this async so we can wait for Firebase
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
                            playerDeviceId: myDeviceId, // <-- Add this!
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Create Room',
                  ), // Changed text from "Go to Waiting Room"
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
// Import your other screens here
import 'join_room_screen.dart';
import 'waiting_room_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your App Logo or Title
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

              // Button 2: Waiting Room
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WaitingRoomScreen(),
                      ),
                    );
                  },
                  child: const Text('Go to Waiting Room'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
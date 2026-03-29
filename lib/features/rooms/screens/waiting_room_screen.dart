import 'package:flutter/material.dart';
// Import your screens
import 'package:veto/features/voting/screens/genre_selection_screen.dart';
import 'landing_screen.dart'; 

class WaitingRoomScreen extends StatelessWidget {
  final String roomCode;
  
  const WaitingRoomScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room: $roomCode"),
        automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Waiting for others...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(), // Pushes buttons to the bottom

            // Button 1: Start Session
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GenreSelectionScreen()),
                  );
                },
                child: const Text('Start Session'),
              ),
            ),
            const SizedBox(height: 16),

            // Button 2: Leave Room
            SizedBox(
              width: double.infinity,
              height: 55,
              child: TextButton(
                onPressed: () {
                  // This clears ALL previous pages and goes back to Landing
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LandingScreen()),
                    (route) => false, 
                  );
                },
                child: const Text('Leave Room', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
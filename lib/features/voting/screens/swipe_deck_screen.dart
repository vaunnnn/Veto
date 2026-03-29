import 'package:flutter/material.dart';

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  // A simple list of items to "Veto" or "Approve"
  final List<String> movies = ['Inception', 'The Dark Knight', 'Interstellar', 'Parasite'];
  int currentIndex = 0;

  void _nextCard() {
    setState(() {
      if (currentIndex < movies.length - 1) {
        currentIndex++;
      } else {
        // Handle when the deck is empty
        _showFinishedDialog();
      }
    });
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Voting Finished!"),
        content: const Text("Waiting for other players to finish..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("Back to Home"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Veto Your Choices"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Progress Indicator
          Text("Item ${currentIndex + 1} of ${movies.length}"),
          
          const SizedBox(height: 20),
          
          // The Card Stack
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    movies[currentIndex],
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Dislike / Veto Button
                FloatingActionButton.large(
                  heroTag: "dislike",
                  backgroundColor: Colors.redAccent,
                  onPressed: _nextCard,
                  child: const Icon(Icons.close, color: Colors.white, size: 40),
                ),
                
                // Like / Approve Button
                FloatingActionButton.large(
                  heroTag: "like",
                  backgroundColor: Colors.greenAccent.shade700,
                  onPressed: _nextCard,
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
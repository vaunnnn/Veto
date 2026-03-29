import 'package:flutter/material.dart';
// Import the next destination
import 'swipe_deck_screen.dart';

class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({super.key});

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  // A simple list to keep track of selected genres
  final List<String> genres = ['Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi'];
  final Set<String> selectedGenres = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Genres"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                final isSelected = selectedGenres.contains(genre);

                return CheckboxListTile(
                  title: Text(genre),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedGenres.add(genre);
                      } else {
                        selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              },
            ),
          ),
          
          // The "Start Voting" Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedGenres.isEmpty 
                  ? null // Disable button if no genre is picked
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SwipeDeckScreen(),
                        ),
                      );
                    },
                child: const Text('Start Voting', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
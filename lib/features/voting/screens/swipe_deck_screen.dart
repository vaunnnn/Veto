import 'package:flutter/material.dart';
import 'package:veto/core/themes/app_colors.dart';

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  // A simple list of items (Will eventually be TMDB Movie Models)
  final List<Map<String, String>> movies = [
    {
      'title': 'NEON HORIZON',
      'description': 'In a world where memories are traded like currency, one detective must find h...',
      'rating': '9.2 IMDB',
      'genre': 'SCI-FI',
      'image': 'https://images.unsplash.com/photo-1605810230434-7631ac76ec81?q=80&w=800&auto=format&fit=crop' 
    },
    {
      'title': 'THE DARK KNIGHT',
      'description': 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham...',
      'rating': '9.0 IMDB',
      'genre': 'ACTION',
      'image': 'https://images.unsplash.com/photo-1509347528160-9a9e33742cdb?q=80&w=800&auto=format&fit=crop'
    }
  ];
  
  int currentIndex = 0;

  void _nextCard() {
    setState(() {
      if (currentIndex < movies.length - 1) {
        currentIndex++;
      } else {
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
    final currentMovie = movies[currentIndex];
    
    // Grab the current theme so we can respond to Light/Dark mode
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Uses the background from app_theme.dart
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.iconTheme.color), // Adapts to light/dark
          onPressed: () {},
        ),
        title: const Text(
          "VETO",
          style: TextStyle(
            color: AppColors.primary, // Using your centralized Veto Red!
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.secondary, // Dark Charcoal from your palette
              radius: 18,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // Subheader
          Text(
            "NOW PREMIERING",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              // Adapts text color based on light/dark mode
              color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white54, 
            ),
          ),
          
          const SizedBox(height: 20),
          
          // The Card Stack
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  image: DecorationImage(
                    image: NetworkImage(currentMovie['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Dark Gradient Overlay (Kept black so white text is always readable over the poster)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Card Content (Text and Badges)
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges Row
                          Row(
                            children: [
                              _buildBadge(currentMovie['rating']!, AppColors.primary), // Using Veto Red
                              const SizedBox(width: 8),
                              _buildBadge(currentMovie['genre']!, Colors.white.withOpacity(0.2)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Movie Title
                          Text(
                            currentMovie['title']!,
                            style: const TextStyle(
                              color: Colors.white, // Kept white to contrast with the dark gradient
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Movie Description
                          Text(
                            currentMovie['description']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Veto / Dislike Button
                _buildCircularButton(
                  icon: Icons.close,
                  iconColor: theme.brightness == Brightness.light ? AppColors.secondary : Colors.white,
                  backgroundColor: theme.colorScheme.surface,
                  size: 65,
                  onTap: _nextCard,
                ),
                const SizedBox(width: 25),
                
                // Info Button (Smaller)
                _buildCircularButton(
                  icon: Icons.info_rounded,
                  iconColor: Colors.grey,
                  backgroundColor: AppColors.neutral, // Light grey from palette
                  size: 50,
                  onTap: () {},
                  hasShadow: false,
                ),
                const SizedBox(width: 25),
                
                // Approve / Like Button
                _buildCircularButton(
                  icon: Icons.favorite,
                  iconColor: AppColors.primary, // Using Veto Red
                  backgroundColor: theme.colorScheme.surface,
                  size: 65,
                  onTap: _nextCard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for the small pills (IMDB, GENRE)
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper Widget for the circular action buttons
  Widget _buildCircularButton({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required double size,
    required VoidCallback onTap,
    bool hasShadow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: size * 0.45),
        ),
      ),
    );
  }
}
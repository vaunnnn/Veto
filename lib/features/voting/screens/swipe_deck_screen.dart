import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:veto/core/themes/app_colors.dart';

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  // The controller that allows our buttons to trigger swipes
  final CardSwiperController controller = CardSwiperController();

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
    },
    {
      'title': 'DUNE: PART TWO',
      'description': 'Paul Atreides unites with Chani and the Fremen while on a warpath of revenge...',
      'rating': '8.8 IMDB',
      'genre': 'SCI-FI',
      'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop'
    }
  ];

  @override
  void dispose() {
    controller.dispose(); // Always dispose controllers to prevent memory leaks!
    super.dispose();
  }

  // Triggered when a physical swipe happens OR a button is pressed
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint('Swiped ${direction.name} on ${movies[previousIndex]['title']}');
    
    // Here is where we will eventually send the vote to the database!
    if (direction == CardSwiperDirection.right) {
      // Voted YES
    } else if (direction == CardSwiperDirection.left) {
      // Voted NO / VETO
    }
    
    return true; // Return true to allow the swipe animation to complete
  }

  void _onEnd() {
    // Triggered when the deck is completely empty
    showDialog(
      context: context,
      barrierDismissible: false,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.iconTheme.color),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 18,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          Text(
            "NOW PREMIERING",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white54,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // The Interactive Card Swiper
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: movies.length,
              onSwipe: _onSwipe,
              onEnd: _onEnd,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // We restrict swiping to only Left (Veto) and Right (Approve)
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                // We extracted your beautiful card UI into a separate method below
                return _buildMovieCard(movies[index]);
              },
            ),
          ),

          const SizedBox(height: 40),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularButton(
                  icon: Icons.close,
                  iconColor: theme.brightness == Brightness.light ? AppColors.secondary : Colors.white,
                  backgroundColor: theme.colorScheme.surface,
                  size: 65,
                  // Use the controller to trigger a left swipe programmatically
                  onTap: () => controller.swipe(CardSwiperDirection.left),
                ),
                const SizedBox(width: 25),
                
                _buildCircularButton(
                  icon: Icons.info_rounded,
                  iconColor: Colors.grey,
                  backgroundColor: AppColors.neutral,
                  size: 50,
                  onTap: () {}, // Future: Open movie details modal
                  hasShadow: false,
                ),
                const SizedBox(width: 25),
                
                _buildCircularButton(
                  icon: Icons.favorite,
                  iconColor: AppColors.primary,
                  backgroundColor: theme.colorScheme.surface,
                  size: 65,
                  // Use the controller to trigger a right swipe programmatically
                  onTap: () => controller.swipe(CardSwiperDirection.right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- EXTRACTED UI METHODS ---

  Widget _buildMovieCard(Map<String, String> movie) {
    return Container(
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
          image: NetworkImage(movie['image']!),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0, left: 0, right: 0,
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBadge(movie['rating']!, AppColors.primary),
                    const SizedBox(width: 8),
                    _buildBadge(movie['genre']!, Colors.white.withOpacity(0.2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  movie['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie['description']!,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCircularButton({
    required IconData icon, required Color iconColor, required Color backgroundColor,
    required double size, required VoidCallback onTap, bool hasShadow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: backgroundColor, shape: BoxShape.circle,
          boxShadow: hasShadow ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))] : [],
        ),
        child: Center(child: Icon(icon, color: iconColor, size: size * 0.45)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:veto/core/themes/app_colors.dart'; // Adjust path if needed
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  final CardSwiperController controller = CardSwiperController();

  // Changed from Map<String, String> to Map<String, dynamic> to support JSON
  List<Map<String, dynamic>> movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  // --- API INTEGRATION ---
  Future<void> _fetchMovies() async {
    // We hardcode a few titles to build the initial deck for testing.
    final List<String> testTitles = [
      'Guardians of the Galaxy Vol. 2',
      'The Dark Knight',
      'Dune',
      'Inception',
      'Interstellar'
    ];
    
    final String apiKey = dotenv.env['OMDB_API_KEY'] ?? '';
    List<Map<String, dynamic>> fetchedMovies = [];

    try {
      for (String title in testTitles) {
        final url = Uri.parse('https://www.omdbapi.com/?t=${Uri.encodeComponent(title)}&apikey=$apiKey');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['Response'] == 'True') {
            fetchedMovies.add(data);
          }
        }
      }

      setState(() {
        movies = fetchedMovies;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching movies: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    debugPrint('Swiped ${direction.name} on ${movies[previousIndex]['Title']}');
    // Veto logic goes here!
    return true; 
  }

  void _onEnd() {
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
        // Using withValues to avoid deprecation warnings
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
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
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : movies.isEmpty 
            // Fallback if the API fails or returns no data
            ? const Center(child: Text("No movies found. Check your API key!"))
            : Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "NOW PREMIERING",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: movies.length,
                      onSwipe: _onSwipe,
                      onEnd: _onEnd,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
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
                          onTap: () => controller.swipe(CardSwiperDirection.left),
                        ),
                        const SizedBox(width: 25),
                        _buildCircularButton(
                          icon: Icons.info_rounded,
                          iconColor: Colors.grey,
                          backgroundColor: theme.colorScheme.surface,
                          size: 50,
                          onTap: () {}, 
                          hasShadow: false,
                        ),
                        const SizedBox(width: 25),
                        _buildCircularButton(
                          icon: Icons.favorite,
                          iconColor: AppColors.primary,
                          backgroundColor: theme.colorScheme.surface,
                          size: 65,
                          onTap: () => controller.swipe(CardSwiperDirection.right),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final String posterUrl = movie['Poster'] != "N/A" 
        ? movie['Poster'] 
        : 'https://via.placeholder.com/800x1200?text=No+Poster';
    
    final String mainGenre = (movie['Genre'] as String).split(',').first.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        image: DecorationImage(
          image: NetworkImage(posterUrl),
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
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
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
                    _buildBadge('${movie['imdbRating']} IMDB', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildBadge(mainGenre, Colors.white.withValues(alpha: 0.2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  movie['Title'].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie['Plot'],
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.4),
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
          boxShadow: hasShadow ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))] : [],
        ),
        child: Center(child: Icon(icon, color: iconColor, size: size * 0.45)),
      ),
    );
  }
}
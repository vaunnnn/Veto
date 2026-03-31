import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:veto/core/themes/app_colors.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui'; 

class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen> {
  final CardSwiperController controller = CardSwiperController();

  List<Map<String, dynamic>> movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  // --- API INTEGRATION ---
  Future<void> _fetchMovies() async {
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
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
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
              radius: 16,
              backgroundColor: theme.brightness == Brightness.light ? const Color(0xFF1A1A1A) : Colors.white,
              child: Icon(
                Icons.person, 
                size: 20, 
                color: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : movies.isEmpty 
            ? const Center(child: Text("No movies found. Check your API key!"))
            : Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // The Scrollable Movie Card
                  Expanded(
                    child: CardSwiper(
                      controller: controller,
                      cardsCount: movies.length,
                      onSwipe: _onSwipe,
                      onEnd: _onEnd,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      allowedSwipeDirection: const AllowedSwipeDirection.symmetric(horizontal: true),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        return _ScrollableMovieCard(movie: movies[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // The New Scroll Indicator
                  Column(
                    children: [
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        "SCROLL FOR MORE INFO",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Symmetrical Action Buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dislike Button (Now matching the Heart button)
                        _buildCircularButton(
                          icon: Icons.close,
                          iconColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          size: 80,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4), 
                          onTap: () => controller.swipe(CardSwiperDirection.left),
                        ),
                        const SizedBox(width: 30),
                        // Approve Button
                        _buildCircularButton(
                          icon: Icons.favorite,
                          iconColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          size: 80,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4), 
                          onTap: () => controller.swipe(CardSwiperDirection.right),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon, required Color iconColor, required Color backgroundColor,
    required double size, required VoidCallback onTap, bool hasShadow = true, Color? shadowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: backgroundColor, shape: BoxShape.circle,
          boxShadow: hasShadow ? [
            BoxShadow(
              color: shadowColor ?? Colors.black.withValues(alpha: 0.08), 
              blurRadius: 15, 
              spreadRadius: shadowColor != null ? 2 : 0, 
              offset: const Offset(0, 5)
            )
          ] : [],
        ),
        child: Center(child: Icon(icon, color: iconColor, size: size * 0.45)),
      ),
    );
  }
}

// --- STATEFUL WIDGET FOR SCROLLABLE CARD ---
class _ScrollableMovieCard extends StatefulWidget {
  final Map<String, dynamic> movie;

  const _ScrollableMovieCard({required this.movie});

  @override
  State<_ScrollableMovieCard> createState() => _ScrollableMovieCardState();
}

class _ScrollableMovieCardState extends State<_ScrollableMovieCard> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    // Calculates a 0.0 to 1.0 progress based on the first 150 pixels of scrolling
    double offset = _scrollController.offset;
    double progress = (offset / 150.0).clamp(0.0, 1.0);
    
    if (_scrollProgress != progress) {
      setState(() {
        _scrollProgress = progress;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String posterUrl = widget.movie['Poster'] != "N/A" 
        ? widget.movie['Poster'] 
        : 'https://via.placeholder.com/800x1200?text=No+Poster';
    
    final String mainGenre = (widget.movie['Genre'] as String).split(',').first.toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
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
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Static Poster Background
                Positioned.fill(
                  child: Image.network(posterUrl, fit: BoxFit.cover),
                ),
                
                // 2. Base Bottom Gradient (Always visible to pop the text)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                ),

                // 3. Dynamic Blur & Darken Overlay (Reacts to scroll)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _scrollProgress * 12.0, // Max blur of 12
                      sigmaY: _scrollProgress * 12.0,
                    ),
                    child: Container(
                      // Gets progressively darker up to 75% opacity
                      color: Colors.black.withValues(alpha: _scrollProgress * 0.75), 
                    ),
                  ),
                ),

                // 4. The Scrollable Content
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pushes the content down so the poster is visible initially
                        SizedBox(height: constraints.maxHeight - 200),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Expanded Info Badges
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildBadge('${widget.movie['imdbRating']} IMDB', AppColors.primary),
                                  _buildBadge(mainGenre, Colors.white.withValues(alpha: 0.2)),
                                  _buildBadge(widget.movie['Year'] ?? '', Colors.white.withValues(alpha: 0.2)),
                                  _buildBadge(widget.movie['Rated'] ?? '', Colors.white.withValues(alpha: 0.2)),
                                  _buildBadge(widget.movie['Runtime'] ?? '', Colors.white.withValues(alpha: 0.2)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                widget.movie['Title'].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Text(
                                widget.movie['Plot'],
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9), 
                                  fontSize: 14, 
                                  height: 1.5
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Additional Information blocks
                              _buildInfoBlock('CAST', widget.movie['Actors']),
                              _buildInfoBlock('AWARDS', widget.movie['Awards']),
                              
                              // Extra padding so users can scroll all the way past the bottom text
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildBadge(String text, Color color) {
    if (text.isEmpty || text == "N/A") return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoBlock(String title, String? content) {
    if (content == null || content.isEmpty || content == "N/A") return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: Colors.white.withValues(alpha: 0.5), 
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
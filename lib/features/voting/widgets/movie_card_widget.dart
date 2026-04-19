import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:veto/core/themes/app_colors.dart';

class MovieCard extends StatefulWidget {
  final Map<String, dynamic> movie;

  const MovieCard({super.key, required this.movie});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  // NEW: State variables for our extra details
  String _director = '';
  List<String> _cast = [];
  List<Map<String, String>> _reviews = [];
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // NEW: Fetch the juicy details the moment this card is created in the background!
    _fetchAdditionalDetails();
  }

  // --- THE LAZY LOADER ---
  Future<void> _fetchAdditionalDetails() async {
    final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
    final movieId = widget.movie['id'];
    if (movieId == null) return;

    // TMDB allows us to append credits and reviews into a single, blazing-fast API call
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&append_to_response=credits,reviews',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 1. Extract Director
        final crew = data['credits']?['crew'] as List? ?? [];
        final directorObj = crew.firstWhere(
          (member) => member['job'] == 'Director',
          orElse: () => null,
        );
        final directorName = directorObj != null
            ? directorObj['name']
            : 'Unknown';

        // 2. Extract Top 4 Cast Members
        final castList = data['credits']?['cast'] as List? ?? [];
        final topCast = castList
            .take(4)
            .map((c) => c['name'].toString())
            .toList();

        // 3. Extract Top 2 Reviews
        final reviewList = data['reviews']?['results'] as List? ?? [];
        final topReviews = reviewList
            .take(2)
            .map(
              (r) => {
                'author': r['author'].toString(),
                'content': r['content'].toString(),
              },
            )
            .toList();

        if (mounted) {
          setState(() {
            _director = directorName;
            _cast = topCast;
            _reviews = topReviews;
            _isLoadingDetails = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  // --- THE FIX: WATCH FOR NEW MOVIES ---
  @override
  void didUpdateWidget(MovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the swiper recycles this card for a NEW movie, clear the slate and fetch again!
    if (oldWidget.movie['id'] != widget.movie['id']) {
      setState(() {
        _isLoadingDetails = true;
        _director = '';
        _cast = [];
        _reviews = [];
        _scrollProgress = 0.0; // Resets the blur effect too!
      });
      _fetchAdditionalDetails();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

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
    final String posterUrl = widget.movie['poster_path'] != null
        ? 'https://image.tmdb.org/t/p/w500${widget.movie['poster_path']}'
        : 'https://via.placeholder.com/800x1200?text=No+Poster';

    final Map<int, String> tmdbReverseGenres = {
      28: 'ACTION',
      12: 'ADVENTURE',
      16: 'ANIMATION',
      35: 'COMEDY',
      80: 'CRIME',
      99: 'DOCUMENTARY',
      18: 'DRAMA',
      10751: 'FAMILY',
      14: 'FANTASY',
      36: 'HISTORY',
      27: 'HORROR',
      10402: 'MUSICAL',
      9648: 'MYSTERY',
      10749: 'ROMANCE',
      878: 'SCI-FI',
      53: 'THRILLER',
      37: 'WESTERN',
    };

    List<String> movieGenres = ['CINEMA'];
    if (widget.movie['genre_ids'] != null &&
        (widget.movie['genre_ids'] as List).isNotEmpty) {
      movieGenres = (widget.movie['genre_ids'] as List)
          .map((id) => tmdbReverseGenres[id] ?? '')
          .where((genre) => genre.isNotEmpty)
          .toList();
      if (movieGenres.isEmpty) movieGenres = ['CINEMA'];
    }

    final String title = widget.movie['title'] ?? 'Unknown Title';
    final String overview = widget.movie['overview'] ?? 'No plot available.';
    final String releaseDate = widget.movie['release_date'] ?? '';
    final String year = releaseDate.length >= 4
        ? releaseDate.substring(0, 4)
        : '';
    final String rating = (widget.movie['vote_average'] ?? 0.0).toStringAsFixed(
      1,
    );
    final String language = (widget.movie['original_language'] ?? '')
        .toString()
        .toUpperCase();

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
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _scrollProgress * 12.0,
                      sigmaY: _scrollProgress * 12.0,
                    ),
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: _scrollProgress * 0.75,
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: constraints.maxHeight - 200),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildBadge(
                                    '$rating / 10',
                                    AppColors.primary,
                                  ),
                                  ...movieGenres.map(
                                    (genre) => _buildBadge(
                                      genre,
                                      Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  _buildBadge(
                                    year,
                                    Colors.white.withValues(alpha: 0.2),
                                  ),
                                  _buildBadge(
                                    language,
                                    Colors.white.withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Text(
                                title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Text(
                                overview,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // --- THE NEW DETAILS SECTION ---
                              if (_isLoadingDetails)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                // DIRECTOR
                                _buildSectionTitle('DIRECTOR'),
                                const SizedBox(height: 4),
                                Text(
                                  _director,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // CAST
                                if (_cast.isNotEmpty) ...[
                                  _buildSectionTitle('MAIN CAST'),
                                  const SizedBox(height: 4),
                                  Text(
                                    _cast.join(', '),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // REVIEWS
                                if (_reviews.isNotEmpty) ...[
                                  _buildSectionTitle('FEATURED REVIEWS'),
                                  const SizedBox(height: 12),
                                  ..._reviews.map(
                                    (review) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: AppColors.primary,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  review['author']!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              review['content']!,
                                              maxLines: 5,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],

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
      },
    );
  }

  // A tiny helper to make those section titles look sleek and uniform
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    if (text.isEmpty || text == "N/A") return const SizedBox.shrink();

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
}
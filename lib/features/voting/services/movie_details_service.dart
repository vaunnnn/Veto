import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MovieDetailsService {
  static final MovieDetailsService _instance = MovieDetailsService._internal();
  factory MovieDetailsService() => _instance;
  MovieDetailsService._internal();

  final Map<int, MovieDetails> _cache = {};

  Future<MovieDetails?> getDetails(int movieId) async {
    if (_cache.containsKey(movieId)) {
      return _cache[movieId];
    }

    final details = await _fetchDetails(movieId);
    if (details != null) {
      _cache[movieId] = details;
    }

    return details;
  }

  Future<MovieDetails?> _fetchDetails(int movieId) async {
    final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey&append_to_response=credits,reviews',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final crew = data['credits']?['crew'] as List? ?? [];
        final directorObj = crew.firstWhere(
          (member) => member['job'] == 'Director',
          orElse: () => null,
        );
        final directorName = directorObj != null
            ? directorObj['name']
            : 'Unknown';

        final castList = data['credits']?['cast'] as List? ?? [];
        final topCast = castList
            .take(4)
            .map((c) => c['name'].toString())
            .toList();

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

        return MovieDetails(
          director: directorName,
          cast: topCast,
          reviews: topReviews,
        );
      }
    } catch (e) {
      // Log error without exposing sensitive data
      debugPrint("Error fetching movie details");
    }

    return null;
  }

  void clearCache() {
    _cache.clear();
  }
}

class MovieDetails {
  final String director;
  final List<String> cast;
  final List<Map<String, String>> reviews;

  MovieDetails({
    required this.director,
    required this.cast,
    required this.reviews,
  });
}

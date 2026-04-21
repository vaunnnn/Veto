import 'package:veto/core/domain/repositories/movie_repository.dart';

class MovieFilterService {
  final MovieRepository _movieRepository;

  MovieFilterService({required MovieRepository movieRepository})
    : _movieRepository = movieRepository;

  Future<List<Map<String, dynamic>>> fetchMoviesWithFilters({
    required List<String> genres,
    required Map<String, dynamic> filterSettings,
    required int page,
  }) async {
    final minYear = filterSettings['minYear'] ?? 1970;
    final maxYear = filterSettings['maxYear'] ?? DateTime.now().year;
    final minScore = (filterSettings['minScore'] ?? 6.0).toDouble();
    final maxRuntime = filterSettings['maxRuntime'] ?? 'Any Length';
    final familyFriendly = filterSettings['familyFriendly'] ?? false;
    final rawLanguages = filterSettings['languages'] ?? [];
    final languages = List<String>.from(rawLanguages);

    // Convert genres from Firebase format to TMDB genre IDs
    // This mapping should be moved to a constant or configuration
    final genreIds = _convertGenresToIds(genres);

    final movies = await _movieRepository.discoverMovies(
      genres: genreIds,
      minYear: minYear,
      maxYear: maxYear,
      minScore: minScore,
      maxRuntime: maxRuntime,
      familyFriendly: familyFriendly,
      languages: languages,
      page: page,
    );

    // Convert to Map format expected by existing UI
    return movies.map((movie) => movie.toJson()).toList();
  }

  List<String> _convertGenresToIds(List<String> genreNames) {
    // TMDB genre mapping
    const genreMap = {
      'Action': '28',
      'Adventure': '12',
      'Animation': '16',
      'Comedy': '35',
      'Crime': '80',
      'Documentary': '99',
      'Drama': '18',
      'Family': '10751',
      'Fantasy': '14',
      'History': '36',
      'Horror': '27',
      'Music': '10402',
      'Mystery': '9648',
      'Romance': '10749',
      'Science Fiction': '878',
      'TV Movie': '10770',
      'Thriller': '53',
      'War': '10752',
      'Western': '37',
    };

    return genreNames
        .map((name) => genreMap[name] ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }
}

class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final int? voteCount;
  final String? releaseDate;
  final List<int>? genreIds;
  final bool? adult;
  final String? originalLanguage;
  final double? popularity;
  final bool? video;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.voteCount,
    this.releaseDate,
    this.genreIds,
    this.adult,
    this.originalLanguage,
    this.popularity,
    this.video,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List?)?.cast<int>(),
      adult: json['adult'] as bool?,
      originalLanguage: json['original_language'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble(),
      video: json['video'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'overview': overview,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'adult': adult,
      'original_language': originalLanguage,
      'popularity': popularity,
      'video': video,
    };
  }

  Movie copyWith({
    int? id,
    String? title,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    List<int>? genreIds,
    bool? adult,
    String? originalLanguage,
    double? popularity,
    bool? video,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      adult: adult ?? this.adult,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      popularity: popularity ?? this.popularity,
      video: video ?? this.video,
    );
  }
}

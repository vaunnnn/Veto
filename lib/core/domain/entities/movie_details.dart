class MovieDetails {
  final String director;
  final List<String> cast;
  final List<Map<String, String>> reviews;

  MovieDetails({
    required this.director,
    required this.cast,
    required this.reviews,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      director: json['director'] as String,
      cast: (json['cast'] as List).cast<String>(),
      reviews: (json['reviews'] as List).cast<Map<String, String>>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'director': director, 'cast': cast, 'reviews': reviews};
  }

  MovieDetails copyWith({
    String? director,
    List<String>? cast,
    List<Map<String, String>>? reviews,
  }) {
    return MovieDetails(
      director: director ?? this.director,
      cast: cast ?? this.cast,
      reviews: reviews ?? this.reviews,
    );
  }
}

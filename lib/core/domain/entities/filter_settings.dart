class FilterSettings {
  final int minYear;
  final int maxYear;
  final double minScore;
  final String maxRuntime;
  final bool familyFriendly;
  final List<String> languages;

  FilterSettings({
    required this.minYear,
    required this.maxYear,
    required this.minScore,
    required this.maxRuntime,
    required this.familyFriendly,
    required this.languages,
  });

  factory FilterSettings.defaultSettings() {
    return FilterSettings(
      minYear: 1970,
      maxYear: DateTime.now().year,
      minScore: 6.0,
      maxRuntime: 'Any Length',
      familyFriendly: false,
      languages: [],
    );
  }

  factory FilterSettings.fromMap(Map<String, dynamic> map) {
    return FilterSettings(
      minYear: (map['minYear'] as int?) ?? 1970,
      maxYear: (map['maxYear'] as int?) ?? DateTime.now().year,
      minScore: (map['minScore'] as num?)?.toDouble() ?? 6.0,
      maxRuntime: map['maxRuntime'] as String? ?? 'Any Length',
      familyFriendly: map['familyFriendly'] as bool? ?? false,
      languages: List<String>.from(map['languages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minYear': minYear,
      'maxYear': maxYear,
      'minScore': minScore,
      'maxRuntime': maxRuntime,
      'familyFriendly': familyFriendly,
      'languages': languages,
    };
  }

  FilterSettings copyWith({
    int? minYear,
    int? maxYear,
    double? minScore,
    String? maxRuntime,
    bool? familyFriendly,
    List<String>? languages,
  }) {
    return FilterSettings(
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      minScore: minScore ?? this.minScore,
      maxRuntime: maxRuntime ?? this.maxRuntime,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      languages: languages ?? this.languages,
    );
  }
}

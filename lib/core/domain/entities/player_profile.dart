class PlayerProfile {
  final String deviceId;
  final String name;
  final String? avatar;
  final bool isHost;
  final List<String>? genres;

  PlayerProfile({
    required this.deviceId,
    required this.name,
    this.avatar,
    required this.isHost,
    this.genres,
  });

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      deviceId: map['deviceId'] as String,
      name: map['name'] as String? ?? 'Guest',
      avatar: map['avatar'] as String?,
      isHost: map['isHost'] as bool? ?? false,
      genres: map['genres'] != null ? List<String>.from(map['genres']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'name': name,
      'avatar': avatar,
      'isHost': isHost,
      'genres': genres,
    };
  }

  PlayerProfile copyWith({
    String? deviceId,
    String? name,
    String? avatar,
    bool? isHost,
    List<String>? genres,
  }) {
    return PlayerProfile(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isHost: isHost ?? this.isHost,
      genres: genres ?? this.genres,
    );
  }
}

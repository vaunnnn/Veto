import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veto/core/domain/entities/player_profile.dart';
import 'package:veto/core/domain/entities/filter_settings.dart';

enum RoomStatus { waiting, swiping, voting, matchFound, finished }

extension RoomStatusExtension on RoomStatus {
  String get value {
    switch (this) {
      case RoomStatus.waiting:
        return 'waiting';
      case RoomStatus.swiping:
        return 'swiping';
      case RoomStatus.voting:
        return 'voting';
      case RoomStatus.matchFound:
        return 'matchFound';
      case RoomStatus.finished:
        return 'finished';
    }
  }

  static RoomStatus fromString(String value) {
    switch (value) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'swiping':
        return RoomStatus.swiping;
      case 'voting':
        return RoomStatus.voting;
      case 'matchFound':
        return RoomStatus.matchFound;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }
}

class Room {
  final String code;
  final String hostId;
  final RoomStatus status;
  final List<String> connectedPlayers;
  final Map<String, PlayerProfile> playerProfiles;
  final FilterSettings filterSettings;
  final Timestamp expiresAt;
  final Map<String, dynamic>? latestMatch;
  final List<Map<String, dynamic>> matchedMovies;

  Room({
    required this.code,
    required this.hostId,
    required this.status,
    required this.connectedPlayers,
    required this.playerProfiles,
    required this.filterSettings,
    required this.expiresAt,
    this.latestMatch,
    required this.matchedMovies,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      code: doc.id,
      hostId: data['hostId'] as String,
      status: RoomStatusExtension.fromString(
        data['status'] as String? ?? 'waiting',
      ),
      connectedPlayers: List<String>.from(data['connectedPlayers'] ?? []),
      playerProfiles: (data['playerProfiles'] as Map<String, dynamic>? ?? {})
          .map(
            (key, value) => MapEntry(
              key,
              PlayerProfile.fromMap(value as Map<String, dynamic>),
            ),
          ),
      filterSettings: FilterSettings.fromMap(
        data['filterSettings'] as Map<String, dynamic>? ?? {},
      ),
      expiresAt: data['expiresAt'] as Timestamp,
      latestMatch: data['latestMatch'] as Map<String, dynamic>?,
      matchedMovies: List<Map<String, dynamic>>.from(
        data['matchedMovies'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'status': status.value,
      'connectedPlayers': connectedPlayers,
      'playerProfiles': playerProfiles.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'filterSettings': filterSettings.toMap(),
      'expiresAt': expiresAt,
      'latestMatch': latestMatch,
      'matchedMovies': matchedMovies,
    };
  }

  Room copyWith({
    String? code,
    String? hostId,
    RoomStatus? status,
    List<String>? connectedPlayers,
    Map<String, PlayerProfile>? playerProfiles,
    FilterSettings? filterSettings,
    Timestamp? expiresAt,
    Map<String, dynamic>? latestMatch,
    List<Map<String, dynamic>>? matchedMovies,
  }) {
    return Room(
      code: code ?? this.code,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      connectedPlayers: connectedPlayers ?? this.connectedPlayers,
      playerProfiles: playerProfiles ?? this.playerProfiles,
      filterSettings: filterSettings ?? this.filterSettings,
      expiresAt: expiresAt ?? this.expiresAt,
      latestMatch: latestMatch ?? this.latestMatch,
      matchedMovies: matchedMovies ?? this.matchedMovies,
    );
  }
}

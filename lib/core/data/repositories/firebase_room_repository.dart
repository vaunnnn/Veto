import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:veto/core/domain/entities/room.dart';
import 'package:veto/core/domain/repositories/room_repository.dart';

class FirebaseRoomRepository implements RoomRepository {
  final FirebaseFirestore _firestore;

  FirebaseRoomRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  void _validateRoomCode(String roomCode) {
    if (!roomCode.startsWith('VETO-') || roomCode.length != 9) {
      throw ArgumentError('Invalid room code format');
    }
    final suffix = roomCode.substring(5);
    if (!suffix.contains(RegExp(r'^[A-Z0-9]{4}$'))) {
      throw ArgumentError('Room code suffix must be 4 alphanumeric characters');
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final code = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return 'VETO-$code';
  }

  Future<void> _deleteVotesSubcollection(String roomCode) async {
    try {
      final votesRef = _firestore
          .collection('rooms')
          .doc(roomCode)
          .collection('votes');
      
      final snapshot = await votesRef.get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Failed to delete votes subcollection for room $roomCode: $e");
      // Silently fail - room deletion should proceed anyway
    }
  }

  @override
  Future<String> createRoom(String hostDeviceId) async {
    final String roomCode = _generateRoomCode();

    // Clean up expired rooms
    try {
      final expiredRooms = await _firestore
          .collection('rooms')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      for (var doc in expiredRooms.docs) {
        await doc.reference.delete();
      }

      if (expiredRooms.docs.isNotEmpty) {
        debugPrint("Cleaned up ${expiredRooms.docs.length} dead rooms!");
      }
    } catch (e) {
      debugPrint("Garbage collector skipped");
    }

    // Create new room
    await _firestore.collection('rooms').doc(roomCode).set({
      'hostId': hostDeviceId,
      'status': 'waiting',
      'connectedPlayers': [hostDeviceId],
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 60)),
      ),
      'filterSettings': {
        'minYear': 1970,
        'maxYear': DateTime.now().year,
        'minScore': 6.0,
        'maxRuntime': 'Any Length',
        'familyFriendly': false,
        'languages': [],
      },
    });

    return roomCode;
  }

  @override
  Future<bool> joinRoom(String roomCode, String playerDeviceId) async {
    _validateRoomCode(roomCode);
    if (playerDeviceId.isEmpty) {
      throw ArgumentError('playerDeviceId cannot be empty');
    }
    final roomRef = _firestore.collection('rooms').doc(roomCode);
    final snapshot = await roomRef.get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;

      if (data['status'] != 'waiting') {
        return false;
      }

      await roomRef.update({
        'connectedPlayers': FieldValue.arrayUnion([playerDeviceId]),
      });
      return true;
    }

    return false;
  }

  @override
  Stream<Room?> watchRoom(String roomCode) {
    _validateRoomCode(roomCode);
    return _firestore.collection('rooms').doc(roomCode).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return Room.fromFirestore(snapshot);
      }
      return null;
    });
  }

  @override
  Future<void> updateRoomStatus(String roomCode, String status) async {
    _validateRoomCode(roomCode);
    await _firestore.collection('rooms').doc(roomCode).update({
      'status': status,
    });
  }

  @override
  Future<void> updatePlayerProfile(
    String roomCode,
    String playerDeviceId,
    Map<String, dynamic> profile,
  ) async {
    _validateRoomCode(roomCode);
    if (playerDeviceId.isEmpty) {
      throw ArgumentError('playerDeviceId cannot be empty');
    }
    final Map<String, dynamic> updates = {};
    for (final entry in profile.entries) {
      updates['playerProfiles.$playerDeviceId.${entry.key}'] = entry.value;
    }
    await _firestore.collection('rooms').doc(roomCode).update(updates);
  }

  @override
  Future<void> updateFilterSettings(
    String roomCode,
    Map<String, dynamic> settings,
  ) async {
    _validateRoomCode(roomCode);
    await _firestore.collection('rooms').doc(roomCode).update({
      'filterSettings': settings,
    });
  }

  @override
  Future<void> leaveRoom(String roomCode, String playerDeviceId) async {
    _validateRoomCode(roomCode);
    if (playerDeviceId.isEmpty) {
      throw ArgumentError('playerDeviceId cannot be empty');
    }
    final roomRef = _firestore.collection('rooms').doc(roomCode);

    await roomRef.update({
      'connectedPlayers': FieldValue.arrayRemove([playerDeviceId]),
      'playerProfiles.$playerDeviceId': FieldValue.delete(),
    });

    // Check if room is empty and delete if needed
    final snapshot = await roomRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final connectedPlayers = List.from(data['connectedPlayers'] ?? []);
      if (connectedPlayers.isEmpty) {
        await _deleteVotesSubcollection(roomCode);
        await roomRef.delete();
      }
    }
  }

  @override
  Future<void> deleteRoom(String roomCode) async {
    _validateRoomCode(roomCode);
    await _deleteVotesSubcollection(roomCode);
    await _firestore.collection('rooms').doc(roomCode).delete();
  }

  @override
  Future<void> clearMatch(String roomCode) async {
    _validateRoomCode(roomCode);
    await _firestore.collection('rooms').doc(roomCode).update({
      'latestMatch': FieldValue.delete(),
    });
  }
}


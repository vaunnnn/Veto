import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class RoomService {
  // The 'get' keyword waits until the absolute last second to connect
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- 1. GENERATE A PAIRING CODE ---
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    // Generates a random 4-character string (e.g., "A7X9")
    final code = String.fromCharCodes(
      Iterable.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return 'VETO-$code';
  }

  // --- 2. THE "CREATE" FLOW ---
  Future<String> createRoom(String hostDeviceId) async {
    final String roomCode = _generateRoomCode();

    // --- 🧹 THE SNEAKY GARBAGE COLLECTOR ---
    try {
      // 1. Find all rooms where the 'expiresAt' time is in the past
      final expiredRooms = await FirebaseFirestore.instance
          .collection('rooms')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      // 2. Delete them silently in the background
      for (var doc in expiredRooms.docs) {
        await doc.reference.delete();
      }

      if (expiredRooms.docs.isNotEmpty) {
        debugPrint("Cleaned up ${expiredRooms.docs.length} dead rooms!");
      }
    } catch (e) {
      // If it fails, who cares? We just want them to get into their new room!
       debugPrint("Garbage collector skipped");
    }
    // ----------------------------------------

    // --- ✨ CREATE THE NEW ROOM ---
    await FirebaseFirestore.instance.collection('rooms').doc(roomCode).set({
      'hostId': hostDeviceId,
      'status': 'waiting',
      'connectedPlayers': [hostDeviceId],
      // Set this room to officially "expire" 60 minutes from right now
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 60)),
      ),

      // NEW: Default Filter Settings so the room has a baseline!
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

  // --- 3. THE "JOIN" FLOW ---
  Future<bool> joinRoom(String roomCode, String playerDeviceId) async {
    // Point directly to the room the user typed in
    final roomRef = _db.collection('rooms').doc(roomCode);

    // Check if it exists
    final snapshot = await roomRef.get();

    if (snapshot.exists) {
      // NEW: Read the room's data to check the status
      final data = snapshot.data() as Map<String, dynamic>;

      // NEW: If the game has already started, reject the join request!
      if (data['status'] != 'waiting') {
        return false;
      }

      // If it exists AND is still 'waiting', let them in!
      await roomRef.update({
        'connectedPlayers': FieldValue.arrayUnion([playerDeviceId]),
      });
      return true; // Join successful
    } else {
      return false; // Room code is invalid
    }
  }
}

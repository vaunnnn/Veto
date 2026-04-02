import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class RoomService {
  // The 'get' keyword waits until the absolute last second to connect
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // --- 1. GENERATE A PAIRING CODE ---
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    // Generates a random 4-character string (e.g., "A7X9")
    final code = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return 'VETO-$code'; 
  }

  // --- 2. THE "CREATE" FLOW ---
  Future<String> createRoom(String hostDeviceId) async {
    final String roomCode = _generateRoomCode();

    // Create a new document in the 'rooms' collection
    await _db.collection('rooms').doc(roomCode).set({
      'hostId': hostDeviceId,
      'status': 'waiting', // The room is open but the game hasn't started
      'connectedPlayers': [hostDeviceId], // Host is the first player
      'createdAt': FieldValue.serverTimestamp(), // Good for cleaning up old rooms later
    });

    return roomCode; // Return the code so the UI can display it
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
        'connectedPlayers': FieldValue.arrayUnion([playerDeviceId])
      });
      return true; // Join successful
    } else {
      return false; // Room code is invalid
    }
  }
}
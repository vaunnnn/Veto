// Example for join_room_screen.dart
import 'package:flutter/material.dart';

class JoinRoomScreen extends StatelessWidget {
  const JoinRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Room")),
      body: const Center(child: Text("Welcome to Join Room")),
    );
  }
}
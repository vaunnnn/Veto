import 'package:flutter/material.dart';
import 'waiting_room_screen.dart';
import '../services/room_service.dart'; // Import the service

// Change to StatefulWidget so we can handle the text input and loading state
class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  final RoomService _roomService = RoomService();
  bool _isLoading = false;

  // Dummy device ID for testing
  final String myDeviceId = "device_${DateTime.now().millisecondsSinceEpoch}";

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    bool success = await _roomService.joinRoom(code, myDeviceId);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingRoomScreen(roomCode: code),
        ),
      );
    } else if (mounted) {
      // Show an error if the room code is wrong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Room Code. Try again!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        // ... (Keep your existing beautiful AppBar code here)
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // ... (Keep your existing header text here)
                    const SizedBox(height: 40),

                    Container(
                      // ... (Keep your existing Container decoration here)
                      child: Column(
                        children: [
                          // ... (Keep your "ACCESS CODE" label)
                          
                          // Update the TextField to use the controller
                          TextField(
                            controller: _codeController, // Added this!
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                              color: colorScheme.primary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'VETO-XXXX',
                              // ... (Keep your existing decoration)
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Update the Join Room Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleJoin,
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('JOIN ROOM'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ... (Keep your existing footer text)
          ],
        ),
      ),
    );
  }
}
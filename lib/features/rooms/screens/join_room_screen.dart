import 'package:flutter/material.dart';
import 'waiting_room_screen.dart';
import '../services/room_service.dart';

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
          builder: (context) => WaitingRoomScreen(
            roomCode: code,
            playerDeviceId: myDeviceId, // <-- Add this!
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Room Code. Try again!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We use a light background to match the mockup
    final Color bgColor = theme.brightness == Brightness.light
        ? const Color(0xFFF8F9FA)
        : colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      // This allows the gradient to flow behind the AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true, // Forces the Row to center
        title: Row(
          mainAxisSize: MainAxisSize.min, // Shrink-wraps the icon and text together
          children: [
            Image.asset(
              'assets/images/veto-logo.png',
              height: 32,
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          // Subtle top gradient matching the mockup
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // 1. INCREASED SPACING: Lowers the content into a more comfortable "thumb zone"
                        const SizedBox(height: 50),

                        // Header Section
                        const SizedBox(height: 12),
                        Text(
                          'Grab a Seat\n with Your Friends.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Input your friend\'s invite code to join the vetoing session.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Input Card Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? Colors.white
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ACCESS CODE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Text Field
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFFF4F4F5)
                                      : colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _codeController,
                                  textAlign: TextAlign.center,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.0,
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'V E T O - X X X X',
                                    hintStyle: TextStyle(
                                      // 2. DYNAMIC COLOR: Adapts visibility based on Light/Dark Mode
                                      color: theme.brightness == Brightness.light
                                          ? colorScheme.primary.withValues(alpha: 0.2)
                                          : colorScheme.onSurface.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                      fontSize: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Join Room Button
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleJoin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text(
                                          'JOIN ROOM',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Footer Text
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                  child: Text(
                    'Lost your code? Contact the host of your session.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

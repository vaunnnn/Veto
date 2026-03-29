import 'package:flutter/material.dart';
import 'waiting_room_screen.dart';

class JoinRoomScreen extends StatelessWidget {
  const JoinRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We grab the theme data once to keep the code below clean
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // backgroundColor is handled automatically by AppTheme!
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          // colorScheme.onSurface adapts automatically to Light/Dark mode
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface), 
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'VETO',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary, // Grabs AppColors.primary (Red)
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    
                    // Header Section
                    Text(
                      'PREMIUM ACCESS',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        // FIXED: Replaced withOpacity with withValues
                        color: colorScheme.onSurface.withValues(alpha: 0.5), 
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the\nSilver Screen',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Input your unique invite code to join the synchronized cinematic session.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          // FIXED: Replaced withOpacity with withValues
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Input Card Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface, // Uses surfaceLight or surfaceDark automatically!
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            // FIXED: Replaced withOpacity with withValues
                            color: Colors.black.withValues(
                                alpha: theme.brightness == Brightness.light ? 0.04 : 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ACCESS CODE',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              // FIXED: Replaced withOpacity with withValues
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Text Field
                          TextField(
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                              color: colorScheme.primary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'V E T O - X X X X',
                              hintStyle: textTheme.titleLarge?.copyWith(
                                // FIXED: Replaced withOpacity with withValues
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Join Room Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WaitingRoomScreen(),
                                  ),
                                );
                              },
                              child: const Text('JOIN ROOM'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer Text
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
              child: Text(
                'Lost your code? Contact the host of your session.',
                style: textTheme.bodySmall?.copyWith(
                  // FIXED: Replaced withOpacity with withValues
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
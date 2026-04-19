import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String status;
  final bool isYou;
  final bool isHostView;
  final String targetDeviceId;
  final String roomCode;
  final ColorScheme colorScheme;
  final Brightness brightness;
  final VoidCallback onEditProfile;
  final VoidCallback onKick;

  const PlayerCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.status,
    required this.isYou,
    required this.isHostView,
    required this.targetDeviceId,
    required this.roomCode,
    required this.colorScheme,
    required this.brightness,
    required this.onEditProfile,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),

                  // THE NEW KICK BUTTON
                  if (isHostView && !isYou)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onKick,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_remove_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                  if (isYou)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (isYou)
              Text(
                'DISPLAY NAME',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
            if (!isYou) const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isYou)
                  GestureDetector(
                    onTap: onEditProfile,
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
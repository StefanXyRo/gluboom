// FILE: lib/features/5_stories/presentation/widgets/story_circle_widget.dart
// VERSIUNE COMPLETĂ: Cu indicator vizual pentru starea de "Live".

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class StoryCircle extends StatelessWidget {
  final String? profileImageUrl;
  final String username;
  final VoidCallback onTap;
  final bool hasActiveStory;
  final bool isCurrentUser;
  final bool isLive; // ADAUGAT: Parametru pentru starea de live

  const StoryCircle({
    super.key,
    required this.profileImageUrl,
    required this.username,
    required this.onTap,
    this.hasActiveStory = true,
    this.isCurrentUser = false,
    this.isLive = false, // Valoare default
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            SizedBox(
              height: 68,
              width: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Indicatorul de Live are prioritate
                      border: isLive ? Border.all(color: Colors.red, width: 3) : null,
                      gradient: hasActiveStory && !isCurrentUser && !isLive
                          ? const LinearGradient(
                              colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976), Color(0xFF962FBF), Color(0xFF4F5BD5)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            )
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                      child: profileImageUrl == null ? const Icon(Iconsax.user, size: 30, color: Colors.grey) : null,
                    ),
                  ),
                  if (isCurrentUser && !isLive)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  // Badge-ul "LIVE"
                  if (isLive)
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1.5)
                        ),
                        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(
                username,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

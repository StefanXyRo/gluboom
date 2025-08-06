// FILE: lib/features/2_profile/presentation/widgets/profile_stat_widget.dart
// Înlocuiește conținutul fișierului existent cu acest cod.

import 'package:flutter/material.dart';

class ProfileStatWidget extends StatelessWidget {
  final int count;
  final String label;
  // ADAUGAT: Parametru pentru a face widget-ul interactiv
  final VoidCallback? onTap;

  const ProfileStatWidget({
    super.key,
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

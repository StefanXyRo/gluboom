// FILE: lib/features/2_profile/presentation/widgets/reel_grid_tile.dart
// Creează acest fișier nou în locația specificată.

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/reel_model.dart';

class ReelGridTile extends StatelessWidget {
  final ReelModel reel;
  const ReelGridTile({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navighează la vizualizarea individuală a Reel-ului
      },
      child: Container(
        decoration: BoxDecoration(
          // Momentan folosim un placeholder. Pe viitor, putem stoca un thumbnail.
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: Icon(
            Iconsax.video_play,
            color: Colors.grey,
            size: 40,
          ),
        ),
      ),
    );
  }
}

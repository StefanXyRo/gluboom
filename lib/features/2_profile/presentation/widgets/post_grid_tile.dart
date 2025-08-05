// FILE: lib/features/2_profile/presentation/widgets/post_grid_tile.dart
// Creează acest fișier nou în locația specificată.

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/post_model.dart';

class PostGridTile extends StatelessWidget {
  final PostModel post;
  const PostGridTile({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navighează la vizualizarea individuală a postării
      },
      child: Container(
        decoration: BoxDecoration(
          image: post.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(post.imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: Colors.grey.shade200,
        ),
        // Dacă postarea nu are imagine, afișăm un placeholder
        child: post.imageUrl == null
            ? const Center(child: Icon(Iconsax.document_text, color: Colors.grey))
            : null,
      ),
    );
  }
}

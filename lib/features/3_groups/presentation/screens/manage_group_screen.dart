import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'pending_posts_screen.dart';

class ManageGroupScreen extends StatelessWidget {
  final String groupId;
  const ManageGroupScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrare Grup'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Iconsax.document_text),
            title: const Text('Postări în așteptare'),
            subtitle: const Text('Aprobă sau respinge postările membrilor.'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PendingPostsScreen(groupId: groupId),
                ),
              );
            },
          ),
          // Aici pot fi adăugate și alte opțiuni de administrare
        ],
      ),
    );
  }
}

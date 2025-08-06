import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/post_model.dart';
import '../../../4_feed/presentation/widgets/post_card_widget.dart';

class PendingPostsScreen extends StatelessWidget {
  final String groupId;
  const PendingPostsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postări în așteptare'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('groupId', isEqualTo: groupId)
            .where('isApproved', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nicio postare în așteptare.'));
          }
          final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    PostCard(post: post),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('posts').doc(post.id).update({'isApproved': true});
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Aprobă'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Respinge'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

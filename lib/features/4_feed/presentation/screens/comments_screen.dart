// FILE: lib/features/4_feed/presentation/screens/comments_screen.dart
// Creează acest fișier nou în locația specificată.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../data/models/comment_model.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _currentUser == null) {
      return;
    }

    final userData = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    final username = userData.data()?['username'] ?? 'Utilizator';
    final photoUrl = userData.data()?['photoUrl'];

    // Adăugăm comentariul în sub-colecția 'comments' a postării
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'authorId': _currentUser!.uid,
      'text': _commentController.text.trim(),
      'createdAt': Timestamp.now(),
      'authorUsername': username,
      'authorPhotoUrl': photoUrl,
    });

    // Incrementăm contorul de comentarii al postării
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'commentCount': FieldValue.increment(1)});

    _commentController.clear();
    FocusScope.of(context).unfocus(); // Ascunde tastatura
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarii'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Fii primul care comentează!'));
                }

                final comments = snapshot.data!.docs
                    .map((doc) => CommentModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.authorPhotoUrl != null
                            ? NetworkImage(comment.authorPhotoUrl!)
                            : null,
                        child: comment.authorPhotoUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(comment.authorUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.text),
                    );
                  },
                );
              },
            ),
          ),
          // Câmpul de introducere a comentariului
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Adaugă un comentariu...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

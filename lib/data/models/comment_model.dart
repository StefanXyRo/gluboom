// FILE: lib/data/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorId;
  final String text;
  final Timestamp createdAt;
  final String authorUsername;
  final String? authorPhotoUrl;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    required this.authorUsername,
    this.authorPhotoUrl,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      authorUsername: data['authorUsername'] ?? 'Utilizator',
      authorPhotoUrl: data['authorPhotoUrl'],
    );
  }
}

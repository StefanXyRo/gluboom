// FILE: lib/data/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final Timestamp createdAt;
  final String groupId;
  final bool isPublicPost; // Nou
  final List<String> likes;
  final int commentCount;
  final String authorUsername;
  final String? authorPhotoUrl;

  PostModel({
    required this.id,
    required this.authorId,
    required this.text,
    this.imageUrl,
    required this.likeCount,
    required this.createdAt,
    required this.groupId,
    required this.isPublicPost,
    required this.likes,
    required this.commentCount,
    required this.authorUsername,
    this.authorPhotoUrl,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      likeCount: data['likeCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      groupId: data['groupId'] ?? '',
      isPublicPost: data['isPublicPost'] ?? false,
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      authorUsername: data['authorUsername'] ?? 'Utilizator',
      authorPhotoUrl: data['authorPhotoUrl'],
    );
  }
}
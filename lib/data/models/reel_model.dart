// FILE: lib/data/models/reel_model.dart
// Înlocuiește conținutul fișierului existent cu acest cod.

import 'package:cloud_firestore/cloud_firestore.dart';

class ReelModel {
  final String id;
  final String groupId; // MODIFICAT: De la authorId la groupId
  final String videoUrl;
  final String caption;
  final int likeCount;
  final int commentCount;
  final Timestamp createdAt;
  final List<String> likes;

  // MODIFICAT: Am înlocuit datele autorului cu cele ale grupului
  final String groupName;
  final String? groupPhotoUrl;

  ReelModel({
    required this.id,
    required this.groupId,
    required this.videoUrl,
    required this.caption,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.likes,
    required this.groupName,
    this.groupPhotoUrl,
  });

  factory ReelModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final likesFromDb = data['likes'] as List<dynamic>?;

    return ReelModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      caption: data['caption'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likes: likesFromDb?.map((e) => e as String).toList() ?? [],
      groupName: data['groupName'] ?? 'Grup',
      groupPhotoUrl: data['groupPhotoUrl'],
    );
  }
}

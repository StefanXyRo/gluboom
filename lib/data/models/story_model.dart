import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String groupId;
  final String mediaUrl;
  final String mediaType; // Corectat: Câmpul a fost readăugat
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final String groupName;
  final String? groupPhotoUrl;

  StoryModel({
    required this.id,
    required this.groupId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    required this.groupName,
    this.groupPhotoUrl,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      groupName: data['groupName'] ?? 'Grup',
      groupPhotoUrl: data['groupPhotoUrl'],
    );
  }
}
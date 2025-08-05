// FILE: lib/data/models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> admins;
  final String profileImageUrl;
  final int memberCount;
  final Timestamp createdAt;
  final bool isPublic;
  final bool requiresApproval;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.admins,
    required this.profileImageUrl,
    required this.memberCount,
    required this.createdAt,
    required this.isPublic,
    required this.requiresApproval,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      admins: List<String>.from(data['admins'] ?? []),
      profileImageUrl: data['profileImageUrl'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isPublic: data['isPublic'] ?? true,
      requiresApproval: data['requiresApproval'] ?? false,
    );
  }
}

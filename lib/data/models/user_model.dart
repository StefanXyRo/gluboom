// FILE: lib/data/models/user_model.dart
// Înlocuiește conținutul fișierului existent cu acest cod.

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final String bio;
  final int points;
  final int followerCount;
  final int followingCount;
  
  // ADAUGAT: Câmp pentru starea de live
  final bool isLive;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.bio,
    required this.points,
    required this.followerCount,
    required this.followingCount,
    required this.isLive,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'] ?? '',
      points: data['points'] ?? 0,
      followerCount: data['followerCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      isLive: data['isLive'] ?? false,
    );
  }
}

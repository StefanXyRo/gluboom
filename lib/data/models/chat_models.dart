// FILE: lib/data/models/chat_models.dart
// Poți adăuga ambele clase în același fișier sau în fișiere separate.

import 'package:cloud_firestore/cloud_firestore.dart';

// Model pentru un singur mesaj
class MessageModel {
  final String senderId;
  final String text;
  final Timestamp timestamp;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

// Model pentru o conversație (un chat)
class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantUsernames;
  final Map<String, String?> participantPhotoUrls;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantUsernames,
    required this.participantPhotoUrls,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantUsernames: Map<String, String>.from(data['participantUsernames'] ?? {}),
      participantPhotoUrls: Map<String, String?>.from(data['participantPhotoUrls'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }
}

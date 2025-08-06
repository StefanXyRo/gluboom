// FILE: lib/data/models/event_model.dart
// Creează acest fișier nou în locația specificată.

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String groupId;
  final String creatorId;
  final String title;
  final String description;
  final Timestamp eventDate;
  final String location;
  final List<String> attendees;

  EventModel({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.attendees,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: data['eventDate'] ?? Timestamp.now(),
      location: data['location'] ?? 'Online',
      attendees: List<String>.from(data['attendees'] ?? []),
    );
  }
}

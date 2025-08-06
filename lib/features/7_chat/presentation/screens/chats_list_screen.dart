// FILE: lib/features/7_chat/presentation/screens/chats_list_screen.dart
// Creează acest fișier nou în structura de foldere corespunzătoare.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/chat_models.dart';
import '../../../../data/models/user_model.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Te rog să te autentifici.")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Mesaje', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Căutăm toate chat-urile în care utilizatorul curent este participant
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nicio conversație începută.'));
          }

          final chats = snapshot.data!.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Găsim ID-ul celuilalt participant pentru a afișa numele și poza corectă
              final otherUserId = chat.participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
              final otherUsername = chat.participantUsernames[otherUserId] ?? 'Utilizator';
              final otherPhotoUrl = chat.participantPhotoUrls[otherUserId];

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: otherPhotoUrl != null ? NetworkImage(otherPhotoUrl) : null,
                  child: otherPhotoUrl == null ? const Icon(Iconsax.user) : null,
                ),
                title: Text(otherUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  // La apăsare, deschidem ecranul de chat
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chat.id,
                      otherUserId: otherUserId,
                      otherUsername: otherUsername,
                      otherUserPhotoUrl: otherPhotoUrl,
                    )
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// FILE: lib/features/2_profile/presentation/screens/followers_following_screen.dart
// Creează acest fișier nou în locația specificată.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/user_model.dart';
import '../widgets/user_list_tile.dart';

enum FollowListType { followers, following }

class FollowersFollowingScreen extends StatelessWidget {
  final String userId;
  final FollowListType listType;

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.listType,
  });

  String get _title => listType == FollowListType.followers ? 'Urmăritori' : 'Urmăriri';
  String get _collectionName => listType == FollowListType.followers ? 'followers' : 'following';

  // Funcție care încarcă datele utilizatorilor pe baza ID-urilor
  Future<List<UserModel>> _fetchUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    final userDocs = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
        
    return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(_title, style: const TextStyle(color: Colors.black)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Citim lista de ID-uri din sub-colecția corespunzătoare
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(_collectionName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Niciun utilizator în această listă.'));
          }

          // Extragem ID-urile
          final userIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          // Folosim un FutureBuilder pentru a încărca detaliile utilizatorilor
          return FutureBuilder<List<UserModel>>(
            future: _fetchUsers(userIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                return const Center(child: Text('Nu s-au putut încărca utilizatorii.'));
              }

              final users = userSnapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return UserListTile(user: users[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

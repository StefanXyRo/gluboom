// FILE: lib/features/2_profile/presentation/screens/user_profile_screen.dart
// VERSIUNE FINALĂ: Afișează lista de grupuri publice ale utilizatorului.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../7_chat/presentation/screens/chat_screen.dart';
import '../widgets/profile_stat_widget.dart';
import 'edit_profile_screen.dart';
import '../../../3_groups/presentation/widgets/group_card_widget.dart';
import '../../../3_groups/presentation/screens/group_details_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  bool _isFollowing = false;
  bool _isLoadingFollow = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    if (_currentUser == null) {
      setState(() => _isLoadingFollow = false);
      return;
    }
    final followingDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('following')
        .doc(widget.userId)
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = followingDoc.exists;
        _isLoadingFollow = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUser == null) return;
    setState(() => _isLoadingFollow = true);

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    final otherUserRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final newIsFollowing = !_isFollowing;

    final batch = FirebaseFirestore.instance.batch();

    if (newIsFollowing) {
      batch.set(currentUserRef.collection('following').doc(widget.userId), {});
      batch.set(otherUserRef.collection('followers').doc(_currentUser!.uid), {});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
      batch.update(otherUserRef, {'followerCount': FieldValue.increment(1)});
    } else {
      batch.delete(currentUserRef.collection('following').doc(widget.userId));
      batch.delete(otherUserRef.collection('followers').doc(_currentUser!.uid));
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
      batch.update(otherUserRef, {'followerCount': FieldValue.increment(-1)});
    }

    await batch.commit();

    if (mounted) {
      setState(() {
        _isFollowing = newIsFollowing;
        _isLoadingFollow = false;
      });
    }
  }

  Future<void> _startChat(UserModel otherUser) async {
    if (_currentUser == null) return;

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    
    final chatParticipants = [_currentUser!.uid, widget.userId]..sort();
    final chatId = chatParticipants.join('_');

    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    
    if (!(await chatDoc.get()).exists) {
      final currentUserData = await currentUserRef.get();
      
      await chatDoc.set({
        'participants': chatParticipants,
        'participantUsernames': {
          _currentUser!.uid: currentUserData['username'],
          widget.userId: otherUser.username,
        },
        'participantPhotoUrls': {
          _currentUser!.uid: currentUserData['photoUrl'],
          widget.userId: otherUser.photoUrl,
        },
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatId: chatId,
        otherUserId: widget.userId,
        otherUsername: otherUser.username,
        otherUserPhotoUrl: otherUser.photoUrl,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final username = snapshot.data!['username'] ?? '';
            return Text(username, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = UserModel.fromFirestore(snapshot.data!);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                _buildGroupsList(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .where('members', arrayContains: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ProfileStatWidget(count: 0, label: 'Grupuri');
                        }
                        final count = snapshot.data?.docs.length ?? 0;
                        return ProfileStatWidget(count: count, label: 'Grupuri');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(user.bio.isNotEmpty ? user.bio : 'Fără biografie.'),
          const SizedBox(height: 16),
          if (widget.userId != _currentUser?.uid)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoadingFollow ? null : _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.grey.shade200 : Colors.blue,
                      foregroundColor: _isFollowing ? Colors.black : Colors.white,
                    ),
                    child: Text(_isFollowing ? 'Urmărești' : 'Urmărește'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _startChat(user),
                    child: const Text('Mesaj'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: user))),
                child: const Text('Editează Profilul'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grupuri Publice',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .where('members', arrayContains: user.uid)
                .where('isPublic', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('Acest utilizator nu este membru în niciun grup public.'),
                  ),
                );
              }
              final groups = snapshot.data!.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(group.profileImageUrl),
                      ),
                      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${group.memberCount} membri'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailsScreen(group: group),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

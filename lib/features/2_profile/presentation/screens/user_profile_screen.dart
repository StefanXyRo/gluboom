// FILE: lib/features/2_profile/presentation/screens/user_profile_screen.dart
// VERSIUNE COMPLETĂ: Cu logică de follow și grid-uri funcționale.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/models/reel_model.dart';
import '../../../7_chat/presentation/screens/chat_screen.dart';
import '../widgets/profile_stat_widget.dart';
import '../widgets/post_grid_tile.dart';
import '../widgets/reel_grid_tile.dart';
import 'followers_following_screen.dart';
import 'edit_profile_screen.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                    }
                    final user = UserModel.fromFirestore(snapshot.data!);
                    return _buildProfileHeader(user);
                  },
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildPostsGrid(),
              _buildReelsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      stream: FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: user.uid).snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return ProfileStatWidget(count: count, label: 'Postări');
                      }
                    ),
                    ProfileStatWidget(
                      count: user.followerCount, 
                      label: 'Urmăritori',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FollowersFollowingScreen(userId: user.uid, listType: FollowListType.followers))),
                    ),
                    ProfileStatWidget(
                      count: user.followingCount, 
                      label: 'Urmăriri',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FollowersFollowingScreen(userId: user.uid, listType: FollowListType.following))),
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
          ),
          const SizedBox(height: 16),
          const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Iconsax.grid_3)),
              Tab(icon: Icon(Iconsax.video_play)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nicio postare.'));
        }
        final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) => PostGridTile(post: posts[index]),
        );
      },
    );
  }

  Widget _buildReelsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reels')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Niciun Reel.'));
        }
        final reels = snapshot.data!.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();
        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) => ReelGridTile(reel: reels[index]),
        );
      },
    );
  }
}

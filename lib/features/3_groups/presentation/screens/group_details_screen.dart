// FILE: lib/features/3_groups/presentation/screens/group_details_screen.dart
// VERSIUNE COMPLETĂ: Cu upload specific pe tab-uri.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../4_feed/presentation/screens/create_post_screen.dart';
import '../../../6_reels/presentation/screens/create_reel_screen.dart';
import 'create_event_screen.dart';
import '../../../4_feed/presentation/widgets/post_card_widget.dart';
import 'manage_group_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final group = GroupModel.fromFirestore(groupSnapshot.data!);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(_currentUser?.uid).collection('groups').doc(widget.groupId).snapshots(),
          builder: (context, membershipSnapshot) {
            final isMember = membershipSnapshot.hasData && membershipSnapshot.data!.exists;
            final isAdmin = group.admins.contains(_currentUser?.uid);

            return Scaffold(
              backgroundColor: Colors.white,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 250.0,
                      pinned: true,
                      backgroundColor: Colors.white,
                      elevation: 1,
                      iconTheme: const IconThemeData(color: Colors.white),
                      actions: [
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Iconsax.setting_2, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ManageGroupScreen(groupId: widget.groupId),
                                  ));
                            },
                          )
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        centerTitle: false,
                        titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
                        background: Image.network(group.profileImageUrl, fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildGroupHeader(group, isMember, isAdmin),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupPosts(group, isMember),
                    const Center(child: Text('Reels-urile grupului vor apărea aici.')),
                    const Center(child: Text('Evenimentele grupului vor apărea aici.')),
                  ],
                ),
              ),
              floatingActionButton: _buildFloatingActionButton(group, isMember, isAdmin),
            );
          },
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(GroupModel group, bool isMember, bool isAdmin) {
    if (!isMember) return null;

    return FloatingActionButton(
      onPressed: () {
        if (_tabController == null) return;
        switch (_tabController!.index) {
          case 0:
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(initialGroup: group)));
            break;
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateReelScreen()));
            break;
          case 2:
            if (isAdmin) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventScreen(groupId: group.id)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doar administratorii pot crea evenimente.')));
            }
            break;
        }
      },
      backgroundColor: Colors.deepPurple,
      child: const Icon(Iconsax.add, color: Colors.white),
    );
  }

  void _joinGroup(GroupModel group) async {
    if (_currentUser == null) return;
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(group.id);
    final userGroupRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('groups').doc(group.id);

    if (group.requiresApproval) {
      await groupRef.collection('joinRequests').doc(_currentUser!.uid).set({'requestedAt': Timestamp.now()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cererea de înscriere a fost trimisă.')));
    } else {
      await groupRef.update({'members': FieldValue.arrayUnion([_currentUser!.uid]), 'memberCount': FieldValue.increment(1)});
      await userGroupRef.set({'joinedAt': Timestamp.now()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te-ai alăturat grupului!')));
    }
  }

  void _leaveGroup(GroupModel group) async {
    if (_currentUser == null) return;
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(group.id);
    final userGroupRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('groups').doc(group.id);

    await groupRef.update({'members': FieldValue.arrayRemove([_currentUser!.uid]), 'memberCount': FieldValue.increment(-1)});
    await userGroupRef.delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ai părăsit grupul.')));
  }

  Widget _buildGroupHeader(GroupModel group, bool isMember, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 12),
          Text(group.description, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 16),
          if (!isMember)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinGroup(group),
                child: const Text('Alătură-te Grupului'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _leaveGroup(group),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Părăsește Grupul'),
              ),
            ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: 'Postări'), Tab(text: 'Reels'), Tab(text: 'Evenimente')],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupPosts(GroupModel group, bool isMember) {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('groupId', isEqualTo: group.id)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (!isMember) {
      query = query.where('isPublicPost', isEqualTo: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Nicio postare în acest grup.'));
        final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}

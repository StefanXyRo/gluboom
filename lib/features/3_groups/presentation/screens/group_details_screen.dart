// FILE: lib/features/3_groups/presentation/screens/group_details_screen.dart
// VERSIUNE COMPLETĂ: Cu importul lipsă adăugat.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/post_model.dart';
import '../../../4_feed/presentation/screens/create_post_screen.dart';
import '../../../4_feed/presentation/widgets/post_card_widget.dart';
import '../../../2_profile/presentation/widgets/profile_stat_widget.dart';
import 'manage_group_screen.dart';
import 'edit_group_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.group.admins.contains(_currentUser?.uid);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                                  ManageGroupScreen(groupId: widget.group.id),
                            ));
                      },
                    )
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(widget.group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
                  background: Image.network(widget.group.profileImageUrl, fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildGroupHeader(isAdmin),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildGroupPosts(),
              const Center(child: Text('Reels-urile grupului vor apărea aici.')),
              const Center(child: Text('Evenimentele grupului vor apărea aici.')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(initialGroup: widget.group))),
          backgroundColor: Colors.deepPurple,
          child: const Icon(Iconsax.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 12),
          Text(widget.group.description, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 16),
          // Aici va veni butonul de Join
          const SizedBox(height: 16),
          const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: 'Postări'), Tab(text: 'Reels'), Tab(text: 'Evenimente')],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('groupId', isEqualTo: widget.group.id).orderBy('createdAt', descending: true).snapshots(),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/post_model.dart';
import '../../../../data/models/story_model.dart';
import '../../../5_stories/presentation/widgets/story_circle_widget.dart';
import '../../../5_stories/presentation/screens/create_story_screen.dart';
import '../../../5_stories/presentation/screens/story_viewer_screen.dart';
import '../../../7_chat/presentation/screens/chats_list_screen.dart';
import '../widgets/post_card_widget.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Gluboom', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.send_1, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatsListScreen())),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1))),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('stories').where('expiresAt', isGreaterThan: Timestamp.now()).orderBy('expiresAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final stories = snapshot.data!.docs.map((doc) => StoryModel.fromFirestore(doc)).toList();
                  
                  // CORECTAT: Grupăm story-urile după groupId
                  final Map<String, List<StoryModel>> groupStories = {};
                  for (var story in stories) {
                    groupStories.putIfAbsent(story.groupId, () => []).add(story);
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: groupStories.length,
                    itemBuilder: (context, index) {
                      final groupId = groupStories.keys.elementAt(index);
                      final storiesOfGroup = groupStories[groupId]!;
                      final firstStory = storiesOfGroup.first;
                      return StoryCircle(
                        profileImageUrl: firstStory.groupPhotoUrl,
                        username: firstStory.groupName,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewerScreen(stories: storiesOfGroup))),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').where('isPublicPost', isEqualTo: true).orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text('Nicio postare publică. Alătură-te unui grup!')));
              }
              final posts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: posts[index]),
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

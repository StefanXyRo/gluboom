// FILE: lib/screens/home_screen.dart
// VERSIUNE COMPLETĂ: Cu importul lipsă adăugat.

import 'package:flutter/material.dart';
import 'package:gluboom/features/2_profile/presentation/screens/profile_page.dart';
import 'package:iconsax/iconsax.dart';
import '../features/4_feed/presentation/screens/feed_page.dart';
import '../features/4_feed/presentation/screens/create_post_screen.dart';
import '../features/3_groups/presentation/screens/groups_list_screen.dart';
import '../features/6_reels/presentation/screens/reels_screen.dart';
import '../features/6_reels/presentation/screens/create_reel_screen.dart';
import '../features/5_stories/presentation/screens/create_story_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    FeedPage(),
    GroupsListScreen(),
    SizedBox.shrink(),
    ReelsScreen(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreateMenu(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
  
  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Iconsax.document_text),
              title: const Text('Postare nouă'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.video_play),
              title: const Text('Reel nou'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateReelScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.additem),
              title: const Text('Story nou'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateStoryScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isReelsSelected = _selectedIndex == 3;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(_selectedIndex == 0 ? Iconsax.home1 : Iconsax.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(_selectedIndex == 1 ? Iconsax.discover1 : Iconsax.discover), label: 'Grupuri'),
          BottomNavigationBarItem(icon: const Icon(Iconsax.add_square, size: 32), label: 'Creează'),
          BottomNavigationBarItem(icon: Icon(_selectedIndex == 3 ? Iconsax.video_play5 : Iconsax.video_play), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(_selectedIndex == 4 ? Iconsax.profile_circle5 : Iconsax.profile_circle), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isReelsSelected ? Colors.black : Colors.white,
        selectedItemColor: isReelsSelected ? Colors.white : Colors.black,
        unselectedItemColor: isReelsSelected ? Colors.grey : Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}

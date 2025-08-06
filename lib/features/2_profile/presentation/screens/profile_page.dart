// FILE: lib/features/2_profile/presentation/screens/profile_page.dart
// VERSIUNE COMPLETĂ: Cu grid-uri funcționale și pagină de profil pentru utilizatorul curent.

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
import 'user_profile_screen.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Utilizator neconectat."),
        ),
      );
    }
    return UserProfileScreen(userId: _currentUser!.uid);
  }
}

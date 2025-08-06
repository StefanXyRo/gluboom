// FILE: lib/features/2_profile/presentation/widgets/user_list_tile.dart
// Înlocuiește conținutul fișierului existent cu acest cod.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:iconsax/iconsax.dart';
import '../../../../data/models/user_model.dart';
import '../screens/user_profile_screen.dart'; // Importăm noul ecran

class UserListTile extends StatefulWidget {
  final UserModel user;
  const UserListTile({super.key, required this.user});

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    // ... (codul rămâne la fel)
  }

  Future<void> _toggleFollow() async {
    // ... (codul rămâne la fel)
  }

  @override
  Widget build(BuildContext context) {
    // Ascundem utilizatorul curent din listă
    if (widget.user.uid == _currentUser?.uid) {
      return const SizedBox.shrink();
    }
    
    return ListTile(
      // MODIFICAT: Adăugăm onTap pentru a naviga la profil
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: widget.user.uid),
        ));
      },
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: widget.user.photoUrl != null ? NetworkImage(widget.user.photoUrl!) : null,
        child: widget.user.photoUrl == null ? const Icon(Iconsax.user) : null,
      ),
      title: Text(widget.user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(widget.user.email),
      trailing: _isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey.shade200 : Colors.blue,
                foregroundColor: _isFollowing ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isFollowing ? 'Urmărești' : 'Urmărește'),
            ),
    );
  }
}

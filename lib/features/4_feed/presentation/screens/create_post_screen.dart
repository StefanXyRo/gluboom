import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/group_model.dart';

class CreatePostScreen extends StatefulWidget {
  final GroupModel? initialGroup;
  const CreatePostScreen({super.key, this.initialGroup});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  GroupModel? _selectedGroup;
  List<GroupModel> _userGroups = [];
  bool _isPublicPost = true;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.initialGroup;
    if (_selectedGroup != null) {
      _isPublicPost = _selectedGroup!.isPublic;
    }
    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final groupsSnapshot = await FirebaseFirestore.instance.collection('groups').where('members', arrayContains: user.uid).get();
    if (mounted) {
      setState(() {
        _userGroups = groupsSnapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() { _imageFile = File(pickedFile.path); });
    }
  }

  Future<String?> _uploadImage(File image) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final fileName = 'post_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = firebase_storage.FirebaseStorage.instance.ref().child('post_images').child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _submitPost() async {
    if (_selectedGroup == null || _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Te rog selectează un grup și scrie un mesaj.")));
      return;
    }
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _isLoading = true; });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final isAdmin = _selectedGroup!.admins.contains(user.uid);

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'text': _textController.text.trim(),
        'imageUrl': imageUrl,
        'likeCount': 0,
        'commentCount': 0,
        'likes': [],
        'createdAt': Timestamp.now(),
        'authorUsername': userData.data()?['username'],
        'authorPhotoUrl': userData.data()?['photoUrl'],
        'groupId': _selectedGroup!.id,
        'isPublicPost': _isPublicPost,
        'isApproved': isAdmin, // Aprobare automată pentru admini
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("A apărut o eroare: $e")));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postare nouă')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_userGroups.isNotEmpty)
              DropdownButtonFormField<GroupModel>(
                value: _selectedGroup,
                hint: const Text('Selectează grupul unde vrei să postezi...'),
                items: _userGroups.map((group) => DropdownMenuItem(value: group, child: Text(group.name))).toList(),
                onChanged: (value) => setState(() {
                  _selectedGroup = value;
                  if (value != null) {
                    _isPublicPost = value.isPublic;
                  }
                }),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(hintText: 'Ce se întâmplă?', border: InputBorder.none),
                maxLines: null,
              ),
            ),
            if (_imageFile != null)
              Image.file(_imageFile!, height: 200),
            SwitchListTile(
              title: const Text('Postare Publică'),
              subtitle: const Text('Vizibilă pentru oricine, nu doar pentru membrii grupului.'),
              value: _isPublicPost,
              onChanged: (value) => setState(() => _isPublicPost = value),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.photo_camera), onPressed: _pickImage),
                ElevatedButton(onPressed: _isLoading ? null : _submitPost, child: const Text('Postează')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

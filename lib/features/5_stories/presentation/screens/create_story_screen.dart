import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../data/models/group_model.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  GroupModel? _selectedGroup;
  List<GroupModel> _adminGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminGroups();
  }

  Future<void> _fetchAdminGroups() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final groupsSnapshot = await FirebaseFirestore.instance.collection('groups').where('admins', arrayContains: user.uid).get();
    if (mounted) {
      setState(() {
        _adminGroups = groupsSnapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      setState(() { _imageFile = File(pickedFile.path); });
    }
  }

  Future<String?> _uploadImage(File image, String groupId) async {
    final fileName = 'story_${groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage.from('stories').upload(fileName, image);
    return Supabase.instance.client.storage.from('stories').getPublicUrl(fileName);
  }

  Future<void> _postStory() async {
    if (_imageFile == null || _selectedGroup == null) return;
    setState(() { _isLoading = true; });

    try {
      final imageUrl = await _uploadImage(_imageFile!, _selectedGroup!.id);
      if (imageUrl == null) throw Exception("Eroare la încărcarea imaginii.");
      
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('stories').add({
        'groupId': _selectedGroup!.id,
        'mediaUrl': imageUrl,
        'mediaType': 'image',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
        'groupName': _selectedGroup!.name,
        'groupPhotoUrl': _selectedGroup!.profileImageUrl,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("A apărut o eroare: $e")));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _imageFile == null
            ? Center(
                child: ElevatedButton(onPressed: _pickImage, child: const Text('Selectează o Imagine')),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_imageFile!, fit: BoxFit.cover),
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
      bottomSheet: _imageFile != null ? Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<GroupModel>(
                value: _selectedGroup,
                hint: const Text('Postează în grupul...', style: TextStyle(color: Colors.white)),
                items: _adminGroups.map((group) => DropdownMenuItem(value: group, child: Text(group.name))).toList(),
                onChanged: (value) => setState(() => _selectedGroup = value),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _postStory,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Postează'),
            ),
          ],
        ),
      ) : null,
    );
  }
}

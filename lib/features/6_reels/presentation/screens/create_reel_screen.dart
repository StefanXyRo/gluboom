// FILE: lib/features/6_reels/presentation/screens/create_reel_screen.dart
// Înlocuiește conținutul fișierului existent cu acest cod.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:video_player/video_player.dart';
import '../../../../data/models/group_model.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  File? _videoFile;
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  
  // NOU: Stări pentru selecția grupului
  GroupModel? _selectedGroup;
  List<GroupModel> _adminGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminGroups().then((_) {
      _pickVideo();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminGroups() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Căutăm grupurile unde utilizatorul curent este admin
    final groupsSnapshot = await FirebaseFirestore.instance.collection('groups').where('admins', arrayContains: user.uid).get();
    if (mounted) {
      setState(() {
        _adminGroups = groupsSnapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _videoFile = File(pickedFile.path);
      _videoController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<String?> _uploadVideo(File video, String groupId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'reel_${groupId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await supabase.storage.from('reels').upload(fileName, video);
      return supabase.storage.from('reels').getPublicUrl(fileName);
    } catch (e) { return null; }
  }

  Future<void> _publishReel() async {
    if (_videoFile == null || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Te rog selectează un grup.")));
      return;
    }
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() { _isLoading = true; });

    try {
      final videoUrl = await _uploadVideo(_videoFile!, _selectedGroup!.id);
      if (videoUrl == null) throw Exception("Eroare la încărcarea video.");

      await FirebaseFirestore.instance.collection('reels').add({
        'groupId': _selectedGroup!.id,
        'videoUrl': videoUrl,
        'caption': _captionController.text.trim(),
        'likeCount': 0,
        'commentCount': 0,
        'likes': [],
        'createdAt': Timestamp.now(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reel nou'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishReel,
            child: const Text('Publică', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _videoController == null || !_videoController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_adminGroups.isNotEmpty)
                        DropdownButtonFormField<GroupModel>(
                          value: _selectedGroup,
                          hint: const Text('Postează în numele grupului...', style: TextStyle(color: Colors.white)),
                          dropdownColor: Colors.black87,
                          style: const TextStyle(color: Colors.white),
                          items: _adminGroups.map((group) => DropdownMenuItem(value: group, child: Text(group.name))).toList(),
                          onChanged: (value) => setState(() => _selectedGroup = value),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Adaugă o descriere...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading) Container(color: Colors.black.withOpacity(0.7), child: const Center(child: CircularProgressIndicator())),
              ],
            ),
    );
  }
}

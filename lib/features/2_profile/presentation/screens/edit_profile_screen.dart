// FILE: lib/features/2_profile/presentation/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importăm Supabase
import '../../../../data/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- FUNCȚIE RESCRISĂ PENTRU SUPABASE ---
  Future<String?> _uploadImage(File image) async {
    try {
      final supabase = Supabase.instance.client;
      // Creăm un nume unic pentru fișier folosind ID-ul utilizatorului și un timestamp
      final fileName = '${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Încărcăm fișierul în bucket-ul 'profile-pictures'
      await supabase.storage.from('profile-pictures').upload(
            fileName,
            image,
          );

      // Obținem URL-ul public al fișierului încărcat
      final publicUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);
          
      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Eroare la încărcarea imaginii: $e")),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isLoading = true; });

    String? photoUrl = widget.user.photoUrl;
    if (_imageFile != null) {
      photoUrl = await _uploadImage(_imageFile!);
    }

    if (photoUrl != null || _imageFile == null) {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
      });
    }

    setState(() { _isLoading = false; });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI-ul rămâne neschimbat...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editează Profilul'),
        actions: [
          IconButton(
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2,)) : const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (widget.user.photoUrl != null
                        ? NetworkImage(widget.user.photoUrl!)
                        : null) as ImageProvider?,
                child: _imageFile == null && widget.user.photoUrl == null
                    ? Icon(Icons.camera_alt, color: Colors.grey.shade800)
                    : null,
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Schimbă poza de profil'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nume de utilizator',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Biografie',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// FILE: lib/features/3_groups/presentation/screens/create_group_screen.dart
// VERSIUNE COMPLETĂ: Cu opțiuni de confidențialitate și poză obligatorie.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:iconsax/iconsax.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPublic = true;
  bool _requiresApproval = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() { _imageFile = File(pickedFile.path); });
    }
  }

  Future<String?> _uploadImage(File image, String groupId) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('group_profile_pictures')
          .child('$groupId.jpg');

      await ref.putFile(image);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Numele și poza grupului sunt obligatorii.")));
      return;
    }
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() { _isLoading = true; });

    try {
      DocumentReference groupRef = FirebaseFirestore.instance.collection('groups').doc();
      final imageUrl = await _uploadImage(_imageFile!, groupRef.id);
      if (imageUrl == null) throw Exception("Eroare la încărcarea imaginii.");

      await groupRef.set({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'creatorId': user.uid,
        'admins': [user.uid],
        'members': [user.uid],
        'memberCount': 1,
        'isPublic': _isPublic,
        'requiresApproval': _requiresApproval,
        'createdAt': Timestamp.now(),
        'profileImageUrl': imageUrl,
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
      appBar: AppBar(title: const Text('Creează un grup nou')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? const Icon(Iconsax.camera, size: 40) : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Adaugă o poză (obligatoriu)'),
            const SizedBox(height: 24),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Numele grupului')),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descriere'), maxLines: 3),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: SwitchListTile(
                title: const Text('Grup Public', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Oricine poate găsi și vedea postările acestui grup.'),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: Colors.deepPurple,
              ),
            ),
            SwitchListTile(
              title: const Text('Necesită Aprobare'),
              subtitle: const Text('Administratorii trebuie să aprobe membrii noi.'),
              value: _requiresApproval,
              onChanged: (value) => setState(() => _requiresApproval = value),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Creează Grupul'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

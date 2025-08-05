// FILE: lib/features/3_groups/presentation/screens/create_group_screen.dart
// VERSIUNE COMPLETĂ: Cu management de erori îmbunătățit pentru încărcarea imaginii.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // MODIFICAT: Am adăugat afișarea detaliată a erorilor
  Future<String?> _uploadImage(File image, String groupId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'group_profile_${groupId}.jpg';
      
      await supabase.storage.from('group-pictures').upload(
        fileName,
        image,
        fileOptions: const FileOptions(upsert: true), // upsert: true permite suprascrierea
      );
      
      return supabase.storage.from('group-pictures').getPublicUrl(fileName);
    } catch (e) {
      // Afișăm eroarea exactă în consolă și într-un SnackBar
      debugPrint("!!! EROARE LA ÎNCĂRCAREA ÎN SUPABASE: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Eroare la încărcarea imaginii: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      
      // Verificăm dacă imaginea s-a încărcat cu succes
      if (imageUrl == null) {
        throw Exception("Încărcarea imaginii a eșuat. Verifică politicile de securitate din Supabase.");
      }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("A apărut o eroare la crearea grupului: $e")));
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
            SwitchListTile(
              title: const Text('Grup Public'),
              subtitle: const Text('Oricine poate găsi și vedea postările acestui grup.'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
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

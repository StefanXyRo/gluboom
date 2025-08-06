// FILE: lib/features/3_groups/presentation/screens/edit_group_screen.dart
// Creează acest fișier nou în locația specificată.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/group_model.dart';

class EditGroupScreen extends StatefulWidget {
  final GroupModel group;
  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() { _imageFile = File(pickedFile.path); });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'group_${widget.group.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Vom crea un nou bucket pentru pozele de grup
      await supabase.storage.from('group-pictures').upload(fileName, image);
      return supabase.storage.from('group-pictures').getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare la încărcarea imaginii: $e")));
      return null;
    }
  }

  Future<void> _saveChanges() async {
    setState(() { _isLoading = true; });

    String? newImageUrl = widget.group.profileImageUrl;
    if (_imageFile != null) {
      newImageUrl = await _uploadImage(_imageFile!);
    }

    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.group.id).update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'profileImageUrl': newImageUrl,
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
      appBar: AppBar(
        title: const Text('Editează Grupul'),
        actions: [
          IconButton(
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveChanges,
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
                    : NetworkImage(widget.group.profileImageUrl),
              ),
            ),
            TextButton(onPressed: _pickImage, child: const Text('Schimbă poza grupului')),
            const SizedBox(height: 24),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Numele grupului')),
            const SizedBox(height: 16),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descriere'), maxLines: 3),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Pick an image from the local gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Save changes to the Firestore Database
  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty && _bioController.text.isEmpty && _imageFile == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      
      // Upload image to Firebase Storage if a new one was picked
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('user_pics/$_userId.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // Update the specific user document in the 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        if (_nameController.text.isNotEmpty) 'name': _nameController.text,
        if (_bioController.text.isNotEmpty) 'bio': _bioController.text,
        if (imageUrl != null) 'photoUrl': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true); // Return 'true' to indicate data changed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update database: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null 
                          ? const Icon(Icons.camera_alt, size: 40, color: AppColors.primary) 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "New Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: "Bio", border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: _updateProfile,
                      child: const Text("Save Profile", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
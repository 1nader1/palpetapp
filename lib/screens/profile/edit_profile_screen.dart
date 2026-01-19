import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _selectedLocation;
  bool _isLoading = false;
  String _initialUsername = "";

  String? _currentPhotoUrl;
  File? _selectedImage;

  final List<String> _jordanAreas = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Salt',
    'Madaba',
    'Jerash',
    'Ajloun',
    'Mafraq',
    'Karak',
    'Tafilah',
    'Ma\'an',
    'Abdoun',
    'Dabouq',
    'Khalda',
    'Sweifieh',
    'Jubaiha',
    'Tla\' Al-Ali'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _usernameController.text = doc['username'] ?? '';
          _initialUsername = doc['username'] ?? '';
          _selectedLocation = doc['location'];
          _currentPhotoUrl = doc['photoUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final newUsername = _usernameController.text.trim().toLowerCase();

      if (newUsername != _initialUsername) {
        bool isUnique = await AuthService().isUsernameUnique(newUsername);
        if (!isUnique) throw 'Username is already taken';
      }

      await DatabaseService().updateUserProfile(
        uid: uid,
        name: _nameController.text.trim(),
        username: newUsername,
        location: _selectedLocation!,
        imageFile: _selectedImage,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentPhotoUrl!);
    } else {
      imageProvider = const NetworkImage(
          'https://cdn-icons-png.flaticon.com/512/847/847969.png');
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("Edit Profile"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 3),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: "Full Name",
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Enter name" : null),
                    const SizedBox(height: 20),
                    TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                            prefixText: "@"),
                        validator: (v) => v!.isEmpty ? "Enter username" : null),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                          labelText: "Location", border: OutlineInputBorder()),
                      items: _jordanAreas
                          .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLocation = v),
                      validator: (v) => v == null ? 'Select area' : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text("Save Changes",
                                style: TextStyle(color: Colors.white)))),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<String> _jordanAreas = [
    'Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Salt', 'Madaba', 
    'Jerash', 'Ajloun', 'Mafraq', 'Karak', 'Tafilah', 'Ma\'an',
    'Abdoun', 'Dabouq', 'Khalda', 'Sweifieh', 'Jubaiha', 'Tla\' Al-Ali'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _usernameController.text = doc['username'] ?? '';
          _initialUsername = doc['username'] ?? '';
          _selectedLocation = doc['location'];
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final newUsername = _usernameController.text.trim().toLowerCase();

      // Validate uniqueness only if changed
      if (newUsername != _initialUsername) {
        bool isUnique = await AuthService().isUsernameUnique(newUsername);
        if (!isUnique) throw 'Username is already taken';
      }

      await DatabaseService().updateUserProfile(
        uid: uid,
        name: _nameController.text.trim(),
        username: newUsername,
        location: _selectedLocation!,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Enter name" : null),
              const SizedBox(height: 20),
              TextFormField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder(), prefixText: "@"), validator: (v) => v!.isEmpty ? "Enter username" : null),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(labelText: "Location", border: OutlineInputBorder()),
                items: _jordanAreas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _selectedLocation = v),
                validator: (v) => v == null ? 'Select area' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text("Save Changes", style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }
}
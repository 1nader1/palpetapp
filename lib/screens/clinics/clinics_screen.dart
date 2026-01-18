import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/clinic.dart';
import '../../services/database_service.dart';
import 'clinic_details_screen.dart';
import 'widgets/clinic_card.dart';
import 'widgets/clinic_card_skeleton.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  String _searchKeyword = "";

  bool _isClinicOpen(String workingHours) {
    try {
      if (workingHours.isEmpty) return false;

      final parts = workingHours.contains(' - ')
          ? workingHours.split(' - ')
          : workingHours.split('-');

      if (parts.length != 2) return false;

      final startStr = parts[0].trim();
      final endStr = parts[1].trim();

      final format = DateFormat.jm();
      final now = DateTime.now();

      final startTimeRef = format.parse(startStr);
      final endTimeRef = format.parse(endStr);

      final openTime = DateTime(
          now.year, now.month, now.day, startTimeRef.hour, startTimeRef.minute);
      var closeTime = DateTime(
          now.year, now.month, now.day, endTimeRef.hour, endTimeRef.minute);

      if (closeTime.isBefore(openTime)) {
        closeTime = closeTime.add(const Duration(days: 1));
        if (now.hour < 12 && now.isBefore(closeTime)) {
          return true;
        }
        if (now.isAfter(openTime) ||
            now.isBefore(DateTime(now.year, now.month, now.day, endTimeRef.hour,
                endTimeRef.minute))) {
          return true;
        }
      }

      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Vet Clinics",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddClinicDialog(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchKeyword = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Search for a clinic...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Clinic>>(
              stream: _dbService.getClinics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: 5,
                    itemBuilder: (context, index) => const ClinicCardSkeleton(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading clinics"));
                }

                final clinics = snapshot.data ?? [];
                final filteredClinics = clinics
                    .where((clinic) => clinic.name
                        .toLowerCase()
                        .contains(_searchKeyword.toLowerCase()))
                    .toList();

                if (filteredClinics.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://i.pinimg.com/1200x/85/d6/fe/85d6fe2e402686d661019df7e4c09a30.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => const Icon(
                                    Icons.local_hospital,
                                    size: 60,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No Clinics Found",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "We couldn't find any clinics matching\nyour search.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredClinics.length,
                  itemBuilder: (context, index) {
                    final clinic = filteredClinics[index];

                    final bool isCurrentlyOpen =
                        _isClinicOpen(clinic.workingHours);

                    return ClinicCard(
                      clinicId: clinic.id,
                      ownerId: clinic.ownerId,
                      name: clinic.name,
                      address: clinic.address,
                      imageUrl: clinic.imageUrl,
                      isOpen: isCurrentlyOpen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ClinicDetailsScreen(clinic: clinic),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClinicDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add a clinic")),
      );
      return;
    }

    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final descController = TextEditingController();
    final hoursController = TextEditingController(text: "09:00 AM - 05:00 PM");
    final servicesController = TextEditingController();

    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add New Clinic"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          selectedImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: selectedImage != null
                            ? DecorationImage(
                                image: FileImage(selectedImage!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text("Tap to add photo",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: "Clinic Name")),
                  TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address")),
                  TextField(
                      controller: phoneController,
                      decoration:
                          const InputDecoration(labelText: "Phone Number"),
                      keyboardType: TextInputType.phone),
                  TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(
                          labelText: "Working Hours",
                          hintText: "e.g. 9 AM - 6 PM")),
                  TextField(
                    controller: servicesController,
                    decoration: const InputDecoration(
                        labelText: "Services",
                        hintText: "Separate by comma (e.g. Surgery, Grooming)"),
                  ),
                  TextField(
                      controller: descController,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            addressController.text.isEmpty) return;

                        setState(() => isUploading = true);

                        String imageUrl =
                            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?q=80&w=2070';

                        if (selectedImage != null) {
                          try {
                            imageUrl =
                                await _dbService.uploadImage(selectedImage!);
                          } catch (e) {
                            print("Error uploading image: $e");
                          }
                        }

                        List<String> servicesList =
                            servicesController.text.isNotEmpty
                                ? servicesController.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .toList()
                                : ['General Checkup'];

                        final newClinic = Clinic(
                          id: '',
                          ownerId: user.uid,
                          name: nameController.text,
                          address: addressController.text,
                          phoneNumber: phoneController.text,
                          description: descController.text,
                          imageUrl: imageUrl,
                          rating: 0.0,
                          isOpen: true,
                          workingHours: hoursController.text,
                          services: servicesList,
                        );

                        await _dbService.addClinic(newClinic);

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Add",
                          style: TextStyle(color: Colors.white)),
                    ),
            ],
          );
        },
      ),
    );
  }
}

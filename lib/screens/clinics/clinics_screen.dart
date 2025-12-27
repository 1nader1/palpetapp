import 'dart:io'; // للتعامل مع ملف الصورة
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // [مهم] لاستيراد مكتبة الصور
import '../../core/constants/app_colors.dart';
import '../../data/models/clinic.dart';
import '../../services/database_service.dart';
import 'widgets/clinic_card.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  String _searchKeyword = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Clinic>>(
              stream: _dbService.getClinics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading clinics"));
                }

                final clinics = snapshot.data ?? [];
                final filteredClinics = clinics.where((clinic) =>
                    clinic.name.toLowerCase().contains(_searchKeyword.toLowerCase())
                ).toList();

                if (filteredClinics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        const Text(
                          "No clinics found",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredClinics.length,
                  itemBuilder: (context, index) {
                    return ClinicCard(clinic: filteredClinics[index]);
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
    final hoursController = TextEditingController(text: "09:00 AM - 05:00 PM"); // القيمة الافتراضية
    final servicesController = TextEditingController(); // لإدخال الخدمات مفصولة بفواصل
    
    File? selectedImage; // لتخزين الصورة المختارة
    bool isUploading = false; // حالة التحميل

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
                  // --- اختيار الصورة ---
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
                            ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text("Tap to add photo", style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Clinic Name")),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
                  
                  // --- حقول جديدة ---
                  TextField(
                    controller: hoursController, 
                    decoration: const InputDecoration(
                      labelText: "Working Hours",
                      hintText: "e.g. 9 AM - 6 PM"
                    )
                  ),
                  TextField(
                    controller: servicesController,
                    decoration: const InputDecoration(
                      labelText: "Services",
                      hintText: "Separate by comma (e.g. Surgery, Grooming)"
                    ),
                  ),
                  // ------------------
                  
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () async {
                        if (nameController.text.isEmpty || addressController.text.isEmpty) return;

                        setState(() => isUploading = true);

                        String imageUrl = 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?q=80&w=2070'; // صورة افتراضية
                        
                        // رفع الصورة إذا تم اختيارها
                        if (selectedImage != null) {
                          try {
                            imageUrl = await _dbService.uploadImage(selectedImage!);
                          } catch (e) {
                            print("Error uploading image: $e");
                          }
                        }

                        // تحويل نص الخدمات إلى قائمة
                        List<String> servicesList = servicesController.text.isNotEmpty
                            ? servicesController.text.split(',').map((e) => e.trim()).toList()
                            : ['General Checkup'];

                        final newClinic = Clinic(
                          id: '',
                          ownerId: user.uid,
                          name: nameController.text,
                          address: addressController.text,
                          phoneNumber: phoneController.text,
                          description: descController.text,
                          imageUrl: imageUrl, // استخدام الرابط (المرفوع أو الافتراضي)
                          rating: 0.0,
                          isOpen: true,
                          workingHours: hoursController.text, // القيمة المدخلة
                          services: servicesList, // القائمة المحولة
                        );

                        await _dbService.addClinic(newClinic);
                        
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Add", style: TextStyle(color: Colors.white)),
                    ),
            ],
          );
        },
      ),
    );
  }
}
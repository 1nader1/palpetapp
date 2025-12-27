import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // [مهم]
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/clinic.dart';
import '../../services/database_service.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Clinic _clinic;
  int _selectedTab = 0;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    _checkOwnership();
  }

  void _checkOwnership() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == widget.clinic.ownerId) {
      setState(() {
        _isOwner = true;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Clinic"),
        content: const Text("Are you sure you want to delete this clinic?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteClinic(_clinic.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _clinic.name);
    final phoneController = TextEditingController(text: _clinic.phoneNumber);
    final addressController = TextEditingController(text: _clinic.address);
    final descController = TextEditingController(text: _clinic.description);
    final hoursController = TextEditingController(text: _clinic.workingHours);
    final servicesController = TextEditingController(text: _clinic.services.join(', '));
    
    File? newImageFile;
    bool isOpen = _clinic.isOpen;
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Clinic"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- تعديل الصورة ---
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setDialogState(() {
                          newImageFile = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: newImageFile != null
                              ? FileImage(newImageFile!)
                              : NetworkImage(_clinic.imageUrl) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(color: Colors.black26),
                          const Center(child: Icon(Icons.edit, color: Colors.white, size: 40)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Clinic Name")),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number")),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
                  
                  // --- الحقول الجديدة للتعديل ---
                  TextField(controller: hoursController, decoration: const InputDecoration(labelText: "Working Hours")),
                  TextField(controller: servicesController, decoration: const InputDecoration(labelText: "Services (comma separated)")),
                  // ---------------------------

                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Is Open?"),
                    value: isOpen,
                    onChanged: (val) {
                      setDialogState(() => isOpen = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              isUpdating
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setDialogState(() => isUpdating = true);

                        String finalImageUrl = _clinic.imageUrl;
                        // رفع الصورة الجديدة إذا تم تغييرها
                        if (newImageFile != null) {
                          try {
                            finalImageUrl = await _dbService.uploadImage(newImageFile!);
                          } catch (e) {
                            print("Error updating image: $e");
                          }
                        }

                        // تحديث قائمة الخدمات
                        List<String> updatedServices = servicesController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        final updatedClinic = Clinic(
                          id: _clinic.id,
                          ownerId: _clinic.ownerId,
                          name: nameController.text,
                          address: addressController.text,
                          description: descController.text,
                          imageUrl: finalImageUrl, // الصورة الجديدة أو القديمة
                          rating: _clinic.rating,
                          phoneNumber: phoneController.text,
                          isOpen: isOpen,
                          workingHours: hoursController.text, // الساعات المعدلة
                          services: updatedServices, // الخدمات المعدلة
                        );

                        await _dbService.updateClinic(updatedClinic);
                        
                        if (mounted) {
                          setState(() {
                            _clinic = updatedClinic;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save"),
                    ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: _isOwner
            ? [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                    onPressed: _showEditDialog,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12, left: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: _confirmDelete,
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 320,
              width: double.infinity,
              child: Image.network(
                _clinic.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _clinic.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.serviceVetBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _clinic.rating.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton("Details", 0),
                        _buildTabButton("Hours", 1),
                        _buildTabButton("Services", 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentTabContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildDetailsContent();
      case 1:
        return _buildHoursContent();
      case 2:
        return _buildServicesContent();
      default:
        return _buildDetailsContent();
    }
  }

  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("About Clinic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          _clinic.description,
          style: const TextStyle(color: AppColors.textGrey, height: 1.6, fontSize: 15),
        ),
        const SizedBox(height: 24),
        const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _clinic.address,
                  style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text("Contact Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.phone, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Phone Number", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _clinic.phoneNumber,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _makePhoneCall(_clinic.phoneNumber),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("Call", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoursContent() {
    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _clinic.isOpen ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _clinic.isOpen ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _clinic.isOpen ? Icons.check_circle : Icons.cancel,
                size: 50,
                color: _clinic.isOpen ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _clinic.isOpen ? "Open Now" : "Closed",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _clinic.isOpen ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "You can visit us now",
                style: TextStyle(color: _clinic.isOpen ? Colors.green[600] : Colors.red[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_filled, color: AppColors.primary),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Working Hours", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(_clinic.workingHours, style: const TextStyle(color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesContent() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Facilities & Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _clinic.services.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _clinic.services[index],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
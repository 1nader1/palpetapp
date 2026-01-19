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

      String normalizeTime(String rawTime) {
        String clean = rawTime.trim().toUpperCase();
        String period = "";
        if (clean.contains("AM")) {
          period = "AM";
          clean = clean.replaceAll("AM", "").trim();
        } else if (clean.contains("PM")) {
          period = "PM";
          clean = clean.replaceAll("PM", "").trim();
        }
        if (!clean.contains(":")) {
          clean = "$clean:00";
        }
        return "$clean $period".trim();
      }

      final startStr = normalizeTime(parts[0]);
      final endStr = normalizeTime(parts[1]);
      final format = DateFormat('h:mm a'); 
      final now = DateTime.now();

      DateTime startTimeRef;
      DateTime endTimeRef;

      DateTime parseFlexible(String timeStr) {
        try {
          return format.parse(timeStr);
        } catch (_) {
          return DateFormat('h:mma').parse(timeStr.replaceAll(' ', ''));
        }
      }

      startTimeRef = parseFlexible(startStr);
      endTimeRef = parseFlexible(endStr);

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
            onPressed: () => _showAddClinicSheet(context),
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
                                'https://img.freepik.com/free-vector/cute-dog-cat-friendship-cartoon-vector-icon-illustration-animal-nature-icon-concept-isolated_138676-5626.jpg',
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

  void _showAddClinicSheet(BuildContext context) {
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
    final serviceInputController = TextEditingController();
    List<String> servicesList = []; 

    final openHourController = TextEditingController(text: "9");
    final openMinuteController = TextEditingController(text: "00");
    final closeHourController = TextEditingController(text: "5");
    final closeMinuteController = TextEditingController(text: "00");

    String openPeriod = "AM";
    String closePeriod = "PM";

    File? selectedImage;
    bool isUploading = false;
    bool showErrors = false;

    // --- التغيير هنا: استخدام DraggableScrollableSheet ---
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85, // الارتفاع المبدئي
        maxChildSize: 0.95, // أقصى ارتفاع
        minChildSize: 0.5, // أدنى ارتفاع قبل الإغلاق
        expand: false, // مهم جداً لجعل الزوايا تظهر والخلفية شفافة
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;

              void addService() {
                final text = serviceInputController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    servicesList.add(text);
                    serviceInputController.clear();
                  });
                }
              }

              void removeService(String item) {
                setState(() {
                  servicesList.remove(item);
                });
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    // الهيدر ثابت (لا يتحرك مع السكرول ولكن يمكن سحبه لإغلاق النافذة)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Add New Clinic",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        // ربط السكرول كونترولر الخاص بالنافذة هنا
                        controller: scrollController, 
                        // الحشوة للكيبورد
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      selectedImage = File(pickedFile.path);
                                    });
                                  }
                                },
                                child: Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey[300]!),
                                    image: selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(selectedImage!),
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: selectedImage == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: AppColors.primary
                                                          .withOpacity(0.1),
                                                      blurRadius: 8)
                                                ],
                                              ),
                                              child: const Icon(Icons.add_a_photo,
                                                  color: AppColors.primary,
                                                  size: 32),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "Upload Clinic Photo",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          alignment: Alignment.topRight,
                                          padding: const EdgeInsets.all(8),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: 16,
                                            child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildInputField(
                                label: "Clinic Name",
                                controller: nameController,
                                icon: Icons.local_hospital,
                                isRequired: true,
                                showErrors: showErrors,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                                label: "Address",
                                controller: addressController,
                                icon: Icons.location_on,
                                isRequired: true,
                                showErrors: showErrors,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                                label: "Phone Number",
                                controller: phoneController,
                                icon: Icons.phone,
                                inputType: TextInputType.phone,
                                isRequired: true,
                                showErrors: showErrors,
                            ),
                            
                            const SizedBox(height: 24),
                            const Text("Working Hours", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSplitTimeInput(
                                    label: "Opens At",
                                    hourController: openHourController,
                                    minuteController: openMinuteController,
                                    period: openPeriod,
                                    onPeriodChanged: (val) => setState(() => openPeriod = val!),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSplitTimeInput(
                                    label: "Closes At",
                                    hourController: closeHourController,
                                    minuteController: closeMinuteController,
                                    period: closePeriod,
                                    onPeriodChanged: (val) => setState(() => closePeriod = val!),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Text("Services", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: serviceInputController,
                                    decoration: InputDecoration(
                                      hintText: "e.g. Surgery, Vaccination",
                                      filled: true,
                                      fillColor: const Color(0xFFF9FAFB),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: addService,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (servicesList.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: servicesList.map((service) {
                                  return Chip(
                                    label: Text(service),
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () => removeService(service),
                                  );
                                }).toList(),
                              ),

                            const SizedBox(height: 24),
                            
                            // الوصف مع خاصية الرفع التلقائي
                            _buildInputField(
                                label: "Description",
                                controller: descController,
                                icon: Icons.description,
                                maxLines: 3,
                                onTap: () {
                                  // تأخير بسيط لضمان فتح الكيبورد
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    if (scrollController.hasClients) {
                                      // التمرير لأسفل لضمان ظهور الحقل
                                      scrollController.animateTo(
                                        scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  });
                                },
                            ),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        setState(() => showErrors = true);

                                        if (nameController.text.isEmpty ||
                                            addressController.text.isEmpty ||
                                            phoneController.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Please fill in all required fields marked in red"),
                                                  backgroundColor: Colors.red,
                                              ));
                                          return;
                                        }

                                        setState(() => isUploading = true);

                                        String imageUrl =
                                            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?q=80&w=2070';

                                        if (selectedImage != null) {
                                          try {
                                            imageUrl = await _dbService
                                                .uploadImage(selectedImage!);
                                          } catch (e) {
                                            print("Error uploading image: $e");
                                          }
                                        }

                                        final finalServices = servicesList.isNotEmpty 
                                            ? servicesList 
                                            : ['General Checkup'];
                                        
                                        final String finalWorkingHours = 
                                            "${openHourController.text}:${openMinuteController.text} $openPeriod - ${closeHourController.text}:${closeMinuteController.text} $closePeriod";

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
                                          workingHours: finalWorkingHours,
                                          services: finalServices,
                                        );

                                        await _dbService.addClinic(newClinic);

                                        if (context.mounted) Navigator.pop(context);
                                      },
                                child: isUploading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        "Save Clinic",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSplitTimeInput({
    required String label,
    required TextEditingController hourController,
    required TextEditingController minuteController,
    required String period,
    required Function(String?) onPeriodChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hourController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: "HH",
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              const Text(":", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
              Expanded(
                child: TextField(
                  controller: minuteController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: "MM",
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: period,
                    items: ["AM", "PM"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: onPeriodChanged,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    bool isRequired = false,
    bool showErrors = false,
    VoidCallback? onTap,
  }) {
    bool isError = showErrors && isRequired && controller.text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: isError 
                  ? const BorderSide(color: Colors.red) 
                  : BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              "Required",
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }
}
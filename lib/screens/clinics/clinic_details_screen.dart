import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Timestamp
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/clinic.dart';
import '../../services/database_service.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final Clinic clinic;

  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen>
    with WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();
  late Clinic _clinic;
  int _selectedTab = 0;
  bool _isOwner = false;
  bool _isCallClicked = false;

  @override
  void initState() {
    super.initState();
    _clinic = widget.clinic;
    WidgetsBinding.instance.addObserver(this);
    _checkOwnership();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCallClicked) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isCallClicked = false;
          });
          _checkAndShowRatingDialog();
        }
      });
    }
  }

  void _checkOwnership() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == widget.clinic.ownerId) {
      setState(() {
        _isOwner = true;
      });
    }
  }

  // --- REVIEWS MODAL START ---
  void _showReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Handle bar
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
                
                // Header with "Write Review" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Reviews",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _checkAndShowRatingDialog();
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Write a Review"),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const Divider(),
                
                // Reviews List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getReviews(_clinic.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("No reviews yet. Be the first!", 
                              style: TextStyle(color: Colors.grey[500])),
                          ],
                        );
                      }

                      return ListView.builder(
                        controller: controller,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final double rating = (data['rating'] ?? 0.0).toDouble();
                          final String comment = data['comment'] ?? '';
                          final String reviewerId = data['reviewerId'] ?? '';
                          final Timestamp? createdAt = data['createdAt'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Fetch Reviewer Name
                                    FutureBuilder<String>(
                                      future: _dbService.getUserName(reviewerId),
                                      builder: (context, nameSnapshot) {
                                        return Text(
                                          nameSnapshot.data ?? "Loading...",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      createdAt != null 
                                        ? DateFormat.yMMMd().format(createdAt.toDate())
                                        : '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    comment,
                                    style: const TextStyle(color: AppColors.textDark, height: 1.4),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  // --- REVIEWS MODAL END ---

  Future<void> _checkAndShowRatingDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (currentUser.uid == _clinic.ownerId) return;

    bool alreadyReviewed = await _dbService.hasUserReviewed(
      currentUser.uid,
      _clinic.ownerId,
      'clinic',
      petId: _clinic.id,
    );

    if (!mounted) return;

    if (alreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You have already reviewed this clinic."),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    _showRatingDialog(currentUser.uid);
  }

  void _showRatingDialog(String currentUserId) {
    double rating = 0;
    TextEditingController commentController = TextEditingController();
    bool isTransactionConfirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                      isTransactionConfirmed
                          ? Icons.star
                          : Icons.check_circle_outline,
                      color: isTransactionConfirmed
                          ? Colors.amber
                          : AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                      isTransactionConfirmed ? "Rate Clinic" : "Service Check"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isTransactionConfirmed) ...[
                    const Text(
                      "Did you visit or contact this clinic successfully?",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("No",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setStateDialog(() {
                              isTransactionConfirmed = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text("How was your experience?"),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment (optional)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: isTransactionConfirmed
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Skip",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (rating > 0) {
                            await _dbService.addReview(
                              targetUserId: _clinic.ownerId,
                              reviewerId: currentUserId,
                              rating: rating,
                              comment: commentController.text,
                              reviewType: 'clinic',
                              petId: _clinic.id,
                            );

                            await _dbService.addBooking(
                              userId: currentUserId,
                              providerId: _clinic.ownerId,
                              serviceType: 'Vet Clinic',
                              itemName: _clinic.name,
                              details: {
                                'ratingGiven': rating,
                                'location': _clinic.address,
                              },
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text("Thanks for your feedback!"),
                                backgroundColor: Colors.green,
                              ));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Please select a star rating")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Submit"),
                      ),
                    ]
                  : null,
            );
          },
        );
      },
    );
  }

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    setState(() {
      _isCallClicked = true;
    });

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        setState(() => _isCallClicked = false);
      }
    } catch (e) {
      setState(() => _isCallClicked = false);
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
    final servicesController =
        TextEditingController(text: _clinic.services.join(', '));

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
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);
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
                          const Center(
                              child: Icon(Icons.edit,
                                  color: Colors.white, size: 40)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: "Clinic Name")),
                  TextField(
                      controller: phoneController,
                      decoration:
                          const InputDecoration(labelText: "Phone Number")),
                  TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address")),
                  TextField(
                      controller: hoursController,
                      decoration:
                          const InputDecoration(labelText: "Working Hours")),
                  TextField(
                      controller: servicesController,
                      decoration: const InputDecoration(
                          labelText: "Services (comma separated)")),
                  TextField(
                      controller: descController,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      maxLines: 3),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Is Open? (Manual Override)"),
                    value: isOpen,
                    onChanged: (val) {
                      setDialogState(() => isOpen = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              isUpdating
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setDialogState(() => isUpdating = true);
                        String finalImageUrl = _clinic.imageUrl;
                        if (newImageFile != null) {
                          try {
                            finalImageUrl =
                                await _dbService.uploadImage(newImageFile!);
                          } catch (e) {
                            print("Error updating image: $e");
                          }
                        }
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
                          imageUrl: finalImageUrl,
                          rating: _clinic.rating,
                          phoneNumber: phoneController.text,
                          isOpen: isOpen,
                          workingHours: hoursController.text,
                          services: updatedServices,
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
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
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
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppColors.primary, size: 20),
                    onPressed: _showEditDialog,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12, left: 4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
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
                      // --- CLICKABLE RATING START ---
                      GestureDetector(
                        onTap: _showReviewsModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.serviceVetBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: _dbService.getItemRatingStats(_clinic.id),
                            builder: (context, snapshot) {
                              String ratingText = "New";
                              String countText = "";
                              if (snapshot.hasData) {
                                double avg = snapshot.data!['average'] ?? 0.0;
                                int count = snapshot.data!['count'] ?? 0;
                                if (count > 0) {
                                  ratingText = avg.toStringAsFixed(1);
                                  countText = " ($count)";
                                }
                              }
                              return Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$ratingText$countText",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      // --- CLICKABLE RATING END ---
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
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
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
        const Text("About Clinic",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          _clinic.description,
          style: const TextStyle(
              color: AppColors.textGrey, height: 1.6, fontSize: 15),
        ),
        const SizedBox(height: 24),
        const Text("Location",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                child: const Icon(Icons.location_on,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _clinic.address,
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text("Contact Info",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.phone, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Phone Number",
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _clinic.phoneNumber,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _makePhoneCall(_clinic.phoneNumber),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("Call",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoursContent() {
    final bool isOpenNow = _isClinicOpen(_clinic.workingHours);

    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isOpenNow ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isOpenNow ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isOpenNow ? Icons.check_circle : Icons.cancel,
                size: 50,
                color: isOpenNow ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isOpenNow ? "Open Now" : "Closed",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isOpenNow ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "You can visit us now",
                style: TextStyle(
                    color: isOpenNow ? Colors.green[600] : Colors.red[600]),
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
                  const Text("Working Hours",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(_clinic.workingHours,
                      style: const TextStyle(color: AppColors.textGrey)),
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
        const Text("Facilities & Services",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
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
                  const Icon(Icons.medical_services_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _clinic.services[index],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textDark),
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
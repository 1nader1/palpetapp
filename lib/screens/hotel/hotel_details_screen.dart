import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const HotelDetailsScreen({super.key, required this.data});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> with WidgetsBindingObserver {
  int _selectedTab = 0;
  bool _isCallClicked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCallClicked) {
      // تأخير بسيط لضمان استقرار الواجهة
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    
    setState(() {
      _isCallClicked = true;
    });

    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Error launching call: $e");
      setState(() {
        _isCallClicked = false;
      });
    }
  }

  Future<void> _checkAndShowRatingDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String? targetUserId = widget.data['ownerId']; 

    if (currentUser == null || targetUserId == null) return;
    
    // 1. فحص الحماية: منع المالك من تقييم نفسه
    if (currentUser.uid == targetUserId) return;

    // 2. فحص التكرار: هل قام بتقييم هذا الفندق (خدمة الفندقة) مسبقاً؟
    bool alreadyReviewed = await DatabaseService().hasUserReviewed(currentUser.uid, targetUserId, 'hotel');
    
    if (!mounted) return;

    if (alreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already reviewed this hotel."),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    _showRatingDialog(currentUser.uid, targetUserId);
  }

  void _showRatingDialog(String currentUserId, String targetUserId) {
    double rating = 0;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                   Icon(Icons.star, color: Colors.amber),
                   SizedBox(width: 8),
                   Text("Rate Hotel Service"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("How was your experience with this hotel?"),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Skip", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (rating > 0) {
                      await DatabaseService().addReview(
                        targetUserId: targetUserId,
                        reviewerId: currentUserId,
                        rating: rating,
                        comment: commentController.text,
                        reviewType: 'hotel', // تحديد النوع كـ hotel
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thanks for your feedback!"),
                            backgroundColor: Colors.green,
                          )
                        );
                      }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a star rating"))
                       );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.data['imageUrl'] ?? widget.data['image'] ?? '';
    final String name = widget.data['name'] ?? 'Hotel Name';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 320,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.hotel, size: 50, color: Colors.grey)),
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
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
                        _buildTabButton("Amenities", 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  AnimatedCrossFade(
                    firstChild: _buildDetailsContent(),
                    secondChild: _buildAmenitiesContent(),
                    crossFadeState: _selectedTab == 0
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent() {
    final String description = widget.data['description'] ?? "No description available.";
    final String price = widget.data['price'] ?? "N/A";
    final String capacity = widget.data['capacity'] ?? "N/A";
    final String address = widget.data['location'] ?? widget.data['address'] ?? "Unknown Address";
    final String phone = widget.data['contactPhone'] ?? widget.data['phone'] ?? "N/A";
    
    List<String> supportedPets = [];
    if (widget.data['type'] != null) {
      supportedPets = widget.data['type'].toString().split(',').map((e) => e.trim()).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("About Hotel",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
              color: AppColors.textGrey, height: 1.6, fontSize: 15),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Accepts",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: supportedPets
                          .map((pet) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(pet,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              
              Container(
                  width: 1,
                  height: 60, 
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Price",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text(" /night",
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12), 

                  const Text("Capacity",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.meeting_room, size: 16, color: AppColors.textDark), 
                      const SizedBox(width: 4),
                      Text(
                        capacity,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text("Location",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
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
                    phone,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: phone != "N/A" ? () => _makePhoneCall(phone) : null,
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

  Widget _buildAmenitiesContent() {
    List<String> amenitiesList = [];
    
    if (widget.data['amenities'] is String) {
      amenitiesList = (widget.data['amenities'] as String)
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) => e.trim())
          .toList();
    } 
    else if (widget.data['amenities'] is List) {
      amenitiesList = List<String>.from(widget.data['amenities']);
    }

    if (amenitiesList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No specific amenities listed."),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Facilities & Services",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          itemCount: amenitiesList.length,
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
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      amenitiesList[index],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
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
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';

class LostFoundDetailsScreen extends StatefulWidget {
  final Pet pet;

  const LostFoundDetailsScreen({super.key, required this.pet});

  @override
  State<LostFoundDetailsScreen> createState() => _LostFoundDetailsScreenState();
}

class _LostFoundDetailsScreenState extends State<LostFoundDetailsScreen>
    with WidgetsBindingObserver {
  bool _isCallClicked = false;
  final DatabaseService _dbService = DatabaseService();

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
    setState(() => _isCallClicked = true);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        setState(() => _isCallClicked = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch phone dialer")),
          );
        }
      }
    } catch (e) {
      setState(() => _isCallClicked = false);
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
                    const Text(
                      "User Reviews",
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
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _dbService.getUserReviews(widget.pet.ownerId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(child: Text("Something went wrong"));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rate_review_outlined,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("No reviews for this user yet.",
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        );
                      }

                      return ListView.builder(
                        controller: controller,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final double rating =
                              (data['rating'] ?? 0.0).toDouble();
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FutureBuilder<String>(
                                      future:
                                          _dbService.getUserName(reviewerId),
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
                                          ? DateFormat.yMMMd()
                                              .format(createdAt.toDate())
                                          : '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    comment,
                                    style: const TextStyle(
                                        color: AppColors.textDark, height: 1.4),
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

  Future<void> _checkAndShowRatingDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String targetUserId = widget.pet.ownerId;

    if (currentUser == null) return;
    if (currentUser.uid == targetUserId) return;

    bool alreadyReviewed = await _dbService.hasUserReviewed(
        currentUser.uid, targetUserId, 'lost_found');

    if (!mounted) return;

    if (alreadyReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You have already reviewed this interaction."),
          backgroundColor: Colors.orange));
      return;
    }

    _showRatingDialog(currentUser.uid, targetUserId);
  }

  void _showRatingDialog(String currentUserId, String targetUserId) {
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
                  Text(isTransactionConfirmed ? "Rate User" : "Status Check"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isTransactionConfirmed) ...[
                    const Text(
                      "Was the pet returned/found successfully?",
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
                    const Text("How was your interaction with this user?"),
                    const SizedBox(height: 20),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                              icon: Icon(
                                  index < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 32),
                              onPressed: () {
                                setStateDialog(() {
                                  rating = index + 1.0;
                                });
                              });
                        })),
                    const SizedBox(height: 10),
                    TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                            hintText: "Write a comment (optional)",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50]),
                        maxLines: 2),
                  ],
                ],
              ),
              actions: isTransactionConfirmed
                  ? [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Skip",
                              style: TextStyle(color: Colors.grey))),
                      ElevatedButton(
                        onPressed: () async {
                          if (rating > 0) {
                            await _dbService.addReview(
                              targetUserId: targetUserId,
                              reviewerId: currentUserId,
                              rating: rating,
                              comment: commentController.text,
                              reviewType: 'lost_found',
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Feedback recorded!"),
                                      backgroundColor: Colors.green));
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
                                borderRadius: BorderRadius.circular(10))),
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

  @override
  Widget build(BuildContext context) {
    final bool isLost = widget.pet.postType == 'Lost';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.pet.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: Colors.grey[200]),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pet.name,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark),
                          ),

                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _showReviewsModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: _dbService
                                    .getUserRatingStats(widget.pet.ownerId),
                                builder: (context, snapshot) {
                                  String ratingText = "New User";
                                  if (snapshot.hasData) {
                                    double avg =
                                        snapshot.data!['average'] ?? 0.0;
                                    int count = snapshot.data!['count'] ?? 0;
                                    if (count > 0) {
                                      ratingText =
                                          "${avg.toStringAsFixed(1)} ($count)";
                                    }
                                  }
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        ratingText,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.chevron_right,
                                          size: 14, color: Colors.grey),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),

                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLost ? Colors.redAccent : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLost ? "LOST" : "FOUND",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.pet.type} • ${widget.pet.age}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  const Text("Last Seen Location",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            color: isLost ? Colors.redAccent : Colors.green,
                            size: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.pet.location,
                            style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textDark,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Description",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(
                    widget.pet.description,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textGrey, height: 1.6),
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
                          child: const Icon(Icons.phone,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Phone Number",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              widget.pet.contactPhone,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () =>
                              _makePhoneCall(widget.pet.contactPhone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: const Text("Call",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
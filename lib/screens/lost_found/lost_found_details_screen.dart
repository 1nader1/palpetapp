import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../core/constants/app_colors.dart';

class LostFoundDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const LostFoundDetailsScreen({super.key, required this.data});

  // دالة الاتصال
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- الحل الجذري للمشكلة هنا ---
    // نحدد قيمة isLost بشكل آمن:
    // 1. هل هي موجودة في البيانات؟ نستخدمها.
    // 2. غير موجودة؟ نفحص postType.
    // 3. كلاهما غير موجود؟ نفترض أنها false (Found) لتجنب الخطأ.
    bool isLost = false;
    
    if (data['isLost'] != null) {
      isLost = data['isLost'];
    } else if (data['postType'] != null) {
      // نفحص النص القادم من قاعدة البيانات
      final String type = data['postType'].toString().toLowerCase();
      isLost = (type == 'lost');
    }

    // استخراج باقي البيانات مع قيم احتياطية (Placeholder) لتجنب أي خطأ آخر
    final String imageUrl = data['imageUrl'] ?? data['image'] ?? '';
    final String name = data['name'] ?? 'Unknown';
    final String type = data['type'] ?? 'Pet';
    final String location = data['location'] ?? 'Unknown Location';
    final String description = data['description'] ?? 'No description.';
    final String phone = data['contactPhone'] ?? data['phone'] ?? 'N/A';
    
    // معالجة التاريخ (سواء كان نصاً أو Timestamp)
    String dateStr = data['date'] ?? '';
    if (dateStr.isEmpty && data['createdAt'] != null) {
      // تحويل بسيط إذا كان التاريخ قادماً من السيرفر
      dateStr = data['createdAt'].toString().split(' ')[0]; 
    }

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
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الحيوان
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                        )
                      : Container(color: Colors.grey[300], child: const Icon(Icons.pets, size: 50, color: Colors.grey)),
                  
                  // تدرج لوني
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
                          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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
                  // الاسم والحالة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLost ? AppColors.lostRed : AppColors.foundGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLost ? "LOST" : "FOUND",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$type • $dateStr",
                    style: const TextStyle(fontSize: 16, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // الموقع
                  const Text("Last Seen Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                        Icon(Icons.location_on, color: isLost ? AppColors.lostRed : AppColors.foundGreen, size: 30),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(location, style: const TextStyle(fontSize: 15, color: AppColors.textDark, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // الوصف
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 15, color: AppColors.textGrey, height: 1.6)),
                  const SizedBox(height: 24),

                  // الاتصال
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Phone Number", style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: phone != 'N/A' ? () => _makePhoneCall(phone) : null,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
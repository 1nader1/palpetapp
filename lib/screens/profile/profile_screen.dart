import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart'; // تأكد أن المسار صحيح لصفحة اللوج ان
import 'widgets/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // متغيرات لحفظ بيانات المستخدم
  String _name = "جاري التحميل...";
  String _email = "";
  String _photoUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=2080&auto=format&fit=crop"; // صورة افتراضية

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // دالة لجلب البيانات من فايربيس
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? ""; // الإيميل موجود دائماً في الـ Auth
      });

      try {
        // جلب الاسم من Firestore (من كولكشن users)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _name = userDoc['name'] ?? "مستخدم PalPet";
            // يمكنك هنا أيضاً جلب الصورة إذا كنت قد حفظتها في الداتابيس
          });
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  // دالة تسجيل الخروج
  void _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        // العودة لصفحة تسجيل الدخول وحذف كل الصفحات السابقة من المكدس
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل تسجيل الخروج: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_photoUrl),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            
            // عرض الاسم الحقيقي
            Text(
              _name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            // عرض الإيميل الحقيقي
            Text(
              _email,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard("My Pets", "0"), // مؤقتاً 0 حتى نبرمج إضافة الحيوانات
                  const SizedBox(width: 16),
                  _buildStatCard("Bookings", "0"),
                  const SizedBox(width: 16),
                  _buildStatCard("Reviews", "0"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "General",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ProfileMenuItem(
                    title: "Edit Profile",
                    icon: Icons.person_outline,
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    title: "My Pets",
                    icon: Icons.pets_outlined,
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    title: "My Appointments",
                    icon: Icons.calendar_today_outlined,
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    title: "Favorites",
                    icon: Icons.favorite_border,
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Settings",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ProfileMenuItem(
                    title: "Notifications",
                    icon: Icons.notifications_none,
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    title: "Language",
                    icon: Icons.language,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  
                  // زر تسجيل الخروج
                  ProfileMenuItem(
                    title: "Log Out",
                    icon: Icons.logout,
                    isLogout: true,
                    onTap: _handleLogout, // تم ربط الدالة هنا
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
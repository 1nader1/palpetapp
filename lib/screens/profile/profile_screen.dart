import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart'; 
import 'widgets/profile_menu_item.dart';
import '../profile/widgets/edit_profile_screen.dart';

// Import your target screens here
// import 'edit_profile_screen.dart';
// import 'user_posts_screen.dart';
// import 'my_appointments_screen.dart';
// import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _name = "loading...";
  String _email = "";
  String _photoUrl = "https://cdn-icons-png.flaticon.com/128/1077/1077114.png";
  
  int _myPostsCount = 0;
  int _favoritesCount = 0;
  int _appointmentsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initDynamicData();
  }

  void _initDynamicData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {

      _databaseService.getUserPets(user.uid).listen((pets) {
        if (mounted) setState(() => _myPostsCount = pets.length);
      });


      _databaseService.getFavoritesCount(user.uid).listen((count) {
        if (mounted) setState(() => _favoritesCount = count);
      });


      _databaseService.getAppointmentsCount(user.uid).listen((count) {
        if (mounted) setState(() => _appointmentsCount = count);
      });
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _email = user.email ?? "");
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _name = userDoc['name'] ?? "palpet user";
          });
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  void _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("logout failure: $e")),
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
            _buildHeader(),
            const SizedBox(height: 60),
            Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(_email, style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
            const SizedBox(height: 24),
            
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard("My Posts", _myPostsCount.toString()),
                  const SizedBox(width: 16),
                  _buildStatCard("Appointments", _appointmentsCount.toString()),
                  const SizedBox(width: 16),
                  _buildStatCard("Favorites", _favoritesCount.toString()),
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
                    child: Text("General", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const SizedBox(height: 12),
                  
                  // Dynamic Menu Items
                  ProfileMenuItem(
                    title: "Edit Profile",
                    icon: Icons.person_outline,
                    onTap: ()  {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    },
                  ),
                  ProfileMenuItem(
                    title: "My Posts",
                    icon: Icons.dynamic_feed_outlined,
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPostsScreen()));
                    },
                  ),
                  ProfileMenuItem(
                    title: "My Appointments",
                    icon: Icons.calendar_today_outlined,
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()));
                    },
                  ),
                  ProfileMenuItem(
                    title: "Favorites",
                    icon: Icons.favorite_border,
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                    },
                  ),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const SizedBox(height: 12),
                  ProfileMenuItem(title: "Notifications", icon: Icons.notifications_none, onTap: () {}),
                  ProfileMenuItem(title: "Language", icon: Icons.language, onTap: () {}),
                  const SizedBox(height: 12),
                  ProfileMenuItem(title: "Log Out", icon: Icons.logout, isLogout: true, onTap: _handleLogout),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: CircleAvatar(radius: 60, backgroundImage: NetworkImage(_photoUrl)),
          ),
        ),
      ],
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
        ),
        child: Column(
          children: [
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
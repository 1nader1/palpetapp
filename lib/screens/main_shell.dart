import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'adoption/adoption_screen.dart';
import 'lost_found/lost_found_screen.dart';
import 'hotel/pet_hotels_screen.dart';
import 'clinics/clinics_screen.dart'; 
// 1. إضافة استيراد صفحة الإشعارات
import 'notifications/notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // 0
    const Center(child: Text("Add Post")), // 1
    const Center(child: Text("Profile")), // 2
    const AdoptionScreen(), // 3
    const LostFoundScreen(), // 4
    const PetHotelsScreen(), // 5
    const ClinicsScreen(), // 6
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(Icons.pets, color: AppColors.primary, size: 32),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.language), onPressed: () {}),
          
          // 2. تفعيل زر الإشعارات هنا
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // --- القائمة الجانبية (Drawer) ---
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('PalPet Menu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
            ),

            // 1. Home
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),

            // 2. Adoption
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Adoption'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),

            // 3. Lost & Found
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Lost & Found'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 4);
              },
            ),

            // 4. Pet Hotels
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Pet Hotels'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 5;
                });
              },
            ),

            // 5. Vet Clinics
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Vet Clinics'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 6;
                });
              },
            ),
          ],
        ),
      ),

      body: _screens[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBarBackground,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add, size: 32),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              activeIcon: Icon(Icons.person, size: 28),
              label: '',
            ),
          ],

          currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
          selectedItemColor: _selectedIndex > 2
              ? AppColors.textDark.withOpacity(0.6)
              : AppColors.textDark,
          unselectedItemColor: AppColors.textDark.withOpacity(0.6),
          backgroundColor: Colors.transparent,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
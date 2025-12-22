import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'adoption/adoption_screen.dart';
import 'lost_found/lost_found_screen.dart';
import 'hotel/pet_hotels_screen.dart';
<<<<<<< HEAD
import 'clinics/clinics_screen.dart';
import 'profile/profile_screen.dart';
import 'add_post/add_post_screen.dart';

=======
import 'clinics/clinics_screen.dart'; 
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
>>>>>>> 0f777b44c11b2f7b5c5d81a72d1e75feb7c65558
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
<<<<<<< HEAD
    const HomeScreen(),
    const AddPostScreen(),
    const ProfileScreen(),
    const AdoptionScreen(),
    const LostFoundScreen(),
    const PetHotelsScreen(),
    const ClinicsScreen(),
=======
    const HomeScreen(), 
    const Center(child: Text("Add Post")), 
    const ProfileScreen () , 
    const AdoptionScreen(), 
    const LostFoundScreen(), 
    const PetHotelsScreen(), 
    const ClinicsScreen(), 
>>>>>>> 0f777b44c11b2f7b5c5d81a72d1e75feb7c65558
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
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.pets, color: AppColors.primary, size: 32),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.language), onPressed: () {}),
          
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
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Adoption'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Lost & Found'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 4);
              },
            ),
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

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'adoption/adoption_screen.dart'; // 1. استيراد الصفحة

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // 2. تحديث القائمة لإضافة صفحة التبني كعنصر رابع (Index 3)
  final List<Widget> _screens = [
    const HomeScreen(),           // Index 0
    const Center(child: Text("Add Post Screen")), // Index 1 (كما طلبت لم نعدل عليه)
    const Center(child: Text("Profile Screen")),  // Index 2
    const AdoptionScreen(),       // Index 3 (Adoption)
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
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
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
                child: Text('PalPet Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // إغلاق القائمة
                _onItemTapped(0); // الذهاب للرئيسية
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Adoption'),
              onTap: () {
                Navigator.pop(context); // إغلاق القائمة
                // 3. هنا نقوم بتغيير الصفحة إلى التبني (Index 3)
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),
          ],
        ),
      ),
      
      body: _screens[_selectedIndex], // يعرض الصفحة المختارة

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
          // 4. خدعة برمجية:
          // بما أن لدينا 3 أزرار فقط، ولكن قد يكون الـ Index المختار هو 3 (Adoption)
          // يجب أن نخبر النافيجيشن بار أن يحدد العنصر الأول (أو أي عنصر) شكلياً فقط
          // أو يمكننا عدم تحديد أي شيء بجعل النوع fixed
          currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex, 
          
          // هنا نغير اللون لنجعل الأيقونات تبدو غير مختارة إذا كنا في صفحة التبني
          selectedItemColor: _selectedIndex > 2 
              ? AppColors.textDark.withOpacity(0.6) // لون باهت إذا كنا في التبني
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
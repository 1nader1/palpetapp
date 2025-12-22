import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/lost_found_card.dart';
import 'lost_found_details_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  // متغيرات الحالة
  int _selectedFilterIndex = 0;
  String? _selectedPetType;
  String _searchQuery = ""; // متغير البحث
  final TextEditingController _searchController = TextEditingController();

  // البيانات الوهمية
  final List<Map<String, dynamic>> _alerts = [
    {
      "name": "Buddy",
      "date": "Oct 15, 2023",
      "location": "Al-Jibeh, near the central park, Amman",
      "image": "https://images.unsplash.com/photo-1591769225440-811ad7d6eca6?auto=format&fit=crop&w=800&q=80",
      "isLost": true, 
      "type": "Dog",
      "description": "Buddy is a very friendly Golden Retriever. He was wearing a red collar with a tag. He got lost while we were walking near the park. He loves food and answers to his name immediately.",
      "contactPhone": "0791234567"
    },
    {
      "name": "Mimi",
      "date": "Oct 17, 2023",
      "location": "Nablus, Downtown area near the market",
      "image": "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80",
      "isLost": false, 
      "type": "Cat",
      "description": "Found this white cat near the market. She looks domestic and well-fed. She has no collar but is very tame.",
      "contactPhone": "0599123456"
    },
    {
      "name": "Rocky",
      "date": "Oct 18, 2023",
      "location": "Amman, 7th Circle, near Safeway",
      "image": "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80",
      "isLost": true, 
      "type": "Dog",
      "description": "Small black puppy, looks scared. Ran away from home in the evening. Please call if seen.",
      "contactPhone": "0771234567"
    },
  ];

  // منطق الفلترة والبحث
  List<Map<String, dynamic>> get _filteredAlerts {
    return _alerts.where((item) {
      // 1. فلترة الحالة (Lost/Found)
      if (_selectedFilterIndex == 1 && item['isLost'] == false) return false;
      if (_selectedFilterIndex == 2 && item['isLost'] == true) return false;

      // 2. فلترة النوع (Type)
      if (_selectedPetType != null &&
          _selectedPetType != "All Pet Types" &&
          item['type'] != _selectedPetType) return false;

      // 3. فلترة البحث (Search Query)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = item['name'].toString().toLowerCase();
        final location = item['location'].toString().toLowerCase();
        
        // إذا كان الاسم والموقع لا يحتويان على نص البحث، استبعد العنصر
        if (!name.contains(query) && !location.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header Banner ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bannerGradientStart,
                    AppColors.bannerGradientEnd
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "Lost & Found",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Report lost pets or help reunite\nfound animals with their owners",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark.withOpacity(0.7),
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildActionButton("Report Lost Pet",
                              AppColors.lostRed, Icons.warning_amber_rounded)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildActionButton(
                              "Report Found Pet",
                              AppColors.foundGreen,
                              Icons.check_circle_outline)),
                    ],
                  )
                ],
              ),
            ),

            // --- Filters & Search ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem("All Alerts", 0),
                        _buildTabItem("Lost Pets", 1, activeColor: AppColors.lostRed),
                        _buildTabItem("Found Pets", 2, activeColor: AppColors.foundGreen),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPetType,
                        hint: const Text("Pet Type"),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        items: [
                          "All Pet Types",
                          "Dog",
                          "Cat",
                          "Bird",
                          "Rabbit",
                          "Other"
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          setState(() => _selectedPetType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      // تحديث الحالة عند الكتابة لتفعيل البحث
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search name, location...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- List ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _filteredAlerts.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No results found.", style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredAlerts.length,
                itemBuilder: (context, index) {
                  final item = _filteredAlerts[index];

                  // هذا هو الجزء الذي يحل المشكلة في السطر 257
                  // أزلنا GestureDetector واستخدمنا onViewDetails
                  return LostFoundCard(
                    name: item['name'],
                    date: item['date'],
                    location: item['location'],
                    imageUrl: item['image'],
                    isLost: item['isLost'],
                    // هنا نمرر كود التنقل للزر الجديد داخل الكارد
                    onViewDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LostFoundDetailsScreen(data: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildActionButton(String label, Color color, IconData icon) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index,
      {Color activeColor = AppColors.textDark}) {
    final bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
              color: isSelected ? activeColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import '../add_post/add_post_screen.dart'; // لاستدعاء شاشة الإضافة
import 'widgets/lost_found_card.dart';
import 'lost_found_details_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  // متغيرات الحالة
  int _selectedFilterIndex = 0; // 0=All, 1=Lost, 2=Found
  String? _selectedPetType;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // تيار البيانات من الفايربيس
  late Stream<List<Pet>> _petsStream;

  @override
  void initState() {
    super.initState();
    // جلب البيانات مرة واحدة عند الفتح
    _petsStream = DatabaseService().getPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // دالة مساعدة لتنسيق التاريخ يدوياً (بدون مكتبة intl)
  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown Date";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<Pet>>(
          stream: _petsStream,
          builder: (context, snapshot) {
            // 1. حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. تصفية البيانات (Logic)
            List<Pet> displayList = [];
            if (snapshot.hasData) {
              final allPets = snapshot.data!;

              displayList = allPets.where((pet) {
                // أ. قبول فقط أنواع Lost و Found (تجاهل التبني والفنادق)
                if (pet.postType != 'Lost' &&
                    pet.postType != 'Found' &&
                    pet.postType != 'lost' &&
                    pet.postType != 'found') {
                  return false;
                }

                // ب. فلترة التبويب (Tabs: All vs Lost vs Found)
                if (_selectedFilterIndex == 1 &&
                    pet.postType.toLowerCase() != 'lost') return false;
                if (_selectedFilterIndex == 2 &&
                    pet.postType.toLowerCase() != 'found') return false;

                // ج. فلترة نوع الحيوان (Dropdown)
                if (_selectedPetType != null &&
                    _selectedPetType != "All Pet Types" &&
                    pet.type != _selectedPetType) return false;

                // د. فلترة البحث (Search)
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  final name = pet.name.toLowerCase();
                  final location = pet.location.toLowerCase();
                  if (!name.contains(query) && !location.contains(query)) {
                    return false;
                  }
                }

                return true;
              }).toList();
            }

            // 3. بناء الواجهة
            return SingleChildScrollView(
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
                        // أزرار الإبلاغ
                        Row(
                          children: [
                            Expanded(
                                child: _buildActionButton(
                              context,
                              "Report Lost Pet",
                              AppColors.lostRed,
                              Icons.warning_amber_rounded,
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildActionButton(
                              context,
                              "Report Found Pet",
                              AppColors.foundGreen,
                              Icons.check_circle_outline,
                            )),
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
                              _buildTabItem("Lost Pets", 1,
                                  activeColor: AppColors.lostRed),
                              _buildTabItem("Found Pets", 2,
                                  activeColor: AppColors.foundGreen),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Type
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
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                              items: [
                                "All Pet Types",
                                "Dog",
                                "Cat",
                                "Bird",
                                "Rabbit",
                                "Other"
                              ]
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
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
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search name, location...",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
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
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- List (Real Data) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: displayList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text("No alerts found.",
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final pet = displayList[index];
                              final bool isLost =
                                  pet.postType.toLowerCase() == 'lost';
                              final String formattedDate =
                                  _formatDate(pet.createdAt);

                              return LostFoundCard(
                                name: pet.name,
                                date: formattedDate,
                                location: pet.location,
                                imageUrl: pet.imageUrl,
                                isLost: isLost,
                                onViewDetails: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LostFoundDetailsScreen(pet: pet),
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
            );
          }),
    );
  }

  // Helper Widgets
  Widget _buildActionButton(
      BuildContext context, String label, Color color, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPostScreen()),
        );
      },
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
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

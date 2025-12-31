import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import 'widgets/hotel_card.dart';
import 'hotel_details_screen.dart';
import 'widgets/hotel_card_skeleton.dart'; // [مهم] تأكد من استيراد السكيلتون

class PetHotelsScreen extends StatefulWidget {
  const PetHotelsScreen({super.key});

  @override
  State<PetHotelsScreen> createState() => _PetHotelsScreenState();
}

class _PetHotelsScreenState extends State<PetHotelsScreen> {
  String? _selectedPetType;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late Stream<List<Pet>> _hotelsStream;

  @override
  void initState() {
    super.initState();
    _hotelsStream = DatabaseService().getPets();
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
            // 1. Header (ثابت)
            _buildHeader(),

            // 2. Filters (ثابت)
            _buildFilters(),

            // 3. List Data (متغير)
            _buildListStream(),
          ],
        ),
      ),
    );
  }

  // --- Header Widget ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFA726), // ألوانك المخصصة كما في الكود السابق
            Color(0xFFEF6C00)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Pet Hotels",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Find the perfect stay for your furry friend",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // --- Filters Widget ---
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                hint: const Text("Filter by Pet Type"),
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                items: ["All Types", "Dog", "Cat", "Bird", "Rabbit", "Other"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
              hintText: "Search hotels by name...",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  // --- List Stream Widget ---
  Widget _buildListStream() {
    return StreamBuilder<List<Pet>>(
      stream: _hotelsStream,
      builder: (context, snapshot) {
        
        // 1. حالة التحميل (Shimmer Effect)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3, // عدد بطاقات التحميل الوهمية
            itemBuilder: (context, index) => const HotelCardSkeleton(),
          );
        }

        // 2. معالجة البيانات والفلترة
        List<Pet> displayList = [];
        if (snapshot.hasData) {
          final allPets = snapshot.data!;
          displayList = allPets.where((pet) {
            // أ. تصفية حسب النوع: Hotel فقط
            if (pet.postType != 'Hotel') return false;

            // ب. فلترة حسب نوع الحيوان
            if (_selectedPetType != null && _selectedPetType != "All Types") {
              final List<String> supportedTypes =
                  pet.type.split(',').map((e) => e.trim()).toList();
              if (!supportedTypes.contains(_selectedPetType)) {
                return false;
              }
            }

            // ج. البحث بالاسم
            if (_searchQuery.isNotEmpty) {
              final name = pet.name.toLowerCase();
              final query = _searchQuery.toLowerCase();
              if (!name.contains(query)) {
                return false;
              }
            }
            return true;
          }).toList();
        }

        // 3. حالة عدم وجود بيانات (Empty State Illustration)
        if (displayList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://i.pinimg.com/1200x/85/d6/fe/85d6fe2e402686d661019df7e4c09a30.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) =>
                          const Icon(Icons.hotel_class, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "No Hotels Found",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try adjusting your filters to find\nthe perfect stay.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // 4. عرض القائمة الحقيقية
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final pet = displayList[index];
              List<String> supported =
                  pet.type.split(',').map((e) => e.trim()).toList();

              return HotelCard(
                name: pet.name,
                address: pet.location,
                ownerId: pet.ownerId, // الحفاظ على تعديلك الخاص بـ ownerId
                imageUrl: pet.imageUrl,
                description: pet.description,
                supportedPets: supported,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelDetailsScreen(data: pet.toMap()),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
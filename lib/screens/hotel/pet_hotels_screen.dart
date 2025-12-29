import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import 'widgets/hotel_card.dart';
import 'hotel_details_screen.dart';

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
      body: StreamBuilder<List<Pet>>(
        stream: _hotelsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Pet> displayList = [];
          if (snapshot.hasData) {
            final allPets = snapshot.data!;
            
            displayList = allPets.where((pet) {
              // 1. تصفية حسب النوع: Hotel فقط
              if (pet.postType != 'Hotel') return false;

              // 2. فلترة حسب نوع الحيوان
              if (_selectedPetType != null && _selectedPetType != "All Types") {
                final List<String> supportedTypes = pet.type.split(',').map((e) => e.trim()).toList();
                if (!supportedTypes.contains(_selectedPetType)) {
                  return false;
                }
              }

              // 3. البحث بالاسم
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFA726),
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
                            color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Find the perfect stay for your furry friend",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
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
                            icon: const Icon(Icons.filter_list,
                                color: AppColors.primary),
                            items: ["All Types", "Dog", "Cat", "Bird", "Rabbit", "Other"]
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedPetType = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search hotels by name...",
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 14),
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
                ),

                // List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: displayList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text("No hotels found matching your search.",
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final pet = displayList[index];

                            List<String> supported = pet.type.split(',').map((e) => e.trim()).toList();

                            return HotelCard(
                              name: pet.name,
                              address: pet.location, 
                              // --- التعديل هنا ---
                              // حذفنا rating: 0.0
                              // أضفنا ownerId بدلاً منه
                              ownerId: pet.ownerId, 
                              // -------------------
                              imageUrl: pet.imageUrl,
                              description: pet.description,
                              supportedPets: supported,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          HotelDetailsScreen(data: pet.toMap())),
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
        }
      ),
    );
  }
}
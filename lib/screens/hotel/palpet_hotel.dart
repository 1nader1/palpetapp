import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/hotel_card.dart';
import 'hotel_details_screen.dart';

class PetHotelsScreen extends StatefulWidget {
  const PetHotelsScreen({super.key});

  @override
  State<PetHotelsScreen> createState() => _PetHotelsScreenState();
}

class _PetHotelsScreenState extends State<PetHotelsScreen> {
  // متغيرات الحالة
  String? _selectedPetType;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _hotels = [
    {
      "name": "Paws Luxury Resort",
      "address": "Dabouq, Amman",
      "price": "25 JD",
      "rating": 4.8,
      "supportedPets": ["Dog"],
      "description":
          "The finest luxury hotel for dogs in Amman. Huge play areas, swimming pools, and professional trainers available 24/7.",
      "image":
          "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=800&q=80",
      "amenities": ["Grooming", "Pool", "Webcam", "AC Rooms", "Training"],
      "phone": "+962 79 111 2222"
    },
    {
      "name": "Cozy Tails Inn",
      "address": "Abdoun, Amman",
      "price": "18 JD",
      "rating": 4.5,
      "supportedPets": ["Cat"],
      "description":
          "A quiet and peaceful sanctuary for your feline friends. Soundproof rooms and plenty of climbing structures.",
      "image":
          "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80",
      "amenities": ["Daily Walks", "Organic Food", "Vet on Call", "Toy Room"],
      "phone": "+962 79 333 4444"
    },
    {
      "name": "Happy Pet Hotel",
      "address": "Irbid City Center",
      "price": "15 JD",
      "rating": 4.2,
      "supportedPets": ["Dog", "Cat"],
      "description":
          "Affordable and friendly care for all pets. Separate wings for dogs and cats to ensure comfort for everyone.",
      "image":
          "https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=800&q=80",
      "amenities": ["Large Play Area", "Group Play", "Basic Grooming"],
      "phone": "+962 79 555 6666"
    },
  ];

  List<Map<String, dynamic>> get _filteredHotels {
    return _hotels.where((hotel) {
      // أ. فلترة النوع (Dropdown)
      final List<String> supported = hotel['supportedPets'];
      if (_selectedPetType != null && _selectedPetType != "All Types") {
        if (!supported.contains(_selectedPetType)) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final name = hotel['name'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        // إذا الاسم لا يحتوي على نص البحث، استبعد العنصر
        if (!name.contains(query)) {
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
            // --- 1. Header Banner ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFA726),
                    Color(0xFFEF6C00)
                  ], // Gradient البرتقالي
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

            // --- 2. Filters & Search ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Dropdown Filter
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
                        items: ["All Types", "Dog", "Cat", "Bird"]
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

                  // Search Field (تم التعديل هنا ليعمل)
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      // 3. تحديث الحالة عند الكتابة
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

            // --- 3. Hotel List ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _filteredHotels.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text("No hotels found matching your search.",
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredHotels.length,
                      itemBuilder: (context, index) {
                        final hotel = _filteredHotels[index];

                        return HotelCard(
                          name: hotel['name'],
                          address: hotel['address'],
                          rating: hotel['rating'],
                          imageUrl: hotel['image'],
                          description: hotel['description'],
                          supportedPets: hotel['supportedPets'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      HotelDetailsScreen(data: hotel)),
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
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart'; // تأكد من وجود هذا الاستيراد
import 'pet_details_screen.dart';
import 'widgets/adoption_pet_card.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  // متغير لتخزين تيار البيانات (Stream) لمنع إعادة التحميل عند البحث
  late Stream<List<Pet>> _petsStream;

  // متغيرات الفلترة
  String _searchQuery = "";
  String? _selectedType;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    // تهيئة الاستماع للداتا بيس مرة واحدة عند فتح الشاشة
    _petsStream = DatabaseService().getPets();
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم StreamBuilder للاستماع للبيانات القادمة من الفايربيس
    return StreamBuilder<List<Pet>>(
      stream: _petsStream,
      builder: (context, snapshot) {
        
        // 1. حالة التحميل: إظهار دائرة تحميل داخل نفس التصميم
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        // 2. معالجة البيانات وتطبيق الفلترة
        List<Pet> filteredPets = [];
        if (snapshot.hasData) {
          final allPets = snapshot.data!;
          
          filteredPets = allPets.where((pet) {
            // أولاً: التأكد أن البوست من نوع "تبني" (Adoption)
            if (pet.postType != 'Adoption') return false;

            // ثانياً: البحث بالاسم أو الفصيلة
            final matchesSearch = _searchQuery.isEmpty ||
                pet.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                pet.breed.toLowerCase().contains(_searchQuery.toLowerCase());
            
            // ثالثاً: فلتر النوع (كلب، قطة...)
            final matchesType = _selectedType == null || _selectedType == "All" || pet.type == _selectedType;
            
            // رابعاً: فلتر الجنس
            final matchesGender = _selectedGender == null || _selectedGender == "All" || pet.gender == _selectedGender;

            return matchesSearch && matchesType && matchesGender;
          }).toList();
        }

        // 3. بناء الواجهة (نفس تصميمك الأصلي)
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: AppColors.adoptionHeader,
              ),
              child: Column(
                children: [
                  const Text(
                    "Find Your Perfect\nCompanion",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Browse pets looking for a forever\nhome",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Filters and List Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Type Filter
                  _buildDropdown(
                    hint: "Pet Type",
                    value: _selectedType,
                    items: ["All", "Dog", "Cat", "Bird", "Other"], 
                    onChanged: (val) {
                      setState(() {
                        _selectedType = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender Filter
                  _buildDropdown(
                    hint: "Gender",
                    value: _selectedGender,
                    items: ["All", "Male", "Female"], 
                    onChanged: (val) {
                      setState(() {
                        _selectedGender = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextFormField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search by name, breed...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Results List
                  if (filteredPets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        // رسالة مختلفة حسب الحالة
                        snapshot.hasData 
                            ? "No pets found matching your criteria." 
                            : "Loading pets...",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...filteredPets.map((pet) => AdoptionPetCard(
                      name: pet.name,
                      age: pet.age,
                      gender: pet.gender,
                      breed: pet.breed,
                      description: pet.description,
                      imageUrl: pet.imageUrl,
                      tags: pet.healthTags, // ستظهر فارغة للمنشورات الجديدة إذا لم تضف تاجز
                      onViewDetails: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PetDetailsScreen(pet: pet)),
                        );
                      },
                    )).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: AppColors.textDark)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
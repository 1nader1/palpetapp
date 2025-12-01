import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import 'pet_details_screen.dart';
import 'widgets/adoption_pet_card.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {

  final List<Pet> _allPets = [
    Pet(
      name: "Luna",
      type: "Cat",
      gender: "Female",
      breed: "Siamese",
      age: "1 year",
      description: "Quiet and affectionate Siamese cat. Prefers a calm household.",
      imageUrl: "https://images.unsplash.com/photo-1513245543132-31f507417b26?auto=format&fit=crop&w=800&q=80",
      healthTags: ["Vaccinated", "Neutered/Spayed"],
      location: "AMMAN, JORDAN",
      contactPhone: "+962 79 123 4567",
      contactEmail: "adoption@palpet.com",
    ),
    Pet(
      name: "Max",
      type: "Dog",
      gender: "Male",
      breed: "Golden Retriever",
      age: "1 year 6 months",
      description: "Friendly and playful golden retriever. Good with children and other pets.",
      imageUrl: "https://images.unsplash.com/photo-1633722715463-d30f4f325e24?auto=format&fit=crop&w=800&q=80",
      healthTags: ["Vaccinated", "Neutered/Spayed"],
      location: "AMMAN, JORDAN",
      contactPhone: "+962 79 123 4567",
      contactEmail: "adoption@palpet.com",
    ),
    Pet(
      name: "Bella",
      type: "Dog",
      gender: "Female",
      breed: "Labrador",
      age: "2 years",
      description: "Energetic and loyal. Loves long walks and playing fetch.",
      imageUrl: "https://images.unsplash.com/photo-1591769225440-811ad7d6eca6?auto=format&fit=crop&w=800&q=80",
      healthTags: ["Vaccinated"],
      location: "IRBID, JORDAN",
      contactPhone: "+962 78 999 8888",
      contactEmail: "rescue@jordanpets.com",
    ),
  ];


  List<Pet> _filteredPets = [];
  String _searchQuery = "";
  String? _selectedType;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _filteredPets = _allPets;
  }


  void _filterPets() {
    setState(() {
      _filteredPets = _allPets.where((pet) {

        final matchesSearch = pet.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            pet.breed.toLowerCase().contains(_searchQuery.toLowerCase());
        

        final matchesType = _selectedType == null || pet.type == _selectedType;
        

        final matchesGender = _selectedGender == null || pet.gender == _selectedGender;

        return matchesSearch && matchesType && matchesGender;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [

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

        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [

              // 1. Pet Type Dropdown
              _buildDropdown(
                hint: "Pet Type",
                value: _selectedType,
                items: ["Dog", "Cat"],
                onChanged: (val) {
                  _selectedType = val;
                  _filterPets();
                },
              ),
              const SizedBox(height: 16),

              // 2. Gender Dropdown
              _buildDropdown(
                hint: "Gender",
                value: _selectedGender,
                items: ["Male", "Female"],
                onChanged: (val) {
                  _selectedGender = val;
                  _filterPets();
                },
              ),
              const SizedBox(height: 16),

              // 3. Search Field
              TextFormField(
                onChanged: (val) {
                  _searchQuery = val;
                  _filterPets();
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


              if (_filteredPets.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No pets found matching your criteria.", style: TextStyle(color: Colors.grey)),
                )
              else
                ..._filteredPets.map((pet) => GestureDetector(
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PetDetailsScreen(pet: pet)),
                    );
                  },
                  child: AbsorbPointer(
                    child: AdoptionPetCard(
                      name: pet.name,
                      age: pet.age,
                      gender: pet.gender,
                      breed: pet.breed,
                      description: pet.description,
                      imageUrl: pet.imageUrl,
                      tags: pet.healthTags,
                    ),
                  ),
                )).toList(),
            ],
          ),
        ),
      ],
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
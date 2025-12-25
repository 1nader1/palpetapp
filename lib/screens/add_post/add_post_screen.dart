import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palpet/core/constants/app_colors.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/services/auth_service.dart';
import 'package:palpet/services/database_service.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  bool _isLoading = false;
  
  File? _selectedImage;
  String _selectedType = 'Adoption';
  final List<String> _postTypes = ['Adoption', 'Lost', 'Found', 'Hotel'];

  // --- القوائم ---
  final List<String> _speciesList = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Hamster', 'Turtle', 'Other'];
  final List<String> _genderList = ['Male', 'Female'];

  // --- متغيرات الاختيار ---
  String? _selectedSpecies; // للأنواع العادية (اختيار واحد)
  List<String> _selectedHotelSpecies = []; // للفنادق (اختيار متعدد)
  String? _selectedGender;

  // --- Controllers ---
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Adoption Specific
  final _ageController = TextEditingController();
  
  // Health Tags
  final _healthTagController = TextEditingController(); 
  final List<String> _healthTags = []; 

  // Lost/Found Specific
  final _phoneController = TextEditingController();
  final _rewardController = TextEditingController();
  
  // Hotel Specific
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  
  // Amenities
  final _amenitiesInputController = TextEditingController();
  final List<String> _amenities = [];

  final String _defaultImageUrl = 'https://via.placeholder.com/300?text=No+Image';

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    _healthTagController.dispose();
    _phoneController.dispose();
    _rewardController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _amenitiesInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // --- Helper Functions ---
  void _addHealthTag() {
    final text = _healthTagController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _healthTags.add(text);
        _healthTagController.clear();
      });
    }
  }

  void _removeHealthTag(String tag) {
    setState(() {
      _healthTags.remove(tag);
    });
  }

  void _addAmenity() {
    final text = _amenitiesInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _amenities.add(text);
        _amenitiesInputController.clear();
      });
    }
  }

  void _removeAmenity(String item) {
    setState(() {
      _amenities.remove(item);
    });
  }

  // --- دالة إظهار نافذة الاختيار المتعدد للفنادق ---
  void _showMultiSelectDialog() async {
    final List<String> tempSelected = List.from(_selectedHotelSpecies);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Accepted Species"),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _speciesList.map((item) {
                    return CheckboxListTile(
                      value: tempSelected.contains(item),
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            tempSelected.add(item);
                          } else {
                            tempSelected.remove(item);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    // حفظ الاختيارات
                    this.setState(() {
                      _selectedHotelSpecies = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- دالة النشر ---
  Future<void> _submitPost() async {
    FocusScope.of(context).unfocus();

    // 1. التحقق من الحقول الأساسية
    bool basicInfoFilled = _nameController.text.isNotEmpty && 
                           _locationController.text.isNotEmpty && 
                           _descriptionController.text.isNotEmpty;

    // 2. التحقق من اختيار النوع
    bool speciesSelected = false;
    if (_selectedType == 'Hotel') {
      speciesSelected = _selectedHotelSpecies.isNotEmpty;
    } else {
      speciesSelected = _selectedSpecies != null;
    }

    if (!basicInfoFilled || !speciesSelected) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please fill basic info & select species'))
       );
       return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception("User not logged in");

      String imageUrl = _defaultImageUrl; 
      
      if (_selectedImage != null) {
        imageUrl = await DatabaseService().uploadImage(_selectedImage!);
      }

      String? amenitiesString;
      if (_amenities.isNotEmpty) {
        amenitiesString = _amenities.join(','); 
      }

      // تحديد النوع
      String finalTypeValue = '';
      if (_selectedType == 'Hotel') {
        finalTypeValue = _selectedHotelSpecies.join(',');
      } else {
        finalTypeValue = _selectedSpecies!;
      }

      Pet newPet = Pet(
        ownerId: user.uid,
        postType: _selectedType,
        name: _nameController.text,
        type: finalTypeValue,
        breed: _breedController.text,
        gender: _selectedGender ?? '', 
        age: _ageController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        location: _locationController.text,
        contactPhone: _phoneController.text,
        healthTags: _healthTags, 
        reward: _rewardController.text.isNotEmpty ? _rewardController.text : null,
        price: _priceController.text.isNotEmpty ? _priceController.text : null,
        capacity: _capacityController.text.isNotEmpty ? _capacityController.text : null,
        amenities: amenitiesString, 
      );

      await DatabaseService().addPet(newPet);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create New Post",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _buildImagePicker(),
              ),

              const SizedBox(height: 24),

              const Text("Post Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTypeSelector(),

              const SizedBox(height: 24),

              const Text("Basic Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTextField(label: "Name (Pet/Hotel)", controller: _nameController, icon: Icons.pets),
              const SizedBox(height: 12),
              
              // --- هنا التغيير الجوهري في العرض ---
              Row(
                children: [
                  Expanded(
                    child: _selectedType == 'Hotel'
                        // إذا كان هوتيل، نعرض القائمة المتعددة بنفس تصميم الدروب داون
                        ? _buildMultiSelectDropdownField()
                        // إذا كان غير ذلك، نعرض الدروب داون العادي
                        : _buildDropdownField(
                            label: "Species", 
                            value: _selectedSpecies,
                            items: _speciesList,
                            icon: Icons.category,
                            onChanged: (val) => setState(() => _selectedSpecies = val),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(label: "Breed/Details", controller: _breedController, icon: Icons.style)),
                ],
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildDynamicFields(),
              ),

              const SizedBox(height: 24),

              const Text("Location & Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTextField(label: "Location / Address", controller: _locationController, icon: Icons.location_on),
              const SizedBox(height: 12),
              _buildTextField(
                label: "Description / Caption",
                controller: _descriptionController,
                icon: Icons.description,
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: const Text("Post Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // --- ويدجت الاختيار المتعدد بتصميم الدروب داون ---
  Widget _buildMultiSelectDropdownField() {
    String displayText = _selectedHotelSpecies.isEmpty 
        ? "Select Species" 
        : _selectedHotelSpecies.join(", ");

    return InkWell(
      onTap: _showMultiSelectDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Accepted Species",
          prefixIcon: const Icon(Icons.category, color: Colors.grey, size: 22),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // سهم صغير ليوحي بأنه قائمة
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 22) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
        image: _selectedImage != null 
          ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
          : null,
      ),
      child: _selectedImage == null 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10)],
                ),
                child: const Icon(Icons.add_a_photo, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text(
                "Add Photo (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          )
        : null,
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _postTypes.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDynamicFields() {
    switch (_selectedType) {
      case 'Adoption':
        return Column(
          key: const ValueKey('Adoption'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Adoption Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(label: "Age", controller: _ageController, icon: Icons.cake)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField(
                    label: "Gender",
                    value: _selectedGender,
                    items: _genderList,
                    icon: Icons.male,
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(label: "Contact Phone", controller: _phoneController, icon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildHealthTagsInput(),
          ],
        );
      case 'Lost':
      case 'Found':
        return Column(
          key: const ValueKey('LostFound'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Contact & Reward", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTextField(label: "Contact Phone Number", controller: _phoneController, icon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(label: "Reward (Optional)", controller: _rewardController, icon: Icons.monetization_on_outlined),
          ],
        );
      case 'Hotel':
        return Column(
          key: const ValueKey('Hotel'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hotel Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(label: "Price / Night", controller: _priceController, icon: Icons.attach_money, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: "Capacity", controller: _capacityController, icon: Icons.home_work)),
              ],
            ),
            const SizedBox(height: 12),
            _buildAmenitiesInput(), 
            const SizedBox(height: 12),
            _buildTextField(label: "Contact Phone", controller: _phoneController, icon: Icons.phone, keyboardType: TextInputType.phone),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHealthTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "Health Info (e.g. Vaccinated)",
                controller: _healthTagController,
                icon: Icons.local_hospital,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addHealthTag,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_healthTags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _healthTags.map((tag) => Chip(
              label: Text(tag),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeHealthTag(tag),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildAmenitiesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "Amenities (e.g. Wifi, Pool)",
                controller: _amenitiesInputController,
                icon: Icons.star_border,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addAmenity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_amenities.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _amenities.map((item) => Chip(
              label: Text(item),
              backgroundColor: Colors.orange.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeAmenity(item),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    IconData? icon,
    TextEditingController? controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 22) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
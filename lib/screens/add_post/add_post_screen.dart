import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  String _selectedType = 'Adoption';
  final List<String> _postTypes = ['Adoption', 'Lost', 'Found', 'Hotel'];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(),

            const SizedBox(height: 24),

            const Text("Post Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTypeSelector(),

            const SizedBox(height: 24),

            const Text("Basic Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTextField(label: "Pet Name", controller: _nameController, icon: Icons.pets),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildTextField(label: "Species", icon: Icons.category)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: "Breed", icon: Icons.style)),
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
                onPressed: () {
                },
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

  Widget _buildImagePicker() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
      ),
      child: Column(
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
            "Add Pet Photos",
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            "Up to 5 images",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
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
                Expanded(child: _buildTextField(label: "Age", icon: Icons.cake)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: "Gender", icon: Icons.male)),
              ],
            ),
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
            _buildTextField(label: "Contact Phone Number", icon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(label: "Reward (Optional)", icon: Icons.monetization_on_outlined),
            const SizedBox(height: 12),
            _buildTextField(label: "Last Seen Date/Time", icon: Icons.access_time),
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
                Expanded(child: _buildTextField(label: "Price / Night", icon: Icons.attach_money, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: "Capacity", icon: Icons.home_work)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(label: "Amenities", icon: Icons.list),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
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
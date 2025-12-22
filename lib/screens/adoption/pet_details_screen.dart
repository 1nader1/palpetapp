import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';

class PetDetailsScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.favorite_border,
                  color: Colors.red, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Image.network(
                pet.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("About",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(
                    pet.description,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem("Breed", pet.breed)),
                      Expanded(child: _buildInfoItem("Age", pet.age)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Health",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: pet.healthTags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(tag,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textGrey)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Location",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(pet.location,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Contact",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.phone_outlined, pet.contactPhone),
                  const SizedBox(height: 8),
                  _buildContactRow(Icons.email_outlined, pet.contactEmail),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Adopt Me",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String info) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 12),
        Text(info,
            style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../home/widgets/pet_card.dart'; 
import '../home/widgets/home_banner.dart'; 
import '../home/widgets/service_card.dart';  

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        
        const HomeBanner(),


        const Center(
          child: Text(
            "Our Services",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "Comprehensive pet care services designed to\nkeep your furry friends happy and healthy",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        GridView.count(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          crossAxisCount: 2, 
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, 
          children: const [
            ServiceCard(
              title: "Adoption",
              subtitle: "Browse pets looking for a forever home",
              icon: Icons.pets,
              backgroundColor: AppColors.serviceAdoptionBg,
            ),
            ServiceCard(
              title: "Lost & Found",
              subtitle: "Report lost pets or help reunite found animals",
              icon: Icons.search,
              backgroundColor: AppColors.serviceLostBg,
            ),
            ServiceCard(
              title: "Vet Clinics",
              subtitle: "Find veterinary clinics near you",
              icon: Icons.local_hospital,
              backgroundColor: AppColors.serviceVetBg,
            ),
            ServiceCard(
              title: "Pet Hotels",
              subtitle: "Safe and comfortable accommodations",
              icon: Icons.house, // أو Icons.home_work
              backgroundColor: AppColors.serviceHotelBg,
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(color: Colors.black12, thickness: 1), 
        const SizedBox(height: 32),
        const Center(
          child: Text(
            "Meet Our Featured Pets",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "These adorable pets are looking for their\nforever homes",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        const PetCard(
          name: "Max",
          breed: "Golden Retriever",
          age: "2 years old",
          description: "Friendly and energetic dog looking for an active family.",
          imageUrl: "https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80",
        ),
        const PetCard(
          name: "Luna",
          breed: "Orange Tabby",
          age: "1 year old",
          description: "Gentle and affectionate cat who loves to cuddle.",
          imageUrl: "https://images.unsplash.com/photo-1574158622682-e40e69881006?auto=format&fit=crop&w=800&q=80",
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
}
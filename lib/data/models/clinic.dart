class Clinic {
  final String id;
  final String name;
  final String address;
  final String description;
  final String imageUrl; 
  final double rating;
  final String phoneNumber;
  final bool isOpen;
  final String workingHours;
  final List<String> services;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.phoneNumber,
    this.isOpen = true,
    this.workingHours = '09:00 AM - 10:00 PM',
    this.services = const ['Vaccination', 'Surgery', 'Dental Care', 'Grooming', 'Emergency'],
  });
}

final List<Clinic> dummyClinics = [
  Clinic(
    id: '1',
    name: 'Elite Vet Clinic',
    address: 'Amman, 7th Circle, St. 20',
    description: 'Elite Vet Clinic provides comprehensive medical and surgical care for your pets. We are equipped with the latest technology to ensure the best treatment.',
    imageUrl: 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?q=80&w=2070',
    rating: 4.8,
    phoneNumber: '0790000000',
    isOpen: true,
  ),
  Clinic(
    id: '2',
    name: 'Pet Care Center',
    address: 'Irbid, University Street',
    description: 'A friendly place for your furry friends with experienced veterinarians available 24/7 for emergencies.',
    imageUrl: 'https://images.unsplash.com/photo-1628009368231-760335298453?q=80&w=2070',
    rating: 4.5,
    phoneNumber: '0780000000',
    isOpen: false,
  ),
];
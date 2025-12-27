class Clinic {
  final String id;
  final String ownerId; // [جديد] معرف صاحب المنشور
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
    required this.ownerId, // [جديد]
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

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId, // حفظ المعرف في قاعدة البيانات
      'name': name,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'phoneNumber': phoneNumber,
      'isOpen': isOpen,
      'workingHours': workingHours,
      'services': services,
    };
  }
}

// بيانات وهمية للاختبار (اختياري)
final List<Clinic> dummyClinics = [
  Clinic(
    id: '1',
    ownerId: 'admin_id',
    name: 'Elite Vet Clinic',
    address: 'Amman, 7th Circle, St. 20',
    description: 'Elite Vet Clinic provides comprehensive medical and surgical care for your pets.',
    imageUrl: 'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?q=80&w=2070',
    rating: 4.8,
    phoneNumber: '0790000000',
    isOpen: true,
  ),
];
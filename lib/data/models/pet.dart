class Pet {
  final String name;
  final String type; // Dog, Cat, etc.
  final String gender;
  final String breed;
  final String age;
  final String description;
  final String imageUrl;
  final List<String> healthTags; // Vaccinated, etc.
  final String location;
  final String contactPhone;
  final String contactEmail;

  Pet({
    required this.name,
    required this.type,
    required this.gender,
    required this.breed,
    required this.age,
    required this.description,
    required this.imageUrl,
    required this.healthTags,
    required this.location,
    required this.contactPhone,
    required this.contactEmail,
  });
}
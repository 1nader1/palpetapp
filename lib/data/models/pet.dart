class Pet {
  final String id; // ضروري للتعامل مع الحذف والتعديل لاحقاً
  final String name;
  final String type;
  final String gender;
  final String breed;
  final String age;
  final String description;
  final String imageUrl;
  final List<String> healthTags;
  final String location;
  final String contactPhone;
  final String contactEmail;

  Pet({
    this.id = '', // قيمة افتراضية
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

  // تحويل البيانات من التطبيق إلى فايربيس (إرسال)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'gender': gender,
      'breed': breed,
      'age': age,
      'description': description,
      'imageUrl': imageUrl,
      'healthTags': healthTags,
      'location': location,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
    };
  }

  // تحويل البيانات من فايربيس إلى التطبيق (قراءة)
  factory Pet.fromMap(Map<String, dynamic> map, String documentId) {
    return Pet(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      gender: map['gender'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      healthTags: List<String>.from(map['healthTags'] ?? []),
      location: map['location'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/data/models/clinic.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Stream<List<Pet>> getPets() {
    return _db.collection('pets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addPet(Pet pet) async {
    try {
      await _db.collection('pets').add(pet.toMap());
    } catch (e) {
      print("Error adding pet: $e");
      rethrow;
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      await _db.collection('pets').doc(petId).delete();
    } catch (e) {
      print("Error deleting pet: $e");
      rethrow;
    }
  }


Stream<List<Clinic>> getClinics() {
  return _db.collection('clinics').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) {
        final data = doc.data();
        return Clinic(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          phoneNumber: data['phoneNumber'] ?? '',
          isOpen: data['isOpen'] ?? true,
          workingHours: data['workingHours'] ?? '09:00 AM - 10:00 PM',
          // Safety check for List type
          services: (data['services'] is List) 
              ? List<String>.from(data['services']) 
              : [],
        );
      }).toList());
}
}
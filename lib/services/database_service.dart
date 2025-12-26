import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/data/models/clinic.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('pets_images/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Error Uploading Image, try again");
    }
  }

  Stream<List<Pet>> getUserPets(String userId) {
    return _db
        .collection('pets')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<Pet>> getPets() {
    return _db
        .collection('pets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }


  Future<String> addPet(Pet pet) async {
    try {
      DocumentReference docRef = await _db.collection('pets').add(pet.toMap());
      return docRef.id;
    } catch (e) {
      print("Error adding pet: $e");
      rethrow;
    }
  }

  Future<void> deletePet(String petId) async {
    await _db.collection('pets').doc(petId).delete();
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
            services: (data['services'] is List) ? List<String>.from(data['services']) : [],
          );
        }).toList());
  }


  Stream<int> getFavoritesCount(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getAppointmentsCount(String userId) {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
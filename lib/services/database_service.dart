import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/data/models/clinic.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. User Profile Functions ---
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String username,
    required String location,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'name': name,
        'username': username.toLowerCase(),
        'location': location,
      });
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception("Failed to update profile information.");
    }
  }

  // --- 2. Image Upload ---
  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('pets_images/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Failed to upload image.");
    }
  }

  // --- 3. Pet Functions (CRUD) ---

  // Get all pets (Global feed)
  Stream<List<Pet>> getPets() {
    return _db.collection('pets').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Pet.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // NEW: Get pets specific to a user (My Posts)
  Stream<List<Pet>> getUserPets(String uid) {
    return _db.collection('pets')
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Pet.fromMap(doc.data(), doc.id)).toList();
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

  // NEW: Update an existing pet
  Future<void> updatePet(Pet pet) async {
    try {
      await _db.collection('pets').doc(pet.id).update(pet.toMap());
    } catch (e) {
      print("Error updating pet: $e");
      throw Exception("Failed to update post.");
    }
  }

  Future<void> deletePet(String petId) async {
    await _db.collection('pets').doc(petId).delete();
  }

  Future<Pet?> getPetById(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection('pets').doc(id).get();
      if (doc.exists) {
        return Pet.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error getting pet: $e");
    }
    return null;
  }

  // --- 4. Clinics & Notifications (Existing) ---
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

  Future<void> checkAndSendNotifications(Pet newPet, String petId) async {
    try {
      if (newPet.postType == 'Found') {
        final matchesSnapshot = await _db
            .collection('pets')
            .where('postType', isEqualTo: 'Lost')
            .where('type', isEqualTo: newPet.type)
            .where('location', isEqualTo: newPet.location)
            .get();

        for (var doc in matchesSnapshot.docs) {
          final lostPetData = doc.data();
          final ownerId = lostPetData['ownerId'];
          if (ownerId != newPet.ownerId) {
            await _createNotification(
              userId: ownerId,
              title: "Possible Match! 🐾",
              body: "A ${newPet.type} was found in ${newPet.location} matching your lost pet.",
              petId: petId,
              notificationType: 'found_match',
            );
          }
        }
      }

      if (newPet.postType == 'Lost') {
        final usersInAreaSnapshot = await _db
            .collection('users')
            .where('location', isEqualTo: newPet.location)
            .get();

        for (var doc in usersInAreaSnapshot.docs) {
          final targetUserId = doc.id;
          if (targetUserId != newPet.ownerId) {
            await _createNotification(
              userId: targetUserId,
              title: "Lost Pet Alert 🚨",
              body: "A ${newPet.type} was lost in your area (${newPet.location}). Help find them!",
              petId: petId,
              notificationType: 'lost_alert',
            );
          }
        }
      }
    } catch (e) {
      print("Error sending notifications: $e");
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String petId,
    required String notificationType,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'petId': petId,
      'type': notificationType,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
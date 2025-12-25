import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/data/models/clinic.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. دالة رفع الصور ---
  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('pets_images/$fileName.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("فشل في رفع الصورة، يرجى المحاولة مرة أخرى.");
    }
  }

  // --- 2. دوال الحيوانات ---

  Stream<List<Pet>> getPets() {
    return _db.collection('pets').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Pet.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // تعديل: الدالة الآن ترجع ID المستند الجديد لاستخدامه في الإشعار
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

  // دالة جديدة: جلب حيوان معين عن طريق الـ ID (لصفحة الإشعارات)
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

  // --- 3. دوال العيادات ---
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

  // --- 4. دوال الإشعارات الذكية ---

  // إضافة petId للمعاملات لربط الإشعار بالبوست
  Future<void> checkAndSendNotifications(Pet newPet, String petId) async {
    try {
      // الحالة 1: Found -> Lost Matches (شخص وجد حيوان -> نرسل لمن أضاع مثله)
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
              title: "مطابقة محتملة! 🐾",
              body: "تم العثور على ${newPet.type} في ${newPet.location} قد يكون حيوانك المفقود.",
              petId: petId,
              notificationType: 'found_match',
            );
          }
        }
      }

      // الحالة 2: Lost -> Area Users (شخص أضاع حيوان -> نرسل لسكان المنطقة)
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
              title: "تنبيه حيوان مفقود 🚨",
              body: "فُقد ${newPet.type} في منطقتك (${newPet.location}). ساعدنا في البحث!",
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
      'petId': petId, // هنا نحفظ رقم البوست
      'type': notificationType,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
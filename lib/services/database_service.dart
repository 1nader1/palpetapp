import 'dart:io'; // ضروري للتعامل مع ملفات الصور
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ضروري لخدمة التخزين
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/data/models/clinic.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // تعريف خدمة التخزين

  // --- 1. دالة رفع الصور (الجديدة) ---
  Future<String> uploadImage(File imageFile) async {
    try {
      // إنشاء اسم فريد للصورة بناءً على الوقت الحالي لضمان عدم تكرار الأسماء
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      
      // تحديد المسار داخل التخزين (داخل مجلد اسمه pets_images)
      Reference ref = _storage.ref().child('pets_images/$fileName.jpg');

      // بدء عملية الرفع
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // بعد اكتمال الرفع، نجلب رابط التحميل (URL) لنخزنه في الداتا بيس
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("فشل في رفع الصورة، يرجى المحاولة مرة أخرى.");
    }
  }

  // --- 2. دوال الحيوانات / المنشورات ---

  Stream<List<Pet>> getPets() {
    return _db
        .collection('pets')
        .orderBy('createdAt', descending: true) // ترتيب المنشورات: الأحدث أولاً
        .snapshots()
        .map((snapshot) {
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

  // --- 3. دوال العيادات (كما هي) ---

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
            services: (data['services'] is List) 
                ? List<String>.from(data['services']) 
                : [],
          );
        }).toList());
  }
}
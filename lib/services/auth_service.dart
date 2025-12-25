import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // نأخذ نسخة من الفايربيس
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. معرفة المستخدم الحالي (هل هو مسجل دخول أم لا؟)
  User? get currentUser => _auth.currentUser;

  // Stream لمراقبة حالة المستخدم (مفيد لتوجيه المستخدم للصفحة الرئيسية أو صفحة الدخول تلقائياً)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 2. إنشاء حساب جديد (Sign Up) - معدل لاستقبال الموقع
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String location, // <--- إضافة الموقع هنا
  }) async {
    try {
      // إنشاء الحساب في Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // حفظ بيانات المستخدم الإضافية في Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'location': location, // <--- حفظ الموقع في الداتابيس
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // 3. تسجيل الدخول (Sign In)
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // 4. تسجيل الخروج (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // دالة مساعدة لترجمة أخطاء فايربيس للعربية
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً.';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'network-request-failed':
        return 'تأكد من اتصالك بالإنترنت.';
      default:
        return 'حدث خطأ: ${e.message}';
    }
  }
}
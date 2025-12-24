import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // إضافة مكتبة المصادقة
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart'; // إضافة استيراد صفحة الدخول

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PalPetApp());
}

class PalPetApp extends StatelessWidget {
  const PalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PalPet',

      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold, 
            color: AppColors.textDark
          ),
          bodyMedium: TextStyle(
            fontSize: 14, 
            color: AppColors.textGrey
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
      ),
      
      // هنا التغيير الأساسي: فحص حالة المستخدم
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. في حالة الانتظار (تحميل)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          
          // 2. إذا كان المستخدم مسجل دخول (يوجد بيانات) -> نذهب للرئيسية
          if (snapshot.hasData) {
            return const MainShell();
          }
          
          // 3. إذا لم يكن مسجل دخول -> نذهب لصفحة الدخول
          return const LoginScreen();
        },
      ),
    );
  }
}
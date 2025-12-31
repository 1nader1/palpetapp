import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [مهم] استيراد المكتبة
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart'; // [مهم] استيراد شاشة الـ Onboarding

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. تهيئة الفايربيس
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. فحص هل المستخدم فتح التطبيق من قبل؟
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(PalPetApp(showOnboarding: !seenOnboarding));
}

class PalPetApp extends StatelessWidget {
  final bool showOnboarding; // متغير لتحديد حالة البدء

  const PalPetApp({super.key, required this.showOnboarding});

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
      
      // منطق التوجيه الرئيسي
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // A. حالة الانتظار
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          
          // B. إذا كان المستخدم مسجل دخول بالفعل -> الرئيسية مباشرة
          if (snapshot.hasData) {
            return const MainShell();
          }
          
          // C. إذا لم يكن مسجل دخول:
          // نفحص هل يجب عرض الـ Onboarding أم شاشة تسجيل الدخول؟
          if (showOnboarding) {
            return const OnboardingScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
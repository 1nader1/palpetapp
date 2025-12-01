import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'screens/main_shell.dart';


void main() {
  runApp(const PalPetApp());
}

class PalPetApp extends StatelessWidget {
  const PalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PalPet',
      // إعداد الثيم العام هنا ليطبق على كل الصفحات
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        useMaterial3: true,
        fontFamily: 'Segoe UI', // أو أي خط تفضله
        
        // إعدادات النصوص العامة
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

        // إعدادات الـ AppBar الافتراضية
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
      ),
      home: const MainShell(), // نقطة البداية هي الإطار العام
    );
  }
}
import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'screens/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
      home: const MainShell(),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _selectedLocation; // متغير لحفظ المنطقة المختارة

  // نفس قائمة المناطق الموحدة في التطبيق
  final List<String> _jordanAreas = [
    'Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Salt', 'Madaba', 
    'Jerash', 'Ajloun', 'Mafraq', 'Karak', 'Tafilah', 'Ma\'an',
    'Abdoun', 'Dabouq', 'Khalda', 'Sweifieh', 'Jubaiha', 'Tla\' Al-Ali'
  ];

  void _register() async {
    if (_formKey.currentState!.validate()) {
      // التحقق من اختيار المنطقة
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your location'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await AuthService().signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          location: _selectedLocation!, // نرسل المنطقة للباك إند
        );
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainShell()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create a new account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join the PalPet Community!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                ),
                const SizedBox(height: 40),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Full Name', Icons.person_outline),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email', Icons.email_outlined),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                
                // --- Location Dropdown (الجديد) ---
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: _inputDecoration('Select City / Area', Icons.location_on_outlined),
                  items: _jordanAreas.map((area) {
                    return DropdownMenuItem(value: area, child: Text(area));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedLocation = val),
                  validator: (val) => val == null ? 'Please select your area' : null,
                ),
                const SizedBox(height: 16),
                // ----------------------------------

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password', Icons.lock_outline),
                  validator: (value) =>
                      value!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 24),

                // Register Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
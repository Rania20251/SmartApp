import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color primary = Color(0xff5B2EFF);
  static const Color bg = Color(0xffF7F8FC);

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool isValidEmail(String email) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

  Future<bool> emailExists(String email) async {
    final users = await ApiService.getUsers();
    final e = email.trim().toLowerCase();
    return users.any((u) =>
    (u['email']?.toString().trim().toLowerCase() ?? '') == e);
  }

  Future<void> registerUser() async {
    if (isLoading) return;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (fullName.isEmpty) return showMessage(AppStrings.enterFullName);
    if (email.isEmpty) return showMessage(AppStrings.enterEmail);
    if (!isValidEmail(email)) return showMessage('Please enter a valid email');
    if (password.isEmpty) return showMessage(AppStrings.enterPassword);

    setState(() => isLoading = true);

    try {
      if (await emailExists(email)) {
        showMessage('Email already exists');
        return;
      }

      final ok = await ApiService.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (ok) {
        showMessage(AppStrings.accountCreated);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        showMessage(AppStrings.registrationFailed);
      }
    } catch (_) {
      showMessage(AppStrings.connectionFailed);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration field(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(AppStrings.createAccount),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add,size:70,color:primary),
                const SizedBox(height:18),
                Text(AppStrings.createAccount,style: const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
                const SizedBox(height:24),
                TextField(controller: fullNameController,textInputAction: TextInputAction.next,decoration: field(AppStrings.fullName, Icons.person)),
                const SizedBox(height:16),
                TextField(controller: emailController,keyboardType: TextInputType.emailAddress,textInputAction: TextInputAction.next,decoration: field(AppStrings.email, Icons.email)),
                const SizedBox(height:16),
                TextField(controller: passwordController,obscureText:true,onSubmitted: (_)=>registerUser(),decoration: field(AppStrings.password, Icons.lock)),
                const SizedBox(height:26),
                SizedBox(
                  width: double.infinity,
                  height:52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withOpacity(.65),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed:isLoading?null:registerUser,
                    child:isLoading?const CircularProgressIndicator(color: Colors.white):Text(AppStrings.createAccount,style: const TextStyle(fontSize:18)),
                  ),
                ),
                const SizedBox(height:14),
                TextButton(onPressed: ()=>Navigator.pop(context),child: Text(AppStrings.alreadyHaveAccount))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

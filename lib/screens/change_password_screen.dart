import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> changePassword() async {
    if (oldPasswordController.text.trim().isEmpty) {
      showMessage(AppStrings.enterOldPassword);
      return;
    }

    if (newPasswordController.text.trim().isEmpty) {
      showMessage(AppStrings.enterNewPassword);
      return;
    }

    if (newPasswordController.text.trim().length < 6) {
      showMessage(
        AppStrings.isArabic
            ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
            : 'Password must be at least 6 characters',
      );
      return;
    }

    if (confirmPasswordController.text.trim().isEmpty) {
      showMessage(AppStrings.confirmNewPasswordMessage);
      return;
    }

    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      showMessage(AppStrings.passwordsDoNotMatch);
      return;
    }

    if (UserSession.userId == null) {
      showMessage(AppStrings.userNotFound);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await ApiService.changePassword(
      userId: UserSession.userId!,
      oldPassword: oldPasswordController.text.trim(),
      newPassword: newPasswordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      showMessage(AppStrings.passwordChanged);
      Navigator.pop(context);
    } else {
      showMessage(AppStrings.passwordChangeFailed);
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.changePassword),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            width: 390,
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const SizedBox(height: 30),
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: primary,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    AppStrings.updatePassword,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppStrings.enterOldAndNewPassword,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: oldPasswordController,
                  obscureText: hideOld,
                  decoration: passwordDecoration(
                    hint: AppStrings.oldPassword,
                    icon: Icons.lock_outline,
                    hidden: hideOld,
                    onToggle: () {
                      setState(() {
                        hideOld = !hideOld;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: hideNew,
                  decoration: passwordDecoration(
                    hint: AppStrings.newPassword,
                    icon: Icons.lock,
                    hidden: hideNew,
                    onToggle: () {
                      setState(() {
                        hideNew = !hideNew;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirm,
                  decoration: passwordDecoration(
                    hint: AppStrings.confirmNewPassword,
                    icon: Icons.verified_user,
                    hidden: hideConfirm,
                    onToggle: () {
                      setState(() {
                        hideConfirm = !hideConfirm;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading ? null : changePassword,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      AppStrings.changePassword,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration passwordDecoration({
    required String hint,
    required IconData icon,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

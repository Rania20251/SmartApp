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
  static const Color primary = Color(0xFF5B2EFF);
  static const Color background = Color(0xFFF7F8FC);
  static const Color lightPurple = Color(0xFFEDE7FF);

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> changePassword() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      showMessage(AppStrings.enterOldPassword);
      return;
    }

    if (newPassword.isEmpty) {
      showMessage(AppStrings.enterNewPassword);
      return;
    }

    if (newPassword.length < 6) {
      showMessage(
        AppStrings.isArabic
            ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
            : 'Password must be at least 6 characters',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(AppStrings.confirmNewPasswordMessage);
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage(AppStrings.passwordsDoNotMatch);
      return;
    }

    final userId = UserSession.userId;

    if (userId == null) {
      showMessage(AppStrings.userNotFound);
      return;
    }

    if (isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final success = await ApiService.changePassword(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (success) {
        showMessage(AppStrings.passwordChanged);
        Navigator.pop(context);
      } else {
        showMessage(AppStrings.passwordChangeFailed);
      }
    } catch (_) {
      showMessage(AppStrings.passwordChangeFailed);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void toggleOldPassword() {
    setState(() {
      hideOld = !hideOld;
    });
  }

  void toggleNewPassword() {
    setState(() {
      hideNew = !hideNew;
    });
  }

  void toggleConfirmPassword() {
    setState(() {
      hideConfirm = !hideConfirm;
    });
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
    return Directionality(
      textDirection: AppStrings.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
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
                Container(
                  width: 104,
                  height: 104,
                  margin: const EdgeInsets.symmetric(horizontal: 123),
                  decoration: const BoxDecoration(
                    color: lightPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 62,
                    color: primary,
                  ),
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: oldPasswordController,
                  obscureText: hideOld,
                  textInputAction: TextInputAction.next,
                  decoration: passwordDecoration(
                    hint: AppStrings.oldPassword,
                    icon: Icons.lock_outline,
                    hidden: hideOld,
                    onToggle: toggleOldPassword,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: hideNew,
                  textInputAction: TextInputAction.next,
                  decoration: passwordDecoration(
                    hint: AppStrings.newPassword,
                    icon: Icons.lock,
                    hidden: hideNew,
                    onToggle: toggleNewPassword,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: hideConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => changePassword(),
                  decoration: passwordDecoration(
                    hint: AppStrings.confirmNewPassword,
                    icon: Icons.verified_user,
                    hidden: hideConfirm,
                    onToggle: toggleConfirmPassword,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withOpacity(0.65),
                      elevation: 6,
                      shadowColor: primary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: isLoading ? null : changePassword,
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      AppStrings.changePassword,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
      prefixIcon: Icon(
        icon,
        color: primary,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          hidden ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF757575),
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFEDEDF3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primary,
          width: 1.6,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

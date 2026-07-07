import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  int currentStep = 0;
  bool isLoading = false;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool validEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage(AppStrings.isArabic ? 'أدخلي البريد الإلكتروني' : 'Enter email');
      return;
    }

    if (!validEmail(email)) {
      showMessage(AppStrings.isArabic ? 'البريد الإلكتروني غير صحيح' : 'Invalid email address');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await ApiService.sendResetCode(email: email);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      setState(() {
        currentStep = 1;
      });

      showMessage(
        AppStrings.isArabic
            ? 'تم إرسال كود التحقق إلى بريدك الإلكتروني'
            : 'Verification code sent to your email',
      );
    } else {
      showMessage(
        AppStrings.isArabic
            ? 'فشل إرسال الكود. تأكدي من البريد الإلكتروني'
            : 'Failed to send code. Check your email',
      );
    }
  }

  Future<void> verifyCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (code.isEmpty) {
      showMessage(AppStrings.isArabic ? 'أدخلي كود التحقق' : 'Enter verification code');
      return;
    }

    if (code.length != 6) {
      showMessage(AppStrings.isArabic ? 'الكود يجب أن يكون 6 أرقام' : 'Code must be 6 digits');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await ApiService.verifyResetCode(
      email: email,
      code: code,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      setState(() {
        currentStep = 2;
      });

      showMessage(
        AppStrings.isArabic
            ? 'تم التحقق من الكود'
            : 'Code verified successfully',
      );
    } else {
      showMessage(
        AppStrings.isArabic
            ? 'الكود غير صحيح أو انتهت صلاحيته'
            : 'Invalid or expired code',
      );
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      showMessage(AppStrings.isArabic ? 'أدخلي كلمة المرور الجديدة' : 'Enter new password');
      return;
    }

    if (newPassword.length < 6) {
      showMessage(AppStrings.isArabic ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters');
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(AppStrings.isArabic ? 'أكدي كلمة المرور الجديدة' : 'Confirm new password');
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage(AppStrings.isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await ApiService.resetPasswordWithCode(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      showMessage(
        AppStrings.isArabic
            ? 'تم تغيير كلمة المرور بنجاح'
            : 'Password reset successfully',
      );

      Navigator.pop(context);
    } else {
      showMessage(
        AppStrings.isArabic
            ? 'فشل تغيير كلمة المرور'
            : 'Failed to reset password',
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
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
          title: Text(AppStrings.isArabic ? 'نسيت كلمة المرور' : 'Forgot Password'),
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
                const SizedBox(height: 24),
                const Icon(
                  Icons.lock_reset,
                  size: 82,
                  color: primary,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    pageTitle(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    pageSubtitle(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                stepIndicator(),
                const SizedBox(height: 26),
                if (currentStep == 0) emailStep(),
                if (currentStep == 1) codeStep(),
                if (currentStep == 2) passwordStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String pageTitle() {
    if (currentStep == 0) {
      return AppStrings.isArabic ? 'استعادة كلمة المرور' : 'Reset Password';
    }

    if (currentStep == 1) {
      return AppStrings.isArabic ? 'أدخلي كود التحقق' : 'Enter Verification Code';
    }

    return AppStrings.isArabic ? 'كلمة مرور جديدة' : 'New Password';
  }

  String pageSubtitle() {
    if (currentStep == 0) {
      return AppStrings.isArabic
          ? 'أدخلي بريدك الإلكتروني لإرسال كود التحقق'
          : 'Enter your email to receive a verification code';
    }

    if (currentStep == 1) {
      return AppStrings.isArabic
          ? 'تم إرسال كود مكوّن من 6 أرقام إلى بريدك'
          : 'A 6-digit code was sent to your email';
    }

    return AppStrings.isArabic
        ? 'أدخلي كلمة المرور الجديدة'
        : 'Enter your new password';
  }

  Widget stepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stepCircle(0),
        stepLine(),
        stepCircle(1),
        stepLine(),
        stepCircle(2),
      ],
    );
  }

  Widget stepCircle(int step) {
    const primary = Color(0xff5B2EFF);
    final active = currentStep >= step;

    return CircleAvatar(
      radius: 15,
      backgroundColor: active ? primary : Colors.grey.shade300,
      child: Text(
        '${step + 1}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget stepLine() {
    return Container(
      width: 45,
      height: 3,
      color: Colors.grey.shade300,
    );
  }

  Widget emailStep() {
    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: inputDecoration(
            hint: AppStrings.email,
            icon: Icons.email,
          ),
        ),
        const SizedBox(height: 22),
        mainButton(
          title: AppStrings.isArabic ? 'إرسال الكود' : 'Send Code',
          onPressed: sendCode,
        ),
      ],
    );
  }

  Widget codeStep() {
    return Column(
      children: [
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: inputDecoration(
            hint: AppStrings.isArabic ? 'كود التحقق' : 'Verification Code',
            icon: Icons.pin,
          ),
        ),
        Align(
          alignment: AppStrings.isArabic ? Alignment.centerLeft : Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : sendCode,
            child: Text(
              AppStrings.isArabic ? 'إعادة إرسال الكود' : 'Resend Code',
              style: const TextStyle(
                color: Color(0xff5B2EFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        mainButton(
          title: AppStrings.isArabic ? 'تحقق من الكود' : 'Verify Code',
          onPressed: verifyCode,
        ),
      ],
    );
  }

  Widget passwordStep() {
    return Column(
      children: [
        TextField(
          controller: newPasswordController,
          obscureText: hideNewPassword,
          decoration: passwordDecoration(
            hint: AppStrings.isArabic ? 'كلمة المرور الجديدة' : 'New Password',
            icon: Icons.lock,
            hidden: hideNewPassword,
            onToggle: () {
              setState(() {
                hideNewPassword = !hideNewPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController,
          obscureText: hideConfirmPassword,
          decoration: passwordDecoration(
            hint: AppStrings.isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
            icon: Icons.verified_user,
            hidden: hideConfirmPassword,
            onToggle: () {
              setState(() {
                hideConfirmPassword = !hideConfirmPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        mainButton(
          title: AppStrings.isArabic ? 'تغيير كلمة المرور' : 'Reset Password',
          onPressed: resetPassword,
        ),
      ],
    );
  }

  Widget mainButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    const primary = Color(0xff5B2EFF);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
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

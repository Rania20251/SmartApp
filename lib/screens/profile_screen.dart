import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../language/app_strings.dart';
import '../services/user_session.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const ProfileScreen({
    super.key,
    this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int appointmentCount = 0;
  bool isLoadingAppointmentCount = false;

  @override
  void initState() {
    super.initState();
    loadAppointmentCount();
  }

  Future<void> loadAppointmentCount() async {
    if (isLoadingAppointmentCount) return;

    final userId = UserSession.userId ?? 0;
    if (userId == 0) return;

    isLoadingAppointmentCount = true;

    try {
      final count = await ApiService.getAppointmentCountByUser(userId);

      if (!mounted) return;

      setState(() {
        appointmentCount = count;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        appointmentCount = 0;
      });
    } finally {
      isLoadingAppointmentCount = false;
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadAppointmentCount();
  }



  String translateName(String value) {
    if (!AppStrings.isArabic) return value;

    return value
        .replaceAll('Rana', 'رنا')
        .replaceAll('Salah', 'صلاح')
        .replaceAll('Sarah', 'سارة')
        .replaceAll('Sara', 'سارة')
        .replaceAll('Ahmad', 'أحمد')
        .replaceAll('Ahmed', 'أحمد')
        .replaceAll('Ali', 'علي')
        .replaceAll('Mohammad', 'محمد')
        .replaceAll('Mohammed', 'محمد')
        .replaceAll('Omar', 'عمر')
        .replaceAll('Nour', 'نور')
        .replaceAll('Adnan', 'عدنان')
        .replaceAll('Rania', 'رانيا')
        .replaceAll('Ramia', 'راميا');
  }

  String translateAddress(String value) {
    final v = value.trim();

    if (v.isEmpty) return AppStrings.notAvailable;

    if (AppStrings.isArabic) {
      final lower = v.toLowerCase();

      if (lower == 'not available' || lower == 'n/a') {
        return AppStrings.notAvailable;
      }

      return v
          .replaceAll(RegExp(r'\bAmman\b', caseSensitive: false), 'عمّان')
          .replaceAll(RegExp(r'\bJordan\b', caseSensitive: false), 'الأردن')
          .replaceAll(RegExp(r'\bIrbid\b', caseSensitive: false), 'إربد')
          .replaceAll(RegExp(r'\bZarqa\b', caseSensitive: false), 'الزرقاء')
          .replaceAll(RegExp(r'\bAqaba\b', caseSensitive: false), 'العقبة')
          .replaceAll(RegExp(r'\bMadaba\b', caseSensitive: false), 'مادبا')
          .replaceAll(RegExp(r'\bSalt\b', caseSensitive: false), 'السلط')
          .replaceAll(RegExp(r'\bKarak\b', caseSensitive: false), 'الكرك')
          .replaceAll(RegExp(r'\bStreet\b', caseSensitive: false), 'شارع')
          .replaceAll(RegExp(r'\bSt\b', caseSensitive: false), 'شارع')
          .replaceAll(RegExp(r'\bCity\b', caseSensitive: false), 'مدينة');
    }

    return v
        .replaceAll('عمّان', 'Amman')
        .replaceAll('عمان', 'Amman')
        .replaceAll('الأردن', 'Jordan')
        .replaceAll('الاردن', 'Jordan')
        .replaceAll('إربد', 'Irbid')
        .replaceAll('اربد', 'Irbid')
        .replaceAll('الزرقاء', 'Zarqa')
        .replaceAll('العقبة', 'Aqaba')
        .replaceAll('مادبا', 'Madaba')
        .replaceAll('السلط', 'Salt')
        .replaceAll('الكرك', 'Karak')
        .replaceAll('شارع', 'Street')
        .replaceAll('مدينة', 'City');
  }

  String translateGender(String value) {
    final v = value.trim().toLowerCase();

    if (v.isEmpty) return AppStrings.notAvailable;

    if (AppStrings.isArabic) {
      if (v == 'male' || v == 'm' || v == 'ذكر') return 'ذكر';
      if (v == 'female' || v == 'f' || v == 'أنثى' || v == 'انثى') return 'أنثى';
      if (v == 'not available' || v == 'n/a') return AppStrings.notAvailable;
    } else {
      if (v == 'ذكر') return 'Male';
      if (v == 'أنثى' || v == 'انثى') return 'Female';
    }

    return value;
  }

  String translateRole(String value) {
    final v = value.trim().toLowerCase();

    if (AppStrings.isArabic) {
      if (v == 'admin') return 'أدمن';
      if (v == 'patient') return 'مريض';
    } else {
      if (v == 'أدمن') return 'Admin';
      if (v == 'مريض') return 'Patient';
    }

    return value;
  }

  ImageProvider getProfileImage() {
    final imagePath = UserSession.profileImage ?? '';

    if (imagePath.startsWith('data:image')) {
      final base64Part = imagePath.split(',').last;
      return MemoryImage(base64Decode(base64Part));
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImageProvider(imagePath);
    }

    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }

    return const AssetImage('assets/images/profile.jpg');
  }

  void changeLanguage(Locale locale) {
    AppStrings.changeLanguage(locale);

    setState(() {});

    widget.onLanguageChanged?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.languageChanged)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    final fullName = translateName(UserSession.fullName ?? AppStrings.noName);
    final email = UserSession.email ?? AppStrings.noEmail;
    final phone = UserSession.phoneNumber ?? AppStrings.notAvailable;
    final address = translateAddress(UserSession.address ?? AppStrings.notAvailable);
    final gender = translateGender(UserSession.gender ?? AppStrings.notAvailable);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.profile),
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
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xffEDE7FF),
                        backgroundImage: getProfileImage(),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );

                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    fullName,
                    textAlign: TextAlign.center,
                    textDirection:
                    AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    email,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${AppStrings.role}: ${translateRole(UserSession.role ?? 'Patient')}',
                    style: TextStyle(
                      color: UserSession.isAdmin ? primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${AppStrings.userId}: ${UserSession.userId}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ProfileItem(
                  icon: Icons.calendar_month,
                  title: AppStrings.myAppointments,
                  value: '$appointmentCount ${AppStrings.appointments}',
                ),
                ProfileItem(
                  icon: Icons.medical_services,
                  title: AppStrings.medicalRecords,
                  value: AppStrings.fromDatabase,
                ),
                ProfileItem(
                  icon: Icons.phone,
                  title: AppStrings.phoneNumber,
                  value: phone,
                ),
                ProfileItem(
                  icon: Icons.location_on,
                  title: AppStrings.address,
                  value: address,
                ),
                ProfileItem(
                  icon: Icons.person,
                  title: AppStrings.gender,
                  value: gender,
                ),
                ProfileItem(
                  icon: Icons.language,
                  title: AppStrings.language,
                  value: AppStrings.isArabic ? AppStrings.arabic : AppStrings.english,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.language),
                    label: Text(
                      AppStrings.changeLanguageText,
                      textDirection:
                      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    onPressed: () {
                      changeLanguage(
                        AppStrings.isArabic
                            ? const Locale('en')
                            : const Locale('ar'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: Text(
                      AppStrings.editProfile,
                      textDirection:
                      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );

                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.lock),
                    label: Text(
                      AppStrings.changePassword,
                      textDirection:
                      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                ),
                if (UserSession.isAdmin) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: Text(
                        AppStrings.adminDashboard,
                        textDirection:
                        AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(
                      AppStrings.logout,
                      textDirection:
                      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    onPressed: () async {
                      await UserSession.clear();

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                            (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xffEDE7FF),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
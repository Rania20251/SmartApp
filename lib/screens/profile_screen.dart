import 'dart:convert';

import 'package:flutter/material.dart';

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
  ImageProvider getProfileImage() {
    final imagePath = UserSession.profileImage ?? '';

    if (imagePath.startsWith('data:image')) {
      final base64Part = imagePath.split(',').last;
      return MemoryImage(base64Decode(base64Part));
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
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

    final fullName = UserSession.fullName ?? AppStrings.noName;
    final email = UserSession.email ?? AppStrings.noEmail;
    final phone = UserSession.phoneNumber ?? AppStrings.notAvailable;
    final address = UserSession.address ?? AppStrings.notAvailable;
    final gender = UserSession.gender ?? AppStrings.notAvailable;

    return Scaffold(
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
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${AppStrings.role}: ${UserSession.role ?? 'Patient'}',
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
              FutureBuilder<int>(
                future: ApiService.getAppointmentCountByUser(
                  UserSession.userId ?? 0,
                ),
                builder: (context, snapshot) {
                  String value = AppStrings.loading;

                  if (snapshot.hasData) {
                    value = '${snapshot.data} ${AppStrings.appointments}';
                  }

                  if (snapshot.hasError) {
                    value = '0 ${AppStrings.appointments}';
                  }

                  return ProfileItem(
                    icon: Icons.calendar_month,
                    title: AppStrings.myAppointments,
                    value: value,
                  );
                },
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
                  label: Text(AppStrings.changeLanguageText),
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
                  label: Text(AppStrings.editProfile),
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
                  label: Text(AppStrings.changePassword),
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
                    label: Text(AppStrings.adminDashboard),
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
                  label: Text(AppStrings.logout),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'admin_dashboard_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

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

  bool isLoadingAppointmentCount = true;
  bool isRefreshingAppointmentCount = false;
  bool isLoggingOut = false;

  int? _screenUserId;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();

    _screenUserId = UserSession.userId;
    ApiService.appointmentsVersion.addListener(
      _onAppointmentsChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAppointmentCount(forceRefresh: false);
    });
  }

  void _onAppointmentsChanged() {
    if (!mounted || isRefreshingAppointmentCount) return;

    // يتحدث فقط بعد حجز/تأكيد/إكمال/إلغاء/حذف حقيقي.
    _loadAppointmentCount(forceRefresh: false);
  }

  @override
  void dispose() {
    ApiService.appointmentsVersion.removeListener(
      _onAppointmentsChanged,
    );
    _requestVersion++;
    super.dispose();
  }

  Future<void> _loadAppointmentCount({
    bool forceRefresh = false,
  }) async {
    final currentUserId = UserSession.userId ?? 0;

    if (currentUserId <= 0) {
      if (!mounted) return;

      setState(() {
        appointmentCount = 0;
        isLoadingAppointmentCount = false;
        isRefreshingAppointmentCount = false;
      });

      return;
    }

    // يمنع تشغيل أكثر من تحديث في نفس الوقت.
    if (isRefreshingAppointmentCount) return;

    final requestVersion = ++_requestVersion;

    if (mounted) {
      setState(() {
        if (isLoadingAppointmentCount) {
          isLoadingAppointmentCount = true;
        } else {
          isRefreshingAppointmentCount = true;
        }
      });
    }

    try {
      final count = await ApiService
          .getAppointmentCountByUser(
        currentUserId,
        forceRefresh: forceRefresh,
      )
          .timeout(const Duration(seconds: 12));

      // يمنع طلب حساب قديم من تحديث حساب جديد.
      if (!mounted ||
          requestVersion != _requestVersion ||
          UserSession.userId != currentUserId ||
          _screenUserId != currentUserId) {
        return;
      }

      setState(() {
        appointmentCount = count;
        isLoadingAppointmentCount = false;
        isRefreshingAppointmentCount = false;
      });
    } on TimeoutException {
      if (!mounted ||
          requestVersion != _requestVersion ||
          UserSession.userId != currentUserId) {
        return;
      }

      setState(() {
        isLoadingAppointmentCount = false;
        isRefreshingAppointmentCount = false;
      });
    } catch (_) {
      if (!mounted ||
          requestVersion != _requestVersion ||
          UserSession.userId != currentUserId) {
        return;
      }

      setState(() {
        isLoadingAppointmentCount = false;
        isRefreshingAppointmentCount = false;
      });
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (!mounted) return;

    // نحدّث بيانات البروفايل المعروضة فقط.
    // لا نعيد تحميل الحجوزات لأن تعديل البروفايل لا يغيّر عددها.
    setState(() {});
  }

  Future<void> _logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      // أوقف أي طلب قديم قبل تبديل الحساب.
      _requestVersion++;

      // امسح كاش الحساب القديم قبل مسح UserSession.
      ApiService.clearSessionCaches();
      await UserSession.clear();
    } finally {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
            (route) => false,
      );
    }
  }

  String translateName(String value) {
    return AppStrings.personNameByLanguage(value);
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

      if (v == 'female' ||
          v == 'f' ||
          v == 'أنثى' ||
          v == 'انثى') {
        return 'أنثى';
      }

      if (v == 'not available' || v == 'n/a') {
        return AppStrings.notAvailable;
      }
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
    final imagePath = UserSession.profileImage?.trim() ?? '';

    try {
      if (imagePath.startsWith('data:image')) {
        final base64Part = imagePath.split(',').last;
        return MemoryImage(base64Decode(base64Part));
      }
    } catch (_) {
      return const AssetImage('assets/images/profile.jpg');
    }

    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
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
      SnackBar(
        content: Text(AppStrings.languageChanged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);

    final englishName = UserSession.fullName?.trim() ?? '';
    final arabicName = UserSession.fullNameAr?.trim() ?? '';

    final fullName = AppStrings.isArabic
        ? (arabicName.isNotEmpty
        ? arabicName
        : translateName(
      englishName.isNotEmpty
          ? englishName
          : AppStrings.noName,
    ))
        : (englishName.isNotEmpty
        ? englishName
        : (arabicName.isNotEmpty
        ? translateName(arabicName)
        : AppStrings.noName));

    final email = UserSession.email?.trim().isNotEmpty == true
        ? UserSession.email!
        : AppStrings.noEmail;

    final phone = UserSession.phoneNumber?.trim().isNotEmpty == true
        ? UserSession.phoneNumber!
        : AppStrings.notAvailable;

    final address = translateAddress(
      UserSession.address ?? '',
    );

    final gender = translateGender(
      UserSession.gender ?? '',
    );

    final appointmentValue = isLoadingAppointmentCount
        ? (AppStrings.isArabic ? 'جاري التحميل...' : 'Loading...')
        : '$appointmentCount ${AppStrings.appointments}';

    return Directionality(
      textDirection:
      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.profile),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: AppStrings.isArabic ? 'تحديث' : 'Refresh',
              onPressed: isRefreshingAppointmentCount
                  ? null
                  : () => _loadAppointmentCount(forceRefresh: true),
              icon: isRefreshingAppointmentCount
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFFEDE7FF),
                            backgroundImage: getProfileImage(),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _openEditProfile,
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
                        textDirection: AppStrings.isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
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
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '${AppStrings.role}: '
                            '${translateRole(UserSession.role ?? 'Patient')}',
                        style: TextStyle(
                          color: UserSession.isAdmin ? primary : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '${AppStrings.userId}: ${UserSession.userId ?? '-'}',
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
                      value: appointmentValue,
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
                      value: AppStrings.isArabic
                          ? AppStrings.arabic
                          : AppStrings.english,
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.language,
                      title: AppStrings.changeLanguageText,
                      foregroundColor: primary,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        changeLanguage(
                          AppStrings.isArabic
                              ? const Locale('en')
                              : const Locale('ar'),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.edit,
                      title: AppStrings.editProfile,
                      foregroundColor: primary,
                      backgroundColor: Colors.white,
                      onPressed: _openEditProfile,
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.lock,
                      title: AppStrings.changePassword,
                      foregroundColor: primary,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    if (UserSession.isAdmin) ...[
                      const SizedBox(height: 12),
                      _actionButton(
                        icon: Icons.admin_panel_settings,
                        title: AppStrings.adminDashboard,
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.logout,
                      title: isLoggingOut
                          ? (AppStrings.isArabic
                          ? 'جاري تسجيل الخروج...'
                          : 'Logging out...')
                          : AppStrings.logout,
                      foregroundColor: Colors.white,
                      backgroundColor: primary,
                      onPressed: isLoggingOut ? null : _logout,
                      loading: isLoggingOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color foregroundColor,
    required Color backgroundColor,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    final TextDirection textDirection =
    AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(.65),
          disabledForegroundColor: foregroundColor.withOpacity(.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: onPressed,
        child: Directionality(
          textDirection: textDirection,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            textDirection: textDirection,
            children: [
              if (loading)
                SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              else
                Icon(icon),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  title,
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    const primary = Color(0xFF5B2EFF);

    final alignment = AppStrings.isArabic
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    final textAlignment =
    AppStrings.isArabic ? TextAlign.right : TextAlign.left;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        textDirection:
        AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEDE7FF),
            child: Icon(
              icon,
              color: primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: textAlignment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    value,
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: textAlignment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static int? userId;
  static String? fullName;
  static String? email;
  static String? phoneNumber;
  static String? address;
  static String? gender;
  static String? dateOfBirth;
  static String? profileImage;
  static String? role;

  static String normalizeRole(dynamic value) {
    final r = value?.toString().trim() ?? '';

    if (r.toLowerCase() == 'admin') return 'Admin';
    if (r.toLowerCase() == 'patient') return 'Patient';

    return r.isEmpty ? 'Patient' : r;
  }

  static bool isAdminEmail(String? value) {
    final e = value?.trim().toLowerCase() ?? '';

    return e == 'rana@test.com' ||
        e == 'admin@test.com' ||
        e == 'admin@medlink.com';
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    userId = int.tryParse(user['userId']?.toString() ?? '') ?? 0;
    fullName = user['fullName']?.toString() ?? '';
    email = user['email']?.toString() ?? '';
    phoneNumber = user['phoneNumber']?.toString() ?? '';
    address = user['address']?.toString() ?? '';
    gender = user['gender']?.toString() ?? '';
    dateOfBirth = user['dateOfBirth']?.toString() ?? '';
    profileImage = user['profileImage']?.toString() ?? '';

    role = normalizeRole(user['role']);

    if (isAdminEmail(email)) {
      role = 'Admin';
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('userId', userId ?? 0);
    await prefs.setString('fullName', fullName ?? '');
    await prefs.setString('email', email ?? '');
    await prefs.setString('phoneNumber', phoneNumber ?? '');
    await prefs.setString('address', address ?? '');
    await prefs.setString('gender', gender ?? '');
    await prefs.setString('dateOfBirth', dateOfBirth ?? '');
    await prefs.setString('profileImage', profileImage ?? '');
    await prefs.setString('role', role ?? 'Patient');
  }

  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    userId = prefs.getInt('userId');
    fullName = prefs.getString('fullName');
    email = prefs.getString('email');
    phoneNumber = prefs.getString('phoneNumber');
    address = prefs.getString('address');
    gender = prefs.getString('gender');
    dateOfBirth = prefs.getString('dateOfBirth');
    profileImage = prefs.getString('profileImage');

    role = normalizeRole(prefs.getString('role'));

    if (isAdminEmail(email)) {
      role = 'Admin';
      await prefs.setString('role', 'Admin');
    }
  }

  static Future<void> updateProfileImage(String imagePath) async {
    profileImage = imagePath;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImage', imagePath);
  }

  static Future<void> updateRole(String newRole) async {
    role = normalizeRole(newRole);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role ?? 'Patient');
  }

  static bool get isLoggedIn => userId != null && userId != 0;

  static bool get isAdmin {
    final r = role?.trim().toLowerCase() ?? '';
    return r == 'admin' || isAdminEmail(email);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    userId = null;
    fullName = null;
    email = null;
    phoneNumber = null;
    address = null;
    gender = null;
    dateOfBirth = null;
    profileImage = null;
    role = null;
  }
}

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

  static Future<void> saveUser(Map<String, dynamic> user) async {
    userId = user['userId'];
    fullName = user['fullName'];
    email = user['email'];
    phoneNumber = user['phoneNumber'];
    address = user['address'];
    gender = user['gender'];
    dateOfBirth = user['dateOfBirth'];
    profileImage = user['profileImage'];
    role = user['role'] ?? 'Patient';

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
    role = prefs.getString('role') ?? 'Patient';
  }

  static Future<void> updateProfileImage(String imagePath) async {
    profileImage = imagePath;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImage', imagePath);
  }

  static bool get isLoggedIn => userId != null;

  static bool get isAdmin => role == 'Admin';

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
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession._();

  static int? userId;
  static String? fullName;
  static String? fullNameAr;
  static String? email;
  static String? phoneNumber;
  static String? address;
  static String? gender;
  static String? dateOfBirth;
  static String? profileImage;
  static String? role;

  static const String _userIdKey = 'userId';
  static const String _fullNameKey = 'fullName';
  static const String _fullNameArKey = 'fullNameAr';
  static const String _emailKey = 'email';
  static const String _phoneNumberKey = 'phoneNumber';
  static const String _addressKey = 'address';
  static const String _genderKey = 'gender';
  static const String _dateOfBirthKey = 'dateOfBirth';
  static const String _profileImageKey = 'profileImage';
  static const String _roleKey = 'role';

  static String normalizeRole(dynamic value) {
    final r =
        value?.toString().trim().toLowerCase() ?? '';

    if (r == 'admin' || r == 'administrator') {
      return 'Admin';
    }

    if (r == 'patient' || r == 'user') {
      return 'Patient';
    }

    return r.isEmpty
        ? 'Patient'
        : value.toString().trim();
  }

  static bool isAdminEmail(String? value) {
    final e = value?.trim().toLowerCase() ?? '';

    return e == 'rana@test.com' ||
        e == 'admin@test.com' ||
        e == 'admin@medlink.com';
  }

  static dynamic _readValue(
      Map<String, dynamic> user,
      List<String> keys,
      ) {
    for (final key in keys) {
      if (user.containsKey(key) &&
          user[key] != null) {
        return user[key];
      }
    }

    return null;
  }

  static Future<void> saveUser(
      Map<String, dynamic> user,
      ) async {
    final parsedUserId = int.tryParse(
      _readValue(
        user,
        ['userId', 'UserId', 'id', 'Id'],
      )?.toString() ??
          '',
    );

    if (parsedUserId == null ||
        parsedUserId <= 0) {
      throw Exception('Invalid user id');
    }

    final newFullName =
        _readValue(
          user,
          ['fullName', 'FullName', 'name', 'Name'],
        )?.toString().trim() ??
            '';

    final newFullNameAr =
        _readValue(
          user,
          ['fullNameAr', 'FullNameAr'],
        )?.toString().trim() ??
            '';

    final newEmail =
        _readValue(
          user,
          ['email', 'Email'],
        )?.toString().trim().toLowerCase() ??
            '';

    final newPhoneNumber =
        _readValue(
          user,
          [
            'phoneNumber',
            'PhoneNumber',
            'phone',
            'Phone',
          ],
        )?.toString().trim() ??
            '';

    final newAddress =
        _readValue(
          user,
          ['address', 'Address'],
        )?.toString().trim() ??
            '';

    final newGender =
        _readValue(
          user,
          ['gender', 'Gender'],
        )?.toString().trim() ??
            '';

    final newDateOfBirth =
        _readValue(
          user,
          ['dateOfBirth', 'DateOfBirth'],
        )?.toString().trim() ??
            '';

    final newProfileImage =
        _readValue(
          user,
          [
            'profileImage',
            'ProfileImage',
            'image',
            'Image',
          ],
        )?.toString().trim() ??
            '';

    var newRole = normalizeRole(
      _readValue(user, ['role', 'Role']),
    );

    if (isAdminEmail(newEmail)) {
      newRole = 'Admin';
    }

    final prefs =
    await SharedPreferences.getInstance();

    await _removeSessionKeys(prefs);

    userId = parsedUserId;
    fullName = newFullName;
    fullNameAr = newFullNameAr;
    email = newEmail;
    phoneNumber = newPhoneNumber;
    address = newAddress;
    gender = newGender;
    dateOfBirth = newDateOfBirth;
    profileImage = newProfileImage;
    role = newRole;

    await Future.wait([
      prefs.setInt(_userIdKey, parsedUserId),
      prefs.setString(
        _fullNameKey,
        newFullName,
      ),
      prefs.setString(
        _fullNameArKey,
        newFullNameAr,
      ),
      prefs.setString(_emailKey, newEmail),
      prefs.setString(
        _phoneNumberKey,
        newPhoneNumber,
      ),
      prefs.setString(
        _addressKey,
        newAddress,
      ),
      prefs.setString(
        _genderKey,
        newGender,
      ),
      prefs.setString(
        _dateOfBirthKey,
        newDateOfBirth,
      ),
      prefs.setString(
        _profileImageKey,
        newProfileImage,
      ),
      prefs.setString(_roleKey, newRole),
    ]);
  }

  static Future<void> loadUser() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedUserId =
    prefs.getInt(_userIdKey);

    if (savedUserId == null ||
        savedUserId <= 0) {
      _clearMemory();
      return;
    }

    userId = savedUserId;
    fullName =
        prefs.getString(_fullNameKey) ?? '';
    fullNameAr =
        prefs.getString(_fullNameArKey) ?? '';
    email =
        prefs
            .getString(_emailKey)
            ?.trim()
            .toLowerCase() ??
            '';
    phoneNumber =
        prefs.getString(_phoneNumberKey) ?? '';
    address =
        prefs.getString(_addressKey) ?? '';
    gender =
        prefs.getString(_genderKey) ?? '';
    dateOfBirth =
        prefs.getString(_dateOfBirthKey) ?? '';
    profileImage =
        prefs.getString(_profileImageKey) ?? '';

    role = normalizeRole(
      prefs.getString(_roleKey),
    );

    if (isAdminEmail(email)) {
      role = 'Admin';
      await prefs.setString(
        _roleKey,
        'Admin',
      );
    }
  }

  static Future<void> updateProfileImage(
      String imagePath,
      ) async {
    if (!isLoggedIn) return;

    final cleanPath = imagePath.trim();
    profileImage = cleanPath;

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      _profileImageKey,
      cleanPath,
    );
  }

  static Future<void> updateRole(
      String newRole,
      ) async {
    if (!isLoggedIn) return;

    role =
    isAdminEmail(email)
        ? 'Admin'
        : normalizeRole(newRole);

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      _roleKey,
      role ?? 'Patient',
    );
  }

  static Future<void> updateStoredUser({
    String? newFullName,
    String? newFullNameAr,
    String? newEmail,
    String? newPhoneNumber,
    String? newAddress,
    String? newGender,
    String? newDateOfBirth,
    String? newProfileImage,
  }) async {
    if (!isLoggedIn) return;

    final prefs =
    await SharedPreferences.getInstance();

    if (newFullName != null) {
      fullName = newFullName.trim();

      await prefs.setString(
        _fullNameKey,
        fullName!,
      );
    }

    if (newFullNameAr != null) {
      fullNameAr = newFullNameAr.trim();

      await prefs.setString(
        _fullNameArKey,
        fullNameAr!,
      );
    }

    if (newEmail != null) {
      email =
          newEmail.trim().toLowerCase();

      await prefs.setString(
        _emailKey,
        email!,
      );

      if (isAdminEmail(email)) {
        role = 'Admin';

        await prefs.setString(
          _roleKey,
          'Admin',
        );
      }
    }

    if (newPhoneNumber != null) {
      phoneNumber =
          newPhoneNumber.trim();

      await prefs.setString(
        _phoneNumberKey,
        phoneNumber!,
      );
    }

    if (newAddress != null) {
      address = newAddress.trim();

      await prefs.setString(
        _addressKey,
        address!,
      );
    }

    if (newGender != null) {
      gender = newGender.trim();

      await prefs.setString(
        _genderKey,
        gender!,
      );
    }

    if (newDateOfBirth != null) {
      dateOfBirth =
          newDateOfBirth.trim();

      await prefs.setString(
        _dateOfBirthKey,
        dateOfBirth!,
      );
    }

    if (newProfileImage != null) {
      profileImage =
          newProfileImage.trim();

      await prefs.setString(
        _profileImageKey,
        profileImage!,
      );
    }
  }

  static bool get isLoggedIn =>
      userId != null && userId! > 0;

  static bool get isAdmin {
    final r =
        role?.trim().toLowerCase() ?? '';

    return r == 'admin' ||
        isAdminEmail(email);
  }

  static String get sessionKey {
    if (!isLoggedIn) return 'guest';

    return '${userId!}_'
        '${email?.trim().toLowerCase() ?? ''}';
  }

  static Future<void> clear() async {
    final prefs =
    await SharedPreferences.getInstance();

    await _removeSessionKeys(prefs);
    _clearMemory();
  }

  static Future<void> clearUser() async {
    await clear();
  }

  static Future<void> _removeSessionKeys(
      SharedPreferences prefs,
      ) async {
    await Future.wait([
      prefs.remove(_userIdKey),
      prefs.remove(_fullNameKey),
      prefs.remove(_fullNameArKey),
      prefs.remove(_emailKey),
      prefs.remove(_phoneNumberKey),
      prefs.remove(_addressKey),
      prefs.remove(_genderKey),
      prefs.remove(_dateOfBirthKey),
      prefs.remove(_profileImageKey),
      prefs.remove(_roleKey),
    ]);
  }

  static void _clearMemory() {
    userId = null;
    fullName = null;
    fullNameAr = null;
    email = null;
    phoneNumber = null;
    address = null;
    gender = null;
    dateOfBirth = null;
    profileImage = null;
    role = null;
  }
}

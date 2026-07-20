import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'user_session.dart';


class AppointmentSlotTakenException implements Exception {
  final String message;

  const AppointmentSlotTakenException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // يتغير فقط عند حجز/تأكيد/إكمال/إلغاء/حذف موعد.
  // لا يوجد Timer ولا تحديث تلقائي متكرر.
  static final ValueNotifier<int> appointmentsVersion =
  ValueNotifier<int>(0);

  static void notifyAppointmentsChanged() {
    appointmentsVersion.value++;
  }

  static const String siteUrl = 'http://medlink-rana.premiumasp.net';
  static const String baseUrl = '$siteUrl/api';

  static const Duration normalTimeout = Duration(seconds: 12);
  static const Duration uploadTimeout = Duration(seconds: 30);

  static final Uri specialtiesUrl = Uri.parse('$baseUrl/Specialties');
  static final Uri usersUrl = Uri.parse('$baseUrl/Users');
  static final Uri doctorsUrl = Uri.parse('$baseUrl/Doctors');
  static final Uri appointmentsUrl = Uri.parse('$baseUrl/Appointments');
  static final Uri medicalRecordsUrl = Uri.parse('$baseUrl/MedicalRecords');
  static final Uri bannersUrl = Uri.parse('$baseUrl/Banners');

  static Map<String, String> get headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static List<dynamic>? _doctorsCache;
  static List<dynamic>? _specialtiesCache;
  // كاش لوحة الأدمن منفصل عن كاش كل مريض.
  static List<dynamic>? _allAppointmentsCache;
  static final Map<int, List<dynamic>> _userAppointmentsCache = {};

  // عداد البروفايل منفصل تماماً عن طلب شاشة المواعيد.
  // لذلك تحميل البروفايل لا يحجز أو يؤخر تحميل ScheduleScreen.
  static final Map<int, int> _appointmentCountCache = {};
  static final Map<int, Future<int>> _appointmentCountRequests = {};
  static final Map<int, List<dynamic>> _notificationsCache = {};
  static List<dynamic>? _bannersCache;

  static Future<List<dynamic>>? _doctorsRequest;
  static Future<List<dynamic>>? _specialtiesRequest;
  static Future<List<dynamic>>? _allAppointmentsRequest;
  static final Map<int, Future<List<dynamic>>> _userAppointmentsRequests = {};
  static final Map<int, Future<List<dynamic>>> _notificationsRequests = {};
  static Future<List<dynamic>>? _bannersRequest;

  static void clearDoctorsCache() {
    _doctorsCache = null;
    _doctorsRequest = null;
  }

  static void clearSpecialtiesCache() {
    _specialtiesCache = null;
    _specialtiesRequest = null;
    clearDoctorsCache();
  }

  static void clearAppointmentsCache([int? userId]) {
    if (userId != null) {
      _userAppointmentsCache.remove(userId);
      _userAppointmentsRequests.remove(userId);
      _appointmentCountCache.remove(userId);
      _appointmentCountRequests.remove(userId);
      return;
    }

    _allAppointmentsCache = null;
    _allAppointmentsRequest = null;
    _userAppointmentsCache.clear();
    _userAppointmentsRequests.clear();
    _appointmentCountCache.clear();
    _appointmentCountRequests.clear();
  }

  static void resetAppointmentsCache([int? userId]) {
    clearAppointmentsCache(userId);
  }

  /// تُستدعى عند نجاح تسجيل الدخول أو تسجيل الخروج حتى لا تنتقل
  /// أي بيانات خاصة من حساب إلى حساب آخر على نفس الجهاز.
  static void clearSessionCaches() {
    clearAppointmentsCache();
    clearNotificationsCache();
  }

  /// تنظيف شامل للكاش عند الحاجة.
  static void clearAllCache() {
    clearDoctorsCache();
    clearSpecialtiesCache();
    clearAppointmentsCache();
    clearNotificationsCache();
    clearBannersCache();
  }

  static void clearNotificationsCache([int? userId]) {
    if (userId == null) {
      _notificationsCache.clear();
      _notificationsRequests.clear();
      return;
    }

    _notificationsCache.remove(userId);
    _notificationsRequests.remove(userId);
  }

  static void clearBannersCache() {
    _bannersCache = null;
    _bannersRequest = null;
  }

  static Future<List<dynamic>> getBanners({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _bannersCache != null) return _bannersCache!;
    if (!forceRefresh && _bannersRequest != null) return _bannersRequest!;

    final request = (() async {
      try {
        final response =
        await http.get(bannersUrl, headers: headers).timeout(normalTimeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = decodeList(response.body);

          final banners = data.map((banner) {
            if (banner is Map<String, dynamic>) {
              banner['imageUrl'] = fixImageUrl(
                banner['imageUrl']?.toString() ??
                    banner['ImageUrl']?.toString() ??
                    '',
              );
            }
            return banner;
          }).toList();

          _bannersCache = banners;
          return banners;
        }

        return _bannersCache ?? [];
      } catch (_) {
        return _bannersCache ?? [];
      } finally {
        _bannersRequest = null;
      }
    })();

    _bannersRequest = request;
    return request;
  }

  static Future<void> uploadBannerImageBytes({
    required Uint8List bytes,
    required String fileName,
    required int position,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/Banners/upload'),
    );

    request.fields['position'] = position.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final response = await request.send().timeout(uploadTimeout);
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload banner image: $body');
    }

    clearBannersCache();
  }

  static Future<void> deleteBannerImage(int position) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Banners/$position'),
      headers: headers,
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete banner image');
    }

    clearBannersCache();
  }

  static String fixImageUrl(String image) {
    final value = image.trim();

    if (value.isEmpty || value.toLowerCase() == 'string') {
      return 'assets/images/profile.jpg';
    }

    if (value.startsWith('data:image')) return value;
    if (value.startsWith('assets/')) return value;

    // لا نغيّر البروتوكول الذي رجع من السيرفر.
    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '$siteUrl$value';
    }

    if (value.startsWith('images/') ||
        value.startsWith('uploads/')) {
      return '$siteUrl/$value';
    }

    return '$siteUrl/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String fixFileUrl(String fileUrl) {
    final value = fileUrl.trim();

    if (value.isEmpty ||
        value.toLowerCase() == 'string' ||
        value.toLowerCase() == 'null') {
      return '';
    }

    if (value.startsWith('data:')) return value;

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '$siteUrl$value';
    }

    return '$siteUrl/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String withImageCacheVersion(
      String imageUrl, {
        Object? version,
      }) {
    final value = imageUrl.trim();

    if (value.isEmpty ||
        value.startsWith('assets/') ||
        value.startsWith('data:image')) {
      return value;
    }

    final uri = Uri.tryParse(value);

    if (uri == null) return value;

    final query = Map<String, String>.from(uri.queryParameters);
    query['v'] = (version ?? DateTime.now().millisecondsSinceEpoch).toString();

    return uri.replace(queryParameters: query).toString();
  }

  static String getSpecialtyName(dynamic doctor) {
    if (doctor is! Map) return '';

    final specialtyNavigation =
        doctor['specialtyNavigation'] ?? doctor['SpecialtyNavigation'];

    if (specialtyNavigation is Map<String, dynamic>) {
      return specialtyNavigation['name']?.toString() ??
          specialtyNavigation['Name']?.toString() ??
          '';
    }

    return doctor['specialty']?.toString() ??
        doctor['Specialty']?.toString() ??
        doctor['specialtyName']?.toString() ??
        doctor['SpecialtyName']?.toString() ??
        '';
  }

  static List<dynamic> decodeList(String body) {
    final data = jsonDecode(body);
    return data is List ? data : [];
  }

  static Map<String, dynamic>? decodeMap(String body) {
    final data = jsonDecode(body);
    return data is Map<String, dynamic> ? data : null;
  }

  static Future<List<dynamic>> getSpecialties({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _specialtiesCache != null) return _specialtiesCache!;
    if (!forceRefresh && _specialtiesRequest != null) return _specialtiesRequest!;

    final request = (() async {
      try {
        final response =
        await http.get(specialtiesUrl, headers: headers).timeout(normalTimeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = decodeList(response.body);

          final specialties = data.where((item) {
            if (item is! Map) return false;

            final id = item['specialtyId'] ?? item['SpecialtyId'] ?? item['id'] ?? item['Id'];
            final name = item['name'] ?? item['Name'] ?? item['specialtyName'] ?? item['SpecialtyName'];

            final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');

            return parsedId != null &&
                parsedId > 0 &&
                name != null &&
                name.toString().trim().isNotEmpty;
          }).map((item) {
            if (item is Map<String, dynamic>) {
              final id = item['specialtyId'] ?? item['SpecialtyId'] ?? item['id'] ?? item['Id'];
              final name = item['name'] ?? item['Name'] ?? item['specialtyName'] ?? item['SpecialtyName'];
              final icon = item['icon'] ?? item['Icon'] ?? '';

              item['specialtyId'] = id is int ? id : int.tryParse(id.toString()) ?? 0;
              item['name'] = name.toString();
              item['icon'] = icon.toString();
            }

            return item;
          }).toList();

          _specialtiesCache = specialties;
          return _specialtiesCache!;
        }

        return _specialtiesCache ?? [];
      } catch (_) {
        return _specialtiesCache ?? [];
      } finally {
        _specialtiesRequest = null;
      }
    })();

    _specialtiesRequest = request;
    return request;
  }

  static Future<void> createSpecialty({
    required String name,
    required String icon,
  }) async {
    final response = await http
        .post(
      specialtiesUrl,
      headers: headers,
      body: jsonEncode({
        'name': name.trim(),
        'icon': icon.trim(),
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create specialty: ${response.body}');
    }

    clearSpecialtiesCache();
  }

  static Future<void> updateSpecialty({
    required int specialtyId,
    required String name,
    required String icon,
  }) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/Specialties/$specialtyId'),
      headers: headers,
      body: jsonEncode({
        'specialtyId': specialtyId,
        'name': name.trim(),
        'icon': icon.trim(),
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update specialty: ${response.body}');
    }

    clearSpecialtiesCache();
  }

  static Future<void> deleteSpecialty(int specialtyId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Specialties/$specialtyId'),
      headers: headers,
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete specialty: ${response.body}');
    }

    clearSpecialtiesCache();
  }

  static String doctorImageBase64FromBytes(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static Future<String> uploadDoctorImageBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/Doctors/upload-image'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final response =
    await request.send().timeout(uploadTimeout);

    final body =
    await response.stream.bytesToString();

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final data = decodeMap(body);
      final imageUrl = (
          data?['imageUrl'] ??
              data?['ImageUrl'] ??
              ''
      ).toString();

      if (imageUrl.isEmpty) {
        throw Exception('Image URL is empty');
      }

      return fixImageUrl(imageUrl);
    }

    throw Exception(
      'Failed to upload doctor image '
          '(${response.statusCode}): $body',
    );
  }

  static Future<String> uploadAndSaveDoctorImageBytes({
    required int doctorId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/Doctors/$doctorId/upload-image',
      ),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final response =
    await request.send().timeout(uploadTimeout);

    final body =
    await response.stream.bytesToString();

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final data = decodeMap(body);

      final imageUrl = (
          data?['imageUrl'] ??
              data?['ImageUrl'] ??
              ''
      ).toString().trim();

      if (imageUrl.isEmpty) {
        throw Exception(
          'Image was uploaded but no URL was returned.',
        );
      }

      clearDoctorsCache();

      return fixImageUrl(imageUrl);
    }

    throw Exception(
      'Failed to save doctor image '
          '(${response.statusCode}): $body',
    );
  }

  static Future<String> uploadDoctorImage(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/Doctors/upload-image'),
    );

    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath('file', filePath),
    );

    final response =
    await request.send().timeout(uploadTimeout);

    final body =
    await response.stream.bytesToString();

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final data = decodeMap(body);
      final imageUrl = (
          data?['imageUrl'] ??
              data?['ImageUrl'] ??
              ''
      ).toString();

      if (imageUrl.isEmpty) {
        throw Exception('Image URL is empty');
      }

      return fixImageUrl(imageUrl);
    }

    throw Exception(
      'Failed to upload doctor image '
          '(${response.statusCode}): $body',
    );
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return null;
    }

    final loginUrls = <Uri>[
      Uri.parse('http://medlink-rana.premiumasp.net/api/Users/login'),
      Uri.parse('https://medlink-rana.premiumasp.net/api/Users/login'),
    ];

    for (final loginUrl in loginUrls) {
      try {
        final response = await http
            .post(
          loginUrl,
          headers: headers,
          body: jsonEncode({
            'email': cleanEmail,
            'password': cleanPassword,
          }),
        )
            .timeout(normalTimeout);

        if (response.statusCode == 200) {
          final user = decodeMap(response.body);

          if (user == null) {
            continue;
          }

          final rawUserId =
              user['userId'] ??
                  user['UserId'] ??
                  user['id'] ??
                  user['Id'];

          final parsedUserId =
          rawUserId is int
              ? rawUserId
              : int.tryParse(rawUserId?.toString() ?? '');

          if (parsedUserId == null || parsedUserId <= 0) {
            continue;
          }

          // تصفير بيانات الحساب السابق قبل حفظ المستخدم الجديد.
          clearSessionCaches();

          return Map<String, dynamic>.from(user);
        }

        // 401 تعني أن البيانات غير صحيحة، فلا نكرر على رابط آخر.
        if (response.statusCode == 401) {
          return null;
        }
      } catch (_) {
        // نجرب الرابط الثاني فقط عند فشل الاتصال.
      }
    }

    return null;
  }

  static Future<bool> sendResetCode({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users/send-reset-code'),
        headers: headers,
        body: jsonEncode({
          'email': email.trim(),
        }),
      )
          .timeout(normalTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users/verify-reset-code'),
        headers: headers,
        body: jsonEncode({
          'email': email.trim(),
          'code': code.trim(),
        }),
      )
          .timeout(normalTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/Users/reset-password'),
        headers: headers,
        body: jsonEncode({
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword.trim(),
        }),
      )
          .timeout(normalTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> register({
    required String fullName,
    String fullNameAr = '',
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        usersUrl,
        headers: headers,
        body: jsonEncode({
          'fullName': fullName.trim(),
          'fullNameAr': fullNameAr.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'phoneNumber': '',
          'address': '',
          'gender': '',
          'dateOfBirth': '',
          'profileImage': 'assets/images/profile.jpg',
          'role': 'Patient',
        }),
      )
          .timeout(normalTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateUser({
    required int userId,
    required String fullName,
    String fullNameAr = '',
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    required String gender,
    required String dateOfBirth,
    required String profileImage,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/Users/$userId'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'fullName': fullName.trim(),
          'fullNameAr': fullNameAr.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'phoneNumber': phoneNumber.trim(),
          'address': address.trim(),
          'gender': gender.trim(),
          'dateOfBirth': dateOfBirth.trim(),
          'profileImage': profileImage.trim(),
        }),
      )
          .timeout(normalTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getUsers() async {
    try {
      final response =
      await http.get(usersUrl, headers: headers).timeout(normalTimeout);

      if (response.statusCode == 200) {
        return decodeList(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getPatients() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Users/patients'), headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        return decodeList(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getRecentPatients() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Users/recent-patients'), headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        return decodeList(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteUser(int userId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/Users/$userId'), headers: headers)
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }

  static Future<int> getUsersCount() async {
    final users = await getUsers();
    return users.length;
  }

  static Future<int> getPatientsCount() async {
    final patients = await getPatients();
    return patients.length;
  }

  static Future<bool> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/Users/change-password/$userId'),
        headers: headers,
        body: jsonEncode({
          'oldPassword': oldPassword.trim(),
          'newPassword': newPassword.trim(),
        }),
      )
          .timeout(normalTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getDoctors({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _doctorsCache != null) return _doctorsCache!;
    if (!forceRefresh && _doctorsRequest != null) return _doctorsRequest!;

    final request = (() async {
      try {
        final response =
        await http.get(doctorsUrl, headers: headers).timeout(normalTimeout);

        if (response.statusCode == 200) {
          final data = decodeList(response.body);

          final doctors = data.map((doctor) {
            if (doctor is Map<String, dynamic>) {
              final rawImage = (
                  doctor['image'] ??
                      doctor['Image'] ??
                      doctor['doctorImage'] ??
                      doctor['DoctorImage'] ??
                      ''
              ).toString();

              final fixedImage = fixImageUrl(rawImage);

              // نحافظ على نفس رابط الصورة أثناء التحديث
              // الصامت، لكي يستفيد CachedNetworkImage من الكاش
              // ولا يعيد تنزيل صور الأطباء كل مرة.
              doctor['image'] = fixedImage;

              final rawDoctorId =
                  doctor['doctorId'] ??
                      doctor['DoctorId'] ??
                      doctor['id'] ??
                      doctor['Id'];

              doctor['doctorId'] = rawDoctorId is int
                  ? rawDoctorId
                  : int.tryParse(rawDoctorId?.toString() ?? '') ?? 0;

              doctor['fullName'] = (
                  doctor['fullName'] ??
                      doctor['FullName'] ??
                      doctor['name'] ??
                      doctor['Name'] ??
                      ''
              ).toString();

              doctor['specialty'] = getSpecialtyName(doctor);
            }
            return doctor;
          }).toList();

          _doctorsCache = doctors;
          return doctors;
        }

        _doctorsCache = [];
        return [];
      } catch (_) {
        return _doctorsCache ?? [];
      } finally {
        _doctorsRequest = null;
      }
    })();

    _doctorsRequest = request;
    return request;
  }

  static Future<List<dynamic>> searchDoctors(String query) async {
    final doctors = await getDoctors();
    final search = query.trim().toLowerCase();

    if (search.isEmpty) return doctors;

    return doctors.where((doctor) {
      final name = doctor['fullName']?.toString().toLowerCase() ?? '';
      final specialty = doctor['specialty']?.toString().toLowerCase() ?? '';

      return name.contains(search) || specialty.contains(search);
    }).toList();
  }

  static Future<dynamic> getDoctorById(
      int id, {
        bool forceRefresh = false,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl/Doctors/$id').replace(
        queryParameters: forceRefresh
            ? {
          'v': DateTime.now()
              .millisecondsSinceEpoch
              .toString(),
        }
            : null,
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        final data = decodeMap(response.body);

        if (data != null) {
          final rawImage = (
              data['image'] ??
                  data['Image'] ??
                  data['doctorImage'] ??
                  data['DoctorImage'] ??
                  ''
          ).toString();

          data['image'] = fixImageUrl(rawImage);
          data['specialty'] = getSpecialtyName(data);
        }

        return data;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> createDoctor({
    required String fullName,
    required int specialtyId,
    required String phoneNumber,
    required String email,
    required String image,
  }) async {
    final cleanName = fullName.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanEmail = email.trim();
    final cleanImage = image.trim();

    if (cleanName.isEmpty) {
      throw Exception('Doctor name is required');
    }

    if (specialtyId <= 0) {
      throw Exception('Please select a specialty');
    }

    final response = await http
        .post(
      doctorsUrl,
      headers: headers,
      body: jsonEncode({
        'doctorId': 0,
        'fullName': cleanName,
        'specialtyId': specialtyId,
        'phoneNumber': cleanPhone,
        'email': cleanEmail,
        'image': cleanImage,
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor: ${response.body}');
    }

    clearDoctorsCache();
  }

  static Future<void> updateDoctor({
    required int doctorId,
    required String fullName,
    required int specialtyId,
    required String phoneNumber,
    required String email,
    required String image,
  }) async {
    final cleanImage = image.trim();

    final response = await http
        .put(
      Uri.parse('$baseUrl/Doctors/$doctorId'),
      headers: headers,
      body: jsonEncode({
        'doctorId': doctorId,
        'fullName': fullName.trim(),
        'specialtyId': specialtyId,
        'phoneNumber': phoneNumber.trim(),
        'email': email.trim(),
        'image': cleanImage,
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to update doctor '
            '(${response.statusCode}): ${response.body}',
      );
    }

    clearDoctorsCache();
  }

  static Future<Map<String, dynamic>> uploadAndSaveDoctorImage({
    required int doctorId,
    required String fullName,
    required int specialtyId,
    required String phoneNumber,
    required String email,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (doctorId <= 0) {
      throw Exception('Invalid doctor id');
    }

    if (bytes.isEmpty) {
      throw Exception('The selected image is empty');
    }

    String savedImageUrl;

    try {
      // المسار المباشر: يرفع الصورة ويربطها بالطبيب في طلب واحد.
      savedImageUrl = await uploadAndSaveDoctorImageBytes(
        doctorId: doctorId,
        bytes: bytes,
        fileName: fileName,
      );
    } catch (_) {
      // مسار احتياطي يحافظ على التوافق مع نسخة السيرفر القديمة.
      savedImageUrl = await uploadDoctorImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      await updateDoctor(
        doctorId: doctorId,
        fullName: fullName,
        specialtyId: specialtyId,
        phoneNumber: phoneNumber,
        email: email,
        image: savedImageUrl,
      );
    }

    clearDoctorsCache();

    final refreshed = await getDoctorById(
      doctorId,
      forceRefresh: true,
    );

    if (refreshed is Map) {
      final result = Map<String, dynamic>.from(refreshed);

      final refreshedImage = (
          result['image'] ??
              result['Image'] ??
              result['doctorImage'] ??
              result['DoctorImage'] ??
              savedImageUrl
      ).toString();

      final visibleImage = withImageCacheVersion(
        fixImageUrl(refreshedImage),
        version: DateTime.now().millisecondsSinceEpoch,
      );

      result['image'] = visibleImage;
      result['Image'] = visibleImage;

      return result;
    }

    // حتى لو تعذر إعادة التحميل، نعيد البيانات الموجودة مع رابط الصورة المحفوظ.
    return <String, dynamic>{
      'doctorId': doctorId,
      'fullName': fullName.trim(),
      'specialtyId': specialtyId,
      'phoneNumber': phoneNumber.trim(),
      'email': email.trim(),
      'image': withImageCacheVersion(
        fixImageUrl(savedImageUrl),
        version: DateTime.now().millisecondsSinceEpoch,
      ),
    };
  }

  static Future<void> deleteDoctor(int doctorId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/Doctors/$doctorId'), headers: headers)
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete doctor');
    }

    clearDoctorsCache();
  }

  static Future<void> bookAppointment({
    required int patientId,
    required int doctorId,
    required DateTime appointmentDate,
    String doctorName = '',
    String specialtyName = '',
    String doctorImage = '',
  }) async {
    if (patientId <= 0) {
      throw Exception('Invalid patient id');
    }

    if (doctorId <= 0) {
      throw Exception('Invalid doctor id');
    }

    final response = await http
        .post(
      appointmentsUrl,
      headers: headers,
      body: jsonEncode({
        'appointmentId': 0,
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate.toIso8601String(),
        'status': 'Pending',
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode == 409) {
      String message = 'هذا الموعد غير متاح.';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}

      throw AppointmentSlotTakenException(message);
    }

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'تعذر حجز الموعد (${response.statusCode}).',
      );
    }

    // مهم: لا ننتظر طلبات GET بعد نجاح الحجز.
    // سابقاً كان الحجز ينجح في السيرفر ثم يبقى الزر يحمل،
    // وإذا تأخر تحديث القوائم تظهر رسالة Failed رغم نجاح الحجز.
    Map<String, dynamic> createdAppointment = <String, dynamic>{
      'appointmentId': 0,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': 'Pending',
      'doctorName': doctorName.trim(),
      'specialtyName': specialtyName.trim(),
      'doctorImage': fixImageUrl(doctorImage),
    };

    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          createdAppointment = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // نجاح الحجز لا يعتمد على إمكانية قراءة جسم الاستجابة.
      }
    }

    createdAppointment['patientId'] =
        createdAppointment['patientId'] ??
            createdAppointment['PatientId'] ??
            patientId;

    createdAppointment['doctorId'] =
        createdAppointment['doctorId'] ??
            createdAppointment['DoctorId'] ??
            doctorId;

    createdAppointment['appointmentDate'] =
        createdAppointment['appointmentDate'] ??
            createdAppointment['AppointmentDate'] ??
            appointmentDate.toIso8601String();

    createdAppointment['status'] =
        createdAppointment['status'] ??
            createdAppointment['Status'] ??
            'Pending';

    final returnedDoctorName = (
        createdAppointment['doctorName'] ??
            createdAppointment['DoctorName'] ??
            ''
    ).toString().trim();

    final returnedSpecialtyName = (
        createdAppointment['specialtyName'] ??
            createdAppointment['SpecialtyName'] ??
            ''
    ).toString().trim();

    final returnedDoctorImage = (
        createdAppointment['doctorImage'] ??
            createdAppointment['DoctorImage'] ??
            createdAppointment['image'] ??
            createdAppointment['Image'] ??
            ''
    ).toString().trim();

    if (returnedDoctorName.isEmpty && doctorName.trim().isNotEmpty) {
      createdAppointment['doctorName'] = doctorName.trim();
      createdAppointment['DoctorName'] = doctorName.trim();
    }

    if (returnedSpecialtyName.isEmpty && specialtyName.trim().isNotEmpty) {
      createdAppointment['specialtyName'] = specialtyName.trim();
      createdAppointment['SpecialtyName'] = specialtyName.trim();
    }

    if (returnedDoctorImage.isNotEmpty) {
      final fixedDoctorImage = fixImageUrl(returnedDoctorImage);
      createdAppointment['doctorImage'] = fixedDoctorImage;
      createdAppointment['DoctorImage'] = fixedDoctorImage;
      createdAppointment['image'] = fixedDoctorImage;
      createdAppointment['Image'] = fixedDoctorImage;
    } else if (doctorImage.trim().isNotEmpty) {
      final fixedDoctorImage = fixImageUrl(doctorImage);
      createdAppointment['doctorImage'] = fixedDoctorImage;
      createdAppointment['DoctorImage'] = fixedDoctorImage;
      createdAppointment['image'] = fixedDoctorImage;
      createdAppointment['Image'] = fixedDoctorImage;
    }

    final currentUserList = List<dynamic>.from(
      _userAppointmentsCache[patientId] ?? const <dynamic>[],
    );

    final createdId = (
        createdAppointment['appointmentId'] ??
            createdAppointment['AppointmentId'] ??
            0
    ).toString();

    final alreadyExists = createdId != '0' &&
        currentUserList.any((item) {
          if (item is! Map) return false;

          final itemId =
              item['appointmentId'] ?? item['AppointmentId'];

          return itemId?.toString() == createdId;
        });

    if (!alreadyExists) {
      currentUserList.insert(
        0,
        Map<String, dynamic>.from(createdAppointment),
      );
    }

    _userAppointmentsCache[patientId] = currentUserList;
    _userAppointmentsRequests.remove(patientId);

    final previousCount = _appointmentCountCache[patientId];
    if (previousCount != null && !alreadyExists) {
      _appointmentCountCache[patientId] = previousCount + 1;
    } else {
      _appointmentCountCache[patientId] = currentUserList.length;
    }
    _appointmentCountRequests.remove(patientId);

    if (_allAppointmentsCache != null && !alreadyExists) {
      _allAppointmentsCache!.insert(
        0,
        Map<String, dynamic>.from(createdAppointment),
      );
    }

    _allAppointmentsRequest = null;
    clearNotificationsCache(patientId);

    // الشاشة والبروفايل يتحدثان فوراً من الكاش بدون انتظار الشبكة.
    notifyAppointmentsChanged();
  }

  static Future<List<dynamic>> getAllAppointments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _allAppointmentsCache != null) {
      return List<dynamic>.from(_allAppointmentsCache!);
    }

    if (!forceRefresh && _allAppointmentsRequest != null) {
      return _allAppointmentsRequest!;
    }

    final request = (() async {
      try {
        final response = await http
            .get(appointmentsUrl, headers: headers)
            .timeout(normalTimeout);

        if (response.statusCode != 200) {
          if (_allAppointmentsCache != null) {
            return List<dynamic>.from(_allAppointmentsCache!);
          }

          throw Exception(
            'Failed to load appointments: '
                '${response.statusCode} ${response.body}',
          );
        }

        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          throw Exception('Appointments response is not a list');
        }

        final appointments = decoded.map<dynamic>((appointment) {
          if (appointment is! Map) return appointment;

          final copy = Map<String, dynamic>.from(appointment);

          final doctorImage = copy['doctorImage'] ??
              copy['DoctorImage'] ??
              copy['image'] ??
              copy['Image'];

          final fixedImage = fixImageUrl(
            doctorImage?.toString() ?? '',
          );

          copy['doctorImage'] = fixedImage;
          copy['DoctorImage'] = fixedImage;
          copy['image'] = fixedImage;

          return copy;
        }).toList();

        _allAppointmentsCache =
        List<dynamic>.from(appointments);

        _rebuildUserAppointmentCaches(appointments);

        return List<dynamic>.from(appointments);
      } catch (_) {
        if (_allAppointmentsCache != null) {
          return List<dynamic>.from(_allAppointmentsCache!);
        }

        rethrow;
      } finally {
        _allAppointmentsRequest = null;
      }
    })();

    _allAppointmentsRequest = request;
    return request;
  }

  static Future<List<dynamic>> getAppointments({
    bool forceRefresh = false,
  }) async {
    final userId = UserSession.userId;

    if (userId == null || userId <= 0) {
      return <dynamic>[];
    }

    if (!forceRefresh &&
        _userAppointmentsCache.containsKey(userId)) {
      return List<dynamic>.from(
        _userAppointmentsCache[userId]!,
      );
    }

    if (!forceRefresh &&
        _userAppointmentsRequests.containsKey(userId)) {
      return _userAppointmentsRequests[userId]!;
    }

    final request = (() async {
      try {
        final response = await http
            .get(
          Uri.parse(
            '$baseUrl/Appointments/patient/$userId',
          ),
          headers: headers,
        )
            .timeout(normalTimeout);

        if (UserSession.userId != userId) {
          return <dynamic>[];
        }

        // دعم نسخة السيرفر القديمة فقط عندما يكون المسار غير موجود.
        if (response.statusCode == 404) {
          final all = await getAllAppointments(
            forceRefresh: forceRefresh,
          );

          if (UserSession.userId != userId) {
            return <dynamic>[];
          }

          final id = userId.toString();

          final fallback = all.where((appointment) {
            if (appointment is! Map) return false;

            return appointment['patientId']?.toString() == id ||
                appointment['PatientId']?.toString() == id;
          }).map<dynamic>((appointment) {
            return appointment is Map
                ? Map<String, dynamic>.from(appointment)
                : appointment;
          }).toList();

          _userAppointmentsCache[userId] =
          List<dynamic>.from(fallback);

          return List<dynamic>.from(fallback);
        }

        if (response.statusCode != 200) {
          if (_userAppointmentsCache.containsKey(userId)) {
            return List<dynamic>.from(
              _userAppointmentsCache[userId]!,
            );
          }

          throw Exception(
            'Failed to load patient appointments: '
                '${response.statusCode} ${response.body}',
          );
        }

        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          throw Exception(
            'Patient appointments response is not a list',
          );
        }

        var appointments = decoded.map<dynamic>((appointment) {
          if (appointment is! Map) return appointment;

          final copy = Map<String, dynamic>.from(appointment);

          final doctorImage = copy['doctorImage'] ??
              copy['DoctorImage'] ??
              copy['image'] ??
              copy['Image'];

          final fixedImage = fixImageUrl(
            doctorImage?.toString() ?? '',
          );

          copy['doctorImage'] = fixedImage;
          copy['DoctorImage'] = fixedImage;
          copy['image'] = fixedImage;

          return copy;
        }).toList();

        // بعض نسخ السيرفر تعيد قائمة فارغة من
        // patient/{userId} رغم وجود مواعيد. في هذه الحالة
        // نجلب القائمة العامة مرة ونأخذ مواعيد المستخد فقط.
        if (appointments.isEmpty) {
          final all = await getAllAppointments(
            forceRefresh: forceRefresh,
          );

          if (UserSession.userId != userId) {
            return <dynamic>[];
          }

          final id = userId.toString();
          appointments = all.where((appointment) {
            if (appointment is! Map) return false;

            return appointment['patientId']?.toString() == id ||
                appointment['PatientId']?.toString() == id;
          }).map<dynamic>((appointment) {
            return appointment is Map
                ? Map<String, dynamic>.from(appointment)
                : appointment;
          }).toList();
        }

        if (UserSession.userId != userId) {
          return <dynamic>[];
        }

        // القائمة الفارغة نتيجة صحيحة، لذلك لا نحمل كل مواعيد النظام مرة ثانية.
        _userAppointmentsCache[userId] =
        List<dynamic>.from(appointments);

        return List<dynamic>.from(appointments);
      } catch (_) {
        if (_userAppointmentsCache.containsKey(userId)) {
          return List<dynamic>.from(
            _userAppointmentsCache[userId]!,
          );
        }

        rethrow;
      } finally {
        _userAppointmentsRequests.remove(userId);
      }
    })();

    _userAppointmentsRequests[userId] = request;
    return request;
  }

  static void _rebuildUserAppointmentCaches(List<dynamic> appointments) {
    final grouped = <int, List<dynamic>>{};

    for (final appointment in appointments) {
      if (appointment is! Map) continue;

      final rawId = appointment['patientId'] ?? appointment['PatientId'];
      final patientId =
      rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

      if (patientId == null) continue;

      grouped.putIfAbsent(patientId, () => <dynamic>[]).add(
        Map<String, dynamic>.from(appointment),
      );
    }

    _userAppointmentsCache
      ..clear()
      ..addAll(grouped);
    _userAppointmentsRequests.clear();
  }

  static Future<void> updateAppointmentStatus({
    required Map<String, dynamic> appointment,
    required String status,
  }) async {
    final rawAppointmentId =
        appointment['appointmentId'] ?? appointment['AppointmentId'];

    final rawPatientId =
        appointment['patientId'] ?? appointment['PatientId'];

    final rawDoctorId =
        appointment['doctorId'] ?? appointment['DoctorId'];

    final rawAppointmentDate =
        appointment['appointmentDate'] ?? appointment['AppointmentDate'];

    final appointmentId = rawAppointmentId is int
        ? rawAppointmentId
        : int.tryParse(rawAppointmentId?.toString() ?? '');

    final patientId = rawPatientId is int
        ? rawPatientId
        : int.tryParse(rawPatientId?.toString() ?? '');

    final doctorId = rawDoctorId is int
        ? rawDoctorId
        : int.tryParse(rawDoctorId?.toString() ?? '');

    final appointmentDate =
        rawAppointmentDate?.toString().trim() ?? '';

    if (appointmentId == null ||
        appointmentId <= 0 ||
        patientId == null ||
        patientId <= 0 ||
        doctorId == null ||
        doctorId <= 0 ||
        appointmentDate.isEmpty) {
      throw Exception('Invalid appointment data');
    }

    final response = await http
        .put(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: headers,
      body: jsonEncode({
        'appointmentId': appointmentId,
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate,
        'status': status.trim(),
      }),
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to update appointment status '
            '(${response.statusCode}): ${response.body}',
      );
    }

    void updateList(List<dynamic>? list) {
      if (list == null) return;

      for (final item in list) {
        if (item is! Map) continue;

        final itemId =
            item['appointmentId'] ?? item['AppointmentId'];

        if (itemId?.toString() == appointmentId.toString()) {
          item['status'] = status;
          item['Status'] = status;
          break;
        }
      }
    }

    updateList(_allAppointmentsCache);

    for (final list in _userAppointmentsCache.values) {
      updateList(list);
    }

    _allAppointmentsRequest = null;
    _userAppointmentsRequests.clear();
    clearNotificationsCache();
    notifyAppointmentsChanged();
  }

  static Future<int> getAppointmentCountByUser(
      int patientId, {
        bool forceRefresh = false,
      }) async {
    if (patientId <= 0) return 0;

    if (!forceRefresh &&
        _appointmentCountCache.containsKey(patientId)) {
      return _appointmentCountCache[patientId]!;
    }

    if (!forceRefresh &&
        _appointmentCountRequests.containsKey(patientId)) {
      return _appointmentCountRequests[patientId]!;
    }

    final request = (() async {
      try {
        final response = await http
            .get(
          Uri.parse(
            '$baseUrl/Appointments/patient/$patientId',
          ),
          headers: headers,
        )
            .timeout(normalTimeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);

          if (decoded is List) {
            final count = decoded.length;
            _appointmentCountCache[patientId] = count;
            return count;
          }
        }

        // دعم نسخة السيرفر القديمة إذا لم يوجد مسار patient.
        if (response.statusCode == 404) {
          final all = await getAllAppointments(
            forceRefresh: forceRefresh,
          );

          final id = patientId.toString();
          final count = all.where((appointment) {
            if (appointment is! Map) return false;

            return appointment['patientId']?.toString() == id ||
                appointment['PatientId']?.toString() == id;
          }).length;

          _appointmentCountCache[patientId] = count;
          return count;
        }

        return _appointmentCountCache[patientId] ??
            _userAppointmentsCache[patientId]?.length ??
            0;
      } catch (_) {
        return _appointmentCountCache[patientId] ??
            _userAppointmentsCache[patientId]?.length ??
            0;
      } finally {
        _appointmentCountRequests.remove(patientId);
      }
    })();

    _appointmentCountRequests[patientId] = request;
    return request;
  }

  static Future<void> deleteAppointment(int appointmentId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: headers,
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'تعذر حذف الموعد (${response.statusCode}).',
      );
    }

    // نحدد صاحب الموعد قبل الحذف حتى يتحدث عداد البروفايل فوراً.
    int? deletedPatientId;

    for (final entry in _userAppointmentsCache.entries) {
      final exists = entry.value.any((item) {
        if (item is! Map) return false;
        final rawId = item['appointmentId'] ?? item['AppointmentId'];
        return rawId?.toString() == appointmentId.toString();
      });

      if (exists) {
        deletedPatientId = entry.key;
        break;
      }
    }

    // نحذف الموعد من الكاش مباشرة بدل تصفير القائمة كاملة.
    void removeFromList(List<dynamic>? list) {
      if (list == null) return;

      list.removeWhere((item) {
        if (item is! Map) return false;

        final rawId =
            item['appointmentId'] ?? item['AppointmentId'];

        return rawId?.toString() == appointmentId.toString();
      });
    }

    removeFromList(_allAppointmentsCache);

    for (final list in _userAppointmentsCache.values) {
      removeFromList(list);
    }

    _allAppointmentsRequest = null;
    _userAppointmentsRequests.clear();

    if (deletedPatientId != null) {
      _appointmentCountCache[deletedPatientId!] =
          _userAppointmentsCache[deletedPatientId!]?.length ?? 0;
      _appointmentCountRequests.remove(deletedPatientId!);
    }

    clearNotificationsCache();
    notifyAppointmentsChanged();
  }

  static List<dynamic> _normalizeMedicalRecords(
      List<dynamic> records,
      ) {
    return records.map<dynamic>((record) {
      if (record is! Map) return record;

      final copy = Map<String, dynamic>.from(record);

      final rawFileUrl =
          copy['fileUrl'] ??
              copy['FileUrl'] ??
              copy['filePath'] ??
              copy['FilePath'] ??
              '';

      final fixedFileUrl = fixFileUrl(rawFileUrl.toString());

      copy['fileUrl'] = fixedFileUrl;
      copy['FileUrl'] = fixedFileUrl;

      return copy;
    }).toList();
  }

  static int? _medicalRecordPatientId(dynamic record) {
    if (record is! Map) return null;

    final direct =
        record['patientId'] ??
            record['PatientId'] ??
            record['userId'] ??
            record['UserId'];

    final directId = direct is int
        ? direct
        : int.tryParse(direct?.toString() ?? '');

    if (directId != null) return directId;

    final patient = record['patient'] ?? record['Patient'];

    if (patient is Map) {
      final nested =
          patient['patientId'] ??
              patient['PatientId'] ??
              patient['userId'] ??
              patient['UserId'] ??
              patient['id'] ??
              patient['Id'];

      return nested is int
          ? nested
          : int.tryParse(nested?.toString() ?? '');
    }

    return null;
  }

  static Future<List<dynamic>> getMedicalRecords() async {
    final response = await http
        .get(medicalRecordsUrl, headers: headers)
        .timeout(normalTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load medical records '
            '(${response.statusCode}): ${response.body}',
      );
    }

    return _normalizeMedicalRecords(
      decodeList(response.body),
    );
  }

  static Future<List<dynamic>> getMedicalRecordsByUser(
      int patientId,
      ) async {
    if (patientId <= 0) {
      throw Exception('Invalid patient id');
    }

    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/MedicalRecords/patient/$patientId'),
        headers: headers,
      )
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        final directRecords = _normalizeMedicalRecords(
          decodeList(response.body),
        );

        // بعض نسخ السيرفر ترجع 200 وقائمة فارغة رغم وجود سجلات.
        if (directRecords.isNotEmpty) {
          return directRecords;
        }
      }
    } catch (_) {
      // نكمل للمسار الاحتياطي.
    }

    final allRecords = await getMedicalRecords();

    return allRecords.where((record) {
      return _medicalRecordPatientId(record) == patientId;
    }).map<dynamic>((record) {
      return record is Map
          ? Map<String, dynamic>.from(record)
          : record;
    }).toList();
  }

  static Future<void> createMedicalRecord({
    required int patientId,
    required int doctorId,
    required String title,
    required String description,
    required String recordDate,
    required String status,
    required String fileUrl,
  }) async {
    final response = await http
        .post(
      medicalRecordsUrl,
      headers: headers,
      body: jsonEncode({
        'patientId': patientId,
        'doctorId': doctorId,
        'title': title,
        'description': description,
        'recordDate': recordDate,
        'status': status,
        'fileUrl': fileUrl,
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to create medical record '
            '(${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> uploadMedicalRecord({
    required int patientId,
    required int doctorId,
    required String title,
    required String description,
    required String status,
    required String filePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/MedicalRecords/upload'),
    );

    request.headers.addAll({'Accept': 'application/json'});

    request.fields['PatientId'] = patientId.toString();
    request.fields['DoctorId'] = doctorId.toString();
    request.fields['Title'] = title.trim();
    request.fields['Description'] = description.trim();
    request.fields['Status'] = status.trim();

    request.files.add(await http.MultipartFile.fromPath('File', filePath));

    final response = await request.send().timeout(uploadTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload medical record file');
    }
  }

  static Future<void> deleteMedicalRecord(int recordId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/MedicalRecords/$recordId'),
      headers: headers,
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete medical record');
    }
  }

  static Future<int> getDoctorsCount() async {
    final doctors = await getDoctors();
    return doctors.length;
  }

  static Future<int> getMedicalRecordsCount() async {
    final records = await getMedicalRecords();
    return records.length;
  }


  static Future<int> getPendingAppointmentsCount({
    bool forceRefresh = false,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/Appointments/pending-count',
      ).replace(
        queryParameters: forceRefresh
            ? {
          'v': DateTime.now().millisecondsSinceEpoch.toString(),
        }
            : null,
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          final rawCount = decoded['count'] ?? decoded['Count'];
          final count = rawCount is int
              ? rawCount
              : int.tryParse(rawCount?.toString() ?? '');

          if (count != null) return count;
        }

        final plainCount = int.tryParse(response.body.trim());
        if (plainCount != null) return plainCount;
      }

      // توافق مؤقت قبل نشر مسار pending-count على السيرفر.
      final appointments = await getAllAppointments(
        forceRefresh: forceRefresh,
      );

      return appointments.where((appointment) {
        if (appointment is! Map) return false;

        final rawStatus =
            appointment['status'] ?? appointment['Status'] ?? '';

        return rawStatus
            .toString()
            .trim()
            .toLowerCase() ==
            'pending';
      }).length;
    } catch (_) {
      if (_allAppointmentsCache != null) {
        return _allAppointmentsCache!.where((appointment) {
          if (appointment is! Map) return false;

          final rawStatus =
              appointment['status'] ?? appointment['Status'] ?? '';

          return rawStatus
              .toString()
              .trim()
              .toLowerCase() ==
              'pending';
        }).length;
      }

      rethrow;
    }
  }

  static Future<int> getAppointmentsCount({
    bool forceRefresh = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Appointments/count').replace(
        queryParameters: forceRefresh
            ? {
          'v': DateTime.now().millisecondsSinceEpoch.toString(),
        }
            : null,
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          final rawCount = decoded['count'] ?? decoded['Count'];
          final count = rawCount is int
              ? rawCount
              : int.tryParse(rawCount?.toString() ?? '');

          if (count != null) return count;
        }

        final plainCount = int.tryParse(response.body.trim());
        if (plainCount != null) return plainCount;
      }

      // توافق مؤقت إذا لم يُنشر مسار count على السيرفر بعد.
      final appointments = await getAllAppointments(
        forceRefresh: forceRefresh,
      );

      return appointments.length;
    } catch (_) {
      if (_allAppointmentsCache != null) {
        return _allAppointmentsCache!.length;
      }

      rethrow;
    }
  }

  static Future<List<dynamic>> getNotificationsByUser(
      int userId, {
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh && _notificationsCache.containsKey(userId)) {
      return List<dynamic>.from(_notificationsCache[userId]!);
    }

    if (!forceRefresh && _notificationsRequests.containsKey(userId)) {
      return _notificationsRequests[userId]!;
    }

    final request = (() async {
      try {
        final response = await http
            .get(
          Uri.parse('$baseUrl/Notifications/user/$userId'),
          headers: headers,
        )
            .timeout(normalTimeout);

        if (response.statusCode == 200) {
          final data = decodeList(response.body);
          _notificationsCache[userId] = data;
          return List<dynamic>.from(data);
        }

        _notificationsCache[userId] = [];
        return [];
      } catch (_) {
        return _notificationsCache[userId] ?? [];
      } finally {
        _notificationsRequests.remove(userId);
      }
    })();

    _notificationsRequests[userId] = request;
    return request;
  }


  static Future<int> getNotificationsCountByUser(
      int userId, {
        bool forceRefresh = false,
      }) async {
    final notifications = await getNotificationsByUser(
      userId,
      forceRefresh: forceRefresh,
    );

    return notifications.length;
  }

  static Future<void> deleteNotification(int notificationId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Notifications/$notificationId'),
      headers: headers,
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }

    clearNotificationsCache();
  }
}

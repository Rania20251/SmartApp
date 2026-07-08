import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'user_session.dart';

class ApiService {
  static const String siteUrl = 'http://medlink-rana.premiumasp.net';
  static const String baseUrl = '$siteUrl/api';

  static const Duration normalTimeout = Duration(seconds: 20);
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
  static List<dynamic>? _appointmentsCache;
  static final Map<int, List<dynamic>> _notificationsCache = {};
  static List<dynamic>? _bannersCache;

  static Future<List<dynamic>>? _doctorsRequest;
  static Future<List<dynamic>>? _specialtiesRequest;
  static Future<List<dynamic>>? _appointmentsRequest;
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

  static void clearAppointmentsCache() {
    _appointmentsCache = null;
    _appointmentsRequest = null;
  }

  static void resetAppointmentsCache() {
    _appointmentsCache = null;
    _appointmentsRequest = null;
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

        if (response.statusCode == 200) {
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

    if (value.isEmpty || value == 'string') {
      return 'assets/images/profile.jpg';
    }

    if (value.startsWith('data:image')) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (value.startsWith('/')) return '$siteUrl$value';
    if (value.startsWith('images/') || value.startsWith('uploads/')) {
      return '$siteUrl/$value';
    }
    if (value.startsWith('assets/')) return value;

    return value;
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

        if (response.statusCode == 200) {
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

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final response = await request.send().timeout(uploadTimeout);
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = decodeMap(body);
      final imageUrl = data?['imageUrl']?.toString() ?? '';

      if (imageUrl.isEmpty) {
        throw Exception('Image URL is empty');
      }

      return fixImageUrl(imageUrl);
    }

    throw Exception('Failed to upload doctor image: $body');
  }

  static Future<String> uploadDoctorImage(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/Doctors/upload-image'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', filePath),
    );

    final response = await request.send().timeout(uploadTimeout);
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = decodeMap(body);
      final imageUrl = data?['imageUrl']?.toString() ?? '';

      if (imageUrl.isEmpty) {
        throw Exception('Image URL is empty');
      }

      return fixImageUrl(imageUrl);
    }

    throw Exception('Failed to upload doctor image: $body');
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users/login'),
        headers: headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
        }),
      )
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        return decodeMap(response.body);
      }

      return null;
    } catch (_) {
      return null;
    }
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
              doctor['image'] = fixImageUrl(doctor['image']?.toString() ?? '');
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

  static Future<dynamic> getDoctorById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Doctors/$id'), headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        final data = decodeMap(response.body);

        if (data != null) {
          data['image'] = fixImageUrl(data['image']?.toString() ?? '');
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
    final cleanImage = image.trim().isEmpty ? '' : fixImageUrl(image);

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
        'image': fixImageUrl(image),
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update doctor: ${response.body}');
    }

    clearDoctorsCache();
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
  }) async {
    final response = await http
        .post(
      appointmentsUrl,
      headers: headers,
      body: jsonEncode({
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate.toIso8601String(),
        'status': 'Pending',
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to book appointment');
    }

    resetAppointmentsCache();
    clearNotificationsCache(patientId);
  }

  static Future<List<dynamic>> getAllAppointments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _appointmentsCache != null) {
      return _appointmentsCache!;
    }

    if (_appointmentsRequest != null) {
      return _appointmentsRequest!;
    }

    final request = (() async {
      try {
        final response = await http
            .get(appointmentsUrl, headers: headers)
            .timeout(normalTimeout);

        if (response.statusCode == 200) {
          final data = decodeList(response.body);

          final appointments = data.map((appointment) {
            if (appointment is Map<String, dynamic>) {
              final doctorImage = appointment['doctorImage'] ??
                  appointment['DoctorImage'] ??
                  appointment['image'] ??
                  appointment['Image'];

              final fixedImage = fixImageUrl(doctorImage?.toString() ?? '');

              appointment['doctorImage'] = fixedImage;
              appointment['DoctorImage'] = fixedImage;
              appointment['image'] = fixedImage;
            }

            return appointment;
          }).toList();

          // Important for mobile:
          // Do not replace a good cached list with an empty list during refresh.
          // Sometimes the hosting is slow and returns late/empty while the UI is refreshing.
          if (appointments.isNotEmpty || _appointmentsCache == null) {
            _appointmentsCache = appointments;
          }

          return _appointmentsCache ?? appointments;
        }

        return _appointmentsCache ?? [];
      } catch (_) {
        return _appointmentsCache ?? [];
      } finally {
        _appointmentsRequest = null;
      }
    })();

    _appointmentsRequest = request;
    return request;
  }

  static Future<List<dynamic>> getAppointments({
    bool forceRefresh = false,
  }) async {
    try {
      final appointments = await getAllAppointments(forceRefresh: forceRefresh);

      if (UserSession.userId == null) return appointments;

      final currentUserId = UserSession.userId.toString();

      return appointments.where((appointment) {
        return appointment['patientId']?.toString() == currentUserId ||
            appointment['PatientId']?.toString() == currentUserId;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> updateAppointmentStatus({
    required Map<String, dynamic> appointment,
    required String status,
  }) async {
    final appointmentId =
        appointment['appointmentId'] ?? appointment['AppointmentId'];

    final patientId = appointment['patientId'] ?? appointment['PatientId'];
    final doctorId = appointment['doctorId'] ?? appointment['DoctorId'];
    final appointmentDate =
        appointment['appointmentDate'] ?? appointment['AppointmentDate'];

    final response = await http
        .put(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: headers,
      body: jsonEncode({
        'appointmentId': appointmentId,
        'patientId': patientId,
        'doctorId': doctorId,
        'appointmentDate': appointmentDate,
        'status': status,
      }),
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update appointment status');
    }

    // Update local cache immediately instead of clearing it.
    // This keeps Manage Appointments visible and fast on mobile.
    if (_appointmentsCache != null) {
      for (final item in _appointmentsCache!) {
        if (item is Map<String, dynamic>) {
          final id = item['appointmentId'] ?? item['AppointmentId'];
          if (id.toString() == appointmentId.toString()) {
            item['status'] = status;
            item['Status'] = status;
            break;
          }
        }
      }
    }

    _appointmentsRequest = null;
    clearNotificationsCache();
  }

  static Future<int> getAppointmentCountByUser(int patientId) async {
    final appointments = await getAllAppointments();
    final id = patientId.toString();

    return appointments.where((appointment) {
      return appointment['patientId']?.toString() == id ||
          appointment['PatientId']?.toString() == id;
    }).length;
  }

  static Future<void> deleteAppointment(int appointmentId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: headers,
    )
        .timeout(normalTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete appointment');
    }

    resetAppointmentsCache();
    clearNotificationsCache();
  }

  static Future<List<dynamic>> getMedicalRecords() async {
    try {
      final response = await http
          .get(medicalRecordsUrl, headers: headers)
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        return decodeList(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getMedicalRecordsByUser(int patientId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/MedicalRecords/patient/$patientId'),
        headers: headers,
      )
          .timeout(normalTimeout);

      if (response.statusCode == 200) {
        return decodeList(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
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
      throw Exception('Failed to create medical record');
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

  static Future<int> getAppointmentsCount() async {
    final appointments = await getAllAppointments();
    return appointments.length;
  }

  static Future<List<dynamic>> getNotificationsByUser(
      int userId, {
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh && _notificationsCache.containsKey(userId)) {
      return _notificationsCache[userId]!;
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
          return data;
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
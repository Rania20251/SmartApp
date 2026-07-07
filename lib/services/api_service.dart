import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'user_session.dart';

class ApiService {
  static const String siteUrl = 'http://medlink-rana.premiumasp.net';
  static const String baseUrl = '$siteUrl/api';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String fixImageUrl(String image) {
    final value = image.trim();

    if (value.isEmpty || value == 'string') {
      return 'assets/images/profile.jpg';
    }

    if (value.startsWith('data:image')) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (value.startsWith('/')) return '$siteUrl$value';
    if (value.startsWith('images/') || value.startsWith('uploads/')) return '$siteUrl/$value';
    if (value.startsWith('assets/')) return value;

    return value;
  }

  static String getSpecialtyName(dynamic doctor) {
    final specialtyNavigation = doctor['specialtyNavigation'];

    if (specialtyNavigation is Map<String, dynamic>) {
      return specialtyNavigation['name']?.toString() ?? '';
    }

    return doctor['specialty']?.toString() ?? '';
  }

  static Future<List<dynamic>> getSpecialties() async {
    final response = await http
        .get(Uri.parse('$baseUrl/Specialties'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }

    return [];
  }

  static Future<void> createSpecialty({
    required String name,
    required String icon,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/Specialties'),
      headers: headers,
      body: jsonEncode({
        "name": name.trim(),
        "icon": icon.trim(),
      }),
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create specialty: ${response.body}');
    }
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
        "specialtyId": specialtyId,
        "name": name.trim(),
        "icon": icon.trim(),
      }),
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update specialty: ${response.body}');
    }
  }

  static Future<void> deleteSpecialty(int specialtyId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/Specialties/$specialtyId'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete specialty: ${response.body}');
    }
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

    final response = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final body = await response.stream.bytesToString();

    print('UPLOAD STATUS: ${response.statusCode}');
    print('UPLOAD BODY: $body');

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      final imageUrl = data['imageUrl']?.toString() ?? '';

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

    final response = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final body = await response.stream.bytesToString();

    print('UPLOAD STATUS: ${response.statusCode}');
    print('UPLOAD BODY: $body');

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      final imageUrl = data['imageUrl']?.toString() ?? '';

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
          "email": email.trim(),
          "password": password.trim(),
        }),
      )
          .timeout(const Duration(seconds: 20));

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
      }

      return null;
    } catch (e) {
      print('LOGIN ERROR: $e');
      return null;
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
        Uri.parse('$baseUrl/Users'),
        headers: headers,
        body: jsonEncode({
          "fullName": fullName.trim(),
          "email": email.trim(),
          "password": password.trim(),
          "phoneNumber": "",
          "address": "",
          "gender": "",
          "dateOfBirth": "",
          "profileImage": "assets/images/profile.jpg",
          "role": "Patient",
        }),
      )
          .timeout(const Duration(seconds: 20));

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('REGISTER ERROR: $e');
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
          "userId": userId,
          "fullName": fullName.trim(),
          "email": email.trim(),
          "password": password.trim(),
          "phoneNumber": phoneNumber.trim(),
          "address": address.trim(),
          "gender": gender.trim(),
          "dateOfBirth": dateOfBirth.trim(),
          "profileImage": profileImage.trim(),
        }),
      )
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('UPDATE USER ERROR: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http
        .get(Uri.parse('$baseUrl/Users'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }

    return [];
  }

  static Future<List<dynamic>> getPatients() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Users/patients'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      print('GET PATIENTS ERROR: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getRecentPatients() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Users/recent-patients'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      print('GET RECENT PATIENTS ERROR: $e');
      return [];
    }
  }

  static Future<void> deleteUser(int userId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/Users/$userId'), headers: headers)
        .timeout(const Duration(seconds: 20));

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
          "oldPassword": oldPassword.trim(),
          "newPassword": newPassword.trim(),
        }),
      )
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('CHANGE PASSWORD ERROR: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getDoctors() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Doctors'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((doctor) {
            if (doctor is Map<String, dynamic>) {
              doctor['image'] = fixImageUrl(doctor['image']?.toString() ?? '');
              doctor['specialty'] = getSpecialtyName(doctor);
            }
            return doctor;
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('GET DOCTORS ERROR: $e');
      return [];
    }
  }

  static Future<List<dynamic>> searchDoctors(String query) async {
    final doctors = await getDoctors();
    final search = query.toLowerCase();

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
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          data['image'] = fixImageUrl(data['image']?.toString() ?? '');
          data['specialty'] = getSpecialtyName(data);
        }

        return data;
      }

      return null;
    } catch (e) {
      print('GET DOCTOR BY ID ERROR: $e');
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
    final fixedImage = fixImageUrl(image);

    final response = await http
        .post(
      Uri.parse('$baseUrl/Doctors'),
      headers: headers,
      body: jsonEncode({
        "fullName": fullName.trim(),
        "specialtyId": specialtyId,
        "phoneNumber": phoneNumber.trim(),
        "email": email.trim(),
        "image": fixedImage,
      }),
    )
        .timeout(const Duration(seconds: 20));

    print('CREATE DOCTOR STATUS: ${response.statusCode}');
    print('CREATE DOCTOR BODY: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor: ${response.body}');
    }
  }

  static Future<void> updateDoctor({
    required int doctorId,
    required String fullName,
    required int specialtyId,
    required String phoneNumber,
    required String email,
    required String image,
  }) async {
    final fixedImage = fixImageUrl(image);

    final response = await http
        .put(
      Uri.parse('$baseUrl/Doctors/$doctorId'),
      headers: headers,
      body: jsonEncode({
        "doctorId": doctorId,
        "fullName": fullName.trim(),
        "specialtyId": specialtyId,
        "phoneNumber": phoneNumber.trim(),
        "email": email.trim(),
        "image": fixedImage,
      }),
    )
        .timeout(const Duration(seconds: 20));

    print('UPDATE DOCTOR STATUS: ${response.statusCode}');
    print('UPDATE DOCTOR BODY: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update doctor: ${response.body}');
    }
  }

  static Future<void> deleteDoctor(int doctorId) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/Doctors/$doctorId'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete doctor');
    }
  }

  static Future<void> bookAppointment({
    required int patientId,
    required int doctorId,
    required DateTime appointmentDate,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/Appointments'),
      headers: headers,
      body: jsonEncode({
        "patientId": patientId,
        "doctorId": doctorId,
        "appointmentDate": appointmentDate.toIso8601String(),
        "status": "Pending",
      }),
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to book appointment');
    }
  }

  static Future<List<dynamic>> getAllAppointments() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Appointments'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) return [];

        return data.map((appointment) {
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
      }

      return [];
    } catch (e) {
      print('GET ALL APPOINTMENTS ERROR: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getAppointments() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Appointments'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) return [];

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

        if (UserSession.userId == null) return appointments;

        return appointments.where((appointment) {
          return appointment['patientId']?.toString() ==
              UserSession.userId.toString() ||
              appointment['PatientId']?.toString() ==
                  UserSession.userId.toString();
        }).toList();
      }

      return [];
    } catch (e) {
      print('GET APPOINTMENTS ERROR: $e');
      return [];
    }
  }

  static Future<void> updateAppointmentStatus({
    required Map<String, dynamic> appointment,
    required String status,
  }) async {
    final appointmentId = appointment['appointmentId'];

    final response = await http
        .put(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: headers,
      body: jsonEncode({
        "appointmentId": appointment['appointmentId'],
        "patientId": appointment['patientId'],
        "doctorId": appointment['doctorId'],
        "appointmentDate": appointment['appointmentDate'],
        "status": status,
      }),
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update appointment status');
    }
  }

  static Future<int> getAppointmentCountByUser(int patientId) async {
    final appointments = await getAppointments();

    return appointments.where((appointment) {
      return appointment['patientId'].toString() == patientId.toString();
    }).length;
  }

  static Future<void> deleteAppointment(int appointmentId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: headers,
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete appointment');
    }
  }

  static Future<List<dynamic>> getMedicalRecords() async {
    final response = await http
        .get(Uri.parse('$baseUrl/MedicalRecords'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }

    return [];
  }

  static Future<List<dynamic>> getMedicalRecordsByUser(int patientId) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/MedicalRecords/patient/$patientId'),
      headers: headers,
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }

    return [];
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
      Uri.parse('$baseUrl/MedicalRecords'),
      headers: headers,
      body: jsonEncode({
        "patientId": patientId,
        "doctorId": doctorId,
        "title": title,
        "description": description,
        "recordDate": recordDate,
        "status": status,
        "fileUrl": fileUrl,
      }),
    )
        .timeout(const Duration(seconds: 20));

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

    final response = await request.send().timeout(const Duration(seconds: 30));

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
        .timeout(const Duration(seconds: 20));

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
    final response = await http
        .get(Uri.parse('$baseUrl/Appointments'), headers: headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data.length;
    }

    return 0;
  }

  static Future<List<dynamic>> getNotificationsByUser(int userId) async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/Notifications/user/$userId'),
      headers: headers,
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }

    return [];
  }

  static Future<void> deleteNotification(int notificationId) async {
    final response = await http
        .delete(
      Uri.parse('$baseUrl/Notifications/$notificationId'),
      headers: headers,
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }
  }
}
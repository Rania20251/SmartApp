import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'user_session.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://localhost:7065/api';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5117/api';
    }

    return 'https://localhost:7065/api';
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email.trim(),
          "password": password.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "fullName": fullName.trim(),
        "email": email.trim(),
        "password": password.trim(),
        "phoneNumber": "",
        "address": "",
        "gender": "",
        "dateOfBirth": "",
        "profileImage": "assets/images/profile.jpg",
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
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
    final response = await http.put(
      Uri.parse('$baseUrl/Users/$userId'),
      headers: {'Content-Type': 'application/json'},
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
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/Users'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load users');
  }

  static Future<void> deleteUser(int userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/Users/$userId'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }

  static Future<int> getUsersCount() async {
    final users = await getUsers();
    return users.length;
  }

  static Future<bool> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Users/change-password/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "oldPassword": oldPassword.trim(),
          "newPassword": newPassword.trim(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getDoctors() async {
    final response = await http.get(Uri.parse('$baseUrl/Doctors'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load doctors');
  }

  static Future<List<dynamic>> searchDoctors(String query) async {
    final doctors = await getDoctors();

    return doctors.where((doctor) {
      final name = doctor['fullName']?.toString().toLowerCase() ?? '';
      final specialty = doctor['specialty']?.toString().toLowerCase() ?? '';
      final search = query.toLowerCase();

      return name.contains(search) || specialty.contains(search);
    }).toList();
  }

  static Future<dynamic> getDoctorById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/Doctors/$id'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load doctor');
  }

  static Future<void> createDoctor({
    required String fullName,
    required String specialty,
    required String phoneNumber,
    required String email,
    required String image,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Doctors'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "fullName": fullName.trim(),
        "specialty": specialty.trim(),
        "phoneNumber": phoneNumber.trim(),
        "email": email.trim(),
        "image": image.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create doctor');
    }
  }

  static Future<void> updateDoctor({
    required int doctorId,
    required String fullName,
    required String specialty,
    required String phoneNumber,
    required String email,
    required String image,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Doctors/$doctorId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "doctorId": doctorId,
        "fullName": fullName.trim(),
        "specialty": specialty.trim(),
        "phoneNumber": phoneNumber.trim(),
        "email": email.trim(),
        "image": image.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update doctor');
    }
  }

  static Future<void> deleteDoctor(int doctorId) async {
    final response = await http.delete(Uri.parse('$baseUrl/Doctors/$doctorId'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete doctor');
    }
  }

  static Future<void> bookAppointment({
    required int patientId,
    required int doctorId,
    required DateTime appointmentDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Appointments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "patientId": patientId,
        "doctorId": doctorId,
        "appointmentDate": appointmentDate.toIso8601String(),
        "status": "Pending",
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to book appointment');
    }
  }

  static Future<List<dynamic>> getAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/Appointments'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is! List) return [];

      if (UserSession.userId == null) {
        return data;
      }

      return data.where((appointment) {
        return appointment['patientId']?.toString() ==
            UserSession.userId.toString();
      }).toList();
    }

    throw Exception('Failed to load appointments');
  }

  static Future<void> updateAppointmentStatus({
    required Map<String, dynamic> appointment,
    required String status,
  }) async {
    final appointmentId = appointment['appointmentId'];

    final response = await http.put(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "appointmentId": appointment['appointmentId'],
        "patientId": appointment['patientId'],
        "doctorId": appointment['doctorId'],
        "appointmentDate": appointment['appointmentDate'],
        "status": status,
      }),
    );

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
    final response = await http.delete(
      Uri.parse('$baseUrl/Appointments/$appointmentId'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete appointment');
    }
  }

  static Future<List<dynamic>> getMedicalRecords() async {
    final response = await http.get(Uri.parse('$baseUrl/MedicalRecords'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load medical records');
  }

  static Future<List<dynamic>> getMedicalRecordsByUser(int patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MedicalRecords/patient/$patientId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load user medical records');
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
    final response = await http.post(
      Uri.parse('$baseUrl/MedicalRecords'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "patientId": patientId,
        "doctorId": doctorId,
        "title": title,
        "description": description,
        "recordDate": recordDate,
        "status": status,
        "fileUrl": fileUrl,
      }),
    );

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

    request.fields['PatientId'] = patientId.toString();
    request.fields['DoctorId'] = doctorId.toString();
    request.fields['Title'] = title.trim();
    request.fields['Description'] = description.trim();
    request.fields['Status'] = status.trim();

    request.files.add(
      await http.MultipartFile.fromPath(
        'File',
        filePath,
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload medical record file');
    }
  }

  static Future<void> deleteMedicalRecord(int recordId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/MedicalRecords/$recordId'),
    );

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
    final response = await http.get(Uri.parse('$baseUrl/Appointments'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data.length;
    }

    return 0;
  }

  static Future<List<dynamic>> getNotificationsByUser(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Notifications/user/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load notifications');
  }

  static Future<void> deleteNotification(int notificationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Notifications/$notificationId'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }
  }
}
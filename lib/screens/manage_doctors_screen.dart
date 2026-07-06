import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import 'add_doctor_screen.dart';
import 'edit_doctor_screen.dart';

class ManageDoctorsScreen extends StatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  State<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends State<ManageDoctorsScreen> {
  late Future<List<dynamic>> doctorsFuture;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  void loadDoctors() {
    doctorsFuture = ApiService.getDoctors();
  }

  void refreshDoctors() {
    setState(() {
      loadDoctors();
    });
  }

  int getDoctorSpecialtyId(dynamic doctor) {
    final directId = int.tryParse(doctor['specialtyId']?.toString() ?? '');
    if (directId != null && directId > 0) return directId;

    final specialtyNavigation = doctor['specialtyNavigation'];
    if (specialtyNavigation is Map<String, dynamic>) {
      final navId = int.tryParse(
        specialtyNavigation['specialtyId']?.toString() ?? '',
      );
      if (navId != null && navId > 0) return navId;
    }

    return 1;
  }

  String getDoctorSpecialtyName(dynamic doctor) {
    final specialtyNavigation = doctor['specialtyNavigation'];

    if (specialtyNavigation is Map<String, dynamic>) {
      final name = specialtyNavigation['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    }

    final specialty = doctor['specialty']?.toString() ?? '';
    if (specialty.isNotEmpty) return specialty;

    return AppStrings.specialist;
  }

  String getDoctorImagePath(dynamic doctor) {
    final image = doctor['image']?.toString().trim() ?? '';

    if (image.isNotEmpty && image != 'string') {
      return ApiService.fixImageUrl(image);
    }

    return 'assets/images/profile.jpg';
  }

  Widget doctorImage(String imagePath) {
    final image = imagePath.trim();

    if (image.startsWith('data:image')) {
      try {
        final base64Part = image.split(',').last;
        return ClipOval(
          child: Image.memory(
            base64Decode(base64Part),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return defaultDoctorImage();
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          image,
          key: ValueKey(image),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    return defaultDoctorImage();
  }

  Widget defaultDoctorImage() {
    return ClipOval(
      child: Image.asset(
        'assets/images/profile.jpg',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> changeDoctorImage(Map<String, dynamic> doctor) async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final doctorId =
        int.tryParse(doctor['doctorId']?.toString() ?? '0') ?? 0;

    if (doctorId == 0) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating image...')),
      );

      final bytes = await picked.readAsBytes();
      final fileName = picked.name.isNotEmpty ? picked.name : 'doctor.jpg';

      final uploadedImageUrl = await ApiService.uploadDoctorImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      await ApiService.updateDoctor(
        doctorId: doctorId,
        fullName: doctor['fullName']?.toString() ?? '',
        specialtyId: getDoctorSpecialtyId(doctor),
        phoneNumber: doctor['phoneNumber']?.toString() ?? '',
        email: doctor['email']?.toString() ?? '',
        image: uploadedImageUrl,
      );

      refreshDoctors();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.doctorImageUpdated)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.doctorImageUpdateFailed}: $e')),
      );
    }
  }

  Future<void> openAddDoctor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
    );

    if (result == true) {
      refreshDoctors();
    }
  }

  Future<void> openEditDoctor(Map<String, dynamic> doctor) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditDoctorScreen(doctor: doctor),
      ),
    );

    if (result == true) {
      refreshDoctors();
    }
  }

  Future<void> deleteDoctor(int doctorId) async {
    await ApiService.deleteDoctor(doctorId);
    refreshDoctors();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.doctorDeleted)),
    );
  }

  Future<void> confirmDelete(int doctorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.deleteDoctor),
          content: Text(AppStrings.deleteDoctorConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppStrings.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await deleteDoctor(doctorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.manageDoctors),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshDoctors,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: openAddDoctor,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppStrings.failedLoadDoctors,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final doctors = snapshot.data ?? [];

          if (doctors.isEmpty) {
            return Center(child: Text(AppStrings.noDoctorsFound));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];

              final doctorId =
                  int.tryParse(doctor['doctorId']?.toString() ?? '0') ?? 0;

              final imagePath = getDoctorImagePath(doctor);
              final specialtyName = getDoctorSpecialtyName(doctor);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: doctorImage(imagePath),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor['fullName']?.toString() ?? AppStrings.doctor,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialtyName,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            doctor['email']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: AppStrings.changeImage,
                          icon: const Icon(Icons.image, color: Colors.purple),
                          onPressed: () => changeDoctorImage(doctor),
                        ),
                        IconButton(
                          tooltip: AppStrings.edit,
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => openEditDoctor(doctor),
                        ),
                        IconButton(
                          tooltip: AppStrings.delete,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDelete(doctorId),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

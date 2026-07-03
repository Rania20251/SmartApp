import 'package:flutter/material.dart';

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

  final List<String> doctorImages = const [
    'assets/images/doctor1.jpg',
    'assets/images/doctor2.jpg',
    'assets/images/doctor3.jpg',
    'assets/images/doctor4.jpg',
  ];

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

  ImageProvider getDoctorImage(dynamic doctor) {
    final image = doctor['image']?.toString() ?? '';

    if (image.isNotEmpty && image.startsWith('assets/')) {
      return AssetImage(image);
    }

    return const AssetImage('assets/images/profile.jpg');
  }

  Future<void> changeDoctorImage(Map<String, dynamic> doctor) async {
    final selectedImage = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.changeImage),
          content: SizedBox(
            width: double.maxFinite,
            height: 260,
            child: GridView.builder(
              itemCount: doctorImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final imagePath = doctorImages[index];

                return InkWell(
                  onTap: () {
                    Navigator.pop(context, imagePath);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedImage == null) return;

    final doctorId = int.tryParse(
      doctor['doctorId']?.toString() ?? '0',
    ) ??
        0;

    try {
      await ApiService.updateDoctor(
        doctorId: doctorId,
        fullName: doctor['fullName']?.toString() ?? '',
        specialty: doctor['specialty']?.toString() ?? '',
        phoneNumber: doctor['phoneNumber']?.toString() ?? '',
        email: doctor['email']?.toString() ?? '',
        image: selectedImage,
      );

      refreshDoctors();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.doctorImageUpdated)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.doctorImageUpdateFailed)),
      );
    }
  }

  Future<void> openAddDoctor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddDoctorScreen(),
      ),
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
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
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
    const primary = Color(0xff5B2EFF);

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

              final doctorId = int.tryParse(
                doctor['doctorId']?.toString() ?? '0',
              ) ??
                  0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xffEDE7FF),
                      backgroundImage: getDoctorImage(doctor),
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
                            doctor['specialty']?.toString() ??
                                AppStrings.specialist,
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
                          onPressed: () {
                            changeDoctorImage(doctor);
                          },
                        ),
                        IconButton(
                          tooltip: AppStrings.edit,
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            openEditDoctor(doctor);
                          },
                        ),
                        IconButton(
                          tooltip: AppStrings.delete,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            confirmDelete(doctorId);
                          },
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
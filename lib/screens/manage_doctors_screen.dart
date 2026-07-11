// Reviewed for optimization. Structure preserved.
// For deeper optimization, refactor to cache futures and const widgets.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  // الاحتفاظ بآخر قائمة ظاهرة حتى لا تختفي أثناء أي تحديث.
  List<dynamic> cachedDoctors = [];

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  void loadDoctors({bool forceRefresh = false}) {
    doctorsFuture = ApiService.getDoctors(
      forceRefresh: forceRefresh,
    ).then((data) {
      cachedDoctors = List<dynamic>.from(data);
      return cachedDoctors;
    });
  }

  void refreshDoctors() {
    ApiService.clearDoctorsCache();

    setState(() {
      loadDoctors(forceRefresh: true);
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
    if (doctor is! Map) {
      return 'assets/images/profile.jpg';
    }

    final image = (
        doctor['image'] ??
            doctor['Image'] ??
            doctor['doctorImage'] ??
            doctor['DoctorImage'] ??
            ''
    ).toString().trim();

    if (image.isEmpty || image.toLowerCase() == 'string') {
      return 'assets/images/profile.jpg';
    }

    return ApiService.fixImageUrl(image);
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
        child: CachedNetworkImage(
          imageUrl: image,
          key: ValueKey(image),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => defaultDoctorImage(),
          errorWidget: (_, __, ___) => defaultDoctorImage(),
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


  String translateDoctorName(String name) {
    var value = name.trim();

    if (value.isEmpty) {
      return AppStrings.doctor;
    }

    if (AppStrings.isArabic) {
      value = value
          .replaceAll(RegExp(r'\bDr\.?\s*', caseSensitive: false), '')
          .replaceAll('دكتور', '')
          .replaceAll('الدكتور', '')
          .replaceAll('Ahmad', 'أحمد')
          .replaceAll('Ahmed', 'أحمد')
          .replaceAll('Ali', 'علي')
          .replaceAll('Sara', 'سارة')
          .replaceAll('Sarah', 'سارة')
          .replaceAll('Sali', 'سالي')
          .replaceAll('Sally', 'سالي')
          .replaceAll('Mohammad', 'محمد')
          .replaceAll('Mohammed', 'محمد')
          .replaceAll('Muhammad', 'محمد')
          .replaceAll('Omar', 'عمر')
          .replaceAll('Nour', 'نور')
          .replaceAll('Noor', 'نور')
          .replaceAll('Adnan', 'عدنان')
          .replaceAll('Rania', 'رانيا')
          .replaceAll('Ramia', 'راميا')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (!value.startsWith('د.')) {
        value = 'د. $value';
      }

      return value;
    }

    value = value
        .replaceAll('الدكتور', '')
        .replaceAll('دكتور', '')
        .replaceAll('د.', '')
        .replaceAll('أحمد', 'Ahmad')
        .replaceAll('احمد', 'Ahmad')
        .replaceAll('علي', 'Ali')
        .replaceAll('سارة', 'Sara')
        .replaceAll('سالي', 'Sali')
        .replaceAll('محمد', 'Mohammad')
        .replaceAll('عمر', 'Omar')
        .replaceAll('نور', 'Nour')
        .replaceAll('عدنان', 'Adnan')
        .replaceAll('رانيا', 'Rania')
        .replaceAll('راميا', 'Ramia')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    value = value.replaceFirst(
      RegExp(r'^Dr\.?\s*', caseSensitive: false),
      '',
    );

    return 'Dr. $value';
  }

  String translateSpecialtyName(String name) {
    final translated = AppStrings.specialtyByLanguage(name).trim();

    if (AppStrings.isArabic) {
      return translated
          .replaceAll('Cardiology', 'أمراض القلب')
          .replaceAll('Dentistry', 'طب الأسنان')
          .replaceAll('Pediatrics', 'طب الأطفال')
          .replaceAll('Neurology', 'طب الأعصاب')
          .replaceAll('Emergency', 'الطوارئ')
          .replaceAll('Dermatology', 'الأمراض الجلدية')
          .replaceAll('Ophthalmology', 'طب العيون')
          .replaceAll('Orthopedics', 'طب العظام')
          .replaceAll('General Medicine', 'الطب العام')
          .replaceAll('Internal Medicine', 'الطب الباطني');
    }

    return translated
        .replaceAll('أمراض القلب', 'Cardiology')
        .replaceAll('طب القلب', 'Cardiology')
        .replaceAll('طب الأسنان', 'Dentistry')
        .replaceAll('طب الاسنان', 'Dentistry')
        .replaceAll('طب الأطفال', 'Pediatrics')
        .replaceAll('طب الاطفال', 'Pediatrics')
        .replaceAll('طب الأعصاب', 'Neurology')
        .replaceAll('طب الاعصاب', 'Neurology')
        .replaceAll('الطوارئ', 'Emergency')
        .replaceAll('الأمراض الجلدية', 'Dermatology')
        .replaceAll('الامراض الجلدية', 'Dermatology')
        .replaceAll('طب العيون', 'Ophthalmology')
        .replaceAll('طب العظام', 'Orthopedics')
        .replaceAll('الطب العام', 'General Medicine')
        .replaceAll('الطب الباطني', 'Internal Medicine');
  }

  Future<void> changeDoctorImage(
      Map<String, dynamic> doctor,
      ) async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final doctorId = int.tryParse(
      (
          doctor['doctorId'] ??
              doctor['DoctorId'] ??
              doctor['id'] ??
              doctor['Id'] ??
              '0'
      ).toString(),
    ) ??
        0;

    if (doctorId <= 0) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isArabic
                  ? 'جاري تحديث الصورة...'
                  : 'Updating image...',
            ),
          ),
        );
      }

      final bytes = await picked.readAsBytes();
      final fileName = picked.name.isNotEmpty
          ? picked.name
          : 'doctor.jpg';

      // 1) رفع الصورة وأخذ الرابط.
      final uploadedImageUrl =
      await ApiService.uploadDoctorImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      // 2) حفظ الرابط مع بيانات الطبيب.
      await ApiService.updateDoctor(
        doctorId: doctorId,
        fullName: (
            doctor['fullName'] ??
                doctor['FullName'] ??
                ''
        ).toString(),
        specialtyId: getDoctorSpecialtyId(doctor),
        phoneNumber: (
            doctor['phoneNumber'] ??
                doctor['PhoneNumber'] ??
                ''
        ).toString(),
        email: (
            doctor['email'] ??
                doctor['Email'] ??
                ''
        ).toString(),
        image: uploadedImageUrl.trim(),
      );

      // تحديث العنصر الحالي مباشرة قبل إعادة التحميل.
      doctor['image'] = uploadedImageUrl.trim();
      doctor['Image'] = uploadedImageUrl.trim();

      ApiService.clearDoctorsCache();

      if (!mounted) return;

      // الصورة تتحدث مباشرة من نفس العنصر بدون إعادة تحميل القائمة كاملة.
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.doctorImageUpdated),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.doctorImageUpdateFailed}: $e',
          ),
        ),
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
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
          initialData: cachedDoctors.isEmpty ? null : cachedDoctors,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                cachedDoctors.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && cachedDoctors.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.failedLoadDoctors,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final doctors = snapshot.data ?? cachedDoctors;

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

                return RepaintBoundary(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 62,
                          height: 62,
                          child: doctorImage(imagePath),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: AppStrings.isArabic
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                translateDoctorName(doctor['fullName']?.toString() ?? AppStrings.doctor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                translateSpecialtyName(specialtyName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doctor['email']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 116,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: AppStrings.changeImage,
                                  icon: const Icon(
                                    Icons.image,
                                    color: Colors.purple,
                                    size: 24,
                                  ),
                                  onPressed: () => changeDoctorImage(doctor),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: AppStrings.edit,
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  onPressed: () => openEditDoctor(doctor),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: AppStrings.delete,
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  onPressed: () => confirmDelete(doctorId),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
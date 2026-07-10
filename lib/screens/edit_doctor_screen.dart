import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';

class EditDoctorScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const EditDoctorScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  List<dynamic> specialties = [];
  int? selectedSpecialtyId;

  bool isLoading = false;
  bool isLoadingSpecialties = true;

  String imageUrl = '';
  Uint8List? selectedImageBytes;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.doctor['fullName']?.toString() ?? '';
    phoneController.text = widget.doctor['phoneNumber']?.toString() ?? '';
    emailController.text = widget.doctor['email']?.toString() ?? '';
    imageUrl = ApiService.fixImageUrl(
      (
          widget.doctor['image'] ??
              widget.doctor['Image'] ??
              widget.doctor['doctorImage'] ??
              widget.doctor['DoctorImage'] ??
              ''
      ).toString(),
    );

    selectedSpecialtyId = int.tryParse(
      widget.doctor['specialtyId']?.toString() ?? '',
    );

    loadSpecialties();
  }

  Future<void> loadSpecialties() async {
    try {
      final data = await ApiService.getSpecialties();

      if (!mounted) return;

      if (selectedSpecialtyId == null) {
        final specialtyNavigation = widget.doctor['specialtyNavigation'];

        if (specialtyNavigation is Map<String, dynamic>) {
          selectedSpecialtyId = int.tryParse(
            specialtyNavigation['specialtyId']?.toString() ?? '',
          );
        }
      }

      setState(() {
        specialties = data;
        isLoadingSpecialties = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingSpecialties = false);
      showMessage(AppStrings.enterSpecialty);
    }
  }

  bool get hasNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  ImageProvider? get previewImage {
    if (selectedImageBytes != null) {
      return MemoryImage(selectedImageBytes!);
    }

    if (hasNetworkImage) {
      return NetworkImage(imageUrl);
    }

    if (imageUrl.isNotEmpty) {
      return AssetImage(imageUrl);
    }

    return null;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> pickAndUploadImage() async {
    if (isLoading) return;

    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedImageBytes = bytes;
      isLoading = true;
    });

    try {
      final uploadedUrl =
      await ApiService.uploadDoctorImageBytes(
        bytes: bytes,
        fileName: picked.name.isNotEmpty
            ? picked.name
            : 'doctor.jpg',
      );

      if (!mounted) return;

      setState(() {
        // هذا الرابط نفسه سيُرسل إلى updateDoctor عند الضغط على حفظ.
        imageUrl = uploadedUrl.trim();
      });

      showMessage(
        AppStrings.isArabic
            ? 'تم رفع الصورة، اضغطي تحديث الطبيب لحفظها'
            : 'Image uploaded. Press Update Doctor to save it.',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        AppStrings.isArabic
            ? 'فشل رفع الصورة: $e'
            : 'Failed to upload image: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateDoctor() async {
    final doctorId =
        int.tryParse(widget.doctor['doctorId']?.toString() ?? '0') ?? 0;

    if (doctorId == 0) {
      showMessage(AppStrings.invalidDoctorId);
      return;
    }

    if (nameController.text.trim().isEmpty) {
      showMessage(AppStrings.enterDoctorName);
      return;
    }

    if (selectedSpecialtyId == null) {
      showMessage(AppStrings.enterSpecialty);
      return;
    }

    setState(() => isLoading = true);

    try {
      final cleanImageUrl = imageUrl.trim();

      await ApiService.updateDoctor(
        doctorId: doctorId,
        fullName: nameController.text.trim(),
        specialtyId: selectedSpecialtyId!,
        phoneNumber: phoneController.text.trim(),
        email: emailController.text.trim(),
        image: cleanImageUrl,
      );

      ApiService.clearDoctorsCache();

      if (!mounted) return;

      showMessage(AppStrings.doctorUpdated);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showMessage(AppStrings.updateDoctorFailed);
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'medical_services':
        return Icons.medical_services;
      case 'psychology':
        return Icons.psychology;
      case 'child_care':
        return Icons.child_care;
      case 'face':
        return Icons.face;
      case 'healing':
        return Icons.healing;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'vaccines':
        return Icons.vaccines;
      case 'visibility':
        return Icons.visibility;
      case 'elderly':
        return Icons.elderly;
      default:
        return Icons.medical_services;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.editDoctor),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 390,
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 20),

              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xffEDE7FF),
                  backgroundImage: previewImage,
                  child: previewImage == null
                      ? const Icon(Icons.person, size: 55, color: primary)
                      : null,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: isLoading ? null : pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: const Text('Choose Image'),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: inputDecoration(
                  hint: AppStrings.doctorFullName,
                  icon: Icons.person,
                ),
              ),

              const SizedBox(height: 16),

              isLoadingSpecialties
                  ? Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(),
              )
                  : DropdownButtonFormField<int>(
                value: selectedSpecialtyId,
                decoration: inputDecoration(
                  hint: AppStrings.specialty,
                  icon: Icons.medical_services,
                ),
                items: specialties.map((specialty) {
                  final id = specialty['specialtyId'];
                  final name = specialty['name']?.toString() ?? '';
                  final icon = specialty['icon']?.toString() ?? '';

                  return DropdownMenuItem<int>(
                    value: id is int ? id : int.tryParse(id.toString()),
                    child: Row(
                      children: [
                        Icon(
                          getIconData(icon),
                          size: 20,
                          color: primary,
                        ),
                        const SizedBox(width: 10),
                        Text(name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSpecialtyId = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: inputDecoration(
                  hint: AppStrings.phoneNumber,
                  icon: Icons.phone,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration(
                  hint: AppStrings.email,
                  icon: Icons.email,
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : updateDoctor,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    AppStrings.updateDoctor,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
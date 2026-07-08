import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  static const Color primary = Color(0xff5B2EFF);
  static const Color background = Color(0xffF7F8FC);
  static const Color lightPurple = Color(0xffEDE7FF);

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  List<dynamic> specialties = [];
  int? selectedSpecialtyId;

  bool isLoading = false;
  bool isLoadingSpecialties = true;

  Uint8List? selectedImageBytes;
  String selectedImageName = '';
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    loadSpecialties();
  }

  Future<void> loadSpecialties() async {
    setState(() {
      isLoadingSpecialties = true;
    });

    try {
      final data = await ApiService.getSpecialties(forceRefresh: true);

      final validSpecialties = data.where((specialty) {
        final id = getSpecialtyId(specialty);
        final name = getSpecialtyName(specialty);
        return id != null && id > 0 && name.trim().isNotEmpty;
      }).toList();

      if (!mounted) return;

      setState(() {
        specialties = validSpecialties;
        isLoadingSpecialties = false;

        if (selectedSpecialtyId == null && specialties.isNotEmpty) {
          selectedSpecialtyId = getSpecialtyId(specialties.first);
        }

        if (selectedSpecialtyId != null) {
          final exists = specialties.any(
                (s) => getSpecialtyId(s) == selectedSpecialtyId,
          );

          if (!exists) {
            selectedSpecialtyId =
            specialties.isNotEmpty ? getSpecialtyId(specialties.first) : null;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingSpecialties = false;
      });

      showMessage(AppStrings.enterSpecialty);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> pickDoctorImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedImageBytes = bytes;
      selectedImageName = picked.name.isNotEmpty ? picked.name : 'doctor.jpg';
    });
  }

  Future<String> uploadSelectedImageIfNeeded() async {
    final bytes = selectedImageBytes;

    if (bytes == null) return '';

    return ApiService.uploadDoctorImageBytes(
      bytes: bytes,
      fileName: selectedImageName.isEmpty ? 'doctor.jpg' : selectedImageName,
    );
  }

  Future<void> addDoctor() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      showMessage(AppStrings.enterDoctorName);
      return;
    }

    if (selectedSpecialtyId == null || selectedSpecialtyId! <= 0) {
      showMessage(AppStrings.enterSpecialty);
      await loadSpecialties();
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final uploadedImageUrl = await uploadSelectedImageIfNeeded();

      await ApiService.createDoctor(
        fullName: name,
        specialtyId: selectedSpecialtyId!,
        phoneNumber: phone,
        email: email,
        image: uploadedImageUrl,
      );

      ApiService.clearDoctorsCache();

      if (!mounted) return;

      showMessage(AppStrings.doctorAdded);
      Navigator.pop(context, true);
    } catch (e) {
      showMessage('${AppStrings.addDoctorFailed}: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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

  int? getSpecialtyId(dynamic specialty) {
    if (specialty is! Map) return null;

    final id = specialty['specialtyId'] ??
        specialty['SpecialtyId'] ??
        specialty['id'] ??
        specialty['Id'];

    if (id is int) return id;

    return int.tryParse(id?.toString() ?? '');
  }

  String getSpecialtyName(dynamic specialty) {
    if (specialty is! Map) return '';

    return specialty['name']?.toString() ??
        specialty['Name']?.toString() ??
        specialty['specialtyName']?.toString() ??
        specialty['SpecialtyName']?.toString() ??
        '';
  }

  String getSpecialtyIcon(dynamic specialty) {
    if (specialty is! Map) return '';

    return specialty['icon']?.toString() ??
        specialty['Icon']?.toString() ??
        '';
  }

  ImageProvider? get previewImage {
    final bytes = selectedImageBytes;

    if (bytes != null) return MemoryImage(bytes);

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }

    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }

    return null;
  }

  List<DropdownMenuItem<int>> specialtyItems() {
    final items = <DropdownMenuItem<int>>[];

    for (final specialty in specialties) {
      final value = getSpecialtyId(specialty);

      if (value == null || value <= 0) continue;

      final name = getSpecialtyName(specialty);
      final icon = getSpecialtyIcon(specialty);

      if (name.trim().isEmpty) continue;

      items.add(
        DropdownMenuItem<int>(
          value: value,
          child: Row(
            children: [
              Icon(
                getIconData(icon),
                size: 20,
                color: primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
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
    final image = previewImage;
    final items = specialtyItems();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(AppStrings.addDoctor),
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
                  backgroundColor: lightPurple,
                  backgroundImage: image,
                  child: image == null
                      ? const Icon(
                    Icons.local_hospital,
                    size: 55,
                    color: primary,
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isLoading ? null : pickDoctorImage,
                icon: const Icon(Icons.image),
                label: Text(AppStrings.changeImage),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
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
                isExpanded: true,
                decoration: inputDecoration(
                  hint: AppStrings.specialty.isNotEmpty
                      ? AppStrings.specialty
                      : 'Select Specialty',
                  icon: Icons.medical_services,
                ),
                items: items,
                onChanged: isLoading || items.isEmpty
                    ? null
                    : (value) {
                  if (selectedSpecialtyId == value) return;

                  setState(() {
                    selectedSpecialtyId = value;
                  });
                },
              ),
              if (!isLoadingSpecialties && items.isEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.enterSpecialty,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: loadSpecialties,
                      child: Text(AppStrings.isArabic ? 'إعادة تحميل' : 'Reload'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: inputDecoration(
                  hint: AppStrings.phoneNumber,
                  icon: Icons.phone,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
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
                    disabledBackgroundColor: primary.withOpacity(.65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : addDoctor,
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : Text(
                    AppStrings.addDoctor,
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

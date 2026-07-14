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

  String canonicalDoctorNameForStorage(String value) {
    var clean = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    clean = clean
        .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^Doctor\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^د\.?\s*'), '')
        .replaceFirst(RegExp(r'^دكتور\s+'), '')
        .replaceFirst(RegExp(r'^الدكتور\s+'), '')
        .trim();

    if (clean.isEmpty) return '';

    const arabicToEnglish = <String, String>{
      'أحمد': 'Ahmad',
      'احمد': 'Ahmad',
      'علي': 'Ali',
      'سارة': 'Sara',
      'ساره': 'Sara',
      'محمد': 'Mohammad',
      'محمود': 'Mahmoud',
      'عمر': 'Omar',
      'نور': 'Nour',
      'عدنان': 'Adnan',
      'هبة': 'Hiba',
      'هبه': 'Hiba',
      'رنا': 'Rana',
      'رانيا': 'Rania',
      'صلاح': 'Salah',
      'سالي': 'Sali',
      'خالد': 'Khaled',
      'يوسف': 'Yousef',
      'مريم': 'Mariam',
      'هناء': 'Hana',
      'هالة': 'Hala',
      'هاله': 'Hala',
      'لينا': 'Lina',
      'يارا': 'Yara',
      'آية': 'Aya',
      'ايه': 'Aya',
      'منى': 'Mona',
      'هدى': 'Huda',
      'مراد': 'Murad',
      'أسامة': 'Osama',
      'اسامة': 'Osama',
      'رامي': 'Rami',
      'فادي': 'Fadi',
      'زياد': 'Ziad',
      'طارق': 'Tariq',
      'إبراهيم': 'Ibrahim',
      'ابراهيم': 'Ibrahim',
      'مصطفى': 'Mustafa',
      'معاذ': 'Moath',
    };

    final words = clean
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
      final plain = word
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim();

      final known = arabicToEnglish[plain];
      if (known != null) return known;

      if (RegExp(r'[\u0600-\u06FF]').hasMatch(plain)) {
        return transliterateArabicWord(plain);
      }

      if (plain.isEmpty) return '';

      return plain.length == 1
          ? plain.toUpperCase()
          : '${plain[0].toUpperCase()}${plain.substring(1).toLowerCase()}';
    })
        .where((word) => word.isNotEmpty)
        .toList();

    return words.join(' ').trim();
  }

  String transliterateArabicWord(String word) {
    const letters = <String, String>{
      'ا': 'a',
      'أ': 'a',
      'إ': 'i',
      'آ': 'aa',
      'ء': '',
      'ؤ': 'o',
      'ئ': 'e',
      'ب': 'b',
      'ت': 't',
      'ث': 'th',
      'ج': 'j',
      'ح': 'h',
      'خ': 'kh',
      'د': 'd',
      'ذ': 'th',
      'ر': 'r',
      'ز': 'z',
      'س': 's',
      'ش': 'sh',
      'ص': 's',
      'ض': 'd',
      'ط': 't',
      'ظ': 'z',
      'ع': 'a',
      'غ': 'gh',
      'ف': 'f',
      'ق': 'q',
      'ك': 'k',
      'ل': 'l',
      'م': 'm',
      'ن': 'n',
      'ه': 'h',
      'ة': 'a',
      'و': 'w',
      'ى': 'a',
      'ي': 'y',
      'َ': 'a',
      'ُ': 'u',
      'ِ': 'i',
      'ْ': '',
      'ّ': '',
      'ـ': '',
    };

    final buffer = StringBuffer();

    for (final rune in word.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(letters[char] ?? char);
    }

    final result = buffer
        .toString()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .trim();

    if (result.isEmpty) return word;

    return result.length == 1
        ? result.toUpperCase()
        : '${result[0].toUpperCase()}${result.substring(1).toLowerCase()}';
  }

  @override
  void initState() {
    super.initState();
    loadSpecialties();
  }

  Future<void> loadSpecialties() async {
    if (!mounted) return;

    setState(() {
      isLoadingSpecialties = true;
    });

    try {
      final data = await ApiService.getSpecialties();

      final validSpecialties = data.where((specialty) {
        final id = getSpecialtyId(specialty);
        final name = getSpecialtyName(specialty);

        return id != null &&
            id > 0 &&
            name.trim().isNotEmpty;
      }).toList();

      if (!mounted) return;

      int? resolvedSpecialtyId = selectedSpecialtyId;

      final exists = resolvedSpecialtyId != null &&
          validSpecialties.any(
                (item) => getSpecialtyId(item) == resolvedSpecialtyId,
          );

      if (!exists && validSpecialties.isNotEmpty) {
        resolvedSpecialtyId =
            getSpecialtyId(validSpecialties.first);
      }

      setState(() {
        specialties = validSpecialties;
        selectedSpecialtyId = resolvedSpecialtyId;
        isLoadingSpecialties = false;
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
    if (isLoading) return;

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
      selectedImageName =
      picked.name.isNotEmpty ? picked.name : 'doctor.jpg';
    });
  }

  Future<String> uploadSelectedImageIfNeeded() async {
    final bytes = selectedImageBytes;

    if (bytes == null) return '';

    final uploadedUrl = await ApiService.uploadDoctorImageBytes(
      bytes: bytes,
      fileName: selectedImageName.isEmpty
          ? 'doctor.jpg'
          : selectedImageName,
    );

    final fixedUrl = ApiService.fixImageUrl(uploadedUrl).trim();

    if (fixedUrl.isEmpty || fixedUrl == 'string') {
      throw Exception('Doctor image URL was not returned by the server');
    }

    return fixedUrl;
  }

  Future<void> addDoctor() async {
    if (isLoading) return;

    final enteredName = nameController.text.trim();
    final name = canonicalDoctorNameForStorage(enteredName);
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (enteredName.isEmpty || name.isEmpty) {
      showMessage(AppStrings.enterDoctorName);
      return;
    }

    if (selectedSpecialtyId == null ||
        selectedSpecialtyId! <= 0) {
      showMessage(AppStrings.enterSpecialty);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final uploadedImageUrl =
      await uploadSelectedImageIfNeeded();

      if (mounted) {
        setState(() {
          imageUrl = uploadedImageUrl;
        });
      }

      await ApiService.createDoctor(
        fullName: name,
        specialtyId: selectedSpecialtyId!,
        phoneNumber: phone,
        email: email,
        image: uploadedImageUrl,
      );

      // حتى تظهر صورة الطبيب الجديدة عند الرجوع مباشرة.
      ApiService.clearDoctorsCache();

      if (!mounted) return;

      showMessage(AppStrings.doctorAdded);
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(
        '${AppStrings.addDoctorFailed}: $e',
      );
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

    if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
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
      final id = getSpecialtyId(specialty);
      final originalName = getSpecialtyName(specialty);
      final icon = getSpecialtyIcon(specialty);

      if (id == null ||
          id <= 0 ||
          originalName.trim().isEmpty) {
        continue;
      }

      final shownName = AppStrings.specialtyByLanguage(
        originalName,
      );

      items.add(
        DropdownMenuItem<int>(
          value: id,
          child: Row(
            textDirection: AppStrings.isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            children: [
              Icon(
                getIconData(icon),
                size: 20,
                color: primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  shownName,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
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

    final validSelectedValue = items.any(
          (item) => item.value == selectedSpecialtyId,
    )
        ? selectedSpecialtyId
        : null;

    return Directionality(
      textDirection:
      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                  onPressed:
                  isLoading ? null : pickDoctorImage,
                  icon: const Icon(Icons.image),
                  label: Text(AppStrings.changeImage),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  textDirection: AppStrings.isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  decoration: inputDecoration(
                    hint: AppStrings.doctorFullName,
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.isArabic
                      ? 'يمكن كتابة الاسم بالعربي أو الإنجليزي، وسيظهر حسب لغة التطبيق.'
                      : 'You can enter the name in Arabic or English; it will display in the app language.',
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoadingSpecialties)
                  Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: validSelectedValue,
                    isExpanded: true,
                    decoration: inputDecoration(
                      hint: AppStrings.specialty,
                      icon: Icons.medical_services,
                    ),
                    items: items,
                    onChanged:
                    isLoading || items.isEmpty
                        ? null
                        : (value) {
                      setState(() {
                        selectedSpecialtyId = value;
                      });
                    },
                  ),
                if (!isLoadingSpecialties && items.isEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.enterSpecialty,
                          textAlign: AppStrings.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: loadSpecialties,
                        child: Text(
                          AppStrings.isArabic
                              ? 'إعادة تحميل'
                              : 'Reload',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  textDirection: AppStrings.isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
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
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
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
                      disabledBackgroundColor:
                      primary.withOpacity(.65),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

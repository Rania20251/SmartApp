import 'dart:convert';

import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import 'doctor_details_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final searchController = TextEditingController();
  String searchText = '';

  late Future<List<dynamic>> doctorsFuture;
  late Future<List<dynamic>> specialtiesFuture;
  late Future<List<List<dynamic>>> doctorsDataFuture;

  @override
  void initState() {
    super.initState();
    doctorsFuture = ApiService.getDoctors();
    specialtiesFuture = ApiService.getSpecialties();
    doctorsDataFuture = Future.wait([doctorsFuture, specialtiesFuture]);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String getDoctorImage(dynamic doctor) {
    final image = doctor['image']?.toString().trim() ?? '';

    if (image.isNotEmpty && image != 'string') {
      return image;
    }

    return 'assets/images/profile.jpg';
  }

  int getDoctorSpecialtyId(dynamic doctor) {
    final directId = int.tryParse(doctor['specialtyId']?.toString() ?? '');
    if (directId != null) return directId;

    final nav = doctor['specialtyNavigation'];
    if (nav is Map<String, dynamic>) {
      return int.tryParse(nav['specialtyId']?.toString() ?? '') ?? 0;
    }

    return 0;
  }

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ـ', '')
        .replaceAll('َ', '')
        .replaceAll('ً', '')
        .replaceAll('ُ', '')
        .replaceAll('ٌ', '')
        .replaceAll('ِ', '')
        .replaceAll('ٍ', '')
        .replaceAll('ْ', '')
        .replaceAll('ّ', '')
        .replaceAll('.', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
  }

  String translateSpecialty(String name) {
    final value = name.toLowerCase().trim();

    if (!AppStrings.isArabic) return name;

    if (value.contains('cardiology') || value.contains('heart') || value.contains('قلب')) return 'القلب';
    if (value.contains('dentistry') || value.contains('dental') || value.contains('dentist') || value.contains('أسنان') || value.contains('اسنان')) return 'الأسنان';
    if (value.contains('neurology') || value.contains('neuro') || value.contains('أعصاب') || value.contains('اعصاب')) return 'الأعصاب';
    if (value.contains('pediatrics') || value.contains('pedia') || value.contains('child') || value.contains('أطفال') || value.contains('اطفال')) return 'الأطفال';
    if (value.contains('dermatology') || value.contains('derma') || value.contains('skin') || value.contains('جلدية')) return 'الجلدية';
    if (value.contains('ophthalmology') || value.contains('eye') || value.contains('eyes') || value.contains('عيون')) return 'العيون';
    if (value.contains('surgery') || value.contains('surgeon') || value.contains('جراحة')) return 'الجراحة';

    return name;
  }

  String translateDoctorName(String name) {
    if (!AppStrings.isArabic) return name;

    final value = name.toLowerCase().trim();

    if (value.contains('ahmad ali') || value.contains('ahmed ali')) {
      return 'د. أحمد علي';
    }

    if (value.contains('sarah ahmad') || value.contains('sara ahmad')) {
      return 'د. سارة أحمد';
    }

    return name
        .replaceAll('Dr.', 'د.')
        .replaceAll('dr.', 'د.')
        .replaceAll('Ahmad', 'أحمد')
        .replaceAll('Ahmed', 'أحمد')
        .replaceAll('Ali', 'علي')
        .replaceAll('Sara', 'سارة')
        .replaceAll('Sarah', 'سارة')
        .replaceAll('Mohammad', 'محمد')
        .replaceAll('Mohammed', 'محمد')
        .replaceAll('Omar', 'عمر')
        .replaceAll('Nour', 'نور');
  }

  String englishDoctorName(String name) {
    return name
        .replaceAll('د.', 'Dr.')
        .replaceAll('د ', 'Dr. ')
        .replaceAll('أحمد', 'Ahmad')
        .replaceAll('احمد', 'Ahmad')
        .replaceAll('علي', 'Ali')
        .replaceAll('سارة', 'Sarah')
        .replaceAll('ساره', 'Sarah')
        .replaceAll('محمد', 'Mohammad')
        .replaceAll('عمر', 'Omar')
        .replaceAll('نور', 'Nour');
  }

  String arabicDoctorName(String name) {
    return name
        .replaceAll('Dr.', 'د.')
        .replaceAll('dr.', 'د.')
        .replaceAll('Dr', 'د.')
        .replaceAll('dr', 'د.')
        .replaceAll('Ahmad', 'أحمد')
        .replaceAll('Ahmed', 'أحمد')
        .replaceAll('Ali', 'علي')
        .replaceAll('Sarah', 'سارة')
        .replaceAll('Sara', 'سارة')
        .replaceAll('Mohammad', 'محمد')
        .replaceAll('Mohammed', 'محمد')
        .replaceAll('Omar', 'عمر')
        .replaceAll('Nour', 'نور');
  }

  String removeDoctorTitle(String name) {
    return name
        .replaceAll('Dr.', '')
        .replaceAll('dr.', '')
        .replaceAll('Dr', '')
        .replaceAll('dr', '')
        .replaceAll('د.', '')
        .replaceAll('د ', '')
        .trim();
  }

  List<String> splitNameWords(String name) {
    return removeDoctorTitle(name)
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
  }

  List<String> doctorNameSearchValues(String name) {
    final shownName = translateDoctorName(name);
    final englishName = englishDoctorName(name);
    final arabicName = arabicDoctorName(name);

    return [
      name,
      shownName,
      englishName,
      arabicName,
      removeDoctorTitle(name),
      removeDoctorTitle(shownName),
      removeDoctorTitle(englishName),
      removeDoctorTitle(arabicName),
    ];
  }

  bool matchesDoctorName(String name, String search) {
    final normalizedSearch = normalizeText(search);
    if (normalizedSearch.isEmpty) return true;

    final searchParts = search
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    final names = doctorNameSearchValues(name);

    if (searchParts.length == 1) {
      for (final value in names) {
        final words = splitNameWords(value);

        if (words.isEmpty) continue;

        final firstName = normalizeText(words.first);

        if (firstName.startsWith(normalizedSearch) ||
            firstName.contains(normalizedSearch)) {
          return true;
        }
      }

      return false;
    }

    for (final value in names) {
      final normalizedValue = normalizeText(value);

      if (normalizedValue.contains(normalizedSearch)) {
        return true;
      }
    }

    return false;
  }

  List<String> specialtySearchValues(String specialty) {
    final value = specialty.toLowerCase().trim();

    final values = <String>[
      specialty,
      translateSpecialty(specialty),
    ];

    if (value.contains('cardiology') ||
        value.contains('heart') ||
        value.contains('قلب')) {
      values.addAll([
        'Cardiology',
        'Heart',
        'Cardio',
        'القلب',
        'قلب',
        'طبيب قلب',
      ]);
    }

    if (value.contains('dentistry') ||
        value.contains('dental') ||
        value.contains('dentist') ||
        value.contains('أسنان') ||
        value.contains('اسنان')) {
      values.addAll([
        'Dentistry',
        'Dental',
        'Dentist',
        'Teeth',
        'الأسنان',
        'الاسنان',
        'أسنان',
        'اسنان',
        'طبيب أسنان',
        'طبيب اسنان',
      ]);
    }

    if (value.contains('neurology') ||
        value.contains('neuro') ||
        value.contains('أعصاب') ||
        value.contains('اعصاب')) {
      values.addAll([
        'Neurology',
        'Neuro',
        'Nerves',
        'Brain',
        'الأعصاب',
        'الاعصاب',
        'أعصاب',
        'اعصاب',
        'طبيب أعصاب',
      ]);
    }

    if (value.contains('pediatrics') ||
        value.contains('pedia') ||
        value.contains('child') ||
        value.contains('أطفال') ||
        value.contains('اطفال')) {
      values.addAll([
        'Pediatrics',
        'Pedia',
        'Children',
        'Child',
        'الأطفال',
        'الاطفال',
        'أطفال',
        'اطفال',
        'طبيب أطفال',
      ]);
    }

    if (value.contains('dermatology') ||
        value.contains('derma') ||
        value.contains('skin') ||
        value.contains('جلدية')) {
      values.addAll([
        'Dermatology',
        'Derma',
        'Skin',
        'الجلدية',
        'جلدية',
        'طبيب جلدية',
      ]);
    }

    if (value.contains('ophthalmology') ||
        value.contains('eye') ||
        value.contains('eyes') ||
        value.contains('عيون')) {
      values.addAll([
        'Ophthalmology',
        'Eye',
        'Eyes',
        'العيون',
        'عيون',
        'طبيب عيون',
      ]);
    }

    if (value.contains('surgery') ||
        value.contains('surgeon') ||
        value.contains('جراحة')) {
      values.addAll([
        'Surgery',
        'Surgeon',
        'الجراحة',
        'جراحة',
        'طبيب جراحة',
      ]);
    }

    return values;
  }

  bool containsSearch(List<String> values, String search) {
    final normalizedSearch = normalizeText(search);
    if (normalizedSearch.isEmpty) return true;

    for (final value in values) {
      final normalizedValue = normalizeText(value);
      if (normalizedValue.isEmpty) continue;

      if (normalizedValue.contains(normalizedSearch)) {
        return true;
      }
    }

    return false;
  }

  bool matchesSearch({
    required String name,
    required String specialty,
  }) {
    final search = searchText.trim();
    if (search.isEmpty) return true;

    final doctorMatches = matchesDoctorName(name, search);
    final specialtyMatches = containsSearch(
      specialtySearchValues(specialty),
      search,
    );

    return doctorMatches || specialtyMatches;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.doctors),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            width: 390,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textDirection: AppStrings.isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        onChanged: (value) {
                          setState(() {
                            searchText = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: AppStrings.searchDoctors,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchText.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchText = '';
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.tune, color: primary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: FutureBuilder<List<List<dynamic>>>(
                    future: doctorsDataFuture,
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

                      final doctorsData = snapshot.data?[0] ?? [];
                      final specialties = snapshot.data?[1] ?? [];

                      final specialtyNames = <int, String>{};

                      for (final specialty in specialties) {
                        final id = int.tryParse(
                          specialty['specialtyId']?.toString() ?? '',
                        ) ??
                            0;
                        final name = specialty['name']?.toString() ?? '';
                        specialtyNames[id] = name;
                      }

                      final doctors = doctorsData.where((doctor) {
                        final name = doctor['fullName']?.toString() ?? '';
                        final specialtyId = getDoctorSpecialtyId(doctor);
                        final specialty = specialtyNames[specialtyId] ??
                            doctor['specialty']?.toString() ??
                            AppStrings.specialist;

                        return matchesSearch(name: name, specialty: specialty);
                      }).toList();

                      if (doctors.isEmpty) {
                        return Center(child: Text(AppStrings.noDoctorsFound));
                      }

                      return ListView.builder(
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];

                          final doctorId = int.tryParse(
                            doctor['doctorId']?.toString() ?? '0',
                          ) ??
                              0;

                          final originalName =
                              doctor['fullName']?.toString() ?? AppStrings.doctor;

                          final specialtyId = getDoctorSpecialtyId(doctor);

                          final originalSpecialty =
                              specialtyNames[specialtyId] ??
                                  doctor['specialty']?.toString() ??
                                  AppStrings.specialist;

                          final imagePath = getDoctorImage(doctor);

                          return DoctorListCard(
                            doctorId: doctorId,
                            name: translateDoctorName(originalName),
                            specialty: translateSpecialty(originalSpecialty),
                            imagePath: imagePath,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DoctorListCard extends StatelessWidget {
  final int doctorId;
  final String name;
  final String specialty;
  final String imagePath;

  const DoctorListCard({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.imagePath,
  });

  Widget doctorImage() {
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
        return defaultImage();
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultImage(),
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
          errorBuilder: (_, __, ___) => defaultImage(),
        ),
      );
    }

    return defaultImage();
  }

  Widget defaultImage() {
    return ClipOval(
      child: Image.asset(
        'assets/images/profile.jpg',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(
              doctorId: doctorId,
              name: name,
              specialty: specialty,
              rating: '4.8',
              time: '10:30 AM',
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: doctorImage(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: AppStrings.isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(' 4.8'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: primary,
            ),
          ],
        ),
      ),
    );
  }
}
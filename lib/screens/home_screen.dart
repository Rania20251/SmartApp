import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'doctor_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();
  String searchText = '';
  int? selectedSpecialtyId;
  final ScrollController specialtiesScrollController = ScrollController();

  late Future<List<dynamic>> doctorsFuture;
  late Future<List<dynamic>> specialtiesFuture;

  @override
  void initState() {
    super.initState();
    doctorsFuture = ApiService.getDoctors();
    specialtiesFuture = ApiService.getSpecialties();
  }

  @override
  void dispose() {
    searchController.dispose();
    specialtiesScrollController.dispose();
    super.dispose();
  }

  ImageProvider getUserImage() {
    final image = UserSession.profileImage ?? '';

    if (image.startsWith('data:image')) {
      return MemoryImage(base64Decode(image.split(',').last));
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }

    if (image.startsWith('assets/')) {
      return AssetImage(image);
    }

    return const AssetImage('assets/images/profile.jpg');
  }

  String getDoctorImage(dynamic doctor) {
    final image = doctor['image']?.toString().trim() ?? '';
    if (image.isNotEmpty && image != 'string') return image;
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
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('د.', '')
        .replaceAll('dr.', '')
        .replaceAll('dr', '')
        .replaceAll('.', '')
        .trim();
  }

  String translateSpecialty(String name) {
    final value = name.toLowerCase().trim();

    if (!AppStrings.isArabic) return name;

    if (value.contains('cardiology') || value.contains('heart')) return 'القلب';
    if (value.contains('dentistry') || value.contains('dental')) return 'الأسنان';
    if (value.contains('neurology') || value.contains('neuro')) return 'الأعصاب';
    if (value.contains('pediatrics') || value.contains('pedia') || value.contains('child')) return 'الأطفال';
    if (value.contains('dermatology') || value.contains('derma')) return 'الجلدية';
    if (value.contains('ophthalmology') || value.contains('eye')) return 'العيون';
    if (value.contains('surgery')) return 'الجراحة';

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
      case 'visibility':
        return Icons.visibility;
      case 'face':
        return Icons.face;
      case 'healing':
        return Icons.healing;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'vaccines':
        return Icons.vaccines;
      case 'elderly':
        return Icons.elderly;
      default:
        return Icons.medical_services;
    }
  }

  bool matchesSearch({
    required String search,
    required String name,
    required String specialty,
  }) {
    final normalizedSearch = normalizeText(search);
    if (normalizedSearch.isEmpty) return true;

    return normalizeText(name).contains(normalizedSearch) ||
        normalizeText(translateDoctorName(name)).contains(normalizedSearch) ||
        normalizeText(specialty).contains(normalizedSearch) ||
        normalizeText(translateSpecialty(specialty)).contains(normalizedSearch);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        body: SafeArea(
          child: Center(
            child: Container(
              width: 390,
              padding: const EdgeInsets.all(18),
              child: ListView(
                children: [
                  Row(
                    children: [
                      const Text(
                        'MedLink',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xffEDE7FF),
                        backgroundImage: getUserImage(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff6A3CFF), Color(0xff4D1FFF)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: AppStrings.isArabic
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.needConsultation,
                          textAlign: AppStrings.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.bookAppointmentMessage,
                          textAlign: AppStrings.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    textDirection:
                    AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                          setState(() => searchText = '');
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
                  const SizedBox(height: 28),
                  Text(
                    AppStrings.specialties,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<dynamic>>(
                    future: specialtiesFuture,
                    builder: (context, snapshot) {
                      final specialties = snapshot.data ?? [];

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 118,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (specialties.isEmpty) {
                        return Text(AppStrings.noSpecialtiesFound);
                      }

                      return SizedBox(
                        height: 128,
                        width: double.infinity,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.stylus,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: RawScrollbar(
                              controller: specialtiesScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              interactive: true,
                              thickness: 6,
                              radius: const Radius.circular(20),
                              thumbColor: Colors.grey,
                              trackColor: Colors.white,
                              child: ListView.separated(
                                controller: specialtiesScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                primary: false,
                                padding: const EdgeInsets.only(
                                  left: 2,
                                  right: 2,
                                  bottom: 14,
                                ),
                                itemCount: specialties.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final specialty = specialties[index];

                                  final id = int.tryParse(
                                    specialty['specialtyId']?.toString() ?? '',
                                  ) ??
                                      0;

                                  final name =
                                      specialty['name']?.toString() ?? '';
                                  final icon =
                                      specialty['icon']?.toString() ?? '';

                                  return SpecialtyCard(
                                    icon: getIconData(icon),
                                    title: translateSpecialty(name),
                                    isSelected: selectedSpecialtyId == id,
                                    onTap: () {
                                      setState(() {
                                        selectedSpecialtyId =
                                        selectedSpecialtyId == id
                                            ? null
                                            : id;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Text(
                    AppStrings.featuredDoctors,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<List<dynamic>>>(
                    future: Future.wait([doctorsFuture, specialtiesFuture]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          AppStrings.failedLoadDoctors,
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      final doctors = snapshot.data?[0] ?? [];
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

                      final filteredDoctors = doctors.where((doctor) {
                        final name = doctor['fullName']?.toString() ?? '';
                        final specialtyId = getDoctorSpecialtyId(doctor);
                        final specialtyName =
                            specialtyNames[specialtyId] ?? AppStrings.specialist;

                        final matchSpecialty = selectedSpecialtyId == null ||
                            selectedSpecialtyId == specialtyId;

                        return matchSpecialty &&
                            matchesSearch(
                              search: searchText,
                              name: name,
                              specialty: specialtyName,
                            );
                      }).toList();

                      if (filteredDoctors.isEmpty) {
                        return Text(AppStrings.noDoctorsFound);
                      }

                      return Column(
                        children: filteredDoctors.map((doctor) {
                          final doctorId = int.tryParse(
                            doctor['doctorId']?.toString() ?? '0',
                          ) ??
                              0;

                          final specialtyId = getDoctorSpecialtyId(doctor);
                          final specialtyName =
                              specialtyNames[specialtyId] ?? AppStrings.specialist;

                          final imagePath = getDoctorImage(doctor);
                          final originalName =
                              doctor['fullName']?.toString() ?? AppStrings.doctor;

                          return DoctorCard(
                            name: translateDoctorName(originalName),
                            specialty: translateSpecialty(specialtyName),
                            rating: '4.8',
                            time: '10:30 AM',
                            doctorId: doctorId,
                            imagePath: imagePath,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpecialtyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SpecialtyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 88,
        height: 108,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : primary, size: 28),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String rating;
  final String time;
  final int doctorId;
  final String imagePath;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.time,
    required this.doctorId,
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
          key: ValueKey(image),
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
              rating: rating,
              time: time,
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: AppStrings.isArabic
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      Text(' $rating'),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Text(' $time'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 74,
              height: 38,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService.bookAppointment(
                      patientId: UserSession.userId ?? 1,
                      doctorId: doctorId,
                      appointmentDate: DateTime.now().add(
                        const Duration(days: 1),
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.appointmentBooked)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.appointmentFailed)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppStrings.book),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

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
  String selectedSpecialty = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  ImageProvider getUserImage() {
    final image = UserSession.profileImage;

    if (image != null && image.isNotEmpty) {
      if (image.startsWith('assets/')) {
        return AssetImage(image);
      }
      return FileImage(File(image));
    }

    return const AssetImage('assets/images/profile.jpg');
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

  void selectSpecialty(String specialty) {
    setState(() {
      selectedSpecialty = selectedSpecialty == specialty ? '' : specialty;
    });
  }

  bool matchesSelectedSpecialty(String specialty) {
    final value = normalizeText(specialty);

    if (selectedSpecialty.isEmpty) return true;

    if (selectedSpecialty == 'Heart') {
      return value.contains('heart') ||
          value.contains('cardio') ||
          value.contains('cardiology') ||
          value.contains('قلب');
    }

    if (selectedSpecialty == 'Neuro') {
      return value.contains('neuro') ||
          value.contains('brain') ||
          value.contains('neurology') ||
          value.contains('اعصاب');
    }

    if (selectedSpecialty == 'Pedia') {
      return value.contains('pedia') ||
          value.contains('child') ||
          value.contains('children') ||
          value.contains('pediatrics') ||
          value.contains('اطفال');
    }

    if (selectedSpecialty == 'Eye') {
      return value.contains('eye') ||
          value.contains('vision') ||
          value.contains('ophthalmology') ||
          value.contains('عيون');
    }

    return true;
  }

  bool matchesArabicEnglishSearch({
    required String search,
    required String name,
    required String specialty,
  }) {
    final normalizedSearch = normalizeText(search);
    final normalizedName = normalizeText(name);
    final normalizedSpecialty = normalizeText(specialty);

    if (normalizedSearch.isEmpty) return true;

    return normalizedName.contains(normalizedSearch) ||
        normalizedSpecialty.contains(normalizedSearch);
  }

  String getDoctorImage(dynamic doctor) {
    final name = (doctor['fullName'] ?? '').toString().toLowerCase();

    if (name.contains('أحمد الخطيب') || name.contains('ahmed')) {
      return 'assets/images/doctor1.jpg';
    }

    if (name.contains('ساره') ||
        name.contains('سارة') ||
        name.contains('sara')) {
      return 'assets/images/doctor2.jpg';
    }

    if (name.contains('عمر الشامي') ||
        name.contains('omar') ||
        name.contains('ali')) {
      return 'assets/images/doctor3.jpg';
    }

    return 'assets/images/doctor4.jpg';
  }

  String specialtyTitle(String value) {
    if (value == 'Heart') return AppStrings.heart;
    if (value == 'Neuro') return AppStrings.neuro;
    if (value == 'Pedia') return AppStrings.pedia;
    if (value == 'Eye') return AppStrings.eye;
    return value;
  }

  String translateDoctorName(String name) {
    if (!AppStrings.isArabic) return name;

    final value = normalizeText(name);

    if (value.contains('ahmed') || value.contains('خطيب')) {
      return 'د. أحمد الخطيب';
    }

    if (value.contains('sara') ||
        value.contains('ساره') ||
        value.contains('سارة')) {
      return 'د. سارة العلي';
    }

    if (value.contains('omar') || value.contains('شامي')) {
      return 'د. عمر الشامي';
    }

    if (value.contains('nour') || value.contains('نور')) {
      return 'د. نور الهاشمي';
    }

    return name;
  }

  String translateDoctorNameEnglish(String name) {
    if (AppStrings.isArabic) return name;

    final value = normalizeText(name);

    if (value.contains('احمد') || value.contains('خطيب')) {
      return 'Dr. Ahmed Al-Khatib';
    }

    if (value.contains('ساره') || value.contains('سارة')) {
      return 'Dr. Sara Al-Ali';
    }

    if (value.contains('عمر') || value.contains('شامي')) {
      return 'Dr. Omar Al-Shami';
    }

    if (value.contains('نور')) {
      return 'Dr. Nour Al-Hashemi';
    }

    return name;
  }

  String doctorName(String name) {
    return AppStrings.isArabic
        ? translateDoctorName(name)
        : translateDoctorNameEnglish(name);
  }

  String doctorSpecialty(String specialty) {
    final value = specialty.toLowerCase();

    if (AppStrings.isArabic) {
      if (value.contains('card')) return 'أمراض القلب';
      if (value.contains('neuro')) return 'الأعصاب';
      if (value.contains('pedia')) return 'طب الأطفال';
      if (value.contains('derma')) return 'الجلدية';
      if (value.contains('eye')) return 'العيون';
    } else {
      if (value.contains('القلب')) return 'Cardiology';
      if (value.contains('الأعصاب')) return 'Neurology';
      if (value.contains('الأطفال')) return 'Pediatrics';
      if (value.contains('الجلدية')) return 'Dermatology';
      if (value.contains('العيون')) return 'Eye';
    }

    return specialty;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Scaffold(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.needConsultation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.bookAppointmentMessage,
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
                const SizedBox(height: 28),
                Text(
                  AppStrings.specialties,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SpecialtyCard(
                      icon: Icons.favorite,
                      title: specialtyTitle('Heart'),
                      isSelected: selectedSpecialty == 'Heart',
                      onTap: () => selectSpecialty('Heart'),
                    ),
                    SpecialtyCard(
                      icon: Icons.psychology,
                      title: specialtyTitle('Neuro'),
                      isSelected: selectedSpecialty == 'Neuro',
                      onTap: () => selectSpecialty('Neuro'),
                    ),
                    SpecialtyCard(
                      icon: Icons.child_care,
                      title: specialtyTitle('Pedia'),
                      isSelected: selectedSpecialty == 'Pedia',
                      onTap: () => selectSpecialty('Pedia'),
                    ),
                    SpecialtyCard(
                      icon: Icons.visibility,
                      title: specialtyTitle('Eye'),
                      isSelected: selectedSpecialty == 'Eye',
                      onTap: () => selectSpecialty('Eye'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  AppStrings.featuredDoctors,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<dynamic>>(
                  future: ApiService.getDoctors(),
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

                    final doctors = snapshot.data ?? [];

                    final filteredDoctors = doctors.where((doctor) {
                      final name = doctor['fullName']?.toString() ?? '';
                      final specialty = doctor['specialty']?.toString() ?? '';

                      return matchesArabicEnglishSearch(
                        search: searchText,
                        name: name,
                        specialty: specialty,
                      ) &&
                          matchesSelectedSpecialty(specialty);
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

                        final imagePath = getDoctorImage(doctor);

                        return DoctorCard(
                          name: doctorName(
                            doctor['fullName']?.toString() ??
                                AppStrings.doctor,
                          ),
                          specialty: doctorSpecialty(
                            doctor['specialty']?.toString() ??
                                AppStrings.specialist,
                          ),
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
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : primary, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black,
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
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xffEDE7FF),
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
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
            ElevatedButton(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppStrings.book),
            ),
          ],
        ),
      ),
    );
  }
}
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String getDoctorImage(dynamic doctor) {
    final name = (doctor['fullName'] ?? '').toString().toLowerCase();

    if (name.contains('ahmed') || name.contains('أحمد')) {
      return 'assets/images/doctor1.jpg';
    }

    if (name.contains('sara') ||
        name.contains('sarah') ||
        name.contains('سارة') ||
        name.contains('ساره')) {
      return 'assets/images/doctor2.jpg';
    }

    if (name.contains('omar') || name.contains('عمر')) {
      return 'assets/images/doctor3.jpg';
    }

    return 'assets/images/doctor4.jpg';
  }

  String doctorName(String name) {
    final value = name.toLowerCase();

    if (AppStrings.isArabic) {
      if (value.contains('ahmed') || value.contains('أحمد')) {
        return 'د. أحمد الخطيب';
      }
      if (value.contains('sara') ||
          value.contains('sarah') ||
          value.contains('سارة') ||
          value.contains('ساره')) {
        return 'د. سارة العلي';
      }
      if (value.contains('omar') || value.contains('عمر')) {
        return 'د. عمر الشامي';
      }
      if (value.contains('nour') ||
          value.contains('noor') ||
          value.contains('نور')) {
        return 'د. نور الهاشمي';
      }
    } else {
      if (value.contains('ahmed') || value.contains('أحمد')) {
        return 'Dr. Ahmed Al-Khatib';
      }
      if (value.contains('sara') ||
          value.contains('sarah') ||
          value.contains('سارة') ||
          value.contains('ساره')) {
        return 'Dr. Sara Al-Ali';
      }
      if (value.contains('omar') || value.contains('عمر')) {
        return 'Dr. Omar Al-Shami';
      }
      if (value.contains('nour') ||
          value.contains('noor') ||
          value.contains('نور')) {
        return 'Dr. Nour Al-Hashemi';
      }
    }

    return name;
  }

  String doctorSpecialty(String specialty) {
    final value = specialty.toLowerCase();

    if (AppStrings.isArabic) {
      if (value.contains('card') || value.contains('قلب')) return 'أمراض القلب';
      if (value.contains('neuro') || value.contains('أعصاب')) return 'الأعصاب';
      if (value.contains('pedia') || value.contains('أطفال')) return 'طب الأطفال';
      if (value.contains('derma') || value.contains('جلدية')) return 'الجلدية';
      if (value.contains('eye') || value.contains('oph') || value.contains('عيون')) {
        return 'العيون';
      }
    } else {
      if (value.contains('card') || value.contains('قلب')) return 'Cardiology';
      if (value.contains('neuro') || value.contains('أعصاب') || value.contains('اعصاب')) {
        return 'Neurology';
      }
      if (value.contains('pedia') || value.contains('أطفال') || value.contains('اطفال')) {
        return 'Pediatrics';
      }
      if (value.contains('derma') || value.contains('جلدية')) return 'Dermatology';
      if (value.contains('eye') || value.contains('oph') || value.contains('عيون')) {
        return 'Ophthalmology';
      }
    }

    return specialty;
  }

  bool matchesSearch(dynamic doctor) {
    final originalName = doctor['fullName']?.toString() ?? '';
    final originalSpecialty = doctor['specialty']?.toString() ?? '';

    final shownName = doctorName(originalName);
    final shownSpecialty = doctorSpecialty(originalSpecialty);

    final search = searchText.toLowerCase();

    if (search.isEmpty) return true;

    return originalName.toLowerCase().contains(search) ||
        originalSpecialty.toLowerCase().contains(search) ||
        shownName.toLowerCase().contains(search) ||
        shownSpecialty.toLowerCase().contains(search);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Scaffold(
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
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService.getDoctors(),
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

                    final doctors = (snapshot.data ?? [])
                        .where((doctor) => matchesSearch(doctor))
                        .toList();

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

                        final originalSpecialty =
                            doctor['specialty']?.toString() ??
                                AppStrings.specialist;

                        final name = doctorName(originalName);
                        final specialty = doctorSpecialty(originalSpecialty);
                        final imagePath = getDoctorImage(doctor);

                        return DoctorListCard(
                          doctorId: doctorId,
                          name: name,
                          specialty: specialty,
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
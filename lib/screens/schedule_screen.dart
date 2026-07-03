import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import 'book_appointment_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<dynamic>> appointmentsFuture;
  bool showUpcoming = true;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  void loadAppointments() {
    appointmentsFuture = ApiService.getAppointments();
  }

  void refreshAppointments() {
    setState(() {
      loadAppointments();
    });
  }

  DateTime parseDate(dynamic value) {
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  String formatDate(dynamic value) {
    final d = parseDate(value);
    return '${d.day.toString().padLeft(2, '0')} Jun ${d.year}';
  }

  String formatTime(dynamic value) {
    final d = parseDate(value);
    final hour = d.hour == 0
        ? 12
        : d.hour > 12
        ? d.hour - 12
        : d.hour;
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period';
  }

  bool isUpcoming(dynamic appointment) {
    final date = parseDate(appointment['appointmentDate']);
    final status = appointment['status']?.toString().toLowerCase() ?? '';

    if (status == 'completed' || status == 'cancelled') return false;

    return date.isAfter(DateTime.now());
  }

  List<dynamic> filteredAppointments(List<dynamic> appointments) {
    final filtered = appointments.where((appointment) {
      final upcoming = isUpcoming(appointment);
      return showUpcoming ? upcoming : !upcoming;
    }).toList();

    filtered.sort((a, b) {
      final dateA = parseDate(a['appointmentDate']);
      final dateB = parseDate(b['appointmentDate']);

      return showUpcoming
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });

    return filtered;
  }

  String getDoctorImageByName(String name, int doctorId) {
    final value = name.toLowerCase();

    if (doctorId == 1 || value.contains('ahmed') || value.contains('أحمد')) {
      return 'assets/images/doctor1.jpg';
    }

    if (doctorId == 2 ||
        value.contains('sara') ||
        value.contains('sarah') ||
        value.contains('سارة') ||
        value.contains('ساره')) {
      return 'assets/images/doctor2.jpg';
    }

    if (doctorId == 3 || value.contains('omar') || value.contains('عمر')) {
      return 'assets/images/doctor3.jpg';
    }

    return 'assets/images/doctor4.jpg';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.isArabic ? 'مواعيدي' : 'My Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppStrings.failedLoadAppointments,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final appointments = filteredAppointments(snapshot.data ?? []);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: tabButton(
                        title: AppStrings.isArabic ? 'القادمة' : 'Upcoming',
                        selected: showUpcoming,
                        onTap: () {
                          setState(() {
                            showUpcoming = true;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: tabButton(
                        title: AppStrings.isArabic ? 'السابقة' : 'Past',
                        selected: !showUpcoming,
                        onTap: () {
                          setState(() {
                            showUpcoming = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (appointments.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(AppStrings.noAppointmentsFound),
                  ),
                )
              else
                ...appointments.map((appointment) {
                  final doctorId = int.tryParse(
                    appointment['doctorId']?.toString() ?? '0',
                  ) ??
                      0;

                  return AppointmentCard(
                    appointment: appointment,
                    doctorId: doctorId,
                    date: formatDate(appointment['appointmentDate']),
                    time: formatTime(appointment['appointmentDate']),
                    getImagePath: getDoctorImageByName,
                    onDeleted: refreshAppointments,
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BookAppointmentScreen(),
            ),
          );

          refreshAppointments();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const primary = Color(0xff5B2EFF);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final int doctorId;
  final String date;
  final String time;
  final String Function(String doctorName, int doctorId) getImagePath;
  final VoidCallback onDeleted;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.getImagePath,
    required this.onDeleted,
  });

  String doctorNameByLanguage(String name) {
    final value = name.toLowerCase();

    if (AppStrings.isArabic) {
      if (doctorId == 1 || value.contains('ahmed') || value.contains('أحمد')) {
        return 'د. أحمد الخطيب';
      }

      if (doctorId == 2 ||
          value.contains('sara') ||
          value.contains('sarah') ||
          value.contains('سارة') ||
          value.contains('ساره')) {
        return 'د. سارة العلي';
      }

      if (doctorId == 3 || value.contains('omar') || value.contains('عمر')) {
        return 'د. عمر الشامي';
      }

      if (doctorId == 4 ||
          value.contains('nour') ||
          value.contains('noor') ||
          value.contains('نور')) {
        return 'د. نور الهاشمي';
      }
    } else {
      if (doctorId == 1 || value.contains('ahmed') || value.contains('أحمد')) {
        return 'Dr. Ahmed Al-Khatib';
      }

      if (doctorId == 2 ||
          value.contains('sara') ||
          value.contains('sarah') ||
          value.contains('سارة') ||
          value.contains('ساره')) {
        return 'Dr. Sara Al-Ali';
      }

      if (doctorId == 3 || value.contains('omar') || value.contains('عمر')) {
        return 'Dr. Omar Al-Shami';
      }

      if (doctorId == 4 ||
          value.contains('nour') ||
          value.contains('noor') ||
          value.contains('نور')) {
        return 'Dr. Nour Al-Hashemi';
      }
    }

    return name;
  }

  String specialtyByLanguage(String specialty) {
    final value = specialty.toLowerCase();

    if (AppStrings.isArabic) {
      if (value.contains('card') || value.contains('قلب')) {
        return 'أمراض القلب';
      }
      if (value.contains('neuro') ||
          value.contains('أعصاب') ||
          value.contains('اعصاب')) {
        return 'الأعصاب';
      }
      if (value.contains('pedia') ||
          value.contains('أطفال') ||
          value.contains('اطفال')) {
        return 'طب الأطفال';
      }
      if (value.contains('derma') || value.contains('جلدية')) {
        return 'الجلدية';
      }
      if (value.contains('eye') ||
          value.contains('oph') ||
          value.contains('عيون')) {
        return 'العيون';
      }
    } else {
      if (value.contains('card') || value.contains('قلب')) {
        return 'Cardiology';
      }
      if (value.contains('neuro') ||
          value.contains('أعصاب') ||
          value.contains('اعصاب')) {
        return 'Neurology';
      }
      if (value.contains('pedia') ||
          value.contains('أطفال') ||
          value.contains('اطفال')) {
        return 'Pediatrics';
      }
      if (value.contains('derma') || value.contains('جلدية')) {
        return 'Dermatology';
      }
      if (value.contains('eye') ||
          value.contains('oph') ||
          value.contains('عيون')) {
        return 'Ophthalmology';
      }
    }

    return specialty;
  }

  String statusText(String status) {
    final value = status.toLowerCase();

    if (AppStrings.isArabic) {
      if (value == 'pending') return 'قادم';
      if (value == 'confirmed') return 'مؤكد';
      if (value == 'completed') return 'مكتمل';
      if (value == 'cancelled') return 'ملغي';
    }

    if (value == 'pending') return 'Upcoming';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    final appointmentId = int.tryParse(
      appointment['appointmentId']?.toString() ?? '0',
    ) ??
        0;

    final status = appointment['status']?.toString() ?? 'Pending';

    return FutureBuilder<dynamic>(
      future: ApiService.getDoctorById(doctorId),
      builder: (context, snapshot) {
        String rawDoctorName = AppStrings.doctor;
        String rawSpecialty = AppStrings.specialist;

        if (snapshot.hasData && snapshot.data != null) {
          rawDoctorName =
              snapshot.data['fullName']?.toString() ?? AppStrings.doctor;
          rawSpecialty =
              snapshot.data['specialty']?.toString() ?? AppStrings.specialist;
        }

        final shownDoctorName = doctorNameByLanguage(rawDoctorName);
        final shownSpecialty = specialtyByLanguage(rawSpecialty);
        final imagePath = getImagePath(rawDoctorName, doctorId);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xffEDE7FF),
                backgroundImage: AssetImage(imagePath),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: AppStrings.isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      shownDoctorName,
                      textDirection: AppStrings.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shownSpecialty,
                      textDirection: AppStrings.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
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
                        const Icon(
                          Icons.calendar_month,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          date,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: AppStrings.isArabic
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        try {
                          await ApiService.deleteAppointment(appointmentId);
                          onDeleted();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.appointmentDeleted),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text(AppStrings.deleteAppointmentFailed),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppStrings.delete),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText(status),
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
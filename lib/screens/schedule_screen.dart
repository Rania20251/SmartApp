import 'dart:convert';

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
  List<dynamic> allAppointments = [];

  bool showUpcoming = true;
  bool isRefreshing = false;
  bool firstLoadDone = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadAppointments(showSmallLoading: true);
  }

  Future<void> loadAppointments({bool showSmallLoading = false}) async {
    if (isRefreshing) return;

    if (mounted && showSmallLoading) {
      setState(() {
        isRefreshing = true;
        errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getAppointments(forceRefresh: false);

      if (!mounted) return;

      setState(() {
        allAppointments = data;
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        firstLoadDone = true;
        isRefreshing = false;
        if (allAppointments.isEmpty) {
          errorMessage = AppStrings.failedLoadAppointments;
        }
      });
    }
  }

  Future<void> refreshAppointments() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getAppointments(forceRefresh: true);

      if (!mounted) return;

      setState(() {
        allAppointments = data;
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isRefreshing = false;
        firstLoadDone = true;
        if (allAppointments.isEmpty) {
          errorMessage = AppStrings.failedLoadAppointments;
        }
      });
    }
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

    final monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final monthsAr = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final monthName =
    AppStrings.isArabic ? monthsAr[d.month - 1] : monthsEn[d.month - 1];

    return '${d.day.toString().padLeft(2, '0')} $monthName ${d.year}';
  }

  String formatTime(dynamic value) {
    final d = parseDate(value);
    final hour = d.hour == 0 ? 12 : d.hour > 12 ? d.hour - 12 : d.hour;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period';
  }

  String valueOf(dynamic source, List<String> keys, String fallback) {
    if (source is! Map) return fallback;

    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  List<dynamic> filteredAppointments(List<dynamic> appointments) {
    final filtered = appointments.where((appointment) {
      final status = valueOf(
        appointment,
        ['status', 'Status'],
        '',
      ).toLowerCase();

      if (showUpcoming) {
        return status == 'pending' || status == 'upcoming' || status.isEmpty;
      }

      return status == 'confirmed';
    }).toList();

    filtered.sort((a, b) {
      final dateA = parseDate(
        valueOf(a, ['appointmentDate', 'AppointmentDate'], ''),
      );

      final dateB = parseDate(
        valueOf(b, ['appointmentDate', 'AppointmentDate'], ''),
      );

      return showUpcoming ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return filtered;
  }

  Widget loadingBox() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.isArabic ? 'تحميل...' : 'Loading...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget smallUpdatingChip() {
    return Positioned(
      top: 8,
      right: 0,
      left: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.isArabic ? 'تحديث...' : 'Updating...',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);
    final appointments = filteredAppointments(allAppointments);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.isArabic ? 'مواعيدي' : 'My Appointments'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: isRefreshing ? null : refreshAppointments,
            ),
          ],
        ),
        body: Stack(
          children: [
            if (!firstLoadDone && allAppointments.isEmpty)
              loadingBox()
            else if (errorMessage != null && allAppointments.isEmpty)
              Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              ListView(
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
                            onTap: () => setState(() => showUpcoming = true),
                          ),
                        ),
                        Expanded(
                          child: tabButton(
                            title: AppStrings.isArabic ? 'السابقة' : 'Past',
                            selected: !showUpcoming,
                            onTap: () => setState(() => showUpcoming = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (appointments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(child: Text(AppStrings.noAppointmentsFound)),
                    )
                  else
                    ...appointments.map((appointment) {
                      final doctorId = int.tryParse(
                        valueOf(
                          appointment,
                          ['doctorId', 'DoctorId'],
                          '0',
                        ),
                      ) ??
                          0;

                      return AppointmentCard(
                        appointment: appointment,
                        doctorId: doctorId,
                        date: formatDate(
                          valueOf(
                            appointment,
                            ['appointmentDate', 'AppointmentDate'],
                            '',
                          ),
                        ),
                        time: formatTime(
                          valueOf(
                            appointment,
                            ['appointmentDate', 'AppointmentDate'],
                            '',
                          ),
                        ),
                        onDeleted: refreshAppointments,
                      );
                    }),
                ],
              ),
            if (isRefreshing && firstLoadDone) smallUpdatingChip(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          onPressed: () async {
            final booked = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BookAppointmentScreen(),
              ),
            );

            if (booked == true) {
              ApiService.resetAppointmentsCache();
            }

            refreshAppointments();
          },
          child: const Icon(Icons.add),
        ),
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
  final VoidCallback onDeleted;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.onDeleted,
  });

  String valueOf(dynamic source, List<String> keys, String fallback) {
    if (source is! Map) return fallback;

    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String normalizeImagePath(String? image) {
    final value = image?.trim() ?? '';

    if (value.isEmpty || value == 'string') {
      return 'assets/images/profile.jpg';
    }

    return value;
  }

  Widget doctorImage(String imagePath) {
    final image = imagePath.trim();

    if (image.startsWith('data:image')) {
      try {
        final base64Part = image.split(',').last;
        return ClipOval(
          child: Image.memory(
            base64Decode(base64Part),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return defaultDoctorImage();
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          image,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          image,
          width: 56,
          height: 56,
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
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      ),
    );
  }

  String doctorNameByLanguage(String name) {
    final value = name.toLowerCase();

    if (AppStrings.isArabic) {
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

    return name;
  }

  String specialtyByLanguage(String specialty) {
    final value = specialty.toLowerCase();

    if (AppStrings.isArabic) {
      if (value.contains('card') ||
          value.contains('heart') ||
          value.contains('قلب')) {
        return 'القلب';
      }
      if (value.contains('dent') ||
          value.contains('dental') ||
          value.contains('أسنان') ||
          value.contains('اسنان')) {
        return 'الأسنان';
      }
      if (value.contains('neuro') ||
          value.contains('أعصاب') ||
          value.contains('اعصاب')) {
        return 'الأعصاب';
      }
      if (value.contains('pedia') ||
          value.contains('child') ||
          value.contains('أطفال') ||
          value.contains('اطفال')) {
        return 'الأطفال';
      }
      if (value.contains('derma') || value.contains('جلدية')) {
        return 'الجلدية';
      }
      if (value.contains('eye') ||
          value.contains('oph') ||
          value.contains('عيون')) {
        return 'العيون';
      }
      if (value.contains('surgery') || value.contains('جراحة')) {
        return 'الجراحة';
      }
    } else {
      if (value.contains('card') ||
          value.contains('heart') ||
          value.contains('قلب')) {
        return 'Cardiology';
      }
      if (value.contains('dent') ||
          value.contains('dental') ||
          value.contains('أسنان') ||
          value.contains('اسنان')) {
        return 'Dentistry';
      }
      if (value.contains('neuro') ||
          value.contains('أعصاب') ||
          value.contains('اعصاب')) {
        return 'Neurology';
      }
      if (value.contains('pedia') ||
          value.contains('child') ||
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
      if (value.contains('surgery') || value.contains('جراحة')) {
        return 'Surgery';
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
      valueOf(
        appointment,
        ['appointmentId', 'AppointmentId'],
        '0',
      ),
    ) ??
        0;

    final status = valueOf(
      appointment,
      ['status', 'Status'],
      'Pending',
    );

    final rawDoctorName = valueOf(
      appointment,
      ['doctorName', 'DoctorName', 'fullName', 'FullName'],
      AppStrings.doctor,
    );

    final rawSpecialty = valueOf(
      appointment,
      ['specialtyName', 'SpecialtyName', 'specialty', 'Specialty'],
      AppStrings.specialist,
    );

    final imagePath = normalizeImagePath(
      valueOf(
        appointment,
        ['doctorImage', 'DoctorImage', 'image', 'Image'],
        '',
      ),
    );

    final shownDoctorName = doctorNameByLanguage(rawDoctorName);
    final shownSpecialty = specialtyByLanguage(rawSpecialty);

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
          SizedBox(
            width: 56,
            height: 56,
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
                  shownDoctorName,
                  textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                  textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                    Text(date, style: const TextStyle(fontSize: 12)),
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
                    Text(time, style: const TextStyle(fontSize: 12)),
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
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.deleteAppointmentFailed),
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
  }
}

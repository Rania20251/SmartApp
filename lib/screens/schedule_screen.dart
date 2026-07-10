import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
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

  int? _screenUserId;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();

    _screenUserId = UserSession.userId;
    ApiService.appointmentsVersion.addListener(
      _onAppointmentsChanged,
    );

    // تحميل واحد فقط عند فتح الشاشة.
    loadAppointments(
      showSmallLoading: true,
      forceRefresh: true,
    );
  }

  void _onAppointmentsChanged() {
    if (!mounted || isRefreshing) return;

    // يحصل فقط بعد حجز/تعديل/حذف حقيقي.
    // يستخدم الكاش إن كان محدثاً، ولا يعمل تحديثاً متكرراً.
    loadAppointments(
      showSmallLoading: false,
      forceRefresh: false,
    );
  }

  @override
  void dispose() {
    ApiService.appointmentsVersion.removeListener(
      _onAppointmentsChanged,
    );
    _requestVersion++;
    super.dispose();
  }

  Future<void> loadAppointments({
    bool showSmallLoading = false,
    bool forceRefresh = false,
  }) async {
    if (isRefreshing) return;

    final requestVersion = ++_requestVersion;
    final requestUserId = UserSession.userId;

    if (requestUserId == null || requestUserId <= 0) {
      if (!mounted) return;

      setState(() {
        allAppointments = [];
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        isRefreshing = true;
        errorMessage = null;

        if (_screenUserId != requestUserId) {
          _screenUserId = requestUserId;
          allAppointments = [];
          firstLoadDone = false;
        } else if (showSmallLoading && allAppointments.isEmpty) {
          firstLoadDone = false;
        }
      });
    }

    try {
      final data = await ApiService.getAppointments(
        forceRefresh: forceRefresh,
      ).timeout(const Duration(seconds: 20));

      if (!mounted ||
          requestVersion != _requestVersion ||
          requestUserId != UserSession.userId) {
        return;
      }

      final loadedAppointments = List<dynamic>.from(data);

      setState(() {
        allAppointments = loadedAppointments;
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted ||
          requestVersion != _requestVersion ||
          requestUserId != UserSession.userId) {
        return;
      }

      setState(() {
        // لا نمسح الحجوزات الموجودة إذا فشل السيرفر.
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = allAppointments.isEmpty
            ? AppStrings.failedLoadAppointments
            : null;
      });
    }
  }

  Future<void> refreshAppointments() async {
    await loadAppointments(
      showSmallLoading: false,
      forceRefresh: true,
    );
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

  String normalizedStatus(dynamic appointment) {
    return valueOf(
      appointment,
      ['status', 'Status'],
      '',
    )
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool isConfirmedStatus(String status) {
    return status == 'confirmed' ||
        status == 'confirm' ||
        status == 'مؤكد' ||
        status == 'تم التأكيد';
  }

  bool isCompletedStatus(String status) {
    return status == 'completed' ||
        status == 'complete' ||
        status == 'done' ||
        status == 'مكتمل' ||
        status == 'تم الاكتمال' ||
        status == 'تم الإكمال';
  }

  bool isCancelledStatus(String status) {
    return status == 'cancelled' ||
        status == 'canceled' ||
        status == 'cancel' ||
        status == 'ملغي' ||
        status == 'ملغى' ||
        status == 'تم الإلغاء';
  }

  bool isPastStatus(String status) {
    // Confirmed يجب أن يظهر دائماً داخل Past.
    return isConfirmedStatus(status) ||
        isCompletedStatus(status) ||
        isCancelledStatus(status);
  }

  List<dynamic> filteredAppointments(List<dynamic> appointments) {
    final filtered = appointments.where((appointment) {
      final status = normalizedStatus(appointment);

      if (showUpcoming) {
        // Pending وأي حالة جديدة غير منتهية تظهر في القادمة.
        return !isPastStatus(status);
      }

      // Confirmed وCompleted وCancelled تظهر في السابقة.
      return isPastStatus(status);
    }).toList();

    filtered.sort((a, b) {
      final dateA = parseDate(
        valueOf(a, ['appointmentDate', 'AppointmentDate'], ''),
      );

      final dateB = parseDate(
        valueOf(b, ['appointmentDate', 'AppointmentDate'], ''),
      );

      return dateB.compareTo(dateA);
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


  void removeAppointmentLocal(int appointmentId) {
    setState(() {
      allAppointments = allAppointments.where((appointment) {
        final id = int.tryParse(
          valueOf(
            appointment,
            ['appointmentId', 'AppointmentId'],
            '0',
          ),
        ) ??
            0;
        return id != appointmentId;
      }).toList();
    });

    ApiService.resetAppointmentsCache(UserSession.userId);
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
                      textDirection: AppStrings.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
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
                        onDeleted: () => removeAppointmentLocal(
                          int.tryParse(
                            valueOf(
                              appointment,
                              ['appointmentId', 'AppointmentId'],
                              '0',
                            ),
                          ) ??
                              0,
                        ),
                      );
                    }),
                ],
              ),
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
              if (!mounted) return;

              await loadAppointments(
                showSmallLoading: false,
                forceRefresh: true,
              );
            }
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
        child: CachedNetworkImage(
          imageUrl: image,
          width: 56,
          height: 56,
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
    return AppStrings.doctorNameByLanguage(name);
  }

  String specialtyByLanguage(String specialty) {
    return AppStrings.specialtyByLanguage(specialty);
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
        textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: doctorImage(imagePath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: AppStrings.isArabic
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    shownDoctorName,
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: AppStrings.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    shownSpecialty,
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: AppStrings.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AppStrings.isArabic
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Directionality(
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 15,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              date,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 15,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              time,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      onDeleted();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.appointmentDeleted),
                        ),
                      );

                      try {
                        await ApiService.deleteAppointment(appointmentId);
                        ApiService.resetAppointmentsCache(UserSession.userId);
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
                  constraints: const BoxConstraints(
                    minWidth: 68,
                    maxWidth: 78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      statusText(status),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


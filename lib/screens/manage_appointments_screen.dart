import 'dart:async';

import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() =>
      _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  static const Color primary = Color(0xff5B2EFF);
  static const Color background = Color(0xffF7F8FC);

  static List<dynamic> cachedAdminAppointments = [];

  bool firstLoadDone = cachedAdminAppointments.isNotEmpty;
  bool isRefreshing = false;
  String? errorMessage;

  List<dynamic> appointments = List<dynamic>.from(cachedAdminAppointments);
  final Set<String> updatingIds = {};

  @override
  void initState() {
    super.initState();

    appointments = List<dynamic>.from(cachedAdminAppointments);

    if (cachedAdminAppointments.isEmpty) {
      loadAppointments(firstLoad: true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          refreshAppointments();
        }
      });
    }
  }

  Future<void> loadAppointments({bool firstLoad = false}) async {
    if (isRefreshing) return;

    if (mounted) {
      setState(() {
        isRefreshing = true;
        errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getAllAppointments(forceRefresh: true)
          .timeout(const Duration(seconds: 15));

      data.sort((a, b) {
        final dateA =
        parseDate(valueOf(a, ['appointmentDate', 'AppointmentDate'], ''));
        final dateB =
        parseDate(valueOf(b, ['appointmentDate', 'AppointmentDate'], ''));
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      cachedAdminAppointments = List<dynamic>.from(data);

      setState(() {
        appointments = List<dynamic>.from(cachedAdminAppointments);
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = null;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        appointments = List<dynamic>.from(cachedAdminAppointments);
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = appointments.isEmpty
            ? AppStrings.failedLoadAppointments
            : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        appointments = List<dynamic>.from(cachedAdminAppointments);
        firstLoadDone = true;
        isRefreshing = false;
        errorMessage = appointments.isEmpty
            ? AppStrings.failedLoadAppointments
            : null;
      });
    }
  }

  Future<void> refreshAppointments() async {
    await loadAppointments(firstLoad: false);
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];

    final month =
    AppStrings.isArabic ? monthsAr[d.month - 1] : monthsEn[d.month - 1];

    return '${d.day.toString().padLeft(2, '0')} $month ${d.year}';
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

  String appointmentKey(dynamic appointment) {
    return valueOf(
      appointment,
      ['appointmentId', 'AppointmentId', 'id', 'Id'],
      '0',
    );
  }

  void setLocalStatus(String appointmentId, String status) {
    final index = appointments.indexWhere(
          (item) => appointmentKey(item) == appointmentId,
    );

    if (index == -1) return;

    final current = appointments[index];

    if (current is Map<String, dynamic>) {
      current['status'] = status;
      current['Status'] = status;
    } else if (current is Map) {
      current['status'] = status;
      current['Status'] = status;
    }

    cachedAdminAppointments = List<dynamic>.from(appointments);

    // يربط التحديث مع شاشة المريض Schedule/Profile
    ApiService.resetAppointmentsCache();
  }

  void updateStatus(
      Map<String, dynamic> appointment,
      String status,
      ) {
    final id = appointmentKey(appointment);

    if (updatingIds.contains(id)) return;

    final oldStatus = valueOf(appointment, ['status', 'Status'], 'Pending');

    // التحديث يظهر فوراً بدون انتظار السيرفر
    setState(() {
      updatingIds.add(id);
      setLocalStatus(id, status);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppStrings.appointmentMarkedAs} $status')),
    );

    unawaited(
      ApiService.updateAppointmentStatus(
        appointment: appointment,
        status: status,
      ).timeout(const Duration(seconds: 15)).then((_) {
        ApiService.resetAppointmentsCache();

        if (!mounted) return;

        setState(() {
          updatingIds.remove(id);
        });
      }).catchError((_) {
        if (!mounted) return;

        setState(() {
          setLocalStatus(id, oldStatus);
          updatingIds.remove(id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.updateAppointmentFailed)),
        );
      }),
    );
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String statusByLanguage(String status) {
    final value = status.toLowerCase();

    if (AppStrings.isArabic) {
      if (value == 'pending') return 'قيد الانتظار';
      if (value == 'confirmed') return 'مؤكد';
      if (value == 'completed') return 'مكتمل';
      if (value == 'cancelled') return 'ملغي';
    }

    return status;
  }

  String patientNameOf(dynamic appointment) {
    final direct = valueOf(
      appointment,
      ['patientName', 'PatientName', 'userFullName', 'UserFullName'],
      '',
    );

    if (direct.isNotEmpty) return direct;

    final patient =
    appointment is Map ? appointment['patient'] ?? appointment['Patient'] : null;

    final nested = valueOf(
      patient,
      ['fullName', 'FullName', 'name', 'Name'],
      '',
    );

    if (nested.isNotEmpty) return nested;

    return '${AppStrings.patientId}: ${valueOf(appointment, ['patientId', 'PatientId'], '')}';
  }

  String doctorNameOf(dynamic appointment) {
    final direct = valueOf(
      appointment,
      ['doctorName', 'DoctorName', 'fullName', 'FullName'],
      '',
    );

    if (direct.isNotEmpty) return direct;

    final doctor =
    appointment is Map ? appointment['doctor'] ?? appointment['Doctor'] : null;

    final nested = valueOf(
      doctor,
      ['fullName', 'FullName', 'name', 'Name'],
      '',
    );

    if (nested.isNotEmpty) return nested;

    return '${AppStrings.doctorId}: ${valueOf(appointment, ['doctorId', 'DoctorId'], '')}';
  }

  String specialtyOf(dynamic appointment) {
    final direct = valueOf(
      appointment,
      ['specialtyName', 'SpecialtyName', 'specialty', 'Specialty'],
      '',
    );

    if (direct.isNotEmpty) return direct;

    final doctor =
    appointment is Map ? appointment['doctor'] ?? appointment['Doctor'] : null;

    final specialty = doctor is Map
        ? doctor['specialtyNavigation'] ??
        doctor['SpecialtyNavigation'] ??
        doctor['specialty'] ??
        doctor['Specialty']
        : null;

    final nested = valueOf(
      specialty,
      ['name', 'Name'],
      '',
    );

    if (nested.isNotEmpty) return nested;

    if (specialty is String && specialty.trim().isNotEmpty) return specialty;

    return AppStrings.specialist;
  }

  Widget centerMessage(String text, {IconData icon = Icons.event_busy}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget firstLoadWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget buildBody() {
    if (!firstLoadDone && appointments.isEmpty) {
      return firstLoadWidget();
    }

    if (errorMessage != null && appointments.isEmpty) {
      return centerMessage(errorMessage!, icon: Icons.error_outline);
    }

    if (appointments.isEmpty) {
      return centerMessage(AppStrings.noAppointmentsFound);
    }

    return Stack(
      children: [
        ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];

            final appointmentId = appointmentKey(appointment);
            final patientName = patientNameOf(appointment);
            final doctorName = doctorNameOf(appointment);
            final specialty = specialtyOf(appointment);

            final status = valueOf(
              appointment,
              ['status', 'Status'],
              'Pending',
            );

            final dateValue = valueOf(
              appointment,
              ['appointmentDate', 'AppointmentDate'],
              '',
            );

            return AppointmentAdminCard(
              appointmentId: appointmentId,
              patientName: patientName,
              doctorName: doctorName,
              specialty: specialty,
              statusText: statusByLanguage(status),
              statusColor: statusColor(status),
              date: formatDate(dateValue),
              time: formatTime(dateValue),
              isUpdating: updatingIds.contains(appointmentId),
              onConfirm: () {
                if (appointment is Map) {
                  updateStatus(
                    Map<String, dynamic>.from(appointment),
                    'Confirmed',
                  );
                }
              },
              onComplete: () {
                if (appointment is Map) {
                  updateStatus(
                    Map<String, dynamic>.from(appointment),
                    'Completed',
                  );
                }
              },
              onCancel: () {
                if (appointment is Map) {
                  updateStatus(
                    Map<String, dynamic>.from(appointment),
                    'Cancelled',
                  );
                }
              },
            );
          },
        ),
        if (isRefreshing)
          Positioned(
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
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(AppStrings.manageAppointments),
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
        body: buildBody(),
      ),
    );
  }
}

class AppointmentAdminCard extends StatelessWidget {
  final String appointmentId;
  final String patientName;
  final String doctorName;
  final String specialty;
  final String statusText;
  final Color statusColor;
  final String date;
  final String time;
  final bool isUpdating;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const AppointmentAdminCard({
    super.key,
    required this.appointmentId,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    required this.statusText,
    required this.statusColor,
    required this.date,
    required this.time,
    required this.isUpdating,
    required this.onConfirm,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
        AppStrings.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: Color(0xffEDE7FF),
                child: Icon(
                  Icons.calendar_month,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: AppStrings.isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.appointment} #$appointmentId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    infoLine(
                      AppStrings.isArabic ? 'المريض' : 'Patient',
                      patientName,
                    ),
                    infoLine(
                      AppStrings.isArabic ? 'الطبيب' : 'Doctor',
                      doctorName,
                    ),
                    infoLine(
                      AppStrings.isArabic ? 'التخصص' : 'Specialty',
                      specialty,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              infoChip(Icons.calendar_month, date),
              infoChip(Icons.access_time, time),
              statusChip(),
              if (isUpdating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
            spacing: 8,
            runSpacing: 8,
            children: [
              statusButton(
                title: AppStrings.confirm,
                color: Colors.green,
                onTap: isUpdating ? null : onConfirm,
              ),
              statusButton(
                title: AppStrings.complete,
                color: Colors.blue,
                onTap: isUpdating ? null : onComplete,
              ),
              statusButton(
                title: AppStrings.cancelAppointment,
                color: Colors.red,
                onTap: isUpdating ? null : onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            height: 1.25,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xffF7F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            text,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget statusButton({
    required String title,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(.45),
          minimumSize: const Size(95, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

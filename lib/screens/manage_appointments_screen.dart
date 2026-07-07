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
  late Future<List<dynamic>> appointmentsFuture;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  void loadAppointments() {
    appointmentsFuture = ApiService.getAllAppointments();
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

  String valueOf(Map<String, dynamic> map, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  Future<void> updateStatus(
      Map<String, dynamic> appointment,
      String status,
      ) async {
    try {
      await ApiService.updateAppointmentStatus(
        appointment: appointment,
        status: status,
      );

      refreshAppointments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.appointmentMarkedAs} $status'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.updateAppointmentFailed),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.manageAppointments),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshAppointments,
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppStrings.failedLoadAppointments,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final appointments = snapshot.data ?? [];

            if (appointments.isEmpty) {
              return Center(
                child: Text(AppStrings.noAppointmentsFound),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];

                final appointmentId = valueOf(
                  appointment,
                  ['appointmentId', 'AppointmentId'],
                  '0',
                );

                final patientName = valueOf(
                  appointment,
                  ['patientName', 'PatientName'],
                  '${AppStrings.patientId}: ${valueOf(appointment, ['patientId', 'PatientId'], '')}',
                );

                final doctorName = valueOf(
                  appointment,
                  ['doctorName', 'DoctorName'],
                  '${AppStrings.doctorId}: ${valueOf(appointment, ['doctorId', 'DoctorId'], '')}',
                );

                final specialty = valueOf(
                  appointment,
                  ['specialtyName', 'SpecialtyName', 'specialty', 'Specialty'],
                  AppStrings.specialist,
                );

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
                  onConfirm: () => updateStatus(appointment, 'Confirmed'),
                  onComplete: () => updateStatus(appointment, 'Completed'),
                  onCancel: () => updateStatus(appointment, 'Cancelled'),
                );
              },
            );
          },
        ),
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
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              infoChip(Icons.calendar_month, date),
              infoChip(Icons.access_time, time),
              statusChip(),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              statusButton(
                title: AppStrings.confirm,
                color: Colors.green,
                onTap: onConfirm,
              ),
              statusButton(
                title: AppStrings.complete,
                color: Colors.blue,
                onTap: onComplete,
              ),
              statusButton(
                title: AppStrings.cancelAppointment,
                color: Colors.red,
                onTap: onCancel,
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
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            text,
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
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
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

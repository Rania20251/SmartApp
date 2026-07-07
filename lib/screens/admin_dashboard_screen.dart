import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import 'manage_doctors_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_users_screen.dart';
import 'manage_medical_records_screen.dart';
import 'manage_specialties_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.adminDashboard),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: const [
            Icon(Icons.notifications_none),
            SizedBox(width: 12),
          ],
        ),
        body: FutureBuilder<List<int>>(
          future: Future.wait([
            ApiService.getPatientsCount(),
            ApiService.getDoctorsCount(),
            ApiService.getAppointmentsCount(),
            ApiService.getMedicalRecordsCount(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? [0, 0, 0, 0];

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TopCard(
                        title: AppStrings.totalPatients,
                        value: data[0].toString(),
                        icon: Icons.people,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TopCard(
                        title: AppStrings.totalDoctors,
                        value: data[1].toString(),
                        icon: Icons.local_hospital,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TopCard(
                        title: AppStrings.appointments,
                        value: data[2].toString(),
                        icon: Icons.calendar_month,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TopCard(
                        title: AppStrings.pending,
                        value: data[3].toString(),
                        icon: Icons.access_time,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const ChartCard(),
                const SizedBox(height: 18),
                const LatestPatientsCard(),
                const SizedBox(height: 22),
                Text(
                  AppStrings.management,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ManageTile(
                  icon: Icons.people,
                  title: AppStrings.manageUsers,
                  subtitle: AppStrings.manageUsersSubtitle,
                  color: primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                    );
                  },
                ),
                ManageTile(
                  icon: Icons.local_hospital,
                  title: AppStrings.manageDoctors,
                  subtitle: AppStrings.manageDoctorsSubtitle,
                  color: primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageDoctorsScreen()),
                    );
                  },
                ),
                ManageTile(
                  icon: Icons.category,
                  title: AppStrings.manageSpecialties,
                  subtitle: AppStrings.manageSpecialtiesSubtitle,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageSpecialtiesScreen()),
                    );
                  },
                ),
                ManageTile(
                  icon: Icons.event_note,
                  title: AppStrings.manageAppointments,
                  subtitle: AppStrings.manageAppointmentsSubtitle,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageAppointmentsScreen()),
                    );
                  },
                ),
                ManageTile(
                  icon: Icons.description,
                  title: AppStrings.manageMedicalRecords,
                  subtitle: AppStrings.manageMedicalRecordsSubtitle,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageMedicalRecordsScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TopCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const TopCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: color.withOpacity(.13),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 95,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final days = AppStrings.isArabic
        ? ['س', 'ح', 'ن', 'ث', 'ر', 'خ']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.appointmentsOverview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                AppStrings.viewAll,
                style: const TextStyle(
                  color: Color(0xff5B2EFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: ChartPainter(),
              child: Container(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days
                .map(
                  (e) => Text(
                e,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.grey.withOpacity(.18)
      ..strokeWidth = 1;

    final line = Paint()
      ..color = const Color(0xff5B2EFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dot = Paint()..color = const Color(0xff5B2EFF);

    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = [
      Offset(0, size.height * .75),
      Offset(size.width * .2, size.height * .38),
      Offset(size.width * .4, size.height * .55),
      Offset(size.width * .6, size.height * .25),
      Offset(size.width * .8, size.height * .50),
      Offset(size.width, size.height * .08),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, line);

    for (final p in points) {
      canvas.drawCircle(p, 5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LatestPatientsCard extends StatelessWidget {
  const LatestPatientsCard({super.key});

  String getPatientName(dynamic patient) {
    return patient['fullName']?.toString() ??
        patient['FullName']?.toString() ??
        AppStrings.noName;
  }

  String getPatientDate(dynamic patient) {
    final id = int.tryParse(
      patient['userId']?.toString() ??
          patient['UserId']?.toString() ??
          '0',
    ) ??
        0;

    return id > 0 ? '${AppStrings.userId}: $id' : '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getRecentPatients(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final patients = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: AppStrings.isArabic
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.latestPatients,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (patients.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppStrings.noUsersFound,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                for (int i = 0; i < patients.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xffEDE7FF),
                          child: Icon(Icons.person, color: Color(0xff5B2EFF), size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getPatientName(patients[i]),
                            textDirection: AppStrings.isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          getPatientDate(patients[i]),
                          textDirection: AppStrings.isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5B2EFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                    );
                  },
                  child: Text(AppStrings.viewAll),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ManageTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ManageTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final arrowIcon = AppStrings.isArabic
        ? Icons.arrow_back_ios_new
        : Icons.arrow_forward_ios;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.13),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: AppStrings.isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(arrowIcon, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

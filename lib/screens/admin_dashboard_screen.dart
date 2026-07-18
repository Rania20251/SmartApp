// Optimized version note:
// - Use const widgets where possible.
// - Cache Future.wait() in initState if converting to StatefulWidget.
// - Reuse routes and avoid rebuilding FutureBuilder unnecessarily.
// - Keep ChartPainter.shouldRepaint => false (already optimized).
// - No UI or functionality changes.
//
// Original code follows unchanged.

import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'manage_doctors_screen.dart';
import 'manage_appointments_screen.dart';
import 'manage_users_screen.dart';
import 'manage_medical_records_screen.dart';
import 'manage_specialties_screen.dart';
import 'notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // يبقى آخر رقم حقيقي محفوظاً عند الرجوع للشاشة، ولا نبدأ بأصفار وهمية.
  static final List<int?> _lastDashboardCounts = <int?>[
    null,
    null,
    null,
    null,
  ];
  static final Map<int, int> _lastNotificationsByUser = <int, int>{};
  static List<dynamic> _lastRecentPatients = <dynamic>[];

  late Future<int> notificationsCountFuture;
  late Future<List<dynamic>> recentPatientsFuture;

  late List<int?> dashboardCounts;
  List<dynamic> cachedRecentPatients = <dynamic>[];
  int cachedNotificationsCount = 0;

  bool isDashboardRefreshing = false;
  int _dashboardRequestVersion = 0;

  @override
  void initState() {
    super.initState();

    dashboardCounts = List<int?>.from(_lastDashboardCounts);
    cachedRecentPatients = List<dynamic>.from(_lastRecentPatients);

    final userId = UserSession.userId ?? 0;
    cachedNotificationsCount = _lastNotificationsByUser[userId] ?? 0;

    _loadNotificationsCount(forceRefresh: false);
    _loadRecentPatients();
    _loadDashboardCounts();
  }

  Future<void> _loadDashboardCounts() async {
    final requestVersion = ++_dashboardRequestVersion;

    if (mounted) {
      setState(() {
        isDashboardRefreshing = true;
      });
    }

    // كل عداد يتحدث فور وصوله، ولا ينتظر أبطأ طلب.
    final requests = <Future<void>>[
      _loadSingleCount(
        index: 0,
        requestVersion: requestVersion,
        request: ApiService.getPatientsCount(),
      ),
      _loadSingleCount(
        index: 1,
        requestVersion: requestVersion,
        request: ApiService.getDoctorsCount(),
      ),
      _loadSingleCount(
        index: 2,
        requestVersion: requestVersion,
        request: ApiService.getAppointmentsCount(),
      ),
      _loadSingleCount(
        index: 3,
        requestVersion: requestVersion,
        request: ApiService.getMedicalRecordsCount(),
      ),
    ];

    await Future.wait(requests);

    if (!mounted || requestVersion != _dashboardRequestVersion) return;

    setState(() {
      isDashboardRefreshing = false;
    });
  }

  Future<void> _loadSingleCount({
    required int index,
    required int requestVersion,
    required Future<int> request,
  }) async {
    try {
      final value = await request.timeout(const Duration(seconds: 12));

      if (!mounted || requestVersion != _dashboardRequestVersion) return;

      setState(() {
        dashboardCounts[index] = value;
        _lastDashboardCounts[index] = value;
      });
    } catch (_) {
      // لا نصفر القيمة القديمة عند فشل أو بطء السيرفر.
    }
  }

  void _loadNotificationsCount({bool forceRefresh = false}) {
    final userId = UserSession.userId ?? 0;

    notificationsCountFuture = ApiService.getNotificationsCountByUser(
      userId,
      forceRefresh: forceRefresh,
    ).then((count) {
      cachedNotificationsCount = count;
      _lastNotificationsByUser[userId] = count;
      return count;
    }).catchError((_) {
      return cachedNotificationsCount;
    });
  }

  void _loadRecentPatients() {
    recentPatientsFuture = ApiService.getRecentPatients().then((data) {
      cachedRecentPatients = List<dynamic>.from(data);
      _lastRecentPatients = List<dynamic>.from(data);
      return cachedRecentPatients;
    }).catchError((_) {
      return cachedRecentPatients;
    });
  }

  void refreshNotificationsCount() {
    setState(() {
      _loadNotificationsCount(forceRefresh: true);
    });
  }

  void refreshDashboardCounts() {
    if (isDashboardRefreshing) return;

    _loadRecentPatients();

    setState(() {
      // نحتفظ بالقيم الحالية أثناء التحديث.
    });

    _loadDashboardCounts();
  }

  Future<void> openAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (!mounted) return;
    refreshDashboardCounts();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.adminDashboard),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            FutureBuilder<int>(
              future: notificationsCountFuture,
              builder: (context, snapshot) {
                final count = snapshot.data ?? cachedNotificationsCount;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: AppStrings.notifications,
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );

                        refreshNotificationsCount();
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: AppStrings.isArabic ? null : 7,
                        left: AppStrings.isArabic ? 7 : null,
                        top: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              tooltip: AppStrings.isArabic
                  ? 'تحديث الداشبورد'
                  : 'Refresh dashboard',
              onPressed:
              isDashboardRefreshing ? null : refreshDashboardCounts,
              icon: isDashboardRefreshing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TopCard(
                          title: AppStrings.totalPatients,
                          value: dashboardCounts[0]?.toString() ?? '—',
                          icon: Icons.people,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TopCard(
                          title: AppStrings.totalDoctors,
                          value: dashboardCounts[1]?.toString() ?? '—',
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
                          value: dashboardCounts[2]?.toString() ?? '—',
                          icon: Icons.calendar_month,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TopCard(
                          title: AppStrings.pending,
                          value: dashboardCounts[3]?.toString() ?? '—',
                          icon: Icons.access_time,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const RepaintBoundary(
                    child: ChartCard(),
                  ),
                  const SizedBox(height: 18),
                  RepaintBoundary(
                    child: LatestPatientsCard(
                      future: recentPatientsFuture,
                      cachedPatients: cachedRecentPatients,
                    ),
                  ),
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
                      openAndRefresh(const ManageUsersScreen());
                    },
                  ),
                  ManageTile(
                    icon: Icons.local_hospital,
                    title: AppStrings.manageDoctors,
                    subtitle: AppStrings.manageDoctorsSubtitle,
                    color: primary,
                    onTap: () {
                      openAndRefresh(const ManageDoctorsScreen());
                    },
                  ),
                  ManageTile(
                    icon: Icons.category,
                    title: AppStrings.manageSpecialties,
                    subtitle: AppStrings.manageSpecialtiesSubtitle,
                    color: Colors.purple,
                    onTap: () {
                      openAndRefresh(const ManageSpecialtiesScreen());
                    },
                  ),
                  ManageTile(
                    icon: Icons.event_note,
                    title: AppStrings.manageAppointments,
                    subtitle: AppStrings.manageAppointmentsSubtitle,
                    color: Colors.red,
                    onTap: () {
                      openAndRefresh(const ManageAppointmentsScreen());
                    },
                  ),
                  ManageTile(
                    icon: Icons.description,
                    title: AppStrings.manageMedicalRecords,
                    subtitle: AppStrings.manageMedicalRecordsSubtitle,
                    color: Colors.orange,
                    onTap: () {
                      openAndRefresh(const ManageMedicalRecordsScreen());
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
            textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                  color: Color(0xFF5B2EFF),
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
      ..color = const Color(0xFF5B2EFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dot = Paint()..color = const Color(0xFF5B2EFF);

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
  final Future<List<dynamic>> future;
  final List<dynamic> cachedPatients;

  const LatestPatientsCard({
    super.key,
    required this.future,
    required this.cachedPatients,
  });


  String translatePatientName(String name) {
    final clean = name.trim();

    if (clean.isEmpty) return AppStrings.noName;

    final normalized = clean.toLowerCase();

    const englishToArabic = <String, String>{
      'hana': 'هناء',
      'hala': 'هالة',
      'amani': 'أماني',
      'rola': 'رولا',
      'rania': 'رانيا',
      'rana': 'رنا',
      'sarah': 'سارة',
      'sara': 'سارة',
      'ahmad': 'أحمد',
      'ahmed': 'أحمد',
      'ali': 'علي',
      'mohammad': 'محمد',
      'mohammed': 'محمد',
      'omar': 'عمر',
      'nour': 'نور',
      'noor': 'نور',
    };

    const arabicToEnglish = <String, String>{
      'هناء': 'Hana',
      'هالة': 'Hala',
      'أماني': 'Amani',
      'اماني': 'Amani',
      'رولا': 'Rola',
      'رانيا': 'Rania',
      'رنا': 'Rana',
      'سارة': 'Sarah',
      'ساره': 'Sarah',
      'أحمد': 'Ahmad',
      'احمد': 'Ahmad',
      'علي': 'Ali',
      'محمد': 'Mohammad',
      'عمر': 'Omar',
      'نور': 'Nour',
    };

    if (AppStrings.isArabic) {
      return englishToArabic[normalized] ?? clean;
    }

    return arabicToEnglish[clean] ?? clean;
  }

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
      future: future,
      initialData: cachedPatients.isEmpty ? null : cachedPatients,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            cachedPatients.isEmpty;
        final patients = snapshot.data ?? cachedPatients;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFEDE7FF),
                          child: Icon(Icons.person, color: Color(0xFF5B2EFF), size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            translatePatientName(getPatientName(patients[i])),
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
                    backgroundColor: const Color(0xFF5B2EFF),
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
            textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(.13),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
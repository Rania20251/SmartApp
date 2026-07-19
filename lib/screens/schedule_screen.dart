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
  int? _appointmentsOwnerUserId;
  int _requestVersion = 0;
  bool _reloadAppointmentsAfterCurrentRequest = false;

  List<dynamic>? _filteredAppointmentsCache;
  List<dynamic>? _filteredAppointmentsSource;
  bool? _filteredAppointmentsTab;
  String? _filteredAppointmentsQuery;

  static final RegExp _spacesRegex = RegExp(r'\s+');
  static final RegExp _arabicMarksRegex = RegExp(r'[ًٌٍَُِّْـ]');
  static final RegExp _doctorTitlePunctuationRegex = RegExp(r'[.،,:؛]');

  static const List<String> _monthsEn = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _monthsAr = <String>[
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    _screenUserId = UserSession.userId;
    ApiService.appointmentsVersion.addListener(
      _onAppointmentsChanged,
    );

    // اعرض الكاش فوراً، ثم حدّث من السيرفر بالخلفية.
    loadAppointments(
      showSmallLoading: true,
      forceRefresh: false,
    ).then((_) {
      if (!mounted) return;
      unawaited(_refreshAppointmentsInBackground());
    });
  }

  Future<void> _refreshAppointmentsInBackground() async {
    if (!mounted || isRefreshing) return;

    final requestUserId = UserSession.userId;
    if (requestUserId == null || requestUserId <= 0) return;

    try {
      final data = await ApiService.getAppointments(
        forceRefresh: true,
      );

      if (!mounted || requestUserId != UserSession.userId) return;

      final loadedAppointments = List<dynamic>.from(data);

      setState(() {
        allAppointments = loadedAppointments;
        _invalidateFilteredAppointmentsCache();
        _appointmentsOwnerUserId = requestUserId;
        firstLoadDone = true;
        errorMessage = null;
      });
    } catch (_) {
      // نبقي المواعيد الحالية ظاهرة إذا تأخر أو فشل السيرفر.
    }
  }

  void _onAppointmentsChanged() {
    if (!mounted) return;

    // إذا حدث الحجز أثناء وجود طلب جارٍ، لا نهمل التحديث.
    // نؤجله ليعمل فور انتهاء الطلب الحالي.
    if (isRefreshing) return;

    // التغيير المحلي موجود في كاش ApiService، لذلك لا نعيد طلب الشبكة.
    loadAppointments(
      showSmallLoading: false,
      forceRefresh: false,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();

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
    if (isRefreshing) {
      return;
    }

    final requestVersion = ++_requestVersion;
    final requestUserId = UserSession.userId;

    if (requestUserId == null || requestUserId <= 0) {
      if (!mounted) return;

      setState(() {
        allAppointments = [];
        _appointmentsOwnerUserId = null;
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
          _appointmentsOwnerUserId = null;
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
      );

      if (!mounted ||
          requestVersion != _requestVersion ||
          requestUserId != UserSession.userId) {
        return;
      }

      final loadedAppointments = List<dynamic>.from(data);

      setState(() {
        allAppointments = loadedAppointments;
        _invalidateFilteredAppointmentsCache();
        _appointmentsOwnerUserId = requestUserId;
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

  void _invalidateFilteredAppointmentsCache() {
    _filteredAppointmentsCache = null;
    _filteredAppointmentsSource = null;
    _filteredAppointmentsTab = null;
    _filteredAppointmentsQuery = null;
  }

  void _runQueuedAppointmentsReload() {}

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
    final monthName =
    AppStrings.isArabic ? _monthsAr[d.month - 1] : _monthsEn[d.month - 1];

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
        .replaceAll(_spacesRegex, ' ');
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

  String normalizeSearchText(dynamic value) {
    var text = value?.toString().trim().toLowerCase() ?? '';

    const replacements = <String, String>{
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ة': 'ه',
      'ى': 'ي',
      'ؤ': 'و',
      'ئ': 'ي',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    return text
        .replaceAll(_arabicMarksRegex, '')
        .replaceAll(_spacesRegex, ' ')
        .trim();
  }

  String doctorNameOf(dynamic appointment) {
    final direct = valueOf(
      appointment,
      ['doctorName', 'DoctorName', 'fullName', 'FullName'],
      '',
    );

    if (direct.isNotEmpty) return direct;

    final doctor = appointment is Map
        ? appointment['doctor'] ?? appointment['Doctor']
        : null;

    return valueOf(
      doctor,
      ['fullName', 'FullName', 'name', 'Name'],
      AppStrings.doctor,
    );
  }

  String firstNameOf(String fullName) {
    final cleanName = fullName.trim().replaceAll(_spacesRegex, ' ');
    if (cleanName.isEmpty) return '';

    final parts = cleanName
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';

    const doctorTitles = <String>{
      'dr',
      'doctor',
      'د',
      'دكتور',
      'دكتوره',
      'الدكتور',
      'الدكتوره',
    };

    for (final part in parts) {
      final normalizedPart = normalizeSearchText(
        part.replaceAll(_doctorTitlePunctuationRegex, ''),
      );

      if (!doctorTitles.contains(normalizedPart)) {
        return part;
      }
    }

    return parts.first;
  }

  bool matchesSearch(dynamic appointment) {
    final query = normalizeSearchText(searchQuery);
    if (query.isEmpty) return true;

    final appointmentNumber = valueOf(
      appointment,
      ['appointmentId', 'AppointmentId', 'id', 'Id'],
      '',
    );

    final rawDoctorName = doctorNameOf(appointment);
    final translatedDoctorName =
    AppStrings.doctorNameByLanguage(rawDoctorName);

    final rawFirstName = normalizeSearchText(firstNameOf(rawDoctorName));
    final translatedFirstName =
    normalizeSearchText(firstNameOf(translatedDoctorName));
    final normalizedNumber = normalizeSearchText(appointmentNumber);

    return rawFirstName.contains(query) ||
        translatedFirstName.contains(query) ||
        normalizedNumber.contains(query);
  }

  List<dynamic> filteredAppointments(List<dynamic> appointments) {
    if (identical(_filteredAppointmentsSource, appointments) &&
        _filteredAppointmentsTab == showUpcoming &&
        _filteredAppointmentsQuery == searchQuery &&
        _filteredAppointmentsCache != null) {
      return _filteredAppointmentsCache!;
    }

    final filtered = appointments.where((appointment) {
      final status = normalizedStatus(appointment);
      final matchesTab =
      showUpcoming ? !isPastStatus(status) : isPastStatus(status);

      return matchesTab && matchesSearch(appointment);
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

    _filteredAppointmentsSource = appointments;
    _filteredAppointmentsTab = showUpcoming;
    _filteredAppointmentsQuery = searchQuery;
    _filteredAppointmentsCache = filtered;

    return filtered;
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;

      final normalizedValue = value.trim();
      if (searchQuery == normalizedValue) return;

      setState(() {
        searchQuery = normalizedValue;
        _invalidateFilteredAppointmentsCache();
      });
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();

    if (searchQuery.isEmpty) return;

    setState(() {
      searchQuery = '';
      _invalidateFilteredAppointmentsCache();
    });
  }

  Widget buildSearchField() {
    const primary = Color(0xFF5B2EFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        textDirection:
        AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: AppStrings.isArabic
              ? 'ابحث بأول اسم للطبيب أو رقم الملف'
              : 'Search doctor first name or file number',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: primary,
          ),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
            onPressed: clearSearch,
            icon: const Icon(
              Icons.close,
              color: Colors.grey,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
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
      _invalidateFilteredAppointmentsCache();
    });

  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);
    final currentUserId = UserSession.userId;

    // توحيد عرض الصفحة على Chrome مع بقاء الموبايل بعرضه الطبيعي.
    final screenWidth = MediaQuery.sizeOf(context).width;
    const double webContentMaxWidth = 520;
    final double visibleContentWidth =
    screenWidth > webContentMaxWidth ? webContentMaxWidth : screenWidth;
    final double floatingButtonSideSpace =
    ((screenWidth - visibleContentWidth) / 2).clamp(0.0, double.infinity);
    final ownsVisibleData =
        currentUserId != null && _appointmentsOwnerUserId == currentUserId;

    // حماية من ظهور بيانات حساب سابق ولو للحظة.
    final safeAppointments =
    ownsVisibleData ? allAppointments : const <dynamic>[];
    final appointments = filteredAppointments(safeAppointments);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: webContentMaxWidth,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                        sliver: SliverToBoxAdapter(
                          child: buildSearchField(),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverToBoxAdapter(
                          child: Container(
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
                                    title: AppStrings.isArabic
                                        ? 'القادمة'
                                        : 'Upcoming',
                                    selected: showUpcoming,
                                    onTap: () {
                                      if (!showUpcoming) {
                                        setState(() {
                                          showUpcoming = true;
                                          _invalidateFilteredAppointmentsCache();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: tabButton(
                                    title:
                                    AppStrings.isArabic ? 'السابقة' : 'Past',
                                    selected: !showUpcoming,
                                    onTap: () {
                                      if (showUpcoming) {
                                        setState(() {
                                          showUpcoming = false;
                                          _invalidateFilteredAppointmentsCache();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                      if (appointments.isEmpty && firstLoadDone)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Center(
                              child: Text(AppStrings.noAppointmentsFound),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final appointment = appointments[index];
                                final doctorId = int.tryParse(
                                  valueOf(
                                    appointment,
                                    ['doctorId', 'DoctorId'],
                                    '0',
                                  ),
                                ) ??
                                    0;
                                final appointmentId = int.tryParse(
                                  valueOf(
                                    appointment,
                                    ['appointmentId', 'AppointmentId'],
                                    '0',
                                  ),
                                ) ??
                                    0;
                                final dateValue = valueOf(
                                  appointment,
                                  ['appointmentDate', 'AppointmentDate'],
                                  '',
                                );

                                return AppointmentCard(
                                  key: ValueKey(appointmentId),
                                  appointment: appointment
                                  is Map<String, dynamic>
                                      ? appointment
                                      : Map<String, dynamic>.from(
                                    appointment,
                                  ),
                                  doctorId: doctorId,
                                  date: formatDate(dateValue),
                                  time: formatTime(dateValue),
                                  onDeleted: () =>
                                      removeAppointmentLocal(appointmentId),
                                );
                              },
                              childCount: appointments.length,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 90),
                      ),
                    ],
                  ),

                  if (isRefreshing)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                          ),
                        ),
                      ),
                    ),

                  if (errorMessage != null &&
                      safeAppointments.isEmpty &&
                      firstLoadDone)
                    Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsetsDirectional.only(
            end: floatingButtonSideSpace,
          ),
          child: FloatingActionButton(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            onPressed: () async {
              final booked = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookAppointmentScreen(),
                ),
              );

              if (!mounted) return;

              // الموعد أضيف إلى كاش ApiService فور نجاح الحجز.
              // نعرضه مباشرة بدون انتظار الداشبورد أو البروفايل أو طلب GET جديد.
              if (booked == true) {
                await loadAppointments(
                  showSmallLoading: false,
                  forceRefresh: false,
                );
              }
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const primary = Color(0xFF5B2EFF);

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
        return Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEDE7FF),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            base64Decode(base64Part),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
          ),
        );
      } catch (_) {
        return defaultDoctorImage();
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          image,
          key: ValueKey<String>(image),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return defaultDoctorImage();
          },
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          image,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    return defaultDoctorImage();
  }

  Widget defaultDoctorImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEDE7FF),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/profile.jpg',
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
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
    const primary = Color(0xFF5B2EFF);

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
                      try {
                        await ApiService.deleteAppointment(appointmentId);

                        onDeleted();

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.appointmentDeleted),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.isArabic
                                  ? 'تعذر حذف الموعد، حاولي مرة أخرى.'
                                  : 'Could not delete the appointment. Please try again.',
                            ),
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


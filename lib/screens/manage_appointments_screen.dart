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

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void loadAppointments() {
    appointmentsFuture = ApiService.getAppointments();
  }

  void refreshAppointments() {
    setState(() {
      loadAppointments();
    });
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

      if (!mounted) return;

      refreshAppointments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.appointmentMarkedAs} $status',
          ),
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

  String valueOf(
      dynamic source,
      List<String> keys, [
        String fallback = '',
      ]) {
    if (source is! Map) return fallback;

    for (final key in keys) {
      final value = source[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  String doctorNameOf(dynamic appointment) {
    final directName = valueOf(
      appointment,
      [
        'doctorName',
        'DoctorName',
      ],
    );

    if (directName.isNotEmpty) {
      return directName;
    }

    if (appointment is Map) {
      final doctor =
          appointment['doctor'] ?? appointment['Doctor'];

      final nestedName = valueOf(
        doctor,
        [
          'fullName',
          'FullName',
          'name',
          'Name',
        ],
      );

      if (nestedName.isNotEmpty) {
        return nestedName;
      }
    }

    final doctorId = valueOf(
      appointment,
      [
        'doctorId',
        'DoctorId',
      ],
    );

    return doctorId.isEmpty
        ? AppStrings.noName
        : '${AppStrings.doctorId}: $doctorId';
  }

  String appointmentIdOf(dynamic appointment) {
    return valueOf(
      appointment,
      [
        'appointmentId',
        'AppointmentId',
        'id',
        'Id',
      ],
      '0',
    );
  }

  String normalizeSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  String firstDoctorName(String name) {
    String cleaned = normalizeSearch(name);

    cleaned = cleaned
        .replaceFirst(RegExp(r'^dr\.?\s*'), '')
        .replaceFirst(RegExp(r'^doctor\s+'), '')
        .replaceFirst(RegExp(r'^د\.?\s*'), '')
        .replaceFirst(RegExp(r'^دكتور\s+'), '')
        .trim();

    if (cleaned.isEmpty) {
      return '';
    }

    return cleaned.split(RegExp(r'\s+')).first;
  }

  bool matchesSearch(dynamic appointment) {
    final query = normalizeSearch(searchQuery);

    if (query.isEmpty) {
      return true;
    }

    final appointmentId = appointmentIdOf(appointment);

    if (RegExp(r'^\d+$').hasMatch(query)) {
      return appointmentId.startsWith(query);
    }

    final doctorName = doctorNameOf(appointment);

    final translatedDoctorName =
    AppStrings.doctorNameByLanguage(doctorName);

    final firstName = firstDoctorName(doctorName);
    final translatedFirstName =
    firstDoctorName(translatedDoctorName);

    return firstName.startsWith(query) ||
        translatedFirstName.startsWith(query);
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
    if (!AppStrings.isArabic) {
      return status;
    }

    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'مؤكد';

      case 'completed':
        return 'مكتمل';

      case 'cancelled':
        return 'ملغي';

      default:
        return 'قيد الانتظار';
    }
  }

  Widget buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value.trim();
          });
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppStrings.isArabic
              ? 'ابحث باسم الدكتور الأول أو رقم الموعد'
              : 'Search by doctor first name or appointment ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
            onPressed: () {
              searchController.clear();

              setState(() {
                searchQuery = '';
              });
            },
            icon: const Icon(Icons.close),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection:
      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
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

            final visibleAppointments = appointments
                .where(matchesSearch)
                .toList();

            return Column(
              children: [
                buildSearchField(),
                Expanded(
                  child: appointments.isEmpty
                      ? Center(
                    child: Text(
                      AppStrings.noAppointmentsFound,
                    ),
                  )
                      : visibleAppointments.isEmpty
                      ? Center(
                    child: Text(
                      AppStrings.isArabic
                          ? 'لا توجد نتائج مطابقة'
                          : 'No matching appointments',
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount:
                    visibleAppointments.length,
                    itemBuilder: (context, index) {
                      final dynamic rawAppointment =
                      visibleAppointments[index];

                      if (rawAppointment is! Map) {
                        return const SizedBox.shrink();
                      }

                      final appointment =
                      Map<String, dynamic>.from(
                        rawAppointment,
                      );

                      final status = valueOf(
                        appointment,
                        ['status', 'Status'],
                        'Pending',
                      );

                      final appointmentId =
                      appointmentIdOf(
                        appointment,
                      );

                      final doctorName =
                      doctorNameOf(appointment);

                      final appointmentDate = valueOf(
                        appointment,
                        [
                          'appointmentDate',
                          'AppointmentDate',
                        ],
                      );

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 16,
                        ),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          AppStrings.isArabic
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              textDirection:
                              AppStrings.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                  Color(0xffEDE7FF),
                                  child: Icon(
                                    Icons.calendar_month,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    AppStrings.isArabic
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment:
                                        AppStrings.isArabic
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Text(
                                          AppStrings.isArabic
                                              ? 'موعد رقم $appointmentId'
                                              : '${AppStrings.appointment} #$appointmentId',
                                          textAlign:
                                          AppStrings.isArabic
                                              ? TextAlign.right
                                              : TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Row(
                                        textDirection:
                                        AppStrings.isArabic
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              AppStrings
                                                  .doctorNameByLanguage(
                                                doctorName,
                                              ),
                                              textAlign:
                                              AppStrings.isArabic
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                              overflow:
                                              TextOverflow.ellipsis,
                                              style:
                                              const TextStyle(
                                                color:
                                                Colors.black87,
                                                fontWeight:
                                                FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            statusByLanguage(
                                              status,
                                            ),
                                            textAlign:
                                            AppStrings.isArabic
                                                ? TextAlign.left
                                                : TextAlign.right,
                                            style: TextStyle(
                                              color:
                                              statusColor(status),
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Align(
                                        alignment:
                                        AppStrings.isArabic
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Text(
                                          appointmentDate,
                                          textAlign:
                                          AppStrings.isArabic
                                              ? TextAlign.right
                                              : TextAlign.left,
                                          style:
                                          const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              textDirection:
                              AppStrings.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              children: [
                                Expanded(
                                  child: statusButton(
                                    title:
                                    AppStrings.confirm,
                                    color: Colors.green,
                                    onTap: () {
                                      updateStatus(
                                        appointment,
                                        'Confirmed',
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: statusButton(
                                    title:
                                    AppStrings.complete,
                                    color: Colors.blue,
                                    onTap: () {
                                      updateStatus(
                                        appointment,
                                        'Completed',
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: statusButton(
                                    title: AppStrings
                                        .cancelAppointment,
                                    color: Colors.red,
                                    onTap: () {
                                      updateStatus(
                                        appointment,
                                        'Cancelled',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
          padding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
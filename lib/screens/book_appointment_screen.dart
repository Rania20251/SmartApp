import 'package:flutter/material.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const Color primary = Color(0xFF5B2EFF);

  int? selectedDoctorId;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;
  late Future<List<dynamic>> doctorsFuture;

  @override
  void initState() {
    super.initState();
    doctorsFuture = ApiService.getDoctors(forceRefresh: true);
  }

  int doctorIdOf(dynamic doctor) {
    if (doctor is! Map) return 0;

    final rawId =
        doctor['doctorId'] ??
            doctor['DoctorId'] ??
            doctor['id'] ??
            doctor['Id'];

    return rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  String valueOf(dynamic source, List<String> keys, String fallback) {
    if (source is! Map) return fallback;

    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: firstDate.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: DateTime(2030, 12, 31),
    );

    if (date != null && mounted) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null && mounted) {
      setState(() => selectedTime = time);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  DateTime finalAppointmentDate() {
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  String formattedDate() {
    if (selectedDate == null) return AppStrings.selectDate;

    return '${selectedDate!.year}-'
        '${selectedDate!.month.toString().padLeft(2, '0')}-'
        '${selectedDate!.day.toString().padLeft(2, '0')}';
  }

  Future<void> submitAppointment() async {
    if (isLoading) return;

    final patientId = UserSession.userId ?? 0;
    final doctorId = selectedDoctorId ?? 0;

    if (patientId <= 0) {
      showMessage(
        AppStrings.isArabic
            ? 'يرجى تسجيل الدخول أولاً.'
            : 'Please sign in first.',
      );
      return;
    }

    if (doctorId <= 0) {
      showMessage(AppStrings.pleaseSelectDoctor);
      return;
    }

    if (selectedDate == null) {
      showMessage(AppStrings.pleaseSelectDate);
      return;
    }

    if (selectedTime == null) {
      showMessage(AppStrings.pleaseSelectTime);
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.bookAppointment(
        patientId: patientId,
        doctorId: doctorId,
        appointmentDate: finalAppointmentDate(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on AppointmentSlotTakenException {
      showMessage(
        AppStrings.isArabic
            ? 'هذا الموعد غير متاح، اختاري وقتاً آخر.'
            : 'This appointment is unavailable. Choose another time.',
      );
    } catch (_) {
      showMessage(
        AppStrings.isArabic
            ? 'تعذر حجز الموعد، حاولي مرة أخرى.'
            : 'Could not book the appointment. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.bookAppointment),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: FutureBuilder<List<dynamic>>(
          future: doctorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primary),
              );
            }

            final doctors = (snapshot.data ?? <dynamic>[])
                .where((doctor) => doctorIdOf(doctor) > 0)
                .toList();

            if (doctors.isEmpty) {
              return Center(child: Text(AppStrings.noDoctorsFound));
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: 390,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: AppStrings.isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.bookAppointment,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<int>(
                        value: selectedDoctorId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: AppStrings.selectDoctor,
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: doctors.map<DropdownMenuItem<int>>((doctor) {
                          final id = doctorIdOf(doctor);
                          final name = valueOf(
                            doctor,
                            ['fullName', 'FullName', 'name', 'Name'],
                            AppStrings.doctor,
                          );
                          final specialty = valueOf(
                            doctor,
                            [
                              'specialty',
                              'Specialty',
                              'specialtyName',
                              'SpecialtyName',
                            ],
                            AppStrings.specialist,
                          );

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${AppStrings.doctorNameByLanguage(name)} - '
                                  '${AppStrings.specialtyByLanguage(specialty)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                          setState(() => selectedDoctorId = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: isLoading ? null : pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month),
                              const SizedBox(width: 12),
                              Text(formattedDate()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: isLoading ? null : pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 12),
                              Text(
                                selectedTime == null
                                    ? AppStrings.selectTime
                                    : selectedTime!.format(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submitAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            AppStrings.bookNow,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

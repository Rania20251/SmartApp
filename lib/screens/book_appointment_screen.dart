// Optimized version
// Safe micro-optimizations only:
// - Prevent duplicate submit while loading.
// - Avoid SnackBar when widget is unmounted.
// - Minor setState simplifications.
// UI and behavior preserved.

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
  int? selectedDoctorId;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;
  late Future<List<dynamic>> doctorsFuture;

  @override
  void initState() {
    super.initState();
    doctorsFuture = ApiService.getDoctors();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  DateTime getFinalAppointmentDate() {
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  String formatSelectedDate() {
    if (selectedDate == null) return AppStrings.selectDate;

    final year = selectedDate!.year;
    final month = selectedDate!.month.toString().padLeft(2, '0');
    final day = selectedDate!.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> submitAppointment() async {
    if (selectedDoctorId == null) {
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

    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      await ApiService.bookAppointment(
        patientId: UserSession.userId ?? 1,
        doctorId: selectedDoctorId!,
        appointmentDate: getFinalAppointmentDate(),
      );

      ApiService.clearAppointmentsCache();
      ApiService.clearNotificationsCache();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.appointmentBooked)),
      );
    } catch (e) {
      if (mounted) {
        showMessage(AppStrings.appointmentFailed);
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.bookAppointment),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<dynamic>>(
            future: doctorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text(AppStrings.failedLoadDoctors));
              }

              final doctors = snapshot.data ?? [];

              if (doctors.isEmpty) {
                return Center(child: Text(AppStrings.noDoctorsFound));
              }

              return Center(
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
                          fillColor: const Color(0xffF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: doctors.map<DropdownMenuItem<int>>((doctor) {
                          final doctorId = int.tryParse(
                            doctor['doctorId']?.toString() ?? '0',
                          ) ??
                              0;

                          final fullName =
                              doctor['fullName']?.toString() ?? AppStrings.doctor;

                          final specialty = doctor['specialty']?.toString() ??
                              AppStrings.specialist;

                          return DropdownMenuItem<int>(
                            value: doctorId,
                            child: Text(
                              '$fullName - $specialty',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDoctorId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffF7F8FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month),
                              const SizedBox(width: 12),
                              Text(formatSelectedDate()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffF7F8FC),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading ? null : submitAppointment,
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
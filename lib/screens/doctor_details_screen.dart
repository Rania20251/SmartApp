import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final int doctorId;
  final String name;
  final String specialty;
  final String rating;
  final String time;
  final String imagePath;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.time,
    required this.imagePath,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  int selectedDay = 1;
  int selectedTime = 1;
  bool isFavorite = false;
  bool isBooked = false;

  final List<String> times = ['09:00 AM', '10:30 AM', '12:00 PM'];

  @override
  void initState() {
    super.initState();
    loadFavorite();
  }

  String get favoriteKey =>
      'favorite_doctor_${UserSession.userId ?? 0}_${widget.doctorId}';

  List<DateTime> get availableDates {
    final today = DateTime.now();
    return List.generate(5, (index) {
      final date = today.add(Duration(days: index + 1));
      return DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      isFavorite = prefs.getBool(favoriteKey) ?? false;
    });
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !isFavorite;

    await prefs.setBool(favoriteKey, newValue);

    if (!mounted) return;

    setState(() {
      isFavorite = newValue;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newValue
              ? (AppStrings.isArabic
              ? 'تمت إضافة الطبيب إلى المفضلة'
              : 'Doctor added to favorites')
              : (AppStrings.isArabic
              ? 'تمت إزالة الطبيب من المفضلة'
              : 'Doctor removed from favorites'),
        ),
      ),
    );
  }

  String get safeImagePath {
    final image = widget.imagePath.trim();

    if (image.isEmpty || image == 'string') {
      return 'assets/images/profile.jpg';
    }

    return ApiService.fixImageUrl(image);
  }

  String translateDoctorName(String name) {
    if (!AppStrings.isArabic) return name;

    final value = name.toLowerCase().trim();

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

  String translateSpecialty(String specialty) {
    final value = specialty.toLowerCase().trim();

    if (!AppStrings.isArabic) return specialty;

    if (value.contains('cardiology') ||
        value.contains('heart') ||
        value.contains('قلب')) {
      return 'القلب';
    }

    if (value.contains('dentistry') ||
        value.contains('dental') ||
        value.contains('أسنان') ||
        value.contains('اسنان')) {
      return 'الأسنان';
    }

    if (value.contains('neurology') ||
        value.contains('neuro') ||
        value.contains('أعصاب') ||
        value.contains('اعصاب')) {
      return 'الأعصاب';
    }

    if (value.contains('pediatrics') ||
        value.contains('pedia') ||
        value.contains('child') ||
        value.contains('أطفال') ||
        value.contains('اطفال')) {
      return 'الأطفال';
    }

    if (value.contains('dermatology') ||
        value.contains('derma') ||
        value.contains('جلدية')) {
      return 'الجلدية';
    }

    if (value.contains('ophthalmology') ||
        value.contains('eye') ||
        value.contains('عيون')) {
      return 'العيون';
    }

    if (value.contains('surgery') || value.contains('جراحة')) {
      return 'الجراحة';
    }

    return specialty;
  }

  String dayName(DateTime date) {
    final daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final daysAr = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];

    return AppStrings.isArabic ? daysAr[date.weekday - 1] : daysEn[date.weekday - 1];
  }

  DateTime selectedAppointmentDateTime() {
    final date = availableDates[selectedDay];
    final selectedTimeText = times[selectedTime];

    final parts = selectedTimeText.split(' ');
    final hm = parts.first.split(':');

    int hour = int.tryParse(hm.first) ?? 9;
    final minute = int.tryParse(hm.last) ?? 0;
    final period = parts.length > 1 ? parts.last.toUpperCase() : 'AM';

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Widget doctorImage() {
    final image = safeImagePath;

    if (image.startsWith('data:image')) {
      try {
        final base64Part = image.split(',').last;

        return ClipOval(
          child: Image.memory(
            base64Decode(base64Part),
            width: 96,
            height: 96,
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
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          image,
          width: 96,
          height: 96,
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
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      ),
    );
  }

  String aboutDoctor() {
    final specialty = translateSpecialty(widget.specialty);

    if (AppStrings.isArabic) {
      return 'استشاري متخصص بخبرة عالية في مجال $specialty. يقدم رعاية طبية دقيقة ويساعد المرضى على اختيار العلاج المناسب.';
    }

    return 'An experienced specialist in ${widget.specialty}. Provides accurate medical care and helps patients choose the right treatment plan.';
  }

  Future<void> bookAppointment() async {
    try {
      final appointmentDate = selectedAppointmentDateTime();

      await ApiService.bookAppointment(
        patientId: UserSession.userId ?? 1,
        doctorId: widget.doctorId,
        appointmentDate: appointmentDate,
      );

      if (!mounted) return;

      setState(() {
        isBooked = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.appointmentBooked)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.appointmentFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    final shownName = translateDoctorName(widget.name);
    final shownSpecialty = translateSpecialty(widget.specialty);
    final dates = availableDates;

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.doctorDetails),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: AppStrings.isArabic ? 'المفضلة' : 'Favorite',
              onPressed: toggleFavorite,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey<bool>(isFavorite),
                  color: isFavorite ? Colors.red : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: doctorImage(),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: AppStrings.isArabic
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          shownName,
                          textAlign: AppStrings.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          shownSpecialty,
                          textAlign: AppStrings.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: AppStrings.isArabic
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 18),
                            Text(' ${widget.rating}'),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.isArabic ? '(120 تقييم)' : '(120 reviews)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isBooked) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.isArabic
                            ? 'تم حجز الموعد وسيظهر في قائمة مواعيدي'
                            : 'Appointment booked and will appear in My Appointments',
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              AppStrings.isArabic ? 'عن الطبيب' : 'About Doctor',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              aboutDoctor(),
              style: const TextStyle(
                color: Colors.grey,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.isArabic ? 'الأوقات المتاحة' : 'Available Times',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(dates.length, (index) {
                final selected = selectedDay == index;
                final date = dates[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() {
                    selectedDay = index;
                    isBooked = false;
                  }),
                  child: Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName(date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          date.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(times.length, (index) {
                final selected = selectedTime == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    selectedTime = index;
                    isBooked = false;
                  }),
                  child: Container(
                    width: 100,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      times[index],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 34),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBooked ? Colors.green : primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(isBooked ? Icons.check_circle : Icons.calendar_month),
                label: Text(
                  isBooked
                      ? (AppStrings.isArabic ? 'تم الحجز' : 'Booked')
                      : AppStrings.bookAppointment,
                  style: const TextStyle(fontSize: 17),
                ),
                onPressed: bookAppointment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

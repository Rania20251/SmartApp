import 'dart:convert';
import 'dart:typed_data';

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
  static const Color primary = Color(0xFF5B2EFF);
  static const List<String> times = ['09:00 AM', '10:30 AM', '12:00 PM'];

  int selectedDay = 1;
  int selectedTime = 1;
  bool isFavorite = false;
  bool isBooked = false;
  bool isBooking = false;
  int userRating = 0;

  late final List<DateTime> dates;
  late final String shownName;
  late final String shownSpecialty;
  late final String safeImage;
  late final String aboutText;
  Uint8List? imageBytes;

  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    dates = List.generate(5, (index) {
      final date = today.add(Duration(days: index + 1));
      return DateTime(date.year, date.month, date.day);
    });

    shownName = translateDoctorName(widget.name);
    shownSpecialty = translateSpecialty(widget.specialty);
    safeImage = getSafeImagePath(widget.imagePath);
    aboutText = aboutDoctor();

    if (safeImage.startsWith('data:image')) {
      try {
        imageBytes = base64Decode(safeImage.split(',').last);
      } catch (_) {
        imageBytes = null;
      }
    }

    loadFavorite();
  }

  String get favoriteKey =>
      'favorite_doctor_${UserSession.userId ?? 0}_${widget.doctorId}';

  String get ratingKey =>
      'doctor_rating_${UserSession.userId ?? 0}_${widget.doctorId}';

  Future<void> loadFavorite() async {
    prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      isFavorite = prefs?.getBool(favoriteKey) ?? false;
      userRating = prefs?.getInt(ratingKey) ?? 0;
    });
  }

  Future<void> showRatingDialog() async {
    var selectedRating = userRating;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                AppStrings.isArabic
                    ? 'قيّم الطبيب'
                    : 'Rate this doctor',
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.isArabic
                        ? 'اختر عدد النجوم'
                        : 'Choose the number of stars',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final selected = star <= selectedRating;

                        return IconButton(
                          tooltip: '$star',
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = star;
                            });
                          },
                          icon: Icon(
                            selected ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 34,
                          ),
                        );
                      }),
                    ),
                  ),
                  if (selectedRating > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$selectedRating / 5',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    AppStrings.isArabic ? 'إلغاء' : 'Cancel',
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: selectedRating == 0
                      ? null
                      : () => Navigator.pop(
                    dialogContext,
                    selectedRating,
                  ),
                  child: Text(
                    AppStrings.isArabic ? 'إرسال التقييم' : 'Submit',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    prefs ??= await SharedPreferences.getInstance();
    await prefs!.setInt(ratingKey, result);

    if (!mounted) return;
    setState(() => userRating = result);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.isArabic
              ? 'شكراً، تم حفظ تقييمك'
              : 'Thank you. Your rating was saved.',
        ),
      ),
    );
  }

  Widget ratingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E4FF)),
      ),
      child: Row(
        textDirection:
        AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF3DD),
            ),
            child: const Icon(Icons.star, color: Colors.orange, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: AppStrings.isArabic
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.isArabic ? 'تقييمك للطبيب' : 'Your rating',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < userRating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 19,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: showRatingDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              userRating == 0
                  ? (AppStrings.isArabic ? 'قيّم' : 'Rate')
                  : (AppStrings.isArabic ? 'تعديل' : 'Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> toggleFavorite() async {
    prefs ??= await SharedPreferences.getInstance();

    final newValue = !isFavorite;
    await prefs!.setBool(favoriteKey, newValue);

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

  String getSafeImagePath(String path) {
    final image = path.trim();

    if (image.isEmpty || image == 'string') {
      return 'assets/images/profile.jpg';
    }

    final fixedImage = ApiService.fixImageUrl(image).trim();

    if (fixedImage.isEmpty || fixedImage == 'string') {
      return 'assets/images/profile.jpg';
    }

    return fixedImage;
  }

  String translateDoctorName(String name) {
    return AppStrings.doctorNameByLanguage(name);
  }

  String translateSpecialty(String specialty) {
    return AppStrings.specialtyByLanguage(specialty);
  }

  String dayName(DateTime date) {
    const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysAr = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];

    return AppStrings.isArabic
        ? daysAr[date.weekday - 1]
        : daysEn[date.weekday - 1];
  }

  DateTime selectedAppointmentDateTime() {
    final date = dates[selectedDay];
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
    if (imageBytes != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          imageBytes!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          gaplessPlayback: true,
        ),
      );
    }

    if (safeImage.startsWith('http://') || safeImage.startsWith('https://')) {
      return Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          safeImage,
          key: ValueKey<String>(safeImage),
          width: 96,
          height: 96,
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

    if (safeImage.startsWith('assets/')) {
      return Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          safeImage,
          width: 96,
          height: 96,
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
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEDE7FF),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/profile.jpg',
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
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
    if (isBooking) return;

    final patientId = UserSession.userId ?? 0;

    if (patientId <= 0 || widget.doctorId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isArabic
                ? 'تعذر تحديد المريض أو الطبيب، أعيدي فتح الصفحة.'
                : 'Could not identify the patient or doctor. Reopen the page.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final appointmentDate = selectedAppointmentDateTime();

      await ApiService.bookAppointment(
        patientId: patientId,
        doctorId: widget.doctorId,
        appointmentDate: appointmentDate,
        doctorName: widget.name,
        specialtyName: widget.specialty,
        doctorImage: widget.imagePath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.appointmentBooked)),
      );

      Navigator.pop(context, true);
    } on AppointmentSlotTakenException {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isArabic
                ? 'هذا الموعد غير متاح، اختاري وقتًا آخر.'
                : 'This appointment is unavailable. Please choose another time.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.appointmentFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      textDirection: AppStrings.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: doctorImage(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: AppStrings.isArabic
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  shownName,
                                  textDirection: AppStrings.isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  textAlign: AppStrings.isArabic
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    height: 1.15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
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
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: AppStrings.isArabic
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      Text(' ${widget.rating}'),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppStrings.isArabic
                                            ? '(120 تقييم)'
                                            : '(120 reviews)',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                        textDirection: AppStrings.isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
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
                  const SizedBox(height: 18),
                  ratingCard(),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.isArabic ? 'عن الطبيب' : 'About Doctor',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aboutText,
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
                        onTap: () {
                          if (selectedDay == index && !isBooked) return;

                          setState(() {
                            selectedDay = index;
                            isBooked = false;
                          });
                        },
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
                        onTap: () {
                          if (selectedTime == index && !isBooked) return;

                          setState(() {
                            selectedTime = index;
                            isBooked = false;
                          });
                        },
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
                              fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
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
                      icon: isBooking
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        isBooked
                            ? Icons.check_circle
                            : Icons.calendar_month,
                      ),
                      label: Text(
                        isBooking
                            ? (AppStrings.isArabic
                            ? 'جاري الحجز...'
                            : 'Booking...')
                            : isBooked
                            ? (AppStrings.isArabic
                            ? 'تم الحجز'
                            : 'Booked')
                            : AppStrings.bookAppointment,
                        style: const TextStyle(fontSize: 17),
                      ),
                      onPressed: isBooking ? null : bookAppointment,
                    ),
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

import 'package:flutter/material.dart';
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

  final List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  final List<String> dates = ['16', '17', '18', '19', '20'];
  final List<String> times = ['09:00 AM', '10:30 AM', '12:00 PM'];

  String aboutDoctor() {
    if (AppStrings.isArabic) {
      return 'استشاري متخصص بخبرة عالية في مجال ${widget.specialty}. يقدم رعاية طبية دقيقة ويساعد المرضى على اختيار العلاج المناسب.';
    }

    return 'An experienced specialist in ${widget.specialty}. Provides accurate medical care and helps patients choose the right treatment plan.';
  }

  Future<void> bookAppointment() async {
    try {
      await ApiService.bookAppointment(
        patientId: UserSession.userId ?? 1,
        doctorId: widget.doctorId,
        appointmentDate: DateTime.now().add(
          Duration(days: selectedDay + 1),
        ),
      );

      if (!mounted) return;

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

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.doctorDetails),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [
          Icon(Icons.favorite_border),
          SizedBox(width: 14),
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
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xffEDE7FF),
                  backgroundImage: AssetImage(widget.imagePath),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.specialty,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 18),
                          Text(' ${widget.rating}'),
                          const SizedBox(width: 6),
                          const Text(
                            '(120 reviews)',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            AppStrings.isArabic ? 'عن الطبيب' : 'About Doctor',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (index) {
              final selected = selectedDay == index;

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    selectedDay = index;
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
                        days[index],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dates[index],
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
                  setState(() {
                    selectedTime = index;
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
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.calendar_month),
              label: Text(
                AppStrings.bookAppointment,
                style: const TextStyle(fontSize: 17),
              ),
              onPressed: bookAppointment,
            ),
          ),
        ],
      ),
    );
  }
}
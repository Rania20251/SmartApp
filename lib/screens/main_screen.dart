import 'package:flutter/material.dart';
import '../language/app_strings.dart';

import 'home_screen.dart';
import 'doctors_screen.dart';
import 'schedule_screen.dart';
import 'records_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final screens = const [
    HomeScreen(),
    DoctorsScreen(),
    ScheduleScreen(),
    RecordsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital),
            label: AppStrings.doctors,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month),
            label: AppStrings.appointments,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_services),
            label: AppStrings.medicalRecords,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: AppStrings.notifications,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
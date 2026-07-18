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

  void refreshLanguage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);
    const navigationMaxWidth = 520.0;

    final screens = <Widget>[
      const HomeScreen(),
      const DoctorsScreen(),
      const ScheduleScreen(),
      const RecordsScreen(),
      const NotificationsScreen(),
      ProfileScreen(
        onLanguageChanged: refreshLanguage,
      ),
    ];

    return Directionality(
      textDirection:
      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: screens[currentIndex],
        bottomNavigationBar: Container(
          width: double.infinity,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: navigationMaxWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: BottomNavigationBar(
                    currentIndex: currentIndex,
                    selectedItemColor: primary,
                    unselectedItemColor: Colors.grey,
                    backgroundColor: Colors.white,
                    type: BottomNavigationBarType.fixed,
                    selectedFontSize: 11,
                    unselectedFontSize: 10,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    onTap: (index) {
                      if (currentIndex == index) return;

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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

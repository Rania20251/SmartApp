import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSettings.loadSettings();

  runApp(const SmartClinicApp());
}

class SmartClinicApp extends StatefulWidget {
  const SmartClinicApp({super.key});

  @override
  State<SmartClinicApp> createState() => _SmartClinicAppState();
}

class _SmartClinicAppState extends State<SmartClinicApp> {
  Future<void> changeLanguage(Locale locale) async {
    await AppSettings.changeLanguage(locale);

    setState(() {});
  }

  Future<void> changeTheme(bool value) async {
    await AppSettings.changeTheme(value);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedLink',
      locale: AppSettings.currentLocale,
      themeMode: AppSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}
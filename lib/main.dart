import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SmartClinicApp());

  await AppSettings.loadSettings();
}

class SmartClinicApp extends StatefulWidget {
  const SmartClinicApp({super.key});

  @override
  State<SmartClinicApp> createState() => _SmartClinicAppState();
}

class _SmartClinicAppState extends State<SmartClinicApp> {
  Future<void> changeLanguage(Locale locale) async {
    await AppSettings.changeLanguage(locale);

    if (!mounted) return;

    setState(() {});
  }

  Future<void> changeTheme(bool value) async {
    await AppSettings.changeTheme(value);

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedLink',
      locale: AppSettings.currentLocale,
      themeMode:
      AppSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const SplashScreen(),
    );
  }
}
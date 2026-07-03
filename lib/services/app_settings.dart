import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static Locale currentLocale = const Locale('en');
  static bool isDarkMode = false;

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final language = prefs.getString('language') ?? 'en';
    final dark = prefs.getBool('darkMode') ?? false;

    currentLocale = Locale(language);
    isDarkMode = dark;
  }

  static Future<void> changeLanguage(Locale locale) async {
    currentLocale = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  static Future<void> changeTheme(bool value) async {
    isDarkMode = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String key = 'notifications';

  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final oldData = prefs.getStringList(key) ?? [];

    final notification = {
      "title": title,
      "message": message,
      "type": type,
      "date": DateTime.now().toString(),
    };

    oldData.insert(0, jsonEncode(notification));

    await prefs.setStringList(key, oldData);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(key) ?? [];

    return data.map((item) {
      return jsonDecode(item) as Map<String, dynamic>;
    }).toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
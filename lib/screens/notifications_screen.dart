import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<dynamic>> notificationsFuture;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  void loadNotifications() {
    notificationsFuture =
        ApiService.getNotificationsByUser(UserSession.userId ?? 0);
  }

  void refreshNotifications() {
    ApiService.clearNotificationsCache();

    setState(() {
      loadNotifications();
    });
  }

  Future<void> deleteNotification(int notificationId) async {
    await ApiService.deleteNotification(notificationId);

    ApiService.clearNotificationsCache();

    refreshNotifications();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.notificationDeleted)),
    );
  }

  IconData getIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('appointment')) {
      return Icons.calendar_month;
    }

    if (lowerTitle.contains('medical')) {
      return Icons.description;
    }

    if (lowerTitle.contains('deleted')) {
      return Icons.delete;
    }

    return Icons.notifications;
  }

  Color getColor(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('booked')) {
      return const Color(0xff5B2EFF);
    }

    if (lowerTitle.contains('updated')) {
      return Colors.green;
    }

    if (lowerTitle.contains('deleted')) {
      return Colors.red;
    }

    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.notifications),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshNotifications,
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppStrings.failedLoadNotifications,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Text(AppStrings.noNotificationsYet),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];

                final notificationId = int.tryParse(
                  item['notificationId']?.toString() ?? '0',
                ) ??
                    0;

                final title = item['title']?.toString() ?? '';
                final message = item['message']?.toString() ?? '';
                final createdAt = item['createdAt']?.toString() ?? '';

                return notificationCard(
                  icon: getIcon(title),
                  color: getColor(title),
                  title: title,
                  subtitle: message,
                  date: createdAt,
                  onDelete: () {
                    deleteNotification(notificationId);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget notificationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String date,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: AppStrings.isArabic
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? AppStrings.notification : title,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    textAlign: AppStrings.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
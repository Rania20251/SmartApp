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

  String translateNotificationTitle(String title) {
    if (!AppStrings.isArabic) return title.isEmpty ? AppStrings.notification : title;

    final value = title.toLowerCase().trim();

    if (value.contains('appointment') && value.contains('book')) {
      return 'تم حجز موعد';
    }

    if (value.contains('appointment') && value.contains('confirm')) {
      return 'تم تأكيد الموعد';
    }

    if (value.contains('appointment') && value.contains('complete')) {
      return 'تم إكمال الموعد';
    }

    if (value.contains('appointment') && value.contains('cancel')) {
      return 'تم إلغاء الموعد';
    }

    if (value.contains('appointment') && value.contains('update')) {
      return 'تم تحديث الموعد';
    }

    if (value.contains('medical')) {
      return 'السجل الطبي';
    }

    if (value.contains('deleted')) {
      return 'تم الحذف';
    }

    if (title.trim().isEmpty) return AppStrings.notification;

    return title
        .replaceAll(RegExp(r'Appointment', caseSensitive: false), 'الموعد')
        .replaceAll(RegExp(r'Booked', caseSensitive: false), 'تم حجزه')
        .replaceAll(RegExp(r'Updated', caseSensitive: false), 'تم تحديثه')
        .replaceAll(RegExp(r'Deleted', caseSensitive: false), 'تم حذفه')
        .replaceAll(RegExp(r'Confirmed', caseSensitive: false), 'تم تأكيده')
        .replaceAll(RegExp(r'Completed', caseSensitive: false), 'تم إكماله')
        .replaceAll(RegExp(r'Cancelled', caseSensitive: false), 'تم إلغاؤه')
        .replaceAll(RegExp(r'Medical', caseSensitive: false), 'طبي');
  }

  String translateNotificationMessage(String message) {
    if (!AppStrings.isArabic) return message;

    return message
        .replaceAll(RegExp(r'appointment', caseSensitive: false), 'الموعد')
        .replaceAll(RegExp(r'booked', caseSensitive: false), 'تم حجزه')
        .replaceAll(RegExp(r'updated', caseSensitive: false), 'تم تحديثه')
        .replaceAll(RegExp(r'deleted', caseSensitive: false), 'تم حذفه')
        .replaceAll(RegExp(r'confirmed', caseSensitive: false), 'تم تأكيده')
        .replaceAll(RegExp(r'completed', caseSensitive: false), 'تم إكماله')
        .replaceAll(RegExp(r'cancelled', caseSensitive: false), 'تم إلغاؤه')
        .replaceAll(RegExp(r'Dr\.', caseSensitive: false), 'د.')
        .replaceAll('Ahmad', 'أحمد')
        .replaceAll('Ahmed', 'أحمد')
        .replaceAll('Ali', 'علي')
        .replaceAll('Sarah', 'سارة')
        .replaceAll('Sara', 'سارة')
        .replaceAll('Mohammad', 'محمد')
        .replaceAll('Mohammed', 'محمد');
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

    if (lowerTitle.contains('updated') ||
        lowerTitle.contains('confirmed') ||
        lowerTitle.contains('completed')) {
      return Colors.green;
    }

    if (lowerTitle.contains('deleted') || lowerTitle.contains('cancelled')) {
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
                  item['notificationId']?.toString() ??
                      item['NotificationId']?.toString() ??
                      '0',
                ) ??
                    0;

                final title = item['title']?.toString() ??
                    item['Title']?.toString() ??
                    '';

                final message = item['message']?.toString() ??
                    item['Message']?.toString() ??
                    '';

                final createdAt = item['createdAt']?.toString() ??
                    item['CreatedAt']?.toString() ??
                    '';

                return notificationCard(
                  icon: getIcon(title),
                  color: getColor(title),
                  title: translateNotificationTitle(title),
                  subtitle: translateNotificationMessage(message),
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
        textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? AppStrings.notification : title,
                  textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textDirection:
                  AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: AppStrings.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    textDirection: TextDirection.ltr,
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

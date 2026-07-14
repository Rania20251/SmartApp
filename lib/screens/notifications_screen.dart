import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  List<dynamic> notifications = [];
  final Set<int> deletingNotificationIds = <int>{};

  bool isLoading = true;
  bool isRefreshing = false;
  String? loadError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    ApiService.appointmentsVersion.addListener(_onAppointmentsChanged);

    loadNotifications();
  }

  void _onAppointmentsChanged() {
    if (!mounted || isLoading || isRefreshing) return;

    // عند تأكيد/إكمال/إلغاء أي موعد يتم تحديث الإشعارات مباشرة.
    loadNotifications(showFullLoader: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        !isLoading &&
        !isRefreshing) {
      // عند الرجوع للتطبيق أو للشاشة نجلب أحدث إشعارات من السيرفر.
      loadNotifications(showFullLoader: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ApiService.appointmentsVersion.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  Future<void> loadNotifications({bool showFullLoader = true}) async {
    if (!mounted) return;

    setState(() {
      if (showFullLoader) {
        isLoading = true;
      } else {
        isRefreshing = true;
      }
      loadError = null;
    });

    try {
      ApiService.clearNotificationsCache();

      final result = await ApiService.getNotificationsByUser(
        UserSession.userId ?? 0,
      );

      if (!mounted) return;

      setState(() {
        notifications = List<dynamic>.from(result);
        isLoading = false;
        isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        loadError = AppStrings.failedLoadNotifications;
      });
    }
  }

  Future<void> refreshNotifications() async {
    if (isRefreshing) return;
    await loadNotifications(showFullLoader: false);
  }

  Future<void> deleteNotification(int notificationId) async {
    if (notificationId <= 0 || deletingNotificationIds.contains(notificationId)) {
      return;
    }

    final index = notifications.indexWhere(
          (item) => getNotificationId(item) == notificationId,
    );

    if (index == -1) return;

    final removedNotification = notifications[index];

    setState(() {
      deletingNotificationIds.add(notificationId);
      notifications.removeAt(index);
    });

    try {
      await ApiService.deleteNotification(notificationId);
      ApiService.clearNotificationsCache();

      if (!mounted) return;

      setState(() {
        deletingNotificationIds.remove(notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.notificationDeleted)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        deletingNotificationIds.remove(notificationId);

        final safeIndex = index.clamp(0, notifications.length).toInt();
        notifications.insert(safeIndex, removedNotification);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.failedLoadNotifications)),
      );
    }
  }

  int getNotificationId(dynamic item) {
    return int.tryParse(
      item['notificationId']?.toString() ??
          item['NotificationId']?.toString() ??
          '0',
    ) ??
        0;
  }

  String translateNotificationTitle(String title) {
    if (!AppStrings.isArabic) {
      return title.isEmpty ? AppStrings.notification : title;
    }

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

    if (value.contains('appointment') &&
        (value.contains('cancel') ||
            value.contains('canceled') ||
            value.contains('cancelled'))) {
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
        .replaceAll(RegExp(r'Cancelled|Canceled|Cancel', caseSensitive: false), 'تم إلغاؤه')
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
        .replaceAll(RegExp(r'cancelled|canceled|cancel', caseSensitive: false), 'تم إلغاؤه')
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

    if (lowerTitle.contains('deleted') ||
        lowerTitle.contains('cancelled') ||
        lowerTitle.contains('canceled') ||
        lowerTitle.contains('cancel')) {
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
              icon: isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh),
              onPressed: isRefreshing ? null : refreshNotifications,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SizedBox(
              width: double.infinity,
              child: buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null && notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loadError!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => loadNotifications(),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: refreshNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Center(
                child: Text(AppStrings.noNotificationsYet),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          final notificationId = getNotificationId(item);

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
            isDeleting: deletingNotificationIds.contains(notificationId),
            onDelete: notificationId <= 0
                ? null
                : () => deleteNotification(notificationId),
          );
        },
      ),
    );
  }

  Widget notificationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String date,
    required bool isDeleting,
    required VoidCallback? onDelete,
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
                  textAlign:
                  AppStrings.isArabic ? TextAlign.right : TextAlign.left,
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
                  textAlign:
                  AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    textDirection: TextDirection.ltr,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDeleting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

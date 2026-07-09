import 'dart:convert';

import 'package:flutter/material.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Future<List<dynamic>> usersFuture;

  @override
  void initState() {
    super.initState();
    usersFuture = ApiService.getPatients();
  }

  void refreshUsers() {
    setState(() {
      usersFuture = ApiService.getPatients();
    });
  }

  String translateUserName(String name) {
    if (!AppStrings.isArabic) return name;

    final clean = name.trim();

    if (clean.isEmpty) return AppStrings.noName;

    return clean
        .replaceAll(RegExp(r'\bHana\b', caseSensitive: false), 'هناء')
        .replaceAll(RegExp(r'\bHala\b', caseSensitive: false), 'هالة')
        .replaceAll(RegExp(r'\bRana\b', caseSensitive: false), 'رنا')
        .replaceAll(RegExp(r'\bRania\b', caseSensitive: false), 'رانيا')
        .replaceAll(RegExp(r'\bRamia\b', caseSensitive: false), 'راميا')
        .replaceAll(RegExp(r'\bSalah\b', caseSensitive: false), 'صلاح')
        .replaceAll(RegExp(r'\bSarah\b', caseSensitive: false), 'سارة')
        .replaceAll(RegExp(r'\bSara\b', caseSensitive: false), 'سارة')
        .replaceAll(RegExp(r'\bAhmad\b', caseSensitive: false), 'أحمد')
        .replaceAll(RegExp(r'\bAhmed\b', caseSensitive: false), 'أحمد')
        .replaceAll(RegExp(r'\bAli\b', caseSensitive: false), 'علي')
        .replaceAll(RegExp(r'\bMohammad\b', caseSensitive: false), 'محمد')
        .replaceAll(RegExp(r'\bMohammed\b', caseSensitive: false), 'محمد')
        .replaceAll(RegExp(r'\bOmar\b', caseSensitive: false), 'عمر')
        .replaceAll(RegExp(r'\bNour\b', caseSensitive: false), 'نور')
        .replaceAll(RegExp(r'\bAdnan\b', caseSensitive: false), 'عدنان')
        .replaceAll(RegExp(r'\bOsama\b', caseSensitive: false), 'أسامة')
        .replaceAll(RegExp(r'\bMurad\b', caseSensitive: false), 'مراد')
        .replaceAll(RegExp(r'\bAya\b', caseSensitive: false), 'آية')
        .replaceAll(RegExp(r'\bNoor\b', caseSensitive: false), 'نور')
        .replaceAll(RegExp(r'\bLina\b', caseSensitive: false), 'لينا')
        .replaceAll(RegExp(r'\bYara\b', caseSensitive: false), 'يارا')
        .replaceAll(RegExp(r'\bMona\b', caseSensitive: false), 'منى')
        .replaceAll(RegExp(r'\bHuda\b', caseSensitive: false), 'هدى')
        .replaceAll(RegExp(r'\bKhaled\b', caseSensitive: false), 'خالد')
        .replaceAll(RegExp(r'\bKhalid\b', caseSensitive: false), 'خالد')
        .replaceAll(RegExp(r'\bYousef\b', caseSensitive: false), 'يوسف')
        .replaceAll(RegExp(r'\bYusuf\b', caseSensitive: false), 'يوسف')
        .replaceAll(RegExp(r'\bMariam\b', caseSensitive: false), 'مريم')
        .replaceAll(RegExp(r'\bMaryam\b', caseSensitive: false), 'مريم');
  }

  String getUserImage(dynamic user) {
    final image = user['profileImage']?.toString().trim() ??
        user['ProfileImage']?.toString().trim() ??
        '';

    if (image.isNotEmpty && image != 'string') {
      return ApiService.fixImageUrl(image);
    }

    return 'assets/images/profile.jpg';
  }

  Widget defaultUserImage() {
    const primary = Color(0xff5B2EFF);
    return const CircleAvatar(
      radius: 30,
      backgroundColor: Color(0xffEDE7FF),
      child: Icon(Icons.person, color: primary),
    );
  }

  Widget userImage(String imagePath) {
    final image = imagePath.trim();

    if (image.startsWith('data:image')) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(image.split(',').last),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {}
    }

    if (image.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultUserImage(),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return ClipOval(
        child: Image.asset(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => defaultUserImage(),
        ),
      );
    }

    return defaultUserImage();
  }

  Future<void> deleteUser(int userId) async {
    try {
      await ApiService.deleteUser(userId);
      if (!mounted) return;
      refreshUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.userDeleted)),
      );
    } catch (_) {}
  }

  Future<void> confirmDelete(int userId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(AppStrings.deleteUser),
          content: Text(AppStrings.deleteUserConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppStrings.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await deleteUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.manageUsers),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshUsers,
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppStrings.failedLoadUsers,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return Center(child: Text(AppStrings.noUsersFound));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                final id = int.tryParse(
                  '${user['userId'] ?? user['UserId'] ?? 0}',
                ) ??
                    0;

                final full = translateUserName(
                  '${user['fullName'] ?? user['FullName'] ?? AppStrings.noName}',
                );

                final email =
                    '${user['email'] ?? user['Email'] ?? AppStrings.noEmail}';

                final phone =
                    '${user['phoneNumber'] ?? user['PhoneNumber'] ?? ''}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    textDirection:
                    AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: userImage(getUserImage(user)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              full,
                              textDirection: AppStrings.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              textAlign: AppStrings.isArabic
                                  ? TextAlign.right
                                  : TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              textDirection: TextDirection.ltr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                phone,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${AppStrings.userId}: $id',
                              textDirection: AppStrings.isArabic
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDelete(id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

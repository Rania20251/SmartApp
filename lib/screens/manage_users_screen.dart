import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  late Future<List<dynamic>> usersFuture;

  // الاحتفاظ بآخر قائمة حتى لا تختفي أثناء التحديث.
  List<dynamic> cachedUsers = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void loadUsers() {
    usersFuture = ApiService.getPatients().then((data) {
      cachedUsers = List<dynamic>.from(data);
      return cachedUsers;
    });
  }

  void refreshUsers() {
    setState(() {
      loadUsers();
    });
  }

  String translateUserName(String name) {
    final clean = name
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.isEmpty) return AppStrings.noName;

    const englishToArabic = <String, String>{
      'hana': 'هناء',
      'hala': 'هالة',
      'amani': 'أماني',
      'rola': 'رولا',
      'rana': 'رنا',
      'rania': 'رانيا',
      'ramia': 'راميا',
      'salah': 'صلاح',
      'sarah': 'سارة',
      'sara': 'سارة',
      'ahmad': 'أحمد',
      'ahmed': 'أحمد',
      'ali': 'علي',
      'mohammad': 'محمد',
      'mohammed': 'محمد',
      'mohamed': 'محمد',
      'omar': 'عمر',
      'nour': 'نور',
      'noor': 'نور',
      'adnan': 'عدنان',
      'osama': 'أسامة',
      'murad': 'مراد',
      'aya': 'آية',
      'lina': 'لينا',
      'yara': 'يارا',
      'mona': 'منى',
      'huda': 'هدى',
      'khaled': 'خالد',
      'khalid': 'خالد',
      'yousef': 'يوسف',
      'yusuf': 'يوسف',
      'mariam': 'مريم',
      'maryam': 'مريم',
    };

    const arabicToEnglish = <String, String>{
      'هناء': 'Hana',
      'هالة': 'Hala',
      'هاله': 'Hala',
      'أماني': 'Amani',
      'اماني': 'Amani',
      'رولا': 'Rola',
      'رنا': 'Rana',
      'رانيا': 'Rania',
      'راميا': 'Ramia',
      'صلاح': 'Salah',
      'سارة': 'Sarah',
      'ساره': 'Sarah',
      'أحمد': 'Ahmad',
      'احمد': 'Ahmad',
      'علي': 'Ali',
      'محمد': 'Mohammad',
      'عمر': 'Omar',
      'نور': 'Nour',
      'عدنان': 'Adnan',
      'أسامة': 'Osama',
      'اسامة': 'Osama',
      'مراد': 'Murad',
      'آية': 'Aya',
      'ايه': 'Aya',
      'لينا': 'Lina',
      'يارا': 'Yara',
      'منى': 'Mona',
      'هدى': 'Huda',
      'خالد': 'Khaled',
      'يوسف': 'Yousef',
      'مريم': 'Mariam',
    };

    final words = clean
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (AppStrings.isArabic) {
      return words.map((word) {
        final cleanedWord = word
            .replaceAll('.', '')
            .replaceAll(',', '')
            .trim();

        return englishToArabic[cleanedWord.toLowerCase()] ??
            cleanedWord;
      }).join(' ');
    }

    return words.map((word) {
      final cleanedWord = word
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim();

      return arabicToEnglish[cleanedWord] ?? cleanedWord;
    }).join(' ');
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
        child: CachedNetworkImage(
          imageUrl: image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => defaultUserImage(),
          errorWidget: (_, __, ___) => defaultUserImage(),
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: FutureBuilder<List<dynamic>>(
                future: usersFuture,
                initialData: cachedUsers.isEmpty ? null : cachedUsers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      cachedUsers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError && cachedUsers.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.failedLoadUsers,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final users = snapshot.data ?? cachedUsers;

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

                      return RepaintBoundary(
                        child: Container(
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

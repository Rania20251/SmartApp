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
      builder: (_) => AlertDialog(
        title: Text(AppStrings.deleteUser),
        content: Text(AppStrings.deleteUserConfirm),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: ()=>Navigator.pop(context,true), child: Text(AppStrings.delete,style: const TextStyle(color: Colors.red))),
        ],
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
            IconButton(icon: const Icon(Icons.refresh), onPressed: refreshUsers),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(AppStrings.failedLoadUsers, style: const TextStyle(color: Colors.red)));
            }
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return Center(child: Text(AppStrings.noUsersFound));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: users.length,
              itemBuilder: (context,index){
                final user=users[index];
                final id=int.tryParse('${user['userId']??user['UserId']??0}')??0;
                final full='${user['fullName']??user['FullName']??AppStrings.noName}';
                final email='${user['email']??user['Email']??AppStrings.noEmail}';
                final phone='${user['phoneNumber']??user['PhoneNumber']??''}';
                return Container(
                  margin: const EdgeInsets.only(bottom:16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(22)),
                  child: Row(children:[
                    SizedBox(width:60,height:60,child:userImage(getUserImage(user))),
                    const SizedBox(width:14),
                    Expanded(child:Column(
                      crossAxisAlignment: AppStrings.isArabic?CrossAxisAlignment.end:CrossAxisAlignment.start,
                      children:[
                        Text(full,maxLines:1,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
                        const SizedBox(height:4),
                        Text(email,maxLines:1,overflow:TextOverflow.ellipsis,style: const TextStyle(color: Colors.grey)),
                        if(phone.isNotEmpty)...[
                          const SizedBox(height:4),
                          Text(phone,style: const TextStyle(fontSize:12))
                        ],
                        const SizedBox(height:4),
                        Text('${AppStrings.userId}: $id',style: const TextStyle(fontSize:12))
                      ],
                    )),
                    IconButton(icon: const Icon(Icons.delete,color: Colors.red),onPressed: ()=>confirmDelete(id))
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

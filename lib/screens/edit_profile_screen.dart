import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController genderController;
  late TextEditingController birthController;

  final ImagePicker picker = ImagePicker();

  bool isLoading = false;
  String profileImage = '';
  Uint8List? selectedImageBytes;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: UserSession.fullName ?? '',
    );

    emailController = TextEditingController(
      text: UserSession.email ?? '',
    );

    phoneController = TextEditingController(
      text: UserSession.phoneNumber ?? '',
    );

    addressController = TextEditingController(
      text: UserSession.address ?? '',
    );

    genderController = TextEditingController(
      text: normalizeGenderForStorage(
        UserSession.gender ?? '',
      ),
    );

    birthController = TextEditingController(
      text: UserSession.dateOfBirth ?? '',
    );

    profileImage = UserSession.profileImage ?? '';
  }

  String normalizeGenderForStorage(String value) {
    final gender = value.trim().toLowerCase();

    if (gender == 'male' ||
        gender == 'm' ||
        gender == 'ذكر') {
      return 'Male';
    }

    if (gender == 'female' ||
        gender == 'f' ||
        gender == 'أنثى' ||
        gender == 'انثى') {
      return 'Female';
    }

    return '';
  }

  ImageProvider getProfileImage() {
    if (selectedImageBytes != null) {
      return MemoryImage(selectedImageBytes!);
    }

    try {
      if (profileImage.startsWith('data:image')) {
        final base64Part = profileImage.split(',').last;
        return MemoryImage(base64Decode(base64Part));
      }
    } catch (_) {
      return const AssetImage(
        'assets/images/profile.jpg',
      );
    }

    if (profileImage.startsWith('http://') ||
        profileImage.startsWith('https://')) {
      return NetworkImage(profileImage);
    }

    if (profileImage.startsWith('assets/')) {
      return AssetImage(profileImage);
    }

    return const AssetImage(
      'assets/images/profile.jpg',
    );
  }

  Future<void> pickProfileImage() async {
    if (isLoading) return;

    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (bytes.isEmpty) return;

    final base64Image = base64Encode(bytes);

    setState(() {
      selectedImageBytes = bytes;
      profileImage =
      'data:image/jpeg;base64,$base64Image';
    });
  }

  String? selectedGenderValue() {
    final normalized = normalizeGenderForStorage(
      genderController.text,
    );

    if (normalized.isEmpty) return null;

    return normalized;
  }

  Future<void> pickBirthDate() async {
    DateTime initialDate = DateTime(2000, 1, 1);

    try {
      if (birthController.text.trim().isNotEmpty) {
        initialDate = DateTime.parse(
          birthController.text.trim(),
        );
      }
    } catch (_) {}

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: AppStrings.dateOfBirth,
      cancelText: AppStrings.cancel,
      confirmText:
      AppStrings.isArabic ? 'اختيار' : 'Select',
    );

    if (pickedDate == null) return;

    setState(() {
      birthController.text =
      '${pickedDate.year}-'
          '${pickedDate.month.toString().padLeft(2, '0')}-'
          '${pickedDate.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> saveProfile() async {
    if (isLoading) return;

    final userId = UserSession.userId;

    if (userId == null || userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.profileUpdateFailed,
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final storedGender = normalizeGenderForStorage(
      genderController.text,
    );

    try {
      final success = await ApiService.updateUser(
        userId: userId,
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        password: '',
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        gender: storedGender,
        dateOfBirth: birthController.text.trim(),
        profileImage: profileImage.isEmpty
            ? 'assets/images/profile.jpg'
            : profileImage,
      );

      if (!mounted) return;

      if (success) {
        UserSession.fullName =
            nameController.text.trim();

        UserSession.email =
            emailController.text.trim();

        UserSession.phoneNumber =
            phoneController.text.trim();

        UserSession.address =
            addressController.text.trim();

        UserSession.gender = storedGender;

        UserSession.dateOfBirth =
            birthController.text.trim();

        UserSession.profileImage =
        profileImage.isEmpty
            ? 'assets/images/profile.jpg'
            : profileImage;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.profileUpdated,
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.profileUpdateFailed,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.profileUpdateFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    genderController.dispose();
    birthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    final bool isArabic = AppStrings.isArabic;
    final TextDirection textDirection =
    isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.editProfile),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: ListView(
                  children: [
                    const SizedBox(height: 18),

                    Center(
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor:
                        const Color(0xffEDE7FF),
                        backgroundImage:
                        getProfileImage(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : pickProfileImage,
                        icon: const Icon(Icons.image),
                        label: Text(
                          isArabic
                              ? 'اختيار صورة الملف الشخصي'
                              : 'Choose Profile Image',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    buildField(
                      AppStrings.fullName,
                      Icons.person,
                      nameController,
                    ),

                    buildField(
                      AppStrings.email,
                      Icons.email,
                      emailController,
                      keyboardType:
                      TextInputType.emailAddress,
                      forceLtr: true,
                    ),

                    buildField(
                      AppStrings.phoneNumber,
                      Icons.phone,
                      phoneController,
                      keyboardType:
                      TextInputType.phone,
                      forceLtr: true,
                    ),

                    buildField(
                      AppStrings.address,
                      Icons.location_on,
                      addressController,
                    ),

                    buildGenderDropdown(),

                    buildDatePickerField(),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : saveProfile,
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          AppStrings.saveChanges,
                          textDirection:
                          textDirection,
                          style:
                          const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGenderDropdown() {
    final bool isArabic = AppStrings.isArabic;
    final TextDirection textDirection =
    isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: DropdownButtonFormField<String>(
        value: selectedGenderValue(),
        decoration: inputDecoration(
          AppStrings.gender,
          Icons.wc,
        ),
        isExpanded: true,
        items: [
          DropdownMenuItem<String>(
            value: 'Male',
            child: Align(
              alignment: isArabic
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                isArabic ? 'ذكر' : 'Male',
                textDirection: textDirection,
              ),
            ),
          ),
          DropdownMenuItem<String>(
            value: 'Female',
            child: Align(
              alignment: isArabic
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                isArabic ? 'أنثى' : 'Female',
                textDirection: textDirection,
              ),
            ),
          ),
        ],
        onChanged: isLoading
            ? null
            : (value) {
          if (value == null) return;

          setState(() {
            genderController.text = value;
          });
        },
      ),
    );
  }

  Widget buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLoading ? null : pickBirthDate,
        child: AbsorbPointer(
          child: TextField(
            controller: birthController,
            textDirection: TextDirection.ltr,
            textAlign: AppStrings.isArabic
                ? TextAlign.right
                : TextAlign.left,
            decoration: inputDecoration(
              AppStrings.dateOfBirth,
              Icons.calendar_month,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField(
      String hint,
      IconData icon,
      TextEditingController controller, {
        TextInputType? keyboardType,
        bool forceLtr = false,
      }) {
    final bool isArabic = AppStrings.isArabic;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: forceLtr
            ? TextDirection.ltr
            : isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        textAlign:
        isArabic ? TextAlign.right : TextAlign.left,
        decoration: inputDecoration(
          hint,
          icon,
        ),
      ),
    );
  }

  InputDecoration inputDecoration(
      String hint,
      IconData icon,
      ) {
    final bool isArabic = AppStrings.isArabic;

    return InputDecoration(
      hintText: hint,
      hintTextDirection:
      isArabic ? TextDirection.rtl : TextDirection.ltr,
      prefixIcon: isArabic ? null : Icon(icon),
      suffixIcon: isArabic ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xff5B2EFF),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
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

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: UserSession.fullName ?? '');
    emailController = TextEditingController(text: UserSession.email ?? '');
    phoneController = TextEditingController(text: UserSession.phoneNumber ?? '');
    addressController = TextEditingController(text: UserSession.address ?? '');
    genderController = TextEditingController(text: UserSession.gender ?? '');
    birthController = TextEditingController(text: UserSession.dateOfBirth ?? '');
  }

  String? selectedGenderValue() {
    final gender = genderController.text.trim().toLowerCase();

    if (gender == 'male' || gender == 'ذكر') return 'Male';
    if (gender == 'female' || gender == 'أنثى' || gender == 'انثى') return 'Female';

    return null;
  }

  Future<void> pickBirthDate() async {
    DateTime initialDate = DateTime(2000, 1, 1);

    try {
      if (birthController.text.trim().isNotEmpty) {
        initialDate = DateTime.parse(birthController.text.trim());
      }
    } catch (_) {}

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: AppStrings.dateOfBirth,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.isArabic ? 'اختيار' : 'Select',
    );

    if (pickedDate != null) {
      setState(() {
        birthController.text =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> saveProfile() async {
    setState(() => isLoading = true);

    final success = await ApiService.updateUser(
      userId: UserSession.userId!,
      fullName: nameController.text,
      email: emailController.text,
      password: '123456',
      phoneNumber: phoneController.text,
      address: addressController.text,
      gender: genderController.text,
      dateOfBirth: birthController.text,
      profileImage: UserSession.profileImage ?? 'assets/images/profile.jpg',
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (success) {
      UserSession.fullName = nameController.text;
      UserSession.email = emailController.text;
      UserSession.phoneNumber = phoneController.text;
      UserSession.address = addressController.text;
      UserSession.gender = genderController.text;
      UserSession.dateOfBirth = birthController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.profileUpdated)),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.profileUpdateFailed)),
      );
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

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.editProfile),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 390,
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const SizedBox(height: 20),

              buildField(AppStrings.fullName, Icons.person, nameController),
              buildField(AppStrings.email, Icons.email, emailController),
              buildField(AppStrings.phoneNumber, Icons.phone, phoneController),
              buildField(AppStrings.address, Icons.location_on, addressController),

              buildGenderDropdown(),

              buildDatePickerField(),

              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : saveProfile,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    AppStrings.saveChanges,
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: selectedGenderValue(),
        decoration: inputDecoration(AppStrings.gender, Icons.wc),
        items: [
          DropdownMenuItem(
            value: 'Male',
            child: Text(AppStrings.isArabic ? 'ذكر' : 'Male'),
          ),
          DropdownMenuItem(
            value: 'Female',
            child: Text(AppStrings.isArabic ? 'أنثى' : 'Female'),
          ),
        ],
        onChanged: (value) {
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
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: pickBirthDate,
        child: AbsorbPointer(
          child: TextField(
            controller: birthController,
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
      TextEditingController controller,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: inputDecoration(hint, icon),
      ),
    );
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
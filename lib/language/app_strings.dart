import 'package:flutter/material.dart';

class AppStrings {
  static Locale currentLocale = const Locale('en');

  static bool get isArabic => currentLocale.languageCode == 'ar';

  static void changeLanguage(Locale locale) {
    currentLocale = locale;
  }

  static String get appTitle => isArabic ? 'العيادة الذكية' : 'Smart Clinic';

  static String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  static String get register => isArabic ? 'إنشاء حساب' : 'Register';
  static String get home => isArabic ? 'الرئيسية' : 'Home';
  static String get appointments => isArabic ? 'المواعيد' : 'Appointments';
  static String get medicalRecords => isArabic ? 'السجل الطبي' : 'Medical Records';
  static String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  static String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  static String get doctors => isArabic ? 'الأطباء' : 'Doctors';
  static String get users => isArabic ? 'المستخدمين' : 'Users';
  static String get adminDashboard => isArabic ? 'لوحة تحكم الأدمن' : 'Admin Dashboard';
  static String get overview => isArabic ? 'نظرة عامة' : 'Overview';
  static String get management => isArabic ? 'الإدارة' : 'Management';  static String get settings => isArabic ? 'الإعدادات' : 'Settings';
  static String get language => isArabic ? 'اللغة' : 'Language';
  static String get english => isArabic ? 'الإنجليزية' : 'English';
  static String get arabic => isArabic ? 'العربية' : 'Arabic';
  static String get notifications => isArabic ? 'الإشعارات' : 'Notifications';

  static String get loginToAccount => isArabic ? 'سجّل الدخول إلى حسابك' : 'Login to your account';
  static String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  static String get password => isArabic ? 'كلمة المرور' : 'Password';
  static String get enterEmail => isArabic ? 'يرجى إدخال البريد الإلكتروني' : 'Please enter your email';
  static String get enterPassword => isArabic ? 'يرجى إدخال كلمة المرور' : 'Please enter your password';
  static String get invalidLogin => isArabic ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة' : 'Invalid email or password';
  static String get connectionFailed => isArabic ? 'فشل الاتصال. تحقق من الـ API' : 'Connection failed. Check API.';
  static String get createNewAccount => isArabic ? 'إنشاء حساب جديد' : 'Create New Account';

  static String get createAccount => isArabic ? 'إنشاء حساب' : 'Create Account';
  static String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  static String get enterFullName => isArabic ? 'يرجى إدخال الاسم الكامل' : 'Please enter your full name';
  static String get accountCreated => isArabic ? 'تم إنشاء الحساب بنجاح' : 'Account created successfully';
  static String get registrationFailed => isArabic ? 'فشل إنشاء الحساب' : 'Registration failed';
  static String get alreadyHaveAccount => isArabic ? 'لديك حساب؟ تسجيل الدخول' : 'Already have an account? Login';

  static String get needConsultation => isArabic ? 'تحتاج إلى استشارة؟' : 'Need a consultation?';
  static String get bookAppointmentMessage => isArabic ? 'احجز موعدك مع أفضل الأطباء بسهولة.' : 'Book your appointment with the best doctors easily.';
  static String get searchDoctors => isArabic ? 'ابحث عن طبيب أو تخصص' : 'Search doctors or specialty';
  static String get specialties => isArabic ? 'التخصصات' : 'Specialties';
  static String get featuredDoctors => isArabic ? 'الأطباء المميزون' : 'Featured Doctors';
  static String get failedLoadDoctors => isArabic ? 'فشل تحميل الأطباء' : 'Failed to load doctors';
  static String get noDoctorsFound => isArabic ? 'لا يوجد أطباء' : 'No doctors found';

  static String get appointmentBooked => isArabic ? 'تم حجز الموعد بنجاح' : 'Appointment booked successfully';
  static String get appointmentFailed => isArabic ? 'فشل حجز الموعد' : 'Failed to book appointment';
  static String get book => isArabic ? 'احجز' : 'Book';

  static String get heart => isArabic ? 'القلب' : 'Heart';
  static String get neuro => isArabic ? 'الأعصاب' : 'Neuro';
  static String get pedia => isArabic ? 'الأطفال' : 'Pedia';
  static String get eye => isArabic ? 'العيون' : 'Eye';

  static String get noName => isArabic ? 'بدون اسم' : 'No Name';
  static String get noEmail => isArabic ? 'بدون بريد إلكتروني' : 'No Email';
  static String get notAvailable => isArabic ? 'غير متوفر' : 'Not Available';
  static String get role => isArabic ? 'الدور' : 'Role';
  static String get userId => isArabic ? 'رقم المستخدم' : 'User ID';
  static String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  static String get myAppointments => isArabic ? 'مواعيدي' : 'My Appointments';
  static String get fromDatabase => isArabic ? 'من قاعدة البيانات' : 'From Database';
  static String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  static String get address => isArabic ? 'العنوان' : 'Address';
  static String get gender => isArabic ? 'الجنس' : 'Gender';
  static String get changeLanguageText => isArabic ? 'تغيير اللغة' : 'Change Language';
  static String get languageChanged => isArabic ? 'تم تغيير اللغة' : 'Language changed';
  static String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  static String get changePassword => isArabic ? 'تغيير كلمة المرور' : 'Change Password';

  static String get schedule => isArabic ? 'الجدول' : 'Schedule';
  static String get failedLoadAppointments => isArabic ? 'فشل تحميل المواعيد' : 'Failed to load appointments';
  static String get noAppointmentsFound => isArabic ? 'لا توجد مواعيد' : 'No appointments found';
  static String get doctor => isArabic ? 'طبيب' : 'Doctor';
  static String get specialist => isArabic ? 'أخصائي' : 'Specialist';
  static String get patientId => isArabic ? 'رقم المريض' : 'Patient ID';
  static String get dateTime => isArabic ? 'التاريخ والوقت' : 'Date & Time';
  static String get appointmentDeleted => isArabic ? 'تم حذف الموعد بنجاح' : 'Appointment deleted successfully';
  static String get deleteAppointmentFailed => isArabic ? 'فشل حذف الموعد' : 'Failed to delete appointment';

  static String get noFileFound => isArabic ? 'لم يتم العثور على ملف' : 'No file found';
  static String get couldNotOpenFile => isArabic ? 'تعذر فتح الملف' : 'Could not open file';
  static String get filePathNotFound => isArabic ? 'مسار الملف غير موجود' : 'File path not found';
  static String get uploadedMedicalReport => isArabic ? 'تقرير طبي مرفوع' : 'Uploaded medical report';
  static String get uploaded => isArabic ? 'تم الرفع' : 'Uploaded';
  static String get reportUploaded => isArabic ? 'تم رفع التقرير بنجاح' : 'Report uploaded successfully';
  static String get uploadFailed => isArabic ? 'فشل الرفع' : 'Upload failed';
  static String get recordDeleted => isArabic ? 'تم حذف السجل بنجاح' : 'Record deleted successfully';
  static String get deleteRecordFailed => isArabic ? 'فشل حذف السجل' : 'Failed to delete record';
  static String get deleteRecord => isArabic ? 'حذف السجل' : 'Delete Record';
  static String get deleteRecordConfirm => isArabic ? 'هل أنت متأكد أنك تريد حذف هذا السجل الطبي؟' : 'Are you sure you want to delete this medical record?';
  static String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  static String get delete => isArabic ? 'حذف' : 'Delete';
  static String get uploadMedicalReport => isArabic ? 'رفع تقرير طبي' : 'Upload Medical Report';
  static String get uploading => isArabic ? 'جاري الرفع...' : 'Uploading...';
  static String get chooseFile => isArabic ? 'اختيار ملف' : 'Choose File';
  static String get medicalRecord => isArabic ? 'سجل طبي' : 'Medical Record';
  static String get date => isArabic ? 'التاريخ' : 'Date';
  static String get failedLoadMedicalRecords => isArabic ? 'فشل تحميل السجلات الطبية' : 'Failed to load medical records';
  static String get noMedicalRecordsFound => isArabic ? 'لا توجد سجلات طبية' : 'No medical records found';

  static String get manageDoctors => isArabic ? 'إدارة الأطباء' : 'Manage Doctors';
  static String get deleteDoctor => isArabic ? 'حذف الطبيب' : 'Delete Doctor';
  static String get deleteDoctorConfirm => isArabic ? 'هل أنت متأكد أنك تريد حذف هذا الطبيب؟' : 'Are you sure you want to delete this doctor?';
  static String get doctorDeleted => isArabic ? 'تم حذف الطبيب بنجاح' : 'Doctor deleted successfully';
  static String get changeImage => isArabic ? 'تغيير الصورة' : 'Change Image';
  static String get edit => isArabic ? 'تعديل' : 'Edit';
  static String get doctorImageUpdated => isArabic ? 'تم تحديث صورة الطبيب بنجاح' : 'Doctor image updated successfully';
  static String get doctorImageUpdateFailed => isArabic ? 'فشل تحديث صورة الطبيب' : 'Failed to update doctor image';

  static String get bookAppointment => isArabic ? 'حجز موعد' : 'Book Appointment';
  static String get selectDoctor => isArabic ? 'اختر الطبيب' : 'Select Doctor';
  static String get selectDate => isArabic ? 'اختر التاريخ' : 'Select Date';
  static String get selectTime => isArabic ? 'اختر الوقت' : 'Select Time';
  static String get pleaseSelectDoctor => isArabic ? 'يرجى اختيار الطبيب' : 'Please select a doctor';
  static String get pleaseSelectDate => isArabic ? 'يرجى اختيار التاريخ' : 'Please select a date';
  static String get pleaseSelectTime => isArabic ? 'يرجى اختيار الوقت' : 'Please select a time';
  static String get bookNow => isArabic ? 'احجز الآن' : 'Book Now';

  static String get doctorDetails => isArabic ? 'تفاصيل الطبيب' : 'Doctor Details';
  static String get rating => isArabic ? 'التقييم' : 'Rating';
  static String get availableTime => isArabic ? 'وقت التوفر' : 'Available Time';
  static String get specialty => isArabic ? 'التخصص' : 'Specialty';
  static String get doctorId => isArabic ? 'رقم الطبيب' : 'Doctor ID';

  static String get notification => isArabic ? 'إشعار' : 'Notification';
  static String get notificationDeleted => isArabic ? 'تم حذف الإشعار' : 'Notification deleted';
  static String get failedLoadNotifications => isArabic ? 'فشل تحميل الإشعارات' : 'Failed to load notifications';
  static String get noNotificationsYet => isArabic ? 'لا توجد إشعارات بعد' : 'No notifications yet';

  static String get failedLoadDashboardData => isArabic ? 'فشل تحميل بيانات لوحة التحكم' : 'Failed to load dashboard data';
  static String get manageUsers => isArabic ? 'إدارة المستخدمين' : 'Manage Users';
  static String get manageUsersSubtitle => isArabic ? 'عرض وحذف المستخدمين' : 'View and delete users';
  static String get manageDoctorsSubtitle => isArabic ? 'إضافة وتعديل وحذف الأطباء' : 'Add, edit, and delete doctors';
  static String get manageAppointments => isArabic ? 'إدارة المواعيد' : 'Manage Appointments';
  static String get manageAppointmentsSubtitle => isArabic ? 'تأكيد أو إكمال أو إلغاء المواعيد' : 'Confirm, complete, or cancel appointments';
  static String get manageMedicalRecords => isArabic ? 'إدارة السجلات الطبية' : 'Manage Medical Records';
  static String get manageMedicalRecordsSubtitle => isArabic ? 'عرض وحذف السجلات الطبية' : 'View and delete medical records';

  static String get deleteUser => isArabic ? 'حذف المستخدم' : 'Delete User';
  static String get deleteUserConfirm => isArabic ? 'هل أنت متأكد من حذف هذا المستخدم؟' : 'Are you sure you want to delete this user?';
  static String get userDeleted => isArabic ? 'تم حذف المستخدم بنجاح' : 'User deleted successfully';
  static String get failedLoadUsers => isArabic ? 'فشل تحميل المستخدمين' : 'Failed to load users';
  static String get noUsersFound => isArabic ? 'لا يوجد مستخدمون' : 'No users found';

  static String get addDoctor => isArabic ? 'إضافة طبيب' : 'Add Doctor';
  static String get doctorFullName => isArabic ? 'الاسم الكامل للطبيب' : 'Doctor Full Name';
  static String get enterDoctorName => isArabic ? 'يرجى إدخال اسم الطبيب' : 'Please enter doctor name';
  static String get enterSpecialty => isArabic ? 'يرجى إدخال التخصص' : 'Please enter specialty';
  static String get doctorAdded => isArabic ? 'تمت إضافة الطبيب بنجاح' : 'Doctor added successfully';
  static String get addDoctorFailed => isArabic ? 'فشل إضافة الطبيب' : 'Failed to add doctor';
  static String get editDoctor => isArabic ? 'تعديل الطبيب' : 'Edit Doctor';
  static String get updateDoctor => isArabic ? 'تحديث الطبيب' : 'Update Doctor';
  static String get invalidDoctorId => isArabic ? 'رقم الطبيب غير صالح' : 'Invalid doctor ID';
  static String get doctorUpdated => isArabic ? 'تم تحديث بيانات الطبيب بنجاح' : 'Doctor updated successfully';
  static String get updateDoctorFailed => isArabic ? 'فشل تحديث بيانات الطبيب' : 'Failed to update doctor';

  static String get appointment => isArabic ? 'موعد' : 'Appointment';
  static String get appointmentMarkedAs => isArabic ? 'تم تغيير حالة الموعد إلى' : 'Appointment marked as';
  static String get updateAppointmentFailed => isArabic ? 'فشل تحديث الموعد' : 'Failed to update appointment';
  static String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  static String get complete => isArabic ? 'إكمال' : 'Complete';
  static String get cancelAppointment => isArabic ? 'إلغاء' : 'Cancel';

  static String get failedLoadRecords => isArabic ? 'فشل تحميل السجلات' : 'Failed to load records';
  static String get deleteRecordConfirmShort => isArabic ? 'هل أنت متأكد أنك تريد حذف هذا السجل؟' : 'Are you sure you want to delete this record?';

  static String get updatePassword => isArabic ? 'تحديث كلمة المرور' : 'Update Password';
  static String get enterOldAndNewPassword => isArabic ? 'أدخل كلمة المرور القديمة والجديدة' : 'Enter your old and new password';
  static String get oldPassword => isArabic ? 'كلمة المرور القديمة' : 'Old Password';
  static String get newPassword => isArabic ? 'كلمة المرور الجديدة' : 'New Password';
  static String get confirmNewPassword => isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password';
  static String get enterOldPassword => isArabic ? 'يرجى إدخال كلمة المرور القديمة' : 'Please enter old password';
  static String get enterNewPassword => isArabic ? 'يرجى إدخال كلمة المرور الجديدة' : 'Please enter new password';
  static String get confirmNewPasswordMessage => isArabic ? 'يرجى تأكيد كلمة المرور الجديدة' : 'Please confirm new password';
  static String get passwordsDoNotMatch => isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  static String get userNotFound => isArabic ? 'المستخدم غير موجود. يرجى تسجيل الدخول مرة أخرى.' : 'User not found. Please login again.';
  static String get passwordChanged => isArabic ? 'تم تغيير كلمة المرور بنجاح' : 'Password changed successfully';
  static String get passwordChangeFailed => isArabic ? 'فشل تغيير كلمة المرور' : 'Failed to change password';

  static String get saveChanges => isArabic ? 'حفظ التعديلات' : 'Save Changes';
  static String get profileUpdated => isArabic ? 'تم تحديث الملف الشخصي بنجاح' : 'Profile updated successfully';
  static String get profileUpdateFailed => isArabic ? 'فشل تحديث الملف الشخصي' : 'Failed to update profile';
  static String get dateOfBirth => isArabic ? 'تاريخ الميلاد' : 'Date of Birth';

  static String get totalPatients => isArabic ? 'إجمالي المرضى' : 'Total Patients';
  static String get totalDoctors => isArabic ? 'إجمالي الأطباء' : 'Total Doctors';
  static String get pending => isArabic ? 'قيد الانتظار' : 'Pending';
  static String get appointmentsOverview => isArabic ? 'إحصائيات المواعيد' : 'Appointments Overview';
  static String get latestPatients => isArabic ? 'آخر المرضى' : 'Latest Patients';
  static String get viewAll => isArabic ? 'عرض الكل' : 'View All';
  static String get today => isArabic ? 'اليوم' : 'Today';
  static String get total => isArabic ? 'الإجمالي' : 'Total';
  static String get patients => isArabic ? 'المرضى' : 'Patients';
  static String get manageSpecialties => isArabic ? 'إدارة التخصصات' : 'Manage Specialties';
  static String get manageSpecialtiesSubtitle => isArabic ? 'إضافة وتعديل وحذف التخصصات' : 'Add, edit, and delete specialties';
  static String get addSpecialty => isArabic ? 'إضافة تخصص' : 'Add Specialty';
  static String get editSpecialty => isArabic ? 'تعديل التخصص' : 'Edit Specialty';
  static String get deleteSpecialty => isArabic ? 'حذف التخصص' : 'Delete Specialty';
  static String get deleteSpecialtyConfirm => isArabic ? 'هل أنت متأكد أنك تريد حذف هذا التخصص؟' : 'Are you sure you want to delete this specialty?';
  static String get specialtyName => isArabic ? 'اسم التخصص' : 'Specialty Name';
  static String get chooseIcon => isArabic ? 'اختر الأيقونة' : 'Choose Icon';
  static String get save => isArabic ? 'حفظ' : 'Save';
  static String get specialtyAdded => isArabic ? 'تمت إضافة التخصص بنجاح' : 'Specialty added successfully';
  static String get specialtyUpdated => isArabic ? 'تم تعديل التخصص بنجاح' : 'Specialty updated successfully';
  static String get specialtyDeleted => isArabic ? 'تم حذف التخصص بنجاح' : 'Specialty deleted successfully';
  static String get specialtyDeleteFailed => isArabic ? 'لا يمكن حذف التخصص لأنه مرتبط بأطباء' : 'Cannot delete specialty because it has doctors';
  static String get noSpecialtiesFound => isArabic ? 'لا توجد تخصصات' : 'No specialties found';
  static String get operationFailed => isArabic ? 'فشلت العملية' : 'Operation failed';


  static String _normalizeNameSpaces(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _removeDoctorTitle(String value) {
    return _normalizeNameSpaces(
      value
          .replaceAll(
        RegExp(r'\bdoctor\b', caseSensitive: false),
        ' ',
      )
          .replaceAll(
        RegExp(r'\bdr\.?', caseSensitive: false),
        ' ',
      )
          .replaceAll('دكتور', ' ')
          .replaceAll('د.', ' '),
    );
  }

  static String personNameByLanguage(String name) {
    final clean = _removeDoctorTitle(name);

    if (clean.isEmpty) {
      return isArabic ? 'بدون اسم' : 'No Name';
    }

    if (isArabic) {
      const knownNames = <String, String>{
        'ahmad': 'أحمد',
        'ahmed': 'أحمد',
        'mohammad': 'محمد',
        'mohammed': 'محمد',
        'mohamed': 'محمد',
        'mahmoud': 'محمود',
        'ali': 'علي',
        'sarah': 'سارة',
        'sara': 'سارة',
        'sali': 'سالي',
        'sally': 'سالي',
        'rana': 'رنا',
        'rania': 'رانيا',
        'ramia': 'راميا',
        'salah': 'صلاح',
        'omar': 'عمر',
        'nour': 'نور',
        'noor': 'نور',
        'adnan': 'عدنان',
        'yousef': 'يوسف',
        'yusuf': 'يوسف',
        'khaled': 'خالد',
        'khalid': 'خالد',
        'hassan': 'حسن',
        'hasan': 'حسن',
        'hussein': 'حسين',
        'reem': 'ريم',
        'lama': 'لمى',
        'lina': 'لينا',
        'dana': 'دانا',
        'sami': 'سامي',
        'sameer': 'سمير',
        'samir': 'سمير',
        'maha': 'مها',
        'aya': 'آية',
        'amal': 'أمل',
        'huda': 'هدى',
      };

      final words = clean
          .split(RegExp(r'\s+'))
          .where((word) => word.trim().isNotEmpty)
          .map((word) {
        final punctuationFree = word
            .replaceAll('.', '')
            .replaceAll(',', '')
            .trim();

        if (!RegExp(r'[a-zA-Z]').hasMatch(punctuationFree)) {
          return punctuationFree;
        }

        final key = punctuationFree.toLowerCase();
        return knownNames[key] ?? _transliterateLatinWord(key);
      }).where((word) => word.trim().isNotEmpty).toList();

      return _normalizeNameSpaces(words.join(' '));
    }

    const knownNames = <String, String>{
      'أحمد': 'Ahmad',
      'احمد': 'Ahmad',
      'محمد': 'Mohammad',
      'محمود': 'Mahmoud',
      'علي': 'Ali',
      'سارة': 'Sarah',
      'ساره': 'Sarah',
      'سالي': 'Sali',
      'رنا': 'Rana',
      'رانيا': 'Rania',
      'راميا': 'Ramia',
      'صلاح': 'Salah',
      'عمر': 'Omar',
      'نور': 'Nour',
      'عدنان': 'Adnan',
      'يوسف': 'Yousef',
      'خالد': 'Khaled',
      'حسن': 'Hassan',
      'حسين': 'Hussein',
      'ريم': 'Reem',
      'لمى': 'Lama',
      'لينا': 'Lina',
      'دانا': 'Dana',
      'سامي': 'Sami',
      'سمير': 'Sameer',
      'مها': 'Maha',
      'آية': 'Aya',
      'ايه': 'Aya',
      'أمل': 'Amal',
      'امل': 'Amal',
      'هدى': 'Huda',
    };

    final words = clean
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) => knownNames[word.trim()] ?? word.trim())
        .where((word) => word.isNotEmpty)
        .toList();

    return _normalizeNameSpaces(words.join(' '));
  }

  static String doctorNameByLanguage(String name) {
    final personName = personNameByLanguage(name);

    if (isArabic) {
      return _normalizeNameSpaces('د. $personName');
    }

    return _normalizeNameSpaces('Dr. $personName');
  }

  static String _transliterateLatinWord(String word) {
    var result = word.toLowerCase();

    const combinations = <String, String>{
      'sh': 'ش',
      'ch': 'تش',
      'kh': 'خ',
      'gh': 'غ',
      'th': 'ث',
      'dh': 'ذ',
      'ph': 'ف',
      'oo': 'و',
      'ou': 'و',
      'ee': 'ي',
      'ai': 'اي',
      'ay': 'اي',
    };

    combinations.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    const letters = <String, String>{
      'a': 'ا',
      'b': 'ب',
      'c': 'ك',
      'd': 'د',
      'e': 'ي',
      'f': 'ف',
      'g': 'ج',
      'h': 'ه',
      'i': 'ي',
      'j': 'ج',
      'k': 'ك',
      'l': 'ل',
      'm': 'م',
      'n': 'ن',
      'o': 'و',
      'p': 'ب',
      'q': 'ق',
      'r': 'ر',
      's': 'س',
      't': 'ت',
      'u': 'و',
      'v': 'ف',
      'w': 'و',
      'x': 'كس',
      'y': 'ي',
      'z': 'ز',
    };

    final buffer = StringBuffer();

    for (final rune in result.runes) {
      final character = String.fromCharCode(rune);
      buffer.write(letters[character] ?? character);
    }

    return buffer.toString();
  }

  static String specialtyByLanguage(String specialty) {
    final clean = specialty
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.isEmpty) {
      return isArabic ? 'أخصائي' : 'Specialist';
    }

    final value = clean.toLowerCase();

    if (isArabic) {
      if (value.contains('emergency') ||
          value.contains('er medicine') ||
          value.contains('urgent care') ||
          value.contains('طوارئ')) {
        return 'الطوارئ';
      }

      if (value.contains('cardiology') ||
          value.contains('cardiac') ||
          value.contains('heart') ||
          value.contains('قلب')) {
        return 'أمراض القلب';
      }

      if (value.contains('dentistry') ||
          value.contains('dental') ||
          value.contains('dentist') ||
          value.contains('teeth') ||
          value.contains('أسنان') ||
          value.contains('اسنان')) {
        return 'طب الأسنان';
      }

      if (value.contains('neurology') ||
          value.contains('neurologist') ||
          value.contains('neuro') ||
          value.contains('nerve') ||
          value.contains('أعصاب') ||
          value.contains('اعصاب')) {
        return 'طب الأعصاب';
      }

      if (value.contains('pediatrics') ||
          value.contains('pediatric') ||
          value.contains('child') ||
          value.contains('children') ||
          value.contains('أطفال') ||
          value.contains('اطفال')) {
        return 'طب الأطفال';
      }

      if (value.contains('dermatology') ||
          value.contains('dermatologist') ||
          value.contains('derma') ||
          value.contains('skin') ||
          value.contains('جلدية') ||
          value.contains('جلديه')) {
        return 'الأمراض الجلدية';
      }

      if (value.contains('ophthalmology') ||
          value.contains('ophthalmologist') ||
          value.contains('eye') ||
          value.contains('vision') ||
          value.contains('عيون')) {
        return 'طب العيون';
      }

      if (value.contains('orthopedics') ||
          value.contains('orthopedic') ||
          value.contains('bone') ||
          value.contains('bones') ||
          value.contains('عظام')) {
        return 'جراحة العظام';
      }

      if (value.contains('internal medicine') ||
          value.contains('internist') ||
          value.contains('internal') ||
          value.contains('باطنية') ||
          value.contains('باطنيه') ||
          value.contains('باطن')) {
        return 'الطب الباطني';
      }

      if (value.contains('general surgery') ||
          value.contains('surgery') ||
          value.contains('surgeon') ||
          value.contains('جراحة') ||
          value.contains('جراحه')) {
        return 'الجراحة العامة';
      }

      if (value.contains('gynecology') ||
          value.contains('obstetrics') ||
          value.contains('ob/gyn') ||
          value.contains('obgyn') ||
          value.contains('women') ||
          value.contains('نسائية') ||
          value.contains('نسائي') ||
          value.contains('توليد')) {
        return 'النسائية والتوليد';
      }

      if (value.contains('psychiatry') ||
          value.contains('psychiatrist') ||
          value.contains('mental health') ||
          value.contains('نفسي')) {
        return 'الطب النفسي';
      }

      if (value.contains('psychology') ||
          value.contains('psychologist') ||
          value.contains('علم النفس')) {
        return 'علم النفس';
      }

      if (value.contains('ent') ||
          value.contains('ear nose throat') ||
          value.contains('otolaryngology') ||
          value.contains('أنف') ||
          value.contains('انف') ||
          value.contains('أذن') ||
          value.contains('اذن') ||
          value.contains('حنجرة') ||
          value.contains('حنجره')) {
        return 'الأنف والأذن والحنجرة';
      }

      if (value.contains('urology') ||
          value.contains('urologist') ||
          value.contains('urinary') ||
          value.contains('مسالك')) {
        return 'المسالك البولية';
      }

      if (value.contains('pulmonology') ||
          value.contains('pulmonary') ||
          value.contains('chest') ||
          value.contains('lung') ||
          value.contains('صدر') ||
          value.contains('رئة') ||
          value.contains('رئه')) {
        return 'الأمراض الصدرية';
      }

      if (value.contains('gastroenterology') ||
          value.contains('gastro') ||
          value.contains('digestive') ||
          value.contains('هضم') ||
          value.contains('جهاز هضمي')) {
        return 'الجهاز الهضمي';
      }

      if (value.contains('endocrinology') ||
          value.contains('endocrine') ||
          value.contains('diabetes') ||
          value.contains('غدد') ||
          value.contains('سكري')) {
        return 'الغدد الصماء والسكري';
      }

      if (value.contains('nephrology') ||
          value.contains('kidney') ||
          value.contains('renal') ||
          value.contains('كلى')) {
        return 'أمراض الكلى';
      }

      if (value.contains('oncology') ||
          value.contains('cancer') ||
          value.contains('أورام') ||
          value.contains('اورام')) {
        return 'الأورام';
      }

      if (value.contains('hematology') ||
          value.contains('blood') ||
          value.contains('دم')) {
        return 'أمراض الدم';
      }

      if (value.contains('rheumatology') ||
          value.contains('rheumatic') ||
          value.contains('روماتيزم') ||
          value.contains('مفاصل')) {
        return 'الروماتيزم والمفاصل';
      }

      if (value.contains('family medicine') ||
          value.contains('family doctor') ||
          value.contains('طب الأسرة') ||
          value.contains('طب الاسرة') ||
          value.contains('أسرة') ||
          value.contains('اسرة')) {
        return 'طب الأسرة';
      }

      if (value.contains('general medicine') ||
          value.contains('general practitioner') ||
          value.contains('general') ||
          value.contains('طب عام') ||
          value.contains('عام')) {
        return 'الطب العام';
      }

      if (value.contains('nutrition') ||
          value.contains('dietitian') ||
          value.contains('diet') ||
          value.contains('تغذية') ||
          value.contains('تغذيه')) {
        return 'التغذية العلاجية';
      }

      if (value.contains('physiotherapy') ||
          value.contains('physical therapy') ||
          value.contains('rehabilitation') ||
          value.contains('علاج طبيعي') ||
          value.contains('تأهيل') ||
          value.contains('تاهيل')) {
        return 'العلاج الطبيعي والتأهيل';
      }

      if (value.contains('laboratory') ||
          value.contains('laboratories') ||
          value.contains('medical lab') ||
          value == 'lab' ||
          value.contains('labs') ||
          value.contains('مختبر') ||
          value.contains('تحاليل')) {
        return 'المختبرات الطبية';
      }

      return clean;
    }

    if (value.contains('مختبر') || value.contains('تحاليل')) {
      return 'Medical Laboratories';
    }
    if (value.contains('طوارئ')) return 'Emergency Medicine';
    if (value.contains('قلب')) return 'Cardiology';
    if (value.contains('أسنان') || value.contains('اسنان')) return 'Dentistry';
    if (value.contains('أعصاب') || value.contains('اعصاب')) return 'Neurology';
    if (value.contains('أطفال') || value.contains('اطفال')) return 'Pediatrics';
    if (value.contains('جلدية') || value.contains('جلديه')) return 'Dermatology';
    if (value.contains('عيون')) return 'Ophthalmology';
    if (value.contains('عظام')) return 'Orthopedics';
    if (value.contains('باطن')) return 'Internal Medicine';
    if (value.contains('جراحة') || value.contains('جراحه')) return 'General Surgery';
    if (value.contains('نسائ') || value.contains('توليد')) return 'Gynecology and Obstetrics';
    if (value.contains('طب نفسي')) return 'Psychiatry';
    if (value.contains('علم النفس')) return 'Psychology';
    if (value.contains('أنف') ||
        value.contains('انف') ||
        value.contains('أذن') ||
        value.contains('اذن') ||
        value.contains('حنجرة') ||
        value.contains('حنجره')) {
      return 'ENT';
    }
    if (value.contains('مسالك')) return 'Urology';
    if (value.contains('صدر') || value.contains('رئة') || value.contains('رئه')) return 'Pulmonology';
    if (value.contains('هضم')) return 'Gastroenterology';
    if (value.contains('غدد') || value.contains('سكري')) return 'Endocrinology and Diabetes';
    if (value.contains('كلى')) return 'Nephrology';
    if (value.contains('أورام') || value.contains('اورام')) return 'Oncology';
    if (value.contains('دم')) return 'Hematology';
    if (value.contains('روماتيزم') || value.contains('مفاصل')) return 'Rheumatology';
    if (value.contains('أسرة') || value.contains('اسرة')) return 'Family Medicine';
    if (value.contains('طب عام') || value == 'عام') return 'General Medicine';
    if (value.contains('تغذية') || value.contains('تغذيه')) return 'Clinical Nutrition';
    if (value.contains('علاج طبيعي') ||
        value.contains('تأهيل') ||
        value.contains('تاهيل')) {
      return 'Physiotherapy and Rehabilitation';
    }

    return clean;
  }

}

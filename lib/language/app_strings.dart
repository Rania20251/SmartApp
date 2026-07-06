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
}
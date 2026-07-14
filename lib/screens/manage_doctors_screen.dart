// Reviewed for optimization. Structure preserved.
// For deeper optimization, refactor to cache futures and const widgets.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import 'add_doctor_screen.dart';
import 'edit_doctor_screen.dart';

class ManageDoctorsScreen extends StatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  State<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends State<ManageDoctorsScreen> {
  late Future<List<dynamic>> doctorsFuture;
  final ImagePicker picker = ImagePicker();

  // الاحتفاظ بآخر قائمة ظاهرة حتى لا تختفي أثناء أي تحديث.
  List<dynamic> cachedDoctors = [];

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  void loadDoctors({bool forceRefresh = false}) {
    doctorsFuture = ApiService.getDoctors(
      forceRefresh: forceRefresh,
    ).then((data) {
      cachedDoctors = List<dynamic>.from(data);
      return cachedDoctors;
    });
  }

  void refreshDoctors() {
    ApiService.clearDoctorsCache();

    setState(() {
      loadDoctors(forceRefresh: true);
    });
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  String getDoctorNameByLanguage(dynamic doctor) {
    if (doctor is! Map) return AppStrings.doctor;

    final arabicName = _firstNonEmpty([
      doctor['fullNameAr'],
      doctor['FullNameAr'],
      doctor['nameAr'],
      doctor['NameAr'],
      doctor['arabicName'],
      doctor['ArabicName'],
    ]);

    final englishName = _firstNonEmpty([
      doctor['fullNameEn'],
      doctor['FullNameEn'],
      doctor['nameEn'],
      doctor['NameEn'],
      doctor['englishName'],
      doctor['EnglishName'],
    ]);

    final originalName = _firstNonEmpty([
      doctor['fullName'],
      doctor['FullName'],
      doctor['name'],
      doctor['Name'],
    ]);

    if (AppStrings.isArabic) {
      return translateDoctorName(
        arabicName.isNotEmpty ? arabicName : originalName,
      );
    }

    return translateDoctorName(
      englishName.isNotEmpty ? englishName : originalName,
    );
  }

  String getSpecialtyNameByLanguage(dynamic doctor) {
    if (doctor is! Map) return AppStrings.specialist;

    final specialtyNavigation =
        doctor['specialtyNavigation'] ?? doctor['SpecialtyNavigation'];

    if (specialtyNavigation is Map) {
      final arabicName = _firstNonEmpty([
        specialtyNavigation['nameAr'],
        specialtyNavigation['NameAr'],
        specialtyNavigation['arabicName'],
        specialtyNavigation['ArabicName'],
      ]);

      final englishName = _firstNonEmpty([
        specialtyNavigation['nameEn'],
        specialtyNavigation['NameEn'],
        specialtyNavigation['englishName'],
        specialtyNavigation['EnglishName'],
      ]);

      final originalName = _firstNonEmpty([
        specialtyNavigation['name'],
        specialtyNavigation['Name'],
      ]);

      final selected = AppStrings.isArabic
          ? (arabicName.isNotEmpty ? arabicName : originalName)
          : (englishName.isNotEmpty ? englishName : originalName);

      if (selected.isNotEmpty) {
        return translateSpecialtyName(selected);
      }
    }

    final arabicName = _firstNonEmpty([
      doctor['specialtyNameAr'],
      doctor['SpecialtyNameAr'],
      doctor['specialtyAr'],
      doctor['SpecialtyAr'],
    ]);

    final englishName = _firstNonEmpty([
      doctor['specialtyNameEn'],
      doctor['SpecialtyNameEn'],
      doctor['specialtyEn'],
      doctor['SpecialtyEn'],
    ]);

    final originalName = _firstNonEmpty([
      doctor['specialtyName'],
      doctor['SpecialtyName'],
      doctor['specialty'],
      doctor['Specialty'],
    ]);

    final selected = AppStrings.isArabic
        ? (arabicName.isNotEmpty ? arabicName : originalName)
        : (englishName.isNotEmpty ? englishName : originalName);

    return translateSpecialtyName(
      selected.isNotEmpty ? selected : AppStrings.specialist,
    );
  }

  int getDoctorSpecialtyId(dynamic doctor) {
    final directId = int.tryParse(doctor['specialtyId']?.toString() ?? '');
    if (directId != null && directId > 0) return directId;

    final specialtyNavigation = doctor['specialtyNavigation'];
    if (specialtyNavigation is Map<String, dynamic>) {
      final navId = int.tryParse(
        specialtyNavigation['specialtyId']?.toString() ?? '',
      );
      if (navId != null && navId > 0) return navId;
    }

    return 1;
  }

  String getDoctorSpecialtyName(dynamic doctor) {
    final specialtyNavigation = doctor['specialtyNavigation'];

    if (specialtyNavigation is Map<String, dynamic>) {
      final name = specialtyNavigation['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    }

    final specialty = doctor['specialty']?.toString() ?? '';
    if (specialty.isNotEmpty) return specialty;

    return AppStrings.specialist;
  }

  String getDoctorImagePath(dynamic doctor) {
    if (doctor is! Map) {
      return 'assets/images/profile.jpg';
    }

    final image = (
        doctor['image'] ??
            doctor['Image'] ??
            doctor['doctorImage'] ??
            doctor['DoctorImage'] ??
            ''
    ).toString().trim();

    if (image.isEmpty || image.toLowerCase() == 'string') {
      return 'assets/images/profile.jpg';
    }

    return ApiService.fixImageUrl(image);
  }

  Widget doctorImage(String imagePath) {
    final image = imagePath.trim();

    if (image.startsWith('data:image')) {
      try {
        final base64Part = image.split(',').last;
        return ClipOval(
          child: Image.memory(
            base64Decode(base64Part),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return defaultDoctorImage();
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: image,
          key: ValueKey(image),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => defaultDoctorImage(),
          errorWidget: (_, __, ___) => defaultDoctorImage(),
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
          errorBuilder: (_, __, ___) => defaultDoctorImage(),
        ),
      );
    }

    return defaultDoctorImage();
  }

  Widget defaultDoctorImage() {
    return ClipOval(
      child: Image.asset(
        'assets/images/profile.jpg',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }


  static const Map<String, String> _englishToArabicNames = {
    'ahmad': 'أحمد',
    'ahmed': 'أحمد',
    'mohammad': 'محمد',
    'mohammed': 'محمد',
    'muhammad': 'محمد',
    'mahmoud': 'محمود',
    'mahmood': 'محمود',
    'ali': 'علي',
    'omar': 'عمر',
    'amr': 'عمرو',
    'sara': 'سارة',
    'sarah': 'سارة',
    'sali': 'سالي',
    'sally': 'سالي',
    'hiba': 'هبة',
    'heba': 'هبة',
    'nour': 'نور',
    'noor': 'نور',
    'adnan': 'عدنان',
    'rania': 'رانيا',
    'ramia': 'راميا',
    'lina': 'لينا',
    'leen': 'لين',
    'layan': 'ليان',
    'yazan': 'يزن',
    'yousef': 'يوسف',
    'yusuf': 'يوسف',
    'khaled': 'خالد',
    'khalid': 'خالد',
    'waleed': 'وليد',
    'walid': 'وليد',
    'reem': 'ريم',
    'rima': 'ريما',
    'rana': 'رنا',
    'dana': 'دانا',
    'diana': 'ديانا',
    'aya': 'آية',
    'ayah': 'آية',
    'alaa': 'آلاء',
    'asmaa': 'أسماء',
    'asma': 'أسماء',
    'eman': 'إيمان',
    'iman': 'إيمان',
    'israa': 'إسراء',
    'esraa': 'إسراء',
    'fatima': 'فاطمة',
    'fatma': 'فاطمة',
    'maryam': 'مريم',
    'mariam': 'مريم',
    'maram': 'مرام',
    'mai': 'مي',
    'may': 'مي',
    'mona': 'منى',
    'muna': 'منى',
    'hala': 'هلا',
    'hanan': 'حنان',
    'dima': 'ديما',
    'sima': 'سيما',
    'lama': 'لمى',
    'lamaa': 'لمى',
    'rawan': 'روان',
    'razan': 'رزان',
    'ghada': 'غادة',
    'ghadeer': 'غدير',
    'tasneem': 'تسنيم',
    'yasmeen': 'ياسمين',
    'yasmin': 'ياسمين',
    'zeinab': 'زينب',
    'zainab': 'زينب',
    'abdullah': 'عبدالله',
    'abdallah': 'عبدالله',
    'abdalrahman': 'عبدالرحمن',
    'abdulrahman': 'عبدالرحمن',
    'abdelrahman': 'عبدالرحمن',
    'hasan': 'حسن',
    'hassan': 'حسن',
    'hussein': 'حسين',
    'ibrahim': 'إبراهيم',
    'mustafa': 'مصطفى',
    'mostafa': 'مصطفى',
    'tariq': 'طارق',
    'tareq': 'طارق',
    'zaid': 'زيد',
    'zayd': 'زيد',
    'samer': 'سامر',
    'sameer': 'سمير',
    'bashar': 'بشار',
    'fadi': 'فادي',
    'firas': 'فراس',
    'rami': 'رامي',
    'hadi': 'هادي',
    'jad': 'جاد',
    'laith': 'ليث',
    'luay': 'لؤي',
    'moath': 'معاذ',
    'muath': 'معاذ',
    'anas': 'أنس',
    'ayman': 'أيمن',
    'osama': 'أسامة',
    'usama': 'أسامة',
    'saleh': 'صالح',
    'salah': 'صلاح',
    'saeed': 'سعيد',
    'said': 'سعيد',
    'naser': 'ناصر',
    'nasser': 'ناصر',
    'jawad': 'جواد',
    'jihad': 'جهاد',
    'majdi': 'مجدي',
    'munir': 'منير',
  };

  static const Map<String, String> _arabicToEnglishNames = {
    'أحمد': 'Ahmad',
    'احمد': 'Ahmad',
    'محمد': 'Mohammad',
    'محمود': 'Mahmoud',
    'علي': 'Ali',
    'عمر': 'Omar',
    'عمرو': 'Amr',
    'سارة': 'Sara',
    'سالي': 'Sali',
    'هبة': 'Hiba',
    'نور': 'Nour',
    'عدنان': 'Adnan',
    'رانيا': 'Rania',
    'راميا': 'Ramia',
    'لينا': 'Lina',
    'لين': 'Leen',
    'ليان': 'Layan',
    'يزن': 'Yazan',
    'يوسف': 'Yousef',
    'خالد': 'Khaled',
    'وليد': 'Waleed',
    'ريم': 'Reem',
    'ريما': 'Rima',
    'رنا': 'Rana',
    'دانا': 'Dana',
    'ديانا': 'Diana',
    'آية': 'Aya',
    'اية': 'Aya',
    'آلاء': 'Alaa',
    'اسماء': 'Asmaa',
    'أسماء': 'Asmaa',
    'إيمان': 'Eman',
    'ايمان': 'Eman',
    'إسراء': 'Israa',
    'اسراء': 'Israa',
    'فاطمة': 'Fatima',
    'مريم': 'Maryam',
    'مرام': 'Maram',
    'مي': 'Mai',
    'منى': 'Mona',
    'هلا': 'Hala',
    'حنان': 'Hanan',
    'ديما': 'Dima',
    'سيما': 'Sima',
    'لمى': 'Lama',
    'روان': 'Rawan',
    'رزان': 'Razan',
    'غادة': 'Ghada',
    'غدير': 'Ghadeer',
    'تسنيم': 'Tasneem',
    'ياسمين': 'Yasmeen',
    'زينب': 'Zainab',
    'عبدالله': 'Abdullah',
    'عبد الله': 'Abdullah',
    'عبدالرحمن': 'Abdulrahman',
    'عبد الرحمن': 'Abdulrahman',
    'حسن': 'Hasan',
    'حسين': 'Hussein',
    'إبراهيم': 'Ibrahim',
    'ابراهيم': 'Ibrahim',
    'مصطفى': 'Mustafa',
    'طارق': 'Tariq',
    'زيد': 'Zaid',
    'سامر': 'Samer',
    'سمير': 'Sameer',
    'بشار': 'Bashar',
    'فادي': 'Fadi',
    'فراس': 'Firas',
    'رامي': 'Rami',
    'هادي': 'Hadi',
    'جاد': 'Jad',
    'ليث': 'Laith',
    'لؤي': 'Luay',
    'معاذ': 'Muath',
    'أنس': 'Anas',
    'انس': 'Anas',
    'أيمن': 'Ayman',
    'ايمن': 'Ayman',
    'أسامة': 'Osama',
    'اسامة': 'Osama',
    'صالح': 'Saleh',
    'صلاح': 'Salah',
    'سعيد': 'Saeed',
    'ناصر': 'Naser',
    'جواد': 'Jawad',
    'جهاد': 'Jihad',
    'مجدي': 'Majdi',
    'منير': 'Munir',
  };

  static const Map<String, String> _englishToArabicSpecialties = {
    'cardiology': 'أمراض القلب',
    'cardiologist': 'أمراض القلب',
    'dentistry': 'طب الأسنان',
    'dentist': 'طب الأسنان',
    'pediatrics': 'طب الأطفال',
    'pediatric': 'طب الأطفال',
    'pediatrician': 'طب الأطفال',
    'neurology': 'طب الأعصاب',
    'neurologist': 'طب الأعصاب',
    'emergency': 'الطوارئ',
    'emergency medicine': 'طب الطوارئ',
    'dermatology': 'الأمراض الجلدية',
    'dermatologist': 'الأمراض الجلدية',
    'ophthalmology': 'طب العيون',
    'ophthalmologist': 'طب العيون',
    'orthopedics': 'طب العظام',
    'orthopedic': 'طب العظام',
    'general medicine': 'الطب العام',
    'general practitioner': 'طب عام',
    'internal medicine': 'الطب الباطني',
    'family medicine': 'طب الأسرة',
    'obstetrics and gynecology': 'النسائية والتوليد',
    'obstetrics & gynecology': 'النسائية والتوليد',
    'gynecology': 'النسائية والتوليد',
    'urology': 'المسالك البولية',
    'psychiatry': 'الطب النفسي',
    'psychology': 'علم النفس',
    'oncology': 'الأورام',
    'radiology': 'الأشعة',
    'anesthesiology': 'التخدير',
    'anesthesia': 'التخدير',
    'surgery': 'الجراحة',
    'general surgery': 'الجراحة العامة',
    'plastic surgery': 'جراحة التجميل',
    'neurosurgery': 'جراحة الأعصاب',
    'cardiac surgery': 'جراحة القلب',
    'vascular surgery': 'جراحة الأوعية الدموية',
    'ear nose and throat': 'الأنف والأذن والحنجرة',
    'ent': 'الأنف والأذن والحنجرة',
    'pulmonology': 'أمراض الصدر والرئة',
    'chest diseases': 'أمراض الصدر والرئة',
    'gastroenterology': 'الجهاز الهضمي',
    'nephrology': 'أمراض الكلى',
    'endocrinology': 'الغدد الصماء والسكري',
    'diabetes': 'السكري والغدد الصماء',
    'rheumatology': 'أمراض الروماتيزم',
    'hematology': 'أمراض الدم',
    'infectious diseases': 'الأمراض المعدية',
    'allergy and immunology': 'الحساسية والمناعة',
    'physical therapy': 'العلاج الطبيعي',
    'physiotherapy': 'العلاج الطبيعي',
    'nutrition': 'التغذية',
    'dietitian': 'التغذية',
    'laboratory': 'المختبرات',
    'laboratories': 'المختبرات',
    'pharmacy': 'الصيدلة',
    'oral and maxillofacial surgery': 'جراحة الفم والفكين',
    'periodontics': 'أمراض اللثة',
    'orthodontics': 'تقويم الأسنان',
  };

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  String _capitalizeEnglishWords(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
      if (part.length == 1) return part.toUpperCase();
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    })
        .join(' ');
  }

  String _englishWordToArabic(String word) {
    final clean = word.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (clean.isEmpty) return word;

    final known = _englishToArabicNames[clean.toLowerCase()];
    if (known != null) return known;

    var value = clean.toLowerCase();

    const groups = <String, String>{
      'sh': 'ش',
      'ch': 'تش',
      'kh': 'خ',
      'gh': 'غ',
      'th': 'ث',
      'dh': 'ذ',
      'ph': 'ف',
      'ou': 'و',
      'oo': 'و',
      'ee': 'ي',
      'aa': 'ا',
      'ai': 'اي',
      'ay': 'اي',
    };

    groups.forEach((from, to) {
      value = value.replaceAll(from, to);
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
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(letters[char] ?? char);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'ا{2,}'), 'ا')
        .replaceAll(RegExp(r'ي{2,}'), 'ي')
        .replaceAll(RegExp(r'و{2,}'), 'و');
  }

  String _arabicWordToEnglish(String word) {
    final known = _arabicToEnglishNames[word.trim()];
    if (known != null) return known;

    const letters = <String, String>{
      'ا': 'a',
      'أ': 'a',
      'إ': 'i',
      'آ': 'aa',
      'ب': 'b',
      'ت': 't',
      'ث': 'th',
      'ج': 'j',
      'ح': 'h',
      'خ': 'kh',
      'د': 'd',
      'ذ': 'dh',
      'ر': 'r',
      'ز': 'z',
      'س': 's',
      'ش': 'sh',
      'ص': 's',
      'ض': 'd',
      'ط': 't',
      'ظ': 'z',
      'ع': 'a',
      'غ': 'gh',
      'ف': 'f',
      'ق': 'q',
      'ك': 'k',
      'ل': 'l',
      'م': 'm',
      'ن': 'n',
      'ه': 'h',
      'ة': 'a',
      'و': 'w',
      'ؤ': 'o',
      'ي': 'y',
      'ى': 'a',
      'ئ': 'e',
      'ء': '',
    };

    final buffer = StringBuffer();
    for (final rune in word.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(letters[char] ?? char);
    }

    return _capitalizeEnglishWords(buffer.toString());
  }

  String _nameToArabic(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_englishWordToArabic)
        .join(' ');
  }

  String _nameToEnglish(String value) {
    final fullKnown = _arabicToEnglishNames[value.trim()];
    if (fullKnown != null) return fullKnown;

    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_arabicWordToEnglish)
        .join(' ');
  }

  String translateDoctorName(String name) {
    var value = name
        .trim()
        .replaceAll(RegExp(r'^(Dr\.?|Doctor)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(الدكتور|دكتور|د\.)\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (value.isEmpty) return AppStrings.doctor;

    if (AppStrings.isArabic) {
      if (!_containsArabic(value)) {
        value = _nameToArabic(value);
      }

      return value.startsWith('د.') ? value : 'د. $value';
    }

    if (_containsArabic(value)) {
      value = _nameToEnglish(value);
    } else {
      value = _capitalizeEnglishWords(value);
    }

    return value.toLowerCase().startsWith('dr.')
        ? value
        : 'Dr. $value';
  }

  String translateSpecialtyName(String name) {
    final original = name.trim();
    if (original.isEmpty) return AppStrings.specialist;

    final translatedByApp = AppStrings.specialtyByLanguage(original).trim();
    final value = translatedByApp.isNotEmpty ? translatedByApp : original;

    if (AppStrings.isArabic) {
      if (_containsArabic(value)) return value;

      final exact = _englishToArabicSpecialties[_normalizeKey(value)];
      if (exact != null) return exact;

      // تخصص غير موجود بالقاموس: يُكتب بالعربية صوتياً بدل بقائه إنجليزياً.
      return value
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .map(_englishWordToArabic)
          .join(' ');
    }

    if (!_containsArabic(value)) {
      return _capitalizeEnglishWords(value);
    }

    for (final entry in _englishToArabicSpecialties.entries) {
      if (_normalizeKey(entry.value) == _normalizeKey(value)) {
        return _capitalizeEnglishWords(entry.key);
      }
    }

    // تخصص عربي غير موجود بالقاموس: يُكتب بالإنجليزية صوتياً.
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_arabicWordToEnglish)
        .join(' ');
  }

  Future<void> changeDoctorImage(
      Map<String, dynamic> doctor,
      ) async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final doctorId = int.tryParse(
      (
          doctor['doctorId'] ??
              doctor['DoctorId'] ??
              doctor['id'] ??
              doctor['Id'] ??
              '0'
      ).toString(),
    ) ??
        0;

    if (doctorId <= 0) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.isArabic
                  ? 'جاري تحديث الصورة...'
                  : 'Updating image...',
            ),
          ),
        );
      }

      final bytes = await picked.readAsBytes();
      final fileName = picked.name.isNotEmpty
          ? picked.name
          : 'doctor.jpg';

      // 1) رفع الصورة وأخذ الرابط.
      final uploadedImageUrl =
      await ApiService.uploadDoctorImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      // 2) حفظ الرابط مع بيانات الطبيب.
      await ApiService.updateDoctor(
        doctorId: doctorId,
        fullName: (
            doctor['fullName'] ??
                doctor['FullName'] ??
                ''
        ).toString(),
        specialtyId: getDoctorSpecialtyId(doctor),
        phoneNumber: (
            doctor['phoneNumber'] ??
                doctor['PhoneNumber'] ??
                ''
        ).toString(),
        email: (
            doctor['email'] ??
                doctor['Email'] ??
                ''
        ).toString(),
        image: uploadedImageUrl.trim(),
      );

      // تحديث العنصر الحالي مباشرة قبل إعادة التحميل.
      doctor['image'] = uploadedImageUrl.trim();
      doctor['Image'] = uploadedImageUrl.trim();

      ApiService.clearDoctorsCache();

      if (!mounted) return;

      // الصورة تتحدث مباشرة من نفس العنصر بدون إعادة تحميل القائمة كاملة.
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.doctorImageUpdated),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.doctorImageUpdateFailed}: $e',
          ),
        ),
      );
    }
  }

  Future<void> openAddDoctor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
    );

    if (result == true) {
      refreshDoctors();
    }
  }

  Future<void> openEditDoctor(Map<String, dynamic> doctor) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditDoctorScreen(doctor: doctor),
      ),
    );

    if (result == true) {
      refreshDoctors();
    }
  }

  Future<void> deleteDoctor(int doctorId) async {
    await ApiService.deleteDoctor(doctorId);
    refreshDoctors();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.doctorDeleted)),
    );
  }

  Future<void> confirmDelete(int doctorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.deleteDoctor),
          content: Text(AppStrings.deleteDoctorConfirm),
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
        );
      },
    );

    if (confirm == true) {
      await deleteDoctor(doctorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.manageDoctors),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshDoctors,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: openAddDoctor,
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: doctorsFuture,
          initialData: cachedDoctors.isEmpty ? null : cachedDoctors,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                cachedDoctors.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && cachedDoctors.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.failedLoadDoctors,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final doctors = snapshot.data ?? cachedDoctors;

            if (doctors.isEmpty) {
              return Center(child: Text(AppStrings.noDoctorsFound));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];

                final doctorId =
                    int.tryParse(doctor['doctorId']?.toString() ?? '0') ?? 0;

                final imagePath = getDoctorImagePath(doctor);
                final specialtyName = getSpecialtyNameByLanguage(doctor);

                return RepaintBoundary(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 62,
                          height: 62,
                          child: doctorImage(imagePath),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getDoctorNameByLanguage(doctor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                textDirection: AppStrings.isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                specialtyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doctor['email']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 116,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: AppStrings.changeImage,
                                  icon: const Icon(
                                    Icons.image,
                                    color: Colors.purple,
                                    size: 24,
                                  ),
                                  onPressed: () => changeDoctorImage(doctor),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: AppStrings.edit,
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  onPressed: () => openEditDoctor(doctor),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: AppStrings.delete,
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  onPressed: () => confirmDelete(doctorId),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
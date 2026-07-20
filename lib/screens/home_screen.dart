import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import 'doctor_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();
  String searchText = '';
  int? selectedSpecialtyId;
  final ScrollController specialtiesScrollController = ScrollController();
  final PageController bannerController = PageController();

  int currentBannerIndex = 0;
  final ValueNotifier<int> bannerIndexNotifier = ValueNotifier<int>(0);
  Timer? bannerTimer;
  List<String> bannerImages = [];

  static const String bannersKey = 'home_banner_images';

  bool get isAdmin {
    final role = UserSession.role?.trim().toLowerCase() ?? '';
    return role == 'admin';
  }

  late Future<List<dynamic>> doctorsFuture;
  late Future<List<dynamic>> specialtiesFuture;

  List<dynamic> cachedDoctors = [];
  List<dynamic> cachedSpecialties = [];
  Timer? searchDebounce;

  @override
  void initState() {
    super.initState();

    // نعرض الأطباء من الكاش فوراً، ثم نحدّثهم بهدوء من السيرفر.
    // هذا لا يغيّر doctorId ولا مسار الحجز.
    doctorsFuture = _loadDoctorsFast();

    specialtiesFuture = ApiService.getSpecialties().then((data) {
      cachedSpecialties = List<dynamic>.from(data);
      return cachedSpecialties;
    });

    loadBanners();
  }

  Future<List<dynamic>> _loadDoctorsFast() async {
    try {
      // أولاً: استخدم كاش ApiService حتى تظهر البطاقات بأسرع وقت.
      final cachedData = await ApiService.getDoctors(forceRefresh: false);
      cachedDoctors = List<dynamic>.from(cachedData);

      // ثانياً: تحديث صامت من السيرفر بدون إخفاء الأطباء الموجودين.
      unawaited(_refreshDoctorsInBackground());

      return cachedDoctors;
    } catch (_) {
      // إذا لم يتوفر الكاش، نجلب من السيرفر مرة واحدة.
      final freshData = await ApiService.getDoctors(forceRefresh: true);
      cachedDoctors = List<dynamic>.from(freshData);
      return cachedDoctors;
    }
  }

  Future<void> _refreshDoctorsInBackground() async {
    try {
      final freshData = await ApiService.getDoctors(forceRefresh: true);
      if (!mounted) return;

      final freshDoctors = List<dynamic>.from(freshData);

      setState(() {
        cachedDoctors = freshDoctors;
        doctorsFuture = Future<List<dynamic>>.value(cachedDoctors);
      });
    } catch (_) {
      // نبقي الأطباء الموجودين ظاهرين إذا فشل التحديث.
    }
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    bannerTimer?.cancel();
    bannerController.dispose();
    bannerIndexNotifier.dispose();
    searchController.dispose();
    specialtiesScrollController.dispose();
    super.dispose();
  }


  Future<void> loadBanners() async {
    try {
      final data = await ApiService.getBanners(forceRefresh: false);

      final fixed = List<String>.filled(3, '');

      for (final banner in data) {
        if (banner is Map) {
          final position = int.tryParse(
            banner['position']?.toString() ??
                banner['Position']?.toString() ??
                '0',
          ) ??
              0;

          final image = banner['imageUrl']?.toString() ??
              banner['ImageUrl']?.toString() ??
              '';

          if (position >= 0 && position < 3 && image.trim().isNotEmpty) {
            fixed[position] = ApiService.fixImageUrl(image);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        bannerImages = fixed;
        currentBannerIndex = 0;
        bannerIndexNotifier.value = 0;
      });

      startBannerTimer();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        bannerImages = List<String>.filled(3, '');
        currentBannerIndex = 0;
        bannerIndexNotifier.value = 0;
      });
    }
  }

  Future<void> saveBanners() async {
    await loadBanners();
  }

  List<String> get activeBannerImages {
    return bannerImages.where((e) => e.trim().isNotEmpty).toList();
  }

  void startBannerTimer() {
    bannerTimer?.cancel();

    bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final images = activeBannerImages;

      if (!mounted || images.length < 2 || !bannerController.hasClients) {
        return;
      }

      final nextIndex = (currentBannerIndex + 1) % images.length;

      bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> pickBannerImage(int index) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 900,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    await ApiService.uploadBannerImageBytes(
      bytes: bytes,
      fileName: picked.name.isNotEmpty ? picked.name : 'banner.jpg',
      position: index,
    );

    await loadBanners();

    if (!mounted) return;

    if (bannerController.hasClients) {
      bannerController.jumpToPage(0);
    }

    startBannerTimer();
  }

  Future<void> deleteBannerImage(int index) async {
    await ApiService.deleteBannerImage(index);
    await loadBanners();

    if (!mounted) return;

    if (bannerController.hasClients) {
      bannerController.jumpToPage(0);
    }

    startBannerTimer();
  }

  Future<void> openBannerManager() async {
    if (!isAdmin) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: AppStrings.isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.isArabic
                        ? 'إدارة صور البنر'
                        : 'Manage Banner Images',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEDE7FF),
                            backgroundImage:
                            i < bannerImages.length && bannerImages[i].trim().isNotEmpty
                                ? bannerImageProvider(bannerImages[i])
                                : null,
                            child:
                            i >= bannerImages.length || bannerImages[i].trim().isEmpty
                                ? const Icon(
                              Icons.image,
                              color: Color(0xFF5B2EFF),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.isArabic
                                  ? 'صورة البنر ${i + 1}'
                                  : 'Banner Image ${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await pickBannerImage(i);
                              setSheetState(() {});
                            },
                            icon: const Icon(
                              Icons.upload_file,
                              color: Color(0xFF5B2EFF),
                            ),
                          ),
                          if (i < bannerImages.length && bannerImages[i].trim().isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                await deleteBannerImage(i);
                                setSheetState(() {});
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B2EFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.isArabic ? 'تم' : 'Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ImageProvider? bannerImageProvider(String image) {
    final value = image.trim();

    try {
      if (value.startsWith('data:image')) {
        return MemoryImage(base64Decode(value.split(',').last));
      }

      if (value.startsWith('http://') || value.startsWith('https://')) {
        return NetworkImage(value);
      }

      if (value.startsWith('assets/')) {
        return AssetImage(value);
      }
    } catch (_) {}

    return null;
  }

  Widget buildHomeBanner() {
    const primary = Color(0xFF5B2EFF);
    final images = activeBannerImages;
    final hasImages = images.isNotEmpty;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: hasImages
                ? PageView.builder(
              controller: bannerController,
              itemCount: images.length,
              onPageChanged: (index) {
                currentBannerIndex = index;
                bannerIndexNotifier.value = index;
              },
              itemBuilder: (context, index) {
                final image = images[index].trim();

                if (image.startsWith('http://') || image.startsWith('https://')) {
                  return CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 190,
                    fadeInDuration: Duration.zero,
                    memCacheWidth: 900,
                    placeholder: (_, __) => defaultBanner(),
                    errorWidget: (_, __, ___) => defaultBanner(),
                  );
                }

                final provider = bannerImageProvider(image);

                if (provider == null) return defaultBanner();

                return Image(
                  image: provider,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 190,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                );
              },
            )
                : defaultBanner(),
          ),
        ),
        if (hasImages)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: bannerIndexNotifier,
              builder: (context, bannerIndex, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final selected = bannerIndex == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white70,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        if (isAdmin)
          Positioned(
            top: 10,
            right: AppStrings.isArabic ? null : 10,
            left: AppStrings.isArabic ? 10 : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: openBannerManager,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.90),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.edit,
                  color: primary,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget defaultBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A3CFF), Color(0xFF4D1FFF)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
        AppStrings.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.needConsultation,
            textAlign: AppStrings.isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.bookAppointmentMessage,
            textAlign: AppStrings.isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }


  ImageProvider getUserImage() {
    final image = UserSession.profileImage ?? '';

    if (image.startsWith('data:image')) {
      return MemoryImage(base64Decode(image.split(',').last));
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return CachedNetworkImageProvider(image);
    }

    if (image.startsWith('assets/')) {
      return AssetImage(image);
    }

    return const AssetImage('assets/images/profile.jpg');
  }

  String getDoctorImage(dynamic doctor) {
    if (doctor is! Map) {
      return 'assets/images/profile.jpg';
    }

    final possibleImages = <dynamic>[
      doctor['image'],
      doctor['Image'],
      doctor['doctorImage'],
      doctor['DoctorImage'],
      doctor['imageUrl'],
      doctor['ImageUrl'],
      doctor['profileImage'],
      doctor['ProfileImage'],
      doctor['photo'],
      doctor['Photo'],
    ];

    String image = '';

    for (final value in possibleImages) {
      final candidate = value?.toString().trim() ?? '';

      if (candidate.isNotEmpty &&
          candidate.toLowerCase() != 'string' &&
          candidate.toLowerCase() != 'null') {
        image = candidate;
        break;
      }
    }

    if (image.isEmpty) {
      return 'assets/images/profile.jpg';
    }

    return ApiService.fixImageUrl(image);
  }

  int getDoctorSpecialtyId(dynamic doctor) {
    if (doctor is! Map) return 0;

    final rawId =
        doctor['specialtyId'] ??
            doctor['SpecialtyId'] ??
            doctor['id'] ??
            doctor['Id'];

    final directId =
    rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (directId != null && directId > 0) return directId;

    final nav =
        doctor['specialtyNavigation'] ?? doctor['SpecialtyNavigation'];

    if (nav is Map) {
      final nested =
          nav['specialtyId'] ??
              nav['SpecialtyId'] ??
              nav['id'] ??
              nav['Id'];

      return nested is int
          ? nested
          : int.tryParse(nested?.toString() ?? '') ?? 0;
    }

    return 0;
  }

  int getDoctorId(dynamic doctor) {
    if (doctor is! Map) return 0;

    final rawId =
        doctor['doctorId'] ??
            doctor['DoctorId'] ??
            doctor['id'] ??
            doctor['Id'];

    return rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('د.', '')
        .replaceAll('dr.', '')
        .replaceAll('dr', '')
        .replaceAll('.', '')
        .trim();
  }

  String translateSpecialty(String name) {
    return AppStrings.specialtyByLanguage(name);
  }

  String translateDoctorName(String name) {
    return AppStrings.doctorNameByLanguage(name);
  }

  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'medical_services':
        return Icons.medical_services;
      case 'psychology':
        return Icons.psychology;
      case 'child_care':
        return Icons.child_care;
      case 'visibility':
        return Icons.visibility;
      case 'face':
        return Icons.face;
      case 'healing':
        return Icons.healing;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'vaccines':
        return Icons.vaccines;
      case 'elderly':
        return Icons.elderly;
      default:
        return Icons.medical_services;
    }
  }

  String getFirstDoctorName(String fullName) {
    final normalizedName = normalizeText(fullName);

    if (normalizedName.isEmpty) return '';

    final parts = normalizedName
        .split(RegExp(r'\\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';

    return parts.first;
  }

  bool matchesSearch({
    required String search,
    required String name,
    required String specialty,
  }) {
    final normalizedSearch = normalizeText(search);

    if (normalizedSearch.isEmpty) return true;

    final originalFirstName = getFirstDoctorName(name);
    final translatedFirstName = getFirstDoctorName(
      translateDoctorName(name),
    );

    return originalFirstName.startsWith(normalizedSearch) ||
        translatedFirstName.startsWith(normalizedSearch);
  }

  void onSearchChanged(String value) {
    searchDebounce?.cancel();

    searchDebounce = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;

      final nextValue = value.trim();
      if (nextValue == searchText) return;

      setState(() {
        searchText = nextValue;
      });
    });
  }

  void clearSearch() {
    searchDebounce?.cancel();
    searchController.clear();

    if (searchText.isEmpty) return;

    setState(() {
      searchText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: SafeArea(
          child: Center(
            child: Container(
              width: 390,
              padding: const EdgeInsets.all(18),
              child: ListView(
                children: [
                  Row(
                    textDirection:
                    AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      const Text(
                        'MedLink',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEDE7FF),
                        backgroundImage: getUserImage(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  buildHomeBanner(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    textAlign: AppStrings.isArabic
                        ? TextAlign.right
                        : TextAlign.left,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchDoctors,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: clearSearch,
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppStrings.specialties,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<dynamic>>(
                    future: specialtiesFuture,
                    initialData:
                    cachedSpecialties.isEmpty ? null : cachedSpecialties,
                    builder: (context, snapshot) {
                      final specialties =
                          snapshot.data ?? cachedSpecialties;

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          cachedSpecialties.isEmpty) {
                        return const SizedBox(
                          height: 118,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (specialties.isEmpty) {
                        return Text(AppStrings.noSpecialtiesFound);
                      }

                      return SizedBox(
                        height: 128,
                        width: double.infinity,
                        child: Directionality(
                          textDirection: AppStrings.isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.stylus,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: RawScrollbar(
                              controller: specialtiesScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              interactive: true,
                              thickness: 6,
                              radius: const Radius.circular(20),
                              thumbColor: Colors.grey,
                              trackColor: Colors.white,
                              child: ListView.separated(
                                controller: specialtiesScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                primary: false,
                                padding: const EdgeInsets.only(
                                  left: 2,
                                  right: 2,
                                  bottom: 14,
                                ),
                                itemCount: specialties.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final specialty = specialties[index];

                                  final id = int.tryParse(
                                    specialty['specialtyId']?.toString() ?? '',
                                  ) ??
                                      0;

                                  final name =
                                      specialty['name']?.toString() ?? '';
                                  final icon =
                                      specialty['icon']?.toString() ?? '';

                                  return SpecialtyCard(
                                    icon: getIconData(icon),
                                    title: translateSpecialty(name),
                                    isSelected: selectedSpecialtyId == id,
                                    onTap: () {
                                      setState(() {
                                        selectedSpecialtyId =
                                        selectedSpecialtyId == id
                                            ? null
                                            : id;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Text(
                    AppStrings.featuredDoctors,
                    textAlign:
                    AppStrings.isArabic ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<dynamic>>(
                    future: doctorsFuture,
                    initialData: cachedDoctors.isEmpty ? null : cachedDoctors,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          cachedDoctors.isEmpty) {
                        return const SizedBox(
                          height: 42,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError && cachedDoctors.isEmpty) {
                        return Text(
                          AppStrings.failedLoadDoctors,
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      final doctors = snapshot.data ?? cachedDoctors;
                      final specialties = cachedSpecialties;

                      final specialtyNames = <int, String>{};

                      for (final specialty in specialties) {
                        final id = int.tryParse(
                          specialty['specialtyId']?.toString() ?? '',
                        ) ??
                            0;
                        final name = specialty['name']?.toString() ?? '';
                        specialtyNames[id] = name;
                      }

                      final filteredDoctors = doctors.where((doctor) {
                        final name = doctor['fullName']?.toString() ?? '';
                        final specialtyId = getDoctorSpecialtyId(doctor);
                        final specialtyName =
                            specialtyNames[specialtyId] ?? AppStrings.specialist;

                        final matchSpecialty = selectedSpecialtyId == null ||
                            selectedSpecialtyId == specialtyId;

                        return matchSpecialty &&
                            matchesSearch(
                              search: searchText,
                              name: name,
                              specialty: specialtyName,
                            );
                      }).toList();

                      if (filteredDoctors.isEmpty) {
                        return Text(AppStrings.noDoctorsFound);
                      }

                      return Column(
                        children: List.generate(filteredDoctors.length, (index) {
                          final doctor = filteredDoctors[index];
                          final doctorId = getDoctorId(doctor);

                          final specialtyId = getDoctorSpecialtyId(doctor);
                          final specialtyName =
                              specialtyNames[specialtyId] ?? AppStrings.specialist;

                          final imagePath = getDoctorImage(doctor);
                          final originalName = (
                              doctor['fullName'] ??
                                  doctor['FullName'] ??
                                  doctor['name'] ??
                                  doctor['Name'] ??
                                  AppStrings.doctor
                          ).toString();

                          return RepaintBoundary(
                            child: DoctorCard(
                              key: ValueKey(doctorId),
                              name: translateDoctorName(originalName),
                              specialty: translateSpecialty(specialtyName),
                              rating: '4.8',
                              time: '10:30 AM',
                              doctorId: doctorId,
                              imagePath: imagePath,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpecialtyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SpecialtyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 88,
        height: 108,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : primary, size: 28),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorCard extends StatefulWidget {
  final String name;
  final String specialty;
  final String rating;
  final String time;
  final int doctorId;
  final String imagePath;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.time,
    required this.doctorId,
    required this.imagePath,
  });

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  Widget doctorImage() {
    final image = widget.imagePath.trim();

    if (image.startsWith('data:image')) {
      try {
        final base64Part = image.split(',').last;

        return ClipOval(
          child: Image.memory(
            base64Decode(base64Part),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        );
      } catch (_) {
        return defaultImage();
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: kIsWeb
            ? Image.network(
          image,
          key: ValueKey<String>(image),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return defaultImage();
          },
          errorBuilder: (_, __, ___) => defaultImage(),
        )
            : CachedNetworkImage(
          imageUrl: image,
          key: ValueKey<String>(image),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (_, __) => defaultImage(),
          errorWidget: (_, __, ___) => defaultImage(),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEDE7FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => defaultImage(),
        ),
      );
    }

    return defaultImage();
  }

  Widget defaultImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEDE7FF),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/profile.jpg',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(
              doctorId: widget.doctorId,
              name: widget.name,
              specialty: widget.specialty,
              rating: widget.rating,
              time: widget.time,
              imagePath: widget.imagePath,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: doctorImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: AppStrings.isArabic
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.name,
                      textDirection: AppStrings.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign: AppStrings.isArabic
                          ? TextAlign.right
                          : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.specialty,
                      textDirection: AppStrings.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign: AppStrings.isArabic
                          ? TextAlign.right
                          : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AppStrings.isArabic
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                          Text(' ${widget.rating}'),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          Text(' ${widget.time}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 74,
              height: 38,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailsScreen(
                        doctorId: widget.doctorId,
                        name: widget.name,
                        specialty: widget.specialty,
                        rating: widget.rating,
                        time: widget.time,
                        imagePath: widget.imagePath,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppStrings.book),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

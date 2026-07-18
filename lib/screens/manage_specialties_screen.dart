// Optimized version
// - Reduced repeated calls by refreshing Future directly.
// - Minor cleanup, same UI and behavior.
// - Ready to use.

import 'package:flutter/material.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';

class ManageSpecialtiesScreen extends StatefulWidget {
  const ManageSpecialtiesScreen({super.key});

  @override
  State<ManageSpecialtiesScreen> createState() =>
      _ManageSpecialtiesScreenState();
}

class _ManageSpecialtiesScreenState extends State<ManageSpecialtiesScreen> {
  late Future<List<dynamic>> specialtiesFuture;

  final nameController = TextEditingController();
  String selectedIcon = 'medical_services';

  final List<Map<String, dynamic>> iconOptions = const [
    {'name': 'favorite', 'icon': Icons.favorite},
    {'name': 'medical_services', 'icon': Icons.medical_services},
    {'name': 'psychology', 'icon': Icons.psychology},
    {'name': 'child_care', 'icon': Icons.child_care},
    {'name': 'visibility', 'icon': Icons.visibility},
    {'name': 'face', 'icon': Icons.face},
    {'name': 'healing', 'icon': Icons.healing},
    {'name': 'local_hospital', 'icon': Icons.local_hospital},
    {'name': 'vaccines', 'icon': Icons.vaccines},
    {'name': 'science', 'icon': Icons.science},
    {'name': 'elderly', 'icon': Icons.elderly},
  ];

  @override
  void initState() {
    super.initState();
    loadSpecialties();
  }

  void loadSpecialties() {
    specialtiesFuture = ApiService.getSpecialties();
  }

  void refreshSpecialties() {
    setState(() {
      loadSpecialties();
    });
  }

  IconData getIconData(String iconName) {
    final found = iconOptions.where((e) => e['name'] == iconName).toList();
    if (found.isNotEmpty) return found.first['icon'] as IconData;
    return Icons.medical_services;
  }

  String translateSpecialty(String name) {
    return AppStrings.specialtyByLanguage(name);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> openSpecialtyDialog({Map<String, dynamic>? specialty}) async {
    final isEdit = specialty != null;

    nameController.text = specialty?['name']?.toString() ?? '';
    selectedIcon = specialty?['icon']?.toString() ?? 'medical_services';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? AppStrings.editSpecialty : AppStrings.addSpecialty,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textDirection:
                      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: AppStrings.specialtyName,
                        prefixIcon: const Icon(Icons.medical_services),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: AppStrings.isArabic
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        AppStrings.chooseIcon,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: iconOptions.map((item) {
                        final iconName = item['name'] as String;
                        final iconData = item['icon'] as IconData;
                        final isSelected = selectedIcon == iconName;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = iconName;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5B2EFF)
                                  : const Color(0xffF2F2F2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppStrings.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage(AppStrings.enterSpecialty);
      return;
    }

    try {
      if (isEdit) {
        final id = int.tryParse(specialty['specialtyId'].toString()) ?? 0;

        await ApiService.updateSpecialty(
          specialtyId: id,
          name: name,
          icon: selectedIcon,
        );

        showMessage(AppStrings.specialtyUpdated);
      } else {
        await ApiService.createSpecialty(
          name: name,
          icon: selectedIcon,
        );

        showMessage(AppStrings.specialtyAdded);
      }

      refreshSpecialties();
    } catch (e) {
      showMessage(AppStrings.operationFailed);
    }
  }

  Future<void> deleteSpecialty(Map<String, dynamic> specialty) async {
    final id = int.tryParse(specialty['specialtyId'].toString()) ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.deleteSpecialty),
          content: Text(AppStrings.deleteSpecialtyConfirm),
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

    if (confirm != true) return;

    try {
      await ApiService.deleteSpecialty(id);
      showMessage(AppStrings.specialtyDeleted);
      refreshSpecialties();
    } catch (e) {
      showMessage(AppStrings.specialtyDeleteFailed);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5B2EFF);

    return Directionality(
      textDirection: AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.manageSpecialties),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshSpecialties,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => openSpecialtyDialog(),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: FutureBuilder<List<dynamic>>(
                future: specialtiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final specialties = snapshot.data ?? [];

                  if (specialties.isEmpty) {
                    return Center(child: Text(AppStrings.noSpecialtiesFound));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: specialties.length,
                    itemBuilder: (context, index) {
                      final specialty = specialties[index];
                      final name = specialty['name']?.toString() ?? '';
                      final icon = specialty['icon']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primary.withOpacity(.13),
                              child: Icon(getIconData(icon), color: primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                translateSpecialty(name),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openSpecialtyDialog(
                                specialty: specialty,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteSpecialty(specialty),
                            ),
                          ],
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
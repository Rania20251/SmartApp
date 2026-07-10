import 'package:flutter/material.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';

class ManageMedicalRecordsScreen extends StatefulWidget {
  const ManageMedicalRecordsScreen({super.key});

  @override
  State<ManageMedicalRecordsScreen> createState() =>
      _ManageMedicalRecordsScreenState();
}

class _ManageMedicalRecordsScreenState
    extends State<ManageMedicalRecordsScreen> {
  late Future<List<dynamic>> recordsFuture;

  @override
  void initState() {
    super.initState();
    recordsFuture = ApiService.getMedicalRecords();
  }

  void refreshRecords() {
    setState(() {
      recordsFuture = ApiService.getMedicalRecords();
    });
  }

  Future<void> deleteRecord(int recordId) async {
    try {
      await ApiService.deleteMedicalRecord(recordId);

      if (!mounted) return;

      refreshRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.recordDeleted)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.failedLoadRecords)),
      );
    }
  }

  Future<void> confirmDelete(int recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection:
        AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            AppStrings.deleteRecord,
            textAlign:
            AppStrings.isArabic ? TextAlign.right : TextAlign.left,
          ),
          content: Text(
            AppStrings.deleteRecordConfirmShort,
            textAlign:
            AppStrings.isArabic ? TextAlign.right : TextAlign.left,
          ),
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

    if (confirm == true) {
      await deleteRecord(recordId);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Directionality(
      textDirection:
      AppStrings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8FC),
        appBar: AppBar(
          title: Text(AppStrings.manageMedicalRecords),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: AppStrings.isArabic ? 'تحديث' : 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: refreshRecords,
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppStrings.failedLoadRecords,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final records = snapshot.data ?? [];

            if (records.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.noMedicalRecordsFound,
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                final recordId = int.tryParse(
                  record['recordId']?.toString() ?? '0',
                ) ??
                    0;

                final title =
                    record['title']?.toString() ??
                        AppStrings.medicalRecord;

                final description =
                    record['description']?.toString() ?? '';

                final patientId =
                    record['patientId']?.toString() ?? '';

                final doctorId =
                    record['doctorId']?.toString() ?? '';

                final recordDate =
                    record['recordDate']?.toString() ?? '';

                final status =
                    record['status']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    textDirection: AppStrings.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xffEDE7FF),
                        child: Icon(
                          Icons.description,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: AppStrings.isArabic
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                title,
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
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                description,
                                textDirection: AppStrings.isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                '${AppStrings.patientId}: $patientId',
                                textDirection: AppStrings.isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                '${AppStrings.doctorId}: $doctorId',
                                textDirection: AppStrings.isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                recordDate,
                                textDirection: TextDirection.ltr,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                status,
                                textDirection: AppStrings.isArabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                textAlign: AppStrings.isArabic
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: AppStrings.delete,
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => confirmDelete(recordId),
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

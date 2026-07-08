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
      builder: (_) => AlertDialog(
        title: Text(AppStrings.deleteRecord),
        content: Text(AppStrings.deleteRecordConfirmShort),
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
    );

    if (confirm == true) {
      await deleteRecord(recordId);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff5B2EFF);

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.manageMedicalRecords),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshRecords,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppStrings.failedLoadRecords,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(child: Text(AppStrings.noMedicalRecordsFound));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final recordId = int.tryParse(record['recordId']?.toString() ?? '0') ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xffEDE7FF),
                      child: Icon(Icons.description, color: primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['title']?.toString() ?? AppStrings.medicalRecord,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record['description']?.toString() ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text('${AppStrings.patientId}: ${record['patientId']}'),
                          Text('${AppStrings.doctorId}: ${record['doctorId']}'),
                          const SizedBox(height: 6),
                          Text(record['recordDate']?.toString() ?? ''),
                          const SizedBox(height: 6),
                          Text(
                            record['status']?.toString() ?? '',
                            style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmDelete(recordId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

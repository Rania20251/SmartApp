import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late Future<List<dynamic>> recordsFuture;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  void loadRecords() {
    recordsFuture = ApiService.getMedicalRecordsByUser(UserSession.userId ?? 0);
  }

  void refreshRecords() {
    setState(() {
      loadRecords();
    });
  }

  String getFileName(String path) {
    if (path.isEmpty) return '';
    return path.split('/').last.split('\\').last;
  }

  IconData getFileIcon(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;

    if (name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png')) {
      return Icons.image;
    }

    return Icons.insert_drive_file;
  }

  Future<void> openFileUrl(String fileUrl) async {
    if (fileUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.noFileFound)),
      );
      return;
    }

    final uri = Uri.parse(fileUrl);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.couldNotOpenFile)),
      );
    }
  }

  Future<void> uploadReport() async {
    if (isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) return;

    final file = result.files.single;
    final fileName = file.name;
    final filePath = file.path;

    if (filePath == null || filePath.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.filePathNotFound)),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      await ApiService.uploadMedicalRecord(
        patientId: UserSession.userId ?? 0,
        doctorId: 1,
        title: fileName,
        description: AppStrings.uploadedMedicalReport,
        status: AppStrings.uploaded,
        filePath: filePath,
      );

      refreshRecords();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.reportUploaded)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.uploadFailed}: $e')),
      );
    }

    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> deleteRecord(int recordId) async {
    try {
      await ApiService.deleteMedicalRecord(recordId);
      refreshRecords();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.recordDeleted)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.deleteRecordFailed)),
      );
    }
  }

  Future<void> confirmDelete(int recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.deleteRecord),
          content: Text(AppStrings.deleteRecordConfirm),
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
      await deleteRecord(recordId);
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return '';

    final text = value.toString();

    if (text.contains('T')) return text.split('T').first;
    if (text.contains(' ')) return text.split(' ').first;

    return text;
  }

  Widget uploadBox() {
    const primary = Color(0xff5B2EFF);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload, size: 42, color: primary),
          const SizedBox(height: 10),
          Text(
            AppStrings.uploadMedicalReport,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'PDF, JPG, JPEG, PNG',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : uploadReport,
              icon: isUploading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.upload_file),
              label: Text(
                isUploading ? AppStrings.uploading : AppStrings.chooseFile,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget recordCard(dynamic record) {
    const primary = Color(0xff5B2EFF);

    final recordId = int.tryParse(record['recordId']?.toString() ?? '0') ?? 0;

    final fileUrl = record['fileUrl']?.toString() ?? '';
    final fileName = getFileName(fileUrl);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xffEDE7FF),
            child: Icon(getFileIcon(fileName), color: primary),
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
                const SizedBox(height: 6),
                Text(
                  record['description']?.toString() ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text('${AppStrings.date}: ${formatDate(record['recordDate'])}'),
                const SizedBox(height: 8),
                Text(
                  record['status']?.toString() ?? '',
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (fileUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: InkWell(
                      onTap: () => openFileUrl(fileUrl),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      appBar: AppBar(
        title: Text(AppStrings.medicalRecords),
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
      body: Column(
        children: [
          uploadBox(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppStrings.failedLoadMedicalRecords,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Center(child: Text(AppStrings.noMedicalRecordsFound));
                }

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return recordCard(records[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

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
  static const Color primary = Color(0xff5B2EFF);
  static const Color background = Color(0xffF7F8FC);
  static const Color lightPurple = Color(0xffEDE7FF);

  late Future<List<dynamic>> recordsFuture;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    recordsFuture = getRecords();
  }

  Future<List<dynamic>> getRecords() {
    return ApiService.getMedicalRecordsByUser(UserSession.userId ?? 0);
  }

  void refreshRecords() {
    setState(() {
      recordsFuture = getRecords();
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String getFileName(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('data:')) return 'uploaded_file';

    final slashIndex = path.lastIndexOf('/');
    final backSlashIndex = path.lastIndexOf('\\');
    final index = slashIndex > backSlashIndex ? slashIndex : backSlashIndex;

    return index == -1 ? path : path.substring(index + 1);
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

  String mimeType(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';

    return 'application/octet-stream';
  }

  Future<void> openFileUrl(String fileUrl) async {
    final url = fileUrl.trim();

    if (url.isEmpty) {
      showMessage(AppStrings.noFileFound);
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      showMessage(AppStrings.couldNotOpenFile);
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      showMessage(AppStrings.couldNotOpenFile);
    }
  }

  Future<void> uploadReport() async {
    if (isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;
    final fileName = file.name;
    final bytes = file.bytes;

    if (bytes == null) {
      showMessage(AppStrings.filePathNotFound);
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final fileUrl = 'data:${mimeType(fileName)};base64,${base64Encode(bytes)}';

      await ApiService.createMedicalRecord(
        patientId: UserSession.userId ?? 0,
        doctorId: 1,
        title: fileName,
        description: AppStrings.uploadedMedicalReport,
        recordDate: DateTime.now().toIso8601String(),
        status: AppStrings.uploaded,
        fileUrl: fileUrl,
      );

      if (!mounted) return;

      setState(() {
        recordsFuture = getRecords();
        isUploading = false;
      });

      showMessage(AppStrings.reportUploaded);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      showMessage('${AppStrings.uploadFailed}: $e');
    }
  }

  Future<void> deleteRecord(int recordId) async {
    try {
      await ApiService.deleteMedicalRecord(recordId);

      if (!mounted) return;

      setState(() {
        recordsFuture = getRecords();
      });

      showMessage(AppStrings.recordDeleted);
    } catch (_) {
      showMessage(AppStrings.deleteRecordFailed);
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

    final tIndex = text.indexOf('T');
    if (tIndex != -1) return text.substring(0, tIndex);

    final spaceIndex = text.indexOf(' ');
    if (spaceIndex != -1) return text.substring(0, spaceIndex);

    return text;
  }

  Widget uploadBox() {
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
                disabledBackgroundColor: primary.withOpacity(.65),
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
    final recordId = int.tryParse(record['recordId']?.toString() ?? '0') ?? 0;

    final fileUrl = record['fileUrl']?.toString() ?? '';
    final title = record['title']?.toString() ?? AppStrings.medicalRecord;
    final description = record['description']?.toString() ?? '';
    final status = record['status']?.toString() ?? '';
    final date = formatDate(record['recordDate']);
    final fileName = fileUrl.startsWith('data:') ? title : getFileName(fileUrl);
    final icon = getFileIcon(fileName);

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
            backgroundColor: lightPurple,
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text('${AppStrings.date}: $date'),
                const SizedBox(height: 8),
                Text(
                  status,
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
      backgroundColor: background,
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
                  itemBuilder: (context, index) => recordCard(records[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
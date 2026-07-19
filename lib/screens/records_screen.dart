import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/file_downloader_stub.dart'
if (dart.library.html) '../services/file_downloader_web.dart';
import '../services/user_session.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  static const Color primary = Color(0xFF5B2EFF);
  static const Color background = Color(0xFFF7F8FC);
  static const Color lightPurple = Color(0xFFEDE7FF);

  late Future<List<dynamic>> recordsFuture;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    recordsFuture = getRecords();
  }

  Future<List<dynamic>> getRecords() async {
    final patientId = UserSession.userId ?? 0;

    if (patientId <= 0) {
      throw Exception('Invalid patient id');
    }

    return ApiService.getMedicalRecordsByUser(patientId);
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
        name.endsWith('.png') ||
        name.endsWith('.webp')) {
      return Icons.image;
    }

    return Icons.insert_drive_file;
  }

  String mimeType(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';

    return 'application/octet-stream';
  }


  Uint8List? decodeDataFile(String fileUrl) {
    try {
      final commaIndex = fileUrl.indexOf(',');
      if (commaIndex < 0) return null;
      return base64Decode(fileUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  bool isImageFile(String fileName, String fileUrl) {
    final value = '$fileName $fileUrl'.toLowerCase();

    return value.contains('data:image') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.png') ||
        value.endsWith('.webp');
  }

  Future<Uint8List?> loadFileBytes(String fileUrl) async {
    final cleanUrl = ApiService.fixFileUrl(fileUrl);

    if (cleanUrl.startsWith('data:')) {
      return decodeDataFile(cleanUrl);
    }

    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) return null;

    try {
      final response =
      await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}

    return null;
  }

  String detectFileExtension({
    required String fileUrl,
    required Uint8List bytes,
  }) {
    final lowerUrl = fileUrl.toLowerCase();

    if (lowerUrl.startsWith('data:application/pdf')) return '.pdf';
    if (lowerUrl.startsWith('data:image/png')) return '.png';
    if (lowerUrl.startsWith('data:image/jpeg') ||
        lowerUrl.startsWith('data:image/jpg')) {
      return '.jpg';
    }
    if (lowerUrl.startsWith('data:image/webp')) return '.webp';

    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return '.pdf';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return '.png';
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return '.jpg';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return '.webp';
    }

    final cleanPath = fileUrl.split('?').first.split('#').first.toLowerCase();

    for (final extension in const ['.pdf', '.jpg', '.jpeg', '.png', '.webp']) {
      if (cleanPath.endsWith(extension)) {
        return extension == '.jpeg' ? '.jpg' : extension;
      }
    }

    return '';
  }

  String safeDownloadName({
    required String fileName,
    required String fileUrl,
    required Uint8List bytes,
  }) {
    var name = fileName.trim();

    if (name.isEmpty || name == 'uploaded_file') {
      name = 'medical_report';
    }

    name = name.replaceAll(
      RegExp(r'\.(pdf|jpg|jpeg|png|webp)$', caseSensitive: false),
      '',
    );

    final extension = detectFileExtension(
      fileUrl: fileUrl,
      bytes: bytes,
    );

    final cleanName = name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');

    return extension.isEmpty ? cleanName : '$cleanName$extension';
  }

  Future<void> downloadFile({
    required String fileUrl,
    required String fileName,
    bool openAfterSaving = false,
  }) async {
    final cleanUrl = ApiService.fixFileUrl(fileUrl);

    if (cleanUrl.isEmpty) {
      showMessage(AppStrings.noFileFound);
      return;
    }

    final bytes = await loadFileBytes(cleanUrl);

    if (bytes == null || bytes.isEmpty) {
      showMessage(
        AppStrings.isArabic
            ? 'تعذر تحميل الملف'
            : 'Could not download the file',
      );
      return;
    }

    final safeName = safeDownloadName(
      fileName: fileName,
      fileUrl: cleanUrl,
      bytes: bytes,
    );

    try {
      if (kIsWeb) {
        await downloadBytesOnWeb(
          bytes: bytes,
          fileName: safeName,
          mimeType: mimeType(safeName),
        );

        showMessage(
          AppStrings.isArabic
              ? 'تم تنزيل التقرير'
              : 'Report downloaded',
        );
        return;
      }

      final path = await FilePicker.platform.saveFile(
        dialogTitle:
        AppStrings.isArabic ? 'حفظ التقرير الطبي' : 'Save medical report',
        fileName: safeName,
        bytes: bytes,
      );

      if (path == null || path.trim().isEmpty) {
        return;
      }

      if (openAfterSaving) {
        final result = await OpenFilex.open(path);

        if (result.type != ResultType.done) {
          showMessage(
            AppStrings.isArabic
                ? 'تم حفظ الملف، لكن تعذر فتحه تلقائياً'
                : 'The file was saved but could not be opened automatically',
          );
          return;
        }
      }

      showMessage(
        openAfterSaving
            ? (AppStrings.isArabic ? 'تم فتح التقرير' : 'Report opened')
            : (AppStrings.isArabic ? 'تم تنزيل التقرير' : 'Report downloaded'),
      );
    } catch (_) {
      showMessage(
        AppStrings.isArabic
            ? 'تعذر حفظ التقرير'
            : 'Could not save the report',
      );
    }
  }

  Future<void> openFileUrl({
    required String fileUrl,
    required String fileName,
  }) async {
    final url = ApiService.fixFileUrl(fileUrl);

    if (url.isEmpty) {
      showMessage(AppStrings.noFileFound);
      return;
    }

    if (url.startsWith('data:')) {
      final bytes = decodeDataFile(url);

      if (bytes == null || bytes.isEmpty) {
        showMessage(AppStrings.couldNotOpenFile);
        return;
      }

      if (isImageFile(fileName, url)) {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            insetPadding: const EdgeInsets.all(18),
            child: Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                    maxHeight: 750,
                  ),
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: IconButton.filled(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      await downloadFile(
        fileUrl: url,
        fileName: fileName,
        openAfterSaving: true,
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri != null &&
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    await downloadFile(
      fileUrl: url,
      fileName: fileName,
      openAfterSaving: true,
    );
  }

  Future<void> uploadReport() async {
    if (isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
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
            'PDF, JPG, JPEG, PNG, WEBP',
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
                      onTap: () => openFileUrl(fileUrl: fileUrl, fileName: fileName),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: AppStrings.isArabic ? 'عرض التقرير' : 'View report',
                icon: const Icon(Icons.visibility, color: primary),
                onPressed: fileUrl.isEmpty
                    ? null
                    : () => openFileUrl(
                  fileUrl: fileUrl,
                  fileName: fileName,
                ),
              ),
              IconButton(
                tooltip:
                AppStrings.isArabic ? 'تنزيل التقرير' : 'Download report',
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: fileUrl.isEmpty
                    ? null
                    : () => downloadFile(
                  fileUrl: fileUrl,
                  fileName: fileName,
                ),
              ),
              IconButton(
                tooltip: AppStrings.delete,
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => confirmDelete(recordId),
              ),
            ],
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                uploadBox(),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: recordsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
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
                        return Center(
                          child: Text(
                            AppStrings.noMedicalRecordsFound,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) =>
                            recordCard(records[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
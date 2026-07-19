import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../language/app_strings.dart';
import '../services/api_service.dart';
import '../services/file_download_helper.dart';

class ManageMedicalRecordsScreen extends StatefulWidget {
  const ManageMedicalRecordsScreen({super.key});

  @override
  State<ManageMedicalRecordsScreen> createState() =>
      _ManageMedicalRecordsScreenState();
}

class _ManageMedicalRecordsScreenState
    extends State<ManageMedicalRecordsScreen> {
  static const Color primary = Color(0xFF5B2EFF);
  static const Color background = Color(0xFFF7F8FC);

  final List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRecords(showLoading: true);
  }

  Map<String, dynamic> _toRecordMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  Future<void> _loadRecords({required bool showLoading}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final List<dynamic> result = await ApiService.getMedicalRecords();

      if (!mounted) return;

      final List<Map<String, dynamic>> loadedRecords = result
          .map<Map<String, dynamic>>(_toRecordMap)
          .where((record) => record.isNotEmpty)
          .toList(growable: false);

      setState(() {
        _records
          ..clear()
          ..addAll(loadedRecords);

        _isLoading = false;
        _isRefreshing = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _loadError = AppStrings.failedLoadRecords;
      });
    }
  }

  Future<void> refreshRecords() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _loadError = null;
    });

    await _loadRecords(showLoading: false);
  }

  Future<void> deleteRecord(int recordId) async {
    if (recordId <= 0) return;

    final int index = _records.indexWhere(
          (record) =>
      int.tryParse(record['recordId']?.toString() ?? '0') == recordId,
    );

    if (index < 0) return;

    final Map<String, dynamic> removedRecord =
    Map<String, dynamic>.from(_records[index]);

    setState(() {
      _records.removeAt(index);
    });

    try {
      await ApiService.deleteMedicalRecord(recordId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.recordDeleted)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        final int safeIndex =
        index.clamp(0, _records.length).toInt();
        _records.insert(safeIndex, removedRecord);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.failedLoadRecords)),
      );
    }
  }

  Future<void> confirmDelete(int recordId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

  String _textValue(
      Map<String, dynamic> record,
      String key, {
        String fallback = '',
      }) {
    final String value = record[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }


  String _translateRecordText(String value) {
    var text = value.trim();

    if (text.isEmpty) return text;

    if (AppStrings.isArabic) {
      text = text
          .replaceAll(
        RegExp(
          r'Uploaded medical report',
          caseSensitive: false,
        ),
        'تقرير طبي مرفوع',
      )
          .replaceAll(
        RegExp(
          r'Medical report',
          caseSensitive: false,
        ),
        'تقرير طبي',
      )
          .replaceAll(
        RegExp(
          r'Medical record',
          caseSensitive: false,
        ),
        'سجل طبي',
      )
          .replaceAll(
        RegExp(
          r'Uploaded',
          caseSensitive: false,
        ),
        'تم الرفع',
      )
          .replaceAll(
        RegExp(
          r'Pending',
          caseSensitive: false,
        ),
        'قيد الانتظار',
      )
          .replaceAll(
        RegExp(
          r'Completed',
          caseSensitive: false,
        ),
        'مكتمل',
      )
          .replaceAll(
        RegExp(
          r'Confirmed',
          caseSensitive: false,
        ),
        'مؤكد',
      )
          .replaceAll(
        RegExp(
          r'Cancelled|Canceled',
          caseSensitive: false,
        ),
        'ملغي',
      );

      return text;
    }

    text = text
        .replaceAll('تقرير طبي مرفوع', 'Uploaded medical report')
        .replaceAll('تقرير طبي', 'Medical report')
        .replaceAll('السجل الطبي', 'Medical record')
        .replaceAll('سجل طبي', 'Medical record')
        .replaceAll('تم الرفع', 'Uploaded')
        .replaceAll('مرفوع', 'Uploaded')
        .replaceAll('قيد الانتظار', 'Pending')
        .replaceAll('مكتمل', 'Completed')
        .replaceAll('مؤكد', 'Confirmed')
        .replaceAll('ملغي', 'Cancelled')
        .replaceAll('ملغى', 'Cancelled');

    return text;
  }

  String _translateRecordTitle(String title) {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      return AppStrings.medicalRecord;
    }

    final lower = cleanTitle.toLowerCase();

    final looksLikeFileName =
        lower.endsWith('.pdf') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp');

    if (looksLikeFileName) {
      return cleanTitle;
    }

    return _translateRecordText(cleanTitle);
  }


  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _fileNameFromRecord({
    required String title,
    required String fileUrl,
  }) {
    final cleanTitle = title.trim();

    if (cleanTitle.isNotEmpty) {
      return cleanTitle;
    }

    final uri = Uri.tryParse(fileUrl);
    final pathName =
    uri == null || uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;

    if (pathName.trim().isNotEmpty) {
      return Uri.decodeComponent(pathName);
    }

    return 'medical_report';
  }

  String _detectFileExtension({
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

  String _safeDownloadName({
    required String fileName,
    required String fileUrl,
    required Uint8List bytes,
  }) {
    var name = fileName.trim();

    if (name.isEmpty) {
      name = 'medical_report';
    }

    name = name.replaceAll(
      RegExp(r'\.(pdf|jpg|jpeg|png|webp)$', caseSensitive: false),
      '',
    );

    final extension = _detectFileExtension(
      fileUrl: fileUrl,
      bytes: bytes,
    );

    final cleanName = name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');

    return extension.isEmpty ? cleanName : '$cleanName$extension';
  }

  String _mimeType(String fileName) {
    final name = fileName.toLowerCase();

    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';

    return 'application/octet-stream';
  }

  Uint8List? _decodeDataFile(String fileUrl) {
    try {
      final commaIndex = fileUrl.indexOf(',');
      if (commaIndex < 0) return null;
      return base64Decode(fileUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  bool _isImageFile(String fileName, String fileUrl) {
    final value = '$fileName $fileUrl'.toLowerCase();

    return value.contains('data:image') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.png') ||
        value.endsWith('.webp');
  }

  Future<Uint8List?> _loadFileBytes(String fileUrl) async {
    final cleanUrl = fileUrl.trim();

    if (cleanUrl.startsWith('data:')) {
      return _decodeDataFile(cleanUrl);
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

  Future<void> _saveFile({
    required String fileUrl,
    required String fileName,
    bool openAfterSaving = false,
  }) async {
    if (fileUrl.trim().isEmpty) {
      _showMessage(
        AppStrings.isArabic ? 'لا يوجد ملف مرفق' : 'No attached file',
      );
      return;
    }

    final bytes = await _loadFileBytes(fileUrl);

    if (bytes == null || bytes.isEmpty) {
      _showMessage(
        AppStrings.isArabic
            ? 'تعذر تحميل الملف'
            : 'Could not download the file',
      );
      return;
    }

    final safeName = _safeDownloadName(
      fileName: fileName,
      fileUrl: fileUrl,
      bytes: bytes,
    );

    try {
      final path = await saveDownloadedBytes(
        bytes: bytes,
        fileName: safeName,
        mimeType: _mimeType(safeName),
        dialogTitle:
        AppStrings.isArabic ? 'حفظ التقرير الطبي' : 'Save medical report',
      );

      if (path == null) {
        // المستخدم أغلق نافذة الحفظ على الهاتف أو سطح المكتب.
        return;
      }

      // على Chrome يبدأ التنزيل مباشرة ولا يوجد مسار محلي يمكن فتحه.
      if (path == webDownloadCompletedMarker) {
        _showMessage(
          AppStrings.isArabic ? 'تم تنزيل التقرير' : 'Report downloaded',
        );
        return;
      }

      if (openAfterSaving) {
        final result = await OpenFilex.open(path);

        if (result.type != ResultType.done) {
          _showMessage(
            AppStrings.isArabic
                ? 'تم حفظ الملف، لكن تعذر فتحه تلقائياً'
                : 'The file was saved but could not be opened automatically',
          );
          return;
        }
      }

      _showMessage(
        openAfterSaving
            ? (AppStrings.isArabic ? 'تم فتح التقرير' : 'Report opened')
            : (AppStrings.isArabic
            ? 'تم تنزيل التقرير'
            : 'Report downloaded'),
      );
    } catch (_) {
      _showMessage(
        AppStrings.isArabic
            ? 'تعذر حفظ التقرير'
            : 'Could not save the report',
      );
    }
  }

  Future<void> _viewFile({
    required String fileUrl,
    required String fileName,
  }) async {
    final cleanUrl = fileUrl.trim();

    if (cleanUrl.isEmpty) {
      _showMessage(
        AppStrings.isArabic ? 'لا يوجد ملف مرفق' : 'No attached file',
      );
      return;
    }

    if (cleanUrl.startsWith('data:')) {
      final bytes = _decodeDataFile(cleanUrl);

      if (bytes == null || bytes.isEmpty) {
        _showMessage(
          AppStrings.isArabic ? 'تعذر فتح الملف' : 'Could not open the file',
        );
        return;
      }

      if (_isImageFile(fileName, cleanUrl)) {
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

      await _saveFile(
        fileUrl: cleanUrl,
        fileName: fileName,
        openAfterSaving: true,
      );
      return;
    }

    final uri = Uri.tryParse(cleanUrl);

    if (uri != null &&
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    await _saveFile(
      fileUrl: cleanUrl,
      fileName: fileName,
      openAfterSaving: true,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: primary),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError ?? AppStrings.failedLoadRecords,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isRefreshing ? null : refreshRecords,
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.isArabic ? 'إعادة المحاولة' : 'Try again'),
              style: FilledButton.styleFrom(backgroundColor: primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: primary,
      onRefresh: refreshRecords,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(
              child: Text(
                AppStrings.noMedicalRecordsFound,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = AppStrings.isArabic;
    final TextDirection textDirection =
    isArabic ? TextDirection.rtl : TextDirection.ltr;
    final TextAlign textAlign =
    isArabic ? TextAlign.right : TextAlign.left;
    final CrossAxisAlignment crossAxisAlignment =
    isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(AppStrings.manageMedicalRecords),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: isArabic ? 'تحديث' : 'Refresh',
              onPressed: _isRefreshing ? null : refreshRecords,
              icon: _isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary,
                ),
              )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: _buildBody(
                textDirection: textDirection,
                textAlign: textAlign,
                crossAxisAlignment: crossAxisAlignment,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required TextDirection textDirection,
    required TextAlign textAlign,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_loadError != null && _records.isEmpty) {
      return _buildError();
    }

    if (_records.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: refreshRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        cacheExtent: 450,
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> record = _records[index];

          final int recordId =
              int.tryParse(record['recordId']?.toString() ?? '0') ?? 0;

          final String rawTitle = _textValue(
            record,
            'title',
            fallback: AppStrings.medicalRecord,
          );

          final String title = _translateRecordTitle(rawTitle);

          final String description = _translateRecordText(
            _textValue(record, 'description'),
          );

          final String patientId = _textValue(record, 'patientId');
          final String doctorId = _textValue(record, 'doctorId');
          final String recordDate = _textValue(record, 'recordDate');

          final String status = _translateRecordText(
            _textValue(record, 'status'),
          );

          final String fileUrl = _textValue(
            record,
            'fileUrl',
            fallback: _textValue(record, 'FileUrl'),
          );

          final String fileName = _fileNameFromRecord(
            title: rawTitle,
            fileUrl: fileUrl,
          );

          return _MedicalRecordCard(
            key: ValueKey<int>(recordId),
            title: title,
            description: description,
            patientId: patientId,
            doctorId: doctorId,
            recordDate: recordDate,
            status: status,
            fileName: fileName,
            hasFile: fileUrl.isNotEmpty,
            recordId: recordId,
            textDirection: textDirection,
            textAlign: textAlign,
            crossAxisAlignment: crossAxisAlignment,
            onView: fileUrl.isEmpty
                ? null
                : () => _viewFile(
              fileUrl: fileUrl,
              fileName: fileName,
            ),
            onDownload: fileUrl.isEmpty
                ? null
                : () => _saveFile(
              fileUrl: fileUrl,
              fileName: fileName,
            ),
            onDelete: recordId > 0 ? () => confirmDelete(recordId) : null,
          );
        },
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  const _MedicalRecordCard({
    super.key,
    required this.title,
    required this.description,
    required this.patientId,
    required this.doctorId,
    required this.recordDate,
    required this.status,
    required this.fileName,
    required this.hasFile,
    required this.recordId,
    required this.textDirection,
    required this.textAlign,
    required this.crossAxisAlignment,
    required this.onView,
    required this.onDownload,
    required this.onDelete,
  });

  static const Color primary = Color(0xFF5B2EFF);

  final String title;
  final String description;
  final String patientId;
  final String doctorId;
  final String recordDate;
  final String status;
  final String fileName;
  final bool hasFile;
  final int recordId;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        textDirection: textDirection,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEDE7FF),
            child: Icon(
              Icons.description,
              color: primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                _RecordText(
                  text: title,
                  textDirection: textDirection,
                  textAlign: textAlign,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _RecordText(
                    text: description,
                    textDirection: textDirection,
                    textAlign: textAlign,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _RecordText(
                  text: '${AppStrings.patientId}: $patientId',
                  textDirection: textDirection,
                  textAlign: textAlign,
                ),
                const SizedBox(height: 3),
                _RecordText(
                  text: '${AppStrings.doctorId}: $doctorId',
                  textDirection: textDirection,
                  textAlign: textAlign,
                ),
                if (hasFile) ...[
                  const SizedBox(height: 6),
                  Row(
                    textDirection: textDirection,
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 17,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          textAlign: textAlign,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (recordDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _RecordText(
                    text: recordDate,
                    textDirection: TextDirection.ltr,
                    textAlign: textAlign,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _RecordText(
                    text: status,
                    textDirection: textDirection,
                    textAlign: textAlign,
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: AppStrings.isArabic ? 'عرض التقرير' : 'View report',
                onPressed: onView,
                icon: Icon(
                  Icons.visibility,
                  color: hasFile ? primary : Colors.grey,
                ),
              ),
              IconButton(
                tooltip:
                AppStrings.isArabic ? 'تنزيل التقرير' : 'Download report',
                onPressed: onDownload,
                icon: Icon(
                  Icons.download,
                  color: hasFile ? Colors.blue : Colors.grey,
                ),
              ),
              IconButton(
                tooltip: AppStrings.delete,
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordText extends StatelessWidget {
  const _RecordText({
    required this.text,
    required this.textDirection,
    required this.textAlign,
    this.maxLines,
    this.style,
  });

  final String text;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textDirection: textDirection,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

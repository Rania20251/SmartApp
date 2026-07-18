import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

const String webDownloadCompletedMarker = '__WEB_DOWNLOAD_COMPLETED__';

Future<String?> saveDownloadedBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? dialogTitle,
}) async {
  try {
    // اختيار مكان الحفظ (Windows / Desktop)
    final String? output = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle ?? 'Save File',
      fileName: fileName,
      bytes: bytes,
    );

    if (output != null) {
      final file = File(output);
      await file.writeAsBytes(bytes, flush: true);
      return output;
    }

    // Android
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return path;
  } catch (_) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';

      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      return path;
    } catch (_) {
      return null;
    }
  }
}
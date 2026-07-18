import 'dart:typed_data';

Future<void> downloadBytesOnWeb({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  throw UnsupportedError(
    'downloadBytesOnWeb is only available on the web.',
  );
}
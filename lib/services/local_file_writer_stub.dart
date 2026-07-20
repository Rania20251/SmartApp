import 'dart:typed_data';

Future<void> writeBytesToLocalFile(
    String path,
    Uint8List bytes,
    ) async {
  throw UnsupportedError('Local file writing is not supported.');
}

Future<String> writeBytesToTemporaryFile(
    String fileName,
    Uint8List bytes,
    ) async {
  throw UnsupportedError('Temporary file writing is not supported.');
}

import 'dart:io';
import 'dart:typed_data';

Future<void> writeBytesToLocalFile(
    String path,
    Uint8List bytes,
    ) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<String> writeBytesToTemporaryFile(
    String fileName,
    Uint8List bytes,
    ) async {
  final safeName = fileName.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
  final path = '${Directory.systemTemp.path}${Platform.pathSeparator}$safeName';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

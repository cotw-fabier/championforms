import 'dart:io';

/// Writes a small text file in the system temp directory (the app's cache
/// dir on Android) and returns its absolute path.
Future<String> createDemoFile() async {
  final file = File(
    '${Directory.systemTemp.path}/championforms clipboard demo.txt',
  );
  await file.writeAsString(
    'Copied by the championforms clipboard inspector.\n',
  );
  return file.absolute.path;
}

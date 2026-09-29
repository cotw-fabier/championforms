// A local file for the "File list" button. Only native platforms have a
// file system to point the clipboard at; the web stub throws.
export 'demo_file_stub.dart' if (dart.library.io) 'demo_file_io.dart';

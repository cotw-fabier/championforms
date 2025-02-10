import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart';

/// Stores file data which we can pass through
/// when doing drag & drop or file uploads
class FileModel {
  final String fileName;

  /// Stores the reader object from super_drag_and_drop
  final DataReader? fileReader;

  /// Stores the stream of data if the file is being streamed
  final Stream<Uint8List>? fileStream;

  /// Stores the bytes of the file if we got the whole file to pass through
  final Uint8List? fileBytes;

  const FileModel({
    required this.fileName,
    this.fileReader,
    this.fileStream,
    this.fileBytes,
  });
}

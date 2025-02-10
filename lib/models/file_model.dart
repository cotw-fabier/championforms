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

  FileModel copyWith({
    String? fileName,
    DataReader? fileReader,
    Stream<Uint8List>? fileStream,
    Uint8List? fileBytes,
  }) {
    return FileModel(
      fileName: fileName ?? this.fileName,
      fileReader: fileReader ?? this.fileReader,
      fileStream: fileStream ?? this.fileStream,
      fileBytes: fileBytes ?? this.fileBytes,
    );
  }

  Future<Uint8List?> getFileBytes() async {
    if (fileBytes != null) {
      return fileBytes;
    } else if (fileStream != null) {
      final List<int> bytesBuffer = [];
      await for (final chunk in fileStream!) {
        bytesBuffer.addAll(chunk);
      }
      final Uint8List completeBytes = Uint8List.fromList(bytesBuffer);
      return completeBytes;
    }
    return null;
  }
}

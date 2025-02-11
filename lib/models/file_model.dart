import 'dart:typed_data';

import 'package:championforms/models/mime_data.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
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

  /// Store the file MimeType. This can't be set until the file has been read
  final MimeData? mimeData;

  /// Stores the file extension from when it was uploaded
  final String? uploadExtension;

  const FileModel({
    required this.fileName,
    this.fileReader,
    this.fileStream,
    this.fileBytes,
    this.mimeData,
    this.uploadExtension,
  });

  FileModel copyWith({
    String? fileName,
    DataReader? fileReader,
    Stream<Uint8List>? fileStream,
    Uint8List? fileBytes,
    MimeData? mimeData,
    String? uploadExtension,
  }) {
    return FileModel(
      fileName: fileName ?? this.fileName,
      fileReader: fileReader ?? this.fileReader,
      fileStream: fileStream ?? this.fileStream,
      fileBytes: fileBytes ?? this.fileBytes,
      mimeData: mimeData ?? this.mimeData,
      uploadExtension: uploadExtension ?? this.uploadExtension,
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

  Future<MimeData> readMimeData() async {
    final mimeType =
        lookupMimeType(fileName, headerBytes: await getFileBytes());
    debugPrint("Looking up mime type: $mimeType");
    return MimeData(
        extension: extensionFromMime(mimeType ?? "") ?? "",
        mime: mimeType ?? "application/octet-stream");
  }
}

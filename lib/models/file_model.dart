import 'dart:typed_data';

import 'package:championforms/models/mime_data.dart';
import 'package:mime/mime.dart';

/// Stores file data for drag-and-drop and file upload operations.
///
/// This model provides a cross-platform representation of uploaded files,
/// containing the file name, raw bytes, MIME type information, and upload extension.
///
/// ## Memory Considerations
///
/// **IMPORTANT:** Files are loaded entirely into memory as [Uint8List].
/// This simplifies implementation but has memory implications:
///
/// - **Small files (< 1MB):** Excellent performance, no concerns
/// - **Medium files (1-10MB):** Good performance, acceptable memory usage
/// - **Large files (10-50MB):** Acceptable but monitor memory usage
/// - **Very large files (> 50MB):** NOT RECOMMENDED - may cause OutOfMemory errors
///
/// For production applications that handle large files, consider:
/// - Implementing `maxFileSize` validation (e.g., 50MB limit)
/// - Displaying file size warnings to users
/// - Rejecting files above a safe threshold
/// - Using streaming file uploads for files > 50MB (not currently supported)
///
/// ## Usage
///
/// FileModel instances are created automatically by [FileUploadWidget] when
/// files are selected via drag-and-drop or file picker dialog. Access them
/// through [FormResults]:
///
/// ```dart
/// // Single file
/// FileModel? file = FormResults.grab("fieldId").asFile();
///
/// // Multiple files
/// List<FileModel> files = FormResults.grab("fieldId").asFileList();
///
/// // Access file properties
/// String name = file.fileName;
/// Uint8List? bytes = await file.getFileBytes();
/// String? mimeType = file.mimeData?.mime;
/// String? extension = file.uploadExtension;
/// ```
///
/// ## Properties
///
/// - [fileName]: Original name of the uploaded file
/// - [fileBytes]: Complete file contents in memory (may be null during creation)
/// - [mimeData]: MIME type information (e.g., "image/png", "application/pdf")
/// - [uploadExtension]: File extension from upload (e.g., "pdf", "jpg")
class FileModel {
  /// The original name of the file as provided during upload.
  ///
  /// Example: "document.pdf", "photo.jpg", "data.csv"
  final String fileName;

  /// The complete file contents as bytes.
  ///
  /// **Memory Warning:** This stores the ENTIRE file in memory. For large files
  /// (> 50MB), this may cause OutOfMemory errors. Consider validating file size
  /// before allowing upload.
  ///
  /// May be null during FileModel construction, but should be populated before
  /// the FileModel is stored in FormResults.
  final Uint8List? fileBytes;

  /// MIME type information for the file.
  ///
  /// Detected using the `mime` package based on file extension and/or file bytes.
  /// Common examples:
  /// - Images: "image/png", "image/jpeg", "image/gif"
  /// - Documents: "application/pdf", "application/msword"
  /// - Text: "text/plain", "text/csv"
  ///
  /// Falls back to "application/octet-stream" if MIME type cannot be determined.
  final MimeData? mimeData;

  /// The file extension as provided during upload.
  ///
  /// Extracted from the file name without the leading dot.
  /// Examples: "pdf", "jpg", "csv", "docx"
  ///
  /// Used for:
  /// - Validating against [allowedExtensions]
  /// - Determining file type icons
  /// - MIME type detection
  final String? uploadExtension;

  const FileModel({
    required this.fileName,
    this.fileBytes,
    this.mimeData,
    this.uploadExtension,
  });

  /// Creates a copy of this FileModel with optionally replaced properties.
  ///
  /// Useful for updating a FileModel after initial creation, such as:
  /// - Adding MIME data after detection
  /// - Updating file bytes after reading
  ///
  /// Example:
  /// ```dart
  /// FileModel fileData = FileModel(fileName: 'doc.pdf');
  /// fileData = fileData.copyWith(
  ///   mimeData: await fileData.readMimeData(),
  ///   fileBytes: loadedBytes,
  /// );
  /// ```
  FileModel copyWith({
    String? fileName,
    Uint8List? fileBytes,
    MimeData? mimeData,
    String? uploadExtension,
  }) {
    return FileModel(
      fileName: fileName ?? this.fileName,
      fileBytes: fileBytes ?? this.fileBytes,
      mimeData: mimeData ?? this.mimeData,
      uploadExtension: uploadExtension ?? this.uploadExtension,
    );
  }

  /// Returns the file bytes as a Future.
  ///
  /// This method returns immediately with [fileBytes] wrapped in a Future.
  /// It exists for API compatibility with previous versions that used
  /// asynchronous file reading.
  ///
  /// Since files are already loaded into memory, this operation is instant.
  ///
  /// Returns `null` if [fileBytes] is not populated.
  Future<Uint8List?> getFileBytes() async {
    return Future.value(fileBytes);
  }

  /// Detects and returns MIME type information for this file.
  ///
  /// Uses the `mime` package to determine the MIME type based on:
  /// 1. File extension from [fileName]
  /// 2. File header bytes from [fileBytes] (if available)
  ///
  /// Returns a [MimeData] object containing:
  /// - `mime`: The detected MIME type (e.g., "image/png")
  /// - `extension`: The corresponding file extension
  ///
  /// Falls back to "application/octet-stream" if MIME type cannot be determined.
  ///
  /// Example:
  /// ```dart
  /// MimeData mime = await fileModel.readMimeData();
  /// print(mime.mime); // "application/pdf"
  /// print(mime.extension); // "pdf"
  /// ```
  Future<MimeData> readMimeData() async {
    final mimeType =
        lookupMimeType(fileName, headerBytes: await getFileBytes());
    return MimeData(
        extension: extensionFromMime(mimeType ?? "") ?? "",
        mime: mimeType ?? "application/octet-stream");
  }
}

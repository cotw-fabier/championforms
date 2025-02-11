import 'package:championforms/models/mime_filetypes.dart';

MimeFileType getFileType(String mimeType) {
  // Normalize the MIME type to lowercase (and trim parameters, if any)
  final lowerMime = mimeType.toLowerCase().split(';').first.trim();

  // HTML, code, and related types
  if (lowerMime.startsWith('text/html') ||
      lowerMime.startsWith('application/javascript') ||
      lowerMime.startsWith('application/json') ||
      lowerMime.startsWith('application/xml') ||
      lowerMime.startsWith('text/css') ||
      lowerMime.startsWith('text/markdown')) {
    return MimeFileType.htmlOrCode;
  }
  // Plain text and CSV files
  else if (lowerMime.startsWith('text/plain') ||
      lowerMime.startsWith('text/csv')) {
    return MimeFileType.plainText;
  }
  // Documents: word processing, spreadsheets, presentations, etc.
  else if (lowerMime.startsWith('application/pdf') ||
      lowerMime.startsWith('application/msword') ||
      lowerMime.startsWith(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document') ||
      lowerMime.startsWith('application/rtf') ||
      lowerMime.startsWith('application/vnd.oasis.opendocument.text') ||
      lowerMime.startsWith('application/vnd.ms-excel') ||
      lowerMime.startsWith(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') ||
      lowerMime.startsWith('application/vnd.oasis.opendocument.spreadsheet') ||
      lowerMime.startsWith('application/vnd.ms-powerpoint') ||
      lowerMime.startsWith(
          'application/vnd.openxmlformats-officedocument.presentationml.presentation') ||
      lowerMime.startsWith('application/vnd.oasis.opendocument.presentation')) {
    return MimeFileType.document;
  }
  // Images
  else if (lowerMime.startsWith('image/')) {
    return MimeFileType.image;
  }
  // Videos
  else if (lowerMime.startsWith('video/')) {
    return MimeFileType.video;
  }
  // Audio
  else if (lowerMime.startsWith('audio/')) {
    return MimeFileType.audio;
  }
  // Executables
  else if (lowerMime.startsWith('application/x-executable') ||
      lowerMime.startsWith('application/x-msdownload') ||
      lowerMime.startsWith('application/vnd.microsoft.portable-executable')) {
    return MimeFileType.executable;
  }
  // Archives and compressed files
  else if (lowerMime.startsWith('application/zip') ||
      lowerMime.startsWith('application/x-7z-compressed') ||
      lowerMime.startsWith('application/x-rar-compressed') ||
      lowerMime.startsWith('application/gzip') ||
      lowerMime.startsWith('application/x-tar')) {
    return MimeFileType.archive;
  }
  // Anything else
  else {
    return MimeFileType.other;
  }
}

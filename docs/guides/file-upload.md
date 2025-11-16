# File Upload Guide

Complete guide to implementing file uploads in ChampionForms with platform setup, drag-and-drop, and validation.

## Table of Contents

- [Overview](#overview)
- [Platform Setup (Critical)](#platform-setup-critical)
  - [iOS Setup](#ios-setup)
  - [Android Setup](#android-setup)
  - [macOS Setup](#macos-setup)
  - [Web Setup](#web-setup)
- [Quick Start](#quick-start)
- [FileUpload API](#fileupload-api)
- [Features](#features)
- [Validation](#validation)
- [Accessing Uploaded Files](#accessing-uploaded-files)
- [Platform Differences](#platform-differences)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Troubleshooting](#troubleshooting)

## Overview

The `form.FileUpload` field provides a complete file upload solution with:

- **File Picker Integration**: Native file selection dialogs on all platforms
- **Drag-and-Drop**: Desktop platforms (Windows, macOS, Linux) support drag-and-drop
- **File Type Filtering**: Restrict uploads by file extension
- **File Previews**: Automatic preview generation for images, icons for other files
- **Validation**: Built-in validators for file types, MIME types, and custom validation
- **Cross-Platform**: Works on mobile, desktop, and web with platform-specific adaptations

`FileUpload` extends `OptionSelect`, storing files as special `FieldOption` instances with `FileModel` data in `additionalData`.

## Platform Setup (Critical)

### Important Note

`FileUpload` uses the `file_picker` package which **requires platform-specific permissions**. Your app will not be able to access files until you configure these permissions.

### iOS Setup

**File**: `ios/Runner/Info.plist`

Add the following keys to your Info.plist file:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload images</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record videos</string>
```

Customize the description strings to match your app's actual use case.

**Optional**: If you don't need certain file types, you can exclude permissions in your `Podfile`:

```ruby
# Add BEFORE target 'Runner' do
Pod::PICKER_MEDIA = false    # Exclude photo library access
Pod::PICKER_AUDIO = false    # Exclude audio file access
Pod::PICKER_DOCUMENT = false # Exclude document access

target 'Runner' do
  use_frameworks!  # Required since file_picker v1.7.0
  # ... rest of podfile
end
```

### Android Setup

**File**: `android/app/src/main/AndroidManifest.xml`

Add permissions inside the `<manifest>` tag:

**For Android 12 and below (API level 32 and below):**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.yourapp">

    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />

    <application ...>
        ...
    </application>
</manifest>
```

**For Android 13+ (API level 33+), add these additional permissions:**

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

**Full example for modern Android apps:**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.yourapp">

    <!-- Legacy permissions for Android 12 and below -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />

    <!-- Granular permissions for Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

    <application ...>
        ...
    </application>
</manifest>
```

### macOS Setup

**Files**:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

Add file access entitlements to **both** files:

**For read-only access:**

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

**For read/write access:**

```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

**Full example:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

You can also configure these entitlements through Xcode's UI:
1. Open `macos/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to Signing & Capabilities
4. Under App Sandbox, enable "User Selected Files" with "Read Only" or "Read/Write"

### Web Setup

No special setup required! Web apps can use the file picker API directly.

### Desktop (Windows/Linux)

No special setup required. Ensure desktop support is enabled:

```bash
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```

### Full Documentation

For the most up-to-date platform configuration details, see the [file_picker setup guide](https://pub.dev/packages/file_picker#setup).

## Quick Start

### Basic File Upload

```dart
form.FileUpload(
  id: 'avatar',
  title: 'Upload Profile Picture',
  allowedExtensions: ['jpg', 'png', 'gif'],
  validators: [
    form.Validator(
      validator: (value) => form.Validators.fileIsImage(value),
      reason: 'Must be an image file',
    ),
  ],
)
```

### Multiple File Upload

```dart
form.FileUpload(
  id: 'documents',
  title: 'Upload Documents',
  description: 'PDF or Word documents only',
  multiselect: true,
  allowedExtensions: ['pdf', 'doc', 'docx'],
  validators: [
    form.Validator(
      validator: (value) => form.Validators.fileIsDocument(value),
      reason: 'Only document files allowed',
    ),
    form.Validator(
      validator: (value) => form.Validators.listIsNotEmpty(value),
      reason: 'Please upload at least one document',
    ),
  ],
)
```

## FileUpload API

### Constructor

`FileUpload` extends `OptionSelect` and adds file-specific properties:

```dart
FileUpload({
  required String id,
  String? title,
  String? description,
  bool multiselect = false,
  List<String>? allowedExtensions,
  int? maxFileSize = 52428800, // 50 MB default
  bool displayUploadedFiles = true,
  bool clearOnUpload = false,
  Widget Function(FieldColorScheme, FileUpload)? dropDisplayWidget,
  // + all OptionSelect properties (theme, validators, onChange, etc.)
})
```

### Properties

#### id (required)
**Type**: `String`

Unique identifier for the field. Use this ID to retrieve uploaded files from results.

```dart
form.FileUpload(id: 'profile_picture')
```

#### title
**Type**: `String?`

Label displayed above the field.

```dart
form.FileUpload(
  id: 'avatar',
  title: 'Profile Picture',
)
```

#### description
**Type**: `String?`

Helper text displayed below the title, above the upload area.

```dart
form.FileUpload(
  id: 'documents',
  title: 'Upload Documents',
  description: 'Accepted formats: PDF, Word. Max size: 10 MB',
)
```

#### multiselect
**Type**: `bool`
**Default**: `false`

Allow multiple files to be uploaded. When `false`, selecting a new file replaces the previous one (unless `clearOnUpload` is configured differently).

```dart
form.FileUpload(
  id: 'attachments',
  multiselect: true, // Allow multiple files
)
```

#### allowedExtensions
**Type**: `List<String>?`
**Default**: `null` (all file types allowed)

Filter file types by extension. Extensions should be specified **without** the leading dot.

This filter applies to:
- The native file picker dialog (only shows allowed types)
- Drag-and-drop operations (rejects disallowed files)

```dart
form.FileUpload(
  id: 'images',
  allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
)

form.FileUpload(
  id: 'documents',
  allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
)
```

#### maxFileSize
**Type**: `int?`
**Default**: `52428800` (50 MB)

Maximum file size in bytes. Files exceeding this size are rejected with an error.

**Memory Warning**: Files are loaded entirely into memory. Setting this too high may cause OutOfMemory errors on mobile devices. The 50 MB default is a safe balance for most use cases.

Set to `null` to allow files of any size (not recommended for production).

```dart
form.FileUpload(
  id: 'avatar',
  maxFileSize: 5 * 1024 * 1024, // 5 MB limit
)

form.FileUpload(
  id: 'unlimited',
  maxFileSize: null, // No size limit (use with caution!)
)
```

#### displayUploadedFiles
**Type**: `bool`
**Default**: `true`

Show previews/icons of uploaded files below the upload area.

When `true`:
- Images show thumbnail previews
- Other files show file type icons with filenames
- File size is displayed
- Remove button appears for each file

Set to `false` if you want to build a custom display of uploaded files.

```dart
form.FileUpload(
  id: 'hidden_display',
  displayUploadedFiles: false, // Build your own file list UI
)
```

#### clearOnUpload
**Type**: `bool`
**Default**: `false`

When `true`, selecting new files clears all previously uploaded files before adding the new ones. When `false`, new files are added to the existing list.

Useful for single-file fields where you want explicit replacement behavior:

```dart
form.FileUpload(
  id: 'avatar',
  multiselect: false,
  clearOnUpload: true, // Each upload replaces the previous file
)
```

#### dropDisplayWidget
**Type**: `Widget Function(FieldColorScheme, FileUpload)?`
**Default**: `null` (uses built-in drop zone UI)

Customize the appearance of the drag-and-drop zone. The function receives:
- `FieldColorScheme`: Color scheme for the current field state
- `FileUpload`: The field instance (access properties like `title`)

```dart
form.FileUpload(
  id: 'custom_drop',
  dropDisplayWidget: (colors, field) => Container(
    padding: EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: colors.borderColor, width: 2),
      borderRadius: BorderRadius.circular(12),
      color: colors.backgroundColor,
    ),
    child: Column(
      children: [
        Icon(Icons.cloud_upload, size: 48, color: colors.iconColor),
        SizedBox(height: 8),
        Text(
          'Drop files here or click to browse',
          style: TextStyle(color: colors.textColor),
        ),
      ],
    ),
  ),
)
```

#### Inherited Properties

From `OptionSelect` and `Field`:
- `validators`: List of `form.Validator` instances
- `validateLive`: Validate on blur (default: `false`)
- `onChange`: Callback when files change
- `onSubmit`: Callback when Enter is pressed (if applicable)
- `disabled`: Disable the field
- `hideField`: Hide the field from the form
- `theme`: Override theme for this field
- `leading`/`trailing`: Icons or widgets around the field

## Features

### File Picker

Click the upload area to open the native file picker dialog.

- Filtered by `allowedExtensions` if specified
- Supports single or multiple selection based on `multiselect`
- Works on all platforms (mobile, desktop, web)

### Drag-and-Drop (Desktop Only)

On desktop platforms (Windows, macOS, Linux), users can drag files directly onto the upload area.

- Visual feedback when dragging files over the drop zone
- Files are filtered by `allowedExtensions`
- Rejected files show an error message
- Works seamlessly alongside the file picker

**Note**: Drag-and-drop is **not available** on mobile (iOS/Android) or web platforms.

### File Previews

When `displayUploadedFiles` is `true`, uploaded files are displayed below the upload area:

**For images:**
- Thumbnail preview (scaled down)
- Filename
- File size
- Remove button

**For other files:**
- File type icon (based on extension/MIME type)
- Filename
- File size
- Remove button

### File Size Limits

Files exceeding `maxFileSize` are automatically rejected with an error message. The default limit is 50 MB to prevent memory issues.

## Validation

### Built-in File Validators

ChampionForms provides several file-specific validators in the `form.Validators` class.

#### fileIsImage()

Checks if **all** uploaded files are images (MIME type starts with `image/`).

```dart
form.Validator(
  validator: (value) => form.Validators.fileIsImage(value),
  reason: 'All files must be images',
)
```

Accepts: JPG, PNG, GIF, SVG, WebP, BMP, TIFF, and other image formats.

#### fileIsCommonImage()

Checks for common image formats only (JPG, PNG, SVG, GIF, WebP).

```dart
form.Validator(
  validator: (value) => form.Validators.fileIsCommonImage(value),
  reason: 'Only JPG, PNG, SVG, GIF, or WebP images allowed',
)
```

More restrictive than `fileIsImage()`. Use this to exclude uncommon formats like TIFF or BMP.

#### fileIsDocument()

Checks if **all** uploaded files are documents (Word, PDF, plain text, RTF, or ODT).

```dart
form.Validator(
  validator: (value) => form.Validators.fileIsDocument(value),
  reason: 'Only document files allowed',
)
```

Accepts:
- PDF (`.pdf`)
- Word (`.doc`, `.docx`)
- Plain text (`.txt`)
- Rich Text Format (`.rtf`)
- OpenDocument Text (`.odt`)

#### fileIsMimeType()

Check for specific MIME types. Use this for custom file type validation.

```dart
form.Validator(
  validator: (value) => form.Validators.fileIsMimeType(value, [
    'image/jpeg',
    'image/png',
    'application/pdf',
  ]),
  reason: 'Only JPEG, PNG images or PDF files allowed',
)
```

Common MIME types:
- Images: `image/jpeg`, `image/png`, `image/gif`, `image/svg+xml`, `image/webp`
- Documents: `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- Text: `text/plain`, `text/csv`, `text/html`
- Archives: `application/zip`, `application/x-rar-compressed`

### Custom File Validation

You can write custom validators that inspect file properties.

#### File Size Limit

Limit individual file sizes:

```dart
form.Validator(
  validator: (value) {
    if (value is! List<FieldOption>) return true;

    for (final option in value) {
      if (option.additionalData is FileModel) {
        final file = option.additionalData as FileModel;
        final bytes = file.fileBytes?.length ?? 0;
        if (bytes > 10 * 1024 * 1024) { // 10 MB
          return false;
        }
      }
    }
    return true;
  },
  reason: 'Each file must be under 10 MB',
)
```

**Note**: The `maxFileSize` property provides this functionality automatically. This example shows how to implement custom size checks.

#### File Count Limit

Limit the number of uploaded files:

```dart
form.Validator(
  validator: (value) {
    if (value is! List<FieldOption>) return true;
    return value.length <= 5;
  },
  reason: 'Maximum 5 files allowed',
)
```

#### Required Files

Require at least one file to be uploaded:

```dart
form.Validator(
  validator: (value) => form.Validators.listIsNotEmpty(value),
  reason: 'Please upload at least one file',
)
```

#### Filename Pattern

Validate filenames against a pattern:

```dart
form.Validator(
  validator: (value) {
    if (value is! List<FieldOption>) return true;

    final pattern = RegExp(r'^[a-zA-Z0-9_\-]+\.(jpg|png)$');
    for (final option in value) {
      if (option.additionalData is FileModel) {
        final file = option.additionalData as FileModel;
        if (!pattern.hasMatch(file.fileName)) {
          return false;
        }
      }
    }
    return true;
  },
  reason: 'Filenames must contain only letters, numbers, hyphens, and underscores',
)
```

### Combining Validators

You can combine multiple validators for comprehensive validation:

```dart
form.FileUpload(
  id: 'profile_picture',
  title: 'Upload Profile Picture',
  allowedExtensions: ['jpg', 'png'],
  maxFileSize: 5 * 1024 * 1024, // 5 MB
  validators: [
    // Require at least one file
    form.Validator(
      validator: (value) => form.Validators.listIsNotEmpty(value),
      reason: 'Profile picture is required',
    ),
    // Ensure it's an image
    form.Validator(
      validator: (value) => form.Validators.fileIsCommonImage(value),
      reason: 'Only JPG or PNG images allowed',
    ),
    // Additional custom validation
    form.Validator(
      validator: (value) {
        // Your custom logic here
        return true;
      },
      reason: 'Custom validation failed',
    ),
  ],
)
```

## Accessing Uploaded Files

### Getting Files from Results

After calling `FormResults.getResults()`, access uploaded files using the field ID:

```dart
void handleSubmit() {
  final results = form.FormResults.getResults(controller: controller);

  if (results.errorState) {
    // Handle validation errors
    print('Form has errors: ${results.formErrors}');
    return;
  }

  // Get files from a single-file upload field
  final avatar = results.grab('avatar').asFile();
  if (avatar != null) {
    print('Avatar: ${avatar.fileName}');
    print('Size: ${avatar.fileBytes?.length ?? 0} bytes');
  }

  // Get files from a multi-file upload field
  final documents = results.grab('documents').asFileList();
  print('Uploaded ${documents.length} documents');
  for (final file in documents) {
    print('- ${file.fileName} (${file.mimeData?.mime})');
  }
}
```

### Result Accessor Methods

#### asFile()

Returns the **first** file from the upload, or `null` if no files were uploaded. Best for single-file upload fields.

```dart
final FileModel? file = results.grab('avatar').asFile();

if (file != null) {
  print('Filename: ${file.fileName}');
  print('MIME type: ${file.mimeData?.mime}');
  print('Size: ${file.fileBytes?.length ?? 0} bytes');
}
```

#### asFileList()

Returns **all** uploaded files as a `List<FileModel>`. Best for multi-file upload fields.

```dart
final List<FileModel> files = results.grab('attachments').asFileList();

if (files.isEmpty) {
  print('No files uploaded');
} else {
  print('Uploaded ${files.length} files');
  for (final file in files) {
    print('- ${file.fileName}');
  }
}
```

### FileModel Structure

Each uploaded file is represented by a `FileModel` instance:

```dart
class FileModel {
  final String fileName;        // Original filename (e.g., "document.pdf")
  final Uint8List? fileBytes;   // Complete file contents in memory
  final MimeData? mimeData;     // MIME type information
  final String? uploadExtension; // File extension (e.g., "pdf")
}
```

#### fileName
Original name of the uploaded file, including extension.

```dart
print(file.fileName); // "resume.pdf"
```

#### fileBytes
Complete file contents as a `Uint8List`. Use this to:
- Upload files to a server
- Save files to disk
- Process file contents (e.g., image manipulation)

**Memory Warning**: This contains the **entire file in memory**. For large files (> 50 MB), this may cause OutOfMemory errors.

```dart
final bytes = file.fileBytes;
if (bytes != null) {
  // Upload to server
  await uploadToServer(bytes, file.fileName);

  // Save to disk (mobile/desktop)
  final savedFile = File('/path/to/save/${file.fileName}');
  await savedFile.writeAsBytes(bytes);

  // Process image
  final image = img.decodeImage(bytes);
}
```

#### mimeData
MIME type information detected from the file extension and/or file header bytes.

```dart
class MimeData {
  final String mime;      // Full MIME type (e.g., "image/jpeg")
  final String extension; // File extension (e.g., "jpg")
}
```

Common MIME types:
- `image/jpeg`, `image/png`, `image/gif`
- `application/pdf`
- `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- `text/plain`, `text/csv`

```dart
final mime = file.mimeData;
if (mime != null) {
  print('MIME type: ${mime.mime}');       // "image/jpeg"
  print('Extension: ${mime.extension}');  // "jpg"

  if (mime.mime.startsWith('image/')) {
    print('This is an image file');
  }
}
```

If MIME type cannot be determined, falls back to `"application/octet-stream"`.

#### uploadExtension
File extension extracted from the filename, **without** the leading dot.

```dart
print(file.uploadExtension); // "pdf" (not ".pdf")
```

Use this for:
- Display purposes (e.g., showing "PDF" badge)
- File type categorization
- Saving files with correct extensions

### Complete File Access Example

```dart
void processUploadedFiles() {
  final results = form.FormResults.getResults(controller: controller);

  if (results.errorState) {
    showError('Please fix form errors');
    return;
  }

  final files = results.grab('documents').asFileList();

  for (final file in files) {
    print('Processing: ${file.fileName}');
    print('  Extension: ${file.uploadExtension}');
    print('  MIME: ${file.mimeData?.mime ?? "unknown"}');
    print('  Size: ${file.fileBytes?.length ?? 0} bytes');

    // Access file bytes for upload
    if (file.fileBytes != null) {
      uploadFile(file.fileName, file.fileBytes!);
    }

    // Check file type
    if (file.mimeData != null) {
      if (file.mimeData!.mime.startsWith('image/')) {
        processImage(file);
      } else if (file.mimeData!.mime == 'application/pdf') {
        processPDF(file);
      }
    }
  }
}
```

## Platform Differences

File handling varies by platform due to OS limitations.

### Web

**Capabilities:**
- File picker works
- Drag-and-drop **does NOT work** (file_picker limitation)
- `fileBytes` always available (files loaded into memory)
- File processing happens entirely in browser

**Limitations:**
- No access to file system paths
- Cannot save files directly to disk
- Memory constraints (large files may crash browser)

**Example:**
```dart
if (kIsWeb) {
  // Use bytes directly
  final bytes = file.fileBytes!;

  // Upload via HTTP
  final request = http.MultipartRequest('POST', uploadUrl);
  request.files.add(http.MultipartFile.fromBytes(
    'file',
    bytes,
    filename: file.fileName,
  ));
  await request.send();
}
```

### Mobile (iOS/Android)

**Capabilities:**
- File picker works (requires permissions)
- `fileBytes` available (loaded into memory)
- Access to file metadata

**Limitations:**
- No drag-and-drop
- Memory constraints (large files may crash app)
- Permissions required (see [Platform Setup](#platform-setup-critical))

**Example:**
```dart
if (Platform.isIOS || Platform.isAndroid) {
  // Save to app's documents directory
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/${file.fileName}';
  final savedFile = File(filePath);
  await savedFile.writeAsBytes(file.fileBytes!);

  print('File saved to: $filePath');
}
```

### Desktop (Windows/macOS/Linux)

**Capabilities:**
- File picker works
- Drag-and-drop works
- `fileBytes` available
- More generous memory limits

**Limitations:**
- macOS requires entitlements (see [macOS Setup](#macos-setup))

**Example:**
```dart
if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
  // Users can drag files onto the upload area
  // Or use the file picker

  // Save anywhere on the file system
  final savePath = '/path/to/save/${file.fileName}';
  final savedFile = File(savePath);
  await savedFile.writeAsBytes(file.fileBytes!);
}
```

### Handling Platform Differences

Use conditional logic to handle platform-specific behaviors:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

void handleFileUpload(FileModel file) {
  if (kIsWeb) {
    // Web-specific handling
    uploadViaHttp(file.fileBytes!, file.fileName);
  } else if (Platform.isIOS || Platform.isAndroid) {
    // Mobile-specific handling
    saveToAppDirectory(file);
  } else {
    // Desktop-specific handling
    saveToFileSystem(file);
  }
}
```

## Best Practices

### 1. Always Set File Size Limits

Prevent memory issues and improve user experience:

```dart
form.FileUpload(
  id: 'avatar',
  maxFileSize: 5 * 1024 * 1024, // 5 MB
  // ... other properties
)
```

For production apps, consider:
- Images: 5-10 MB
- Documents: 20-50 MB
- Very large files: Not recommended (use chunked uploads instead)

### 2. Validate File Types Strictly

Use both `allowedExtensions` AND validators for defense in depth:

```dart
form.FileUpload(
  id: 'images',
  allowedExtensions: ['jpg', 'jpeg', 'png'], // Filter in picker
  validators: [
    // Verify MIME type (more reliable than extension)
    form.Validator(
      validator: (value) => form.Validators.fileIsMimeType(value, [
        'image/jpeg',
        'image/png',
      ]),
      reason: 'Only JPEG and PNG images allowed',
    ),
  ],
)
```

Why both?
- `allowedExtensions`: User convenience (filters file picker)
- MIME validator: Security (verifies actual file type)

### 3. Provide Clear Instructions

Help users understand file requirements:

```dart
form.FileUpload(
  id: 'resume',
  title: 'Upload Resume',
  description: 'PDF or Word documents only. Maximum 5 MB.',
  allowedExtensions: ['pdf', 'doc', 'docx'],
  maxFileSize: 5 * 1024 * 1024,
)
```

### 4. Handle Upload Progress

Show feedback during file processing and uploads:

```dart
Future<void> uploadFile(FileModel file) async {
  // Show progress indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  try {
    final request = http.MultipartRequest('POST', uploadUrl);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      file.fileBytes!,
      filename: file.fileName,
    ));

    final response = await request.send();

    if (response.statusCode == 200) {
      showSuccess('File uploaded successfully');
    } else {
      showError('Upload failed');
    }
  } catch (e) {
    showError('Upload error: $e');
  } finally {
    Navigator.of(context).pop(); // Hide progress
  }
}
```

### 5. Validate Before Upload

Always check form validation before processing files:

```dart
void handleSubmit() {
  // Validate form
  final results = form.FormResults.getResults(controller: controller);

  if (results.errorState) {
    showError('Please fix errors before submitting');
    return;
  }

  // Now safe to process files
  final files = results.grab('documents').asFileList();
  for (final file in files) {
    uploadFile(file);
  }
}
```

### 6. Clean Up Resources

While `FileModel` stores files in memory (no manual cleanup needed), consider clearing large files from the form after successful upload:

```dart
Future<void> uploadAndClear() async {
  final results = form.FormResults.getResults(controller: controller);
  final files = results.grab('documents').asFileList();

  // Upload files
  await uploadFiles(files);

  // Clear the form field
  controller.removeMultiSelectOptions('documents');
}
```

### 7. Display Upload Status

Show users which files are being uploaded and their status:

```dart
class UploadProgressDialog extends StatefulWidget {
  final List<FileModel> files;

  const UploadProgressDialog({required this.files});

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  final Map<String, double> _progress = {};

  @override
  void initState() {
    super.initState();
    for (final file in widget.files) {
      _progress[file.fileName] = 0.0;
      _uploadFile(file);
    }
  }

  Future<void> _uploadFile(FileModel file) async {
    // Simulate upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() => _progress[file.fileName] = i / 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Uploading Files'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.files.map((file) {
          final progress = _progress[file.fileName] ?? 0.0;
          return ListTile(
            title: Text(file.fileName),
            subtitle: LinearProgressIndicator(value: progress),
            trailing: Text('${(progress * 100).toInt()}%'),
          );
        }).toList(),
      ),
    );
  }
}
```

### 8. Handle Errors Gracefully

Provide helpful error messages:

```dart
try {
  final results = form.FormResults.getResults(controller: controller);

  if (results.errorState) {
    // Show field-specific errors
    for (final error in results.formErrors) {
      if (error.fieldId == 'documents') {
        showError(error.reason);
      }
    }
    return;
  }

  // Process files...
} catch (e) {
  showError('An unexpected error occurred: $e');
}
```

## Complete Examples

### Example 1: Image Upload with Validation

From the example app (`example/lib/main.dart` lines 291-322):

```dart
form.FileUpload(
  id: 'avatar',
  title: 'Upload Profile Picture',
  description: 'Drag & drop or click to upload (JPG, PNG only)',
  multiselect: false,
  validateLive: true,
  clearOnUpload: true,
  allowedExtensions: ['jpg', 'jpeg', 'png'],
  maxFileSize: 5 * 1024 * 1024, // 5 MB
  validators: [
    form.Validator(
      validator: (value) => form.Validators.listIsNotEmpty(value),
      reason: 'Profile picture is required',
    ),
    form.Validator(
      validator: (value) => form.Validators.fileIsImage(value),
      reason: 'Only image files (JPG, PNG) are allowed',
    ),
  ],
)
```

Accessing the uploaded file:

```dart
final results = form.FormResults.getResults(controller: controller);
if (!results.errorState) {
  final avatar = results.grab('avatar').asFile();
  if (avatar != null) {
    print('Avatar: ${avatar.fileName}');
    print('Size: ${avatar.fileBytes?.length ?? 0} bytes');
    print('MIME: ${avatar.mimeData?.mime}');

    // Upload to server
    await uploadAvatar(avatar.fileBytes!, avatar.fileName);
  }
}
```

### Example 2: Document Upload with Size Limits

```dart
form.FileUpload(
  id: 'resume',
  title: 'Upload Resume',
  description: 'PDF or Word documents only. Maximum 10 MB.',
  allowedExtensions: ['pdf', 'doc', 'docx'],
  maxFileSize: 10 * 1024 * 1024, // 10 MB
  validators: [
    form.Validator(
      validator: (value) => form.Validators.listIsNotEmpty(value),
      reason: 'Resume is required',
    ),
    form.Validator(
      validator: (value) => form.Validators.fileIsDocument(value),
      reason: 'Only document files are allowed',
    ),
  ],
)
```

### Example 3: Multiple Images with Preview

```dart
form.FileUpload(
  id: 'gallery',
  title: 'Upload Photos',
  description: 'Select up to 10 photos',
  multiselect: true,
  displayUploadedFiles: true, // Show previews
  allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
  maxFileSize: 20 * 1024 * 1024, // 20 MB per file
  validators: [
    form.Validator(
      validator: (value) {
        if (value is! List<FieldOption>) return true;
        return value.length <= 10;
      },
      reason: 'Maximum 10 photos allowed',
    ),
    form.Validator(
      validator: (value) => form.Validators.fileIsImage(value),
      reason: 'All files must be images',
    ),
  ],
)
```

Accessing multiple files:

```dart
final results = form.FormResults.getResults(controller: controller);
if (!results.errorState) {
  final photos = results.grab('gallery').asFileList();
  print('Uploaded ${photos.length} photos');

  for (final photo in photos) {
    print('- ${photo.fileName} (${photo.fileBytes?.length ?? 0} bytes)');
    await uploadPhoto(photo);
  }
}
```

### Example 4: Custom Drop Zone

```dart
form.FileUpload(
  id: 'custom_upload',
  title: 'Upload Files',
  multiselect: true,
  allowedExtensions: ['pdf', 'jpg', 'png'],
  dropDisplayWidget: (colors, field) => Container(
    height: 200,
    decoration: BoxDecoration(
      border: Border.all(
        color: colors.borderColor,
        width: 2,
        style: BorderStyle.solid,
      ),
      borderRadius: BorderRadius.circular(12),
      color: colors.backgroundColor,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 64,
          color: colors.iconColor,
        ),
        SizedBox(height: 16),
        Text(
          'Drag and drop files here',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'or click to browse',
          style: TextStyle(
            fontSize: 14,
            color: colors.hintColor,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'PDF, JPG, PNG only',
          style: TextStyle(
            fontSize: 12,
            color: colors.hintColor,
          ),
        ),
      ],
    ),
  ),
)
```

### Example 5: File Upload with HTTP Upload

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> uploadToServer() async {
  final results = form.FormResults.getResults(controller: controller);

  if (results.errorState) {
    showError('Please fix form errors');
    return;
  }

  final files = results.grab('documents').asFileList();

  for (final file in files) {
    final uri = Uri.parse('https://api.example.com/upload');
    final request = http.MultipartRequest('POST', uri);

    // Add file
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      file.fileBytes!,
      filename: file.fileName,
    ));

    // Add metadata
    request.fields['filename'] = file.fileName;
    request.fields['mime_type'] = file.mimeData?.mime ?? 'application/octet-stream';
    request.fields['size'] = '${file.fileBytes?.length ?? 0}';

    // Send request
    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        print('Uploaded: ${data['url']}');
      } else {
        print('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
    }
  }
}
```

### Example 6: Platform-Specific File Handling

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, File;
import 'package:path_provider/path_provider.dart';

Future<void> handleFiles() async {
  final results = form.FormResults.getResults(controller: controller);
  final files = results.grab('documents').asFileList();

  for (final file in files) {
    if (kIsWeb) {
      // Web: Upload directly from memory
      await uploadViaHttp(file.fileBytes!, file.fileName);
    } else if (Platform.isIOS || Platform.isAndroid) {
      // Mobile: Save to app directory first
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${file.fileName}';
      final savedFile = File(path);
      await savedFile.writeAsBytes(file.fileBytes!);
      print('Saved to: $path');
    } else {
      // Desktop: User can choose save location
      final savePath = await FilePicker.platform.saveFile(
        fileName: file.fileName,
      );
      if (savePath != null) {
        final savedFile = File(savePath);
        await savedFile.writeAsBytes(file.fileBytes!);
        print('Saved to: $savePath');
      }
    }
  }
}
```

## Troubleshooting

### File Picker Not Opening

**Symptom**: Clicking the upload area does nothing.

**Possible Causes**:
1. Missing platform permissions
2. `file_picker` dependency not installed
3. Platform not supported

**Solutions**:
- Verify permissions are configured (see [Platform Setup](#platform-setup-critical))
- Check `pubspec.yaml` includes `file_picker` dependency
- Run `flutter pub get`
- Check console for permission errors
- On iOS, ensure `use_frameworks!` is in Podfile

### Files Not Uploading

**Symptom**: Files are selected but don't appear or upload fails.

**Possible Causes**:
1. File exceeds `maxFileSize`
2. File type not in `allowedExtensions`
3. Validation errors
4. Network issues (if uploading to server)

**Solutions**:
- Check file size is under `maxFileSize` limit
- Verify file extension is in `allowedExtensions` list
- Check form validation errors: `results.formErrors`
- Test network connection
- Check server logs for upload errors

### Drag-and-Drop Not Working

**Symptom**: Dragging files onto upload area doesn't work.

**Possible Causes**:
1. Platform doesn't support drag-and-drop
2. File type not in `allowedExtensions`
3. `desktop_drop` dependency missing

**Solutions**:
- Drag-and-drop only works on desktop (Windows, macOS, Linux)
- Not supported on web or mobile
- Verify `desktop_drop` is in `pubspec.yaml`
- Check file extension matches `allowedExtensions`
- Use file picker as fallback on mobile/web

### Out of Memory Errors

**Symptom**: App crashes or freezes when uploading large files.

**Possible Causes**:
1. File size too large for device memory
2. Multiple large files uploaded simultaneously
3. `maxFileSize` not set or too high

**Solutions**:
- Set reasonable `maxFileSize` limits (5-50 MB depending on use case)
- Limit number of files with custom validator
- Process files one at a time
- Consider chunked upload for very large files (requires custom implementation)
- Test on devices with limited memory (older phones)

Example fix:

```dart
form.FileUpload(
  id: 'documents',
  maxFileSize: 20 * 1024 * 1024, // 20 MB limit
  validators: [
    form.Validator(
      validator: (value) {
        if (value is! List<FieldOption>) return true;
        return value.length <= 3; // Max 3 files
      },
      reason: 'Maximum 3 files at a time',
    ),
  ],
)
```

### Permission Denied Errors

**Symptom**: Error messages about missing permissions.

**Platform**: iOS/Android

**Solutions**:
- Add required permissions to `Info.plist` (iOS) or `AndroidManifest.xml` (Android)
- Request permissions at runtime (automatic for `file_picker`)
- Users must grant permission when prompted
- Check device settings if permission was previously denied

### Files Not Displaying

**Symptom**: Files upload successfully but don't show previews.

**Possible Causes**:
1. `displayUploadedFiles` set to `false`
2. `fileBytes` is null
3. Theme colors make files invisible

**Solutions**:
- Set `displayUploadedFiles: true`
- Verify `file.fileBytes` is populated
- Check theme colors aren't hiding the file list
- Build custom file list if needed

### Validation Errors Not Showing

**Symptom**: Files fail validation but no error message appears.

**Possible Causes**:
1. Validator configured incorrectly
2. `validateLive` not enabled
3. `FormResults.getResults()` not called

**Solutions**:
- Ensure validators return `false` on failure (not `true`)
- Set `validateLive: true` for immediate feedback
- Call `FormResults.getResults()` to trigger validation
- Check `results.formErrors` for error details

Example:

```dart
validators: [
  form.Validator(
    validator: (value) => form.Validators.fileIsImage(value), // Returns false if not image
    reason: 'Only images allowed',
  ),
],
```

## Related Documentation

For more information, see:

- [Field Types API Reference](/docs/api/field-types.md) - Complete FileUpload API
- [Validation Guide](/docs/guides/validation.md) - All validation patterns
- [Form Results API](/docs/api/form-results.md) - Accessing form data
- [Basic Patterns Guide](/docs/guides/basic-patterns.md) - Form fundamentals
- [file_picker Documentation](https://pub.dev/packages/file_picker) - Underlying package
- [desktop_drop Documentation](https://pub.dev/packages/desktop_drop) - Drag-and-drop package

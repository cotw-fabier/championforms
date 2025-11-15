import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FileUpload extends OptionSelect {
  /// Display Uploaded Files
  final bool displayUploadedFiles;

  /// Clear files on upload
  /// When true, selecting new files will clear all previously uploaded files before adding the new ones.
  /// When false (default), new files are added to the existing list (running tally behavior).
  final bool clearOnUpload;

  /// Build the list of files
  final Widget Function(List<FieldOption>)? fileUploadBuilder;

  /// Allowed Extensions
  /// Add a list of allowed extensions to upload. This will limit visible choices when using the file picker
  /// And it will cause drag and drop to reject options which are not compatible.
  /// If set to null then all files are allowed
  final List<String>? allowedExtensions;

  /// Maximum file size in bytes
  /// Files exceeding this size will be rejected with an error message.
  /// Default: 52428800 bytes (50 MB) to prevent memory issues.
  /// Set to null to allow files of any size (not recommended for production).
  ///
  /// Note: Large files are loaded entirely into memory, so setting this too high
  /// may cause OutOfMemory errors on mobile devices.
  final int? maxFileSize;

  /// Change the display of the drag and drop zone for file uploads.
  /// Takes parameters of the current color scheme and the
  /// field details so they're available for building your custom implementation.
  final Widget Function(FieldColorScheme, FileUpload)?
      dropDisplayWidget;

  FileUpload({
    required super.id,
    super.icon,
    super.multiselect = false,
    super.leading,
    super.trailing,
    super.theme,
    super.title,
    super.description,
    super.disabled,
    super.hideField,
    super.requestFocus,
    super.defaultValue = const [],
    super.caseSensitiveDefaultValue = true,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    super.fieldLayout,
    super.fieldBackground,
    this.allowedExtensions,
    this.maxFileSize = 52428800, // 50 MB default
    this.displayUploadedFiles = true,
    this.clearOnUpload = false,
    this.fileUploadBuilder,
    this.dropDisplayWidget,
    super.fieldBuilder, // Pass through optional custom fieldBuilder
  }) : super(
          options: [],
        );

  // --- Override asFileListConverter ---

  /// Extracts FileModel objects from the additionalData of selected options.
  /// The input `value` is dynamic, expected to be List<FieldOption>.
  @override
  List<FileModel> Function(dynamic value)? get asFileListConverter =>
      (dynamic value) {
        List<FieldOption> effectiveOptions;
        if (value is List<FieldOption>) {
          effectiveOptions = value;
        } else if (value == null) {
          // Use the defaultValue from the superclass (OptionSelect)
          // which should be an empty list for FileUpload if not specified otherwise.
          effectiveOptions = defaultValue;
        } else {
          // If value is not List<FieldOption> and not null, it's an unexpected type.
          throw TypeError();
        }

        List<FileModel> files = [];
        for (final option in effectiveOptions) {
          if (option.additionalData is FileModel) {
            files.add(option.additionalData as FileModel);
          } else {
            debugPrint(
                "Warning: FileUpload field '${super.id}' encountered an option ('${option.value}') without a FileModel in additionalData.");
          }
        }
        return files;
      };
}

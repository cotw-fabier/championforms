import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/controllers/form_controller.dart';
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

  @override
  FileUpload copyWith({
    String? id,
    Widget? icon,
    List<FieldOption>? options, // Added to match parent signature
    bool? multiselect,
    Widget? leading,
    Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<FieldOption>? defaultValue,
    bool? caseSensitiveDefaultValue,
    List<Validator>? validators,
    bool? validateLive,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    Widget Function(FieldBuilderContext)? fieldBuilder,
    List<String>? allowedExtensions,
    int? maxFileSize,
    bool? displayUploadedFiles,
    bool? clearOnUpload,
    Widget Function(List<FieldOption>)? fileUploadBuilder,
    Widget Function(FieldColorScheme, FileUpload)? dropDisplayWidget,
  }) {
    // Note: options parameter is ignored for FileUpload since options are managed internally
    return FileUpload(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      multiselect: multiselect ?? this.multiselect,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      theme: theme ?? this.theme,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      defaultValue: defaultValue ?? this.defaultValue,
      caseSensitiveDefaultValue: caseSensitiveDefaultValue ?? this.caseSensitiveDefaultValue,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      fieldBuilder: fieldBuilder ?? this.fieldBuilder,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      displayUploadedFiles: displayUploadedFiles ?? this.displayUploadedFiles,
      clearOnUpload: clearOnUpload ?? this.clearOnUpload,
      fileUploadBuilder: fileUploadBuilder ?? this.fileUploadBuilder,
      dropDisplayWidget: dropDisplayWidget ?? this.dropDisplayWidget,
    );
  }

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

import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/field_builders/fileupload_field_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChampionFileUpload extends ChampionOptionSelect {
  /// Display Uploaded Files
  final bool displayUploadedFiles;

  /// Build the list of files
  final Widget Function(List<MultiselectOption>)? fileUploadBuilder;

  /// Allowed Extensions
  /// Add a list of allowed extensions to upload. This will limit visible choices when using the file picker
  /// And it will cause drag and drop to reject options which are not compatible.
  /// If set to null then all files are allowed
  final List<String>? allowedExtensions;

  /// Change the display of the drag and drop zone for file uploads.
  /// Takes parameters of the current color scheme and the
  /// field details so they're available for building your custom implementation.
  final Widget Function(FieldColorScheme, ChampionFileUpload)?
      dropDisplayWidget;

  ChampionFileUpload({
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
    this.displayUploadedFiles = true,
    this.fileUploadBuilder,
    this.dropDisplayWidget,
  }) : super(
          fieldBuilder: fileUploadFieldBuilder,
          options: [],
        );

  // --- Override asFileListConverter ---

  /// Extracts FileModel objects from the additionalData of selected options.
  /// The input `value` is dynamic, expected to be List<MultiselectOption>.
  @override
  List<FileModel> Function(dynamic value)? get asFileListConverter =>
      (dynamic value) {
        List<MultiselectOption> effectiveOptions;
        if (value is List<MultiselectOption>) {
          effectiveOptions = value;
        } else if (value == null) {
          // Use the defaultValue from the superclass (ChampionOptionSelect)
          // which should be an empty list for ChampionFileUpload if not specified otherwise.
          effectiveOptions = defaultValue;
        } else {
          // If value is not List<MultiselectOption> and not null, it's an unexpected type.
          throw TypeError();
        }

        List<FileModel> files = [];
        for (final option in effectiveOptions) {
          if (option.additionalData is FileModel) {
            files.add(option.additionalData as FileModel);
          } else {
            debugPrint(
                "Warning: ChampionFileUpload field '${super.id}' encountered an option ('${option.value}') without a FileModel in additionalData.");
          }
        }
        return files;
      };
}

import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
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
}

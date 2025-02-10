import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/widgets_external/field_builders/fileupload_field_builder.dart';

class ChampionFileUpload extends ChampionOptionSelect {
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
  }) : super(
          options: [],
          fieldBuilder: fileUploadFieldBuilder,
        );
}

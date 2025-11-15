import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/stateful_field_widget.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/widgets.dart';

/// OptionSelect widget implementation using [StatefulFieldWidget].
///
/// This refactored implementation eliminates boilerplate by:
/// - Automatic controller and focus management via [FieldBuilderContext]
/// - Automatic value synchronization and change detection
/// - Automatic validation on focus loss (when validateLive is true)
/// - Automatic lifecycle management
///
/// The widget delegates actual UI rendering to field-specific builders
/// (dropdown, checkbox, chip, radio) via the field's `fieldBuilder` property.
class OptionSelectWidget extends StatefulFieldWidget {
  const OptionSelectWidget({
    required super.context,
    super.key,
  });

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    FieldBuilderContext ctx,
  ) {
    final field = ctx.field as OptionSelect;

    // Call the field's builder with the new FieldBuilderContext signature
    return field.fieldBuilder(ctx);
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    final field = context.field as OptionSelect;

    // Trigger onChange callback if defined
    if (field.onChange != null) {
      final results = FormResults.getResults(
        controller: context.controller,
        fields: [context.field],
      );
      field.onChange!(results);
    }
  }
}

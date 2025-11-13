import 'package:championforms/fieldbuilders/textfieldbuilder.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/textfield.dart' as form_types;
import 'package:championforms/models/formresults.dart';
import 'package:championforms/widgets_external/stateful_field_widget.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/material.dart' as material_tf show TextField;

/// TextField widget implementation using [StatefulFieldWidget].
///
/// This refactored implementation eliminates ~180 lines of boilerplate by:
/// - Automatic controller and focus management via [FieldBuilderContext]
/// - Automatic value synchronization and change detection
/// - Automatic validation on focus loss (when validateLive is true)
/// - Automatic lifecycle management
///
/// The widget handles:
/// - Text input with Material TextField
/// - Autocomplete overlay integration
/// - Enter key submission via TextField.onSubmitted
/// - Custom field overrides
/// - onChange callback triggering
class TextFieldWidget extends StatefulFieldWidget {
  const TextFieldWidget({
    required super.context,
    super.key,
  });

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    FieldBuilderContext ctx,
  ) {
    final field = ctx.field as form_types.TextField;
    final textController = ctx.getTextController();
    final focusNode = ctx.getFocusNode();
    final materialTheme = Theme.of(context);

    // Build the TextField widget
    final textField = overrideTextField(
      context: context,
      leading: field.leading,
      trailing: field.trailing,
      icon: field.icon,
      labelText: field.textFieldTitle,
      hintText: field.hintText,
      keyboardType: field.keyboardType,
      inputFormatters: field.inputFormatters,
      controller: textController,
      focusNode: focusNode,
      obscureText: field.password,
      colorScheme: ctx.colors,
      baseField: material_tf.TextField(
        maxLines: field.maxLines,
        onChanged: (value) {
          // Sync TextEditingController changes back to FormController
          ctx.setValue(value);
        },
        onSubmitted: (value) {
          // Handle Enter key submission
          if (field.onSubmit != null) {
            final formResults = FormResults.getResults(
              controller: ctx.controller,
            );
            field.onSubmit!(formResults);
          }
        },
        style: materialTheme.textTheme.bodyMedium,
      ),
    );

    // Wrap with autocomplete if configured
    final wrappedField = field.autoComplete != null &&
            field.autoComplete!.type != AutoCompleteType.none
        ? AutocompleteWrapper(
            child: textField,
            autoComplete: field.autoComplete!,
            focusNode: focusNode,
            textEditingController: textController,
            colorScheme: ctx.colors,
          )
        : textField;

    // Wrap with field builder
    return FormFieldWrapperDesignWidget(child: wrappedField);
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    final field = context.field as form_types.TextField;

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

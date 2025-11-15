import 'package:championforms/functions/inputdecoration_from_theme.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/multiselect_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Dropdown field builder for OptionSelect fields.
///
/// Updated in v0.6.0+ to use FieldBuilderContext signature.
/// The context provides access to controller, field, theme, colors, and convenience methods.
Widget dropdownFieldBuilder(FieldBuilderContext ctx) {
  // final context = ctx.controller.context;
  final field = ctx.field as OptionSelect;
  final currentColors = ctx.colors;
  final controller = ctx.controller;
  return MultiselectWidget(
    id: field.id,
    controller: controller,
    field: field,
    requestFocus: field.requestFocus,
    child: DropdownButtonFormField<String>(
      value: field.defaultValue != null && field.defaultValue.isNotEmpty
          ? field.defaultValue.first.value
          : null,
      dropdownColor: currentColors.backgroundColor,
      items: (field.options ?? [])
          .map((option) => DropdownMenuItem<String>(
                value: option.value.toString(),
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: currentColors.textColor,
                  ),
                ),
              ))
          .toList(),
      onSaved: field.onSubmit != null
          ? (String? value) {
              final FormResults results = FormResults.getResults(
                  controller: controller, fields: [field]);
              field.onSubmit!(results);
            }
          : null,
      onChanged: (String? value) {
        // Find the value we're going to pass.
        if (value != null) {
          // Selects from options, or from default values, or makes a new value
          final selectedOption = field.options
                  ?.firstWhereOrNull((val) => value == val.value.toString()) ??
              field.defaultValue
                  .firstWhereOrNull((val) => value == val.value.toString()) ??
              FieldOption(label: value, value: value);

          // Update value using FieldBuilderContext
          controller.updateMultiselectValues(
            field.id,
            [selectedOption],
            multiselect: field.multiselect,
          );
        } else {
          // Clear selection
          controller.resetMultiselectChoices(field.id);
        }

        // Note: onChange callback is triggered automatically via onValueChanged hook
      },
      decoration: getInputDecorationFromScheme(currentColors)?.copyWith(
        prefixIcon: field.leading,
        suffixIcon: field.trailing,
        icon: field.icon,
      ),
    ),
  );
}

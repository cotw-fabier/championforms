import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/multiselect_widget.dart';
import 'package:flutter/material.dart';

/// Radio-group field builder for [OptionSelect] fields.
///
/// The counterpart to `checkboxFieldBuilder`, and the reason it exists is that
/// a single-select `CheckboxSelect` *behaves* correctly — ticking one option
/// clears the others, because `toggleMultiSelectValue` does that when
/// `multiselect` is false — while *looking* wrong. Square ticks say "pick as
/// many as you like"; round radios say "pick exactly one". That is not
/// cosmetic. It is the only signal a person gets about what the control will
/// let them do, before they try.
///
/// Radios are deliberately **not** deselectable by tapping the selected one.
/// A native radio group behaves that way, and a group that can be emptied by
/// accident is a required field that quietly becomes unanswered.
Widget radioFieldBuilder(FieldBuilderContext ctx) {
  final field = ctx.field as OptionSelect;
  final currentColors = ctx.colors;
  final controller = ctx.controller;

  final List<FieldOption> currentSelectedOptions = controller.hasField(field.id)
      ? controller.getFieldValue<List<FieldOption>>(field.id) ?? []
      : [];
  final selectedValue =
      currentSelectedOptions.isEmpty ? null : currentSelectedOptions.first.value;

  return MultiselectWidget(
    id: field.id,
    controller: controller,
    requestFocus: field.requestFocus,
    field: field,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...(field.options ?? []).map(
          (option) => RadioListTile<String>(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              option.label,
              style: TextStyle(color: currentColors.textColor),
            ),
            subtitle: option.hintText == null
                ? null
                : Text(
                    option.hintText!,
                    style: TextStyle(color: currentColors.hintTextColor),
                  ),
            activeColor: currentColors.iconColor,
            hoverColor: currentColors.borderColor,
            tileColor: currentColors.backgroundColor,
            value: option.value,
            // ignore: deprecated_member_use
            groupValue: selectedValue,
            // ignore: deprecated_member_use
            onChanged: field.disabled
                ? null
                : (String? newValue) {
                    if (newValue == null) return;
                    // `toggleMultiSelectValue` clears the other choices for a
                    // single-select field, so the group behaves as a radio
                    // group without this builder tracking state of its own.
                    controller.toggleMultiSelectValue(
                      field.id,
                      toggleOn: [newValue],
                    );
                  },
          ),
        ),
      ],
    ),
  );
}

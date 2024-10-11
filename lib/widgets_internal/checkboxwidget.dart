import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class FormFieldCheckboxWidgetField extends ConsumerWidget {
  const FormFieldCheckboxWidgetField({
    super.key,
    required this.field,
    required this.formId,
    this.multiSelect = true,
    this.width,
    this.height,
    this.maxHeight,
    this.expanded = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;

  final FormFieldDef field;
  final Widget Function({required Widget child})? fieldBuilder;
  final String formId;
  final bool multiSelect;
  final double? width;
  final double? height;
  final double? maxHeight;
  final bool expanded;

  // Default implementation for the fieldBuilder.
  static Widget defaultFieldBuilder({required Widget child}) {
    // Replace this with the implementation of `FormFieldWrapperDesignWidget`.
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void handleCheckboxChange(bool selected, String value) {
      if (!multiSelect && selected) {
        ref.invalidate(choiceChipNotifierProvider("$formId${field.id}"));
      }

      final newChipSelection = ChoiceChipValue(id: value, value: selected);
      final notifier =
          ref.read(choiceChipNotifierProvider("$formId${field.id}").notifier);

      if (selected) {
        notifier.addChoice(newChipSelection);
      } else {
        notifier.removeChoice(value);
      }
    }

    final chipValues =
        ref.watch(choiceChipNotifierProvider("$formId${field.id}"));

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: width ??
            (constraints.maxWidth < double.infinity && expanded
                ? constraints.maxWidth
                : null),
        height: height ??
            (constraints.maxHeight < double.infinity && expanded
                ? constraints.maxHeight
                : null),
        constraints:
            maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
        child: fieldBuilder!(
          child: buildCheckboxList(
            options: field.options,
            chipValues: chipValues,
            onCheckboxChanged: handleCheckboxChange,
          ),
        ),
      );
    });
  }
}

// This function creates the column list of checkboxes
Widget buildCheckboxList({
  required List<FormFieldChoiceOption> options,
  required List<ChoiceChipValue> chipValues,
  required void Function(bool selected, String value) onCheckboxChanged,
}) {
  return ListView(
    shrinkWrap: true,
    children: options
        .map(
          (option) => CheckboxListTile(
            title: Text(option.name),
            value: chipValues
                    .firstWhereOrNull((element) => element.id == option.value)
                    ?.value ??
                false,
            onChanged: (bool? selected) {
              if (selected != null) {
                onCheckboxChanged(selected, option.value);
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        )
        .toList(),
  );
}

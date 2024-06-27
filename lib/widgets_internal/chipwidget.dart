import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class FormFieldChipField extends ConsumerWidget {
  const FormFieldChipField({
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
          child: Wrap(
            spacing: 7,
            runSpacing: 10,
            children: field.options
                .map((option) => ChoiceChip(
                    label: Text(option.name),
                    selected: chipValues
                            .firstWhereOrNull(
                                (element) => element.id == option.value)
                            ?.value ??
                        false,
                    onSelected: (bool selected) {
                      if (!multiSelect && selected) {
                        ref.invalidate(
                            choiceChipNotifierProvider("$formId${field.id}"));
                      }

                      // do we reset the values so only one can be selected?

                      debugPrint(
                          "Selected: ${option.value} Turned it $selected");
                      if (selected) {
                        final newChipSelection =
                            ChoiceChipValue(id: option.value, value: true);
                        ref
                            .read(
                                choiceChipNotifierProvider("$formId${field.id}")
                                    .notifier)
                            .addChoice(newChipSelection);
                      } else {
                        ref
                            .read(
                                choiceChipNotifierProvider("$formId${field.id}")
                                    .notifier)
                            .removeChoice(option.value);
                      }
                    }))
                .toList(),
          ),
        ),
      );
    });
  }
}

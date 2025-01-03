import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/providers/field_focus.dart';
import 'package:championforms/providers/formfield_value_by_id.dart';
import 'package:championforms/providers/formfieldsstorage.dart';
import 'package:championforms/providers/multiselect_provider.dart';
import 'package:championforms/widgets_internal/field_widgets/textfieldwidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/providers/formerrorprovider.dart';
import 'package:collection/collection.dart';

class FormBuilderWidget extends ConsumerStatefulWidget {
  const FormBuilderWidget({
    super.key,
    this.fields = const [],
    required this.id,
    required this.formWrapper,
    required this.theme,
    this.spacer,
  });

  final List<FormFieldBase> fields;
  final String id;
  final double? spacer;
  final Widget Function(
    BuildContext context,
    List<Widget> form,
  ) formWrapper;

  final FormTheme theme;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FormBuilderWidgetState();
}

class _FormBuilderWidgetState extends ConsumerState<FormBuilderWidget> {
  @override
  void initState() {
    super.initState();

    // We're going to loop through the incoming fields and set defaults for chip values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // At this point we need to make sure all these fields are merged together into one list in case we need to reference it later.
      ref
          .read(formFieldsStorageNotifierProvider(widget.id).notifier)
          .addFields(widget.fields.whereType<FormFieldDef>().toList());

      // Replace with your default values for chips

      for (final field in widget.fields) {
        if (field is FormFieldDef) {
          // populate default values for the text fields
          if (field is ChampionTextField) {
            ref
                .read(textFormFieldValueByIdProvider("${widget.id}${field.id}")
                    .notifier)
                .updateValue(field.defaultValue ?? "");
          } else if (field is ChampionOptionSelect) {
            for (final defaultValue in field.defaultValue) {
              final defaultOption = field.options
                  .firstWhereOrNull((option) => option.value == defaultValue);

              if (defaultOption != null) {
                ref
                    .read(multiSelectOptionNotifierProvider(
                            "${widget.id}${field.id}")
                        .notifier)
                    .addChoice(defaultOption, field.multiselect);
              }
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> output = [];

    // Listen for the form fields as long as this form is active
    ref.listen(formFieldsStorageNotifierProvider(widget.id), (prev, next) {});

    for (final field in widget.fields) {
      if (field is FormFieldDef) {
        //debugPrint("Field ${field.id} is hidden: ${field.hideField}");
        if (field.hideField) continue;

        // If we have validators and we're doing live validation lets setup the function now
        Function(String value)? validate;
        if (field.validateLive) {
          validate = (value) {
            // int validatorPosition = 0;

            // Pull results for just this field
            FormResults.getResults(
              formId: widget.id,
              fields: [field],
              ref: ref,
            );
          };
        }

        // Determine what state we are in and set colors / etc based on our state:

        // Start with errors

        final int validatorCount = field.validators?.length ?? 0;
        List<FormBuilderError> errors = [];

        for (int i = 0; i < validatorCount; i++) {
          final error = ref
              .watch(formBuilderErrorNotifierProvider(widget.id, field.id, i));

          if (error != null) errors.add(error);
        }

        // merge the theme from the field into the form theme.
        final finalTheme = field.theme != null
            ? widget.theme.copyWith(theme: field.theme)
            : widget.theme;

        // Set the state
        final fieldFocused =
            ref.watch(fieldFocusNotifierProvider(widget.id + field.id));
        FieldState fieldState;
        FieldColorScheme fieldColor;
        if (errors.isNotEmpty) {
          fieldState = FieldState.error;
          fieldColor = finalTheme.errorColorScheme!;
        } else if (field.disabled == true) {
          fieldState = FieldState.disabled;
          fieldColor = finalTheme.disabledColorScheme!;
        } else if (fieldFocused) {
          fieldState = FieldState.active;
          fieldColor = finalTheme.activeColorScheme!;
        } else {
          fieldState = FieldState.normal;
          fieldColor = finalTheme.colorScheme!;
        }

        Widget outputWidget;

        // Determine the field layout and the field background

        switch (field) {
          case ChampionTextField():
            outputWidget = TextFieldWidget(
              id: "${widget.id}${field.id}",
              field: field,
              fieldOverride: field.fieldOverride,
              fieldState: fieldState,
              colorScheme: fieldColor,
              formId: widget.id,
              fieldId: field.id,
              onDrop: field.onDrop,
              onPaste: field.onPaste,
              draggable: field.draggable,
              onSubmitted: field.onSubmit,
              onChanged: field.onChange,
              password: field.password,
              requestFocus: field.requestFocus,
              validate: validate,
              initialValue: field.defaultValue,
              labelText: field.textFieldTitle,
              hintText: field.hintText,
              maxLines: field.maxLines,
            );

            break;

          case ChampionOptionSelect():

            // Because we are using a builder instead of a widget we need to listen to the value provider here

            ref.listen(
                multiSelectOptionNotifierProvider("${widget.id}${field.id}"),
                (prev, next) {});

            outputWidget = field.fieldBuilder(
              context,
              ref,
              widget.id,
              field.options,
              field,
              fieldState,
              fieldColor,
              ref
                  .watch(multiSelectOptionNotifierProvider(
                      "${widget.id}${field.id}"))
                  .map((option) => option.value)
                  .toList(),
              (focus) {
                ref
                    .read(fieldFocusNotifierProvider(widget.id + field.id)
                        .notifier)
                    .setFocus(focus);
              },
              (MultiselectOption? selectedOption) {
                if (selectedOption != null) {
                  ref
                      .read(multiSelectOptionNotifierProvider(
                              "${widget.id}${field.id}")
                          .notifier)
                      .addChoice(selectedOption, field.multiselect);
                } else {
                  ref
                      .read(multiSelectOptionNotifierProvider(
                              ("${widget.id}${field.id}"))
                          .notifier)
                      .resetChoices();
                }
                if (field.validateLive == true) {
                  // Run validation
                  FormResults.getResults(
                      ref: ref, formId: widget.id, fields: [field]);
                }
              },
            );

            break;

          default:
            outputWidget = Container();
            break;
        }

        // Lets add the new form field with our layout
        output.add(
          field.fieldLayout(
            context,
            field,
            fieldColor,
            errors,
            field.fieldBackground(
              context,
              field,
              fieldColor,
              outputWidget,
            ),
          ),
        );

        // Add a simple spacer
        if (widget.spacer != null) {
          output.add(SizedBox(
            height: widget.spacer!,
          ));
        }
      }
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: widget.formWrapper(
        context,
        output,
      ),
    );
  }
}

class FormBuilderValidatorErrors extends ConsumerWidget {
  const FormBuilderValidatorErrors({
    super.key,
    required this.id,
    required this.field,
  });

  final String id;
  final FormFieldDef field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // determine if there is an error for this field.
    // If there is, then we need to return it in order of validator

    final int validatorCount = field.validators?.length ?? 0;

    List<FormBuilderError> errors = [];

    for (int i = 0; i < validatorCount; i++) {
      final error =
          ref.watch(formBuilderErrorNotifierProvider(id, field.id, i));

      if (error != null) errors.add(error);
    }

    // We have zero errors, so we can return a blank list.
    if (errors == []) {
      return Container();
    }
    List<Widget> output = [];

    // Loop through, add each error reason to the list
    for (final error in errors) {
      output.add(
          Text(error.reason, style: Theme.of(context).textTheme.labelSmall));
      output.add(const SizedBox(
        height: 10,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: output,
    );
  }
}

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/field_widgets/textfieldwidget.dart';
import 'package:flutter/material.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/formfieldclass.dart';

class FormBuilderWidget extends StatefulWidget {
  const FormBuilderWidget({
    super.key,
    this.fields = const [],
    required this.formWrapper,
    required this.theme,
    required this.controller,
    this.spacer,
  });

  final List<FormFieldBase> fields;
  final double? spacer;
  final ChampionFormController controller;
  final Widget Function(
    BuildContext context,
    List<Widget> form,
  ) formWrapper;

  final FormTheme theme;
  @override
  State<StatefulWidget> createState() => _FormBuilderWidgetState();
}

class _FormBuilderWidgetState extends State<FormBuilderWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuildOnControllerUpdate);

    // We're going to loop through the incoming fields and set defaults for chip values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // At this point we need to make sure all these fields are merged together into one list in case we need to reference it later.
      _updateDefaults();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuildOnControllerUpdate);
    super.dispose();
  }

  void _rebuildOnControllerUpdate() {
    setState(() {});
  }

  void _updateDefaults() {
    // We're going to add all fields from this widget into our controller
    widget.controller
        .addFields(widget.fields.whereType<FormFieldDef>().toList());

    // Replace with your default values for chips

    for (final field in widget.fields) {
      if (field is FormFieldDef) {
        // populate default values for the text fields
        if (field is ChampionTextField) {
          widget.controller
              .updateTextFieldValue(field.id, field.defaultValue ?? "");
        } else if (field is ChampionOptionSelect) {
          final defaultValues = field.options
              .where((option) => field.defaultValue.contains(option.value))
              .toList();
          if (defaultValues.isNotEmpty) {
            widget.controller.updateMultiselectValues(field.id, defaultValues,
                multiselect: field.multiselect);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> output = [];

    // Listen for the form fields as long as this form is active

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
              controller: widget.controller,
              fields: [field],
            );
          };
        }

        // Determine what state we are in and set colors / etc based on our state:

        // Start with errors

        //final int validatorCount = field.validators?.length ?? 0;
        List<FormBuilderError> errors = [];

        errors = [...errors, ...widget.controller.findErrors(field.id)];

        // merge the theme from the field into the form theme.
        final finalTheme = field.theme != null
            ? widget.theme.copyWith(theme: field.theme)
            : widget.theme;

        // Set the state
        final fieldFocused = widget.controller.isFieldFocused(field.id);
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
              controller: widget.controller,
              field: field,
              fieldOverride: field.fieldOverride,
              fieldState: fieldState,
              colorScheme: fieldColor,
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
            outputWidget = field.fieldBuilder(
              context,
              widget.controller,
              field.options,
              field,
              fieldState,
              fieldColor,
              widget.controller
                      .findMultiselectValue(field.id)
                      ?.values
                      .map((option) => option.value)
                      .toList() ??
                  [],
              (focus) {
                widget.controller.setFieldFocus(field.id, focus);
              },
              (MultiselectOption? selectedOption) {
                if (selectedOption != null) {
                  widget.controller.updateMultiselectValues(
                      field.id, [selectedOption],
                      multiselect: field.multiselect);
                } else {
                  widget.controller.resetMultiselectChoices(field.id);
                }
                if (field.validateLive == true) {
                  // Run validation
                  FormResults.getResults(
                      controller: widget.controller, fields: [field]);
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

class FormBuilderValidatorErrors extends StatelessWidget {
  const FormBuilderValidatorErrors({
    super.key,
    required this.field,
    required this.controller,
  });

  final ChampionFormController controller;
  final FormFieldDef field;

  @override
  Widget build(
    BuildContext context,
  ) {
    // determine if there is an error for this field.
    // If there is, then we need to return it in order of validator

    //final int validatorCount = field.validators?.length ?? 0;

    List<FormBuilderError> errors = [];

    errors = [...errors, ...controller.findErrors(field.id)];

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

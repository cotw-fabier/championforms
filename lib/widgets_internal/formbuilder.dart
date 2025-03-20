import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/functions/gather_child_errors.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/field_types/championtextfield.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/field_widgets/textfieldwidget.dart';
import 'package:championforms/widgets_internal/rowcolumn_widgets/row_builder.dart';
import 'package:flutter/material.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';

class FormBuilderWidget extends StatefulWidget {
  const FormBuilderWidget({
    super.key,
    this.fields = const [],
    this.pageName = "default",
    this.formWrapper,
    required this.theme,
    required this.controller,
    this.spacer,
    this.parentErrors,
    this.fieldPadding,
  });

  final List<FormBuilderError>? parentErrors;
  final EdgeInsets? fieldPadding;

  final List<FormFieldBase> fields;
  final String? pageName;
  final double? spacer;
  final ChampionFormController controller;
  final Widget Function(
    BuildContext context,
    List<Widget> form,
  )? formWrapper;

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

      // Create a running list of visible fields for more refined error checking on
      // multipage forms which may not display all fields at once.

      widget.controller
          .updateActiveFields(widget.fields.whereType<FormFieldDef>().toList());

      // Update the pageFields
      // only run this if the page isn't set to "default"
      if (widget.pageName != null) {
        widget.controller.updatePageFields(
            widget.pageName!, widget.fields.whereType<FormFieldDef>().toList());
      }
    });
  }

  @override
  void dispose() {
    // Clean up active fields.
    widget.controller
        .removeActiveFields(widget.fields.whereType<FormFieldDef>().toList());

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
                multiselect: field.multiselect, overwrite: true);
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
      // If we have validators and we're doing live validation lets setup the function now
      Function(String value)? validate;
      if (field is FormFieldDef) {
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
      }

      // Determine what state we are in and set colors / etc based on our state:

      // Start with errors

      // If we have a parent rolling up errors,
      // we skip direct display of errors in the child
      // but we still need the child to highlight in red, etc.
      List<FormBuilderError> errorsForThisField =
          widget.controller.findErrors(field.id);

      // If the field is hidden, skip:
      if ((field as dynamic).hideField) {
        continue;
      }

      // Merge the field's custom theme with the parent form's theme
      final mergedTheme = (field is FormFieldDef && field.theme != null)
          ? widget.theme.copyWith(theme: field.theme)
          : widget.theme;

      // Determine field color state from errors or focus
      FieldState fieldState;
      FieldColorScheme fieldColors;
      final hasErrors = errorsForThisField.isNotEmpty;
      final isFocused = (field is FormFieldDef)
          ? widget.controller.isFieldFocused(field.id)
          : false;

      if (hasErrors) {
        fieldState = FieldState.error;
        fieldColors = mergedTheme.errorColorScheme!;
      } else if (field is FormFieldDef && field.disabled) {
        fieldState = FieldState.disabled;
        fieldColors = mergedTheme.disabledColorScheme!;
      } else if (isFocused) {
        fieldState = FieldState.active;
        fieldColors = mergedTheme.activeColorScheme!;
      } else {
        fieldState = FieldState.normal;
        fieldColors = mergedTheme.colorScheme!;
      }

      Widget outputWidget;

      // Determine the field layout and the field background

      switch (field) {
        // Row and Column
        // if you see a row, run displaylogic and then call this widget recursively.
        // ---- CHAMPION ROW ----
        case ChampionRow rowField:
          {
            List<FormBuilderError> childErrors = [];

            if (rowField.rollUpErrors) {
              // Gather child errors from all columns inside the row
              childErrors = gatherAllChildErrors(
                rowField.columns.expand((c) => c.fields).toList(),
                widget.controller,
              );
            }

            // If rowField.rollUpErrors is true, the row
            // should display all child errors.
            // Otherwise the row only displays its own direct errors.
            final rowErrors =
                rowField.rollUpErrors ? childErrors : errorsForThisField;

            // Determine row color state from rowErrors
            final rowHasErrors = rowErrors.isNotEmpty;
            final rowState = rowHasErrors ? FieldState.error : fieldState;
            final rowColor =
                rowHasErrors ? mergedTheme.errorColorScheme! : fieldColors;

            // Finally build the row
            outputWidget = ChampionRowWidget(
              rowField: rowField,
              columns: rowField.columns,
              errors: rowErrors.isEmpty ? null : rowErrors,
              colorScheme: rowColor,
              controller: widget.controller,
              theme: mergedTheme,
              fieldPadding: widget.fieldPadding,
            );

            break;
          }

        case ChampionTextField():
          outputWidget = TextFieldWidget(
            controller: widget.controller,
            field: field,
            fieldOverride: field.fieldOverride,
            fieldState: fieldState,
            colorScheme: fieldColors,
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
            fieldColors,
            widget.controller
                    .findMultiselectValue(field.id)
                    ?.values
                    .map((option) => option.value)
                    .toList() ??
                [],
            (focus) {
              widget.controller.setFieldFocus(field.id, focus, field);
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

      // Add padding to the form field if it was defined.
      if (widget.fieldPadding != null &&
          widget.fieldPadding != EdgeInsets.all(0) &&
          field is FormFieldDef) {
        outputWidget =
            Padding(padding: widget.fieldPadding!, child: outputWidget);
      }

      // Lets add the new form field with our layout
      if (field is FormFieldDef) {
        output.add(
          field.fieldLayout(
            context,
            field,
            fieldColors,
            widget.parentErrors == null ? errorsForThisField : [],
            field.fieldBackground(
              context,
              field,
              fieldColors,
              outputWidget,
            ),
          ),
        );
      } else if (field is ChampionRow || field is ChampionColumn) {
        output.add(outputWidget);
      }

      // Add a simple spacer
      if (widget.spacer != null) {
        output.add(SizedBox(
          height: widget.spacer!,
        ));
      }
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: widget.formWrapper != null
          ? widget.formWrapper!(
              context,
              output,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: output,
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

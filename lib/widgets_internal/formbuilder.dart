import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/functions/gather_child_errors.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/field_types/championtextfield.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/rowcolumn_widgets/column_builder.dart';
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

    // --- Ensure core builders are registered ---
    if (!ChampionFormFieldRegistry.instance.hasBuilderFor(ChampionTextField)) {
      ChampionFormFieldRegistry.instance
          .registerCoreBuilders(); // Call your registration logic
    }

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
    widget.controller.removeListener(_rebuildOnControllerUpdate);
    // Clean up active fields.
    widget.controller.removeActiveFields(
      widget.fields.whereType<FormFieldDef>().toList(),
      // noNotify: true,
    );
    super.dispose();
  }

  void _rebuildOnControllerUpdate() {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _updateDefaults() {
    final fieldDefs = widget.fields.whereType<FormFieldDef>().toList();

    // We're going to add all fields from this widget into our controller
    widget.controller
        .addFields(widget.fields.whereType<FormFieldDef>().toList());

    // Replace with your default values for chips

    for (final field in widget.fields) {
      final fieldDefs = widget.fields.whereType<FormFieldDef>().toList();

      // Add fields to controller (registers definitions, calculates initial state)
      widget.controller.addFields(fieldDefs,
          noNotify: true); // noNotify true likely okay here

      if (field is FormFieldDef) {
        // populate default values for the text fields
        // Only set if the value isn't already present or differs from default
        final currentValue = widget.controller.getFieldValue<dynamic>(field.id);
        if (currentValue == null && field.defaultValue != null) {
          widget.controller
              .updateFieldValue(field.id, field.defaultValue, noNotify: true);
        }
        // if (field is ChampionTextField) {
        // } else if (field is ChampionOptionSelect) {
        //   final defaultValues = field.options
        //       .where((option) => field.defaultValue.contains(option.value))
        //       .toList();
        //   if (defaultValues.isNotEmpty) {
        //     widget.controller.updateMultiselectValues(field.id, defaultValues,
        //         multiselect: field.multiselect, overwrite: true);
        // }
        // }
      }
    }
    // Update active fields list in the controller
    widget.controller.updateActiveFields(fieldDefs, noNotify: true);

    // Update page fields if applicable
    if (widget.pageName != null && widget.pageName != "default") {
      widget.controller.updatePageFields(widget.pageName!, fieldDefs);
    }

    // Initial validation check if needed? Usually done on submit/interaction.
    // If initial errors are desired:
    // FormResults.getResults(controller: widget.controller, fields: fieldDefs);

    // Trigger a rebuild if initial values were set
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> output = [];

    // Listen for the form fields as long as this form is active

    for (final field in widget.fields) {
      // --- Skip hidden fields ---
      if (field is ChampionRow && field.hideField ||
          field is ChampionColumn && field.hideField ||
          field is FormFieldDef && field.hideField) {
        continue;
      }

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

      // --- Process Based on Field Type ---

      // Determine field color state from errors or focus
      FieldState fieldState;
      FieldColorScheme fieldColors;
      final hasErrors = errorsForThisField.isNotEmpty;
      final isFocused = (field is FormFieldDef)
          ? widget.controller.isFieldFocused(field.id)
          : false;

      // ---- Process based on field type ----
      Widget outputWidget;

      // Determine the field layout and the field background

      if (field is FormFieldDef) {
        // 1. Get the state from the controller
        final FieldState fieldState = widget.controller.getFieldState(field.id);

        // 2. Determine colors based on the retrieved state and theme
        final FieldColorScheme fieldColors;
        switch (fieldState) {
          case FieldState.error:
            fieldColors = mergedTheme.errorColorScheme!;
            break;
          case FieldState.disabled:
            fieldColors = mergedTheme.disabledColorScheme!;
            break;
          case FieldState.active:
            fieldColors = mergedTheme.activeColorScheme!;
            break;
          case FieldState.normal:
          default:
            fieldColors = mergedTheme.colorScheme!;
            break;
        }

        // 3. Get errors for potential display (only if not rolled up by parent)
        final List<FormBuilderError> errorsForDisplay =
            widget.parentErrors == null
                ? widget.controller.findErrors(field.id)
                : []; // Don't display if parent handles it

        // 4. Build the field using the registry
        outputWidget = ChampionFormFieldRegistry.instance.buildField(
          context,
          widget.controller,
          field, // The field definition
          fieldState, // The state retrieved from controller
          fieldColors, // The colors determined by state & theme
          (bool focused) {
            // Focus change callback -> Notify controller
            widget.controller.setFieldFocus(field.id, focused);
          },
          // Pass other necessary parameters if buildField requires them
        );

        // 5. Apply Padding if specified
        if (widget.fieldPadding != null &&
            widget.fieldPadding != EdgeInsets.zero) {
          outputWidget =
              Padding(padding: widget.fieldPadding!, child: outputWidget);
        }

        // 6. Wrap with standard field layout (title, description, errors)
        output.add(
          field.fieldLayout(
            context,
            field,
            widget.controller,
            fieldColors,
            field.fieldBackground(
              context,
              field,
              widget.controller,
              fieldColors,
              outputWidget, // The widget built by the registry
            ),
          ),
        );
      } else if (field is ChampionRow) {
        // --- Handle Row Layout ---
        List<FormBuilderError> childErrors = [];
        bool rowHasDirectErrors = widget.controller
            .findErrors(field.id)
            .isNotEmpty; // Check if row itself has errors assigned

        if (field.rollUpErrors) {
          childErrors = gatherAllChildErrors(
            field.columns.expand((c) => c.fields).toList(),
            widget.controller,
          );
        }

        // Errors to potentially display *at the row level*
        final rowErrorsForDisplay = field.rollUpErrors
            ? childErrors
            : (rowHasDirectErrors
                ? widget.controller.findErrors(field.id)
                : []);
        final bool rowShouldHighlightError = rowErrorsForDisplay.isNotEmpty;

        // Determine Row's appearance based on its errors (rolled up or direct)
        final rowColor = rowShouldHighlightError
            ? mergedTheme.errorColorScheme!
            : mergedTheme.colorScheme!;

        // If rowField.rollUpErrors is true, the row
        // should display all child errors.
        // Otherwise the row only displays its own direct errors.
        final rowErrors = field.rollUpErrors ? childErrors : errorsForThisField;

        // Finally build the row
        outputWidget = ChampionRowWidget(
          rowField: field,
          columns: field.columns,
          errors: rowErrors.isEmpty ? null : rowErrors,
          colorScheme: rowColor,
          controller: widget.controller,
          theme: mergedTheme,
          fieldPadding: widget.fieldPadding,
        );

        output.add(outputWidget); // Add column directly
      } else if (field is ChampionColumn) {
        // --- Handle Column Layout (Usually within a Row) ---
        List<FormBuilderError> colChildErrors = [];
        bool colHasDirectErrors =
            widget.controller.findErrors(field.id).isNotEmpty;

        if (field.rollUpErrors) {
          colChildErrors =
              gatherAllChildErrors(field.fields, widget.controller);
        }

        final List<FormBuilderError>? colErrorsForDisplay = field.rollUpErrors
            ? colChildErrors
            : (colHasDirectErrors
                ? widget.controller.findErrors(field.id)
                : []);
        final bool colShouldHighlightError =
            colErrorsForDisplay?.isNotEmpty ?? false;

        final colColor = colShouldHighlightError
            ? mergedTheme.errorColorScheme!
            : mergedTheme.colorScheme!;

        outputWidget = ChampionColumnWidget(
          columnField: field,
          errors: colErrorsForDisplay?.isEmpty ?? false
              ? null
              : colErrorsForDisplay,
          colorScheme: colColor, // Pass calculated color
          controller: widget.controller,
          columnWrapper: field.columnWrapper,
          theme: mergedTheme, // Pass theme
          fieldPadding: widget.fieldPadding, // Pass padding
        );
        output.add(outputWidget); // Add column directly
      } else {
        // Should not happen if all fields extend FormFieldBase
        outputWidget = const SizedBox.shrink(); // Or an error widget
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

// --- FormBuilderValidatorErrors Widget ---
class FormBuilderValidatorErrors extends StatelessWidget {
  const FormBuilderValidatorErrors({
    super.key,
    required this.fieldId, // Use fieldId instead of the whole field object
    required this.controller,
    this.errorTextStyle, // Allow custom styling
  });

  final ChampionFormController controller;
  final String fieldId;
  final TextStyle? errorTextStyle;

  @override
  Widget build(BuildContext context) {
    // Get errors directly from the controller for this field ID
    final List<FormBuilderError> errors = controller.findErrors(fieldId);

    // If no errors, return an empty container
    if (errors.isEmpty) {
      return const SizedBox.shrink(); // Use SizedBox.shrink() for zero size
    }

    // Default style if none provided
    final style = errorTextStyle ??
        Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error);

    // Build the list of error texts
    List<Widget> output = [];
    for (int i = 0; i < errors.length; i++) {
      output.add(Text(errors[i].reason, style: style));
      // Add spacing between multiple errors, but not after the last one
      if (i < errors.length - 1) {
        output.add(const SizedBox(height: 4)); // Smaller spacing for errors
      }
    }

    // Wrap errors in a column
    return Padding(
      padding: const EdgeInsets.only(top: 4.0), // Add some top padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // Align errors left
        children: output,
      ),
    );
  }
}

import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/providers/fieldactiveprovider.dart';
import 'package:championforms/providers/formfieldsstorage.dart';
import 'package:championforms/providers/textformfieldbyid.dart';
import 'package:championforms/widgets_external/layoutwrappers/verticallayout.dart';
import 'package:championforms/widgets_internal/field_widgets/textfieldwidget.dart';
import 'package:championforms/widgets_internal/fieldelements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formfieldtoolbar.dart';
import 'package:championforms/providers/formerrorprovider.dart';
import 'package:championforms/widgets_internal/quilltoolbar.dart';

class FormBuilderWidget extends ConsumerStatefulWidget {
  const FormBuilderWidget({
    super.key,
    this.fields = const [],
    required this.id,
    this.spacing = 10,
    this.formWidth,
    this.formHeight,
    required this.theme,
  });

  final List<FormFieldBase> fields;
  final String id;
  final double spacing;
  final double? formWidth;
  final double? formHeight;
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
          if (field is FormFieldTextField) {
            ref
                .read(
                    textFormFieldValueById("${widget.id}${field.id}").notifier)
                .state = field.defaultValue ?? "";
          }

          // populate default values for chips
          // TODO: Implement Choice Fields
          /*
          if (field.type == FormFieldType.chips ||
              field.type == FormFieldType.checkbox ||
              field.type == FormFieldType.dropdown) {
            for (final defaultValue in field.defaultValues ?? []) {
              final defaultChipValue =
                  ChoiceChipValue(id: defaultValue, value: true);
              ref
                  .read(choiceChipNotifierProvider("${widget.id}${field.id}")
                      .notifier)
                  .addChoice(defaultChipValue);
            }
          }
          */

          // populate default values for tag field
          // TODO Implement tag Field
          /*
          if (field.type == FormFieldType.tagField) {
            ref
                .read(formListStringsNotifierProvider("${widget.id}${field.id}")
                    .notifier)
                .populate(field.defaultValues);
          }
          */

          // Populate the rich text field controller
          // TODO Implement Rich Text Field
          /*
          if (field.type == FormFieldType.richText) {
            ref
                .read(quillControllerNotifierProvider(
                  widget.id,
                  field.id,
                ).notifier)
                .setValue(
                  (field.deltaValue ?? Delta()
                    ..insert(field.defaultValue ?? "")),
                );
          }
          */
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> output = [];
    final theme = Theme.of(context);

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
            int validatorPosition = 0;

            // Pull results for just this field
            final fieldResults = FormResults.getResults(
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
        FieldState fieldState;
        FieldColorScheme fieldColor;
        if (errors.isNotEmpty) {
          fieldState = FieldState.error;
          fieldColor = finalTheme.errorColorScheme!;
        } else if (field.disabled == true) {
          fieldState = FieldState.disabled;
          fieldColor = finalTheme.disabledColorScheme!;
        } else if (ref.watch(fieldActiveNotifierProvider(widget.id)) ==
            field.id) {
          fieldState = FieldState.active;
          fieldColor = finalTheme.activeColorScheme!;
        } else {
          fieldState = FieldState.normal;
          fieldColor = finalTheme.colorScheme!;
        }

        Widget outputWidget;

        switch (field) {
          case FormFieldTextField():
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
              icon: field.icon,
              initialValue: field.defaultValue,
              hintText: field.hintText,
              maxLines: field.maxLines,
            );

            break;

          // TODO Reimplement other field types
          /*
          case FormFieldType.richText:
            outputWidget = QuillWidgetTextArea(
              field: field,
              height: field.height,
              maxHeight: field.maxHeight,
              password: field.password,
              id: "${widget.id}${field.id}",
              fieldId: field.id,
              formId: widget.id,
              requestFocus: field.requestFocus,
              onChanged: field.onChange,
              active: field.active,
              icon: field.icon,
              initialValue: field.deltaValue ?? Delta()
                ..insert(field.defaultValue ?? ""),
              hintText: field.hintText,
              maxLines: null,
              onDrop: field.onDrop,
              onPaste: field.onPaste,
              draggable: field.draggable,
            );

            break;
          case FormFieldType.chips:
            outputWidget = FormFieldChipField(
              field: field,
              formId: widget.id,
              multiSelect: field.multiselect,
              height: field.height,
              onChanged: field.onChange,
              maxHeight: field.maxHeight,
              expanded: field.fillArea,
            );

            break;
          case FormFieldType.dropdown:
            outputWidget = FormFieldSearchableDropDownField(
              field: field,
              formId: widget.id,
              multiSelect: field.multiselect,
              // TODO: Implement onSubmitted
              //onSubmitted: field.onSubmit,
              onChanged: field.onChange,
              height: field.height,
              maxHeight: field.maxHeight,
              expanded: field.fillArea,
            );

            break;
          case FormFieldType.checkbox:
            outputWidget = FormFieldCheckboxWidgetField(
              field: field,
              formId: widget.id,
              multiSelect: field.multiselect,
              // TODO: Implement onSubmitted
              //onSubmitted: field.onSubmit,
              onChanged: field.onChange,
              height: field.height,
              maxHeight: field.maxHeight,
              expanded: field.fillArea,
            );

            break;
          case FormFieldType.tagField:
            // Watch this provider to keep it alive while the form is active
            final tagValues = ref.watch(
                formListStringsNotifierProvider("${widget.id}${field.id}"));

            outputWidget = FormBuilderStringAutoCompleteTags(
              id: widget.id,
              field: field,
              initialValues: field.defaultValues ?? [],
              // TODO: Implement OnSubmitted
              //onSubmitted: field.onSubmit,
              //onChanged: field.onChange,
              expanded: field.fillArea,
              fieldBuilder: field.fieldBuilder,
            );

            break;
          case FormFieldType.widget:
            outputWidget = field.child ?? Container();
            break;
          */

          default:
            outputWidget = Container();
            break;
        }

        // Lets establish our field layout
        Widget Function({
          Widget? title,
          Widget? description,
          Widget? errors,
          Widget? icon,
          bool? expanded,
          FormTheme theme,
          Widget layout,
          Widget field,
        }) fieldLayout;

        if (widget.theme.layoutBuilder! != null) {
          fieldLayout = widget.theme.layoutBuilder!;
        } else {
          fieldLayout = fieldVerticalLayoutBuilder(
            field: outputWidget,
            theme: field.theme ?? widget.theme,
          );
        }
        // Lets add the new form field with our layout
        output.add(
          FormFieldWrapper(
            expanded: field.fillArea,
            width: field.width,
            height: field.height,
            flex: field.flex,
            child: Builder(builder: (context) {
              return fieldLayout(
                title: field.title != null
                    ? FieldTextElement(
                        color: fieldColor.titleColor,
                        textStyle: field.titleStyle ?? widget.theme.titleStyle!,
                        text: field.title!)
                    : null,
                description: field.description != null
                    ? FieldTextElement(
                        color: fieldColor.descriptionColor,
                        textStyle: field.descriptionStyle ??
                            widget.theme.descriptionStyle!,
                        text: field.description!)
                    : null,
                expanded: field.fillArea,
                // TODO: Add Errors
                fieldWrapper: field.fieldBuilder ?? widget.theme.fieldBuilder,
                icon: field.icon,
                colors: fieldColor,
                field: outputWidget,
              );
            }),
          ),
        );

        // Add spacer

        output.add(SizedBox(
          height: widget.spacing,
        ));
      } else if (field is FormFieldToolbar) {
        // We're going to add the toolbar here
        final toolbar = QuillToolbarWidget(
          fieldId: field.editorId,
          formId: field.formId ?? widget.id,
          hideField: field.hideField,
          followLastActiveQuill: field.followLastActiveQuill,
          disableField: field.disableField,
          toolbarBuilder: field.toolbarBuilder,
        );

        output.add(toolbar);
      }
    }

    return Container(
      width: widget.formWidth,
      height: widget.formHeight,
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: output,
        );
      }),
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

class FormFieldWrapper extends StatelessWidget {
  const FormFieldWrapper({
    super.key,
    required this.expanded,
    this.width,
    this.height,
    required this.child,
    this.flex,
  });
  final bool expanded;
  final double? width;
  final double? height;
  final Widget child;
  final int? flex;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return child;
    }
    return Expanded(
      flex: flex ?? 1,
      child: LayoutBuilder(builder: (context, constraints) {
        return child;
      }),
    );
  }
}

/* class FormBuilderWidget extends ConsumerWidget {
  const FormBuilderWidget({
    super.key,
    this.fields = const [],
    required this.id,
  });

  final List<FormFieldDef> fields;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> output = [];

    for (final field in fields) {
      switch (field.type) {
        case FormFieldType.textField:
          // TODO: Handle this case.

          break;

        default:
          break;
      }
    }

    return Container();
  }
}
 */

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/functions/gather_child_errors.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/column.dart';
import 'package:championforms/models/field_types/row.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_external/form_wrappers/simple_wrapper.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';

class FormBuilderWidget extends flutter.StatefulWidget {
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
  final flutter.EdgeInsets? fieldPadding;

  final List<FormElement> fields;
  final String? pageName;
  final double? spacer;
  final FormController controller;
  final flutter.Widget Function(
    flutter.BuildContext context,
    List<flutter.Widget> form,
  )? formWrapper;

  final FormTheme theme;
  @override
  flutter.State<flutter.StatefulWidget> createState() => _FormBuilderWidgetState();
}

class _FormBuilderWidgetState extends flutter.State<FormBuilderWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuildOnControllerUpdate);

    if (!FormFieldRegistry.instance.isInitialized) {
      FormFieldRegistry.instance.registerCoreBuilders();
    }

    flutter.WidgetsBinding.instance.addPostFrameCallback((_) {
      final allFieldDefs = _flattenAllFields(widget.fields);
      _updateDefaults(allFieldDefs);
      widget.controller.updateActiveFields(allFieldDefs);
      if (widget.pageName != null) {
        widget.controller.updatePageFields(widget.pageName!, allFieldDefs);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuildOnControllerUpdate);
    widget.controller.removeActiveFields(
      _flattenAllFields(widget.fields),
    );
    super.dispose();
  }

  List<Field> _flattenAllFields(List<FormElement> elements) {
    final List<Field> flatList = [];
    for (final element in elements) {
      if (element is Field) {
        flatList.add(element);
      } else if (element is Row) {
        for (final column in element.children) {
          flatList.addAll(_flattenAllFields(column.children));
        }
      } else if (element is Column) {
        flatList.addAll(_flattenAllFields(element.children));
      }
    }
    return flatList;
  }

  void _rebuildOnControllerUpdate() {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _updateDefaults(List<Field> fieldDefs) {
    widget.controller.addFields(fieldDefs, noNotify: true);
    for (final field in fieldDefs) {
      final currentValue = widget.controller.getFieldValue(field.id);
      if (currentValue == null && field.defaultValue != null) {
        widget.controller
            .updateFieldValue(field.id, field.defaultValue, noNotify: true);
      }
    }
    widget.controller.updateActiveFields(fieldDefs, noNotify: true);
    if (widget.pageName != null && widget.pageName != "default") {
      widget.controller.updatePageFields(widget.pageName!, fieldDefs);
    }
    setState(() {});
  }

  @override
  flutter.Widget build(flutter.BuildContext context) {
    // The root of the builder now uses LayoutBuilder to capture width constraints.
    return flutter.LayoutBuilder(
      builder: (context, constraints) {
        // Build the list of widgets from the form elements.
        List<flutter.Widget> output = _buildElementList(widget.fields);

        // Get the user-provided wrapper or the default.
        final formWrapper = widget.formWrapper ?? simpleWrapper;

        // The wrapper lays out the widgets.
        flutter.Widget formContent = formWrapper(context, output);

        // The FocusTraversalGroup should wrap the actual content.
        return flutter.FocusTraversalGroup(
          policy: flutter.OrderedTraversalPolicy(),
          // The SizedBox ensures the content has a defined width, solving Row issues.
          child: flutter.SizedBox(
            width: constraints.maxWidth,
            child: formContent,
          ),
        );
      },
    );
  }

  List<flutter.Widget> _buildElementList(List<FormElement> elements) {
    List<flutter.Widget> output = [];
    for (final element in elements) {
      if ((element is Row && element.hideField) ||
          (element is Column && element.hideField) ||
          (element is Field && element.hideField)) {
        continue;
      }

      if (element is Field) {
        output.add(_buildFormField(element));
      } else if (element is Row) {
        output.add(_buildRow(element));
      } else if (element is Column) {
        // Standalone columns are wrapped in a full-width row
        output.add(_buildRow(Row(children: [element])));
      }
    }
    return output;
  }

  flutter.Widget _buildRow(Row row) {
    flutter.Widget layout;
    if (row.collapse) {
      layout = flutter.Column(
        mainAxisSize: flutter.MainAxisSize.min,
        crossAxisAlignment: flutter.CrossAxisAlignment.start,
        children: row.children.map((col) => _buildColumn(col)).toList(),
      );
    } else {
      final List<flutter.Widget> spacedChildren = [];
      for (int i = 0; i < row.children.length; i++) {
        final column = row.children[i];
        bool hasAnyWidthFactor = row.children.any((c) => c.widthFactor != null);
        int flex = 1;
        if (hasAnyWidthFactor) {
          flex = (column.widthFactor ?? 1.0).round().clamp(1, 1000);
        }

        spacedChildren.add(
          flutter.Expanded(
            flex: flex,
            child: _buildColumn(column),
          ),
        );

        // Add spacing after each column except the last one
        if (i < row.children.length - 1) {
          spacedChildren.add(flutter.SizedBox(width: row.spacing));
        }
      }

      layout = flutter.Row(
        crossAxisAlignment: flutter.CrossAxisAlignment.start,
        children: spacedChildren,
      );
    }

    if (row.rollUpErrors) {
      List<FormBuilderError> childErrors =
          gatherAllChildErrors(row.children, widget.controller);
      if (childErrors.isNotEmpty) {
        return flutter.Column(
          mainAxisSize: flutter.MainAxisSize.min,
          crossAxisAlignment: flutter.CrossAxisAlignment.start,
          children: [
            layout,
            flutter.Container(color: flutter.Colors.red, width: row.spacing),
            flutter.Padding(
              padding: const flutter.EdgeInsets.symmetric(horizontal: 8.0),
              child: flutter.Column(
                crossAxisAlignment: flutter.CrossAxisAlignment.start,
                children: childErrors
                    .map((err) => flutter.Text(
                          err.reason,
                          style: flutter.TextStyle(
                              color: widget.theme.errorColorScheme?.textColor),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      }
    }
    return layout;
  }

  flutter.Widget _buildColumn(Column column) {
    List<flutter.Widget> childWidgets = _buildElementList(column.children);
    final List<flutter.Widget> spacedChildren = [];

    for (int i = 0; i < childWidgets.length; i++) {
      spacedChildren.add(childWidgets[i]);
      // Add spacing after each child except the last one
      if (i < childWidgets.length - 1) {
        spacedChildren.add(flutter.SizedBox(height: column.spacing));
      }
    }

    flutter.Widget layout = flutter.Column(
      mainAxisSize: flutter.MainAxisSize.min,
      crossAxisAlignment: flutter.CrossAxisAlignment.start,
      children: spacedChildren,
    );

    if (column.columnWrapper != null) {
      List<FormBuilderError>? errors = column.rollUpErrors
          ? gatherAllChildErrors(column.children, widget.controller)
          : null;
      layout = column.columnWrapper!(context, layout, errors);
    }

    if (column.rollUpErrors && column.columnWrapper == null) {
      List<FormBuilderError> childErrors =
          gatherAllChildErrors(column.children, widget.controller);
      if (childErrors.isNotEmpty) {
        return flutter.Column(
          mainAxisSize: flutter.MainAxisSize.min,
          crossAxisAlignment: flutter.CrossAxisAlignment.start,
          children: [
            layout,
            flutter.Container(color: flutter.Colors.red, width: column.spacing),
            flutter.Padding(
              padding: const flutter.EdgeInsets.symmetric(horizontal: 8.0),
              child: flutter.Column(
                crossAxisAlignment: flutter.CrossAxisAlignment.start,
                children: childErrors
                    .map((err) => flutter.Text(
                          err.reason,
                          style: flutter.TextStyle(
                              color: widget.theme.errorColorScheme?.textColor),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      }
    }
    return layout;
  }

  flutter.Widget _buildFormField(Field field) {
    final mergedTheme = (field.theme != null)
        ? widget.theme.copyWith(theme: field.theme)
        : widget.theme;

    final FieldState fieldState = widget.controller.getFieldState(field.id);
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

    flutter.Widget outputWidget = FormFieldRegistry.instance.buildField(
      context,
      widget.controller,
      field,
      fieldState,
      fieldColors,
      (bool focused) {
        widget.controller.setFieldFocus(field.id, focused);
      },
    );

    if (widget.fieldPadding != null && widget.fieldPadding != flutter.EdgeInsets.zero) {
      outputWidget =
          flutter.Padding(padding: widget.fieldPadding!, child: outputWidget);
    }

    return field.fieldLayout(
      context,
      field,
      widget.controller,
      fieldColors,
      field.fieldBackground(
        context,
        field,
        widget.controller,
        fieldColors,
        outputWidget,
      ),
    );
  }
}

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
import 'package:championforms/widgets_external/form_wrappers/simple_wrapper.dart';
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

  final List<ChampionFormElement> fields;
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

    if (!ChampionFormFieldRegistry.instance.isInitialized) {
      ChampionFormFieldRegistry.instance.registerCoreBuilders();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  List<FormFieldDef> _flattenAllFields(List<ChampionFormElement> elements) {
    final List<FormFieldDef> flatList = [];
    for (final element in elements) {
      if (element is FormFieldDef) {
        flatList.add(element);
      } else if (element is ChampionRow) {
        for (final column in element.children) {
          flatList.addAll(_flattenAllFields(column.children));
        }
      } else if (element is ChampionColumn) {
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

  void _updateDefaults(List<FormFieldDef> fieldDefs) {
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
  Widget build(BuildContext context) {
    // The root of the builder now uses LayoutBuilder to capture width constraints.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Build the list of widgets from the form elements.
        List<Widget> output = _buildElementList(widget.fields);

        // Get the user-provided wrapper or the default.
        final formWrapper = widget.formWrapper ?? simpleWrapper;

        // The wrapper lays out the widgets.
        Widget formContent = formWrapper(context, output);

        // The FocusTraversalGroup should wrap the actual content.
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          // The SizedBox ensures the content has a defined width, solving Row issues.
          child: SizedBox(
            width: constraints.maxWidth,
            child: formContent,
          ),
        );
      },
    );
  }

  List<Widget> _buildElementList(List<ChampionFormElement> elements) {
    List<Widget> output = [];
    for (final element in elements) {
      if ((element is ChampionRow && element.hideField) ||
          (element is ChampionColumn && element.hideField) ||
          (element is FormFieldDef && element.hideField)) {
        continue;
      }

      if (element is FormFieldDef) {
        output.add(_buildFormField(element));
      } else if (element is ChampionRow) {
        output.add(_buildRow(element));
      } else if (element is ChampionColumn) {
        // Standalone columns are wrapped in a full-width row
        output.add(_buildRow(ChampionRow(children: [element])));
      }
    }
    return output;
  }

  Widget _buildRow(ChampionRow row) {
    Widget layout;
    if (row.collapse) {
      layout = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: row.children.map((col) => _buildColumn(col)).toList(),
      );
    } else {
      final List<Widget> spacedChildren = [];
      for (int i = 0; i < row.children.length; i++) {
        final column = row.children[i];
        bool hasAnyWidthFactor = row.children.any((c) => c.widthFactor != null);
        int flex = 1;
        if (hasAnyWidthFactor) {
          flex = (column.widthFactor ?? 1.0).round().clamp(1, 1000);
        }

        spacedChildren.add(
          Expanded(
            flex: flex,
            child: _buildColumn(column),
          ),
        );

        // Add spacing after each column except the last one
        if (i < row.children.length - 1) {
          spacedChildren.add(SizedBox(width: row.spacing));
        }
      }

      layout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: spacedChildren,
      );
    }

    if (row.rollUpErrors) {
      List<FormBuilderError> childErrors =
          gatherAllChildErrors(row.children, widget.controller);
      if (childErrors.isNotEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            layout,
            Container(color: Colors.red, width: row.spacing),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: childErrors
                    .map((err) => Text(
                          err.reason,
                          style: TextStyle(
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

  Widget _buildColumn(ChampionColumn column) {
    List<Widget> childWidgets = _buildElementList(column.children);
    final List<Widget> spacedChildren = [];

    for (int i = 0; i < childWidgets.length; i++) {
      spacedChildren.add(childWidgets[i]);
      // Add spacing after each child except the last one
      if (i < childWidgets.length - 1) {
        spacedChildren.add(SizedBox(height: column.spacing));
      }
    }

    Widget layout = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            layout,
            Container(color: Colors.red, width: column.spacing),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: childErrors
                    .map((err) => Text(
                          err.reason,
                          style: TextStyle(
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

  Widget _buildFormField(FormFieldDef field) {
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

    Widget outputWidget = ChampionFormFieldRegistry.instance.buildField(
      context,
      widget.controller,
      field,
      fieldState,
      fieldColors,
      (bool focused) {
        widget.controller.setFieldFocus(field.id, focused);
      },
    );

    if (widget.fieldPadding != null && widget.fieldPadding != EdgeInsets.zero) {
      outputWidget =
          Padding(padding: widget.fieldPadding!, child: outputWidget);
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

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/functions/gather_child_errors.dart';
import 'package:championforms/models/field_types/column.dart';
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/row.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_external/field_view.dart';
import 'package:championforms/widgets_internal/field_render_helpers.dart';
import 'package:championforms/widgets_external/form_wrappers/simple_wrapper.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter/scheduler.dart';
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
    this.enableAutofillGroup = false,
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

  /// Whether to wrap form content in [AutofillGroup].
  final bool enableAutofillGroup;

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
      if (!mounted) return;
      // _updateDefaults is the sole owner of registration: it registers the
      // definitions, seeds defaults, and updates the active + page lists.
      // It notifies once here so listeners see the fields appear.
      _updateDefaults(_flattenAllFields(widget.fields), notify: true);
    });
  }

  @override
  void didUpdateWidget(covariant FormBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuildOnControllerUpdate);
      widget.controller.addListener(_rebuildOnControllerUpdate);
      oldWidget.controller.removeActiveFields(
        _flattenAllFields(oldWidget.fields),
        noNotify: true,
      );
    }

    final oldFields = _flattenAllFields(oldWidget.fields);
    final newFields = _flattenAllFields(widget.fields);
    final oldIds = oldFields.map((f) => f.id).toList();
    final newIds = newFields.map((f) => f.id).toList();

    // This runs on every parent rebuild, and _rebuildOnControllerUpdate calls
    // setState on every controller notification — so an unchanged field list
    // must do no registry work at all, or the two feed each other.
    final sameShape = oldIds.length == newIds.length &&
        Iterable<int>.generate(oldIds.length)
            .every((i) => oldIds[i] == newIds[i]);
    if (sameShape && oldWidget.controller == widget.controller) {
      // Same ids, but a definition may still have changed — a parent that
      // rebuilds with `hideField: true` or a new `conditional`. Hand the
      // controller the new definitions without notifying: a silent update
      // cannot feed back into _rebuildOnControllerUpdate, and passing only
      // definitions that are not the identical object keeps the common
      // rebuild free.
      final changed = [
        for (var i = 0; i < newFields.length; i++)
          if (!identical(oldFields[i], newFields[i])) newFields[i],
      ];
      if (changed.isNotEmpty) {
        widget.controller.addFields(changed, noNotify: true);
      }
      return;
    }

    // Fields this widget no longer renders leave activeFields — that list
    // tracks what is on screen, and dispose() is not the only way to leave it.
    final newIdSet = newIds.toSet();
    final noLongerRendered =
        oldFields.where((f) => !newIdSet.contains(f.id)).toList();
    if (noLongerRendered.isNotEmpty) {
      widget.controller.removeActiveFields(noLongerRendered, noNotify: true);
    }

    // Register what is declared now. This picks up fields newly added to a
    // live list — which were previously never registered at all, so
    // updateFieldValue on one threw — and refreshes changed definitions.
    //
    // Fields that have dropped OUT of the list are deliberately NOT withdrawn.
    // A wizard swaps one Form's fields: list per step (see the multi-page
    // guide), and Flutter reuses the State, so "no longer in the list" is
    // indistinguishable here from "you are on a later page". Withdrawing would
    // silently delete every step the person already filled in. Call
    // FormController.unregisterFields explicitly when a field is genuinely
    // gone, or — better — express the change with `conditional` / `hideField`,
    // which keeps the field declared while excluding it from results and
    // validation.
    _updateDefaults(newFields, notify: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuildOnControllerUpdate);
    // Only activeFields is cleared. Definitions and values deliberately
    // survive: Flutter unmounts widgets for its own reasons — a lazy list
    // culling an off-screen child, a route transition — and an answer must not
    // disappear because of one. See FormController.registeredFields.
    widget.controller.removeActiveFields(
      _flattenAllFields(widget.fields),
      noNotify: true,
    );
    super.dispose();
  }

  /// Flattens all fields including sub-fields from compound fields.
  ///
  /// This method recursively processes form elements and expands compound
  /// fields into their individual sub-fields with proper ID prefixing and
  /// state propagation.
  List<Field> _flattenAllFields(List<FormElement> elements) {
    final List<Field> flatList = [];
    for (final element in elements) {
      if (element is CompoundField) {
        // Add the compound field itself (for validation)
        flatList.add(element);
        // Expand compound field into sub-fields
        flatList.addAll(expandCompoundField(element));
      } else if (element is Field) {
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

  bool _rebuildScheduled = false;

  /// Rebuilds this form when the controller notifies.
  ///
  /// Notifications can arrive while the framework is building (e.g. a
  /// registration from [didUpdateWidget], or a child field's own lifecycle),
  /// where calling [setState] synchronously is not allowed. In that case the
  /// rebuild is deferred to the end of the current frame. Everywhere else
  /// (gesture handlers, async callbacks, post-frame callbacks) it rebuilds
  /// synchronously.
  ///
  /// This deliberately does not use a zero-duration [Future.delayed]: that
  /// leaves a real timer pending after every notification, which fails any
  /// widget test that finishes on a plain `pump()` ("A Timer is still pending
  /// even after the widget tree was disposed").
  void _rebuildOnControllerUpdate() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  /// Registers [fieldDefs] with the controller, seeds their defaults, and
  /// records them as active (and as part of this form's page, if named).
  ///
  /// [notify] fires a single listener notification once registration is
  /// complete. It is on for the initial mount so listeners see the fields
  /// appear, and off for no-op re-registrations so a rebuild cannot feed
  /// itself through [_rebuildOnControllerUpdate].
  void _updateDefaults(List<Field> fieldDefs, {bool notify = false}) {
    widget.controller.addFields(fieldDefs, noNotify: true);
    for (final field in fieldDefs) {
      if (!widget.controller.hasFieldValue(field.id) && field.defaultValue != null) {
        widget.controller
            .updateFieldValue(field.id, field.defaultValue, noNotify: true);
      }
    }
    widget.controller.updateActiveFields(fieldDefs, noNotify: !notify);
    // No special case for "default": Form passes a null pageName unless the
    // caller names a page, so "default" only ever arrives if someone wrote it
    // literally, and it should then behave like any other page name.
    if (widget.pageName != null) {
      widget.controller.updatePageFields(widget.pageName!, fieldDefs);
    }
    if (mounted) setState(() {});
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

        // Wrap in AutofillGroup if enabled
        if (widget.enableAutofillGroup) {
          formContent = flutter.AutofillGroup(child: formContent);
        }

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
      // `isFieldHidden` is the union of the static `hideField` flag and the
      // field's serializable `conditional` rules, evaluated against the
      // controller's live values. The controller notifies on every value
      // change and this widget rebuilds on that notification, so a condition
      // takes effect on the next frame. Crucially it is the *same* question
      // `FormResults` asks, so a field can never be drawn without being
      // validated or validated without being drawn.
      if ((element is Row && element.hideField) ||
          (element is Column && element.hideField) ||
          (element is Field && widget.controller.isFieldHidden(element))) {
        continue;
      }

      if (element is Field) {
        // Plain and compound fields alike: FieldView is the one render path.
        output.add(FieldView(
          controller: widget.controller,
          field: element,
          theme: widget.theme,
          fieldPadding: widget.fieldPadding,
        ));
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
}

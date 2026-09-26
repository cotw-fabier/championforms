import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_defaults_singleton.dart';
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/field_render_helpers.dart';
import 'package:championforms/widgets_internal/field_wiggle_animator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Renders one field — exactly as a `Form` would — anywhere in the widget
/// tree.
///
/// This is the per-field half of `Form`: theme resolution, the field-state
/// palette, the registered builder, `fieldLayout` / `fieldBackground`, field
/// padding and the validation wiggle. `Form` draws every field through it,
/// so a field in a `FieldView` looks and behaves the same as one in a form.
/// Use it to place a field somewhere a `Form` does not fit, such as a block
/// embedded in a rich-text document.
///
/// ## The field must already be registered
///
/// A `Form` registers its fields with the controller for you. A `FieldView`
/// does not: call [FormController.addFields] first, with every field
/// [fieldsToRegister] returns (a compound field needs its sub-fields too).
///
/// ```dart
/// final field = form.TextField(id: 'note', title: 'Note');
/// controller.addFields(form.FieldView.fieldsToRegister(field));
///
/// form.FieldView(controller: controller, field: field);
/// ```
///
/// A `FieldView` draws its field unconditionally. [Field.hideField] and
/// [Field.conditional] are decisions a `Form` makes about which fields to
/// draw; outside a form, check [FormController.isFieldHidden] yourself if
/// you need them.
///
/// It rebuilds on its own when the controller reports a change that matters
/// to this field — its value, focus, state or errors — and ignores changes
/// to other fields.
class FieldView extends StatefulWidget {
  const FieldView({
    super.key,
    required this.controller,
    required this.field,
    this.theme,
    this.fieldPadding,
  });

  /// The controller [field] is registered on.
  final FormController controller;

  /// The field to render. Must be registered on [controller].
  final Field field;

  /// Theme overrides, merged over the default and global theme the same way
  /// `Form.theme` is. The field's own [Field.theme] is applied on top.
  final FormTheme? theme;

  /// Padding around the field widget, inside its layout and background.
  /// `Form` passes its own `fieldPadding` here. Defaults to none.
  final EdgeInsets? fieldPadding;

  /// The fields to pass to [FormController.addFields] before showing [field]
  /// in a `FieldView`: the field itself and, for a [CompoundField], its
  /// prefixed sub-fields (exactly as a `Form` registers them).
  static List<Field> fieldsToRegister(Field field) => [
    field,
    if (field is CompoundField) ...expandCompoundField(field),
  ];

  @override
  State<FieldView> createState() => _FieldViewState();
}

class _FieldViewState extends State<FieldView> {
  /// Sub-fields of a compound [FieldView.field], expanded once per widget
  /// configuration rather than on every build or notification.
  List<Field> _subFields = const [];

  /// What the last build saw of the controller for this field. A
  /// notification that leaves it unchanged was about some other field.
  List<Object?> _signature = const [];

  bool _rebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    _expandSubFields();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FieldView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (!identical(oldWidget.field, widget.field)) {
      _expandSubFields();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _expandSubFields() {
    final field = widget.field;
    _subFields = field is CompoundField ? expandCompoundField(field) : const [];
  }

  /// A cheap snapshot of everything about this field the render depends on.
  ///
  /// Values are compared with `==`: the controller replaces a value rather
  /// than mutating it, so a changed list is a new list.
  List<Object?> _computeSignature() {
    final controller = widget.controller;
    final ids = [widget.field.id, for (final f in _subFields) f.id];
    return [
      for (final id in ids) ...[
        controller.hasFieldDefinition(id),
        controller.getFieldState(id),
        controller.isFieldFocused(id),
        controller.getFieldValueOrNull<Object>(id),
        ...controller.findErrors(id).map((e) => e.reason),
        // Separates one id's error list from the next.
        null,
      ],
    ];
  }

  /// Rebuilds when a notification changed something this field shows.
  ///
  /// Notifications can arrive while the framework is building, where
  /// [setState] is not allowed; the rebuild is then deferred to the end of
  /// the frame. It never uses a zero-duration timer, which would leave a
  /// pending timer behind every notification in widget tests.
  void _onControllerChanged() {
    if (!mounted) return;
    final next = _computeSignature();
    if (listEquals(next, _signature)) return;
    _signature = next;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
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

  @override
  Widget build(BuildContext context) {
    _signature = _computeSignature();

    if (!FormFieldRegistry.instance.isInitialized) {
      FormFieldRegistry.instance.registerCoreBuilders();
    }

    final baseTheme = FormTheme().withDefaults(
      inputTheme: widget.theme,
      textInfo: Theme.of(context).textTheme,
      colorInfo: Theme.of(context).colorScheme,
    );

    final field = widget.field;
    final Widget built = field is CompoundField
        ? _buildCompound(context, field, baseTheme)
        : _buildField(context, field, baseTheme);

    final bool animateErrors =
        field.animateValidationErrors ??
        FormFieldDefaults.instance.animateValidationErrors;

    return animateErrors
        ? FieldWiggleAnimator(
            controller: widget.controller,
            fieldId: field.id,
            child: built,
          )
        : built;
  }

  Widget _buildField(BuildContext context, Field field, FormTheme baseTheme) {
    final controller = widget.controller;
    final mergedTheme = field.theme != null
        ? baseTheme.copyWith(theme: field.theme)
        : baseTheme;

    final FieldState fieldState = controller.getFieldState(field.id);
    final FieldColorScheme fieldColors = colorsForFieldState(
      mergedTheme,
      fieldState,
    );

    Widget outputWidget = FormFieldRegistry.instance.buildField(
      context,
      controller,
      field,
      fieldState,
      fieldColors,
      (bool focused) {
        controller.setFieldFocus(field.id, focused);
      },
    );

    final padding = widget.fieldPadding;
    if (padding != null && padding != EdgeInsets.zero) {
      outputWidget = Padding(padding: padding, child: outputWidget);
    }

    return field.fieldLayout(
      context,
      field,
      controller,
      fieldColors,
      field.fieldBackground(
        context,
        field,
        controller,
        fieldColors,
        outputWidget,
      ),
    );
  }

  /// Builds a compound field: each sub-field through its own [FieldView],
  /// arranged by the compound type's registered layout.
  Widget _buildCompound(
    BuildContext context,
    CompoundField compoundField,
    FormTheme baseTheme,
  ) {
    final controller = widget.controller;
    final registration = FormFieldRegistry.instance
        .getCompoundRegistrationByType(compoundField.runtimeType);

    if (registration == null) {
      debugPrint(
        'Error: No registration found for compound field type '
        '${compoundField.runtimeType}',
      );
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.withValues(alpha: 0.1),
        child: Text(
          'Error: Compound field ${compoundField.runtimeType} not registered',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    // Sub-fields resolve their theme from the same base as the compound; the
    // compound's own theme already reached them through expansion.
    final subFieldWidgets = [
      for (final subField in _subFields)
        FieldView(
          controller: controller,
          field: subField,
          theme: widget.theme,
          fieldPadding: widget.fieldPadding,
        ),
    ];

    List<FormBuilderError>? errors;
    if (registration.rollUpErrors || compoundField.rollUpErrors) {
      // Validators on the compound store their errors under its own id; the
      // sub-fields may carry their own as well.
      errors = [
        ...controller.findErrors(compoundField.id),
        for (final subField in _subFields)
          ...controller.findErrors(subField.id),
      ];
      if (errors.isEmpty) errors = null;
    }

    final mergedTheme = compoundField.theme != null
        ? baseTheme.copyWith(theme: compoundField.theme)
        : baseTheme;
    final fieldState = controller.getFieldState(compoundField.id);

    final fieldBuilderContext = FieldBuilderContext(
      field: compoundField,
      controller: controller,
      theme: mergedTheme,
      state: fieldState,
      colors: colorsForFieldState(mergedTheme, fieldState),
    );

    final layoutBuilder =
        registration.layoutBuilder ?? CompoundField.buildDefaultCompoundLayout;

    return layoutBuilder(fieldBuilderContext, subFieldWidgets, errors);
  }
}

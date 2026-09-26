import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test harnesses for [AutocompleteWrapper].
///
/// Since the 0.4 field-builder refactor, [AutocompleteWrapper] treats the
/// [form.FormController] as its single source of truth: it listens to the
/// controller (not to a TextEditingController) and writes selections back to
/// the controller. The host field widget owns the TextEditingController <->
/// controller sync. These helpers give tests a host that honors that contract.

/// A real single-field form whose TextField carries [autoComplete].
///
/// This is exactly how consumers get the autocomplete overlay, so it exercises
/// the wrapper through the library's own TextField widget (including its
/// TextEditingController/FocusNode wiring).
class AutocompleteFormHarness {
  AutocompleteFormHarness._(this.tester, this.controller, this.fieldId);

  final WidgetTester tester;
  final form.FormController controller;
  final String fieldId;

  static Future<AutocompleteFormHarness> pump(
    WidgetTester tester, {
    required AutoCompleteBuilder autoComplete,
    String fieldId = 'test',
    FormTheme? theme,
    Widget? below,
  }) async {
    final controller = form.FormController();
    addTearDown(controller.dispose);

    final formWidget = form.Form(
      controller: controller,
      theme: theme,
      fields: [form.TextField(id: fieldId, autoComplete: autoComplete)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: below == null
              ? formWidget
              : Column(children: [formWidget, below]),
        ),
      ),
    );
    // Let the Form register its fields.
    await tester.pump();
    return AutocompleteFormHarness._(tester, controller, fieldId);
  }

  Finder get textField => find.byType(TextField);

  TextEditingController get textController =>
      controller.getFieldController<TextEditingController>(fieldId)!;

  FocusNode get focusNode => controller.getFieldController<FocusNode>(fieldId)!;

  String? get value => controller.getFieldValue<String>(fieldId);

  /// Focuses the field and types [text] as a user would.
  Future<void> type(String text) async {
    await tester.tap(textField);
    await tester.pump();
    await tester.enterText(textField, text);
    await tester.pump(); // controller notification -> filter options
    await tester.pump(); // post-frame callback inserts the overlay
  }
}

/// A bare [AutocompleteWrapper] around a Material TextField, wired to the
/// [FieldBuilderContext] the way a custom field is expected to be (typed text
/// goes to the controller via `ctx.setValue`).
///
/// Use this for wrapper-only API that the library TextField does not expose,
/// such as [AutocompleteWrapper.onOptionSelected].
Widget wiredAutocompleteWrapper({
  required FieldBuilderContext ctx,
  required AutoCompleteBuilder autoComplete,
  void Function(CompleteOption)? onOptionSelected,
}) {
  return AutocompleteWrapper(
    autoComplete: autoComplete,
    context: ctx,
    onOptionSelected: onOptionSelected,
    child: TextField(
      controller: ctx.getTextController(),
      focusNode: ctx.getFocusNode(),
      onChanged: (value) => ctx.setValue(value),
    ),
  );
}

import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test implementation of StatefulFieldWidget for testing lifecycle hooks.
class TestFieldWidget extends StatefulWidget {
  final FieldBuilderContext context;
  final void Function(dynamic oldValue, dynamic newValue)? onValueChangedCallback;
  final void Function(bool isFocused)? onFocusChangedCallback;
  final void Function()? onValidateCallback;
  final Widget Function(BuildContext, FormTheme, FieldBuilderContext)? buildOverride;

  const TestFieldWidget({
    super.key,
    required this.context,
    this.onValueChangedCallback,
    this.onFocusChangedCallback,
    this.onValidateCallback,
    this.buildOverride,
  });

  @override
  State<TestFieldWidget> createState() => _TestFieldWidgetState();
}

class _TestFieldWidgetState extends State<TestFieldWidget> {
  dynamic _lastValue;
  late bool _lastFocusState;

  @override
  void initState() {
    super.initState();
    // Initialize tracked state - get current value from controller
    // This properly captures the field's defaultValue if no explicit value is set
    _lastValue = _getCurrentValue();
    _lastFocusState = widget.context.hasFocus;
    widget.context.controller.addListener(_onControllerUpdate);
  }

  /// Gets the current value, falling back to default value if no explicit value is set.
  dynamic _getCurrentValue() {
    final value = widget.context.getValue();
    if (value == null && !widget.context.controller.hasFieldValue(widget.context.field.id)) {
      return widget.context.controller.getFieldDefaultValue(widget.context.field.id);
    }
    return value;
  }

  void _onControllerUpdate() {
    final newValue = _getCurrentValue();
    final newFocus = widget.context.hasFocus;

    if (newValue != _lastValue) {
      if (widget.onValueChangedCallback != null) {
        widget.onValueChangedCallback!(_lastValue, newValue);
      }
      _lastValue = newValue;
    }

    if (newFocus != _lastFocusState) {
      if (widget.onFocusChangedCallback != null) {
        widget.onFocusChangedCallback!(newFocus);
      }
      _lastFocusState = newFocus;

      // Trigger validation on focus loss
      if (!newFocus) {
        if (widget.onValidateCallback != null) {
          widget.onValidateCallback!();
        } else {
          // Default: trigger validation if validateLive is true
          if (widget.context.field.validateLive) {
            widget.context.controller.validateField(widget.context.field.id);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.buildOverride != null) {
      return widget.buildOverride!(context, widget.context.theme, widget.context);
    }
    return Container(
      child: Text('Test Field: ${_getCurrentValue()?.toString() ?? "null"}'),
    );
  }

  @override
  void dispose() {
    widget.context.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

void main() {
  group('StatefulFieldWidget Lifecycle', () {
    testWidgets('onValueChanged hook is invoked when field value changes', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        defaultValue: 'initial',
      );

      controller.addFields([field]);

      final context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      dynamic capturedOldValue;
      dynamic capturedNewValue;
      int callCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFieldWidget(
              context: context,
              onValueChangedCallback: (oldValue, newValue) {
                capturedOldValue = oldValue;
                capturedNewValue = newValue;
                callCount++;
              },
            ),
          ),
        ),
      );

      // Initial pump completes
      await tester.pump();

      // Change value
      controller.updateFieldValue('test_field', 'updated');
      await tester.pump();

      // Assert
      expect(callCount, equals(1));
      expect(capturedOldValue, equals('initial'));
      expect(capturedNewValue, equals('updated'));

      // Cleanup
      controller.dispose();
    });

    testWidgets('onFocusChanged hook is invoked when focus state changes', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
      );

      controller.addFields([field]);

      final context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      bool? capturedFocusState;
      int callCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFieldWidget(
              context: context,
              onFocusChangedCallback: (isFocused) {
                capturedFocusState = isFocused;
                callCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Change focus to true
      controller.setFieldFocus('test_field', true);
      await tester.pump();

      // Assert focus gained
      expect(callCount, equals(1));
      expect(capturedFocusState, isTrue);

      // Change focus to false
      controller.setFieldFocus('test_field', false);
      await tester.pump();

      // Assert focus lost
      expect(callCount, equals(2));
      expect(capturedFocusState, isFalse);

      // Cleanup
      controller.dispose();
    });

    testWidgets('automatic validation triggers on focus loss when validateLive is true', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        validateLive: true,
        validators: [
          form.Validator(
            validator: (value) {
              // Validator receives the field value directly
              if (value == null) return false;
              if (value is String) return value.isNotEmpty;
              return false;
            },
            reason: 'Field is required',
          ),
        ],
      );

      controller.addFields([field]);

      final context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFieldWidget(context: context),
          ),
        ),
      );

      await tester.pump();

      // Set field to empty (invalid)
      controller.updateFieldValue('test_field', '');
      await tester.pump();

      // Gain focus then lose it
      controller.setFieldFocus('test_field', true);
      await tester.pump();

      controller.setFieldFocus('test_field', false);
      await tester.pump();

      // Assert: validation should have been triggered
      final errors = controller.formErrors.where((e) => e.fieldId == 'test_field').toList();
      expect(errors.length, equals(1));
      expect(errors.first.reason, equals('Field is required'));

      // Cleanup
      controller.dispose();
    });

    testWidgets('automatic validation does NOT trigger when validateLive is false', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        validateLive: false, // Explicitly false
        validators: [
          form.Validator(
            validator: (value) {
              // Validator receives the field value directly
              if (value == null) return false;
              if (value is String) return value.isNotEmpty;
              return false;
            },
            reason: 'Field is required',
          ),
        ],
      );

      controller.addFields([field]);

      final context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFieldWidget(context: context),
          ),
        ),
      );

      await tester.pump();

      // Set field to empty (invalid)
      controller.updateFieldValue('test_field', '');
      await tester.pump();

      // Gain focus then lose it
      controller.setFieldFocus('test_field', true);
      await tester.pump();

      controller.setFieldFocus('test_field', false);
      await tester.pump();

      // Assert: validation should NOT have been triggered
      final errors = controller.formErrors.where((e) => e.fieldId == 'test_field').toList();
      expect(errors.length, equals(0));

      // Cleanup
      controller.dispose();
    });

    testWidgets('buildWithTheme is called with correct parameters', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        defaultValue: 'test_value',
      );

      controller.addFields([field]);

      final context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      BuildContext? capturedBuildContext;
      FormTheme? capturedTheme;
      FieldBuilderContext? capturedContext;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFieldWidget(
              context: context,
              buildOverride: (ctx, theme, fieldContext) {
                capturedBuildContext = ctx;
                capturedTheme = theme;
                capturedContext = fieldContext;
                return Container(child: const Text('Custom Build'));
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(capturedBuildContext, isNotNull);
      expect(capturedTheme, equals(context.theme));
      expect(capturedContext, equals(context));
      expect(find.text('Custom Build'), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('controller listener is removed on dispose', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
      );

      controller.addFields([field]);

      final context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      int callCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFieldWidget(
              context: context,
              onValueChangedCallback: (_, __) {
                callCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Change value - should trigger callback
      controller.updateFieldValue('test_field', 'value1');
      await tester.pump();
      expect(callCount, equals(1));

      // Dispose the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pump();

      // Change value again - should NOT trigger callback
      controller.updateFieldValue('test_field', 'value2');
      await tester.pump();
      expect(callCount, equals(1)); // Still 1, not 2

      // Cleanup
      controller.dispose();
    });
  });
}

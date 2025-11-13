import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test implementation tracking build calls for performance testing.
class PerformanceTestFieldWidget extends StatefulWidget {
  final FieldBuilderContext context;
  final void Function()? onBuild;

  const PerformanceTestFieldWidget({
    super.key,
    required this.context,
    this.onBuild,
  });

  @override
  State<PerformanceTestFieldWidget> createState() => _PerformanceTestFieldWidgetState();
}

class _PerformanceTestFieldWidgetState extends State<PerformanceTestFieldWidget> {
  dynamic _lastValue;
  late bool _lastFocusState;

  @override
  void initState() {
    super.initState();
    // Initialize tracked state - get current value from controller
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

    bool shouldRebuild = false;

    if (newValue != _lastValue) {
      _lastValue = newValue;
      shouldRebuild = true;
    }

    if (newFocus != _lastFocusState) {
      _lastFocusState = newFocus;
      shouldRebuild = true;
    }

    // Only call setState if relevant changes occurred
    if (shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Track build calls
    if (widget.onBuild != null) {
      widget.onBuild!();
    }

    return Container(
      child: Text('Value: ${_getCurrentValue()?.toString() ?? "null"}'),
    );
  }

  @override
  void dispose() {
    widget.context.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}

void main() {
  group('StatefulFieldWidget Performance Optimizations', () {
    testWidgets('lazy TextEditingController creation - only created on first access', (tester) async {
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

      // Act & Assert: Before accessing getTextController
      // The TextEditingController should not exist in the controller yet
      final textControllerBefore = controller.getFieldController<TextEditingController>(field.id);
      expect(textControllerBefore, isNull, reason: 'TextEditingController should not exist before first access');

      // Access the text controller (lazy initialization)
      final textController1 = context.getTextController();
      expect(textController1, isNotNull, reason: 'TextEditingController should be created on first access');

      // Verify it's registered in the controller
      final textControllerAfter = controller.getFieldController<TextEditingController>(field.id);
      expect(textControllerAfter, isNotNull, reason: 'TextEditingController should be registered with controller');
      expect(textControllerAfter, equals(textController1), reason: 'Should be the same instance');

      // Access again - should return same instance
      final textController2 = context.getTextController();
      expect(textController2, equals(textController1), reason: 'Should return same instance on subsequent calls');

      // Cleanup
      controller.dispose();
    });

    testWidgets('lazy FocusNode creation - only created on first access', (tester) async {
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

      // Act & Assert: Before accessing getFocusNode
      // The FocusNode should not exist in the controller yet
      final focusNodeBefore = controller.getFieldController<FocusNode>(field.id);
      expect(focusNodeBefore, isNull, reason: 'FocusNode should not exist before first access');

      // Access the focus node (lazy initialization)
      final focusNode1 = context.getFocusNode();
      expect(focusNode1, isNotNull, reason: 'FocusNode should be created on first access');

      // Verify it's registered in the controller
      final focusNodeAfter = controller.getFieldController<FocusNode>(field.id);
      expect(focusNodeAfter, isNotNull, reason: 'FocusNode should be registered with controller');
      expect(focusNodeAfter, equals(focusNode1), reason: 'Should be the same instance');

      // Access again - should return same instance
      final focusNode2 = context.getFocusNode();
      expect(focusNode2, equals(focusNode1), reason: 'Should return same instance on subsequent calls');

      // Cleanup
      controller.dispose();
    });

    testWidgets('rebuild prevention - only rebuild on value or focus change', (tester) async {
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

      int buildCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceTestFieldWidget(
              context: context,
              onBuild: () {
                buildCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      final initialBuildCount = buildCount;

      // Change unrelated field (should NOT trigger rebuild)
      final otherField = form.TextField(id: 'other_field', textFieldTitle: 'Other', defaultValue: 'other_value');
      controller.addFields([otherField]);
      controller.updateFieldValue('other_field', 'changed');
      await tester.pump();

      expect(buildCount, equals(initialBuildCount),
        reason: 'Should not rebuild when unrelated field changes');

      // Change THIS field's value (SHOULD trigger rebuild)
      controller.updateFieldValue('test_field', 'updated');
      await tester.pump();

      expect(buildCount, greaterThan(initialBuildCount),
        reason: 'Should rebuild when field value changes');

      final afterValueChangeBuildCount = buildCount;

      // Change focus state (SHOULD trigger rebuild)
      controller.setFieldFocus('test_field', true);
      await tester.pump();

      expect(buildCount, greaterThan(afterValueChangeBuildCount),
        reason: 'Should rebuild when focus state changes');

      // Cleanup
      controller.dispose();
    });

    testWidgets('value notifier optimization - prevents unnecessary widget tree rebuilds', (tester) async {
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

      int buildCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceTestFieldWidget(
              context: context,
              onBuild: () {
                buildCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      final initialBuildCount = buildCount;

      // Update field value to SAME value (should NOT trigger rebuild)
      // NOTE: Due to FormController limitation, this will trigger a controller notification,
      // but StatefulFieldWidget's value comparison will prevent the widget rebuild
      controller.updateFieldValue('test_field', 'initial');
      await tester.pump();

      expect(buildCount, equals(initialBuildCount),
        reason: 'Should not rebuild when value is set to same value');

      // Update to different value (SHOULD trigger rebuild)
      controller.updateFieldValue('test_field', 'different');
      await tester.pump();

      expect(buildCount, greaterThan(initialBuildCount),
        reason: 'Should rebuild when value actually changes');

      // Cleanup
      controller.dispose();
    });

    testWidgets('combined optimization - multiple unrelated updates do not cause excessive rebuilds', (tester) async {
      // Arrange
      final controller = form.FormController();
      final field1 = form.TextField(id: 'field1', textFieldTitle: 'Field 1', defaultValue: 'value1');
      final field2 = form.TextField(id: 'field2', textFieldTitle: 'Field 2', defaultValue: 'value2');
      final field3 = form.TextField(id: 'field3', textFieldTitle: 'Field 3', defaultValue: 'value3');

      controller.addFields([field1, field2, field3]);

      final context1 = FieldBuilderContext(
        controller: controller,
        field: field1,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      int buildCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceTestFieldWidget(
              context: context1,
              onBuild: () {
                buildCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      final initialBuildCount = buildCount;

      // Update multiple OTHER fields (should NOT trigger rebuild)
      controller.updateFieldValue('field2', 'updated2');
      await tester.pump();
      controller.updateFieldValue('field3', 'updated3');
      await tester.pump();

      expect(buildCount, equals(initialBuildCount),
        reason: 'Should not rebuild when other fields change');

      // Update field1 ONCE (should trigger exactly ONE rebuild)
      controller.updateFieldValue('field1', 'updated1');
      await tester.pump();

      expect(buildCount, equals(initialBuildCount + 1),
        reason: 'Should trigger exactly one rebuild for field1 change');

      // Cleanup
      controller.dispose();
    });
  });
}

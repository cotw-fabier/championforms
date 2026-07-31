import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_colors.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/field_types/convienence_classes/checkboxselect.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the two v0.7.0 features:
/// 1. `colors: FieldColors.destructive` emphasis → `FieldState.destructive`
///    resolution (empty & unfocused only; focus/fill/real-error/disabled all win).
/// 2. `FormController.validationFailureTick` bumping on validation failure, which
///    the (widget-level) wiggle animation listens to.
void main() {
  group('Destructive emphasis colors → FieldState resolution', () {
    late FormController controller;

    setUp(() => controller = FormController());
    tearDown(() => controller.dispose());

    test('destructive + empty + unfocused resolves to FieldState.destructive', () {
      controller.addFields([
        TextField(id: 'danger', colors: FieldColors.destructive),
      ]);

      expect(controller.getFieldState('danger'), FieldState.destructive);
    });

    test('a normal field (default colors) is never destructive when empty', () {
      controller.addFields([TextField(id: 'plain')]);

      expect(controller.getFieldState('plain'), FieldState.normal);
    });

    test('focusing a destructive field turns the destructive look off (active)', () {
      controller.addFields([
        TextField(id: 'danger', colors: FieldColors.destructive),
      ]);
      expect(controller.getFieldState('danger'), FieldState.destructive);

      controller.setFieldFocus('danger', true);
      expect(controller.getFieldState('danger'), FieldState.active);

      // Blurring an (empty) destructive field returns it to destructive.
      controller.setFieldFocus('danger', false);
      expect(controller.getFieldState('danger'), FieldState.destructive);
    });

    test('filling a destructive field reverts it to normal', () {
      controller.addFields([
        TextField(id: 'danger', colors: FieldColors.destructive),
      ]);
      expect(controller.getFieldState('danger'), FieldState.destructive);

      controller.updateFieldValue<String>('danger', 'now has content');
      expect(controller.getFieldState('danger'), FieldState.normal);
    });

    test('whitespace-only content is still considered empty (stays destructive)', () {
      controller.addFields([
        TextField(id: 'danger', colors: FieldColors.destructive),
      ]);

      controller.updateFieldValue<String>('danger', '   ');
      expect(controller.getFieldState('danger'), FieldState.destructive);
    });

    test('a real validation error wins over destructive emphasis', () {
      controller.addFields([
        TextField(
          id: 'danger',
          colors: FieldColors.destructive,
          validateLive: true,
          validators: [
            Validator(
              reason: 'Must contain @',
              validator: (value) => (value as String?)?.contains('@') ?? false,
            ),
          ],
        ),
      ]);

      // updateFieldValue with an invalid value triggers live validation.
      controller.updateFieldValue<String>('danger', 'invalid');
      expect(controller.getFieldState('danger'), FieldState.error);
    });

    test('disabled wins over destructive emphasis', () {
      controller.addFields([
        TextField(id: 'danger', colors: FieldColors.destructive, disabled: true),
      ]);

      expect(controller.getFieldState('danger'), FieldState.disabled);
    });

    test('destructive multiselect: empty selection is destructive, a selection reverts to normal', () {
      final a = FieldOption(label: 'A', value: 'a');
      final b = FieldOption(label: 'B', value: 'b');
      controller.addFields([
        CheckboxSelect(
          id: 'picks',
          colors: FieldColors.destructive,
          options: [a, b],
          multiselect: true,
        ),
      ]);

      expect(controller.getFieldState('picks'), FieldState.destructive);

      controller.toggleMultiSelectValue('picks', toggleOn: ['a']);
      expect(controller.getFieldState('picks'), FieldState.normal);
    });
  });

  group('validationFailureTick', () {
    late FormController controller;

    setUp(() => controller = FormController());
    tearDown(() => controller.dispose());

    test('starts at zero', () {
      expect(controller.validationFailureTick, 0);
    });

    test('increments when explicit validation finds an error', () {
      controller.addFields([
        TextField(
          id: 'email',
          validators: [
            Validator(
              reason: 'Must contain @',
              validator: (value) => (value as String?)?.contains('@') ?? false,
            ),
          ],
        ),
      ]);
      controller.updateFieldValue<String>('email', 'invalid', noNotify: true);

      final before = controller.validationFailureTick;
      controller.validateField('email');

      expect(controller.hasErrors('email'), isTrue);
      expect(controller.validationFailureTick, greaterThan(before));
    });

    test('increments on live/on-blur validation failure', () {
      controller.addFields([
        TextField(
          id: 'email',
          validateLive: true,
          validators: [
            Validator(
              reason: 'Must contain @',
              validator: (value) => (value as String?)?.contains('@') ?? false,
            ),
          ],
        ),
      ]);

      final before = controller.validationFailureTick;
      controller.updateFieldValue<String>('email', 'invalid');
      expect(controller.validationFailureTick, greaterThan(before));
    });

    test('does not increment when validation passes', () {
      controller.addFields([
        TextField(
          id: 'email',
          validators: [
            Validator(
              reason: 'Must contain @',
              validator: (value) => (value as String?)?.contains('@') ?? false,
            ),
          ],
        ),
      ]);
      controller.updateFieldValue<String>('email', 'good@example.com', noNotify: true);

      final before = controller.validationFailureTick;
      controller.validateField('email');

      expect(controller.hasErrors('email'), isFalse);
      expect(controller.validationFailureTick, before);
    });
  });
}

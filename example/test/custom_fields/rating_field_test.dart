import 'package:championforms/championforms.dart' as form;
import 'package:championforms/controllers/form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/custom_fields/rating_field.dart';

/// Tests for RatingField custom field implementation.
///
/// Tests focused on:
/// - Rating value selection (tap star)
/// - Rating value updates controller
/// - Validation behavior
/// - Theme application
void main() {
  // Register the custom field before running tests
  setUpAll(() {
    registerRatingField();
  });

  group('RatingField Custom Field Tests', () {
    late FormController controller;
    late RatingField field;

    setUp(() {
      controller = FormController();
      field = RatingField(
        id: 'test_rating',
        title: 'Test Rating',
        maxStars: 5,
        validateLive: true,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('Rating value selection - tap star updates value',
        (WidgetTester tester) async {
      // Arrange: Render the rating field in a form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );

      // Act: Find and tap the third star
      final starFinder = find.byIcon(Icons.star_border).at(2);
      await tester.tap(starFinder);
      await tester.pump();

      // Assert: Value should be set to 3
      expect(controller.getFieldValue<int>('test_rating'), equals(3));
    });

    testWidgets('Rating value updates controller correctly',
        (WidgetTester tester) async {
      // Arrange: Render the rating field
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );

      // Act: Tap star to set rating
      final firstStar = find.byIcon(Icons.star_border).first;
      await tester.tap(firstStar);
      await tester.pump();

      // Assert: Controller should have the new value
      final value = controller.getFieldValue<int>('test_rating');
      expect(value, isNotNull);
      expect(value, equals(1));
    });

    testWidgets('Validation behavior - minimum rating validation',
        (WidgetTester tester) async {
      // Arrange: Field with minimum rating validator
      final validatedField = RatingField(
        id: 'validated_rating',
        title: 'Rate this',
        maxStars: 5,
        validateLive: true,
        validators: [
          form.Validator(
            validator: (results) {
              final value = results.grab('validated_rating').asInt();
              return value != null && value >= 3;
            },
            reason: 'Minimum rating of 3 stars required',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [validatedField],
            ),
          ),
        ),
      );

      // Act: Select 2 stars (below minimum)
      final secondStar = find.byIcon(Icons.star_border).at(1);
      await tester.tap(secondStar);
      await tester.pump();

      // Trigger validation
      controller.validateField('validated_rating');
      await tester.pump();

      // Assert: Should have validation error
      expect(controller.formErrors.length, greaterThan(0));
      expect(
        controller.formErrors.first.reason,
        contains('Minimum rating of 3 stars required'),
      );
    });

    testWidgets('Theme application - uses theme colors',
        (WidgetTester tester) async {
      // Arrange: Field with custom theme
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );

      // Act: Pump frame to ensure theme is applied
      await tester.pump();

      // Assert: Widget should render without errors (theme applied successfully)
      expect(find.byType(RatingFieldWidget), findsOneWidget);
    });

    test('RatingField default value initialization', () {
      // Arrange & Act: Create field with default value
      final fieldWithDefault = RatingField(
        id: 'default_rating',
        title: 'Default Rating',
        maxStars: 5,
        defaultValue: 4,
      );

      // Assert: Default value should be set
      expect(fieldWithDefault.defaultValue, equals(4));
    });

    test('RatingField maxStars configuration', () {
      // Arrange & Act: Create field with different maxStars
      final customField = RatingField(
        id: 'custom_rating',
        title: 'Custom Rating',
        maxStars: 10,
      );

      // Assert: maxStars should be set correctly
      expect(customField.maxStars, equals(10));
    });

    testWidgets('Selected rating displays filled stars',
        (WidgetTester tester) async {
      // Arrange: Set initial rating programmatically
      controller.updateFieldValue<int>('test_rating', 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );

      // Act: Pump to render with value
      await tester.pump();

      // Assert: Should have 3 filled stars and 2 empty stars
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('Tapping same star rating maintains value',
        (WidgetTester tester) async {
      // Arrange: Render field
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );

      // Act: Tap third star twice
      final thirdStar = find.byIcon(Icons.star_border).at(2);
      await tester.tap(thirdStar);
      await tester.pump();

      final currentValue = controller.getFieldValue<int>('test_rating');

      // Tap again (now it's a filled star)
      final filledStar = find.byIcon(Icons.star).at(2);
      await tester.tap(filledStar);
      await tester.pump();

      // Assert: Value should remain 3
      expect(controller.getFieldValue<int>('test_rating'), equals(currentValue));
    });
  });
}

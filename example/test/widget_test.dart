// Smoke tests for the ChampionForms example app.
//
// This replaces the stock `flutter create` counter test, which asserted on a
// counter/'+' button the example app has never had.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/custom_fields/rating_field.dart';
import 'package:example/main.dart';

void main() {
  // main() registers the custom RatingField before runApp; tests pump MyApp
  // directly, so they must do the same or the form cannot build that field.
  setUpAll(registerRatingField);

  testWidgets('Example app renders the demo form with its default values',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('ChampionForms v0.0.5 Demo'), findsOneWidget);

    // Fields from the demo form are on screen.
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Rate Your Experience'), findsOneWidget);

    // The Email field is seeded from its defaultValue.
    expect(find.text('fabbage@tehfab1.com'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('"Set Values" updates fields programmatically',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final setValues = find.widgetWithText(ElevatedButton, 'Set Values');
    await tester.ensureVisible(setValues);
    await tester.pumpAndSettle();
    await tester.tap(setValues);
    await tester.pumpAndSettle();

    // The controller update is reflected in the Email TextField.
    expect(find.text('programmatic@example.com'), findsOneWidget);
    expect(find.text('fabbage@tehfab1.com'), findsNothing);
  });
}

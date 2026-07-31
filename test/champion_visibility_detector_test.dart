import 'package:championforms/widgets_internal/visibility/champion_visibility_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the hand-rolled [ChampionVisibilityDetector] reports a rising
/// visible fraction as its child scrolls into the viewport — the reusable
/// utility that gates the validation wiggle.
void main() {
  testWidgets('reports ~0 when off screen and rises as it scrolls into view',
      (tester) async {
    double reported = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Push the detector well below the ~600px viewport.
                const SizedBox(height: 1200),
                ChampionVisibilityDetector(
                  onVisibilityChanged: (f) => reported = f,
                  child: const SizedBox(height: 100, width: 100),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Off screen: essentially not visible.
    expect(reported, lessThan(0.1));

    // Scroll the detector fully into view.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1150));
    await tester.pumpAndSettle();

    expect(reported, greaterThan(0.9));
  });
}

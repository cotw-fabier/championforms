import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart' show FormFieldDefaults;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The block wiggle on an anchored issue follows the core field wiggle:
/// `animateValidationErrors` (field, then `FormFieldDefaults`), reduce
/// motion, and visibility gating.
void main() {
  tearDown(() => FormFieldDefaults.instance.animateValidationErrors = true);

  DocumentField docField({bool? animate, List<DocNode>? nodes}) =>
      DocumentField(
        id: 'doc',
        animateValidationErrors: animate,
        ruleSet: const RuleSet(
          constraints: [ForbiddenPatternRule(pattern: 'TODO')],
        ),
        initialDocument: DocSnapshot(
          nodes ??
              [
                const ParagraphNode(id: 'ok', text: DocText('Fine')),
                const ParagraphNode(id: 'bad', text: DocText('TODO later')),
              ],
        ),
      );

  /// The horizontal offset of the block's own wiggle transform (the nearest
  /// `Transform` above its issue marker).
  double blockDx(WidgetTester tester, String nodeId) {
    final transform = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(ValueKey('document-issue-$nodeId')),
            matching: find.byType(Transform),
          )
          .first,
    );
    return transform.transform.getTranslation().x;
  }

  /// Submits, then samples the block's offset over the animation.
  Future<List<double>> submitAndSample(
    WidgetTester tester,
    DocHarness h, {
    String nodeId = 'bad',
  }) async {
    final results = form.FormResults.getResults(controller: h.controller);
    expect(results.errorState, isTrue);
    await tester.pump();
    final samples = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      samples.add(blockDx(tester, nodeId));
    }
    await tester.pumpAndSettle();
    return samples;
  }

  testWidgets('submit with an anchored issue wiggles the offending block', (
    tester,
  ) async {
    final h = await pumpDocumentForm(tester, fields: [docField()]);
    final samples = await submitAndSample(tester, h);
    expect(samples.any((dx) => dx.abs() > 0.5), isTrue, reason: '$samples');
    // It settles back to rest.
    expect(blockDx(tester, 'bad'), 0);
  });

  testWidgets('reduce motion: no wiggle', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await pumpDocumentForm(tester, fields: [docField()]);
    final samples = await submitAndSample(tester, h);
    expect(samples, everyElement(0));
  });

  testWidgets('animateValidationErrors: false on the field: no wiggle', (
    tester,
  ) async {
    final h = await pumpDocumentForm(
      tester,
      fields: [docField(animate: false)],
    );
    final samples = await submitAndSample(tester, h);
    expect(samples, everyElement(0));
  });

  testWidgets('FormFieldDefaults animateValidationErrors = false: no wiggle', (
    tester,
  ) async {
    FormFieldDefaults.instance.animateValidationErrors = false;
    final h = await pumpDocumentForm(tester, fields: [docField()]);
    final samples = await submitAndSample(tester, h);
    expect(samples, everyElement(0));
  });

  testWidgets('the field-level true overrides a false app-wide default', (
    tester,
  ) async {
    FormFieldDefaults.instance.animateValidationErrors = false;
    final h = await pumpDocumentForm(tester, fields: [docField(animate: true)]);
    final samples = await submitAndSample(tester, h);
    expect(samples.any((dx) => dx.abs() > 0.5), isTrue, reason: '$samples');
  });

  testWidgets('an off-screen block waits until it scrolls into view', (
    tester,
  ) async {
    final nodes = [
      for (var i = 0; i < 40; i++)
        ParagraphNode(id: 'p$i', text: DocText('Paragraph $i')),
      const ParagraphNode(id: 'bad', text: DocText('TODO later')),
    ];
    final h = await pumpDocumentForm(
      tester,
      fields: [docField(nodes: nodes)],
      size: const Size(800, 400),
    );
    expect(
      tester.getTopLeft(find.text('TODO later', findRichText: true)).dy,
      greaterThan(400),
    );

    final hidden = await submitAndSample(tester, h);
    expect(hidden, everyElement(0), reason: 'played while off screen');

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('document-issue-bad')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Within the settle delay: still at rest.
    await tester.pump(const Duration(milliseconds: 100));
    expect(blockDx(tester, 'bad'), 0);
    final samples = <double>[];
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      samples.add(blockDx(tester, 'bad'));
    }
    expect(samples.any((dx) => dx.abs() > 0.5), isTrue, reason: '$samples');
    await tester.pumpAndSettle();
  });
}

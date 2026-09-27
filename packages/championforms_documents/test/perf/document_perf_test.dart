// Editor performance benchmark. Tagged `perf` and excluded from the default
// run (skipped through the tag in dart_test.yaml); run it with:
//
//   flutter test --tags perf --run-skipped test/perf/
//
// These are debug (JIT) numbers from the widget-test binding; for profile
// mode in a real macOS window, run tool/profile_documents.sh. The bounds
// are deliberately generous so the test only catches order-of-magnitude
// regressions, not machine noise.
@Tags(['perf'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'document_perf_bench.dart';

void main() {
  testWidgets(
    'a 600-node document with 20 embedded fields stays interactive',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final report = await runDocumentBenchmark(tester, mode: 'debug, JIT');
      debugPrint(report.table());

      expect(report['first build'].maxMs, lessThan(20000));
      expect(report['keystroke'].medianMs, lessThan(500));
      expect(report['keystroke'].p95Ms, lessThan(1500));
      expect(report['snapshot push'].medianMs, lessThan(500));
      expect(report['toSnapshot'].medianMs, lessThan(250));
      expect(report['evaluate'].medianMs, lessThan(250));
      expect(report['getResults'].medianMs, lessThan(1000));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

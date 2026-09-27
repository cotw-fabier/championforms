// The document editor benchmark, shared by the `perf`-tagged widget test
// (test/perf/document_perf_test.dart, debug JIT) and the profile-mode
// integration test that tool/profile_documents.sh generates. It depends
// only on package imports so it can be copied into another app as is.
import 'dart:math' as math;

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;
import 'package:super_editor/super_editor_test.dart';

/// Nodes in the benchmark document.
const benchNodeCount = 600;

/// Embedded field blocks among them (one every 30 nodes).
const benchEmbeddedCount = 20;

/// Keystrokes timed one by one.
const benchKeystrokes = 50;

/// A 600-node document: a heading every 30 nodes, one embedded field block
/// per section, and paragraphs, list items, tasks, quotes and dividers in
/// between. Text carries mentions, dates, amounts and marks so every rule
/// in [benchRuleSet] has something to find.
DocSnapshot buildBenchDocument() {
  final nodes = <DocNode>[];
  for (var i = 0; i < benchNodeCount; i++) {
    final id = 'n${i.toString().padLeft(3, '0')}';
    final section = i ~/ 30;
    switch (i % 30) {
      case 0:
        nodes.add(
          HeadingNode(
            id: id,
            level: section % 3 == 0 ? 1 : 2,
            text: DocText(switch (section) {
              1 => 'Scope',
              2 => 'Payment terms',
              _ => 'Section $section',
            }),
          ),
        );
      case 15:
        nodes.add(
          EmbeddedFieldNode(
            id: id,
            fieldJson: section.isEven
                ? {'type': 'textField', 'title': 'Field $section'}
                : {
                    'type': 'checkboxSelect',
                    'title': 'Options $section',
                    'multiselect': true,
                    'options': [
                      {'value': 'a', 'label': 'A'},
                      {'value': 'b', 'label': 'B'},
                      {'value': 'c', 'label': 'C'},
                    ],
                  },
          ),
        );
      case 29:
        nodes.add(DividerNode(id: id));
      default:
        final text =
            'Item $i for @person${i % 17} due 2026-${(i % 12 + 1).toString().padLeft(2, '0')}-15, '
            'amount \$${1000 + i * 7}.50. Lorem ipsum dolor sit amet, '
            'consectetur adipiscing elit, sed do eiusmod tempor.';
        final marks = [
          const DocMark(type: DocMarkType.bold, start: 0, end: 4),
          DocMark(type: DocMarkType.italic, start: 10, end: 20),
        ];
        nodes.add(switch (i % 7) {
          0 || 1 || 2 => ParagraphNode(id: id, text: DocText(text, marks)),
          3 => ListItemNode(id: id, text: DocText(text)),
          4 => ListItemNode(id: id, ordered: true, text: DocText(text)),
          5 => TaskNode(id: id, checked: i.isEven, text: DocText(text)),
          _ => QuoteNode(id: id, text: DocText(text)),
        });
    }
  }
  return DocSnapshot(nodes);
}

/// A contract-style rule set: the default transforms, six extracts and
/// four constraints.
const benchRuleSet = RuleSet(
  extracts: [
    MentionsExtract(key: 'people', required: true),
    DatesExtract(key: 'dates', all: true),
    SectionTextExtract(key: 'scope', title: 'Scope', required: true),
    RegexExtract(key: 'amounts', pattern: r'\$\d[\d,]*(?:\.\d{2})?', all: true),
    TaskStatusExtract(key: 'tasks'),
    HasSectionExtract(key: 'hasPayment', title: 'Payment terms'),
  ],
  constraints: [
    RequiredSectionRule(title: 'Payment terms', nonEmpty: true),
    MinLengthRule(min: 100),
    MaxLengthRule(max: 1000000),
    ForbiddenPatternRule(pattern: r'\bTODO\b'),
  ],
);

/// Durations of one measured phase.
class BenchStat {
  BenchStat(this.name, List<Duration> samples) : samples = [...samples]..sort();

  final String name;
  final List<Duration> samples;

  double _ms(Duration d) => d.inMicroseconds / 1000;

  double get medianMs => _ms(samples[samples.length ~/ 2]);

  double get p95Ms => _ms(
    samples[math.min(samples.length - 1, (samples.length * 0.95).ceil() - 1)],
  );

  double get maxMs => _ms(samples.last);

  String row() =>
      '| ${name.padRight(34)} | ${samples.length.toString().padLeft(3)} '
      '| ${medianMs.toStringAsFixed(2).padLeft(9)} '
      '| ${p95Ms.toStringAsFixed(2).padLeft(9)} '
      '| ${maxMs.toStringAsFixed(2).padLeft(9)} |';
}

/// What [runDocumentBenchmark] measured.
class BenchReport {
  BenchReport(this.mode, this.stats);

  final String mode;
  final Map<String, BenchStat> stats;

  BenchStat operator [](String key) => stats[key]!;

  String table() => [
    'championforms_documents benchmark ($mode): $benchNodeCount nodes, '
        '$benchEmbeddedCount embedded fields',
    '| ${'phase'.padRight(34)} |   n | median ms |    p95 ms |    max ms |',
    '|${'-' * 36}|-----|-----------|-----------|-----------|',
    for (final s in stats.values) s.row(),
  ].join('\n');
}

Duration _time(void Function() body) {
  final sw = Stopwatch()..start();
  body();
  return sw.elapsed;
}

Future<Duration> _timeAsync(Future<void> Function() body) async {
  final sw = Stopwatch()..start();
  await body();
  return sw.elapsed;
}

/// Pumps a form holding a [DocumentField] over [buildBenchDocument] and
/// measures:
///
/// - `first build`: the first `pumpWidget` (build, layout, paint of all
///   600 nodes and registration of the 20 embedded fields);
/// - `keystroke`: typing one character through the IME, including its
///   frame, over [benchKeystrokes] keystrokes;
/// - `snapshot push`: `flush()` after a keystroke (editor → snapshot →
///   embedded sync → controller value → derived values → issues);
/// - `toSnapshot`: the editor document → [DocSnapshot] conversion alone;
/// - `evaluate`: [evaluate] with [benchRuleSet];
/// - `getResults`: `DocumentFields.getResults` over the whole form.
///
/// [onPhase] is called with `'keystrokes'` right before the timed keystrokes
/// and with `'done'` right after them, so a live binding can attribute
/// engine frame timings to typing.
Future<BenchReport> runDocumentBenchmark(
  WidgetTester tester, {
  required String mode,
  void Function(String phase)? onPhase,
}) async {
  if (!tester.testTextInput.isRegistered) tester.testTextInput.register();
  final doc = buildBenchDocument();
  assert(doc.nodes.length == benchNodeCount);
  assert(doc.embeddedFields.length == benchEmbeddedCount);

  final controller = form.FormController();
  final stats = <String, BenchStat>{};
  try {
    final firstBuild = await _timeAsync(
      () => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: form.Form(
                controller: controller,
                fields: [
                  DocumentField(
                    id: 'doc',
                    initialDocument: doc,
                    ruleSet: benchRuleSet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final settle = await _timeAsync(() => tester.pumpAndSettle());
    stats['first build'] = BenchStat('first build (pumpWidget)', [firstBuild]);
    stats['settle'] = BenchStat('first settle (pumpAndSettle)', [settle]);

    for (var i = 0; i < benchEmbeddedCount; i++) {
      final nodeId = doc.embeddedFields.elementAt(i).id;
      expect(
        controller.hasFieldDefinition('doc.field.$nodeId'),
        isTrue,
        reason: 'embedded field $nodeId is registered',
      );
    }

    final state = tester.state<DocumentFieldWidgetState>(
      find.byType(DocumentFieldWidget),
    );
    final editor = state.editorState!;

    // Type at the end of a paragraph in the middle of the document.
    const target = 'n301';
    final targetNode = doc.nodeById(target)! as TextDocNode;
    editor.focusNode.requestFocus();
    await tester.pump();
    editor.editor.execute([
      _caretAt(editor.document, target, targetNode.text.text.length),
    ]);
    await tester.pump();

    final keystrokes = <Duration>[];
    onPhase?.call('keystrokes');
    for (var i = 0; i < benchKeystrokes; i++) {
      final ch = String.fromCharCode(0x61 + i % 26);
      keystrokes.add(await _timeAsync(() => tester.typeImeText(ch)));
    }
    onPhase?.call('done');
    stats['keystroke'] = BenchStat('keystroke (IME char + frame)', keystrokes);

    final typed =
        (editor.snapshot().nodeById(target)! as TextDocNode).text.text;
    expect(typed.length, targetNode.text.text.length + benchKeystrokes);

    final pushes = <Duration>[];
    for (var i = 0; i < 20; i++) {
      await tester.typeImeText('z');
      pushes.add(_time(state.flush));
    }
    stats['snapshot push'] = BenchStat('snapshot push (flush)', pushes);
    await tester.pump();

    final current = editor.snapshot();
    expect(
      DocumentField.coerce(controller.getFieldValueOrNull<Object>('doc')),
      current,
      reason: 'flush pushed the latest snapshot',
    );

    stats['toSnapshot'] = BenchStat('toSnapshot (editor -> snapshot)', [
      for (var i = 0; i < 20; i++) _time(editor.snapshot),
    ]);

    late ExtractionResult result;
    stats['evaluate'] = BenchStat('evaluate (RuleSet)', [
      for (var i = 0; i < 50; i++)
        _time(() => result = evaluate(current, benchRuleSet)),
    ]);
    expect((result.values['people'] as List), hasLength(17));
    expect(result.values['hasPayment'], isTrue);
    expect(result.issues, isEmpty);

    stats['getResults'] = BenchStat('DocumentFields.getResults', [
      for (var i = 0; i < 10; i++)
        _time(() => DocumentFields.getResults(controller: controller)),
    ]);
  } finally {
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  }
  return BenchReport(mode, stats);
}

se.ChangeSelectionRequest _caretAt(
  se.Document document,
  String nodeId,
  int offset,
) => se.ChangeSelectionRequest(
  se.DocumentSelection.collapsed(
    position: SuperEditorAdapter.toEditorPosition(document, nodeId, offset),
  ),
  se.SelectionChangeType.placeCaret,
  se.SelectionReason.userInteraction,
);

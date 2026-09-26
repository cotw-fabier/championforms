import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Fixed extends TransformRule {
  const _Fixed(this.edit);
  final DocEdit? edit;
  @override
  String get ruleName => 'fixed';
  @override
  DocEdit? apply(DocSnapshot doc, DocInputEvent event) => edit;
  @override
  Map<String, dynamic> toJson() => const {};
}

final class _ThrowingTransform extends TransformRule {
  const _ThrowingTransform();
  @override
  String get ruleName => 'boom';
  @override
  DocEdit? apply(DocSnapshot doc, DocInputEvent event) =>
      throw StateError('boom');
  @override
  Map<String, dynamic> toJson() => const {};
}

final class _ValueExtract extends ExtractRule {
  const _ValueExtract(this.value, {required super.key, super.required});
  final Object? value;
  @override
  String get ruleName => 'value';
  @override
  Object? extract(DocSnapshot doc) => value;
  @override
  Map<String, dynamic> toJson() => const {};
}

final class _ThrowingExtract extends ExtractRule {
  const _ThrowingExtract({required super.key, super.required});
  @override
  String get ruleName => 'throwingExtract';
  @override
  Object? extract(DocSnapshot doc) => throw const FormatException('nope');
  @override
  Map<String, dynamic> toJson() => const {};
}

final class _SeesExtracted extends ConstraintRule {
  const _SeesExtracted();
  @override
  String get ruleName => 'seesExtracted';
  @override
  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted) => [
    DocIssue('saw ${extracted['a']}', nodeId: 'p1', start: 0, end: 1),
  ];
  @override
  Map<String, dynamic> toJson() => const {};
}

final class _ThrowingConstraint extends ConstraintRule {
  const _ThrowingConstraint();
  @override
  String get ruleName => 'throwingConstraint';
  @override
  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted) =>
      throw ArgumentError('bad');
  @override
  Map<String, dynamic> toJson() => const {};
}

void main() {
  final doc = DocSnapshot(const [
    ParagraphNode(id: 'p1', text: DocText('one')),
    DividerNode(id: 'd'),
    ParagraphNode(id: 'p2', text: DocText('two')),
  ]);

  List<String> ids(DocSnapshot d) => [for (final n in d.nodes) n.id];

  group('DocEditApplier', () {
    test('applies ops in order', () {
      final result = DocEditApplier.apply(
        doc,
        const DocEdit([
          InsertAfterOp(null, ParagraphNode(id: 'first')),
          InsertAfterOp('p2', ParagraphNode(id: 'last')),
          RemoveNodeOp('d'),
          ReplaceNodeOp('p1', HeadingNode(id: 'p1', text: DocText('one'))),
          // Anchors on a node inserted earlier in the same edit.
          InsertAfterOp('first', DividerNode(id: 'd2')),
        ], caret: DocCaret('p1', 3)),
      );
      expect(ids(result), ['first', 'd2', 'p1', 'p2', 'last']);
      expect(result.nodeById('p1'), isA<HeadingNode>());
      expect(ids(doc), ['p1', 'd', 'p2'], reason: 'input untouched');
    });

    test('a replacement may take a new, unused id', () {
      final result = DocEditApplier.apply(
        doc,
        const DocEdit([ReplaceNodeOp('d', DividerNode(id: 'd9'))]),
      );
      expect(ids(result), ['p1', 'd9', 'p2']);
    });

    test('throws on unknown ids', () {
      for (final op in const <DocEditOp>[
        ReplaceNodeOp('x', ParagraphNode(id: 'x')),
        RemoveNodeOp('x'),
        InsertAfterOp('x', ParagraphNode(id: 'y')),
      ]) {
        expect(
          () => DocEditApplier.apply(doc, DocEdit([op])),
          throwsStateError,
        );
      }
    });

    test('throws on a duplicate insert or a colliding replacement', () {
      expect(
        () => DocEditApplier.apply(
          doc,
          const DocEdit([InsertAfterOp('p1', ParagraphNode(id: 'p2'))]),
        ),
        throwsStateError,
      );
      expect(
        () => DocEditApplier.apply(
          doc,
          const DocEdit([ReplaceNodeOp('p1', DividerNode(id: 'd'))]),
        ),
        throwsStateError,
      );
    });

    test('removing then re-inserting an id is allowed', () {
      final result = DocEditApplier.apply(
        doc,
        const DocEdit([
          RemoveNodeOp('d'),
          InsertAfterOp('p2', DividerNode(id: 'd')),
        ]),
      );
      expect(ids(result), ['p1', 'p2', 'd']);
    });

    test('validates the caret', () {
      DocSnapshot at(String id, int offset) => DocEditApplier.apply(
        doc,
        DocEdit(const [], caret: DocCaret(id, offset)),
      );
      expect(ids(at('p1', 0)), ids(doc));
      expect(ids(at('p1', 3)), ids(doc));
      expect(ids(at('d', 1)), ids(doc));
      expect(() => at('p1', 4), throwsStateError);
      expect(() => at('p1', -1), throwsStateError);
      expect(() => at('d', 2), throwsStateError);
      expect(() => at('gone', 0), throwsStateError);
      expect(
        () => DocEditApplier.apply(
          doc,
          const DocEdit([RemoveNodeOp('p1')], caret: DocCaret('p1', 0)),
        ),
        throwsStateError,
        reason: 'caret checked against the result',
      );
    });

    test('caret offsets are UTF-16 code units', () {
      final emoji = DocSnapshot(const [
        ParagraphNode(id: 'e', text: DocText('a👋')),
      ]);
      expect(
        DocEditApplier.apply(
          emoji,
          const DocEdit([], caret: DocCaret('e', 3)),
        ).nodes.single.id,
        'e',
      );
      expect(
        () => DocEditApplier.apply(
          emoji,
          const DocEdit([], caret: DocCaret('e', 4)),
        ),
        throwsStateError,
      );
    });

    test('keeps the schema version and works on an empty doc', () {
      final result = DocEditApplier.apply(
        DocSnapshot.empty,
        const DocEdit([InsertAfterOp(null, ParagraphNode(id: 'a'))]),
      );
      expect(ids(result), ['a']);
      expect(result.schemaVersion, DocSnapshot.currentSchemaVersion);
    });
  });

  group('TransformEngine', () {
    const e1 = DocEdit([RemoveNodeOp('d')]);
    const e2 = DocEdit([RemoveNodeOp('p2')]);
    const event = EnterPressed('p1', caretOffset: 0);

    test('the first non-null edit wins', () {
      final engine = TransformEngine(const [
        _Fixed(null),
        _Fixed(e1),
        _Fixed(e2),
      ]);
      expect(engine.handle(doc, event), same(e1));
    });

    test('null when no rule reacts, including with no rules', () {
      expect(TransformEngine(const [_Fixed(null)]).handle(doc, event), isNull);
      expect(TransformEngine(const []).handle(doc, event), isNull);
      expect(TransformEngine(const []).run(doc, event), isNull);
    });

    test('a throwing rule declines', () {
      final engine = TransformEngine(const [_ThrowingTransform(), _Fixed(e2)]);
      expect(engine.handle(doc, event), same(e2));
    });

    test('run applies the edit and returns the caret', () {
      final engine = TransformEngine(const [
        _Fixed(DocEdit([RemoveNodeOp('d')], caret: DocCaret('p2', 1))),
      ]);
      final result = engine.run(doc, event)!;
      expect(ids(result.doc), ['p1', 'p2']);
      expect(result.caret!.nodeId, 'p2');
      expect(result.caret!.offset, 1);
    });

    test('fromRuleSet uses the transforms', () {
      final engine = TransformEngine.fromRuleSet(
        const RuleSet(transforms: [_Fixed(e1)]),
      );
      expect(engine.rules, hasLength(1));
      expect(engine.handle(doc, event), same(e1));
    });
  });

  group('evaluate', () {
    test('collects values, then required issues, then constraints', () {
      final result = evaluate(
        doc,
        const RuleSet(
          extracts: [
            _ValueExtract('x', key: 'a'),
            _ValueExtract(null, key: 'b', required: true),
            _ValueExtract(0, key: 'c', required: true),
            _ValueExtract(false, key: 'd', required: true),
          ],
          constraints: [_SeesExtracted()],
        ),
      );
      expect(result.values, {'a': 'x', 'b': null, 'c': 0, 'd': false});
      expect(result.issues.map((i) => i.message), ['"b" is required', 'saw x']);
      expect(result.issues.first.nodeId, isNull);
      expect(result.issues.last.nodeId, 'p1');
      expect(result.isValid, isFalse);
    });

    test('empty means null, blank string, empty list or map', () {
      for (final empty in [null, '', '  \n', <Object>[], <String, Object>{}]) {
        expect(isEmptyExtractedValue(empty), isTrue, reason: '$empty');
        final result = evaluate(
          doc,
          RuleSet(extracts: [_ValueExtract(empty, key: 'k', required: true)]),
        );
        expect(result.issues.single.message, '"k" is required');
      }
      for (final value in [
        'x',
        0,
        false,
        const ['a'],
        const {'a': 1},
      ]) {
        expect(isEmptyExtractedValue(value), isFalse, reason: '$value');
      }
    });

    test('a required value that is present passes', () {
      final result = evaluate(
        doc,
        const RuleSet(
          extracts: [_ValueExtract('ok', key: 'k', required: true)],
        ),
      );
      expect(result.isValid, isTrue);
    });

    test('a throwing extract becomes an issue and a null value', () {
      final result = evaluate(
        doc,
        const RuleSet(
          extracts: [
            _ThrowingExtract(key: 'k', required: true),
            _ValueExtract(1, key: 'n'),
          ],
        ),
      );
      expect(result.values, {'k': null, 'n': 1});
      expect(
        result.issues.single.message,
        startsWith('Rule throwingExtract failed: FormatException: nope'),
      );
    });

    test('a throwing constraint becomes an issue; others still run', () {
      final result = evaluate(
        doc,
        const RuleSet(
          extracts: [_ValueExtract('v', key: 'a')],
          constraints: [_ThrowingConstraint(), _SeesExtracted()],
        ),
      );
      expect(result.issues.map((i) => i.message), [
        startsWith('Rule throwingConstraint failed:'),
        'saw v',
      ]);
    });

    test('an invalid extract key is reported, not stored', () {
      final result = evaluate(
        doc,
        const RuleSet(extracts: [_ValueExtract('v', key: 'a.b')]),
      );
      expect(result.values, isEmpty);
      expect(result.issues.single.message, startsWith('Rule value failed:'));
    });

    test('the later of two rules with one key wins', () {
      final result = evaluate(
        doc,
        const RuleSet(
          extracts: [
            _ValueExtract(1, key: 'k'),
            _ValueExtract(2, key: 'k'),
          ],
        ),
      );
      expect(result.values, {'k': 2});
    });

    test('an empty rule set on an empty doc is valid', () {
      final result = evaluate(DocSnapshot.empty, RuleSet.empty);
      expect(result.values, isEmpty);
      expect(result.isValid, isTrue);
    });
  });
}

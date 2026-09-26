import 'dart:convert';

import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

DocSnapshot doc(List<DocNode> nodes) => DocSnapshot(nodes);
ParagraphNode p(String id, String text) =>
    ParagraphNode(id: id, text: DocText(text));
HeadingNode h(String id, String text, [int level = 1]) =>
    HeadingNode(id: id, level: level, text: DocText(text));

/// A service agreement used across groups.
final agreement = doc([
  h('title', 'Service Agreement'),
  p('intro', 'Between @alice and @bob, starting 2026-10-01.'),
  h('scope', 'Scope', 2),
  p('s1', 'Build the thing for @alice.'),
  h('scopeDetail', 'Details', 3),
  const ListItemNode(id: 's2', text: DocText('Due 12/31/2026')),
  h('pricing', 'Pricing', 2),
  p('pr1', r'Total: $4,000'),
  const TaskNode(id: 't1', checked: true, text: DocText('Sign')),
  const TaskNode(id: 't2', text: DocText('Pay')),
  const DividerNode(id: 'div'),
  const EmbeddedFieldNode(id: 'e1', fieldJson: {'type': 'fileUpload'}),
  h('empty', 'Notes', 2),
  h('end', 'Appendix', 1),
]);

void main() {
  setUpAll(DocumentRules.ensureInitialized);

  group('mentions', () {
    const rule = MentionsExtract(key: 'people');

    test('unique names in order of appearance', () {
      expect(rule.extract(agreement), ['alice', 'bob']);
    });

    test('handles punctuation, unicode, dots and emails', () {
      final d = doc([
        p('a', 'cc @zoë, @jean-luc. and @ada.lovelace; mail x@y.com @_x9'),
        const QuoteNode(id: 'q', text: DocText('(@bob) @@nope @ lone')),
      ]);
      expect(rule.extract(d), [
        'zoë',
        'jean-luc',
        'ada.lovelace',
        '_x9',
        'bob',
      ]);
    });

    test('empty doc gives an empty list, which fails required', () {
      expect(rule.extract(DocSnapshot.empty), isEmpty);
      final r = evaluate(
        DocSnapshot.empty,
        const RuleSet(extracts: [MentionsExtract(key: 'p', required: true)]),
      );
      expect(r.issues.single.message, '"p" is required');
    });
  });

  group('dates', () {
    test('first date in document order, normalized to ISO', () {
      expect(const DatesExtract(key: 'd').extract(agreement), '2026-10-01');
      expect(
        const DatesExtract(key: 'd').extract(doc([p('a', 'on 3/7/2025')])),
        '2025-03-07',
      );
    });

    test('all dates, unique, in order', () {
      final d = doc([
        p('a', 'from 1/2/2025 to 2025-01-31, again 2025-01-02'),
        p('b', '12/31/2026'),
      ]);
      expect(const DatesExtract(key: 'd', all: true).extract(d), [
        '2025-01-02',
        '2025-01-31',
        '2026-12-31',
      ]);
    });

    test('ignores impossible dates and digit runs', () {
      final d = doc([
        p('a', '2024-02-30 13/01/2024 2024-13-01 12345-01-01 1/1/20245 v1.2'),
        p('b', 'leap 2/29/2024'),
      ]);
      expect(const DatesExtract(key: 'd', all: true).extract(d), [
        '2024-02-29',
      ]);
    });

    test('no dates: null or empty list', () {
      expect(const DatesExtract(key: 'd').extract(DocSnapshot.empty), isNull);
      expect(
        const DatesExtract(key: 'd', all: true).extract(DocSnapshot.empty),
        isEmpty,
      );
    });
  });

  group('sectionText', () {
    test('text under a heading, case-insensitive, sub-headings included', () {
      expect(
        const SectionTextExtract(
          key: 's',
          title: '  scope ',
        ).extract(agreement),
        'Build the thing for @alice.\nDetails\nDue 12/31/2026',
      );
    });

    test('stops at the next heading of the same or higher level', () {
      expect(
        const SectionTextExtract(key: 's', title: 'Pricing').extract(agreement),
        r'Total: $4,000'
        '\nSign\nPay',
      );
      expect(
        const SectionTextExtract(
          key: 's',
          title: 'Service agreement',
        ).extract(agreement),
        contains('Appendix').not,
      );
    });

    test('empty section is "", missing section is null', () {
      expect(
        const SectionTextExtract(key: 's', title: 'Notes').extract(agreement),
        '',
      );
      expect(
        const SectionTextExtract(key: 's', title: 'Nope').extract(agreement),
        isNull,
      );
      expect(
        const SectionTextExtract(
          key: 's',
          title: 'Appendix',
        ).extract(agreement),
        '',
      );
    });

    test('multi-byte titles match', () {
      final d = doc([h('a', 'Résumé 📄'), p('b', 'x')]);
      expect(
        const SectionTextExtract(key: 's', title: 'RÉSUMÉ 📄').extract(d),
        'x',
      );
    });
  });

  group('regex', () {
    test('first match, group, all, case', () {
      expect(
        const RegexExtract(
          key: 'r',
          pattern: r'\$([\d,]+)',
          group: 1,
        ).extract(agreement),
        '4,000',
      );
      expect(
        const RegexExtract(
          key: 'r',
          pattern: r'@(\w+)',
          group: 1,
          all: true,
        ).extract(agreement),
        ['alice', 'bob', 'alice'],
      );
      expect(
        const RegexExtract(key: 'r', pattern: 'TOTAL').extract(agreement),
        isNull,
      );
      expect(
        const RegexExtract(
          key: 'r',
          pattern: 'TOTAL',
          caseSensitive: false,
        ).extract(agreement),
        'Total',
      );
    });

    test('^ and \$ match per block', () {
      expect(
        const RegexExtract(
          key: 'r',
          pattern: r'^Due (.+)$',
          group: 1,
        ).extract(agreement),
        '12/31/2026',
      );
    });

    test('non-participating groups are skipped with all', () {
      final d = doc([p('a', 'a1 b c2')]);
      expect(
        const RegexExtract(
          key: 'r',
          pattern: r'[a-c](\d)?',
          group: 1,
          all: true,
        ).extract(d),
        ['1', '2'],
      );
    });

    test('a bad pattern or group fails as an issue', () {
      final r = evaluate(
        agreement,
        const RuleSet(
          extracts: [
            RegexExtract(key: 'a', pattern: '('),
            RegexExtract(key: 'b', pattern: 'Total', group: 3),
          ],
        ),
      );
      expect(r.values, {'a': null, 'b': null});
      expect(
        r.issues.map((i) => i.message),
        everyElement(startsWith('Rule regex failed:')),
      );
      expect(r.issues, hasLength(2));
    });
  });

  group('taskStatus / hasSection', () {
    test('counts tasks', () {
      expect(const TaskStatusExtract(key: 't').extract(agreement), {
        'total': 2,
        'done': 1,
      });
      expect(const TaskStatusExtract(key: 't').extract(DocSnapshot.empty), {
        'total': 0,
        'done': 0,
      });
    });

    test('hasSection', () {
      expect(
        const HasSectionExtract(key: 'h', title: 'pricing').extract(agreement),
        isTrue,
      );
      expect(
        const HasSectionExtract(key: 'h', title: 'Pricing:').extract(agreement),
        isFalse,
      );
      // A paragraph with the title text is not a section.
      expect(
        const HasSectionExtract(
          key: 'h',
          title: 'Total: \$4,000',
        ).extract(agreement),
        isFalse,
      );
    });
  });

  group('requiredSection', () {
    test('missing section: unanchored issue', () {
      final issues = const RequiredSectionRule(
        title: 'Termination',
      ).check(agreement, {});
      expect(issues.single.message, 'Section "Termination" is required');
      expect(issues.single.nodeId, isNull);
    });

    test(
      'present passes; nonEmpty anchors an empty section to its heading',
      () {
        expect(
          const RequiredSectionRule(title: 'Notes').check(agreement, {}),
          isEmpty,
        );
        final issues = const RequiredSectionRule(
          title: 'notes',
          nonEmpty: true,
        ).check(agreement, {});
        expect(issues.single.nodeId, 'empty');
        expect(issues.single.start, 0);
        expect(issues.single.end, 5);
        expect(
          const RequiredSectionRule(
            title: 'Scope',
            nonEmpty: true,
          ).check(agreement, {}),
          isEmpty,
        );
      },
    );

    test('whitespace-only body counts as empty; custom message', () {
      final d = doc([h('a', 'X'), p('b', '   ')]);
      final issues = const RequiredSectionRule(
        title: 'X',
        nonEmpty: true,
        message: 'Fill X in',
      ).check(d, {});
      expect(issues.single.message, 'Fill X in');
    });
  });

  group('minLength / maxLength', () {
    final d = doc([
      h('h', 'Intro'),
      p('a', 'hello'), // 5
      p('b', '👋👋👋'), // 3 chars, 6 code units
      h('h2', 'Other'),
      p('c', 'abc'),
    ]);

    test('counts code points over text nodes', () {
      // Whole doc: 5 + 5 + 3 + 5 + 3 = 21.
      expect(const MinLengthRule(min: 21).check(d, {}), isEmpty);
      expect(const MinLengthRule(min: 22).check(d, {}).single.nodeId, isNull);
      expect(const MaxLengthRule(max: 21).check(d, {}), isEmpty);
    });

    test('section scope anchors min to the heading', () {
      expect(
        const MinLengthRule(min: 8, section: 'intro').check(d, {}),
        isEmpty,
      );
      final issue = const MinLengthRule(
        min: 9,
        section: 'Intro',
      ).check(d, {}).single;
      expect(issue.nodeId, 'h');
      expect(issue.message, 'Section "Intro" needs at least 9 characters');
      expect((issue.start, issue.end), (0, 5));
    });

    test('min on a missing section fails unanchored; max passes', () {
      expect(
        const MinLengthRule(min: 1, section: 'Nope').check(d, {}).single.nodeId,
        isNull,
      );
      expect(
        const MaxLengthRule(max: 0, section: 'Nope').check(d, {}),
        isEmpty,
      );
    });

    test('max anchors to where the limit is crossed, in UTF-16 offsets', () {
      // Intro body: "hello" (5) then 3 emoji; max 6 fits one emoji.
      final issue = const MaxLengthRule(
        max: 6,
        section: 'Intro',
      ).check(d, {}).single;
      expect(issue.nodeId, 'b');
      expect(issue.start, 2);
      expect(issue.end, 6);
      final whole = const MaxLengthRule(max: 3).check(d, {}).single;
      expect(whole.nodeId, 'h');
      expect((whole.start, whole.end), (3, 5));
      expect(whole.message, 'The document must be at most 3 characters');
    });

    test('empty document', () {
      expect(
        const MinLengthRule(min: 1).check(DocSnapshot.empty, {}),
        hasLength(1),
      );
      expect(const MinLengthRule(min: 0).check(DocSnapshot.empty, {}), isEmpty);
      expect(const MaxLengthRule(max: 0).check(DocSnapshot.empty, {}), isEmpty);
    });
  });

  group('forbiddenPattern', () {
    test('one anchored issue per match', () {
      final d = doc([
        p('a', 'TODO fix, todo later'),
        const TaskNode(id: 't', text: DocText('👋 TODO')),
      ]);
      final issues = const ForbiddenPatternRule(
        pattern: 'todo',
        caseSensitive: false,
      ).check(d, {});
      expect(
        [for (final i in issues) (i.nodeId, i.start, i.end)],
        [('a', 0, 4), ('a', 10, 14), ('t', 3, 7)],
      );
      expect(issues.first.message, '"TODO" is not allowed');
    });

    test('empty matches are ignored; custom message', () {
      final issues = const ForbiddenPatternRule(
        pattern: r'x*',
        message: 'no x',
      ).check(doc([p('a', 'abxc')]), {});
      expect(issues.single.message, 'no x');
      expect((issues.single.start, issues.single.end), (2, 3));
    });

    test('a bad pattern fails as an issue', () {
      final r = evaluate(
        agreement,
        const RuleSet(constraints: [ForbiddenPatternRule(pattern: '[')]),
      );
      expect(
        r.issues.single.message,
        startsWith('Rule forbiddenPattern failed:'),
      );
    });
  });

  group('RuleSet JSON through the registry', () {
    const ruleSet = RuleSet(
      transforms: [
        MarkdownPrefixRule(),
        EnterSplitsRule(),
        BackspaceMergesRule(),
      ],
      extracts: [
        MentionsExtract(key: 'people', required: true),
        DatesExtract(key: 'dates', all: true),
        SectionTextExtract(key: 'scope', title: 'Scope'),
        RegexExtract(
          key: 'total',
          pattern: r'\$([\d,]+)',
          group: 1,
          all: false,
          caseSensitive: false,
        ),
        TaskStatusExtract(key: 'tasks'),
        HasSectionExtract(key: 'hasPricing', title: 'Pricing'),
      ],
      constraints: [
        RequiredSectionRule(title: 'Scope', nonEmpty: true, message: 'm'),
        MinLengthRule(min: 10, section: 'Scope'),
        MaxLengthRule(max: 5000),
        ForbiddenPatternRule(
          pattern: 'TBD',
          caseSensitive: false,
          message: 'x',
        ),
      ],
    );

    test('round-trips every built-in rule through a JSON string', () {
      final json =
          jsonDecode(jsonEncode(ruleSet.toJson())) as Map<String, dynamic>;
      final back = RuleSet.fromJson(json);
      expect(back.toJson(), ruleSet.toJson());
      expect(
        back.transforms.map((r) => r.runtimeType),
        ruleSet.transforms.map((r) => r.runtimeType),
      );
      expect(
        back.extracts.map((r) => (r.runtimeType, r.key, r.required)),
        ruleSet.extracts.map((r) => (r.runtimeType, r.key, r.required)),
      );
      expect(
        back.constraints.map((r) => r.runtimeType),
        ruleSet.constraints.map((r) => r.runtimeType),
      );
      // And it evaluates identically.
      final a = evaluate(agreement, ruleSet);
      final b = evaluate(agreement, back);
      expect(b.values, a.values);
      expect(b.issues.map((i) => i.message), a.issues.map((i) => i.message));
    });

    test('evaluates the agreement', () {
      final r = evaluate(agreement, ruleSet);
      expect(r.values, {
        'people': ['alice', 'bob'],
        'dates': ['2026-10-01', '2026-12-31'],
        'scope': 'Build the thing for @alice.\nDetails\nDue 12/31/2026',
        'total': '4,000',
        'tasks': {'total': 2, 'done': 1},
        'hasPricing': true,
      });
      expect(r.isValid, isTrue);
    });

    test('every built-in name is registered and stable', () {
      for (final name in [
        'markdownPrefix',
        'enterSplits',
        'backspaceMerges',
        'mentions',
        'dates',
        'sectionText',
        'regex',
        'taskStatus',
        'hasSection',
        'requiredSection',
        'minLength',
        'maxLength',
        'forbiddenPattern',
      ]) {
        expect(RuleRegistry.isRegistered(name), isTrue, reason: name);
      }
    });

    test('an unknown rule is rejected', () {
      expect(
        () => RuleSet.fromJson({
          'extracts': [
            {'rule': 'fieldValue', 'key': 'x'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => RuleSet.fromJson({
          'extracts': [
            {'key': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('a rule in the wrong group is rejected', () {
      expect(
        () => RuleSet.fromJson({
          'constraints': [
            {'rule': 'mentions', 'key': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('bad config is rejected', () {
      for (final bad in <Map<String, dynamic>>[
        {'rule': 'mentions'},
        {'rule': 'mentions', 'key': 3},
        {'rule': 'dates', 'key': 'd', 'all': 'yes'},
        {'rule': 'regex', 'key': 'r'},
        {'rule': 'sectionText', 'key': 's'},
        {'rule': 'minLength'},
        {'rule': 'maxLength', 'max': '10'},
        {'rule': 'requiredSection'},
        {'rule': 'forbiddenPattern', 'pattern': 'x', 'message': 1},
      ]) {
        expect(
          () => RuleRegistry.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('ensureInitialized is idempotent', () {
      DocumentRules.ensureInitialized();
      registerBuiltinRules();
      expect(RuleRegistry.isRegistered('regex'), isTrue);
    });
  });
}

extension on Matcher {
  Matcher get not => isNot(this);
}

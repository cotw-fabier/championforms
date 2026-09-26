import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

/// Encodes to a JSON string and back, as a save/load or clipboard would.
Map<String, dynamic> wire(Map<String, dynamic> json) =>
    (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>();

void main() {
  const marked = DocText('Hello bold link 👋', [
    DocMark(type: DocMarkType.bold, start: 6, end: 10),
    DocMark(type: DocMarkType.italic, start: 0, end: 5),
    DocMark(type: DocMarkType.underline, start: 1, end: 2),
    DocMark(type: DocMarkType.strikethrough, start: 2, end: 3),
    DocMark(type: DocMarkType.code, start: 3, end: 4),
    DocMark(type: DocMarkType.link, start: 11, end: 15, href: 'https://x.dev'),
  ]);

  final allNodes = <DocNode>[
    const ParagraphNode(id: 'p', text: marked),
    const HeadingNode(id: 'h', level: 3, text: DocText('Title')),
    const ListItemNode(
      id: 'l',
      ordered: true,
      indent: 2,
      text: DocText('item'),
    ),
    const TaskNode(id: 't', checked: true, text: DocText('done')),
    const QuoteNode(id: 'q', text: DocText('quoted')),
    const DividerNode(id: 'd'),
    const EmbeddedFieldNode(
      id: 'e',
      fieldJson: {
        'type': 'textField',
        'id': 'ignored',
        'options': [
          1,
          2,
          {'a': true},
        ],
      },
      sourceId: 'orig',
    ),
  ];

  group('DocNode JSON', () {
    for (final node in allNodes) {
      test('${node.type} round-trips', () {
        final back = DocNode.fromJson(wire(node.toJson()));
        expect(back, node);
        expect(back.runtimeType, node.runtimeType);
        expect(back.hashCode, node.hashCode);
      });
    }

    test('every mark type and href round-trips', () {
      final back = DocText.fromJson(wire(marked.toJson()));
      expect(back, marked);
      expect(back.marks.map((m) => m.type).toSet(), DocMarkType.values.toSet());
      expect(back.marks.last.href, 'https://x.dev');
    });

    test('empty text omits marks and restores empty', () {
      const p = ParagraphNode(id: 'p');
      expect(p.toJson()['content'], {'text': ''});
      expect(DocNode.fromJson(wire(p.toJson())), p);
    });

    test('missing content defaults to empty text', () {
      expect(
        DocNode.fromJson({'id': 'a', 'type': 'paragraph'}),
        const ParagraphNode(id: 'a'),
      );
    });

    test('embedded field without sourceId omits it', () {
      const e = EmbeddedFieldNode(id: 'e', fieldJson: {'type': 'x'});
      expect(e.toJson().containsKey('sourceId'), isFalse);
      expect(e.fieldType, 'x');
      expect(e.controllerIdFor('doc'), 'doc.field.e');
    });

    test('rejects unknown type, missing id, bad level and bad marks', () {
      expect(
        () => DocNode.fromJson({'id': 'a', 'type': 'table'}),
        throwsFormatException,
      );
      expect(
        () => DocNode.fromJson({'type': 'paragraph'}),
        throwsFormatException,
      );
      expect(
        () => DocNode.fromJson({'id': '', 'type': 'paragraph'}),
        throwsFormatException,
      );
      expect(
        () => DocNode.fromJson({'id': 'a', 'type': 'heading', 'level': 7}),
        throwsFormatException,
      );
      expect(
        () => DocNode.fromJson({'id': 'a', 'type': 'listItem', 'indent': -1}),
        throwsFormatException,
      );
      expect(
        () => DocNode.fromJson({'id': 'a', 'type': 'embeddedField'}),
        throwsFormatException,
      );
      expect(
        () => DocText.fromJson({
          'text': 'x',
          'marks': [
            {'type': 'bold', 'start': 3, 'end': 1},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => DocText.fromJson({
          'text': 'x',
          'marks': [
            {'type': 'sparkle', 'start': 0, 'end': 1},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('DocSnapshot', () {
    test('round-trips every node type through a JSON string', () {
      final doc = DocSnapshot(allNodes);
      final back = DocSnapshot.fromJson(wire(doc.toJson()));
      expect(back, doc);
      expect(back.hashCode, doc.hashCode);
      expect(back.embeddedFields.single.id, 'e');
      expect(back.indexOf('t'), 3);
      expect(back.nodeById('nope'), isNull);
    });

    test('rejects duplicate node ids', () {
      expect(
        () => DocSnapshot(const [ParagraphNode(id: 'a'), DividerNode(id: 'a')]),
        throwsArgumentError,
      );
      expect(
        () => DocSnapshot.fromJson({
          'schemaVersion': 1,
          'nodes': [
            {'id': 'a', 'type': 'divider'},
            {'id': 'a', 'type': 'divider'},
          ],
        }),
        throwsArgumentError,
      );
    });

    test('rejects newer, invalid and malformed schemas', () {
      expect(
        () => DocSnapshot.fromJson({
          'schemaVersion': DocSnapshot.currentSchemaVersion + 1,
          'nodes': <Object>[],
        }),
        throwsFormatException,
      );
      expect(
        () => DocSnapshot.fromJson({'schemaVersion': 0, 'nodes': []}),
        throwsFormatException,
      );
      expect(
        () => DocSnapshot.fromJson({'schemaVersion': '1', 'nodes': []}),
        throwsFormatException,
      );
      expect(
        () => DocSnapshot.fromJson({'schemaVersion': 1}),
        throwsFormatException,
      );
    });

    test('a missing schemaVersion is read as version 1', () {
      expect(DocSnapshot.fromJson({'nodes': []}), DocSnapshot.empty);
    });

    test('nodes are unmodifiable', () {
      final doc = DocSnapshot(const [ParagraphNode(id: 'a')]);
      expect(
        () => doc.nodes.add(const DividerNode(id: 'b')),
        throwsUnsupportedError,
      );
    });
  });

  group('DocClipboardPayload', () {
    const fragment = form.ClipboardFragment(
      plainText: 'Blue',
      html: '<span>Blue</span>',
      data: {
        'type': 'optionSelect',
        'value': ['blue'],
      },
    );

    test('round-trips nodes and field fragments', () {
      final payload = DocClipboardPayload(
        nodes: allNodes,
        fields: const {'e': fragment},
      );
      final back = DocClipboardPayload.fromJson(wire(payload.toJson()));
      expect(back.schemaVersion, DocClipboardPayload.currentSchemaVersion);
      expect(back.nodes, allNodes);
      expect(back.fields.keys, ['e']);
      expect(back.fields['e']!.plainText, 'Blue');
      expect(back.fields['e']!.html, '<span>Blue</span>');
      expect(back.fields['e']!.data, fragment.data);
    });

    test('omits empty fields', () {
      const payload = DocClipboardPayload(nodes: [ParagraphNode(id: 'a')]);
      expect(payload.toJson().containsKey('fields'), isFalse);
      expect(
        DocClipboardPayload.fromJson(wire(payload.toJson())).fields,
        isEmpty,
      );
    });

    test('rejects newer and missing versions', () {
      expect(
        () => DocClipboardPayload.fromJson({
          'schemaVersion': DocClipboardPayload.currentSchemaVersion + 1,
          'nodes': <Object>[],
        }),
        throwsFormatException,
      );
      expect(
        () => DocClipboardPayload.fromJson({'nodes': <Object>[]}),
        throwsFormatException,
      );
    });

    test('rejects malformed payloads', () {
      expect(
        () => DocClipboardPayload.fromJson({'schemaVersion': 1}),
        throwsFormatException,
      );
      expect(
        () =>
            DocClipboardPayload.fromJson({'schemaVersion': 1, 'nodes': 'nope'}),
        throwsFormatException,
      );
      expect(
        () => DocClipboardPayload.fromJson({
          'schemaVersion': 1,
          'nodes': [
            {'id': 'a', 'type': 'bogus'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => DocClipboardPayload.fromJson({
          'schemaVersion': 1,
          'nodes': <Object>[],
          'fields': {
            'e': {'html': 'x'},
          },
        }),
        throwsFormatException,
      );
    });
  });

  group('ids', () {
    test('newNodeId gives distinct uuid v4 strings', () {
      final ids = {for (var i = 0; i < 200; i++) newNodeId()};
      expect(ids, hasLength(200));
      expect(
        ids.first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('id segments', () {
      for (final ok in ['a', 'start_date', 'A1', '_']) {
        expect(isValidIdSegment(ok), isTrue, reason: ok);
        expect(checkIdSegment(ok), ok);
      }
      for (final bad in ['', 'a.b', 'a-b', 'a b', 'zoë', 'x\n']) {
        expect(isValidIdSegment(bad), isFalse, reason: bad);
        expect(() => checkIdSegment(bad, 'key'), throwsArgumentError);
      }
    });
  });

  group('DocText ops', () {
    test('concat shifts the second text\'s marks', () {
      const a = DocText('ab', [
        DocMark(type: DocMarkType.bold, start: 0, end: 2),
      ]);
      const b = DocText('cd', [
        DocMark(type: DocMarkType.italic, start: 1, end: 2),
      ]);
      expect(
        a.concat(b),
        const DocText('abcd', [
          DocMark(type: DocMarkType.bold, start: 0, end: 2),
          DocMark(type: DocMarkType.italic, start: 3, end: 4),
        ]),
      );
    });

    test('slice clips and re-bases marks', () {
      const t = DocText('abcdef', [
        DocMark(type: DocMarkType.bold, start: 0, end: 3),
        DocMark(type: DocMarkType.code, start: 4, end: 6),
      ]);
      expect(
        t.slice(2),
        const DocText('cdef', [
          DocMark(type: DocMarkType.bold, start: 0, end: 1),
          DocMark(type: DocMarkType.code, start: 2, end: 4),
        ]),
      );
    });
  });
}

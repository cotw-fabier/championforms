import 'dart:convert';

import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('untrusted JSON only ever throws FormatException', () {
    final hostile = <Object?>[
      {
        'nodes': [42],
      },
      {
        'nodes': ['x'],
      },
      {
        'nodes': [
          {'id': 'a', 'type': 'paragraph', 'content': 7},
        ],
      },
      {
        'nodes': [
          {
            'id': 'a',
            'type': 'paragraph',
            'content': {
              'text': 'x',
              'marks': [1],
            },
          },
        ],
      },
      {
        'nodes': [
          {
            'id': 'a',
            'type': 'paragraph',
            'content': {
              'text': 'x',
              'marks': [
                {'type': 'link', 'start': 0, 'end': 1, 'href': 3},
              ],
            },
          },
        ],
      },
      {
        'nodes': [
          {
            'id': 'a',
            'type': 'embeddedField',
            'field': {'type': 'textField'},
            'sourceId': 9,
          },
        ],
      },
    ];

    for (final (i, json) in hostile.indexed) {
      test('DocSnapshot case $i', () {
        expect(
          () => DocSnapshot.fromJson(json as Map<String, dynamic>),
          throwsFormatException,
        );
      });
      test('DocClipboardPayload case $i', () {
        final withVersion = {
          ...json as Map<String, dynamic>,
          'schemaVersion': 1,
        };
        expect(
          () => DocClipboardPayload.fromJson(withVersion),
          throwsFormatException,
        );
      });
    }

    test('payload fields map of the wrong shape', () {
      expect(
        () => DocClipboardPayload.fromJson({
          'schemaVersion': 1,
          'nodes': [],
          'fields': {'n1': 5},
        }),
        throwsFormatException,
      );
    });
  });

  group('DocClipboardPayload.decode', () {
    test('round-trips encode()', () {
      final payload = DocClipboardPayload(
        nodes: [const ParagraphNode(id: 'p1', text: DocText('hello'))],
      );
      expect(DocClipboardPayload.decode(payload.encode()).nodes, payload.nodes);
    });

    test('rejects oversize input before parsing', () {
      final big = 'x' * (DocClipboardPayload.maxEncodedLength + 1);
      expect(() => DocClipboardPayload.decode(big), throwsFormatException);
    });

    test('rejects non-JSON and non-object JSON', () {
      expect(
        () => DocClipboardPayload.decode('not json'),
        throwsFormatException,
      );
      expect(
        () => DocClipboardPayload.decode(jsonEncode([1, 2])),
        throwsFormatException,
      );
    });
  });

  test('DocIssue has value equality', () {
    expect(
      const DocIssue('m', nodeId: 'a', start: 1, end: 2),
      const DocIssue('m', nodeId: 'a', start: 1, end: 2),
    );
    expect(
      const DocIssue('m', nodeId: 'a'),
      isNot(const DocIssue('m', nodeId: 'b')),
    );
  });
}

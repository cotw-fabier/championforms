import 'dart:convert';
import 'dart:typed_data';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:championforms_documents/championforms_documents.dart';
import 'package:championforms_documents/src/clipboard/clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

const docId = 'doc';

final doc = DocSnapshot([
  const HeadingNode(id: 'h', text: DocText('Agreement')),
  const ParagraphNode(
    id: 'p',
    text: DocText('Hello bold world', [
      DocMark(type: DocMarkType.bold, start: 6, end: 10),
    ]),
  ),
  const EmbeddedFieldNode(
    id: 'tf',
    fieldJson: {'type': 'textField', 'title': 'Client'},
  ),
  const EmbeddedFieldNode(
    id: 'cb',
    fieldJson: {
      'type': 'checkboxSelect',
      'options': ['red', 'green', 'blue'],
    },
  ),
  const EmbeddedFieldNode(id: 'pw', fieldJson: {'type': 'password'}),
  const EmbeddedFieldNode(id: 'fu', fieldJson: {'type': 'fileUpload'}),
  const EmbeddedFieldNode(id: 'nm', fieldJson: {'type': 'name'}),
  const ListItemNode(id: 'li', text: DocText('last item')),
]);

final fileBytes = Uint8List.fromList(List.generate(64, (i) => i));

/// Registers the document's embedded fields in [controller] under their
/// controller ids and fills in values, as the embedded field manager would.
void registerEmbedded(form.FormController controller) {
  final fields = <form.Field>[
    for (final node in doc.embeddedFields)
      form.FormFieldRegistry.fieldFromJson({
        ...node.fieldJson,
        'id': node.controllerIdFor(docId),
      })!,
  ];
  controller.addFields(fields);
  final name = fields.whereType<form.NameField>().single;
  controller.addFields([
    for (final s in ['firstname', 'middlename', 'lastname'])
      form.TextField(id: '${name.id}_$s'),
  ]);
  controller.updateFieldValue<String>('doc.field.tf', 'Ada Lovelace');
  controller.updateMultiselectValues('doc.field.cb', [
    form.FieldOption(value: 'green'),
    form.FieldOption(value: 'blue'),
  ], overwrite: true);
  controller.updateFieldValue<String>('doc.field.pw', 'hunter2');
  controller.updateMultiselectValues('doc.field.fu', [
    form.FieldOption(
      value: 'contract.pdf',
      additionalData: form.FileModel(
        fileName: 'contract.pdf',
        fileBytes: fileBytes,
      ),
    ),
  ], overwrite: true);
  controller.updateFieldValue<String>('${name.id}_firstname', 'Grace');
  controller.updateFieldValue<String>('${name.id}_lastname', 'Hopper');
}

DocSelection all() => const DocSelection(
  startNodeId: 'h',
  startOffset: 0,
  endNodeId: 'li',
  endOffset: 9,
);

DocSelection block(String id) =>
    DocSelection(startNodeId: id, startOffset: 0, endNodeId: id, endOffset: 1);

void main() {
  setUpAll(() {
    form.FormFieldRegistry.ensureInitialized();
    // Core ships no JSON factory for FileUpload or NameField; a document that
    // embeds them needs one (the documents registration is expected to add
    // these). Tests register minimal ones.
    form.FormFieldRegistry.registerJsonAlias<form.FileUpload>(
      'fileUpload',
      (j) => form.FileUpload(id: j['id'] as String, multiselect: true),
    );
    form.FormFieldRegistry.registerJsonAlias<form.NameField>(
      'name',
      (j) => form.NameField(id: j['id'] as String),
    );
  });

  late form.FormController controller;
  late FakeClipboardBackend backend;
  late DocClipboardSessionCache cache;
  late ChampionDocClipboard clipboard;

  ChampionDocClipboard withBackend(FakeClipboardBackend b) =>
      ChampionDocClipboard(controller, backend: b, cache: cache);

  setUp(() {
    controller = form.FormController();
    registerEmbedded(controller);
    backend = FakeClipboardBackend();
    cache = DocClipboardSessionCache();
    clipboard = withBackend(backend);
  });

  tearDown(() => controller.dispose());

  group('copy', () {
    test('writes custom, HTML and plain text in one item', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: all());
      expect(backend.writes, hasLength(1));
      final c = backend.contents;
      expect(c.keys.toSet(), {
        docClipboardFormat,
        ClipboardFormat.html,
        ClipboardFormat.plainText,
      });

      final payload = DocClipboardPayload.decode(
        utf8.decode(c[docClipboardFormat] as Uint8List),
      );
      expect(payload.nodes, doc.nodes); // original ids, full nodes
      expect(payload.fields.keys.toSet(), {'tf', 'cb', 'fu', 'nm'});
      expect(payload.fields['tf']!.data, {
        'type': 'textField',
        'value': 'Ada Lovelace',
      });
      expect(payload.fields['nm']!.plainText, 'Grace, Hopper');

      final html = c[ClipboardFormat.html] as String;
      expect(html, contains('<h1>Agreement</h1>'));
      expect(html, contains('<p>Hello <strong>bold</strong> world</p>'));
      expect(html, contains('<div><span>Ada Lovelace</span></div>'));
      expect(html, contains('data-championforms="'));
      expect(html, contains('<!--championforms:'));
      expect(extractPayloadJsonFromHtml(html).first, payload.encode());

      expect(
        c[ClipboardFormat.plainText],
        'Agreement\nHello bold world\nAda Lovelace\n☐ red\n☑ green\n☑ blue\n'
        'contract.pdf\nGrace, Hopper\n- last item',
      );
    });

    test('password values never reach the clipboard or the cache', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: all());
      final everything = [
        utf8.decode(backend.contents[docClipboardFormat] as Uint8List),
        backend.contents[ClipboardFormat.html],
        backend.contents[ClipboardFormat.plainText],
      ].join('\n');
      expect(everything, isNot(contains('hunter2')));
      expect(cache.entry!.liveValues.keys, isNot(contains('pw')));
      // The definition is kept, so the block pastes back as an empty field.
      expect(cache.entry!.payload.nodes.map((n) => n.id), contains('pw'));

      // Copying only the password block writes no value either.
      await clipboard.copy(docId: docId, doc: doc, selection: block('pw'));
      expect(backend.contents[ClipboardFormat.plainText], '');
      final pasted = await clipboard.paste(docId: docId, doc: doc);
      expect(pasted!.nodes.single, isA<EmbeddedFieldNode>());
      expect(pasted.fieldValues, isEmpty);
    });

    test('one embedded block copies its own fragment html and text', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: block('cb'));
      expect(
        backend.contents[ClipboardFormat.plainText],
        '☐ red\n☑ green\n☑ blue',
      );
      final html = backend.contents[ClipboardFormat.html] as String;
      expect(
        html,
        endsWith(
          '"><ul><li>☐ red</li><li>☑ green</li><li>☑ blue</li></ul></div>',
        ),
      );
    });

    test(
      'a field not (yet) registered is copied from its definition',
      () async {
        final bare = form.FormController();
        addTearDown(bare.dispose);
        final c = ChampionDocClipboard(bare, backend: backend, cache: cache);
        await c.copy(docId: docId, doc: doc, selection: block('tf'));
        expect(backend.contents[ClipboardFormat.plainText], '');
        final payload = DocClipboardPayload.decode(
          utf8.decode(backend.contents[docClipboardFormat] as Uint8List),
        );
        expect(payload.fields['tf']!.data['value'], '');
      },
    );

    test('a collapsed selection writes nothing', () async {
      await clipboard.copy(
        docId: docId,
        doc: doc,
        selection: const DocSelection(
          startNodeId: 'p',
          startOffset: 2,
          endNodeId: 'p',
          endOffset: 2,
        ),
      );
      expect(backend.writes, isEmpty);
      expect(cache.entry, isNull);
    });
  });

  group('paste precedence', () {
    test(
      'custom format round-trips with fresh ids and restored values',
      () async {
        await clipboard.copy(docId: docId, doc: doc, selection: all());
        cache.clear(); // prove the custom format alone is enough
        final result = (await clipboard.paste(docId: docId, doc: doc))!;

        expect(result.nodes.map((n) => n.type), doc.nodes.map((n) => n.type));
        for (var i = 0; i < doc.nodes.length; i++) {
          expect(result.nodes[i].id, isNot(doc.nodes[i].id));
        }
        final p = result.nodes[1] as ParagraphNode;
        expect(p.text, (doc.nodes[1] as ParagraphNode).text);

        final embedded = result.nodes.whereType<EmbeddedFieldNode>().toList();
        expect(embedded.map((e) => e.sourceId), ['tf', 'cb', 'pw', 'fu', 'nm']);
        expect(embedded.every((e) => !e.fieldJson.containsKey('id')), isTrue);

        String idOf(String source) =>
            embedded.firstWhere((e) => e.sourceId == source).id;
        expect(result.fieldValues[idOf('tf')], 'Ada Lovelace');
        expect(result.fieldValues[idOf('cb')], ['green', 'blue']);
        expect(result.fieldValues[idOf('fu')], [
          {'name': 'contract.pdf', 'mimeType': null, 'size': 64},
        ]);
        expect(result.fieldValues[idOf('nm')], {
          'firstname': 'Grace',
          'middlename': '',
          'lastname': 'Hopper',
        });
        expect(result.fieldValues.containsKey(idOf('pw')), isFalse);
      },
    );

    test(
      'Android-like backend (no custom format) recovers via the HTML',
      () async {
        final android = FakeClipboardBackend(unsupported: {docClipboardFormat});
        final c = withBackend(android);
        await c.copy(docId: docId, doc: doc, selection: all());
        expect(android.contents.containsKey(docClipboardFormat), isFalse);
        cache.clear();

        final result = (await c.paste(docId: docId, doc: doc))!;
        expect(result.nodes, hasLength(doc.nodes.length));
        expect(
          result.nodes.whereType<EmbeddedFieldNode>().map((e) => e.sourceId),
          ['tf', 'cb', 'pw', 'fu', 'nm'],
        );
      },
    );

    test(
      'an app that strips attributes still leaves the comment copy',
      () async {
        final android = FakeClipboardBackend(unsupported: {docClipboardFormat});
        final c = withBackend(android);
        await c.copy(docId: docId, doc: doc, selection: all());
        cache.clear();
        final html = android.contents[ClipboardFormat.html] as String;
        final stripped = html.replaceAll(
          RegExp(r' data-championforms="[^"]*"'),
          '',
        );
        expect(stripped, isNot(contains('data-championforms')));
        android.setExternal({
          ClipboardFormat.html: stripped,
          ClipboardFormat.plainText: 'unrelated',
        });

        final result = (await c.paste(docId: docId, doc: doc))!;
        expect(
          result.nodes.whereType<EmbeddedFieldNode>().map((e) => e.sourceId),
          ['tf', 'cb', 'pw', 'fu', 'nm'],
        );
      },
    );

    test(
      'the session cache restores ID data when only plain text is left',
      () async {
        await clipboard.copy(docId: docId, doc: doc, selection: all());
        final plain = backend.contents[ClipboardFormat.plainText] as String;
        // The OS kept only text, with Windows line endings.
        backend.setExternal({
          ClipboardFormat.plainText: '${plain.replaceAll('\n', '\r\n')}\r\n',
        });

        final result = (await clipboard.paste(docId: docId, doc: doc))!;
        expect(result.nodes.first, isA<HeadingNode>());
        expect(
          result.nodes.whereType<EmbeddedFieldNode>().map((e) => e.sourceId),
          ['tf', 'cb', 'pw', 'fu', 'nm'],
        );
      },
    );

    test('FileUpload bytes survive through the cache', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: block('fu'));
      backend.setExternal({ClipboardFormat.plainText: 'contract.pdf'});

      final result = (await clipboard.paste(docId: docId, doc: doc))!;
      final node = result.nodes.single as EmbeddedFieldNode;
      final value = result.fieldValues[node.id] as List;
      final file =
          (value.single as form.FieldOption).additionalData as form.FileModel;
      expect(file.fileBytes, fileBytes);

      // Also when the custom format is still there (same payload).
      await clipboard.copy(docId: docId, doc: doc, selection: block('fu'));
      final again = (await clipboard.paste(docId: docId, doc: doc))!;
      final v2 = again.fieldValues[again.nodes.single.id] as List;
      expect(v2.single, isA<form.FieldOption>());

      // And the value restores into a registered field, bytes included.
      final pastedField = form.FormFieldRegistry.fieldFromJson({
        ...node.fieldJson,
        'id': node.controllerIdFor(docId),
      })!;
      controller.addFields([pastedField]);
      expect(restorePastedFieldValue(controller, pastedField, value), isTrue);
      final stored = controller.getFieldValue<List<form.FieldOption>>(
        pastedField.id,
      )!;
      expect(
        (stored.single.additionalData as form.FileModel).fileBytes,
        fileBytes,
      );
    });

    test('a stale cache does not hijack a different clipboard', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: all());
      backend.setExternal({ClipboardFormat.plainText: 'something else'});
      final result = (await clipboard.paste(docId: docId, doc: doc))!;
      expect(result.nodes.single, isA<ParagraphNode>());
      expect(result.fieldValues, isEmpty);
    });

    test('foreign HTML goes through the importer', () async {
      backend.setExternal({
        ClipboardFormat.html: '<h2>Title</h2><ul><li><b>x</b></li></ul>',
        ClipboardFormat.plainText: 'Title\nx',
      });
      final result = (await clipboard.paste(docId: docId, doc: doc))!;
      expect(result.nodes[0], isA<HeadingNode>());
      expect(
        (result.nodes[1] as ListItemNode).text.marks.single.type,
        DocMarkType.bold,
      );
    });

    test('plain text runs through the markdown prefix rule', () async {
      backend.setExternal({
        ClipboardFormat.plainText:
            '# Title\n- item\n  - nested\n[x] done\nplain',
      });
      final result = (await clipboard.paste(docId: docId, doc: doc))!;
      expect(result.nodes[0], isA<HeadingNode>());
      expect(result.nodes[1], isA<ListItemNode>());
      expect((result.nodes[2] as ListItemNode).indent, 1);
      expect((result.nodes[3] as TaskNode).checked, isTrue);
      expect((result.nodes[4] as ParagraphNode).text.text, 'plain');
    });

    test('an empty clipboard pastes nothing', () async {
      expect(await clipboard.paste(docId: docId, doc: doc), isNull);
      backend.setExternal({ClipboardFormat.plainText: ''});
      expect(await clipboard.paste(docId: docId, doc: doc), isNull);
    });

    test('a failing backend read pastes nothing instead of throwing', () async {
      final c = ChampionDocClipboard(
        controller,
        backend: _ThrowingBackend(),
        cache: cache,
      );
      expect(await c.paste(docId: docId, doc: doc), isNull);
    });
  });

  group('fresh ids', () {
    test('pasting twice never collides and records sourceId', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: all());
      final a = (await clipboard.paste(docId: docId, doc: doc))!;
      final b = (await clipboard.paste(docId: docId, doc: doc))!;
      final ids = [
        ...doc.nodes.map((n) => n.id),
        ...a.nodes.map((n) => n.id),
        ...b.nodes.map((n) => n.id),
      ];
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        a.fieldValues.keys.toSet().intersection(b.fieldValues.keys.toSet()),
        isEmpty,
      );
      final sources = [
        for (final r in [a, b])
          ...r.nodes.whereType<EmbeddedFieldNode>().map((e) => e.sourceId),
      ];
      expect(sources, [
        'tf',
        'cb',
        'pw',
        'fu',
        'nm',
        'tf',
        'cb',
        'pw',
        'fu',
        'nm',
      ]);
      // Every pasted id is a valid controller id segment.
      for (final n in [...a.nodes, ...b.nodes]) {
        expect(isValidIdSegment(n.id.replaceAll('-', '_')), isTrue);
      }
    });
  });

  group('hostile payloads degrade safely', () {
    Uint8List custom(Object json) => Uint8List.fromList(
      utf8.encode(json is String ? json : jsonEncode(json)),
    );

    Future<DocPasteResult?> pasteCustom(
      Object json, {
      String plain = 'fallback text',
    }) {
      backend.setExternal({
        docClipboardFormat: custom(json),
        ClipboardFormat.plainText: plain,
      });
      return clipboard.paste(docId: docId, doc: doc);
    }

    void expectFallback(DocPasteResult? r) {
      expect(r, isNotNull);
      expect((r!.nodes.single as ParagraphNode).text.text, 'fallback text');
    }

    test('malformed JSON falls through', () async {
      expectFallback(await pasteCustom('{not json'));
      expectFallback(await pasteCustom([1, 2, 3]));
      expectFallback(
        await pasteCustom({
          'schemaVersion': 1,
          'nodes': [
            {'id': 'x', 'type': 'heading', 'level': 99},
          ],
        }),
      );
    });

    test('invalid UTF-8 bytes fall through', () async {
      backend.setExternal({
        docClipboardFormat: Uint8List.fromList([0xff, 0xfe, 0xfd]),
        ClipboardFormat.plainText: 'fallback text',
      });
      expectFallback(await clipboard.paste(docId: docId, doc: doc));
    });

    test('oversize payloads are rejected before parsing', () async {
      final huge =
          '{"schemaVersion":1,"nodes":[],"pad":"'
          '${'x' * DocClipboardPayload.maxEncodedLength}"}';
      expectFallback(await pasteCustom(huge));
      // Oversize HTML is neither scanned nor imported.
      backend.setExternal({
        ClipboardFormat.html: '<p>${'y' * maxHtmlScanLength}</p>',
        ClipboardFormat.plainText: 'fallback text',
      });
      expectFallback(await clipboard.paste(docId: docId, doc: doc));
    });

    test('a newer schemaVersion falls through', () async {
      expectFallback(
        await pasteCustom({
          'schemaVersion': DocClipboardPayload.currentSchemaVersion + 1,
          'nodes': <Object>[],
        }),
      );
    });

    test(
      'an unknown field type becomes a paragraph of its plain text',
      () async {
        final r = await pasteCustom({
          'schemaVersion': 1,
          'nodes': [
            {
              'id': 'u',
              'type': 'embeddedField',
              'field': {'type': 'totallyUnknown'},
            },
            {
              'id': 'v',
              'type': 'embeddedField',
              'field': {'type': 'alsoUnknown'},
            },
          ],
          'fields': {
            'u': {
              'plainText': 'shown as text',
              'data': {'type': 'totallyUnknown', 'value': 1},
            },
          },
        });
        // 'v' has no fragment and no text: dropped.
        expect((r!.nodes.single as ParagraphNode).text.text, 'shown as text');
        expect(r.fieldValues, isEmpty);
      },
    );

    test('a malformed known field type also degrades to text', () async {
      final r = await pasteCustom({
        'schemaVersion': 1,
        'nodes': [
          {
            'id': 'u',
            'type': 'embeddedField',
            'field': {'type': 'checkboxSelect', 'options': 'not a list'},
          },
        ],
        'fields': {
          'u': {
            'plainText': 'boxes',
            'data': {'type': 'checkboxSelect', 'value': <String>[]},
          },
        },
      });
      expect((r!.nodes.single as ParagraphNode).text.text, 'boxes');
    });

    test(
      'a script-like id inside fieldJson or as node id is stripped',
      () async {
        final r = await pasteCustom({
          'schemaVersion': 1,
          'nodes': [
            {
              'id': '<img src=x onerror=alert(1)>',
              'type': 'embeddedField',
              'field': {
                'type': 'textField',
                'id': '"><script>alert(1)</script>',
              },
            },
          ],
          'fields': {
            '<img src=x onerror=alert(1)>': {
              'plainText': 'v',
              'data': {'type': 'textField', 'value': 'v'},
            },
          },
        });
        final node = r!.nodes.single as EmbeddedFieldNode;
        expect(node.fieldJson, {'type': 'textField'});
        expect(node.sourceId, isNull);
        expect(node.controllerIdFor(docId), 'doc.field.${node.id}');
        expect(r.fieldValues[node.id], 'v');
      },
    );

    test('mismatched value data is dropped, not coerced', () async {
      final r = await pasteCustom({
        'schemaVersion': 1,
        'nodes': [
          {
            'id': 'a',
            'type': 'embeddedField',
            'field': {
              'type': 'checkboxSelect',
              'options': ['x'],
            },
          },
        ],
        'fields': {
          'a': {
            'plainText': 'x',
            'data': {'type': 'textField', 'value': 'not a list'},
          },
        },
      });
      expect(r!.nodes.single, isA<EmbeddedFieldNode>());
      expect(r.fieldValues, isEmpty);
    });

    test('out-of-range marks and javascript links are cleaned', () async {
      final r = await pasteCustom({
        'schemaVersion': 1,
        'nodes': [
          {
            'id': 'p',
            'type': 'paragraph',
            'content': {
              'text': 'abc',
              'marks': [
                {'type': 'bold', 'start': 1, 'end': 500},
                {
                  'type': 'link',
                  'start': 0,
                  'end': 3,
                  'href': 'javascript:alert(1)',
                },
              ],
            },
          },
        ],
      });
      final text = (r!.nodes.single as ParagraphNode).text;
      expect(text.marks, [
        const DocMark(type: DocMarkType.bold, start: 1, end: 3),
      ]);
    });

    test(
      'a hostile HTML-embedded payload falls through to the importer',
      () async {
        final bad = base64Url.encode(utf8.encode('{"schemaVersion":1}'));
        backend.setExternal({
          ClipboardFormat.html:
              '<div data-championforms="$bad"><p>visible</p></div>',
          ClipboardFormat.plainText: 'visible',
        });
        final r = (await clipboard.paste(docId: docId, doc: doc))!;
        expect((r.nodes.single as ParagraphNode).text.text, 'visible');
      },
    );
  });

  group('restorePastedFieldValue', () {
    test('writes each codec shape back into the controller', () async {
      await clipboard.copy(docId: docId, doc: doc, selection: all());
      cache.clear();
      final r = (await clipboard.paste(docId: docId, doc: doc))!;
      final target = form.FormController();
      addTearDown(target.dispose);
      for (final node in r.nodes.whereType<EmbeddedFieldNode>()) {
        final field = form.FormFieldRegistry.fieldFromJson({
          ...node.fieldJson,
          'id': node.controllerIdFor('copy'),
        })!;
        target.addFields([field]);
        if (field is form.NameField) {
          target.addFields([
            for (final s in ['firstname', 'middlename', 'lastname'])
              form.TextField(id: '${field.id}_$s'),
          ]);
        }
        restorePastedFieldValue(target, field, r.fieldValues[node.id]);
      }
      String cid(String source) => r.nodes
          .whereType<EmbeddedFieldNode>()
          .firstWhere((e) => e.sourceId == source)
          .controllerIdFor('copy');
      expect(target.getFieldValue<String>(cid('tf')), 'Ada Lovelace');
      expect(
        target
            .getFieldValue<List<form.FieldOption>>(cid('cb'))!
            .map((o) => o.value),
        ['green', 'blue'],
      );
      expect(target.getFieldValue<String>('${cid('nm')}_lastname'), 'Hopper');
      // File metadata alone cannot restore files.
      expect(
        target.getFieldValueOrNull<List<form.FieldOption>>(cid('fu')) ?? [],
        isEmpty,
      );
    });
  });
}

class _ThrowingBackend implements ClipboardBackend {
  @override
  Future<Set<ClipboardFormat>> availableFormats() async => {};

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) =>
      Future.error(const ClipboardException('denied'));

  @override
  bool supports(ClipboardFormat format) => true;

  @override
  Future<void> write(ClipboardItem item) async {}
}

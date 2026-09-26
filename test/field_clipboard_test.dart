import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/mime_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A custom field written against the pre-clipboard API: its constructor and
/// `copyWith` know nothing about `clipboard`. It must keep compiling and
/// working.
class LegacyRatingField extends form.Field with form.TextFieldConverters {
  LegacyRatingField({
    required super.id,
    super.title,
    super.disabled,
    this.stars = 5,
  });

  final int stars;

  @override
  String? get defaultValue => null;

  @override
  LegacyRatingField copyWith({
    String? id,
    Widget? icon,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<form.Validator>? validators,
    bool? validateLive,
    Function(form.FormResults results)? onSubmit,
    Function(form.FormResults results)? onChange,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )?
    fieldLayout,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )?
    fieldBackground,
    int? stars,
  }) {
    return LegacyRatingField(
      id: id ?? this.id,
      title: title ?? this.title,
      disabled: disabled ?? this.disabled,
      stars: stars ?? this.stars,
    );
  }
}

/// A codec that tags everything it copies, to tell it apart from built-ins.
class TaggingCodec extends form.FieldClipboardCodec {
  const TaggingCodec();

  @override
  form.ClipboardFragment? copy(form.Field field, dynamic value) =>
      form.ClipboardFragment(
        plainText: 'tagged:$value',
        data: {'type': 'tagged', 'value': '$value'},
      );

  @override
  dynamic paste(Map<String, dynamic> data) =>
      data['type'] == 'tagged' ? data['value'] : null;
}

/// A map that throws on every read — the most hostile paste input.
class ExplodingMap extends MapBase<String, dynamic> {
  @override
  dynamic operator [](Object? key) => throw StateError('boom');
  @override
  void operator []=(String key, dynamic value) => throw StateError('boom');
  @override
  void clear() => throw StateError('boom');
  @override
  Iterable<String> get keys => throw StateError('boom');
  @override
  dynamic remove(Object? key) => throw StateError('boom');
}

/// JSON round trip, as the fragment would travel through a real clipboard.
Map<String, dynamic> viaJson(form.ClipboardFragment fragment) =>
    form.ClipboardFragment.fromJson(
      jsonDecode(jsonEncode(fragment.toJson())) as Map<String, dynamic>,
    ).data;

void main() {
  setUpAll(form.FormFieldRegistry.ensureInitialized);
  setUp(() => FormFieldDefaults.instance.reset());
  tearDown(() => FormFieldDefaults.instance.reset());

  form.FieldClipboardCodec codecFor(form.Field field) =>
      form.FormFieldRegistry.resolveClipboard(field)!;

  final options = [
    form.FieldOption(value: 'a', label: 'Apple'),
    form.FieldOption(value: 'b', label: 'Banana'),
    form.FieldOption(value: 'c', label: 'Cherry'),
  ];

  group('TextField', () {
    test('round-trips copy -> paste', () {
      final field = form.TextField(id: 'note');
      final codec = codecFor(field);
      expect(codec, isA<form.TextFieldClipboardCodec>());

      final fragment = codec.copy(field, 'hello')!;
      expect(fragment.plainText, 'hello');
      expect(fragment.html, '<span>hello</span>');
      expect(fragment.data, {'type': 'textField', 'value': 'hello'});
      expect(codec.paste(viaJson(fragment)), 'hello');
    });

    test('escapes HTML and turns newlines into <br>', () {
      final field = form.TextField(id: 'note');
      final fragment = codecFor(
        field,
      ).copy(field, '<script>alert("x")</script> & \'y\'\nline 2\r\nline 3')!;
      expect(
        fragment.html,
        '<span>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; '
        '&#39;y&#39;<br>line 2<br>line 3</span>',
      );
      // The plain text is the value, untouched.
      expect(fragment.plainText, contains('<script>'));
    });

    test('password fields are never copied', () {
      final password = form.TextField.password(id: 'pw');
      expect(codecFor(password).copy(password, 'secret'), isNull);

      final obscured = form.TextField(id: 'pw2', password: true);
      expect(codecFor(obscured).copy(obscured, 'secret'), isNull);
    });
  });

  group('OptionSelect family', () {
    test('checkbox fields list every option with tick glyphs', () {
      final field = form.CheckboxSelect(id: 'fruit', options: options);
      final codec = codecFor(field);
      final fragment = codec.copy(field, [options[0], options[2]])!;

      expect(fragment.plainText, '☑ Apple\n☐ Banana\n☑ Cherry');
      expect(
        fragment.html,
        '<ul><li>☑ Apple</li><li>☐ Banana</li><li>☑ Cherry</li></ul>',
      );
      expect(fragment.data, {
        'type': 'checkboxSelect',
        'value': ['a', 'c'],
      });
      expect(codec.paste(viaJson(fragment)), ['a', 'c']);
    });

    test('chip fields are checklists too', () {
      final field = form.ChipSelect(id: 'chips', options: options);
      final fragment = codecFor(field).copy(field, [options[1]])!;
      expect(fragment.plainText, '☐ Apple\n☑ Banana\n☐ Cherry');
      expect(fragment.type, 'chipSelect');
    });

    test('dropdowns and radios copy just the selected label', () {
      final dropdown = form.OptionSelect(id: 'dd', options: options);
      final dd = codecFor(dropdown).copy(dropdown, [options[1]])!;
      expect(dd.plainText, 'Banana');
      expect(dd.html, '<span>Banana</span>');
      expect(dd.data, {
        'type': 'optionSelect',
        'value': ['b'],
      });

      final radio = form.RadioSelect(id: 'r', options: options);
      final r = codecFor(radio).copy(radio, [options[2]])!;
      expect(r.plainText, 'Cherry');
      expect(r.type, 'radioSelect');
    });

    test('labels are HTML-escaped', () {
      final field = form.CheckboxSelect(
        id: 'x',
        options: [form.FieldOption(value: 'v', label: '<b>Bold</b> & co')],
      );
      final fragment = codecFor(field).copy(field, <form.FieldOption>[])!;
      expect(
        fragment.html,
        '<ul><li>☐ &lt;b&gt;Bold&lt;/b&gt; &amp; co</li></ul>',
      );
    });

    test('paste values restore through optionsFor into the controller', () {
      final controller = form.FormController();
      addTearDown(controller.dispose);
      final field = form.CheckboxSelect(
        id: 'fruit',
        options: options,
        multiselect: true,
      );
      controller.addFields([field]);

      final codec = codecFor(field);
      final fragment = codec.copy(field, [options[0], options[2]])!;
      final values = codec.paste(viaJson(fragment)) as List<String>;

      final restored = form.OptionSelectClipboardCodec.optionsFor(field, [
        ...values,
        'not-an-option',
        'a',
      ]);
      expect(restored, [options[0], options[2]]);

      controller.updateMultiselectValues(field.id, restored, overwrite: true);
      expect(controller.getMultiselectValue('fruit')!.map((o) => o.value), [
        'a',
        'c',
      ]);
    });

    test('optionsFor keeps one option for a single-select field', () {
      final field = form.OptionSelect(id: 'dd', options: options);
      expect(form.OptionSelectClipboardCodec.optionsFor(field, ['c', 'a']), [
        options[2],
      ]);
    });
  });

  group('FileUpload', () {
    final file = form.FileModel(
      fileName: 'report <final>.pdf',
      fileBytes: Uint8List.fromList(List.filled(42, 7)),
      mimeData: MimeData(mime: 'application/pdf', extension: 'pdf'),
    );
    final picked = [
      form.FieldOption(
        value: 'uuid-1',
        label: file.fileName,
        additionalData: file,
      ),
      form.FieldOption(value: 'uuid-2', label: 'notes.txt'),
    ];

    test('copies names and metadata, never bytes, and round-trips', () {
      final field = form.FileUpload(id: 'docs', multiselect: true);
      final codec = codecFor(field);
      expect(codec, isA<form.FileUploadClipboardCodec>());

      final fragment = codec.copy(field, picked)!;
      expect(fragment.plainText, 'report <final>.pdf\nnotes.txt');
      expect(
        fragment.html,
        '<ul><li>report &lt;final&gt;.pdf</li><li>notes.txt</li></ul>',
      );
      final metadata = [
        {
          'name': 'report <final>.pdf',
          'mimeType': 'application/pdf',
          'size': 42,
        },
        {'name': 'notes.txt', 'mimeType': null, 'size': null},
      ];
      expect(fragment.data, {'type': 'fileUpload', 'value': metadata});
      expect(jsonEncode(fragment.toJson()), isNot(contains('fileBytes')));
      expect(codec.paste(viaJson(fragment)), metadata);
    });
  });

  group('Compound fields', () {
    test('NameField copies the joined value and round-trips sub-fields', () {
      final controller = form.FormController();
      addTearDown(controller.dispose);
      final field = form.NameField(id: 'person');
      controller.addFields(form.FieldView.fieldsToRegister(field));
      controller.updateFieldValue<String>('person_firstname', 'Ada');
      controller.updateFieldValue<String>('person_lastname', 'Lovelace');

      final codec = codecFor(field);
      expect(codec, isA<form.CompoundClipboardCodec>());

      final value = form.CompoundClipboardCodec.valueFrom(controller, field);
      expect(value, {
        'firstname': 'Ada',
        'middlename': '',
        'lastname': 'Lovelace',
      });

      final fragment = codec.copy(field, value)!;
      // What results.grab('person').asCompound() produces.
      expect(fragment.plainText, 'Ada, Lovelace');
      expect(fragment.type, 'name');

      final pasted = codec.paste(viaJson(fragment)) as Map<String, String>;
      expect(pasted, value);

      // Restore into a fresh controller.
      final other = form.FormController();
      addTearDown(other.dispose);
      other.addFields(form.FieldView.fieldsToRegister(field));
      form.CompoundClipboardCodec.writeTo(other, field, {
        ...pasted,
        'unknown': 'ignored',
      });
      expect(other.getFieldValue<String>('person_firstname'), 'Ada');
      expect(other.getFieldValue<String>('person_lastname'), 'Lovelace');
      expect(other.hasFieldDefinition('person_unknown'), isFalse);
    });

    test('AddressField matches asCompound', () {
      final controller = form.FormController();
      addTearDown(controller.dispose);
      final field = form.AddressField(id: 'home');
      controller.addFields(form.FieldView.fieldsToRegister(field));
      controller.updateFieldValue<String>('home_street', '1 Main St');
      controller.updateFieldValue<String>('home_city', 'Springfield');
      controller.updateFieldValue<String>('home_zip', '12345');

      final fragment = codecFor(
        field,
      ).copy(field, form.CompoundClipboardCodec.valueFrom(controller, field))!;
      final results = form.FormResults.getResults(controller: controller);
      expect(fragment.plainText, results.grab('home').asCompound());
      expect(fragment.plainText, '1 Main St, Springfield, 12345');
      expect(fragment.type, 'address');
    });
  });

  group('Resolution', () {
    test('clipboardEnabled = false disables resolution entirely', () {
      final plain = form.TextField(id: 't');
      final overridden = form.TextField(
        id: 'o',
        clipboard: const TaggingCodec(),
      );
      expect(form.FormFieldRegistry.resolveClipboard(plain), isNotNull);

      FormFieldDefaults.instance.clipboardEnabled = false;
      expect(form.FormFieldRegistry.resolveClipboard(plain), isNull);
      expect(form.FormFieldRegistry.resolveClipboard(overridden), isNull);

      FormFieldDefaults.instance.reset();
      expect(FormFieldDefaults.instance.clipboardEnabled, isTrue);
    });

    test('a per-field codec beats the registry', () {
      final field = form.TextField(id: 't', clipboard: const TaggingCodec());
      final codec = form.FormFieldRegistry.resolveClipboard(field);
      expect(codec, isA<TaggingCodec>());
      expect(codec!.copy(field, 'x')!.plainText, 'tagged:x');
    });

    test('copyWith carries the per-field codec on every built-in field', () {
      const codec = TaggingCodec();
      final fields = <form.Field>[
        form.TextField(id: 'a', clipboard: codec),
        form.TextField.email(id: 'b', clipboard: codec),
        form.OptionSelect(id: 'c', clipboard: codec),
        form.CheckboxSelect(id: 'd', options: options, clipboard: codec),
        form.ChipSelect(id: 'e', options: options, clipboard: codec),
        form.RadioSelect(id: 'f', options: options, clipboard: codec),
        form.FileUpload(id: 'g', clipboard: codec),
        form.NameField(id: 'h', clipboard: codec),
        form.AddressField(id: 'i', clipboard: codec),
      ];
      for (final field in fields) {
        expect(
          field.clipboard,
          same(codec),
          reason: field.runtimeType.toString(),
        );
        expect(
          field.copyWith(id: 'copy').clipboard,
          same(codec),
          reason: '${field.runtimeType}.copyWith',
        );
      }
    });

    test(
      'registerClipboardCodec and register(clipboard:) set type defaults',
      () {
        final field = LegacyRatingField(id: 'stars');
        expect(form.FormFieldRegistry.clipboardFor(LegacyRatingField), isNull);
        expect(form.FormFieldRegistry.resolveClipboard(field), isNull);

        form.FormFieldRegistry.registerClipboardCodec<LegacyRatingField>(
          const TaggingCodec(),
        );
        expect(
          form.FormFieldRegistry.resolveClipboard(field),
          isA<TaggingCodec>(),
        );

        form.FormFieldRegistry.register<LegacyRatingField>(
          'legacyRating',
          (ctx) => const SizedBox(),
          clipboard: const form.TextFieldClipboardCodec(),
        );
        expect(
          form.FormFieldRegistry.clipboardFor(LegacyRatingField),
          isA<form.TextFieldClipboardCodec>(),
        );
        expect(
          form.FormFieldRegistry.resolveClipboard(
            field,
          )!.copy(field, '4')!.data,
          {'type': 'legacyRating', 'value': '4'},
        );
      },
    );
  });

  group('Legacy custom fields (non-breaking)', () {
    test('a custom Field without clipboard support compiles and works', () {
      final field = LegacyRatingField(id: 'rating', title: 'Rating');
      expect(field.clipboard, isNull);

      final copy = field.copyWith(id: 'rating2', stars: 3);
      expect(copy.id, 'rating2');
      expect(copy.stars, 3);
      expect(copy.clipboard, isNull);

      final controller = form.FormController();
      addTearDown(controller.dispose);
      controller.addFields([field]);
      controller.updateFieldValue<String>('rating', '4');
      expect(
        form.FormResults.getResults(
          controller: controller,
        ).grab('rating').asString(),
        '4',
      );
    });
  });

  group('Hostile paste input', () {
    final garbage = <Map<String, dynamic>>[
      {},
      {'type': 1, 'value': 'x'},
      {'value': 'no type'},
      {'type': 'textField'},
      {'type': 'textField', 'value': 42},
      {
        'type': 'textField',
        'value': ['list'],
      },
      {'type': 'optionSelect', 'value': 'not a list'},
      {
        'type': 'optionSelect',
        'value': [1, 2],
      },
      {
        'type': 'optionSelect',
        'value': ['a', null],
      },
      {
        'type': 'fileUpload',
        'value': [
          {'name': 5},
        ],
      },
      {
        'type': 'fileUpload',
        'value': ['name'],
      },
      {
        'type': 'fileUpload',
        'value': [
          {'name': 'a', 'size': -1},
        ],
      },
      {
        'type': 'fileUpload',
        'value': [
          {'name': 'a', 'size': 'big'},
        ],
      },
      {
        'type': 'fileUpload',
        'value': [
          {'name': 'a', 'mimeType': 3},
        ],
      },
      {
        'type': 'name',
        'value': ['not', 'a', 'map'],
      },
      {
        'type': 'name',
        'value': {'firstname': 1},
      },
      {
        'type': 'name',
        'value': {1: 'x'},
      },
      ExplodingMap(),
    ];

    const codecs = <form.FieldClipboardCodec>[
      form.TextFieldClipboardCodec(),
      form.OptionSelectClipboardCodec(),
      form.FileUploadClipboardCodec(),
      form.CompoundClipboardCodec(),
    ];

    test('returns null and never throws', () {
      for (final codec in codecs) {
        for (var i = 0; i < garbage.length; i++) {
          final data = garbage[i];
          final why = '${codec.runtimeType} on garbage[$i]';
          // Maps that happen to be well-formed for a *different* codec may
          // legitimately decode (a list of strings is a valid option value);
          // what matters is that nothing throws and garbage yields null.
          late Object? result;
          expect(
            () => result = codec.paste(data),
            returnsNormally,
            reason: why,
          );
          if (data is ExplodingMap || data.isEmpty || data['type'] is! String) {
            expect(result, isNull, reason: why);
          }
        }
      }
    });

    test('each codec rejects the others\' shapes where they differ', () {
      expect(
        const form.TextFieldClipboardCodec().paste({
          'type': 'optionSelect',
          'value': ['a'],
        }),
        isNull,
      );
      expect(
        const form.OptionSelectClipboardCodec().paste({
          'type': 'textField',
          'value': 'a',
        }),
        isNull,
      );
      expect(
        const form.FileUploadClipboardCodec().paste({
          'type': 'optionSelect',
          'value': ['a'],
        }),
        isNull,
      );
      expect(
        const form.CompoundClipboardCodec().paste({
          'type': 'textField',
          'value': 'a',
        }),
        isNull,
      );
    });

    test('codecs refuse to copy for the wrong field type', () {
      final text = form.TextField(id: 't');
      expect(const form.OptionSelectClipboardCodec().copy(text, 'x'), isNull);
      expect(const form.FileUploadClipboardCodec().copy(text, 'x'), isNull);
      expect(const form.CompoundClipboardCodec().copy(text, 'x'), isNull);
    });
  });
}

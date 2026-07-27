import 'package:championforms/championforms.dart' as cf;
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/core/validator_registry.dart';
import 'package:championforms/models/field_condition.dart';
import 'package:championforms/models/named_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A field type whose only purpose is to prove a custom factory works.
class _RatingField extends cf.TextField {
  _RatingField({required super.id, required this.stars, super.title});

  final int stars;

  static _RatingField fromJson(Map<String, dynamic> json) => _RatingField(
        id: json['id'] as String,
        stars: json['stars'] as int? ?? 5,
        title: json['title'] as String?,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FormFieldRegistry.ensureInitialized();
    ValidatorRegistry.reset();
    ValidatorRegistry.ensureInitialized();
  });

  group('dispatch', () {
    test('every core type name decodes', () {
      for (final name in const [
        'textField',
        'text',
        'textarea',
        'email',
        'password',
        'tel',
        'url',
        'number',
        'optionSelect',
        'select',
        'checkboxSelect',
        'checkbox',
        'chipSelect',
        'chips',
      ]) {
        final field = FormFieldRegistry.fieldFromJson({
          'id': 'f',
          'type': name,
          if (name.contains('elect') || name.startsWith('chip') ||
              name == 'checkbox' || name == 'chips')
            'options': ['a', 'b'],
        });
        expect(field, isNotNull, reason: 'type "$name" did not decode');
        expect(field!.id, 'f');
      }
    });

    test('an unknown type returns null rather than throwing', () {
      // A document can outlive the build reading it. One unfamiliar field must
      // not take the whole form down.
      expect(
        FormFieldRegistry.fieldFromJson({'id': 'f', 'type': 'hologram'}),
        isNull,
      );
      expect(FormFieldRegistry.fieldFromJson({'id': 'f'}), isNull);
      expect(FormFieldRegistry.hasFromJsonFor('hologram'), isFalse);
    });

    test('a malformed recognised field throws', () {
      // Unfamiliar and malformed are different problems and get different
      // answers: null for the first, an exception for the second.
      expect(
        () => FormFieldRegistry.fieldFromJson({'type': 'text'}),
        throwsFormatException,
      );
      expect(
        () => FormFieldRegistry.fieldFromJson(
            {'id': 'f', 'type': 'text', 'validators': 3}),
        throwsFormatException,
      );
      expect(
        () => FormFieldRegistry.fieldFromJson(
            {'id': 'f', 'type': 'text', 'title': 7}),
        throwsFormatException,
      );
    });

    test('fieldFromJsonNamed decodes without a type key', () {
      final field =
          FormFieldRegistry.fieldFromJsonNamed('text', {'id': 'f'});
      expect(field, isA<cf.TextField>());
    });

    test('an alias does not steal the canonical name', () {
      // `nameForType` must keep answering with one stable string, or
      // serializing a field would produce whichever alias registered last.
      expect(FormFieldRegistry.nameForType(cf.TextField), 'textField');
      expect(FormFieldRegistry.typeForName('email'), cf.TextField);
      expect(FormFieldRegistry.typeForName('textField'), cf.TextField);
    });
  });

  group('TextField.fromJson', () {
    test('reads the base properties', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 'notes',
        'type': 'textarea',
        'title': 'Notes',
        'description': 'Anything else?',
        'hintText': 'Optional',
        'maxLength': 500,
        'defaultValue': 'hello',
        'disabled': true,
        'requestFocus': true,
        'validateLive': true,
      }) as cf.TextField;

      expect(field.title, 'Notes');
      expect(field.description, 'Anything else?');
      expect(field.hintText, 'Optional');
      expect(field.maxLength, 500);
      expect(field.defaultValue, 'hello');
      expect(field.disabled, isTrue);
      expect(field.requestFocus, isTrue);
      expect(field.validateLive, isTrue);
      // A textarea's height is a property of the type, not something every
      // document has to remember.
      expect(field.maxLines, 5);
    });

    test('an explicit maxLines beats the type default', () {
      final field = FormFieldRegistry.fieldFromJson(
          {'id': 'n', 'type': 'textarea', 'maxLines': 2}) as cf.TextField;
      expect(field.maxLines, 2);
    });

    test('the semantic types configure their keyboards and hints', () {
      final email = FormFieldRegistry.fieldFromJson(
          {'id': 'e', 'type': 'email'}) as cf.TextField;
      expect(email.keyboardType, TextInputType.emailAddress);
      expect(email.autofillHints, contains(AutofillHints.email));
      expect(email.password, isFalse);

      final password = FormFieldRegistry.fieldFromJson(
          {'id': 'p', 'type': 'password'}) as cf.TextField;
      expect(password.password, isTrue);

      final tel = FormFieldRegistry.fieldFromJson(
          {'id': 't', 'type': 'tel'}) as cf.TextField;
      expect(tel.keyboardType, TextInputType.phone);

      final url = FormFieldRegistry.fieldFromJson(
          {'id': 'u', 'type': 'url'}) as cf.TextField;
      expect(url.keyboardType, TextInputType.url);

      final number = FormFieldRegistry.fieldFromJson(
          {'id': 'n', 'type': 'number'}) as cf.TextField;
      expect(number.keyboardType!.decimal, isTrue);
    });

    test('a non-string defaultValue is coerced rather than refused', () {
      final field = FormFieldRegistry.fieldFromJson(
          {'id': 'n', 'type': 'number', 'defaultValue': 42}) as cf.TextField;
      expect(field.defaultValue, '42');
    });

    test('an integer that survived a JavaScript round trip is accepted', () {
      final field = FormFieldRegistry.fieldFromJson(
          {'id': 'n', 'type': 'text', 'maxLength': 500.0}) as cf.TextField;
      expect(field.maxLength, 500);
    });

    test('unrecognised keys are ignored, not rejected', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 'f',
        'type': 'text',
        'somethingFromTheFuture': {'nested': true},
      });
      expect(field, isNotNull);
    });
  });

  group('validators', () {
    test('a bare string is a validator that takes no parameters', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 'e',
        'type': 'email',
        'validators': ['required', 'email'],
      })!;
      expect(field.validators, hasLength(2));
      expect(field.validators!.first.validator(''), isFalse);
      expect(field.validators!.first.reason, 'is required');
    });

    test('the object form carries params through', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 'e',
        'type': 'email',
        'validators': [
          {
            'name': 'maxLength',
            'params': {'max': 254},
          },
        ],
      })!;
      final validator = field.validators!.single;
      expect(validator.validator('a' * 255), isFalse);
      expect(validator.validator('a' * 254), isTrue);
      expect(validator.reason, 'must be at most 254 characters');
    });

    test('an absent validators key is null, not an empty list', () {
      final field =
          FormFieldRegistry.fieldFromJson({'id': 'e', 'type': 'text'})!;
      expect(field.validators, isNull);
    });

    test('an unknown validator name throws rather than vanishing', () {
      // A rule that silently disappears stops protecting the data it was
      // written for, and the failure shows up as bad rows rather than an error.
      expect(
        () => FormFieldRegistry.fieldFromJson({
          'id': 'e',
          'type': 'text',
          'validators': ['nonesuch'],
        }),
        throwsA(isA<UnknownValidatorException>()),
      );
    });
  });

  group('selection fields', () {
    test('options accept both the bare and the object form', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 's',
        'type': 'select',
        'options': [
          'weekly',
          {'value': 'monthly', 'label': 'Once a month', 'hintText': 'Slower'},
        ],
      }) as cf.OptionSelect;

      expect(field.options, hasLength(2));
      expect(field.options![0].value, 'weekly');
      expect(field.options![0].label, 'weekly');
      expect(field.options![1].label, 'Once a month');
      expect(field.options![1].hintText, 'Slower');
    });

    test('defaultValue resolves against options and drops unknown values', () {
      // An option removed from the document since the value was stored must not
      // reappear as a selectable choice just because something once picked it.
      final field = FormFieldRegistry.fieldFromJson({
        'id': 's',
        'type': 'checkboxSelect',
        'options': ['a', 'b'],
        'defaultValue': ['a', 'gone'],
      }) as cf.CheckboxSelect;

      expect(field.defaultValue.map((o) => o.value), ['a']);
      expect(field.multiselect, isTrue);
    });

    test('a scalar defaultValue works for a single select', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 's',
        'type': 'select',
        'options': ['a', 'b'],
        'defaultValue': 'b',
      }) as cf.OptionSelect;
      expect(field.defaultValue.single.value, 'b');
    });

    test('checkbox is single-select and checkboxSelect is multi', () {
      final single = FormFieldRegistry.fieldFromJson({
        'id': 's',
        'type': 'checkbox',
        'options': ['a'],
      }) as cf.CheckboxSelect;
      expect(single.multiselect, isFalse);

      // An explicit flag wins either way.
      final forced = FormFieldRegistry.fieldFromJson({
        'id': 's',
        'type': 'checkbox',
        'options': ['a'],
        'multiselect': true,
      }) as cf.CheckboxSelect;
      expect(forced.multiselect, isTrue);
    });

    test('a malformed option throws', () {
      expect(
        () => FormFieldRegistry.fieldFromJson({
          'id': 's',
          'type': 'select',
          'options': [
            {'label': 'no value'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => FormFieldRegistry.fieldFromJson(
            {'id': 's', 'type': 'select', 'options': 'a,b'}),
        throwsFormatException,
      );
    });
  });

  group('conditional', () {
    test('decodes onto the field and evaluates', () {
      final field = FormFieldRegistry.fieldFromJson({
        'id': 'team_size',
        'type': 'number',
        'conditional': {
          'match': 'all',
          'action': 'show',
          'rules': [
            {'fieldId': 'role', 'operator': 'equals', 'value': 'team'},
          ],
        },
      })!;

      expect(field.conditional, isNotNull);
      expect(field.conditional!.isVisible({'role': 'team'}), isTrue);
      expect(field.conditional!.isVisible({'role': 'solo'}), isFalse);
    });

    test('a non-object conditional throws', () {
      expect(
        () => FormFieldRegistry.fieldFromJson(
            {'id': 'f', 'type': 'text', 'conditional': true}),
        throwsFormatException,
      );
    });
  });

  group('custom factories', () {
    test('a caller-registered factory is reachable by name', () {
      FormFieldRegistry.register<_RatingField>(
        'rating',
        (context) => const SizedBox.shrink(),
        fromJson: _RatingField.fromJson,
      );

      final field = FormFieldRegistry.fieldFromJson({
        'id': 'r',
        'type': 'rating',
        'stars': 3,
        'title': 'How was it?',
      });

      expect(field, isA<_RatingField>());
      expect((field! as _RatingField).stars, 3);
      expect(field.title, 'How was it?');
      expect(FormFieldRegistry.decodableTypeNames, contains('rating'));
    });

    test('a type may be renderable without being decodable', () {
      FormFieldRegistry.register<_UndecodableField>(
        'undecodable',
        (context) => const SizedBox.shrink(),
      );
      expect(FormFieldRegistry.hasBuilderForName('undecodable'), isTrue);
      expect(FormFieldRegistry.hasFromJsonFor('undecodable'), isFalse);
      expect(
        FormFieldRegistry.fieldFromJson({'id': 'x', 'type': 'undecodable'}),
        isNull,
      );
    });
  });

  group('a decoded field is a real field', () {
    testWidgets('it renders and validates in a Form', (tester) async {
      final controller = cf.FormController();
      final fields = <cf.FormElement>[
        FormFieldRegistry.fieldFromJson({'id': 'role', 'type': 'text'})!,
        FormFieldRegistry.fieldFromJson({
          'id': 'email',
          'type': 'email',
          'title': 'Email',
          'validators': ['required', 'email'],
          'conditional': {
            'rules': [
              {'fieldId': 'role', 'operator': 'isNotEmpty'},
            ],
          },
        })!,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(controller: controller, fields: fields),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hidden, so its `required` must not fail the form.
      expect(find.text('Email'), findsNothing);
      expect(cf.FormResults.getResults(controller: controller).errorState, isFalse);

      controller.updateFieldValue('role', 'creator');
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(cf.FormResults.getResults(controller: controller).errorState, isTrue);

      controller.updateFieldValue('email', 'a@b.com');
      await tester.pumpAndSettle();
      expect(cf.FormResults.getResults(controller: controller).errorState, isFalse);
      await tester.pumpAndSettle();
    });
  });
}

/// Renderable, not decodable — the normal state for a custom field whose
/// author has not needed serialization.
class _UndecodableField extends cf.TextField {
  _UndecodableField({required super.id});
}

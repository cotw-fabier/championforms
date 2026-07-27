import 'package:championforms/core/validator_registry.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/named_validator.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the validator registered under [name] against [value].
bool _check(String name, dynamic value, {Map<String, dynamic> params = const {}}) {
  final validator = ValidatorRegistry.resolve(name, params: params);
  expect(validator, isNotNull, reason: '"$name" is not registered');
  return validator!.validator(value);
}

void main() {
  setUp(() {
    ValidatorRegistry.reset();
    ValidatorRegistry.ensureInitialized();
  });

  group('registry mechanics', () {
    test('ensureInitialized is idempotent', () {
      final before = ValidatorRegistry.registeredNames.length;
      ValidatorRegistry.ensureInitialized();
      expect(ValidatorRegistry.registeredNames.length, before);
    });

    test('an unregistered name resolves to null', () {
      expect(ValidatorRegistry.resolve('nope'), isNull);
      expect(ValidatorRegistry.hasValidator('nope'), isFalse);
    });

    test('a custom validator is resolvable and receives its params', () {
      ValidatorRegistry.register(
        'divisibleBy',
        (params) => Validator(
          validator: (value) =>
              (int.tryParse('$value') ?? 1) % (params['by'] as int) == 0,
          reason: 'must divide by ${params['by']}',
        ),
      );

      expect(_check('divisibleBy', '9', params: {'by': 3}), isTrue);
      expect(_check('divisibleBy', '10', params: {'by': 3}), isFalse);
      expect(
        ValidatorRegistry.resolve('divisibleBy', params: {'by': 3})!.reason,
        'must divide by 3',
      );
    });

    test('a built-in can be overridden', () {
      ValidatorRegistry.register(
        'required',
        (params) => Validator(validator: (_) => true, reason: 'never fails'),
      );
      expect(_check('required', null), isTrue);
    });
  });

  group('built-ins', () {
    test('required rejects null, blank and empty collections', () {
      expect(_check('required', null), isFalse);
      expect(_check('required', ''), isFalse);
      expect(_check('required', '   '), isFalse);
      expect(_check('required', <String>[]), isFalse);
      expect(_check('required', false), isFalse);
      expect(_check('required', 'a'), isTrue);
      expect(_check('required', ['a']), isTrue);
      expect(_check('required', 0), isTrue);
    });

    test('email', () {
      expect(_check('email', 'a@b.com'), isTrue);
      expect(_check('email', 'nope'), isFalse);
      // Blank passes; `required` is what makes a field mandatory. Otherwise
      // every optional email field would be impossible to leave empty.
      expect(_check('email', ''), isTrue);
    });

    test('url accepts absolute http(s) only', () {
      expect(_check('url', 'https://example.com/x'), isTrue);
      expect(_check('url', 'http://example.com'), isTrue);
      expect(_check('url', 'example.com'), isFalse);
      expect(_check('url', 'ftp://example.com'), isFalse);
      expect(_check('url', 'not a url'), isFalse);
      expect(_check('url', ''), isTrue);
    });

    test('tel accepts the shapes people actually type', () {
      expect(_check('tel', '+1 (555) 010-9999'), isTrue);
      expect(_check('tel', '5550109999'), isTrue);
      expect(_check('tel', '555'), isFalse);
      expect(_check('tel', '+1234567890123456'), isFalse);
      expect(_check('tel', 'call me'), isFalse);
      expect(_check('tel', ''), isTrue);
    });

    test('minLength / maxLength / lengthRange', () {
      expect(_check('minLength', 'abc', params: {'min': 3}), isTrue);
      expect(_check('minLength', 'ab', params: {'min': 3}), isFalse);
      expect(_check('maxLength', 'abcd', params: {'max': 3}), isFalse);
      expect(_check('maxLength', 'abc', params: {'max': 3}), isTrue);
      expect(
        _check('lengthRange', 'abcd', params: {'min': 2, 'max': 5}),
        isTrue,
      );
    });

    test('min / max coerce the way a text field and JSON both deliver', () {
      // A number field hands back a String; a JSON round trip hands back 2.0.
      expect(_check('min', '5', params: {'min': 2}), isTrue);
      expect(_check('min', '1', params: {'min': 2.0}), isFalse);
      expect(_check('max', 5, params: {'max': 4}), isFalse);
      expect(_check('max', 4.0, params: {'max': 4}), isTrue);
      // Blank defers to `required`.
      expect(_check('min', '', params: {'min': 2}), isTrue);
    });

    test('min reports the constraint in its reason', () {
      expect(
        ValidatorRegistry.resolve('min', params: {'min': 2})!.reason,
        'must be at least 2',
      );
      expect(
        ValidatorRegistry.resolve('maxLength', params: {'max': 254})!.reason,
        'must be at most 254 characters',
      );
    });

    test('a caller-supplied reason wins', () {
      expect(
        ValidatorRegistry.resolve(
          'required',
          params: {'reason': 'We need this to email you.'},
        )!
            .reason,
        'We need this to email you.',
      );
    });

    test('regex', () {
      expect(_check('regex', 'AB12', params: {'pattern': r'^[A-Z]{2}\d{2}$'}),
          isTrue);
      expect(_check('regex', 'ab12', params: {'pattern': r'^[A-Z]{2}\d{2}$'}),
          isFalse);
      expect(_check('regex', '', params: {'pattern': r'^\d+$'}), isTrue);
    });

    test('oneOf reaches through FieldOption and checks every list member', () {
      const params = {
        'values': ['a', 'b'],
      };
      expect(_check('oneOf', 'a', params: params), isTrue);
      expect(_check('oneOf', 'c', params: params), isFalse);
      expect(_check('oneOf', FieldOption(value: 'b'), params: params), isTrue);
      expect(
        _check('oneOf', [FieldOption(value: 'a'), FieldOption(value: 'b')],
            params: params),
        isTrue,
      );
      // The second member is not allowed — a check of only the first would
      // let an injected option through.
      expect(
        _check('oneOf', [FieldOption(value: 'a'), FieldOption(value: 'z')],
            params: params),
        isFalse,
      );
    });
  });

  group('NamedValidator', () {
    test('round-trips through JSON', () {
      const rule = NamedValidator('maxLength', params: {'max': 254});
      expect(rule.toJson(), {
        'name': 'maxLength',
        'params': {'max': 254},
      });
      expect(NamedValidator.fromJson(rule.toJson()), rule);
    });

    test('omits empty params', () {
      expect(const NamedValidator('required').toJson(), {'name': 'required'});
    });

    test('resolves to a working Validator', () {
      final validator =
          const NamedValidator('minLength', params: {'min': 3}).resolve();
      expect(validator.validator('abc'), isTrue);
      expect(validator.validator('ab'), isFalse);
      expect(validator.reason, 'must be at least 3 characters');
    });

    test('resolveAll preserves order', () {
      final resolved = NamedValidator.resolveAll(const [
        NamedValidator('required'),
        NamedValidator('email'),
      ]);
      expect(resolved, hasLength(2));
      expect(resolved.first.reason, 'is required');
      expect(resolved.last.reason, 'must be a valid email address');
    });

    test('an unknown name throws, and the message lists what is registered',
        () {
      expect(
        () => const NamedValidator('creditCard').resolve(),
        throwsA(
          isA<UnknownValidatorException>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('creditCard'), contains('required')),
          ),
        ),
      );
    });

    test('fromJson rejects a missing or non-string name', () {
      expect(() => NamedValidator.fromJson({}), throwsFormatException);
      expect(() => NamedValidator.fromJson({'name': 7}), throwsFormatException);
      expect(
        () => NamedValidator.fromJson({'name': 'x', 'params': 'nope'}),
        throwsFormatException,
      );
    });
  });
}

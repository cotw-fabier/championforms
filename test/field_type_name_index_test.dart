import 'package:championforms/championforms.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A field type that exists only for these tests.
class _IndexProbeField extends TextField {
  _IndexProbeField({required super.id});
}

class _OtherProbeField extends TextField {
  _OtherProbeField({required super.id});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('typeName <-> Type index', () {
    setUp(FormFieldRegistry.ensureInitialized);

    test('ensureInitialized registers the core builders exactly once', () {
      FormFieldRegistry.ensureInitialized();
      expect(FormFieldRegistry.instance.isInitialized, isTrue);
      // Idempotent: a second call must not throw and must not lose the index.
      FormFieldRegistry.ensureInitialized();
      expect(FormFieldRegistry.typeForName('textField'), TextField);
    });

    test('every core field type is reachable from its registered name', () {
      expect(FormFieldRegistry.typeForName('textField'), TextField);
      expect(FormFieldRegistry.typeForName('optionSelect'), OptionSelect);
      expect(FormFieldRegistry.typeForName('checkboxSelect'), CheckboxSelect);
      expect(FormFieldRegistry.typeForName('chipSelect'), ChipSelect);
      expect(FormFieldRegistry.typeForName('fileUpload'), FileUpload);
    });

    test('compound field types are indexed too', () {
      expect(FormFieldRegistry.typeForName('name'), NameField);
      expect(FormFieldRegistry.typeForName('address'), AddressField);
    });

    test('every registered name resolves, and its type has a canonical name',
        () {
      // Not a strict inverse: aliases mean several names can share a type
      // (`email` and `textField` are both `TextField`). What must hold is that
      // every name resolves, and that every type has exactly one canonical
      // name which itself round-trips — otherwise serializing a field would
      // produce whichever alias registered last.
      for (final name in FormFieldRegistry.registeredTypeNames.toList()) {
        final type = FormFieldRegistry.typeForName(name);
        expect(type, isNotNull, reason: 'no type for registered name $name');

        final canonical = FormFieldRegistry.nameForType(type!);
        expect(canonical, isNotNull,
            reason: '$type (reached via "$name") has no canonical name');
        expect(FormFieldRegistry.typeForName(canonical!), type);
      }
    });

    test('an unregistered name resolves to null rather than throwing', () {
      expect(FormFieldRegistry.typeForName('definitelyNotAField'), isNull);
      expect(FormFieldRegistry.hasBuilderForName('definitelyNotAField'), isFalse);
    });

    test('hasBuilderForName agrees with hasBuilderFor', () {
      expect(FormFieldRegistry.hasBuilderForName('textField'), isTrue);
      expect(FormFieldRegistry.hasBuilderFor<TextField>(), isTrue);
    });

    test('registering a custom type makes it resolvable by name', () {
      FormFieldRegistry.register<_IndexProbeField>(
        'indexProbe',
        (context) => const SizedBox.shrink(),
      );

      expect(FormFieldRegistry.typeForName('indexProbe'), _IndexProbeField);
      expect(FormFieldRegistry.nameForType(_IndexProbeField), 'indexProbe');
      expect(
        FormFieldRegistry.registeredTypeNames,
        contains('indexProbe'),
      );
    });

    test('re-registering a type under a new name drops the old name', () {
      FormFieldRegistry.register<_OtherProbeField>(
        'firstName',
        (context) => const SizedBox.shrink(),
      );
      expect(FormFieldRegistry.typeForName('firstName'), _OtherProbeField);

      FormFieldRegistry.register<_OtherProbeField>(
        'secondName',
        (context) => const SizedBox.shrink(),
      );

      // The stale name must not keep resolving — a document naming it would
      // otherwise decode to a type the caller has since renamed away from.
      expect(FormFieldRegistry.typeForName('firstName'), isNull);
      expect(FormFieldRegistry.typeForName('secondName'), _OtherProbeField);
      expect(FormFieldRegistry.nameForType(_OtherProbeField), 'secondName');
    });
  });
}

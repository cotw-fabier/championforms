import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

EmbeddedFieldNode _node(String id, Map<String, dynamic> json) =>
    EmbeddedFieldNode(id: id, fieldJson: json);

const _gate = form.FieldCondition(
  rules: [
    form.ConditionRule(
      fieldId: 'gate',
      operator: form.ConditionOperator.equals,
      value: 'open',
    ),
  ],
);

void main() {
  setUpAll(() {
    form.FormFieldRegistry.ensureInitialized();
    form.ValidatorRegistry.ensureInitialized();
  });

  late form.FormController controller;
  late EmbeddedFieldManager manager;

  setUp(() {
    controller = form.FormController();
    manager = EmbeddedFieldManager(controller: controller, docId: 'doc');
  });
  tearDown(() => controller.dispose());

  test('new nodes are built from JSON under the derived id', () {
    manager.sync([
      _node('a', {'type': 'text', 'title': 'A', 'id': 'ignored'}),
      _node('b', {
        'type': 'select',
        'options': ['x', 'y'],
      }),
    ]);
    expect(controller.hasFieldDefinition('doc.field.a'), isTrue);
    expect(controller.hasFieldDefinition('doc.field.b'), isTrue);
    expect(controller.hasFieldDefinition('ignored'), isFalse);
    expect(manager.fieldFor('a'), isA<form.TextField>());
    expect(manager.fieldFor('a')!.title, 'A');
    expect(manager.fieldFor('b'), isA<form.OptionSelect>());
  });

  test('removed nodes are explicitly unregistered and leave the results', () {
    manager.sync([
      _node('a', {'type': 'text'}),
      _node('b', {'type': 'text'}),
    ]);
    controller.updateFieldValue<String>('doc.field.b', 'kept');
    expect(
      manager.sync([
        _node('a', {'type': 'text'}),
      ]),
      isTrue,
    );
    expect(controller.hasFieldDefinition('doc.field.b'), isFalse);
    final results = form.FormResults.getResults(controller: controller);
    expect(results.results.keys, ['doc.field.a']);
    // Values are kept, so an undo restores them.
    manager.sync([
      _node('a', {'type': 'text'}),
      _node('b', {'type': 'text'}),
    ]);
    expect(controller.getFieldValue<String>('doc.field.b'), 'kept');
  });

  test('an unchanged sync does nothing; a changed definition re-registers', () {
    manager.sync([
      _node('a', {'type': 'text', 'title': 'One'}),
    ]);
    expect(
      manager.sync([
        _node('a', {'type': 'text', 'title': 'One'}),
      ]),
      isFalse,
    );
    expect(
      manager.sync([
        _node('a', {'type': 'text', 'title': 'Two'}),
      ]),
      isTrue,
    );
    expect(manager.fieldFor('a')!.title, 'Two');
    expect(controller.hasFieldDefinition('doc.field.a'), isTrue);
  });

  test('an unknown type is unsupported, not registered, not a crash', () {
    manager.sync([
      _node('x', {'type': 'hologram'}),
      _node('y', {'title': 'no type'}),
      _node('z', {'type': 'text', 'validators': 5}),
    ]);
    expect(controller.registeredFieldIds, isEmpty);
    expect(manager.unsupportedReason('x'), contains('hologram'));
    expect(manager.unsupportedReason('y'), isNotNull);
    expect(manager.unsupportedReason('z'), startsWith('Invalid field block'));
  });

  test('compound fields register their sub-fields too', () {
    manager.sync([
      _node('n', {'type': 'name'}),
    ]);
    expect(controller.hasFieldDefinition('doc.field.n'), isTrue);
    expect(
      controller.registeredFieldIds.where(
        (id) => id.startsWith('doc.field.n_'),
      ),
      isNotEmpty,
    );
    manager.sync(const []);
    expect(controller.registeredFieldIds, isEmpty);
  });

  test('blocks inherit disabled, hidden, theme and conditional', () {
    final theme = form.FormTheme();
    manager.setInheritance(
      EmbeddedFieldInheritance(
        disabled: true,
        hideField: true,
        conditional: _gate,
        theme: theme,
      ),
    );
    manager.sync([
      _node('a', {'type': 'text'}),
    ]);
    final field = manager.fieldFor('a')!;
    expect(field.disabled, isTrue);
    expect(field.hideField, isTrue);
    expect(field.theme, same(theme));
    expect(field.conditional, same(_gate));
  });

  test('changing the inheritance re-registers the blocks', () {
    manager.sync([
      _node('a', {'type': 'text'}),
    ]);
    expect(controller.isFieldIdHidden('doc.field.a'), isFalse);
    manager.setInheritance(const EmbeddedFieldInheritance(hideField: true));
    expect(controller.isFieldIdHidden('doc.field.a'), isTrue);
    final results = form.FormResults.getResults(controller: controller);
    expect(results.results, isEmpty);
  });

  test('conditions combine', () {
    const own = form.FieldCondition(
      rules: [
        form.ConditionRule(
          fieldId: 'other',
          operator: form.ConditionOperator.isNotEmpty,
        ),
      ],
    );
    final merged = EmbeddedFieldManager.combineConditions(own, _gate)!;
    expect(merged.rules, hasLength(2));
    const anyHide = form.FieldCondition(
      match: form.ConditionMatch.any,
      action: form.ConditionAction.hide,
      rules: [],
    );
    expect(
      EmbeddedFieldManager.combineConditions(anyHide, _gate),
      same(_gate),
      reason: 'incompatible shapes: the parent wins',
    );
    expect(EmbeddedFieldManager.combineConditions(null, _gate), same(_gate));
    expect(EmbeddedFieldManager.combineConditions(own, null), same(own));
  });

  group('applyFieldValues', () {
    setUp(() {
      manager.sync([
        _node('t', {'type': 'text'}),
        _node('c', {
          'type': 'checkboxSelect',
          'multiselect': true,
          'options': ['a', 'b', 'c'],
        }),
        _node('f', {'type': 'fileUpload'}),
        _node('n', {'type': 'name'}),
      ]);
    });

    test('text, option values, compound maps', () {
      manager.applyFieldValues({
        't': 'hello',
        'c': ['c', 'a', 'zzz'],
        'n': {'firstname': 'Ada', 'lastname': 'Lovelace'},
      });
      expect(controller.getFieldValue<String>('doc.field.t'), 'hello');
      expect(
        controller
            .getFieldValue<List<form.FieldOption>>('doc.field.c')!
            .map((o) => o.value),
        ['c', 'a'],
      );
      expect(controller.getFieldValue<String>('doc.field.n_firstname'), 'Ada');
      expect(
        controller.getFieldValue<String>('doc.field.n_lastname'),
        'Lovelace',
      );
    });

    test('file metadata is skipped; live file options are restored', () {
      manager.applyFieldValues({
        'f': [
          {'name': 'a.pdf', 'mimeType': 'application/pdf', 'size': 3},
        ],
      });
      expect(
        controller.getFieldValueOrNull<List<form.FieldOption>>('doc.field.f') ??
            const [],
        isEmpty,
      );
      final live = [form.FieldOption(value: 'a.pdf', label: 'a.pdf')];
      manager.applyFieldValues({'f': live});
      expect(
        controller
            .getFieldValue<List<form.FieldOption>>('doc.field.f')!
            .single
            .value,
        'a.pdf',
      );
    });

    test('unknown nodes and ill-typed values are ignored', () {
      manager.applyFieldValues({'missing': 'x', 'c': 'not a list', 'n': 42});
      expect(
        controller.getFieldValueOrNull<Object>('doc.field.c'),
        anyOf(isNull, isEmpty),
      );
    });
  });
}

// Deliberately imports ONLY the public barrel. Every symbol named below has to
// be reachable from `package:championforms/championforms.dart` with no deep
// import into `models/` or `core/` — which is the whole assertion this file
// makes. A deep import here would defeat it silently.
import 'package:championforms/championforms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FormBuilderError is nameable from the barrel', () {
    // It was always *receivable* — `FormResults.formErrors` hands them out —
    // and never nameable, so anything that wanted to hold one in a typed
    // variable had to deep-import.
    const error = FormBuilderError(
      reason: 'is required',
      fieldId: 'email',
      validatorPosition: 0,
    );
    expect(error.reason, 'is required');
    expect(error.fieldId, 'email');

    final List<FormBuilderError> errors = [error];
    expect(errors, hasLength(1));
  });

  test('the results API hands back the exported type', () {
    final controller = FormController();
    controller.addFields([TextField(id: 'a')], noNotify: true);
    // `addError` takes the exported type positionally, which is itself the
    // point: naming the argument was impossible from the barrel before.
    controller.addError(const FormBuilderError(
      reason: 'nope',
      fieldId: 'a',
      validatorPosition: 0,
    ));

    final List<FormBuilderError> found = controller.findErrors('a');
    expect(found.single.reason, 'nope');
  });

  test('the serializable rule types are exported', () {
    const condition = FieldCondition(rules: [
      ConditionRule(
        fieldId: 'role',
        operator: ConditionOperator.equals,
        value: 'team',
      ),
    ]);
    expect(condition.isVisible({'role': 'team'}), isTrue);
    expect(ConditionMatch.all.name, 'all');
    expect(ConditionAction.hide.name, 'hide');

    ValidatorRegistry.ensureInitialized();
    const named = NamedValidator('minLength', params: {'min': 2});
    expect(named.resolve().validator('a'), isFalse);
    expect(() => const NamedValidator('nope').resolve(),
        throwsA(isA<UnknownValidatorException>()));
  });

  test('the JSON entry points are exported', () {
    FormFieldRegistry.ensureInitialized();
    ValidatorRegistry.ensureInitialized();

    final field = FormFieldRegistry.fieldFromJson({
      'id': 'email',
      'type': 'email',
      'title': 'Email',
      'validators': ['required'],
    });

    expect(field, isA<TextField>());
    expect(FieldJson.id({'id': 'x'}), 'x');
    expect(FormFieldRegistry.typeForName('email'), TextField);
  });
}

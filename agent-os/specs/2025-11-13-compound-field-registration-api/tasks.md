# Task Breakdown: Compound Field Registration API

## Overview
Total Tasks: 4 task groups with ~20-40 strategic tests expected
Assigned roles: api-engineer, ui-designer, testing-engineer
Tech stack: Flutter, Dart (>=3.0.5), ChampionForms package architecture

## Task List

### Phase 1: Core Architecture & Registration System

#### Task Group 1: Compound Field Base Classes and Registry Extension
**Assigned implementer:** api-engineer
**Dependencies:** None
**Complexity:** High - Core architectural changes

- [x] 1.0 Complete compound field architecture and registration system
  - [x] 1.1 Write 5-8 focused tests for CompoundField base class and registration
    - Test CompoundField instantiation with sub-field definitions
    - Test sub-field ID prefixing logic (pattern: `{compoundId}_{subFieldId}`)
    - Test FormFieldRegistry.registerCompound<T>() method registration
    - Test type safety with generic T extends CompoundField
    - Test registration lookup for compound fields
    - Test compound field builder storage and retrieval
    - Skip exhaustive edge cases and error scenarios
  - [x] 1.2 Create CompoundField base class
    - Extend Field abstract class from `/home/fabier/Documents/code/championforms/lib/models/field_types/formfieldclass.dart`
    - Add properties: `List<Field> Function(CompoundField) subFieldsBuilder`, `Widget Function(BuildContext, List<Widget>, List<FormBuilderError>?) layoutBuilder`, `bool rollUpErrors` (default: false)
    - Implement abstract method: `List<Field> buildSubFields()`
    - Follow existing Field pattern for properties: id, title, description, validators, disabled, theme
    - Add ID prefixing logic: `String _prefixSubFieldId(String compoundId, String subFieldId)`
    - Location: `/home/fabier/Documents/code/championforms/lib/models/field_types/compound_field.dart`
  - [x] 1.3 Create CompoundFieldRegistration data class
    - Properties: `String typeName`, `Function subFieldsBuilder`, `Function? layoutBuilder`, `bool rollUpErrors`, `FieldConverters? converters`
    - Purpose: Store compound field registration metadata
    - Location: `/home/fabier/Documents/code/championforms/lib/models/field_types/compound_field_registration.dart`
  - [x] 1.4 Extend FormFieldRegistry with registerCompound<T>() method
    - Add static method: `static void registerCompound<T extends CompoundField>(String typeName, List<Field> Function(T) subFieldsBuilder, Widget Function(BuildContext, List<Widget>, List<FormBuilderError>?)? layoutBuilder, {bool rollUpErrors = false, FieldConverters? converters})`
    - Create internal storage: `Map<Type, CompoundFieldRegistration> _compoundRegistrations = {}`
    - Add companion method: `static bool hasCompoundBuilderFor<T extends CompoundField>()`
    - Follow existing registration pattern from `/home/fabier/Documents/code/championforms/lib/core/field_builder_registry.dart`
    - Include debug output: `debugPrint('Registered compound field for type $T ($typeName)')`
  - [x] 1.5 Implement default vertical layout builder
    - Create function: `Widget _buildDefaultCompoundLayout(BuildContext context, List<Widget> subFields, List<FormBuilderError>? errors)`
    - Layout: Column with sub-fields vertically stacked, 10px spacing
    - Error display: If errors provided and rollUpErrors true, show errors at bottom in red text
    - Location: Add to compound_field.dart as static method
  - [x] 1.6 Ensure compound field architecture tests pass
    - Run ONLY the 5-8 tests written in 1.1
    - Verify CompoundField instantiation works
    - Verify registration and lookup work correctly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 5-8 tests written in 1.1 pass
- CompoundField base class extends Field with sub-field management
- FormFieldRegistry.registerCompound<T>() successfully registers compound fields
- Sub-field ID prefixing follows pattern: `{compoundId}_{subFieldId}`
- Default vertical layout builder stacks sub-fields with proper spacing

---

### Phase 2: Controller Integration & Sub-field Management

#### Task Group 2: Form Widget Integration and Sub-field Transparency
**Assigned implementer:** api-engineer
**Dependencies:** Task Group 1
**Complexity:** High - Integration with existing Form widget and FormController

- [x] 2.0 Complete Form widget integration and sub-field controller transparency
  - [x] 2.1 Write 6-8 focused tests for compound field controller integration
    - Test Form widget encounters CompoundField and generates sub-fields
    - Test sub-fields registered individually with FormController
    - Test controller methods work on sub-field IDs: getFieldValue(), updateFieldValue()
    - Test TextEditingController lifecycle management for sub-fields
    - Test FocusNode lifecycle management for sub-fields
    - Test theme propagation from compound field to sub-fields
    - Test disabled state propagation from compound field to sub-fields
    - Skip exhaustive testing of all controller methods
  - [x] 2.2 Extend Form widget to recognize and process CompoundField types
    - Modify form field building logic in `/home/fabier/Documents/code/championforms/widgets_internal/form.dart`
    - Add compound field detection: Check if field is CompoundField type
    - Call `subFieldsBuilder(compoundField)` to generate sub-field list
    - Apply ID prefixing to all sub-fields using pattern: `{compoundId}_{subFieldId}`
    - Allow developer override if sub-field already has prefixed ID
  - [x] 2.3 Implement sub-field registration with FormController
    - Each sub-field registered individually using existing Field registration flow
    - Sub-fields are controller-transparent: no special compound field awareness in FormController
    - Ensure TextEditingController and FocusNode created per sub-field via existing lifecycle
    - Location: Modify form field iteration logic in Form widget build method
  - [x] 2.4 Implement theme and disabled state propagation
    - Apply compound field theme to sub-fields if sub-field.theme is null
    - Apply disabled state: if compoundField.disabled, set all sub-fields to disabled
    - Use copyWith pattern for immutable field updates
    - Preserve sub-field-specific overrides if already set
  - [x] 2.5 Build compound field layout using layoutBuilder or default
    - If custom layoutBuilder provided in registration, use it
    - Otherwise, use default vertical layout builder from Task 1.5
    - Pass built sub-field widgets to layout builder
    - If rollUpErrors true, collect errors from all sub-fields and pass to layout builder
  - [x] 2.6 Ensure Form integration tests pass
    - Run ONLY the 6-8 tests written in 2.1
    - Verify compound fields render correctly in Form widget
    - Verify sub-fields act as normal fields from controller perspective
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 6-8 tests written in 2.1 pass
- Form widget successfully processes CompoundField types
- Sub-fields registered individually with FormController
- All existing controller methods work on sub-field IDs without modifications
- Theme and disabled state propagate from compound field to sub-fields

---

### Phase 3: Results Access & Validation

#### Task Group 3: Results Accessor and Error Rollup
**Assigned implementer:** api-engineer
**Dependencies:** Task Group 2
**Complexity:** Medium - Extension of existing results system

- [x] 3.0 Complete results access API and validation pattern
  - [x] 3.1 Write 4-6 focused tests for results access and validation
    - Test asCompound() method joins sub-field values with delimiter
    - Test asCompound() detects compound fields by sub-field ID pattern
    - Test individual sub-field access via grab("compoundId_subFieldId").asString()
    - Test validation executes on individual sub-fields independently
    - Test error rollup when rollUpErrors: true
    - Skip exhaustive delimiter testing and edge cases
  - [x] 3.2 Add asCompound() method to FieldResultAccessor class
    - Signature: `String asCompound({String delimiter = ", ", String fallback = ""})`
    - Logic: Detect compound field by checking if field ID has associated sub-fields (pattern: fields starting with `{fieldId}_`)
    - Collect sub-field string values using grab(subId).asString() for each sub-field
    - Filter out empty string values
    - Join with delimiter and return
    - Location: `/home/fabier/Documents/code/championforms/lib/models/formresults.dart`
  - [x] 3.3 Add helper method _getSubFieldIds() to FieldResultAccessor
    - Signature: `List<String> _getSubFieldIds(String compoundId)`
    - Logic: Query fieldDefinitions map for IDs starting with `{compoundId}_`
    - Return list of matching sub-field IDs
    - Location: Add to FieldResultAccessor class in formresults.dart
  - [x] 3.4 Implement validation pattern following Row/Column error rollup
    - Each sub-field has independent validators list
    - Validation executes per sub-field via existing validation infrastructure
    - Errors stored in FormController under sub-field IDs: `controller.formErrors['{compoundId}_{subFieldId}']`
    - Reference Row/Column error rollup pattern from `/home/fabier/Documents/code/championforms/lib/models/field_types/row.dart`
  - [x] 3.5 Implement error collection for rollUpErrors pattern
    - If compoundField.rollUpErrors is true, collect all errors from sub-field IDs
    - Pass collected errors to layout builder as List<FormBuilderError>
    - If rollUpErrors is false, pass null to layout builder (errors display inline with each sub-field)
    - Location: Add to compound field rendering logic in Form widget
  - [x] 3.6 Ensure results access and validation tests pass
    - Run ONLY the 4-6 tests written in 3.1
    - Verify asCompound() correctly joins sub-field values
    - Verify validation works independently on sub-fields
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 4-6 tests written in 3.1 pass
- asCompound() method joins sub-field values with configurable delimiter
- Individual sub-field values accessible via standard grab() method
- Validation executes independently on each sub-field
- Error rollup pattern works when rollUpErrors: true

---

### Phase 4: Built-in Compound Fields & Testing

#### Task Group 4: NameField and AddressField Implementation
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 3
**Complexity:** Medium - Reference implementations using compound field API

- [x] 4.0 Complete built-in compound fields (NameField and AddressField)
  - [x] 4.1 Write 4-6 focused tests for NameField and AddressField
    - Test NameField generates firstname, lastname sub-fields
    - Test NameField with includeMiddleName option
    - Test AddressField generates street, city, state, zip sub-fields
    - Test AddressField with includeStreet2 and includeCountry options
    - Test built-in compound fields work in Form widget
    - Skip exhaustive layout and styling tests
  - [x] 4.2 Create NameField compound field class
    - Properties: `bool includeMiddleName` (default: true)
    - Sub-fields: TextField('firstname'), TextField('lastname'), optionally TextField('middlename')
    - Implement buildSubFields() method
    - Location: `/home/fabier/Documents/code/championforms/lib/default_fields/name_field.dart`
  - [x] 4.3 Register NameField with custom horizontal layout
    - Layout: Row with Expanded widgets
    - Flex ratios: firstname (flex: 1), middlename (flex: 1), lastname (flex: 2)
    - 10px spacing between fields
    - Registration code in: `/home/fabier/Documents/code/championforms/lib/core/field_builder_registry.dart` in registerCoreBuilders()
  - [x] 4.4 Create AddressField compound field class
    - Properties: `bool includeStreet2` (default: true), `bool includeCountry` (default: false)
    - Sub-fields: TextField('street'), optional TextField('street2'), TextField('city'), TextField('state'), TextField('zip'), optional TextField('country')
    - Implement buildSubFields() method
    - Location: `/home/fabier/Documents/code/championforms/lib/default_fields/address_field.dart`
  - [x] 4.5 Register AddressField with custom multi-row layout
    - Row 1: street (full width)
    - Row 2: street2 (full width, if includeStreet2)
    - Row 3: city (flex: 4), state (flex: 3), zip (flex: 3) in horizontal Row
    - Row 4: country (full width, if includeCountry)
    - Error display at bottom if rollUpErrors
    - 10px vertical spacing between rows
    - Registration code in registerCoreBuilders()
  - [x] 4.6 Export NameField and AddressField in championforms.dart
    - Add to main barrel export: `/home/fabier/Documents/code/championforms/lib/championforms.dart`
    - Ensure namespace pattern: import 'package:championforms/championforms.dart' as form;
    - Usage: form.NameField(...), form.AddressField(...)
  - [x] 4.7 Ensure built-in compound field tests pass
    - Run ONLY the 4-6 tests written in 4.1
    - Verify NameField and AddressField work correctly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 4-6 tests written in 4.1 pass
- NameField creates firstname, lastname, and optional middlename sub-fields
- AddressField creates street, city, state, zip, and optional street2/country sub-fields
- Custom layouts render correctly for both built-in compound fields
- Both fields exported via championforms.dart with form. namespace prefix

---

### Phase 5: Final Testing & Documentation

#### Task Group 5: Comprehensive Testing and Example App
**Assigned implementer:** testing-engineer
**Dependencies:** Task Groups 1-4
**Complexity:** Medium - Gap analysis and integration testing

- [x] 5.0 Review existing tests and fill critical gaps only
  - [x] 5.1 Review tests from Task Groups 1-4
    - Review the 5-8 tests written by api-engineer (Task 1.1)
    - Review the 6-8 tests written by api-engineer (Task 2.1)
    - Review the 4-6 tests written by api-engineer (Task 3.1)
    - Review the 4-6 tests written by ui-designer (Task 4.1)
    - Total existing tests: approximately 19-28 tests
  - [x] 5.2 Analyze test coverage gaps for compound field feature only
    - Identify critical user workflows lacking test coverage
    - Focus on: Full form with multiple compound fields, mixed compound and standard fields, results retrieval patterns
    - Focus ONLY on gaps related to this compound field feature
    - Do NOT assess entire ChampionForms package test coverage
    - Prioritize integration tests over unit test gaps
  - [x] 5.3 Write up to 10 additional strategic tests maximum
    - Integration test: Full form with NameField and AddressField
    - Integration test: Mixed form with compound fields and standard TextField
    - Integration test: Compound field with custom layout builder override
    - Integration test: Error rollup pattern with multiple sub-field validation failures
    - Integration test: Results access using asCompound() with different delimiters
    - Integration test: Theme propagation from compound field to all sub-fields
    - Integration test: Disabled state propagation from compound field
    - Skip performance tests, edge cases, and exhaustive validation scenarios unless business-critical
    - Location: `/home/fabier/Documents/code/championforms/test/compound_field_full_integration_test.dart`
  - [x] 5.4 Create example app demonstration
    - Add new demo page to example app: `/home/fabier/Documents/code/championforms/example/lib/pages/compound_fields_demo.dart`
    - Demonstrate NameField with includeMiddleName toggle
    - Demonstrate AddressField with includeStreet2 and includeCountry toggles
    - Show custom layout builder override example
    - Show results retrieval with asCompound() and individual sub-field access
    - Add button to display FormResults with compound field values
  - [x] 5.5 Run feature-specific tests only
    - Run ONLY tests related to compound field feature
    - Expected total: approximately 29-38 tests maximum
    - Command: `flutter test test/compound_field*.dart test/name_field_test.dart test/address_field_test.dart`
    - Verify all critical workflows pass
    - Do NOT run entire ChampionForms test suite
  - [x] 5.6 Update CHANGELOG.md with new feature
    - Add entry under [Unreleased] section
    - Document: New CompoundField base class, FormFieldRegistry.registerCompound<T>() method, asCompound() results accessor
    - Document: Built-in NameField and AddressField convenience classes
    - List breaking changes: None (fully backward compatible)
  - [x] 5.7 Create documentation for custom compound field creation
    - Add section to README.md: "Creating Custom Compound Fields"
    - Include code example of registering custom compound field
    - Show sub-field definition pattern
    - Show custom layout builder example
    - Reference NameField and AddressField as examples
  - [x] 5.8 Verify backward compatibility
    - Run existing ChampionForms test suite: `flutter test`
    - Ensure all existing tests pass
    - Verify no breaking changes to existing Field types
    - Verify existing FormFieldRegistry.register<T>() still works
    - Verify existing results accessors (asString, asFile, etc.) still work

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 29-38 tests total)
- Critical compound field workflows have test coverage
- No more than 10 additional tests added by testing-engineer
- Example app demonstrates NameField and AddressField usage
- Documentation added for custom compound field creation
- Full backward compatibility maintained with existing ChampionForms API

---

## Execution Order

Recommended implementation sequence:
1. **Phase 1: Core Architecture** (Task Group 1) - Foundation for all compound field functionality
2. **Phase 2: Controller Integration** (Task Group 2) - Makes sub-fields work as normal fields
3. **Phase 3: Results Access** (Task Group 3) - Enables convenient value retrieval
4. **Phase 4: Built-in Fields** (Task Group 4) - Reference implementations and usability
5. **Phase 5: Testing & Documentation** (Task Group 5) - Validation and completeness

## Implementation Notes

### Critical Patterns to Follow

**Sub-field ID Prefixing:**
```dart
String _prefixSubFieldId(String compoundId, String subFieldId) {
  if (subFieldId.startsWith('$compoundId_')) {
    return subFieldId; // Already prefixed
  }
  return '${compoundId}_$subFieldId';
}
```

**Controller Transparency:**
- Sub-fields must be registered individually with FormController
- No special compound field handling in FormController
- All existing controller methods work unchanged on sub-field IDs

**Theme Propagation:**
```dart
final subFields = registration.subFieldsBuilder(compoundField).map((subField) {
  if (subField.theme == null && compoundTheme != null) {
    return subField.copyWith(theme: compoundTheme);
  }
  return subField;
}).toList();
```

**Error Rollup Pattern:**
```dart
if (compoundField.rollUpErrors) {
  final subFieldErrors = compoundField.subFieldIds
      .map((id) => controller.getFieldErrors(id))
      .expand((errors) => errors)
      .toList();
  layoutBuilder(context, subFieldWidgets, subFieldErrors);
} else {
  layoutBuilder(context, subFieldWidgets, null);
}
```

### Testing Strategy

- **Development phase (Groups 1-4)**: Each group writes 2-8 focused tests covering only critical behaviors
- **Verification phase (Group 5)**: testing-engineer adds maximum 10 additional tests to fill gaps
- **Total expected tests**: 29-38 tests for entire compound field feature
- **Test scope**: ONLY this compound field feature, NOT entire package
- **Test execution**: Run feature-specific tests only during development, full suite only at final verification

### File Locations Summary

**New Files:**
- `/home/fabier/Documents/code/championforms/lib/models/field_types/compound_field.dart`
- `/home/fabier/Documents/code/championforms/lib/models/field_types/compound_field_registration.dart`
- `/home/fabier/Documents/code/championforms/lib/default_fields/name_field.dart`
- `/home/fabier/Documents/code/championforms/lib/default_fields/address_field.dart`
- `/home/fabier/Documents/code/championforms/test/compound_field_full_integration_test.dart`
- `/home/fabier/Documents/code/championforms/example/lib/pages/compound_fields_demo.dart`

**Modified Files:**
- `/home/fabier/Documents/code/championforms/lib/core/field_builder_registry.dart` (add registerCompound method)
- `/home/fabier/Documents/code/championforms/widgets_internal/form.dart` (add compound field processing)
- `/home/fabier/Documents/code/championforms/lib/models/formresults.dart` (add asCompound method)
- `/home/fabier/Documents/code/championforms/lib/championforms.dart` (export new classes)
- `/home/fabier/Documents/code/championforms/CHANGELOG.md` (document new feature)
- `/home/fabier/Documents/code/championforms/README.md` (add documentation section)

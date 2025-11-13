# Spec Requirements: Compound Field Registration API

## Initial Description
We recently updated the field registration setup to allow custom fields on top of ChampionForms. Now we need to develop an API for expanding this registration process to support compound fields.

Compound fields are composite fields made up of multiple sub-fields. For example:
- An "address" field with ID "address" would contain sub-fields like:
  - "address_street"
  - "address_street2"
  - "address_city"
  - "address_state"
  - "address_zip"
  - etc.

The compound field would:
- Handle custom layouts for the collection of text fields
- Support validation on individual sub-fields
- Provide an idiomatic registration process on top of our current FormFieldRegistry setup
- Make it quick and easy to declare and register these compound fields with the controller

## Requirements Discussion

### First Round Questions

**Q1: Sub-field ID Strategy** - How should sub-field IDs be generated from the compound field's ID?
**Answer:** Sub-field IDs should be automatically prefixed with the compound field's ID using an underscore separator (e.g., "address" becomes "address_street", "address_city"). Developers should have the ability to override this if needed for specific use cases.

**Q2: Compound Field Definition API** - How should developers define compound fields?
**Answer:** Option C - Registration-based approach where sub-fields are defined in the builder. This allows registration of reusable compound fields via:

```dart
FormFieldRegistry.registerCompound<AddressField>(
  'address',
  subFields: (field) => [
    TextField(id: "${field.id}_street"),
    TextField(id: "${field.id}_city"),
  ],
  builder: (context, subFields) => CustomLayout(subFields),
)
```

**Q3: Sub-field Validation** - How should validation work with compound fields?
**Answer:** Sub-fields should behave exactly like normal fields for validation purposes. Each sub-field has its own validators applied individually. The compound field itself acts as a layout container and should follow the Row/Column pattern with error rollup capability - meaning validation errors from sub-fields can be displayed together at the bottom of the compound field if `rollUpErrors: true` is set.

**Q4: Default Layout Builder** - What should the default layout be if no custom builder is provided?
**Answer:** A simple vertical stacked layout (like a Column) should be the default. Developers should be able to override this using the `CompoundField.field("fieldId").builder()` API to provide custom layouts for each compound field instance.

**Q5: Results Access** - How should developers access compound field results?
**Answer:** Add an `asCompound()` method to `FieldResultAccessor` that joins all sub-field values into a single string with a delimiter (default: comma). This provides a convenient way to get the full compound value: `results.grab("address").asCompound(delimiter: ", ")`. Developers can still access individual sub-field values using their full IDs: `results.grab("address_street").asString()`.

**Q6: Controller Interaction** - How should compound fields interact with FormController?
**Answer:** Sub-fields should act as completely normal, independent fields from the controller's perspective. The compound field itself should be invisible to the controller - it exists purely as a registration/layout convenience. When developers call `controller.getFieldValue("address_street")`, it should work exactly like any other field.

**Q7: Sub-field Declaration** - Should sub-fields be auto-generated or developer-declared?
**Answer:** Sub-fields should be declared by the developer in the registration function. This provides maximum flexibility - developers specify exactly which fields they want (TextField, OptionSelect, etc.) and can configure each one individually. The compound field can apply overarching features like theme and disabled state to all sub-fields automatically.

**Q8: Error Display Pattern** - How should validation errors be displayed?
**Answer:** Follow the Row/Column pattern: errors can be displayed inline with each sub-field (default), or rolled up to display together at the bottom of the compound field container if `rollUpErrors: true` is set on the compound field definition.

**Q9: Built-in Examples** - Should we provide convenience compound fields?
**Answer:** Yes, provide built-in examples as convenience classes: `NameField` (first name, last name, optional middle name) and `AddressField` (street, street2, city, state, zip, optional country). These serve as both useful utilities and reference implementations for developers creating their own compound fields.

**Q10: API Consistency** - How does this fit with the existing FormFieldRegistry pattern?
**Answer:** Use the registration-based API: `FormFieldRegistry.registerCompound<T>()` as a companion to the existing `FormFieldRegistry.register<T>()`. This maintains consistency with the existing field registration pattern while adding compound-specific capabilities (sub-field definition, layout builder).

### Existing Code to Reference

**Similar Features Identified:**
- Feature: Row and Column layout system - Path: `/home/fabier/Documents/code/championforms/lib/models/field_types/row.dart` and `/home/fabier/Documents/code/championforms/lib/models/field_types/column.dart`
  - Components to potentially reuse: `rollUpErrors` pattern, `hideField` pattern, layout structure
  - Backend logic to reference: Error rollup mechanism from Row/Column rendering

- Feature: Field Registration System - Path: `/home/fabier/Documents/code/championforms/lib/core/field_builder_registry.dart`
  - Components to potentially reuse: `FormFieldRegistry` singleton pattern, `register()` static method API
  - Backend logic to reference: Builder storage, type-based lookup, initialization flow

- Feature: Results Accessor Pattern - Path: `/home/fabier/Documents/code/championforms/lib/models/formresults.dart`
  - Components to potentially reuse: `FieldResultAccessor` class, accessor method pattern (asString, asFile, etc.)
  - Backend logic to reference: Value retrieval, type conversion, fallback handling

### Follow-up Questions

No follow-up questions were needed. All requirements were clearly defined in the first round.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
No visual assets to analyze.

## Requirements Summary

### Functional Requirements

**1. Compound Field Registration API**
- Add `FormFieldRegistry.registerCompound<T>()` static method
- Accept a type parameter `T` that extends a new `CompoundField` base class
- Take parameters:
  - `typeName`: String identifier for debugging
  - `subFields`: Function that receives the field instance and returns a List of Field definitions
  - `builder`: Function that receives context and sub-fields list, returns a layout widget
  - Optional: `rollUpErrors` boolean (default false)
  - Optional: `converters` for custom value conversion

**2. Sub-field ID Management**
- Automatically prefix sub-field IDs with compound field ID plus underscore
- Pattern: `{compoundFieldId}_{subFieldId}`
- Example: Field ID "address" creates sub-fields "address_street", "address_city", etc.
- Allow developer override of ID generation for edge cases

**3. Sub-field Behavior**
- Sub-fields act as completely independent fields from controller perspective
- Controller methods work directly on sub-field IDs: `controller.getFieldValue("address_street")`
- Each sub-field has its own validators, theme, focus state, etc.
- Compound field itself is invisible to the controller - purely a layout/registration convenience

**4. Validation Pattern**
- Each sub-field can have its own validators list
- Validators execute on individual sub-fields independently
- Follow Row/Column error rollup pattern:
  - Default: Errors display inline with each sub-field
  - Optional: `rollUpErrors: true` displays all sub-field errors together at bottom of compound field

**5. Layout System**
- Default layout: Simple vertical stack (Column-like)
- Custom layout via builder function: `builder: (context, subFields) => CustomLayout()`
- Per-instance override: `CompoundField.field("fieldId").builder(() => CustomWidget())`
- Compound field should support applying theme and disabled state to all sub-fields

**6. Results Access API**
- Add `asCompound()` method to `FieldResultAccessor` class
- Signature: `String asCompound({String delimiter = ", ", String fallback = ""})`
- Behavior: Joins all sub-field string values using the delimiter
- Example: `results.grab("address").asCompound()` returns "123 Main St, Suite 4, New York, NY, 10001"
- Individual sub-field access still works: `results.grab("address_street").asString()`

**7. Built-in Compound Fields**
- `NameField`: Compound field with first name, last name, optional middle name
  - Sub-fields: "firstname", "middlename", "lastname"
  - Default layout: Horizontal row with 25% / 25% / 50% flex
- `AddressField`: Compound field for physical addresses
  - Sub-fields: "street", "street2", "city", "state", "zip", "country" (optional)
  - Default layout:
    - Row 1: street (full width)
    - Row 2: street2 (full width, optional)
    - Row 3: city (40%), state (30%), zip (30%)
    - Row 4: country (full width, optional)

**8. Theme and State Propagation**
- Compound field definition can specify theme that applies to all sub-fields
- Disabled state propagates to all sub-fields
- Sub-fields can still have individual overrides if needed

### Reusability Opportunities

**Existing Components to Reuse:**
1. **Row/Column Error Rollup Logic**
   - Reuse `rollUpErrors` boolean property pattern
   - Reuse error collection and display mechanism from Row/Column widgets
   - Reference: `/home/fabier/Documents/code/championforms/lib/models/field_types/row.dart`

2. **FormFieldRegistry Registration Pattern**
   - Follow existing `register<T>()` static method signature
   - Use same type-based storage and lookup mechanism
   - Maintain consistency with builder function pattern
   - Reference: `/home/fabier/Documents/code/championforms/lib/core/field_builder_registry.dart`

3. **FieldResultAccessor Extension Pattern**
   - Add `asCompound()` method following same pattern as `asString()`, `asFile()`, etc.
   - Use same fallback and error handling approach
   - Follow existing type conversion architecture
   - Reference: `/home/fabier/Documents/code/championforms/lib/models/formresults.dart`

4. **Field Base Classes**
   - Extend existing `Field` or `FormElement` base class for `CompoundField`
   - Reuse common properties: `id`, `validators`, `defaultValue`, `hideField`, `disabled`
   - Follow established field definition patterns

5. **FieldBuilderContext Pattern**
   - Use existing `FieldBuilderContext` for builder functions
   - Provides access to controller, field, theme, state, colors
   - Maintains consistency with current field builder API

**Backend Patterns to Follow:**
1. Type-based registration and lookup (from FormFieldRegistry)
2. Singleton pattern for global registry (from FormFieldRegistry.instance)
3. Error collection and propagation (from Row/Column rendering)
4. Value conversion with fallbacks (from FieldResultAccessor)
5. Automatic resource management (TextEditingController, FocusNode lifecycle)

### Scope Boundaries

**In Scope:**
- `FormFieldRegistry.registerCompound<T>()` static method
- New `CompoundField` base class extending Field or FormElement
- Automatic sub-field ID prefixing with compound field ID
- Sub-field definition via function callback during registration
- Default vertical layout builder
- Custom layout builder override capability
- Per-instance builder override via `.builder()` method
- `asCompound()` accessor method on FieldResultAccessor
- Error rollup following Row/Column pattern
- Theme and disabled state propagation to sub-fields
- Built-in `NameField` compound field
- Built-in `AddressField` compound field
- Documentation for creating custom compound fields
- Unit tests for compound field registration and behavior
- Integration tests for built-in compound fields

**Out of Scope:**
- Nested compound fields (compound field containing another compound field) - Future enhancement
- Automatic form generation from data models - Separate feature
- Server-side validation integration - Separate feature
- Conditional sub-field display based on other field values - Covered by existing conditional logic feature on roadmap
- Advanced layout templates beyond simple vertical stack - Developers can create via custom builders
- Internationalization of built-in compound fields - Covered by existing i18n roadmap item
- Drag-and-drop reordering of sub-fields - Not required for initial release
- Dynamic sub-field addition/removal at runtime - Future enhancement
- Compound field value serialization formats beyond string join - Can be added later if needed

### Technical Considerations

**Integration Points:**
- Extends existing FormFieldRegistry singleton
- Integrates with current Field base class hierarchy
- Works with existing FormController methods (transparent to controller)
- Compatible with FieldResultAccessor result retrieval pattern
- Uses existing validation and error handling infrastructure
- Leverages current theme and styling system

**Existing System Constraints:**
- Must maintain backward compatibility with existing Field types
- Must work with namespace-based import: `import 'package:championforms/championforms.dart' as form;`
- Sub-fields must be fully compatible with all controller methods
- Must follow Flutter widget lifecycle patterns (StatelessWidget/StatefulWidget)
- Must respect existing field disposal patterns for TextEditingController and FocusNode

**Technology Stack (from tech-stack.md):**
- Dart (>=3.0.5 <4.0.0)
- Flutter (>=1.17.0)
- Uses existing package dependencies (no new dependencies required)
- Published as part of championforms package on pub.dev

**Design Patterns to Follow:**
- Singleton pattern for registry (consistent with FormFieldRegistry)
- Builder pattern for field construction
- Composition over inheritance (compound fields compose existing fields)
- Type-safe generics for field types
- Functional programming for field definition (callback-based)

**Performance Considerations:**
- Sub-fields should not duplicate controller operations
- Registration should happen once at app initialization
- Layout building should be efficient for forms with multiple compound fields
- No additional overhead compared to manually defining sub-fields

**Testing Strategy:**
- Unit tests: Compound field registration, sub-field ID generation, error rollup logic
- Widget tests: Built-in compound fields (NameField, AddressField), custom layout builders
- Integration tests: Full form with compound fields, validation, results access
- Example app: Demonstrate NameField and AddressField usage with custom layouts

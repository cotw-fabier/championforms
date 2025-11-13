# Spec Requirements: Simplify Custom Field API

## Initial Description

The goal is to dramatically simplify the custom field creation API in ChampionForms while maintaining all necessary hooks for validation, state management, focus handling, and callbacks. The current API requires ~120-150 lines of boilerplate code per custom field. The new API should reduce this to ~30-50 lines while providing both high-level convenience helpers and low-level flexibility.

Key improvements to implement:
1. FieldBuilderContext class - bundles 6 builder parameters into one context object with convenience methods
2. StatefulFieldWidget base class - handles controller integration boilerplate automatically
3. Simplified registration API - FormFieldRegistry.register() with inline converter support
4. Converter mixins - TextFieldConverters, MultiselectFieldConverters, etc. to eliminate boilerplate
5. Unified builder signatures between registry and fieldBuilder property
6. Comprehensive documentation and examples

The user has confirmed they want:
- Priority: Simpler registration API
- Breaking changes are acceptable
- Keep both builder approaches (registry + fieldBuilder)
- Both high-level helpers and low-level flexibility

## Requirements Discussion

### First Round Questions

**Q1: Version and Breaking Changes**
I assume this will be released as version 0.6.0 since it's a breaking API change. Is that correct, or do you have a different versioning strategy in mind?

**Answer:** 0.6.0 (breaking change accepted)

**Q2: Migration Tooling**
Given the breaking nature of these changes, should we provide an automated migration script similar to the v0.4.0 migration tool at `tools/project-migration.dart`, or is clear documentation sufficient?

**Answer:** No automated script needed, but clear documentation is essential

**Q3: FieldBuilderContext Design**
For the FieldBuilderContext class, I'm thinking it should expose the raw controller as a property for advanced use cases (like the current ~120-line implementations). Should we hide the controller by default and only expose it via an "advanced" getter, or make it a standard property?

**Answer:** Expose the raw controller for advanced use cases while keeping simple API as default

**Q4: Lifecycle Hooks**
Should StatefulFieldWidget provide lifecycle hooks like `onValueChanged()`, `onFocusChanged()`, or `onValidate()` that subclasses can override? This could further reduce boilerplate for common patterns.

**Answer:** Yes, provide `onValueChanged()` and `onFocusChanged()` hooks that subclasses can override

**Q5: Converter Implementation**
For the converter mixins (TextFieldConverters, MultiselectFieldConverters), should these be:
- Abstract classes that custom fields extend?
- Mixins that can be combined?
- Utility classes with static methods?

I'm leaning toward mixins for maximum flexibility.

**Answer:** Use mixins

**Q6: Registry Naming**
For the simplified registration API, should we keep `FormFieldRegistry.instance.registerField()` or introduce a shorter static method like `FormFieldRegistry.register()`?

**Answer:** `FormFieldRegistry.register()` static method (maintain singleton pattern internally)

**Q7: Documentation Emphasis**
Should the documentation emphasize using the registry approach for reusable custom field types and the fieldBuilder property for one-off customizations? Or treat both equally?

**Answer:** File-based custom fields for new field types, inline builders for custom design of known field types

**Q8: Documentation Scope**
For comprehensive documentation, should we include:
- Migration guide for existing custom fields?
- "Custom Field Cookbook" with 3-5 examples?
- Update to the example app with custom field demonstrations?
- API reference documentation?

Also, should we **move all docs (including migration guides) into a docs/ folder** for better organization?

**Answer:**
- Migration guide
- Custom field cookbook with examples
- Update example app to include 1-2 custom fields
- **Move all docs (including migration guides) into a docs/ folder**

**Q9: Testing Strategy**
Should we add comprehensive tests for the new custom field base classes and helper utilities, or focus testing primarily on the existing fields' migration to the new API?

**Answer:** Yes, comprehensive testing for new custom field components

**Q10: Validation Integration**
How should validation triggering work for custom fields? Should StatefulFieldWidget automatically call validation on focus loss, or should field authors explicitly opt-in?

**Answer:** Try to make automatic if possible, otherwise provide clear opt-in hooks for authors to notify controller of focus loss

**Q11: Theme Integration**
I'm thinking StatefulFieldWidget could provide a `buildWithTheme(BuildContext, FormTheme)` method that automatically handles theme cascading. Does that align with your vision?

**Answer:** `buildWithTheme()` method sounds perfect

**Q12: Converter Error Handling**
When converters fail (e.g., expecting a List but getting a String), should they:
- Return null/default values silently?
- Throw exceptions?
- Add validation errors to the form?

**Answer:** Throw exceptions on invalid format

**Q13: Focus Management**
Custom fields currently can access FocusNode via the controller. Should the new API abstract this into a helper, or keep the current manual approach?

**Answer:** Must support current behavior (focusNode property)

**Q14: Performance Considerations**
Should we add performance optimizations like lazy initialization of field widgets or value notifiers to prevent unnecessary rebuilds?

**Answer:** Yes, implement optimizations (lazy initialization, value notifiers, rebuild prevention)

**Q15: Backwards Compatibility**
Should we maintain a deprecated version of the old API alongside the new one, or is a clean breaking change acceptable given the 0.x version status?

**Answer:** Breaking change, no deprecation period needed

**Q16: Timeline and Priority**
Are there any upcoming features or deadlines that would impact the timeline for this refactor? Should this take priority over other specs?

**Answer:** Focus on this spec (prioritized)

**Q17: Scope of Refactoring**
Should we refactor the existing built-in field implementations (TextField, OptionSelect, FileUpload) to use the new base classes as part of this spec? This would validate the API and reduce maintenance burden.

**Answer:** Refactor existing built-in field implementations (TextField, OptionSelect, etc.) to use the new base classes

### Existing Code to Reference

No specific similar features were identified for reference. The implementation will analyze existing field implementations in `lib/models/field_types/` and `lib/widgets_internal/field_widgets/` to understand current patterns and ensure the new API supports all necessary hooks.

### Visual Assets

**Files Provided:**
No visual assets provided.

**Visual Check Performed:**
Visual assets folder checked via bash command - no files found.

## Requirements Summary

### Functional Requirements

**Core API Components:**
1. **FieldBuilderContext class**
   - Bundle all builder parameters (controller, field, theme, validators, callbacks) into single context object
   - Expose raw controller as property for advanced use cases
   - Provide convenience methods for common operations
   - Handle theme cascading automatically

2. **StatefulFieldWidget base class**
   - Handle controller integration boilerplate automatically
   - Provide lifecycle hooks: `onValueChanged()`, `onFocusChanged()`
   - Implement `buildWithTheme(BuildContext, FormTheme)` method for automatic theme handling
   - Support current FocusNode behavior via focusNode property
   - Include performance optimizations: lazy initialization, value notifiers, rebuild prevention

3. **Simplified Registration API**
   - Implement `FormFieldRegistry.register()` as static method
   - Maintain singleton pattern internally
   - Support inline converter specification during registration
   - Unified builder signatures between registry and fieldBuilder property

4. **Converter Mixins**
   - Implement as mixins for maximum flexibility
   - Types needed: TextFieldConverters, MultiselectFieldConverters, FileUploadConverters
   - Converters throw exceptions on invalid format (no silent failures)
   - Eliminate boilerplate for type conversions

5. **Validation Integration**
   - Automatic validation triggering on focus loss (if possible)
   - Provide clear opt-in hooks for custom validation timing
   - Maintain compatibility with existing validation system

**Code Refactoring:**
- Refactor all existing built-in field implementations to use new base classes:
  - TextField
  - OptionSelect (including CheckboxSelect, ChipSelect convenience types)
  - FileUpload
- This validates the new API and reduces maintenance burden

**Documentation Requirements:**
1. **Documentation Organization**
   - Create new `docs/` folder structure
   - Move all existing documentation into `docs/` folder
   - Move migration guides (including MIGRATION-0.4.0.md) into `docs/migrations/`

2. **New Documentation**
   - Migration guide for v0.6.0 custom field API changes
   - Custom field cookbook with practical examples
   - Clear guidance: file-based custom fields for new field types, inline builders for custom design of known field types
   - API reference documentation for new classes

3. **Example App Updates**
   - Add 1-2 custom field demonstrations to example app
   - Show both registry and fieldBuilder approaches

**Testing Requirements:**
- Comprehensive tests for new custom field components:
  - FieldBuilderContext functionality
  - StatefulFieldWidget lifecycle hooks
  - Converter mixins behavior and error handling
  - FormFieldRegistry static registration
  - Theme integration via buildWithTheme()
- Validate existing field implementations work correctly after refactoring
- Performance test for lazy initialization and rebuild prevention

**Version and Release:**
- Release as v0.6.0 (breaking change)
- No backwards compatibility or deprecation period
- Clean break from old API

### Reusability Opportunities

**Existing Patterns to Analyze:**
- Current field implementations in `lib/models/field_types/`
- Field widget implementations in `lib/widgets_internal/field_widgets/`
- Current FormFieldRegistry singleton pattern in `core/field_builder_registry.dart`
- Existing theme cascading logic
- Current controller integration patterns

**Code to Ensure Compatibility With:**
- FormController state management (fieldValues map, formErrors, focusListenable)
- Existing validation system (Validator class, validateLive behavior)
- FormResults and FieldResultAccessor type conversion
- Theme hierarchy (Default → Global → Form → Field)
- TextEditingController lifecycle management
- FocusNode management

### Scope Boundaries

**In Scope:**
- FieldBuilderContext class implementation
- StatefulFieldWidget base class with lifecycle hooks
- Converter mixins (Text, Multiselect, FileUpload)
- Simplified FormFieldRegistry.register() static API
- Refactoring all built-in field types to use new base classes
- Comprehensive documentation in new docs/ folder structure
- Migration guide for v0.6.0
- Custom field cookbook with examples
- Example app updates (1-2 custom fields)
- Comprehensive testing for new components
- Performance optimizations (lazy init, value notifiers, rebuild prevention)
- Automatic validation triggering on focus loss (if feasible)
- Theme integration via buildWithTheme() method

**Out of Scope:**
- Automated migration tooling (v0.4.0-style script)
- Deprecation period or backwards compatibility layer
- New field types beyond existing built-ins
- Changes to core validation system
- Changes to FormController architecture
- Changes to FormResults/FieldResultAccessor APIs
- Platform-specific code changes
- Non-custom-field-related documentation updates

**Future Enhancements (Not in This Spec):**
- Additional built-in custom field examples beyond 1-2 in example app
- Video tutorials or interactive documentation
- Visual form builder tools
- Additional converter types beyond Text/Multiselect/FileUpload

### Technical Considerations

**Integration Points:**
- FormController (controllers/form_controller.dart) - must maintain all existing state management hooks
- FormFieldRegistry singleton (core/field_builder_registry.dart) - add static wrapper
- FormTheme cascade system (models/themes.dart) - integrate into buildWithTheme()
- Validation system (models/validatorclass.dart, functions/defaultvalidators/) - automatic triggering
- FormResults type conversion (models/formresults.dart) - converters must match existing behavior
- Field builder functions (widgets_external/field_builders/) - unified signatures

**Existing System Constraints:**
- Must work with FormController's ChangeNotifier pattern
- Must respect TextEditingController lifecycle management
- Must support focusListenable map for focus state tracking
- Must maintain compatibility with validateLive behavior
- Must work with existing Row/Column layout system
- Must support all current Field properties (validators, defaultValue, onChange, onSubmit, etc.)

**Technology Stack:**
- Flutter SDK >=3.35.0
- Dart SDK >=3.0.5 <4.0.0
- Must work with existing dependencies (file_picker, desktop_drop, etc.)
- No new external dependencies for core API

**Performance Requirements:**
- Lazy initialization of field widgets to prevent unnecessary instantiation
- Value notifiers to prevent unnecessary rebuilds
- Efficient theme resolution without repeated lookups
- No performance regression compared to current implementation

**Error Handling:**
- Converters throw exceptions on invalid format (explicit failures)
- Clear error messages for registration failures
- Validation errors propagate through existing formErrors system
- Focus loss opt-in hooks should fail gracefully if not implemented

**Code Quality Standards:**
- Must pass `flutter analyze` with no errors
- Must pass `dart run custom_lint`
- Must be formatted with `flutter format`
- Must include comprehensive dartdoc comments
- Must follow existing architectural patterns
- Must maintain two-tier export system (championforms.dart for lifecycle, championforms_themes.dart for themes)
- Custom field base classes should be exported via championforms.dart with `form.` namespace prefix

**Documentation Standards:**
- Organize all documentation in new `docs/` folder
- Migration guides in `docs/migrations/`
- Clear examples showing both registry and inline builder approaches
- Emphasize file-based custom fields for new types, inline builders for design customization
- Update CHANGELOG.md with breaking changes clearly marked
- Update README.md to reference new docs/ folder structure

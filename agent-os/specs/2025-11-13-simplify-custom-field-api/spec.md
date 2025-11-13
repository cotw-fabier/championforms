# Specification: Simplify Custom Field API (v0.6.0)

## Goal

Dramatically simplify the custom field creation API in ChampionForms by reducing boilerplate from ~120-150 lines to ~30-50 lines while maintaining full flexibility for validation, state management, focus handling, and callbacks.

## User Stories

- As a package user, I want to create custom field types with minimal boilerplate so I can extend ChampionForms efficiently
- As a package maintainer, I want built-in fields to use the same simplified API so the codebase is more maintainable
- As a developer, I want both high-level convenience helpers and low-level controller access so I can handle simple and complex use cases
- As a package user, I want clear documentation showing when to use file-based custom fields vs inline builders so I choose the right approach

## Core Requirements

### Functional Requirements

**1. FieldBuilderContext Class**
- Bundle 6 builder parameters (controller, field, theme, validators, callbacks, state) into single context object
- Expose raw FormController as public property for advanced use cases
- Provide convenience methods for common operations:
  - `getValue<T>()` - get field value with type safety
  - `setValue<T>(T value)` - update field value
  - `addError(String reason)` - add validation error
  - `clearErrors()` - clear field errors
  - `requestFocus()` / `releaseFocus()` - focus management
  - `getTextController()` - lazy TextEditingController creation
  - `getFocusNode()` - lazy FocusNode creation
- Handle theme cascading automatically (Default → Global → Form → Field)

**2. StatefulFieldWidget Base Class**
- Abstract base class that extends StatefulWidget
- Automatically handles controller integration via FieldBuilderContext
- Lifecycle hooks for subclasses to override:
  - `onValueChanged(T? oldValue, T? newValue)` - called when field value changes
  - `onFocusChanged(bool isFocused)` - called when focus state changes
  - `onValidate()` - optional validation hook (automatic by default)
- Abstract method `buildWithTheme(BuildContext context, FormTheme theme, FieldBuilderContext ctx)`
- Automatic disposal of resources (TextEditingController, FocusNode)
- Automatic focus loss validation (if field.validateLive is true)
- Performance optimizations: lazy initialization, rebuild prevention via shouldRebuild

**3. Simplified Registration API**
- Static method `FormFieldRegistry.register<T extends Field>(String typeName, FormFieldBuilder<T> builder)`
- Maintain singleton pattern internally (backward compatible with `.instance` accessor)
- Support inline converter specification:
  ```dart
  FormFieldRegistry.register<CustomField>(
    'custom',
    (ctx) => CustomFieldWidget(ctx: ctx),
    converters: CustomFieldConverters(),
  )
  ```
- Unified builder signature between registry and Field.fieldBuilder property:
  ```dart
  typedef FormFieldBuilder = Widget Function(FieldBuilderContext context)
  ```

**4. Converter Mixins**
- Implement as Dart mixins for composition
- Required mixins:
  - `TextFieldConverters` - for String-based fields
  - `MultiselectFieldConverters` - for List<FieldOption> fields
  - `FileFieldConverters` - for file upload fields
  - `NumericFieldConverters` - for int/double fields
- All converters throw exceptions on invalid format (no silent failures)
- Each mixin provides implementations for:
  - `asStringConverter(dynamic value)` → String
  - `asStringListConverter(dynamic value)` → List<String>
  - `asBoolConverter(dynamic value)` → bool
  - `asFileListConverter(dynamic value)` → List<FileModel>?

**5. Unified Builder Signatures**
- Both registry builders and Field.fieldBuilder use FieldBuilderContext
- Remove 6-parameter signature in favor of single context parameter
- Maintain backward compatibility during transition by supporting both signatures internally

**6. Refactor Existing Fields**
- Migrate ALL built-in field implementations to use new API:
  - TextField → use StatefulFieldWidget + TextFieldConverters
  - OptionSelect → use StatefulFieldWidget + MultiselectFieldConverters
  - CheckboxSelect → use StatefulFieldWidget + MultiselectFieldConverters
  - ChipSelect → use StatefulFieldWidget + MultiselectFieldConverters
  - FileUpload → use StatefulFieldWidget + FileFieldConverters
- Validates new API handles all existing functionality
- Reduces maintenance burden by consolidating patterns

### Non-Functional Requirements

**Performance**
- Lazy initialization of TextEditingController and FocusNode (create only when needed)
- Value notifier optimization to prevent unnecessary rebuilds
- StatefulFieldWidget should only rebuild on relevant state changes
- No performance regression compared to current implementation

**Compatibility**
- Must maintain compatibility with FormController state management
- FocusNode support preserved with current behavior
- Validation system integration unchanged (validateLive, validators list)
- Theme system integration unchanged (FormTheme, FieldColorScheme)
- Existing Form widget integration unchanged

**Error Handling**
- Converters throw explicit exceptions with descriptive messages
- FieldBuilderContext methods validate field existence before operations
- Clear error messages for registration failures
- Validation errors propagate through existing formErrors system

**Documentation**
- Comprehensive dartdoc comments on all public APIs
- Must pass `flutter analyze` with zero errors
- Must pass `dart run custom_lint`
- Follow Effective Dart guidelines

## Technical Approach

### 1. FieldBuilderContext Implementation

**Location**: `lib/models/field_builder_context.dart`

**Key Design**:
```dart
class FieldBuilderContext {
  // Exposed for advanced use
  final FormController controller;
  final Field field;
  final FormTheme theme;
  final FieldState state;
  final FieldColorScheme colors;

  // Lazy-initialized resources
  TextEditingController? _textController;
  FocusNode? _focusNode;

  // Convenience methods
  T? getValue<T>() => controller.getFieldValue<T>(field.id);
  void setValue<T>(T value) => controller.updateFieldValue<T>(field.id, value);
  void addError(String reason) { /* ... */ }
  void clearErrors() => controller.clearErrors(field.id);
  bool get hasFocus => controller.isFieldFocused(field.id);

  TextEditingController getTextController() {
    _textController ??= controller.getTextEditingController(field.id);
    return _textController!;
  }

  FocusNode getFocusNode() {
    _focusNode ??= FocusNode();
    controller.addFieldController(field.id, _focusNode!);
    return _focusNode!;
  }
}
```

**Integration**: Constructed by Form widget's field builder, passed to all custom field builders.

### 2. StatefulFieldWidget Base Class

**Location**: `lib/widgets_external/stateful_field_widget.dart`

**Key Design**:
```dart
abstract class StatefulFieldWidget<T extends Field> extends StatefulWidget {
  final FieldBuilderContext context;

  const StatefulFieldWidget({required this.context, super.key});

  // Abstract method for subclasses
  Widget buildWithTheme(BuildContext context, FormTheme theme, FieldBuilderContext ctx);

  // Optional lifecycle hooks
  void onValueChanged(dynamic oldValue, dynamic newValue) {}
  void onFocusChanged(bool isFocused) {}
  void onValidate() {
    // Default: trigger validation if validateLive is true
    if (context.field.validateLive) {
      context.controller.validateField(context.field.id);
    }
  }

  @override
  State<StatefulFieldWidget> createState() => _StatefulFieldWidgetState<T>();
}

class _StatefulFieldWidgetState<T extends Field> extends State<StatefulFieldWidget<T>> {
  late dynamic _lastValue;
  late bool _lastFocusState;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.context.getValue();
    _lastFocusState = widget.context.hasFocus;
    widget.context.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final newValue = widget.context.getValue();
    final newFocus = widget.context.hasFocus;

    if (newValue != _lastValue) {
      widget.onValueChanged(_lastValue, newValue);
      _lastValue = newValue;
    }

    if (newFocus != _lastFocusState) {
      widget.onFocusChanged(newFocus);
      _lastFocusState = newFocus;

      // Trigger validation on focus loss
      if (!newFocus) {
        widget.onValidate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildWithTheme(context, widget.context.theme, widget.context);
  }

  @override
  void dispose() {
    widget.context.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}
```

**Validation**: Automatic on focus loss if validateLive enabled, with override hook for custom behavior.

### 3. Simplified FormFieldRegistry

**Location**: Update `lib/core/field_builder_registry.dart`

**Key Changes**:
```dart
class FormFieldRegistry {
  // Private singleton instance
  static final FormFieldRegistry _instance = FormFieldRegistry._internal();
  FormFieldRegistry._internal();

  // Public static methods (new API)
  static void register<T extends Field>(
    String typeName,
    FormFieldBuilder builder, {
    FieldConverters? converters,
  }) {
    _instance._registerInternal<T>(typeName, builder, converters);
  }

  static bool hasBuilderFor<T extends Field>() {
    return _instance._builders.containsKey(T);
  }

  // Legacy instance accessor (backward compatible)
  static FormFieldRegistry get instance => _instance;

  // Internal implementation
  final Map<Type, FormFieldBuilder> _builders = {};

  void _registerInternal<T extends Field>(
    String typeName,
    FormFieldBuilder builder,
    FieldConverters? converters,
  ) {
    _builders[T] = builder;
    if (converters != null) {
      // Store converters for later use
    }
  }
}
```

**Unified Signature**: All builders use `FormFieldBuilder = Widget Function(FieldBuilderContext)`

### 4. Converter Mixins

**Location**: `lib/models/field_converters.dart`

**Key Design**:
```dart
abstract class FieldConverters {
  String Function(dynamic value) get asStringConverter;
  List<String> Function(dynamic value) get asStringListConverter;
  bool Function(dynamic value) get asBoolConverter;
  List<FileModel>? Function(dynamic value)? get asFileListConverter;
}

mixin TextFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is String) return value;
    if (value == null) return "";
    throw TypeError(); // Explicit failure
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is String) return [value];
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is String) return value.isNotEmpty;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}

mixin MultiselectFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is List<FieldOption>) {
      return value.map((o) => o.label).join(", ");
    }
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is List<FieldOption>) {
      return value.map((o) => o.value).toList();
    }
    if (value == null) return [];
    throw TypeError();
  };

  // ... other converters
}

// Similar mixins for FileFieldConverters, NumericFieldConverters
```

**Error Handling**: All converters throw TypeError on invalid input for explicit failure reporting.

### 5. Built-in Field Refactoring

**Example: TextField Refactor**

Before (~150 lines):
```dart
class TextFieldWidget extends StatefulWidget {
  // 50+ lines of boilerplate: initState, dispose, listeners, etc.
}
```

After (~40 lines):
```dart
class TextFieldWidget extends StatefulFieldWidget<TextField> {
  TextFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, FieldBuilderContext ctx) {
    final textController = ctx.getTextController();
    final focusNode = ctx.getFocusNode();

    return Material.TextField(
      controller: textController,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: ctx.field.textFieldTitle,
        hintText: ctx.field.hintText,
      ),
      // ... other properties
    );
  }

  @override
  void onValueChanged(oldValue, newValue) {
    if (ctx.field.onChange != null) {
      ctx.field.onChange!(FormResults.getResults(controller: ctx.controller));
    }
  }
}
```

**Refactoring Priority**:
1. TextField (most commonly extended)
2. OptionSelect (base for CheckboxSelect, ChipSelect)
3. FileUpload
4. CheckboxSelect / ChipSelect (inherit from OptionSelect refactor)

### 6. Documentation Structure

**New `docs/` folder**:
```
docs/
├── README.md (overview, getting started)
├── custom-fields/
│   ├── custom-field-cookbook.md (5+ examples)
│   ├── field-builder-context.md (API reference)
│   ├── stateful-field-widget.md (base class guide)
│   └── converters.md (converter mixins guide)
├── migrations/
│   ├── MIGRATION-0.4.0.md (moved from root)
│   └── MIGRATION-0.6.0.md (new)
├── api/
│   ├── form-controller.md
│   ├── field-types.md
│   └── validation.md
└── themes/
    ├── theming-guide.md
    └── custom-themes.md
```

**Migration Guide (MIGRATION-0.6.0.md)**:
- Breaking changes summary
- Before/after code comparisons
- Step-by-step migration instructions for existing custom fields
- Deprecation notices (none, clean break)

**Custom Field Cookbook Examples**:
1. Simple text field variant (e.g., phone number field with formatting)
2. Custom multiselect (e.g., tag selector with autocomplete)
3. Rich text editor field
4. Date/time picker field
5. Signature pad field
6. File upload with preview

**Emphasis in Docs**:
- File-based custom fields (`lib/custom_fields/my_field.dart`) for NEW field types
- Inline builders (`field.fieldBuilder = (ctx) => ...`) for DESIGN customization of existing types

### 7. Testing Strategy

**Unit Tests** (`test/custom_field_api_test.dart`):
- FieldBuilderContext convenience methods
- StatefulFieldWidget lifecycle hooks
- Converter mixin behavior (valid inputs, exception throwing)
- FormFieldRegistry.register() static API
- Theme cascading in FieldBuilderContext

**Widget Tests** (`test/stateful_field_widget_test.dart`):
- StatefulFieldWidget rebuild behavior
- Focus change detection
- Value change detection
- Automatic validation on focus loss
- Resource disposal (TextEditingController, FocusNode)

**Integration Tests** (`example/test/custom_field_integration_test.dart`):
- Complete custom field lifecycle
- Controller integration
- Theme application
- Validation flow
- Form submission with custom fields

**Refactor Validation Tests**:
- Ensure TextField refactor passes all existing tests
- Ensure OptionSelect refactor passes all existing tests
- Ensure FileUpload refactor passes all existing tests
- Performance benchmarks (no regression)

### 8. Example App Updates

**Add Custom Field Demos** (`example/lib/custom_fields/`):
1. `rating_field.dart` - Star rating custom field (file-based)
   - Demonstrates StatefulFieldWidget
   - Shows custom value type (int)
   - Includes custom validation
2. `styled_text_field.dart` - Themed text field (inline builder)
   - Demonstrates inline fieldBuilder customization
   - Shows theme override
   - Uses existing TextField type

**Update Example App** (`example/lib/main.dart`):
- Add "Custom Fields" tab
- Show both file-based and inline approaches
- Include validation examples
- Show results handling

## Reusable Components

### Existing Code to Leverage

**FormController**:
- State management patterns (fieldValues map, formErrors, focusListenable)
- Focus management (`setFieldFocus`, `isFieldFocused`, `currentlyFocusedFieldId`)
- Validation system (`validateField`, `validateForm`)
- Controller lifecycle (`addFieldController`, `getFieldController`, disposal)
- Value accessors (`getFieldValue`, `updateFieldValue`)

**FormFieldRegistry**:
- Singleton pattern implementation
- Type-based registration system
- Builder storage and lookup
- Error placeholder generation

**Field Base Classes**:
- Field abstract class with shared properties (validators, defaultValue, onChange, etc.)
- FieldBase interface
- Converter function signatures (asStringConverter, etc.)

**Theme System**:
- FormTheme cascade logic (Default → Global → Form → Field)
- FieldColorScheme states (normal, active, error, disabled, selected)
- Theme.withDefaults() method
- FormThemeSingleton for global overrides

**Existing Field Implementations**:
- TextEditingController management patterns in TextField
- FocusNode integration patterns
- Validation triggering on focus loss
- onChange/onSubmit callback patterns
- Autocomplete overlay integration

### New Components Required

**FieldBuilderContext** - No existing equivalent
- Why: Current API passes 6 separate parameters; need bundled context
- Purpose: Reduce boilerplate and provide convenience methods

**StatefulFieldWidget** - No existing equivalent
- Why: Current fields manually implement lifecycle boilerplate
- Purpose: Abstract common patterns and provide lifecycle hooks

**Converter Mixins** - Partially exists in Field classes
- Why: Current converters are spread across individual Field implementations
- Purpose: Reusable, composable converter implementations

**Static FormFieldRegistry Methods** - Enhancement to existing singleton
- Why: Current API requires `.instance.registerBuilder<T>()`
- Purpose: Simpler API surface for registration

**Unified Builder Signature** - Replaces existing FormFieldBuilder typedef
- Why: Current signature has 6 parameters
- Purpose: Single FieldBuilderContext parameter

## Migration Strategy

### Phase 1: Foundation (Week 1)
1. Implement FieldBuilderContext class
2. Implement converter mixins (Text, Multiselect, File, Numeric)
3. Add static methods to FormFieldRegistry
4. Comprehensive unit tests for new components

### Phase 2: Base Class (Week 2)
1. Implement StatefulFieldWidget abstract base class
2. Implement _StatefulFieldWidgetState lifecycle management
3. Widget tests for StatefulFieldWidget
4. Performance tests (lazy init, rebuild prevention)

### Phase 3: Built-in Refactor (Week 3)
1. Refactor TextField to use StatefulFieldWidget
2. Refactor OptionSelect to use StatefulFieldWidget
3. Refactor FileUpload to use StatefulFieldWidget
4. Validate all existing tests pass
5. Refactor CheckboxSelect and ChipSelect (inherit from OptionSelect)

### Phase 4: Documentation (Week 4)
1. Create docs/ folder structure
2. Move existing docs into docs/
3. Write MIGRATION-0.6.0.md
4. Write custom-field-cookbook.md with 5+ examples
5. Write API reference docs (FieldBuilderContext, StatefulFieldWidget, converters)
6. Update README.md to reference new docs structure

### Phase 5: Examples (Week 5)
1. Create rating_field.dart custom field example
2. Create styled_text_field.dart inline builder example
3. Update example app with "Custom Fields" tab
4. Integration tests for custom field examples

### Phase 6: Release (Week 6)
1. Update CHANGELOG.md with breaking changes
2. Update pubspec.yaml to version 0.6.0
3. Final review and testing
4. Publish to pub.dev
5. Announce breaking changes in README

## Out of Scope

- Automated migration tooling (manual migration via docs is sufficient)
- Deprecation period or backward compatibility layer (clean break acceptable for 0.x)
- Changes to FormController core architecture
- Changes to validation system design
- Changes to FormResults/FieldResultAccessor APIs
- New field types beyond refactoring existing built-ins
- Platform-specific code changes
- Video tutorials or interactive documentation
- Visual form builder tools
- Additional converter types beyond Text/Multiselect/File/Numeric

## Success Criteria

### Quantitative Metrics
- Custom field boilerplate reduced from 120-150 lines to 30-50 lines (60-70% reduction)
- All existing tests pass after built-in field refactoring
- Zero performance regression in field rendering benchmarks
- 100% dartdoc coverage on new public APIs
- Zero errors from `flutter analyze`
- Zero errors from `dart run custom_lint`

### Qualitative Metrics
- Custom field creation is demonstrably simpler (via cookbook examples)
- Documentation clearly guides users to file-based vs inline approaches
- Migration guide enables users to update existing custom fields independently
- Built-in fields serve as reference implementations for custom fields
- API feels natural and follows Dart/Flutter conventions
- Community feedback is positive on reduced complexity

### Validation Checklist
- [ ] FieldBuilderContext provides all necessary controller access
- [ ] StatefulFieldWidget handles all lifecycle boilerplate automatically
- [ ] Converter mixins eliminate type conversion boilerplate
- [ ] FormFieldRegistry.register() works with static method syntax
- [ ] All built-in fields successfully refactored to new API
- [ ] All existing tests pass without modification
- [ ] Custom field cookbook includes 5+ working examples
- [ ] Migration guide is comprehensive and actionable
- [ ] Example app demonstrates both file-based and inline approaches
- [ ] Zero breaking changes to FormController, validation, or theme systems

# Migration Guide: v0.5.x → v0.6.0

This guide will help you upgrade from ChampionForms v0.5.x to v0.6.0.

## Overview

Version 0.6.0 is a **breaking change release** that dramatically simplifies custom field creation by reducing boilerplate from **120-150 lines to 30-50 lines** (60-70% reduction).

**Key Highlights:**
- ✨ **FieldBuilderContext**: Bundles 6 parameters into one clean context object
- ✨ **StatefulFieldWidget**: Abstract base class with automatic lifecycle management
- ✨ **Converter Mixins**: Reusable type conversion logic for different field types
- ✨ **Simplified FormFieldRegistry**: Static registration methods (`register()`, `hasBuilderFor()`)
- ✨ **Unified Builder Signature**: Single FieldBuilderContext parameter instead of 6 separate parameters
- ⚡ **Performance Optimizations**: Lazy initialization, rebuild prevention
- 🔧 **No automated migration script**: Manual migration required (see guide below)

**Who This Affects:**
- ✅ **Custom field developers**: If you've created custom field types, you need to migrate
- ❌ **Regular users**: If you only use built-in fields (TextField, OptionSelect, FileUpload), **no changes required**

**Migration Time Estimate:** 30-60 minutes per custom field

---

## Breaking Changes Summary

### 1. FormFieldBuilder Signature Change
**Before (v0.5.x):**
```dart
typedef FormFieldBuilder = Widget Function(
  FormController controller,
  Field field,
  FormTheme theme,
  List<Validator> validators,
  FieldCallbacks callbacks,
  FieldState state,
);
```

**After (v0.6.0):**
```dart
typedef FormFieldBuilder = Widget Function(FieldBuilderContext context);
```

### 2. FormFieldRegistry Registration Method
**Before (v0.5.x):**
```dart
FormFieldRegistry.instance.registerField('customField', (controller, field, theme, validators, callbacks, state) {
  // 6 parameters
  return CustomFieldWidget(...);
});
```

**After (v0.6.0):**
```dart
FormFieldRegistry.register<CustomField>('customField', (ctx) {
  // Single context parameter
  return CustomFieldWidget(context: ctx);
});
```

### 3. Built-in Fields Refactored (Internal Change)
Built-in fields (TextField, OptionSelect, FileUpload, etc.) now use the new API internally. **No changes required for users** - the public API remains the same.

---

## Before/After Code Comparison

### Example: Custom Rating Field

**Before (v0.5.x): ~120-150 lines**

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class RatingFieldWidget extends StatefulWidget {
  final form.FormController controller;
  final form.Field field;
  final FormTheme theme;
  final List<form.Validator> validators;

  const RatingFieldWidget({
    Key? key,
    required this.controller,
    required this.field,
    required this.theme,
    required this.validators,
  }) : super(key: key);

  @override
  State<RatingFieldWidget> createState() => _RatingFieldWidgetState();
}

class _RatingFieldWidgetState extends State<RatingFieldWidget> {
  late int _currentRating;
  late bool _isFocused;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.controller.getFieldValue<int>(widget.field.id) ?? 0;
    _isFocused = widget.controller.isFieldFocused(widget.field.id);
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final newRating = widget.controller.getFieldValue<int>(widget.field.id) ?? 0;
    final newFocus = widget.controller.isFieldFocused(widget.field.id);

    if (newRating != _currentRating || newFocus != _isFocused) {
      setState(() {
        _currentRating = newRating;
        _isFocused = newFocus;
      });

      // Validate on blur
      if (_isFocused && !newFocus && widget.field.validateLive) {
        widget.controller.validateField(widget.field.id);
      }
    }
  }

  void _updateRating(int rating) {
    widget.controller.updateFieldValue<int>(widget.field.id, rating);

    // Trigger onChange callback if provided
    if (widget.field.onChange != null) {
      final results = form.FormResults.getResults(controller: widget.controller);
      widget.field.onChange!(results);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.field.title != null)
          Text(widget.field.title!, style: widget.theme.titleTextStyle),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                color: widget.theme.activeColors.borderColor,
              ),
              onPressed: () => _updateRating(index + 1),
            );
          }),
        ),
        // Error display logic...
      ],
    );
  }
}

// Register the field
void registerRatingField() {
  FormFieldRegistry.instance.registerField(
    'rating',
    (controller, field, theme, validators, callbacks, state) {
      return RatingFieldWidget(
        controller: controller,
        field: field,
        theme: theme,
        validators: validators,
      );
    },
  );
}
```

**After (v0.6.0): ~30-50 lines**

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class RatingFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const RatingFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    final rating = ctx.getValue<int>() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Text(ctx.field.title!, style: theme.titleTextStyle),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: ctx.colors.borderColor,
              ),
              onPressed: () => ctx.setValue<int>(index + 1),
            );
          }),
        ),
        // Error display automatically handled by Form widget
      ],
    );
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    // Trigger onChange callback if provided
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}

// Register the field
void registerRatingField() {
  form.FormFieldRegistry.register<form.Field>(
    'rating',
    (ctx) => RatingFieldWidget(context: ctx),
  );
}
```

**Key Improvements:**
- ❌ Removed manual controller listener setup/teardown (~20 lines)
- ❌ Removed manual state tracking (_currentRating, _isFocused) (~10 lines)
- ❌ Removed manual focus/value change detection (~20 lines)
- ❌ Removed manual validation triggering (~5 lines)
- ❌ Removed dispose() boilerplate (~5 lines)
- ✅ Automatic lifecycle management via StatefulFieldWidget
- ✅ Clean context-based API (ctx.getValue, ctx.setValue, ctx.colors)
- ✅ Optional lifecycle hooks (onValueChanged, onFocusChanged, onValidate)

---

## Step-by-Step Migration Instructions

### Step 1: Update Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.6.0
```

Run:
```bash
flutter pub upgrade championforms
```

### Step 2: Identify Custom Fields to Migrate

Search your codebase for:
- `FormFieldRegistry.instance.registerField()` calls
- `Field.fieldBuilder` property usage (inline builders)
- Custom widgets that take `FormController` and `Field` parameters

### Step 3: Migrate Custom Field Widgets

For each custom field widget:

#### A. Extend StatefulFieldWidget

**Before:**
```dart
class MyCustomField extends StatefulWidget {
  final FormController controller;
  final Field field;
  final FormTheme theme;
  // ...
}
```

**After:**
```dart
class MyCustomField extends form.StatefulFieldWidget<form.Field> {
  const MyCustomField({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    // Your UI code
  }
}
```

#### B. Replace Parameter Access

**Before:**
```dart
widget.controller.getFieldValue<T>(widget.field.id)
widget.controller.updateFieldValue<T>(widget.field.id, value)
widget.field.title
widget.theme.titleTextStyle
```

**After:**
```dart
ctx.getValue<T>()          // or context.getValue<T>()
ctx.setValue<T>(value)     // or context.setValue<T>(value)
ctx.field.title            // or context.field.title
theme.titleTextStyle       // passed as parameter to buildWithTheme
ctx.colors.borderColor     // state-aware color access
```

#### C. Remove Lifecycle Boilerplate

Delete these methods (handled automatically by StatefulFieldWidget):
- `initState()` with `controller.addListener()`
- `dispose()` with `controller.removeListener()`
- `_onControllerUpdate()` change detection logic
- Manual state variables for tracking values/focus

#### D. Use Lifecycle Hooks (Optional)

If you need custom behavior on value/focus changes:

```dart
@override
void onValueChanged(dynamic oldValue, dynamic newValue) {
  // Called automatically when value changes
  if (context.field.onChange != null) {
    final results = form.FormResults.getResults(controller: context.controller);
    context.field.onChange!(results);
  }
}

@override
void onFocusChanged(bool isFocused) {
  // Called automatically when focus changes
  print('Field ${context.field.id} focus: $isFocused');
}

@override
void onValidate() {
  // Custom validation logic (default triggers validation if validateLive is true)
  super.onValidate(); // Call default behavior
  // Add custom validation logic here
}
```

### Step 4: Update Registration Calls

**Before:**
```dart
FormFieldRegistry.instance.registerField('myField', (controller, field, theme, validators, callbacks, state) {
  return MyCustomFieldWidget(
    controller: controller,
    field: field,
    theme: theme,
    validators: validators,
  );
});
```

**After:**
```dart
form.FormFieldRegistry.register<form.Field>('myField', (ctx) {
  return MyCustomFieldWidget(context: ctx);
});
```

### Step 5: Update Inline Field Builders (If Used)

If you're using `field.fieldBuilder` for inline customization:

**Before:**
```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email',
  fieldBuilder: (controller, field, theme, validators, callbacks, state) {
    return CustomizedTextField(controller: controller, field: field, theme: theme);
  },
)
```

**After:**
```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email',
  fieldBuilder: (ctx) {
    return CustomizedTextField(context: ctx);
  },
)
```

### Step 6: Test Your Custom Fields

1. Run your app and verify custom fields render correctly
2. Test value updates (typing, selection, etc.)
3. Test validation (on blur if validateLive: true)
4. Test onChange/onSubmit callbacks
5. Test form submission with `FormResults.getResults()`
6. Check for console errors or warnings

---

## Migration Checklist

Use this checklist when migrating each custom field:

- [ ] Updated `pubspec.yaml` to v0.6.0
- [ ] Ran `flutter pub upgrade`
- [ ] Changed widget to extend `form.StatefulFieldWidget<form.Field>`
- [ ] Replaced constructor parameters with `required super.context`
- [ ] Renamed `build()` to `buildWithTheme(BuildContext, FormTheme, FieldBuilderContext)`
- [ ] Updated all field value access to use `ctx.getValue<T>()`
- [ ] Updated all field value updates to use `ctx.setValue<T>(value)`
- [ ] Updated theme access to use `theme` parameter and `ctx.colors`
- [ ] Removed `initState()` controller listener setup
- [ ] Removed `dispose()` controller listener cleanup
- [ ] Removed manual state tracking variables
- [ ] Removed manual change detection logic
- [ ] Added `onValueChanged()` hook if onChange callback needed
- [ ] Added `onFocusChanged()` hook if focus behavior needed
- [ ] Updated registration call to use `FormFieldRegistry.register<T>()`
- [ ] Updated registration builder to use single `(ctx)` parameter
- [ ] Updated inline builders (if any) to use `(ctx)` parameter
- [ ] Tested field rendering
- [ ] Tested value updates
- [ ] Tested validation
- [ ] Tested callbacks
- [ ] Tested form submission

---

## Common Migration Pitfalls

### Pitfall 1: Forgetting to Use Context Parameter Name

**Problem:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  // Using 'context' for BuildContext but also accessing FieldBuilderContext
  final value = context.getValue(); // ERROR: BuildContext doesn't have getValue()
}
```

**Solution:**
```dart
@override
Widget buildWithTheme(BuildContext buildContext, FormTheme theme, form.FieldBuilderContext ctx) {
  // Use 'buildContext' for BuildContext, 'ctx' for FieldBuilderContext
  final value = ctx.getValue();
  return Container(...); // buildContext used for widget tree
}
```

**Alternative:**
```dart
class MyField extends form.StatefulFieldWidget<form.Field> {
  const MyField({required super.context}); // 'context' is FieldBuilderContext

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    // Use 'this.context' for FieldBuilderContext (from StatefulFieldWidget)
    // Use 'ctx' for convenience parameter (same as this.context)
    // Use 'context' for BuildContext (shadows parent property)
    final value = this.context.getValue(); // or ctx.getValue()
  }
}
```

### Pitfall 2: Not Removing Old Lifecycle Code

**Problem:**
```dart
class MyField extends form.StatefulFieldWidget<form.Field> {
  @override
  void initState() {
    super.initState();
    // Old code: widget.controller.addListener(_onUpdate); // DON'T DO THIS
  }
}
```

**Solution:**
Remove all manual listener setup - StatefulFieldWidget handles it automatically.

### Pitfall 3: Trying to Access TextEditingController/FocusNode Incorrectly

**Problem:**
```dart
// Old way - no longer accessible
final textController = widget.controller.getTextEditingController(widget.field.id);
```

**Solution:**
```dart
// New way - lazy initialization via context
final textController = ctx.getTextController();
final focusNode = ctx.getFocusNode();
```

### Pitfall 4: Forgetting Generic Type in Registration

**Problem:**
```dart
FormFieldRegistry.register('myField', (ctx) => MyWidget(context: ctx));
// Missing generic type parameter
```

**Solution:**
```dart
FormFieldRegistry.register<form.Field>('myField', (ctx) => MyWidget(context: ctx));
// Or use custom field type if you have one:
FormFieldRegistry.register<MyCustomFieldType>('myField', (ctx) => MyWidget(context: ctx));
```

### Pitfall 5: Not Testing Validation Behavior

**Problem:**
Validation might not trigger correctly if you override `onValidate()` without calling super.

**Solution:**
```dart
@override
void onValidate() {
  super.onValidate(); // Call this first to get default behavior
  // Add custom validation logic here
}
```

---

## Converter Mixins (Advanced)

If your custom field needs type conversion for FormResults (e.g., `results.grab('field').asString()`), you can implement converter mixins.

### Example: Custom Numeric Field with Converters

```dart
class NumericFieldConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is int || value is double) return value.toString();
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is int || value is double) return [value.toString()];
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is int || value is double) return value != 0;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter => null;
}

// Register with converters
form.FormFieldRegistry.register<MyNumericField>(
  'numeric',
  (ctx) => MyNumericFieldWidget(context: ctx),
  converters: NumericFieldConverters(),
);
```

See [Converters Guide](../custom-fields/converters.md) for more details.

---

## FAQ

### Q: Do I need to migrate if I only use built-in fields?
**A:** No! Built-in fields (TextField, OptionSelect, FileUpload, etc.) continue to work without any changes. You only need to migrate if you've created custom field types.

### Q: Can I mix v0.5.x and v0.6.0 custom fields in the same app?
**A:** No. Once you upgrade to v0.6.0, all custom fields must use the new API. We recommend migrating all custom fields at once.

### Q: What if I have a lot of custom fields?
**A:** Migrate them incrementally in a feature branch. The pattern is consistent across all fields, so after migrating the first one, the rest will be faster.

### Q: Do I need to use StatefulFieldWidget, or can I use a regular StatefulWidget?
**A:** You don't *have* to use StatefulFieldWidget, but you'll lose all the automatic lifecycle management, boilerplate reduction, and performance optimizations. We strongly recommend using it.

### Q: Can I still access the FormController directly?
**A:** Yes! `ctx.controller` gives you direct access to the FormController for advanced use cases.

### Q: What happened to the 6-parameter builder signature?
**A:** It's been replaced with a single `FieldBuilderContext` parameter that bundles all 6 parameters plus adds convenience methods. This reduces complexity and makes the API cleaner.

### Q: How do I handle focus management now?
**A:** StatefulFieldWidget handles focus automatically. Use `ctx.getFocusNode()` for the FocusNode if you need it, and override `onFocusChanged(bool isFocused)` if you need custom focus behavior.

### Q: Will there be a v0.7.0 that breaks custom fields again?
**A:** No plans for further breaking changes to the custom field API. v0.6.0 establishes the long-term pattern.

---

## Getting Help

If you encounter issues during migration:

1. Check the [Custom Field Cookbook](../custom-fields/custom-field-cookbook.md) for working examples
2. Review the [FieldBuilderContext API Reference](../custom-fields/field-builder-context.md)
3. Read the [StatefulFieldWidget Guide](../custom-fields/stateful-field-widget.md)
4. Open an issue on [GitHub](https://github.com/fabier/championforms/issues) with your migration question

---

## What's Next?

After migrating, explore the new capabilities:

- **Performance**: Lazy initialization and rebuild prevention
- **Cleaner Code**: 60-70% less boilerplate
- **Better Patterns**: Reusable converter mixins
- **Easier Maintenance**: Built-in fields use the same patterns as custom fields

Check out the [Custom Field Cookbook](../custom-fields/custom-field-cookbook.md) for inspiration on what you can build with the simplified API!

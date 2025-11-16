# FieldBuilderContext API Reference

Complete API documentation for the `FieldBuilderContext` class introduced in ChampionForms v0.6.0.

## Overview

`FieldBuilderContext` is the cornerstone of the simplified custom field API in v0.6.0. It bundles all parameters needed by field builders into a single context object, reducing the builder signature from 6 parameters to 1.

**Location:** `lib/models/field_builder_context.dart`

**Purpose:**
- Simplify field builder signatures
- Provide convenient helper methods
- Support lazy resource initialization
- Enable theme-aware field development

## Table of Contents

1. [Quick Start](#quick-start)
2. [Public Properties](#public-properties)
3. [Convenience Methods](#convenience-methods)
   - [Value Management](#value-management)
   - [Error Management](#error-management)
   - [Focus Management](#focus-management)
   - [Resource Management](#resource-management)
   - [OptionSelect-Specific Methods](#optionselect-specific-methods)
4. [Usage Patterns](#usage-patterns)
5. [Best Practices](#best-practices)
6. [Advanced Use Cases](#advanced-use-cases)

---

## Quick Start

### Basic Usage in Custom Field

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class MyCustomField extends form.StatefulFieldWidget<form.Field> {
  const MyCustomField({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    // Get current value
    final value = ctx.getValue<String>() ?? '';

    // Access field properties
    final title = ctx.field.title;

    // Use theme-aware colors
    final borderColor = ctx.colors.borderColor;

    return TextField(
      controller: ctx.getTextController(),
      focusNode: ctx.getFocusNode(),
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
      ),
      onChanged: (newValue) {
        ctx.setValue(newValue);
      },
    );
  }
}
```

### Builder Signature Evolution

**Before v0.6.0 (6 parameters):**
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

**v0.6.0+ (single context parameter):**
```dart
typedef FormFieldBuilder = Widget Function(FieldBuilderContext context);
```

---

## Public Properties

All properties are `final` and initialized via the constructor.

### controller
```dart
final FormController controller;
```

**Description:** The `FormController` managing this field's state.

**Use Case:** Advanced operations that require direct controller access.

**Example:**
```dart
// Access other fields' values
final otherValue = ctx.controller.getFieldValue('other_field_id');

// Programmatically set focus
ctx.controller.setFieldFocus(ctx.field.id, true);

// Trigger validation manually
ctx.controller.validateField(ctx.field.id);
```

**Best Practice:** Prefer using context convenience methods over direct controller access when possible.

---

### field
```dart
final Field field;
```

**Description:** The field definition for this field (e.g., `TextField`, `OptionSelect`).

**Properties Available:**
- `field.id` - Unique field identifier
- `field.title` - Display title
- `field.description` - Help text
- `field.validators` - List of validators
- `field.defaultValue` - Default value
- `field.validateLive` - Validate on blur flag
- `field.onChange` - Change callback
- `field.onSubmit` - Submit callback

**Example:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  return Column(
    children: [
      if (ctx.field.title != null)
        Text(ctx.field.title!),
      if (ctx.field.description != null)
        Text(ctx.field.description!, style: theme.hintTextStyle),
      // Field UI
    ],
  );
}
```

---

### theme
```dart
final FormTheme theme;
```

**Description:** The resolved theme for this field after cascading.

**Cascade Order:** Default Theme → Global Theme → Form Theme → Field Theme

**Properties Available:**
- `theme.normalColors` - Colors for normal state
- `theme.activeColors` - Colors for focused state
- `theme.errorColors` - Colors for error state
- `theme.disabledColors` - Colors for disabled state
- `theme.selectedColors` - Colors for selected state
- `theme.titleTextStyle` - Title text styling
- `theme.descriptionTextStyle` - Description text styling
- `theme.hintTextStyle` - Hint text styling
- `theme.chipTextStyle` - Chip text styling
- `theme.inputDecoration` - InputDecoration builder

**Example:**
```dart
Text(
  ctx.field.title!,
  style: ctx.theme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
)
```

---

### state
```dart
final FieldState state;
```

**Description:** The current state of this field.

**Possible Values:**
- `FieldState.normal` - Default state
- `FieldState.active` - Field is focused
- `FieldState.error` - Validation error exists
- `FieldState.disabled` - Field is disabled
- `FieldState.selected` - Option is selected (multiselect)

**Use Case:** Conditional rendering based on field state.

**Example:**
```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: ctx.state == FieldState.error
          ? Colors.red
          : ctx.colors.borderColor,
      width: ctx.state == FieldState.active ? 2 : 1,
    ),
  ),
  child: // Field content
)
```

---

### colors
```dart
final FieldColorScheme colors;
```

**Description:** The color scheme for the current field state (automatically selected from theme based on `state`).

**Properties Available:**
- `colors.backgroundColor` - Background color
- `colors.borderColor` - Border color
- `colors.textColor` - Text color
- `colors.iconColor` - Icon color
- `colors.hintColor` - Hint text color
- `colors.backgroundGradient` - Optional gradient

**Use Case:** Apply theme-aware colors without manual state checking.

**Example:**
```dart
TextField(
  decoration: InputDecoration(
    fillColor: ctx.colors.backgroundColor,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: ctx.colors.borderColor),
    ),
    hintStyle: TextStyle(color: ctx.colors.hintColor),
  ),
)
```

---

## Convenience Methods

### Value Management

#### getValue<T>()
```dart
T? getValue<T>()
```

**Description:** Gets the current value for this field with type safety.

**Returns:** The field's value cast to type `T`, the default value, or `null`.

**Type Parameters:**
- `String` - Text fields
- `List<FieldOption>` - Multiselect fields
- `List<FileModel>` - File upload fields
- `int`, `double` - Numeric fields
- Any custom type

**Example:**
```dart
// Text field
final name = ctx.getValue<String>() ?? '';

// Multiselect
final options = ctx.getValue<List<form.FieldOption>>() ?? [];

// File upload
final files = ctx.getValue<List<form.FileModel>>() ?? [];

// Custom type
final rating = ctx.getValue<int>() ?? 0;
```

**See Also:** [setValue](#setvaluet)

---

#### setValue<T>()
```dart
void setValue<T>(T value, {bool noNotify = false})
```

**Description:** Sets the value for this field.

**Parameters:**
- `value` - The new value to set
- `noNotify` - If `true`, suppresses listener notification (default: `false`)

**Triggers:**
- Controller listeners (unless `noNotify` is true)
- onChange callback (unless `noNotify` is true)
- Widget rebuilds

**Example:**
```dart
// Simple update
ctx.setValue('new value');

// Silent update (no notification)
ctx.setValue('new value', noNotify: true);

// Update multiselect
final updated = List<form.FieldOption>.from(selectedOptions)..add(newOption);
ctx.setValue(updated);

// Update numeric value
ctx.setValue<int>(5);
```

**See Also:** [getValue](#getvaluet)

---

### Error Management

#### addError()
```dart
void addError(String reason)
```

**Description:** Adds a validation error for this field.

**Parameters:**
- `reason` - The error message to display

**Behavior:**
- Does NOT clear existing errors
- Adds error to controller's error list
- Triggers error state for field
- Error displayed by Form widget

**Example:**
```dart
// Add single error
ctx.addError('Invalid email format');

// Add multiple errors
ctx.clearErrors(); // Clear first
ctx.addError('Field is required');
ctx.addError('Must be at least 8 characters');

// Conditional error
if (value.length < 8) {
  ctx.addError('Password must be at least 8 characters');
}
```

**See Also:** [clearErrors](#clearerrors)

---

#### clearErrors()
```dart
void clearErrors()
```

**Description:** Clears all validation errors for this field.

**Behavior:**
- Removes all errors associated with this field's ID
- Resets field state to normal (if no other errors exist)
- Does NOT trigger validation

**Use Case:** Clear errors before re-validating or when value changes.

**Example:**
```dart
// Clear before validating
ctx.clearErrors();
if (isInvalid) {
  ctx.addError('Validation failed');
}

// Clear on value change
@override
void onValueChanged(dynamic oldValue, dynamic newValue) {
  ctx.clearErrors(); // Remove previous errors
}
```

**See Also:** [addError](#adderror)

---

### Focus Management

#### hasFocus
```dart
bool get hasFocus
```

**Description:** Returns whether this field is currently focused.

**Returns:** `true` if focused, `false` otherwise.

**Use Case:** Conditional UI based on focus state.

**Example:**
```dart
// Show autocomplete only when focused
if (ctx.hasFocus) {
  return AutocompleteOverlay(/* ... */);
}

// Change border color on focus
border: Border.all(
  color: ctx.hasFocus
      ? ctx.theme.activeColors.borderColor
      : ctx.colors.borderColor,
),

// Trigger validation on blur
@override
void onFocusChanged(bool isFocused) {
  if (!isFocused && ctx.field.validateLive) {
    ctx.controller.validateField(ctx.field.id);
  }
}
```

**See Also:** [getFocusNode](#getfocusnode)

---

### Resource Management

#### getTextController()
```dart
TextEditingController getTextController()
```

**Description:** Gets or creates a `TextEditingController` for this field (lazy initialization).

**Behavior:**
- Creates controller on first call
- Returns cached instance on subsequent calls
- Automatically registered with FormController
- Automatically disposed by FormController

**Initialization:**
- Initial text set from field's current value
- Synced with field value in controller

**Important:** Do NOT manually dispose the returned controller.

**Example:**
```dart
final textController = ctx.getTextController();

return TextField(
  controller: textController,
  decoration: InputDecoration(
    labelText: ctx.field.title,
  ),
  onChanged: (value) {
    // Controller value automatically updated
    // Optionally trigger callbacks:
    ctx.setValue(value); // Updates controller state
  },
);
```

**Value Synchronization Pattern:**

When fields can be updated programmatically (via `controller.updateTextFieldValue()` or `setValue()`), ensure the TextEditingController stays synchronized:

```dart
final textController = ctx.getTextController();
final value = ctx.getValue<String>() ?? '';

// Ensure controller has current value (prevents stale values)
if (textController.text != value) {
  textController.text = value;
}

return TextField(controller: textController);
```

**Why This Matters:** Without synchronization, external updates (e.g., programmatic field updates, form resets) won't reflect in the TextField until the user types. This pattern ensures the visual state matches the controller state.

**Performance Note:** Only allocated when actually needed - don't call unless you need text editing.

**See Also:** [getFocusNode](#getfocusnode)

---

#### getFocusNode()
```dart
FocusNode getFocusNode()
```

**Description:** Gets or creates a `FocusNode` for this field (lazy initialization).

**Behavior:**
- Creates focus node on first call
- Returns cached instance on subsequent calls
- Automatically registered with FormController
- Automatically disposed by FormController

**Controller Integration:**
- Enables focus state tracking via `hasFocus`
- Enables automatic validation on focus loss
- Enables programmatic focus control

**Important:** Do NOT manually dispose the returned focus node.

**Example:**
```dart
final focusNode = ctx.getFocusNode();

return TextField(
  focusNode: focusNode,
  onFocusChange: (focused) {
    if (!focused && ctx.field.validateLive) {
      ctx.controller.validateField(ctx.field.id);
    }
  },
);
```

**Performance Note:** Only allocated when actually needed - don't call unless you need focus management.

**See Also:** [getTextController](#gettextcontroller), [hasFocus](#hasfocus)

---

### OptionSelect-Specific Methods

When working with `OptionSelect` fields (checkboxes, switches, chip selects, radio buttons), the context provides additional helper methods for managing selected options.

#### isOptionSelected()
```dart
bool isOptionSelected(String optionValue)
```

**Description:** Checks if a specific option is currently selected in a multiselect field.

**Parameters:**
- `optionValue` - The value of the option to check (matches `FieldOption.value`)

**Returns:** `true` if the option is selected, `false` otherwise.

**Use Case:** Determining visual state for checkboxes, switches, and chip selects.

**Example:**
```dart
class SwitchFieldWidget extends form.StatefulFieldWidget<form.OptionSelect> {
  const SwitchFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext buildContext, FormTheme theme, form.FieldBuilderContext ctx) {
    final field = ctx.field as form.OptionSelect;
    final option = field.options.first;

    return Switch(
      value: ctx.isOptionSelected(option.value),
      onChanged: (bool value) {
        ctx.toggleValue(option);
      },
    );
  }
}
```

**Implementation Detail:** This method queries the current field value (which is a `List<FieldOption>` for multiselect fields) and checks if any option has a matching `value` property.

---

#### toggleValue()
```dart
void toggleValue(FieldOption option)
```

**Description:** Toggles the selection state of an option in a multiselect field.

**Parameters:**
- `option` - The `FieldOption` to toggle

**Behavior:**
- If option is selected: Removes it from the selection
- If option is not selected: Adds it to the selection
- Triggers onChange callback
- Notifies controller listeners
- Validates field if `validateLive` is enabled

**Use Case:** Handling user interactions with checkboxes, switches, and chip selects.

**Example:**
```dart
class CheckboxFieldWidget extends form.StatefulFieldWidget<form.OptionSelect> {
  const CheckboxFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext buildContext, FormTheme theme, form.FieldBuilderContext ctx) {
    final field = ctx.field as form.OptionSelect;

    return Column(
      children: field.options.map((option) {
        return CheckboxListTile(
          title: Text(option.label),
          value: ctx.isOptionSelected(option.value),
          onChanged: (bool? checked) {
            ctx.toggleValue(option);
          },
        );
      }).toList(),
    );
  }
}
```

**Alternative Pattern:** For more control, you can manually manage the selected options list:

```dart
// Get current selections
final selectedOptions = ctx.getValue<List<form.FieldOption>>() ?? [];

// Add option
final updated = [...selectedOptions, newOption];
ctx.setValue(updated);

// Remove option
final updated = selectedOptions.where((o) => o.value != optionToRemove.value).toList();
ctx.setValue(updated);
```

**See Also:** [isOptionSelected](#isoptionselected), [setValue](#setvaluet)

---

## Usage Patterns

### Pattern 1: Simple Text Field Variant

```dart
class EmailFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const EmailFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    return TextField(
      controller: ctx.getTextController(),
      focusNode: ctx.getFocusNode(),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: ctx.field.title,
        hintText: 'user@example.com',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: ctx.colors.borderColor),
        ),
      ),
    );
  }
}
```

### Pattern 2: Custom Value Type

```dart
class RatingFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const RatingFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    final rating = ctx.getValue<int>() ?? 0;

    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: ctx.colors.iconColor,
          ),
          onPressed: () => ctx.setValue<int>(index + 1),
        );
      }),
    );
  }
}
```

### Pattern 3: Accessing Other Fields

```dart
class PasswordConfirmField extends form.StatefulFieldWidget<form.Field> {
  const PasswordConfirmField({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    // Access another field's value
    final password = ctx.controller.getFieldValue<String>('password');
    final confirm = ctx.getValue<String>() ?? '';

    // Custom validation
    if (confirm.isNotEmpty && password != confirm) {
      ctx.clearErrors();
      ctx.addError('Passwords do not match');
    }

    return TextField(
      controller: ctx.getTextController(),
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
      ),
    );
  }
}
```

### Pattern 4: Conditional UI Based on State

```dart
class ConditionalFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const ConditionalFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ctx.state == FieldState.error
            ? theme.errorColors.backgroundColor
            : ctx.colors.backgroundColor,
        border: Border.all(
          color: ctx.colors.borderColor,
          width: ctx.state == FieldState.active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextField(controller: ctx.getTextController()),
          if (ctx.state == FieldState.error)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please fix the errors above',
                style: TextStyle(color: theme.errorColors.textColor),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Best Practices

### 1. Use Convenience Methods Over Direct Controller Access

**Good:**
```dart
final value = ctx.getValue<String>();
ctx.setValue('new value');
ctx.clearErrors();
```

**Avoid:**
```dart
final value = ctx.controller.getFieldValue<String>(ctx.field.id);
ctx.controller.updateFieldValue(ctx.field.id, 'new value');
ctx.controller.clearErrors(ctx.field.id);
```

**Reason:** Convenience methods are cleaner, less verbose, and less error-prone.

---

### 2. Lazy Resource Initialization

**Good:**
```dart
// Only create when needed
if (needsTextEditing) {
  final controller = ctx.getTextController();
  // Use controller
}
```

**Avoid:**
```dart
// Don't create unnecessarily
@override
void initState() {
  super.initState();
  final controller = ctx.getTextController(); // Created even if not used
}
```

**Reason:** Lazy initialization improves performance by avoiding unnecessary resource allocation.

---

### 3. Use colors Property for Theme-Aware Styling

**Good:**
```dart
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: ctx.colors.borderColor),
    ),
  ),
)
```

**Avoid:**
```dart
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: ctx.state == FieldState.error
            ? ctx.theme.errorColors.borderColor
            : ctx.state == FieldState.active
                ? ctx.theme.activeColors.borderColor
                : ctx.theme.normalColors.borderColor,
      ),
    ),
  ),
)
```

**Reason:** `ctx.colors` automatically selects the correct color scheme for the current state.

---

### 4. Clear Errors Before Adding New Ones

**Good:**
```dart
void validateEmail(String email) {
  ctx.clearErrors(); // Clear previous errors first
  if (email.isEmpty) {
    ctx.addError('Email is required');
  } else if (!isValidEmail(email)) {
    ctx.addError('Invalid email format');
  }
}
```

**Avoid:**
```dart
void validateEmail(String email) {
  // Errors accumulate without clearing
  if (email.isEmpty) {
    ctx.addError('Email is required');
  }
  if (!isValidEmail(email)) {
    ctx.addError('Invalid email format');
  }
}
```

**Reason:** Prevents error accumulation and ensures only current errors are displayed.

---

### 5. Trigger onChange Callbacks in onValueChanged Hook

**Good:**
```dart
@override
void onValueChanged(dynamic oldValue, dynamic newValue) {
  if (context.field.onChange != null) {
    final results = form.FormResults.getResults(controller: context.controller);
    context.field.onChange!(results);
  }
}
```

**Avoid:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  return TextField(
    onChanged: (value) {
      ctx.setValue(value);
      // Triggering onChange here causes it to fire multiple times per change
      if (ctx.field.onChange != null) {
        final results = form.FormResults.getResults(controller: ctx.controller);
        ctx.field.onChange!(results);
      }
    },
  );
}
```

**Reason:** `onValueChanged` hook is called once per value change, preventing duplicate callback invocations.

---

## Advanced Use Cases

### Multi-Field Validation

Validate this field based on another field's value:

```dart
class PasswordConfirmField extends form.StatefulFieldWidget<form.Field> {
  const PasswordConfirmField({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    return TextField(
      controller: ctx.getTextController(),
      obscureText: true,
      onChanged: (value) {
        _validatePasswordMatch(ctx, value);
      },
    );
  }

  void _validatePasswordMatch(form.FieldBuilderContext ctx, String confirmValue) {
    final password = ctx.controller.getFieldValue<String>('password');

    ctx.clearErrors();
    if (confirmValue.isNotEmpty && password != confirmValue) {
      ctx.addError('Passwords do not match');
    }
  }
}
```

### Programmatic Focus Control

```dart
// Focus this field programmatically
ctx.controller.setFieldFocus(ctx.field.id, true);

// Focus another field
ctx.controller.setFieldFocus('other_field_id', true);

// Remove focus from all fields
ctx.controller.setFieldFocus(ctx.field.id, false);
```

### Silent Value Updates

Update value without triggering onChange or rebuilding widgets:

```dart
// Silent update (useful for initialization)
ctx.setValue('initial value', noNotify: true);

// Normal update (triggers onChange and rebuilds)
ctx.setValue('user input');
```

### Accessing Active Fields

Get all currently rendered fields:

```dart
final activeFields = ctx.controller.activeFields;
print('Form has ${activeFields.length} active fields');

// Check if a specific field is active
final isActive = activeFields.any((f) => f.id == 'email');
```

---

## Related Documentation

- [StatefulFieldWidget Guide](stateful-field-widget.md) - Base class using FieldBuilderContext
- [Custom Field Cookbook](custom-field-cookbook.md) - Practical examples
- [Converters Guide](converters.md) - Type conversion patterns
- [Migration Guide v0.5.x → v0.6.0](../migrations/MIGRATION-0.6.0.md) - Upgrade instructions

---

## Summary

`FieldBuilderContext` dramatically simplifies custom field development by:

✅ **Bundling 6 parameters into 1 context object**
✅ **Providing convenient helper methods for common operations**
✅ **Supporting lazy resource initialization for performance**
✅ **Enabling theme-aware field development**
✅ **Exposing full controller access for advanced use cases**

With FieldBuilderContext, custom field boilerplate is reduced from **120-150 lines to 30-50 lines** (60-70% reduction).

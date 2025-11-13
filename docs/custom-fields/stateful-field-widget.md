# StatefulFieldWidget Guide

Complete guide to building custom fields with the `StatefulFieldWidget` base class in ChampionForms v0.6.0+.

## Overview

`StatefulFieldWidget` is an abstract base class that eliminates ~50 lines of boilerplate per custom field by automatically handling:
- Controller listener registration/disposal
- Value and focus change detection
- Automatic validation on focus loss
- Performance-optimized rebuilds

**Location:** `lib/widgets_external/stateful_field_widget.dart`

**Boilerplate Reduction:** From ~120-150 lines to ~30-50 lines (60-70% reduction)

## Table of Contents

1. [Quick Start](#quick-start)
2. [Base Class API](#base-class-api)
3. [Lifecycle Hooks](#lifecycle-hooks)
4. [Complete Example](#complete-example)
5. [Advanced Patterns](#advanced-patterns)
6. [Best Practices](#best-practices)
7. [Performance Tips](#performance-tips)

---

## Quick Start

### Minimal Custom Field

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class SimpleTextField extends form.StatefulFieldWidget {
  const SimpleTextField({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    return TextField(
      controller: ctx.getTextController(),
      focusNode: ctx.getFocusNode(),
      decoration: InputDecoration(
        labelText: ctx.field.title,
      ),
    );
  }
}
```

**That's it!** No `initState`, `dispose`, listener setup, or change detection needed.

---

## Base Class API

### Constructor

```dart
const StatefulFieldWidget({
  required FieldBuilderContext context,
  Key? key,
});
```

**Parameters:**
- `context` - The `FieldBuilderContext` containing controller, field, theme, etc.
- `key` - Optional widget key (passed to `super.key`)

### Abstract Method: buildWithTheme

```dart
Widget buildWithTheme(
  BuildContext context,
  FormTheme theme,
  FieldBuilderContext ctx,
);
```

**Must be implemented by subclasses.**

**Parameters:**
- `context` - Flutter BuildContext (for widget tree operations)
- `theme` - Resolved FormTheme (after cascading)
- `ctx` - FieldBuilderContext (for field operations)

**Returns:** The widget to display for this field.

**Example:**
```dart
@override
Widget buildWithTheme(
  BuildContext buildContext,
  FormTheme theme,
  form.FieldBuilderContext ctx,
) {
  final value = ctx.getValue<String>() ?? '';

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: ctx.colors.borderColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(value),
  );
}
```

---

## Lifecycle Hooks

All lifecycle hooks are **optional** - override only what you need.

### onValueChanged

```dart
void onValueChanged(dynamic oldValue, dynamic newValue) {
  // Override to handle value changes
}
```

**When Called:** Automatically when the field's value changes in the controller.

**Use Cases:**
- Trigger onChange callbacks
- Update local state
- Perform side effects
- Log changes

**Example:**
```dart
@override
void onValueChanged(dynamic oldValue, dynamic newValue) {
  // Trigger the field's onChange callback
  if (context.field.onChange != null) {
    final results = form.FormResults.getResults(controller: context.controller);
    context.field.onChange!(results);
  }

  // Log changes (development only)
  print('Field ${context.field.id}: $oldValue → $newValue');
}
```

---

### onFocusChanged

```dart
void onFocusChanged(bool isFocused) {
  // Override to handle focus changes
}
```

**When Called:** Automatically when the field gains or loses focus.

**Parameters:**
- `isFocused` - `true` if field gained focus, `false` if lost focus

**Use Cases:**
- Show/hide overlays (autocomplete, date picker)
- Update UI based on focus state
- Log focus events
- Trigger custom validation

**Example:**
```dart
@override
void onFocusChanged(bool isFocused) {
  if (isFocused) {
    // Show autocomplete overlay
    _showAutocomplete();
  } else {
    // Hide autocomplete overlay
    _hideAutocomplete();
  }
}
```

---

### onValidate

```dart
void onValidate() {
  // Override to customize validation behavior
}
```

**When Called:** Automatically when the field loses focus (if `field.validateLive` is true).

**Default Behavior:** Calls `controller.validateField(field.id)`.

**Use Cases:**
- Custom validation logic
- Multi-field validation
- Conditional validation
- Custom error handling

**Example:**
```dart
@override
void onValidate() {
  // Call default validation
  super.onValidate();

  // Add custom validation
  final value = context.getValue<String>();
  if (value != null && value.length > 100) {
    context.addError('Value too long (max 100 characters)');
  }
}
```

**Important:** Call `super.onValidate()` if you want the default validation to run.

---

## Complete Example

### Rating Field Widget

A custom field for star ratings with automatic lifecycle management.

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

/// Star rating field (1-5 stars)
class RatingFieldWidget extends form.StatefulFieldWidget {
  final int maxStars;

  const RatingFieldWidget({
    required super.context,
    this.maxStars = 5,
  });

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final rating = ctx.getValue<int>() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              ctx.field.title!,
              style: theme.titleTextStyle,
            ),
          ),

        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxStars, (index) {
            return IconButton(
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: index < rating
                    ? Colors.amber
                    : ctx.colors.iconColor,
              ),
              onPressed: () => ctx.setValue<int>(index + 1),
              iconSize: 32,
            );
          }),
        ),

        // Description
        if (ctx.field.description != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              ctx.field.description!,
              style: theme.hintTextStyle,
            ),
          ),
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

    // Optional: Haptic feedback
    // HapticFeedback.selectionClick();
  }
}

// Usage in form
form.TextField(
  id: 'satisfaction',
  title: 'How satisfied are you?',
  description: 'Rate from 1 to 5 stars',
  fieldBuilder: (ctx) => RatingFieldWidget(context: ctx),
  validators: [
    form.Validator(
      validator: (r) => (r.asString().isEmpty) || (int.tryParse(r.asString()) ?? 0) < 3,
      reason: 'Please rate at least 3 stars',
    ),
  ],
)
```

---

## Advanced Patterns

### Pattern 1: Multi-Field Validation

Validate based on another field's value:

```dart
class PasswordConfirmField extends form.StatefulFieldWidget {
  const PasswordConfirmField({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    return TextField(
      controller: ctx.getTextController(),
      focusNode: ctx.getFocusNode(),
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
      ),
    );
  }

  @override
  void onValidate() {
    // Get password from another field
    final password = context.controller.getFieldValue<String>('password');
    final confirm = context.getValue<String>();

    // Clear previous errors
    context.clearErrors();

    // Validate match
    if (confirm != null && password != null && confirm != password) {
      context.addError('Passwords do not match');
    }

    // Still run default validation
    super.onValidate();
  }
}
```

### Pattern 2: Conditional UI Based on Focus

Show overlay when focused:

```dart
class AutocompleteTextField extends form.StatefulFieldWidget {
  const AutocompleteTextField({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    return Stack(
      children: [
        TextField(
          controller: ctx.getTextController(),
          focusNode: ctx.getFocusNode(),
        ),

        // Show autocomplete overlay when focused
        if (ctx.hasFocus)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: AutocompleteOverlay(/* ... */),
          ),
      ],
    );
  }

  @override
  void onFocusChanged(bool isFocused) {
    // Overlay will show/hide automatically due to rebuild
    // Optional: Add custom logic here
  }
}
```

### Pattern 3: Local State Management

Combine with local state for complex UI:

```dart
class TagInputField extends form.StatefulFieldWidget {
  const TagInputField({required super.context});

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    final tags = ctx.getValue<List<String>>() ?? [];

    return Column(
      children: [
        // Display existing tags
        Wrap(
          children: tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () {
                final updated = List<String>.from(tags)..remove(tag);
                ctx.setValue(updated);
              },
            );
          }).toList(),
        ),

        // Input for new tags
        TextField(
          controller: _inputController,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final updated = List<String>.from(tags)..add(value);
              ctx.setValue(updated);
              _inputController.clear();
            }
          },
        ),
      ],
    );
  }
}
```

---

## Best Practices

### 1. Always Call super.onValidate() for Default Validation

**Good:**
```dart
@override
void onValidate() {
  super.onValidate(); // Default validation runs
  // Add custom validation
}
```

**Avoid:**
```dart
@override
void onValidate() {
  // Skipped default validation!
  // Add custom validation
}
```

---

### 2. Use ctx Parameter in buildWithTheme

**Good:**
```dart
@override
Widget buildWithTheme(BuildContext buildContext, FormTheme theme, form.FieldBuilderContext ctx) {
  final value = ctx.getValue<String>();
  return TextField(controller: ctx.getTextController());
}
```

**Avoid:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  // Using 'context' for both BuildContext and FieldBuilderContext causes confusion
  final value = context.getValue<String>(); // ERROR: BuildContext doesn't have getValue
}
```

---

### 3. Trigger onChange in onValueChanged Hook

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
      // Calling onChange here causes duplicate invocations
      if (ctx.field.onChange != null) {
        final results = form.FormResults.getResults(controller: ctx.controller);
        ctx.field.onChange!(results);
      }
    },
  );
}
```

---

### 4. Don't Manually Manage Controller Listeners

**Good:**
```dart
class MyField extends form.StatefulFieldWidget {
  // StatefulFieldWidget handles listeners automatically
}
```

**Avoid:**
```dart
class MyField extends form.StatefulFieldWidget {
  @override
  void initState() {
    super.initState();
    context.controller.addListener(_onUpdate); // DON'T DO THIS
  }

  @override
  void dispose() {
    context.controller.removeListener(_onUpdate); // NOT NEEDED
    super.dispose();
  }
}
```

---

### 5. Use Lazy Initialization for Resources

**Good:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  // Only create when needed
  if (needsTextEditing) {
    return TextField(controller: ctx.getTextController());
  }
  return Container(); // No controller created
}
```

**Avoid:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  // Always creates controller, even if not used
  final controller = ctx.getTextController();
  if (needsTextEditing) {
    return TextField(controller: controller);
  }
  return Container();
}
```

---

## Performance Tips

### 1. Minimize buildWithTheme Complexity

Keep `buildWithTheme` simple - extract complex UI into separate widgets:

**Good:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  return _ComplexFieldUI(ctx: ctx, theme: theme);
}
```

**Avoid:**
```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  // 200 lines of complex UI...
}
```

### 2. Use const Constructors When Possible

```dart
const MyFieldWidget({required super.context, super.key});
```

### 3. Avoid Rebuilding Entire Field UI

Use `StatefulBuilder` or `ValueNotifier` for partial UI updates:

```dart
@override
Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
  return Column(
    children: [
      // Static part (doesn't rebuild)
      Text(ctx.field.title!),

      // Dynamic part (rebuilds independently)
      ValueListenableBuilder<int>(
        valueListenable: _counterNotifier,
        builder: (context, count, child) {
          return Text('Count: $count');
        },
      ),
    ],
  );
}
```

### 4. Leverage Automatic Rebuild Prevention

StatefulFieldWidget only rebuilds when:
- Field value changes
- Focus state changes

It does NOT rebuild when:
- Other fields change
- Unrelated controller state changes

This is handled automatically - no configuration needed!

---

## What's Handled Automatically

When you extend `StatefulFieldWidget`, you get these for free:

✅ **Controller listener registration** (in initState)
✅ **Controller listener removal** (in dispose)
✅ **Value change detection** (old vs new comparison)
✅ **Focus change detection** (old vs new comparison)
✅ **Automatic validation** (on focus loss if validateLive is true)
✅ **Performance-optimized rebuilds** (only on relevant changes)
✅ **Resource cleanup** (TextEditingController, FocusNode managed by FormController)

---

## What You Need to Provide

❗ **Required:**
- `buildWithTheme()` implementation

✅ **Optional:**
- `onValueChanged()` override (for onChange callbacks, side effects)
- `onFocusChanged()` override (for custom focus behavior)
- `onValidate()` override (for custom validation logic)

---

## Related Documentation

- [FieldBuilderContext API Reference](field-builder-context.md) - Context object API
- [Custom Field Cookbook](custom-field-cookbook.md) - Practical examples
- [Converters Guide](converters.md) - Type conversion patterns
- [Migration Guide v0.5.x → v0.6.0](../migrations/MIGRATION-0.6.0.md) - Upgrade instructions

---

## Summary

`StatefulFieldWidget` is the foundation of custom field development in v0.6.0+, providing:

✅ **Automatic lifecycle management** - No manual listener setup/cleanup
✅ **Change detection** - onValueChanged and onFocusChanged hooks
✅ **Automatic validation** - Validates on blur when validateLive is true
✅ **Performance optimization** - Rebuilds only on relevant changes
✅ **Clean API** - Single abstract method to implement

With StatefulFieldWidget, custom field boilerplate is reduced from **120-150 lines to 30-50 lines** (60-70% reduction).

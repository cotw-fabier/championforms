# Advanced Custom Field Patterns

Advanced patterns and techniques for creating sophisticated custom fields in ChampionForms v0.6.0+. These patterns go beyond the basics covered in the [Custom Field Cookbook](custom-field-cookbook.md).

## Table of Contents

1. [Field Subclassing: Extending Existing Field Types](#field-subclassing-extending-existing-field-types)
   - [Required: Implementing copyWith](#required-implementing-copywith)
2. [Visual Error Indication Patterns](#visual-error-indication-patterns)
3. [Complex Value Storage Strategies](#complex-value-storage-strategies)
4. [Multi-Field Coordination](#multi-field-coordination)
5. [Performance Optimization Techniques](#performance-optimization-techniques)

---

## Field Subclassing: Extending Existing Field Types

Instead of always extending `form.Field`, you can extend existing field types like `OptionSelect` or `TextField` to inherit their behavior and converters.

### When to Extend Existing Types

Extend an existing field type when:

✅ **Inheriting converters** - Reuse existing conversion logic (multiselect, file upload, etc.)
✅ **Adding visual variants** - Same data model, different UI (e.g., Switch extends OptionSelect)
✅ **Customizing behavior** - Slight modifications to existing field types
✅ **Reducing boilerplate** - Leverage existing infrastructure

### Required: Implementing copyWith

**CRITICAL:** All custom field subclasses **must** implement the `copyWith` method, regardless of whether they extend `Field`, `OptionSelect`, `TextField`, or any other field type. This requirement applies to:

- Custom fields extending `form.Field`
- Custom fields extending `form.OptionSelect`
- Custom fields extending `form.TextField`
- Custom fields extending `form.FileUpload`
- Any other Field subclass

The `copyWith` method enables proper field copying for compound fields and state propagation. Without it, your custom field will fail to compile.

#### Implementation Pattern for Field Subclasses

When extending a field type, include all properties from both the parent class and your custom class:

```dart
class MyCustomSelect extends form.OptionSelect {
  final String customProperty;

  MyCustomSelect({
    required super.id,
    required super.options,
    super.multiselect,
    // ... all parent properties
    this.customProperty = '',
  });

  @override
  MyCustomSelect copyWith({
    // All parent properties as nullable parameters
    String? id,
    List<form.FieldOption>? options,
    bool? multiselect,
    // ... include ALL OptionSelect properties

    // Your custom properties
    String? customProperty,
  }) {
    return MyCustomSelect(
      id: id ?? this.id,
      options: options ?? this.options,
      multiselect: multiselect ?? this.multiselect,
      // ... copy ALL parent properties
      customProperty: customProperty ?? this.customProperty,
    );
  }
}
```

**Important:** When extending a field type, you must include ALL properties from the parent class in your `copyWith` method. Forgetting parent properties will cause them to be lost during field copying.

For a complete list of parent class properties to include:
- `Field` properties: See [API documentation](../api/field-types.md)
- `OptionSelect` properties: See [OptionSelect API](../api/field-types.md#optionselect)
- `TextField` properties: See [TextField API](../api/field-types.md#textfield)

### Pattern: Extending OptionSelect

`OptionSelect` provides multiselect functionality with built-in converters. Perfect for switches, checkboxes, and radio buttons.

**Example: Switch Field**

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

/// Switch field extending OptionSelect
///
/// Inherits:
/// - Multiselect option storage
/// - Built-in converters (asList, asMultiselectList, etc.)
/// - Option selection logic
class SwitchField extends form.OptionSelect {
  final bool labelOnLeft;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? trackHeight;

  SwitchField({
    required super.id,
    required super.options,  // Must have exactly 1 option
    super.title,
    super.description,
    super.validators,
    super.defaultValue,
    this.labelOnLeft = false,
    this.activeColor,
    this.inactiveColor,
    this.trackHeight,
  }) : assert(options.length == 1, 'SwitchField must have exactly 1 option');

  @override
  SwitchField copyWith({
    String? id,
    List<form.FieldOption>? options,
    bool? multiselect,
    Widget? icon,
    Widget? leading,
    Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<form.FieldOption>? defaultValue,
    bool? caseSensitiveDefaultValue,
    List<form.Validator>? validators,
    bool? validateLive,
    Function(form.FormResults results)? onSubmit,
    Function(form.FormResults results)? onChange,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    Widget Function(form.FieldBuilderContext)? fieldBuilder,
    bool? labelOnLeft,
    Color? activeColor,
    Color? inactiveColor,
    double? trackHeight,
  }) {
    return SwitchField(
      id: id ?? this.id,
      options: options ?? this.options,
      title: title ?? this.title,
      description: description ?? this.description,
      validators: validators ?? this.validators,
      defaultValue: defaultValue ?? this.defaultValue,
      labelOnLeft: labelOnLeft ?? this.labelOnLeft,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      trackHeight: trackHeight ?? this.trackHeight,
    );
  }
}

/// Switch widget
class SwitchFieldWidget extends form.StatefulFieldWidget<SwitchField> {
  const SwitchFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final field = ctx.field as SwitchField;
    final option = field.options.first;
    final isSelected = ctx.isOptionSelected(option.value);

    final switchWidget = Switch(
      value: isSelected,
      activeColor: field.activeColor ?? ctx.colors.iconColor,
      inactiveTrackColor: field.inactiveColor,
      onChanged: (_) => ctx.toggleValue(option),
    );

    final labelWidget = option.label != null
        ? Text(option.label!, style: theme.titleTextStyle)
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (field.labelOnLeft && labelWidget != null) ...[
          labelWidget,
          const SizedBox(width: 12),
        ],
        switchWidget,
        if (!field.labelOnLeft && labelWidget != null) ...[
          const SizedBox(width: 12),
          labelWidget,
        ],
      ],
    );
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}
```

**Usage:**

```dart
SwitchField(
  id: 'notifications',
  options: [
    form.FieldOption(value: 'enabled', label: 'Enable Notifications'),
  ],
  labelOnLeft: true,
  defaultValue: [
    form.FieldOption(value: 'enabled', label: 'Enable Notifications'),
  ],
)

// Retrieve value
final results = form.FormResults.getResults(controller: controller);
final isEnabled = results.grab('notifications').asList().isNotEmpty;
// OR
final options = results.grab('notifications').asMultiselectList();
```

### Pattern: Extending Field for Custom Behavior

Extend `form.Field` and implement custom converters:

**Example: Checkbox Field (Multiple Options)**

```dart
/// Checkbox field extending OptionSelect for multi-selection
class CheckboxField extends form.OptionSelect {
  final Axis direction;
  final double spacing;

  CheckboxField({
    required super.id,
    required super.options,
    super.title,
    super.validators,
    super.defaultValue,
    this.direction = Axis.vertical,
    this.spacing = 8.0,
  });
}

class CheckboxFieldWidget extends form.StatefulFieldWidget<CheckboxField> {
  const CheckboxFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final field = ctx.field as CheckboxField;

    final checkboxes = field.options.map((option) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: field.direction == Axis.vertical ? field.spacing / 2 : 0,
          horizontal: field.direction == Axis.horizontal ? field.spacing / 2 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: ctx.isOptionSelected(option.value),
              onChanged: (_) => ctx.toggleValue(option),
            ),
            const SizedBox(width: 8),
            Text(option.label ?? option.value),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(field.title!, style: theme.titleTextStyle),
          ),
        field.direction == Axis.vertical
            ? Column(children: checkboxes)
            : Row(children: checkboxes),
      ],
    );
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}
```

### Advantages of Field Subclassing

✅ **Inherit converters** - No need to reimplement asString(), asList(), etc.
✅ **Consistent data model** - Same storage format as parent type
✅ **Less code** - Reuse parent's infrastructure
✅ **Type safety** - Strong typing with custom properties

### When to Start from Field Instead

Start from `form.Field` when:

- Your field has a completely different data model
- You need custom converters that don't match any existing type
- The parent type's behavior would be confusing
- You want maximum flexibility

---

## Visual Error Indication Patterns

Consistent visual feedback for validation errors improves UX. Here are proven patterns from championforms_shadcn_fields.

### Pattern 1: Border-Based Error Indication

Most common pattern - show errors via border color and thickness:

```dart
@override
Widget buildWithTheme(
  BuildContext buildContext,
  FormTheme theme,
  form.FieldBuilderContext ctx,
) {
  final errors = ctx.controller.findErrors(ctx.field.id);
  final hasError = errors.isNotEmpty;

  // Use error color scheme if errors exist
  final effectiveColors = hasError
      ? (theme.errorColorScheme ?? ctx.colors)
      : ctx.colors;

  return Container(
    decoration: BoxDecoration(
      color: effectiveColors.backgroundColor,
      border: Border.all(
        color: effectiveColors.borderColor,
        width: effectiveColors.borderSize.toDouble(),
      ),
      borderRadius: effectiveColors.borderRadius,
    ),
    child: TextField(
      controller: ctx.getTextController(),
      focusNode: ctx.getFocusNode(),
      decoration: InputDecoration(
        border: InputBorder.none,  // Container handles border
        labelText: ctx.field.title,
      ),
    ),
  );
}
```

### Pattern 2: Icon-Based Error Indication

Show error icon alongside the field:

```dart
@override
Widget buildWithTheme(
  BuildContext buildContext,
  FormTheme theme,
  form.FieldBuilderContext ctx,
) {
  final errors = ctx.controller.findErrors(ctx.field.id);
  final hasError = errors.isNotEmpty;

  return Row(
    children: [
      Expanded(
        child: TextField(
          controller: ctx.getTextController(),
          decoration: InputDecoration(
            labelText: ctx.field.title,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError
                    ? theme.errorColorScheme?.borderColor ?? Colors.red
                    : ctx.colors.borderColor,
              ),
            ),
          ),
        ),
      ),
      if (hasError) ...[
        const SizedBox(width: 8),
        Icon(
          Icons.error_outline,
          color: theme.errorColorScheme?.iconColor ?? Colors.red,
          size: 20,
        ),
      ],
    ],
  );
}
```

### Pattern 3: Background Color Error Indication

Subtle background color change:

```dart
@override
Widget buildWithTheme(
  BuildContext buildContext,
  FormTheme theme,
  form.FieldBuilderContext ctx,
) {
  final errors = ctx.controller.findErrors(ctx.field.id);
  final hasError = errors.isNotEmpty;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: hasError
          ? theme.errorColorScheme?.backgroundColor ?? Colors.red.shade50
          : ctx.colors.backgroundColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: ctx.getTextController(),
      decoration: InputDecoration(
        labelText: ctx.field.title,
        filled: false,
      ),
    ),
  );
}
```

### Pattern 4: Combined Error Indication

Most robust - combines multiple indicators:

```dart
@override
Widget buildWithTheme(
  BuildContext buildContext,
  FormTheme theme,
  form.FieldBuilderContext ctx,
) {
  final errors = ctx.controller.findErrors(ctx.field.id);
  final hasError = errors.isNotEmpty;
  final errorColors = theme.errorColorScheme ?? ctx.colors;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Field title
      if (ctx.field.title != null)
        Text(ctx.field.title!, style: theme.titleTextStyle),

      const SizedBox(height: 8),

      // Field input with error styling
      Container(
        decoration: BoxDecoration(
          border: hasError
              ? Border.all(
                  color: errorColors.borderColor,
                  width: errorColors.borderSize.toDouble(),
                )
              : Border.all(color: ctx.colors.borderColor),
          borderRadius: errorColors.borderRadius,
          color: hasError ? errorColors.backgroundColor : null,
        ),
        child: TextField(
          controller: ctx.getTextController(),
          focusNode: ctx.getFocusNode(),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: hasError
                ? Icon(Icons.error_outline, color: errorColors.iconColor)
                : null,
          ),
        ),
      ),

      // Error messages (Form widget also displays these, but inline can be helpful)
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            errors.first,
            style: TextStyle(
              color: errorColors.textColor,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}
```

### Accessing Error State

Three ways to check for errors:

```dart
// Method 1: Controller's findErrors (most flexible)
final errors = ctx.controller.findErrors(ctx.field.id);
final hasError = errors.isNotEmpty;
final errorMessage = errors.isNotEmpty ? errors.first : null;

// Method 2: FieldState (automatic)
final hasError = ctx.state == FieldState.error;

// Method 3: Theme's error color scheme availability
final hasError = theme.errorColorScheme != null;
```

**Recommendation:** Use `ctx.controller.findErrors()` for maximum control and to display specific error messages.

### Best Practices

✅ **Use theme.errorColorScheme** - Ensures consistent error styling across forms
✅ **Provide multiple indicators** - Border, icon, background, message
✅ **Keep it subtle** - Don't overwhelm the user with red
✅ **Show first error only** - `errors.first` prevents message overload
✅ **Clear on focus** - Consider clearing errors when field gains focus for better UX

---

## Complex Value Storage Strategies

Advanced techniques for storing and converting complex data types.

### Strategy 1: FieldOption.additionalData (Recommended)

Store complex types in `additionalData` while maintaining string serialization in `value`:

```dart
// DateTime storage
form.FieldOption(
  value: date.toIso8601String(),        // "2024-11-15T10:30:00.000Z"
  label: "Nov 15, 2024 10:30 AM",       // User-friendly
  additionalData: date,                 // DateTime object
)

// Custom object storage
form.FieldOption(
  value: jsonEncode(address.toJson()),  // Serializable string
  label: address.formattedAddress,      // "123 Main St, City, 12345"
  additionalData: address,              // Address object
)
```

See [Custom Field Cookbook - Example 7](custom-field-cookbook.md#example-7-working-with-complex-value-types) for complete implementation.

### Strategy 2: JSON Encoding in Value

For fields that don't use FieldOption:

```dart
class GeoLocationField extends form.Field {
  // Store as JSON string
  GeoLocationField({
    required super.id,
    LatLng? defaultLocation,
  }) : super(
    defaultValue: defaultLocation != null
        ? jsonEncode({
            'lat': defaultLocation.latitude,
            'lng': defaultLocation.longitude,
          })
        : null,
  );
}

// Converter extracts and parses
class GeoLocationConverters implements form.FieldConverters {
  @override
  String asString() {
    // Returns JSON string
  }

  LatLng? asLatLng() {
    final value = accessor.value;
    if (value is String) {
      final json = jsonDecode(value);
      return LatLng(json['lat'], json['lng']);
    }
    return null;
  }
}
```

### Strategy 3: Composite Field Pattern

Store multiple related values in a single field:

```dart
class DateTimeRangeField extends form.Field {
  DateTimeRangeField({
    required super.id,
    DateTimeRange? defaultRange,
  }) : super(
    defaultValue: defaultRange != null
        ? [
            form.FieldOption(
              value: 'start',
              label: 'Start',
              additionalData: defaultRange.start,
            ),
            form.FieldOption(
              value: 'end',
              label: 'End',
              additionalData: defaultRange.end,
            ),
          ]
        : null,
  );
}

// Extract both values
class DateTimeRangeConverters implements form.FieldConverters {
  static DateTimeRange? extractRange(form.FieldResultAccessor accessor) {
    final options = accessor.value as List<form.FieldOption>?;
    if (options == null || options.length != 2) return null;

    final start = options[0].additionalData as DateTime?;
    final end = options[1].additionalData as DateTime?;

    if (start == null || end == null) return null;
    return DateTimeRange(start: start, end: end);
  }
}
```

---

## Multi-Field Coordination

Patterns for fields that depend on or interact with other fields.

### Pattern: Dependent Validation

Validate field based on another field's value:

```dart
class PasswordConfirmField extends form.StatefulFieldWidget<form.Field> {
  const PasswordConfirmField({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final textController = ctx.getTextController();
    final value = ctx.getValue<String>() ?? '';

    // Sync controller
    if (textController.text != value) {
      textController.text = value;
    }

    return TextField(
      controller: textController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
      ),
      onChanged: (confirmValue) {
        ctx.setValue(confirmValue);
        _validateMatch(ctx, confirmValue);
      },
    );
  }

  void _validateMatch(form.FieldBuilderContext ctx, String confirmValue) {
    // Get other field's value
    final password = ctx.controller.getFieldValue<String>('password') ?? '';

    ctx.clearErrors();
    if (confirmValue.isNotEmpty && password != confirmValue) {
      ctx.addError('Passwords do not match');
    }
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    // Re-validate on password field change
    _validateMatch(context, newValue as String? ?? '');

    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}
```

### Pattern: Conditional Field Display

Show/hide field based on another field's value:

```dart
class ConditionalField extends form.StatefulFieldWidget<form.Field> {
  final String dependsOnFieldId;
  final bool Function(dynamic value) condition;

  const ConditionalField({
    required super.context,
    required this.dependsOnFieldId,
    required this.condition,
  });

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    // Check condition
    final dependentValue = ctx.controller.getFieldValue(dependsOnFieldId);
    final shouldShow = condition(dependentValue);

    if (!shouldShow) {
      return const SizedBox.shrink();  // Hide field
    }

    return TextField(
      controller: ctx.getTextController(),
      decoration: InputDecoration(
        labelText: ctx.field.title,
      ),
    );
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    // Rebuild when dependent field changes
    setState(() {});
  }
}
```

Usage:

```dart
ConditionalField(
  context: ctx,
  dependsOnFieldId: 'country',
  condition: (value) => value == 'USA',  // Only show if country is USA
)
```

---

## Performance Optimization Techniques

### Technique 1: Lazy Widget Creation

Don't create complex widgets until needed:

```dart
class LazyExpensiveField extends form.StatefulFieldWidget<form.Field> {
  const LazyExpensiveField({required super.context});

  Widget? _cachedWidget;

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    // Create expensive widget only once
    _cachedWidget ??= _buildExpensiveWidget(ctx);

    return _cachedWidget!;
  }

  Widget _buildExpensiveWidget(form.FieldBuilderContext ctx) {
    // Expensive widget creation
    return ComplexWidget(/* ... */);
  }
}
```

### Technique 2: ValueListenableBuilder for Partial Updates

Update only part of the UI:

```dart
class OptimizedField extends form.StatefulFieldWidget<form.Field> {
  const OptimizedField({required super.context});

  final ValueNotifier<int> _counter = ValueNotifier(0);

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    return Column(
      children: [
        // Static part - never rebuilds
        Text('Static Label', style: theme.titleTextStyle),

        // Dynamic part - only rebuilds when counter changes
        ValueListenableBuilder<int>(
          valueListenable: _counter,
          builder: (context, count, child) {
            return Text('Count: $count');
          },
        ),

        ElevatedButton(
          onPressed: () => _counter.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### Technique 3: Debouncing User Input

Prevent excessive updates:

```dart
import 'dart:async';

class DebouncedField extends form.StatefulFieldWidget<form.Field> {
  const DebouncedField({required super.context});

  Timer? _debounceTimer;

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    return TextField(
      controller: ctx.getTextController(),
      onChanged: (value) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          ctx.setValue(value);  // Update form state after debounce
        });
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

---

## Related Documentation

- [Custom Field Cookbook](custom-field-cookbook.md) - Practical examples
- [FieldBuilderContext API Reference](field-builder-context.md) - Context API
- [StatefulFieldWidget Guide](stateful-field-widget.md) - Base class guide
- [Converters Guide](converters.md) - Type conversion patterns

---

## Summary

Advanced custom field patterns enable:

✅ **Field subclassing** - Reuse existing infrastructure (OptionSelect, TextField)
✅ **Visual error indication** - Consistent, accessible error display
✅ **Complex value storage** - Type-safe handling of DateTime, enums, custom objects
✅ **Multi-field coordination** - Dependent validation and conditional display
✅ **Performance optimization** - Lazy creation, partial updates, debouncing

These patterns are battle-tested in championforms_shadcn_fields and production applications.

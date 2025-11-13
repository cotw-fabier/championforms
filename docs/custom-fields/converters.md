# Converters Guide

Guide to using converter mixins for type-safe value conversion in ChampionForms v0.6.0+ custom fields.

## Overview

Converter mixins provide reusable type conversion logic for custom fields, enabling proper handling of `FormResults` methods like `asString()`, `asStringList()`, `asBool()`, and `asFile()`.

**Location:** `lib/models/field_converters.dart`

**Purpose:**
- Type-safe value conversion
- Reusable conversion logic
- Explicit error handling
- Support for built-in and custom field types

## Table of Contents

1. [Quick Start](#quick-start)
2. [Built-in Converters](#built-in-converters)
3. [Creating Custom Converters](#creating-custom-converters)
4. [Registration with FormFieldRegistry](#registration-with-formfieldregistry)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)

---

## Quick Start

### Using Built-in Converters

```dart
import 'package:championforms/championforms.dart' as form;

// Register a custom field with converters
form.FormFieldRegistry.register<form.Field>(
  'myTextField',
  (ctx) => MyTextFieldWidget(context: ctx),
  converters: form.TextFieldConverters(), // Use mixin directly
);
```

### Custom Converter Implementation

```dart
class DateTimeFieldConverters with form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is DateTime) return value.toIso8601String();
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is DateTime) return [value.toIso8601String()];
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is DateTime) return true;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
```

---

## Built-in Converters

ChampionForms provides four built-in converter mixins:

### 1. TextFieldConverters

For String-based fields (TextField, custom text inputs).

```dart
mixin TextFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is String) return value;
    if (value == null) return "";
    throw TypeError();
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
```

**Conversion Logic:**
- `asString`: String → String, null → ""
- `asStringList`: String → [String], null → []
- `asBool`: non-empty String → true, empty/null → false
- `asFile`: Not supported (returns null)

**Usage:**
```dart
// Results retrieval
final results = form.FormResults.getResults(controller: controller);
final name = results.grab('name').asString(); // Uses TextFieldConverters
final hasValue = results.grab('name').asBool(); // true if non-empty
```

---

### 2. MultiselectFieldConverters

For List<FieldOption> fields (OptionSelect, CheckboxSelect, ChipSelect).

```dart
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

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is List<FieldOption>) return value.isNotEmpty;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
```

**Conversion Logic:**
- `asString`: List<FieldOption> → comma-separated labels
- `asStringList`: List<FieldOption> → List<String> of values
- `asBool`: non-empty list → true, empty/null → false
- `asFile`: Not supported (returns null)

**Usage:**
```dart
final results = form.FormResults.getResults(controller: controller);
final countries = results.grab('countries').asStringList(); // ["US", "CA", "MX"]
final display = results.grab('countries').asString(); // "United States, Canada, Mexico"
```

---

### 3. FileFieldConverters

For List<FileModel> fields (FileUpload).

```dart
mixin FileFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is List<FileModel>) {
      return value.map((f) => f.name).join(", ");
    }
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is List<FileModel>) {
      return value.map((f) => f.name).toList();
    }
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is List<FileModel>) return value.isNotEmpty;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => (value) {
    if (value is List<FileModel>) return value;
    if (value == null) return null;
    throw TypeError();
  };
}
```

**Conversion Logic:**
- `asString`: List<FileModel> → comma-separated filenames
- `asStringList`: List<FileModel> → List<String> of filenames
- `asBool`: non-empty list → true, empty/null → false
- `asFile`: List<FileModel> → List<FileModel>, null → null

**Usage:**
```dart
final results = form.FormResults.getResults(controller: controller);
final files = results.grab('documents').asFile(); // List<FileResultData>
final filenames = results.grab('documents').asStringList(); // ["doc1.pdf", "doc2.pdf"]
```

---

### 4. NumericFieldConverters

For int/double fields (custom numeric inputs, sliders, rating fields).

```dart
mixin NumericFieldConverters implements FieldConverters {
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
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
```

**Conversion Logic:**
- `asString`: int/double → string representation
- `asStringList`: int/double → [string]
- `asBool`: non-zero → true, zero/null → false
- `asFile`: Not supported (returns null)

**Usage:**
```dart
final results = form.FormResults.getResults(controller: controller);
final rating = results.grab('rating').asString(); // "5"
final hasRating = results.grab('rating').asBool(); // true if rating != 0
```

---

## Creating Custom Converters

### Step 1: Implement FieldConverters Interface

```dart
import 'package:championforms/championforms.dart' as form;

class MyCustomFieldConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    // Your conversion logic
    if (value is MyCustomType) return value.toString();
    if (value == null) return "";
    throw TypeError(); // Always throw on invalid input
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    // Your conversion logic
    if (value is MyCustomType) return [value.toString()];
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    // Your conversion logic
    if (value is MyCustomType) return value.isValid;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter => (value) {
    // Return null if your field doesn't support files
    return null;
  };
}
```

### Step 2: Use with Mixin Pattern (Optional)

```dart
mixin MyCustomFieldConverters implements form.FieldConverters {
  // Same implementation as above
}

// Can be composed with other mixins
class ComplexConverter with MyCustomFieldConverters, form.TextFieldConverters {
  // Combines both converters (last one wins on conflicts)
}
```

### Example: GeoLocation Converter

```dart
class GeoLocation {
  final double latitude;
  final double longitude;

  GeoLocation(this.latitude, this.longitude);

  @override
  String toString() => '$latitude,$longitude';
}

class GeoLocationConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is GeoLocation) return '${value.latitude},${value.longitude}';
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is GeoLocation) {
      return [value.latitude.toString(), value.longitude.toString()];
    }
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is GeoLocation) return true; // Has location
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter => null;
}

// Usage
form.FormFieldRegistry.register<form.Field>(
  'location',
  (ctx) => GeoLocationFieldWidget(context: ctx),
  converters: GeoLocationConverters(),
);
```

---

## Registration with FormFieldRegistry

### Register with Converters

```dart
form.FormFieldRegistry.register<form.Field>(
  'myField',
  (ctx) => MyFieldWidget(context: ctx),
  converters: MyFieldConverters(), // Provide converters here
);
```

### Without Registration (Inline Builder)

If using inline builders, converters are automatically inferred from the field type:

```dart
form.TextField(
  id: 'email',
  fieldBuilder: (ctx) => CustomEmailWidget(context: ctx),
  // Uses TextFieldConverters automatically
)
```

---

## Error Handling

### Always Throw TypeError on Invalid Input

**Good:**
```dart
@override
String Function(dynamic value) get asStringConverter => (value) {
  if (value is String) return value;
  if (value == null) return "";
  throw TypeError(); // Explicit failure
};
```

**Avoid:**
```dart
@override
String Function(dynamic value) get asStringConverter => (value) {
  if (value is String) return value;
  if (value == null) return "";
  return ""; // Silent failure - bad!
};
```

**Reason:** Throwing TypeError makes bugs obvious during development instead of silently returning incorrect values.

### Catching Conversion Errors

```dart
try {
  final results = form.FormResults.getResults(controller: controller);
  final value = results.grab('myField').asString();
} catch (e) {
  if (e is TypeError) {
    print('Invalid field type conversion');
    // Handle error
  }
}
```

---

## Best Practices

### 1. Always Handle null

Every converter should handle `null` input:

```dart
@override
String Function(dynamic value) get asStringConverter => (value) {
  if (value is MyType) return value.toString();
  if (value == null) return ""; // Always handle null
  throw TypeError();
};
```

### 2. Return Appropriate Default Values

- `asString`: Return `""` for null/empty
- `asStringList`: Return `[]` for null/empty
- `asBool`: Return `false` for null/empty
- `asFile`: Return `null` for null/empty

### 3. Throw TypeError for Invalid Types

Never silently fail - always throw `TypeError` for invalid input types.

### 4. Return null for Unsupported Conversions

If your field doesn't support a conversion (e.g., text field doesn't support `asFile`):

```dart
@override
List<form.FileModel>? Function(dynamic value)? get asFileListConverter => null;
```

### 5. Use Mixins for Reusability

```dart
mixin MyConverters implements form.FieldConverters {
  // Reusable across multiple field types
}

class Field1Converters with MyConverters {}
class Field2Converters with MyConverters {}
```

### 6. Document Custom Converters

```dart
/// Converts GeoLocation objects to string representations.
///
/// - asString: "latitude,longitude"
/// - asStringList: [latitude, longitude]
/// - asBool: true if location exists, false otherwise
class GeoLocationConverters implements form.FieldConverters {
  // Implementation
}
```

---

## Common Patterns

### Pattern 1: Enum Converter

```dart
enum Priority { low, medium, high }

class PriorityConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is Priority) return value.name;
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is Priority) return [value.name];
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is Priority) return true;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
```

### Pattern 2: Complex Object Converter

```dart
class User {
  final String name;
  final String email;

  User(this.name, this.email);
}

class UserConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is User) return '${value.name} <${value.email}>';
    if (value == null) return "";
    throw TypeError();
  };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
    if (value is User) return [value.name, value.email];
    if (value == null) return [];
    throw TypeError();
  };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    if (value is User) return true;
    if (value == null) return false;
    throw TypeError();
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
```

### Pattern 3: Composite Converter (Multiple Types)

```dart
class FlexibleConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(2);
    if (value is bool) return value ? 'Yes' : 'No';
    if (value == null) return "";
    throw TypeError();
  };

  // Other converters follow similar pattern
}
```

---

## Related Documentation

- [FieldBuilderContext API Reference](field-builder-context.md) - Context object API
- [StatefulFieldWidget Guide](stateful-field-widget.md) - Base class guide
- [Custom Field Cookbook](custom-field-cookbook.md) - Practical examples
- [Migration Guide v0.5.x → v0.6.0](../migrations/MIGRATION-0.6.0.md) - Upgrade instructions

---

## Summary

Converter mixins in ChampionForms v0.6.0 provide:

✅ **Type-safe value conversion** - Proper handling of FormResults methods
✅ **Reusable logic** - Compose converters with mixins
✅ **Explicit error handling** - TypeError for invalid conversions
✅ **Built-in converters** - Text, Multiselect, File, Numeric
✅ **Custom converter support** - Easy to implement for custom types

Converters ensure that custom fields integrate seamlessly with the existing FormResults API!

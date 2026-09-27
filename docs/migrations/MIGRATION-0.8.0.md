# Migration Guide: v0.7.x → v0.8.0

## Overview

0.8.0 is mostly additive: `FieldView`, field clipboard codecs, JSON values
export and load, and pending-edit flushing. One change can break a build.

**Who this affects:**

- ✅ **Apps that only use the built-in fields**: no action needed.
- ✅ **Custom fields that extend `Field` or `CompoundField` directly**: no
  action needed. The abstract `Field.copyWith` signature has not changed.
- ⚠️ **Classes that extend a built-in field and override `copyWith`**: read
  [Subclasses of built-in fields](#subclasses-of-built-in-fields).

**Migration time estimate:** one line per affected class.

---

## Subclasses of built-in fields

Every built-in field gained a `clipboard` parameter (a `FieldClipboardCodec`
that describes the field's value for copy and paste). Its concrete `copyWith`
now declares it:

| Class | `copyWith` now declares `clipboard` |
|---|---|
| `TextField` | yes |
| `OptionSelect`, `CheckboxSelect`, `ChipSelect`, `RadioSelect` | yes |
| `FileUpload` | yes |
| `NameField`, `AddressField` | yes |
| `NullField` | yes |

Dart requires an override to accept every named parameter of the method it
overrides. So a class like this, written against 0.7, no longer compiles:

```dart
class TagSelect extends form.CheckboxSelect {
  // ...
  @override
  TagSelect copyWith({
    String? id,
    // ... every CheckboxSelect.copyWith parameter from 0.7 ...
  }) { ... }
}
```

```
error • 'TagSelect.copyWith' isn't a valid override of 'CheckboxSelect.copyWith' • invalid_override
```

### Fix

Add the parameter and forward it:

```dart
@override
TagSelect copyWith({
  String? id,
  // ... the other parameters ...
  form.FieldClipboardCodec? clipboard, // add
}) {
  return TagSelect(
    id: id ?? this.id,
    // ... the other parameters ...
    clipboard: clipboard ?? this.clipboard, // add
  );
}
```

The constructor also needs `super.clipboard` if you want callers to be able to
set it. `test/builtin_subclass_copywith_test.dart` has a complete example.

### Coming from 0.6

0.7.0 did the same thing with `colors`, `animateValidationErrors` and
`conditional`, and did not document it. A subclass of a built-in field written
against 0.6 needs all four:

```dart
form.FieldColors? colors,
bool? animateValidationErrors,
form.FieldCondition? conditional,
form.FieldClipboardCodec? clipboard,
```

each forwarded with `?? this.<name>`.

---

## Codec lookup for subclasses

Registry codecs are looked up by exact type, like builders. A subclass of
`TextField` does not inherit `TextField`'s codec. Either pass `clipboard:` on
the field or register one for the subclass:

```dart
FormFieldRegistry.registerClipboardCodec<MyTextField>(
  const form.TextFieldClipboardCodec(),
);
```

---

## New API summary

| | |
|---|---|
| `form.FieldView` | render one registered field outside a `Form` |
| `Field.clipboard`, `FieldClipboardCodec`, `ClipboardFragment` | per-field clipboard codec |
| `FormFieldRegistry.resolveClipboard(field)` | `field.clipboard ?? clipboardFor(type)` |
| `FormFieldDefaults.instance.clipboardEnabled` | app-wide clipboard switch |
| `FormResults.toJson()` | the collected values as JSON-encodable data |
| `FormController.exportValues()` | every stored value, for a draft that `setFieldValues` loads back |
| `FormController.registerPendingEditFlusher` / `flushPendingEdits` | results reflect buffered input |

See the [CHANGELOG](../../CHANGELOG.md) for the full list.

# Custom Field Cookbook

This cookbook provides practical examples for creating custom form fields in ChampionForms v0.6.0+. Each example demonstrates real-world use cases with complete, working code.

## Table of Contents

1. [Overview: File-Based vs Inline Builders](#overview-file-based-vs-inline-builders)
2. [Required: Implementing copyWith for Custom Field Classes](#required-implementing-copywith-for-custom-field-classes)
3. [Example 1: Phone Number Field with Formatting](#example-1-phone-number-field-with-formatting)
4. [Example 2: Tag Selector with Autocomplete](#example-2-tag-selector-with-autocomplete)
5. [Example 3: Rich Text Editor Field](#example-3-rich-text-editor-field)
6. [Example 4: Date/Time Picker Field](#example-4-datetime-picker-field)
7. [Example 5: Signature Pad Field](#example-5-signature-pad-field)
8. [Example 6: File Upload with Preview Enhancement](#example-6-file-upload-with-preview-enhancement)
9. [Example 7: Working with Complex Value Types](#example-7-working-with-complex-value-types)
10. [Pattern: Central Registry for Custom Field Libraries](#pattern-central-registry-for-custom-field-libraries)

---

## Overview: File-Based vs Inline Builders

ChampionForms v0.6.0 supports two approaches for customizing fields:

### File-Based Custom Fields (New Field Types)
Create a new field type when you need:
- **Completely new behavior** (e.g., signature pad, star rating, slider)
- **Custom validation logic** specific to the field type
- **Reusable components** across multiple forms
- **Complex state management** beyond text input

**Pattern:**
```dart
// lib/custom_fields/my_field.dart
class MyFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const MyFieldWidget({required super.context});

  @override
  Widget buildWithTheme(BuildContext context, FormTheme theme, form.FieldBuilderContext ctx) {
    // Your custom UI
  }
}

// Register for reuse
form.FormFieldRegistry.register<form.Field>('myField', (ctx) => MyFieldWidget(context: ctx));
```

### Inline Builders (Design Customization)
Use inline builders when you need:
- **Design variations** of existing fields (e.g., styled text field, custom dropdown)
- **One-off customizations** for a specific form
- **Theme overrides** without creating a new type
- **Minor UI adjustments** to built-in fields

**Pattern:**
```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email',
  fieldBuilder: (ctx) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctx.getTextController(),
        // Custom styling
      ),
    );
  },
)
```

**Rule of Thumb:** If you're creating a new **behavior**, use file-based. If you're customizing **appearance**, use inline.

---

## Required: Implementing copyWith for Custom Field Classes

**IMPORTANT:** If you create a custom field class that extends `Field` (not just `StatefulFieldWidget`), you **must** implement the `copyWith` method. This requirement was introduced in v0.6.0 to enable proper field copying for compound fields and state propagation.

### Why copyWith is Required

The `copyWith` method is essential for:
- **Compound fields**: When compound fields (like `AddressField` or `NameField`) create sub-fields, they need to prefix the sub-field IDs while preserving all other properties
- **State propagation**: Themes and disabled states from parent fields must be copied to child fields
- **Field cloning**: Forms may need to create field copies with modified properties

### Implementation Pattern

When creating a custom `Field` subclass, implement `copyWith` with nullable parameters for all properties:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

class CustomField extends form.Field {
  final String customProperty;

  @override
  final String? defaultValue;

  CustomField({
    required super.id,
    super.title,
    super.description,
    super.disabled,
    super.hideField,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    super.theme,
    super.fieldLayout,
    super.fieldBackground,
    super.icon,
    super.requestFocus,
    this.customProperty = '',
    this.defaultValue,
  });

  @override
  CustomField copyWith({
    String? id,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<form.Validator>? validators,
    bool? validateLive,
    Function(form.FormResults results)? onSubmit,
    Function(form.FormResults results)? onChange,
    FormTheme? theme,
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
    Widget? icon,
    String? customProperty,
    String? defaultValue,
  }) {
    return CustomField(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      theme: theme ?? this.theme,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      icon: icon ?? this.icon,
      customProperty: customProperty ?? this.customProperty,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  // ... converter implementations ...
}
```

### Common Mistakes

❌ **Forgetting to implement copyWith**
```dart
class MyField extends form.Field {
  // Missing copyWith - will cause compilation error!
}
```

❌ **Missing properties in copyWith**
```dart
@override
MyField copyWith({String? id}) {
  // Only copying id - other properties will be lost!
  return MyField(id: id ?? this.id);
}
```

✅ **Correct implementation**
```dart
@override
MyField copyWith({
  String? id,
  // Include ALL properties as nullable parameters
  String? customProperty,
  // ...
}) {
  return MyField(
    id: id ?? this.id,
    customProperty: customProperty ?? this.customProperty,
    // Copy ALL properties using ?? operator
  );
}
```

### Note for StatefulFieldWidget Users

If you're only creating custom widgets using `StatefulFieldWidget` (as shown in the examples below), you **don't need** to implement `copyWith`. The requirement only applies when extending the `Field` class directly.

---

## Example 1: Phone Number Field with Formatting

A text field variant that automatically formats phone numbers as the user types.

### Use Case
- Enforces phone number format: (123) 456-7890
- Validates US phone number format
- Reusable across multiple forms

### Implementation

**File:** `lib/custom_fields/phone_number_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:championforms/championforms.dart' as form;

/// Custom phone number field with automatic formatting.
///
/// Formats input as: (123) 456-7890
class PhoneNumberFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const PhoneNumberFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final textController = ctx.getTextController();
    final focusNode = ctx.getFocusNode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              ctx.field.title!,
              style: theme.titleTextStyle,
            ),
          ),
        TextField(
          controller: textController,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            PhoneNumberFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '(123) 456-7890',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: ctx.colors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ctx.colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: ctx.colors.borderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.errorColors.borderColor),
            ),
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
  }
}

/// Phone number formatter that adds parentheses and hyphens.
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Only format if we have digits
    if (text.isEmpty) {
      return newValue;
    }

    // Remove any non-digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Build formatted string
    String formatted = '';
    if (digitsOnly.length >= 1) {
      formatted += '(';
      formatted += digitsOnly.substring(0, digitsOnly.length.clamp(0, 3));
    }
    if (digitsOnly.length >= 4) {
      formatted += ') ';
      formatted += digitsOnly.substring(3, digitsOnly.length.clamp(3, 6));
    }
    if (digitsOnly.length >= 7) {
      formatted += '-';
      formatted += digitsOnly.substring(6, digitsOnly.length.clamp(6, 10));
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Validator for US phone numbers
bool isValidPhoneNumber(form.FieldResults results) {
  final value = results.asString();
  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
  return digitsOnly.length != 10; // Return true if INVALID (validator convention)
}
```

### Usage

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

// Register the field (typically in main.dart or app initialization)
void initCustomFields() {
  form.FormFieldRegistry.register<form.Field>(
    'phoneNumber',
    (ctx) => PhoneNumberFieldWidget(context: ctx),
  );
}

// Use in a form
form.Form(
  controller: controller,
  fields: [
    form.TextField(
      id: 'phone',
      title: 'Phone Number',
      validators: [
        form.Validator(
          validator: isValidPhoneNumber,
          reason: 'Please enter a valid 10-digit US phone number',
        ),
      ],
      fieldBuilder: (ctx) => PhoneNumberFieldWidget(context: ctx),
    ),
  ],
)

// Or use via registry (if you created a custom Field subclass)
// See Example 2 for custom Field subclass pattern
```

### Key Takeaways
- Extends `StatefulFieldWidget` for automatic lifecycle management
- Uses `ctx.getTextController()` and `ctx.getFocusNode()` for lazy initialization
- Implements `onValueChanged()` to trigger onChange callbacks
- Uses Flutter's `TextInputFormatter` for automatic formatting
- Clean separation: formatting logic in formatter, validation in validator

---

## Example 2: Tag Selector with Autocomplete

A custom multiselect field that displays selected items as chips and supports autocomplete suggestions.

### Use Case
- Tag-based selection (skills, categories, interests)
- Autocomplete from a predefined list or API
- Visual chip display for selected tags
- Add custom tags not in the list

### Implementation

**File:** `lib/custom_fields/tag_selector_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

/// Custom tag selector with autocomplete and chip display.
class TagSelectorWidget extends form.StatefulFieldWidget<form.Field> {
  const TagSelectorWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final selectedOptions = ctx.getValue<List<form.FieldOption>>() ?? [];
    final textController = TextEditingController(); // Local controller for input

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(ctx.field.title!, style: theme.titleTextStyle),
          ),

        // Display selected tags as chips
        if (selectedOptions.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: selectedOptions.map((option) {
              return Chip(
                label: Text(option.label),
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () {
                  final updated = List<form.FieldOption>.from(selectedOptions)
                    ..remove(option);
                  ctx.setValue(updated);
                },
                backgroundColor: ctx.colors.backgroundColor,
                side: BorderSide(color: ctx.colors.borderColor),
              );
            }).toList(),
          ),

        SizedBox(height: 8),

        // Input field with autocomplete
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }

            // Filter available options (not already selected)
            final allOptions = _getAvailableOptions(ctx.field);
            return allOptions.where((option) {
              return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
            });
          },
          onSelected: (String selection) {
            // Add selected option to field value
            final newOption = form.FieldOption(label: selection, value: selection);
            final updated = List<form.FieldOption>.from(selectedOptions)
              ..add(newOption);
            ctx.setValue(updated);
            textController.clear();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Type to add tags...',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: ctx.colors.borderColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      final newOption = form.FieldOption(
                        label: controller.text,
                        value: controller.text,
                      );
                      final updated = List<form.FieldOption>.from(selectedOptions)
                        ..add(newOption);
                      ctx.setValue(updated);
                      controller.clear();
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  final newOption = form.FieldOption(label: value, value: value);
                  final updated = List<form.FieldOption>.from(selectedOptions)
                    ..add(newOption);
                  ctx.setValue(updated);
                  controller.clear();
                }
              },
            );
          },
        ),
      ],
    );
  }

  /// Get available options from field definition or generate defaults
  List<String> _getAvailableOptions(form.Field field) {
    // If field has predefined options, use those
    if (field is form.OptionSelect && field.options.isNotEmpty) {
      return field.options.map((o) => o.label).toList();
    }

    // Default suggestions (could be loaded from API)
    return [
      'JavaScript',
      'TypeScript',
      'Dart',
      'Flutter',
      'React',
      'Vue',
      'Angular',
      'Node.js',
      'Python',
      'Java',
    ];
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

### Usage

```dart
import 'package:championforms/championforms.dart' as form;

// Register the field
form.FormFieldRegistry.register<form.Field>(
  'tagSelector',
  (ctx) => TagSelectorWidget(context: ctx),
);

// Use in a form
form.OptionSelect(
  id: 'skills',
  title: 'Select Your Skills',
  multiselect: true,
  options: [
    form.FieldOption(label: 'JavaScript', value: 'js'),
    form.FieldOption(label: 'TypeScript', value: 'ts'),
    form.FieldOption(label: 'Dart', value: 'dart'),
    // ... more predefined options
  ],
  fieldBuilder: (ctx) => TagSelectorWidget(context: ctx),
  validators: [
    form.Validator(
      validator: (r) => form.Validators.isEmpty(r),
      reason: 'Please select at least one skill',
    ),
  ],
)

// Get results
final results = form.FormResults.getResults(controller: controller);
if (!results.errorState) {
  final skills = results.grab('skills').asMultiselectList();
  print('Selected skills: ${skills.map((s) => s.label).join(', ')}');
}
```

### Key Takeaways
- Uses Flutter's built-in `Autocomplete` widget for suggestions
- Displays selected items as removable chips
- Supports both selecting from suggestions and adding custom tags
- Works with existing `OptionSelect` field type
- Demonstrates inline builder usage with `fieldBuilder` property

---

## Example 3: Rich Text Editor Field

A field for rich text editing with formatting controls (bold, italic, lists, etc.).

### Use Case
- Blog post content
- Email composition
- Product descriptions with formatting
- Notes with styling

### Implementation

**File:** `lib/custom_fields/rich_text_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

/// Rich text editor field with formatting toolbar.
///
/// Note: This is a simplified example. For production use, consider
/// packages like flutter_quill, html_editor_enhanced, or zefyrka.
class RichTextFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const RichTextFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final textController = ctx.getTextController();
    final focusNode = ctx.getFocusNode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(ctx.field.title!, style: theme.titleTextStyle),
          ),

        // Formatting toolbar
        Container(
          decoration: BoxDecoration(
            color: ctx.colors.backgroundColor,
            border: Border.all(color: ctx.colors.borderColor),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Row(
            children: [
              _ToolbarButton(
                icon: Icons.format_bold,
                tooltip: 'Bold',
                onPressed: () => _insertMarkdown(textController, '**', '**'),
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                tooltip: 'Italic',
                onPressed: () => _insertMarkdown(textController, '_', '_'),
              ),
              _ToolbarButton(
                icon: Icons.format_list_bulleted,
                tooltip: 'Bullet List',
                onPressed: () => _insertMarkdown(textController, '- ', ''),
              ),
              _ToolbarButton(
                icon: Icons.format_list_numbered,
                tooltip: 'Numbered List',
                onPressed: () => _insertMarkdown(textController, '1. ', ''),
              ),
              _ToolbarButton(
                icon: Icons.link,
                tooltip: 'Link',
                onPressed: () => _insertMarkdown(textController, '[', '](url)'),
              ),
            ],
          ),
        ),

        // Text editing area
        TextField(
          controller: textController,
          focusNode: focusNode,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Enter rich text content...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              borderSide: BorderSide(color: ctx.colors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              borderSide: BorderSide(color: ctx.colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              borderSide: BorderSide(color: ctx.colors.borderColor, width: 2),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
        ),

        // Preview hint
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Markdown supported: **bold**, _italic_, - lists',
            style: theme.hintTextStyle?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Insert markdown formatting at cursor position
  void _insertMarkdown(
    TextEditingController controller,
    String prefix,
    String suffix,
  ) {
    final selection = controller.selection;
    final text = controller.text;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );
    } else {
      // No selection, just insert at cursor
      final cursorPos = selection.baseOffset;
      final newText = text.replaceRange(
        cursorPos,
        cursorPos,
        '$prefix$suffix',
      );

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + prefix.length,
        ),
      );
    }
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.all(4),
        constraints: BoxConstraints.tight(Size(36, 36)),
      ),
    );
  }
}
```

### Usage

```dart
import 'package:championforms/championforms.dart' as form;

// Use inline builder for rich text field
form.TextField(
  id: 'content',
  title: 'Post Content',
  maxLines: null, // Allow multiline
  fieldBuilder: (ctx) => RichTextFieldWidget(context: ctx),
  validators: [
    form.Validator(
      validator: (r) => form.Validators.isEmpty(r),
      reason: 'Content is required',
    ),
    form.Validator(
      validator: (r) => r.asString().length < 50,
      reason: 'Content must be at least 50 characters',
    ),
  ],
)

// Get formatted content
final results = form.FormResults.getResults(controller: controller);
final content = results.grab('content').asString();
// Content will be in markdown format: **bold**, _italic_, etc.
```

### Key Takeaways
- Demonstrates custom toolbar above text field
- Uses markdown syntax for formatting (simple and portable)
- Inserts formatting at cursor position or around selection
- For production, consider dedicated rich text packages
- Shows how to build custom UI on top of TextField

---

## Example 4: Date/Time Picker Field

A field that opens Flutter's date/time picker dialogs and displays the selected value.

### Use Case
- Event scheduling
- Appointment booking
- Date of birth entry
- Deadline selection

### Implementation

**File:** `lib/custom_fields/date_time_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;
import 'package:intl/intl.dart'; // Add to pubspec.yaml: intl: ^0.18.0

/// Date/time picker field with customizable modes.
class DateTimeFieldWidget extends form.StatefulFieldWidget<form.Field> {
  final DateTimeMode mode;

  const DateTimeFieldWidget({
    required super.context,
    this.mode = DateTimeMode.date,
  });

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final DateTime? selectedDate = ctx.getValue<DateTime>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(ctx.field.title!, style: theme.titleTextStyle),
          ),

        InkWell(
          onTap: () => _showPicker(buildContext, ctx),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: ctx.colors.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: ctx.colors.backgroundColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? _formatDate(selectedDate)
                      : 'Select ${mode.name}',
                  style: TextStyle(
                    color: selectedDate != null
                        ? ctx.colors.textColor
                        : theme.hintTextStyle?.color,
                  ),
                ),
                Icon(
                  mode == DateTimeMode.time
                      ? Icons.access_time
                      : Icons.calendar_today,
                  color: ctx.colors.iconColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(
    BuildContext context,
    form.FieldBuilderContext ctx,
  ) async {
    final currentValue = ctx.getValue<DateTime>();

    switch (mode) {
      case DateTimeMode.date:
        final picked = await showDatePicker(
          context: context,
          initialDate: currentValue ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          ctx.setValue<DateTime>(picked);
        }
        break;

      case DateTimeMode.time:
        final picked = await showTimePicker(
          context: context,
          initialTime: currentValue != null
              ? TimeOfDay.fromDateTime(currentValue)
              : TimeOfDay.now(),
        );
        if (picked != null) {
          final now = DateTime.now();
          final dateTime = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
          ctx.setValue<DateTime>(dateTime);
        }
        break;

      case DateTimeMode.dateTime:
        // Show date picker first, then time picker
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: currentValue ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );

        if (pickedDate != null) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: currentValue != null
                ? TimeOfDay.fromDateTime(currentValue)
                : TimeOfDay.now(),
          );

          if (pickedTime != null) {
            final dateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            ctx.setValue<DateTime>(dateTime);
          }
        }
        break;
    }
  }

  String _formatDate(DateTime date) {
    switch (mode) {
      case DateTimeMode.date:
        return DateFormat('MMM d, yyyy').format(date);
      case DateTimeMode.time:
        return DateFormat('h:mm a').format(date);
      case DateTimeMode.dateTime:
        return DateFormat('MMM d, yyyy h:mm a').format(date);
    }
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}

enum DateTimeMode {
  date,
  time,
  dateTime,
}

/// Custom converter for DateTime fields
class DateTimeFieldConverters implements form.FieldConverters {
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
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter =>
      null;
}
```

### Usage

```dart
import 'package:championforms/championforms.dart' as form;

// Register with converters
form.FormFieldRegistry.register<form.Field>(
  'dateTime',
  (ctx) => DateTimeFieldWidget(context: ctx),
  converters: DateTimeFieldConverters(),
);

// Use in a form
form.TextField(
  id: 'appointment',
  title: 'Appointment Date & Time',
  fieldBuilder: (ctx) => DateTimeFieldWidget(
    context: ctx,
    mode: DateTimeMode.dateTime,
  ),
  validators: [
    form.Validator(
      validator: (r) => r.asString().isEmpty,
      reason: 'Please select a date and time',
    ),
    form.Validator(
      validator: (r) {
        final dateStr = r.asString();
        if (dateStr.isEmpty) return false;
        final date = DateTime.parse(dateStr);
        return date.isBefore(DateTime.now()); // Return true if INVALID
      },
      reason: 'Appointment must be in the future',
    ),
  ],
)

// Get results as DateTime
final results = form.FormResults.getResults(controller: controller);
final dateStr = results.grab('appointment').asString();
final appointment = DateTime.parse(dateStr);
print('Appointment: $appointment');
```

### Key Takeaways
- Uses Flutter's built-in date/time pickers
- Supports three modes: date, time, dateTime
- Implements custom converter for DateTime values
- Stores DateTime objects in controller (not strings)
- Formats display based on selected mode
- Demonstrates validation with date ranges

---

## Example 5: Signature Pad Field

A field for capturing user signatures with touch/mouse drawing.

### Use Case
- Contract signing
- Consent forms
- Delivery confirmations
- Digital agreements

### Implementation

**File:** `lib/custom_fields/signature_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;
import 'dart:ui' as ui;
import 'dart:typed_data';

/// Signature pad field for capturing drawn signatures.
class SignatureFieldWidget extends form.StatefulFieldWidget<form.Field> {
  const SignatureFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final signature = ctx.getValue<SignatureData>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(ctx.field.title!, style: theme.titleTextStyle),
          ),

        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: ctx.colors.borderColor, width: 2),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: signature == null || signature.points.isEmpty
              ? SignaturePainter(
                  onSignatureComplete: (points) {
                    ctx.setValue(SignatureData(points: points));
                  },
                )
              : Stack(
                  children: [
                    CustomPaint(
                      painter: SignatureDisplayPainter(signature.points),
                      child: Container(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          ctx.setValue<SignatureData?>(null);
                        },
                        tooltip: 'Clear signature',
                      ),
                    ),
                  ],
                ),
        ),

        SizedBox(height: 8),

        Text(
          signature == null || signature.points.isEmpty
              ? 'Draw your signature above'
              : 'Signature captured',
          style: theme.hintTextStyle,
        ),
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

/// Interactive signature pad widget
class SignaturePainter extends StatefulWidget {
  final Function(List<Offset?>) onSignatureComplete;

  const SignaturePainter({required this.onSignatureComplete});

  @override
  State<SignaturePainter> createState() => _SignaturePainterState();
}

class _SignaturePainterState extends State<SignaturePainter> {
  List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _points.add(details.localPosition);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        setState(() {
          _points.add(null); // Null indicates end of stroke
        });
        widget.onSignatureComplete(_points);
      },
      child: CustomPaint(
        painter: SignatureDisplayPainter(_points),
        child: Container(),
      ),
    );
  }
}

/// Painter for displaying signature strokes
class SignatureDisplayPainter extends CustomPainter {
  final List<Offset?> points;

  SignatureDisplayPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignatureDisplayPainter oldDelegate) =>
      oldDelegate.points != points;
}

/// Data model for signature
class SignatureData {
  final List<Offset?> points;

  SignatureData({required this.points});

  /// Convert to PNG bytes (for saving to server)
  Future<Uint8List?> toPng() async {
    if (points.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 400, 200),
      Paint()..color = Colors.white,
    );

    // Draw signature
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 200);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

/// Converter for signature fields
class SignatureFieldConverters implements form.FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
        if (value is SignatureData) {
          return value.points.isNotEmpty ? 'Signature captured' : '';
        }
        if (value == null) return "";
        throw TypeError();
      };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
        if (value is SignatureData) {
          return value.points.isNotEmpty ? ['Signature captured'] : [];
        }
        if (value == null) return [];
        throw TypeError();
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
        if (value is SignatureData) return value.points.isNotEmpty;
        if (value == null) return false;
        throw TypeError();
      };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter =>
      null;
}
```

### Usage

```dart
import 'package:championforms/championforms.dart' as form;

// Register the field
form.FormFieldRegistry.register<form.Field>(
  'signature',
  (ctx) => SignatureFieldWidget(context: ctx),
  converters: SignatureFieldConverters(),
);

// Use in a form
form.TextField(
  id: 'agreement_signature',
  title: 'Sign Here',
  fieldBuilder: (ctx) => SignatureFieldWidget(context: ctx),
  validators: [
    form.Validator(
      validator: (r) => !r.asBool(), // Return true if INVALID (no signature)
      reason: 'Signature is required',
    ),
  ],
)

// Get signature data and convert to PNG
final results = form.FormResults.getResults(controller: controller);
final signature = controller.getFieldValue<SignatureData>('agreement_signature');
if (signature != null) {
  final pngBytes = await signature.toPng();
  // Upload pngBytes to server or save locally
  print('Signature captured: ${pngBytes?.length} bytes');
}
```

### Key Takeaways
- Captures touch/mouse drawing as signature
- Stores signature as list of points (Offset)
- Provides conversion to PNG format for storage
- Implements custom painter for rendering strokes
- Demonstrates storing custom data types in controller
- Shows clear/reset functionality

---

## Example 6: File Upload with Preview Enhancement

Enhance the built-in FileUpload field with custom preview thumbnails and metadata display.

### Use Case
- Image gallery uploads with previews
- Document uploads with file info
- Multi-file uploads with drag-and-drop
- File size and type validation

### Implementation

**File:** `lib/custom_fields/enhanced_file_upload.dart`

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;
import 'dart:io';

/// Enhanced file upload with custom preview and metadata.
///
/// This is an inline builder example that wraps the built-in FileUpload.
class EnhancedFileUploadWidget extends form.StatefulFieldWidget<form.Field> {
  const EnhancedFileUploadWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final files = ctx.getValue<List<form.FileModel>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ctx.field.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(ctx.field.title!, style: theme.titleTextStyle),
          ),

        // Upload button
        OutlinedButton.icon(
          onPressed: () => _pickFiles(ctx),
          icon: Icon(Icons.upload_file),
          label: Text('Choose Files'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: ctx.colors.borderColor),
          ),
        ),

        SizedBox(height: 16),

        // Preview grid
        if (files.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _FilePreviewCard(
                file: files[index],
                onRemove: () {
                  final updated = List<form.FileModel>.from(files)
                    ..removeAt(index);
                  ctx.setValue(updated);
                },
              );
            },
          ),

        // Summary
        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${files.length} file(s) selected • ${_getTotalSize(files)}',
              style: theme.hintTextStyle,
            ),
          ),
      ],
    );
  }

  Future<void> _pickFiles(form.FieldBuilderContext ctx) async {
    // Use file_picker package (already a dependency)
    // This is simplified - in production, use file_picker.FilePicker
    // For this example, we'll show the concept

    // Simulate file picking (replace with actual file_picker code)
    // final result = await FilePicker.platform.pickFiles(
    //   allowMultiple: ctx.field.multiselect,
    //   type: FileType.custom,
    //   allowedExtensions: ctx.field.allowedExtensions,
    // );

    // For demonstration purposes:
    print('File picker would open here');
  }

  String _getTotalSize(List<form.FileModel> files) {
    final totalBytes = files.fold<int>(
      0,
      (sum, file) => sum + (file.size ?? 0),
    );

    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}

/// File preview card with thumbnail and metadata
class _FilePreviewCard extends StatelessWidget {
  final form.FileModel file;
  final VoidCallback onRemove;

  const _FilePreviewCard({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          // Preview or icon
          Center(
            child: _buildPreview(),
          ),

          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(Size(24, 24)),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.9),
              ),
            ),
          ),

          // File name at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              color: Colors.black54,
              child: Text(
                file.name,
                style: TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    // Check if it's an image
    if (_isImage(file.mimeType)) {
      if (file.path != null) {
        return Image.file(
          File(file.path!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (file.bytes != null) {
        return Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }

    // For non-images, show icon based on type
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getFileIcon(file.mimeType), size: 40, color: Colors.grey),
        SizedBox(height: 4),
        if (file.size != null)
          Text(
            _formatSize(file.size!),
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
      ],
    );
  }

  bool _isImage(String? mimeType) {
    return mimeType?.startsWith('image/') ?? false;
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;

    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    }

    return Icons.insert_drive_file;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

### Usage

```dart
import 'package:championforms/championforms.dart' as form;

// Use as inline builder with existing FileUpload field
form.FileUpload(
  id: 'documents',
  title: 'Upload Documents',
  multiselect: true,
  allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
  fieldBuilder: (ctx) => EnhancedFileUploadWidget(context: ctx),
  validators: [
    form.Validator(
      validator: (r) => form.Validators.isEmpty(r),
      reason: 'Please upload at least one document',
    ),
    form.Validator(
      validator: (r) {
        final files = r.asFile();
        return files.any((f) => (f.size ?? 0) > 10 * 1024 * 1024); // 10MB
      },
      reason: 'File size must not exceed 10MB',
    ),
  ],
)

// Get uploaded files
final results = form.FormResults.getResults(controller: controller);
final documents = results.grab('documents').asFile();
for (var doc in documents) {
  print('File: ${doc.name}, Size: ${doc.size}, Path: ${doc.path}');
  // Upload doc.bytes or doc.path to server
}
```

### Key Takeaways
- Enhances built-in FileUpload with custom UI
- Displays file previews in a grid layout
- Shows thumbnails for images, icons for other types
- Displays file metadata (name, size, type)
- Demonstrates inline builder pattern for customization
- Works with existing FileUpload validation

---

## Example 7: Working with Complex Value Types

When building custom fields that work with complex data types (DateTime, custom objects, enums), you need a strategy for storing and retrieving these values. The `FieldOption.additionalData` pattern solves this elegantly.

### Use Case
- Store complex types (DateTime, enums, custom objects)
- Maintain string serialization for persistence
- Provide type-safe access to original values
- Support converters that return complex types

### The Pattern

**Problem:** Forms typically store string values, but your custom field needs to work with complex types like DateTime, enums, or custom objects.

**Solution:** Use `FieldOption` to store both a string representation (for serialization) and the original complex value (in `additionalData`).

```dart
form.FieldOption(
  value: "2024-11-15",              // String for serialization/storage
  label: "November 15, 2024",       // User-friendly display
  additionalData: DateTime(...),    // Original complex type
)
```

### Example: Star Rating Field

```dart
/// Create FieldOption from rating value
static form.FieldOption fromRating(double rating) {
  final label = _getRatingLabel(rating);
  return form.FieldOption(
    value: rating.toString(),           // String for storage
    label: '$rating - $label',          // Display text
    additionalData: rating,             // Original double value
  );
}

/// Extract rating from FieldOption.additionalData
static double extractRating(form.FieldResultAccessor accessor) {
  final value = accessor.value;

  if (value is List<form.FieldOption> && value.isNotEmpty) {
    final option = value.first;

    // Extract from additionalData (preferred)
    if (option.additionalData is double) {
      return option.additionalData as double;
    }

    // Fallback: parse from value string
    return double.tryParse(option.value) ?? 0.0;
  }

  return 0.0;
}
```

### Pattern: DateTime Storage

The same pattern works brilliantly for date/time pickers:

```dart
/// Create FieldOption from DateTime
static form.FieldOption fromDateTime(DateTime date) {
  return form.FieldOption(
    value: date.toIso8601String(),                    // ISO string for serialization
    label: DateFormat('MMM dd, yyyy').format(date),   // "Nov 15, 2024"
    additionalData: date,                             // Original DateTime object
  );
}

/// Extract DateTime from FieldOption
static DateTime? extractDateTime(form.FieldResultAccessor accessor) {
  final value = accessor.value;

  if (value is List<form.FieldOption> && value.isNotEmpty) {
    final option = value.first;

    // Prefer additionalData
    if (option.additionalData is DateTime) {
      return option.additionalData as DateTime;
    }

    // Fallback: parse ISO string
    return DateTime.tryParse(option.value);
  }

  return null;
}
```

### Pattern: Enum Storage

For enum-based fields:

```dart
enum Priority { low, medium, high, critical }

static form.FieldOption fromPriority(Priority priority) {
  return form.FieldOption(
    value: priority.name,                           // "low", "medium", etc.
    label: _formatPriorityLabel(priority),          // "Low Priority", etc.
    additionalData: priority,                       // Original enum value
  );
}

static Priority? extractPriority(form.FieldResultAccessor accessor) {
  final value = accessor.value;

  if (value is List<form.FieldOption> && value.isNotEmpty) {
    final option = value.first;

    // Prefer additionalData
    if (option.additionalData is Priority) {
      return option.additionalData as Priority;
    }

    // Fallback: parse from string
    return Priority.values.firstWhere(
      (p) => p.name == option.value,
      orElse: () => Priority.low,
    );
  }

  return null;
}
```

### Key Takeaways
- Use `FieldOption.additionalData` to store complex types (DateTime, enums, custom objects)
- Keep `FieldOption.value` as a string for serialization/persistence
- Provide static helper methods (`fromX`, `extractX`) for easy usage
- Implement converters that work with both additionalData and fallback parsing
- This pattern enables type-safe access while maintaining string serialization

---

## Pattern: Central Registry for Custom Field Libraries

When creating a library of custom fields (like championforms_shadcn_fields), use a central registry pattern to simplify initialization.

### The Problem

Without a central registry, users must register each field individually:

```dart
// ❌ Tedious for users
FormFieldRegistry.register<TextInputField>('shadcn_text', ...);
FormFieldRegistry.register<DatePickerField>('shadcn_date', ...);
FormFieldRegistry.register<StarRatingField>('shadcn_rating', ...);
// ... 20 more registrations
```

### The Solution

Provide a single registration method:

```dart
// ✅ Simple one-liner
ShadcnFieldRegistry.registerAll();
```

### Implementation

**File:** `lib/registry.dart`

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

/// Central registry for all custom fields
class MyFieldRegistry {
  /// Register all custom fields with ChampionForms
  ///
  /// Call this once in main() before runApp():
  /// ```dart
  /// void main() {
  ///   MyFieldRegistry.registerAll();
  ///   runApp(MyApp());
  /// }
  /// ```
  static void registerAll() {
    FormFieldRegistry.register<TextInputField>(
      'my_text_input',
      (ctx) => TextInputWidget(context: ctx),
      converters: TextInputFieldConverters(),
    );

    FormFieldRegistry.register<DatePickerField>(
      'my_date_picker',
      (ctx) => DatePickerWidget(context: ctx),
      converters: DateTimeConverters(),
    );

    FormFieldRegistry.register<StarRatingField>(
      'my_star_rating',
      (ctx) => StarRatingWidget(context: ctx),
      converters: StarRatingFieldConverters(),
    );

    // ... register all other custom fields
  }

  /// Unregister all fields (useful for testing)
  static void unregisterAll() {
    FormFieldRegistry.unregister<TextInputField>();
    FormFieldRegistry.unregister<DatePickerField>();
    FormFieldRegistry.unregister<StarRatingField>();
    // ... unregister all fields
  }
}
```

### Library Export

**File:** `lib/my_custom_fields.dart`

```dart
library my_custom_fields;

// Export registry
export 'registry.dart';

// Export all custom field types
export 'fields/text_input_field.dart';
export 'fields/date_picker_field.dart';
export 'fields/star_rating_field.dart';

// Export converters
export 'converters/date_time_converters.dart';
export 'converters/star_rating_converters.dart';
```

### Usage by Consumers

```dart
import 'package:my_custom_fields/my_custom_fields.dart';

void main() {
  // One-line registration of all custom fields
  MyFieldRegistry.registerAll();

  runApp(MyApp());
}
```

### Advanced: Conditional Registration

Support conditional field registration for smaller bundle sizes:

```dart
class MyFieldRegistry {
  /// Register only text-based fields
  static void registerTextFields() {
    FormFieldRegistry.register<TextInputField>(...);
    FormFieldRegistry.register<TextAreaField>(...);
  }

  /// Register only selection fields
  static void registerSelectionFields() {
    FormFieldRegistry.register<SwitchField>(...);
    FormFieldRegistry.register<CheckboxField>(...);
  }

  /// Register all fields (convenience)
  static void registerAll() {
    registerTextFields();
    registerSelectionFields();
  }
}
```

### Key Takeaways
- Provide a central registry class for custom field libraries
- Export all fields and converters from a single library file
- Support one-line registration via `registerAll()`
- Consider conditional registration for advanced users
- Provide `unregisterAll()` for testing scenarios

---

## Best Practices

### 1. Choose the Right Approach
- **File-based**: New behaviors, reusable components
- **Inline builder**: Design customization, one-off tweaks

### 2. Use StatefulFieldWidget for Complex Fields
- Automatic lifecycle management
- No manual listener setup/cleanup
- Built-in change detection and validation

### 3. Leverage FieldBuilderContext
- Use convenience methods (getValue, setValue, etc.)
- Access theme-aware colors via `ctx.colors`
- Lazy initialization with getTextController/getFocusNode

### 4. Implement Converters for Custom Types
- Define how your custom data converts to string/list/bool
- Register converters with FormFieldRegistry
- Throw TypeError on invalid input for clear errors

**Inline vs Separate Converter Classes:**
- **Inline converters**: Simple 1:1 type conversions (asString, asInt, etc.)
- **Separate converter class**: Complex data structures, helper methods needed, reusable across multiple fields
- **Mixin vs Class**: Both work - use `mixin` for composition, plain `class` for simple implementations

```dart
// Simple field: Inline converters
class TextInputField extends form.Field implements form.FieldConverters {
  @override
  String asString() => /* ... */;
}

// Complex field: Separate converter class
class StarRatingConverters implements form.FieldConverters {
  static double extractRating(...) { }
  static form.FieldOption fromRating(...) { }
  @override
  String asString() => extractRating().toString();
}
```

### 5. Override Lifecycle Hooks When Needed
- `onValueChanged`: For onChange callbacks, side effects
- `onFocusChanged`: For custom focus behavior
- `onValidate`: For custom validation logic

### 6. Keep Validation Separate
- Define validators on the Field, not in widget
- Use form.Validator with clear reason messages
- Reuse validators across similar fields

### 7. Test Your Custom Fields
- Test value updates and change detection
- Test validation triggers (on blur, on submit)
- Test focus management
- Test with FormResults.getResults()

---

## Additional Resources

- [FieldBuilderContext API Reference](field-builder-context.md)
- [StatefulFieldWidget Guide](stateful-field-widget.md)
- [Converters Guide](converters.md)
- [Migration Guide v0.5.x → v0.6.0](../migrations/MIGRATION-0.6.0.md)
- [Main README](../../README.md)

---

## Contributing Examples

Have a great custom field example? Contributions are welcome! Open a pull request with:
- Complete, working code
- Clear use case description
- Usage example
- Any special dependencies noted

We especially welcome examples for:
- Color picker field
- Slider/range field
- Rating field (stars)
- Location picker field
- Code editor field
- Markdown editor field

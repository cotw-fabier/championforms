# Field Types API Reference

Complete reference guide for all built-in ChampionForms field types, their properties, and usage examples.

## Table of Contents

- [Overview](#overview)
- [Common Properties (FieldBase)](#common-properties-fieldbase)
- [TextField](#textfield)
- [OptionSelect](#optionselect)
- [CheckboxSelect](#checkboxselect)
- [ChipSelect](#chipselect)
- [FileUpload](#fileupload)
- [Row & Column (Layout)](#row--column-layout)
- [Compound Fields](#compound-fields)
  - [NameField](#namefield)
  - [AddressField](#addressfield)
  - [Custom Compound Fields](#custom-compound-fields)
- [Custom Fields](#custom-fields)
- [Related Documentation](#related-documentation)

## Overview

ChampionForms provides a hierarchical field type system that separates standard input fields from layout elements:

### Field Hierarchy

```
FormElement (abstract base)
├── Field (concrete) - Standard input fields
│   ├── TextField - Text input
│   ├── OptionSelect - Selection base class
│   │   ├── CheckboxSelect - Checkbox list
│   │   ├── ChipSelect - Chip-based selection
│   │   └── FileUpload - File picker/upload
│   └── CompoundField - Multi-field composites
│       ├── NameField - Built-in name fields
│       └── AddressField - Built-in address fields
└── Layout Elements
    ├── Row - Horizontal layout container
    └── Column - Vertical layout container
```

### Namespace Import Pattern

All field types use the namespace import pattern to avoid naming conflicts with Flutter's built-in widgets:

```dart
import 'package:championforms/championforms.dart' as form;

// Use fields with form. prefix
form.TextField(id: 'email'),
form.OptionSelect(id: 'country'),
form.Row(children: [...]),
```

### Field vs Layout Types

- **Field Types** (`TextField`, `OptionSelect`, etc.) - Accept user input, have values, support validation
- **Layout Types** (`Row`, `Column`) - Structure the form visually, don't store values themselves

---

## Common Properties (FieldBase)

All field types inherit these base properties:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | **required** | Unique identifier for the field. Used to access field values in results. |
| `title` | `String?` | `null` | Optional title/label displayed above the field |
| `description` | `String?` | `null` | Optional description text displayed above the field |
| `icon` | `Widget?` | `null` | Optional icon widget |
| `disabled` | `bool` | `false` | Whether the field is disabled (non-editable) |
| `hideField` | `bool` | `false` | Whether to hide the field from display |
| `requestFocus` | `bool` | `false` | Whether to automatically focus this field when form loads |
| `validators` | `List<Validator>?` | `null` | List of validation rules to apply |
| `validateLive` | `bool` | `false` | Whether to validate on blur (when field loses focus) |
| `defaultValue` | `dynamic` | varies | Default value for the field (type varies by field) |
| `onChange` | `Function(FormResults)?` | `null` | Callback triggered when field value changes |
| `onSubmit` | `Function(FormResults)?` | `null` | Callback triggered on form submission |
| `theme` | `FormTheme?` | `null` | Custom theme override for this field |
| `fieldLayout` | `Widget Function(...)?` | `null` | Custom layout wrapper function |
| `fieldBackground` | `Widget?` | `null` | Custom background widget |

### Example: Common Properties Usage

```dart
form.TextField(
  id: "username",
  title: "Username",
  description: "Choose a unique username (3-20 characters)",
  disabled: false,
  validateLive: true,
  validators: [
    form.Validator(
      validator: (results) => form.Validators.stringIsNotEmpty(results),
      reason: "Username is required"
    ),
  ],
  onChange: (results) {
    print("Username changed: ${results.grab('username').asString()}");
  },
)
```

---

## TextField

Standard text input field with support for single-line, multi-line, password, and autocomplete modes.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **Basic Properties** |
| `id` | `String` | **required** | Unique identifier |
| `textFieldTitle` | `String?` | `null` | Label text that animates to the border (Material Design style) |
| `hintText` | `String` | `""` | Placeholder text shown inside the field |
| `description` | `String?` | `null` | Help text displayed above the field |
| `defaultValue` | `String?` | `null` | Initial text value |
| **Behavior** |
| `maxLines` | `int?` | `null` | Number of lines (1 for single-line, null or >1 for multiline) |
| `password` | `bool` | `false` | Whether to obscure text (for passwords) |
| `maxLength` | `int?` | `null` | Maximum character length |
| `keyboardType` | `TextInputType?` | `null` | Keyboard type (numeric, email, etc.) |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | Input format restrictions |
| **Visual Elements** |
| `leading` | `Widget?` | `null` | Widget displayed at the start of the field |
| `trailing` | `Widget?` | `null` | Widget displayed at the end of the field |
| `icon` | `Widget?` | `null` | Icon widget |
| **Autocomplete** |
| `autoComplete` | `AutoCompleteBuilder?` | `null` | Autocomplete configuration |
| **Advanced** |
| `fieldBuilder` | `Widget Function(FieldBuilderContext)?` | `null` | Custom field builder override |
| `draggable` | `bool` | `true` | Whether field supports drag operations |
| `onDrop` | `Function?` | `null` | Callback for drop events |
| `onPaste` | `Function?` | `null` | Callback for paste events |

### Examples

#### Basic Text Field

```dart
form.TextField(
  id: "name",
  textFieldTitle: "Full Name",
  hintText: "Enter your full name",
  description: "Your legal name as it appears on ID",
  maxLines: 1,
  validators: [
    form.Validator(
      validator: (r) => form.Validators.stringIsNotEmpty(r),
      reason: "Name is required"
    )
  ],
)
```

#### Email Field with Validation

```dart
form.TextField(
  id: "Email",
  textFieldTitle: "Email Address",
  hintText: "Enter your email",
  description: "Your login email.",
  maxLines: 1,
  validateLive: true,
  validators: [
    form.Validator(
      validator: (results) => form.Validators.stringIsNotEmpty(results),
      reason: "Email cannot be empty."
    ),
    form.Validator(
      validator: (results) => form.Validators.isEmail(results),
      reason: "Please enter a valid email address."
    ),
  ],
  leading: const Icon(Icons.email),
)
```

#### Password Field

```dart
form.TextField(
  id: "Password",
  textFieldTitle: "Password",
  description: "Enter your password",
  maxLines: 1,
  password: true,  // Obscures text
  validateLive: true,
  onSubmit: (results) => _handleLogin(),
  validators: [
    form.Validator(
      validator: (results) => form.Validators.stringIsNotEmpty(results),
      reason: "Password cannot be empty."
    ),
  ],
  leading: const Icon(Icons.lock),
)
```

#### Multiline Text Field

```dart
form.TextField(
  id: "bio",
  textFieldTitle: "Biography",
  hintText: "Tell us about yourself...",
  maxLines: 5,  // Multi-line text area
  maxLength: 500,  // Character limit
)
```

#### Text Field with Autocomplete

```dart
form.TextField(
  id: "Email",
  textFieldTitle: "Email Address",
  hintText: "Enter your email",
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: "test1@example.com"),
      form.CompleteOption(value: "test2@example.com"),
      form.CompleteOption(value: "another@domain.net"),
    ],
    updateOptions: (searchValue) async {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Filter and return options
      return [
        form.CompleteOption(value: "test1@example.com"),
        form.CompleteOption(value: "test2@example.com"),
        form.CompleteOption(value: "another@domain.net"),
      ].where((opt) =>
        opt.value.toLowerCase().contains(searchValue.toLowerCase())
      ).toList();
    },
    debounceWait: const Duration(milliseconds: 250),
  ),
)
```

### AutoCompleteBuilder Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | `AutoCompleteType` | `dropdown` | Autocomplete display type |
| `initialOptions` | `List<CompleteOption>` | `[]` | Initial list of suggestions |
| `updateOptions` | `Future<List<CompleteOption>> Function(String)?` | `null` | Async function to fetch suggestions |
| `debounceDuration` | `Duration` | `1 second` | Debounce for async fetching |
| `debounceWait` | `Duration` | `100ms` | Wait before triggering update |
| `optionBuilder` | `Widget Function(...)?` | `null` | Custom option widget builder |
| `dropdownBoxMargin` | `int` | `8` | Spacing around dropdown |
| `minHeight` | `int?` | `null` | Minimum dropdown height |
| `maxHeight` | `int?` | `null` | Maximum dropdown height |
| `percentageHeight` | `int?` | `null` | Dropdown height as % of available space |

---

## OptionSelect

Base class for selection fields (dropdown, radio, checkbox). Supports single and multi-select modes.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | **required** | Unique identifier |
| `title` | `String?` | `null` | Field label |
| `description` | `String?` | `null` | Help text |
| `options` | `List<FieldOption>?` | `null` | List of selectable options |
| `multiselect` | `bool` | `false` | Allow multiple selections |
| `defaultValue` | `List<FieldOption>` | `[]` | Default selected options |
| `caseSensitiveDefaultValue` | `bool` | `true` | Case-sensitive default matching |
| `leading` | `Widget?` | `null` | Leading widget |
| `trailing` | `Widget?` | `null` | Trailing widget |
| `fieldBuilder` | `Widget Function(FieldBuilderContext)?` | dropdown | Custom UI builder (defaults to dropdown) |

### FieldOption Structure

Options are defined using the `FieldOption` class:

```dart
class FieldOption {
  final String value;          // Value submitted with form
  final String label;          // Display text (defaults to value)
  final Object? additionalData; // Optional extra data
  final String? hintText;      // Optional hint text
}
```

### Examples

#### Dropdown (Single Select)

```dart
form.OptionSelect(
  id: "DropdownField",
  title: "Select an Option",
  description: "Choose one from the list.",
  multiselect: false,
  defaultValue: [
    form.FieldOption(label: "Option 1", value: "Value 1"),
  ],
  options: [
    form.FieldOption(label: "Option 1", value: "Value 1"),
    form.FieldOption(label: "Option 2", value: "Value 2"),
    form.FieldOption(label: "Option 3", value: "Value 3"),
    form.FieldOption(label: "Option 4", value: "Value 4"),
  ],
)
```

#### Multi-Select Dropdown

```dart
form.OptionSelect(
  id: "categories",
  title: "Select Categories",
  description: "Choose all that apply",
  multiselect: true,
  options: [
    form.FieldOption(label: "Electronics", value: "electronics"),
    form.FieldOption(label: "Clothing", value: "clothing"),
    form.FieldOption(label: "Books", value: "books"),
  ],
  validators: [
    form.Validator(
      validator: (r) => form.Validators.listIsNotEmpty(r),
      reason: "Please select at least one category"
    ),
  ],
)
```

#### Options with Additional Data

```dart
form.OptionSelect(
  id: "product",
  title: "Select Product",
  options: [
    form.FieldOption(
      label: "Widget Pro",
      value: "widget_pro",
      additionalData: {"price": 99.99, "sku": "WP-001"}
    ),
    form.FieldOption(
      label: "Widget Basic",
      value: "widget_basic",
      additionalData: {"price": 49.99, "sku": "WB-001"}
    ),
  ],
)

// Access additional data in results
final selectedOptions = results.grab("product").asMultiselectList();
for (final option in selectedOptions) {
  final data = option.additionalData as Map<String, dynamic>;
  print("Price: ${data['price']}");
}
```

---

## CheckboxSelect

Convenience widget for rendering `OptionSelect` as a checkbox list.

### Properties

Inherits all properties from `OptionSelect`. The only difference is the default `fieldBuilder` renders checkboxes instead of a dropdown.

### Example

```dart
form.CheckboxSelect(
  id: "SelectBox",
  title: "Choose Multiple",
  description: "Select all that apply.",
  validateLive: true,
  validators: [
    form.Validator(
      validator: (results) => form.Validators.listIsNotEmpty(results),
      reason: "Please select at least one option."
    ),
  ],
  defaultValue: [
    form.FieldOption(value: "Hiya", label: "Wat"),
  ],
  options: [
    form.FieldOption(value: "Hi", label: "Hello"),
    form.FieldOption(value: "Hiya", label: "Wat"),
    form.FieldOption(value: "Yoz", label: "Sup"),
  ],
)
```

---

## ChipSelect

Convenience widget for rendering `OptionSelect` as chip-based selection UI.

### Properties

Inherits all properties from `OptionSelect`. Uses chip-style visual rendering.

### Example

```dart
form.ChipSelect(
  id: "tags",
  title: "Select Tags",
  description: "Choose relevant tags",
  multiselect: true,
  options: [
    form.FieldOption(label: "Urgent", value: "urgent"),
    form.FieldOption(label: "Important", value: "important"),
    form.FieldOption(label: "Review", value: "review"),
    form.FieldOption(label: "Follow-up", value: "followup"),
  ],
)
```

---

## FileUpload

Specialized field for file uploads with file picker integration and drag-and-drop support.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **Inherited from OptionSelect** |
| `id` | `String` | **required** | Unique identifier |
| `title` | `String?` | `null` | Field label |
| `description` | `String?` | `null` | Help text |
| `multiselect` | `bool` | `false` | Allow multiple file uploads |
| **File-Specific** |
| `allowedExtensions` | `List<String>?` | `null` | File type filter (e.g., `['pdf', 'docx']`) |
| `maxFileSize` | `int?` | `52428800` | Max file size in bytes (default: 50 MB) |
| `displayUploadedFiles` | `bool` | `true` | Show previews/icons of uploaded files |
| `clearOnUpload` | `bool` | `false` | Clear previous files when selecting new ones |
| `dropDisplayWidget` | `Widget Function(...)?` | `null` | Customize drag-and-drop zone appearance |
| `fileUploadBuilder` | `Widget Function(List<FieldOption>)?` | `null` | Custom file list builder |

### Platform Setup Requirements

**IMPORTANT:** `FileUpload` requires platform-specific permissions configuration.

#### iOS - Info.plist

Add these keys to your `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload images</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos</string>
```

#### Android - AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

#### macOS - Entitlements

Add to entitlements files:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

See [file_picker documentation](https://pub.dev/packages/file_picker#setup) for complete setup instructions.

### Examples

#### Image Upload

```dart
form.FileUpload(
  id: "fileUpload",
  title: "Upload Images",
  description: "Drag & drop or click to upload (JPG, PNG only).",
  multiselect: true,
  validateLive: true,
  clearOnUpload: true,
  allowedExtensions: ['jpg', 'jpeg', 'png'],
  validators: [
    form.Validator(
      reason: "Only image files (JPG, PNG) are allowed.",
      validator: (results) => form.Validators.fileIsImage(results),
    ),
  ],
)
```

#### Document Upload with File Size Limit

```dart
form.FileUpload(
  id: "documents",
  title: "Upload Documents",
  description: "PDF or Word files only (max 10 MB each)",
  multiselect: true,
  allowedExtensions: ['pdf', 'doc', 'docx'],
  maxFileSize: 10485760,  // 10 MB in bytes
  validators: [
    form.Validator(
      validator: (results) => form.Validators.fileIsDocument(results),
      reason: "Only document files are allowed"
    ),
  ],
)
```

#### Single File Upload

```dart
form.FileUpload(
  id: "avatar",
  title: "Profile Picture",
  description: "Upload your profile picture (PNG only)",
  multiselect: false,  // Single file only
  allowedExtensions: ['png'],
  validators: [
    form.Validator(
      validator: (r) => form.Validators.fileIsImage(r),
      reason: "Must be an image"
    )
  ],
)
```

#### Custom Drop Zone

```dart
form.FileUpload(
  id: "files",
  title: "Upload Files",
  multiselect: true,
  dropDisplayWidget: (colors, field) => Container(
    padding: EdgeInsets.all(40),
    decoration: BoxDecoration(
      border: Border.all(color: colors.borderColor, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Icon(Icons.cloud_upload, size: 48, color: colors.iconColor),
        SizedBox(height: 16),
        Text(
          "Drop files here or click to browse",
          style: TextStyle(color: colors.textColor),
        ),
      ],
    ),
  ),
)
```

### File Validators

ChampionForms provides built-in file validators:

```dart
// Check if files are images
form.Validators.fileIsImage(results)

// Check for common image types (JPG, PNG, GIF, etc.)
form.Validators.fileIsCommonImage(results)

// Check if files are documents
form.Validators.fileIsDocument(results)

// Check specific MIME types
form.Validators.isMimeType(results, ['image/jpeg', 'image/png'])
```

### Accessing File Results

```dart
final results = form.FormResults.getResults(controller: controller);

// Get files using asFileList()
final files = results.grab("fileUpload").asFileList();

for (final fileData in files) {
  print("File name: ${fileData.fileName}");
  print("File path: ${fileData.filePath}");
  print("MIME type: ${fileData.mimeData?.mime ?? 'N/A'}");

  // Access file bytes (async)
  final bytes = await fileData.fileDetails?.getFileBytes();
  print("File size: ${bytes?.length ?? 0} bytes");
}
```

---

## Row & Column (Layout)

Layout widgets for structuring forms horizontally (Row) and vertically (Column).

### Row Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | `List<Column>` | **required** | List of columns to arrange horizontally |
| `collapse` | `bool` | `false` | Stack columns vertically on small screens |
| `rollUpErrors` | `bool` | `false` | Display all child field errors below the row |
| `hideField` | `bool` | `false` | Hide the entire row |
| `spacing` | `double` | `10` | Spacing between columns |

### Column Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | `List<FormElement>` | **required** | List of fields or nested rows/columns |
| `widthFactor` | `double?` | `null` | Width as fraction of row (e.g., 0.5 for 50%) |
| `rollUpErrors` | `bool` | `false` | Display all child field errors below the column |
| `hideField` | `bool` | `false` | Hide the entire column |
| `spacing` | `double` | `10` | Spacing between child elements |
| `columnWrapper` | `Widget Function(...)?` | `null` | Custom wrapper for column contents |

### Examples

#### Two-Column Layout

```dart
form.Row(
  children: [
    // Left column (email)
    form.Column(
      widthFactor: 2,  // Takes 2/3 of available width
      children: [
        form.TextField(
          id: "Email",
          textFieldTitle: "Email Address",
          hintText: "Enter your email",
        ),
      ],
    ),
    // Right column (password)
    form.Column(
      widthFactor: 1,  // Takes 1/3 of available width
      children: [
        form.TextField(
          id: "Password",
          textFieldTitle: "Password",
          password: true,
        ),
      ],
    ),
  ],
)
```

#### Responsive Collapse

```dart
form.Row(
  collapse: true,  // Stack vertically on narrow screens
  children: [
    form.Column(children: [
      form.TextField(id: "firstName", textFieldTitle: "First Name"),
    ]),
    form.Column(children: [
      form.TextField(id: "lastName", textFieldTitle: "Last Name"),
    ]),
  ],
)
```

#### Nested Rows and Columns

```dart
form.Column(
  children: [
    // First row: Name fields
    form.Row(
      children: [
        form.Column(children: [
          form.TextField(id: "firstName", textFieldTitle: "First"),
        ]),
        form.Column(children: [
          form.TextField(id: "lastName", textFieldTitle: "Last"),
        ]),
      ],
    ),
    // Second row: Contact fields
    form.Row(
      children: [
        form.Column(children: [
          form.TextField(id: "email", textFieldTitle: "Email"),
        ]),
        form.Column(children: [
          form.TextField(id: "phone", textFieldTitle: "Phone"),
        ]),
      ],
    ),
  ],
)
```

#### Error Rollup

```dart
form.Row(
  rollUpErrors: true,  // Show all validation errors below the row
  children: [
    form.Column(children: [
      form.TextField(
        id: "email",
        textFieldTitle: "Email",
        validators: [
          form.Validator(
            validator: (r) => form.Validators.isEmail(r),
            reason: "Invalid email"
          ),
        ],
      ),
    ]),
    form.Column(children: [
      form.TextField(
        id: "confirmEmail",
        textFieldTitle: "Confirm Email",
        validators: [
          form.Validator(
            validator: (r) => form.Validators.isEmail(r),
            reason: "Invalid email"
          ),
        ],
      ),
    ]),
  ],
)
```

---

## Compound Fields

Compound fields are composite fields made up of multiple sub-fields that work together as a cohesive unit. Each sub-field behaves as an independent field in the FormController.

### Key Features

- **Automatic ID Prefixing**: Sub-fields get IDs like `{compoundId}_{subFieldId}` to prevent conflicts
- **Controller Transparency**: Sub-fields work with all existing controller methods
- **Custom Layouts**: Each compound field can define its own layout
- **Flexible Results Access**: Access combined values with `asCompound()` or individual sub-fields

### Built-in Compound Fields

ChampionForms provides two ready-to-use compound fields:

---

## NameField

Built-in compound field for collecting name information (first, middle, last).

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | **required** | Unique identifier |
| `includeMiddleName` | `bool` | `true` | Whether to include middle name field |
| `title` | `String?` | `null` | Field group label |
| `description` | `String?` | `null` | Help text |
| `disabled` | `bool` | `false` | Disable all sub-fields |
| `hideField` | `bool` | `false` | Hide entire field group |
| `rollUpErrors` | `bool` | `false` | Display sub-field errors together |
| `theme` | `FormTheme?` | `null` | Theme for all sub-fields |
| `validators` | `List<Validator>?` | `null` | Validators for the compound field |
| `validateLive` | `bool` | `false` | Validate on blur |
| `onSubmit` | `Function(FormResults)?` | `null` | Submission callback |
| `onChange` | `Function(FormResults)?` | `null` | Change callback |

### Sub-fields Generated

| Sub-field ID | Field Type | Title |
|--------------|------------|-------|
| `{id}_firstname` | TextField | "First Name" |
| `{id}_middlename` | TextField | "Middle Name" (if `includeMiddleName: true`) |
| `{id}_lastname` | TextField | "Last Name" |

### Default Layout

Arranges sub-fields horizontally in a Row with:
- First name: flex 1
- Middle name: flex 1 (if included)
- Last name: flex 2
- 10px spacing between fields

### Examples

#### Basic Name Field

```dart
form.NameField(
  id: 'customer_name',
  title: 'Customer Name',
  includeMiddleName: true,
)
```

#### Name Field without Middle Name

```dart
form.NameField(
  id: 'author_name',
  title: 'Author',
  includeMiddleName: false,  // Only first and last name
)
```

#### Name Field with Validation

```dart
form.NameField(
  id: 'customer_name',
  title: 'Full Name',
  description: 'First, middle, and last name',
  includeMiddleName: true,
  rollUpErrors: true,
  validators: [
    form.Validator(
      validator: (results) {
        final firstName = results.grab('customer_name_firstname').asString();
        final lastName = results.grab('customer_name_lastname').asString();
        return firstName.isNotEmpty && lastName.isNotEmpty;
      },
      reason: 'First and last name are required',
    ),
  ],
)
```

#### Accessing Name Field Results

```dart
final results = form.FormResults.getResults(controller: controller);

// Get full name as combined string
final fullName = results.grab("customer_name").asCompound(delimiter: " ");
// Example: "John Michael Doe"

// Get individual sub-field values
final firstName = results.grab("customer_name_firstname").asString();
final middleName = results.grab("customer_name_middlename").asString();
final lastName = results.grab("customer_name_lastname").asString();
```

---

## AddressField

Built-in compound field for collecting address information.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | **required** | Unique identifier |
| `includeStreet2` | `bool` | `true` | Whether to include apartment/suite field |
| `includeCountry` | `bool` | `false` | Whether to include country field |
| `title` | `String?` | `null` | Field group label |
| `description` | `String?` | `null` | Help text |
| `disabled` | `bool` | `false` | Disable all sub-fields |
| `hideField` | `bool` | `false` | Hide entire field group |
| `rollUpErrors` | `bool` | `false` | Display sub-field errors together |
| `theme` | `FormTheme?` | `null` | Theme for all sub-fields |
| `validators` | `List<Validator>?` | `null` | Validators for the compound field |
| `validateLive` | `bool` | `false` | Validate on blur |
| `onSubmit` | `Function(FormResults)?` | `null` | Submission callback |
| `onChange` | `Function(FormResults)?` | `null` | Change callback |

### Sub-fields Generated

| Sub-field ID | Field Type | Title | Included When |
|--------------|------------|-------|---------------|
| `{id}_street` | TextField | "Street Address" | Always |
| `{id}_street2` | TextField | "Apartment, suite, etc." | `includeStreet2: true` |
| `{id}_city` | TextField | "City" | Always |
| `{id}_state` | TextField | "State" | Always |
| `{id}_zip` | TextField | "ZIP Code" | Always |
| `{id}_country` | TextField | "Country" | `includeCountry: true` |

### Default Layout

Multi-row vertical layout:
1. Street (full width)
2. Street 2 (full width, if included)
3. City (flex: 4) / State (flex: 3) / ZIP (flex: 3) - horizontal row
4. Country (full width, if included)
5. 10px spacing between rows

### Examples

#### Basic Address Field

```dart
form.AddressField(
  id: 'shipping_address',
  title: 'Shipping Address',
  includeStreet2: true,
  includeCountry: false,
)
```

#### Billing Address with Country

```dart
form.AddressField(
  id: 'billing_address',
  title: 'Billing Address',
  description: 'Street, city, state, ZIP, and country',
  includeStreet2: true,
  includeCountry: true,  // Include country field
)
```

#### Address Field with Validation

```dart
form.AddressField(
  id: 'shipping_address',
  title: 'Shipping Address',
  includeStreet2: true,
  includeCountry: false,
  rollUpErrors: true,
  validators: [
    form.Validator(
      validator: (results) {
        final street = results.grab('shipping_address_street').asString();
        final city = results.grab('shipping_address_city').asString();
        final state = results.grab('shipping_address_state').asString();
        final zip = results.grab('shipping_address_zip').asString();
        return street.isNotEmpty &&
               city.isNotEmpty &&
               state.isNotEmpty &&
               zip.isNotEmpty;
      },
      reason: 'Street, city, state, and ZIP are required',
    ),
  ],
)
```

#### Accessing Address Field Results

```dart
final results = form.FormResults.getResults(controller: controller);

// Get full address as combined string
final fullAddress = results.grab("shipping_address").asCompound(delimiter: ", ");
// Example: "123 Main St, Apt 4B, Springfield, IL, 62701"

// Get individual sub-field values
final street = results.grab("shipping_address_street").asString();
final street2 = results.grab("shipping_address_street2").asString();
final city = results.grab("shipping_address_city").asString();
final state = results.grab("shipping_address_state").asString();
final zip = results.grab("shipping_address_zip").asString();
```

---

## Custom Compound Fields

You can create your own compound fields by extending `CompoundField` and registering them with the `FormFieldRegistry`.

### Creating a Custom Compound Field

```dart
import 'package:championforms/championforms.dart' as form;

class ContactField extends form.CompoundField {
  final bool includePhone;

  ContactField({
    required String id,
    this.includePhone = true,
    String? title,
  }) : super(id: id, title: title);

  @override
  List<form.Field> buildSubFields() {
    final fields = [
      form.TextField(id: 'email', title: 'Email'),
    ];

    if (includePhone) {
      fields.add(form.TextField(id: 'phone', title: 'Phone'));
    }

    return fields;
  }
}
```

### Registering with Custom Layout

```dart
import 'package:championforms/championforms_themes.dart';

FormFieldRegistry.registerCompound<ContactField>(
  'contact',
  (field) => field.buildSubFields(),
  (context, subFields, errors) => Row(
    children: subFields.map((f) => Expanded(child: f)).toList(),
  ),
);
```

For complete examples and advanced patterns, see:
- [Compound Fields Guide](../guides/compound-fields.md)
- [Compound Fields Demo](../../example/lib/pages/compound_fields_demo.dart)

---

## Custom Fields

ChampionForms v0.6.0+ provides a simplified API for creating custom field types with 60-70% less boilerplate.

### Quick Example

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class RatingFieldWidget extends form.StatefulFieldWidget {
  const RatingFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
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

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}
```

### Learn More

For complete guides on creating custom fields:
- **[Custom Field Cookbook](../custom-fields/custom-field-cookbook.md)** - 6 practical examples
- **[StatefulFieldWidget Guide](../custom-fields/stateful-field-widget.md)** - Base class reference
- **[FieldBuilderContext API](../custom-fields/field-builder-context.md)** - Context object reference
- **[Migration Guide v0.5.x → v0.6.0](../migrations/MIGRATION-0.6.0.md)** - Upgrade instructions

---

## Related Documentation

### Core Concepts
- [Form Controller API](form-controller.md) - State management and controller methods
- [Validation System](validation.md) - Validators and validation patterns
- [Form Results](form-results.md) - Accessing and converting field values
- [Theming](theming.md) - Customizing field appearance

### Guides
- [Autocomplete Guide](../guides/autocomplete.md) - Implementing autocomplete
- [File Upload Guide](../guides/file-upload.md) - File handling and configuration
- [Layouts Guide](../guides/layouts.md) - Row/Column layout patterns
- [Compound Fields Guide](../guides/compound-fields.md) - Creating reusable field groups

### Custom Fields
- [Custom Field Cookbook](../custom-fields/custom-field-cookbook.md) - Complete examples
- [StatefulFieldWidget](../custom-fields/stateful-field-widget.md) - Base class documentation
- [FieldBuilderContext](../custom-fields/field-builder-context.md) - Context API reference

### Examples
- [Example App](../../example/lib/main.dart) - Complete working example
- [Compound Fields Demo](../../example/lib/pages/compound_fields_demo.dart) - Interactive demo

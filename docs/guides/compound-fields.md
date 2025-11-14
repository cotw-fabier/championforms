# Compound Fields Guide

Compound fields are reusable composite fields made up of multiple sub-fields that work together as a cohesive unit while maintaining full controller transparency.

## Table of Contents

- [What are Compound Fields?](#what-are-compound-fields)
- [Built-in Compound Fields](#built-in-compound-fields)
  - [NameField](#namefield)
  - [AddressField](#addressfield)
- [How Compound Fields Work](#how-compound-fields-work)
- [Accessing Results](#accessing-results)
  - [Using asCompound()](#using-ascompound)
  - [Accessing Individual Sub-fields](#accessing-individual-sub-fields)
- [Creating Custom Compound Fields](#creating-custom-compound-fields)
  - [Step 1: Create the CompoundField Class](#step-1-create-the-compoundfield-class)
  - [Step 2: Register the Compound Field](#step-2-register-the-compound-field)
  - [Step 3: Use Your Compound Field](#step-3-use-your-compound-field)
- [Advanced Topics](#advanced-topics)
  - [Custom Layouts](#custom-layouts)
  - [Error Rollup](#error-rollup)
  - [Theme and State Propagation](#theme-and-state-propagation)
  - [Validation Strategies](#validation-strategies)
- [Best Practices](#best-practices)
- [FAQ](#faq)

---

## What are Compound Fields?

Compound fields are composite form fields that group multiple related sub-fields together with a custom layout. They're perfect for common form patterns like names, addresses, phone numbers, or date ranges.

**Key Benefits:**
- **Reusability:** Define once, use anywhere in your application
- **Controller Transparency:** Sub-fields behave exactly like normal fields
- **Automatic ID Prefixing:** Prevents field ID conflicts
- **Custom Layouts:** Each compound field can have its own visual arrangement
- **Flexible Access:** Access values as joined strings or individual sub-fields

**Example Use Cases:**
- Name fields (first, middle, last)
- Address forms (street, city, state, zip)
- Phone numbers (country code, area code, number)
- Date ranges (start date, end date)
- Credit card details (number, expiry, CVV)

---

## Built-in Compound Fields

ChampionForms includes two production-ready compound fields out of the box.

### NameField

A horizontal layout for capturing a person's name with optional middle name.

**Properties:**
- `id` (required): Unique identifier for the compound field
- `title`: Display title for the field group
- `description`: Helper text shown below the field
- `includeMiddleName`: Whether to include middle name field (default: `true`)
- `validators`: List of validators applied to the compound field
- `disabled`: Disable all sub-fields
- `theme`: Theme applied to all sub-fields

**Sub-fields Generated:**
- `{id}_firstname` - First name text field
- `{id}_middlename` - Middle name text field (if `includeMiddleName` is true)
- `{id}_lastname` - Last name text field

**Layout:**
Horizontal Row with flex ratios:
- First Name: flex 1
- Middle Name: flex 1 (if included)
- Last Name: flex 2

**Example:**
```dart
form.NameField(
  id: 'customer_name',
  title: 'Customer Name',
  description: 'Enter the customer\'s full name',
  includeMiddleName: true,
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

### AddressField

A multi-row layout for capturing complete addresses with optional fields.

**Properties:**
- `id` (required): Unique identifier for the compound field
- `title`: Display title for the field group
- `description`: Helper text shown below the field
- `includeStreet2`: Whether to include apartment/suite field (default: `true`)
- `includeCountry`: Whether to include country field (default: `false`)
- `validators`: List of validators applied to the compound field
- `disabled`: Disable all sub-fields
- `theme`: Theme applied to all sub-fields

**Sub-fields Generated:**
- `{id}_street` - Street address text field
- `{id}_street2` - Apartment/suite text field (if `includeStreet2` is true)
- `{id}_city` - City text field
- `{id}_state` - State/province text field
- `{id}_zip` - ZIP/postal code text field
- `{id}_country` - Country text field (if `includeCountry` is true)

**Layout:**
Multi-row Column:
- Row 1: Street (full width)
- Row 2: Street 2 (full width, if included)
- Row 3: City (flex 4), State (flex 3), ZIP (flex 3) in horizontal row
- Row 4: Country (full width, if included)

**Example:**
```dart
form.AddressField(
  id: 'shipping_address',
  title: 'Shipping Address',
  description: 'Where should we ship your order?',
  includeStreet2: true,
  includeCountry: false,
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

---

## How Compound Fields Work

Understanding the internal mechanics of compound fields helps you use them effectively.

### Field Processing Flow

1. **Form Encounters CompoundField**: When the Form widget processes fields, it detects CompoundField types
2. **Sub-field Generation**: Calls the field's `buildSubFields()` method to generate sub-field list
3. **ID Prefixing**: Automatically prefixes each sub-field ID with the compound field ID
   - Pattern: `{compoundId}_{subFieldId}`
   - Example: `address` + `street` → `address_street`
4. **Controller Registration**: Each sub-field registers individually with FormController
5. **Layout Building**: Renders sub-fields using the custom layout builder (or default vertical layout)

### Controller Transparency

**This is the key architectural principle of compound fields.**

Sub-fields are completely transparent to the FormController. This means:

- ✅ All existing controller methods work unchanged
- ✅ Sub-fields have their own TextEditingControllers and FocusNodes
- ✅ Validation runs independently on each sub-field
- ✅ You can programmatically update sub-fields like any other field
- ✅ No special compound field handling needed in business logic

**Example:**
```dart
// These work exactly the same as normal fields
controller.updateFieldValue('address_street', '123 Main St');
final cityValue = controller.getFieldValue('address_city');
controller.setFieldFocus('address_zip');
```

### ID Prefixing

Automatic ID prefixing prevents conflicts when using multiple compound fields:

```dart
// Two address fields in the same form
form.AddressField(id: 'billing_address'),  // billing_address_street, billing_address_city, etc.
form.AddressField(id: 'shipping_address'), // shipping_address_street, shipping_address_city, etc.
```

**Developer Override**: If a sub-field ID already contains the prefix, it won't be re-prefixed:

```dart
// In your CompoundField's buildSubFields():
form.TextField(id: 'custom_prefix_field') // Won't be prefixed again
```

---

## Accessing Results

Compound fields provide flexible result access patterns.

### Using asCompound()

The `asCompound()` method joins all sub-field values into a single string.

**Signature:**
```dart
String asCompound({String delimiter = ", ", String fallback = ""})
```

**Parameters:**
- `delimiter`: String to join sub-field values (default: `", "`)
- `fallback`: Value to return if no sub-fields found (default: `""`)

**Behavior:**
- Automatically detects compound fields by checking for sub-fields with matching ID prefix
- Collects string values from all sub-fields using `asString()`
- Filters out empty values
- Joins non-empty values with the specified delimiter

**Examples:**
```dart
final results = form.FormResults.getResults(controller: controller);

// Name field with space delimiter
final fullName = results.grab('customer_name').asCompound(delimiter: ' ');
// Result: "John Michael Doe"

// Address field with comma delimiter (default)
final fullAddress = results.grab('shipping_address').asCompound();
// Result: "123 Main St, Apt 4, New York, NY, 10001"

// Custom delimiter
final addressOneLine = results.grab('shipping_address').asCompound(delimiter: ' | ');
// Result: "123 Main St | Apt 4 | New York | NY | 10001"

// With empty sub-fields (filters them out)
// If street2 is empty:
final address = results.grab('shipping_address').asCompound();
// Result: "123 Main St, New York, NY, 10001" (street2 omitted)
```

### Accessing Individual Sub-fields

Access sub-fields using their prefixed IDs just like normal fields.

**Example:**
```dart
final results = form.FormResults.getResults(controller: controller);

// Individual name components
final firstName = results.grab('customer_name_firstname').asString();
final middleName = results.grab('customer_name_middlename').asString();
final lastName = results.grab('customer_name_lastname').asString();

// Individual address components
final street = results.grab('shipping_address_street').asString();
final street2 = results.grab('shipping_address_street2').asString();
final city = results.grab('shipping_address_city').asString();
final state = results.grab('shipping_address_state').asString();
final zip = results.grab('shipping_address_zip').asString();

// Use in business logic
if (street2.isEmpty) {
  print('No apartment/suite number provided');
}
```

### Mixed Access Patterns

Combine both approaches for maximum flexibility:

```dart
// Get full address for display
final displayAddress = results.grab('shipping_address').asCompound(delimiter: '\n');

// Get specific fields for validation or processing
final zipCode = results.grab('shipping_address_zip').asString();
if (zipCode.length != 5) {
  // Handle invalid ZIP
}

// Send to API
final addressData = {
  'full_address': results.grab('shipping_address').asCompound(),
  'street': results.grab('shipping_address_street').asString(),
  'city': results.grab('shipping_address_city').asString(),
  'state': results.grab('shipping_address_state').asString(),
  'postal_code': results.grab('shipping_address_zip').asString(),
};
```

---

## Creating Custom Compound Fields

Create your own reusable compound fields in three steps.

### Step 1: Create the CompoundField Class

Extend `CompoundField` and implement the `buildSubFields()` method.

**Example: Phone Number Field**
```dart
import 'package:championforms/championforms.dart' as form;

class PhoneField extends form.CompoundField {
  final bool includeExtension;

  PhoneField({
    required String id,
    String? title,
    String? description,
    this.includeExtension = false,
    List<form.Validator>? validators,
    bool? disabled,
    FormTheme? theme,
  }) : super(
    id: id,
    title: title,
    description: description,
    validators: validators ?? [],
    disabled: disabled ?? false,
    theme: theme,
  );

  @override
  List<form.Field> buildSubFields() {
    final fields = <form.Field>[
      form.TextField(
        id: 'country_code',
        textFieldTitle: 'Country',
        hintText: '+1',
        maxLines: 1,
        validators: [
          form.Validator(
            validator: (results) => form.Validators.stringIsNotEmpty(results),
            reason: 'Country code required',
          ),
        ],
      ),
      form.TextField(
        id: 'area_code',
        textFieldTitle: 'Area',
        hintText: '555',
        maxLines: 1,
        validators: [
          form.Validator(
            validator: (results) => form.Validators.stringIsNotEmpty(results),
            reason: 'Area code required',
          ),
        ],
      ),
      form.TextField(
        id: 'number',
        textFieldTitle: 'Number',
        hintText: '123-4567',
        maxLines: 1,
        validators: [
          form.Validator(
            validator: (results) => form.Validators.stringIsNotEmpty(results),
            reason: 'Phone number required',
          ),
        ],
      ),
    ];

    if (includeExtension) {
      fields.add(
        form.TextField(
          id: 'extension',
          textFieldTitle: 'Ext',
          hintText: '1234',
          maxLines: 1,
        ),
      );
    }

    return fields;
  }
}
```

### Step 2: Register the Compound Field

Register your compound field with a custom layout builder.

**Basic Registration (Uses Default Vertical Layout):**
```dart
import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart';

void registerPhoneField() {
  FormFieldRegistry.registerCompound<PhoneField>(
    'phone',
    (field) => field.buildSubFields(),
    null, // Use default vertical layout
  );
}
```

**Registration with Custom Layout:**
```dart
void registerPhoneField() {
  FormFieldRegistry.registerCompound<PhoneField>(
    'phone',
    (field) => field.buildSubFields(),
    (context, subFields, errors) {
      // Custom horizontal layout
      final hasExtension = subFields.length > 3;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country code (narrow)
          SizedBox(
            width: 60,
            child: subFields[0],
          ),
          const SizedBox(width: 8),
          // Area code (narrow)
          SizedBox(
            width: 80,
            child: subFields[1],
          ),
          const SizedBox(width: 8),
          // Number (flexible)
          Expanded(
            flex: 3,
            child: subFields[2],
          ),
          // Extension (if included)
          if (hasExtension) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: subFields[3],
            ),
          ],
        ],
      );
    },
  );
}
```

**Call Registration in main():**
```dart
void main() {
  // Register your custom compound field
  registerPhoneField();

  runApp(MyApp());
}
```

### Step 3: Use Your Compound Field

Use your custom compound field just like built-in fields.

```dart
final fields = [
  PhoneField(
    id: 'contact_phone',
    title: 'Contact Phone Number',
    includeExtension: true,
    validators: [
      form.Validator(
        validator: (results) {
          final countryCode = results.grab('contact_phone_country_code').asString();
          final areaCode = results.grab('contact_phone_area_code').asString();
          final number = results.grab('contact_phone_number').asString();
          return countryCode.isNotEmpty && areaCode.isNotEmpty && number.isNotEmpty;
        },
        reason: 'Complete phone number required',
      ),
    ],
  ),
];

// Access results
final fullPhone = results.grab('contact_phone').asCompound(delimiter: '-');
// Result: "+1-555-123-4567" or "+1-555-123-4567-1234" (with extension)
```

---

## Advanced Topics

### Custom Layouts

Create sophisticated layouts for your compound fields.

**Multi-row Layout Example:**
```dart
FormFieldRegistry.registerCompound<DateRangeField>(
  'daterange',
  (field) => field.buildSubFields(),
  (context, subFields, errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Start and End Date
        Row(
          children: [
            Expanded(child: subFields[0]), // start_date
            const SizedBox(width: 16),
            Expanded(child: subFields[1]), // end_date
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Optional time fields
        Row(
          children: [
            Expanded(child: subFields[2]), // start_time
            const SizedBox(width: 16),
            Expanded(child: subFields[3]), // end_time
          ],
        ),
        // Error display
        if (errors != null && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...errors.map((error) => Text(
            error.reason,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          )),
        ],
      ],
    );
  },
);
```

**Responsive Layout Example:**
```dart
FormFieldRegistry.registerCompound<CreditCardField>(
  'creditcard',
  (field) => field.buildSubFields(),
  (context, subFields, errors) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Vertical layout for small screens
      return Column(
        children: [
          subFields[0], // card_number
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: subFields[1]), // expiry
              const SizedBox(width: 12),
              Expanded(child: subFields[2]), // cvv
            ],
          ),
        ],
      );
    } else {
      // Horizontal layout for large screens
      return Row(
        children: [
          Expanded(flex: 3, child: subFields[0]), // card_number
          const SizedBox(width: 12),
          Expanded(flex: 1, child: subFields[1]), // expiry
          const SizedBox(width: 12),
          Expanded(flex: 1, child: subFields[2]), // cvv
        ],
      );
    }
  },
);
```

### Error Rollup

Control where validation errors are displayed.

**Per-field Errors (Default):**
```dart
// Each sub-field displays its own errors inline
FormFieldRegistry.registerCompound<MyField>(
  'myfield',
  (field) => field.buildSubFields(),
  (context, subFields, errors) => Column(children: subFields),
  rollUpErrors: false, // Default
);
```

**Rolled-up Errors:**
```dart
// All sub-field errors collected and displayed at compound field level
FormFieldRegistry.registerCompound<MyField>(
  'myfield',
  (field) => field.buildSubFields(),
  (context, subFields, errors) {
    return Column(
      children: [
        ...subFields,
        // Display rolled-up errors at bottom
        if (errors != null && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors.map((error) => Text(
                '• ${error.reason}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  },
  rollUpErrors: true, // Enable error collection
);
```

### Theme and State Propagation

Compound fields automatically propagate certain properties to sub-fields.

**Automatic Propagation:**
- `theme`: Applied to all sub-fields if they don't have their own theme
- `disabled`: When compound field is disabled, all sub-fields are disabled

**Example:**
```dart
form.AddressField(
  id: 'billing_address',
  theme: myCustomTheme,  // Applied to all sub-fields
  disabled: true,         // All sub-fields disabled
)
```

**Sub-field Override:**
```dart
// In buildSubFields(), you can override for specific sub-fields
@override
List<form.Field> buildSubFields() {
  return [
    form.TextField(
      id: 'field1',
      theme: specificFieldTheme, // This takes precedence
    ),
    form.TextField(id: 'field2'), // Uses compound field's theme
  ];
}
```

### Validation Strategies

Choose the right validation approach for your compound field.

**Strategy 1: Compound-level Validation**
Validate relationships between sub-fields at the compound level.

```dart
form.NameField(
  id: 'name',
  validators: [
    form.Validator(
      validator: (results) {
        final first = results.grab('name_firstname').asString();
        final last = results.grab('name_lastname').asString();
        // Validate that both are provided
        return first.isNotEmpty && last.isNotEmpty;
      },
      reason: 'Both first and last name are required',
    ),
  ],
)
```

**Strategy 2: Sub-field Validation**
Define validators on individual sub-fields for specific requirements.

```dart
@override
List<form.Field> buildSubFields() {
  return [
    form.TextField(
      id: 'zip',
      validators: [
        form.Validator(
          validator: (results) {
            final zip = results.asString();
            return zip.length == 5 && int.tryParse(zip) != null;
          },
          reason: 'ZIP code must be 5 digits',
        ),
      ],
    ),
  ];
}
```

**Strategy 3: Hybrid Approach**
Combine both for comprehensive validation.

```dart
// Sub-field validation in buildSubFields()
form.TextField(
  id: 'email',
  validators: [
    form.Validator(
      validator: (results) => form.Validators.isEmail(results),
      reason: 'Invalid email format',
    ),
  ],
)

// Compound-level validation
form.ContactField(
  id: 'contact',
  validators: [
    form.Validator(
      validator: (results) {
        final email = results.grab('contact_email').asString();
        final phone = results.grab('contact_phone').asString();
        // At least one contact method required
        return email.isNotEmpty || phone.isNotEmpty;
      },
      reason: 'Please provide email or phone number',
    ),
  ],
)
```

---

## Best Practices

### Naming Conventions

**Compound Field IDs:**
- Use descriptive names: `billing_address`, `customer_name`, `contact_phone`
- Use snake_case for consistency
- Avoid generic names like `field1`, `data`

**Sub-field IDs:**
- Use clear, specific names: `street`, `city`, `firstname`, `lastname`
- Don't include the compound ID (prefixing is automatic)
- Keep them short but meaningful

### Reusability

**DO:**
```dart
// Create reusable compound fields for common patterns
class AddressField extends CompoundField { ... }
class NameField extends CompoundField { ... }
class PhoneField extends CompoundField { ... }
```

**DON'T:**
```dart
// Don't create one-off compound fields for single use
// Just use regular fields instead
```

### Configuration

**Provide Sensible Defaults:**
```dart
class AddressField extends CompoundField {
  final bool includeStreet2;
  final bool includeCountry;

  AddressField({
    required String id,
    this.includeStreet2 = true,  // Good default for most cases
    this.includeCountry = false, // Hide by default, enable when needed
  });
}
```

### Layout Design

**Mobile-First:**
```dart
// Consider small screens in your layouts
FormFieldRegistry.registerCompound<MyField>(
  'myfield',
  (field) => field.buildSubFields(),
  (context, subFields, errors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useVertical = screenWidth < 600;

    return useVertical
      ? Column(children: subFields)
      : Row(children: subFields.map((f) => Expanded(child: f)).toList());
  },
);
```

### Error Handling

**Clear Error Messages:**
```dart
form.Validator(
  validator: (results) => /* validation logic */,
  reason: 'Street address, city, state, and ZIP are required', // Specific
  // NOT: 'Invalid input' // Too vague
)
```

---

## FAQ

### Q: Can I nest compound fields inside other compound fields?

**A:** Not in the current implementation. Compound fields can only contain regular fields (TextField, OptionSelect, etc.), not other compound fields. This is a deliberate design choice to keep the architecture simple and predictable.

### Q: How do I programmatically update sub-field values?

**A:** Use the standard controller methods with the prefixed sub-field ID:

```dart
// Update individual sub-field
controller.updateFieldValue('address_street', '456 Oak Ave');

// Update multiple sub-fields
controller.updateFieldValue('address_city', 'Boston');
controller.updateFieldValue('address_state', 'MA');
controller.updateFieldValue('address_zip', '02101');
```

### Q: Can I change the ID prefix pattern?

**A:** No, the pattern `{compoundId}_{subFieldId}` is built into the system for consistency. However, you can work with it by choosing clear compound and sub-field IDs.

### Q: What happens if I use the same sub-field ID in different compound fields?

**A:** The automatic ID prefixing prevents conflicts. Each sub-field gets its compound field ID as a prefix:

```dart
// These don't conflict:
form.NameField(id: 'customer')    // customer_firstname, customer_lastname
form.NameField(id: 'emergency')   // emergency_firstname, emergency_lastname
```

### Q: How do I validate that at least one sub-field is filled?

**A:** Use a compound-level validator:

```dart
form.MyCompoundField(
  id: 'contact',
  validators: [
    form.Validator(
      validator: (results) {
        final email = results.grab('contact_email').asString();
        final phone = results.grab('contact_phone').asString();
        return email.isNotEmpty || phone.isNotEmpty;
      },
      reason: 'Please provide either email or phone',
    ),
  ],
)
```

### Q: Can I access the compound field object itself from results?

**A:** No. Compound fields are architectural constructs that dissolve into their sub-fields at runtime. You access sub-fields individually or use `asCompound()` to get joined values.

### Q: Do compound fields work with pages/multi-step forms?

**A:** Yes! Sub-fields inherit the `pageName` property, so they work seamlessly with the page grouping feature:

```dart
form.AddressField(
  id: 'shipping',
  pageName: 'step2', // All sub-fields inherit this
)
```

### Q: How do I reset/clear a compound field?

**A:** Clear each sub-field individually, or iterate through them:

```dart
// Get sub-field IDs (pattern: {compoundId}_*)
final subFieldIds = controller.activeFields
  .where((field) => field.id.startsWith('address_'))
  .map((field) => field.id);

// Clear each sub-field
for (final id in subFieldIds) {
  controller.updateFieldValue(id, '');
}
```

### Q: Can I use compound fields with custom themes?

**A:** Yes! Apply a theme to the compound field, and it propagates to all sub-fields:

```dart
form.AddressField(
  id: 'billing',
  theme: myCustomTheme, // Applied to all sub-fields
)
```

---

## Next Steps

- **Try the Example**: Run the [compound fields demo](../../example/lib/pages/compound_fields_demo.dart) to see interactive examples
- **Create Your Own**: Start with a simple compound field like a phone number or date range
- **Explore Built-ins**: Study the [NameField](../../lib/default_fields/name_field.dart) and [AddressField](../../lib/default_fields/address_field.dart) source code
- **Share Your Work**: If you create useful compound fields, consider contributing them to the package!

---

**Related Documentation:**
- [Main README](../../README.md) - Getting started guide
- [Custom Fields](../custom-fields/custom-field-cookbook.md) - Creating custom field types
- [Form Controller](../api/form-controller.md) - Controller API reference (Coming Soon)

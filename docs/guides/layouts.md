# Layout Guide

Complete guide to structuring forms with Row and Column layouts in ChampionForms.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Row API](#row-api)
- [Column API](#column-api)
- [Layout Patterns](#layout-patterns)
- [Responsive Design](#responsive-design)
- [Error Rollup](#error-rollup)
- [Nesting Layouts](#nesting-layouts)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Accessibility](#accessibility)
- [Related Documentation](#related-documentation)

## Overview

ChampionForms provides `form.Row` and `form.Column` layout widgets to organize form fields in flexible, responsive layouts without fighting Flutter's native Row and Column widgets.

### What Row and Column Do

- **`form.Row`**: Arranges columns horizontally with customizable spacing and responsive collapsing
- **`form.Column`**: Arranges form fields vertically with proportional width control and error rollup

### When to Use Layouts

Use Row and Column when you need:
- Side-by-side fields (first name / last name)
- Multi-column forms (shipping / billing addresses)
- Responsive layouts that adapt to screen size
- Grouped error displays
- Professional, organized form appearance

### Benefits

- **Responsive**: Automatically adapts to screen sizes with the `collapse` property
- **Organized**: Visually group related fields together
- **Professional**: Create clean, multi-column forms
- **Flexible**: Nest layouts for complex grid structures
- **Error Management**: Roll up validation errors for compact displays

## Quick Start

### Basic Two-Column Layout

```dart
form.Row(
  children: [
    form.Column(
      children: [
        form.TextField(id: 'firstName', textFieldTitle: 'First Name'),
      ],
    ),
    form.Column(
      children: [
        form.TextField(id: 'lastName', textFieldTitle: 'Last Name'),
      ],
    ),
  ],
)
```

This creates a simple side-by-side layout with equal width columns.

## Row API

### Constructor

```dart
Row({
  List<Column> children = const [],
  bool collapse = false,
  bool rollUpErrors = false,
  bool hideField = false,
  double spacing = 10,
})
```

### Properties

#### children

- **Type**: `List<Column>`
- **Required**: Yes
- **Purpose**: Columns to arrange horizontally
- **Note**: Must contain `Column` widgets, not raw fields

```dart
form.Row(
  children: [
    form.Column(children: [...]),
    form.Column(children: [...]),
  ],
)
```

#### collapse

- **Type**: `bool`
- **Default**: `false`
- **Purpose**: Stack columns vertically on small screens
- **Use Case**: Responsive layouts that adapt to mobile devices

When `true`, columns will stack vertically when screen width is below the responsive breakpoint (typically ~600px).

```dart
form.Row(
  collapse: true, // Enable responsive stacking
  children: [...],
)
```

#### rollUpErrors

- **Type**: `bool`
- **Default**: `false`
- **Purpose**: Display all child field errors below the row
- **Use Case**: Compact error display for multi-field rows

When `true`, validation errors from all fields within the row's columns are displayed together below the row instead of inline with each field.

```dart
form.Row(
  rollUpErrors: true,
  children: [
    form.Column(children: [
      form.TextField(id: 'email', validators: [...]),
      form.TextField(id: 'phone', validators: [...]),
    ]),
  ],
)
```

#### hideField

- **Type**: `bool`
- **Default**: `false`
- **Purpose**: Hides the entire row from being displayed and processed
- **Use Case**: Conditional form sections

```dart
form.Row(
  hideField: !showAddressFields,
  children: [...],
)
```

#### spacing

- **Type**: `double`
- **Default**: `10`
- **Purpose**: Spacing between columns in the row
- **Unit**: Logical pixels

```dart
form.Row(
  spacing: 20, // More space between columns
  children: [...],
)
```

## Column API

### Constructor

```dart
Column({
  List<FormElement> children = const [],
  bool rollUpErrors = false,
  bool hideField = false,
  double? widthFactor,
  Widget Function(BuildContext, Widget, List<FormBuilderError>?)? columnWrapper,
  double spacing = 10,
})
```

### Properties

#### children

- **Type**: `List<FormElement>`
- **Required**: Yes
- **Purpose**: Fields to stack vertically
- **Can Contain**: `TextField`, `OptionSelect`, `FileUpload`, `Row` (nested layouts), `CheckboxSelect`, etc.

```dart
form.Column(
  children: [
    form.TextField(id: 'street'),
    form.TextField(id: 'city'),
    form.TextField(id: 'zip'),
  ],
)
```

#### widthFactor

- **Type**: `double?`
- **Default**: `null` (equal distribution)
- **Purpose**: Relative width in parent Row
- **Behavior**: Acts as a flex factor - higher numbers take more space

When set, defines the proportion of horizontal space this column takes within its parent `form.Row`.

```dart
form.Row(
  children: [
    form.Column(
      widthFactor: 2, // Takes 2/3 of width (2 out of 2+1=3)
      children: [...],
    ),
    form.Column(
      widthFactor: 1, // Takes 1/3 of width
      children: [...],
    ),
  ],
)
```

When `widthFactor` is `null`, the column shares remaining space equally with other columns that also have `null` widthFactor.

#### rollUpErrors

- **Type**: `bool`
- **Default**: `false`
- **Purpose**: Display child field errors below the column
- **Cascade**: Can combine with Row's `rollUpErrors`

```dart
form.Column(
  rollUpErrors: true,
  children: [
    form.TextField(id: 'field1', validators: [...]),
    form.TextField(id: 'field2', validators: [...]),
  ],
)
```

#### hideField

- **Type**: `bool`
- **Default**: `false`
- **Purpose**: Hides the entire column from being displayed and processed

```dart
form.Column(
  hideField: !showOptionalFields,
  children: [...],
)
```

#### columnWrapper

- **Type**: `Widget Function(BuildContext, Widget, List<FormBuilderError>?)?`
- **Default**: `null`
- **Purpose**: Wrap the column's contents in a custom widget
- **Use Case**: Add borders, backgrounds, or custom decorations

```dart
form.Column(
  columnWrapper: (context, child, errors) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  },
  children: [...],
)
```

#### spacing

- **Type**: `double`
- **Default**: `10`
- **Purpose**: Spacing between fields in the column

```dart
form.Column(
  spacing: 16,
  children: [...],
)
```

## Layout Patterns

### Pattern 1: Equal Width Columns

Default behavior when all columns have the same `widthFactor` (or all `null`):

```dart
form.Row(
  children: [
    form.Column(
      children: [form.TextField(id: 'firstName', textFieldTitle: 'First Name')],
    ),
    form.Column(
      children: [form.TextField(id: 'lastName', textFieldTitle: 'Last Name')],
    ),
  ],
)
```

**Result**: 50/50 split (each column takes half the width)

### Pattern 2: Proportional Width Columns

Use `widthFactor` to create unequal column widths:

```dart
form.Row(
  children: [
    form.Column(
      widthFactor: 2,  // Takes 2/3 of width (2 out of 2+1=3)
      children: [
        form.TextField(
          id: "Email",
          textFieldTitle: "Email Address",
        ),
      ],
    ),
    form.Column(
      widthFactor: 1,  // Takes 1/3 of width
      children: [
        form.TextField(
          id: "Password",
          textFieldTitle: "Password",
        ),
      ],
    ),
  ],
)
```

**Result**: 2:1 ratio (66.67% : 33.33%)

This is the pattern used in the example app (lines 169 and 222 of main.dart).

### Pattern 3: Three Columns

Create three equal-width columns:

```dart
form.Row(
  children: [
    form.Column(widthFactor: 1, children: [
      form.TextField(id: 'city', textFieldTitle: 'City'),
    ]),
    form.Column(widthFactor: 1, children: [
      form.TextField(id: 'state', textFieldTitle: 'State'),
    ]),
    form.Column(widthFactor: 1, children: [
      form.TextField(id: 'zip', textFieldTitle: 'ZIP'),
    ]),
  ],
)
```

**Result**: 33.33% each

### Pattern 4: Asymmetric Layout

Create custom width distributions:

```dart
form.Row(
  children: [
    form.Column(widthFactor: 3, children: [...]),  // 60% (3 out of 5)
    form.Column(widthFactor: 2, children: [...]),  // 40% (2 out of 5)
  ],
)
```

**Result**: 3:2 ratio (60% : 40%)

### Pattern 5: Mixed Width Factors

Combine explicit and implicit width allocation:

```dart
form.Row(
  children: [
    form.Column(widthFactor: 2, children: [...]),  // Fixed at 2 parts
    form.Column(children: [...]),                  // Shares remaining space
    form.Column(children: [...]),                  // Shares remaining space
  ],
)
```

**Result**: First column takes 2/4 (50%), remaining two split the rest equally (25% each)

## Responsive Design

### The collapse Property

The `collapse` property on `form.Row` enables responsive layouts that adapt to screen size:

```dart
form.Row(
  collapse: true,  // Enable responsive stacking
  children: [
    form.Column(children: [form.TextField(id: 'field1')]),
    form.Column(children: [form.TextField(id: 'field2')]),
  ],
)
```

### When collapse Triggers

- **Default breakpoint**: Typically triggers when screen width < 600px (mobile devices)
- **Behavior**: All columns stack vertically instead of horizontally
- **Width**: Each column takes full width when collapsed
- **Order**: Columns maintain their order (top to bottom)

### Desktop vs Mobile Behavior

#### Desktop (>= 600px width)

```
┌─────────────────────────────────────┐
│  Column 1         │  Column 2       │
│  [First Name]     │  [Last Name]    │
└─────────────────────────────────────┘
```

#### Mobile (< 600px width) with `collapse: true`

```
┌──────────────────┐
│  Column 1        │
│  [First Name]    │
├──────────────────┤
│  Column 2        │
│  [Last Name]     │
└──────────────────┘
```

### Without collapse

When `collapse: false` (default), columns remain horizontal even on small screens, which may cause:
- Cramped fields
- Horizontal scrolling
- Poor mobile user experience

### Recommended Usage

```dart
// For forms with 2+ columns - always enable collapse
form.Row(
  collapse: true,
  children: [...],
)

// For simple side-by-side elements that should stay horizontal
form.Row(
  collapse: false,
  children: [...],
)
```

### Best Practices

1. **Always use `collapse: true`** for multi-column forms intended for mobile use
2. **Test on mobile devices** to ensure layouts work well when collapsed
3. **Keep column count reasonable** (2-3 columns max) for better mobile experience
4. **Consider field order** when collapsed - fields stack in the order columns are defined

## Error Rollup

Error rollup consolidates validation errors from multiple fields into a single display area below the Row or Column.

### What is Error Rollup?

Instead of showing validation errors inline beneath each field, errors are "rolled up" and displayed together below the containing Row or Column.

### Row-Level Rollup

Display all field errors from within the row at the bottom of the row:

```dart
form.Row(
  rollUpErrors: true,
  children: [
    form.Column(children: [
      form.TextField(
        id: 'email',
        validators: [
          form.Validator(
            validator: (r) => form.Validators.isEmail(r),
            reason: "Invalid email address",
          ),
        ],
      ),
    ]),
    form.Column(children: [
      form.TextField(
        id: 'phone',
        validators: [
          form.Validator(
            validator: (r) => form.Validators.stringIsNotEmpty(r),
            reason: "Phone number required",
          ),
        ],
      ),
    ]),
  ],
)
```

**Result**: If email and phone both have errors, both error messages appear below the row, not beneath each field.

### Column-Level Rollup

Display errors from all fields in the column at the bottom of the column:

```dart
form.Column(
  rollUpErrors: true,
  children: [
    form.TextField(id: 'field1', validators: [...]),
    form.TextField(id: 'field2', validators: [...]),
    form.TextField(id: 'field3', validators: [...]),
  ],
)
```

**Result**: All three field errors (if any) appear below the column.

### Combined Rollup (Nested)

When both Row and Column have `rollUpErrors: true`, errors cascade upward:

```dart
form.Row(
  rollUpErrors: true,
  children: [
    form.Column(
      rollUpErrors: true,
      children: [
        form.TextField(id: 'a', validators: [...]),
        form.TextField(id: 'b', validators: [...]),
      ],
    ),
    form.Column(
      rollUpErrors: true,
      children: [
        form.TextField(id: 'c', validators: [...]),
      ],
    ),
  ],
)
```

**Behavior**: Errors from fields a, b, and c all roll up to the column level, then cascade up to the row level, appearing at the bottom of the row.

### When to Use Error Rollup

**Good Use Cases**:
- Compact layouts with multiple fields per row
- Forms where inline errors create visual clutter
- Multi-column layouts where grouped errors are clearer
- Desktop forms with adequate space for error lists

**Avoid When**:
- Long error messages that need field context
- Forms with many fields (hard to associate errors)
- Mobile layouts where scrolling is required to see errors
- Single-field layouts (pointless)

### Visual Comparison

#### Without Error Rollup (Default)

```
┌──────────────────────────┐
│ Email                    │
│ [________________]       │
│ ⚠ Invalid email address  │
└──────────────────────────┘
┌──────────────────────────┐
│ Phone                    │
│ [________________]       │
│ ⚠ Phone number required  │
└──────────────────────────┘
```

#### With Error Rollup

```
┌──────────────────────────┐
│ Email                    │
│ [________________]       │
└──────────────────────────┘
┌──────────────────────────┐
│ Phone                    │
│ [________________]       │
└──────────────────────────┘
⚠ Invalid email address
⚠ Phone number required
```

## Nesting Layouts

ChampionForms supports nesting Rows and Columns to create complex grid layouts.

### Row Inside Column

Stack fields vertically with an embedded horizontal row:

```dart
form.Column(
  children: [
    form.TextField(id: 'title', textFieldTitle: 'Title'),
    form.Row(
      children: [
        form.Column(children: [
          form.TextField(id: 'firstName', textFieldTitle: 'First Name'),
        ]),
        form.Column(children: [
          form.TextField(id: 'lastName', textFieldTitle: 'Last Name'),
        ]),
      ],
    ),
    form.TextField(id: 'email', textFieldTitle: 'Email'),
  ],
)
```

**Result**:
```
Title: [________________]

First Name: [_______]  Last Name: [_______]

Email: [________________]
```

### Column with Nested Row

Create sub-sections within columns:

```dart
form.Row(
  children: [
    form.Column(
      widthFactor: 2,
      children: [
        form.TextField(id: 'description'),
        form.Row(
          children: [
            form.Column(children: [form.TextField(id: 'startDate')]),
            form.Column(children: [form.TextField(id: 'endDate')]),
          ],
        ),
      ],
    ),
    form.Column(
      widthFactor: 1,
      children: [
        form.TextField(id: 'notes'),
      ],
    ),
  ],
)
```

**Result**: Left column (2/3 width) contains description and a nested row with date fields. Right column (1/3 width) contains notes.

### Complex Grid Layout

Build sophisticated layouts with multiple nesting levels:

```dart
form.Row(
  children: [
    form.Column(
      children: [
        form.Row(
          children: [
            form.Column(children: [form.TextField(id: 'a')]),
            form.Column(children: [form.TextField(id: 'b')]),
          ],
        ),
        form.TextField(id: 'c'),
      ],
    ),
    form.Column(children: [
      form.TextField(id: 'd'),
    ]),
  ],
)
```

**Result**: Creates a complex grid where left side has two fields side-by-side (a, b) above field c, and right side has field d.

### Maximum Nesting Depth

There is no hard limit on nesting depth, but best practices suggest:

- **Keep it to 2-3 levels max** for readability
- **Avoid deep nesting** unless truly necessary
- **Use simple vertical lists** when possible (just a list of fields, no Row/Column)
- **Consider compound fields** for complex reusable structures

**Good** (2 levels):
```dart
Row → Column → TextField
```

**Acceptable** (3 levels):
```dart
Row → Column → Row → Column → TextField
```

**Avoid** (4+ levels):
```dart
Row → Column → Row → Column → Row → Column → TextField
```

## Best Practices

### 1. Use widthFactor for Proportional Layouts

Always use `widthFactor` instead of wrapping columns in fixed-width containers:

```dart
// GOOD - Responsive and flexible
form.Row(
  children: [
    form.Column(widthFactor: 2, children: [...]),
    form.Column(widthFactor: 1, children: [...]),
  ],
)

// AVOID - Fixed widths break responsiveness
form.Row(
  children: [
    form.Column(children: [
      Container(width: 400, child: form.TextField(...)),
    ]),
    form.Column(children: [
      Container(width: 200, child: form.TextField(...)),
    ]),
  ],
)
```

### 2. Enable collapse for Multi-Column Forms

Always use `collapse: true` for forms with 2+ columns that will be viewed on mobile:

```dart
form.Row(
  collapse: true,  // Essential for mobile responsiveness
  children: [
    form.Column(children: [...]),
    form.Column(children: [...]),
  ],
)
```

### 3. Group Related Fields

Use Row and Column to visually group related information:

```dart
form.Row(
  children: [
    form.Column(children: [
      // Shipping address fields
      form.TextField(id: 'ship_street', textFieldTitle: 'Street'),
      form.TextField(id: 'ship_city', textFieldTitle: 'City'),
      form.TextField(id: 'ship_zip', textFieldTitle: 'ZIP'),
    ]),
    form.Column(children: [
      // Billing address fields
      form.TextField(id: 'bill_street', textFieldTitle: 'Street'),
      form.TextField(id: 'bill_city', textFieldTitle: 'City'),
      form.TextField(id: 'bill_zip', textFieldTitle: 'ZIP'),
    ]),
  ],
)
```

### 4. Use Error Rollup Sparingly

Only enable error rollup when it genuinely improves the layout:

```dart
// GOOD - Compact row benefits from consolidated errors
form.Row(
  rollUpErrors: true,
  children: [
    form.Column(children: [form.TextField(id: 'a')]),
    form.Column(children: [form.TextField(id: 'b')]),
    form.Column(children: [form.TextField(id: 'c')]),
  ],
)

// POINTLESS - Single field doesn't benefit from rollup
form.Column(
  rollUpErrors: true,
  children: [form.TextField(id: 'only_field')],
)
```

### 5. Maintain Consistent Column Counts

Keep visual rhythm by using consistent column counts across rows:

```dart
// GOOD - Consistent 2-column layout
form.Column(
  children: [
    form.Row(children: [
      form.Column(children: [form.TextField(id: 'a')]),
      form.Column(children: [form.TextField(id: 'b')]),
    ]),
    form.Row(children: [
      form.Column(children: [form.TextField(id: 'c')]),
      form.Column(children: [form.TextField(id: 'd')]),
    ]),
  ],
)

// CONFUSING - Varying column counts
form.Column(
  children: [
    form.Row(children: [
      form.Column(children: [form.TextField(id: 'a')]),
      form.Column(children: [form.TextField(id: 'b')]),
    ]),
    form.Row(children: [
      form.Column(children: [form.TextField(id: 'c')]),
      form.Column(children: [form.TextField(id: 'd')]),
      form.Column(children: [form.TextField(id: 'e')]),
    ]),
  ],
)
```

### 6. Design Mobile-First

Start with vertical layouts and enhance for desktop:

```dart
// Think: How does this look stacked vertically?
// Then: Is it better side-by-side on desktop?
form.Row(
  collapse: true,  // Mobile: vertical, Desktop: horizontal
  children: [
    form.Column(children: [...]),
    form.Column(children: [...]),
  ],
)
```

### 7. Avoid Deep Nesting

Keep layout structures simple and flat:

```dart
// GOOD - Clear 2-level structure
form.Row(
  children: [
    form.Column(children: [
      form.TextField(id: 'field1'),
      form.TextField(id: 'field2'),
    ]),
  ],
)

// AVOID - Unnecessarily deep nesting
form.Row(
  children: [
    form.Column(children: [
      form.Row(children: [
        form.Column(children: [
          form.Row(children: [
            form.Column(children: [
              form.TextField(id: 'field1'),
            ]),
          ]),
        ]),
      ]),
    ]),
  ],
)
```

### 8. Use Appropriate Spacing

Adjust spacing to match your design:

```dart
form.Row(
  spacing: 20,  // More breathing room
  children: [
    form.Column(
      spacing: 12,  // Tighter vertical spacing
      children: [...],
    ),
  ],
)
```

### 9. Label Row Sections Clearly

Add descriptions to help users understand grouped fields:

```dart
form.Row(
  children: [
    form.Column(children: [
      form.TextField(
        id: 'ship_street',
        textFieldTitle: 'Shipping Street',
        description: 'Shipping Address',  // Section label
      ),
      // ... more shipping fields
    ]),
    form.Column(children: [
      form.TextField(
        id: 'bill_street',
        textFieldTitle: 'Billing Street',
        description: 'Billing Address',  // Section label
      ),
      // ... more billing fields
    ]),
  ],
)
```

### 10. Test Responsive Behavior

Always test your layouts at different screen sizes:

```dart
// Use Flutter DevTools to test at:
// - Mobile (375px width)
// - Tablet (768px width)
// - Desktop (1200px+ width)
```

## Complete Examples

### Example 1: Login Form

A simple two-column login form from the ChampionForms example app:

```dart
final List<form.FormElement> fields = [
  form.Row(
    children: [
      form.Column(
        widthFactor: 2,  // Email takes more space
        children: [
          form.TextField(
            id: "Email",
            textFieldTitle: "Email Address",
            hintText: "Enter your email",
            description: "Your login email.",
            maxLines: 1,
            validateLive: true,
            autoComplete: form.AutoCompleteBuilder(
              initialOptions: [
                form.CompleteOption(value: "test1@example.com"),
                form.CompleteOption(value: "test2@example.com"),
              ],
              updateOptions: (searchValue) async {
                // Filter logic here
                return [...];
              },
            ),
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: "Email cannot be empty.",
              ),
              form.Validator(
                validator: (r) => form.Validators.isEmail(r),
                reason: "Please enter a valid email address.",
              ),
            ],
            leading: const Icon(Icons.email),
          ),
        ],
      ),
      form.Column(
        children: [
          form.TextField(
            id: "Password",
            textFieldTitle: "Password",
            description: "Enter your password",
            maxLines: 1,
            password: true,
            validateLive: true,
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: "Password cannot be empty.",
              ),
            ],
            leading: const Icon(Icons.lock),
          ),
        ],
      ),
    ],
  ),
];
```

### Example 2: Address Form

A comprehensive address form with multiple rows:

```dart
final addressFields = [
  // Street address (full width)
  form.TextField(
    id: 'street',
    textFieldTitle: 'Street Address',
    validators: [
      form.Validator(
        validator: (r) => form.Validators.stringIsNotEmpty(r),
        reason: 'Street address required',
      ),
    ],
  ),

  // Optional apartment/suite (full width)
  form.TextField(
    id: 'street2',
    textFieldTitle: 'Apt, Suite, etc. (optional)',
  ),

  // City, State, ZIP (three columns)
  form.Row(
    collapse: true,
    children: [
      form.Column(
        widthFactor: 2,  // City takes more space
        children: [
          form.TextField(
            id: 'city',
            textFieldTitle: 'City',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'City required',
              ),
            ],
          ),
        ],
      ),
      form.Column(
        widthFactor: 1,
        children: [
          form.TextField(
            id: 'state',
            textFieldTitle: 'State',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'State required',
              ),
            ],
          ),
        ],
      ),
      form.Column(
        widthFactor: 1,
        children: [
          form.TextField(
            id: 'zip',
            textFieldTitle: 'ZIP',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'ZIP required',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
```

### Example 3: Payment Form

A payment form with card details:

```dart
final paymentFields = [
  // Card number (full width)
  form.TextField(
    id: 'card_number',
    textFieldTitle: 'Card Number',
    hintText: '1234 5678 9012 3456',
    validators: [
      form.Validator(
        validator: (r) => form.Validators.stringIsNotEmpty(r),
        reason: 'Card number required',
      ),
    ],
  ),

  // Expiry and CVV (two columns)
  form.Row(
    collapse: true,
    children: [
      form.Column(
        widthFactor: 2,
        children: [
          form.TextField(
            id: 'expiry',
            textFieldTitle: 'Expiry Date',
            hintText: 'MM/YY',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'Expiry date required',
              ),
            ],
          ),
        ],
      ),
      form.Column(
        widthFactor: 1,
        children: [
          form.TextField(
            id: 'cvv',
            textFieldTitle: 'CVV',
            hintText: '123',
            password: true,
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'CVV required',
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // Cardholder name (full width)
  form.TextField(
    id: 'cardholder_name',
    textFieldTitle: 'Cardholder Name',
    validators: [
      form.Validator(
        validator: (r) => form.Validators.stringIsNotEmpty(r),
        reason: 'Cardholder name required',
      ),
    ],
  ),
];
```

### Example 4: User Profile

A profile form with avatar upload and personal details:

```dart
final profileFields = [
  // Avatar and name fields side-by-side
  form.Row(
    collapse: true,
    children: [
      form.Column(
        widthFactor: 1,
        children: [
          form.FileUpload(
            id: 'avatar',
            title: 'Profile Picture',
            allowedExtensions: ['jpg', 'jpeg', 'png'],
            validators: [
              form.Validator(
                validator: (r) => form.Validators.fileIsImage(r),
                reason: 'Must be an image',
              ),
            ],
          ),
        ],
      ),
      form.Column(
        widthFactor: 2,
        children: [
          form.TextField(
            id: 'display_name',
            textFieldTitle: 'Display Name',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'Display name required',
              ),
            ],
          ),
          form.TextField(
            id: 'username',
            textFieldTitle: 'Username',
            hintText: '@username',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.stringIsNotEmpty(r),
                reason: 'Username required',
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // Bio (full width)
  form.TextField(
    id: 'bio',
    textFieldTitle: 'Bio',
    hintText: 'Tell us about yourself...',
    maxLines: 5,
  ),
];
```

### Example 5: Shipping and Billing

Dual-column layout for comparing two address sets:

```dart
final addressFields = [
  form.Row(
    collapse: true,
    spacing: 24,
    children: [
      // Shipping Address Column
      form.Column(
        rollUpErrors: true,
        children: [
          form.TextField(
            id: 'ship_street',
            textFieldTitle: 'Street',
            description: 'Shipping Address',
          ),
          form.TextField(id: 'ship_city', textFieldTitle: 'City'),
          form.Row(
            children: [
              form.Column(children: [
                form.TextField(id: 'ship_state', textFieldTitle: 'State'),
              ]),
              form.Column(children: [
                form.TextField(id: 'ship_zip', textFieldTitle: 'ZIP'),
              ]),
            ],
          ),
        ],
      ),

      // Billing Address Column
      form.Column(
        rollUpErrors: true,
        children: [
          form.TextField(
            id: 'bill_street',
            textFieldTitle: 'Street',
            description: 'Billing Address',
          ),
          form.TextField(id: 'bill_city', textFieldTitle: 'City'),
          form.Row(
            children: [
              form.Column(children: [
                form.TextField(id: 'bill_state', textFieldTitle: 'State'),
              ]),
              form.Column(children: [
                form.TextField(id: 'bill_zip', textFieldTitle: 'ZIP'),
              ]),
            ],
          ),
        ],
      ),
    ],
  ),
];
```

### Example 6: Multi-Step Registration

A responsive registration form with grouped sections:

```dart
final registrationFields = [
  // Personal Information Section
  form.Row(
    collapse: true,
    children: [
      form.Column(children: [
        form.TextField(id: 'first_name', textFieldTitle: 'First Name'),
      ]),
      form.Column(children: [
        form.TextField(id: 'last_name', textFieldTitle: 'Last Name'),
      ]),
    ],
  ),

  // Contact Information Section
  form.Row(
    collapse: true,
    children: [
      form.Column(children: [
        form.TextField(id: 'email', textFieldTitle: 'Email'),
      ]),
      form.Column(children: [
        form.TextField(id: 'phone', textFieldTitle: 'Phone'),
      ]),
    ],
  ),

  // Security Section
  form.Row(
    collapse: true,
    rollUpErrors: true,
    children: [
      form.Column(children: [
        form.TextField(
          id: 'password',
          textFieldTitle: 'Password',
          password: true,
        ),
      ]),
      form.Column(children: [
        form.TextField(
          id: 'confirm_password',
          textFieldTitle: 'Confirm Password',
          password: true,
        ),
      ]),
    ],
  ),
];
```

## Responsive Behavior

### Desktop Display (>= 600px)

On desktop and tablet devices:
- Rows display columns horizontally
- Width distributed according to `widthFactor`
- Full horizontal space utilized
- Optimal for side-by-side comparison

```
┌───────────────────────────────────────────┐
│                                           │
│  Email [_____________]  Password [______] │
│                                           │
└───────────────────────────────────────────┘
```

### Mobile Display (< 600px)

On mobile devices with `collapse: true`:
- Rows stack columns vertically
- Each column takes full width
- Order preserved (top to bottom)
- Scrollable for long forms

```
┌──────────────┐
│              │
│ Email        │
│ [__________] │
│              │
├──────────────┤
│              │
│ Password     │
│ [__________] │
│              │
└──────────────┘
```

### Testing Responsive Layouts

Use Flutter DevTools or device emulators to test:

```bash
# Run on different device sizes
flutter run -d chrome --web-browser-flag "--window-size=375,812"  # iPhone
flutter run -d chrome --web-browser-flag "--window-size=768,1024" # iPad
flutter run -d chrome --web-browser-flag "--window-size=1920,1080" # Desktop
```

Or programmatically test in widget tests:

```dart
testWidgets('Row collapses on mobile', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(size: Size(400, 800)), // Mobile size
          child: form.Form(
            controller: controller,
            fields: [
              form.Row(
                collapse: true,
                children: [
                  form.Column(children: [form.TextField(id: 'a')]),
                  form.Column(children: [form.TextField(id: 'b')]),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Verify vertical stacking...
});
```

## Accessibility

### Screen Reader Considerations

ChampionForms layouts are accessible by default:

- **Semantic order**: Fields are announced in DOM order
- **Label association**: Field labels remain properly associated
- **Error announcements**: Validation errors are announced to screen readers
- **Logical grouping**: Row/Column structures maintain logical field relationships

### Keyboard Navigation

Navigation works naturally with Row/Column layouts:

- **Tab order**: Follows visual layout (left-to-right, top-to-bottom)
- **Focus management**: Controller handles focus states
- **Skip navigation**: No special handling needed

### Best Practices for Accessibility

1. **Logical field order**: Ensure tab order makes sense when collapsed

```dart
// Good: Tab order is firstName → lastName → email
form.Row(
  collapse: true,
  children: [
    form.Column(children: [
      form.TextField(id: 'firstName'),
    ]),
    form.Column(children: [
      form.TextField(id: 'lastName'),
    ]),
  ],
),
form.TextField(id: 'email'),
```

2. **Clear labels**: Always provide meaningful field titles

```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email Address',  // Clear, descriptive label
)
```

3. **Error clarity**: Use descriptive error messages with `rollUpErrors`

```dart
form.Row(
  rollUpErrors: true,
  children: [
    form.Column(children: [
      form.TextField(
        id: 'email',
        validators: [
          form.Validator(
            validator: (r) => form.Validators.isEmail(r),
            reason: 'Email address is invalid',  // Specific error
          ),
        ],
      ),
    ]),
  ],
)
```

4. **Semantic descriptions**: Add context with the `description` property

```dart
form.TextField(
  id: 'ssn',
  textFieldTitle: 'Social Security Number',
  description: 'Required for tax purposes',  // Provides context
)
```

## Related Documentation

- **[Basic Patterns](basic-patterns.md)** - Common form patterns using layouts
- **[Compound Fields](compound-fields.md)** - Alternative grouping with NameField and AddressField
- **[Quick Start Guide](quick-start.md)** - Get started with ChampionForms
- **[Pages Guide](pages.md)** - Multi-step forms with page management
- **[API Reference: Row](/Users/fabier/Documents/code/championforms/lib/models/field_types/row.dart)** - Row implementation
- **[API Reference: Column](/Users/fabier/Documents/code/championforms/lib/models/field_types/column.dart)** - Column implementation

---

For questions or issues, visit the [ChampionForms GitHub repository](https://github.com/yourusername/championforms).

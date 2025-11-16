# Theming Guide

Complete guide to customizing ChampionForms appearance through the powerful theming system.

## Table of Contents

- [Overview](#overview)
- [Import Pattern](#import-pattern)
- [Theme Hierarchy](#theme-hierarchy)
- [FormTheme Structure](#formtheme-structure)
- [FieldColorScheme](#fieldcolorscheme)
- [Applying Themes](#applying-themes)
- [State-Based Theming](#state-based-theming)
- [Pre-Built Themes](#pre-built-themes)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

## Overview

The ChampionForms theming system provides comprehensive control over the appearance of all form elements. Themes control:

- **Colors** - Background, border, text, icon, and hint colors for all field states
- **Text Styles** - Typography for titles, descriptions, hints, and chip labels
- **Decorations** - Border radius, border size, and input decorations
- **Gradients** - Optional gradient overlays for backgrounds and borders
- **State Appearance** - Different visual styles for normal, active, error, disabled, and selected states

The theming system uses a cascade pattern where more specific themes override general ones, allowing you to set app-wide defaults while customizing individual forms or fields as needed.

## Import Pattern

ChampionForms uses a two-tier export system. Theme classes are imported separately from lifecycle classes and **do not** use the `form.` namespace prefix:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart'; // No prefix!
```

This separation keeps theme configuration distinct from form lifecycle management. When using theme classes like `FormTheme`, `FieldColorScheme`, or pre-built themes, do **NOT** prefix them with `form.`:

```dart
// CORRECT
final theme = FormTheme(
  colorScheme: FieldColorScheme(...),
);

// INCORRECT
final theme = form.FormTheme(  // Don't do this!
  colorScheme: form.FieldColorScheme(...),
);
```

## Theme Hierarchy

### Cascade Order

Themes cascade from general to specific in this order:

```
Default Theme → Global Theme → Form Theme → Field Theme
```

Each level can override properties from the previous level. If a property is `null` at a more specific level, it inherits from the parent level.

### How It Works

1. **Default Theme** - Automatically generated from Flutter's `Theme.of(context)` using Material Design colors and text styles
2. **Global Theme** - Optional app-wide theme set via `FormThemeSingleton.instance.setTheme()`
3. **Form Theme** - Optional per-form override passed to the `form.Form` widget's `theme` property
4. **Field Theme** - Optional per-field override passed to individual field's `theme` property

More specific themes only need to define properties they want to override. All other properties cascade from parent themes.

### Visual Diagram

```
┌─────────────────────────────────────────┐
│ Default Theme                           │
│ (from Theme.of(context))                │
│ - Provides base colors/styles           │
└──────────────────┬──────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Global Theme (Optional)                 │
│ FormThemeSingleton.instance.setTheme()  │
│ - App-wide overrides                    │
└──────────────────┬──────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Form Theme (Optional)                   │
│ form.Form(theme: ...)                   │
│ - Per-form overrides                    │
└──────────────────┬──────────────────────┘
                   ↓
┌─────────────────────────────────────────┐
│ Field Theme (Optional)                  │
│ form.TextField(theme: ...)              │
│ - Per-field overrides                   │
└──────────────────┬──────────────────────┘
                   ↓
           ┌───────────────┐
           │ Rendered Field│
           └───────────────┘
```

### Cascade Example

```dart
// Default theme provides: Blue borders, black text
// Global theme overrides: Red borders
// Form theme overrides: Green backgrounds
// Field theme overrides: Bold title

// Result for this field:
// - Title: Bold (from field theme)
// - Background: Green (from form theme)
// - Border: Red (from global theme)
// - Text: Black (from default theme)
```

## FormTheme Structure

### Properties Overview

```dart
FormTheme({
  // Custom builders (advanced)
  this.layoutBuilder,
  this.fieldBuilder,
  this.nonTextFieldBuilder,

  // Color schemes by state
  this.colorScheme,           // Normal state
  this.activeColorScheme,     // Focused state
  this.errorColorScheme,      // Validation error state
  this.disabledColorScheme,   // Disabled state
  this.selectedColorScheme,   // Selected options (multiselect)

  // Text styles
  this.titleStyle,            // Field titles/labels
  this.descriptionStyle,      // Help text below fields
  this.hintTextStyle,         // Placeholder text
  this.chipTextStyle,         // Chip labels (ChipSelect)

  // Input decoration
  this.inputDecoration,       // TextField InputDecoration
})
```

### Color Schemes by State

Each state uses a specific `FieldColorScheme` that defines the complete visual appearance for that state:

- **colorScheme** - Default field state (normal, unfocused, no errors)
- **activeColorScheme** - When field has focus (user is typing or interacting)
- **errorColorScheme** - When field has validation errors
- **disabledColorScheme** - When field is disabled (non-interactive)
- **selectedColorScheme** - For selected options in multiselect fields (CheckboxSelect, ChipSelect, OptionSelect)

Fields automatically switch between these color schemes based on their current state.

### Text Styles

- **titleStyle** - Field labels/titles shown above the input
- **descriptionStyle** - Descriptive help text shown below the title
- **hintTextStyle** - Placeholder text shown when field is empty
- **chipTextStyle** - Text labels inside chips (ChipSelect fields)

### InputDecoration

For `TextField` and `TextArea` fields, you can provide a custom `InputDecoration` that controls the Flutter `TextField` appearance directly. This is useful for Material Design-specific customization.

### Custom Builders (Advanced)

- **layoutBuilder** - Custom function to build the complete field layout (title, description, errors, field)
- **fieldBuilder** - Custom widget builder for text input fields
- **nonTextFieldBuilder** - Custom widget builder for non-text fields (dropdowns, checkboxes, etc.)

Most users won't need these - they're for advanced customization scenarios.

## FieldColorScheme

### Structure

The `FieldColorScheme` class defines all colors used to render a field in a specific state:

```dart
FieldColorScheme({
  // Main field colors
  this.backgroundColor = Colors.white,
  this.borderColor = Colors.grey,
  this.textColor = Colors.black,
  this.iconColor = Colors.white,

  // Text colors
  this.hintTextColor = Colors.black,
  this.titleColor = Colors.black,
  this.descriptionColor = Colors.black,

  // Border styling
  this.borderSize = 1,
  this.borderRadius = const BorderRadius.all(Radius.circular(8)),

  // Advanced options
  this.textBackgroundColor,      // Chip background, selected options
  this.backgroundGradient,       // Optional gradient overlay
  this.borderGradient,          // Optional border gradient
  this.textBackgroundGradient,  // Optional chip gradient

  // Surface colors (for overlays like autocomplete)
  this.surfaceBackground = Colors.white,
  this.surfaceText = Colors.black,
})
```

### Properties Explained

#### Core Colors

- **backgroundColor** - Background color of the input field container
- **borderColor** - Color of the field border
- **textColor** - Color of the input text the user types
- **iconColor** - Tint color for icons (e.g., dropdown arrows, file upload icons)

#### Text Colors

- **hintTextColor** - Color of placeholder/hint text when field is empty
- **titleColor** - Color of the field label/title
- **descriptionColor** - Color of the help text description

#### Border Styling

- **borderSize** - Thickness of the border in pixels (default: 1)
- **borderRadius** - Rounded corners configuration (default: 8px radius on all corners)

#### Advanced Colors

- **textBackgroundColor** - Background color for chips in ChipSelect, selected options in dropdowns, and focused autocomplete options
- **surfaceBackground** - Background color for overlay surfaces like autocomplete dropdowns
- **surfaceText** - Text color for overlay surfaces like autocomplete dropdowns

#### Gradients (Optional)

- **backgroundGradient** - `FieldGradientColors` for background gradient overlay
- **borderGradient** - `FieldGradientColors` for border gradient
- **textBackgroundGradient** - `FieldGradientColors` for chip/selection background gradient

Gradient example:
```dart
backgroundGradient: FieldGradientColors(
  colorOne: Colors.blue,
  colorTwo: Colors.purple,
)
```

### Example: Custom Color Scheme

```dart
final customColorScheme = FieldColorScheme(
  backgroundColor: Colors.grey[50]!,
  borderColor: Colors.blue,
  borderSize: 2,
  borderRadius: BorderRadius.circular(12),
  textColor: Colors.black87,
  iconColor: Colors.blue,
  hintTextColor: Colors.grey[400]!,
  titleColor: Colors.blue[900]!,
  descriptionColor: Colors.grey[600]!,
  textBackgroundColor: Colors.blue[100],
);
```

## Applying Themes

### Global Theme (Recommended)

The recommended approach is to set a global theme once at app startup. This ensures a consistent look across all forms in your app.

**Where to set it**: In your root widget's `build` method, before returning `MaterialApp`:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set global theme
    final globalTheme = softBlueColorTheme(context);
    FormThemeSingleton.instance.setTheme(globalTheme);

    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}
```

**Why use global themes?**

- Consistent look and feel across all forms
- Single source of truth for form styling
- Easy to update the entire app's form appearance
- No need to pass theme to every form widget

### Form-Level Theme

Override the global theme for a specific form by passing a theme to the `form.Form` widget:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

form.Form(
  controller: controller,
  theme: redAccentFormTheme(context), // Override global theme
  fields: [
    form.TextField(
      id: 'email',
      title: 'Email Address',
    ),
    // ... more fields
  ],
)
```

**When to use form-level themes:**

- Different visual style for a specific form (e.g., login vs. settings)
- Temporary theme override for a particular screen
- A/B testing different form appearances
- Special forms that need distinct branding

### Field-Level Theme

Override the form theme for a specific field:

```dart
final highlightTheme = FormTheme(
  colorScheme: FieldColorScheme(
    backgroundColor: Colors.yellow[50]!,
    borderColor: Colors.orange,
    borderSize: 3,
    textColor: Colors.black,
  ),
);

form.TextField(
  id: 'important',
  title: 'Important Field',
  theme: highlightTheme, // Override for this field only
)
```

**When to use field-level themes:**

- Highlight a specific important field
- Custom error state appearance
- Special UX requirements for one field
- Call attention to required fields

### Resetting Global Theme

If you need to reset the global theme back to defaults:

```dart
FormThemeSingleton.instance.reset();
```

## State-Based Theming

### Automatic State Selection

ChampionForms automatically selects the appropriate color scheme based on the field's current state:

| Field State | Color Scheme Used | When It Applies |
|------------|------------------|----------------|
| Normal | `colorScheme` | Default state - field is not focused, has no errors, is enabled |
| Active | `activeColorScheme` | User is interacting with the field (focused) |
| Error | `errorColorScheme` | Field has validation errors |
| Disabled | `disabledColorScheme` | Field is disabled (non-interactive) |
| Selected | `selectedColorScheme` | For selected options in multiselect fields |

You don't need to manually manage state transitions - the framework handles this automatically.

### State Priority

When multiple states could apply, this priority order determines which color scheme is used:

1. **Error** (highest priority) - Validation errors always show
2. **Disabled** - Disabled state overrides normal/active
3. **Active** - Focus state when field is being edited
4. **Normal** (default) - Fallback for all other cases

### Custom State Colors

You can customize the appearance for specific states while leaving others at default:

```dart
final customErrorTheme = FormTheme(
  // Only customize error state
  errorColorScheme: FieldColorScheme(
    backgroundColor: Colors.red[50]!,
    borderColor: Colors.red[700]!,
    borderSize: 3,
    textColor: Colors.red[900]!,
    iconColor: Colors.red[700]!,
    hintTextColor: Colors.red[300]!,
    titleColor: Colors.red[900]!,
    descriptionColor: Colors.red[700]!,
  ),
  // All other states inherit from parent theme
);
```

### State Transitions

Field state transitions happen automatically:

```dart
// User taps field → switches from colorScheme to activeColorScheme
// User submits with error → switches to errorColorScheme
// User fixes error and taps field → switches to activeColorScheme
// User unfocuses field → switches back to colorScheme
```

## Pre-Built Themes

ChampionForms includes three professionally designed pre-built themes ready to use.

### Available Themes

#### 1. Soft Blue Theme

A professional, calming blue color palette:

```dart
import 'package:championforms/championforms_themes.dart';

final theme = softBlueColorTheme(context);
```

**Color Palette:**
- Primary: Deep Blue (`#3D52A0`)
- Secondary: Light Blue (`#7091E6`)
- Tertiary: Muted Blue (`#8697C4`)
- Background: Soft Light (`#ADBDDA`)
- Accent: Gold Hint (`#7091E6`)

**Best for:** Professional apps, business forms, corporate branding

#### 2. Red Accent Theme

A bold theme with red accents, includes dark mode support:

```dart
import 'package:championforms/championforms_themes.dart';

final theme = redAccentFormTheme(context);
```

**Features:**
- Automatically adapts to light/dark mode
- Bold red borders and accents
- High contrast for visibility
- Uses platform `Theme.of(context)` colors

**Best for:** Alert forms, important actions, high-priority inputs

#### 3. Iconic Theme

A vibrant, energetic color palette:

```dart
import 'package:championforms/championforms_themes.dart';

final theme = iconicColorTheme(context);
```

**Color Palette:**
- Primary: Vibrant Red-Orange (`#E43D12`)
- Secondary: Rich Pink (`#D6536D`)
- Tertiary: Light Pink (`#FFA2B6`)
- Background: Soft Off-White (`#EBE9E1`)
- Accent: Bright Gold (`#EFB11D`)

**Best for:** Creative apps, vibrant branding, youthful audience

### Using Pre-Built Themes

Simply import and apply:

```dart
import 'package:championforms/championforms_themes.dart';

// As global theme
FormThemeSingleton.instance.setTheme(softBlueColorTheme(context));

// As form theme
form.Form(
  theme: iconicColorTheme(context),
  controller: controller,
  fields: fields,
)
```

### Customizing Pre-Built Themes

Use `copyWith` to customize a pre-built theme:

```dart
final customTheme = softBlueColorTheme(context).copyWith(
  titleStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  ),
  colorScheme: FieldColorScheme(
    backgroundColor: Colors.white,
    borderColor: Color(0xFF3D52A0),
    borderSize: 2,
    borderRadius: BorderRadius.circular(16),
    textColor: Colors.black,
    titleColor: Color(0xFF3D52A0),
    hintTextColor: Colors.grey[400]!,
    descriptionColor: Colors.grey[600]!,
    iconColor: Color(0xFF3D52A0),
  ),
);

FormThemeSingleton.instance.setTheme(customTheme);
```

## Best Practices

### 1. Set Global Theme Early

Set your global theme in the root widget before MaterialApp to ensure it's available throughout the app:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Do this FIRST
    FormThemeSingleton.instance.setTheme(softBlueColorTheme(context));

    return MaterialApp(...);
  }
}
```

### 2. Use Pre-Built Themes as Starting Point

Don't build themes from scratch unless necessary. Start with a pre-built theme and customize:

```dart
// Good
final theme = softBlueColorTheme(context).copyWith(
  titleStyle: myCustomTitleStyle,
);

// Less efficient - building from scratch
final theme = FormTheme(
  colorScheme: FieldColorScheme(...),
  errorColorScheme: FieldColorScheme(...),
  // ... defining everything
);
```

### 3. Respect Platform Conventions

Use Flutter's `Theme.of(context)` colors to maintain platform consistency:

```dart
final platformAware = FormTheme(
  colorScheme: FieldColorScheme(
    backgroundColor: Theme.of(context).colorScheme.surface,
    borderColor: Theme.of(context).colorScheme.outline,
    textColor: Theme.of(context).colorScheme.onSurface,
    titleColor: Theme.of(context).colorScheme.primary,
  ),
);
```

### 4. Consistent State Colors

Follow these conventions for better UX:

- **Error state** → Red/warm colors
- **Active state** → Accent/primary colors with thicker borders
- **Normal state** → Neutral colors
- **Disabled state** → Muted/grayed out colors

```dart
FormTheme(
  errorColorScheme: FieldColorScheme(
    borderColor: Colors.red,      // Red for errors
  ),
  activeColorScheme: FieldColorScheme(
    borderColor: Colors.blue,     // Accent for active
    borderSize: 2,                // Thicker when active
  ),
  disabledColorScheme: FieldColorScheme(
    backgroundColor: Colors.grey[300],  // Grayed when disabled
    textColor: Colors.grey[600],
  ),
)
```

### 5. Accessibility

Ensure your themes meet accessibility standards:

**Color Contrast:**
```dart
// Good - high contrast
FieldColorScheme(
  backgroundColor: Colors.white,
  textColor: Colors.black87,
)

// Bad - low contrast
FieldColorScheme(
  backgroundColor: Colors.grey[200],
  textColor: Colors.grey[400],  // Too similar!
)
```

**Don't Rely on Color Alone:**
- Use border changes, not just color changes
- Include icon state changes
- Provide text error messages, not just red borders

**Screen Reader Support:**
```dart
// Error state should have clear visual AND semantic differences
errorColorScheme: FieldColorScheme(
  backgroundColor: Colors.red[50]!,
  borderColor: Colors.red,
  borderSize: 3,  // Thicker border helps visually impaired
  iconColor: Colors.red,  // Icon changes too
)
```

### 6. Theme Testing

Always test all state appearances:

```dart
// Test checklist:
// - Normal state (unfocused, no errors)
// - Active state (focused, typing)
// - Error state (validation failed)
// - Disabled state (non-interactive)
// - Selected state (for multiselect options)
```

Create a test form with fields in each state:

```dart
form.Form(
  controller: controller,
  fields: [
    form.TextField(id: 'normal', title: 'Normal State'),
    form.TextField(id: 'error', title: 'Error State'), // Add error manually
    form.TextField(id: 'disabled', title: 'Disabled State', disabled: true),
  ],
)
```

### 7. Dark Mode Support

Support dark mode by checking platform brightness:

```dart
FormTheme createTheme(BuildContext context) {
  final brightness = MediaQuery.of(context).platformBrightness;
  final isDark = brightness == Brightness.dark;

  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: isDark ? Colors.grey[900]! : Colors.white,
      borderColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      textColor: isDark ? Colors.white : Colors.black,
      titleColor: isDark ? Colors.blue[300]! : Colors.blue[900]!,
    ),
  );
}

// Use in app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FormThemeSingleton.instance.setTheme(createTheme(context));
    return MaterialApp(...);
  }
}
```

### 8. Performance Considerations

- **Reuse theme objects** - Don't create new themes on every build
- **Cache complex themes** - Store in static final if they don't depend on context
- **Use const where possible** - For static color schemes

```dart
// Good - reuse
static final myTheme = FormTheme(...);

// Good - const when possible
static const myColorScheme = FieldColorScheme(
  backgroundColor: Colors.white,
  borderColor: Colors.blue,
  // ...
);

// Avoid - creates new object every build
Widget build(BuildContext context) {
  return form.Form(
    theme: FormTheme(...),  // New object every rebuild!
  );
}
```

## Examples

### Example 1: Simple Global Theme

Basic setup with a pre-built theme applied globally:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set global theme once
    FormThemeSingleton.instance.setTheme(softBlueColorTheme(context));

    return MaterialApp(
      title: 'ChampionForms Demo',
      home: MyFormScreen(),
    );
  }
}

class MyFormScreen extends StatefulWidget {
  @override
  State<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  late final form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Theme Example')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: form.Form(
          controller: controller,
          // No theme specified - uses global theme
          fields: [
            form.TextField(
              id: 'name',
              title: 'Full Name',
              description: 'Enter your full legal name',
            ),
            form.TextField(
              id: 'email',
              title: 'Email Address',
              validators: [form.Validators.isEmail()],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Per-Form Theme Override

Two forms with different themes on the same screen:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

class MultiThemeScreen extends StatefulWidget {
  @override
  State<MultiThemeScreen> createState() => _MultiThemeScreenState();
}

class _MultiThemeScreenState extends State<MultiThemeScreen> {
  late final form.FormController loginController;
  late final form.FormController signupController;

  @override
  void initState() {
    super.initState();
    loginController = form.FormController();
    signupController = form.FormController();
  }

  @override
  void dispose() {
    loginController.dispose();
    signupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Multi-Theme Example')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Login form with blue theme
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    form.Form(
                      controller: loginController,
                      theme: softBlueColorTheme(context),
                      fields: [
                        form.TextField(
                          id: 'login_email',
                          title: 'Email',
                        ),
                        form.TextField(
                          id: 'login_password',
                          title: 'Password',
                          obscureText: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Signup form with red theme
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign Up',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    form.Form(
                      controller: signupController,
                      theme: redAccentFormTheme(context),
                      fields: [
                        form.TextField(
                          id: 'signup_name',
                          title: 'Full Name',
                        ),
                        form.TextField(
                          id: 'signup_email',
                          title: 'Email',
                        ),
                        form.TextField(
                          id: 'signup_password',
                          title: 'Password',
                          obscureText: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 3: Custom Theme from Scratch

Building a complete custom theme for brand consistency:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

class BrandColors {
  static const primary = Color(0xFF2563EB);      // Blue
  static const secondary = Color(0xFF7C3AED);    // Purple
  static const success = Color(0xFF10B981);      // Green
  static const error = Color(0xFFEF4444);        // Red
  static const warning = Color(0xFFF59E0B);      // Orange
  static const background = Color(0xFFF9FAFB);   // Light gray
  static const textPrimary = Color(0xFF111827);  // Dark gray
  static const textSecondary = Color(0xFF6B7280); // Medium gray
}

FormTheme createBrandTheme(BuildContext context) {
  // Normal state
  final normalColors = FieldColorScheme(
    backgroundColor: BrandColors.background,
    borderColor: Colors.grey[300]!,
    borderSize: 1,
    borderRadius: BorderRadius.circular(8),
    textColor: BrandColors.textPrimary,
    titleColor: BrandColors.textPrimary,
    descriptionColor: BrandColors.textSecondary,
    hintTextColor: Colors.grey[400]!,
    iconColor: BrandColors.primary,
    textBackgroundColor: BrandColors.primary.withOpacity(0.1),
  );

  // Active/focused state
  final activeColors = FieldColorScheme(
    backgroundColor: Colors.white,
    borderColor: BrandColors.primary,
    borderSize: 2,
    borderRadius: BorderRadius.circular(8),
    textColor: BrandColors.textPrimary,
    titleColor: BrandColors.primary,
    descriptionColor: BrandColors.textSecondary,
    hintTextColor: Colors.grey[400]!,
    iconColor: BrandColors.primary,
    textBackgroundColor: BrandColors.primary.withOpacity(0.1),
  );

  // Error state
  final errorColors = FieldColorScheme(
    backgroundColor: BrandColors.error.withOpacity(0.05),
    borderColor: BrandColors.error,
    borderSize: 2,
    borderRadius: BorderRadius.circular(8),
    textColor: BrandColors.textPrimary,
    titleColor: BrandColors.error,
    descriptionColor: BrandColors.error,
    hintTextColor: BrandColors.error.withOpacity(0.5),
    iconColor: BrandColors.error,
    textBackgroundColor: BrandColors.error.withOpacity(0.1),
  );

  // Disabled state
  final disabledColors = FieldColorScheme(
    backgroundColor: Colors.grey[100]!,
    borderColor: Colors.grey[300]!,
    borderSize: 1,
    borderRadius: BorderRadius.circular(8),
    textColor: Colors.grey[500]!,
    titleColor: Colors.grey[600]!,
    descriptionColor: Colors.grey[500]!,
    hintTextColor: Colors.grey[400]!,
    iconColor: Colors.grey[400]!,
    textBackgroundColor: Colors.grey[200],
  );

  // Selected state (for multiselect)
  final selectedColors = FieldColorScheme(
    backgroundColor: BrandColors.primary.withOpacity(0.1),
    borderColor: BrandColors.primary,
    borderSize: 2,
    borderRadius: BorderRadius.circular(8),
    textColor: BrandColors.primary,
    titleColor: BrandColors.primary,
    descriptionColor: BrandColors.textSecondary,
    hintTextColor: BrandColors.primary.withOpacity(0.5),
    iconColor: BrandColors.primary,
    textBackgroundColor: BrandColors.primary,
    surfaceBackground: Colors.white,
    surfaceText: BrandColors.textPrimary,
  );

  return FormTheme(
    colorScheme: normalColors,
    activeColorScheme: activeColors,
    errorColorScheme: errorColors,
    disabledColorScheme: disabledColors,
    selectedColorScheme: selectedColors,
    titleStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: BrandColors.textPrimary,
    ),
    descriptionStyle: TextStyle(
      fontSize: 14,
      color: BrandColors.textSecondary,
      height: 1.5,
    ),
    hintTextStyle: TextStyle(
      fontSize: 14,
      color: Colors.grey[400],
      fontStyle: FontStyle.italic,
    ),
    chipTextStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );
}

// Use in app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FormThemeSingleton.instance.setTheme(createBrandTheme(context));

    return MaterialApp(
      title: 'Brand Theme Example',
      home: MyFormScreen(),
    );
  }
}
```

### Example 4: Dark Mode Theme

Brightness-aware theme that automatically adapts:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

FormTheme createAdaptiveTheme(BuildContext context) {
  final brightness = MediaQuery.of(context).platformBrightness;
  final isDark = brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  // Adaptive colors based on dark/light mode
  final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
  final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
  final textColor = isDark ? Colors.white : Colors.black87;
  final accentColor = isDark ? Colors.blue[300]! : Colors.blue[700]!;

  // Normal state
  final normalColors = FieldColorScheme(
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderSize: 1,
    borderRadius: BorderRadius.circular(12),
    textColor: textColor,
    titleColor: textColor,
    descriptionColor: isDark ? Colors.grey[400]! : Colors.grey[600]!,
    hintTextColor: isDark ? Colors.grey[500]! : Colors.grey[400]!,
    iconColor: accentColor,
    textBackgroundColor: accentColor.withOpacity(0.15),
    surfaceBackground: isDark ? Colors.grey[850]! : Colors.white,
    surfaceText: textColor,
  );

  // Active state
  final activeColors = normalColors.copyWith(
    borderColor: accentColor,
    borderSize: 2,
    backgroundColor: isDark ? Colors.grey[850]! : backgroundColor,
  );

  // Error state
  final errorColors = FieldColorScheme(
    backgroundColor: colorScheme.errorContainer,
    borderColor: colorScheme.error,
    borderSize: 2,
    borderRadius: BorderRadius.circular(12),
    textColor: textColor,
    titleColor: colorScheme.error,
    descriptionColor: colorScheme.error,
    hintTextColor: colorScheme.error.withOpacity(0.6),
    iconColor: colorScheme.error,
    textBackgroundColor: colorScheme.error.withOpacity(0.2),
  );

  // Disabled state
  final disabledColors = FieldColorScheme(
    backgroundColor: isDark ? Colors.grey[850]! : Colors.grey[100]!,
    borderColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
    borderSize: 1,
    borderRadius: BorderRadius.circular(12),
    textColor: isDark ? Colors.grey[600]! : Colors.grey[500]!,
    titleColor: isDark ? Colors.grey[500]! : Colors.grey[600]!,
    descriptionColor: isDark ? Colors.grey[600]! : Colors.grey[500]!,
    hintTextColor: isDark ? Colors.grey[700]! : Colors.grey[400]!,
    iconColor: isDark ? Colors.grey[600]! : Colors.grey[400]!,
  );

  return FormTheme(
    colorScheme: normalColors,
    activeColorScheme: activeColors,
    errorColorScheme: errorColors,
    disabledColorScheme: disabledColors,
    selectedColorScheme: activeColors,
    titleStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    descriptionStyle: TextStyle(
      fontSize: 14,
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    ),
    hintTextStyle: TextStyle(
      fontSize: 14,
      color: isDark ? Colors.grey[500] : Colors.grey[400],
    ),
    chipTextStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.grey[300] : Colors.white,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Mode Theme',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // Follow system setting
      home: Builder(
        builder: (context) {
          // Set adaptive theme based on current brightness
          FormThemeSingleton.instance.setTheme(createAdaptiveTheme(context));
          return MyFormScreen();
        },
      ),
    );
  }
}
```

### Example 5: Error State Customization

Custom error appearance with enhanced visual feedback:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

final enhancedErrorTheme = FormTheme(
  // Only customize error state, inherit everything else
  errorColorScheme: FieldColorScheme(
    // Prominent red background
    backgroundColor: Colors.red[50]!,

    // Thick red border with rounded corners
    borderColor: Colors.red[700]!,
    borderSize: 3,
    borderRadius: BorderRadius.circular(12),

    // Dark red text for readability
    textColor: Colors.red[900]!,
    titleColor: Colors.red[900]!,
    descriptionColor: Colors.red[800]!,
    hintTextColor: Colors.red[400]!,

    // Red icons
    iconColor: Colors.red[700]!,

    // Red chip backgrounds
    textBackgroundColor: Colors.red[700],
  ),
);

class ErrorCustomizationExample extends StatefulWidget {
  @override
  State<ErrorCustomizationExample> createState() =>
      _ErrorCustomizationExampleState();
}

class _ErrorCustomizationExampleState extends State<ErrorCustomizationExample> {
  late final form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final results = form.FormResults.getResults(controller: controller);

    if (results.errorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Error State Example')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: form.Form(
                controller: controller,
                theme: enhancedErrorTheme,
                fields: [
                  form.TextField(
                    id: 'email',
                    title: 'Email Address',
                    description: 'We\'ll never share your email',
                    validators: [
                      form.Validators.isEmail(),
                      form.Validators.isNotEmpty(),
                    ],
                    validateLive: true,
                  ),
                  form.TextField(
                    id: 'age',
                    title: 'Age',
                    description: 'Must be 18 or older',
                    validators: [
                      form.Validator(
                        validator: (results) {
                          final age = int.tryParse(
                            results.grab('age').asString()
                          );
                          return age != null && age >= 18;
                        },
                        reason: 'You must be at least 18 years old',
                      ),
                    ],
                    validateLive: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 6: Material You Integration

Integrating with Material Design 3 dynamic color scheme:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

FormTheme createMaterial3Theme(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  // Normal state using Material 3 surface colors
  final normalColors = FieldColorScheme(
    backgroundColor: colorScheme.surfaceContainerLow,
    borderColor: colorScheme.outline,
    borderSize: 1,
    borderRadius: BorderRadius.circular(12),
    textColor: colorScheme.onSurface,
    titleColor: colorScheme.onSurface,
    descriptionColor: colorScheme.onSurfaceVariant,
    hintTextColor: colorScheme.onSurfaceVariant,
    iconColor: colorScheme.primary,
    textBackgroundColor: colorScheme.primaryContainer,
    surfaceBackground: colorScheme.surfaceContainerHigh,
    surfaceText: colorScheme.onSurface,
  );

  // Active state with primary color emphasis
  final activeColors = FieldColorScheme(
    backgroundColor: colorScheme.surfaceContainerHigh,
    borderColor: colorScheme.primary,
    borderSize: 2,
    borderRadius: BorderRadius.circular(12),
    textColor: colorScheme.onSurface,
    titleColor: colorScheme.primary,
    descriptionColor: colorScheme.onSurfaceVariant,
    hintTextColor: colorScheme.onSurfaceVariant,
    iconColor: colorScheme.primary,
    textBackgroundColor: colorScheme.primaryContainer,
  );

  // Error state using Material 3 error colors
  final errorColors = FieldColorScheme(
    backgroundColor: colorScheme.errorContainer,
    borderColor: colorScheme.error,
    borderSize: 2,
    borderRadius: BorderRadius.circular(12),
    textColor: colorScheme.onErrorContainer,
    titleColor: colorScheme.error,
    descriptionColor: colorScheme.onErrorContainer,
    hintTextColor: colorScheme.onErrorContainer.withOpacity(0.7),
    iconColor: colorScheme.error,
    textBackgroundColor: colorScheme.error,
  );

  // Disabled state
  final disabledColors = FieldColorScheme(
    backgroundColor: colorScheme.surfaceContainerLow,
    borderColor: colorScheme.outline.withOpacity(0.5),
    borderSize: 1,
    borderRadius: BorderRadius.circular(12),
    textColor: colorScheme.onSurface.withOpacity(0.38),
    titleColor: colorScheme.onSurface.withOpacity(0.38),
    descriptionColor: colorScheme.onSurfaceVariant.withOpacity(0.38),
    hintTextColor: colorScheme.onSurfaceVariant.withOpacity(0.38),
    iconColor: colorScheme.onSurface.withOpacity(0.38),
  );

  // Selected state with secondary color
  final selectedColors = FieldColorScheme(
    backgroundColor: colorScheme.secondaryContainer,
    borderColor: colorScheme.secondary,
    borderSize: 2,
    borderRadius: BorderRadius.circular(12),
    textColor: colorScheme.onSecondaryContainer,
    titleColor: colorScheme.secondary,
    descriptionColor: colorScheme.onSecondaryContainer,
    hintTextColor: colorScheme.onSecondaryContainer.withOpacity(0.7),
    iconColor: colorScheme.secondary,
    textBackgroundColor: colorScheme.secondary,
  );

  return FormTheme(
    colorScheme: normalColors,
    activeColorScheme: activeColors,
    errorColorScheme: errorColors,
    disabledColorScheme: disabledColors,
    selectedColorScheme: selectedColors,
    titleStyle: textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    descriptionStyle: textTheme.bodyMedium,
    hintTextStyle: textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    chipTextStyle: textTheme.labelLarge?.copyWith(
      color: colorScheme.onPrimaryContainer,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material You Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          // Apply Material 3 theme
          FormThemeSingleton.instance.setTheme(createMaterial3Theme(context));
          return MyFormScreen();
        },
      ),
    );
  }
}
```

## Troubleshooting

### Theme Not Applying

**Problem:** Your theme changes don't appear in the form.

**Solutions:**

1. **Check import** - Ensure you're importing `championforms_themes.dart`:
   ```dart
   import 'package:championforms/championforms_themes.dart'; // Required!
   ```

2. **Verify namespace** - Theme classes should NOT use `form.` prefix:
   ```dart
   // CORRECT
   FormTheme(...)
   FieldColorScheme(...)

   // INCORRECT
   form.FormTheme(...)  // Don't do this!
   ```

3. **Check singleton setup** - Ensure `setTheme` is called:
   ```dart
   FormThemeSingleton.instance.setTheme(myTheme);
   ```

4. **Verify cascade order** - More specific themes override general ones:
   ```dart
   // Global theme sets border to blue
   FormThemeSingleton.instance.setTheme(FormTheme(
     colorScheme: FieldColorScheme(borderColor: Colors.blue),
   ));

   // But form theme overrides it to red (red wins!)
   form.Form(
     theme: FormTheme(
       colorScheme: FieldColorScheme(borderColor: Colors.red),
     ),
   )
   ```

5. **Hot reload** - Try hot restart (not just hot reload) after theme changes

### Colors Wrong

**Problem:** Colors appear different than expected.

**Solutions:**

1. **Inspect cascade** - Check all theme levels:
   ```dart
   // Debug by setting only one level at a time

   // Step 1: Try field-level theme
   form.TextField(
     theme: FormTheme(
       colorScheme: FieldColorScheme(borderColor: Colors.red),
     ),
   )

   // If that works, problem is in cascade
   // Check form theme, then global theme
   ```

2. **Check state color schemes** - Verify you're setting the right state:
   ```dart
   // If field is focused, activeColorScheme is used!
   FormTheme(
     colorScheme: FieldColorScheme(borderColor: Colors.blue),    // Ignored when focused
     activeColorScheme: FieldColorScheme(borderColor: Colors.red), // Used when focused
   )
   ```

3. **Verify context availability** - Some themes need BuildContext:
   ```dart
   // BAD - context not available yet
   class MyApp extends StatelessWidget {
     final theme = softBlueColorTheme(context); // Error!
   }

   // GOOD - context available in build
   class MyApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       final theme = softBlueColorTheme(context); // Works!
     }
   }
   ```

4. **Check for null overrides** - Null properties inherit from parent:
   ```dart
   // This doesn't set border color to null - it inherits from parent!
   FormTheme(
     colorScheme: FieldColorScheme(
       borderColor: null, // Actually inherits from default theme
     ),
   )
   ```

### Text Styles Not Working

**Problem:** Text styles (title, description, hint) don't change.

**Solutions:**

1. **Ensure TextStyle passed correctly**:
   ```dart
   FormTheme(
     titleStyle: TextStyle(  // Not titleColor!
       fontSize: 20,
       fontWeight: FontWeight.bold,
       color: Colors.blue,
     ),
   )
   ```

2. **Check for null overrides**:
   ```dart
   // This inherits from parent, doesn't remove styling
   FormTheme(
     titleStyle: null,
   )
   ```

3. **Verify cascade** - More specific themes override:
   ```dart
   // Global sets fontSize: 20
   FormThemeSingleton.instance.setTheme(FormTheme(
     titleStyle: TextStyle(fontSize: 20),
   ));

   // Form overrides to fontSize: 16 (wins!)
   form.Form(
     theme: FormTheme(
       titleStyle: TextStyle(fontSize: 16),
     ),
   )
   ```

4. **Use copyWith for partial changes**:
   ```dart
   // Get text theme from context
   final baseStyle = Theme.of(context).textTheme.titleMedium;

   // Override just color, keep other properties
   FormTheme(
     titleStyle: baseStyle?.copyWith(color: Colors.red),
   )
   ```

### State Colors Not Switching

**Problem:** Active/error/disabled colors don't show.

**Solutions:**

1. **Verify state color scheme is defined**:
   ```dart
   FormTheme(
     colorScheme: normalColors,       // Required
     activeColorScheme: activeColors, // Required for active state
     errorColorScheme: errorColors,   // Required for error state
   )
   ```

2. **Check error state requires validation errors**:
   ```dart
   // Error colors only show when field has errors
   form.TextField(
     validators: [form.Validators.isNotEmpty()],
     validateLive: true, // Validate on blur
   )

   // Trigger validation
   form.FormResults.getResults(controller: controller);
   ```

3. **Verify disabled state requires disabled: true**:
   ```dart
   form.TextField(
     disabled: true, // Required for disabled colors to show
   )
   ```

4. **Active state requires focus**:
   ```dart
   // Active colors show when field is focused
   // Tap the field to see active state
   ```

### Performance Issues

**Problem:** Forms rebuild slowly or lag.

**Solutions:**

1. **Cache theme objects** - Don't create new themes every build:
   ```dart
   // BAD - creates new object every build
   @override
   Widget build(BuildContext context) {
     return form.Form(
       theme: FormTheme(...), // New object!
     );
   }

   // GOOD - reuse cached object
   static final _theme = FormTheme(...);

   @override
   Widget build(BuildContext context) {
     return form.Form(
       theme: _theme, // Reused!
     );
   }
   ```

2. **Use const where possible**:
   ```dart
   static const _colorScheme = FieldColorScheme(
     backgroundColor: Colors.white,
     borderColor: Colors.blue,
     // ... all values are const
   );
   ```

3. **Avoid unnecessary theme nesting**:
   ```dart
   // BAD - every field has its own theme
   fields: [
     form.TextField(theme: myTheme),
     form.TextField(theme: myTheme),
     form.TextField(theme: myTheme),
   ]

   // GOOD - set theme once on form
   form.Form(
     theme: myTheme,
     fields: [
       form.TextField(...),
       form.TextField(...),
       form.TextField(...),
     ],
   )
   ```

## Related Documentation

- **[Custom Fields Guide](../custom-fields/creating-custom-fields.md)** - Creating custom field types with themes
- **[FormController API](../api/form-controller.md)** - Controller documentation including theme property
- **[Field Types API](../api/field-types.md)** - All field types and their theme properties
- **[README.md](../../README.md)** - Main package documentation
- **[Validation Guide](../guides/validation-guide.md)** - Validation system documentation
- **[Results Guide](../guides/results-guide.md)** - Getting form results and handling errors

---

**Questions or Issues?**

If you encounter problems not covered in this guide, please file an issue on the [GitHub repository](https://github.com/fabier/championforms/issues).

# Creating Custom Themes

A comprehensive guide to creating, customizing, and applying custom themes in ChampionForms.

## Table of Contents

- [Quick Start](#quick-start)
- [Understanding FormTheme](#understanding-formtheme)
- [Creating a Basic Theme](#creating-a-basic-theme)
- [Customizing Color Schemes](#customizing-color-schemes)
- [Text Style Customization](#text-style-customization)
- [Pre-Built Themes Reference](#pre-built-themes-reference)
- [Advanced Patterns](#advanced-patterns)
- [Dark Mode Support](#dark-mode-support)
- [Complete Examples](#complete-examples)
- [Theme Testing Checklist](#theme-testing-checklist)

## Quick Start

### Minimal Custom Theme

The simplest custom theme requires only a single color scheme:

```dart
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

FormTheme myTheme(BuildContext context) {
  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      borderColor: Colors.grey,
      textColor: Colors.black,
      hintTextColor: Colors.grey.shade400,
      titleColor: Colors.black87,
      descriptionColor: Colors.black54,
      iconColor: Colors.blue,
      surfaceBackground: Colors.white,
      surfaceText: Colors.black,
    ),
  );
}
```

### Applying a Theme Globally

Set your theme once for all forms in your app:

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set global theme before MaterialApp builds
    final globalTheme = myTheme(context);
    FormThemeSingleton.instance.setTheme(globalTheme);

    return MaterialApp(
      // ...
    );
  }
}
```

### Applying a Theme to a Single Form

Override the global theme for a specific form:

```dart
import 'package:championforms/championforms.dart' as form;

form.Form(
  controller: controller,
  theme: myTheme(context), // Override global theme
  fields: fields,
)
```

## Understanding FormTheme

### The FormTheme Class

The `FormTheme` class controls all visual aspects of ChampionForms fields. It consists of:

**Color Schemes** (for different field states):
- `colorScheme` - Normal/default state
- `activeColorScheme` - When field is focused
- `errorColorScheme` - When validation fails
- `disabledColorScheme` - When field is disabled
- `selectedColorScheme` - For selected options (chips, multiselect)

**Text Styles**:
- `titleStyle` - Field titles
- `descriptionStyle` - Help text below fields
- `hintTextStyle` - Placeholder text
- `chipTextStyle` - Text in chips and selected options

**Advanced Customization** (optional):
- `inputDecoration` - Custom InputDecoration builder
- `layoutBuilder` - Custom field layout builder
- `fieldBuilder` - Custom field builder
- `nonTextFieldBuilder` - Custom non-text field builder

### Theme Cascade

Themes follow a cascading hierarchy from general to specific:

```
Default Theme (from Theme.of(context))
    ↓
Global Theme (FormThemeSingleton)
    ↓
Form Theme (passed to Form widget)
    ↓
Field Theme (passed to individual field)
```

Each level overrides the previous. Only non-null properties are applied, so you can selectively override just the parts you need.

### Required vs Optional Properties

**FieldColorScheme** has all properties with default values, so technically everything is optional. However, for a cohesive design, you should define:

**Recommended to customize**:
- `backgroundColor` - Field background color
- `borderColor` - Border color
- `textColor` - Main text color
- `hintTextColor` - Placeholder text color
- `titleColor` - Field title color
- `descriptionColor` - Help text color
- `iconColor` - Icon color

**Optional enhancements**:
- `backgroundGradient` - Gradient background (overrides backgroundColor)
- `borderGradient` - Gradient border (overrides borderColor)
- `borderSize` - Border width (default: 1)
- `borderRadius` - Corner radius (default: 8px circular)
- `textBackgroundColor` - Background for chips/selected items
- `textBackgroundGradient` - Gradient for chips/selected items
- `surfaceBackground` - Background for overlays (autocomplete dropdown)
- `surfaceText` - Text color for overlays

## Creating a Basic Theme

### Step 1: Define Your Color Palette

Start by defining your brand or design colors:

```dart
class MyBrandColors {
  static const primary = Color(0xFF6200EE);
  static const primaryLight = Color(0xFFBB86FC);
  static const secondary = Color(0xFF03DAC6);
  static const error = Color(0xFFB00020);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF000000);
  static const onSurfaceVariant = Color(0xFF666666);
}
```

### Step 2: Create the Normal State

This is the default appearance of your fields:

```dart
final normalColors = FieldColorScheme(
  backgroundColor: MyBrandColors.surface,
  borderColor: MyBrandColors.primary.withOpacity(0.5),
  borderSize: 1,
  borderRadius: BorderRadius.circular(12),
  textColor: MyBrandColors.onSurface,
  hintTextColor: MyBrandColors.onSurfaceVariant,
  titleColor: MyBrandColors.onSurface,
  descriptionColor: MyBrandColors.onSurfaceVariant,
  iconColor: MyBrandColors.primary,
  surfaceBackground: MyBrandColors.surface,
  surfaceText: MyBrandColors.onSurface,
);
```

### Step 3: Create State Variants

Define how fields look when focused, in error, or disabled:

```dart
// Active (focused) state - make it stand out
final activeColors = normalColors.copyWith(
  borderColor: MyBrandColors.primary,
  borderSize: 2,
);

// Error state - clear visual feedback
final errorColors = FieldColorScheme(
  backgroundColor: MyBrandColors.error.withOpacity(0.1),
  borderColor: MyBrandColors.error,
  borderSize: 2,
  borderRadius: BorderRadius.circular(12),
  textColor: MyBrandColors.onSurface,
  hintTextColor: MyBrandColors.onSurfaceVariant,
  titleColor: MyBrandColors.error,
  descriptionColor: MyBrandColors.error,
  iconColor: MyBrandColors.error,
  surfaceBackground: MyBrandColors.surface,
  surfaceText: MyBrandColors.onSurface,
);

// Disabled state - muted appearance
final disabledColors = FieldColorScheme(
  backgroundColor: MyBrandColors.onSurfaceVariant.withOpacity(0.1),
  borderColor: MyBrandColors.onSurfaceVariant.withOpacity(0.3),
  borderSize: 1,
  borderRadius: BorderRadius.circular(12),
  textColor: MyBrandColors.onSurfaceVariant,
  hintTextColor: MyBrandColors.onSurfaceVariant.withOpacity(0.5),
  titleColor: MyBrandColors.onSurfaceVariant,
  descriptionColor: MyBrandColors.onSurfaceVariant.withOpacity(0.7),
  iconColor: MyBrandColors.onSurfaceVariant,
  surfaceBackground: MyBrandColors.surface,
  surfaceText: MyBrandColors.onSurface,
);

// Selected state - for chips and selected options
final selectedColors = FieldColorScheme(
  backgroundColor: MyBrandColors.primary,
  borderColor: MyBrandColors.primary,
  borderSize: 1,
  borderRadius: BorderRadius.circular(12),
  textColor: Colors.white,
  hintTextColor: Colors.white.withOpacity(0.7),
  titleColor: MyBrandColors.primary,
  descriptionColor: MyBrandColors.onSurfaceVariant,
  iconColor: Colors.white,
  textBackgroundColor: MyBrandColors.primary,
  surfaceBackground: MyBrandColors.surface,
  surfaceText: MyBrandColors.onSurface,
);
```

### Step 4: Add Text Styles (Optional)

Customize typography for your forms:

```dart
final titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: MyBrandColors.onSurface,
);

final descriptionStyle = TextStyle(
  fontSize: 14,
  color: MyBrandColors.onSurfaceVariant,
);

final hintStyle = TextStyle(
  fontSize: 16,
  fontStyle: FontStyle.italic,
  color: MyBrandColors.onSurfaceVariant,
);

final chipStyle = TextStyle(
  fontSize: 14,
  color: Colors.white,
);
```

### Step 5: Assemble the FormTheme

Combine all your color schemes and text styles:

```dart
FormTheme myBrandTheme(BuildContext context) {
  return FormTheme(
    colorScheme: normalColors,
    activeColorScheme: activeColors,
    errorColorScheme: errorColors,
    disabledColorScheme: disabledColors,
    selectedColorScheme: selectedColors,
    titleStyle: titleStyle,
    descriptionStyle: descriptionStyle,
    hintTextStyle: hintStyle,
    chipTextStyle: chipStyle,
  );
}
```

### Step 6: Apply Your Theme

Set it globally or per-form as shown in the Quick Start section.

## Customizing Color Schemes

### Understanding Color Scheme States

ChampionForms uses five distinct color schemes to provide visual feedback:

#### 1. Normal State (`colorScheme`)

The default appearance when no interaction is happening:

```dart
FieldColorScheme(
  backgroundColor: Colors.white,
  borderColor: Colors.grey.shade300,
  textColor: Colors.black,
  // ...
)
```

**When used**: Default field appearance

#### 2. Active State (`activeColorScheme`)

When the user focuses on a field:

```dart
FieldColorScheme(
  backgroundColor: Colors.white,
  borderColor: Colors.blue,        // Accent color
  borderSize: 2,                    // Thicker border
  textColor: Colors.black,
  // ...
)
```

**When used**: Field has focus (user clicked/tabbed into it)

**Best practices**:
- Use your accent/primary color for borders
- Increase border size (2px recommended)
- Keep background consistent or slightly brighter

#### 3. Error State (`errorColorScheme`)

When validation fails:

```dart
FieldColorScheme(
  backgroundColor: Colors.red.shade50,  // Subtle error background
  borderColor: Colors.red,               // Clear error border
  borderSize: 2,
  textColor: Colors.black,
  titleColor: Colors.red,                // Error title
  descriptionColor: Colors.red,          // Error message color
  iconColor: Colors.red,
  // ...
)
```

**When used**: Field has validation errors

**Best practices**:
- Use red or warning colors
- Ensure WCAG contrast compliance (4.5:1 minimum)
- Don't rely on color alone - error text is also displayed
- Keep text readable against error background

#### 4. Disabled State (`disabledColorScheme`)

When the field cannot be interacted with:

```dart
FieldColorScheme(
  backgroundColor: Colors.grey.shade100,
  borderColor: Colors.grey.shade300,
  textColor: Colors.grey.shade600,
  hintTextColor: Colors.grey.shade400,
  titleColor: Colors.grey.shade600,
  iconColor: Colors.grey.shade500,
  // ...
)
```

**When used**: Field is disabled (not accepting input)

**Best practices**:
- Use muted/desaturated colors
- Reduce opacity to indicate unavailability
- Maintain minimum contrast for accessibility
- Consider using grey tones

#### 5. Selected State (`selectedColorScheme`)

For selected options in chips, dropdowns, and multiselect:

```dart
FieldColorScheme(
  backgroundColor: Colors.blue,
  borderColor: Colors.blue.shade700,
  textColor: Colors.white,              // Contrast with background
  textBackgroundColor: Colors.blue,     // Chip background
  // ...
)
```

**When used**: Chips, selected dropdown items, checkbox selections

**Best practices**:
- Use your primary/accent color
- Ensure text contrasts well with background
- Make selected items visually distinct
- Consider hover states for web

### Color Scheme Properties in Detail

Here's every property you can customize in a `FieldColorScheme`:

```dart
FieldColorScheme(
  // Background
  backgroundColor: Colors.white,                    // Solid color
  backgroundGradient: FieldGradientColors(         // OR gradient (overrides backgroundColor)
    colorOne: Colors.blue.shade50,
    colorTwo: Colors.purple.shade50,
  ),

  // Border
  borderColor: Colors.grey,                        // Solid color
  borderGradient: FieldGradientColors(             // OR gradient (overrides borderColor)
    colorOne: Colors.blue,
    colorTwo: Colors.purple,
  ),
  borderSize: 1,                                   // Border width in pixels
  borderRadius: BorderRadius.circular(8),          // Corner radius

  // Text colors
  textColor: Colors.black,                         // Input text color
  hintTextColor: Colors.grey,                      // Placeholder text color
  titleColor: Colors.black87,                      // Field title color
  descriptionColor: Colors.black54,                // Help text color

  // Icon
  iconColor: Colors.blue,                          // Leading/trailing icon color

  // Chips and selected items
  textBackgroundColor: Colors.blue.shade100,       // Background for chips
  textBackgroundGradient: FieldGradientColors(     // OR gradient for chips
    colorOne: Colors.blue.shade100,
    colorTwo: Colors.blue.shade200,
  ),

  // Overlay (autocomplete dropdown, etc.)
  surfaceBackground: Colors.white,                 // Overlay background
  surfaceText: Colors.black,                       // Overlay text color
)
```

### Example: Complete State Set

Here's a full example with all five states configured:

```dart
FormTheme completeTheme(BuildContext context) {
  const primary = Color(0xFF1976D2);
  const surface = Colors.white;
  const onSurface = Colors.black;
  const error = Color(0xFFD32F2F);

  return FormTheme(
    // Normal state
    colorScheme: FieldColorScheme(
      backgroundColor: surface,
      borderColor: Colors.grey.shade300,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: onSurface,
      hintTextColor: Colors.grey.shade600,
      titleColor: onSurface,
      descriptionColor: Colors.grey.shade700,
      iconColor: primary,
      surfaceBackground: surface,
      surfaceText: onSurface,
    ),

    // Active/focused state
    activeColorScheme: FieldColorScheme(
      backgroundColor: surface,
      borderColor: primary,
      borderSize: 2,
      borderRadius: BorderRadius.circular(8),
      textColor: onSurface,
      hintTextColor: Colors.grey.shade500,
      titleColor: primary,
      descriptionColor: Colors.grey.shade700,
      iconColor: primary,
      surfaceBackground: surface,
      surfaceText: onSurface,
    ),

    // Error state
    errorColorScheme: FieldColorScheme(
      backgroundColor: error.withOpacity(0.05),
      borderColor: error,
      borderSize: 2,
      borderRadius: BorderRadius.circular(8),
      textColor: onSurface,
      hintTextColor: Colors.grey.shade600,
      titleColor: error,
      descriptionColor: error,
      iconColor: error,
      surfaceBackground: surface,
      surfaceText: onSurface,
    ),

    // Disabled state
    disabledColorScheme: FieldColorScheme(
      backgroundColor: Colors.grey.shade100,
      borderColor: Colors.grey.shade300,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: Colors.grey.shade600,
      hintTextColor: Colors.grey.shade400,
      titleColor: Colors.grey.shade600,
      descriptionColor: Colors.grey.shade500,
      iconColor: Colors.grey.shade500,
      surfaceBackground: surface,
      surfaceText: onSurface,
    ),

    // Selected state (chips, multiselect)
    selectedColorScheme: FieldColorScheme(
      backgroundColor: primary,
      borderColor: primary,
      borderSize: 1,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.white,
      hintTextColor: Colors.white.withOpacity(0.7),
      titleColor: primary,
      descriptionColor: Colors.grey.shade700,
      iconColor: Colors.white,
      textBackgroundColor: primary,
      surfaceBackground: surface,
      surfaceText: onSurface,
    ),
  );
}
```

## Text Style Customization

### Available Text Styles

ChampionForms uses four distinct text styles that you can customize:

#### 1. Title Style (`titleStyle`)

Applied to field titles/labels:

```dart
titleStyle: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
  letterSpacing: 0.15,
)
```

#### 2. Description Style (`descriptionStyle`)

Applied to help text displayed below fields:

```dart
descriptionStyle: TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: Colors.black54,
  height: 1.4,
)
```

#### 3. Hint Text Style (`hintTextStyle`)

Applied to placeholder text in text fields:

```dart
hintTextStyle: TextStyle(
  fontSize: 16,
  fontStyle: FontStyle.italic,
  color: Colors.grey.shade600,
)
```

#### 4. Chip Text Style (`chipTextStyle`)

Applied to text in chips and selected options:

```dart
chipTextStyle: TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Colors.white,
)
```

### Example: Custom Typography System

Create a cohesive typography system for your forms:

```dart
import 'package:google_fonts/google_fonts.dart';

FormTheme typographyTheme(BuildContext context) {
  return FormTheme(
    titleStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      letterSpacing: 0.15,
    ),

    descriptionStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.black54,
      height: 1.5,
    ),

    hintTextStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: Colors.grey.shade600,
    ),

    chipTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      letterSpacing: 0.1,
    ),
  );
}
```

### Using Theme.of(context) Text Styles

Leverage Material Design text themes:

```dart
FormTheme materialTextTheme(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  return FormTheme(
    titleStyle: textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),

    descriptionStyle: textTheme.bodySmall?.copyWith(
      color: Colors.black54,
    ),

    hintTextStyle: textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: Colors.grey.shade600,
    ),

    chipTextStyle: textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
    ),
  );
}
```

## Pre-Built Themes Reference

ChampionForms includes three pre-built themes you can use or customize.

### Soft Blue Theme

A professional theme with blue tones:

```dart
import 'package:championforms/championforms_themes.dart';

// Use directly
FormThemeSingleton.instance.setTheme(softBlueColorTheme(context));

// Or customize
final myTheme = softBlueColorTheme(context).copyWith(
  titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
);
```

**Color palette**:
- Primary: `#3D52A0` (Strong Blue)
- Secondary: `#7091E6` (Light Blue)
- Tertiary: `#8697C4` (Muted Blue)
- Background: `#ADBADA` (Soft Light)
- Accent: `#7091E6` (Hint/Lightest)

**When to use**:
- Professional/corporate applications
- Medical or healthcare forms
- Trust-focused interfaces
- Default safe choice

**Characteristics**:
- Conservative color palette
- Clear state differentiation
- High readability
- Good contrast ratios

### Red Accent Theme

A dynamic theme with red accents that adapts to light/dark mode:

```dart
import 'package:championforms/championforms_themes.dart';

FormThemeSingleton.instance.setTheme(redAccentFormTheme(context));
```

**Color palette** (adapts to brightness):
- Light mode: Red borders, black text, white backgrounds
- Dark mode: Red accents, red text, black backgrounds

**When to use**:
- Apps with existing red branding
- Error-focused or alert forms
- Dark mode applications
- Modern, bold interfaces

**Characteristics**:
- Brightness-aware (light/dark mode)
- Uses `Theme.of(context)` for base colors
- Bold, attention-grabbing
- Dynamic error states

**Implementation highlight**:
```dart
final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

FieldColorScheme(
  backgroundColor: isDark ? Colors.black : Colors.white,
  borderColor: isDark ? Colors.redAccent : Colors.red,
  textColor: isDark ? Colors.redAccent : Colors.black,
  // ...
)
```

### Iconic Theme

A vibrant theme with warm, energetic colors:

```dart
import 'package:championforms/championforms_themes.dart';

FormThemeSingleton.instance.setTheme(iconicColorTheme(context));
```

**Color palette**:
- Primary: `#E43D12` (Vibrant Red-Orange)
- Secondary: `#D6536D` (Rich Pink)
- Tertiary: `#FFA2B6` (Light Pink)
- Background: `#EBE9E1` (Soft Off-White)
- Accent: `#EFB11D` (Bright Gold)

**When to use**:
- Creative or artistic applications
- Consumer-facing products
- Playful interfaces
- Brand-heavy designs

**Characteristics**:
- Warm, energetic palette
- High visual impact
- Distinctive gold accents
- Strong brand presence

### Customizing Pre-Built Themes

Use `copyWith` to override specific properties:

```dart
// Start with Soft Blue, but change text styles
final customTheme = softBlueColorTheme(context).copyWith(
  titleStyle: GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  descriptionStyle: GoogleFonts.roboto(
    fontSize: 14,
    color: Colors.grey.shade700,
  ),
);

FormThemeSingleton.instance.setTheme(customTheme);
```

Or mix themes:

```dart
// Use Iconic colors with Red Accent text styles
final redAccent = redAccentFormTheme(context);
final iconic = iconicColorTheme(context);

final mixedTheme = iconic.copyWith(
  titleStyle: redAccent.titleStyle,
  descriptionStyle: redAccent.descriptionStyle,
);
```

## Advanced Patterns

### Context-Aware Themes

Create themes that adapt to Flutter's `Theme.of(context)`:

```dart
FormTheme contextAwareTheme(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outline,
      textColor: colorScheme.onSurface,
      hintTextColor: colorScheme.onSurfaceVariant,
      titleColor: colorScheme.onSurface,
      descriptionColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      surfaceBackground: colorScheme.surface,
      surfaceText: colorScheme.onSurface,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.primary,
      borderSize: 2,
      textColor: colorScheme.onSurface,
      hintTextColor: colorScheme.onSurfaceVariant,
      titleColor: colorScheme.primary,
      descriptionColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      surfaceBackground: colorScheme.surface,
      surfaceText: colorScheme.onSurface,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: colorScheme.errorContainer,
      borderColor: colorScheme.error,
      borderSize: 2,
      textColor: colorScheme.onSurface,
      hintTextColor: colorScheme.onSurfaceVariant,
      titleColor: colorScheme.error,
      descriptionColor: colorScheme.error,
      iconColor: colorScheme.error,
      surfaceBackground: colorScheme.surface,
      surfaceText: colorScheme.onSurface,
    ),

    titleStyle: textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    descriptionStyle: textTheme.bodySmall,
    hintTextStyle: textTheme.bodyMedium,
    chipTextStyle: textTheme.bodySmall,
  );
}
```

**Benefits**:
- Automatically adapts to app theme changes
- Respects Material Design 3 color roles
- Supports light/dark mode out of the box
- Consistent with rest of app

### Gradient Backgrounds

Use gradients for modern, eye-catching fields:

```dart
FormTheme gradientTheme(BuildContext context) {
  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: Colors.white, // Fallback
      backgroundGradient: FieldGradientColors(
        colorOne: Colors.blue.shade50,
        colorTwo: Colors.purple.shade50,
      ),
      borderColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.black87,
      hintTextColor: Colors.grey.shade600,
      titleColor: Colors.black87,
      descriptionColor: Colors.grey.shade700,
      iconColor: Colors.purple,
      surfaceBackground: Colors.white,
      surfaceText: Colors.black,
    ),

    // Gradient borders for active state
    activeColorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      backgroundGradient: FieldGradientColors(
        colorOne: Colors.blue.shade100,
        colorTwo: Colors.purple.shade100,
      ),
      borderColor: Colors.blue, // Fallback
      borderGradient: FieldGradientColors(
        colorOne: Colors.blue,
        colorTwo: Colors.purple,
      ),
      borderSize: 2,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.black87,
      hintTextColor: Colors.grey.shade600,
      titleColor: Colors.purple,
      descriptionColor: Colors.grey.shade700,
      iconColor: Colors.purple,
      surfaceBackground: Colors.white,
      surfaceText: Colors.black,
    ),
  );
}
```

### Rounded vs Sharp Design

Create themes with different border radius styles:

```dart
// Fully rounded
FormTheme roundedTheme(BuildContext context) {
  final baseScheme = FieldColorScheme(
    backgroundColor: Colors.white,
    borderColor: Colors.blue,
    borderRadius: BorderRadius.circular(24), // Very rounded
    textColor: Colors.black,
    hintTextColor: Colors.grey,
    titleColor: Colors.black,
    descriptionColor: Colors.grey.shade700,
    iconColor: Colors.blue,
    surfaceBackground: Colors.white,
    surfaceText: Colors.black,
  );

  return FormTheme(
    colorScheme: baseScheme,
    selectedColorScheme: baseScheme.copyWith(
      backgroundColor: Colors.blue,
      borderRadius: BorderRadius.circular(20), // Pill-shaped chips
      textColor: Colors.white,
    ),
  );
}

// Sharp/angular
FormTheme sharpTheme(BuildContext context) {
  final baseScheme = FieldColorScheme(
    backgroundColor: Colors.white,
    borderColor: Colors.blue,
    borderRadius: BorderRadius.circular(4), // Minimal rounding
    textColor: Colors.black,
    hintTextColor: Colors.grey,
    titleColor: Colors.black,
    descriptionColor: Colors.grey.shade700,
    iconColor: Colors.blue,
    surfaceBackground: Colors.white,
    surfaceText: Colors.black,
  );

  return FormTheme(
    colorScheme: baseScheme,
    selectedColorScheme: baseScheme.copyWith(
      backgroundColor: Colors.blue,
      borderRadius: BorderRadius.circular(4),
      textColor: Colors.white,
    ),
  );
}

// No rounding (rectangular)
FormTheme rectangularTheme(BuildContext context) {
  final baseScheme = FieldColorScheme(
    backgroundColor: Colors.white,
    borderColor: Colors.blue,
    borderRadius: BorderRadius.zero, // Sharp corners
    textColor: Colors.black,
    hintTextColor: Colors.grey,
    titleColor: Colors.black,
    descriptionColor: Colors.grey.shade700,
    iconColor: Colors.blue,
    surfaceBackground: Colors.white,
    surfaceText: Colors.black,
  );

  return FormTheme(colorScheme: baseScheme);
}
```

### Material You Integration

Full Material 3 integration using color roles:

```dart
FormTheme materialYouTheme(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return FormTheme(
    // Normal state uses surface colors
    colorScheme: FieldColorScheme(
      backgroundColor: colorScheme.surfaceContainerHighest,
      borderColor: colorScheme.outline,
      borderSize: 1,
      borderRadius: BorderRadius.circular(12),
      textColor: colorScheme.onSurface,
      hintTextColor: colorScheme.onSurfaceVariant,
      titleColor: colorScheme.onSurface,
      descriptionColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      surfaceBackground: colorScheme.surfaceContainerHigh,
      surfaceText: colorScheme.onSurface,
    ),

    // Active state uses primary colors
    activeColorScheme: FieldColorScheme(
      backgroundColor: colorScheme.surfaceContainerHighest,
      borderColor: colorScheme.primary,
      borderSize: 2,
      borderRadius: BorderRadius.circular(12),
      textColor: colorScheme.onSurface,
      hintTextColor: colorScheme.onSurfaceVariant,
      titleColor: colorScheme.primary,
      descriptionColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.primary,
      surfaceBackground: colorScheme.surfaceContainerHigh,
      surfaceText: colorScheme.onSurface,
    ),

    // Error state uses error colors
    errorColorScheme: FieldColorScheme(
      backgroundColor: colorScheme.errorContainer,
      borderColor: colorScheme.error,
      borderSize: 2,
      borderRadius: BorderRadius.circular(12),
      textColor: colorScheme.onErrorContainer,
      hintTextColor: colorScheme.onErrorContainer.withOpacity(0.7),
      titleColor: colorScheme.error,
      descriptionColor: colorScheme.error,
      iconColor: colorScheme.error,
      surfaceBackground: colorScheme.surfaceContainerHigh,
      surfaceText: colorScheme.onSurface,
    ),

    // Disabled uses inverseSurface colors
    disabledColorScheme: FieldColorScheme(
      backgroundColor: colorScheme.surfaceContainerLow,
      borderColor: colorScheme.outlineVariant,
      borderSize: 1,
      borderRadius: BorderRadius.circular(12),
      textColor: colorScheme.onSurface.withOpacity(0.38),
      hintTextColor: colorScheme.onSurface.withOpacity(0.38),
      titleColor: colorScheme.onSurface.withOpacity(0.38),
      descriptionColor: colorScheme.onSurface.withOpacity(0.38),
      iconColor: colorScheme.onSurface.withOpacity(0.38),
      surfaceBackground: colorScheme.surfaceContainerHigh,
      surfaceText: colorScheme.onSurface,
    ),

    // Selected uses primary container
    selectedColorScheme: FieldColorScheme(
      backgroundColor: colorScheme.primaryContainer,
      borderColor: colorScheme.primary,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: colorScheme.onPrimaryContainer,
      hintTextColor: colorScheme.onPrimaryContainer.withOpacity(0.7),
      titleColor: colorScheme.primary,
      descriptionColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.onPrimaryContainer,
      textBackgroundColor: colorScheme.primaryContainer,
      surfaceBackground: colorScheme.surfaceContainerHigh,
      surfaceText: colorScheme.onSurface,
    ),

    // Use Material text styles
    titleStyle: textTheme.titleMedium,
    descriptionStyle: textTheme.bodySmall,
    hintTextStyle: textTheme.bodyMedium,
    chipTextStyle: textTheme.labelMedium,
  );
}
```

## Dark Mode Support

### Brightness-Aware Themes

Create a single theme that adapts to light/dark mode:

```dart
FormTheme adaptiveTheme(BuildContext context) {
  final brightness = MediaQuery.of(context).platformBrightness;
  final isDark = brightness == Brightness.dark;

  // Define color palettes
  final lightBackground = Colors.white;
  final darkBackground = Colors.grey.shade900;

  final lightBorder = Colors.grey.shade300;
  final darkBorder = Colors.grey.shade700;

  final lightText = Colors.black;
  final darkText = Colors.white;

  final lightPrimary = Colors.blue.shade700;
  final darkPrimary = Colors.blue.shade300;

  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: isDark ? darkBackground : lightBackground,
      borderColor: isDark ? darkBorder : lightBorder,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: isDark ? darkText : lightText,
      hintTextColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      titleColor: isDark ? darkText : lightText,
      descriptionColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      iconColor: isDark ? darkPrimary : lightPrimary,
      surfaceBackground: isDark ? darkBackground : lightBackground,
      surfaceText: isDark ? darkText : lightText,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: isDark ? darkBackground : lightBackground,
      borderColor: isDark ? darkPrimary : lightPrimary,
      borderSize: 2,
      borderRadius: BorderRadius.circular(8),
      textColor: isDark ? darkText : lightText,
      hintTextColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      titleColor: isDark ? darkPrimary : lightPrimary,
      descriptionColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      iconColor: isDark ? darkPrimary : lightPrimary,
      surfaceBackground: isDark ? darkBackground : lightBackground,
      surfaceText: isDark ? darkText : lightText,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: isDark
          ? Colors.red.shade900.withOpacity(0.3)
          : Colors.red.shade50,
      borderColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
      borderSize: 2,
      borderRadius: BorderRadius.circular(8),
      textColor: isDark ? darkText : lightText,
      hintTextColor: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      titleColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
      descriptionColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
      iconColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
      surfaceBackground: isDark ? darkBackground : lightBackground,
      surfaceText: isDark ? darkText : lightText,
    ),

    disabledColorScheme: FieldColorScheme(
      backgroundColor: isDark
          ? Colors.grey.shade800
          : Colors.grey.shade100,
      borderColor: isDark
          ? Colors.grey.shade700
          : Colors.grey.shade300,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: isDark
          ? Colors.grey.shade600
          : Colors.grey.shade600,
      hintTextColor: isDark
          ? Colors.grey.shade700
          : Colors.grey.shade400,
      titleColor: isDark
          ? Colors.grey.shade600
          : Colors.grey.shade600,
      descriptionColor: isDark
          ? Colors.grey.shade700
          : Colors.grey.shade500,
      iconColor: isDark
          ? Colors.grey.shade600
          : Colors.grey.shade500,
      surfaceBackground: isDark ? darkBackground : lightBackground,
      surfaceText: isDark ? darkText : lightText,
    ),

    selectedColorScheme: FieldColorScheme(
      backgroundColor: isDark ? darkPrimary.withOpacity(0.3) : lightPrimary,
      borderColor: isDark ? darkPrimary : lightPrimary,
      borderSize: 1,
      borderRadius: BorderRadius.circular(16),
      textColor: isDark ? darkPrimary : Colors.white,
      hintTextColor: isDark
          ? darkPrimary.withOpacity(0.7)
          : Colors.white.withOpacity(0.7),
      titleColor: isDark ? darkPrimary : lightPrimary,
      descriptionColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      iconColor: isDark ? darkPrimary : Colors.white,
      textBackgroundColor: isDark
          ? darkPrimary.withOpacity(0.3)
          : lightPrimary,
      surfaceBackground: isDark ? darkBackground : lightBackground,
      surfaceText: isDark ? darkText : lightText,
    ),
  );
}
```

### Dark Theme Best Practices

**1. Use Dark Grays, Not Pure Black**

```dart
// Good
backgroundColor: Color(0xFF121212),  // Dark grey
backgroundColor: Colors.grey.shade900,

// Avoid
backgroundColor: Colors.black,  // Too harsh
```

**2. Reduce Color Saturation**

```dart
// Light mode
borderColor: Colors.blue.shade700,

// Dark mode - use lighter, less saturated version
borderColor: Colors.blue.shade300,
```

**3. Increase Contrast**

```dart
// Ensure text stands out
textColor: isDark ? Colors.white : Colors.black,

// Not enough contrast in dark mode
textColor: isDark ? Colors.grey.shade600 : Colors.black,  // Too dim
```

**4. Use Elevation Through Color**

```dart
// Surface elevation in dark mode
backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,  // Base
surfaceBackground: isDark ? Color(0xFF2C2C2C) : Colors.white,  // Elevated
```

**5. Test Readability**

Ensure WCAG AA compliance (4.5:1 contrast ratio) in both modes:

```dart
// Good contrast in both modes
final textColor = isDark ? Colors.white : Colors.black;
final backgroundColor = isDark ? Color(0xFF121212) : Colors.white;
// Contrast ratio: ~15:1 (both modes)

// Poor contrast in dark mode
final textColor = isDark ? Colors.grey.shade500 : Colors.black;
final backgroundColor = isDark ? Colors.grey.shade800 : Colors.white;
// Contrast ratio: ~2.5:1 (fails WCAG AA)
```

## Complete Examples

### Example 1: Corporate Brand Theme

A professional theme for business applications:

```dart
FormTheme corporateBrandTheme(BuildContext context) {
  // Brand colors
  const brandPrimary = Color(0xFF003366);      // Navy blue
  const brandSecondary = Color(0xFF0066CC);    // Bright blue
  const brandAccent = Color(0xFFFF6B35);       // Orange accent
  const brandNeutral = Color(0xFFF5F5F5);      // Light grey

  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      borderColor: Colors.grey.shade300,
      borderSize: 1,
      borderRadius: BorderRadius.circular(4),  // Subtle rounding
      textColor: brandPrimary,
      hintTextColor: Colors.grey.shade600,
      titleColor: brandPrimary,
      descriptionColor: Colors.grey.shade700,
      iconColor: brandSecondary,
      surfaceBackground: Colors.white,
      surfaceText: brandPrimary,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      borderColor: brandSecondary,
      borderSize: 2,
      borderRadius: BorderRadius.circular(4),
      textColor: brandPrimary,
      hintTextColor: Colors.grey.shade600,
      titleColor: brandSecondary,
      descriptionColor: Colors.grey.shade700,
      iconColor: brandSecondary,
      surfaceBackground: Colors.white,
      surfaceText: brandPrimary,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade700,
      borderSize: 2,
      borderRadius: BorderRadius.circular(4),
      textColor: brandPrimary,
      hintTextColor: Colors.grey.shade600,
      titleColor: Colors.red.shade700,
      descriptionColor: Colors.red.shade700,
      iconColor: Colors.red.shade700,
      surfaceBackground: Colors.white,
      surfaceText: brandPrimary,
    ),

    disabledColorScheme: FieldColorScheme(
      backgroundColor: brandNeutral,
      borderColor: Colors.grey.shade300,
      borderSize: 1,
      borderRadius: BorderRadius.circular(4),
      textColor: Colors.grey.shade600,
      hintTextColor: Colors.grey.shade400,
      titleColor: Colors.grey.shade600,
      descriptionColor: Colors.grey.shade500,
      iconColor: Colors.grey.shade500,
      surfaceBackground: Colors.white,
      surfaceText: brandPrimary,
    ),

    selectedColorScheme: FieldColorScheme(
      backgroundColor: brandSecondary,
      borderColor: brandSecondary,
      borderSize: 1,
      borderRadius: BorderRadius.circular(4),
      textColor: Colors.white,
      hintTextColor: Colors.white.withOpacity(0.7),
      titleColor: brandSecondary,
      descriptionColor: Colors.grey.shade700,
      iconColor: Colors.white,
      textBackgroundColor: brandSecondary,
      surfaceBackground: Colors.white,
      surfaceText: brandPrimary,
    ),

    titleStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: brandPrimary,
      letterSpacing: 0.5,
    ),

    descriptionStyle: TextStyle(
      fontSize: 13,
      color: Colors.grey.shade700,
      height: 1.4,
    ),

    hintTextStyle: TextStyle(
      fontSize: 15,
      color: Colors.grey.shade600,
    ),

    chipTextStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );
}
```

### Example 2: Playful Theme

A fun, colorful theme for consumer apps:

```dart
FormTheme playfulTheme(BuildContext context) {
  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      backgroundGradient: FieldGradientColors(
        colorOne: Colors.pink.shade50,
        colorTwo: Colors.purple.shade50,
      ),
      borderColor: Colors.transparent,
      borderSize: 0,
      borderRadius: BorderRadius.circular(20),  // Very rounded
      textColor: Colors.purple.shade900,
      hintTextColor: Colors.purple.shade400,
      titleColor: Colors.purple.shade700,
      descriptionColor: Colors.purple.shade600,
      iconColor: Colors.purple.shade500,
      surfaceBackground: Colors.white,
      surfaceText: Colors.purple.shade900,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      backgroundGradient: FieldGradientColors(
        colorOne: Colors.pink.shade100,
        colorTwo: Colors.purple.shade100,
      ),
      borderColor: Colors.purple.shade400,
      borderGradient: FieldGradientColors(
        colorOne: Colors.pink.shade400,
        colorTwo: Colors.purple.shade400,
      ),
      borderSize: 3,
      borderRadius: BorderRadius.circular(20),
      textColor: Colors.purple.shade900,
      hintTextColor: Colors.purple.shade400,
      titleColor: Colors.purple.shade700,
      descriptionColor: Colors.purple.shade600,
      iconColor: Colors.purple.shade500,
      surfaceBackground: Colors.white,
      surfaceText: Colors.purple.shade900,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade400,
      borderSize: 3,
      borderRadius: BorderRadius.circular(20),
      textColor: Colors.red.shade900,
      hintTextColor: Colors.red.shade400,
      titleColor: Colors.red.shade700,
      descriptionColor: Colors.red.shade600,
      iconColor: Colors.red.shade500,
      surfaceBackground: Colors.white,
      surfaceText: Colors.red.shade900,
    ),

    disabledColorScheme: FieldColorScheme(
      backgroundColor: Colors.grey.shade100,
      borderColor: Colors.transparent,
      borderSize: 0,
      borderRadius: BorderRadius.circular(20),
      textColor: Colors.grey.shade600,
      hintTextColor: Colors.grey.shade400,
      titleColor: Colors.grey.shade600,
      descriptionColor: Colors.grey.shade500,
      iconColor: Colors.grey.shade500,
      surfaceBackground: Colors.white,
      surfaceText: Colors.grey.shade700,
    ),

    selectedColorScheme: FieldColorScheme(
      backgroundColor: Colors.purple.shade400,
      backgroundGradient: FieldGradientColors(
        colorOne: Colors.pink.shade400,
        colorTwo: Colors.purple.shade400,
      ),
      borderColor: Colors.transparent,
      borderSize: 0,
      borderRadius: BorderRadius.circular(24),  // Pill-shaped
      textColor: Colors.white,
      hintTextColor: Colors.white.withOpacity(0.8),
      titleColor: Colors.purple.shade700,
      descriptionColor: Colors.purple.shade600,
      iconColor: Colors.white,
      textBackgroundColor: Colors.purple.shade400,
      surfaceBackground: Colors.white,
      surfaceText: Colors.purple.shade900,
    ),

    titleStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.purple.shade700,
    ),

    descriptionStyle: TextStyle(
      fontSize: 14,
      color: Colors.purple.shade600,
      height: 1.5,
    ),

    hintTextStyle: TextStyle(
      fontSize: 16,
      fontStyle: FontStyle.italic,
      color: Colors.purple.shade400,
    ),

    chipTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );
}
```

### Example 3: Minimalist Theme

A clean, subtle theme with neutral colors:

```dart
FormTheme minimalistTheme(BuildContext context) {
  const primaryGrey = Color(0xFF2C2C2C);
  const lightGrey = Color(0xFFF8F8F8);
  const borderGrey = Color(0xFFE0E0E0);

  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: lightGrey,
      borderColor: borderGrey,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: primaryGrey,
      hintTextColor: Colors.grey.shade500,
      titleColor: primaryGrey,
      descriptionColor: Colors.grey.shade600,
      iconColor: primaryGrey,
      surfaceBackground: Colors.white,
      surfaceText: primaryGrey,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: Colors.white,
      borderColor: primaryGrey,
      borderSize: 1,  // Keep it subtle
      borderRadius: BorderRadius.circular(8),
      textColor: primaryGrey,
      hintTextColor: Colors.grey.shade500,
      titleColor: primaryGrey,
      descriptionColor: Colors.grey.shade600,
      iconColor: primaryGrey,
      surfaceBackground: Colors.white,
      surfaceText: primaryGrey,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade300,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: primaryGrey,
      hintTextColor: Colors.grey.shade500,
      titleColor: Colors.red.shade700,
      descriptionColor: Colors.red.shade700,
      iconColor: Colors.red.shade700,
      surfaceBackground: Colors.white,
      surfaceText: primaryGrey,
    ),

    disabledColorScheme: FieldColorScheme(
      backgroundColor: Colors.grey.shade50,
      borderColor: Colors.grey.shade200,
      borderSize: 1,
      borderRadius: BorderRadius.circular(8),
      textColor: Colors.grey.shade500,
      hintTextColor: Colors.grey.shade400,
      titleColor: Colors.grey.shade500,
      descriptionColor: Colors.grey.shade400,
      iconColor: Colors.grey.shade400,
      surfaceBackground: Colors.white,
      surfaceText: primaryGrey,
    ),

    selectedColorScheme: FieldColorScheme(
      backgroundColor: primaryGrey,
      borderColor: primaryGrey,
      borderSize: 1,
      borderRadius: BorderRadius.circular(6),
      textColor: Colors.white,
      hintTextColor: Colors.white.withOpacity(0.7),
      titleColor: primaryGrey,
      descriptionColor: Colors.grey.shade600,
      iconColor: Colors.white,
      textBackgroundColor: primaryGrey,
      surfaceBackground: Colors.white,
      surfaceText: primaryGrey,
    ),

    titleStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: primaryGrey,
      letterSpacing: 0.25,
    ),

    descriptionStyle: TextStyle(
      fontSize: 12,
      color: Colors.grey.shade600,
      height: 1.5,
    ),

    hintTextStyle: TextStyle(
      fontSize: 14,
      color: Colors.grey.shade500,
    ),

    chipTextStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );
}
```

### Example 4: Glassmorphism Theme

A modern theme with semi-transparent, blurred backgrounds:

```dart
FormTheme glassmorphismTheme(BuildContext context) {
  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: Colors.white.withOpacity(0.7),
      borderColor: Colors.white.withOpacity(0.3),
      borderSize: 1,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.black87,
      hintTextColor: Colors.black54,
      titleColor: Colors.black87,
      descriptionColor: Colors.black54,
      iconColor: Colors.blue.shade700,
      surfaceBackground: Colors.white.withOpacity(0.9),
      surfaceText: Colors.black87,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: Colors.white.withOpacity(0.8),
      borderColor: Colors.blue.withOpacity(0.6),
      borderSize: 2,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.black87,
      hintTextColor: Colors.black54,
      titleColor: Colors.blue.shade700,
      descriptionColor: Colors.black54,
      iconColor: Colors.blue.shade700,
      surfaceBackground: Colors.white.withOpacity(0.9),
      surfaceText: Colors.black87,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: Colors.red.shade100.withOpacity(0.5),
      borderColor: Colors.red.withOpacity(0.6),
      borderSize: 2,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.black87,
      hintTextColor: Colors.black54,
      titleColor: Colors.red.shade700,
      descriptionColor: Colors.red.shade700,
      iconColor: Colors.red.shade700,
      surfaceBackground: Colors.white.withOpacity(0.9),
      surfaceText: Colors.black87,
    ),

    disabledColorScheme: FieldColorScheme(
      backgroundColor: Colors.grey.shade100.withOpacity(0.5),
      borderColor: Colors.grey.withOpacity(0.3),
      borderSize: 1,
      borderRadius: BorderRadius.circular(16),
      textColor: Colors.grey.shade600,
      hintTextColor: Colors.grey.shade400,
      titleColor: Colors.grey.shade600,
      descriptionColor: Colors.grey.shade500,
      iconColor: Colors.grey.shade500,
      surfaceBackground: Colors.white.withOpacity(0.9),
      surfaceText: Colors.black87,
    ),

    selectedColorScheme: FieldColorScheme(
      backgroundColor: Colors.blue.shade400.withOpacity(0.7),
      borderColor: Colors.blue.withOpacity(0.5),
      borderSize: 1,
      borderRadius: BorderRadius.circular(20),
      textColor: Colors.white,
      hintTextColor: Colors.white.withOpacity(0.8),
      titleColor: Colors.blue.shade700,
      descriptionColor: Colors.black54,
      iconColor: Colors.white,
      textBackgroundColor: Colors.blue.shade400.withOpacity(0.7),
      surfaceBackground: Colors.white.withOpacity(0.9),
      surfaceText: Colors.black87,
    ),

    titleStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),

    descriptionStyle: TextStyle(
      fontSize: 14,
      color: Colors.black54,
    ),

    hintTextStyle: TextStyle(
      fontSize: 16,
      color: Colors.black54,
    ),

    chipTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );
}
```

**Note**: For true glassmorphism effect, you'll need to add `BackdropFilter` with `ImageFilter.blur()` in a custom `layoutBuilder`. The theme above provides the visual styling.

### Example 5: Neumorphism Theme

A soft, raised appearance with subtle shadows:

```dart
FormTheme neumorphismTheme(BuildContext context) {
  const background = Color(0xFFE0E5EC);
  const textColor = Color(0xFF4A5568);

  return FormTheme(
    colorScheme: FieldColorScheme(
      backgroundColor: background,
      borderColor: background,
      borderSize: 0,
      borderRadius: BorderRadius.circular(12),
      textColor: textColor,
      hintTextColor: Color(0xFF9CA3AF),
      titleColor: textColor,
      descriptionColor: Color(0xFF6B7280),
      iconColor: Color(0xFF6366F1),
      surfaceBackground: background,
      surfaceText: textColor,
    ),

    activeColorScheme: FieldColorScheme(
      backgroundColor: background,
      borderColor: Color(0xFF6366F1).withOpacity(0.3),
      borderSize: 2,
      borderRadius: BorderRadius.circular(12),
      textColor: textColor,
      hintTextColor: Color(0xFF9CA3AF),
      titleColor: Color(0xFF6366F1),
      descriptionColor: Color(0xFF6B7280),
      iconColor: Color(0xFF6366F1),
      surfaceBackground: background,
      surfaceText: textColor,
    ),

    errorColorScheme: FieldColorScheme(
      backgroundColor: background,
      borderColor: Colors.red.shade400,
      borderSize: 2,
      borderRadius: BorderRadius.circular(12),
      textColor: textColor,
      hintTextColor: Color(0xFF9CA3AF),
      titleColor: Colors.red.shade700,
      descriptionColor: Colors.red.shade700,
      iconColor: Colors.red.shade700,
      surfaceBackground: background,
      surfaceText: textColor,
    ),

    disabledColorScheme: FieldColorScheme(
      backgroundColor: background.withOpacity(0.5),
      borderColor: background,
      borderSize: 0,
      borderRadius: BorderRadius.circular(12),
      textColor: Color(0xFF9CA3AF),
      hintTextColor: Color(0xFFD1D5DB),
      titleColor: Color(0xFF9CA3AF),
      descriptionColor: Color(0xFFD1D5DB),
      iconColor: Color(0xFF9CA3AF),
      surfaceBackground: background,
      surfaceText: textColor,
    ),

    selectedColorScheme: FieldColorScheme(
      backgroundColor: Color(0xFF6366F1),
      borderColor: Color(0xFF6366F1),
      borderSize: 0,
      borderRadius: BorderRadius.circular(10),
      textColor: Colors.white,
      hintTextColor: Colors.white.withOpacity(0.8),
      titleColor: Color(0xFF6366F1),
      descriptionColor: Color(0xFF6B7280),
      iconColor: Colors.white,
      textBackgroundColor: Color(0xFF6366F1),
      surfaceBackground: background,
      surfaceText: textColor,
    ),

    titleStyle: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),

    descriptionStyle: TextStyle(
      fontSize: 13,
      color: Color(0xFF6B7280),
    ),

    hintTextStyle: TextStyle(
      fontSize: 15,
      color: Color(0xFF9CA3AF),
    ),

    chipTextStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );
}
```

**Note**: For true neumorphism effect with soft shadows, you'll need to customize the `layoutBuilder` to add `BoxShadow` decorations. The theme above provides the color scheme.

## Theme Testing Checklist

Use this checklist to ensure your custom theme works properly across all scenarios:

### Visual States

Test that all color schemes display correctly:

- [ ] **Normal state** displays with correct colors and styling
- [ ] **Active (focused) state** is clearly visible when field is selected
- [ ] **Error state** shows clear visual feedback (red/warning colors)
- [ ] **Disabled state** appears muted and inactive
- [ ] **Selected state** works for chips, dropdowns, and multiselect options

### Text Readability

Verify all text is legible:

- [ ] **Title text** is large enough and has good contrast
- [ ] **Description text** is readable at smaller size
- [ ] **Hint text** is distinguishable from entered text
- [ ] **All text sizes** are appropriate for mobile and desktop
- [ ] **Text colors** work on their backgrounds (check contrast ratio)

### Accessibility

Ensure theme meets accessibility standards:

- [ ] **Color contrast** meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
- [ ] **Error state** doesn't rely on color alone (error messages are displayed)
- [ ] **Focus indicators** are visible for keyboard navigation
- [ ] **Text scales** with system font size settings
- [ ] **Touch targets** are large enough (minimum 44x44 points)

### Dark Mode (if supported)

If your theme supports dark mode:

- [ ] **Dark variant** exists and is implemented
- [ ] **Contrast** is maintained in dark mode
- [ ] **Colors don't burn eyes** (use dark greys, not pure black)
- [ ] **Transitions smoothly** when switching between light/dark
- [ ] **All states** work in both light and dark modes

### Cross-Platform

Test on different platforms:

- [ ] **Mobile** (iOS/Android): Touch targets are appropriately sized
- [ ] **Web**: Hover states work properly
- [ ] **Desktop** (macOS/Windows/Linux): Keyboard navigation is clear
- [ ] **Different screen sizes**: Responsive at all breakpoints

### Field Types

Verify theme works with all field types:

- [ ] **TextField**: Normal text input
- [ ] **TextArea**: Multi-line text input
- [ ] **OptionSelect**: Dropdowns and select fields
- [ ] **CheckboxSelect**: Checkbox groups
- [ ] **ChipSelect**: Chip selections
- [ ] **FileUpload**: File picker fields
- [ ] **Custom fields**: Any custom field types you've registered

### Edge Cases

Test unusual scenarios:

- [ ] **Very long text**: Titles, descriptions, and input don't break layout
- [ ] **Empty states**: Fields with no value display correctly
- [ ] **Many options**: OptionSelect with 50+ items scrolls properly
- [ ] **Multiple errors**: Multiple validation errors display clearly
- [ ] **Rapid state changes**: Quickly focusing/blurring doesn't cause flashing

## Related Documentation

- [Theming Guide](./theming-guide.md) - Theme hierarchy and application patterns
- [Form Controller API](../api/form-controller.md) - Controller theme property
- [Field Types API](../api/field-types.md) - Field-level theming
- [FieldColorScheme API](../api/field-color-scheme.md) - Color scheme properties reference
- [Accessibility Guide](../guides/accessibility.md) - WCAG compliance and best practices

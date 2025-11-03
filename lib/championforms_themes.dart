// ChampionForms - Theming & Configuration
//
// This file exports theme-related classes and the field registry.
// Typically imported once during app initialization.
//
// ## Usage:
// ```dart
// import 'package:championforms/championforms_themes.dart';
// ```
//
// Use this file to:
// - Configure global themes using `FormTheme`
// - Apply pre-built themes (`softBlueColorTheme`, `redAccentFormTheme`, `iconicColorTheme`)
// - Register custom field types using `FormFieldRegistry`

// Export theme classes
export 'package:championforms/models/themes.dart';
export 'package:championforms/models/colorscheme.dart';

// Export theme singleton for global theme configuration
export 'package:championforms/models/theme_singleton.dart';

// Export pre-built themes
export 'package:championforms/themes/soft_blue.dart';
export 'package:championforms/themes/red_accent.dart';
export 'package:championforms/themes/iconic.dart';

// Export field registry for custom field type registration
export 'package:championforms/core/field_builder_registry.dart';

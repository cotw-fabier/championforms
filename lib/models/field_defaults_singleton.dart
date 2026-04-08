// lib/models/field_defaults_singleton.dart

import 'package:flutter/widgets.dart' show SpellCheckConfiguration;

/// A singleton class to hold global defaults for form field behavior.
///
/// Unlike [FormThemeSingleton] (which holds visual theme overrides), this
/// singleton holds non-theme behavioral defaults such as native spellcheck
/// and autocorrect. Override values at app startup to change the defaults
/// app-wide:
///
/// ```dart
/// void main() {
///   FormFieldDefaults.instance
///     ..spellCheck = false
///     ..autocorrect = false; // restore pre-X.Y.Z behavior
///   runApp(MyApp());
/// }
/// ```
///
/// Field-level values on individual [TextField]s always take precedence
/// over these globals. The resolution order is:
///
///   1. Field-level explicit value (e.g. `TextField(spellCheck: false)`)
///   2. Global singleton value (e.g. `FormFieldDefaults.instance.spellCheck`)
///   3. Package hard-coded default (`true`)
///
/// The class is intentionally open to future additions — any new
/// "sensible default" field-behavior flag should be added here rather
/// than forcing consumers to set the value on every field.
class FormFieldDefaults {
  // --- Singleton Setup ---
  static final FormFieldDefaults _instance = FormFieldDefaults._internal();

  factory FormFieldDefaults() {
    return _instance;
  }

  FormFieldDefaults._internal();

  static FormFieldDefaults get instance => _instance;

  // --- Behavior Defaults ---

  /// Default for [TextField.spellCheck] when a field doesn't specify a value.
  ///
  /// Controls the passive red-squiggly underline on misspelled words
  /// (tap/long-press to get suggestions) on iOS and Android.
  ///
  /// Package default: `true`.
  bool spellCheck = true;

  /// Default for [TextField.autocorrect] when a field doesn't specify a value.
  ///
  /// Controls active text rewriting as the user types (e.g. "teh" → "the")
  /// on iOS and Android. Independent from [spellCheck].
  ///
  /// Package default: `true`.
  bool autocorrect = true;

  /// Default for [TextField.spellCheckConfiguration] when a field doesn't
  /// specify one.
  ///
  /// This is the advanced escape hatch for passing a custom spellcheck
  /// service or styling directly to the underlying Material `TextField`
  /// app-wide. When `null` (the package default), the widget layer
  /// auto-builds a `const SpellCheckConfiguration()` based on the resolved
  /// [spellCheck] flag and platform support.
  ///
  /// Field-level [TextField.spellCheckConfiguration] always wins over this
  /// global. Note that an explicit configuration (field-level or global)
  /// only overrides the spellcheck-underline behavior — the [autocorrect]
  /// flag is still resolved independently.
  ///
  /// Package default: `null`.
  SpellCheckConfiguration? spellCheckConfiguration;

  /// Resets all behavior defaults to the package baselines.
  void reset() {
    spellCheck = true;
    autocorrect = true;
    spellCheckConfiguration = null;
  }
}

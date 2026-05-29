// lib/models/field_defaults_singleton.dart

import 'package:flutter/services.dart' show TextCapitalization;
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

  /// Default for [TextField.animateInteractions] when a field doesn't
  /// specify a value.
  ///
  /// Controls a gentle lift-and-scale micro-interaction when the field
  /// gains focus: roughly a 1px upward translation and a 0.8% scale-up,
  /// reversed when focus is lost. Tuned to be perceptible but never
  /// distracting — no bounce, no elastic, exponential ease-out.
  ///
  /// Set to `false` to disable for the whole app (e.g. for accessibility,
  /// reduced-motion preferences, or stylistic reasons):
  ///
  /// ```dart
  /// FormFieldDefaults.instance.animateInteractions = false;
  /// ```
  ///
  /// Package default: `true`.
  bool animateInteractions = true;

  /// Default for [TextField.textCapitalization] when a field doesn't specify
  /// a value.
  ///
  /// Controls how the on-screen keyboard auto-capitalizes typed text on
  /// mobile (sentences, words, characters, or none). Flutter's own
  /// `TextField` default is [TextCapitalization.none], which is why fields
  /// feel "un-native" — native iOS/Android text fields auto-capitalize the
  /// first letter of each sentence. We default to
  /// [TextCapitalization.sentences] to match that native behavior.
  ///
  /// Semantic constructors that shouldn't capitalize ([TextField.email],
  /// [TextField.url], [TextField.username], [TextField.password]) override
  /// this with [TextCapitalization.none] explicitly.
  ///
  /// Package default: [TextCapitalization.sentences].
  TextCapitalization textCapitalization = TextCapitalization.sentences;

  /// Resets all behavior defaults to the package baselines.
  void reset() {
    spellCheck = true;
    autocorrect = true;
    spellCheckConfiguration = null;
    animateInteractions = true;
    textCapitalization = TextCapitalization.sentences;
  }
}

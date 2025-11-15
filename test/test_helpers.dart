import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';

/// Test utilities for creating FieldBuilderContext instances in tests.
///
/// This helper simplifies test setup by providing a convenient way to create
/// FieldBuilderContext instances without manually specifying all parameters.

/// Creates a FieldBuilderContext for testing purposes.
///
/// Parameters:
/// - [controller]: The FormController (required)
/// - [field]: The Field being tested (required)
/// - [theme]: Optional theme override (defaults to FormTheme.defaultTheme)
/// - [state]: Optional field state (defaults to FieldState.normal)
///
/// Example:
/// ```dart
/// final ctx = createTestContext(
///   controller: controller,
///   field: textField,
/// );
/// final widget = MyCustomWidget(context: ctx);
/// ```
FieldBuilderContext createTestContext({
  required form.FormController controller,
  required form.Field field,
  FormTheme? theme,
  FieldState? state,
}) {
  final resolvedTheme = theme ?? const FormTheme();
  final resolvedState = state ?? FieldState.normal;

  // Determine color scheme based on state
  final colors = _getColorsForState(resolvedTheme, resolvedState);

  return FieldBuilderContext(
    controller: controller,
    field: field,
    theme: resolvedTheme,
    state: resolvedState,
    colors: colors,
  );
}

/// Gets the appropriate FieldColorScheme for a given state.
FieldColorScheme _getColorsForState(FormTheme theme, FieldState state) {
  const defaultColors = FieldColorScheme();

  switch (state) {
    case FieldState.normal:
      return theme.colorScheme ?? defaultColors;
    case FieldState.active:
      return theme.activeColorScheme ?? theme.colorScheme ?? defaultColors;
    case FieldState.error:
      return theme.errorColorScheme ?? theme.colorScheme ?? defaultColors;
    case FieldState.disabled:
      return theme.disabledColorScheme ?? theme.colorScheme ?? defaultColors;
  }
}

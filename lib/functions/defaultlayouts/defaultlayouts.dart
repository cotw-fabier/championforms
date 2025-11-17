import 'package:championforms/widgets_external/field_layouts/simple_layout.dart';
import 'package:championforms/widgets_external/field_layouts/simple_description_below_layout.dart';

/// A collection of default field layout functions.
///
/// Field layouts are functions that arrange the field components (title, description,
/// rendered field widget, and errors) into a specific visual structure.
///
/// All layout functions share the same signature:
/// ```dart
/// Widget layoutFunction(
///   BuildContext context,
///   Field fieldDetails,
///   FormController controller,
///   FieldColorScheme currentColors,
///   Widget renderedField,
/// )
/// ```
///
/// ## Usage
///
/// Layout functions can be assigned to individual fields or used as defaults:
///
/// ```dart
/// // Use on a specific field
/// form.TextField(
///   id: "email",
///   title: "Email Address",
///   description: "We'll never share your email",
///   fieldLayout: form.FieldLayouts.simpleDescriptionBelow,
/// )
///
/// // Use as default for all fields in a Field class
/// Field.fieldLayout = form.FieldLayouts.simple;
/// ```
///
/// ## Available Layouts
///
/// - **simple**: Standard layout with title → description → field → errors
/// - **simpleDescriptionBelow**: Alternative layout with title → field → description → errors
class FieldLayouts {
  /// **Standard field layout with description above the field.**
  ///
  /// Visual structure:
  /// 1. Title (if provided)
  /// 2. Description (if provided)
  /// 3. Rendered field widget
  /// 4. Validation errors (if any)
  ///
  /// This is the default layout used by ChampionForms.
  static const simple = fieldSimpleLayout;

  /// **Alternative field layout with description below the field.**
  ///
  /// Visual structure:
  /// 1. Title (if provided)
  /// 2. Rendered field widget
  /// 3. Description (if provided)
  /// 4. Validation errors (if any)
  ///
  /// Use this layout when you want the description to appear closer to validation
  /// errors or when the description provides additional context after seeing the field.
  static const simpleDescriptionBelow = fieldSimpleDescriptionBelowLayout;
}

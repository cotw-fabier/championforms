/// Emphasis/role for a field's color palette, independent of its runtime state.
///
/// [normal] follows the theme's normal palette. [destructive] renders the field
/// in the error palette while it is empty and unfocused, to draw attention to a
/// required or dangerous field before the user interacts with it. Left
/// intentionally extensible (future success/warning roles).
enum FieldColors {
  normal,
  destructive,
}

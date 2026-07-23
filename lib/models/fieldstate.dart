/// The runtime state a field can be in, used to select the visual palette.
enum FieldState {
  normal,
  disabled,
  active,
  error,

  /// A resting field emphasized with the error (destructive) palette.
  ///
  /// Visually identical to [error] but semantically distinct: it is a
  /// deliberate emphasis role (see `FieldColors.destructive`), not the result
  /// of a failed validation. Validation "wiggle" keys on the real [error]
  /// state only, so it does not fire for a field sitting in [destructive].
  destructive,
}

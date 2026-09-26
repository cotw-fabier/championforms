import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/foundation.dart';

/// The palette [theme] uses for a field in [state].
///
/// The single place the state → palette mapping lives: the per-field and
/// compound-field render paths both go through it. [theme] must be a
/// resolved theme (every color scheme set), as produced by
/// `FormTheme.withDefaults`.
FieldColorScheme colorsForFieldState(FormTheme theme, FieldState state) {
  switch (state) {
    case FieldState.error:
      return theme.errorColorScheme!;
    case FieldState.disabled:
      return theme.disabledColorScheme!;
    case FieldState.active:
      return theme.activeColorScheme!;
    case FieldState.destructive:
      // Deliberate emphasis: drawn in the error palette while empty and
      // unfocused (see FieldColors.destructive).
      return theme.errorColorScheme!;
    case FieldState.normal:
      return theme.colorScheme!;
  }
}

/// Generates a prefixed sub-field ID following the pattern
/// `{compoundId}_{subFieldId}`, leaving an already-prefixed id alone.
String prefixSubFieldId(String compoundId, String subFieldId) {
  if (subFieldId.startsWith('${compoundId}_')) {
    return subFieldId;
  }
  return '${compoundId}_$subFieldId';
}

/// Expands [compoundField] into the sub-fields the controller holds.
///
/// Each sub-field gets its prefixed id, the compound's theme (unless it has
/// its own) and the compound's disabled state, applied through the
/// sub-field's `copyWith`. Returns an empty list, with a debug warning, when
/// the compound type was never registered.
List<Field> expandCompoundField(CompoundField compoundField) {
  final registration = FormFieldRegistry.instance
      .getCompoundRegistrationByType(compoundField.runtimeType);

  if (registration == null) {
    debugPrint(
      'Warning: No registration found for compound field type '
      '${compoundField.runtimeType}. Treating as empty field.',
    );
    return [];
  }

  return [
    for (final subField in registration.subFieldsBuilder(compoundField))
      subField.copyWith(
        id: prefixSubFieldId(compoundField.id, subField.id),
        theme: subField.theme ?? compoundField.theme,
        disabled: compoundField.disabled || subField.disabled,
      ),
  ];
}

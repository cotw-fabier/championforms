import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart' show FieldColorScheme;
import 'package:flutter/widgets.dart';

/// A value derived from a document by an extract rule, registered on the
/// controller as `{docId}.{key}`.
///
/// It is never drawn (its registered builder is an empty box) and has no
/// validators: it exists so extracted values show up in `FormResults`
/// (`results.grab('agreement.people')`) and can drive `FieldCondition`s on
/// other fields. The document field keeps its value up to date.
///
/// It inherits the document's `hideField`, `conditional` and `disabled`, so
/// a hidden document takes its derived values out of the results with it.
class DerivedField extends form.Field {
  DerivedField({
    required super.id,
    required this.documentId,
    this.key = '',
    super.disabled,
    super.hideField,
    super.conditional,
  });

  /// The DocumentField this value is derived from.
  final String documentId;

  /// The extract rule key.
  final String key;

  @override
  Object? get defaultValue => null;

  static String _text(dynamic value) => switch (value) {
    null => '',
    final Iterable<Object?> list => list.map((e) => '$e').join(', '),
    _ => '$value',
  };

  @override
  String Function(dynamic value) get asStringConverter => _text;

  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (value) => switch (value) {
        null => const [],
        final Iterable<Object?> list => [for (final e in list) '$e'],
        _ => ['$value'],
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) => switch (value) {
    null => false,
    final bool b => b,
    final String s => s.trim().isNotEmpty,
    final Iterable<Object?> l => l.isNotEmpty,
    final Map<Object?, Object?> m => m.isNotEmpty,
    _ => true,
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter =>
      null;

  @override
  DerivedField copyWith({
    String? id,
    String? documentId,
    String? key,
    Widget? icon,
    form.FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    form.FieldCondition? conditional,
    bool? requestFocus,
    List<form.Validator>? validators,
    bool? validateLive,
    Function(form.FormResults results)? onSubmit,
    Function(form.FormResults results)? onChange,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )?
    fieldLayout,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )?
    fieldBackground,
  }) => DerivedField(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    key: key ?? this.key,
    disabled: disabled ?? this.disabled,
    hideField: hideField ?? this.hideField,
    conditional: conditional ?? this.conditional,
  );
}

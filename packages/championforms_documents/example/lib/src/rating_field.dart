import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

/// A small custom field: a row of stars holding an `int`.
///
/// It is registered with a `fromJson` factory and a clipboard codec, which is
/// all a field type needs to become a document block: the `/` menu builds it
/// from JSON (`{"type": "rating", "maxStars": 5}`), and copying the block
/// carries its value to another document.
class RatingField extends form.Field {
  RatingField({
    required super.id,
    super.title,
    super.description,
    super.disabled,
    super.hideField,
    super.conditional,
    super.requestFocus,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    super.theme,
    super.icon,
    super.fieldLayout,
    super.fieldBackground,
    super.colors,
    super.animateValidationErrors,
    super.clipboard,
    this.maxStars = 5,
    this.defaultValue,
  });

  /// Number of stars.
  final int maxStars;

  @override
  final int? defaultValue;

  /// Builds a rating from `{"type": "rating", "id", "title", "maxStars"}`.
  factory RatingField.fromJson(Map<String, dynamic> json) => RatingField(
    id: form.FieldJson.id(json),
    title: form.FieldJson.string(json, 'title'),
    description: form.FieldJson.string(json, 'description'),
    disabled: form.FieldJson.boolean(json, 'disabled'),
    hideField: form.FieldJson.boolean(json, 'hideField'),
    maxStars: (form.FieldJson.integer(json, 'maxStars') ?? 5).clamp(1, 10),
    defaultValue: form.FieldJson.integer(json, 'defaultValue'),
    conditional: form.FieldJson.conditional(json),
  );

  @override
  RatingField copyWith({
    String? id,
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
    FormTheme? theme,
    Widget? icon,
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
    form.FieldColors? colors,
    bool? animateValidationErrors,
    form.FieldClipboardCodec? clipboard,
    int? maxStars,
    int? defaultValue,
  }) => RatingField(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    disabled: disabled ?? this.disabled,
    hideField: hideField ?? this.hideField,
    conditional: conditional ?? this.conditional,
    requestFocus: requestFocus ?? this.requestFocus,
    validators: validators ?? this.validators,
    validateLive: validateLive ?? this.validateLive,
    onSubmit: onSubmit ?? this.onSubmit,
    onChange: onChange ?? this.onChange,
    theme: theme ?? this.theme,
    icon: icon ?? this.icon,
    fieldLayout: fieldLayout ?? this.fieldLayout,
    fieldBackground: fieldBackground ?? this.fieldBackground,
    colors: colors ?? this.colors,
    animateValidationErrors:
        animateValidationErrors ?? this.animateValidationErrors,
    clipboard: clipboard ?? this.clipboard,
    maxStars: maxStars ?? this.maxStars,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  static int _stars(dynamic value) => value is int ? value : 0;

  @override
  String Function(dynamic value) get asStringConverter =>
      (value) => '${_stars(value)}/$maxStars';

  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (value) => ['${_stars(value)}'];

  @override
  bool Function(dynamic value) get asBoolConverter =>
      (value) => _stars(value) > 0;

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter =>
      null;
}

/// Copies a rating as stars for other apps and as `{"value": n}` for
/// ChampionForms.
class RatingClipboardCodec extends form.FieldClipboardCodec {
  const RatingClipboardCodec();

  @override
  form.ClipboardFragment? copy(form.Field field, dynamic value) {
    final max = field is RatingField ? field.maxStars : 5;
    final stars = value is int ? value.clamp(0, max) : 0;
    final text = '${'★' * stars}${'☆' * (max - stars)} ($stars/$max)';
    return form.ClipboardFragment(
      plainText: text,
      html: '<span>$text</span>',
      data: {'type': 'rating', 'value': stars},
    );
  }

  @override
  dynamic paste(Map<String, dynamic> data) {
    final value = data['value'];
    return value is int && value >= 0 && value <= 10 ? value : null;
  }
}

class RatingFieldWidget extends form.StatefulFieldWidget {
  const RatingFieldWidget({required super.context, super.key});

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final field = ctx.field as RatingField;
    final current = ctx.getValue<int>() ?? field.defaultValue ?? 0;
    final color = field.disabled
        ? Theme.of(context).disabledColor
        : Colors.amber.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= field.maxStars; i++)
          IconButton(
            key: ValueKey('${field.id}-star-$i'),
            visualDensity: VisualDensity.compact,
            tooltip: '$i of ${field.maxStars}',
            onPressed: field.disabled
                ? null
                : () => ctx.setValue(i == current ? 0 : i),
            icon: Icon(
              i <= current ? Icons.star_rounded : Icons.star_outline_rounded,
              color: color,
            ),
          ),
      ],
    );
  }
}

bool _registered = false;

/// Registers the `rating` field type (builder, JSON factory and clipboard
/// codec). Idempotent.
void registerRatingField() {
  if (_registered) return;
  _registered = true;
  form.FormFieldRegistry.ensureInitialized();
  form.FormFieldRegistry.register<RatingField>(
    'rating',
    (ctx) => RatingFieldWidget(context: ctx),
    fromJson: RatingField.fromJson,
    clipboard: const RatingClipboardCodec(),
  );
}

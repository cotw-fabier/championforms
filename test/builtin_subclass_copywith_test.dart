import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A subclass of a built-in field (not of `Field` directly), written with the
/// 0.8.0 migration guidance: its `copyWith` override declares
/// `FieldClipboardCodec? clipboard` and forwards it.
///
/// This file compiling is half the test. An override that leaves `clipboard`
/// out is an `invalid_override` error, because `CheckboxSelect.copyWith`
/// declares it.
class TaggedCheckboxSelect extends form.CheckboxSelect {
  TaggedCheckboxSelect({
    required super.id,
    required super.options,
    super.multiselect,
    super.title,
    super.colors,
    super.animateValidationErrors,
    super.clipboard,
    this.tag = '',
  });

  final String tag;

  @override
  TaggedCheckboxSelect copyWith({
    String? id,
    Widget? icon,
    List<form.FieldOption>? options,
    bool? multiselect,
    Widget? leading,
    Widget? trailing,
    FormTheme? theme,
    form.FieldColors? colors,
    bool? animateValidationErrors,
    form.FieldClipboardCodec? clipboard, // new in 0.8.0
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    form.FieldCondition? conditional,
    bool? requestFocus,
    List<form.FieldOption>? defaultValue,
    bool? caseSensitiveDefaultValue,
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
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    Widget Function(form.FieldBuilderContext)? fieldBuilder,
    String? tag,
  }) {
    return TaggedCheckboxSelect(
      id: id ?? this.id,
      options: options ?? this.options,
      multiselect: multiselect ?? this.multiselect,
      title: title ?? this.title,
      colors: colors ?? this.colors,
      animateValidationErrors:
          animateValidationErrors ?? this.animateValidationErrors,
      clipboard: clipboard ?? this.clipboard,
      tag: tag ?? this.tag,
    );
  }
}

class _MarkerCodec extends form.FieldClipboardCodec {
  const _MarkerCodec(this.name);
  final String name;

  @override
  form.ClipboardFragment? copy(form.Field field, dynamic value) =>
      form.ClipboardFragment(plainText: name, data: {'type': name});

  @override
  dynamic paste(Map<String, dynamic> data) => null;
}

void main() {
  final options = [
    form.FieldOption(value: 'a', label: 'A'),
    form.FieldOption(value: 'b', label: 'B'),
  ];

  test('a built-in subclass keeps its clipboard codec across copyWith', () {
    const codec = _MarkerCodec('original');
    final field = TaggedCheckboxSelect(
      id: 'tags',
      options: options,
      clipboard: codec,
      tag: 'x',
    );

    final copy = field.copyWith(id: 'prefixed_tags');
    expect(copy, isA<TaggedCheckboxSelect>());
    expect(copy.id, 'prefixed_tags');
    expect(copy.tag, 'x');
    expect(copy.clipboard, same(codec));
    expect(form.FormFieldRegistry.resolveClipboard(copy), same(codec));
  });

  test('copyWith(clipboard:) replaces the codec', () {
    const replacement = _MarkerCodec('replacement');
    final field = TaggedCheckboxSelect(
      id: 'tags',
      options: options,
      clipboard: const _MarkerCodec('original'),
    );

    final copy = field.copyWith(clipboard: replacement);
    expect(copy.clipboard, same(replacement));
    expect(copy.options, options);
  });

  test('called through the Field type, copyWith still forwards clipboard', () {
    const codec = _MarkerCodec('original');
    final form.Field field = TaggedCheckboxSelect(
      id: 'tags',
      options: options,
      clipboard: codec,
    );
    // The abstract signature has no `clipboard`; the codec survives anyway.
    final copy = field.copyWith(title: 'Tags');
    expect(copy.clipboard, same(codec));
    expect(copy.title, 'Tags');
  });
}

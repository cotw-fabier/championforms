import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart' show FieldColorScheme;
import 'package:flutter/widgets.dart';

import '../clipboard/doc_clipboard_delegate.dart';
import '../editor/slash_menu.dart';
import '../model/doc_node.dart';
import '../model/doc_plain_text.dart';
import '../model/doc_snapshot.dart';
import '../rules/engine.dart';
import '../rules/rule.dart';
import '../rules/rule_set.dart';
import 'registration.dart';

/// A rich document as a form field.
///
/// Its value in the `FormController` is a [DocSnapshot]. The document can
/// embed live ChampionForms fields (`/` menu → Text input, Checkbox, Select,
/// File upload, or any [blockTemplates]), each registered on the same
/// controller as `{id}.field.{nodeId}`, and its [ruleSet] drives editing
/// (transform rules), derived values (extract rules → fields
/// `{id}.{key}`) and validation (required extracts and constraint rules).
///
/// ```dart
/// form.Form(
///   controller: controller,
///   fields: [
///     form.TextField(id: 'title', title: 'Title'),
///     DocumentField(
///       id: 'agreement',
///       title: 'Agreement',
///       placeholder: 'Type / for blocks',
///       ruleSet: RuleSet(
///         extracts: [MentionsExtract(key: 'people', required: true)],
///       ),
///     ),
///   ],
/// );
///
/// // Later:
/// DocumentFields.flushAll(controller); // push any pending keystrokes
/// final results = form.FormResults.getResults(controller: controller);
/// final doc = results.grab('agreement').asDocument();
/// final people = results.extracted('agreement')['people'];
/// ```
///
/// Constructing a `DocumentField` registers the field type (see
/// [DocumentFields.ensureInitialized]), so no extra setup is needed for a
/// hand-written form; call it yourself before decoding forms from JSON.
class DocumentField extends form.Field {
  DocumentField({
    required super.id,
    this.ruleSet = RuleSet.empty,
    this.initialDocument,
    this.blockTemplates = const [],
    this.includeDefaultFieldBlocks = true,
    this.placeholder,
    this.minHeight = 120,
    this.clipboardDelegate,
    this.readOnly = false,
    super.icon,
    super.theme,
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
    super.fieldLayout,
    super.fieldBackground,
    super.colors,
    super.animateValidationErrors,
    super.clipboard,
  }) : defaultValue = initialDocument ?? _emptyDocument {
    DocumentFields.ensureInitialized();
  }

  /// A document with one empty paragraph. Its node id is fixed so that the
  /// default value compares equal across `copyWith`s.
  static final DocSnapshot _emptyDocument = DocSnapshot([
    const ParagraphNode(id: 'initial'),
  ]);

  /// Transform, extract and constraint rules. A rule set without transforms
  /// edits with [DocumentRules.defaultTransforms].
  final RuleSet ruleSet;

  /// The document a fresh field starts with (defaults to one empty
  /// paragraph). This is the field's [defaultValue].
  final DocSnapshot? initialDocument;

  /// Field blocks the `/` menu offers in addition to the built-in ones.
  final List<DocumentBlockTemplate> blockTemplates;

  /// Whether the `/` menu offers the built-in Text input, Checkbox, Select
  /// and File upload blocks.
  final bool includeDefaultFieldBlocks;

  /// Hint shown while the document is empty.
  final String? placeholder;

  /// Minimum editor height in logical pixels.
  final double minHeight;

  /// Copy / cut / paste handling. Null keeps super_editor's plain-text
  /// behavior. (Named so to stay clear of [form.Field.clipboard], which is
  /// the codec for copying the whole field's value.)
  final DocClipboardDelegate? clipboardDelegate;

  /// Shows the document without letting its text be edited. Embedded
  /// fields stay fillable (unless [disabled]), which is how a fixed template
  /// with blanks is built.
  final bool readOnly;

  /// The validators passed to the constructor, without the internal rule
  /// validator (see [validators]).
  List<form.Validator>? get userValidators => super.validators;

  @override
  final DocSnapshot defaultValue;

  late final _DocumentEvaluator _evaluator = _DocumentEvaluator(ruleSet);

  late final DocumentIssuesValidator _issuesValidator = DocumentIssuesValidator(
    this,
  );

  /// [userValidators] followed by a [DocumentIssuesValidator] that fails
  /// with the rule set's issues (required extracts and constraints), so
  /// `getResults`, `errorState` and `validateLive` all see them.
  @override
  List<form.Validator> get validators => [
    ...?userValidators,
    _issuesValidator,
  ];

  /// Runs [ruleSet]'s extract and constraint rules against [doc]. The last
  /// result is cached, so the validator and the derived fields share one
  /// evaluation per snapshot.
  ExtractionResult evaluateDocument(DocSnapshot doc) => _evaluator.run(doc);

  /// [value] as a document: a [DocSnapshot], or one decoded from its JSON
  /// map; null otherwise.
  static DocSnapshot? coerce(Object? value) {
    if (value is DocSnapshot) return value;
    if (value is Map) {
      try {
        return DocSnapshot.fromJson(value.cast<String, dynamic>());
      } on FormatException {
        return null;
      } on TypeError {
        return null;
      }
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Converters
  // -------------------------------------------------------------------------

  @override
  String Function(dynamic value) get asStringConverter =>
      (value) => toPlainText(coerce(value) ?? defaultValue);

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) => [
    for (final n in (coerce(value) ?? defaultValue).nodes)
      if (n is TextDocNode) n.text.text,
  ];

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
    final doc = coerce(value) ?? defaultValue;
    return doc.nodes.any(
      (n) => n is! TextDocNode || n.text.text.trim().isNotEmpty,
    );
  };

  @override
  List<form.FileModel>? Function(dynamic value)? get asFileListConverter =>
      null;

  // -------------------------------------------------------------------------
  // copyWith / JSON
  // -------------------------------------------------------------------------

  @override
  DocumentField copyWith({
    String? id,
    RuleSet? ruleSet,
    DocSnapshot? initialDocument,
    List<DocumentBlockTemplate>? blockTemplates,
    bool? includeDefaultFieldBlocks,
    String? placeholder,
    double? minHeight,
    DocClipboardDelegate? clipboardDelegate,
    bool? readOnly,
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
    form.FieldColors? colors,
    bool? animateValidationErrors,
    form.FieldClipboardCodec? clipboard,
  }) => DocumentField(
    id: id ?? this.id,
    ruleSet: ruleSet ?? this.ruleSet,
    initialDocument: initialDocument ?? this.initialDocument,
    blockTemplates: blockTemplates ?? this.blockTemplates,
    includeDefaultFieldBlocks:
        includeDefaultFieldBlocks ?? this.includeDefaultFieldBlocks,
    placeholder: placeholder ?? this.placeholder,
    minHeight: minHeight ?? this.minHeight,
    clipboardDelegate: clipboardDelegate ?? this.clipboardDelegate,
    readOnly: readOnly ?? this.readOnly,
    icon: icon ?? this.icon,
    theme: theme ?? this.theme,
    title: title ?? this.title,
    description: description ?? this.description,
    disabled: disabled ?? this.disabled,
    hideField: hideField ?? this.hideField,
    conditional: conditional ?? this.conditional,
    requestFocus: requestFocus ?? this.requestFocus,
    validators: validators ?? userValidators,
    validateLive: validateLive ?? this.validateLive,
    onSubmit: onSubmit ?? this.onSubmit,
    onChange: onChange ?? this.onChange,
    fieldLayout: fieldLayout ?? this.fieldLayout,
    fieldBackground: fieldBackground ?? this.fieldBackground,
    colors: colors ?? this.colors,
    animateValidationErrors:
        animateValidationErrors ?? this.animateValidationErrors,
    clipboard: clipboard ?? this.clipboard,
  );

  /// Builds a DocumentField from JSON (registered as type `"document"`):
  ///
  /// ```json
  /// {
  ///   "type": "document",
  ///   "id": "agreement",
  ///   "title": "Agreement",
  ///   "placeholder": "Type / for blocks",
  ///   "minHeight": 200,
  ///   "readOnly": false,
  ///   "ruleSet": {"transforms": [], "extracts": [], "constraints": []},
  ///   "initialDocument": {"schemaVersion": 1, "nodes": []},
  ///   "blocks": [{"label": "Rating", "field": {"type": "rating"}}]
  /// }
  /// ```
  ///
  /// Plus the common keys every field reads (`description`, `disabled`,
  /// `hideField`, `requestFocus`, `validateLive`, `validators`,
  /// `conditional`). `blocks` become [blockTemplates] (no icon). Throws
  /// [FormatException] for a malformed rule set or document.
  factory DocumentField.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is! Map) {
        throw FormatException(
          'Field "${json['id']}": "$key" must be an object; got '
          '${raw.runtimeType}.',
        );
      }
      return raw.cast<String, dynamic>();
    }

    final ruleSetJson = map('ruleSet');
    final documentJson = map('initialDocument');
    final minHeight = json['minHeight'];
    if (minHeight != null && minHeight is! num) {
      throw FormatException(
        'Field "${json['id']}": "minHeight" must be a number.',
      );
    }
    final blocks = json['blocks'];
    if (blocks != null && blocks is! List) {
      throw FormatException('Field "${json['id']}": "blocks" must be a list.');
    }
    return DocumentField(
      id: form.FieldJson.id(json),
      title: form.FieldJson.string(json, 'title'),
      description: form.FieldJson.string(json, 'description'),
      placeholder: form.FieldJson.string(json, 'placeholder'),
      minHeight: (minHeight as num?)?.toDouble() ?? 120,
      readOnly: form.FieldJson.boolean(json, 'readOnly'),
      disabled: form.FieldJson.boolean(json, 'disabled'),
      hideField: form.FieldJson.boolean(json, 'hideField'),
      requestFocus: form.FieldJson.boolean(json, 'requestFocus'),
      validateLive: form.FieldJson.boolean(json, 'validateLive'),
      validators: form.FieldJson.validators(json),
      conditional: form.FieldJson.conditional(json),
      ruleSet: ruleSetJson == null
          ? RuleSet.empty
          : RuleSet.fromJson(ruleSetJson),
      initialDocument: documentJson == null
          ? null
          : DocSnapshot.fromJson(documentJson),
      blockTemplates: [
        for (final b in (blocks as List?) ?? const [])
          if (b is Map && b['label'] is String && b['field'] is Map)
            DocumentBlockTemplate(
              label: b['label'] as String,
              fieldJson: () =>
                  Map<String, dynamic>.from(b['field'] as Map),
            ),
      ],
    );
  }
}

/// One-entry cache of [evaluate] keyed by snapshot identity.
class _DocumentEvaluator {
  _DocumentEvaluator(this.ruleSet);

  final RuleSet ruleSet;
  DocSnapshot? _doc;
  ExtractionResult? _result;

  ExtractionResult run(DocSnapshot doc) {
    if (identical(doc, _doc) && _result != null) return _result!;
    _doc = doc;
    return _result = evaluate(doc, ruleSet);
  }
}

/// The validator a [DocumentField] adds for its rule set: it evaluates the
/// document it is given and fails when there are issues. Its [reason] is
/// the issues' messages, one per line, from the last evaluation.
class DocumentIssuesValidator extends form.Validator {
  DocumentIssuesValidator(this.field) : super(validator: _unused, reason: '');

  static bool _unused(dynamic _) => true;

  final DocumentField field;

  /// The issues found by the last run.
  List<DocIssue> lastIssues = const [];

  @override
  bool Function(dynamic value) get validator => (value) {
    final doc = DocumentField.coerce(value) ?? field.defaultValue;
    lastIssues = field.evaluateDocument(doc).issues;
    return lastIssues.isEmpty;
  };

  @override
  String get reason => lastIssues.map((i) => i.message).join('\n');
}

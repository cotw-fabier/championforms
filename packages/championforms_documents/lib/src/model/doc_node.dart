import 'package:collection/collection.dart';

import 'doc_text.dart';

/// One block of a document. Immutable; identified by a stable [id] (uuid v4)
/// that survives edits, reorders and save/load.
///
/// The hierarchy is sealed so `switch` over node kinds is exhaustive. Adding
/// a node kind is a schema change: bump [DocSnapshot.currentSchemaVersion].
sealed class DocNode {
  const DocNode(this.id);

  final String id;

  /// Wire name, used as `"type"` in JSON.
  String get type;

  Map<String, dynamic> toJson();

  /// Throws [FormatException] for an unknown type or wrong shape.
  static DocNode fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw FormatException('Node needs a non-empty "id": $json');
    }
    DocText text() => DocText.fromJson(
        ((json['content'] as Map?) ?? const {'text': ''}).cast<String, dynamic>());
    return switch (json['type']) {
      'paragraph' => ParagraphNode(id: id, text: text()),
      'heading' => HeadingNode(
          id: id, level: _int(json, 'level', 1, min: 1, max: 6), text: text()),
      'listItem' => ListItemNode(
          id: id,
          ordered: json['ordered'] == true,
          indent: _int(json, 'indent', 0, min: 0, max: 8),
          text: text()),
      'task' => TaskNode(id: id, checked: json['checked'] == true, text: text()),
      'quote' => QuoteNode(id: id, text: text()),
      'divider' => DividerNode(id: id),
      'embeddedField' => EmbeddedFieldNode(
          id: id,
          fieldJson: switch (json['field']) {
            final Map m => m.cast<String, dynamic>(),
            _ => throw FormatException('embeddedField needs "field": $json'),
          },
          sourceId: json['sourceId'] as String?,
        ),
      final t => throw FormatException('Unknown node type "$t"'),
    };
  }

  static int _int(Map<String, dynamic> json, String key, int fallback,
      {required int min, required int max}) {
    final v = json[key] ?? fallback;
    if (v is! int || v < min || v > max) {
      throw FormatException('"$key" must be an int in [$min, $max]: $json');
    }
    return v;
  }
}

/// A node whose content is inline text.
sealed class TextDocNode extends DocNode {
  const TextDocNode(super.id, this.text);

  final DocText text;

  /// A copy with different text (same id and other properties).
  TextDocNode withText(DocText text);

  Map<String, dynamic> _base() => {'id': id, 'type': type, 'content': text.toJson()};
}

final class ParagraphNode extends TextDocNode {
  const ParagraphNode({required String id, DocText text = DocText.empty})
      : super(id, text);

  @override
  String get type => 'paragraph';

  @override
  ParagraphNode withText(DocText text) => ParagraphNode(id: id, text: text);

  @override
  Map<String, dynamic> toJson() => _base();

  @override
  bool operator ==(Object other) =>
      other is ParagraphNode && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(type, id, text);
}

final class HeadingNode extends TextDocNode {
  const HeadingNode(
      {required String id, this.level = 1, DocText text = DocText.empty})
      : assert(level >= 1 && level <= 6),
        super(id, text);

  final int level;

  @override
  String get type => 'heading';

  @override
  HeadingNode withText(DocText text) =>
      HeadingNode(id: id, level: level, text: text);

  @override
  Map<String, dynamic> toJson() => {..._base(), 'level': level};

  @override
  bool operator ==(Object other) =>
      other is HeadingNode &&
      other.id == id &&
      other.level == level &&
      other.text == text;

  @override
  int get hashCode => Object.hash(type, id, level, text);
}

final class ListItemNode extends TextDocNode {
  const ListItemNode({
    required String id,
    this.ordered = false,
    this.indent = 0,
    DocText text = DocText.empty,
  }) : super(id, text);

  final bool ordered;
  final int indent;

  @override
  String get type => 'listItem';

  @override
  ListItemNode withText(DocText text) =>
      ListItemNode(id: id, ordered: ordered, indent: indent, text: text);

  @override
  Map<String, dynamic> toJson() =>
      {..._base(), 'ordered': ordered, 'indent': indent};

  @override
  bool operator ==(Object other) =>
      other is ListItemNode &&
      other.id == id &&
      other.ordered == ordered &&
      other.indent == indent &&
      other.text == text;

  @override
  int get hashCode => Object.hash(type, id, ordered, indent, text);
}

final class TaskNode extends TextDocNode {
  const TaskNode(
      {required String id, this.checked = false, DocText text = DocText.empty})
      : super(id, text);

  final bool checked;

  @override
  String get type => 'task';

  @override
  TaskNode withText(DocText text) =>
      TaskNode(id: id, checked: checked, text: text);

  @override
  Map<String, dynamic> toJson() => {..._base(), 'checked': checked};

  @override
  bool operator ==(Object other) =>
      other is TaskNode &&
      other.id == id &&
      other.checked == checked &&
      other.text == text;

  @override
  int get hashCode => Object.hash(type, id, checked, text);
}

final class QuoteNode extends TextDocNode {
  const QuoteNode({required String id, DocText text = DocText.empty})
      : super(id, text);

  @override
  String get type => 'quote';

  @override
  QuoteNode withText(DocText text) => QuoteNode(id: id, text: text);

  @override
  Map<String, dynamic> toJson() => _base();

  @override
  bool operator ==(Object other) =>
      other is QuoteNode && other.id == id && other.text == text;

  @override
  int get hashCode => Object.hash(type, id, text);
}

final class DividerNode extends DocNode {
  const DividerNode({required String id}) : super(id);

  @override
  String get type => 'divider';

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type};

  @override
  bool operator ==(Object other) => other is DividerNode && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// A block that renders a live ChampionForms field.
///
/// The document stores only the field **definition** ([fieldJson], the map
/// `FormFieldRegistry.fieldFromJson` builds it from). The **value** lives in
/// the `FormController` under [controllerIdFor]; it is not duplicated here.
final class EmbeddedFieldNode extends DocNode {
  const EmbeddedFieldNode({
    required String id,
    required this.fieldJson,
    this.sourceId,
  }) : super(id);

  /// Field definition JSON. Its own `"id"` is ignored at registration: the
  /// controller id is always derived from the document and node ids.
  final Map<String, dynamic> fieldJson;

  /// For a pasted block, the node id it was copied from (traceability only).
  final String? sourceId;

  /// Registry type name from [fieldJson].
  String? get fieldType => fieldJson['type'] as String?;

  /// The FormController id of this block's field inside document [docId].
  String controllerIdFor(String docId) => '$docId.field.$id';

  @override
  String get type => 'embeddedField';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'field': fieldJson,
        if (sourceId != null) 'sourceId': sourceId,
      };

  @override
  bool operator ==(Object other) =>
      other is EmbeddedFieldNode &&
      other.id == id &&
      other.sourceId == sourceId &&
      const DeepCollectionEquality().equals(other.fieldJson, fieldJson);

  @override
  int get hashCode => Object.hash(
      type, id, sourceId, const DeepCollectionEquality().hash(fieldJson));
}

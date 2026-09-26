import 'package:collection/collection.dart';

import 'doc_node.dart';

/// An immutable, ordered document: the value a `DocumentField` stores in the
/// `FormController`.
final class DocSnapshot {
  DocSnapshot(List<DocNode> nodes, {this.schemaVersion = currentSchemaVersion})
    : nodes = List.unmodifiable(nodes) {
    final seen = <String>{};
    for (final n in nodes) {
      if (!seen.add(n.id)) {
        throw ArgumentError('Duplicate node id "${n.id}"');
      }
    }
  }

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final List<DocNode> nodes;

  static final empty = DocSnapshot(const []);

  DocNode? nodeById(String id) => nodes.firstWhereOrNull((n) => n.id == id);

  int indexOf(String id) => nodes.indexWhere((n) => n.id == id);

  Iterable<EmbeddedFieldNode> get embeddedFields =>
      nodes.whereType<EmbeddedFieldNode>();

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'nodes': [for (final n in nodes) n.toJson()],
  };

  /// Throws [FormatException] for a newer or malformed schema, never a
  /// [TypeError].
  factory DocSnapshot.fromJson(Map<String, dynamic> json) {
    try {
      return DocSnapshot._fromJson(json);
    } on TypeError catch (e) {
      throw FormatException('Malformed document: $e');
    }
  }

  factory DocSnapshot._fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] ?? 1;
    if (version is! int || version < 1 || version > currentSchemaVersion) {
      throw FormatException('Unsupported document schemaVersion: $version');
    }
    final nodes = json['nodes'];
    if (nodes is! List) throw const FormatException('Document needs "nodes"');
    return DocSnapshot([
      for (final n in nodes)
        DocNode.fromJson((n as Map).cast<String, dynamic>()),
    ], schemaVersion: version);
  }

  @override
  bool operator ==(Object other) =>
      other is DocSnapshot &&
      other.schemaVersion == schemaVersion &&
      const ListEquality<DocNode>().equals(other.nodes, nodes);

  @override
  int get hashCode => Object.hash(schemaVersion, Object.hashAll(nodes));
}

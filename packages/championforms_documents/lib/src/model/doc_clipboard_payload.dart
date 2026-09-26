import 'package:championforms/championforms.dart' as form;

import 'doc_node.dart';

/// What a copy from a document puts on the clipboard as ChampionForms ID
/// data (custom format `com.championforms.data`, and embedded in the HTML).
///
/// [nodes] are the copied blocks, already trimmed to the selection (a
/// partially selected paragraph contributes only its selected text). For each
/// [EmbeddedFieldNode] among them, [fields] holds the field's current value
/// as its codec's [form.ClipboardFragment], keyed by node id.
///
/// Pasted payloads are untrusted: [fromJson] validates shape and size, and a
/// paste always gives nodes fresh ids (recording the original as
/// `EmbeddedFieldNode.sourceId`).
final class DocClipboardPayload {
  const DocClipboardPayload({
    required this.nodes,
    this.fields = const {},
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;

  /// JSON larger than this (in UTF-16 code units) is rejected on paste.
  static const maxEncodedLength = 5 * 1024 * 1024;

  /// Custom clipboard format name for this payload.
  static const formatName = 'com.championforms.data';

  final int schemaVersion;
  final List<DocNode> nodes;
  final Map<String, form.ClipboardFragment> fields;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'nodes': [for (final n in nodes) n.toJson()],
    if (fields.isNotEmpty)
      'fields': {for (final e in fields.entries) e.key: e.value.toJson()},
  };

  /// Throws [FormatException] on a wrong shape or unsupported version.
  factory DocClipboardPayload.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version < 1 || version > currentSchemaVersion) {
      throw FormatException('Unsupported clipboard schemaVersion: $version');
    }
    final nodes = json['nodes'];
    if (nodes is! List) throw const FormatException('Payload needs "nodes"');
    final fields = (json['fields'] as Map?) ?? const {};
    return DocClipboardPayload(
      schemaVersion: version,
      nodes: [
        for (final n in nodes)
          DocNode.fromJson((n as Map).cast<String, dynamic>()),
      ],
      fields: {
        for (final e in fields.entries)
          e.key as String: form.ClipboardFragment.fromJson(
            (e.value as Map).cast<String, dynamic>(),
          ),
      },
    );
  }
}

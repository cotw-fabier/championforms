import 'package:flutter/material.dart';

import '../model/doc_ids.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import '../model/doc_text.dart';
import '../model/doc_text_ops.dart';
import '../rules/rule.dart';

/// A field block the `/` menu can insert: a label, an icon and a factory
/// for the field JSON the block is built from
/// (`FormFieldRegistry.fieldFromJson`).
///
/// ```dart
/// DocumentBlockTemplate(
///   label: 'Rating',
///   icon: Icons.star,
///   fieldJson: () => {'type': 'rating', 'title': 'Rating', 'max': 5},
/// )
/// ```
///
/// The JSON's `id` is ignored: a block's field id is always
/// `{docId}.field.{nodeId}`.
@immutable
class DocumentBlockTemplate {
  const DocumentBlockTemplate({
    required this.label,
    required this.fieldJson,
    this.icon,
    this.id,
    this.keywords = const [],
  });

  /// Menu label, also what the `/` query filters on.
  final String label;

  /// Menu icon.
  final IconData? icon;

  /// Builds the field definition for a new block. Called once per insert.
  final Map<String, dynamic> Function() fieldJson;

  /// Stable key for the menu entry (`slash-item-{id}`); defaults to the
  /// label, lower-cased with spaces as dashes.
  final String? id;

  /// Extra words the `/` query also matches.
  final List<String> keywords;

  String get key => id ?? label.toLowerCase().replaceAll(' ', '-');
}

/// The field blocks every document offers: text input, checkbox, select
/// (dropdown) and file upload.
final List<DocumentBlockTemplate> defaultFieldBlockTemplates = [
  DocumentBlockTemplate(
    id: 'text-input',
    label: 'Text input',
    icon: Icons.short_text,
    keywords: const ['field', 'input', 'text'],
    fieldJson: () => {'type': 'text', 'title': 'Text'},
  ),
  DocumentBlockTemplate(
    id: 'checkbox',
    label: 'Checkbox',
    icon: Icons.check_box_outlined,
    keywords: const ['field', 'tick', 'agree'],
    fieldJson: () => {
      'type': 'checkboxSelect',
      'multiselect': true,
      'options': [
        {'value': 'yes', 'label': 'Yes'},
      ],
    },
  ),
  DocumentBlockTemplate(
    id: 'select',
    label: 'Select',
    icon: Icons.arrow_drop_down_circle_outlined,
    keywords: const ['field', 'dropdown', 'choice'],
    fieldJson: () => {
      'type': 'select',
      'title': 'Select',
      'options': [
        {'value': 'option_1', 'label': 'Option 1'},
        {'value': 'option_2', 'label': 'Option 2'},
        {'value': 'option_3', 'label': 'Option 3'},
      ],
    },
  ),
  DocumentBlockTemplate(
    id: 'file-upload',
    label: 'File upload',
    icon: Icons.upload_file,
    keywords: const ['field', 'attachment', 'file'],
    fieldJson: () => {'type': 'fileUpload', 'title': 'File upload'},
  ),
];

/// One entry of the `/` menu. Its [edit] turns the caret's text node into
/// the result on a snapshot, so the menu is testable without an editor.
@immutable
class SlashMenuItem {
  const SlashMenuItem({
    required this.id,
    required this.label,
    required this.edit,
    this.icon,
    this.keywords = const [],
  });

  final String id;
  final String label;
  final IconData? icon;
  final List<String> keywords;

  /// The edit for choosing this item with the caret at [offset] in text node
  /// [nodeId] of [doc] (after the `/query` text has been removed).
  final DocEdit? Function(DocSnapshot doc, String nodeId, int offset) edit;

  /// Whether this item matches the text typed after `/`.
  bool matches(String query) {
    final q = query.toLowerCase().replaceAll(' ', '');
    if (q.isEmpty) return true;
    bool has(String s) => s.toLowerCase().replaceAll(' ', '').contains(q);
    return has(label) || keywords.any(has);
  }

  // -------------------------------------------------------------------------
  // Built-in items
  // -------------------------------------------------------------------------

  /// An item that converts the caret's text node (keeping its text and id).
  factory SlashMenuItem.convert({
    required String id,
    required String label,
    required IconData icon,
    required DocNode Function(String id, DocText text) build,
    List<String> keywords = const [],
  }) => SlashMenuItem(
    id: id,
    label: label,
    icon: icon,
    keywords: keywords,
    edit: (doc, nodeId, offset) {
      final node = doc.nodeById(nodeId);
      if (node is! TextDocNode) return null;
      final converted = build(node.id, node.text);
      final max = converted is TextDocNode ? converted.text.text.length : 0;
      return DocEdit([
        ReplaceNodeOp(node.id, converted),
      ], caret: DocCaret(node.id, offset.clamp(0, max)));
    },
  );

  /// An item that inserts a block node at the caret.
  factory SlashMenuItem.block({
    required String id,
    required String label,
    required IconData icon,
    required DocNode Function() build,
    List<String> keywords = const [],
  }) => SlashMenuItem(
    id: id,
    label: label,
    icon: icon,
    keywords: keywords,
    edit: (doc, nodeId, offset) =>
        insertBlockEdit(doc, nodeId, offset, build()),
  );

  /// An item that inserts a field block from [template].
  factory SlashMenuItem.fieldBlock(DocumentBlockTemplate template) =>
      SlashMenuItem.block(
        id: template.key,
        label: template.label,
        icon: template.icon ?? Icons.widgets_outlined,
        keywords: template.keywords,
        build: () =>
            EmbeddedFieldNode(id: newNodeId(), fieldJson: template.fieldJson()),
      );
}

/// The edit that puts [block] at the caret (offset [offset] of text node
/// [nodeId]) and leaves the caret in a text node after it:
///
/// - an **empty** text node is replaced by the block;
/// - at offset 0 of a non-empty node the block goes **before** it;
/// - at the end, **after** it;
/// - in the middle, the node is **split** around the block (the second half
///   keeps the node's kind and gets a new id).
///
/// When nothing text-like follows the block, an empty paragraph is added so
/// there is somewhere to keep typing.
DocEdit? insertBlockEdit(
  DocSnapshot doc,
  String nodeId,
  int offset,
  DocNode block,
) {
  final node = doc.nodeById(nodeId);
  if (node is! TextDocNode) return null;
  final text = node.text;
  final length = text.text.length;
  final at = offset.clamp(0, length);
  final ops = <DocEditOp>[];
  DocCaret caret;

  DocCaret ensureTextAfter(String blockId, DocNode? next) {
    if (next is TextDocNode) return DocCaret(next.id, 0);
    final paragraph = ParagraphNode(id: newNodeId());
    ops.add(InsertAfterOp(blockId, paragraph));
    return DocCaret(paragraph.id, 0);
  }

  final index = doc.indexOf(node.id);
  final following = index + 1 < doc.nodes.length ? doc.nodes[index + 1] : null;

  if (length == 0) {
    // The block takes the empty node's place.
    ops
      ..add(InsertAfterOp(node.id, block))
      ..add(RemoveNodeOp(node.id));
    caret = ensureTextAfter(block.id, following);
  } else if (at == 0) {
    ops.add(InsertAfterOp(doc.nodeBefore(node.id)?.id, block));
    caret = DocCaret(node.id, 0);
  } else if (at == length) {
    ops.add(InsertAfterOp(node.id, block));
    caret = ensureTextAfter(block.id, following);
  } else {
    final tail = _sameKind(node, text.slice(at));
    ops
      ..add(ReplaceNodeOp(node.id, node.withText(text.slice(0, at))))
      ..add(InsertAfterOp(node.id, block))
      ..add(InsertAfterOp(block.id, tail));
    caret = DocCaret(tail.id, 0);
  }
  return DocEdit(ops, caret: caret);
}

/// A node of [node]'s kind with a new id and [text].
TextDocNode _sameKind(TextDocNode node, DocText text) => switch (node) {
  ParagraphNode() => ParagraphNode(id: newNodeId(), text: text),
  HeadingNode(:final level) => HeadingNode(
    id: newNodeId(),
    level: level,
    text: text,
  ),
  ListItemNode(:final ordered, :final indent) => ListItemNode(
    id: newNodeId(),
    ordered: ordered,
    indent: indent,
    text: text,
  ),
  TaskNode() => TaskNode(id: newNodeId(), text: text),
  QuoteNode() => QuoteNode(id: newNodeId(), text: text),
};

/// The text block kinds every `/` menu offers, then [fieldBlocks].
List<SlashMenuItem> buildSlashMenuItems(
  List<DocumentBlockTemplate> fieldBlocks,
) => [
  SlashMenuItem.convert(
    id: 'paragraph',
    label: 'Text',
    icon: Icons.notes,
    keywords: const ['paragraph', 'plain'],
    build: (id, text) => ParagraphNode(id: id, text: text),
  ),
  for (final level in const [1, 2, 3])
    SlashMenuItem.convert(
      id: 'heading-$level',
      label: 'Heading $level',
      icon: Icons.title,
      keywords: ['h$level', 'title'],
      build: (id, text) => HeadingNode(id: id, level: level, text: text),
    ),
  SlashMenuItem.convert(
    id: 'bulleted-list',
    label: 'Bulleted list',
    icon: Icons.format_list_bulleted,
    keywords: const ['bullet', 'unordered', 'list'],
    build: (id, text) => ListItemNode(id: id, text: text),
  ),
  SlashMenuItem.convert(
    id: 'numbered-list',
    label: 'Numbered list',
    icon: Icons.format_list_numbered,
    keywords: const ['ordered', 'list', 'number'],
    build: (id, text) => ListItemNode(id: id, ordered: true, text: text),
  ),
  SlashMenuItem.convert(
    id: 'task',
    label: 'To-do',
    icon: Icons.check_box_outline_blank,
    keywords: const ['task', 'todo', 'checklist'],
    build: (id, text) => TaskNode(id: id, text: text),
  ),
  SlashMenuItem.convert(
    id: 'quote',
    label: 'Quote',
    icon: Icons.format_quote,
    keywords: const ['blockquote', 'citation'],
    build: (id, text) => QuoteNode(id: id, text: text),
  ),
  SlashMenuItem.block(
    id: 'divider',
    label: 'Divider',
    icon: Icons.horizontal_rule,
    keywords: const ['rule', 'separator', 'hr', 'line'],
    build: () => DividerNode(id: newNodeId()),
  ),
  for (final template in fieldBlocks) SlashMenuItem.fieldBlock(template),
];

/// The `/` menu popup: a list of [items] with [highlighted] marked.
class SlashMenuPanel extends StatelessWidget {
  const SlashMenuPanel({
    super.key,
    required this.items,
    required this.highlighted,
    required this.onSelected,
    this.onHover,
  });

  final List<SlashMenuItem> items;
  final int highlighted;
  final ValueChanged<SlashMenuItem> onSelected;
  final ValueChanged<int>? onHover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('slash-menu'),
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No matching blocks'),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < items.length; i++)
                    InkWell(
                      key: ValueKey('slash-item-${items[i].id}'),
                      // Taps must not steal focus from the editor.
                      canRequestFocus: false,
                      onTap: () => onSelected(items[i]),
                      onHover: (hovering) {
                        if (hovering) onHover?.call(i);
                      },
                      child: Container(
                        color: i == highlighted
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(items[i].icon, size: 18),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                items[i].label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

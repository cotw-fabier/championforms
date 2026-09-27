import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart' as se;

import '../model/doc_node.dart';

/// The super_editor node for an [EmbeddedFieldNode]: a block that renders a
/// live ChampionForms field.
///
/// Like the model node it stores only the field definition; the value lives
/// in the `FormController` under `EmbeddedFieldNode.controllerIdFor(docId)`.
@immutable
class EmbeddedFieldBlock extends se.BlockNode {
  EmbeddedFieldBlock({
    required this.id,
    required this.fieldJson,
    this.sourceId,
    super.metadata,
  }) {
    initAddToMetadata({
      se.NodeMetadata.blockType: const se.NamedAttribution('embeddedField'),
    });
  }

  factory EmbeddedFieldBlock.fromDocNode(EmbeddedFieldNode node) =>
      EmbeddedFieldBlock(
        id: node.id,
        fieldJson: node.fieldJson,
        sourceId: node.sourceId,
      );

  @override
  final String id;

  /// The field definition (see [EmbeddedFieldNode.fieldJson]).
  final Map<String, dynamic> fieldJson;

  /// See [EmbeddedFieldNode.sourceId].
  final String? sourceId;

  /// This block as a model node.
  EmbeddedFieldNode toDocNode() =>
      EmbeddedFieldNode(id: id, fieldJson: fieldJson, sourceId: sourceId);

  @override
  String? copyContent(dynamic selection) => null;

  @override
  bool hasEquivalentContent(se.DocumentNode other) =>
      other is EmbeddedFieldBlock && other.toDocNode() == toDocNode();

  @override
  se.DocumentNode copyWithAddedMetadata(Map<String, dynamic> newProperties) =>
      EmbeddedFieldBlock(
        id: id,
        fieldJson: fieldJson,
        sourceId: sourceId,
        metadata: {...metadata, ...newProperties},
      );

  @override
  se.DocumentNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) =>
      EmbeddedFieldBlock(
        id: id,
        fieldJson: fieldJson,
        sourceId: sourceId,
        metadata: newMetadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddedFieldBlock && other.toDocNode() == toDocNode();

  @override
  int get hashCode => toDocNode().hashCode;
}

/// Builds the content of one embedded block (normally a `FieldView`).
typedef EmbeddedFieldContentBuilder =
    Widget Function(BuildContext context, EmbeddedFieldNode node);

/// Component builder: [EmbeddedFieldBlock] → [EmbeddedFieldComponent].
class EmbeddedFieldComponentBuilder implements se.ComponentBuilder {
  const EmbeddedFieldComponentBuilder(this.buildContent);

  final EmbeddedFieldContentBuilder buildContent;

  @override
  se.SingleColumnLayoutComponentViewModel? createViewModel(
    se.Document document,
    se.DocumentNode node,
  ) {
    if (node is! EmbeddedFieldBlock) return null;
    return EmbeddedFieldViewModel(
      nodeId: node.id,
      createdAt: node.metadata[se.NodeMetadata.createdAt],
      node: node.toDocNode(),
    );
  }

  @override
  Widget? createComponent(
    se.SingleColumnDocumentComponentContext componentContext,
    se.SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! EmbeddedFieldViewModel) return null;
    return EmbeddedFieldComponent(
      componentKey: componentContext.componentKey,
      viewModel: componentViewModel,
      buildContent: buildContent,
    );
  }
}

class EmbeddedFieldViewModel extends se.SingleColumnLayoutComponentViewModel
    with se.SelectionAwareViewModelMixin {
  EmbeddedFieldViewModel({
    required super.nodeId,
    super.createdAt,
    required this.node,
    super.maxWidth,
    super.padding = EdgeInsets.zero,
    se.DocumentNodeSelection? selection,
    Color selectionColor = Colors.transparent,
  }) {
    super.selection = selection;
    super.selectionColor = selectionColor;
  }

  final EmbeddedFieldNode node;

  @override
  EmbeddedFieldViewModel copy() => EmbeddedFieldViewModel(
    nodeId: nodeId,
    createdAt: createdAt,
    node: node,
    maxWidth: maxWidth,
    padding: padding,
    selection: selection,
    selectionColor: selectionColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is EmbeddedFieldViewModel && other.node == node;

  @override
  int get hashCode => super.hashCode ^ node.hashCode;
}

/// Renders an embedded field block.
///
/// Three details (found in the S0 spike) make a live field work inside
/// super_editor:
/// - it is a [se.BoxComponent], not a `SelectableBox` (which swallows
///   pointer events);
/// - an [Actions] override re-enables Tab / Shift+Tab focus traversal,
///   which SuperEditor's `IntentBlocker` blocks on Apple platforms;
/// - a transparent [Material] gives ChampionForms' ink (ListTiles, chips)
///   a surface that the block's decoration does not hide.
///
/// (The third fix, `SuperEditorImePolicies(openImeOnNonPrimaryFocusGain:
/// false)`, lives on the SuperEditor itself.)
class EmbeddedFieldComponent extends StatelessWidget {
  const EmbeddedFieldComponent({
    super.key,
    required this.componentKey,
    required this.viewModel,
    required this.buildContent,
  });

  final GlobalKey componentKey;
  final EmbeddedFieldViewModel viewModel;
  final EmbeddedFieldContentBuilder buildContent;

  @override
  Widget build(BuildContext context) {
    final selection = viewModel.selection?.nodeSelection;
    final isSelected =
        selection is se.UpstreamDownstreamNodeSelection &&
        !selection.isCollapsed;
    return se.BoxComponent(
      key: componentKey,
      child: Actions(
        actions: <Type, Action<Intent>>{
          NextFocusIntent: NextFocusAction(),
          PreviousFocusIntent: PreviousFocusAction(),
        },
        child: Container(
          key: ValueKey('embedded-${viewModel.nodeId}'),
          margin: const EdgeInsets.symmetric(vertical: 6),
          // The selection tint is painted on top: a background colour would
          // hide the field's own ink.
          foregroundDecoration: isSelected
              ? BoxDecoration(
                  color: viewModel.selectionColor.withValues(alpha: 0.35),
                )
              : null,
          child: Material(
            type: MaterialType.transparency,
            child: buildContent(context, viewModel.node),
          ),
        ),
      ),
    );
  }
}

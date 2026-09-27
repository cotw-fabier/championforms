import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart' as se;

import '../clipboard/doc_clipboard_delegate.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import '../rules/rule_set.dart';
import 'clipboard_actions.dart';
import 'doc_edit_command.dart';
import 'embedded_block.dart';
import 'issue_decoration.dart';
import 'rules_bridge.dart';
import 'slash_menu.dart';
import 'super_editor_adapter.dart';
import 'web/clipboard_events.dart';

/// The document editing surface: a super_editor `SuperEditor` configured for
/// ChampionForms documents.
///
/// It owns the `Editor`, `MutableDocument` and composer, and wires in:
/// - the transform rules ([DocumentRulesBridge]) in place of super_editor's
///   markdown reactions;
/// - embedded field blocks ([EmbeddedFieldComponentBuilder]), with the
///   focus fixes they need;
/// - the `/` menu ([SlashMenuPanel]);
/// - copy / cut / paste through an optional [DocClipboardDelegate];
/// - anchored issue highlighting ([issueNodeIds] / [wiggleTick]).
///
/// It knows nothing about `FormController`: `DocumentFieldWidget` connects
/// it to a form. Listen to changes with [onDocumentChanged] and read the
/// content with [DocumentEditorState.snapshot].
class DocumentEditor extends StatefulWidget {
  const DocumentEditor({
    super.key,
    required this.initialDocument,
    required this.docId,
    required this.embeddedContentBuilder,
    this.ruleSet = RuleSet.empty,
    this.blockTemplates = const [],
    this.includeDefaultFieldBlocks = true,
    this.clipboardDelegate,
    this.restoreFieldValues,
    this.onDocumentChanged,
    this.focusNode,
    this.readOnly = false,
    this.placeholder,
    this.minHeight,
    this.textStyle,
    this.issueNodeIds,
    this.wiggleTick,
    this.issueColor,
  });

  /// The content the editor starts with. Later changes to this value are
  /// ignored; call [DocumentEditorState.replaceDocument] instead.
  final DocSnapshot initialDocument;

  /// The document field id (passed to the clipboard delegate).
  final String docId;

  /// Builds an embedded block's content (normally a `FieldView`).
  final EmbeddedFieldContentBuilder embeddedContentBuilder;

  final RuleSet ruleSet;

  /// Extra field blocks for the `/` menu.
  final List<DocumentBlockTemplate> blockTemplates;

  /// Whether the `/` menu offers the built-in field blocks
  /// ([defaultFieldBlockTemplates]).
  final bool includeDefaultFieldBlocks;

  /// Clipboard handling. Null keeps super_editor's plain-text default.
  final DocClipboardDelegate? clipboardDelegate;

  /// Restores `DocPasteResult.fieldValues` after a paste.
  final void Function(Map<String, Object?> fieldValues)? restoreFieldValues;

  /// Called after every document change (not for selection-only changes).
  final void Function(se.DocumentChangeLog changeLog)? onDocumentChanged;

  final FocusNode? focusNode;

  /// Shows the document without letting it be edited. Embedded fields stay
  /// interactive unless they are disabled themselves.
  final bool readOnly;

  /// Hint shown while the document is a single empty paragraph.
  final String? placeholder;

  final double? minHeight;

  /// Base text style for the document (colour from the field theme).
  final TextStyle? textStyle;

  /// Nodes to highlight as having a validation issue.
  final ValueListenable<Set<String>>? issueNodeIds;

  /// Incremented to make the highlighted nodes wiggle.
  final ValueListenable<int>? wiggleTick;

  final Color? issueColor;

  @override
  State<DocumentEditor> createState() => DocumentEditorState();
}

class DocumentEditorState extends State<DocumentEditor>
    with WidgetsBindingObserver {
  late se.MutableDocument _document;
  late se.MutableDocumentComposer _composer;
  late se.Editor _editor;
  late se.ActionTagsPlugin _slashPlugin;
  late final DocumentRulesBridge _rules;
  DocumentClipboardActions? _clipboard;
  se.SuperEditorIosControlsController? _iosControls;
  se.SuperEditorAndroidControlsController? _androidControls;
  BrowserClipboardListener? _browserClipboard;

  late FocusNode _focusNode;
  final _slashLink = LeaderLink();
  final _layoutKey = GlobalKey(debugLabel: 'DocumentEditor.layout');
  final _bodyKey = GlobalKey(debugLabel: 'DocumentEditor.body');
  bool _revealScheduled = false;
  double _bottomInset = 0;
  final _slashPortal = OverlayPortalController();
  int _generation = 0;
  int _slashHighlight = 0;
  bool _isEmpty = false;

  se.Editor get editor => _editor;
  se.MutableDocument get document => _document;
  se.MutableDocumentComposer get composer => _composer;
  FocusNode get focusNode => _focusNode;
  se.ActionTagsPlugin get slashPlugin => _slashPlugin;
  DocumentClipboardActions? get clipboard => _clipboard;
  se.SuperEditorIosControlsController? get iosControls => _iosControls;
  se.SuperEditorAndroidControlsController? get androidControls =>
      _androidControls;

  /// The current content.
  DocSnapshot snapshot() => SuperEditorAdapter.toSnapshot(_document);

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'DocumentEditor');
    _rules = DocumentRulesBridge(widget.ruleSet);
    _createEditor(widget.initialDocument);
    _setUpClipboard();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant DocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.ruleSet, widget.ruleSet)) {
      _rules.ruleSet = widget.ruleSet;
    }
    if (oldWidget.clipboardDelegate != widget.clipboardDelegate ||
        oldWidget.docId != widget.docId) {
      _tearDownClipboard();
      _setUpClipboard();
    }
  }

  @override
  void didChangeMetrics() {
    // The on-screen keyboard opening (or growing) shrinks the page: bring
    // the caret back into view, as EditableText does. (A Scaffold body's
    // MediaQuery has the insets removed, so read the view's.)
    if (!mounted) return;
    final inset = View.maybeOf(context)?.viewInsets.bottom ?? 0;
    if (inset > _bottomInset) _scheduleCaretReveal();
    _bottomInset = inset;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tearDownClipboard();
    _disposeEditor(_document, _composer, _editor, _slashPlugin);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Editor lifecycle
  // -------------------------------------------------------------------------

  void _createEditor(DocSnapshot snapshot) {
    final nodes = snapshot.nodes.isEmpty
        ? DocSnapshot([ParagraphNode(id: se.Editor.createNodeId())])
        : snapshot;
    _document = SuperEditorAdapter.toMutableDocument(nodes)
      ..addListener(_onDocumentChanged);
    _composer = se.MutableDocumentComposer()
      ..selectionNotifier.addListener(_scheduleCaretReveal);
    _editor = se.Editor(
      editables: {
        se.Editor.documentKey: _document,
        se.Editor.composerKey: _composer,
      },
      requestHandlers: [
        _rules.requestHandler,
        applyDocEditRequestHandler,
        ...se.defaultRequestHandlers,
      ],
      // Our transform rules replace super_editor's markdown conversions.
      reactionPipeline: [
        se.UpdateComposerTextStylesReaction(),
        const se.LinkifyReaction(),
        _rules.reaction,
        se.UpdateSubTaskIndentAfterTaskDeletionReaction(),
      ],
      isHistoryEnabled: true,
    );
    _slashPlugin = se.ActionTagsPlugin()
      ..composingActionTag.addListener(_onSlashChanged);
    _isEmpty = _computeIsEmpty();
  }

  void _disposeEditor(
    se.MutableDocument document,
    se.MutableDocumentComposer composer,
    se.Editor editor,
    se.ActionTagsPlugin plugin,
  ) {
    document.removeListener(_onDocumentChanged);
    composer.selectionNotifier.removeListener(_scheduleCaretReveal);
    plugin.composingActionTag.removeListener(_onSlashChanged);
    plugin.dispose();
    editor.dispose();
    composer.dispose();
    document.dispose();
  }

  /// Replaces the whole document (an external value change). The editor,
  /// its history and its selection start fresh; transform rules do not run
  /// on the new content.
  void replaceDocument(DocSnapshot snapshot) {
    final old = (_document, _composer, _editor, _slashPlugin);
    _createEditor(snapshot);
    setState(() => _generation++);
    // The old SuperEditor is still mounted until this frame rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeEditor(old.$1, old.$2, old.$3, old.$4);
    });
  }

  void _onDocumentChanged(se.DocumentChangeLog log) {
    final isEmpty = _computeIsEmpty();
    if (isEmpty != _isEmpty && mounted) setState(() => _isEmpty = isEmpty);
    _scheduleCaretReveal();
    widget.onDocumentChanged?.call(log);
  }

  // -------------------------------------------------------------------------
  // Caret reveal
  // -------------------------------------------------------------------------

  /// Space kept between the caret and the edge of the scrolling page, the
  /// same as `TextField.scrollPadding`'s default.
  static const caretScrollPadding = EdgeInsets.all(20);

  /// Reveals the caret after the next layout. The editor has no scrolling of
  /// its own (see [build]), so super_editor's auto-scroll cannot move the
  /// page: this does it instead, through `RenderObject.showOnScreen`, which
  /// scrolls every enclosing `Scrollable` just enough, like a TextField in a
  /// ListView.
  void _scheduleCaretReveal() {
    if (_revealScheduled || !mounted || widget.readOnly) return;
    if (!_focusNode.hasPrimaryFocus) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      revealCaret();
    });
    // A selection-only change schedules no frame by itself.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Scrolls the enclosing page so the caret (the selection's extent) is
  /// visible. Does nothing without focus or a selection.
  void revealCaret() {
    if (!mounted || !_focusNode.hasPrimaryFocus) return;
    final selection = _composer.selection;
    final Object? layout = _layoutKey.currentState;
    final body = _bodyKey.currentContext?.findRenderObject();
    if (selection == null || layout is! se.DocumentLayout) return;
    if (body is! RenderBox || !body.attached || !body.hasSize) return;
    final Rect? caret;
    try {
      caret = layout.getRectForPosition(selection.extent);
    } catch (_) {
      return; // The component is not laid out yet.
    }
    if (caret == null) return;
    final topLeft = layout.getAncestorOffsetFromDocumentOffset(
      caret.topLeft,
      body,
    );
    final local = topLeft & caret.size;
    body.showOnScreen(
      rect: caretScrollPadding.inflateRect(local),
      duration: const Duration(milliseconds: 100),
      curve: Curves.fastOutSlowIn,
    );
  }

  bool _computeIsEmpty() {
    if (_document.nodeCount != 1) return false;
    final node = _document.first;
    return node is se.ParagraphNode &&
        node.text.isEmpty &&
        node.metadata[se.NodeMetadata.blockType] == se.paragraphAttribution;
  }

  // -------------------------------------------------------------------------
  // Clipboard
  // -------------------------------------------------------------------------

  void _setUpClipboard() {
    final delegate = widget.clipboardDelegate;
    if (delegate == null) return;
    final clipboard = DocumentClipboardActions(
      delegate: delegate,
      docId: widget.docId,
      editorOf: () => _editor,
      restoreFieldValues: (values) => widget.restoreFieldValues?.call(values),
    );
    _clipboard = clipboard;
    _iosControls = se.SuperEditorIosControlsController(
      toolbarBuilder: clipboard.iosToolbar,
    );
    _androidControls = se.SuperEditorAndroidControlsController(
      toolbarBuilder: clipboard.androidToolbar,
    );
    if (BrowserClipboardListener.supported) {
      _browserClipboard = BrowserClipboardListener(
        isActive: () => _focusNode.hasPrimaryFocus,
        onEvent: clipboard.handleBrowserEvent,
      );
    }
  }

  void _tearDownClipboard() {
    _browserClipboard?.dispose();
    _browserClipboard = null;
    _iosControls?.dispose();
    _androidControls?.dispose();
    _iosControls = null;
    _androidControls = null;
    _clipboard = null;
  }

  Future<void> _showContextMenu(TapUpDetails details) async {
    final clipboard = _clipboard;
    if (clipboard == null || widget.readOnly) return;
    final hasSelection = clipboard.expandedSelection() != null;
    final selection = _composer.selection;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      details.globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          key: const ValueKey('document-menu-cut'),
          value: 'cut',
          enabled: hasSelection,
          child: const Text('Cut'),
        ),
        PopupMenuItem(
          key: const ValueKey('document-menu-copy'),
          value: 'copy',
          enabled: hasSelection,
          child: const Text('Copy'),
        ),
        const PopupMenuItem(
          key: ValueKey('document-menu-paste'),
          value: 'paste',
          child: Text('Paste'),
        ),
      ],
    );
    if (choice == null || !mounted) return;
    // The menu took focus, which can clear the editor's selection: put both
    // back before acting on them.
    _focusNode.requestFocus();
    if (selection != null) {
      _editor.execute([
        se.ChangeSelectionRequest(
          selection,
          se.SelectionChangeType.placeCaret,
          se.SelectionReason.userInteraction,
        ),
      ]);
    }
    switch (choice) {
      case 'cut':
        await clipboard.cut();
      case 'copy':
        await clipboard.copy();
      case 'paste':
        await clipboard.paste();
    }
  }

  // -------------------------------------------------------------------------
  // Slash menu
  // -------------------------------------------------------------------------

  void _onSlashChanged() {
    if (!mounted) return;
    setState(() => _slashHighlight = 0);
    if (slashQuery != null && !widget.readOnly) {
      _slashPortal.show();
    } else {
      _slashPortal.hide();
    }
  }

  bool get _menuAbove =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// The text typed after `/`, or null when the menu is closed.
  String? get slashQuery => _slashPlugin.composingActionTag.value?.tag.token;

  /// The menu entries matching [slashQuery].
  List<SlashMenuItem> get matchingSlashItems {
    final query = slashQuery ?? '';
    return buildSlashMenuItems([
      if (widget.includeDefaultFieldBlocks) ...defaultFieldBlockTemplates,
      ...widget.blockTemplates,
    ]).where((i) => i.matches(query)).toList();
  }

  /// Removes the `/query` text and applies [item] at the caret.
  void chooseSlashItem(SlashMenuItem item) {
    _editor.execute([const se.SubmitComposingActionTagRequest()]);
    final selection = _composer.selection;
    if (selection == null) return;
    final position = selection.extent.nodePosition;
    if (position is! se.TextNodePosition) return;
    final doc = snapshot();
    final edit = item.edit(doc, selection.extent.nodeId, position.offset);
    if (edit != null) _editor.execute([ApplyDocEditRequest(edit)]);
  }

  void _closeSlashMenu() {
    _editor.execute([se.CancelComposingActionTagRequest(_slashPlugin.tagRule)]);
  }

  se.ExecutionInstruction _slashKeys({
    required se.SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (slashQuery == null) return se.ExecutionInstruction.continueExecution;
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      return se.ExecutionInstruction.continueExecution;
    }
    final items = matchingSlashItems;
    final key = keyEvent.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _closeSlashMenu();
      return se.ExecutionInstruction.haltExecution;
    }
    if (items.isEmpty) return se.ExecutionInstruction.continueExecution;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() => _slashHighlight = (_slashHighlight + 1) % items.length);
      return se.ExecutionInstruction.haltExecution;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _slashHighlight =
            (_slashHighlight - 1 + items.length) % items.length,
      );
      return se.ExecutionInstruction.haltExecution;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      chooseSlashItem(items[_slashHighlight.clamp(0, items.length - 1)]);
      return se.ExecutionInstruction.haltExecution;
    }
    return se.ExecutionInstruction.continueExecution;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  se.Stylesheet _stylesheet(BuildContext context) {
    final base =
        widget.textStyle ??
        Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 16);
    final color = base.color ?? Theme.of(context).colorScheme.onSurface;
    se.StyleRule block(String name, TextStyle style, {double top = 0}) =>
        se.StyleRule(
          se.BlockSelector(name),
          (doc, node) => {
            se.Styles.padding: se.CascadingPadding.only(top: top),
            se.Styles.textStyle: style,
          },
        );
    return se.defaultStylesheet.copyWith(
      documentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      rules: [
        se.StyleRule(
          se.BlockSelector.all,
          (doc, node) => {
            se.Styles.maxWidth: double.infinity,
            se.Styles.padding: const se.CascadingPadding.symmetric(vertical: 3),
            se.Styles.textStyle: base.copyWith(color: color, height: 1.4),
          },
        ),
        block(
          'header1',
          const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          top: 12,
        ),
        block(
          'header2',
          const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          top: 10,
        ),
        block(
          'header3',
          const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          top: 8,
        ),
        for (final h in const ['header4', 'header5', 'header6'])
          block(h, const TextStyle(fontWeight: FontWeight.bold), top: 6),
        block(
          'blockquote',
          TextStyle(
            color: color.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  List<se.ComponentBuilder> _componentBuilders() {
    final builders = <se.ComponentBuilder>[
      EmbeddedFieldComponentBuilder(widget.embeddedContentBuilder),
      ...se.defaultComponentBuilders,
      if (widget.readOnly)
        const se.ReadOnlyTaskComponentBuilder()
      else
        se.TaskComponentBuilder(_editor),
    ];
    final issues = widget.issueNodeIds;
    if (issues == null) return builders;
    return [
      for (final b in builders)
        IssueDecoratingComponentBuilder(
          b,
          issueNodeIds: issues,
          wiggleTick: widget.wiggleTick,
          issueColor: widget.issueColor ?? Theme.of(context).colorScheme.error,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stylesheet = _stylesheet(context);
    final Widget surface;
    if (widget.readOnly) {
      surface = se.SuperReader(
        key: ValueKey('reader-$_generation'),
        editor: _editor,
        focusNode: _focusNode,
        stylesheet: stylesheet,
        shrinkWrap: true,
        componentBuilders: _componentBuilders(),
      );
    } else {
      surface = se.SuperEditor(
        key: ValueKey('editor-$_generation'),
        editor: _editor,
        focusNode: _focusNode,
        documentLayoutKey: _layoutKey,
        plugins: {_slashPlugin},
        shrinkWrap: true,
        stylesheet: stylesheet,
        // Embedded fields are focus descendants of the editor. Without this
        // the editor opens its own IME connection whenever it gains
        // non-primary focus (an embedded TextField taking focus).
        imePolicies: const se.SuperEditorImePolicies(
          openImeOnNonPrimaryFocusGain: false,
        ),
        keyboardActions: [
          _slashKeys,
          _rules.backspaceAction,
          ...(_clipboard?.patch(se.defaultImeKeyboardActions) ??
              se.defaultImeKeyboardActions),
        ],
        selectorHandlers: _rules.selectorHandlers,
        componentBuilders: _componentBuilders(),
        documentOverlayBuilders: [
          se.AttributedTextBoundsOverlay(
            selector: (a) => a == se.actionTagComposingAttribution,
            builder: (context, attribution) =>
                Leader(link: _slashLink, child: const SizedBox()),
          ),
          ...se.defaultSuperEditorDocumentOverlayBuilders,
        ],
      );
    }

    // Inside an ancestor Scrollable (a form in a scroll view) super_editor
    // renders as a sliver. Give it its own non-scrolling, shrink-wrapped
    // viewport so it lays out as an ordinary box among the other fields;
    // the page keeps its own scrolling.
    Widget viewport = CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [surface],
    );
    if (!widget.readOnly && _iosControls != null && _androidControls != null) {
      viewport = se.SuperEditorIosControlsScope(
        controller: _iosControls!,
        child: se.SuperEditorAndroidControlsScope(
          controller: _androidControls!,
          child: viewport,
        ),
      );
    }
    if (!widget.readOnly && _clipboard != null && !kIsWeb) {
      viewport = GestureDetector(
        // SuperEditor has no desktop context menu; this is ours.
        onSecondaryTapUp: _showContextMenu,
        child: viewport,
      );
    }

    final placeholder = widget.placeholder;
    final body = ConstrainedBox(
      key: _bodyKey,
      constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
      child: Stack(
        children: [
          viewport,
          if (placeholder != null && _isEmpty)
            Positioned(
              left: 8,
              top: 11,
              child: IgnorePointer(
                child: Text(
                  placeholder,
                  key: const ValueKey('document-placeholder'),
                  style:
                      (widget.textStyle ??
                              Theme.of(context).textTheme.bodyLarge ??
                              const TextStyle())
                          .copyWith(color: Theme.of(context).hintColor),
                ),
              ),
            ),
        ],
      ),
    );
    // The `/` menu lives in the app overlay so it can extend past the
    // editor's bounds and still receive taps.
    return OverlayPortal(
      controller: _slashPortal,
      overlayChildBuilder: _buildSlashMenu,
      child: body,
    );
  }

  Widget _buildSlashMenu(BuildContext context) {
    return Follower.withAligner(
      link: _slashLink,
      // On Android the caret drag handle sits in the overlay just below the
      // caret and swallows taps there, so on mobile the menu opens above
      // the caret. The aligner flips it to the other side, and nudges it
      // sideways, at the screen edges.
      aligner: _menuAbove
          ? PreferredPositionAligner(
              followerPosition: PreferredPrimaryPosition.top,
              leaderCrossAxisAnchor: Alignment.topLeft,
              followerCrossAxisAnchor: Alignment.bottomLeft,
              gap: 8,
            )
          : PreferredPositionAligner(
              followerPosition: PreferredPrimaryPosition.bottom,
              leaderCrossAxisAnchor: Alignment.bottomLeft,
              followerCrossAxisAnchor: Alignment.topLeft,
              gap: 8,
            ),
      boundary: const SafeAreaFollowerBoundary(),
      showWhenUnlinked: false,
      child: SlashMenuPanel(
        items: matchingSlashItems,
        highlighted: _slashHighlight,
        onSelected: chooseSlashItem,
        onHover: (i) => setState(() => _slashHighlight = i),
      ),
    );
  }
}

/// Convenience for tests and tools: the embedded blocks of [document].
Iterable<EmbeddedFieldNode> embeddedNodesOf(se.Document document) sync* {
  for (final node in document) {
    if (node is EmbeddedFieldBlock) yield node.toDocNode();
  }
}

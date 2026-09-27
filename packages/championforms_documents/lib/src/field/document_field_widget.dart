import 'dart:async';

import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:super_editor/super_editor.dart' as se;

import '../editor/document_editor.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import 'document_field.dart';
import 'document_runtime.dart';

/// The widget a [DocumentField] renders as (registered for `document`).
///
/// It connects a [DocumentEditor] to the form:
///
/// - **Value.** Document changes are pushed to the controller with a 150 ms
///   trailing throttle, and immediately on blur, on [flush] and through
///   `DocumentFields.flushAll`. One push writes the snapshot and every
///   derived value in a single notification.
/// - **External changes.** When the controller's value changes to anything
///   the editor did not write (`updateFieldValue`, `setFieldValues`,
///   `resetField`, a JSON map from saved data), the editor is rebuilt from
///   it. Its own writes are recognised by identity, so there is no loop.
/// - **Embedded fields** are registered and withdrawn as soon as the
///   document structure changes (not throttled), so a block inserted from
///   the `/` menu is live the moment it appears.
/// - **Derived fields** (`{id}.{key}`) and **issues** come from the rule
///   set; anchored issues highlight their block while the field shows
///   errors, and the block wiggles on each new validation failure.
class DocumentFieldWidget extends StatefulWidget {
  const DocumentFieldWidget({super.key, required this.ctx});

  final form.FieldBuilderContext ctx;

  @override
  State<DocumentFieldWidget> createState() => DocumentFieldWidgetState();
}

class DocumentFieldWidgetState extends State<DocumentFieldWidget> {
  static const throttle = Duration(milliseconds: 150);

  final _editorKey = GlobalKey<DocumentEditorState>();
  final _focusNode = FocusNode(debugLabel: 'DocumentField');
  final _issueNodeIds = ValueNotifier<Set<String>>(const {});
  final _wiggleTick = ValueNotifier<int>(0);

  late DocumentRuntime _runtime;
  late DocSnapshot _initial;
  Timer? _timer;
  bool _dirty = false;
  int _failureTick = 0;
  bool _hadFocus = false;

  DocumentField get field => widget.ctx.field as DocumentField;
  form.FormController get controller => widget.ctx.controller;
  String get docId => field.id;

  /// The editor state (for tests and tools).
  DocumentEditorState? get editorState => _editorKey.currentState;

  /// Whether edits are waiting for the throttle.
  bool get hasPendingChanges => _dirty;

  @override
  void initState() {
    super.initState();
    _runtime = DocumentRuntime.of(controller, field);
    final raw = controller.getFieldValueOrNull<Object>(docId);
    _initial = DocumentField.coerce(raw) ?? field.defaultValue;
    _runtime.lastPushed = raw;
    _runtime.flusher = flush;
    // This runs while the form is building: register without notifying,
    // and publish derived values once the frame is done.
    _runtime.registerDerivedFields(noNotify: true);
    _runtime.syncEmbedded(_initial.embeddedFields, noNotify: true);
    _failureTick = controller.validationFailureTick;
    controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runtime.publishDerived(_currentControllerDocument());
      _updateIssues();
    });
  }

  @override
  void didUpdateWidget(covariant DocumentFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = !identical(oldWidget.ctx.controller, controller);
    final oldRuntime = _runtime;
    if (controllerChanged) {
      // Edits typed against the old controller belong to it. This runs
      // during a build, so write silently.
      _timer?.cancel();
      _timer = null;
      if (_dirty) {
        final doc = editorState?.snapshot();
        if (doc != null) oldRuntime.publish(doc, noNotify: true);
        _dirty = false;
      }
      oldWidget.ctx.controller.removeListener(_onControllerChanged);
      controller.addListener(_onControllerChanged);
    }
    _runtime = DocumentRuntime.of(controller, field);
    if (!identical(oldRuntime, _runtime) && oldRuntime.flusher == flush) {
      // Otherwise flushing the old controller would run this editor.
      oldRuntime.flusher = null;
    }
    _runtime.flusher = flush;
    if (controllerChanged) {
      // Show and register what the new controller holds.
      final raw = controller.getFieldValueOrNull<Object>(docId);
      final incoming = DocumentField.coerce(raw) ?? field.defaultValue;
      _runtime.lastPushed = raw;
      _failureTick = controller.validationFailureTick;
      _runtime.registerDerivedFields(noNotify: true);
      _runtime.syncEmbedded(incoming.embeddedFields, noNotify: true);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(widget.ctx.controller, controller)) return;
        if (incoming == editorState?.snapshot()) {
          _runtime.publishDerived(incoming);
        } else {
          _rehydrate(incoming); // publishes the derived values too
        }
        _updateIssues();
      });
    }
  }

  @override
  void deactivate() {
    // Keep the last keystrokes. This must happen here, not in dispose: by
    // then the editor below has already been unmounted. Notifying while the
    // tree is locked is not allowed, so write silently.
    _savePendingSilently();
    super.deactivate();
  }

  void _savePendingSilently() {
    _timer?.cancel();
    _timer = null;
    if (!_dirty) return;
    final doc = editorState?.snapshot();
    if (doc != null) _runtime.publish(doc, noNotify: true);
    _dirty = false;
  }

  @override
  void dispose() {
    _savePendingSilently();
    // Tear-offs of one method are equal, not identical.
    if (_runtime.flusher == flush) _runtime.flusher = null;
    controller.removeListener(_onControllerChanged);
    _focusNode.dispose();
    _issueNodeIds.dispose();
    _wiggleTick.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Editor → controller
  // -------------------------------------------------------------------------

  void _onDocumentChanged(se.DocumentChangeLog log) {
    final state = editorState;
    if (state == null) return;
    // Structure first, immediately: a new block must be registered before
    // its component builds.
    if (log.changes.any(
      (c) => c is se.NodeInsertedEvent || c is se.NodeRemovedEvent,
    )) {
      _runtime.syncEmbedded(embeddedNodesOf(state.document));
    }
    _dirty = true;
    _timer ??= Timer(throttle, flush);
  }

  /// Pushes pending edits to the controller now.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (!_dirty || !mounted) return;
    _dirty = false;
    final state = editorState;
    if (state == null) return;
    final doc = state.snapshot();
    _runtime.syncEmbedded(doc.embeddedFields, noNotify: true);
    _runtime.publish(doc);
    _updateIssues();
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus == _hadFocus) return;
    _hadFocus = hasFocus;
    if (!hasFocus) flush();
    if (controller.hasFieldDefinition(docId)) {
      controller.setFieldFocus(docId, hasFocus);
    }
  }

  // -------------------------------------------------------------------------
  // Controller → editor
  // -------------------------------------------------------------------------

  DocSnapshot _currentControllerDocument() =>
      DocumentField.coerce(controller.getFieldValueOrNull<Object>(docId)) ??
      field.defaultValue;

  void _onControllerChanged() {
    if (!mounted || !controller.hasFieldDefinition(docId)) return;
    final raw = controller.getFieldValueOrNull<Object>(docId);
    if (!identical(raw, _runtime.lastPushed)) {
      _runtime.lastPushed = raw;
      final incoming = DocumentField.coerce(raw) ?? field.defaultValue;
      _runSafely(() => _rehydrate(incoming));
    }
    final tick = controller.validationFailureTick;
    final failed = tick != _failureTick;
    _failureTick = tick;
    _runSafely(() {
      _updateIssues();
      if (failed && controller.findErrors(docId).isNotEmpty) {
        _wiggleTick.value++;
      }
    });
  }

  void _rehydrate(DocSnapshot incoming) {
    final state = editorState;
    if (state == null) return;
    if (incoming == state.snapshot()) return;
    _timer?.cancel();
    _timer = null;
    _dirty = false;
    _runtime.syncEmbedded(incoming.embeddedFields, noNotify: true);
    state.replaceDocument(incoming);
    _runtime.publishDerived(incoming);
  }

  /// Runs [action] now, or after the frame when called during a build
  /// (controller notifications can arrive then).
  void _runSafely(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
    } else {
      action();
    }
  }

  /// Highlights the blocks of anchored issues while the field shows errors.
  void _updateIssues() {
    if (!mounted) return;
    final hasErrors =
        controller.hasFieldDefinition(docId) &&
        controller.findErrors(docId).isNotEmpty;
    final ids = hasErrors
        ? {
            for (final issue
                in field.evaluateDocument(_currentControllerDocument()).issues)
              if (issue.nodeId != null) issue.nodeId!,
          }
        : const <String>{};
    if (!_sameSet(ids, _issueNodeIds.value)) _issueNodeIds.value = ids;
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  Widget _buildEmbedded(BuildContext context, EmbeddedFieldNode node) {
    final manager = _runtime.manager;
    final embedded = manager.fieldFor(node.id);
    if (embedded == null || !controller.hasFieldDefinition(embedded.id)) {
      return UnsupportedBlockPlaceholder(
        nodeId: node.id,
        message:
            manager.unsupportedReason(node.id) ??
            'Unsupported block type "${node.fieldType}"',
      );
    }
    return form.FieldView(
      key: ValueKey('embedded-field-${embedded.id}'),
      controller: controller,
      field: embedded,
      theme: widget.ctx.theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.ctx.colors;
    final editable = !field.disabled && !field.readOnly;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.borderColor,
          width: colors.borderSize.toDouble(),
        ),
        borderRadius: colors.borderRadius ?? BorderRadius.circular(8),
        color: colors.backgroundColor,
      ),
      child: DocumentEditor(
        key: _editorKey,
        docId: docId,
        initialDocument: _initial,
        embeddedContentBuilder: _buildEmbedded,
        ruleSet: field.ruleSet,
        blockTemplates: field.blockTemplates,
        includeDefaultFieldBlocks: field.includeDefaultFieldBlocks,
        clipboardDelegate: field.clipboardDelegate,
        restoreFieldValues: (values) =>
            _runtime.manager.applyFieldValues(values),
        onDocumentChanged: _onDocumentChanged,
        focusNode: _focusNode,
        readOnly: !editable,
        placeholder: field.placeholder,
        minHeight: field.minHeight,
        textStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colors.textColor),
        issueNodeIds: _issueNodeIds,
        wiggleTick: _wiggleTick,
      ),
    );
  }
}

/// Shown in place of an embedded block whose field type is not registered
/// (or whose definition is malformed), instead of failing the document.
class UnsupportedBlockPlaceholder extends StatelessWidget {
  const UnsupportedBlockPlaceholder({
    super.key,
    required this.nodeId,
    required this.message,
  });

  final String nodeId;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('unsupported-block-$nodeId'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.extension_off_outlined, color: theme.hintColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

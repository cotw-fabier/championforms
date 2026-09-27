import 'package:championforms/championforms.dart' as form;
import 'package:flutter/foundation.dart';

import '../embedded/embedded_field_manager.dart';
import '../model/doc_ids.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import '../rules/engine.dart';
import 'derived_field.dart';
import 'document_field.dart';

/// Everything a document field keeps on its controller besides its own
/// value: the embedded field registrations ([EmbeddedFieldManager]), the
/// derived-value fields (`{docId}.{key}`), and the flush hook of the editor
/// currently showing it.
///
/// There is one runtime per (controller, document id). It outlives the
/// editor widget — a document scrolled out of a lazy list keeps its blocks
/// and derived values in the results — and follows the document's
/// definition on the controller:
///
/// - when the definition changes (hidden, disabled, conditional, theme,
///   rule set), embedded and derived fields are re-registered with the new
///   inheritance;
/// - when the definition is withdrawn (a `Form` stopped listing it,
///   `unregisterFields`), its embedded and derived fields are withdrawn too
///   and the runtime ends.
///
/// Definition changes are picked up on the controller's next notification.
/// `addFields` does not notify for a `hideField`-only change, so a
/// document hidden that way hides its children at the next notification
/// (a `conditional` works immediately, because children inherit it).
class DocumentRuntime {
  DocumentRuntime._(this.controller, DocumentField field)
    : _field = field,
      manager = EmbeddedFieldManager(
        controller: controller,
        docId: field.id,
        inheritance: EmbeddedFieldInheritance.from(field),
      ) {
    controller.addListener(_onControllerChanged);
  }

  static final Expando<Map<String, DocumentRuntime>> _registry = Expando(
    'documentRuntimes',
  );

  /// The runtime for [field] on [controller], created on first use. The
  /// runtime adopts [field] as the current definition.
  static DocumentRuntime of(form.FormController controller, DocumentField field) {
    final map = _registry[controller] ??= {};
    final existing = map[field.id];
    if (existing != null && !existing._disposed) {
      existing.field = field;
      return existing;
    }
    return map[field.id] = DocumentRuntime._(controller, field);
  }

  /// The runtime of document [docId] on [controller], or null.
  static DocumentRuntime? lookup(form.FormController controller, String docId) =>
      _registry[controller]?[docId];

  /// Every live runtime on [controller].
  static Iterable<DocumentRuntime> allOf(form.FormController controller) =>
      _registry[controller]?.values.toList() ?? const [];

  final form.FormController controller;
  final EmbeddedFieldManager manager;
  DocumentField _field;
  bool _disposed = false;

  /// Keys of the derived fields currently registered.
  Set<String> _derivedKeys = {};

  /// The value this runtime (or its editor) last wrote to the controller,
  /// compared by identity to tell our own writes from external ones.
  Object? lastPushed;

  /// Set by the mounted editor: pushes its pending edits.
  VoidCallback? flusher;

  String get docId => _field.id;
  DocumentField get field => _field;

  /// Adopts a new definition of the document.
  set field(DocumentField field) {
    if (identical(field, _field)) return;
    final rulesChanged = !identical(field.ruleSet, _field.ruleSet);
    final inheritance = EmbeddedFieldInheritance.from(field);
    final inheritanceChanged = inheritance != manager.inheritance;
    _field = field;
    if (inheritanceChanged) manager.setInheritance(inheritance, noNotify: true);
    if (inheritanceChanged || rulesChanged) registerDerivedFields(noNotify: true);
  }

  /// Pushes pending editor edits into the controller.
  void flush() => flusher?.call();

  /// The derived field id for extract [key].
  String derivedIdFor(String key) => '$docId.$key';

  /// Registers one [DerivedField] per extract key of the rule set (keys
  /// that are not valid id segments are skipped; the rule reports them as
  /// an issue) and withdraws fields for keys that are gone.
  void registerDerivedFields({bool noNotify = false}) {
    final keys = {
      for (final rule in _field.ruleSet.extracts)
        if (isValidIdSegment(rule.key)) rule.key,
    };
    final removed = _derivedKeys.difference(keys);
    if (removed.isNotEmpty) {
      controller.unregisterFields([
        for (final k in removed) derivedIdFor(k),
      ], noNotify: true);
    }
    _derivedKeys = keys;
    if (keys.isEmpty) return;
    controller.addFields([
      for (final key in keys)
        DerivedField(
          id: derivedIdFor(key),
          documentId: docId,
          key: key,
          disabled: _field.disabled,
          hideField: _field.hideField,
          conditional: _field.conditional,
        ),
    ], noNotify: noNotify);
  }

  /// Registers and withdraws embedded fields to match [nodes].
  void syncEmbedded(Iterable<EmbeddedFieldNode> nodes, {bool noNotify = false}) =>
      manager.sync(nodes, noNotify: noNotify);

  /// The derived values of [doc], keyed by derived field id.
  Map<String, Object?> derivedValues(DocSnapshot doc) {
    final ExtractionResult result = _field.evaluateDocument(doc);
    return {
      for (final key in _derivedKeys) derivedIdFor(key): result.values[key],
    };
  }

  /// Writes [doc] and its derived values to the controller in one
  /// notification (`setFieldValues`), which also runs live validation when
  /// the document has `validateLive`.
  void publish(DocSnapshot doc, {bool noNotify = false}) {
    if (_disposed || !controller.hasFieldDefinition(docId)) return;
    lastPushed = doc;
    controller.setFieldValues({
      ...derivedValues(doc),
      docId: doc,
    }, noNotify: noNotify);
  }

  /// Writes only the derived values of [doc].
  void publishDerived(DocSnapshot doc, {bool noNotify = false}) {
    if (_disposed || _derivedKeys.isEmpty) return;
    controller.setFieldValues(derivedValues(doc), noNotify: noNotify);
  }

  void _onControllerChanged() {
    if (_disposed) return;
    if (!controller.hasFieldDefinition(docId)) {
      dispose();
      return;
    }
    // Follow definition changes made outside the editor (a Form rebuilt
    // with a hidden or disabled document, for instance).
    for (final f in controller.registeredFields) {
      if (f.id == docId) {
        if (f is DocumentField) field = f;
        break;
      }
    }
  }

  /// Withdraws the embedded and derived fields and forgets this runtime.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    controller.removeListener(_onControllerChanged);
    manager.unregisterAll(noNotify: true);
    if (_derivedKeys.isNotEmpty) {
      controller.unregisterFields([
        for (final k in _derivedKeys) derivedIdFor(k),
      ], noNotify: true);
    }
    flusher = null;
    final map = _registry[controller];
    if (map != null && identical(map[docId], this)) map.remove(docId);
  }
}

import 'package:championforms/championforms.dart' as form;
import 'package:flutter/foundation.dart';

import '../clipboard/champion_doc_clipboard.dart' show restorePastedFieldValue;
import '../model/doc_node.dart';

/// What an embedded field inherits from the document that contains it.
///
/// A hidden (or conditionally hidden) document must take its blocks out of
/// the results with it, and a disabled document must not leave editable
/// fields inside it, so these four properties flow from the document field
/// to every embedded field.
@immutable
class EmbeddedFieldInheritance {
  const EmbeddedFieldInheritance({
    this.disabled = false,
    this.hideField = false,
    this.conditional,
    this.theme,
  });

  /// The inheritance [documentField] passes down.
  factory EmbeddedFieldInheritance.from(form.Field documentField) =>
      EmbeddedFieldInheritance(
        disabled: documentField.disabled,
        hideField: documentField.hideField,
        conditional: documentField.conditional,
        theme: documentField.theme,
      );

  final bool disabled;
  final bool hideField;
  final form.FieldCondition? conditional;
  final form.FormTheme? theme;

  @override
  bool operator ==(Object other) =>
      other is EmbeddedFieldInheritance &&
      other.disabled == disabled &&
      other.hideField == hideField &&
      identical(other.conditional, conditional) &&
      identical(other.theme, theme);

  @override
  int get hashCode =>
      Object.hash(disabled, hideField, identityHashCode(conditional), theme);
}

/// One embedded block as the manager knows it.
class _Entry {
  _Entry(this.node, this.field, this.error, this.registeredIds);

  final EmbeddedFieldNode node;

  /// The registered field, or null when the block could not be built.
  final form.Field? field;

  /// Why [field] is null.
  final String? error;

  /// Every controller id registered for this block (a compound field
  /// registers its sub-fields too).
  final List<String> registeredIds;
}

/// Keeps a document's embedded fields registered on the [controller].
///
/// Each [EmbeddedFieldNode] becomes a real field with id
/// `{docId}.field.{nodeId}` ([EmbeddedFieldNode.controllerIdFor]):
///
/// - a **new** node is built with `FormFieldRegistry.fieldFromJson`, given
///   its controller id, made to inherit the document's disabled / hidden /
///   conditional / theme settings ([EmbeddedFieldInheritance]) and registered
///   with `addFields(FieldView.fieldsToRegister(field))`;
/// - a **removed** node is withdrawn with an explicit `unregisterFields`
///   (a `Form` no longer drops fields just because a `fields:` list stopped
///   listing them, and these were never in one). Values are kept, so undoing
///   the delete brings the answer back;
/// - a node whose type is not registered (or whose JSON is malformed) is
///   remembered as **unsupported**: nothing is registered and the editor
///   renders a placeholder ([unsupportedReason]).
///
/// Values live in the controller, never in the document.
class EmbeddedFieldManager {
  EmbeddedFieldManager({
    required this.controller,
    required this.docId,
    EmbeddedFieldInheritance inheritance = const EmbeddedFieldInheritance(),
  }) : _inheritance = inheritance;

  final form.FormController controller;

  /// The DocumentField id the embedded ids are derived from.
  final String docId;

  EmbeddedFieldInheritance _inheritance;
  final Map<String, _Entry> _entries = {};

  EmbeddedFieldInheritance get inheritance => _inheritance;

  /// Node ids currently known (registered or unsupported).
  Iterable<String> get nodeIds => _entries.keys;

  /// Every controller id registered for this document's blocks.
  Iterable<String> get registeredIds =>
      _entries.values.expand((e) => e.registeredIds);

  /// The registered field of block [nodeId], or null.
  form.Field? fieldFor(String nodeId) => _entries[nodeId]?.field;

  /// Why block [nodeId] could not be built, or null when it is fine (or
  /// unknown).
  String? unsupportedReason(String nodeId) => _entries[nodeId]?.error;

  /// Brings the registrations in line with [nodes] (the embedded nodes of
  /// the current document). Returns whether anything changed.
  bool sync(Iterable<EmbeddedFieldNode> nodes, {bool noNotify = false}) {
    final wanted = {for (final n in nodes) n.id: n};
    final toUnregister = <String>[];
    final toRegister = <form.Field>[];

    for (final nodeId in _entries.keys.toList()) {
      final entry = _entries[nodeId]!;
      final next = wanted[nodeId];
      if (next == null || next != entry.node) {
        toUnregister.addAll(entry.registeredIds);
        _entries.remove(nodeId);
      }
    }
    for (final node in wanted.values) {
      if (_entries.containsKey(node.id)) continue;
      final entry = _build(node);
      _entries[node.id] = entry;
      if (entry.field != null) {
        toRegister.addAll(form.FieldView.fieldsToRegister(entry.field!));
      }
    }

    // Ids that are re-registered (a changed definition) must not be
    // withdrawn after being added back.
    final reAdded = {for (final f in toRegister) f.id};
    toUnregister.removeWhere(reAdded.contains);

    if (toUnregister.isEmpty && toRegister.isEmpty) return false;
    // One notification at most: from the last call that runs.
    if (toUnregister.isNotEmpty) {
      controller.unregisterFields(
        toUnregister,
        noNotify: noNotify || toRegister.isNotEmpty,
      );
    }
    if (toRegister.isNotEmpty) {
      controller.addFields(toRegister, noNotify: noNotify);
    }
    return true;
  }

  /// Changes what the blocks inherit, re-registering them when it differs.
  void setInheritance(
    EmbeddedFieldInheritance inheritance, {
    bool noNotify = false,
  }) {
    if (inheritance == _inheritance) return;
    _inheritance = inheritance;
    final nodes = [for (final e in _entries.values) e.node];
    final ids = registeredIds.toList();
    _entries.clear();
    if (ids.isNotEmpty) controller.unregisterFields(ids, noNotify: true);
    sync(nodes, noNotify: noNotify);
  }

  /// Withdraws every block's fields (values are kept).
  void unregisterAll({bool noNotify = false}) {
    final ids = registeredIds.toList();
    _entries.clear();
    if (ids.isNotEmpty) controller.unregisterFields(ids, noNotify: noNotify);
  }

  /// Restores pasted values into freshly registered blocks.
  ///
  /// [values] maps an `EmbeddedFieldNode.id` to the value the clipboard
  /// delegate returned in `DocPasteResult.fieldValues`. Each one goes
  /// through [restorePastedFieldValue], which uses the restore path each
  /// field type's codec documents (text: `updateFieldValue`; option select:
  /// `OptionSelectClipboardCodec.optionsFor` + `updateMultiselectValues(...,
  /// overwrite: true)`; compound: `CompoundClipboardCodec.writeTo`; file
  /// upload: only a live `List<FieldOption>` from the session cache, never
  /// bare metadata).
  ///
  /// A value that does not fit its field is skipped; pasted data is
  /// untrusted and must never throw out of a paste.
  void applyFieldValues(Map<String, Object?> values, {bool noNotify = false}) {
    for (final entry in values.entries) {
      final field = _entries[entry.key]?.field;
      if (field == null) continue;
      try {
        restorePastedFieldValue(
          controller,
          field,
          entry.value,
          noNotify: noNotify,
        );
      } catch (e) {
        debugPrint('Could not restore pasted value for ${field.id}: $e');
      }
    }
  }

  _Entry _build(EmbeddedFieldNode node) {
    final controllerId = node.controllerIdFor(docId);
    form.FormFieldRegistry.ensureInitialized();
    final form.Field? built;
    try {
      built = form.FormFieldRegistry.fieldFromJson({
        ...node.fieldJson,
        'id': controllerId,
      });
    } catch (e) {
      return _Entry(node, null, 'Invalid field block: $e', const []);
    }
    if (built == null) {
      final type = node.fieldType;
      return _Entry(
        node,
        null,
        type == null
            ? 'Unsupported block: no field type'
            : 'Unsupported block type "$type"',
        const [],
      );
    }
    final field = inherit(built.copyWith(id: controllerId), _inheritance);
    return _Entry(node, field, null, [
      for (final f in form.FieldView.fieldsToRegister(field)) f.id,
    ]);
  }

  /// [field] with [inheritance] applied: disabled and hidden OR-ed in, the
  /// field's own theme winning over the document's, and the conditions
  /// combined ([combineConditions]).
  ///
  /// `conditional` is not on `Field.copyWith`'s abstract signature, so it is
  /// passed only to field types whose `copyWith` accepts it (every built-in
  /// type does). A custom type that does not is left with its own condition.
  static form.Field inherit(
    form.Field field,
    EmbeddedFieldInheritance inheritance,
  ) {
    var result = field.copyWith(
      disabled: field.disabled || inheritance.disabled,
      hideField: field.hideField || inheritance.hideField,
      theme: field.theme ?? inheritance.theme,
    );
    final condition = combineConditions(
      field.conditional,
      inheritance.conditional,
    );
    if (!identical(condition, result.conditional)) {
      try {
        result =
            (result as dynamic).copyWith(conditional: condition) as form.Field;
      } on NoSuchMethodError {
        // A custom field whose copyWith has no `conditional`.
      }
    }
    return result;
  }

  /// The condition a child with [own] gets inside a parent with [parent].
  ///
  /// `FieldCondition` is a flat rule list, so two conditions can only be
  /// merged when they agree on how: two "show when all" conditions (or two
  /// "hide when any") merge into one. Otherwise the parent's condition wins,
  /// because a child must never outlive a hidden parent.
  static form.FieldCondition? combineConditions(
    form.FieldCondition? own,
    form.FieldCondition? parent,
  ) {
    if (parent == null) return own;
    if (own == null) return parent;
    final bothShowAll =
        own.match == form.ConditionMatch.all &&
        own.action == form.ConditionAction.show &&
        parent.match == form.ConditionMatch.all &&
        parent.action == form.ConditionAction.show;
    final bothHideAny =
        own.match == form.ConditionMatch.any &&
        own.action == form.ConditionAction.hide &&
        parent.match == form.ConditionMatch.any &&
        parent.action == form.ConditionAction.hide;
    if (bothShowAll || bothHideAny) {
      return form.FieldCondition(
        match: own.match,
        action: own.action,
        rules: [...parent.rules, ...own.rules],
      );
    }
    return parent;
  }
}

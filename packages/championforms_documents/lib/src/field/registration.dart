import 'package:championforms/championforms.dart' as form;
import 'package:flutter/widgets.dart';

import '../clipboard/doc_clipboard_delegate.dart';
import '../rules/builtin/registration.dart';
import '../rules/rule.dart';
import 'derived_field.dart';
import 'document_field.dart';
import 'document_field_widget.dart';

/// Entry point for document fields.
abstract final class DocumentFields {
  static bool _initialized = false;

  /// Registers the `document` field type (builder and `fromJson`), the
  /// internal derived-value field type and the built-in document rules.
  ///
  /// Idempotent. Constructing a [DocumentField] calls it, so a hand-written
  /// form needs nothing more; call it at startup before decoding forms or
  /// documents from JSON.
  static void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    form.FormFieldRegistry.ensureInitialized();
    DocumentRules.ensureInitialized();
    form.FormFieldRegistry.register<DocumentField>(
      'document',
      (ctx) => DocumentFieldWidget(key: ValueKey(ctx.field.id), ctx: ctx),
      fromJson: DocumentField.fromJson,
    );
    form.FormFieldRegistry.register<DerivedField>(
      'documentDerived',
      (ctx) => const SizedBox.shrink(),
    );
  }

  /// Builds the copy / cut / paste handler for every document field that
  /// has no [DocumentField.clipboardDelegate] of its own — in particular
  /// fields decoded from JSON, which cannot carry one.
  ///
  /// Null (the default) keeps super_editor's plain-text clipboard. Set it
  /// once at startup to turn on rich, lossless copy and paste everywhere:
  ///
  /// ```dart
  /// DocumentFields.defaultClipboardDelegate =
  ///     (controller) => ChampionDocClipboard(controller);
  /// ```
  ///
  /// It is called once per document editor and controller (again if the
  /// editor moves to another controller). A field's own delegate always
  /// wins.
  static DocClipboardDelegate Function(form.FormController controller)?
  defaultClipboardDelegate;

  /// The current rule issues of document [docId] on [controller]: required
  /// extracts that are missing and failed constraint rules, the same ones
  /// its validator reports. Empty when the document is valid or [docId] is
  /// not a registered [DocumentField].
  ///
  /// It evaluates the value the controller holds, which trails typing by
  /// the editor's short throttle; call `controller.flushPendingEdits()`
  /// first when that matters (not while building: a flush notifies). The
  /// evaluation is cached per document snapshot, so calling this on every
  /// rebuild is cheap. Unlike `controller.formErrors`, it does not wait for
  /// validation to run. For collected results, see
  /// `results.documentIssues(docId)`.
  static List<DocIssue> issuesOf(form.FormController controller, String docId) {
    final field = _documentField(controller, docId);
    if (field == null) return const [];
    final doc =
        DocumentField.coerce(controller.getFieldValueOrNull<Object>(docId)) ??
        field.defaultValue;
    return field.evaluateDocument(doc).issues;
  }

  static DocumentField? _documentField(
    form.FormController controller,
    String docId,
  ) {
    if (!controller.hasFieldDefinition(docId)) return null;
    for (final f in controller.registeredFields) {
      if (f.id == docId) return f is DocumentField ? f : null;
    }
    return null;
  }
}

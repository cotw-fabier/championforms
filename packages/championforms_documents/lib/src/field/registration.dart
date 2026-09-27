import 'package:championforms/championforms.dart' as form;
import 'package:flutter/widgets.dart';

import '../rules/builtin/registration.dart';
import 'derived_field.dart';
import 'document_field.dart';
import 'document_field_widget.dart';
import 'document_runtime.dart';

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

  /// Pushes every pending edit of the documents registered on [controller]
  /// into the controller.
  ///
  /// Editors push their content on a 150 ms trailing throttle (and on blur),
  /// so the controller's value can trail the last keystrokes. Call this
  /// before `FormResults.getResults`, or use [getResults], which does both.
  /// (A document's rule validation always sees what was flushed; the
  /// results do too once this has run.)
  static void flushAll(form.FormController controller) {
    for (final runtime in DocumentRuntime.allOf(controller)) {
      runtime.flush();
    }
  }

  /// Pushes pending edits of document [docId] (see [flushAll]).
  static void flush(form.FormController controller, String docId) =>
      DocumentRuntime.lookup(controller, docId)?.flush();

  /// [flushAll] followed by `FormResults.getResults` with the same
  /// arguments.
  static form.FormResults getResults({
    required form.FormController controller,
    bool checkForErrors = true,
    List<form.Field>? fields,
    String? pageName,
  }) {
    flushAll(controller);
    return form.FormResults.getResults(
      controller: controller,
      checkForErrors: checkForErrors,
      fields: fields,
      pageName: pageName,
    );
  }
}

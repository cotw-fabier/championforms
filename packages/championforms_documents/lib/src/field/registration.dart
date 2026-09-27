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
  /// internal derived-value field type, the built-in document rules, and a
  /// JSON decoder for `fileUpload` blocks if the core library has none.
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
    // The core registry renders FileUpload but (as of championforms
    // 0.8.0-dev.1) cannot decode it from JSON, which the "File upload" block
    // needs. Register a decoder through the public alias API unless the
    // core provides one.
    if (!form.FormFieldRegistry.hasFromJsonFor('fileUpload')) {
      form.FormFieldRegistry.registerJsonAlias<form.FileUpload>(
        'fileUpload',
        fileUploadFromJson,
      );
    }
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

/// Decodes a `fileUpload` field: the common keys plus `multiselect`,
/// `allowedExtensions` (list of strings) and `maxFileSize` (bytes).
form.FileUpload fileUploadFromJson(Map<String, dynamic> json) {
  final extensions = json['allowedExtensions'];
  if (extensions != null &&
      (extensions is! List || extensions.any((e) => e is! String))) {
    throw FormatException(
      'Field "${json['id']}": "allowedExtensions" must be a list of strings.',
    );
  }
  return form.FileUpload(
    id: form.FieldJson.id(json),
    title: form.FieldJson.string(json, 'title'),
    description: form.FieldJson.string(json, 'description'),
    multiselect: form.FieldJson.boolean(json, 'multiselect'),
    disabled: form.FieldJson.boolean(json, 'disabled'),
    hideField: form.FieldJson.boolean(json, 'hideField'),
    requestFocus: form.FieldJson.boolean(json, 'requestFocus'),
    validateLive: form.FieldJson.boolean(json, 'validateLive'),
    validators: form.FieldJson.validators(json),
    conditional: form.FieldJson.conditional(json),
    allowedExtensions: (extensions as List?)?.cast<String>(),
    maxFileSize: form.FieldJson.integer(json, 'maxFileSize') ?? 52428800,
  );
}

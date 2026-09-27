import 'package:championforms/championforms.dart' as form;
import 'package:flutter/widgets.dart';

import '../rules/builtin/registration.dart';
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
}

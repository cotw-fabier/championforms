import 'package:championforms/championforms.dart' as form;

/// The condition every field a document registers on its behalf carries
/// (embedded blocks, their compound sub-fields, derived values): visible
/// only while the document itself is visible, and then per [inner].
///
/// The document's visibility is read live from the controller
/// ([form.FormController.isFieldIdHidden]), so it covers both its
/// `conditional` and its static `hideField`. That matters for `hideField`:
/// a `Form` rebuilt with a hidden document updates the definition through
/// `addFields` without notifying, so a copied `hideField` flag would only
/// catch up at the controller's next notification. Reading it live makes
/// the children leave `FormResults.getResults` at the same moment the
/// document does.
///
/// Serialises as [inner] (these fields are never written out as JSON, but
/// a caller printing one should see its real rules).
class DocumentScopedCondition extends form.FieldCondition {
  DocumentScopedCondition({
    required this.controller,
    required this.documentId,
    this.inner,
  }) : super(
         rules: inner?.rules ?? const [],
         match: inner?.match ?? form.ConditionMatch.all,
         action: inner?.action ?? form.ConditionAction.show,
       );

  final form.FormController controller;

  /// The document whose visibility gates the field.
  final String documentId;

  /// The field's own (already inherited) condition, if any.
  final form.FieldCondition? inner;

  @override
  bool isVisible(Map<String, dynamic> values) {
    if (controller.isFieldIdHidden(documentId)) return false;
    return inner?.isVisible(values) ?? true;
  }

  @override
  Set<String> get dependencies => {...?inner?.dependencies, documentId};

  @override
  Map<String, dynamic> toJson() => inner?.toJson() ?? super.toJson();

  @override
  String toString() => 'DocumentScopedCondition($documentId, $inner)';

  /// [field] with its condition scoped to document [documentId] on
  /// [controller]. Idempotent. `conditional` is not on `Field.copyWith`'s
  /// abstract signature, so a custom type whose `copyWith` lacks it is
  /// returned as is (it still inherits the copied `hideField`).
  static form.Field scope(
    form.Field field,
    form.FormController controller,
    String documentId,
  ) {
    final own = field.conditional;
    if (own is DocumentScopedCondition &&
        own.documentId == documentId &&
        identical(own.controller, controller)) {
      return field;
    }
    final scoped = DocumentScopedCondition(
      controller: controller,
      documentId: documentId,
      inner: own,
    );
    try {
      return (field as dynamic).copyWith(conditional: scoped) as form.Field;
    } on NoSuchMethodError {
      return field;
    }
  }
}

import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'rating_field.dart';

/// One document template: a full `DocumentField` JSON definition (rule set,
/// initial document and extra `/` blocks) shipped as an asset. Templates
/// are data: the same JSON could come from a server.
class AgreementTemplate {
  const AgreementTemplate({
    required this.id,
    required this.label,
    required this.icon,
    required this.json,
  });

  final String id;
  final String label;
  final IconData icon;

  /// The DocumentField definition, as decoded from the asset.
  final Map<String, dynamic> json;

  String get description => (json['description'] as String?) ?? '';

  /// Builds the document field through the registry
  /// (`FormFieldRegistry.fieldFromJson`), then adds what JSON cannot carry:
  /// the clipboard delegate, which needs the controller, and the app's
  /// Rating block, which has an icon.
  DocumentField buildField(form.FormController controller) {
    ensureFieldTypes();
    final decoded = form.FormFieldRegistry.fieldFromJson(json);
    if (decoded is! DocumentField) {
      throw StateError('Template "$id" is not a document field');
    }
    return decoded.copyWith(
      clipboardDelegate: ChampionDocClipboard(controller),
      blockTemplates: [...decoded.blockTemplates, ratingBlock],
    );
  }

  /// The rule set's extract keys, for the template summary.
  List<String> get extractKeys => [
    for (final r
        in (((json['ruleSet'] as Map?)?['extracts'] as List?) ?? const []))
      (r as Map)['key'] as String,
  ];
}

/// The app's extra `/` menu entry: a star rating field.
final ratingBlock = DocumentBlockTemplate(
  id: 'rating',
  label: 'Rating',
  icon: Icons.star_outline_rounded,
  keywords: const ['stars', 'score', 'field'],
  fieldJson: () => {'type': 'rating', 'title': 'Rating', 'maxStars': 5},
);

/// Registers the document field type, the built-in rules and the app's
/// rating field. Idempotent.
void ensureFieldTypes() {
  DocumentFields.ensureInitialized();
  registerRatingField();
}

/// The templates the picker offers, in order.
class TemplateLibrary {
  TemplateLibrary(this.templates);

  final List<AgreementTemplate> templates;

  static const _entries = [
    ('blank', 'Blank', Icons.note_add_outlined),
    ('service_agreement', 'Service agreement', Icons.handshake_outlined),
    ('meeting_notes', 'Meeting notes', Icons.groups_outlined),
  ];

  /// Loads `assets/templates/<id>.json` for every template.
  static Future<TemplateLibrary> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    final templates = <AgreementTemplate>[];
    for (final (id, label, icon) in _entries) {
      final raw = await assets.loadString('assets/templates/$id.json');
      templates.add(
        AgreementTemplate(
          id: id,
          label: label,
          icon: icon,
          json: (jsonDecode(raw) as Map).cast<String, dynamic>(),
        ),
      );
    }
    return TemplateLibrary(templates);
  }

  AgreementTemplate byId(String id) => templates.firstWhere(
    (t) => t.id == id,
    orElse: () => throw ArgumentError('Unknown template "$id"'),
  );
}

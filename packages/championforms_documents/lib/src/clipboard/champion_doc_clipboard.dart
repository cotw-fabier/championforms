import 'dart:convert';
import 'dart:typed_data';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_clipboard/championforms_clipboard.dart';

import '../model/doc_clipboard_payload.dart';
import '../model/doc_ids.dart';
import '../model/doc_node.dart';
import '../model/doc_plain_text.dart';
import '../model/doc_snapshot.dart';
import '../model/doc_text.dart';
import 'clipboard_sanitize.dart';
import 'doc_clipboard_delegate.dart';
import 'html_exporter.dart';
import 'html_importer.dart';
import 'html_payload.dart';
import 'selection_slicer.dart';
import 'session_cache.dart';

/// The custom clipboard format carrying a [DocClipboardPayload].
final docClipboardFormat = ClipboardFormat.custom(
  DocClipboardPayload.formatName,
);

/// Everything one copy produces, before it is written.
final class DocClipboardData {
  const DocClipboardData({
    required this.nodes,
    required this.fragments,
    required this.liveValues,
    required this.plainText,
    required this.html,
    required this.payload,
    required this.payloadJson,
  });

  /// The selection's nodes (original ids).
  final List<DocNode> nodes;

  /// Clipboard fragments of the copied embedded fields, by node id.
  final Map<String, form.ClipboardFragment> fragments;

  /// Controller values of the copied embedded fields, by node id (see
  /// [DocClipboardCacheEntry.liveValues]).
  final Map<String, Object?> liveValues;

  /// `text/plain`: one line per block; embedded fields as their fragment's
  /// plainText.
  final String plainText;

  /// `text/html`: semantic HTML with the payload embedded (see
  /// [exportHtmlBody] and [embedPayloadInHtml]).
  final String html;

  final DocClipboardPayload payload;

  /// [payload] encoded, or null when it exceeds
  /// [DocClipboardPayload.maxEncodedLength] (then it is neither written as
  /// the custom format nor embedded in the HTML, since no paste would accept
  /// it).
  final String? payloadJson;

  /// The clipboard item for [backend]: the custom format (UTF-8 payload
  /// JSON), `text/html` and `text/plain`, each only if the backend
  /// [ClipboardBackend.supports] it. Null when it supports none.
  ClipboardItem? itemFor(ClipboardBackend backend) {
    final values = <ClipboardFormat, Object>{
      if (payloadJson != null && backend.supports(docClipboardFormat))
        docClipboardFormat: Uint8List.fromList(utf8.encode(payloadJson!)),
      if (backend.supports(ClipboardFormat.html)) ClipboardFormat.html: html,
      if (backend.supports(ClipboardFormat.plainText))
        ClipboardFormat.plainText: plainText,
    };
    return values.isEmpty ? null : ClipboardItem(values);
  }
}

/// The ChampionForms [DocClipboardDelegate]: copies document selections to
/// the system clipboard in three formats and pastes from any of them.
///
/// ```dart
/// final clipboard = ChampionDocClipboard(controller);            // system clipboard
/// final test = ChampionDocClipboard(controller, backend: FakeClipboardBackend());
/// ```
///
/// ## Copy
/// The selection is sliced ([sliceSelection]); each embedded field's value is
/// read from [controller] (`EmbeddedFieldNode.controllerIdFor(docId)`;
/// compound fields through `CompoundClipboardCodec.valueFrom`) and turned
/// into a [form.ClipboardFragment] by the field's resolved codec. One
/// [ClipboardItem] is written with the custom format
/// [DocClipboardPayload.formatName], HTML ([exportHtmlBody], payload embedded
/// as a `data-championforms` attribute *and* a comment) and plain text, each
/// only where the backend supports it. Selecting exactly one embedded block
/// copies its fragment's own html/plainText. A field whose codec refuses the
/// value (a password) or that has no codec keeps its *definition* in the
/// payload (so it pastes back as an empty field) but contributes nothing to
/// the HTML or plain text, and its value is never stored anywhere. The copy
/// is also recorded in the [cache].
///
/// ## Paste precedence
/// 1. the custom format, decoded with [DocClipboardPayload.decode];
/// 2. the payload embedded in the HTML: the attribute copy, then the
///    comment copy;
/// 3. a [cache] hit on the clipboard's plain text;
/// 4. foreign HTML, through [importHtml];
/// 5. plain text, through [fromPlainText] (`- item` → list item…).
///
/// A step that fails to decode (malformed, oversize, newer schemaVersion…)
/// falls through to the next; [paste] never throws. When the payload of
/// step 1 or 2 is the one the [cache] remembers, the cached live values are
/// used too.
///
/// ## Pasted payloads are untrusted
/// Every pasted node gets a fresh [newNodeId]; embedded fields record the
/// original id as `sourceId` (when it looks like an id). Marks are clipped
/// and unsafe links dropped ([sanitizeDocText]). An embedded field's `id`
/// is stripped from its fieldJson, and the definition must build through
/// `FormFieldRegistry.fieldFromJson`; an unknown or malformed type becomes a
/// paragraph holding the fragment's plainText (or is dropped if it has
/// none).
///
/// ## `DocPasteResult.fieldValues`
/// Keyed by the new node id. The shape is the field codec's `paste` shape:
/// `String` (text fields), `List<String>` of option values (option selects:
/// turn into options with `OptionSelectClipboardCodec.optionsFor`),
/// `List<Map<String, dynamic>>` of file metadata (file uploads: nothing to
/// restore), `Map<String, String>` of sub-field suffixes (compound fields).
/// On a cache hit it is instead the live controller value: `String`,
/// `List<FieldOption>` (option selects, and file uploads *with bytes*), or
/// `Map<String, String>`. [restorePastedFieldValue] handles all of them.
final class ChampionDocClipboard implements DocClipboardDelegate {
  ChampionDocClipboard(
    this.controller, {
    ClipboardBackend? backend,
    DocClipboardSessionCache? cache,
  }) : _backend = backend,
       cache = cache ?? DocClipboardSessionCache.instance;

  final form.FormController controller;

  final ClipboardBackend? _backend;

  /// The last-copy cache (default: the shared
  /// [DocClipboardSessionCache.instance]).
  final DocClipboardSessionCache cache;

  /// The backend given to the constructor, else [SystemClipboard.backend]
  /// (resolved lazily, so constructing this never touches the platform).
  ClipboardBackend get backend => _backend ?? SystemClipboard.backend;

  // ===========================================================================
  // COPY
  // ===========================================================================

  @override
  Future<void> copy({
    required String docId,
    required DocSnapshot doc,
    required DocSelection selection,
  }) async {
    final data = encodeSelection(docId: docId, doc: doc, selection: selection);
    if (data == null) return;
    final target = backend;
    final item = data.itemFor(target);
    if (item != null) await target.write(item);
  }

  /// Builds what [copy] writes, without writing it, and records it in the
  /// [cache]. For callers that deliver the formats themselves (a browser
  /// `copy` event's `DataTransfer`, say). Null for an empty selection.
  DocClipboardData? encodeSelection({
    required String docId,
    required DocSnapshot doc,
    required DocSelection selection,
  }) {
    final nodes = sliceSelection(doc, selection);
    if (nodes.isEmpty) return null;

    final fieldsById = {for (final f in controller.registeredFields) f.id: f};
    final fragments = <String, form.ClipboardFragment>{};
    final liveValues = <String, Object?>{};
    for (final node in nodes.whereType<EmbeddedFieldNode>()) {
      final controllerId = node.controllerIdFor(docId);
      final field =
          fieldsById[controllerId] ?? _buildField(node.fieldJson, controllerId);
      if (field == null) continue;
      final codec = form.FormFieldRegistry.resolveClipboard(field);
      if (codec == null) continue;
      final Object? value = field is form.CompoundField
          ? form.CompoundClipboardCodec.valueFrom(controller, field)
          : controller.getFieldValueOrNull<Object>(controllerId);
      form.ClipboardFragment? fragment;
      try {
        fragment = codec.copy(field, value);
      } catch (_) {
        fragment = null;
      }
      if (fragment == null) continue;
      fragments[node.id] = fragment;
      liveValues[node.id] = value;
    }

    final payload = DocClipboardPayload(nodes: nodes, fields: fragments);
    final encoded = payload.encode();
    final payloadJson = encoded.length <= DocClipboardPayload.maxEncodedLength
        ? encoded
        : null;

    final String plainText;
    final String body;
    if (nodes case [final EmbeddedFieldNode only]) {
      final fragment = fragments[only.id];
      plainText = fragment?.plainText ?? '';
      body = fragment == null ? '' : fragmentHtml(fragment);
    } else {
      final exported = [
        for (final n in nodes)
          if (n is! EmbeddedFieldNode || fragments.containsKey(n.id)) n,
      ];
      plainText = toPlainText(
        DocSnapshot(exported),
        embeddedField: (n) => fragments[n.id]!.plainText,
      );
      body = exportHtmlBody(nodes, fragments: fragments);
    }
    final html = payloadJson == null
        ? '<meta charset="utf-8">$body'
        : embedPayloadInHtml(body, payloadJson);

    if (payloadJson != null) {
      cache.remember(
        plainText: plainText,
        payload: payload,
        encodedPayload: payloadJson,
        liveValues: liveValues,
      );
    }
    return DocClipboardData(
      nodes: nodes,
      fragments: fragments,
      liveValues: liveValues,
      plainText: plainText,
      html: html,
      payload: payload,
      payloadJson: payloadJson,
    );
  }

  // ===========================================================================
  // PASTE
  // ===========================================================================

  @override
  Future<DocPasteResult?> paste({
    required String docId,
    required DocSnapshot doc,
  }) async {
    final target = backend;
    ClipboardReadResult read;
    try {
      read = await target.read(
        formats: [
          for (final f in [
            docClipboardFormat,
            ClipboardFormat.html,
            ClipboardFormat.plainText,
          ])
            if (target.supports(f)) f,
        ],
      );
    } catch (_) {
      return null;
    }
    return pasteFromRead(read, docId: docId);
  }

  /// [paste] over clipboard contents already read, for callers that receive
  /// them another way: a browser `paste` event, or text a keyboard's
  /// clipboard chip committed through the IME
  /// (`ClipboardReadResult({ClipboardFormat.plainText: text})`).
  DocPasteResult? pasteFromRead(
    ClipboardReadResult read, {
    required String docId,
  }) {
    // 1. Custom format.
    final bytes = _safe(() => read.bytes(docClipboardFormat));
    if (bytes != null) {
      final json = _safe(() => utf8.decode(bytes));
      final result = json == null ? null : _pastePayloadJson(json, docId);
      if (result != null) return result;
    }

    // 2. Payload embedded in the HTML (attribute, then comment).
    final html = _safe(() => read.html);
    if (html != null) {
      for (final json in extractPayloadJsonFromHtml(html)) {
        final result = _pastePayloadJson(json, docId);
        if (result != null) return result;
      }
    }

    // 3. Session cache.
    final plain = _safe(() => read.plainText);
    final hit = cache.matchPlainText(plain);
    if (hit != null) {
      final result = _materialize(hit.payload, docId, hit.liveValues);
      if (result != null) return result;
    }

    // 4. Foreign HTML.
    if (html != null) {
      final nodes = importHtml(html);
      if (nodes.isNotEmpty) return DocPasteResult(nodes: nodes);
    }

    // 5. Plain text.
    if (plain != null && plain.isNotEmpty) {
      final nodes = _safe(() => fromPlainText(plain).nodes);
      if (nodes != null && nodes.isNotEmpty) {
        return DocPasteResult(nodes: nodes);
      }
    }
    return null;
  }

  DocPasteResult? _pastePayloadJson(String json, String docId) {
    final DocClipboardPayload payload;
    try {
      payload = DocClipboardPayload.decode(json);
    } catch (_) {
      return null; // FormatException (or worse): fall through
    }
    final live = cache.matchEncoded(json)?.liveValues;
    return _materialize(payload, docId, live);
  }

  /// Turns a trusted-shape but untrusted-content payload into insertable
  /// nodes with fresh ids, plus the values to restore.
  DocPasteResult? _materialize(
    DocClipboardPayload payload,
    String docId,
    Map<String, Object?>? liveValues,
  ) {
    form.FormFieldRegistry.ensureInitialized();
    final nodes = <DocNode>[];
    final values = <String, Object?>{};
    for (final node in payload.nodes) {
      final id = newNodeId();
      switch (node) {
        case ParagraphNode(:final text):
          nodes.add(ParagraphNode(id: id, text: sanitizeDocText(text)));
        case HeadingNode(:final text, :final level):
          nodes.add(
            HeadingNode(id: id, level: level, text: sanitizeDocText(text)),
          );
        case ListItemNode(:final text, :final ordered, :final indent):
          nodes.add(
            ListItemNode(
              id: id,
              ordered: ordered,
              indent: indent,
              text: sanitizeDocText(text),
            ),
          );
        case TaskNode(:final text, :final checked):
          nodes.add(
            TaskNode(id: id, checked: checked, text: sanitizeDocText(text)),
          );
        case QuoteNode(:final text):
          nodes.add(QuoteNode(id: id, text: sanitizeDocText(text)));
        case DividerNode():
          nodes.add(DividerNode(id: id));
        case EmbeddedFieldNode():
          _materializeField(
            node,
            id,
            payload.fields[node.id],
            docId,
            liveValues,
            nodes,
            values,
          );
      }
    }
    return nodes.isEmpty
        ? null
        : DocPasteResult(nodes: nodes, fieldValues: values);
  }

  void _materializeField(
    EmbeddedFieldNode node,
    String id,
    form.ClipboardFragment? fragment,
    String docId,
    Map<String, Object?>? liveValues,
    List<DocNode> nodes,
    Map<String, Object?> values,
  ) {
    final fieldJson = Map<String, dynamic>.of(node.fieldJson)..remove('id');
    final pasted = EmbeddedFieldNode(
      id: id,
      fieldJson: fieldJson,
      sourceId: isValidSourceId(node.id) ? node.id : null,
    );
    final field = _buildField(fieldJson, pasted.controllerIdFor(docId));
    if (field == null) {
      // Unknown or malformed type: keep what a reader would see.
      final text = fragment?.plainText ?? '';
      if (text.trim().isNotEmpty) {
        nodes.add(ParagraphNode(id: id, text: DocText(text)));
      }
      return;
    }
    nodes.add(pasted);

    if (liveValues != null && liveValues.containsKey(node.id)) {
      values[id] = liveValues[node.id];
      return;
    }
    if (fragment == null) return;
    final codec = form.FormFieldRegistry.resolveClipboard(field);
    final value = _safe(() => codec?.paste(fragment.data));
    if (value != null) values[id] = value;
  }

  /// A field built from [fieldJson] under [controllerId], or null when its
  /// type is not registered or the JSON is malformed.
  static form.Field? _buildField(
    Map<String, dynamic> fieldJson,
    String controllerId,
  ) {
    try {
      form.FormFieldRegistry.ensureInitialized();
      return form.FormFieldRegistry.fieldFromJson({
        ...fieldJson,
        'id': controllerId,
      });
    } catch (_) {
      return null;
    }
  }

  static T? _safe<T>(T? Function() body) {
    try {
      return body();
    } catch (_) {
      return null;
    }
  }
}

final _sourceIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// Whether a pasted node's original id is kept as `sourceId`: ids we
/// generate (uuid v4) and other short plain ids qualify; anything else from
/// an untrusted payload is dropped.
bool isValidSourceId(String id) => _sourceIdPattern.hasMatch(id);

/// Restores one [DocPasteResult.fieldValues] entry into [field], which must
/// already be registered in [controller] (under `field.id`).
///
/// Handles every shape [ChampionDocClipboard] produces:
/// - compound field + `Map` of sub-field suffix → text:
///   `CompoundClipboardCodec.writeTo`;
/// - option select / file upload + `List<FieldOption>` (a cache hit, file
///   bytes included): `updateMultiselectValues(overwrite: true)`;
/// - option select + `List<String>` of option values: mapped through
///   `OptionSelectClipboardCodec.optionsFor`, then as above;
/// - file upload + file metadata maps: nothing (no bytes to restore);
/// - anything else non-null (`String` for text fields):
///   `updateFieldValue`.
///
/// Returns whether a value was written.
bool restorePastedFieldValue(
  form.FormController controller,
  form.Field field,
  Object? value, {
  bool noNotify = false,
}) {
  if (value == null || !controller.hasFieldDefinition(field.id)) return false;
  switch ((field, value)) {
    case (final form.CompoundField f, final Map map):
      form.CompoundClipboardCodec.writeTo(controller, f, {
        for (final e in map.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      }, noNotify: noNotify);
      return true;
    case (final form.OptionSelect f, final List list):
      final List<form.FieldOption> options;
      if (list.every((v) => v is form.FieldOption)) {
        options = list.cast<form.FieldOption>();
      } else if (f is! form.FileUpload && list.every((v) => v is String)) {
        options = form.OptionSelectClipboardCodec.optionsFor(
          f,
          list.cast<String>(),
        );
      } else {
        return false;
      }
      controller.updateMultiselectValues(
        f.id,
        options,
        overwrite: true,
        noNotify: noNotify,
      );
      return true;
    case (form.OptionSelect(), _) || (form.CompoundField(), _):
      return false;
    default:
      controller.updateFieldValue(field.id, value, noNotify: noNotify);
      return true;
  }
}

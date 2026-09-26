import 'package:collection/collection.dart';

/// Inline formatting kinds a [DocMark] can apply.
enum DocMarkType { bold, italic, underline, strikethrough, code, link }

/// A span of inline formatting over `[start, end)` of a [DocText].
///
/// Offsets are **exclusive at the end** (super_editor's attributed text is
/// inclusive; the editor adapter converts).
final class DocMark {
  const DocMark({
    required this.type,
    required this.start,
    required this.end,
    this.href,
  }) : assert(start <= end);

  final DocMarkType type;
  final int start;
  final int end;

  /// Link target, for [DocMarkType.link] only.
  final String? href;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'start': start,
        'end': end,
        if (href != null) 'href': href,
      };

  factory DocMark.fromJson(Map<String, dynamic> json) {
    final type = DocMarkType.values.asNameMap()[json['type']];
    final start = json['start'];
    final end = json['end'];
    if (type == null || start is! int || end is! int || start > end) {
      throw FormatException('Invalid mark: $json');
    }
    return DocMark(type: type, start: start, end: end, href: json['href'] as String?);
  }

  @override
  bool operator ==(Object other) =>
      other is DocMark &&
      other.type == type &&
      other.start == start &&
      other.end == end &&
      other.href == href;

  @override
  int get hashCode => Object.hash(type, start, end, href);
}

/// Plain text plus inline marks. Immutable.
final class DocText {
  const DocText(this.text, [this.marks = const []]);

  static const empty = DocText('');

  final String text;
  final List<DocMark> marks;

  bool get isEmpty => text.isEmpty;

  /// The sub-range `[start, end)` with marks clipped and re-based.
  DocText slice(int start, [int? end]) {
    final e = end ?? text.length;
    return DocText(text.substring(start, e), [
      for (final m in marks)
        if (m.end > start && m.start < e)
          DocMark(
            type: m.type,
            start: (m.start - start).clamp(0, e - start),
            end: (m.end - start).clamp(0, e - start),
            href: m.href,
          ),
    ]);
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        if (marks.isNotEmpty) 'marks': [for (final m in marks) m.toJson()],
      };

  factory DocText.fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    if (text is! String) throw FormatException('Text needs "text": $json');
    final marks = (json['marks'] as List?) ?? const [];
    return DocText(text, [
      for (final m in marks) DocMark.fromJson((m as Map).cast<String, dynamic>()),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is DocText &&
      other.text == text &&
      const ListEquality<DocMark>().equals(other.marks, marks);

  @override
  int get hashCode => Object.hash(text, Object.hashAll(marks));
}

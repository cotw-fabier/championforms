import 'package:flutter/material.dart';

/// Icon names a `/` block defined in JSON can use (`"icon": "star"`).
///
/// ```json
/// {"type": "document", "id": "agreement",
///  "blocks": [{"label": "Rating", "icon": "star", "field": {"type": "rating"}}]}
/// ```
///
/// The names are the Material icon names ([Icons]) in snake case. An
/// unknown name gets [fallback]; a block without an `"icon"` key gets the
/// menu's default icon. Add your own names to [named] at startup, before
/// decoding forms:
///
/// ```dart
/// DocumentBlockIcons.named['contract'] = Icons.gavel;
/// ```
///
/// Only icons listed here can be named from JSON: icon fonts are
/// tree-shaken, so an icon must be referenced in code to exist in a release
/// build.
abstract final class DocumentBlockIcons {
  /// The icon for an unknown name.
  static const IconData fallback = Icons.widgets_outlined;

  /// Name → icon. Mutable, so an app can add names.
  static final Map<String, IconData> named = {
    'text_fields': Icons.text_fields,
    'short_text': Icons.short_text,
    'notes': Icons.notes,
    'check_box': Icons.check_box_outlined,
    'checklist': Icons.checklist,
    'radio_button_checked': Icons.radio_button_checked,
    'toggle_on': Icons.toggle_on_outlined,
    'list': Icons.list,
    'arrow_drop_down_circle': Icons.arrow_drop_down_circle_outlined,
    'upload_file': Icons.upload_file,
    'attach_file': Icons.attach_file,
    'image': Icons.image_outlined,
    'star': Icons.star_outline_rounded,
    'draw': Icons.draw_outlined,
    'calendar_today': Icons.calendar_today,
    'event': Icons.event,
    'schedule': Icons.schedule,
    'person': Icons.person_outline,
    'email': Icons.email_outlined,
    'phone': Icons.phone_outlined,
    'location_on': Icons.location_on_outlined,
    'link': Icons.link,
    'attach_money': Icons.attach_money,
    'numbers': Icons.numbers,
    'tag': Icons.tag,
    'gavel': Icons.gavel,
    'handshake': Icons.handshake_outlined,
    'widgets': Icons.widgets_outlined,
  };

  /// The icon for [name]: null when [name] is null (the menu's default
  /// icon), [fallback] when it is not a known name.
  static IconData? resolve(Object? name) {
    if (name == null) return null;
    if (name is! String) return fallback;
    return named[name] ?? fallback;
  }
}

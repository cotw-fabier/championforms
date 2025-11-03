/// Platform-agnostic file drag-and-drop widget using desktop_drop package.
///
/// This widget provides native OS file drag-and-drop support across all platforms:
/// - Web: Browser drag-drop events
/// - macOS: Drag from Finder
/// - Windows: Drag from Explorer
/// - Linux: Drag from file manager
/// - Android: Basic file drag support
///
/// The desktop_drop package handles all platform-specific implementations,
/// providing a unified API using XFile for cross-platform compatibility.
///
/// Usage:
/// ```dart
/// import 'package:championforms/widgets_internal/platform/file_drag_target.dart';
///
/// FileDragTarget(
///   onDrop: (files) => handleFiles(files),
///   onHover: () => setState(() => isHovering = true),
///   onLeave: () => setState(() => isHovering = false),
///   multiselect: true,
///   allowedExtensions: ['pdf', 'jpg', 'png'],
///   child: DropZoneWidget(),
/// );
/// ```
library;

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

/// Callback for when files are dropped onto the target
typedef OnDropCallback = void Function(List<XFile> files);

/// Callback for drag hover events
typedef OnHoverCallback = void Function();

/// Callback for drag leave events
typedef OnLeaveCallback = void Function();

/// Widget that handles file drag-and-drop using desktop_drop package
class FileDragTarget extends StatefulWidget {
  /// Child widget to display in the drop zone
  final Widget child;

  /// Callback when files are dropped
  final OnDropCallback? onDrop;

  /// Callback when drag enters the zone
  final OnHoverCallback? onHover;

  /// Callback when drag exits the zone
  final OnLeaveCallback? onLeave;

  /// Whether to allow multiple files to be dropped
  final bool multiselect;

  /// List of allowed file extensions (without dots, e.g., ['pdf', 'jpg'])
  /// If null, all file types are allowed
  final List<String>? allowedExtensions;

  const FileDragTarget({
    super.key,
    required this.child,
    this.onDrop,
    this.onHover,
    this.onLeave,
    this.multiselect = true,
    this.allowedExtensions,
  });

  @override
  State<FileDragTarget> createState() => _FileDragTargetState();
}

class _FileDragTargetState extends State<FileDragTarget> {
  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        // Notify parent that drag has entered the zone
        widget.onHover?.call();
      },
      onDragExited: (details) {
        // Notify parent that drag has left the zone
        widget.onLeave?.call();
      },
      onDragDone: (details) {
        // Process dropped files
        final files = details.files;

        if (files.isEmpty) return;

        // Filter by allowed extensions if specified
        List<XFile> validFiles = files;
        if (widget.allowedExtensions != null &&
            widget.allowedExtensions!.isNotEmpty) {
          validFiles = files.where((file) {
            final fileName = file.name.toLowerCase();
            return widget.allowedExtensions!.any(
              (ext) => fileName.endsWith('.${ext.toLowerCase()}'),
            );
          }).toList();
        }

        // Handle multiselect setting
        if (!widget.multiselect && validFiles.isNotEmpty) {
          // Take only the first file if multiselect is disabled
          validFiles = [validFiles.first];
        }

        // Call the drop callback with validated files
        if (validFiles.isNotEmpty) {
          widget.onDrop?.call(validFiles);
        }

        // Also trigger onLeave to reset hover state
        widget.onLeave?.call();
      },
      child: widget.child,
    );
  }
}

import 'dart:async';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';

import 'clipboard_inspector.dart';
import 'results_json.dart';

/// The live view of the agreement form: extracted values, issues, the full
/// results JSON, the Markdown export and the clipboard inspector.
///
/// It refreshes shortly after each controller notification. The document
/// pushes its edits on a 150 ms throttle, so the panel follows typing
/// without rebuilding on every keystroke. It reads results with
/// `checkForErrors: false`, which runs no validator: the live view never
/// makes a field wiggle.
class SidePanel extends StatefulWidget {
  const SidePanel({super.key, required this.controller, required this.docId});

  final form.FormController controller;
  final String docId;

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  static const _delay = Duration(milliseconds: 60);

  Timer? _timer;
  late form.FormResults _results;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
    _results = _read();
  }

  @override
  void didUpdateWidget(covariant SidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_schedule);
      widget.controller.addListener(_schedule);
      _results = _read();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    _timer ??= Timer(_delay, () {
      _timer = null;
      if (mounted) setState(() => _results = _read());
    });
  }

  form.FormResults _read() => form.FormResults.getResults(
    controller: widget.controller,
    checkForErrors: false,
  );

  DocumentField? get _field {
    for (final f in widget.controller.registeredFields) {
      if (f.id == widget.docId && f is DocumentField) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final extracted = results.extracted(widget.docId);
    final hasDoc = results.results.containsKey(widget.docId);
    final doc = hasDoc ? results.grab(widget.docId).asDocument() : null;
    final field = _field;
    final issues = (doc == null || field == null)
        ? const <DocIssue>[]
        : field.evaluateDocument(doc).issues;
    final errors = widget.controller.formErrors;

    return ListView(
      key: const ValueKey('side-panel'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Section(
          title: 'Extracted values',
          icon: Icons.auto_awesome_outlined,
          subtitle: "results.extracted('${widget.docId}')",
          child: extracted.isEmpty
              ? const _Muted('This template extracts nothing.')
              : Column(
                  children: [
                    for (final e in extracted.entries)
                      _ValueRow(
                        key: ValueKey('extracted-${e.key}'),
                        label: e.key,
                        value: _describe(e.value),
                      ),
                  ],
                ),
        ),
        _Section(
          title: 'Issues',
          icon: Icons.rule_outlined,
          subtitle: 'Rule issues now, and the errors from the last check',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (issues.isEmpty)
                const _Muted('No rule issues.')
              else
                for (final issue in issues)
                  _IssueRow(
                    icon: Icons.warning_amber_rounded,
                    text: issue.message,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
              const Divider(height: 24),
              if (errors.isEmpty)
                const _Muted('No validation errors.')
              else
                for (final e in errors)
                  _IssueRow(
                    key: ValueKey('error-${e.fieldId}-${e.validatorPosition}'),
                    icon: Icons.error_outline,
                    text: '${e.fieldId}: ${e.reason}',
                    color: Theme.of(context).colorScheme.error,
                  ),
            ],
          ),
        ),
        _Section(
          title: 'Results JSON',
          icon: Icons.data_object,
          subtitle: 'FormResults.getResults(checkForErrors: false)',
          initiallyExpanded: false,
          child: _Code(
            key: const ValueKey('results-json'),
            text: prettyJson(resultsToJson(results)),
          ),
        ),
        _Section(
          title: 'Markdown',
          icon: Icons.notes,
          subtitle: "grab('${widget.docId}').asMarkdown()",
          initiallyExpanded: false,
          child: _Code(
            key: const ValueKey('markdown-export'),
            text: hasDoc ? results.grab(widget.docId).asMarkdown() : '',
          ),
        ),
        const _Section(
          title: 'Clipboard inspector',
          icon: Icons.content_paste_search,
          subtitle: 'SystemClipboard.availableFormats()',
          initiallyExpanded: false,
          child: ClipboardInspector(),
        ),
      ],
    );
  }

  static String _describe(Object? value) => switch (value) {
    null => '—',
    final Iterable<Object?> list when list.isEmpty => '[]',
    final Iterable<Object?> list => list.join(', '),
    final Map<Object?, Object?> map =>
      map.entries.map((e) => '${e.key}: ${e.value}').join(', '),
    _ => '$value',
  };
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool initiallyExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('section-$title'),
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _Code extends StatelessWidget {
  const _Code({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          text.isEmpty ? '(empty)' : text,
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

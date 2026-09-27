import 'dart:async';
import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'draft_codec.dart';
import 'draft_storage.dart';
import 'results_json.dart';
import 'side_panel.dart';
import 'templates.dart';

/// Id of the agreement document field.
const agreementId = 'agreement';

/// Id of the scratch document field (second tab).
const scratchId = 'scratch';

/// Width from which the side panel sits next to the editor.
const wideLayoutBreakpoint = 1000.0;

/// Payment fields appear only while the document has a "Pricing" section:
/// a plain `FieldCondition` on the derived field `agreement.hasPricing`.
const pricingCondition = form.FieldCondition(
  rules: [
    form.ConditionRule(
      fieldId: '$agreementId.hasPricing',
      operator: form.ConditionOperator.equals,
      value: true,
    ),
  ],
);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.library,
    required this.storage,
    required this.initialTemplateId,
    required this.dark,
    required this.onToggleTheme,
  });

  final TemplateLibrary library;
  final DraftStorage storage;
  final String initialTemplateId;
  final bool dark;
  final VoidCallback onToggleTheme;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late AgreementTemplate _template;
  late form.FormController _controller;
  late List<form.Field> _fields;

  final form.FormController _scratchController = form.FormController();
  late final List<form.Field> _scratchFields = [
    DocumentField(
      id: scratchId,
      title: 'Scratch document',
      description:
          'Paste blocks copied from the agreement here. Embedded fields come '
          'back as the same field type, with their values.',
      placeholder: 'Paste here, or type / for blocks',
      minHeight: 360,
      blockTemplates: [ratingBlock],
      ruleSet: const RuleSet(extracts: [MentionsExtract(key: 'people')]),
      clipboardDelegate: ChampionDocClipboard(_scratchController),
    ),
  ];

  /// 0: agreement, 1: scratch, 2: side panel (narrow layout only).
  int _tab = 0;

  /// The agreement form's controller (for tests and tools).
  form.FormController get controller => _controller;

  /// The scratch document's controller.
  form.FormController get scratchController => _scratchController;

  AgreementTemplate get template => _template;

  @override
  void initState() {
    super.initState();
    _template = widget.library.byId(widget.initialTemplateId);
    _controller = form.FormController();
    _fields = _buildFields(_template, _controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scratchController.dispose();
    super.dispose();
  }

  List<form.Field> _buildFields(
    AgreementTemplate template,
    form.FormController controller,
  ) => [
    form.TextField(
      id: 'title',
      title: 'Title',
      hintText: 'e.g. Onboarding portal for Acme',
      validateLive: true,
      validators: [
        form.Validator(
          validator: (value) => form.Validators.stringIsNotEmpty(value),
          reason: 'A title is required',
        ),
      ],
    ),
    template.buildField(controller),
    form.TextField(
      id: 'paymentAmount',
      title: 'Payment amount',
      description: 'Shown because the document has a "Pricing" section.',
      hintText: 'e.g. 12000',
      conditional: pricingCondition,
      validators: [
        form.Validator(
          validator: (value) => form.Validators.isDouble(value),
          reason: 'Enter the amount as a number',
        ),
      ],
    ),
    form.OptionSelect(
      id: 'paymentCurrency',
      title: 'Currency',
      conditional: pricingCondition,
      options: [
        form.FieldOption(value: 'USD', label: 'US dollar'),
        form.FieldOption(value: 'EUR', label: 'Euro'),
        form.FieldOption(value: 'GBP', label: 'Pound sterling'),
      ],
      validators: [
        form.Validator(
          validator: (value) => form.Validators.listIsNotEmpty(value),
          reason: 'Pick a currency',
        ),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Template / reset
  // ---------------------------------------------------------------------------

  /// Starts over from [template] on a fresh controller. The old controller
  /// is disposed after the frame that unmounts its form.
  void applyTemplate(AgreementTemplate template) {
    final old = _controller;
    setState(() {
      _template = template;
      _controller = form.FormController();
      _fields = _buildFields(template, _controller);
    });
    SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _reset() {
    applyTemplate(_template);
    _snack('Reset to the "${_template.label}" template.');
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    final results = form.FormResults.getResults(controller: _controller);
    if (results.errorState) {
      final count = results.formErrors.length;
      final summary = results.formErrors
          .take(2)
          .map((e) => e.reason.split('\n').first)
          .join(' · ');
      _snack(
        '$count ${count == 1 ? 'problem' : 'problems'}: $summary',
        error: true,
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('submit-dialog'),
        icon: const Icon(Icons.task_alt),
        title: const Text('Agreement submitted'),
        content: SizedBox(
          width: 560,
          height: 420,
          child: SingleChildScrollView(
            child: SelectableText(
              prettyJson(resultsToJson(results)),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save / load
  // ---------------------------------------------------------------------------

  /// Writes the draft: the template id plus every saveable value.
  Future<void> save() async {
    _controller.flushPendingEdits();
    final draft = Draft(
      templateId: _template.id,
      savedAt: DateTime.now(),
      values: captureValues(_controller),
    );
    try {
      await widget.storage.write(jsonEncode(draft.toJson()));
      _snack(
        'Saved ${draft.values.length} values to ${widget.storage.location}',
      );
    } catch (e) {
      _snack('Save failed: $e', error: true);
    }
  }

  /// Restores the saved draft, then reads the values back and checks they
  /// match what was saved.
  Future<void> load() async {
    final Draft draft;
    try {
      final raw = await widget.storage.read();
      if (raw == null) {
        _snack('Nothing saved yet.');
        return;
      }
      draft = Draft.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (e) {
      _snack('Load failed: $e', error: true);
      return;
    }
    if (!mounted) return;
    applyTemplate(widget.library.byId(draft.templateId));
    await _endOfFrame();
    if (!mounted) return;

    final report = restoreValues(_controller, draft.values);
    await _endOfFrame();
    if (!mounted) return;
    _controller.flushPendingEdits();

    final now = captureValues(_controller);
    const eq = DeepCollectionEquality();
    final mismatched = [
      for (final id in report.restored)
        if (!eq.equals(now[id], draft.values[id])) id,
    ];
    if (mismatched.isEmpty) {
      final skipped = report.skipped.isEmpty
          ? ''
          : ' (${report.skipped.length} not restorable: '
                '${report.skipped.join(', ')})';
      _snack('Loaded and verified ${report.restored.length} values$skipped.');
    } else {
      _snack('Loaded, but these differ: ${mismatched.join(', ')}', error: true);
    }
  }

  Future<void> _endOfFrame() {
    final done = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) => done.complete());
    SchedulerBinding.instance.scheduleFrame();
    return done.future;
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: error ? TextStyle(color: scheme.onErrorContainer) : null,
          ),
          backgroundColor: error ? scheme.errorContainer : null,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideLayoutBreakpoint;
        if (wide && _tab > 1) _tab = 0;
        // Only the visible document is mounted. Its values, embedded fields
        // and derived values live on the controller and survive the switch.
        // (Mounting two DocumentFields at once currently trips super_editor's
        // debug-only duplicate-IME-input check; see test/known_issues_test.dart.)
        final Widget document = _tab == 1 ? _scratchTab() : _agreementTab();
        final panel = SidePanel(controller: _controller, docId: agreementId);

        return Scaffold(
          appBar: _appBar(wide),
          body: wide
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _documentSwitcher(),
                            ),
                          ),
                          Expanded(child: document),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 440, child: panel),
                  ],
                )
              : (_tab == 2 ? panel : document),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: const [
                    NavigationDestination(
                      key: ValueKey('nav-agreement'),
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description),
                      label: 'Agreement',
                    ),
                    NavigationDestination(
                      key: ValueKey('nav-scratch'),
                      icon: Icon(Icons.edit_note_outlined),
                      selectedIcon: Icon(Icons.edit_note),
                      label: 'Scratch',
                    ),
                    NavigationDestination(
                      key: ValueKey('nav-panel'),
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: 'Results',
                    ),
                  ],
                ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(bool wide) {
    final actions = <(String, IconData, String, VoidCallback)>[
      ('save', Icons.save_outlined, 'Save draft', save),
      ('load', Icons.file_open_outlined, 'Load draft', load),
      ('reset', Icons.restart_alt, 'Reset to template', _reset),
    ];
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.gavel_rounded),
          SizedBox(width: 12),
          Flexible(
            child: Text('Agreement Builder', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        for (final (id, icon, label, onPressed) in actions)
          wide
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    key: ValueKey(id),
                    onPressed: onPressed,
                    icon: Icon(icon),
                    label: Text(label.split(' ').first),
                  ),
                )
              : IconButton(
                  key: ValueKey(id),
                  tooltip: label,
                  onPressed: onPressed,
                  icon: Icon(icon),
                ),
        IconButton(
          key: const ValueKey('theme-toggle'),
          tooltip: widget.dark ? 'Light mode' : 'Dark mode',
          onPressed: widget.onToggleTheme,
          icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _documentSwitcher() => SegmentedButton<int>(
    key: const ValueKey('document-switcher'),
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(
        value: 0,
        icon: Icon(Icons.description_outlined),
        label: Text('Agreement', key: ValueKey('switch-agreement')),
      ),
      ButtonSegment(
        value: 1,
        icon: Icon(Icons.edit_note_outlined),
        label: Text('Scratch document', key: ValueKey('switch-scratch')),
      ),
    ],
    selected: {_tab},
    onSelectionChanged: (s) => setState(() => _tab = s.single),
  );

  Widget _page({required Widget child, required String storageKey}) =>
      SingleChildScrollView(
        key: ValueKey(storageKey),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: child,
          ),
        ),
      );

  Widget _agreementTab() => _page(
    storageKey: 'agreement-scroll',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TemplateHeader(
          library: widget.library,
          selected: _template,
          onSelected: applyTemplate,
        ),
        const SizedBox(height: 16),
        form.Form(
          key: ObjectKey(_controller),
          controller: _controller,
          fields: _fields,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('reset-inline'),
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
            FilledButton.icon(
              key: const ValueKey('submit'),
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Submit'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _scratchTab() => _page(
    storageKey: 'scratch-scroll',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Copy blocks between documents'),
            subtitle: const Text(
              'Select a block in the agreement (a filled Select, Checkbox, '
              'File upload or Rating), copy it, and paste it here. The block '
              'is recreated with a new id and its value.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        form.Form(controller: _scratchController, fields: _scratchFields),
        const SizedBox(height: 16),
        _ScratchValues(controller: _scratchController),
      ],
    ),
  );
}

/// Template picker and a summary of what the template's rules extract.
class _TemplateHeader extends StatelessWidget {
  const _TemplateHeader({
    required this.library,
    required this.selected,
    required this.onSelected,
  });

  final TemplateLibrary library;
  final AgreementTemplate selected;
  final ValueChanged<AgreementTemplate> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Template', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                key: const ValueKey('template-picker'),
                showSelectedIcon: false,
                segments: [
                  for (final t in library.templates)
                    ButtonSegment(
                      value: t.id,
                      icon: Icon(t.icon),
                      label: Text(t.label, key: ValueKey('template-${t.id}')),
                    ),
                ],
                selected: {selected.id},
                onSelectionChanged: (s) => onSelected(library.byId(s.single)),
              ),
            ),
            const SizedBox(height: 12),
            Text(selected.description, style: theme.textTheme.bodyMedium),
            if (selected.extractKeys.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Extracts', style: theme.textTheme.labelMedium),
                  for (final key in selected.extractKeys)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('$agreementId.$key'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The scratch document's embedded field values, so a paste can be checked
/// at a glance.
class _ScratchValues extends StatelessWidget {
  const _ScratchValues({required this.controller});

  final form.FormController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final values = {
          for (final f in controller.registeredFields)
            if (f.id.startsWith('$scratchId.field.'))
              f.title ?? f.id: jsonSafe(
                controller.getFieldValueOrNull<Object>(f.id),
              ),
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocks in the scratch document',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (values.isEmpty)
                  Text('None yet.', style: theme.textTheme.bodySmall)
                else
                  for (final e in values.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${e.key}: ${jsonEncode(e.value)}',
                        key: ValueKey('scratch-value-${e.key}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

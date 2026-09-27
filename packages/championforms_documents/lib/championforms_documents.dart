/// Rich document builder for ChampionForms.
///
/// A block editor (built on `super_editor`) whose documents can embed live
/// ChampionForms fields, evaluate document rules, expose results through the
/// familiar `FormResults` API, and copy/paste losslessly through
/// `championforms_clipboard`.
library;

export 'src/clipboard/doc_clipboard_delegate.dart';
export 'src/editor/clipboard_actions.dart';
export 'src/editor/doc_edit_command.dart';
export 'src/editor/document_editor.dart';
export 'src/editor/embedded_block.dart';
export 'src/editor/issue_decoration.dart';
export 'src/editor/paste_insertion.dart';
export 'src/editor/rules_bridge.dart';
export 'src/editor/slash_menu.dart';
export 'src/editor/super_editor_adapter.dart';
export 'src/editor/web/clipboard_events.dart'
    show DocClipboardEvents, BrowserClipboardAction;
export 'src/embedded/embedded_field_manager.dart';
export 'src/field/derived_field.dart';
export 'src/field/document_field.dart';
export 'src/field/document_field_widget.dart';
export 'src/field/registration.dart';
export 'src/model/doc_clipboard_payload.dart';
export 'src/model/doc_ids.dart';
export 'src/model/doc_markdown.dart';
export 'src/model/doc_node.dart';
export 'src/model/doc_plain_text.dart';
export 'src/model/doc_snapshot.dart';
export 'src/model/doc_text.dart';
export 'src/model/doc_text_ops.dart';
export 'src/results/results_extensions.dart';
export 'src/rules/builtin/constraints.dart';
export 'src/rules/builtin/extracts.dart';
export 'src/rules/builtin/registration.dart';
export 'src/rules/builtin/sections.dart';
export 'src/rules/builtin/transforms.dart';
export 'src/rules/engine.dart';
export 'src/rules/rule.dart';
export 'src/rules/rule_set.dart';

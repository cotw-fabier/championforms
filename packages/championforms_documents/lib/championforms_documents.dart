/// Rich document builder for ChampionForms.
///
/// A block editor (built on `super_editor`) whose documents can embed live
/// ChampionForms fields, evaluate document rules, expose results through the
/// familiar `FormResults` API, and copy/paste losslessly through
/// `championforms_clipboard`.
library;

export 'src/model/doc_clipboard_payload.dart';
export 'src/model/doc_node.dart';
export 'src/model/doc_snapshot.dart';
export 'src/model/doc_text.dart';
export 'src/rules/rule.dart';
export 'src/rules/rule_set.dart';

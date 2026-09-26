# championforms_documents

A rich document builder for [ChampionForms](https://pub.dev/packages/championforms).
Documents are edited in a block editor (built on
[super_editor](https://pub.dev/packages/super_editor)) and can embed live
ChampionForms fields, evaluate document rules, and expose their values through
the familiar `FormResults` API. Copy and paste round-trips through
`championforms_clipboard`.

> **Status:** early development (`0.1.0-dev`). The document model, rules
> engine, serializers and results helpers are available; the editor widget
> and `DocumentField` are not yet. This package stays a prerelease until
> super_editor ships a stable release.

It lives in the [championforms repository](https://github.com/cotw-fabier/championforms)
as a pub workspace member.

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
```

## The document model

A document is an immutable `DocSnapshot`: an ordered list of `DocNode`s, each
with a stable uuid id (`newNodeId()`). Node kinds are `ParagraphNode`,
`HeadingNode` (levels 1–6), `ListItemNode` (ordered, indent 0–8), `TaskNode`,
`QuoteNode`, `DividerNode` and `EmbeddedFieldNode` (a live ChampionForms
field, stored as its definition JSON; its value lives in the
`FormController`). Text nodes carry a `DocText` with `DocMark`s (bold, italic,
underline, strikethrough, code, link) over `[start, end)` UTF-16 offsets.

`DocSnapshot.toJson()` / `fromJson()` are versioned (`schemaVersion`); a newer
version, a duplicate node id or an unknown node type is rejected.

## Rules

A `RuleSet` holds three kinds of pure rules. Rule sets are data: they
serialize with `toJson()` and load with `RuleSet.fromJson()`, so templates
and their rules can come from a server. Call `DocumentRules.ensureInitialized()`
once at startup so the built-in rules can be decoded; an unknown rule name is
an error, never silently dropped.

```dart
DocumentRules.ensureInitialized();

final rules = RuleSet(
  transforms: DocumentRules.defaultTransforms,
  extracts: const [
    MentionsExtract(key: 'people'),
    DatesExtract(key: 'startDate', required: true),
    SectionTextExtract(key: 'scope', title: 'Scope'),
  ],
  constraints: const [
    RequiredSectionRule(title: 'Scope', nonEmpty: true),
    MaxLengthRule(max: 5000),
  ],
);

final result = evaluate(snapshot, rules);
result.values;  // {people: [alice], startDate: 2026-10-01, scope: ...}
result.issues;  // [DocIssue(...)] anchored to node ids / text ranges
```

`evaluate()` never throws for a misbehaving rule: a rule that throws becomes
a `DocIssue("Rule <name> failed: …")`, the same stance the core library takes
for a throwing validator. A required extract is missing when its value is
null, a blank string, or an empty list or map.

### Built-in transforms (while typing)

| Rule | Behavior |
|---|---|
| `markdownPrefix` | `- `/`* ` bullet, `1. ` (any `N. `) numbered, `#`…`###### ` headings, `[] `/`[ ] `/`[x] ` tasks, `> ` quote, `---` + Enter divider. The prefix map is configurable. |
| `enterSplits` | Enter splits at the caret. Lists and tasks continue; Enter on an empty item leaves the list; heading + Enter starts a paragraph. |
| `backspaceMerges` | Backspace at the start of a heading/list/task/quote turns it into a paragraph; on a paragraph it merges into the previous block. A previous divider or embedded field is removed instead. |

`TransformEngine(rules).handle(doc, event)` returns the first non-null
`DocEdit`; `DocEditApplier.apply(doc, edit)` applies it.

### Built-in extracts

`mentions` (`@name` list), `dates` (ISO `yyyy-mm-dd` and `m/d/yyyy`, first or
all), `sectionText` (text under a heading), `regex` (pattern, group,
first/all), `taskStatus` (`{total, done}`), `hasSection` (bool).

There is no built-in `fieldValue` extract: rules are pure functions of the
snapshot, and an embedded field's value lives in the controller. Embedded
field values are grabbable directly as `{docId}.field.{nodeId}`.

### Built-in constraints

`requiredSection` (optionally non-empty), `minLength` / `maxLength` (whole
document or one section, counted in Unicode code points), `forbiddenPattern`.
Each accepts a custom `message`.

## Serializers

- `toMarkdown(doc)`: CommonMark plus `~~strike~~` and `<u>underline</u>`.
  Embedded fields render through an optional callback (default
  `[field: <type>]`).
- `toPlainText(doc)`: one line per block.
- `fromPlainText(text)`: builds a document, running each line through the
  `markdownPrefix` rule so pasted `- item` and `# Title` become structured.

## Results

```dart
final results = form.FormResults.getResults(controller: controller);
results.grab('agreement').asDocument();      // DocSnapshot?
results.grab('agreement').asDocumentJson();  // Map?
results.grab('agreement').asMarkdown();      // String
results.extracted('agreement');              // {people: [...], startDate: ...}
```

## License

MIT. See [LICENSE](LICENSE).

# championforms_documents

A rich document builder for [ChampionForms](https://pub.dev/packages/championforms).
Documents are edited in a block editor (built on
[super_editor](https://pub.dev/packages/super_editor)) and can embed live
ChampionForms fields, evaluate document rules, and expose their values through
the familiar `FormResults` API. Copy and paste round-trips through
`championforms_clipboard`.

> **Status:** early development (`0.1.0-dev`). This package stays a
> prerelease until super_editor ships a stable release.

It lives in the [championforms repository](https://github.com/cotw-fabier/championforms)
as a pub workspace member.

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
```

## DocumentField

A `DocumentField` is a form field whose value is a document. Put it in a
`form.Form` next to ordinary fields:

```dart
final controller = form.FormController();

form.Form(
  controller: controller,
  fields: [
    form.TextField(id: 'title', title: 'Title'),
    DocumentField(
      id: 'agreement',
      title: 'Agreement',
      placeholder: 'Type / for blocks',
      minHeight: 200,
      ruleSet: RuleSet(
        extracts: [
          MentionsExtract(key: 'people', required: true),
          HasSectionExtract(key: 'hasPricing', title: 'Pricing'),
        ],
        constraints: [ForbiddenPatternRule(pattern: 'TODO')],
      ),
      initialDocument: savedDoc,          // optional DocSnapshot
      clipboardDelegate: ChampionDocClipboard(controller), // optional
    ),
  ],
);
```

Constructing a `DocumentField` registers the `document` field type. Call
`DocumentFields.ensureInitialized()` yourself before decoding forms from
JSON (`FormFieldRegistry.fieldFromJson({'type': 'document', ...})`, which
accepts `ruleSet`, `initialDocument`, `placeholder`, `minHeight`,
`readOnly`, `blocks` and the common field keys).

### Reading results

The editor pushes its content to the controller on a 150 ms trailing
throttle and on blur. You don't need to flush it yourself: each document
registers a pending-edit flusher on its `FormController`, and
`FormResults.getResults`, `validateForm` and `validatePage` run every
flusher first. A plain results call always sees the last keystroke:

```dart
final results = form.FormResults.getResults(controller: controller);
```

To push pending edits before reading values some other way (for example
`controller.getFieldValue`), call `controller.flushPendingEdits()`.

### What the document registers

- **The document** `agreement`: a `DocSnapshot`.
- **Embedded fields** `agreement.field.{nodeId}`: one real field per
  embedded block (`/` menu → Text input, Checkbox, Select, File upload, or
  any `DocumentBlockTemplate` you pass in `blockTemplates`). They validate,
  appear in results and can be targeted by conditions like any other
  field. Deleting a block unregisters its field; undo brings it (and its
  value) back. A block whose type is not registered shows an "unsupported
  block" placeholder instead of failing.
- **Derived values** `agreement.{key}`: one per extract rule, updated on
  every push, so `results.grab('agreement.people')` works and other fields
  can use them in a `FieldCondition`:

  ```dart
  form.TextField(
    id: 'paymentTerms',
    conditional: const form.FieldCondition(rules: [
      form.ConditionRule(
        fieldId: 'agreement.hasPricing',
        operator: form.ConditionOperator.equals,
        value: true,
      ),
    ]),
  )
  ```

Embedded and derived fields inherit the document's `disabled`, `hideField`,
`conditional` and `theme`, so a hidden document takes them out of the
results with it. Their visibility follows the document's live: a document
hidden through `hideField` alone (which `addFields` does not notify for)
drops them from results at once. `readOnly: true` locks the text but keeps embedded fields
fillable (a fixed template with blanks).

### Validation

Required extracts and constraint rules become the document field's errors
(`errorState`, `formErrors`, live with `validateLive: true`). Issues anchored
to a block mark that block and make it wiggle when validation fails.

### Editing

Typing, Enter and Backspace go through the rule set's transform rules
(`DocumentRules.defaultTransforms` when the rule set has none): `- `, `1. `,
`# `, `[] `, `> ` and `---` + Enter convert blocks; Enter continues lists;
Backspace at the start of a block unwraps or merges it. `/` opens the block
menu (arrows and Enter pick, Escape closes; on phones it opens above the
caret, and the software keyboard's Enter picks too). Inside a scrolling
page the page scrolls to keep the caret in view while typing, moving the
caret, or when the on-screen keyboard opens, like a `TextField`.

### Clipboard

With a `clipboardDelegate`, Cmd/Ctrl+C/X/V, the iOS and Android selection
toolbars and a desktop right-click menu go through it; on the web the
browser's own copy/cut/paste events do (`DocClipboardEvents.current` gives
a custom delegate the event). Pasted nodes are inserted at the caret (see
`pasteEdit` for the exact rules) and pasted embedded field values are
restored. Without a delegate, super_editor's plain-text clipboard is used.

The lower-level pieces are public too: `DocumentEditor` (the editing
surface without a form), `SuperEditorAdapter` (`MutableDocument` ⇄
`DocSnapshot`), `EmbeddedFieldManager` and `DocumentRulesBridge`.

### Known limitations

- **No task or paragraph indentation, no paragraph alignment.** The model
  has no place for them, so the editor does not offer them: Tab on a task
  or paragraph moves focus, and indentation or alignment requests from
  code are ignored. List items indent (super_editor stops at 6 levels; the
  model allows 8).
- **Empty marks** (`start == end`) are dropped when their block is next
  edited. They cover no text, so nothing visible changes.
- **Rebuilding a `Form` with the same field ids does not re-register
  changed definitions** (a championforms core behavior). Toggling
  `hideField` on a `DocumentField` that way hides it on screen, but the
  controller keeps the old definition, so results still include the
  document until its definition is re-registered (`controller.addFields`).
  Prefer a `conditional`, which the controller evaluates live.

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

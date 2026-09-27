# Changelog

## 0.1.0-dev.1

- Initial package skeleton inside the championforms monorepo.
- Document model: `DocSnapshot`, the sealed `DocNode` hierarchy
  (paragraph, heading, list item, task, quote, divider, embedded field),
  `DocText` / `DocMark` inline formatting, versioned JSON, and
  `DocClipboardPayload`. `newNodeId()` and id-segment validation.
- Rules engine: `DocEditApplier.apply`, `TransformEngine` (first non-null
  edit wins) and `evaluate()` for extract and constraint rules. A rule that
  throws is reported as a `DocIssue`, never propagated.
- Built-in rules, registered with `DocumentRules.ensureInitialized()`:
  - transforms `markdownPrefix`, `enterSplits`, `backspaceMerges`;
  - extracts `mentions`, `dates`, `sectionText`, `regex`, `taskStatus`,
    `hasSection`;
  - constraints `requiredSection`, `minLength`, `maxLength`,
    `forbiddenPattern`.
- Serializers: `toMarkdown`, `toPlainText`, `fromPlainText`.
- Results helpers: `grab(id).asDocument()`, `.asDocumentJson()`,
  `.asMarkdown()` and `results.extracted(docId)`.
- `DocumentField` (type `document`, with `fromJson`) and its widget: a
  super_editor block editor as a form field. Its value is a `DocSnapshot`,
  pushed on a 150 ms trailing throttle, on blur and on
  `DocumentFields.flushAll` / `DocumentFields.getResults`; external value
  changes (`setFieldValues`, `resetField`, saved JSON) rebuild the editor.
- Embedded fields: `EmbeddedFieldManager` registers each embedded block as
  `{docId}.field.{nodeId}` (inheriting disabled / hidden / conditional /
  theme), unregisters deleted blocks, shows a placeholder for unknown types
  and restores pasted values.
- Derived fields `{docId}.{key}` for every extract rule (usable in results
  and `FieldCondition`s); required extracts and constraints become the
  field's validation errors, and anchored issues mark and wiggle their
  block.
- Editor: `SuperEditorAdapter` (`MutableDocument` ⇄ `DocSnapshot`, lossless,
  ids kept), transform rules for typing / Enter / Backspace in place of
  super_editor's markdown reactions (`DocumentRulesBridge`), the `/` block
  menu with custom `DocumentBlockTemplate`s, and clipboard wiring for a
  `DocClipboardDelegate` (keyboard, iOS/Android toolbars, desktop context
  menu, browser clipboard events on the web).

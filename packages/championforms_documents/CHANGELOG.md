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

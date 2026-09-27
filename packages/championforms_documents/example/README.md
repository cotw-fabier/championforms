# Agreement Builder (championforms_documents trial app)

A small app that puts a `DocumentField` to work next to ordinary ChampionForms
fields: templates loaded as JSON, rules that extract values while you type,
conditional fields driven by those values, embedded field blocks, validation,
save/load, and copy/paste between documents and other apps.

## Run it

From the repository root, resolve the workspace once:

```bash
flutter pub get
```

Then:

```bash
cd packages/championforms_documents/example
flutter run -d macos     # or: -d chrome, an iOS simulator, an Android device
```

Tests:

```bash
# Widget tests (fake clipboard, in-memory storage)
flutter test

# End-to-end on macOS with the real system clipboard. Always use the wrapper
# from the repository root: it closes the test app that macOS sometimes
# relaunches after `flutter test -d macos`.
tool/macos_integration_test.sh packages/championforms_documents/example integration_test/app_flow_test.dart
```

## What is on screen

- **Template picker**: Blank, Service agreement, Meeting notes. Each is a full
  `DocumentField` definition in `assets/templates/*.json` (rule set, initial
  document, extra `/` blocks), decoded with `FormFieldRegistry.fieldFromJson`.
  Switching template, or **Reset**, starts over on a fresh `FormController`.
- **Title** (a required `form.TextField`) above the **document**.
- **Payment amount / Currency** appear only while the document has a
  "Pricing" heading: a plain `form.FieldCondition` on the derived field
  `agreement.hasPricing`.
- **Submit** validates everything with `FormResults.getResults`. Errors make
  the offending fields and anchored blocks wiggle and show a summary snackbar;
  success shows the results JSON.
- **Save / Load** write the draft (template id, document JSON, embedded field
  values and the other fields) to `agreement_draft.json` in the app documents
  directory (`path_provider`; memory on the web). Load restores it with
  `setFieldValues`, reads the values back and reports whether they match.
  File uploads keep only their names: file bytes are not saved.
- **Side panel** (a tab on narrow screens), refreshed live after the
  document's 150 ms push:
  - extracted values (`results.extracted('agreement')`);
  - rule issues right now, and the errors from the last validation;
  - the full results JSON (collapsible);
  - the Markdown export (`grab('agreement').asMarkdown()`);
  - the **clipboard inspector**: *Refresh* lists every format on the system
    clipboard (`SystemClipboard.availableFormats()`) with a preview.
- **Scratch document** tab: a second `DocumentField` on its own controller, for
  pasting blocks copied from the agreement.
- The `/` menu has an extra **Rating** block: a small custom field type
  (`lib/src/rating_field.dart`) registered with a `fromJson` factory and a
  clipboard codec, which is all a field type needs to become a block.
- Light/dark toggle in the app bar.

## Guided tour

Run `flutter run -d macos` (then again with `-d chrome`) and check off:

1. [ ] **Template.** Pick *Service agreement*. The document shows headings,
   deliverable tasks, and Payment terms / Includes onboarding / Signed copy
   blocks. The side panel lists `parties: acme, globex` and
   `startDate: 2026-10-01`.
2. [ ] **Markdown shortcuts.** On an empty line type `## Notes`, `- item`,
   `1. step`, `[] task` and `> quote`; each converts as you type the space.
   `---` then Enter inserts a divider.
3. [ ] **Slash insert a file upload.** Type `/file` and press Enter. A File
   upload block appears.
4. [ ] **Pick a file** in the new block (or in *Signed copy*). The results JSON
   shows the file name and size under `agreement.field.<nodeId>`.
5. [ ] **Mentions and dates.** Type `@initech` and `2026-11-30` in the
   Parties paragraph. `parties` gains `initech` in the side panel; the first
   date stays `startDate`.
6. [ ] **Conditional payment fields.** On an empty line type `## Pricing`.
   *Payment amount* and *Currency* appear below the document and
   `hasPricing` turns `true`. Delete the heading and they disappear.
7. [ ] **Submit with a missing required section.** Delete the *Parties*
   heading, leave the title empty and press **Submit**. The fields wiggle,
   the snackbar summarizes the problems, the side panel lists them, and the
   "TBD" paragraph is marked as an anchored issue.
8. [ ] Fix the problems (restore a *Parties* section with a mention, replace
   "TBD", add a title) and **Submit** again: the results dialog opens.
9. [ ] **Save**, then **Reset** (the template comes back), then **Load**. The
   snackbar reads "Loaded and verified …" and the results JSON is identical
   to the one before saving (expand *Results JSON* before and after).
10. [ ] **Copy a block to the scratch tab.** Choose *Net 60* in Payment terms,
    select that block (click just before it and Shift+Down, or drag across
    it), press Cmd/Ctrl+C, switch to *Scratch document*, click in it and
    press Cmd/Ctrl+V. A *Payment terms* block appears with *Net 60*
    selected, listed under "Blocks in the scratch document".
11. [ ] **Clipboard inspector.** Open it in the side panel and press
    **Refresh**: it lists `custom:application/x-championforms+json`,
    `text/html` and `text/plain`.
12. [ ] **Other apps.** Paste the same copy into Google Docs or Word: headings,
    lists, bold text and filled fields arrive formatted. Copy a formatted
    passage from them and paste it into the scratch document: headings and
    lists come in as blocks.
13. [ ] **Rating block.** Type `/rating`, pick it, click a star, copy the block
    and paste it into the scratch tab: the stars come along.
14. [ ] Toggle dark mode; narrow the window below 1000 px: the side panel
    moves into a bottom navigation tab.

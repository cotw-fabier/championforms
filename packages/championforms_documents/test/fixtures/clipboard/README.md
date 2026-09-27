# Clipboard HTML fixtures

**These are hand-authored approximations**, not real clipboard captures.
Each file is modeled on the shape the named application puts on the
clipboard's `text/html` flavor (as documented and commonly observed), to
exercise the importer's handling of that app's quirks:

| File | Models | Quirks exercised |
|---|---|---|
| `google_docs.html` | Google Docs | non-bold `<b style="font-weight:normal" id="docs-internal-guid-…">` wrapper; bold/italic/underline/strike as `font-weight:700` / `font-style:italic` / `text-decoration` on spans; `<li aria-level>` with `<p role="presentation">`; nested `<ul>` as a sibling of `<li>`; `role="checkbox"` checklists; monospace font as code; `<br>` between blocks |
| `word.html` | Microsoft Word (Windows) | `<o:p>`, `mso-` styles, conditional comments, `<![if !supportLists]>` list markers and `mso-list:Ignore` spans, list paragraphs with `mso-list:lN levelN`, `mso-bidi-font-weight:normal`, hard-wrapped text |
| `notion.html` | Notion | `to-do-list` with `checkbox-on/off` divs, `<code>`, `<blockquote>` with inline text, `<script>` to drop |
| `pages.html` | Apple Pages / Cocoa HTML Writer | full document with `<style>` in head, class-only styling plus `<b>`/`<i>`, `Apple-converted-space`, empty `<p><br></p>` |
| `chrome_selection.html` | A Chrome page selection | inline computed styles, `<span> </span>` spacers, entities, `javascript:` link, table, `Apple-interchange-newline` |

The manual cross-app clipboard matrix (plan Phase 2b / S4) will replace these
with real captures from each application; keep the file names so the tests in
`test/clipboard/html_importer_test.dart` pick them up.

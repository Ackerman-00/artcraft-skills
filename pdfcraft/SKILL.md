---
name: pdfcraft
description: PdfCraft is the ArtCraft PDF workbench, a clean-room Acrobat Pro reimplementation for macOS, Windows, Linux, FreeBSD and the web. Use this skill whenever the user mentions PdfCraft or pdfcraft-cli, asks what it can do, which file formats or shortcuts it supports, or asks to read, render, search, organize, combine, split, rotate, annotate, fill, sign, redact, OCR, compare, print, protect or convert a PDF; when preparing assets or inputs for it; when driving it headlessly through the CLI, MCP server or UI control channel; or when verifying or troubleshooting its output — even if the app is not named (for example "merge these PDFs", "fill this form", "redact this contract", "make this scan searchable", "convert this PDF to Word").
---

# PdfCraft

## Overview

PdfCraft is an open-source, pure-Rust, clean-room reimplementation of Adobe Acrobat, with
Acrobat Pro as the stated parity target (`README.md`; `docs/target-app-parity.md`). It is at
**alpha** (`ROADMAP.md:3`, `docs/roadmap.md` §Alpha gate) and runs natively on macOS, Windows,
Linux and FreeBSD plus a WebAssembly shell (`apps/pdfcraft-web`, `docs/architecture.md` §Shape).
Source: GitHub `storytold/pdfcraft`; this skill was verified against tag `v0.9.0`.

The PDF object graph is the document model: there is no separate project file, so the `.pdf`
**is** the project (`docs/architecture.md` §Data model and editing). Pages are currently drawn by
the vendored `hayro` family while PdfCraft's own renderer is built (`docs/gaps.md` gap 2;
`vendor/README.md`), so treat rendering fidelity as good-but-unmeasured rather than Acrobat-equal.
The installed `/Applications/PdfCraft.app` reports 0.9.0 and build commit
`645016addcfb9078c557f0189559ab47cdcee057`, identical to the inspected checkout
(`Contents/Info.plist`).

## Capabilities (verified)

Unless a bullet is marked **partial**, the code path is wired into the UI/CLI and was verified at
this tag; the limitations section explains every partial. If your installed version differs, run
`/Applications/PdfCraft.app/Contents/MacOS/PdfCraft --version` and `pdfcraft-cli tools` before
trusting specific flags or tool names.

### Reading, navigation and text
- Tiled CPU rendering of PDF pages with continuous, single-page, two-up and two-page layouts,
  rotation, full screen, Read mode, light/dark/system themes, and per-tab history
  (`crates/ui-egui/src/lib.rs` `set_option`; `crates/ui-egui/src/canvas.rs`; `docs/architecture.md`
  §Rendering and text).
- Reading-order text extraction (columns, RTL runs, vertical CJK), find-as-you-type, next/previous
  match, text selection and permission-aware copy (`crates/render`; `crates/ui-egui/src/canvas.rs:2198`;
  `docs/architecture.md`).
- Bookmarks, page thumbnails, the document's own page labels, page transitions/display times, and
  document word/character counts with optional tagged table/code/image exclusions
  (`bookmark_*`, `doc_info`, `text_word_count` in `crates/automation/src/tools.rs`;
  `docs/word-count.md`).
- PDF 1.0–1.7, plus PDF 2.0 read/write where 2.0-only features are preserved but not used; damaged
  files are repaired and the repairs reported (`crates/cos`; `docs/file-format-parity.md` §PDF).

### Page organization, combine, split, create
- Rotate, delete, move, duplicate, replace, extract, insert blank/file pages, crop/boxes, page
  labels, page transitions (`page_rotate`, `page_delete`, `page_move`, `page_duplicate`,
  `page_replace`, `page_extract`, `page_insert_blank`, `page_insert_file`, `page_set_box`,
  `page_number`, `page_transition_set` — `crates/automation/src/tools.rs`).
- Combine files with a bookmark per file, carrying links, form fields, layer defaults, attachments
  and nested bookmarks; extract and split by page count, before pages, bookmarks or maximum size
  (`doc_combine`, `page_extract`, `doc_split`; `crates/organize/src/import.rs:904-1040`).
- Create PDFs from blank pages, images (PNG/JPEG/TIFF incl. multi-page and BigTIFF, GIF, BMP,
  JPEG 2000) and `.txt`/`.text`; several files can be combined or written separately. **Partial**
  for text: `doc_create` accepts WinAnsi (Western European) characters only
  (`doc_create`, `doc_create_multiple`; `crates/create/src/lib.rs:489`; `docs/file-format-parity.md`).
- Compare two documents: text diff plus optional visual-region diff, side-by-side view when both
  are open, PDF report, or differences added as comments. **Partial**: no change-type filters, page
  ranges or scanned-document handling (`doc_compare`, `doc_compare_report`,
  `doc_compare_mark`; `crates/ui-egui/src/compare_ui.rs`).
- Action Wizard: list built-in actions and run them, or run a custom step list, over many files
  (`action_list`, `action_run`; `crates/engine/src/actions.rs`).

### Comments, forms, layers, attachments
- The standard Acrobat markup types: note, highlight, underline, strikeout, squiggly, replace,
  rectangle, oval, line, arrow, ink, text box, stamp (static/dynamic/custom), polygon, cloud,
  polyline, callout, caret and file attachment; replies, review status, locking, summarize,
  flatten (`comment_*` tools in `crates/automation/src/tools.rs`; `crates/annot`).
- AcroForm listing, filling with regenerated appearances, field creation (text/date/checkbox/
  radio/combo/list/button/image/signature), properties, tab order, calculations and field
  JavaScript, automatic field detection, data import/export; XFA layout and FormCalc are
  **partial** (`crates/forms`, `crates/xfa`, `crates/js`; `form_*` tools).
- Fill & Sign without prepared fields: typed text, checks/crosses/dots/lines, dates, typed or image
  signatures/initials, photo-of-signature scanning (`fill_sign_add`; `crates/ui-egui/src/fill_sign.rs`).
- Layers can be switched in the UI or with `ui.set layer=Name=on|off`; attachments can be opened
  or saved from the Attachments panel (`crates/ui-egui/src/lib.rs` `set_option`;
  `crates/ui-egui/src/panels.rs:715-745`).

### Protect, redact, sanitize, audit
- Standard security handler R2–R6: RC4-40/128, AES-128/256, user/owner passwords with SASLprep,
  permissions, and re-encryption on save (`crates/crypt`; `doc_protect`, `doc_unprotect`).
- Redaction by rectangle, text find, word list, pattern (phone/email/credit-card/SSN/date) or whole
  pages, with FOIA/Privacy Act overlay codes; applying removes text, images, vectors, comments and
  form fields under the marks and runs a verification pass (`crates/redact/src/lib.rs:493`;
  `redact_mark`, `redact_apply`).
- Faux-redaction audit that finds text still extractable under painted boxes and unapplied marks;
  the CLI exits non-zero on findings (`doc_audit_redactions`; `pdfcraft-cli audit`;
  `crates/audit`).
- Remove hidden information / Sanitize, with categories listed first (`doc_hidden_info`,
  `doc_remove_hidden`).

### Signatures
- Sign with `.p12`/`.pfx` digital IDs, macOS Keychain identities, or the Windows certificate store;
  PAdES B-B, SHA-256 (SHA-384 for P-384 keys); certification signatures with
  no-changes/form-fill/comments levels; visible signatures with image, typed text or drawn strokes;
  self-signed ID creation; trust list; validation including changes made after signing. **Partial**
  for hardware tokens, timestamp servers and online revocation
  (`crates/sign`; `sign_document`, `sign_id_create`, `sign_keychain_ids`, `sign_windows_ids`,
  `sign_list`, `sign_trust`).

### OCR, camera, print, export, optimize, standards, accessibility, measuring
- OCR produces an invisible searchable text layer over the page image; batch recognition and
  camera-photo straightening/clean-up are separate tools. **Partial**: English/unaccented Latin
  only (`crates/ocr`; `ocr_recognize`, `ocr_recognize_files`, `page_enhance_camera`).
- Print with Acrobat-style options (ranges, subset, reverse, fit/actual/shrink/custom, multiple,
  booklet, poster, comments/forms, paper sizes, copies, duplex, grayscale, CUPS driver options) or
  write a print-ready PDF (`crates/print`, `craft-print`; `doc_print`, `printers`,
  `printer_options`, `print_readiness`).
- Export pages as PNG/JPEG/TIFF, all embedded images, reading-order text, Word `.docx`,
  PowerPoint `.pptx`, HTML or RTF. **Partial** for Office formats (basic/lossy)
  (`crates/export`; `doc_export_images`,
  `doc_export_all_images`, `doc_export_text`, `doc_export_office`; formats chosen by extension in
  `crates/engine/src/compare.rs:126-148` and `crates/engine/src/export.rs:162`).
- Reduce File Size and the full PDF Optimizer (downsample/compress, discard options), plus a space
  audit (`crates/optimize`; `doc_reduce`, `doc_optimize`, `doc_audit_space`).
- PDF/A-2b and PDF/A-3b verification and conversion. **Partial**: structural rules only, and CMYK
  documents get no output intent (`crates/preflight/src/lib.rs:31`; `pdfa_verify`, `pdfa_convert`).
- Accessibility Checker with 32 rules in 7 categories, HTML report, review records, alt text, tag
  property/sibling-order edits, and bounded text-only auto-tagging. **Partial**: no reading-order
  or table editor (`crates/a11y`; `accessibility_*` tools).
- Calibrated 2D distance/perimeter/area measurements with CSV export (`crates/measure`;
  `measure_*` tools).
- Edit existing text in place (paragraph or line, with rewrapping and formatting), move 1–1000
  mixed objects on a page as one undo step, edit images (move/crop/rotate/flip/replace/delete),
  edit added text/images/links, and import an openly licensed TTF/OTF to complete a source subset.
  **Partial** for existing text: no rotated text, vector editing or arrange/align
  (`crates/edit`; `text_edit`, `text_edit_layout`, `text_paragraphs`, `text_lines`, `object_list`,
  `object_move`, `image_edit`, `content_update`, `link_add`, `text_font_import`).
- Headers/footers with Bates numbering, watermarks (text or image) and backgrounds
  (`doc_header_footer`, `doc_watermark`, `doc_background`, `doc_remove_marks`).

### Automation surfaces (three front doors, one tool table)
- **CLI `pdfcraft-cli`**: `info`, `render`, `text`, `edit`, `combine`, `extract`, `split`, `check`
  (child-process robustness sweep), `audit`, `batch`, `tools`, `run` (single tool or JSON script),
  `ui` (drive a running app), `mcp` (opt-in server). Usage is `apps/pdfcraft-cli/src/main.rs:57`.
- **Tool table**: **170** JSON-Schema tools at this tag, with read-only/destructive hints and
  registry command ids (`crates/automation/src/tools.rs:117`). The command registry has **200**
  commands with menus, shortcuts and enabled-state (`crates/engine/src/commands.rs:163`).
- **MCP server**: opt-in, stdio only, no port; `pdfcraft-cli mcp [--root DIR] [--compact]
  [--automation-read-root DIR] [--automation-write-root DIR]`; tools plus resources for open
  documents (`crates/automation/src/mcp.rs`; `docs/mcp.md`).
- **UI control channel**: opt-in with `pdfcraft --control FILE`; loopback, random port, per-launch
  token in an owner-only file. Methods: `ui.state`, `ui.commands`, `ui.command`, `ui.set`,
  `ui.open`, `ui.inspect`, `ui.click`, `ui.focus`, `ui.resize`, `ui.quit`, `ui.drag`, `ui.move`,
  `ui.type`, `ui.key`, `ui.screenshot`, `ui.dock`, `ui.dock.reset`
  (`crates/ui-egui/src/control.rs:279-350`; `README.md` §Driving the app itself).

## Known limitations and not-implemented

- **Rendering is borrowed and fidelity is unmeasured against Acrobat.** Pages come from vendored
  `hayro` 0.7 with local patches; the replacement renderer and font engine are incomplete
  (`docs/gaps.md` gaps 2 and 12; `docs/architecture.md` §Rendering and text). README claims about
  kerning, colour emoji and blend modes are not independently verified here — **claimed but
  unverified**.
- **Existing-text editing is improved but not general.** Latin text with an embeddable matching
  face works, including full-face completion and Chinese/Japanese insertion in tested cases; text
  no available face can show is refused. Rotated text, vector editing, list/superscript
  preservation, structure-tag retention, and arrange/align remain missing or fragile
  (`docs/gaps.md` gap 3; `docs/editing-existing-text.md`; `text_edit` description in
  `crates/automation/src/tools.rs`).
- **Office import is absent; Office export is lossy.** There is no Create PDF from Word, Excel,
  PowerPoint, HTML, web page, PostScript or EPS; Word export flows text/tables and may lose layout;
  there is no `.xlsx`, `.doc`, SVG, EPS, PostScript, XML-spreadsheet or JPEG 2000 export
  (`crates/create/src/lib.rs:489`; `crates/engine/src/compare.rs:126-148`;
  `docs/gaps.md` gap 8).
- **`doc_create` text is Western European (WinAnsi) only**; other characters are refused
  (`doc_create` description). New text drawn with `page_add_text`/`text_edit` can use Japanese and
  other fallback faces.
- **OCR reads only unaccented Latin (`en`).** Models must be installed (release bundles include
  them; source builds use `cargo xtask models`, `PDFCRAFT_MODELS` overrides). No accent, Cyrillic,
  Greek, CJK, Arabic, Hebrew or Indic recognition; no editable-text OCR output
  (`crates/ocr/src/lib.rs:27`; `docs/gaps.md` gap 7).
- **No Preflight** (catalog marks it planned M11); PDF/A only 2b/3b and partial (CMYK output
  intents, veraPDF oracle not used); no PDF/X or PDF/UA verification, PDF/A-1/4, PDF/E or PDF/VT
  (`crates/engine/src/catalog.rs:408`; `docs/gaps.md` gap 9).
- **Signatures**: no PKCS #11/smart cards except the Windows certificate store; no timestamp-server
  preference, no online OCSP/CRL fetching (LTV only with caller-supplied evidence), no OS trust
  store, no EU Trusted Lists, no signing in the browser (`docs/gaps.md` gap 10;
  `sign_document` schema has no TSA argument).
- **Accessibility is checker + limited repair**: text-only auto-tagging refuses mixed content and
  existing tags; no reading-order/table editor, visual Tags/Order/Content panels or Read Out Loud;
  the app itself is not fully keyboard-operable (`docs/gaps.md` gap 11; `accessibility_autotag_apply`).
- **Forms**: wider Acrobat JavaScript object model incomplete; document actions, form submission,
  barcode fields and rich-text values missing; XFA flattening absent (`docs/gaps.md` gap 15).
- **No scanners** (TWAIN/WIA/ICA/SANE), **no GPU page rasterization** (CPU render then texture
  upload), **no pen pressure**, **no Read Out Loud** (`docs/gaps.md` gap 20).
- **Compare** has side-by-side and visual regions now, but no filtering by change type, page
  ranges or scanned-document support (`docs/gaps.md` gap 21; `crates/ui-egui/src/compare_ui.rs`).
- **Preferences are sparse** (interface language, documents/view, identity, Fill & Sign,
  JavaScript, animation effects); no print-production tools (`docs/gaps.md` gaps 18–19).
- **Performance**: the whole file is held in memory; editing peaks around two copies and saving
  around three; file-backed lazy input is blocked on the renderer (`docs/gaps.md` gap 13).
- **UI precision**: moving a selection across pages, rulers/grids/guides, multiple windows and
  split view are missing (`docs/gaps.md` gap 16).
- **Web build**: no crash-recovery store, no UI control channel transport and no `ui.open`;
  printing goes through the browser dialog; embeds only a subset of fonts (BIZ UDPGothic Regular
  plus Arab/Telu/Hebr/Thai faces) (`crates/ui-egui/src/recovery.rs:10`;
  `crates/ui-egui/src/control.rs:769,777`; `crates/fonts/build.rs`).
- **No AI/cloud features**; only a local/opt-in provider is planned (`docs/gaps.md` gap 23).
- **Other PDF gaps**: no certificate (public-key) encryption, no linearized/Fast-Web-View save,
  no portfolio view, no `.xdp` opened as a document, no Acrobat `.sequ` action files
  (`docs/file-format-parity.md`).
- **Copy-protected documents**: extraction and copy honour permissions; the owner password is
  required (`pdfcraft-cli` `text`; `text_extract`).
- **The macOS `.app` contains only the GUI**; `pdfcraft-cli` is a separate release zip
  (`crates/automation/README.md` §From an installed release; verified: no `pdfcraft-cli` in the
  bundle or on `PATH`).
- **The All tools catalogue shows planned entries** marked with their milestone; a visible tool is
  not proof it works today (`crates/engine/src/catalog.rs:75`; `crates/ui-egui/src/panels.rs:125`).

## How to operate

### Launch (macOS)
- App: `/Applications/PdfCraft.app` (bundle id `ai.storyteller.pdfcraft`, minimum macOS 11.0 —
  `Contents/Info.plist`). Binary: `/Applications/PdfCraft.app/Contents/MacOS/PdfCraft`.
- `open -a PdfCraft` or `open -a PdfCraft /path/file.pdf`. Pass flags with
  `open -a PdfCraft --args --control ~/.pdfcraft-control.json`.
- `/Applications/PdfCraft.app/Contents/MacOS/PdfCraft --version` prints `pdfcraft 0.9.0` without
  opening a window (verified on the installed bundle).
- Desktop flags (parsed in `apps/pdfcraft/src/main.rs:190-215`, applied by
  `crates/ui-egui/src/lib.rs:2453`): files…, `--version`, `--control FILE`,
  `--create-images [images…]`, `--new-window`, `--page N`, `--zoom 150`,
  `--layout single|continuous|two-up|two-page`, `--continuous on|off`, `--panel
  comments|bookmarks|pages|fields|layers|attachments|signatures|accessibility|tags|search|compare|none`,
  `--theme light|dark|system`, `--language auto|<code>`, `--mode all|read|edit|convert|sign`,
  `--tool <catalogue id>`, `--left open|closed`, `--organize on`, `--fields on`,
  `--dialog properties|security|fonts|advanced|shortcuts|split|protect|page-boxes|header-footer|
  watermark|background|export-image|word-count|export-text|export-all-images|accessibility-options|
  recognize-text|js-console|document-js|preferences|compare-files|action-wizard|pdfa|signature|
  optimize|sign|certify|number-pages|none`, `--palette <query>`, `--home on`, `--cover on|off`,
  `--default-layout …`, `--default-continuous on|off`, `--default-zoom fit-width|fit-page|<percent>`,
  `--combine-view grid|list`, `--combine-zoom 60..200`, `--grid-zoom 50..300`, `--rotate 0|90|180|270`,
  `--layer "Name=on|off"`, `--find <text>`, `--quick <tool>`, `--author <name>`.
  Unknown options fail with `unknown option`; `--page`/`--zoom`/`--layout` need an open document.
- By default the All tools/mode rail is on the left and a panel docks on the right; tools can be
  moved to the right (`--tools-side`), and `ui.dock` can open, close, activate, float or move
  panels (`crates/ui-egui/src/docking.rs`; `README.md` §Driving the app itself).

### Headless CLI (not installed with the app)
`pdfcraft-cli` is a separate signed/notarized release asset on macOS:
`pdfcraft-cli-0.9.0-macos-universal.zip`. Put it on `PATH`, or build from a checkout with
`cargo run --release -p pdfcraft-cli --`. Use the same release as the app where possible; the
control protocol is internal and may change between versions.

```sh
pdfcraft-cli info report.pdf
pdfcraft-cli text paper.pdf --page 3
pdfcraft-cli render paper.pdf --page 1 --dpi 144 --out p1.png    # .png/.jpg/.tif/.pam
pdfcraft-cli edit in.pdf --rotate 1,2:90 --delete 5 --title "Q3" --out out.pdf
pdfcraft-cli combine a.pdf b.pdf --out combined.pdf
pdfcraft-cli extract report.pdf --pages 1,3,5-8 --out highlights.pdf
pdfcraft-cli split report.pdf --every 10 --out-dir parts/
pdfcraft-cli batch scans --recursive --steps ocr,optimize --out-dir out --root .
pdfcraft-cli tools | jq '.[].name'
pdfcraft-cli run text_find doc=1 query=invoice
pdfcraft-cli run --script steps.json --root ./work --report
pdfcraft-cli audit maybe-redacted.pdf      # exits non-zero on findings
```

A script is a JSON array of `{"tool": "...", "args": {...}}` steps; one session keeps document ids
stable (`doc_open` → 1). With `--root DIR`, every read/write path, including a step's `"out"`, must
resolve inside DIR. `--report` prints one JSON document with per-step status/result.

MCP (opt-in, stdio, no port): add
`{"command":"pdfcraft-cli","args":["mcp","--root","/path/to/pdfs"]}` to the agent's MCP config.
`--compact` exposes a small core set plus `tool_search` and `tool_call`. For least privilege use
`--automation-read-root` and `--automation-write-root` instead of one broad `--root`; a missing root
grants none of its access (`docs/mcp.md`).

UI control channel (opt-in): start the app with `--control ~/.pdfcraft-control.json`, then:

```sh
pdfcraft-cli ui --control ~/.pdfcraft-control.json inspect query=rotate
pdfcraft-cli ui --control ~/.pdfcraft-control.json click label="Organize pages"
pdfcraft-cli ui --control ~/.pdfcraft-control.json key key=K modifiers='["command"]'
pdfcraft-cli ui --control ~/.pdfcraft-control.json command id=comment.square
pdfcraft-cli ui --control ~/.pdfcraft-control.json drag from='[400,300]' to='[600,420]'
pdfcraft-cli ui --control ~/.pdfcraft-control.json screenshot --out window.png
pdfcraft-cli ui --control ~/.pdfcraft-control.json quit
```

`quit` asks the normal Save/Don't save/Cancel prompt for unsaved work and never discards silently.
Keep the control file in a user-only folder, never `/tmp`.

### Document model and workflow
- One window, several documents as tabs; `--new-window` gives a launch its own window. A dot marks
  unsaved changes. Closing/quitting prompts before loss (`README.md` §Organize;
  `crates/ui-egui/src/lib.rs`).
- The Open dialog filters PDFs; dropping or passing an image/text file converts it into a new,
  unsaved PDF instead (`crates/ui-egui/src/files.rs:70-73`;
  `crates/ui-egui/src/lib.rs:1133-1141`; `crates/ui-egui/src/create_ui.rs:91-98`). Only a PDF is
  edited in place; a converted image/text file must be saved as a new PDF.
- Edits stay in memory as undo steps; autosave writes recovery snapshots every 60 seconds and
  offers recovery after a crash (`crates/ui-egui/src/recovery.rs:25`; encrypted documents stay
  encrypted on disk).
- Save (`⌘S`) writes an **incremental update appended to the same file**, preserving the original
  bytes and prior signatures; Save As (or any new path) is a full rewrite. Writes are atomic via a
  staging file (`crates/automation/src/lib.rs:906-935`; `crates/cos/src/writer.rs:180`;
  `crates/platform/src/staging.rs:73`). `doc_save` `full: true` forces the rewrite.
- A full rewrite happens where it must: redaction, PDF/A conversion, password change, sanitize,
  or Save As with garbage collection; signed documents are protected from optimizer rewrites
  (`docs/architecture.md` §Data model; `doc_optimize` description).
- Export formats are chosen by extension: images `.png/.jpg/.tif`; Office `.docx/.pptx/.html/.htm/
  .rtf`; form/comment data `.xfdf/.fdf/.xml/.xdp/.csv/.txt/.tab/.tsv`; text `.txt`; print output
  either a printer name or a PDF path (`crates/engine/src/compare.rs:143-148`;
  `crates/xfdf/src/lib.rs:49-59`; `doc_print`).

### Panels and keyboard (verified in the command registry)
Panels: comments, bookmarks, pages, fields, layers, attachments, signatures, accessibility, tags,
search, compare (`crates/ui-egui/src/lib.rs:2478-2493`).

`⌘K` command palette · `⌘F` find / `⇧⌘F` advanced search · `⌘G` / `⇧⌘G` next/previous match
(`crates/ui-egui/src/canvas.rs:2198`) · `⌘Z` / `⇧⌘Z` undo/redo · `⌘S` / `⇧⌘S` save / save as · `⌘O` open · `⌘W`
close / `⇧⌘W` close all · `⌘P` print · `⌘D` document properties · `⌘J` JavaScript console ·
`⌘B` add bookmark · `⌘,` preferences · `⌘L` full screen · `⌃⌘H` Read mode · `⌘3` fit visible ·
`⌃Tab` / `⌃⇧Tab` next/previous tab · `⌘[` / `⌘]` previous/next view · `⇧⌘N` go to page
(`crates/engine/src/commands.rs`). On Windows/Linux the command modifier is Ctrl; labels follow
the interface language, machine ids never change.

## Working with an AI agent

**Legitimate work.**
- Prefer the headless tool table over GUI automation. `pdfcraft-cli tools` (or MCP `tools/list`)
  is the capability contract for the installed version; `command_list` maps UI commands to tools.
- Prepare inputs: images (PNG/JPEG/TIFF/GIF/BMP/JP2/J2K/JPX) and `.txt` for `doc_create`;
  XFDF/FDF/XML/XDP/CSV/TXT for `doc_import_data`/`form_merge_data`; `.p12`/`.pfx` or a Keychain/
  Windows-store identity for signing; openly licensed TTF/OTF for `text_font_import`.
- Inspect and repair: `doc_info` exposes warnings and repairs; `doc_inspect` summarizes open
  documents; `doc_revisions` + `doc_open_revision` show what each incremental save appended.
- Verify with independent observations: `page_render`/`render_preview` for pixels, `text_extract`
  for text, `doc_audit_redactions` after redaction, `pdfa_verify` after PDF/A conversion, and
  external `qpdf`, `pdftotext`, `pdftoppm` or a real viewer where installed. The repo itself uses
  hayro, qpdf and poppler as oracles (`README.md` §How it's built).
- For UI work, launch with `--control`, use `ui.inspect` to get the accessibility tree, click by
  unique label or widget id, then `ui.screenshot` to confirm. Never guess coordinates from an old
  launch.
- Use `doc_batch`/`pdfcraft-cli batch` for folders; it never overwrites existing outputs and
  continues after per-file errors unless `--stop-on-error`.

**Must not.**
- Do not drive the GUI blind or assume a deterministic layout across launches; use the control
  channel and `inspect`.
- Do not assume Office/HTML/PostScript import, `.xlsx` export, SVG/EPS/PS/JP2 export, or OCR in any
  language but English.
- Do not rewrite signed documents destructively; incremental save keeps signatures valid, but any
  full rewrite invalidates certification. Keep the original bytes.
- Do not use `doc_create` for non-WinAnsi text; it will refuse. Use `page_add_text`/`text_edit` with
  an embeddable face for other scripts.
- Do not expect headless extraction of document-level attachments (the Attachments panel can open
  and save them; no automation tool does), or an engine tool for layer visibility (only the UI or
  `ui.set layer=…` on the control channel).
- Do not put the control file in a shared folder or enable the MCP server/control channel by
  default; both are opt-in and loopback-only (`README.md` §Driving the app itself).
- Do not assume `pdfcraft-cli` exists on a machine with only the macOS app installed.

## Verification protocol

Alpha-software discipline for every session:
1. **Throwaway round-trip first.** In a scratch folder, open → edit → `doc_save` to a *new* path →
   reopen with `pdfcraft-cli info/text` and in Preview/Acrobat or `qpdf --check`. Reopening only in
   PdfCraft proves little about other readers.
2. **Never trust a silent export.** Re-render exported images, re-read exported text, and open
   `.docx/.pptx` in Word/PowerPoint or LibreOffice before declaring success; Office export is known
   lossy — compare against page images.
3. **Redaction is not done until audited.** Run `pdfcraft-cli audit` (or `doc_audit_redactions`) on
   the saved file; `redact_apply`'s internal verification is a gate, not a substitute.
4. **Signatures:** after signing, use `sign_list` (and `pdfsig`/OpenSSL if available) on the saved
   file; check "changes after signing" and that the revision you expect is the one covered.
5. **Backups and versions.** Keep the original PDF before any full rewrite. Check
   `/Applications/PdfCraft.app/Contents/MacOS/PdfCraft --version` and `pdfcraft-cli --version`
   before trusting this skill's flags or tools; update apps only between projects, never mid-task.
6. **Hostile or huge files.** Use `pdfcraft-cli check` (separate child process per file) when a
   file misbehaves. Read `~/Library/Application Support/PdfCraft/logs/pdfcraft.log` for internal
   errors; treat an unexpected exit as a bug to report, not a boundary.

## Sources & evidence

- Repo: https://github.com/storytold/pdfcraft · installed app: `/Applications/PdfCraft.app` 0.9.0,
  build commit `645016addcfb9078c557f0189559ab47cdcee057`.
- Inspected commit: `645016addcfb9078c557f0189559ab47cdcee057` ("Release 0.9.0"), 2026-10-17;
  date of inspection 2026-10-18.
- Key files read: `README.md`, `ROADMAP.md`, `docs/{gaps,roadmap,architecture,file-format-parity,
  mcp,cli-batch,localization,development,word-count,editing-existing-text,editing-multiple-objects}.md`,
  `Cargo.toml`, `apps/pdfcraft/src/main.rs`, `apps/pdfcraft-cli/src/main.rs`,
  `crates/automation/{README.md,src/tools.rs,src/lib.rs,src/mcp.rs}`, `crates/engine/src/{commands.rs,
  catalog.rs,compare.rs,export.rs,lib.rs}`, `crates/ui-egui/src/{lib.rs,control.rs,recovery.rs,canvas.rs,
  compare_ui.rs,panels.rs,files.rs,system_fonts.rs}`, `crates/create/src/lib.rs`, `crates/crypt/src/lib.rs`,
  `crates/redact/src/lib.rs`, `crates/preflight/src/lib.rs`, `crates/ocr/src/lib.rs`, `crates/sign/src/lib.rs`,
  `crates/organize/src/import.rs`, `crates/xfdf/src/lib.rs`, `crates/platform/src/staging.rs`,
  `crates/fonts/build.rs`, `apps/pdfcraft-web/`, `/Applications/PdfCraft.app/Contents/Info.plist`.
- Shared libraries consulted: `storytold/craft-libs`
  (`craft-print`, `craft-quit`, `craft-ui`, `craft-docpath` pins in `Cargo.toml`).
- Companion: `evidence.md` (claim → evidence → tier table) for spot-checking.

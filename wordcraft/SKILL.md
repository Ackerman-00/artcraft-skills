---
name: wordcraft
description: >-
  WordCraft is an open-source, clean-room reimplementation of Microsoft Word in Rust (alpha,
  v0.10.0): a ribbon word processor that reads and writes .docx (password-protected included),
  opens legacy .doc, and exports PDF, plus a CLI (wordcraft-cli), a 16-tool MCP server, a
  localhost JSON control channel and a headless screenshot harness for agents. Trigger this
  skill whenever the user mentions WordCraft, .docx/.doc/.odt/.rtf/.html/.md/.tex documents in a
  WordCraft context, wordcraft-cli, WordCraft's MCP tools or control channel, personal templates,
  mail merge, macros, track changes, or asks what WordCraft can or cannot do, which formats it
  opens or saves, how to script, automate, batch-convert, verify, repair or troubleshoot it —
  even if the app is not named but the job is word-processor work ("write a .docx", "convert
  this .doc to PDF", "add comments and track changes", "mail-merge a letter", "make a report
  from Markdown"). Do not use it for Microsoft Word itself or other word processors.
---

# WordCraft

Audit basis: this checkout is tag `v0.10.0`, commit `9130181a5fdaee2293e67756fd5458c601489f3c`. The installed `/Applications/WordCraft.app` reports version `0.10.0` and its binary prints `wordcraft 0.10.0 (9130181a)`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. No `references/` directory ships with this skill: everything below is cited inline to the repo.

## Overview

WordCraft is an open-source, clean-room reimplementation of Microsoft Word (Microsoft 365) in pure Rust — "writing and document design" — by the ArtCraft team (README.md:17, README.md:372). It is at **alpha** (ROADMAP.md:3), self-rated ~60% ready for real work, ~55% for a mainstream practitioner's week and ~63% for everyday essentials (ROADMAP.md:23–25), with **498 of 513** ribbon/menu catalog features wired to live commands (97.1%; docs/parity-checklist.md:5). One codebase serves macOS, Windows, Linux, BSD and the web: egui/eframe on the GPU, no Electron (Cargo.toml:76–81, README.md:96–97). Source: GitHub **storytold/wordcraft**, MIT OR Apache-2.0 (Cargo.toml:9, README.md:372). It reads and writes Microsoft's formats from published specifications (ECMA-376/ISO 29500, MS-DOC, OASIS ODF), never from their code (README.md:109–110).

Everything user-visible is a **command with an id**; the ribbon, keyboard, command search, CLI, control channel and MCP all dispatch the same registry (README.md:105–107, AGENTS.md:43, `crates/engine/src/cmd/mod.rs::registry`).

## Capabilities (verified)

### Automation surface at a glance

| Surface | Count at v0.10.0 | Change vs the v0.9.0 skill |
|---|---|---|
| Engine commands (`CommandSpec`) | **638** | +5: `file.listTemplates`, `format.underlineColor`, `text.insertTab`, `view.formatShapePane`, `view.fullScreenView`; none removed |
| Command modules | 50 (`crates/engine/src/cmd/*.rs` minus `mod.rs`) | +2 |
| Catalog coverage | **498/513 (97.1%)** | was 492/507 (97.0%) |
| CLI subcommands | **10** | unchanged |
| MCP tools | **16** | unchanged |
| Control-channel methods | **19**, plus command-id fallthrough | unchanged |
| Interface languages | **27** | was 21; Slovenian is the newest catalog |
| Proofing languages | **11** | was 9; Czech and Indonesian are now in `PROOFED` |
| Modal dialogs | **60** | was 59 |

Do not quote the repo's own command counts: README.md:105 and README.md:200 still say 422, ROADMAP.md:21,28 says 493/508 and 433 commands, docs/mcp.md:106 says "over 270". All are stale; count with `wordcraft-cli commands --json`.

### Editing, formatting, document features
- Writing: typing/IME, AutoCorrect, list autoformat, selections, clipboard with formatting, undo/redo, find & replace incl. regex; typing behaviour is pinned to Word's by `crates/engine/src/tests_typing.rs` (docs/typing-parity.md).
- Formatting, paragraphs, styles/themes, lists, tables (styles, banded rows, merge/split, sort, formulas), pages/sections (margins, columns, headers/footers, watermark, line numbers, hyphenation, drop caps), objects (pictures with crop/recolour/background removal, shapes, text boxes, groups, drawing canvases, wrap, rotation), references (TOC, footnotes/endnotes, citations APA/MLA/Chicago/IEEE, captions, index, table of figures, Zotero), review (spelling/grammar, comments, track changes incl. moves and formatting revisions, accept/reject, compare, restrict editing), mail merge from CSV/spreadsheets, Draw-tab ink (pens, lasso, Ink to Shape, Ink Replay), Read Aloud, Print/Web/Draft/Read/Focus/Full Screen views (README.md:113–128).
- **New in 0.10**: `format.underlineColor` sets `w:u/@w:color` independently of the text colour (`{"color":"RRGGBB"|"auto"}`; `crates/engine/src/cmd/format.rs:105–106,371–379`); `text.insertTab` inserts a literal tab character, bound to `Alt+Tab` on macOS and `Mod+Tab` elsewhere (`crates/engine/src/cmd/text.rs:21–22`); `view.fullScreenView` shows the pages alone and is mutually exclusive with Focus (`crates/engine/src/cmd/view.rs:53–59`); `view.formatShapePane` opens the Format Shape pane, where shape gradients and transparency now live (`crates/engine/src/cmd/view.rs:118–122`, `crates/ui-egui/src/format_shape.rs:79–84`).

### Import / open (by extension, `crates/engine/src/io.rs:9–29` OPEN_EXTS)
- `.docx` / `.docm` / `.dotx` / `.dotm` (Word package; Strict Open XML read via namespace mapping), `.doc` / `.dot` (Word 97-2003 binary reader, `crates/docbin`), `.txt`, `.md`, `.markdown`, `.html`/`.htm`, `.rtf`, `.odt`, `.tex`/`.latex`/`.ltx`, `.xml` (Word XML Document / Flat OPC or Word 2003 XML, told apart by root element), `.json` (WordCraft's native document model), and `*.wcraft.json`.
- Extensionless or unknown-extension files open **by content** if they are Word/RTF/XML/text, with encoding detection; anything else is refused with an error (`crates/engine/src/io.rs:316–330`).
- Password-protected `.docx` opens with a password (agile encryption; `crates/docx/src/crypt.rs`); `.doc` protected with XOR/RC4/RC4 CryptoAPI also opens (`crates/docbin/src/lib.rs:85–92`) — untested on Word-written files; AES `.doc` is refused.
- Pictures: PNG, JPEG, GIF, WebP, BMP, TIFF (TIFF decodes through the `image` crate — `crates/engine/src/cmd/insert.rs:230–241`; docs/file-format-parity.md:59 still lists TIFF as unsupported: stale), plus Windows/Enhanced Metafile `.wmf`/`.emf` at their frame size (`crates/metafile`). Not SVG, ICO, HEIC.
- **New in 0.10 fidelity**: HTML import reads `<ruby>`/`<rb>`/`<rt>` back into a ruby object (`crates/formats/src/html.rs:7,13–14`; docs/file-format-parity.md:58,118); RTF import decodes the East Asian multibyte code pages (#1653); ODT reads table column widths and master-page headers/footers (docs/gaps.md:74; docs/file-format-parity.md:56); a JSON document stores pictures and kept parts as base64 (docs/file-format-parity.md:3).

### Save / native format / export (`crates/engine/src/io.rs:31` SAVE_EXTS)
- Native-lossless: `.docx`/`.docm`/`.dotx`/`.dotm` via `crates/docx` (package flavour from the extension), Word XML Document (Flat OPC) and Word 2003 XML `.xml` (`crates/docx/src/flat.rs`, `wordml2003_write.rs`), and `.json` for agents. A file opened with a password is saved with it again; exports that cannot carry one (pdf, html, txt) stay plain (apps/wordcraft-cli/src/main.rs:59–61).
- Copies/export: `.pdf` (krilla through the pinned `craft-pdf`, Cargo.toml:57, docs/shared-pdf.md), `.png` page images, `.txt`, `.md`, `.html`, `.rtf`, `.odt`, `.tex` (`crates/formats`; partial fidelity — see limitations).
- Print Markup (`--markup` / `markup: true`): comments and tracked changes in PDF/PNG, a comment list in HTML/Markdown/text (`crates/engine/src/io.rs:52–62`).
- Saves are atomic-by-design: serialize, then write an exclusively created sibling temp file, sync, replace; a failed save keeps the original bytes (docs/file-format-parity.md:180–183, "Native save-path guarantees").
- **New in 0.10 fidelity**: shape gradients and transparency (#1500), Word signature lines kept on save and still signable, table style band sizes written (#3415), tracked table/row/cell/section property changes recorded (#41 follow-up), content-control-heavy documents save in the time the controls take (32,000 controls: 3.6 s → 0.1 s, #13) — all in the change log of docs/file-format-parity.md:3 and docs/gaps.md:59,75. Radar charts are drawn (`crates/docx/src/read/chart.rs:5,83,152–164`); docs/file-format-parity.md:109 still lists radar among undrawn types: stale.

### Personal templates (new in 0.10)
- `file.listTemplates {"dir"?}` lists `.dotx`/`.dotm` in the user templates folder: top level plus one level of subfolders as categories, ≤500 templates, ≤64 categories; a network folder (`\\host\share`) is refused, and the automation read root applies to the folder and each file (`crates/engine/src/cmd/user_templates.rs:1–13,17–30`). Without `dir` it uses the folder saved in File › Options and **errors if none is saved** — a headless session has none, so always pass `dir`.
- `file.newFromTemplate {"path"}` opens the file and makes it a new, untitled, **dirty** document attached to that template, exactly as Word does (`crates/engine/src/cmd/tools.rs:490–501`). It does not check the extension: any openable document can be attached as a template.
- `file.saveTemplate {"path"}` writes the document as a template and **appends `.dotx` unless the path already ends `.dotx` or `.dotm`** (`crates/engine/src/cmd/tools.rs:502–510`). `out.docx` becomes `out.docx.dotx`; pass the full template name.
- The GUI path is `ui.saveAsTemplate`, which opens a system Save dialog in the user templates folder — unusable headlessly; use `file.saveTemplate`.

### Automation surfaces (all four drive the same commands)
- **CLI**: `wordcraft-cli convert|info|text|inspect|render|run|commands|parity|mcp|zotero` with flags `--markup`, `--update-fields`, `--format wordml2003|flatopc`, `--page`, `--scale`, `--file`, `--template`, `--cmd 'id={json}'`, `--save`, `--print`, `--author`, `--password`, `--password-file`, `--script FILE|-`, `--json`, `--markdown`, `--connect`, `--automation-read-root`, `--automation-write-root`, and Zotero's `--trace`, `--port` (apps/wordcraft-cli/src/main.rs:16–67 is the authoritative usage text; `SUBCOMMANDS` at :70).
- **`run --script`**: a JSON job file or stdin — `{"file"?…, "template"?, "commands": [{"command": id, "params"?: {…}} | id, …], "save": ["out.docx", "out.pdf"]}` — runs the commands, then saves to each output, format by extension. Relative `file`/`save` paths resolve against the script's folder; paths inside command params stay relative to the working folder; capped at 4 MiB. A failing command stops the run with exit 1 before any output is written (apps/wordcraft-cli/src/main.rs:486–492, :504–530; apps/wordcraft-cli/src/script.rs).
- **MCP server** over stdio: `wordcraft-cli mcp` (headless) or `wordcraft-cli mcp --connect 127.0.0.1:<port>` (bridged to a running app). 16 tools: `list_commands`, `execute`, `batch`, `new_document`, `open_document`, `save_document`, `type_text`, `select_text`, `get_text`, `inspect_document`, `render_page`, `parity`, and app-only `screenshot`, `click`, `key`, `ui_inspect` (`crates/mcp/src/tools.rs:55–135`, `call_tool` at :168; docs/mcp.md:102–122). Resources: `wordcraft://document`, `wordcraft://commands` (`crates/mcp/src/server.rs:28–29`). Unchanged in 0.10.
- **Control channel**: app started with `--control <port>`; JSON lines over `127.0.0.1` with a per-window key from `<settings>/control-key.local-<port>` (macOS settings folder: `~/Library/Application Support/WordCraft`; mode 0600). 19 methods: `engine.execute`, `engine.commands`, `document.inspect`, `ui.inspect`, `ui.click`, `ui.clickText`, `ui.move`, `ui.drag`, `ui.press`/`ui.release`, `ui.wheel`, `ui.key`, `ui.text`, `ui.screenshot`, `ui.render`, `ui.parity`, `ui.resize`, `ui.focus`, `app.quit`; any other method name is treated as a command id (docs/control-protocol.md:51–70). `ui.key`/`ui.text` are background-safe and reply `{"queued": true}` before the edit is applied; `ui.focus` requests native activation separately (docs/control-protocol.md:79–88).
- **Macros**: `tools.recordMacro` / `tools.macros` record and replay command sequences (`crates/engine/src/cmd/tools.rs`; README.md:171).

### Platform
- WebAssembly web build exists and is CI-checked: `apps/wordcraft-web` (`?sample`, `?webgl` URL flags; no TCP control channel, Open/Save go through the browser, apps/wordcraft-web/src/main.rs:1–8); `cargo xtask wasm` checks the layers for wasm32.
- Local recovery of unsaved work (desktop only), `recovery/` under the profile folder, covers new drafts and edits to existing files; password-protected documents get no plaintext recovery copies; headless/CLI/web sessions create none (docs/recovery.md:1–31). Recovery discovery no longer interrupts an explicitly created or opened document (docs/gaps.md:5).
- Native printing through craft-print: `ui.printSettings` (printer list, copies, duplex, grayscale, background discovery with `{"refresh":true}`), `ui.printSubmit`, `ui.print`, `file.printPdf` (also takes `paper` to scale onto another paper size) (docs/control-protocol.md:101–120; docs/gaps.md:60).
- Zotero integration (`crates/zotero`, docs/zotero.md) — needs the Zotero desktop app running. In-app: `ui.zotero.addEditCitation|addEditBibliography|addNote|refresh|removeCodes|setDocPrefs|status|answer`; from a terminal: `wordcraft-cli zotero <command> <file>`.

## Known limitations and not-implemented

Ranked shortfalls with evidence are in **docs/gaps.md** — read it before promising anything. The blocking (beta) list, gaps #1–#7 (docs/gaps.md:88; rows at :55–61):

1. **DOCX has no real-world corpus test**: the repo says no corpus of files from Word, Google Docs, LibreOffice and Pages exists and gap #1 is still open (docs/gaps.md:55). Treat this as **uncertain**: two revision entries cite a 251-document corpus compared against Word PDFs (docs/layout-parity.md:283, docs/file-format-parity.md:311), which contradicts "not started". Do not assume either way; round-trip the user's file.
2. **Word's native ink is not drawn from its strokes** (its picture fallback shows) and **OLE objects show only their picture**; every ink form, drawing canvas (`wpc`), group shape (`wpg`), chart and SmartArt is preserved and written back with all parts (docs/gaps.md:58).
3. **Field crashes and freezes**: startup crash on Intel UHD Graphics (#170), macOS 12.7.6 Intel crash (#979), Thai-font and font-selector freezes (#59, #31) remain open; 197 open issues as of 2026-10-12 (docs/gaps.md:56). Save-path reliability was narrowed but not closed (docs/gaps.md:14).
4. **Pagination differs from Word**: no Aptos-metric font, legacy compatibility options partial, no page-by-page comparison harness (docs/gaps.md:57).
5. Content controls, move tracking and formatting revisions have landed; still missing: drag-and-drop moves (no text drag yet), tracked style-definition changes, custom-XML binding evaluation (docs/gaps.md:59).
6. Print dialog depth: driver tray/options and pages per sheet remain (docs/gaps.md:60).
7. 60 modal dialogs vs Word's ~100 (docs/gaps.md:61; `Dialog` enum, `crates/ui-egui/src/dialogs.rs:145`).

Other verified gaps:
- **Charts/SmartArt from Word are read-only** (no embedded-workbook editing); no combo/3D/stock charts (placeholder shown); radar charts are now drawn; WordCraft's own charts and SmartArt are editable (docs/gaps.md:67).
- **`.doc` is read-only** — WordCraft never writes Word 97-2003 (`crates/docbin/src/lib.rs:3–4`); Word 6/95 files are refused. No PDF Reflow, no MHT, no Works/WordPerfect (docs/gaps.md:68, :80, :84).
- **No VBA execution** (macros in `.docm` are preserved, never run), no Office add-ins, no cloud storage, no real-time co-authoring (docs/gaps.md:79).
- 3D models are dropped; `w:fitText` is not read or written. Legacy `w:ffData` form fields are kept raw and written back; glossary/building blocks and `w:eastAsianLayout` round-trip (docs/file-format-parity.md:87,102,110–111).
- **Writing fidelity is partial for non-DOCX formats**: RTF and ODT ~50%, HTML ~60%, Word 2003 XML write drops shapes/charts/equations and "not yet checked in Word" (docs/file-format-parity.md:55–61). RTF/ODT now write sections; notes and comments in RTF/ODT remain open (docs/gaps.md:74).
- **Proofing** (`crates/proof/src/lang.rs:65–77` PROOFED) covers **11** variants: English (US, UK, Canada), Polish, Portuguese, Italian, Croatian, Turkish, Russian, Czech, Indonesian — most via Hunspell dictionaries installed on the system, not bundled (docs/spelling-dictionaries.md); Bulgarian and German have hyphenation only; everything else is left unmarked (docs/gaps.md:63).
- **RTL/East Asian depth** is incomplete (docs/gaps.md:70–71).
- Mail merge sources: CSV/TSV/TXT (any common encoding) and `.xlsx/.xlsm/.xls/.ods` only; recipient search/filter and merged-only view exist; no Outlook/Access/database sources, no email merge (docs/gaps.md:78; `crates/formats/src/sheet.rs`).
- No in-app AI assistant (agent control is external, over CLI/MCP) (docs/gaps.md:82).
- Default shortcuts: 140 (macOS) / 158 (Linux/Windows) of Word's ~250 (docs/gaps.md:81).
- View windows (Side by Side, Arrange All, Switch Windows) missing (docs/gaps.md:83); one document per window, no tabs (below).
- **Personal templates are narrow**: `.dotx`/`.dotm` only, top level plus one subfolder level, ≤500 entries, network folders refused, and the desktop GUI's template picker needs a saved folder in File › Options (docs/ui-parity.md:286, `crates/engine/src/cmd/user_templates.rs:1–13`).
- The **desktop app's automation is not confined**: `--automation-read-root`/`--automation-write-root` apply to the headless MCP server only and are an error with `--connect` (docs/mcp.md:87).
- docs/gaps.md has duplicated rows (#19/#20/#21); the later entry of each pair is the current one.

## How to operate

Launch (macOS):
- App: `open -a WordCraft` or `open -a WordCraft --args <file.docx>`. Binary: `/Applications/WordCraft.app/Contents/MacOS/WordCraft`. Bundle id `ai.storyteller.wordcraft`.
- App flags (`apps/wordcraft/src/main.rs`): `wordcraft [--sample] [--control PORT] [FILE…]`; `--version`, `-h|--help`. A bad `--control` port exits with status 2.
- **`wordcraft-cli` is not inside the app bundle**. Get it from the release artifact `wordcraft-cli-<ver>-macos-universal.zip` (README.md:270, packaging/macos/package.sh) or build it: `cargo run --release -p wordcraft-cli -- <args>`.
- Useful environment variables: `WORDCRAFT_CONTROL_PORT`, `WORDCRAFT_CONTROL_KEY` (for `mcp --connect`), `WORDCRAFT_PROFILE_DIR` (isolated profile incl. recovery/keys), `WORDCRAFT_NO_PREFS` (agents' test runs; no prefs, no recovery, no key file; docs/recovery.md:28), `WORDCRAFT_PASSWORD`, `WORDCRAFT_REGION=en-US` (paper size on headless runs), `RUST_LOG`.

Document model: **one document per window, no tabs** — `WordApp` holds a single `Session` (`crates/ui-egui/src/lib.rs:524–525`); document-to-document windows are a known gap (docs/gaps.md:83).

Core commands (exact ids, from `crates/engine/src/cmd/file.rs`, `cmd/tools.rs` and `cmd/user_templates.rs`):
`file.new {"template": "blank|sample|letter|resume|report"}` (an unrecognised name silently yields a blank document), `file.open {"path": …, "password"?}`, `file.save {"path"?, "password"?, "markup"?, "format"?}`, `file.saveAs`, `file.encrypt`, `file.rename {"name"}` (the extension is kept, so pass the name with or without it; `crates/engine/src/cmd/file.rs:76`), `file.exportPdf {"path": …, "markup"?}`, `file.exportPng {"path":…, "page"?, "scale"?}`, `file.printPdf {"path", "range"?, "pages"?, "copies"?, "collate"?, "paper"?}`, `file.close {"force"?}` (without `force` an unsaved document errors instead of prompting — closing closes the document, not the app: the window stays and `file.new`/`file.open` continues there), `file.setAuthor {"name"}`, `document.inspect`, `document.text`, `review.trackChanges {"value": true}`, `file.listTemplates {"dir"?}`, `file.newFromTemplate {"path"}`, `file.saveTemplate {"path"}`.

CLI recipes (verified usage strings, apps/wordcraft-cli/src/main.rs:16–67):
```sh
wordcraft-cli convert report.docx report.pdf        # docx, doc [read], pdf, odt, rtf, html, md, tex, txt, json, png, xml
wordcraft-cli render report.docx out.png --page 2 --scale 2   # scale defaults to 2.0, page to 1
wordcraft-cli text report.docx                      # plain text, list labels kept
wordcraft-cli info report.docx                      # pages, words, paragraphs, properties (JSON)
wordcraft-cli inspect report.docx                   # structure as JSON
wordcraft-cli run --template sample --cmd 'select.text={"text":"Membership"}' \
  --cmd format.bold --save out.docx
wordcraft-cli run --script job.json                 # commands + saves from a JSON file (- = stdin)
wordcraft-cli run --file in.docx --cmd edit.undo --cmd 'file.exportPdf={"path":"out.pdf"}'
wordcraft-cli convert locked.docx out.pdf --password '…'      # or --password-file / WORDCRAFT_PASSWORD
wordcraft-cli commands --json                       # every command id, label, params, shortcut
wordcraft-cli mcp --author "Claude (copyedit)" \
  --automation-read-root project --automation-write-root project/out
wordcraft-cli zotero refresh paper.docx --save paper.docx
```
Exit status: 0 on success (a closed stdout pipe also exits 0), 1 on error with the message on stderr (apps/wordcraft-cli/src/main.rs:689–696). Failures never leave a half-written output file for `render`/`run` (apps/wordcraft-cli/src/main.rs:504–530).

Using a personal template headlessly (no `file.new` template name exists for these):
```sh
wordcraft-cli run --cmd 'file.listTemplates={"dir":"templates"}' --print   # discovery
wordcraft-cli run --cmd 'file.newFromTemplate={"path":"templates/Contract.dotx"}' \
  --cmd 'select.text={"text":"[Client]"}' --cmd 'text.insert={"text":"Acme Ltd"}' --save out.docx
wordcraft-cli run --file out.docx --cmd 'file.saveTemplate={"path":"templates/Acme contract.dotx"}'
```
`file.newFromTemplate` leaves the document untitled and dirty; save it to a `.docx` path outside the templates folder — saving into that folder is how stray templates pile up.

Driving the running app (control channel):
```sh
open -a WordCraft --args --control 7981
cat "$HOME/Library/Application Support/WordCraft/control-key.local-7981"
# then one JSON object per line to 127.0.0.1:7981, e.g.
{"id":1,"key":"<key>","method":"engine.execute","params":{"command":"text.insert","params":{"text":"Hello"}}}
{"id":2,"key":"<key>","method":"ui.screenshot","params":{"path":"shot.png"}}
```
An unauthorised request gets `{"ok":false,"error":"unauthorized"}` and the connection closes (docs/control-protocol.md:36–37); an idle connection is closed after 30 s without an authorised request. `wordcraft-cli mcp --connect` sends the key only to loopback addresses; to drive an app on another machine, forward its port and set `WORDCRAFT_CONTROL_KEY` (docs/control-protocol.md:44–49). Open/Save/Export pick formats by file extension in both the CLI and the app (`crates/engine/src/io.rs`); `--save`/`file.save` over an existing file replaces it in place.

Reading the app's own diagnostics: `<settings>/logs/wordcraft.log` (rotated to `.1`/`.2`, capped at 16 MiB; `--version` writes nothing; `WORDCRAFT_NO_PREFS` runs log to stderr only — README.md:175–183). Unreadable .docx parts, pictures/fonts a PDF export left out, and recovered panics land there.

## Working with an AI agent

Legitimate, reliable agent work with WordCraft:
- **Do document work headlessly.** `wordcraft-cli mcp`, `wordcraft-cli run` (flags or `--script`) need no window, no focus and no GUI driving. Verify your own work with `inspect_document` / `get_text` / `render_page` instead of screenshots (docs/mcp.md:113).
- **Prepare inputs**: write Markdown/HTML/CSV/text in the shell and bring it in (`open_document`, `insert.textFromFile`, `mailings.recipients` for `.csv/.tsv/.txt` with encoding detection and `.xlsx/.xlsm/.xls/.ods`, `insert.picture` with a path or base64 bytes).
- **Produce deliverables**: convert/export to PDF/ODT/RTF/HTML/MD/tex/txt/PNG from the CLI (docx and pdf in one `run --script`), and hand the `.docx` on for Word (README.md:99).
- **Attribute your edits**: pass `--author "Claude (copyedit)"` (or `file.setAuthor`) so reviewers can tell agent edits from people's, and turn tracking on explicitly with `review.trackChanges {"value": true}` (docs/mcp.md:39–46).
- **Confine yourself**: run the headless MCP server with `--automation-read-root`/`--automation-write-root` (a missing root grants none of that access; paths are resolved with links followed — docs/mcp.md:48–87). This also bounds the personal-templates folder.
- **Repair/interpret native projects**: the native format is `.docx` itself; `.json` is the engine's own model (media bytes and opaque parts included as base64). Recovery snapshots are versioned JSON under `recovery/` and only the last valid generation is guaranteed (docs/recovery.md).
- **Do not**: drive the GUI blind by clicking at guessed coordinates — prefer commands; assume SVG/ICO/HEIC images load (they don't); assume `.doc` can be written (it can't); assume charts, SmartArt, OLE or native ink *from Word* can be edited (they are preserved through saves, not editable; only WordCraft's own charts and SmartArt are editable); assume `.docx` fidelity on real-world files (gap #1); assume the headless session writes recovery copies (it doesn't); call `ui.saveAsTemplate` headlessly (it opens a system dialog).
- **Watch these footguns**: `file.saveTemplate` appends `.dotx` (`out.docx` → `out.docx.dotx`); `file.new {"template": "MyTemplate"}` silently gives a blank document — use `file.newFromTemplate {"path"}`; `file.listTemplates` without `dir` errors when no folder is saved; `review.trackChanges` without `value` *toggles* (it can turn tracking off in a document saved with it on); `file.close` over the control channel errors on unsaved changes unless `{"force": true}` (which discards them); `ui.key`/`ui.text` replies `{"queued": true}` before the edit has been applied — inspect document/widget state before the next dependent step (docs/control-protocol.md:79–88).

Headless UI screenshots (no focus stealing, works with a locked screen):
`cargo run --release -p wordcraft-ui-egui --example ui_shot -- script.jsonl`
(JSON-line control requests plus `{"shot": "<path>.png"}`, `{"steps": n}`, `{"wait": ms}`, `{"empty": true}` to skip the sample document; crates/ui-egui/examples/ui_shot.rs:1–13).

## Verification protocol

Alpha software that never crashes by design but is unproven on real-world files: trust nothing you did not re-open.

1. **Throwaway round-trip first**: new → type/format → save `.docx` → reopen → export `.pdf`, all in a scratch directory (`wordcraft-cli run --template blank --cmd … --save t.docx`, then `wordcraft-cli convert t.docx t.pdf`, then `wordcraft-cli inspect t.docx`).
2. **Never trust a silent export**: the CLI prints `wrote <path>` only after the command returned Ok, and a failing command writes nothing; still check the file exists, is non-zero, and re-read it. PDFs don't open in WordCraft — check a PDF elsewhere, or render the page with `wordcraft-cli render t.docx page.png` and look at the PNG.
3. **Compare structure, not just text**: `inspect`/`document.inspect` shows styles, tables, sections — use it to catch silent loss (the known failure mode is content dropped without a warning; docs/gaps.md #1).
4. **Keep the user's original untouched**: work on a copy; WordCraft's save replaces the file in place (safely, but in place). Recovery copies exist for the desktop app only, are unencrypted, and the newest edits before a crash can be lost (docs/recovery.md).
5. **Version and back up** project files per session; update the app only between projects (the launcher auto-updates; the version you script against may change).
6. **Re-check the command set you script against**: re-read `wordcraft-cli commands --json` on the installed build and look for the ids you call; the repo's documentation counts drift for months.

## Sources & evidence

- Repo: https://github.com/storytold/wordcraft (org `storytold`), inspected read-only at **tag `v0.10.0`**, commit **`9130181a5fdaee2293e67756fd5458c601489f3c`** ("Release 0.10.0", 2026-10-22).
- Installed app `/Applications/WordCraft.app` is exactly this release: `CFBundleShortVersionString` and `CFBundleVersion` are `0.10.0` (bundle id `ai.storyteller.wordcraft`), and the binary prints `wordcraft 0.10.0 (9130181a)`. If your installed version differs, verify against it (`wordcraft --version`, `wordcraft-cli --version`).
- Key files read: README.md, ROADMAP.md, Cargo.toml, AGENTS.md, docs/{gaps,file-format-parity,mcp,control-protocol,recovery,zotero,parity-checklist,shared-pdf,spelling-dictionaries,ui-parity,layout-parity,localization-parity}.md, apps/wordcraft/src/main.rs, apps/wordcraft-cli/src/{main.rs,script.rs}, crates/engine/src/{io.rs,io_ext.rs,catalog.rs,cmd/mod.rs,cmd/file.rs,cmd/tools.rs,cmd/user_templates.rs,cmd/format.rs,cmd/text.rs,cmd/view.rs,cmd/insert.rs,tests_typing.rs,session.rs}, crates/docx/src/crypt.rs, crates/docbin/src/lib.rs, crates/formats/src/{html.rs,sheet.rs}, crates/mcp/src/{tools.rs,server.rs}, crates/control-key/src/lib.rs, crates/proof/src/lang.rs, crates/ui-egui/src/{lib.rs,dialogs.rs,control.rs,format_shape.rs,backstage.rs,i18n/mod.rs}, crates/ui-egui/examples/ui_shot.rs, apps/wordcraft-web/src/main.rs.
- Shared libraries: `storytold/craft-libs` — WordCraft pins `craft-pdf` (PDF writing) and prints through craft-print (Cargo.toml:57,105–106; docs/shared-pdf.md).
- Diffed v0.9.0..v0.10.0 (1,547 commits) to separate new capability from carried-over behaviour; every carried-forward caution was re-checked against this tag.
- Nothing was built, modified or launched to write this skill; the installed app was only version-checked from its binary. Where the repo contradicts itself (doc counts, gap #1, proofing/language lists, TIFF, radar charts) the contradiction is stated in place rather than resolved by guesswork.

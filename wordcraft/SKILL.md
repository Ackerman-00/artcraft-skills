---
name: wordcraft
description: >-
  WordCraft is an open-source, clean-room reimplementation of Microsoft Word in Rust (alpha,
  v0.11.0): a ribbon word processor that reads and writes .docx (password-protected included),
  opens legacy .doc, and exports PDF, plus a CLI (wordcraft-cli), a 16-tool MCP server, a
  localhost JSON control channel and a headless screenshot harness for agents. Trigger this skill
  whenever the user mentions WordCraft, .docx/.doc/.odt/.rtf/.html/.md/.tex documents in a
  WordCraft context, wordcraft-cli, WordCraft's MCP tools or control channel, personal templates,
  mail merge, macros, track changes, or asks what WordCraft can or cannot do, which formats it
  opens or saves, how to script, automate, batch-convert, verify, repair or troubleshoot it —
  even if the app is not named but the job is word-processor work ("write a .docx", "convert this
  .doc to PDF", "add comments and track changes", "mail-merge a letter", "make a report from
  Markdown"). Do not use it for Microsoft Word itself or other word processors.
---

# WordCraft

Audit basis: this checkout is tag `v0.11.0`, commit `e31f2f06a5f8004ceaa88f68c00b47908e321aa4`. The installed `/Applications/WordCraft.app` reports version `0.11.0` (`CFBundleShortVersionString` and `CFBundleVersion`) with bundle id `ai.storyteller.wordcraft`, and its binary prints `wordcraft 0.11.0 (e31f2f06)`, so the bundle matches this source. **Verify against your installed version** (`wordcraft --version`, `wordcraft-cli --version`) if the ArtCraft Launcher has auto-updated since. No `references/` directory ships with this skill: everything below is cited inline to the repo.

## Overview

WordCraft is an open-source, clean-room reimplementation of Microsoft Word (Microsoft 365) in pure Rust — "writing and document design" — by the ArtCraft team (README.md:17, README.md:372). It is at **alpha** (ROADMAP.md:3): self-rated ~60% ready for real work, ~55% for a mainstream practitioner's week and ~63% for everyday essentials (ROADMAP.md:25–27), with **504 of 520** ribbon/menu catalog features wired to live commands (96.9%; docs/parity-checklist.md:5). One codebase serves macOS, Windows, Linux, BSD and the web: egui/eframe on the GPU, no Electron (Cargo.toml:78–81, README.md:103–104). Source: GitHub **storytold/wordcraft**, MIT OR Apache-2.0 (Cargo.toml:9, README.md:372). It reads and writes Microsoft's formats from published specifications (ECMA-376/ISO 29500, MS-DOC, OASIS ODF), never from their code (README.md:109–110).

Everything user-visible is a **command with an id**; the ribbon, keyboard, command search, CLI, control channel and MCP all dispatch the same registry (README.md:105–107, AGENTS.md:43, `crates/engine/src/cmd/mod.rs:61`).

## Capabilities (verified)

### Automation surface at a glance

Every number below was re-counted from this tag's code on 2026-10-26; the repo's own prose counts are stale (see the note under the table).

| Surface | v0.11.0 | Change since v0.10.0 |
|---|---|---|
| Engine commands (`CommandSpec::new` with a literal id) | **643** | **+5**: `mailings.first`, `mailings.last`, `mailings.goToRecord`, `mailings.printDocuments` (mail merge record navigation and Print Documents, `crates/engine/src/cmd/mailings.rs:442–450,479–487`), `view.readPageColor` (`crates/engine/src/cmd/view.rs:40–42`); **0 removed** |
| Command modules | 50 files under `crates/engine/src/cmd/` (44 register specs, 6 are helpers) | unchanged |
| Catalog coverage | **504 / 520 (96.9%)** | was 498/513 (97.1%); `docs/parity-checklist.md:5`, floor test `crates/engine/src/catalog.rs:590` |
| CLI subcommands | **10** | unchanged (`apps/wordcraft-cli/src/main.rs:70`) |
| CLI flags | **21** plus `-h/--help`, `--version` | unchanged |
| MCP tools | **16** | unchanged (`crates/mcp/src/tools.rs:55`, `docs/mcp.md:105–122`) |
| Control-channel methods | **19**, plus command-id fallthrough | unchanged (`crates/ui-egui/src/control.rs`, `docs/control-protocol.md:51–75`) |
| Interface languages | **27** | unchanged count; the catalogs moved out of this repo into `storytold/craft-i18n` (`crates/ui-egui/src/i18n/mod.rs:73`, `craft-i18n.rev`) |
| Proofing variants | **15** | **+4**: Spanish `es`, `es-MX`, `es-419`, `es-UY` (`crates/proof/src/lang.rs:82–98,104–140`) |
| Dialog names (`Dialog::name`) | **89** | **+3**: `tableToText` (Convert to Text), `mergeRecords` and `printRecords` (Finish & Merge records, #3028); docs claim 60 / 62 — both stale, see below |
| Default shortcuts | 164 specs carry a `.key()`; **145 active on macOS** (19 are non-macOS-only) | was 163 / 145 on macOS; +1 non-macOS binding (`Mod+Alt+H` for highlight). docs say 140/158 — stale |
| Open / save extensions | 19 / 14 | unchanged (`crates/engine/src/io.rs:9,31`) |

Do not quote the repo's command counts: README.md:105 and README.md:200 still say 422, ROADMAP.md:23,30 say 493/508 and 433, docs/mcp.md:109 says "over 270". All are stale; count with `wordcraft-cli commands --json`. The dialog count is the other way round: docs/gaps.md:66 says "60 modal dialogs" and docs/ui-parity.md:34 says 62, but the code answers to **89** distinct names — 50 top-level `Dialog` variants (`crates/ui-egui/src/dialogs.rs:145`), 46 of which are single dialogs yielding 52 names (Find → find/replace/goto, TableStyle → new/modify, MergeRecords, FieldCode, MergeRule), plus 37 names from the four container variants in `crates/ui-egui/src/dialogs_insert.rs`, `dialogs_layout.rs`, `dialogs_review.rs` and `dialogs_refs.rs` (`Dialog::name`, `crates/ui-egui/src/dialogs.rs:967`).

### New in v0.11.0 (verified against the v0.10.0 source)

- **Mail-merge record navigation and record ranges**: `mailings.first`, `mailings.last`, `mailings.goToRecord {"record": n}` (1-based; out-of-range clamps to the first/last record, non-integers refused), and `mailings.printDocuments` (Finish & Merge → Print Documents: merges the chosen records, then asks the app for the print dialog; it drops any `path`) (`crates/engine/src/cmd/mailings.rs:442–487`).
- **Reading page colour**: `view.readPageColor {"value": "none"|"sepia"|"inverse"}`; Read Mode now has its own catalog rows (`view.readColumnWidth`, `view.readPageColor` live, `view.readLayout` still missing) (`crates/engine/src/cmd/view.rs:40–42`, docs/parity-checklist.md:66–68).
- **Spanish proofing** in four varieties, from the system Hunspell dictionaries (`crates/proof/src/lang.rs:82–98,104–140`).
- **Highlight toggling**: `format.highlight` with no `color` now toggles the last chosen colour off when the whole selection has it; an explicit colour still sets (`crates/engine/src/cmd/format.rs:109–114`). On macOS no default key (⌘⌥H is taken); elsewhere `Mod+Alt+H`.
- **AutoFormat As You Type `*bold*` / `_italic_`**: `tools.autocorrect {"boldItalic": true}` (off by default) (`crates/engine/src/cmd/tools.rs:339,458–462`).
- **Convert to Text dialog** and `table.toText {"separator": "paragraph|tab|comma|other", "char"}` — selected rows only if rows are selected (`crates/engine/src/cmd/table.rs:174–175`).
- **Field depth**: document-information fields (TITLE, SUBJECT, AUTHOR, KEYWORDS, COMMENTS, LASTSAVEDBY, REVNUM, NUMCHARS…) update with the other fields (`crates/engine/src/cmd/references.rs:979–1067`); `\* Upper|Lower|Caps|FirstCap`, `\* CardText|OrdText`, `\* DollarText`, `\* Hex`, `\* ArabicDash` in numbers (`crates/layout/src/fields.rs:128–150,243–251`).
- **Restrict Editing is enforced on file commands and identity**: `file.*` commands that change the document are refused on a protected document, `file.setAuthor` (and the CLI `--author`) cannot change the session name under protection, a protected document is un-protected only with `review.restrict {"stop": true}`, and restoring a version keeps protection and its password (`crates/engine/src/cmd/protect.rs:23–25,232–240`, docs/gaps.md:171,173).
- **Line caps**: DrawingML `cap` (flat/square/round) and VML end caps are read, saved, drawn and exported; absent caps default to flat (`crates/doc/src/connector.rs:19`, `crates/docx/src/read/story.rs:1549`, `crates/docx/src/write/story.rs:1100–1127`).
- **A command that changes nothing is not an edit**: no undo step, no dirty flag, redo stack survives (`crates/engine/src/session.rs:1527`).
- **DOCX remembers an unset default font size**: written as 11 pt instead of being left out and read back as 10 pt (`crates/docx/src/write/mod.rs:725–727`).
- **MCP bridge starts before the app**: `wordcraft-cli mcp --connect HOST:PORT` validates the address at startup and, when the app is not listening yet, serves anyway and retries on each call (`apps/wordcraft-cli/src/main.rs:380–387,590–620`, docs/mcp.md:14–18).
- **`type_text {"paragraphs": true}`** splits lines into paragraphs in one command and one undo step (10,000 lines ≈ 10 ms; the breaks are plain breaks, so AutoCorrect does not run on them) (docs/mcp.md:114, `crates/mcp/src/tools.rs`).
- **Interface translations are external**: `crates/ui-egui/src/i18n/mod.rs:1–30` — catalogs live in `storytold/craft-i18n`, embedded at build time from the SHA in `craft-i18n.rev`; a build without `CRAFT_I18N_DIR` is English only.
- App-only commands are unchanged: the front end dispatches **31 `ui.*` ids** (`crates/ui-egui/src/lib.rs:1572–1854`: tabs, dialogs, theme/language/interface size, print settings, file browser, save-as-template…) plus the **8 `ui.zotero.*`** ones (`crates/ui-egui/src/zotero.rs:67–91`), the same sets as v0.10.0. They exist only with a running app: the headless registry has none, and `engine.commands` over the control channel lists them next to the 643 engine commands (`crates/ui-egui/src/control.rs:142–152`).

### Editing, formatting, document features
- Writing: typing/IME, AutoCorrect, list autoformat, selections, clipboard with formatting (HTML/RTF from other programs), undo/redo incl. an undo-history list (`edit.undoTo`, `edit.undoHistory`), find & replace with regex; typing behaviour is pinned to Word's by `crates/engine/src/tests_typing.rs` (docs/typing-parity.md).
- Formatting, paragraphs, styles/themes/style sets, lists, tables (styles with band sizes, banded rows, merge/split, sort, formulas, Convert to Text), pages/sections (margins, columns, headers/footers, watermark, line numbers, hyphenation, drop caps, page borders), objects (pictures with crop/recolour/background removal, shapes, text boxes, groups, drawing canvases, wrap, free rotation), references (TOC, footnotes/endnotes, citations APA/MLA/Chicago/IEEE, captions, table of figures, index, cross-references, Zotero), review (spelling/grammar, comments with local-time stamps, track changes incl. moves and formatting revisions, accept/reject, compare, restrict editing), mail merge (CSV/spreadsheets, rules, Finish & Merge, Print Documents), Draw-tab ink, Read Aloud, Print/Web/Draft/Read/Focus/Full Screen views (README.md:114–128, docs/parity-checklist.md).
- Content controls (`w:sdt`), move tracking (`w:moveFrom`/`w:moveTo`, `w:doNotTrackMoves`), formatting revisions (`w:rPrChange`…`w:sectPrChange`) and glossary/building blocks round-trip (docs/gaps.md:64,191).

### Import / open (by extension, `crates/engine/src/io.rs:9–29` OPEN_EXTS)
- `.docx` / `.docm` / `.dotx` / `.dotm` (Word package; Strict Open XML read via namespace mapping), `.doc` / `.dot` (Word 97-2003 binary reader, `crates/docbin`), `.txt`, `.md`, `.markdown`, `.html`/`.htm`, `.rtf`, `.odt`, `.tex`/`.latex`/`.ltx`, `.xml` (Word XML Document / Flat OPC or Word 2003 XML, told apart by root element), `.json` (WordCraft's native document model), and `*.wcraft.json`.
- Extensionless or unknown-extension files open **by content** when they are Word/RTF/XML/text, with encoding detection; binary files are refused with an error (`crates/engine/src/io.rs:326–360`).
- Password-protected `.docx` opens and saves with a password (agile encryption, `crates/docx/src/crypt.rs`); `.doc` protected with XOR/RC4/RC4 CryptoAPI opens (`crates/docbin/src/crypt.rs:1–20`) — untested on Word-written files; AES `.doc` is refused (docs/gaps.md:67).
- Pictures: PNG, JPEG, GIF, WebP, BMP, TIFF, plus Windows/Enhanced Metafile `.wmf`/`.emf` at their frame size (`crates/engine/src/cmd/insert.rs:230–241`, `crates/metafile`). Not SVG, ICO, HEIC.

### Save / native format / export (`crates/engine/src/io.rs:31` SAVE_EXTS)
- Native-lossless: `.docx`/`.docm`/`.dotx`/`.dotm` via `crates/docx` (package flavour from the extension), Word XML Document (Flat OPC) and Word 2003 XML `.xml` (`crates/docx/src/flat.rs`, `wordml2003_write.rs`), and `.json` for agents. A file opened with a password is saved with it again; exports that cannot carry one (pdf, html, txt) stay plain (`crates/engine/src/io.rs:382–388`).
- Copies/export: `.pdf` (krilla through the pinned `craft-pdf`, Cargo.toml:57, docs/shared-pdf.md), `.png` page images, `.txt`, `.md`, `.html`, `.rtf`, `.odt`, `.tex` (`crates/formats`; partial fidelity — see limitations). PDF/PNG follow the Numeral setting for digit shapes (`crates/engine/src/io.rs:52–62`, `crates/engine/src/cmd/file.rs:375`).
- Print Markup (`--markup` / `markup: true`): comments and tracked changes in PDF/PNG, a comment list in HTML/Markdown/text (`crates/engine/src/io.rs:52–62`).
- `.doc` cannot be written: saving to a `.doc`/`.dot` name returns "can't save as `.doc`" (`crates/engine/src/io.rs:359–376`; `crates/docbin/src/lib.rs:1–8` has no writer).
- Saves are atomic-by-design: serialize, then write an exclusively created sibling temp file, sync, replace; a failed save keeps the original bytes (docs/file-format-parity.md, "Native save-path guarantees"; `crates/engine/src/io/safe_save.rs`).

### Personal templates
- `file.listTemplates {"dir"?}` lists `.dotx`/`.dotm` in the user templates folder: top level plus one level of subfolders as categories, ≤500 templates, ≤64 categories, ≤10,000 directory entries; a network folder (`\\host\share`) and a relative path are refused, and the automation read root applies to the folder and each file (`crates/engine/src/cmd/user_templates.rs:1–30,67–80`). Without `dir` it uses the folder saved in File › Options and **errors if none is saved** — a headless session has none, so always pass `dir`.
- `file.newFromTemplate {"path"}` opens the file and makes it a new, untitled, **dirty** document attached to that template (`crates/engine/src/cmd/tools.rs:534–542`). It does not check the extension.
- `file.saveTemplate {"path"}` writes the document as a template and **appends `.dotx` unless the path already ends `.dotx` or `.dotm` (any case)**; `out.docx` becomes `out.docx.dotx` (`crates/engine/src/cmd/tools.rs:546–554`).
- The GUI path is `ui.saveAsTemplate` (system Save dialog in the user templates folder) — unusable headlessly; use `file.saveTemplate`.

### Automation surfaces (all four drive the same commands)
- **CLI**: `wordcraft-cli convert|info|text|inspect|render|run|commands|parity|mcp|zotero` with flags `--markup`, `--update-fields`, `--format wordml2003|flatopc`, `--page`, `--scale`, `--file`, `--template`, `--cmd 'id={json}'`, `--save`, `--print`, `--author`, `--password`, `--password-file`, `--script FILE|-`, `--json`, `--markdown`, `--connect`, `--automation-read-root`, `--automation-write-root`, and Zotero's `--trace`, `--port` (apps/wordcraft-cli/src/main.rs:16–67 is the authoritative usage text; `SUBCOMMANDS` at :70).
- **`run --script`**: a JSON job file or stdin — `{"file"?, "template"?, "commands": [{"command": id, "params"?: {…}} | id, …], "save"?: ["out.docx", "out.pdf"]}` — runs the commands, then saves to each output, format by extension. Relative `file`/`save` paths resolve against the script's folder; paths inside command params stay relative to the working folder; capped at 4 MiB, 100,000 commands, 64 outputs. A failing command stops the run with `command N (id): …` and exit 1 before any output is written (apps/wordcraft-cli/src/main.rs:486–547; apps/wordcraft-cli/src/script.rs:16–21).
- **MCP server** over stdio: `wordcraft-cli mcp` (headless) or `wordcraft-cli mcp --connect 127.0.0.1:<port>` (bridged to a running app). 16 tools: `list_commands`, `execute`, `batch`, `new_document`, `open_document`, `save_document`, `type_text`, `select_text`, `get_text`, `inspect_document`, `render_page`, `parity`, and app-only `screenshot`, `click`, `key`, `ui_inspect` (`crates/mcp/src/tools.rs:55–135`; docs/mcp.md:105–122). Protocol revision `2025-06-18`, resources `wordcraft://document` and `wordcraft://commands` (`crates/mcp/src/server.rs:8–30`).
- **Control channel**: app started with `--control <port>`; JSON lines over `127.0.0.1` with a per-window key from `<settings>/control-key.<instance>` (`local-<port>` outside Flatpak; mode 0600, removed on exit) (`crates/control-key/src/lib.rs:38–48`, docs/control-protocol.md:17–49). 19 methods: `engine.execute`, `engine.commands`, `document.inspect`, `ui.inspect`, `ui.click`, `ui.clickText`, `ui.move`, `ui.drag`, `ui.press`/`ui.release`, `ui.wheel`, `ui.key`, `ui.text`, `ui.screenshot`, `ui.render`, `ui.parity`, `ui.resize`, `ui.focus`, `app.quit`; any other method name is treated as a command id (docs/control-protocol.md:51–75). `ui.key`/`ui.text` are background-safe and reply `{"queued": true}` before the edit is applied; `ui.focus` requests native activation separately.
- **Macros**: `tools.recordMacro` / `tools.macros` record and replay command sequences (`crates/engine/src/cmd/tools.rs`; README.md:171).
- **Headless UI screenshots**: `cargo run -p wordcraft-ui-egui --example ui_shot -- script.jsonl` — JSON lines of control requests plus `{"shot": "<path>.png"}`, `{"steps": n}`, `{"wait": ms}`, `{"empty": true}`, `{"empty": true, "startScreen": true}` (`crates/ui-egui/examples/ui_shot.rs:1–12`).

### Platform
- WebAssembly web build exists and is CI-checked: `apps/wordcraft-web` (`?webgl`, `?sample`, and inside an iframe `?host=parent` with `&author=`; no TCP control channel, Open/Save go through the browser, apps/wordcraft-web/src/main.rs:1–13); `cargo xtask wasm` checks the layers for wasm32 (`xtask/src/main.rs:131–152`).
- Local recovery of unsaved work (desktop only), `recovery/` under the profile folder, covers new drafts and edits to existing files; password-protected documents get no plaintext recovery copies; headless/CLI/web sessions create none (docs/recovery.md:1–35).
- Native printing through craft-libs' `craft_ui::printing` (craft-print): `ui.printSettings` (printer list, copies, duplex, grayscale, background discovery with `{"refresh":true}`), `ui.printSubmit` and its alias `ui.print`, `file.printPdf` (also takes `paper` to scale onto another paper size) (`crates/ui-egui/src/printing.rs:8–20`, docs/control-protocol.md:100–112; craft-print pinned in apps/wordcraft/Cargo.toml:76).
- Zotero integration (`crates/zotero`, docs/zotero.md) — needs the Zotero desktop app running. In-app: `ui.zotero.addEditCitation|addEditBibliography|addNote|refresh|removeCodes|setDocPrefs|status|answer`; from a terminal: `wordcraft-cli zotero <command> <file>`.

## Known limitations and not-implemented

Ranked shortfalls with evidence are in **docs/gaps.md** — read it before promising anything. The blocking (beta) list, gaps #1–#7 (docs/gaps.md:90; rows at :60–66):

1. **DOCX has no real-world corpus test**: the repo says no corpus of files from Word, Google Docs, LibreOffice and Pages exists; `crates/docx/tests` are synthetic fixtures (docs/gaps.md:60; docs/file-format-parity.md:49). This is **uncertain** — revision entries elsewhere cite measurements on a 251-document corpus checked against Word PDFs (docs/file-format-parity.md:320, docs/layout-parity.md:319) and a private 181-document corpus (docs/layout-parity.md:400), which contradicts "untested", yet no corpus ships in the repo. Do not assume either way: treat fidelity on files you did not create as unverified and round-trip the user's file.
2. **Word's native ink is not drawn from its strokes** (its picture fallback shows) and **OLE objects show only their picture**; every ink form, drawing canvas (`wpc`), group shape (`wpg`), chart and SmartArt is preserved and written back with all parts (docs/gaps.md:63).
3. **Field crashes and freezes** remain open: startup crash on Intel UHD Graphics (#170), macOS 12.7.6 Intel crash (#979), Thai-font and font-selector freezes (#59, #31); 197 open issues as of 2026-10-12 (docs/gaps.md:61). Save-path reliability was narrowed, not closed.
4. **Pagination differs from Word**: no Aptos-metric font, legacy compatibility options partial, no page-by-page comparison harness (docs/gaps.md:62).
5. Still missing from the review/data model: drag-and-drop moves (no text drag yet), tracked style-definition changes, custom-XML binding evaluation (docs/gaps.md:64).
6. Print dialog depth: driver tray/options and pages per sheet remain (docs/gaps.md:65).
7. Dialog depth: 89 dialog names against Word's ~100 (see the count note above; docs/gaps.md:66).

Catalog features with **no command** (16 rows, `insert.inkEquation` listed under two tabs): `tools.dictate`, `insert.onlinePicture`, `insert.model3d`, `insert.screenshot`, `addins.get`, `insert.video`, `insert.inkEquation`, `draw.inkToMath`, `review.translate`, `review.blockAuthors`, `view.arrangeAll`, `view.sideBySide`, `view.syncScroll`, `view.switchWindows`, `view.readLayout` (docs/parity-checklist.md:35–68).

Other verified gaps:
- **Charts/SmartArt from Word are read-only** (no embedded-workbook editing); no combo/3D/stock charts (placeholder shown). WordCraft's own charts and SmartArt are editable (docs/gaps.md:72).
- **`.doc` is read-only** — WordCraft never writes Word 97-2003 (`crates/docbin/src/lib.rs:1–8`); Word 6/95 files are refused. No PDF Reflow, no MHT, no Works/WordPerfect (docs/gaps.md:73,86, docs/file-format-parity.md:59,62).
- **No VBA execution** (macros in `.docm` are preserved, never run), no Office add-ins, no cloud storage, no real-time co-authoring (docs/gaps.md:81).
- **Proofing** (`crates/proof/src/lang.rs:82–98` `PROOFED`, `:104–140` `from_tag`) covers **15** variants: English (US, UK, Canada), Polish, Portuguese, Italian, Croatian, Turkish, Russian, Czech, Indonesian, Spanish (Spain, Mexico, Latin America, Uruguay) — non-English dictionaries are read from the system, not bundled (docs/spelling-dictionaries.md:1–25); Bulgarian and German have hyphenation only; everything else is left unmarked (docs/gaps.md:68).
- **Writing fidelity is partial for non-DOCX formats**: RTF and ODT ~50%, HTML ~60%, Word 2003 XML write drops shapes/charts/equations and "not yet checked in Word" (docs/file-format-parity.md:55–61); notes and comments in RTF/ODT remain open (docs/gaps.md:77).
- **RTL/East Asian depth** is incomplete: kashida, RTL in HTML/ODT/RTF (docs/gaps.md:75–76).
- Mail merge sources: CSV/TSV/TXT (any common encoding) and `.xlsx/.xlsm/.xls/.ods` only; no Outlook/Access/database sources, no email merge (docs/gaps.md:80; `crates/formats/src/sheet.rs`).
- No in-app AI assistant (agent control is external, over CLI/MCP) (docs/gaps.md:84).
- Default shortcuts: 164 bindings, 145 active on macOS, vs Word's ~250 (measured; docs/gaps.md:83 says 140/158 — stale).
- View windows (Side by Side, Arrange All, Switch Windows) missing (docs/gaps.md:85); **one document per window, no tabs** (`crates/ui-egui/src/lib.rs:538–539` holds a single `Session`).
- Screen-reader access is exposed through AccessKit but has not been tested with NVDA/VoiceOver/Orca (docs/gaps.md:78).
- **Personal templates are narrow**: `.dotx`/`.dotm` only, one subfolder level, ≤500 entries, network folders refused, and the GUI picker needs a saved folder in File › Options (`crates/engine/src/cmd/user_templates.rs:1–30,67–80`).
- The **desktop app's automation is not confined**: `--automation-read-root`/`--automation-write-root` apply to the headless MCP server only and are an error with `--connect` (docs/mcp.md:90–99).
- Interface translations come from a separate repo; without the `CRAFT_I18N_DIR` checkout at the pinned SHA the build is English only (`crates/ui-egui/src/i18n/mod.rs:1–18`, `craft-i18n.rev`).

## How to operate

Launch (macOS):
- App: `open -a WordCraft` or `open -a WordCraft --args <file.docx>`. Binary: `/Applications/WordCraft.app/Contents/MacOS/WordCraft`. Bundle id `ai.storyteller.wordcraft`.
- App flags (`apps/wordcraft/src/main.rs:270–285`): `wordcraft [--sample] [--control PORT] [FILE…]`; `--version`, `-h|--help`. A bad `--control` port exits with status 2.
- **`wordcraft-cli` is not inside the app bundle** (only `WordCraft` is in `Contents/MacOS`). Get it from the release artifact `wordcraft-cli-<ver>-macos-universal.zip` (README.md:270, packaging/macos/package.sh) or build it: `cargo run --release -p wordcraft-cli -- <args>`.
- Environment variables that matter to agents: `WORDCRAFT_CONTROL_PORT`, `WORDCRAFT_CONTROL_KEY` (for `mcp --connect`), `WORDCRAFT_PROFILE_DIR` (isolated profile incl. recovery/keys), `WORDCRAFT_NO_PREFS` (no prefs, no recovery, no key file), `WORDCRAFT_PASSWORD`, `WORDCRAFT_REGION=en-US` (paper size on headless runs), `WORDCRAFT_LANGUAGE`, `RUST_LOG` (grep `WORDCRAFT_` in `apps` and `crates`).

Document model: **one document per window, no tabs** — `WordApp` holds a single `Session` (`crates/ui-egui/src/lib.rs:538–539`); document-to-document windows are a known gap.

Core commands (exact ids, from `crates/engine/src/cmd/file.rs`, `cmd/tools.rs`, `cmd/user_templates.rs`):
`file.new {"template": "blank|sample|letter|resume|report"}` (an unrecognised name silently yields a blank document), `file.open {"path": …, "password"?}`, `file.save {"path"?, "password"?, "markup"?, "format"?}`, `file.saveAs`, `file.encrypt`, `file.rename {"name"}` (the extension is kept), `file.exportPdf {"path": …, "markup"?}`, `file.exportPng {"path":…, "page"?, "scale"?}`, `file.printPdf {"path", "range"?, "pages"?, "copies"?, "collate"?, "paper"?}`, `file.close {"force"?}` (without `force` an unsaved document errors instead of prompting — closing closes the document, not the app), `file.setAuthor {"name"}`, `file.properties`, `file.info`, `document.inspect`, `document.text`, `review.trackChanges {"value": true}`, `review.restrict {"mode"?|"stop": true}`, `references.updateFields`, `file.listTemplates {"dir"?}`, `file.newFromTemplate {"path"}`, `file.saveTemplate {"path"}`, `mailings.first|last|goToRecord|printDocuments`.

Positions in command params and `document.inspect` are `{"story": "body" | {"part": n}, "path": [block, row, cell, block, …], "off": byteOffset}` (docs/control-protocol.md:77).

CLI recipes (verified usage strings, apps/wordcraft-cli/src/main.rs:16–67):
```sh
wordcraft-cli convert report.docx report.pdf        # docx, doc [read], pdf, odt, rtf, html, md, tex, txt, json, png, xml
wordcraft-cli convert report.docx out.xml --format wordml2003   # or flatopc (the default Word XML Document)
wordcraft-cli render report.docx out.png --page 2 --scale 2     # scale defaults to 2.0, page to 1
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
Exit status: 0 on success, 1 on error with the message on stderr. A failing `run` writes nothing (every output is checked before the first is written); `wrote <path>` is printed only after a successful save.

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
An unauthorised request gets `{"ok":false,"error":"unauthorized"}` and the connection closes; a line over 1 MiB, or bad JSON, also closes it; a connection with no authorised request within 30 s is closed (docs/control-protocol.md:36–49). `wordcraft-cli mcp --connect` sends the key only to loopback addresses; to drive an app on another machine, forward its port and set `WORDCRAFT_CONTROL_KEY`. Open/Save/Export pick formats by file extension in both the CLI and the app (`crates/engine/src/io.rs`); `--save`/`file.save` over an existing file replaces it in place.

Reading the app's own diagnostics: `<settings>/logs/wordcraft.log` (rotated to `.1`/`.2`, capped at 16 MiB; `--version` writes nothing; `WORDCRAFT_NO_PREFS` runs log to stderr only — README.md:173–184, `apps/wordcraft/src/logging.rs:33–37`). Unreadable .docx parts, pictures/fonts a PDF export left out, and recovered panics land there.

## Working with an AI agent

Legitimate, reliable agent work with WordCraft:
- **Do document work headlessly.** `wordcraft-cli mcp`, `wordcraft-cli run` (flags or `--script`) need no window, no focus and no GUI driving. Verify your own work with `inspect_document` / `get_text` / `render_page` instead of screenshots (docs/mcp.md:105–122).
- **Prepare inputs**: write Markdown/HTML/CSV/text in the shell and bring it in (`open_document`, `insert.textFromFile`, `mailings.recipients` for `.csv/.tsv/.txt` with encoding detection and `.xlsx/.xlsm/.xls/.ods`, `insert.picture` with a path or base64 bytes).
- **Produce deliverables**: convert/export to PDF/ODT/RTF/HTML/MD/tex/txt/PNG from the CLI (docx and pdf in one `run --script`), and hand the `.docx` on for Word.
- **Attribute your edits**: pass `--author "Claude (copyedit)"` (or `file.setAuthor`) so reviewers can tell agent edits from people's, and turn tracking on explicitly with `review.trackChanges {"value": true}` (docs/mcp.md:42–48). Under Restrict Editing the author cannot be changed and most `file.*` commands are refused — do not try to work around it.
- **Confine yourself**: run the headless MCP server with `--automation-read-root`/`--automation-write-root` (a missing root grants none of that access; paths are resolved with links followed; the roots must exist) (`crates/engine/src/file_access.rs:1–20`, docs/mcp.md:51–99). This also bounds the personal-templates folder.
- **Repair/interpret native projects**: the native format is `.docx` itself; `.json` is the engine's own model (media bytes and opaque parts included as base64). Recovery snapshots are versioned JSON under `recovery/`, taken at most every ten seconds; the last valid snapshot is kept until its successor validates, ordinarily two generations remain, and the newest edits can be lost (docs/recovery.md:27–52).
- **Do not**: drive the GUI blind by clicking at guessed coordinates — prefer commands; assume SVG/ICO/HEIC images load (they don't); assume `.doc` can be written (it can't); assume charts, SmartArt, OLE or native ink *from Word* can be edited (they are preserved through saves, not editable; only WordCraft's own charts and SmartArt are editable); assume `.docx` fidelity on real-world files (gap #1); assume a headless session writes recovery copies (it doesn't); call `ui.saveAsTemplate` headlessly (it opens a system dialog).
- **Watch these footguns**: `file.saveTemplate` appends `.dotx` (`out.docx` → `out.docx.dotx`); `file.new {"template": "MyTemplate"}` silently gives a blank document — use `file.newFromTemplate {"path"}`; `file.listTemplates` without `dir` errors when no folder is saved; `review.trackChanges` without `value` *toggles* (it can turn tracking off in a document saved with it on); `format.highlight` without `color` toggles; `file.close` over the control channel errors on unsaved changes unless `{"force": true}` (which discards them); `ui.key`/`ui.text` replies `{"queued": true}` before the edit has been applied — inspect document/widget state before the next dependent step; a `mcp --connect` bridge that starts first reports "not reachable … will retry on each call" until the app's port opens.

## Verification protocol

Alpha software that never crashes by design but is unproven on real-world files: trust nothing you did not re-open.

1. **Throwaway round-trip first**: new → type/format → save `.docx` → reopen → export `.pdf`, all in a scratch directory (`wordcraft-cli run --template blank --cmd … --save t.docx`, then `wordcraft-cli convert t.docx t.pdf`, then `wordcraft-cli inspect t.docx`).
2. **Never trust a silent export**: the CLI prints `wrote <path>` only after the command returned Ok, and a failing command writes nothing; still check the file exists, is non-zero, and re-read it. PDFs don't open in WordCraft — check a PDF elsewhere, or render the page with `wordcraft-cli render t.docx page.png` and look at the PNG.
3. **Compare structure, not just text**: `inspect`/`document.inspect` shows styles, tables, sections — use it to catch silent loss (the known failure mode is content dropped without a warning; gap #1).
4. **Keep the user's original untouched**: work on a copy; WordCraft's save replaces the file in place (safely, but in place). Recovery copies exist for the desktop app only, are unencrypted, and the newest edits before a crash can be lost (docs/recovery.md:25–35).
5. **Version and back up** project files per session; update the app only between projects (the launcher auto-updates; the version you script against may change).
6. **Re-check the command set you script against**: re-read `wordcraft-cli commands --json` on the installed build and look for the ids you call; the repo's documentation counts drift for months (README still says 422 commands vs 643 in code).

## Sources & evidence

- Repo: https://github.com/storytold/wordcraft (org `storytold`), inspected read-only at **tag `v0.11.0`**, commit **`e31f2f06a5f8004ceaa88f68c00b47908e321aa4`** ("Release 0.11.0", 2026-10-26).
- Installed app `/Applications/WordCraft.app` is exactly this release: `CFBundleShortVersionString` and `CFBundleVersion` are `0.11.0` (bundle id `ai.storyteller.wordcraft`), and the binary prints `wordcraft 0.11.0 (e31f2f06)`. If your installed version differs, verify against it (`wordcraft --version`, `wordcraft-cli --version`).
- Key files read: README.md, ROADMAP.md, Cargo.toml, AGENTS.md, craft-i18n.rev, docs/{gaps,file-format-parity,mcp,control-protocol,recovery,zotero,parity-checklist,shared-pdf,spelling-dictionaries,ui-parity,layout-parity,localization-parity,architecture,roadmap,hardware-parity,target-app-parity}.md, apps/wordcraft/src/{main.rs,logging.rs}, apps/wordcraft-cli/src/{main.rs,script.rs,automation_args.rs}, apps/wordcraft-web/src/main.rs, crates/engine/src/{io.rs,io_ext.rs,catalog.rs,session.rs,keymap.rs,file_access.rs,print.rs,lib.rs,cmd/mod.rs,cmd/file.rs,cmd/tools.rs,cmd/user_templates.rs,cmd/mailings.rs,cmd/view.rs,cmd/format.rs,cmd/protect.rs,cmd/references.rs,cmd/insert.rs,cmd/table.rs}, crates/docx/src/{crypt.rs,flat.rs,wordml2003.rs,read/story.rs,write/story.rs,write/mod.rs,read/chart.rs}, crates/docbin/src/{lib.rs,crypt.rs}, crates/formats/src/{html.rs,rtf.rs,odt.rs,sheet.rs,latex.rs,markdown.rs,txt.rs}, crates/mcp/src/{tools.rs,server.rs,backend.rs}, crates/ui-egui/src/{lib.rs,dialogs.rs,dialogs_insert.rs,dialogs_layout.rs,dialogs_review.rs,dialogs_refs.rs,i18n/mod.rs,control.rs,printing.rs,zotero.rs}, crates/ui-egui/examples/ui_shot.rs, crates/proof/src/lang.rs, crates/layout/src/fields.rs, crates/doc/src/connector.rs, crates/control-key/src/lib.rs, xtask/src/main.rs, packaging/macos/package.sh.
- Shared libraries: `storytold/craft-libs` — WordCraft pins `craft-pdf` and the patch that carries it at rev `17744430be327d0257496a6a31c8d38fe20a6756` (Cargo.toml:57,112–113) and prints through craft-print at the same rev (apps/wordcraft/Cargo.toml:76); interface catalogs come from `storytold/craft-i18n` at `craft-i18n.rev` (`04600cbb…`).
- Counts were re-measured from this tag's code on 2026-10-26 (see the table and `evidence.md`), and the capability delta since v0.10.0 was established by diffing this tree against the v0.10.0 release source: commands 638 → 643 (+5, none removed), catalog 498/513 → 504/520, proofing 11 → 15, dialog names 86 → 89, shortcut-bearing specs 163 → 164 (145 macOS-active at both tags), MCP tools 16 → 16, CLI 10/21 → 10/21, control methods 19 → 19, languages 27 → 27, formats unchanged.
- Nothing was built or launched; the clone and the v0.10.0 release source were only read, and the installed app was version-checked from its binary. Where the repo contradicts itself (command counts, dialog count, shortcut count, gap #1) the contradiction is stated in place rather than resolved by guesswork.

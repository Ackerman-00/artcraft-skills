---
name: wordcraft
description: >-
  WordCraft is an open-source, clean-room reimplementation of Microsoft Word in Rust (alpha,
  v0.8.0): a ribbon word processor that reads and writes .docx and exports PDF, plus a CLI
  (wordcraft-cli), an MCP server and a localhost JSON control channel for agents. Trigger this
  skill whenever the user mentions WordCraft, .docx/.doc/.odt/.rtf/.html/.md/.tex documents in a
  WordCraft context, the wordcraft-cli tool, WordCraft's MCP tools or control channel, macros,
  templates, mail merge, track changes, or asks what WordCraft can or cannot do, which formats it
  opens/saves, how to script, automate, batch-convert, verify, repair or troubleshoot it — even if
  the app is not named but the job is word-processor work ("write a .docx", "convert this .doc to
  PDF", "add comments and track changes", "mail-merge a letter", "make a report from Markdown").
  Do not use it for Microsoft Word itself or other word processors.
---

# WordCraft

## Overview

WordCraft is an open-source, clean-room reimplementation of Microsoft Word (Microsoft 365) in pure
Rust — "writing and document design" — by the ArtCraft team (README.md:13, README.md:370–378).
It is at **alpha** (ROADMAP.md:3, ROADMAP.md:44–52), self-rated ~60% "ready for real work" and
~55% for a mainstream practitioner's weekly work (ROADMAP.md:21–22), with **487 of 502**
ribbon/menu catalog features wired to live commands (97.0%; docs/parity-checklist.md:5).
One codebase serves macOS, Windows, Linux, BSD and the web: egui/eframe on the GPU, no Electron
(Cargo.toml:75–82, README.md:96–97). The source lives at GitHub **storytold/wordcraft** under
MIT OR Apache-2.0 (Cargo.toml:9, README.md:362). It is independent of Microsoft: it reads and
writes their formats from the published specifications (ECMA-376/ISO 29500, MS-DOC, OASIS ODF).

Everything user-visible is a **command with an id**; the ribbon, keyboard, command search, CLI,
control channel and MCP all dispatch the same registry (README.md:98–100,
`crates/engine/src/cmd/mod.rs::registry`).

## Capabilities (verified)

### Editing, formatting, document features
- Writing: typing/IME, AutoCorrect, list autoformat, selections, clipboard with formatting,
  undo/redo, find & replace incl. regex (README.md:109; typing behaviour pinned by
  `crates/engine/src/tests_typing.rs`, see AGENTS.md "Typing behaves like Word").
- Formatting, paragraphs, styles/themes, lists, tables (styles, merge/split, sort, formulas),
  pages/sections (margins, columns, headers/footers, watermark, line numbers, hyphenation),
  objects (pictures with crop/recolour/background removal, shapes, text boxes, wrap, rotation),
  references (TOC, footnotes/endnotes, citations APA/MLA/Chicago/IEEE, captions, index),
  review (spelling/grammar, comments, track changes, accept/reject, compare, restrict editing),
  mail merge from CSV/spreadsheets, and View modes with 21 interface languages (README.md:110–121).
  One command per feature in `crates/engine/src/cmd/*.rs` (49 modules).
- Command count: the repo states different totals in different docs — README.md:98 says 422,
  ROADMAP.md:26 says 433, docs/mcp.md:85 says "over 270". Do not quote a number; list them:
  `wordcraft-cli commands [--json]` (`apps/wordcraft-cli/src/main.rs:411–425`).

### Import / open (by extension, `crates/engine/src/io.rs:9–29` OPEN_EXTS)
- `.docx` / `.docm` / `.dotx` / `.dotm` (Word package; Strict Open XML read via namespace
  mapping), `.doc` / `.dot` (Word 97-2003 binary reader, `crates/docbin`), `.txt`, `.md`,
  `.markdown`, `.html`/`.htm`, `.rtf`, `.odt`, `.tex`/`.latex`/`.ltx`, `.xml`
  (Word XML Document / Flat OPC or Word 2003 XML, told apart by root element), `.json`
  (WordCraft's native document model), and `*.wcraft.json`.
- Extensionless or unknown-extension files open **by content** if they are Word/RTF/text,
  with encoding detection; binary files are refused with an error
  (`crates/engine/src/io.rs:250–302`, `crates/formats/src/txt.rs`).
- Pictures: PNG, JPEG, GIF, WebP, BMP, WMF/EMF. Not SVG, TIFF, ICO, HEIC
  (docs/file-format-parity.md:58).

### Save / native format / export (`crates/engine/src/io.rs:31` SAVE_EXTS)
- Native-lossless: `.docx`/`.docm`/`.dotx`/`.dotm` via `crates/docx` (`write_as`, package flavour
  from the extension), plus Word XML Document (Flat OPC) and Word 2003 XML `.xml`
  (`crates/docx/src/flat.rs`, `wordml2003_write.rs`), and `.json` for agents
  (`crates/engine/src/io.rs:305–334`; dispatch in `crates/engine/src/io_ext.rs`).
- Copies/export: `.pdf` (krilla through the pinned `craft-pdf`, README.md:191–192,
  Cargo.toml:55), `.png` page images, `.txt`, `.md`, `.html`, `.rtf`, `.odt`, `.tex`
  (`crates/formats`, partial fidelity — see limitations).
- Password: `.docx`-family packages save agile-encrypted and open with a password
  (`crates/docx/src/crypt.rs`); `.doc` password support is documented inconsistently across
  rows (see evidence.md — uncertain, read `docs/file-format-parity.md` rows 52–55 yourself).
- Print Markup (`--markup` / `markup: true`): comments and tracked changes in PDF/PNG, a comment
  list in HTML/Markdown/text (`crates/engine/src/io.rs:50–62`).

### Automation surfaces (all four drive the same commands)
- **CLI**: `wordcraft-cli convert|info|text|inspect|render|run|commands|parity|mcp|zotero`
  with flags `--markup`, `--format wordml2003|flatopc`, `--page`, `--scale`, `--file`,
  `--template`, `--cmd 'id={json}'`, `--save`, `--print`, `--author`, `--json`, `--markdown`,
  `--connect`, `--automation-read-root`, `--automation-write-root`, and Zotero's `--trace`,
  `--port` (`apps/wordcraft-cli/src/main.rs:15–57` is the authoritative usage text).
- **MCP server** over stdio: `wordcraft-cli mcp` (headless) or
  `wordcraft-cli mcp --connect 127.0.0.1:<port>` (bridged to a running app). Tools:
  `list_commands`, `execute`, `batch`, `new_document`, `open_document`, `save_document`,
  `type_text`, `select_text`, `get_text`, `inspect_document`, `render_page`, `parity`, and
  app-only `screenshot`, `click`, `key`, `ui_inspect` (`crates/mcp/src/tools.rs:55–155`;
  docs/mcp.md:81–100). Resources: `wordcraft://document`, `wordcraft://commands`.
- **Control channel**: app started with `--control <port>`; JSON lines over `127.0.0.1` with a
  per-window key from `<settings>/control-key.local-<port>` (macOS settings folder:
  `~/Library/Application Support/WordCraft`). Methods include `engine.execute`,
  `engine.commands`, `document.inspect`, `ui.inspect`, `ui.click`, `ui.key`, `ui.text`,
  `ui.screenshot`, `ui.render`, `ui.parity`, `app.quit` (`docs/control-protocol.md:51–72`,
  `crates/control-key/src/lib.rs`).
- **Macros**: `tools.recordMacro` / `tools.macros` record and replay command sequences
  (crates/engine/src/cmd/tools.rs:349–363; README.md:162–163).

### Platform
- WebAssembly web build exists and is CI-checked: `apps/wordcraft-web` (`trunk build --release`,
  `?sample`, `?webgl` URL flags; no TCP control channel, Open/Save go through the browser,
  apps/wordcraft-web/src/main.rs:1–8); `cargo xtask wasm` checks L0–L5 + the egui shell for
  wasm32 (xtask/src/main.rs:124–153).
- Local recovery of unsaved work (desktop only), `recovery/` under the profile folder,
  inspectable via `file.recover` (docs/recovery.md).
- Native printing through craft-print: `ui.printSettings`, `ui.printSubmit`, `file.printPdf`,
  `file.print` (docs/control-protocol.md:88–103).
- Zotero integration (`crates/zotero`, docs/zotero.md) — needs the Zotero desktop app running.

## Known limitations and not-implemented

Ranked shortfalls with evidence are in **docs/gaps.md** — read it before promising anything.
The blocking (beta) list, gaps #1–#7:

1. **DOCX never tested on real-world files** (no corpus; synthetic fixtures only) — the files
   people receive are the files that break (docs/gaps.md:27).
2. **Silent content loss on open+save**: remaining native ink forms are dropped; charts, SmartArt
   and OLE objects survive saves but cannot be edited (docs/gaps.md:30).
3. **Field crashes and freezes** on some GPUs/fonts; 197 open issues as of 2026-10-12
   (docs/gaps.md:28).
4. **Pagination differs from Word** (no Aptos-metric font, legacy compatibility options partial,
   no page-by-page comparison harness) (docs/gaps.md:29).
5. Content controls work, but drag-and-drop move tracking, tracked style/table/section changes,
   and custom-XML binding evaluation are missing (docs/gaps.md:31).
6. Print dialog depth (driver tray/options, pages per sheet) (docs/gaps.md:32).
7. 54 modal dialogs vs Word's ~100 (docs/gaps.md:33).

Other verified gaps:
- **Charts/SmartArt from Word are read-only**; no embedded-workbook editing; no combo/3D/radar/
  stock charts (placeholders shown) (docs/gaps.md:39, docs/file-format-parity.md:89).
- **`.doc` is read-only** — WordCraft never writes Word 97-2003 (crates/docbin/src/lib.rs:3–4);
  Word 6/95 files are refused. **No PDF Reflow**, no MHT, no Works/WordPerfect (docs/gaps.md:40,49,53).
- **No VBA execution** (macros in .docm are preserved, never run), no Office add-ins, no cloud
  storage, no real-time co-authoring (docs/gaps.md:48, docs/file-format-parity.md:40).
- **3D models dropped**; legacy `w:ffData` form fields, glossary/building blocks and
  `w:eastAsianLayout`/`w:fitText` are not read or written (docs/file-format-parity.md:92,81,101,100).
- **Writing fidelity is partial for the non-DOCX formats**: RTF and ODT ~50%, HTML ~60%,
  Word 2003 XML write drops shapes/charts/equations etc. (docs/file-format-parity.md:44–50).
  MHT is not supported at all.
- **Proofing languages**: English, Polish, Portuguese, Italian, Croatian, Turkish and Russian
  (plus Czech spelling); everything else is left unmarked (docs/gaps.md:35).
- **RTL/East Asian depth** is incomplete (docs/gaps.md:42–43).
- Mail merge: CSV/TSV/TXT and `.xlsx/.xlsm/.xls/.ods` only; no Outlook/Access/database sources,
  no email merge (docs/gaps.md:47; `crates/formats/src/sheet.rs`).
- No in-app AI assistant (agent control is external, over CLI/MCP) (docs/gaps.md:51).
- The **desktop app's automation is not confined**: `--automation-read-root`/
  `--automation-write-root` apply to the headless MCP server only (docs/mcp.md:66–68).

## How to operate

Launch (macOS):
- App: `open -a WordCraft` or `open -a WordCraft --args <file.docx>`. Binary:
  `/Applications/WordCraft.app/Contents/MacOS/WordCraft`. Bundle id `ai.storyteller.wordcraft`.
- App flags (Apps/wordcraft/src/main.rs:266–278): `wordcraft [--sample] [--control PORT] [FILE…]`;
  `--version`, `-h|--help`. A bad `--control` port exits with status 2.
- **`wordcraft-cli` is not inside the app bundle** (nothing on PATH on the reference machine).
  Get it from the release artifact `wordcraft-cli-<ver>-macos-universal.zip`
  (README.md:260, packaging/macos/package.sh:44–66) or build it:
  `cargo run --release -p wordcraft-cli -- <args>`.
- Useful environment variables: `WORDCRAFT_CONTROL_PORT`, `WORDCRAFT_PROFILE_DIR` (isolated
  profile incl. recovery/keys), `WORDCRAFT_NO_PREFS` (agents' test runs; no prefs, no recovery,
  no key file — docs/recovery.md:20–25), `WORDCRAFT_REGION=en-US` (paper size on headless runs),
  `RUST_LOG` (README.md:178–182), `WGPU_BACKEND` (Windows graphics troubleshooting only,
  README.md:223–240).

Document model: **one document per window, no tabs** — `WordApp` holds a single
`Session`/document (crates/ui-egui/src/lib.rs:420–421); Document-to-document windows (Side by
Side, Arrange All) are a known gap (docs/gaps.md:52).

Core commands (exact ids, from `crates/engine/src/cmd/file.rs:64–123`):
`file.new {"template": "blank|sample|letter|resume|report"}`, `file.open {"path": …, "password"?}`,
`file.save {"path"?, "password"?, "markup"?, "format"?}`, `file.saveAs`,
`file.exportPdf {"path": …, "markup"?}`, `file.exportPng {"path":…, "page"?, "scale"?}`,
`file.printPdf {"path", "range"?, "pages"?, "parity"?, "copies"?, "collate"?}`,
`file.close {"force"?}` (control channel/MCP: without `force` an unsaved document errors instead
of prompting — docs/control-protocol.md:79–86), `file.setAuthor {"name"}`,
`document.inspect`, `document.text`, `review.trackChanges {"value": true}`.

CLI recipes (verified usage strings, apps/wordcraft-cli/src/main.rs:15–57):
```sh
wordcraft-cli convert report.docx report.pdf        # docx, doc [read], pdf, odt, rtf, html, md, tex, txt, json, png, xml
wordcraft-cli convert in.docx out.png               # page 1 only, via file.exportPng
wordcraft-cli render report.docx out.png --page 2 --scale 2   # scale defaults to 2.0, page to 1
wordcraft-cli text report.docx                      # plain text, list labels kept
wordcraft-cli info report.docx                      # pages, words, paragraphs, properties (JSON)
wordcraft-cli inspect report.docx                   # structure as JSON
wordcraft-cli run --template sample --cmd 'select.text={"text":"Membership"}' \
  --cmd format.bold --save out.docx
wordcraft-cli run --file in.docx --cmd edit.undo --cmd 'file.exportPdf={"path":"out.pdf"}'
wordcraft-cli commands --json                       # every command id, label, params, shortcut
wordcraft-cli mcp --author "Claude (copyedit)" \
  --automation-read-root /work/project --automation-write-root /work/project/out
wordcraft-cli zotero refresh paper.docx --save paper.docx
```
Exit status: 0 on success (a closed stdout pipe also exits 0), 1 on error with the message on
stderr (`apps/wordcraft-cli/src/main.rs:558–567`). Failures never leave a half-written output file
for `render`/`run --save` (tested, main.rs:869–892).

Driving the running app (control channel):
```sh
open -a WordCraft --args --control 7981
cat ~/Library/Application\ Support/WordCraft/control-key.local-7981
# then one JSON object per line to 127.0.0.1:7981, e.g.
{"id":1,"key":"<key>","method":"engine.execute","params":{"command":"text.insert","params":{"text":"Hello"}}}
{"id":2,"key":"<key>","method":"ui.screenshot","params":{"path":"/tmp/shot.png"}}
```
An unauthorised request gets `{"ok":false,"error":"unauthorized"}` and the connection closes
(docs/control-protocol.md:36–42). Open/Save/Export flow: formats are chosen by file extension, in
both the CLI and the app (crates/engine/src/io.rs:38–48); `--save`/`file.save` over an existing
file replaces it in place (save-path guarantees: docs/file-format-parity.md "native save path").

Reading the app's own diagnostics: `~/Library/Application Support/WordCraft/logs/wordcraft.log`
(rotated to `.1`/`.2`, capped at 16 MiB; `--version` writes nothing; `WORDCRAFT_NO_PREFS` runs log
to stderr only — README.md:165–182). Unreadable .docx parts, pictures/fonts a PDF export left
out, and recovered panics land there.

## Working with an AI agent

Legitimate, reliable agent work with WordCraft:
- **Do document work headlessly.** `wordcraft-cli mcp` (or `wordcraft-cli run --cmd …`) needs no
  window, no focus and no GUI driving. Verify your own work with `inspect_document` / `get_text` /
  `render_page` instead of screenshots (docs/mcp.md:92–95).
- **Prepare inputs**: write Markdown/HTML/CSV/text in the shell and bring it in
  (`open_document`, `insert.textFromFile`, `mailings.recipients` for `.csv/.tsv/.txt` with
  encoding detection and `.xlsx/.xlsm/.xls/.ods`, `insert.picture` with a path or base64 bytes).
- **Produce deliverables**: convert/export to PDF/ODT/RTF/HTML/MD/tex/txt/PNG from the CLI, and
  hand the `.docx` on for Word (README.md:92–93).
- **Attribute your edits**: pass `--author "Claude (copyedit)"` (or `file.setAuthor`) so reviewers
  can tell agent edits from people's, and turn tracking on explicitly with
  `review.trackChanges {"value": true}` (docs/mcp.md:18–25).
- **Confine yourself**: run the headless MCP server with `--automation-read-root`/
  `--automation-write-root` (a missing root grants none of that access; paths are resolved with
  links followed — docs/mcp.md:27–79).
- **Repair/interpret native projects**: the native format is `.docx` itself; `.json` is the
  engine's own model (media bytes and opaque parts included). Recovery snapshots are versioned
  JSON under `recovery/` and only the last valid generation is guaranteed (docs/recovery.md).
- **Do not**: drive the GUI blind by clicking at guessed coordinates — prefer commands; assume
  SVG/TIFF/HEIC images load (they don't); assume `.doc` can be written (it can't); assume charts,
  SmartArt, OLE, native ink or 3D models survive edits intact; assume `.docx` fidelity on
  real-world files (gap #1); assume the headless session writes recovery copies (it doesn't).
- **Watch two footguns**: `review.trackChanges` without `value` *toggles* (it can turn tracking
  off in a document saved with it on); `file.close` over the control channel errors on unsaved
  changes unless `{"force": true}` (which discards them).

Headless UI screenshots (no focus stealing, works with a locked screen):
`cargo run --release -p wordcraft-ui-egui --example ui_shot -- script.jsonl`
(JSON-line control requests plus `{"shot": "/abs/out.png"}`; crates/ui-egui/examples/ui_shot.rs).

## Verification protocol

Alpha software that never crashes by design but is unproven on real-world files: trust nothing
you did not re-open.

1. **Throwaway round-trip first**: new → type/format → save `.docx` → reopen → export `.pdf`,
   all in a scratch directory (`wordcraft-cli run --template blank --cmd … --save t.docx`, then
   `wordcraft-cli convert t.docx t.pdf`, then `wordcraft-cli inspect t.docx`).
2. **Never trust a silent export**: the CLI prints `wrote <path>` only after the command returned
   Ok (main.rs:330, 407); still check the file exists, is non-zero, and re-read it
   (`wordcraft-cli text t.pdf` will not work — PDFs don't open; check the PDF elsewhere or render
   the page with `wordcraft-cli render t.docx page.png` and look at the PNG).
3. **Compare structure, not just text**: `inspect`/`document.inspect` shows styles, tables,
   sections — use it to catch silent loss (the known failure mode is content dropped without a
   warning; docs/gaps.md #1/#2).
4. **Keep the user's original untouched**: work on a copy; WordCraft's save replaces the file in
   place. Recovery copies exist for the desktop app only, are unencrypted, and the newest edits
   before a crash can be lost (docs/recovery.md:27–31).
5. **Version and back up** project files per session; update the app only between projects
   (the launcher auto-updates; the version you script against may change).

## Sources & evidence

- Repo: https://github.com/storytold/wordcraft (org `storytold`), inspected read-only at
  **HEAD `f2e15cf8f899a79899a2d9595ca4ce7df1e5ea22`** (tag **v0.8.0**, "Release 0.8.0") on
  **2026-10-18**.
- Installed bundle `/Applications/WordCraft.app` reports `CFBundleShortVersionString` **0.8.0**
  and `WordCraftBuildCommit` `f2e15cf8f899a79899a2d9595ca4ce7df1e5ea22` — the same commit, so
  this skill describes the shipped build. If your installed version differs, verify against your
  installed version (`wordcraft --version`, `wordcraft-cli --version`).
- Key files read: README.md, ROADMAP.md, Cargo.toml, AGENTS.md, docs/{gaps,roadmap,file-format-parity,
  mcp,control-protocol,recovery,zotero,parity-checklist}.md, apps/wordcraft/src/main.rs,
  apps/wordcraft-cli/src/main.rs, crates/engine/src/{io.rs,io_ext.rs,catalog.rs,cmd/file.rs,
  cmd/mod.rs,cmd/tools.rs}, crates/docx/src/lib.rs, crates/docbin/src/lib.rs, crates/formats/src/lib.rs,
  crates/mcp/src/tools.rs, crates/control-key/src/lib.rs, crates/ui-egui/src/lib.rs,
  apps/wordcraft-web/src/main.rs, xtask/src/main.rs, crates/ui-egui/examples/ui_shot.rs.
- Shared libraries: `storytold/craft-libs` — WordCraft pins
  `craft-pdf` (PDF writing) and prints through craft-print (Cargo.toml:55, 104–106).

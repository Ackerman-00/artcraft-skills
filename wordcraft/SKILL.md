---
name: wordcraft
description: >-
  WordCraft is an open-source, clean-room reimplementation of Microsoft Word in Rust (alpha,
  v0.9.0): a ribbon word processor that reads and writes .docx (password-protected included) and
  exports PDF, plus a CLI (wordcraft-cli), an MCP server, a localhost JSON control channel and a
  headless screenshot harness for agents. Trigger this skill whenever the user mentions WordCraft,
  .docx/.doc/.odt/.rtf/.html/.md/.tex documents in a WordCraft context, the wordcraft-cli tool,
  WordCraft's MCP tools or control channel, macros, templates, mail merge, track changes, or asks
  what WordCraft can or cannot do, which formats it opens/saves, how to script, automate,
  batch-convert, verify, repair or troubleshoot it — even if the app is not named but the job is
  word-processor work ("write a .docx", "convert this .doc to PDF", "add comments and track
  changes", "mail-merge a letter", "make a report from Markdown"). Do not use it for Microsoft
  Word itself or other word processors.
---

# WordCraft

## Overview

WordCraft is an open-source, clean-room reimplementation of Microsoft Word (Microsoft 365) in pure
Rust — "writing and document design" — by the ArtCraft team (README.md:13, README.md:363–381).
It is at **alpha** (ROADMAP.md:3), self-rated ~60% "ready for real work", ~55% for a mainstream
practitioner's weekly work and ~63% for everyday essentials (README.md:203–206, ROADMAP.md:19–23),
with **492 of 507** ribbon/menu catalog features wired to live commands (97.0%;
docs/parity-checklist.md:5). One codebase serves macOS, Windows, Linux, BSD and the web:
egui/eframe on the GPU, no Electron (Cargo.toml:76–81, README.md:96–97). The source lives at
GitHub **storytold/wordcraft** under MIT OR Apache-2.0 (Cargo.toml:9, README.md:365). It is
independent of Microsoft: it reads and writes their formats from the published specifications
(ECMA-376/ISO 29500, MS-DOC, OASIS ODF).

Everything user-visible is a **command with an id**; the ribbon, keyboard, command search, CLI,
control channel and MCP all dispatch the same registry (README.md:98–100, AGENTS.md:43,
`crates/engine/src/cmd/mod.rs::registry`).

## Capabilities (verified)

### Editing, formatting, document features
- Writing: typing/IME, AutoCorrect, list autoformat, selections, clipboard with formatting,
  undo/redo, find & replace incl. regex; typing behaviour is pinned to Word's by
  `crates/engine/src/tests_typing.rs` (AGENTS.md:51–52, docs/typing-parity.md).
- Formatting, paragraphs, styles/themes, lists, tables (styles, merge/split, sort, formulas),
  pages/sections (margins, columns, headers/footers, watermark, line numbers, hyphenation,
  drop caps), objects (pictures with crop/recolour/background removal, shapes, text boxes,
  groups, drawing canvases, wrap, rotation), references (TOC, footnotes/endnotes, citations
  APA/MLA/Chicago/IEEE, captions, index, Zotero), review (spelling/grammar, comments, track
  changes incl. move tracking and formatting revisions, accept/reject, compare, restrict
  editing), mail merge from CSV/spreadsheets, Draw-tab ink (pens, lasso, Ink to Shape, Ink
  Replay), Read Aloud, and View modes with 21 interface languages (README.md:109–121).
  One command per feature in `crates/engine/src/cmd/*.rs` (48 modules).
- Command count: the registry holds **633 commands** (counted 2026-10-22: 633 `CommandSpec::new`
  entries outside test modules in `crates/engine/src/cmd/*.rs`, all reached by `registry()`).
  The repo's own docs disagree and are stale — README.md:98 says 422, ROADMAP.md:26 says 433,
  docs/mcp.md:103 says "over 270". Do not quote a doc number; list them:
  `wordcraft-cli commands [--json]`.

### Import / open (by extension, `crates/engine/src/io.rs:9–29` OPEN_EXTS)
- `.docx` / `.docm` / `.dotx` / `.dotm` (Word package; Strict Open XML read via namespace
  mapping), `.doc` / `.dot` (Word 97-2003 binary reader, `crates/docbin`), `.txt`, `.md`,
  `.markdown`, `.html`/`.htm`, `.rtf`, `.odt`, `.tex`/`.latex`/`.ltx`, `.xml`
  (Word XML Document / Flat OPC or Word 2003 XML, told apart by root element), `.json`
  (WordCraft's native document model), and `*.wcraft.json`.
- Extensionless or unknown-extension files open **by content** if they are Word/RTF/XML/text,
  with encoding detection; anything else is refused with an error
  (`crates/engine/src/io.rs:316–330`).
- Password-protected `.docx` opens with a password (agile encryption;
  `crates/docx/src/crypt.rs`); `.doc` protected with XOR/RC4/RC4 CryptoAPI also opens
  (`crates/docbin/src/lib.rs:85–92`) — untested on Word-written files; AES `.doc` is refused.
- Pictures: PNG, JPEG, GIF, WebP, BMP, TIFF (TIFF decodes via the `image` crate —
  `crates/engine/src/cmd/insert.rs:226–239`; note docs/file-format-parity.md:59 still lists
  TIFF as unsupported: stale), plus Windows/Enhanced Metafile `.wmf`/`.emf` at their frame size
  (`crates/metafile`). Not SVG, ICO, HEIC.

### Save / native format / export (`crates/engine/src/io.rs:31` SAVE_EXTS)
- Native-lossless: `.docx`/`.docm`/`.dotx`/`.dotm` via `crates/docx` (`write_as`, package
  flavour from the extension), Word XML Document (Flat OPC) and Word 2003 XML `.xml`
  (`crates/docx/src/flat.rs`, `wordml2003_write.rs`), and `.json` for agents
  (`crates/engine/src/io.rs`; dispatch in `crates/engine/src/io_ext.rs`). A file opened with a
  password is saved with it again; exports that cannot carry one (pdf, html, txt) stay plain
  (apps/wordcraft-cli/src/main.rs:59–61).
- Copies/export: `.pdf` (krilla through the pinned `craft-pdf`, README.md:192, Cargo.toml:55,
  docs/shared-pdf.md), `.png` page images, `.txt`, `.md`, `.html`, `.rtf`, `.odt`, `.tex`
  (`crates/formats`; partial fidelity — see limitations).
- Passwords on the CLI: `--password PASS`, `--password-file PATH` or `WORDCRAFT_PASSWORD`
  (apps/wordcraft-cli/src/main.rs:57–61, 129–140).
- Print Markup (`--markup` / `markup: true`): comments and tracked changes in PDF/PNG, a comment
  list in HTML/Markdown/text (`crates/engine/src/io.rs:52–62`).
- Saves are atomic-by-design: serialize, then write an exclusively created sibling temp file,
  sync, replace; a failed save keeps the original bytes (docs/file-format-parity.md:161,
  "Native save-path guarantees"). Renaming a document (`file.rename`) needs a filesystem with
  hard links — exFAT/FAT and some network shares refuse it (docs/gaps.md, "Document renaming").

### Automation surfaces (all four drive the same commands)
- **CLI**: `wordcraft-cli convert|info|text|inspect|render|run|commands|parity|mcp|zotero`
  with flags `--markup`, `--update-fields` (refresh unlocked fields before saving), `--format
  wordml2003|flatopc`, `--page`, `--scale`, `--file`, `--template`, `--cmd 'id={json}'`,
  `--save`, `--print`, `--author`, `--password`, `--password-file`, `--script FILE|-`,
  `--json`, `--markdown`, `--connect`, `--automation-read-root`, `--automation-write-root`,
  and Zotero's `--trace`, `--port` (apps/wordcraft-cli/src/main.rs:16–67 is the authoritative
  usage text).
- **`run --script`** (new in 0.9): a JSON job file or stdin —
  `{"file"?…, "template"?, "commands": [{"command": id, "params"?: {…}} | id, …], "save":
  ["out.docx", "out.pdf"]}` — runs the commands, then saves to each output, format by
  extension (docx and pdf in one run). Relative `file`/`save` paths resolve against the
  script's folder; paths inside command params stay relative to the working folder; capped at
  4 MiB. A failing command stops the run with exit 1 and nothing is written; every output is
  checked before the first is written (docs/mcp.md:18–31, apps/wordcraft-cli/src/script.rs).
- **MCP server** over stdio: `wordcraft-cli mcp` (headless) or
  `wordcraft-cli mcp --connect 127.0.0.1:<port>` (bridged to a running app). 16 tools:
  `list_commands`, `execute`, `batch`, `new_document`, `open_document` (now takes an optional
  `password`), `save_document`, `type_text`, `select_text`, `get_text`, `inspect_document`,
  `render_page`, `parity`, and app-only `screenshot`, `click`, `key`, `ui_inspect`
  (`crates/mcp/src/tools.rs:55–167`, dispatch from :168; docs/mcp.md:102–122). Resources: `wordcraft://document`,
  `wordcraft://commands` (`crates/mcp/src/server.rs:28–29`).
- **Control channel**: app started with `--control <port>`; JSON lines over `127.0.0.1` with a
  per-window key from `<settings>/control-key.local-<port>` (macOS settings folder:
  `~/Library/Application Support/WordCraft`; mode 0600). Methods: `engine.execute`,
  `engine.commands`, `document.inspect`, `ui.inspect`, `ui.click`, `ui.clickText`, `ui.move`,
  `ui.drag`, `ui.press`/`ui.release`, `ui.wheel`, `ui.key`, `ui.text`, `ui.screenshot`,
  `ui.render`, `ui.parity`, `ui.resize`, `ui.focus`, `app.quit`; any other method name is
  treated as a command id (docs/control-protocol.md:51–70). New in 0.9: `ui.key`/`ui.text` are
  background-safe — they reach this window's focused widget without activating it (#2420), the
  reply `{"queued": true}` only acknowledges the queue, so inspect state after; `ui.focus`
  requests native activation separately (docs/control-protocol.md:79–88).
- **Macros**: `tools.recordMacro` / `tools.macros` record and replay command sequences
  (`crates/engine/src/cmd/tools.rs`; README.md:163–164).

### Platform
- WebAssembly web build exists and is CI-checked: `apps/wordcraft-web` (`trunk build --release`,
  `?sample`, `?webgl` URL flags; no TCP control channel, Open/Save go through the browser,
  apps/wordcraft-web/src/main.rs:1–8); `cargo xtask wasm` checks the layers for wasm32.
- Local recovery of unsaved work (desktop only), `recovery/` under the profile folder, covers
  new drafts and edits to existing files; password-protected documents get no plaintext
  recovery copies; headless/CLI/web sessions create none (docs/recovery.md:1–31).
- Native printing through craft-print: `ui.printSettings` (printer list, copies, duplex,
  grayscale, background discovery with `{"refresh":true}`, poll until `discovering` false),
  `ui.printSubmit`, `ui.print`, `file.printPdf` (also takes `paper` to scale onto another paper
  size) (docs/control-protocol.md:100–112; docs/gaps.md #6).
- Zotero integration (`crates/zotero`, docs/zotero.md) — needs the Zotero desktop app running.
  In-app: `ui.zotero.addEditCitation|addEditBibliography|addNote|refresh|removeCodes|
  setDocPrefs|status|answer`; from a terminal: `wordcraft-cli zotero <command> <file>`.

## Known limitations and not-implemented

Ranked shortfalls with evidence are in **docs/gaps.md** — read it before promising anything.
The blocking (beta) list, gaps #1–#7 (docs/gaps.md:38–44, :71):

1. **DOCX never tested on real-world files** (no corpus; synthetic fixtures only) — the files
   people receive are the files that break (docs/gaps.md:38).
2. **Word's native ink is not drawn from its strokes** (shows its picture fallback) and **OLE
   objects show only their picture** — but every ink form, drawing canvases (`wpc`), group
   shapes (`wpg`), charts and SmartArt are now preserved and written back with all their parts
   (docs/gaps.md:41; docs/file-format-parity.md:96,99–101).
3. **Field crashes and freezes in the field** (specific GPU/font reports still open); 197 open
   issues as of 2026-10-12 (docs/gaps.md:39).
4. **Pagination differs from Word** (no Aptos-metric font, legacy compatibility options
   partial, no page-by-page comparison harness) (docs/gaps.md:40).
5. Content controls, move tracking and formatting revisions have landed; still missing:
   drag-and-drop move tracking (no text drag yet), tracked style/table/section changes made in
   WordCraft itself, custom-XML binding evaluation (docs/gaps.md:42).
6. Print dialog depth: driver tray/options and pages per sheet remain (docs/gaps.md:43).
7. 59 modal dialogs vs Word's ~100 (docs/gaps.md:44; `Dialog` enum,
   `crates/ui-egui/src/dialogs.rs:145`).

Other verified gaps:
- **Charts/SmartArt from Word are read-only** (no embedded-workbook editing); no combo/3D/radar/
  stock charts (placeholder shown); WordCraft's own charts and SmartArt are editable
  (docs/gaps.md:50).
- **`.doc` is read-only** — WordCraft never writes Word 97-2003 (crates/docbin/src/lib.rs:3–4);
  Word 6/95 files are refused. **No PDF Reflow**, no MHT, no Works/WordPerfect
  (docs/gaps.md:51,63,67).
- **No VBA execution** (macros in .docm are preserved, never run), no Office add-ins, no cloud
  storage, no real-time co-authoring (docs/gaps.md:62).
- 3D models are dropped; `w:fitText` is not read or written. Legacy `w:ffData` form fields are
  now kept raw and written back; glossary/building blocks and `w:eastAsianLayout` round-trip
  (docs/file-format-parity.md:87,102,110–111).
- **Writing fidelity is partial for the non-DOCX formats**: RTF and ODT ~50%, HTML ~60%,
  Word 2003 XML write drops shapes/charts/equations etc. and is "not yet checked in Word"
  (docs/file-format-parity.md:44–51). RTF/ODT now write sections; notes/comments in RTF/ODT
  are still open (docs/gaps.md:55,57).
- **Proofing** (spelling dictionaries; `crates/proof/src/lang.rs:51–52` PROOFED): English,
  Polish, Portuguese, Italian, Croatian, Turkish, Russian, Czech and Indonesian — 9 languages,
  most via Hunspell dictionaries installed on the system, not bundled
  (docs/spelling-dictionaries.md); Bulgarian has hyphenation only; everything else is left
  unmarked (docs/gaps.md:46). ROADMAP.md:119's shorter proofing list is stale; the code and
  gaps.md agree.
- **RTL/East Asian depth** is incomplete (docs/gaps.md:53–54).
- Mail merge: CSV/TSV/TXT (any common encoding) and `.xlsx/.xlsm/.xls/.ods` only; recipient
  list search/filter and merged-only view exist; no Outlook/Access/database sources, no email
  merge (docs/gaps.md:59; `crates/formats/src/sheet.rs`).
- No in-app AI assistant (agent control is external, over CLI/MCP) (docs/gaps.md:65).
- Default shortcuts: 140 (macOS) / 158 (Linux/Windows) of Word's ~250 (docs/gaps.md:64).
- View windows (Side by Side, Arrange All) missing (docs/gaps.md:66); one document per window,
  no tabs (see below).
- The **desktop app's automation is not confined**: `--automation-read-root`/
  `--automation-write-root` apply to the headless MCP server only and are an error with
  `--connect` (docs/mcp.md:82–84).

## How to operate

Launch (macOS):
- App: `open -a WordCraft` or `open -a WordCraft --args <file.docx>`. Binary:
  `/Applications/WordCraft.app/Contents/MacOS/WordCraft`. Bundle id `ai.storyteller.wordcraft`.
- App flags (apps/wordcraft/src/main.rs:266–278): `wordcraft [--sample] [--control PORT] [FILE…]`;
  `--version`, `-h|--help`. A bad `--control` port exits with status 2.
- **`wordcraft-cli` is not inside the app bundle**. Get it from the release artifact
  `wordcraft-cli-<ver>-macos-universal.zip` (README.md:263, packaging/macos/package.sh) or
  build it: `cargo run --release -p wordcraft-cli -- <args>`.
- Useful environment variables: `WORDCRAFT_CONTROL_PORT`, `WORDCRAFT_CONTROL_KEY` (for
  `mcp --connect`), `WORDCRAFT_PROFILE_DIR` (isolated profile incl. recovery/keys),
  `WORDCRAFT_NO_PREFS` (agents' test runs; no prefs, no recovery, no key file;
  docs/recovery.md:19–25), `WORDCRAFT_PASSWORD` (CLI opens of protected files),
  `WORDCRAFT_REGION=en-US` (paper size on headless runs), `RUST_LOG` (README.md:179–183),
  `WGPU_BACKEND` (Windows graphics troubleshooting only, README.md:225–256),
  `WORDCRAFT_WAYLAND=1` (Linux native Wayland, README.md:278–285).

Document model: **one document per window, no tabs** — `WordApp` holds a single `Session`
(crates/ui-egui/src/lib.rs:498–499); document-to-document windows (Side by Side, Arrange All)
are a known gap (docs/gaps.md:66).

Core commands (exact ids, from `crates/engine/src/cmd/file.rs`):
`file.new {"template": "blank|sample|letter|resume|report"}`, `file.open {"path": …,
"password"?}`, `file.save {"path"?, "password"?, "markup"?, "format"?}`, `file.saveAs`,
`file.encrypt`, `file.rename`, `file.exportPdf {"path": …, "markup"?}`, `file.exportPng
{"path":…, "page"?, "scale"?}`, `file.printPdf {"path", "range"?, "pages"?, "parity"?,
"copies"?, "collate"?, "paper"?}`, `file.close {"force"?}` (control channel/MCP: without
`force` an unsaved document errors instead of prompting — and closing closes the document,
not the app: the window stays and `file.new`/`file.open` continues there,
docs/control-protocol.md:90–98), `file.setAuthor {"name"}`, `document.inspect`,
`document.text`, `review.trackChanges {"value": true}`.

CLI recipes (verified usage strings, apps/wordcraft-cli/src/main.rs:16–67):
```sh
wordcraft-cli convert report.docx report.pdf        # docx, doc [read], pdf, odt, rtf, html, md, tex, txt, json, png, xml
wordcraft-cli convert in.docx out.png               # page 1 only, via file.exportPng
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
  --automation-read-root /work/project --automation-write-root /work/project/out
wordcraft-cli zotero refresh paper.docx --save paper.docx
```
Exit status: 0 on success (a closed stdout pipe also exits 0), 1 on error with the message on
stderr (apps/wordcraft-cli/src/main.rs:689–695). Failures never leave a half-written output
file for `render`/`run` (docs/mcp.md:29–31).

Driving the running app (control channel):
```sh
open -a WordCraft --args --control 7981
cat ~/Library/Application\ Support/WordCraft/control-key.local-7981
# then one JSON object per line to 127.0.0.1:7981, e.g.
{"id":1,"key":"<key>","method":"engine.execute","params":{"command":"text.insert","params":{"text":"Hello"}}}
{"id":2,"key":"<key>","method":"ui.screenshot","params":{"path":"/abs/out.png"}}
```
An unauthorised request gets `{"ok":false,"error":"unauthorized"}` and the connection closes
(docs/control-protocol.md:36–37); an idle connection is closed after 30 s without an authorised
request. `wordcraft-cli mcp --connect` sends the key only to loopback addresses; to drive an
app on another machine, forward its port and set `WORDCRAFT_CONTROL_KEY`
(docs/control-protocol.md:44–49). Open/Save/Export flow: formats are chosen by file extension,
in both the CLI and the app (crates/engine/src/io.rs); `--save`/`file.save` over an existing
file replaces it in place.

Reading the app's own diagnostics: `~/Library/Application Support/WordCraft/logs/wordcraft.log`
(rotated to `.1`/`.2`, capped at 16 MiB; `--version` writes nothing; `WORDCRAFT_NO_PREFS` runs log
to stderr only — README.md:166–183). Unreadable .docx parts, pictures/fonts a PDF export left
out, and recovered panics land there.

## Working with an AI agent

Legitimate, reliable agent work with WordCraft:
- **Do document work headlessly.** `wordcraft-cli mcp`, `wordcraft-cli run` (flags or
  `--script`) need no window, no focus and no GUI driving. Verify your own work with
  `inspect_document` / `get_text` / `render_page` instead of screenshots (docs/mcp.md:113).
- **Prepare inputs**: write Markdown/HTML/CSV/text in the shell and bring it in
  (`open_document`, `insert.textFromFile`, `mailings.recipients` for `.csv/.tsv/.txt` with
  encoding detection and `.xlsx/.xlsm/.xls/.ods`, `insert.picture` with a path or base64 bytes).
- **Produce deliverables**: convert/export to PDF/ODT/RTF/HTML/MD/tex/txt/PNG from the CLI
  (docx and pdf in one `run --script`), and hand the `.docx` on for Word (README.md:92–93).
- **Attribute your edits**: pass `--author "Claude (copyedit)"` (or `file.setAuthor`) so
  reviewers can tell agent edits from people's, and turn tracking on explicitly with
  `review.trackChanges {"value": true}` (docs/mcp.md:39–46).
- **Confine yourself**: run the headless MCP server with `--automation-read-root`/
  `--automation-write-root` (a missing root grants none of that access; paths are resolved with
  links followed — docs/mcp.md:48–84).
- **Repair/interpret native projects**: the native format is `.docx` itself; `.json` is the
  engine's own model (media bytes and opaque parts included). Recovery snapshots are versioned
  JSON under `recovery/` and only the last valid generation is guaranteed (docs/recovery.md).
- **Do not**: drive the GUI blind by clicking at guessed coordinates — prefer commands; assume
  SVG/ICO/HEIC images load (they don't); assume `.doc` can be written (it can't); assume charts,
  SmartArt, OLE or native ink can be *edited* (they are preserved through saves, not editable);
  assume `.docx` fidelity on real-world files (gap #1); assume the headless session writes
  recovery copies (it doesn't).
- **Watch three footguns**: `review.trackChanges` without `value` *toggles* (it can turn
  tracking off in a document saved with it on); `file.close` over the control channel errors on
  unsaved changes unless `{"force": true}` (which discards them); `ui.key`/`ui.text` replies
  `{"queued": true}` before the edit has been applied — inspect document/widget state before
  the next dependent step (docs/control-protocol.md:79–88).

Headless UI screenshots (no focus stealing, works with a locked screen):
`cargo run --release -p wordcraft-ui-egui --example ui_shot -- script.jsonl`
(JSON-line control requests plus `{"shot": "/abs/out.png"}`, `{"steps": n}`, `{"wait": ms}`,
`{"empty": true}` to skip the sample document; crates/ui-egui/examples/ui_shot.rs:1–13).

## Verification protocol

Alpha software that never crashes by design but is unproven on real-world files: trust nothing
you did not re-open.

1. **Throwaway round-trip first**: new → type/format → save `.docx` → reopen → export `.pdf`,
   all in a scratch directory (`wordcraft-cli run --template blank --cmd … --save t.docx`, then
   `wordcraft-cli convert t.docx t.pdf`, then `wordcraft-cli inspect t.docx`).
2. **Never trust a silent export**: the CLI prints `wrote <path>` only after the command
   returned Ok, and a failing command writes nothing; still check the file exists, is non-zero,
   and re-read it. PDFs don't open in WordCraft — check a PDF elsewhere, or render the page
   with `wordcraft-cli render t.docx page.png` and look at the PNG.
3. **Compare structure, not just text**: `inspect`/`document.inspect` shows styles, tables,
   sections — use it to catch silent loss (the known failure mode is content dropped without a
   warning; docs/gaps.md #1).
4. **Keep the user's original untouched**: work on a copy; WordCraft's save replaces the file
   in place (safely, but in place). Recovery copies exist for the desktop app only, are
   unencrypted, and the newest edits before a crash can be lost (docs/recovery.md).
5. **Version and back up** project files per session; update the app only between projects
   (the launcher auto-updates; the version you script against may change).

## Sources & evidence

- Repo: https://github.com/storytold/wordcraft (org `storytold`), inspected read-only at
  **commit `2e6db0bd88795e80375176c01665cff7dbe2b057`** (tag **v0.9.0**, "Release 0.9.0",
  2026-10-19) on **2026-10-22**.
- The installed app `/Applications/WordCraft.app` is exactly this release — its CLI reports
  `wordcraft 0.9.0 (2e6db0bd)` (the bundle's `CFBundleShortVersionString` is stale; trust the
  CLI). If your installed version differs, verify against your installed version
  (`wordcraft --version`, `wordcraft-cli --version`).
- Key files read: README.md, ROADMAP.md, Cargo.toml, AGENTS.md, docs/{gaps,file-format-parity,
  mcp,control-protocol,recovery,zotero,parity-checklist,shared-pdf,spelling-dictionaries}.md,
  apps/wordcraft/src/main.rs, apps/wordcraft-cli/src/{main.rs,script.rs},
  crates/engine/src/{io.rs,io_ext.rs,catalog.rs,cmd/mod.rs,cmd/file.rs,cmd/insert.rs,
  tests_typing.rs}, crates/docx/src/crypt.rs, crates/docbin/src/lib.rs,
  crates/formats/src/lib.rs, crates/mcp/src/{tools.rs,server.rs},
  crates/control-key/src/lib.rs, crates/proof/src/lang.rs, crates/ui-egui/src/{lib.rs,
  dialogs.rs,i18n/}, crates/ui-egui/examples/ui_shot.rs, apps/wordcraft-web/src/main.rs,
  crates/render/src/lib.rs.
- Shared libraries: `storytold/craft-libs` — WordCraft pins `craft-pdf` (PDF writing) at rev
  `c3487320…` and prints through craft-print (Cargo.toml:55,105–106; docs/shared-pdf.md).
- Diffed v0.8.0..v0.9.0 in full to separate new capability from carried-over behaviour.

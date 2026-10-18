---
name: designcraft
description: DesignCraft is the ArtCraft team's open-source, clean-room page-layout and publishing app (an InDesign-style desktop application written in pure Rust, with a documented JSON project format, an IDML/PDF/EPUB/PPTX export pipeline, a headless CLI, an MCP server and a JSON control channel). Trigger this skill whenever the user mentions DesignCraft — or a `.designcraft`, `.dcbook`, `.dclib` or `.dcscript` file — asks what it can or cannot do, which formats it opens or writes, its keyboard shortcuts, how to automate or script it, how to prepare or convert assets for it, how to verify or repair its output, or how to troubleshoot it. Also trigger when the job is described without naming the app: "lay out a magazine", "thread this story across three columns", "set this on a baseline grid", "export a PDF/X-4", "make an EPUB from these pages", "batch-export every page to PNG", "place these photos in a brochure". Do not guess its capabilities from InDesign knowledge — read this first.
---

# DesignCraft

## Overview

DesignCraft is a page-layout and publishing application: an open-source, clean-room reimplementation of
Adobe InDesign's workflow, written from scratch in Rust (README.md: "an open-source, clean-room
reimplementation of Adobe InDesign, rebuilt in pure Rust"). It runs natively on macOS, Windows and Linux,
and in a browser as WebAssembly (`apps/designcraft-web`, README.md §Web).

Maturity is **pre-alpha**: `ROADMAP.md:3` and `docs/target-app-parity.md` ("Stage: **pre-alpha** (fails the
core-workflow gate)"), against a target of InDesign 2026 (21.6). Feature breadth is estimated at ~80%
(measured lower bound 69%, upper bound 99%) and "ready for real work" at ~47% — `docs/target-app-parity.md`.

Source: GitHub `storytold/designcraft`, MIT OR Apache-2.0 (`Cargo.toml`, `LICENSE-MIT`, `LICENSE-APACHE`).
The engine is a layered Cargo workspace (L0 `geom`/`color` → L5 `engine` → L6 `ui-egui` → L7 apps;
README.md §Architecture, enforced by `cargo xtask layers` in `xtask/src/layers.rs`).

The one idea that governs everything: **every user-visible action is a command** with a stable id and JSON
parameters (`crates/engine/src/cmd/mod.rs`, `command_specs()`), and the UI, the CLI, the control channel
and MCP all go through `Session::execute` (`crates/engine/src/lib.rs:5`). Prefer commands over GUI poking.

## Capabilities (verified)

### Layout and document model — implemented
- Facing/non-facing spreads, parent (master) pages with page-number markers, sections, layers, and frames
  typed text / graphic / unassigned; stories threaded across frames and spreads (`crates/doc/src/page.rs`,
  `crates/doc/src/story.rs`; `crates/engine/src/cmd/layout.rs`, `crates/engine/src/cmd/thread.rs`).
- Document setup, page size presets, bleed and slug per edge, start page, page tool for pages of their own
  size (`crates/engine/src/cmd/file.rs` — `file.new` params; `layout.documentSetup`, `layout.pageSize`).
- Multi-document tabs: several documents open at once, `file.activate {index}`, `file.close {index}`,
  `document.list`, next/previous document (`Cmd+F6` / `Cmd+Shift+F6`) — `crates/engine/src/cmd/file.rs`,
  `crates/ui-egui/src/menus.rs:199`.
- Styles (paragraph, character, object, table, cell, groups), swatches (process/spot/tints/gradients),
  text wrap, corner options, effects (`crates/engine/src/cmd/style.rs`, `crates/engine/src/cmd/object.rs`; `crates/doc/src/styles.rs`).
- Interactions: Pathfinder (boolean ops via `flo_curves`), compound paths, clipping paths, gradients,
  stroke styles/arrowheads, tables with merges and graphic cells, footnotes, endnotes, cross-references,
  index, TOC, text variables, conditional text, track changes, data merge, XML tags/DTD, articles,
  object libraries, books (`crates/engine/src/cmd/*` — 60 module `specs()` lists, see `cmd/mod.rs:166`).
- Graphics: placed rasters, PDF pages, SVG, PSD composites, EPS previews (`crates/images`, `crates/render`).

### Text engine — implemented
- Knuth–Plass total-fit paragraph composer plus a single-line composer, with a shared compose cache
  (`crates/compose/src/lib.rs:5`, `crates/compose/src/breaker.rs`).
- Dictionary hyphenation (public-domain Moby list plus trained Liang patterns) and language-dependent
  typographic quotes; bilingual/bidi text (Unicode Bidi), CJK composition with mojikumi/kinsoku, vertical
  type, ruby, kenten, warichu, tate-chu-yoko (`crates/compose/{hyphen,bidi,mojikumi,ruby,kenten,warichu}.rs`,
  `ROADMAP.md`).
- Fonts: own font DB, shaping (harfrust), outlines (skrifa), variable-font instances, document-fonts
  folders beside a document (`crates/fonts/src/fontdb.rs`, `crates/engine/src/cmd/file.rs`
  `load_document_fonts`).

### Import / open — implemented
`file.open` decides by content, not extension (`crates/engine/src/cmd/file.rs:41`, `open_path`):
- Native `.designcraft` (zip or legacy single JSON) — `crates/format`.
- `.idml` InDesign Markup, imported into the native model — `crates/idml/src/import.rs`.
- `.indd` / `.indt`, converted to IDML in memory by `storytold/indd-utils` (`crates/engine/src/cmd/interchange.rs`;
  measured only on synthetic bytes — `docs/gaps.md` §2).
- Placed graphics: PNG, JPEG, GIF, WebP, TIFF, BMP, PSD/PSB composite, SVG, PDF (one page, with crop-box
  choice), Illustrator PDF-compatible files, EPS (TIFF preview or placeholder — no PostScript interpreter)
  (`crates/images/src/lib.rs`, `crates/engine/src/cmd/file.rs` `file.place`).
- Text: `.txt`, `.docx`, `.rtf`, `.md`, `.xlsx` (first used range becomes a table), Tagged Text
  (`crates/textimport/src/{docx,rtf,xlsx,tagged}.rs`, `crates/engine/src/cmd/place_text.rs`).
- Data sources for Data Merge: CSV, TSV, text, `.xlsx` (`crates/engine/src/cmd/datamerge/`).
- Media: mp4, m4v, mov, webm, mp3, m4a, wav, ogg (`crates/engine/src/cmd/media.rs`).
- Swatches `.ase`, ICC `.icc`/`.icm`, XML (with DTD), libraries `.dclib`, books `.dcbook`
  (`crates/engine/src/cmd/{load_styles,colorsettings,xml,library,book}.rs`).

### Native format — implemented
`.designcraft` is a zip (`crates/format/src/lib.rs:1` — "The native `.designcraft` format"): `mimetype` (stored, first,
`application/vnd.designcraft+zip`), `document.json` (pretty JSON of the serde model in `crates/doc`),
`assets/<id>.<ext>` (each referenced placed file once, byte-for-byte), `meta.json`
(`{"format":"designcraft","version":N,"generator":"DesignCraft <ver>"}`) and an optional `preview.png`
(first-page picture for the start screen). Latest version 3 (`VERSION`, line 26); readers upgrade older
versions and still open the legacy single-JSON form with base64 `assetData` (`load_legacy_json`).
Read limits: 100 000 entries, 256 MiB `document.json`, 1 GiB per asset, 4 GiB total, and a document whose
geometry is not finite cannot be saved (`FormatError::Unsaveable`). `file.saveAs` appends `.designcraft`
when the extension is missing (`with_document_extension`).

### Export — implemented
- **PDF** (`crates/pdf`, command `file.exportPdf`): real selectable text with embedded font subsets,
  DeviceCMYK/RGB/Gray, spot `/Separation`, bleed boxes, crop/bleed marks and page info, pages or spreads,
  `standard: "none" | "x4" | "a2b"` (PDF/X-4 output intent with built-in conformance checks; PDF/A-2b),
  tagged PDF structure tree, transparencies flattened (`flatten: high|medium|low|ppi`), hyperlink
  annotations and outlines, interactive options, `file.printBooklet` imposition. `designcraft-cli
  validate-pdf file.pdf` runs the PDF/X-4 checks for CI (`crates/pdf/src/pdfx.rs:201`).
- **EPUB 3** reflowable (`file.exportEpub`) and fixed layout (`file.exportFixedEpub`, pre-paginated page
  images plus their text) — `crates/epub/src/lib.rs`.
- **HTML** (`file.exportHtml`): one self-contained page, styles as CSS, images embedded.
- **PowerPoint** (`file.exportPptx`): every page becomes a slide of editable shapes, pictures, tables and
  text boxes; `lineBreaks: keep|reflow`, `rasterize`, `embedFonts` (`crates/pptx/src/lib.rs`).
- **PNG / JPEG** of a page via the renderer (`designcraft-cli run --export out.png`, `--all-pages DIR`,
  MCP `render_page` / `export_png`, control `ui.render`) — `crates/render/src/lib.rs:414`.
- **IDML** (`file.exportIdml`, `embedImages`), **Text** `.txt`/`.rtf`/tagged (`file.exportText`), **XML**
  (`file.exportXml`).
- **Print** (`file.print`, `file.printers`, `dryRun`) goes through the shared `craft-print` spooler.

### Automation surfaces — implemented
- **CLI** `designcraft-cli` (`apps/designcraft-cli/src/main.rs`, the `USAGE` const): `run`, `commands
  [FILTER]`, `describe COMMAND`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`.
- **MCP server** `designcraft-cli mcp` — stdio JSON-RPC, protocol 2025-06-18 (older revisions accepted),
  tools `list_commands`, `execute`, `batch`, `inspect_document`, `get_story`, `set_story_text`,
  `new_document`, `open_document`, `save_document`, `place_image`, `render_page`, `export_png`,
  `screenshot`, `select_tool`, `pointer`, `key`, `type_text`, `ime`, `click`, `drag`, `menu_list`,
  `ui_inspect`, `ui_set`, `dialog_set`, `dialog_confirm`, `dialog_cancel` (`crates/mcp/src/tools.rs`;
  `docs/mcp.md`).
- **Control channel**: `designcraft --control PORT` serves JSON lines on `127.0.0.1` only
  (`apps/designcraft/src/control_server.rs`; methods in `crates/ui-egui/src/control.rs:169`; 4 MiB line
  limit, 16 connections, no authentication — `docs/control-protocol.md`).
- **Scripts**: one command per line with `$N.path` references to earlier results
  (`crates/engine/src/script.rs`; `script.run {text}`; `docs/agents.md`).
- Surface size at this tag: ≈483 engine command specs (grep of `cmd!` registrations outside test code
  across 60 `specs()` lists; `crates/engine/src/cmd/mod.rs:166`) plus 139 UI commands
  (`crates/ui-egui/src/menus.rs:18` `UI_COMMANDS`). `docs/target-app-parity.md` measured 446 + 99 earlier;
  treat counts as approximate and discover the live list with `designcraft-cli commands`.

### Platforms — implemented
- macOS, Windows, Linux native (`apps/designcraft`); WebAssembly web build via trunk
  (`apps/designcraft-web`: `trunk build --release`, WebGPU with a WebGL2 fallback, `?webgl` to force it,
  `?sample` for the sample magazine). The web build has no control channel, and Save/Export download files
  instead of writing them (README.md §Web).
- Runtime environment variables: `RUST_LOG`, `WGPU_BACKEND`, `WGPU_POWER_PREF`, `WGPU_ADAPTER_NAME`,
  `DESIGNCRAFT_CONTROL_PORT`, `DESIGNCRAFT_CONFIG_DIR`, `DESIGNCRAFT_NO_PREFS`,
  `DESIGNCRAFT_NO_NATIVE_MENU` (README.md §§Logs, Portable mode; `apps/designcraft/src/{main,profile}.rs`).

## Known limitations and not-implemented

Ranked shortfall list: `docs/gaps.md` (kept current by the maintainers — read it before promising work).
The headline items at this tag:

- **Pre-alpha.** The alpha gate is blocked by Smart Text Reflow on the Primary Text Frame adding pages
  users cannot delete (#165) — `docs/gaps.md` §0, `ROADMAP.md:3`. Threading by hand works.
- **Basic canvas editing still fails for some users** — object copy/paste on Windows and Linux,
  right-click context menus, formatting at a caret discarded (`docs/gaps.md` §1, issues #351/#348/#312/…,
  mostly against the 0.4/0.5 builds).
- **INDD/INDT opening is unmeasured on real files** (synthetic bytes only) and **INDB/INDL are not read**;
  no QuarkXPress import. `docs/gaps.md` §§2, 19.
- **IDML round-trip is not proven on real files** — broad importer coverage, but no InDesign-authored
  corpus metric; opened IDML can reflow (`docs/gaps.md` §§3, 4).
- **EPS is preview-only** — no PostScript interpreter; placed EPS is drawn/printed from its TIFF preview
  or replaced by a placeholder (`docs/gaps.md` §19, `crates/images/src/eps.rs`).
- **No ExtendScript/UXP compatibility**: InDesign scripts do not run; the script language is
  DesignCraft's own command language (`docs/gaps.md` §22, `crates/engine/src/script.rs`).
- **No plug-in model** (`docs/gaps.md` §23). **No in-app media playback** (`ROADMAP.md`).
- **PDF output presets and standards**: no PDF/X-1a, PDF/X-3, PDF/UA validation, Adobe `.joboptions`
  presets, or output-intent choice beyond the built-in profile; PostScript printing is absent
  (`docs/gaps.md` §§9, 10).
- **HTML export is one basic page; fixed-layout EPUB writes page images** rather than live text/CSS;
  no EPUB animation or timing (`docs/gaps.md` §17).
- **Hyphenation** for English, Spanish, Portuguese, Norwegian and Greek only; **spelling** English only
  (`docs/gaps.md` §13).
- **No screen-reader exposure** of panels and dialogs; PDF/UA of exports unverified (`docs/gaps.md` §25).
- **Startup crashes and blank canvases on some GPU/driver combinations** are a known, partly mitigated
  class (backend fallback + `gpu.json` skip list; `docs/gaps.md` §5, README.md §Graphics backend).
- **Performance**: no incremental composition (a keystroke in a huge story recomposes more than it must)
  and no GPU raster — the canvas is CPU-rendered with `vello_cpu`, the GPU only composites the UI
  (`docs/gaps.md` §20, README.md §Why DesignCraft).
- **Font discovery**: fonts activated by font services/managers are not always found; no reload when fonts
  change on disk (`docs/gaps.md` §6).
- **Localization** is partial (German and Japanese complete; others 83–85%; some languages missing) —
  `docs/gaps.md` §21, `ROADMAP.md`.
- **Stale documentation to distrust**: the `crates/pdf/src/lib.rs` module header still says "Not yet:
  tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content", but tagged PDF, hyperlinks,
  bookmarks and optional content are wired in (`crates/pdf/src/export.rs`, `links.rs`, `pdflayers.rs`
  commands); `ROADMAP.md`'s "~200 commands" line is old; `ROADMAP.md:189` points at `docs/parity.md`,
  which does not exist (the file is `docs/parity-checklist.md`); `docs/user/getting-started/install.md`
  is stamped `verified: 0.7.1`. **Uncertain — verify with `designcraft-cli describe` against your build.**

## How to operate

### Launch on macOS
- GUI: `open -a DesignCraft` (installed as `/Applications/DesignCraft.app`,
  `CFBundleIdentifier ai.storyteller.designcraft`, `CFBundleShortVersionString 0.9.0`). To open a file:
  `open -a DesignCraft ~/Documents/Brochure.designcraft`.
- Binary inside the bundle: `/Applications/DesignCraft.app/Contents/MacOS/DesignCraft`.
- Real flags of the desktop binary (`apps/designcraft/src/main.rs:346`): `--sample` (open the sample
  magazine), `--control <port>` (JSON-lines control server; also `DESIGNCRAFT_CONTROL_PORT`),
  `--version`, `--gpu-skip=<list>` (internal restart bookkeeping), plus any number of file paths.
- **The CLI is not inside the `.app` on macOS.** The release ships it as a separate
  `designcraft-cli-<version>-macos-<arch>.zip` (`docs/mcp.md`, `packaging/macos/package.sh`), and it is
  *not* on `PATH` on this machine (`which designcraft-cli` → not found). Get it by downloading that asset,
  or build it: `cargo run --release -p designcraft-cli -- <args>` (README.md §Quick start). Do not assume
  a system-wide `designcraft-cli` exists.
- State lives in `~/Library/Application Support/DesignCraft/`: `ui.json`, `prefs.json`,
  `logs/designcraft.log` (rotates to `.1.log`/`.2.log`, 16 MiB cap), and `Recovery/`
  (`apps/designcraft/src/profile.rs`, `crates/engine/src/recovery.rs`). `portable.txt` next to the app
  switches to a `DesignCraftData` folder; `DESIGNCRAFT_CONFIG_DIR` overrides both.

### CLI reference (exact, from `apps/designcraft-cli/src/main.rs`)
```
designcraft-cli run [--in FILE(.designcraft|.idml|.indd|.indt) | --sample] [--cmd ID[=JSON]]...
                   [--page N] [--scale S] [--pdf-options JSON] [--export OUT] [--all-pages DIR]
designcraft-cli commands [FILTER]          # every command as JSON; FILTER matches id/label/menu
designcraft-cli describe COMMAND           # label, menu path, shortcut and parameters of one command
designcraft-cli script [FILE|-] [--in FILE | --sample] [--connect PORT] [--save OUT]
                       [--export OUT] [--keep-going] [--help]
designcraft-cli app [--port PORT] COMMAND [JSON] | app --method METHOD [JSON]
designcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR] [--automation-write-root DIR]
designcraft-cli perf [--pages N] [--runs N] [--strict] | bench FILE [--runs N]
designcraft-cli validate-pdf FILE.pdf | links | --version
```
- `--page`, `--scale` and `--pdf-options` apply to the `--export`s that **follow** them; one left after the
  last export is an error.
- `--export` picks the writer from the extension: `.png`/`.jpg`/`.jpeg` (a page), `.pdf`, `.designcraft`,
  `.idml`, `.epub`, `.pptx`, `.html`/`.htm`, `.rtf`/`.txt`; an unknown extension is an error and *nothing
  runs*; a name with no extension is a PNG of the page (`Export::of`).
- `run --cmd ID=JSON` builds each command's params; `$N.path`/`$last.path` references earlier results;
  unknown parameter keys are refused with "did you mean …" (`crates/engine/src/cmd/params.rs`,
  `crates/engine/src/tests_params.rs:57`).
- `script` prints `{"completed": n, "results": [...]}` plus `failedIndex`/`failedCommand`/`error` and exits
  non-zero on failure; `--keep-going` records failures as results instead.

### Document and window model
- Several documents open in tabs; each tab is its own `DocState` with its own undo history, selection and
  (optionally) its own `Document Fonts` scope (`crates/engine/src/lib.rs`, `crates/ui-egui/src/chrome.rs`
  — the document tab bar; `crates/engine/src/cmd/file.rs` `load_document_fonts`).
- A document is spreads → pages → items; text lives in **stories** that are threaded through text frames;
  parent pages contribute items behind a page's own (`crates/doc/src/{page,story,item}.rs`).
- **Coordinates are points (1/72 in), y down, in spread space**: on a facing spread the right page starts at
  `x = page width` (`docs/mcp.md` §Coordinates). `inspect_document` lists per-spread page bounds.
- **Text offsets are UTF-8 byte offsets**, not character counts (`anchor`, `focus`, `story.replaceRange`,
  `story.length`) — `docs/mcp.md` §Text offsets.
- Commands that create items take `spread`: an integer, or `{"kind":"parent","index":N}` for a parent
  spread (`crates/engine/src/cmd/mod.rs` `spread_param`).

### Open / save / export flows
- Open: `File ▸ Open…` (`Cmd+O`, `file.open {path}`) — content-sniffed; `.idml` and `.indd`/`.indt` route
  through the IDML interchange module. `File ▸ Open Recent` uses `file.recentFiles` / `file.openRecent`.
- Save: `File ▸ Save` (`Cmd+S`, `file.save`) and `Save As…` (`Cmd+Shift+S`, `file.saveAs {path}`) write the
  native `.designcraft` package (extension appended if missing). `file.saveACopy` writes a copy without
  changing the open document. Writes are atomic (`designcraft_engine::atomic::write_atomic`).
- Recovery: unsaved documents are written to the recovery folder on a timer and reopened after a crash
  (`crates/engine/src/recovery.rs`; `file.recovery.{save,list,open}`, `file.revert`).
- Export: the `file.export*` commands above, or the CLI's `--export`. Every export returns
  `{path, bytes, …}` and, where applicable, a `warnings` array — **read it** (e.g. `file.exportPdf` warns on
  mixed gradient colour spaces and PDF/X-4 checks).
- Package for hand-off: `File ▸ Package` (UI command `app.packageDialog`, `Cmd+Alt+Shift+P`; engine
  `file.package`) relinks to a `Links` folder, copies placed files and document fonts, writes an IDML copy,
  an optional PDF and a report (`crates/engine/src/cmd/package.rs`).

### Verified recipes
```sh
# Headless: build a page and export it three ways
designcraft-cli run --sample \
  --cmd 'frame.create={"rect":[36,36,540,300],"content":"text","text":"Hello"}' \
  --export page.png --scale 2 --export page@2x.png --export page.pdf

# Discover then call a command (never guess params)
designcraft-cli commands footnote
designcraft-cli describe xref.insert

# A script with references to earlier results, saved and exported
printf '%s\n' \
  'frame.create {"rect": [72, 72, 540, 300], "content": "text", "text": "Results"}' \
  'text.select {"story": "$0.story", "anchor": 0, "focus": 0}' \
  'footnote.insert {"text": "Survey run in 2026."}' > page.dcs
designcraft-cli script page.dcs --save page.designcraft --export page.pdf --export page.png

# Drive a running app (start it with a control port first)
designcraft --sample --control 7979 &
designcraft-cli app document.inspect
designcraft-cli app --method ui.screenshot '{"path":"/tmp/window.png"}'
designcraft-cli script page.dcs --connect 7979
```
MCP registration (`docs/mcp.md`):
```sh
claude mcp add designcraft -- designcraft-cli mcp \
  --automation-read-root /work/project --automation-write-root /work/project/out
```
The two root flags confine every path a *command* reads or writes (open, place, data sources, libraries,
saves, exports, packaging); a root left out grants none of that access, and `--connect` together with the
roots is an error (`docs/mcp.md` §Confining file access, `crates/engine/src/file_access.rs`).

## Working with an AI agent

**Legitimate and productive**
1. **Prepare inputs.** Rasterise/convert to formats `crates/images` reads (PNG, JPEG, GIF, WebP, TIFF, BMP,
   PSD composite), author SVG or single-page PDF for vector/print art, write `.docx`/`.rtf`/`.txt`/`.md`
   for copy, and CSV/TSV/XLSX for Data Merge. Generate a magazine-style test document with
   `file.newSample` or `designcraft-cli run --sample`.
2. **Drive it through commands, not pixels.** Prefer `designcraft-cli run --cmd`, `script` with `$N.path`
   wiring, MCP `batch`, or the control channel. Every gesture path also exists (`ui.pointer`, `key`,
   `type_text`, `ime`, `dialog_*`), but commands are deterministic, faster, and give you JSON back.
3. **Look at the result.** `render_page`/`export_png`/`ui.render` return or write PNGs — read the image
   after layout work instead of trusting command exit codes. `ui.screenshot` gives the whole window.
4. **Inspect programmatically.** `document.inspect`, `story.get` (including `overset`), `links.list`,
   `font.list`, `preflight.run {minPpi?}`, `view.separations`, `document.preferences` tell you the real
   state; `designcraft-cli describe` tells you a command's exact parameter names before you call it.
5. **Repair and analyse native files.** A `.designcraft` is a zip: `unzip -o f.designcraft -d f/` then read
   `document.json`, `meta.json` and `assets/`. Useful for auditing what a document references, extracting
   placed files, or spotting a missing asset. **Re-zipping by hand is risky**: the reader requires
   `document.json`, honours `meta.json`'s `version` (a version above 3 is refused with "please update"),
   and runs `Document::check()` plus asset wiring on load, so a hand-edited model that violates invariants
   may be refused rather than repaired. Prefer opening the file and re-saving through a command.
6. **Verify exports.** `designcraft-cli validate-pdf out.pdf` (PDF/X-4 checks), `preflight.run` before
   export, `story.get` for overset text, `links.list` for missing images, and the `warnings` array of every
   export result.
7. **Work on throwaway copies.** Copy the project file before an agent session and work in a temp folder —
   `DESIGNCRAFT_CONFIG_DIR=$TMP/dc-profile` isolates preferences and the recovery folder for a test run.

**Do not attempt**
- Do not read capabilities out of InDesign documentation or assume parity: check `docs/gaps.md` and
  `designcraft-cli describe`. ExtendScript, UXP, `.joboptions` presets, plug-ins and Adobe cloud features
  do not exist (`docs/gaps.md` §§22, 23, "Out of scope").
- Do not assume the CLI or MCP server is installed: on macOS the `.app` holds only the desktop app
  (`docs/mcp.md`; verified on this machine). Build or download it first, and say so to the user.
- Do not interpret EPS/PostScript or expect `.indd`/`.indt` fidelity, INDB/INDL, or QuarkXPress import.
- Do not hand-craft IDML as an input format expecting a lossless round-trip — the importer is broad but
  unmeasured on real InDesign files (`docs/gaps.md` §3).
- Do not drive the GUI blind (blind coordinate clicks, no screenshot/inspect feedback), and never run
  `--control` on a port you do not control: the channel has no authentication (`docs/control-protocol.md`).
- Do not edit the repository to change app behaviour; use documents, preferences and commands.

## Verification protocol

DesignCraft is pre-alpha: treat every export as unverified until you have looked at it. The discipline:

1. **Throwaway round-trip first.** With every version, before real work: new document (`file.new` or
   `--sample`) → one edit → `--save` a `.designcraft` → reopen it (`--in`) → export the same page to PNG
   *and* PDF → check the PNG visually and the PDF with `validate-pdf` if you asked for `standard: "x4"`.
   If any step fails or the geometry moved, stop and report; do not build a bigger job on top.
2. **Never trust a silent export.** Read the JSON result (`bytes`, `pages`, `slides`, `warnings`) *and*
   confirm the file exists and is non-empty. A page export with no `--export` after it is a usage error,
   not a no-op, so partial runs fail loudly — except that a failed *step* in a non-`--keep-going` script
   still leaves earlier steps applied in the live app: re-inspect the document before retrying.
3. **Version and back up per session.** The format version is part of the file (`meta.json`); an older app
   refuses a newer document (`FormatError::TooNew`). Keep a copy of the project file at the start of an
   agent session, and if you must deliver files to someone on an older build, test one round-trip on their
   version first.
4. **Update between projects, not during one.** The app is installed and updated by ArtCraft Launcher
   (`docs/user/getting-started/install.md` §Install with ArtCraft Launcher). After an update, re-verify
   the bundle version and build commit before trusting earlier measurements:
   `plutil -p /Applications/DesignCraft.app/Contents/Info.plist | grep -E 'Version|BuildCommit'`
   (at this tag: `0.9.0`, commit `7cb8b12507def48fb9346e5004340b5e8e4cfcb7`).
5. **Isolate test runs.** `DESIGNCRAFT_CONFIG_DIR` to a scratch folder, `DESIGNCRAFT_NO_PREFS` to avoid
   writing preferences, and `--automation-read-root`/`--automation-write-root` when an agent drives MCP.
6. **Prefer re-opening over re-editing.** Because the reader upgrades and validates on load, a save →
   reopen cycle is the cheapest proof that an edit produced a valid document.

*Verify against your installed version.* The repository at this tag and the installed bundle currently
match exactly (same commit); if the launcher has since updated DesignCraft, re-run step 4 and re-check any
command parameters with `designcraft-cli describe` before relying on them.

## Sources & evidence

- Repository: https://github.com/storytold/designcraft — inspected at tag **v0.9.0**, commit
  **`7cb8b12507def48fb9346e5004340b5e8e4cfcb7`** (`git rev-parse HEAD`), 2026-10-18.
- Installed app: `/Applications/DesignCraft.app`, `CFBundleShortVersionString 0.9.0`,
  `DesignCraftBuildCommit 7cb8b12507def48fb9346e5004340b5e8e4cfcb7`, `LSMinimumSystemVersion 11.0`
  (`Contents/Info.plist`; the bundle was inspected, never launched).
- Read for this skill: `README.md`, `Cargo.toml`, `ROADMAP.md`, `docs/agents.md`, `docs/mcp.md`,
  `docs/control-protocol.md`, `docs/gaps.md`, `docs/target-app-parity.md`,
  `docs/user/getting-started/install.md`, `apps/designcraft/src/main.rs`,
  `apps/designcraft-cli/src/{main,automation_args}.rs`, `crates/format/src/lib.rs`,
  `crates/engine/src/{lib,script,guard,recovery}.rs`, `crates/engine/src/cmd/{mod,file,export,interchange,preflight,scripts}.rs`,
  `crates/mcp/src/tools.rs`, `crates/ui-egui/src/{control,menus}.rs`, `apps/designcraft/src/{control_server,profile}.rs`,
  and the per-crate `Cargo.toml` descriptions for `crates/{pdf,epub,pptx,idml,images,textimport}`.
- Live discovery beats this document for details: `designcraft-cli commands`, `designcraft-cli describe ID`,
  and `docs/gaps.md` (the maintainers' ranked work list).

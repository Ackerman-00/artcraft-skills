---
name: designcraft
description: DesignCraft is the ArtCraft team's open-source page-layout and publishing app (an InDesign-parity desktop application written in pure Rust, with a documented JSON project format, an IDML/PDF/EPUB/PPTX export pipeline, a headless CLI, an MCP server and a JSON control channel). Trigger this skill whenever the user mentions DesignCraft — or a `.designcraft`, `.dcbook`, `.dclib` or `.dcscript` file — asks what it can or cannot do, which formats it opens or writes, its keyboard shortcuts, how to automate or script it, how to prepare or convert assets for it, how to verify or repair its output, or how to troubleshoot it. Also trigger when the job is described without naming the app: "lay out a magazine", "thread this story across three columns", "set this on a baseline grid", "export a PDF/X-4", "make an EPUB from these pages", "batch-export every page to PNG", "place these photos in a brochure". Do not guess its capabilities from InDesign knowledge — read this first.
---

# DesignCraft

## Overview

DesignCraft is a page-layout and publishing application written from scratch in Rust: "page layout
and publishing; an open-source, modern desktop publishing and page layout studio" (README.md). Its
stated goal is full Adobe InDesign parity — "faster, open (documented JSON format + IDML), scriptable
by agents (MCP), and available on the web" (ROADMAP.md) — measured against InDesign 2026 (21.6)
(`docs/target-app-parity.md`). It runs natively on macOS, Windows and Linux, and in a browser as
WebAssembly (`apps/designcraft-web`, README.md §Web).

Maturity is **pre-alpha**: `ROADMAP.md:3` and `docs/target-app-parity.md` ("Stage: **pre-alpha**
(fails the core-workflow gate)"; the gate is blocked by Primary Text Frame autoflow, #165). Feature
breadth is estimated at ~80% (measured bounds 69–99%) and "ready for real work" at ~47%
(`docs/target-app-parity.md` headline).
Source: GitHub `storytold/designcraft`, MIT OR Apache-2.0 (`Cargo.toml`, `LICENSE-MIT`,
`LICENSE-APACHE`). Layered Cargo workspace (L0 `geom`/`color` → L5 `engine` → L6 `ui-egui` → L7
apps; README.md §Architecture, enforced by `cargo xtask layers`). Shared craft-libs crates do
printing (`craft-print`), ICC colour management (`craft-cms`), atomic writes (`craft-atomic`) and
document-path policy (`craft-docpath`) — `Cargo.toml:76-87`.

The one idea that governs everything: **every user-visible action is a command** with a stable id and
JSON parameters (`crates/engine/src/lib.rs:3`), and the UI, the CLI, the control channel and MCP all
go through `Session::execute`. Prefer commands over GUI poking. The deep automation reference —
CLI flags, script syntax, all MCP tools, every control-channel method, coordinates and text offsets —
is in `references/agent-surfaces.md` next to this file.

## Capabilities (verified)

### Layout and document model — implemented
- Facing/non-facing spreads, parent (master) pages with page-number markers (parents deletable via
  `layout.parents.delete {id}`), sections, layers, and frames typed text / graphic / unassigned;
  stories threaded across frames and spreads (`crates/doc/src/{page,story}.rs`;
  `crates/engine/src/cmd/{layout,thread}.rs`).
- Document setup, page size presets (incl. A0–A2 posters), bleed and slug per edge, start page, page
  tool for pages of their own size (`crates/engine/src/cmd/file.rs` `file.new`; `layout.documentSetup`,
  `layout.pageSize`).
- Multi-document tabs: several documents at once, `file.activate {index}`, `document.list`,
  next/previous document (`Cmd+F6` / `Cmd+Shift+F6`) — `crates/engine/src/cmd/file.rs:93`,
  `crates/ui-egui/src/menus.rs:199`.
- Styles (paragraph, character, object, table, cell, groups), swatches (process/spot/tints/gradients),
  text wrap, corner options, transparency effects, ICC colour management with working spaces and
  proof setups (`crates/engine/src/cmd/{style,object,colorsettings}.rs`; `crates/doc/src/styles.rs`).
- Interactions: Pathfinder boolean ops, compound paths, clipping paths, gradients, stroke
  styles/arrowheads, tables with merges and graphic cells, footnotes, endnotes, notes,
  cross-references, index, TOC, text variables, conditional text, track changes, data merge, XML
  tags/DTD, articles, object libraries, books, object states, buttons and form fields, page
  transitions — `crates/engine/src/cmd/*` (see `command_specs()` at `crates/engine/src/cmd/mod.rs:166`).
- Generators: QR codes (`object.qrCode`: url/text/sms/email/vcard — `crates/engine/src/cmd/qr.rs:16`),
  math expressions (`math.insert`, a LaTeX subset typeset to SVG —
  `crates/engine/src/cmd/mathexpr.rs:40`), colour themes from a placed image (`color.extractTheme` —
  `crates/engine/src/cmd/color_theme.rs:11`).
- Graphics: placed rasters, PDF pages, SVG, PSD composites, EPS previews (`crates/images`,
  `crates/render`).

### Text engine — implemented
- Knuth–Plass total-fit paragraph composer plus a single-line composer, with a shared compose cache
  (`crates/compose/src/lib.rs`, `crates/compose/src/breaker.rs`).
- Dictionary hyphenation (public-domain Moby list plus trained Liang patterns) and language-dependent
  typographic quotes; bidi text (Unicode Bidi), right-to-left composition with kashida and digit
  substitution, CJK composition with mojikumi/kinsoku, vertical type, ruby, kenten, warichu,
  tate-chu-yoko (`crates/compose/{hyphen,bidi,mojikumi,ruby,kenten,warichu}.rs`, `ROADMAP.md`).
- Fonts: own font DB, shaping (harfrust), outlines (skrifa), variable-font instances (named and
  arbitrary axis values), document-fonts folders beside a document, and Type › Reload Fonts
  (`font.reload`) to re-read fonts changed on disk (`crates/fonts/src/fontdb.rs`,
  `crates/engine/src/cmd/fonts.rs:30`, `crates/engine/src/cmd/file.rs` `load_document_fonts`).

### Import / open — implemented
`file.open` decides by content, not extension (`crates/engine/src/cmd/file.rs:465`, `open_path`):
- Native `.designcraft` (zip or legacy single JSON) — `crates/format`.
- `.idml` InDesign Markup, imported into the native model — `crates/idml/src/import.rs`;
  `.indd`/`.indt` converted to IDML in memory by `storytold/indd-utils`
  (`crates/engine/src/cmd/interchange.rs`; measured only on synthetic bytes — `docs/gaps.md` §2).
- Placed graphics: PNG, JPEG, GIF, WebP, TIFF, BMP, PSD/PSB composite, SVG, PDF (any page, crop-box
  choice), Illustrator PDF-compatible files, EPS (TIFF preview or placeholder — no PostScript
  interpreter) (`crates/images/src/lib.rs`, `crates/engine/src/cmd/file.rs:134` `file.place`).
- Text: `.txt`/`.text`, `.docx`, `.rtf`, `.md`, `.xlsx` (first used range becomes a table), Tagged
  Text (`crates/textimport/src/lib.rs:94`, `crates/textimport/src/{docx,rtf,xlsx,tagged}.rs`,
  `crates/engine/src/cmd/place_text.rs`). Data sources for Data Merge: CSV, TSV, text, `.xlsx`
  (`crates/engine/src/cmd/datamerge/`).
- Media (poster/placeholder frames, no playback): mp4, m4v, mov, webm, ogv, mp3, m4a, wav, ogg, oga,
  aac (`crates/doc/src/item.rs:839`, `media_mime`; `crates/engine/src/cmd/media.rs`).
- Swatches `.ase`, ICC `.icc`/`.icm`, XML (with DTD), libraries `.dclib`, books `.dcbook`, and a
  page of an IDML or `.designcraft` document (`file.place {layoutPage}`) as a group of objects
  (`crates/engine/src/cmd/{style,colorsettings,xml,library,book}.rs`).

### Native format — implemented
`.designcraft` is a zip (`crates/format/src/lib.rs:1`): `mimetype` (stored, first,
`application/vnd.designcraft+zip`), `document.json` (pretty JSON of the serde model in `crates/doc`),
`assets/<id>.<ext>` (each referenced placed file once, byte-for-byte), `meta.json` (format version
and generator) and an optional `preview.png`. Latest reader capability is version 3
(`VERSION`, `crates/format/src/lib.rs:26`); the writer pins a file to version 3 only when it holds
EPS assets, else stays at version 2 so older readers keep working (`lib.rs:90`). Readers upgrade
older versions and still open the legacy single-JSON form with base64 `assetData` (`load`,
`lib.rs:156`). Read limits: 100 000 entries, 256 MiB `document.json`, 1 GiB per asset, 4 GiB total
(`lib.rs:164-170`); a document with non-finite geometry cannot be saved (`FormatError::Unsaveable`,
`lib.rs:72`). `file.saveAs` appends `.designcraft` when the extension is missing
(`with_document_extension`, `crates/engine/src/cmd/file.rs:167`). Writes are atomic (`craft-atomic`
via `crates/engine/src/io.rs:113`).

### Export — implemented
- **PDF** (`crates/pdf`, command `file.exportPdf`): real selectable text with embedded font subsets,
  DeviceCMYK/RGB/Gray, spot `/Separation`, bleed boxes, crop/bleed marks and page info, pages or
  spreads, `standard: "none" | "x4" | "a2b"` (PDF/X-4 output intent with built-in conformance
  checks; PDF/A-2b), tagged PDF structure tree, transparency flattening
  (`flatten: high|medium|low|ppi`), hyperlink annotations and outlines, interactive options,
  `file.printBooklet` imposition; `designcraft-cli validate-pdf file.pdf` runs the PDF/X-4 checks
  for CI (`crates/pdf/src/pdfx.rs:210`).
- **EPUB 3** reflowable (`file.exportEpub`) and fixed layout (`file.exportFixedEpub`, pre-paginated
  page images plus their text) — `crates/epub/src/lib.rs`.
- **HTML** (`file.exportHtml`): one self-contained page, styles as CSS, images embedded.
- **PowerPoint** (`file.exportPptx`): every page becomes a slide of editable shapes, pictures, tables
  and text boxes; `lineBreaks: keep|reflow`, `rasterize`, `embedFonts` (`crates/pptx/src/lib.rs`,
  `crates/engine/src/cmd/export.rs:29`).
- **PNG / JPEG** of a page via the renderer (`designcraft-cli run --export out.png`, `--all-pages
  DIR`; MCP `render_page` / `export_png`; control `ui.render`) — `crates/render/src/lib.rs:414`.
- **IDML** (`file.exportIdml`, `embedImages`), **Text** `.txt`/`.rtf`/tagged (`file.exportText`),
  **XML** (`file.exportXml`).
- **Print** (`file.print`, `file.printers`, `dryRun`) through the shared `craft-print` spooler
  (CUPS on macOS/Linux; Windows spooler in-process) — `Cargo.toml:80`, `docs/gaps.md` §10.

### Automation surfaces — implemented
- **CLI** `designcraft-cli` (`apps/designcraft-cli/src/main.rs`, the `USAGE` const at :42): `run`,
  `commands [FILTER]`, `describe COMMAND`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`,
  `links`.
- **MCP server** `designcraft-cli mcp` — stdio JSON-RPC, protocol 2025-06-18 (older revisions
  accepted), 26 tools: command discovery/execution (`list_commands`, `execute`, `batch`), document
  I/O and inspection (`inspect_document`, `get_story`, `set_story_text`, `new_document`,
  `open_document`, `save_document`, `place_image`), rendering (`render_page`, `export_png`,
  `screenshot`), input/UI tools (`select_tool`, `pointer`, `key`, `type_text`, `ime`, `click`,
  `drag`, `menu_list`, `ui_inspect`, `ui_set`, `dialog_set/confirm/cancel`)
  (`crates/mcp/src/tools.rs:83`; `docs/mcp.md`). Read/write root flags confine every path a command
  touches (`crates/engine/src/file_access.rs`).
- **Control channel**: `designcraft --control PORT` serves JSON lines on `127.0.0.1` only
  (`apps/designcraft/src/control_server.rs`; methods in `crates/ui-egui/src/control.rs:149`; 4 MiB
  line limit, 16 connections, no authentication — `docs/control-protocol.md`).
- **Scripts**: one command per line with `$N.path` references to earlier results
  (`crates/engine/src/script.rs`; `script.run {text}`; `docs/agents.md`).
- Surface size at this tag: **485 engine command specs** (unique `cmd!` registrations outside
  `#[cfg(test)]` across 61 `specs()` lists; `crates/engine/src/cmd/mod.rs:166`) plus **164 UI
  commands** (`crates/ui-egui/src/menus.rs:18` `UI_COMMANDS`). `docs/target-app-parity.md` measured
  446 + 99 earlier (2026-10-10); treat counts as approximate and discover the live list with
  `designcraft-cli commands`.

### Platforms — implemented
- macOS, Windows, Linux native (`apps/designcraft`); WebAssembly web build via trunk
  (`apps/designcraft-web`: WebGPU with a WebGL2 fallback, `?webgl` to force it, `?sample` for the
  sample magazine). The web build has no control channel, and Save/Export download files instead
  of writing them (README.md §Web). Runtime environment variables: `RUST_LOG`, `WGPU_BACKEND`,
  `WGPU_POWER_PREF`, `WGPU_ADAPTER_NAME`, `WGPU_VALIDATION_INDIRECT_CALL`,
  `DESIGNCRAFT_CONTROL_PORT`, `DESIGNCRAFT_CONFIG_DIR`, `DESIGNCRAFT_NO_PREFS`,
  `DESIGNCRAFT_NO_NATIVE_MENU`, `DESIGNCRAFT_WAYLAND` (Linux) — README.md §§Logs, Portable mode;
  `apps/designcraft/src/{main,profile}.rs`.

## Known limitations and not-implemented

Ranked shortfall list: `docs/gaps.md` (kept current by the maintainers — read it before promising
work). Headline items at this tag:

- **Pre-alpha.** The alpha gate is blocked by Smart Text Reflow on the Primary Text Frame adding
  pages users cannot delete (#165) — `docs/gaps.md` §0, `ROADMAP.md:3`. Threading by hand works.
- **Basic canvas editing still fails for some users** — object copy/paste on Windows and Linux,
  right-click context menus, formatting at a caret discarded (`docs/gaps.md` §1; issues mostly
  against the 0.4/0.5 builds).
- **INDD/INDT opening is unmeasured on real files**; **INDB/INDL are not read**; no QuarkXPress
  import (`docs/gaps.md` §§2, 19).
- **IDML round-trip is not proven on real files** — broad importer coverage, but no InDesign-authored
  corpus metric; opened IDML can reflow (`docs/gaps.md` §§3, 4).
- **EPS is preview-only** — no PostScript interpreter; placed EPS is drawn/printed from its TIFF
  preview or replaced by a placeholder (`docs/gaps.md` §19, `crates/images/src/eps.rs`).
- **No ExtendScript/UXP compatibility**: InDesign scripts do not run; the script language is
  DesignCraft's own command language (`docs/gaps.md` §22). **No plug-in model** (`docs/gaps.md`
  §23). **No in-app media playback** (`docs/gaps.md` §19 area, ROADMAP.md).
- **PDF output presets and standards**: no PDF/X-1a, PDF/X-3, PDF/UA validation, Adobe
  `.joboptions` presets, or output-intent choice beyond the built-in profile; PostScript printing
  is absent (`docs/gaps.md` §§9, 10).
- **HTML export is one basic page; fixed-layout EPUB writes page images** rather than live
  text/CSS; no EPUB animation or timing (`docs/gaps.md` §17).
- **Hyphenation** for English, Spanish, Portuguese, Norwegian and Greek only; **spelling** English
  only (`docs/gaps.md` §13).
- **No screen-reader exposure** of panels and dialogs; PDF/UA of exports unverified
  (`docs/gaps.md` §25).
- **Startup crashes and blank canvases on some GPU/driver combinations** are a known, partly
  mitigated class (backend fallback + `gpu.json` skip list; `docs/gaps.md` §5, README.md §Graphics
  backend).
- **Performance**: no incremental composition and no GPU raster — the canvas is CPU-rendered with
  `vello_cpu`, the GPU only composites the UI (`docs/gaps.md` §20, README.md §Why DesignCraft).
- **Font discovery**: fonts activated by font services/managers are not always found everywhere;
  disk changes are noticed only on request (`font.reload`), not automatically (`docs/gaps.md` §6 —
  shrunk at this tag: macOS reads CoreText's fonts, `font.reload` exists).
- **Localization** is partial: Japanese 95%, Czech and Polish 99%, Georgian 100%, several languages
  61–85%, Hindi/Indonesian/Korean/Vietnamese absent — `ROADMAP.md` §Languages, `docs/gaps.md` §21.
  (The older "German and Japanese complete" claim no longer holds: the table now scores German 83%.)
- **Stale documentation to distrust**: `crates/pdf/src/lib.rs:28` still says "Not yet: tagged PDF,
  bookmarks, hyperlinks, overprint, layers as optional content", but tagged PDF, hyperlinks,
  bookmarks, forms and page transitions are wired in (`crates/pdf/src/{export,links,forms,
  transitions}.rs`, `crates/engine/src/cmd/pdflayers.rs`); `ROADMAP.md:180`'s "~200 commands" line
  is old (registry has 485 + 164); `docs/user/getting-started/install.md` is stamped
  `verified: 0.7.1`. Uncertain — verify with `designcraft-cli describe` against your build.

## How to operate

### Launch on macOS
- GUI: `open -a DesignCraft` (installed under `/Applications/DesignCraft.app`,
  `CFBundleIdentifier ai.storyteller.designcraft`, version 0.11.0 at this pin). To open a file:
  `open -a DesignCraft ~/Documents/Brochure.designcraft`. The binary inside the bundle is
  `/Applications/DesignCraft.app/Contents/MacOS/DesignCraft`.
- Real flags of the desktop binary (`apps/designcraft/src/main.rs:350`): `--sample` (open the sample
  magazine), `--control <port>` (JSON-lines control server; also `DESIGNCRAFT_CONTROL_PORT`),
  `--version`, `--gpu-skip=<list>` (internal restart bookkeeping, `apps/designcraft/src/gpu.rs:57`),
  plus any number of file paths.
- **The CLI is not inside the `.app` on macOS.** The release ships it as a separate
  `designcraft-cli-<version>-macos-*.zip` asset (`docs/mcp.md` §From an installed release;
  `packaging/macos/package.sh`), and it is *not* on `PATH` on this machine (`which designcraft-cli`
  → not found). Get it by downloading that asset, installing with `cargo install --path
  apps/designcraft-cli --locked` (`docs/mcp.md` §From source), or build it: `cargo run --release
  -p designcraft-cli -- <args>` (README.md §Quick start). Do not assume a system-wide
  `designcraft-cli` exists.
- State lives in `~/Library/Application Support/DesignCraft/`: `ui.json`, `prefs.json`,
  `logs/designcraft.log` (rotates to `.1.log`/`.2.log`, 16 MiB cap), `gpu.json`, and `Recovery/`
  (`apps/designcraft/src/profile.rs`, `crates/engine/src/recovery.rs`). `portable.txt` next to the
  app switches to a `DesignCraftData` folder; `DESIGNCRAFT_CONFIG_DIR` overrides both.

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
- `--page`, `--scale` and `--pdf-options` apply to the `--export`s that **follow** them; one left
  after the last export is an error.
- `--export` picks the writer from the extension: `.png`/`.jpg`/`.jpeg` (a page), `.pdf`,
  `.designcraft`, `.idml`, `.epub`, `.pptx`, `.html`/`.htm`, `.rtf`/`.txt`; an unknown extension is
  an error and *nothing runs*; a name with no extension is a PNG of the page (`Export::of`).
- `run --cmd ID=JSON` builds each command's params; `$N.path`/`$last.path` reference earlier
  results; a params key the command's description doesn't name is an error
  (`crates/engine/src/cmd/params.rs`, `docs/agents.md`).
- `script` prints `{"completed": n, "results": [...]}` plus `failedIndex`/`failedCommand`/`error`
  and exits non-zero on failure; `--keep-going` records failures as results instead.

### Document and window model
- Several documents open in tabs; each tab is its own `DocState` with its own undo history,
  selection and (optionally) its own `Document Fonts` scope (`crates/engine/src/lib.rs`,
  `crates/ui-egui/src/chrome.rs`; `crates/engine/src/cmd/file.rs` `load_document_fonts`). A
  document is spreads → pages → items; text lives in **stories** threaded through text frames;
  parent pages contribute items behind a page's own (`crates/doc/src/{page,story,item}.rs`).
- **Coordinates are points (1/72 in), y down, in spread space**: on a facing spread the right page
  starts at `x = page width` (`docs/mcp.md` §Coordinates); `inspect_document` lists per-spread page
  bounds. **Text offsets are UTF-8 byte offsets**, not character counts (`anchor`, `focus`,
  `story.replaceRange`, `story.length`) — `docs/mcp.md` §Text offsets.
- Commands that create items take `spread`: an integer, or `{"kind":"parent","index":N}` for a
  parent spread (`crates/engine/src/cmd/mod.rs` `spread_param`).

### Open / save / export flows
- Open: `File ▸ Open…` (`Cmd+O`, `file.open {path}`) — content-sniffed; `.idml` and `.indd`/`.indt`
  route through the IDML interchange module. `File ▸ Open Recent` uses `file.recentFiles` /
  `file.openRecent` (`crates/engine/src/cmd/file.rs:45`).
- Save: `File ▸ Save` (`Cmd+S`, `file.save`) and `Save As…` (`Cmd+Shift+S`, `file.saveAs {path}`)
  write the native `.designcraft` package (extension appended if missing); `file.saveACopy` writes a
  copy without changing the open document; writes are atomic.
- Recovery: unsaved documents are written to the recovery folder every 30 s and reopened after a
  crash (`crates/engine/src/recovery.rs`; `file.recovery.{save,list,open}`, `file.revert`).
- Export: the `file.export*` commands above, or the CLI's `--export`. Every export returns
  `{path, bytes, …}` plus a `warnings` array where applicable — **read it** (e.g. `file.exportPdf`
  warns on mixed gradient colour spaces and PDF/X-4 checks).
- Package for hand-off: `File ▸ Package` (`app.packageDialog`, `Cmd+Alt+Shift+P`; engine
  `file.package`) relinks to a `Links` folder with **package-relative link paths** (a package holds
  no path from the machine that made it), copies placed files and document fonts, writes an IDML
  copy, an optional PDF and a report (`crates/engine/src/cmd/package.rs`; ROADMAP progress log
  2026-10-17).

### Verified recipes
```sh
# Headless: build a page and export it three ways (--scale applies to the exports after it)
designcraft-cli run --sample \
  --cmd 'frame.create={"rect":[36,36,540,300],"content":"text","text":"Hello"}' \
  --export page.png --scale 2 --export page@2x.png --export page.pdf

# Discover then call a command (never guess params)
designcraft-cli commands footnote && designcraft-cli describe xref.insert

# A script with references to earlier results, saved and exported
printf '%s\n' \
  'frame.create {"rect": [72, 72, 540, 300], "content": "text", "text": "Results"}' \
  'text.select {"story": "$0.story", "anchor": 0, "focus": 0}' \
  'footnote.insert {"text": "Survey run in 2026."}' > page.dcs
designcraft-cli script page.dcs --save page.designcraft --export page.pdf --export page.png

# Drive a running app (start it with a control port first)
designcraft --sample --control 7979 &
designcraft-cli app document.inspect
designcraft-cli script page.dcs --connect 7979
```
MCP registration (`docs/mcp.md`):
```sh
claude mcp add designcraft -- designcraft-cli mcp \
  --automation-read-root /work/project --automation-write-root /work/project/out
```
The two root flags confine every path a *command* reads or writes (open, place, data sources,
libraries, saves, exports, packaging); a root left out grants none of that access, and `--connect`
together with the roots is an error (`docs/mcp.md` §Confining file access,
`crates/engine/src/file_access.rs`).

## Working with an AI agent

**Legitimate and productive**
1. **Prepare inputs.** Rasterise/convert to formats `crates/images` reads (PNG, JPEG, GIF, WebP,
   TIFF, BMP, PSD composite), author SVG or single-page PDF for vector/print art, write
   `.docx`/`.rtf`/`.txt`/`.md` for copy, and CSV/TSV/XLSX for Data Merge. Generate a magazine-style
   test document with `file.newSample` or `designcraft-cli run --sample`.
2. **Drive it through commands, not pixels.** Prefer `designcraft-cli run --cmd`, `script` with
   `$N.path` wiring, MCP `batch`, or the control channel. Every gesture path also exists
   (`ui.pointer`, `key`, `type_text`, `ime`, `dialog_*`), but commands are deterministic, faster,
   and give you JSON back.
3. **Look at the result.** `render_page`/`export_png`/`ui.render` return or write PNGs — read the
   image after layout work instead of trusting command exit codes; `ui.screenshot` gives the whole
   window.
4. **Inspect programmatically.** `document.inspect`, `story.get` (including `overset`),
   `links.list`, `font.list`, `preflight.run {minPpi?}`, `view.separations`,
   `document.preferences` tell you the real state; `designcraft-cli describe` tells you a command's
   exact parameter names before you call it.
5. **Repair and analyse native files.** A `.designcraft` is a zip: `unzip -o f.designcraft -d f/`
   then read `document.json`, `meta.json` and `assets/` — useful for auditing references,
   extracting placed files, or spotting a missing asset. **Re-zipping by hand is risky**: the
   reader requires `document.json`, honours `meta.json`'s `version` (above 3 is refused with
   "please update"), and runs `Document::check()` plus asset wiring on load, so a hand-edited model
   that violates invariants may be refused rather than repaired — prefer opening and re-saving
   through a command.
6. **Verify exports.** `designcraft-cli validate-pdf out.pdf` (PDF/X-4 checks), `preflight.run`
   before export, `story.get` for overset text, `links.list` for missing images, and the `warnings`
   array of every export result.
7. **Work on throwaway copies.** Copy the project file before an agent session; isolate a test run
   with `DESIGNCRAFT_CONFIG_DIR=$TMP/dc-profile` (preferences and the recovery folder follow it).

**Do not attempt**
- Do not read capabilities out of InDesign documentation or assume parity: check `docs/gaps.md`
  and `designcraft-cli describe`. ExtendScript, UXP, `.joboptions` presets, plug-ins and Adobe
  cloud features do not exist (`docs/gaps.md` §§22, 23, "Out of scope").
- Do not assume the CLI or MCP server is installed: on macOS the `.app` holds only the desktop app
  (`docs/mcp.md`; verified on this machine). Build or download it first, and say so to the user.
- Do not interpret EPS/PostScript or expect `.indd`/`.indt` fidelity, INDB/INDL, or QuarkXPress
  import; do not hand-craft IDML expecting a lossless round-trip (`docs/gaps.md` §§2, 3, 19).
- Do not drive the GUI blind (blind coordinate clicks, no screenshot/inspect feedback), and never
  run `--control` on a port you do not control: the channel has no authentication
  (`docs/control-protocol.md`).
- Do not edit the repository to change app behaviour; use documents, preferences and commands.

## Verification protocol

DesignCraft is pre-alpha: treat every export as unverified until you have looked at it. The
discipline:

1. **Throwaway round-trip first.** With every version, before real work: new document (`file.new`
   or `--sample`) → one edit → `--save` a `.designcraft` → reopen it (`--in`) → export the same page
   to PNG *and* PDF → check the PNG visually and the PDF with `validate-pdf` if you asked for
   `standard: "x4"`. If any step fails or the geometry moved, stop and report.
2. **Never trust a silent export.** Read the JSON result (`bytes`, `pages`, `slides`, `warnings`)
   *and* confirm the file exists and is non-empty. A page export with no `--export` after it is a
   usage error, not a no-op — except that a failed *step* in a non-`--keep-going` script still
   leaves earlier steps applied in the live app: re-inspect the document before retrying.
3. **Version and back up per session.** The format version is part of the file (`meta.json`); an
   older app refuses a newer document (`FormatError::TooNew`). Keep a copy of the project file at
   the start of a session; to deliver files to someone on an older build, test one round-trip on
   their version first.
4. **Update between projects, not during one.** After a launcher update, re-verify the bundle
   version and build commit before trusting earlier measurements:
   `plutil -p /Applications/DesignCraft.app/Contents/Info.plist | grep -E 'Version|BuildCommit'`
   (at this pin: `0.11.0`, commit `4d62a501c18fb3cf453c6e9f19f15cbc9c558e26`).
5. **Isolate test runs.** `DESIGNCRAFT_CONFIG_DIR` to a scratch folder, `DESIGNCRAFT_NO_PREFS` to
   avoid writing preferences, and `--automation-read-root`/`--automation-write-root` when an agent
   drives MCP.
6. **Prefer re-opening over re-editing.** Because the reader upgrades and validates on load, a
   save → reopen cycle is the cheapest proof that an edit produced a valid document.

*Verify against your installed version.* The repository at this pin and the installed bundle
currently match exactly (same commit); if the launcher has since updated DesignCraft, re-run step 4
and re-check command parameters with `designcraft-cli describe` before relying on them.

## Sources & evidence

- Repository: https://github.com/storytold/designcraft — inspected at tag **v0.11.0**, commit
  **`4d62a501c18fb3cf453c6e9f19f15cbc9c558e26`** (`git rev-parse HEAD`), 2026-10-22.
- Installed app: `DesignCraft.app` in the system Applications folder, `CFBundleShortVersionString
  0.11.0`, `DesignCraftBuildCommit 4d62a501c18fb3cf453c6e9f19f15cbc9c558e26`,
  `LSMinimumSystemVersion 11.0` (`Contents/Info.plist`; the bundle was inspected, never launched;
  `Contents/MacOS/DesignCraft --version` prints `designcraft 0.11.0`).
- Read for this skill: `README.md`, `Cargo.toml`, `ROADMAP.md`, `docs/{agents,mcp,
  control-protocol,gaps,target-app-parity}.md`, `docs/user/getting-started/install.md`,
  `apps/designcraft/src/{main,profile,gpu,control_server}.rs`,
  `apps/designcraft-cli/src/{main,automation_args}.rs`, `crates/format/src/lib.rs`,
  `crates/engine/src/{lib,script,guard,recovery,io,file_access}.rs`, `crates/engine/src/cmd/*`
  (module `specs()` lists incl. file, export, interchange, fonts, layout, qr, mathexpr,
  color_theme, colorsettings, book, library, style, scripts, states, transitions, buttons),
  `crates/mcp/src/tools.rs`, `crates/ui-egui/src/{control,menus}.rs`, `crates/doc/src/item.rs`,
  `crates/textimport/src/lib.rs`, `crates/pdf/src/{lib,pdfx}.rs`, `crates/images/src/eps.rs`.
- Deep automation tables (CLI, script syntax, MCP tools, control methods, coordinates, offsets,
  sample commands): `references/agent-surfaces.md`. Live discovery beats this document for details:
  `designcraft-cli commands`, `designcraft-cli describe ID`, and `docs/gaps.md` (the maintainers'
  ranked work list).

---
name: designcraft
description: DesignCraft is the ArtCraft team's clean-room, open-source InDesign-class page-layout app (pure Rust; `.designcraft` project format; IDML/INDD import; PDF/X-4, PDF/A-2b, EPUB, editable PPTX, HTML and PNG export; headless CLI, MCP server and JSON control channel). Trigger this skill whenever the user mentions DesignCraft — or a `.designcraft`, `.idml`, `.indd`, `.indt`, `.dcbook`, `.dclib`, `.ase` or command-script file — asks what it can or cannot do, which formats it opens or writes, its keyboard shortcuts, how to automate or script it, how to prepare or convert assets for it, how to verify or repair its output, or how to troubleshoot it. Also trigger when the job is described without naming the app — "lay out a magazine", "thread this story across three columns", "set this on a baseline grid", "export a PDF/X-4", "make an EPUB from these pages", "batch-export every page to PNG", "place these photos in a brochure", "move these column guides", "import my InDesign shortcuts". Do not guess its capabilities from InDesign knowledge — read this first.
---

# DesignCraft

Audit basis: this checkout is tag `v0.12.0`, commit `5e8ef678321cfdd2d18927e2af94d58e5f9d8836`. The installed `/Applications/DesignCraft.app` reports version `0.12.0` and its binary prints `designcraft 0.12.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Deep automation detail — CLI flags, script syntax, all 26 MCP tools, control methods, coordinates, guide and column geometry, shortcut import — is in `references/agent-surfaces.md` next to this file.

## Overview

DesignCraft is a page-layout and publishing application written from scratch in Rust: "an open-source, modern desktop publishing and page layout studio" (`README.md`). It targets full Adobe InDesign 2026 parity — "faster, open (documented JSON format + IDML), scriptable by agents (MCP), and available on the web" (`ROADMAP.md`) — as a clean-room application (`AGENTS.md`). It runs natively on macOS, Windows and Linux, and in a browser as WebAssembly (`README.md` §Web, `apps/designcraft-web`). Maturity is **pre-alpha**: the alpha gate is still blocked by Smart Text Reflow on the Primary Text Frame (`ROADMAP.md:3`, `docs/gaps.md` §0); the maintainers estimate ~80% feature breadth and ~47% "ready for real work" (`docs/target-app-parity.md`). Source: GitHub `storytold/designcraft`, MIT OR Apache-2.0 (`Cargo.toml:9`), a layered Cargo workspace enforced by `cargo xtask layers`; shared craft-libs crates provide printing, ICC colour management, atomic writes and document-path policy (`Cargo.toml:76-87`).

The one idea that governs everything: **every user-visible action is a command** with a stable id and JSON parameters (`crates/engine/src/lib.rs`), and the UI, CLI, control channel and MCP all go through `Session::execute`. Prefer commands over GUI poking.

## Capabilities (verified)

### Layout, guides and the document model — implemented
- Facing/non-facing spreads, parent (master) pages with page-number markers, sections, layers, and frames typed text / graphic / unassigned; stories threaded across frames and spreads (`crates/doc/src/{page,story}.rs`; `crates/engine/src/cmd/{layout,thread}.rs`).
- Document setup, page-size presets (incl. A0–A2 posters), bleed/slug, start page, Page tool for pages of their own size (`layout.documentSetup`, `layout.pageSize`, `file.new`).
- Multi-document tabs: `file.activate {index}`, `document.list`, next/previous document (`Cmd+F6` / `Cmd+Shift+F6`) — `crates/engine/src/cmd/file.rs`, `crates/ui-egui/src/menus.rs`.
- **Ruler guides (v0.12 surface):** `guide.add` (horizontal/vertical/both; page, spread or liquid guide), `guide.list`, `guide.select`, `guide.selectAll` (`Cmd+Alt+G`), `guide.deselect`, `guide.move`, `guide.moveBy` (moves every selected guide along its own axis in one undo step), `guide.delete` (`{}` = the selection), `guide.deleteAll`, `layout.createGuides` (`crates/engine/src/cmd/guides.rs`). Guides are selected like objects (click, Shift-click, marquee, arrow keys, Delete, X/Y fields), and a dragged guide snaps along its axis to guides, margins, columns, bleed, page/object edges and centres and the document grid; Shift snaps to ruler ticks, Cmd suspends snapping (`crates/ui-egui/src/canvas.rs` `guide_spot`, `crates/tools/src/snap.rs` `Gesture::Guide`, `crates/ui-egui/src/guide_selection_tests.rs`).
- **Custom column guides (v0.12):** a page can keep dragged column positions rather than an even split (`Columns.positions`, `crates/doc/src/page.rs`), move one gutter with `layout.moveColumnGuide {page, gutter, position, spread?|parent?}`, read them from `document.inspect` (`gutter`, `customColumns`, `columnRects`), and round-trip them through IDML (`ColumnsPositions`). Both gutter edges move together and stop at neighbouring guides/margins; at most 216 columns; changing the count or gutter re-divides evenly (`crates/engine/src/cmd/layout.rs`, `crates/idml/src/{import,export}.rs`).
- Guide locks: `view.lockGuides` (`Cmd+Alt+;`, a UI/view state persisted in `ui.json`) blocks pointer dragging; `view.lockColumnGuides` is a document setting (`column_guides_locked`, **on by default**, saved in the document and IDML `ColumnGuideLocked`) and blocks both dragging and `layout.moveColumnGuide` (`crates/engine/src/cmd/guides.rs`, `crates/doc/src/lib.rs`).
- Styles (paragraph, character, object, table, cell, groups), swatches (process/spot/tints/gradients), text wrap, corner options, transparency effects, ICC colour management with working spaces and proof setups (`crates/engine/src/cmd/{style,object,colorsettings}.rs`; `crates/doc/src/styles.rs`).
- Interactions: Pathfinder boolean ops, compound/clipping paths, gradients, stroke styles/arrowheads, tables with merges and graphic cells, footnotes, endnotes, notes, cross-references, index, TOC, text variables, conditional text, track changes, data merge, XML tags/DTD, articles, object libraries, books, object states, buttons and form fields, page transitions — `crates/engine/src/cmd/*` (see `command_specs()` at `crates/engine/src/cmd/mod.rs:167`).
- Generators: QR codes (`object.qrCode`), math expressions (`math.insert`/`math.svg`, a LaTeX subset typeset to SVG), colour themes from a placed image (`color.extractTheme`) — `crates/engine/src/cmd/{qr,mathexpr,color_theme}.rs`.
- Graphics: placed rasters, PDF pages, SVG, PSD composites, EPS previews (`crates/images`, `crates/render`).

### Text engine — implemented
- Knuth–Plass total-fit paragraph composer plus a single-line composer, with a shared compose cache (`crates/compose/src/lib.rs`, `crates/compose/src/breaker.rs`).
- Dictionary hyphenation (public-domain Moby list plus trained Liang patterns) and language-dependent typographic quotes; bidi/RTL with kashida and digit substitution; CJK composition with mojikumi/kinsoku; vertical type, ruby, kenten, warichu, tate-chu-yoko (`crates/compose/{hyphen,bidi,mojikumi,ruby,kenten,warichu}.rs`, `ROADMAP.md`).
- Column rules on text frames (weight, colour, tint, offset, insets), Paragraph Rules above/below, and Span Columns from the Paragraph panel/Paragraph Style Options (`crates/doc/src/item.rs` `column_rule*`; `crates/ui-egui/src/dialogs.rs` span-columns dialog; `crates/idml/src/*`).
- Fonts: own font DB, shaping (harfrust), outlines (skrifa), variable-font instances, `Document Fonts` folders beside a document (name matched without regard to case), and Type › Reload Fonts (`font.reload`) (`crates/fonts/src/fontdb.rs`, `crates/engine/src/cmd/fonts.rs`, `crates/engine/src/cmd/file.rs` `load_document_fonts`).

### Import / open — implemented
`file.open` decides by content, not extension (`crates/engine/src/cmd/file.rs` `open_path`):
- Native `.designcraft` (zip or legacy single JSON) — `crates/format`.
- `.idml` InDesign Markup, imported into the native model — `crates/idml/src/import.rs`; `.indd`/`.indt` converted to IDML in memory by `storytold/indd-utils` (`crates/engine/src/cmd/interchange.rs`; real-file fidelity unmeasured — `docs/gaps.md` §2).
- Placed graphics: PNG, JPEG, GIF, WebP, TIFF, BMP, PSD/PSB composite, SVG, PDF (any page, crop-box choice), PDF-compatible Illustrator files detected as PDF, EPS (TIFF preview or placeholder — no PostScript interpreter) (`crates/images/src/lib.rs`, `crates/engine/src/cmd/file.rs` `file.place`).
- Text: `.txt`/`.text`, `.docx`, `.rtf`, `.md` (plain text), `.xlsx` (first used range becomes a table), Tagged Text (`crates/textimport/src/lib.rs`, `crates/textimport/src/{docx,rtf,xlsx,tagged}.rs`, `crates/engine/src/cmd/place_text.rs`); Data Merge sources CSV, TSV, text, `.xlsx` (`crates/engine/src/cmd/datamerge/`).
- Media (poster/placeholder frames, no playback): mp4, m4v, mov, webm, ogv, mp3, m4a, wav, ogg, oga, aac (`crates/doc/src/item.rs` `media_mime`; `crates/engine/src/cmd/media.rs`).
- Swatches `.ase`, ICC `.icc`/`.icm`, XML (with DTD), libraries `.dclib`, books `.dcbook`, and a page of an IDML or `.designcraft` document (`file.place {layoutPage}`) as a group of objects (`crates/engine/src/cmd/{style,colorsettings,xml,library,book}.rs`).

### Native format — implemented
`.designcraft` is a zip (`crates/format/src/lib.rs`): `mimetype` (stored, first, `application/vnd.designcraft+zip`), `document.json` (pretty JSON of the serde model in `crates/doc`), `assets/<id>.<ext>` (each referenced placed file once, byte-for-byte), `meta.json` (format version and generator) and an optional `preview.png`. Latest reader capability is version 3 (`VERSION`); the writer pins a file to version 3 only when it holds EPS assets, else stays at version 2 so older readers keep working (`lib.rs:90`). Readers upgrade older versions and still open the legacy single-JSON form with base64 `assetData`. Read limits: 100 000 entries, 256 MiB `document.json`, 1 GiB per asset, 4 GiB total; a document with non-finite geometry cannot be saved. `file.saveAs` appends `.designcraft` unless the path already ends with that extension (so `x.idml` becomes `x.idml.designcraft`), and writes are atomic (`crates/engine/src/io.rs`).

### Export — implemented
- **PDF** (`file.exportPdf`): real selectable text with embedded font subsets, DeviceCMYK/RGB/Gray, spot `/Separation`, bleed boxes, crop/bleed marks and page info, pages or spreads, `standard: "none" | "x4" | "a2b"` (PDF/X-4 output intent with built-in conformance checks; PDF/A-2b), tagged PDF structure tree, transparency flattening (`flatten: high|medium|low|ppi`), hyperlink annotations and outlines, interactive options, `file.printBooklet` imposition; `designcraft-cli validate-pdf file.pdf` runs the PDF/X-4 checks for CI (`crates/pdf/src/pdfx.rs:210`).
- **EPUB 3** reflowable (`file.exportEpub`) and fixed layout (`file.exportFixedEpub`; pre-paginated page images plus their text) — `crates/epub/src/lib.rs`.
- **HTML** (`file.exportHtml`): one self-contained page, styles as CSS, images embedded.
- **PowerPoint** (`file.exportPptx`): every page becomes a slide of editable shapes, pictures, tables and text boxes; `lineBreaks: keep|reflow`, `rasterize`, `embedFonts` (`crates/pptx/src/lib.rs`).
- **PNG / JPEG** of a page via the renderer (`designcraft-cli run --export out.png`, `--all-pages DIR`; MCP `render_page` / `export_png`; control `ui.render`) — `crates/render/src/lib.rs`.
- **IDML** (`file.exportIdml`, `embedImages`), **Text** `.txt`/`.rtf`/tagged (`file.exportText`), **XML** (`file.exportXml`).
- **Print** (`file.print`, `file.printers`, `dryRun`) through the shared `craft-print` spooler (CUPS on macOS/Linux; Windows spooler in-process) — `Cargo.toml`, `docs/gaps.md` §10.

### Automation surfaces — implemented
- **CLI** `designcraft-cli` (`apps/designcraft-cli/src/main.rs`, `USAGE`): `run`, `commands [FILTER]`, `describe COMMAND`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`, `--version`. On macOS it is **not inside `DesignCraft.app`**: the release ships a separate `designcraft-cli-<version>-macos-<arch>.zip`, and it is not on `PATH` unless installed (`docs/mcp.md` §From an installed release; `packaging/macos/package.sh`).
- **MCP server** `designcraft-cli mcp` — stdio JSON-RPC, protocol 2025-06-18 (older revisions accepted), **26 tools**, unchanged at this tag: command discovery/execution (`list_commands`, `execute`, `batch`), document I/O and inspection (`inspect_document`, `get_story`, `set_story_text`, `new_document`, `open_document`, `save_document`, `place_image`), rendering (`render_page`, `export_png`, `screenshot`), input/UI tools (`select_tool`, `pointer`, `key`, `type_text`, `ime`, `click`, `drag`, `menu_list`, `ui_inspect`, `ui_set`, `dialog_set/confirm/cancel`) (`crates/mcp/src/tools.rs:83`; `docs/mcp.md`). Read/write root flags confine every path a command touches (`crates/engine/src/file_access.rs`).
- **Control channel**: `designcraft --control PORT` serves JSON lines on `127.0.0.1` only (`apps/designcraft/src/control_server.rs`; methods in `crates/ui-egui/src/control.rs:149`; 4 MiB line limit, 16 connections, no authentication — `docs/control-protocol.md`).
- **Scripts**: one command per line with `$N.path` references to earlier results (`crates/engine/src/script.rs`; `script.run {text}`; `docs/agents.md`). The Scripts panel runs a script as one undo step and restores the document on failure (`crates/engine/src/cmd/scripts.rs`).
- **Shortcut import (v0.12):** `window.importShortcuts {path | text}` reads a set saved by InDesign's Keyboard Shortcuts ▸ Show Set (`.txt`; UTF-8/BOM or UTF-16; Windows or Mac key names; ≤ 8 MiB). Matched commands take its Default shortcuts (Text for type/text commands without a Default entry); other commands give up keys it takes; tools keep their keys. Returns `{set, imported, changed, conflictsCleared, skipped, unmatched, unmatchedWithoutShortcut, unreadable}` (`crates/ui-egui/src/shortcut_import.rs`, `crates/ui-egui/src/menus.rs`).
- Surface size at this tag: **527 engine command specs** (unique `cmd!` registrations outside `#[cfg(test)]` across 61 `specs()` lists) plus **166 UI commands** (`UI_COMMANDS`). Versus v0.11.0 (521 + 164): **+6 engine** (`guide.select`, `guide.selectAll`, `guide.deselect`, `guide.moveBy`, `layout.moveColumnGuide`, `view.lockColumnGuides`) and **+2 UI** (`view.lockGuides`, `window.importShortcuts`); nothing removed. MCP stays 26 and the CLI subcommands are unchanged. CLI discovery lists engine commands only; a running app's `engine.commands` / MCP `list_commands` also lists UI commands marked `"ui": true`. Counts are approximate by construction — discover the live list with `designcraft-cli commands` and `describe`.

### Platforms — implemented
- macOS, Windows, Linux native (`apps/designcraft`); WebAssembly web build via trunk (`apps/designcraft-web`: WebGPU with a WebGL2 fallback, `?webgl` to force it, `?sample` for the sample magazine). The web build has no control channel, and Save/Export download files instead of writing them (`README.md` §Web). Runtime environment variables: `RUST_LOG`, `WGPU_BACKEND`, `WGPU_POWER_PREF`, `WGPU_ADAPTER_NAME`, `WGPU_VALIDATION_INDIRECT_CALL`, `DESIGNCRAFT_CONTROL_PORT`, `DESIGNCRAFT_CONFIG_DIR`, `DESIGNCRAFT_NO_PREFS`, `DESIGNCRAFT_NO_NATIVE_MENU`, `DESIGNCRAFT_WAYLAND` (Linux) — `README.md` §§Logs, Portable mode; `apps/designcraft/src/{main,profile}.rs`.

## Known limitations and not-implemented

Ranked shortfall list: `docs/gaps.md` (kept current by the maintainers — read it before promising work). Headline items at this tag:

- **Pre-alpha.** The alpha gate is blocked by Smart Text Reflow on the Primary Text Frame adding pages users cannot delete (#165) — `docs/gaps.md` §0, `ROADMAP.md:3`. Threading by hand works.
- **Basic canvas editing still fails for some users** — object copy/paste on Windows and Linux, right-click context menus, formatting at a caret discarded (`docs/gaps.md` §1). v0.12 changes the clipboard path (copied objects put a placeholder on the system clipboard and paste with Ctrl+V on Linux/Windows; `crates/engine/src/cmd/edit.rs`), but the gaps list still names these as open.
- **INDD/INDT opening is unmeasured on real files**; **INDB/INDL are not read**; no QuarkXPress import (`docs/gaps.md` §§2, 19).
- **IDML round-trip is not proven on real files** — broad importer coverage, but no InDesign-authored corpus metric; opened IDML can reflow (`docs/gaps.md` §§3, 4).
- **EPS is preview-only** — no PostScript interpreter; placed EPS is drawn/printed from its TIFF preview or replaced by a placeholder (`docs/gaps.md` §19, `crates/images/src/eps.rs`).
- **No ExtendScript/UXP compatibility**: InDesign scripts do not run; the script language is DesignCraft's own command language (`docs/gaps.md` §22). **No plug-in model** (`docs/gaps.md` §23). **No in-app media playback** (`docs/gaps.md` §19 area, `ROADMAP.md`).
- **PDF output presets and standards**: no PDF/X-1a, PDF/X-3, PDF/UA validation, Adobe `.joboptions` presets, or output-intent choice beyond the built-in profile; PostScript printing is absent (`docs/gaps.md` §§9, 10; `crates/pdf/src/lib.rs` `Standard`).
- **HTML export is one basic page; fixed-layout EPUB writes page images** rather than live text/CSS; no EPUB animation or timing (`docs/gaps.md` §17).
- **Hyphenation** for English, Spanish, Portuguese, Norwegian and Greek only; **spelling** English only (`docs/gaps.md` §13). **No screen-reader exposure**; PDF/UA unverified (`docs/gaps.md` §25).
- **Startup crashes and blank canvases on some GPU/driver combinations** remain a partly mitigated class (backend fallback + `gpu.json` skip list; `docs/gaps.md` §5). **Performance**: no incremental composition and no GPU raster — the canvas is CPU-rendered with `vello_cpu`, the GPU only composites the UI (`docs/gaps.md` §20, `README.md` §Why DesignCraft).
- **Font discovery** still misses fonts activated by some font services/managers; disk changes are noticed only on request (`font.reload`) (`docs/gaps.md` §6). **Localization** is partial: Japanese 95%, Czech/Polish 99%, Georgian 100%, several 61–85%, Hindi/Indonesian/Korean/Vietnamese absent (`ROADMAP.md` §Languages, `docs/gaps.md` §21).
- **Shortcut import limits**: reads only InDesign Show Set `.txt` (not `.indk`), applies only the Default context (Text for type/text commands), rejects macOS Control-key chords, never changes tool keys, and cannot write/export a set (`crates/ui-egui/src/shortcut_import.rs`, `docs/file-format-parity.md` keyboard row).
- **Custom column guides** are horizontal column gutters only; locked by default and `layout.moveColumnGuide` refuses while locked; changing column count or gutter discards the custom positions; a page that changes side of the spine mirrors them (`crates/engine/src/cmd/layout.rs`, `crates/doc/src/page.rs`).
- **`file.close` is not a safe "close tab"**: it closes without asking and discards the document's recovery data (`crates/engine/src/lib.rs` `close_document`; `crates/ui-egui/src/menus.rs` `close_document` comment). The UI's File ▸ Close / tab × asks when the document is dirty.
- **Claimed but unverified**: README says "every menu item, tool gesture, panel control and dialog" can be driven over the JSON control channel and MCP. The command registry and control methods are broad, but this audit did not launch the GUI to exercise every dialog and gesture; treat a specific dialog as unverified until `ui.dialog.open` / `ui_inspect` confirms it.
- **Stale documentation to distrust**: `crates/pdf/src/lib.rs` still says "Not yet: tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content", but those are wired in (`crates/pdf/src/{export,links,forms,transitions}.rs`); `ROADMAP.md:180`'s "~200 commands" is old; `docs/target-app-parity.md:45` cites 446 engine + 99 UI commands (an older measurement); `docs/user/getting-started/install.md` is stamped `verified: 0.7.1`; `docs/agents.md` says most commands ignore unknown parameters, while the CLI, MCP and control channel reject them (`crates/engine/src/cmd/params.rs`, `crates/ui-egui/src/control.rs:164`). Verify with `designcraft-cli describe` against your build.

## How to operate

### Launch on macOS
- GUI: `open -a DesignCraft` (installed under `/Applications/DesignCraft.app`, `CFBundleIdentifier ai.storyteller.designcraft`, version 0.12.0 at this pin); to open a file: `open -a DesignCraft brochure.designcraft`. The binary inside the bundle is `/Applications/DesignCraft.app/Contents/MacOS/DesignCraft`.
- Real flags of the desktop binary (`apps/designcraft/src/main.rs`): `--sample`, `--control <port>` (also `DESIGNCRAFT_CONTROL_PORT`), `--version`, `--gpu-skip=<list>` (internal restart bookkeeping), plus any number of file paths.
- **The CLI is not inside the `.app`.** Get it from the separate `designcraft-cli-<version>-macos-*.zip` release asset, `cargo install --path apps/designcraft-cli --locked`, or `cargo build --release -p designcraft-cli`; do not assume a system-wide `designcraft-cli` exists.
- State lives in the app's settings folder (`~/Library/Application Support/DesignCraft/` on macOS): `ui.json`, `prefs.json`, `logs/designcraft.log` (rotates to `.1.log`/`.2.log`, 16 MiB cap), `gpu.json`, and `Recovery/` (`apps/designcraft/src/profile.rs`, `crates/engine/src/recovery.rs`). `portable.txt` next to the app switches to a `DesignCraftData` folder; `DESIGNCRAFT_CONFIG_DIR` overrides both.

### CLI reference (exact, from `apps/designcraft-cli/src/main.rs`)
```
designcraft-cli run [--in FILE(.designcraft|.idml|.indd|.indt) | --sample] [--cmd ID[=JSON]]...
                   [--page N] [--scale S] [--pdf-options JSON] [--export OUT] [--all-pages DIR]
designcraft-cli commands [FILTER]          # engine commands as JSON; FILTER matches id/label/menu
designcraft-cli describe COMMAND           # label, menu path, shortcut and parameters of one command
designcraft-cli script [FILE|-] [--in FILE | --sample] [--connect PORT] [--save OUT]
                       [--export OUT] [--keep-going] [--help]
designcraft-cli app [--port PORT] COMMAND [JSON] | app --method METHOD [JSON]
designcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR] [--automation-write-root DIR]
designcraft-cli perf [--pages N] [--runs N] [--strict] | bench FILE [--runs N]
designcraft-cli validate-pdf FILE.pdf | links | --version
```
- `--page`, `--scale` and `--pdf-options` apply to the `--export`s that **follow** them; one left after the last export is an error.
- `--export` picks the writer from the extension: `.png`/`.jpg`/`.jpeg` (a page), `.pdf`, `.designcraft` (Save As), `.idml`, `.epub`, `.pptx`, `.html`/`.htm`, `.rtf`/`.txt`; an unknown extension is an error and *nothing runs*; a name with no extension is a PNG of the page.
- `run --cmd ID=JSON` uses `$N.path`/`$last.path` references; a params key the command's description doesn't name is an error (checked by the CLI, MCP and control channel).
- `script` prints `{"completed": n, "results": [...]}` plus `failedIndex`/`failedCommand`/`error` and exits non-zero on failure; `--keep-going` records failures as results instead.

### Document and window model
- Several documents open in tabs; each tab is its own `DocState` with its own undo history, selection and (optionally) its own `Document Fonts` scope (`crates/engine/src/lib.rs`, `crates/ui-egui/src/chrome.rs`). A document is spreads → pages → items; text lives in **stories** threaded through text frames; parent pages contribute items behind a page's own (`crates/doc/src/{page,story,item}.rs`).
- **Coordinates are points (1/72 in), y down, in spread space**: on a facing spread the right page starts at `x = page width` (`docs/mcp.md` §Coordinates); `inspect_document` lists per-spread page bounds. **Text offsets are UTF-8 byte offsets**, not character counts (`anchor`, `focus`, `story.replaceRange`, story `length`) — `docs/mcp.md` §Text offsets.
- Commands that create items take `spread`: an integer, or `{"kind":"parent","index":N}` (`crates/engine/src/cmd/mod.rs` `spread_param`). `page` in guide/column commands is the page's **index within its spread**; `document.inspect` page `index` is absolute.
- **Closing:** `file.close {index?}` closes without prompting and discards recovery data; the UI's File ▸ Close / tab × asks when dirty (`crates/ui-egui/src/menus.rs` `close_document`). The control method `app.quit` also quits without asking; the `app.quit` command (like ⌘Q) asks.

### Guides and column guides — recipes
```sh
# Add a horizontal + vertical guide through a point, move the pair, list them
designcraft-cli run --sample \
  --cmd 'guide.add={"orientation":"both","point":[72,72]}' \
  --cmd 'guide.moveBy={"dx":12,"dy":0}' \
  --cmd 'guide.list={}'

# Select every unlocked guide on spread 0 and nudge them one point right
designcraft-cli run --in brochure.designcraft \
  --cmd 'guide.selectAll={"spread":0}' \
  --cmd 'guide.moveBy={"dx":1}'
```
- `guide.list` returns `{page, index, orientation, position, spread, selected}`; positions are spread coordinates. `guide.add` makes at most two guides; `layout.createGuides` is capped at 10,000 per command with rows/columns ≤ 1000. A guide added to a parent spread shows on the pages using it.
- `view.lockGuides` only stops pointer dragging; `guide.move`/`guide.moveBy` still run unless the guide or its **layer** is locked. To protect guides from commands, put them on a layer and lock the layer. `guide.selectAll` skips locked/hidden layers.
- Column gutters are **locked by default**. Unlock, move, then re-lock:
```sh
designcraft-cli run --in brochure.designcraft \
  --cmd 'view.lockColumnGuides={"on":false}' \
  --cmd 'layout.moveColumnGuide={"page":0,"gutter":0,"position":180}' \
  --cmd 'view.lockColumnGuides={"on":true}' \
  --export out.designcraft
```
`gutter` 0 is between the first two columns; `position` is the gutter's new left edge in spread x. The result `{positions, left}` gives column edges relative to the margin box. Read current geometry from `document.inspect` (`columns`, `gutter`, `customColumns`, `columnRects`).

### Shortcut import — recipe
```sh
# Requires the desktop app running with a control port (UI command; not available headless)
designcraft app window.importShortcuts '{"path":"indesign-shortcuts.txt"}'
```
Read the report before trusting it: `changed`, `conflictsCleared`, `skipped` (with `takenBy`), `unmatched` (tools say `reason: "tool keys are fixed"`) and `unreadable`. The importer matches InDesign menu names to DesignCraft labels/menu paths; it does not translate ExtendScript, does not apply non-Default contexts (except Text for type/text commands), and refuses macOS Control-key chords. Reset with `window.resetShortcuts {}`.

### Open / save / export flows
- Open: `File ▸ Open…` (`Cmd+O`, `file.open {path}`) — content-sniffed; `.idml` and `.indd`/`.indt` route through the IDML interchange module. `file.recentFiles` / `file.openRecent` back Open Recent.
- Save: `File ▸ Save` (`Cmd+S`, `file.save`) and `Save As…` (`Cmd+Shift+S`, `file.saveAs {path}`) write the native `.designcraft` package; `file.saveACopy` writes a copy without changing the open document; writes are atomic.
- Recovery: unsaved documents are written to the recovery folder every 30 s by default (`recoveryMinutes`, minimum 5 s) and reopened after a crash (`crates/engine/src/recovery.rs`; `file.recovery.{save,list,open}`, `file.revert`).
- Export: the `file.export*` commands above, or the CLI's `--export`. Every export returns `{path, bytes, …}` plus a `warnings` array where applicable — **read it** (e.g. `file.exportPdf` warns on mixed gradient colour spaces and PDF/X-4 checks).
- Package: `File ▸ Package` (`app.packageDialog`, `Cmd+Alt+Shift+P`; `file.package {dir, idml?, pdf?, instructions?}`) relinks to a `Links` folder with **package-relative link paths**, copies placed files and document fonts, writes an IDML copy (`idml` defaults true), an optional PDF (`pdf` defaults false) and a report (`crates/engine/src/cmd/package.rs`).

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
  --automation-read-root "$PWD" --automation-write-root "$PWD/out"
```
The two root flags confine every path a *command* reads or writes (open, place, data sources, libraries, saves, exports, packaging); a root left out grants none of that access, and `--connect` together with the roots is an error (`crates/engine/src/file_access.rs`).

## Working with an AI agent

**Legitimate and productive**
1. **Prepare inputs.** Convert to formats `crates/images` reads (PNG, JPEG, GIF, WebP, TIFF, BMP, PSD composite), author SVG or single-page PDF for vector/print art, write `.docx`/`.rtf`/`.txt`/`.md` for copy, and CSV/TSV/XLSX for Data Merge. Generate a test document with `file.newSample`.
2. **Drive it through commands, not pixels.** Prefer `designcraft-cli run --cmd`, `script` with `$N.path` wiring, MCP `batch`, or the control channel. Gesture paths exist (`ui.pointer`, `key`, `type_text`, `ime`, `dialog_*`), but commands are deterministic and return JSON.
3. **Look at the result.** `render_page`/`export_png`/`ui.render` return or write PNGs — read the image after layout work; `ui.screenshot` gives the whole window.
4. **Inspect programmatically.** `document.inspect` (pages incl. `columnRects`/`customColumns`, items, stories with `overset`, styles, swatches, selection incl. `guides`), `story.get`, `links.list`, `font.list`, `preflight.run {minPpi?}`, `document.preferences`; `view.separations` is UI-only (desktop app). `designcraft-cli describe` gives exact parameter names.
5. **Set up geometry programmatically.** `guide.add`/`guide.move`/`guide.moveBy`, read back with `guide.list`; move column gutters with `layout.moveColumnGuide` after `view.lockColumnGuides {on:false}`, then verify `columnRects` in `document.inspect`.
6. **Repair and analyse native files.** A `.designcraft` is a zip: unzip, read `document.json`, `meta.json` and `assets/`. **Re-zipping by hand is risky**: the reader requires `document.json`, honours `meta.json`'s version (above 3 is refused), and runs `Document::check()` plus asset wiring on load, so a hand-edited model may be refused. Prefer open → re-save through a command.
7. **Verify exports.** `designcraft-cli validate-pdf out.pdf`, `preflight.run`, `story.get` for overset text, `links.list` for missing images, and every export's `warnings`.
8. **Import a designer's InDesign shortcut set** with `window.importShortcuts`, report the `changed`/`unmatched`/`unreadable` lists, and test one imported shortcut.
9. **Work on throwaway copies.** Copy the project file before a session; isolate a run with `DESIGNCRAFT_CONFIG_DIR` pointed at a scratch folder.

**Do not attempt**
- Do not assume parity: check `docs/gaps.md` and `designcraft-cli describe`. ExtendScript, UXP, `.joboptions` presets, plug-ins and Adobe cloud features do not exist (`docs/gaps.md` §§22, 23).
- Do not assume the CLI or MCP server is installed: on macOS the `.app` holds only the desktop app (`docs/mcp.md`). Build or download it first, and say so.
- Do not run `file.close` or MCP/control `app.quit` on a dirty document — both discard unsaved work and recovery data.
- Do not expect the shortcut importer to read `.indk`, apply non-Default contexts, handle macOS Control-key chords, or write a set; check `changed` and test a shortcut after importing.
- Do not move column guides on a locked document; unlock first and re-lock. Do not assume `view.lockGuides` protects guides from commands — it only stops the pointer.
- Do not interpret EPS/PostScript or expect `.indd`/`.indt` fidelity, INDB/INDL, or QuarkXPress import; do not hand-craft IDML expecting a lossless round-trip (`docs/gaps.md` §§2, 3, 19).
- Do not drive the GUI blind (no screenshot/inspect feedback), and never run `--control` on a port you do not control: the channel has no authentication (`docs/control-protocol.md`).
- Do not edit the repository to change app behaviour; use documents, preferences and commands.

## Verification protocol

DesignCraft is pre-alpha: treat every export as unverified until you have looked at it.

1. **Throwaway round-trip first.** New document (`file.new` or `--sample`) → one edit → save a `.designcraft` → reopen it (`--in`) → export the same page to PNG *and* PDF → check the PNG visually and the PDF with `validate-pdf` if you asked for `standard: "x4"`. If a step fails or geometry moved, stop and report.
2. **Never trust a silent export.** Read the JSON result (`bytes`, `pages`, `slides`, `warnings`) *and* confirm the file exists and is non-empty. A failed *step* in a non-`--keep-going` script still leaves earlier steps applied in the live app: re-inspect before retrying.
3. **Version and back up per session.** The format version is in `meta.json`; an older app refuses a newer document (`FormatError::TooNew`). Keep a copy at the start of a session; to deliver files to someone on an older build, test one round-trip on their version first.
4. **Update between projects, not during one.** After a launcher update, re-verify the bundle version and build commit: `plutil -p /Applications/DesignCraft.app/Contents/Info.plist | grep -E 'Version|BuildCommit'` (at this pin: `0.12.0`, commit `5e8ef678…`).
5. **Isolate test runs.** `DESIGNCRAFT_CONFIG_DIR` to a scratch folder, `DESIGNCRAFT_NO_PREFS` to avoid writing preferences, and `--automation-read-root`/`--automation-write-root` for MCP.
6. **Prefer re-opening over re-editing.** The reader upgrades and validates on load, so save → reopen is the cheapest proof that an edit produced a valid document.
7. **Verify guide/column geometry, not just "no error".** After guide edits read `guide.list`; after `layout.moveColumnGuide` read `document.inspect`'s `columnRects`/`customColumns`. Reopen and confirm they survive (and IDML too, if handing off IDML).
8. **Verify a shortcut import by its report and one keystroke** — check `changed` and `conflictsCleared`, confirm the command's shortcut, then trigger it once.

*Verify against your installed version.* The repository at this pin and the installed bundle match exactly; if the launcher has since updated DesignCraft, re-run step 4 and re-check command parameters with `designcraft-cli describe` before relying on them.

## Sources & evidence

- Repository: https://github.com/storytold/designcraft — inspected at tag **v0.12.0**, commit **`5e8ef678321cfdd2d18927e2af94d58e5f9d8836`** (`git rev-parse HEAD`; `Release 0.12.0`, 2026-10-22), 2026-10-23.
- Installed app: `DesignCraft.app` in the system Applications folder, `CFBundleShortVersionString 0.12.0`, `DesignCraftBuildCommit 5e8ef678…`, `LSMinimumSystemVersion 11.0` (`Contents/Info.plist`; inspected, never launched; `Contents/MacOS/DesignCraft --version` prints `designcraft 0.12.0`).
- Read for this skill: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`, `docs/{agents,mcp,control-protocol,gaps,target-app-parity,file-format-parity}.md`, `docs/user/getting-started/install.md`, `apps/designcraft/src/{main,profile,gpu,logging,control_server,native_menu}.rs`, `apps/designcraft-cli/src/{main,automation_args}.rs`, `crates/format/src/lib.rs`, `crates/engine/src/{lib,script,recovery,io,file_access}.rs`, `crates/engine/src/cmd/*` (incl. `guides.rs`, `layout.rs`, `inspect.rs`, `edit.rs`, `params.rs`, `package.rs`, `export.rs`, `interchange.rs`), `crates/mcp/src/tools.rs`, `crates/ui-egui/src/{control,menus,canvas,shortcut_import}.rs`, `crates/ui-egui/src/guide_selection_tests.rs`, `crates/doc/src/{page,selection,vars,time}.rs`, `crates/textimport/src/lib.rs`, `crates/pdf/src/{lib,pdfx}.rs`, `crates/epub/src/lib.rs`, `crates/images/src/eps.rs`, `crates/compose/src/lib.rs`.
- Deep automation tables (CLI, scripts, MCP tools, control methods, coordinates, guides/columns, shortcut import, sample commands): `references/agent-surfaces.md`. Live discovery beats this document: `designcraft-cli commands`, `designcraft-cli describe ID`, and `docs/gaps.md`.

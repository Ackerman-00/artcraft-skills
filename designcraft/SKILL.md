---
name: designcraft
description: DesignCraft is the ArtCraft team's clean-room, open-source InDesign-class page-layout app (pure Rust; `.designcraft` project format; IDML/INDD/INDT import; PDF/X-4, PDF/A-2b, EPUB with Split Document, editable PPTX, HTML, PNG and JPEG export; headless CLI, MCP server and JSON control channel). Trigger this skill whenever the user mentions DesignCraft — or a `.designcraft`, `.idml`, `.indd`, `.indt`, `.dcbook`, `.dclib`, `.ase` or command-script file — asks what it can or cannot do, which formats it opens or writes, its keyboard shortcuts, how to automate or script it, how to prepare or convert assets for it, how to place PDFs and choose their layers, how to verify or repair its output, or how to troubleshoot it. Also trigger when the job is described without naming the app — "lay out a magazine", "thread this story across three columns", "set this on a baseline grid", "export a PDF/X-4", "make an EPUB from these pages", "split the EPUB into chapters", "batch-export every page to PNG", "place these photos in a brochure", "hide a layer of this placed PDF", "convert these text variables to text", "import my InDesign shortcuts". Do not guess its capabilities from InDesign knowledge — read this first.
---

# DesignCraft

Audit basis: this checkout is tag `v0.13.0`, commit `dcce40fb8731213c1f8e31cdd23444995afc62ce`. The installed `/Applications/DesignCraft.app` reports version `0.13.0` (`CFBundleShortVersionString`, `DesignCraftVersion`, `DesignCraftBuildCommit` = the same SHA) and its binary prints `designcraft 0.13.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Deep automation detail — CLI flags, script syntax, all 26 MCP tools, the control methods, coordinates, guide and column geometry, layer options, EPUB splitting, shortcut import — is in `references/agent-surfaces.md` next to this file.

## Overview

DesignCraft is a page-layout and publishing application written from scratch in Rust: "an open-source, modern desktop publishing and page layout studio" (`README.md`). It aims at full Adobe InDesign 2026 parity — "faster, open (documented JSON format + IDML), scriptable by agents (MCP), and available on the web" (`ROADMAP.md`) — as a clean-room application (`AGENTS.md`). It runs natively on macOS, Windows and Linux, and in a browser as WebAssembly (`README.md` §Web, `apps/designcraft-web`). Maturity is **pre-alpha**: the alpha gate is still blocked by fixes to Smart Text Reflow on the Primary Text Frame (#165), ~5–7 h away (`ROADMAP.md:3`, `docs/gaps.md` §0); the maintainers estimate ~80% feature breadth and ~47% "ready for real work" (`docs/target-app-parity.md` §Headline). Source: GitHub `storytold/designcraft`, MIT OR Apache-2.0 (`Cargo.toml`), a layered Cargo workspace enforced by `cargo xtask layers`; shared craft-libs crates provide printing, ICC colour management, atomic writes, PDF writing and document-path policy (`Cargo.toml` — craft-pdf rev `9f75d3dc19b4b514c4f3d4847ed1ec1b0e86b4ef` at this tag).

The one idea that governs everything: **every user-visible action is a command** with a stable id and JSON parameters (`crates/engine/src/cmd/mod.rs:167` `command_specs`), and the UI, CLI, control channel and MCP all go through `Session::execute` (`crates/engine/src/lib.rs:529`). Prefer commands over GUI poking.

## Capabilities (verified)

### Layout, guides and the document model — implemented
- Facing/non-facing spreads, parent (master) pages with page-number markers, sections, layers, and frames typed text / graphic / unassigned; stories threaded across frames and spreads (`crates/doc/src/{page,story}.rs`; `crates/engine/src/cmd/{layout,thread}.rs`).
- Document setup, page-size presets (incl. A0–A2 posters), bleed/slug, start page, Page tool for pages of their own size (`layout.documentSetup`, `layout.pageSize`, `file.new`).
- Multi-document tabs: `file.activate {index}`, `document.list`, next/previous document (`Cmd+F6` / `Cmd+Shift+F6`) — `crates/engine/src/cmd/file.rs`, `crates/ui-egui/src/menus.rs`.
- **Ruler guides:** `guide.add` (horizontal/vertical/both; page, spread or liquid guide), `guide.list`, `guide.select`, `guide.selectAll` (`Cmd+Alt+G`), `guide.deselect`, `guide.move`, `guide.moveBy`, `guide.delete`, `guide.deleteAll`, `layout.createGuides` (`crates/engine/src/cmd/guides.rs`; caps 10 000 guides, rows/columns ≤ 1000). Guides are selected like objects and a dragged guide snaps along its axis; Shift snaps to ruler ticks, Cmd suspends snapping (`crates/ui-egui/src/canvas.rs`, `crates/tools/src/snap.rs`).
- **Custom column guides:** a page keeps dragged column positions (`Columns.positions`, `crates/doc/src/page.rs`), `layout.moveColumnGuide {page, gutter, position, spread?|parent?}`, at most 216 columns (`page.rs:46` `MAX_COLUMNS`); `view.lockColumnGuides` is a document setting, **on by default**, saved in the document and IDML (`ColumnGuideLocked`); `view.lockGuides` (`Cmd+Alt+;`) only stops pointer dragging (`crates/engine/src/cmd/guides.rs`).
- **Page view history (v0.13):** `view.goBack` (`Cmd+PageUp`) / `view.goForward` (`Cmd+PageDown`) retrace page jumps at the current zoom; a new jump drops the pages ahead, scrolling adds no entry, deleted pages are skipped (`crates/ui-egui/src/page_history.rs`, `crates/ui-egui/src/menus.rs:259`).
- Styles (paragraph, character, object, table, cell, groups), swatches (process/spot/tints/gradients), text wrap, corner options, transparency effects, ICC colour management with working spaces and proof setups (`crates/engine/src/cmd/{style,object,colorsettings}.rs`; `crates/doc/src/styles.rs`).
- Interactions: Pathfinder boolean ops, compound/clipping paths, gradients, stroke styles/arrowheads, tables with merges and graphic cells, footnotes, endnotes, notes, cross-references, index, TOC, text variables, conditional text, track changes, data merge, XML tags/DTD, articles, object libraries, books, object states, buttons and form fields, page transitions, Flex Layout — `crates/engine/src/cmd/*`.
- Generators: QR codes (`object.qrCode`), math expressions (`math.insert`/`math.svg`), colour themes from a placed image (`color.extractTheme`), live captions (`object.caption`) — `crates/engine/src/cmd/{qr,mathexpr,color_theme}.rs`.
- Graphics: placed rasters, PDF pages, SVG, PSD composites, EPS previews, image clipping paths read from IDML (`crates/images`, `crates/render`, `crates/idml/src/import.rs`).

### Placed PDFs and placed-graphic layer options — implemented (v0.13), rendering caveat below
- **Object Layer Options** distinguishes a placed PDF's own defaults from an explicit choice: `object.layerOptions {ids?, hidden: [name], useDefaults?}` where `useDefaults: false` with `hidden: []` means *explicitly all on*, and legacy `hidden: []` resets to file defaults (`crates/engine/src/cmd/pdflayers.rs`). `object.pdfLayers {id?}` lists `{name, visible, default, overridden}`.
- Every explicit choice is validated with one real visibility rewrite per distinct source **before** any item is edited or undo recorded, so a mixed selection stays atomic and a PDF that lists layers but cannot be rewritten is refused (`crates/engine/src/cmd/pdflayers.rs`).
- Output honours the choice: plain and PDF/X-4 exports keep vector artwork and optional content with per-placement overrides (including repeated placements), booklet and book-merge output included; PDF/A-2b applies the choices to an export-only 300 ppi raster copy; embedded IDML stores a separate PDF variant per placement while external-only IDML export rejects active choices; `file.package` reports a placement whose choice an IDML copy cannot carry (`crates/pdf/src/optional_content.rs`, `crates/engine/src/cmd/export.rs`, `crates/idml/src/export.rs`).
- **IDML `GraphicLayerOption`/`GraphicLayer` settings are retained per placement** (not on the shared asset), so two placements of one file can keep different layer choices; scalar attributes, layer order, parent/child links, names, original/current visibility and view/export/print flags survive IDML import, native save/reopen and IDML export (`crates/doc/src/assets.rs:48`, `crates/idml/src/{import,export}.rs`, `docs/graphic-layer-options.md`).
- Retention is not layer-aware rendering — read **Known limitations** before promising appearance fidelity.

### Text engine — implemented
- Knuth–Plass total-fit paragraph composer plus a single-line composer, with a shared compose cache; optical kerning measured from glyph outlines (`crates/compose/src/lib.rs`, `crates/compose/src/breaker.rs`, `crates/compose/src/optical.rs`).
- Dictionary hyphenation (Moby list + trained Liang patterns), language-dependent quotes, bidi/RTL with kashida and digit substitution, CJK composition with mojikumi/kinsoku, vertical type, ruby, kenten, warichu, tate-chu-yoko (`crates/compose/src/hyphen/`, `crates/compose/src/{bidi,mojikumi,ruby,kenten,warichu}.rs`).
- **Story-level Optical Margin Alignment (v0.13):** `story.options {story?, frame?, opticalMargin?, opticalMarginSize?}` sets hanging punctuation/edges for every paragraph of a story except paragraphs with `ignoreOpticalMargin`; the **Story** panel and `type.selectionAttrs.storyOptions` expose it, and IDML carries `StoryPreference/@OpticalMarginAlignment`/`@OpticalMarginSize` plus `IgnoreEdgeAlignment` (`crates/engine/src/cmd/text.rs:108`, `crates/ui-egui/src/panels/story.rs`, `crates/engine/src/cmd/style.rs`).
- Hyphenation Settings (`app.hyphenationDialog`) sets limits, zone, the Better Spacing ↔ Fewer Hyphens slider, Hyphenate Capitalized/Last Word/Across Column and Preview as one undo step; new documents start with those three off in `[Basic Paragraph]`, opened/imported files keep their own (`crates/ui-egui/src/menus.rs`, `crates/engine/src/cmd/file.rs:240`).
- **Bulleted/numbered list buttons (v0.13):** `list.bullets` / `list.numbers {on?}` apply InDesign's default hanging indent (18 pt / −18 pt) to paragraphs with no indents and remove it again if they set it (`crates/engine/src/cmd/lists.rs:18`).
- **Notes (v0.13):** `note.convertFromText {author?}`, `note.next`, `note.previous` (caret after the anchor; unavailable in table cells and footnotes) alongside the existing `note.*` commands (`crates/engine/src/cmd/editorial.rs`, specs at :41, :106 and :115).
- **Convert Variable to Text (v0.13):** `variables.convertToText` (selected instances) and `variables.convertAllToText {name}` (every instance of one variable) replace each instance with the value it shows on its page; the variable stays defined (`crates/engine/src/cmd/variables.rs`, specs at :77 and :86).
- Column rules and Span Columns, Paragraph Rules above/below, Based on Parent, custom anchored objects with **Relative to Spine** (`anchored.options {spineRelative}`, mirrored on right-hand pages) — `crates/doc/src/item.rs`, `crates/ui-egui/src/dialogs.rs`, `crates/engine/src/cmd/anchored.rs:21`.
- Fonts: own font DB, shaping (harfrust), outlines (skrifa), variable-font instances, `Document Fonts` folders beside a document (case-insensitive), Type › Reload Fonts (`font.reload`) (`crates/fonts/src/fontdb.rs`, `crates/engine/src/cmd/{fonts,file}.rs`).

### Import / open — implemented
`file.open` decides by content, not extension (`crates/engine/src/cmd/file.rs` `open_path`):
- Native `.designcraft` (zip or legacy single JSON) — `crates/format`.
- `.idml` InDesign Markup imported into the native model — `crates/idml/src/import.rs`; `.indd`/`.indt` converted to IDML in memory by `storytold/indd-utils` (`crates/engine/src/cmd/interchange.rs`; real-file fidelity unmeasured — `docs/gaps.md` §2).
- Placed graphics: PNG, JPEG, GIF, WebP, TIFF, BMP, PSD/PSB composite, SVG, PDF (any page, crop-box choice), PDF-compatible Illustrator files detected as PDF, EPS (TIFF preview or placeholder — no PostScript interpreter) (`crates/images/src/lib.rs`).
- Text: `.txt`/`.text` (UTF-8 or UTF-16), `.md`, `.docx`, `.rtf`, `.xlsx` (first used range becomes a table), Tagged Text (`crates/textimport/src/lib.rs:96`); Data Merge sources CSV, TSV, text, `.xlsx` (`crates/engine/src/cmd/datamerge/`).
- Media (poster/placeholder frames, no playback): mp4, m4v, mov, webm, ogv, mp3, m4a, wav, ogg, oga, aac (`crates/doc/src/item.rs` `media_mime`; `crates/engine/src/cmd/media.rs`).
- Swatches `.ase`, ICC `.icc`/`.icm`, XML (with DTD), libraries `.dclib`, books `.dcbook`, and a page of an IDML or `.designcraft` document (`file.place {layoutPage}`) as a group of objects (`crates/engine/src/cmd/{style,colorsettings,xml,library,book}.rs`).
- `file.openRecent {index}` backs File › Open Recent (at most `recentFilesMax`, default 20) — `crates/engine/src/cmd/file.rs:45`, `crates/engine/src/lib.rs` `prefs`.

### Native format — implemented (format version 4 at this tag)
`.designcraft` is a zip (`crates/format/src/lib.rs`): `mimetype` (stored, first, `application/vnd.designcraft+zip`), `document.json` (pretty JSON of the serde model in `crates/doc`), `assets/` entries (one `<id>.<ext>` per referenced placed file, byte-for-byte, each file once), `meta.json` (format version and generator) and an optional `preview.png`. Latest reader capability is **version 4** (`VERSION`, `crates/format/src/lib.rs:29`): version 3 added retained EPS artwork; **version 4 is one capability covering both retained placed-graphic layer options and explicit all-on placed-PDF layer choices** (v0.12.0 was 3). `required_version` (`lib.rs:75`) pins a file to 4 only when it needs one of those, else keeps 2 or 3 so older readers still open it. Readers upgrade older versions and still open the legacy single-JSON form. Read limits: 100 000 entries, 256 MiB `document.json`, 1 GiB per asset, 4 GiB total; a document with non-finite geometry cannot be saved. `file.saveAs` appends `.designcraft` unless the path already ends with it, and writes are atomic (`crates/engine/src/io.rs`).

### Export — implemented
- **PDF** (`file.exportPdf`): real selectable text with embedded font subsets, DeviceCMYK/RGB/Gray, spot `/Separation`, bleed boxes, crop/bleed marks and page info, pages or spreads, `standard: "none" | "x4" | "a2b"`, tagged structure tree, transparency flattening, hyperlink annotations and outlines, interactive options, `created` (Unix seconds) for reproducible files, `file.printBooklet` imposition (`crates/engine/src/cmd/export.rs:12`; `crates/pdf/src/lib.rs`).
- **PDF/X-4 checks (v0.13 grew):** `designcraft-cli validate-pdf FILE.pdf` prints `{valid, issues}` and exits non-zero on failure; checks include PDF version, output intent, Info/XMP identification, interpolation, encryption, trim boxes, Type 3 fonts, device RGB under a CMYK output intent, and **fonts that draw visible text without an embedded font program — including inside placed PDF forms**, with font names and pages; render-mode-3 invisible text is exempt (`crates/pdf/src/pdfx.rs:212`, `crates/pdf/src/pdfx/fonts.rs:16`, `docs/agents.md` §PDF/X-4 validation).
- **EPUB 3** reflowable (`file.exportEpub`) and fixed layout (`file.exportFixedEpub`; pre-paginated page images plus their text). **Split Document (v0.13):** `document.epubSplit {split?}` stores off / before each export-tagged paragraph / before each paragraph of one style; `file.exportEpub {split}` overrides it for one export and `style.exportTag {split}` marks the styles; navigation and note links point across the files (`crates/epub/src/lib.rs:42`, `crates/epub/src/lib.rs:1063`, `crates/engine/src/cmd/export.rs:19`).
- **HTML** (`file.exportHtml`): one self-contained page, styles as CSS, images embedded, stories and graphics in reading order; returns `warnings`.
- **PowerPoint** (`file.exportPptx`): every page becomes a slide of editable shapes, pictures, tables and text boxes; `lineBreaks: keep|reflow`, `rasterize` (default true: unsupported objects become 300 ppi images), `embedFonts` (default true); approximations and drops are reported in `warnings` (`crates/pptx/src/lib.rs`).
- **PNG / JPEG** of a page via the renderer (`designcraft-cli run --export out.png`, `--all-pages DIR`; MCP `render_page` / `export_png`; control `ui.render`) — `crates/render/src/lib.rs`.
- **IDML** (`file.exportIdml`, `embedImages`), **Text** `.txt`/`.rtf`/tagged (`file.exportText`), **XML** (`file.exportXml`).
- **Print** (`file.print`, `file.printers`, `dryRun`, `created`) through the shared `craft-print` spooler (CUPS on macOS/Linux; Windows spooler in-process) — `Cargo.toml`, `docs/gaps.md` §10.

### Automation surfaces — implemented
- **CLI** `designcraft-cli` (`apps/designcraft-cli/src/main.rs`, `USAGE`): `run`, `commands [FILTER]`, `describe COMMAND`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`, `--version` — 10 subcommands, unchanged at this tag. On macOS it is **not inside `DesignCraft.app`**: the release ships a separate `designcraft-cli-<version>-macos-universal.zip`, and it is not on `PATH` unless installed (`README.md` §Downloads; `docs/mcp.md` §From an installed release). v0.13 changes: `mcp` takes `--automation-read-root`/`--automation-write-root` **more than once** (`apps/designcraft-cli/src/automation_args.rs:15`), in `--flag DIR` and `--flag=DIR` spellings, and `validate-pdf` gained the visible-unembedded-font checks.
- **MCP server** `designcraft-cli mcp` — stdio JSON-RPC, protocol 2025-06-18 (older revisions accepted), **26 tools**, byte-identical to v0.12.0: command discovery/execution (`list_commands`, `execute`, `batch`), document I/O and inspection (`inspect_document`, `get_story`, `set_story_text`, `new_document`, `open_document`, `save_document`, `place_image`), rendering (`render_page`, `export_png`, `screenshot`), input/UI tools (`select_tool`, `pointer`, `key`, `type_text`, `ime`, `click`, `drag`, `menu_list`, `ui_inspect`, `ui_set`, `dialog_set/confirm/cancel`) (`crates/mcp/src/tools.rs:83`; `docs/mcp.md`). Read/write root flags confine every path a command touches (`crates/engine/src/file_access.rs`).
- **Control channel**: `designcraft --control PORT` serves JSON lines on `127.0.0.1` only, **26 methods**, unchanged at this tag (`apps/designcraft/src/control_server.rs`; `crates/ui-egui/src/control.rs:149`; 4 MiB line limit, 16 connections, no authentication — `docs/control-protocol.md`).
- **Scripts**: one command per line with `$N.path` references to earlier results (`crates/engine/src/script.rs`; `script.run {text}`; `docs/agents.md`). The Scripts panel runs a script as one undo step and restores the document on failure (`crates/engine/src/cmd/scripts.rs`).
- **Shortcut import**: `window.importShortcuts {path | text}` reads an InDesign Keyboard Shortcuts ▸ Show Set `.txt` (UTF-8/BOM or UTF-16; Windows or Mac key names; ≤ 8 MiB), applies its Default context (Text for type/text commands without one), reports `{set, imported, changed, conflictsCleared, skipped, unmatched, unmatchedWithoutShortcut, unreadable}`; tools keep their keys (`crates/ui-egui/src/shortcut_import.rs` — `MAX_BYTES` :17, `import` :359).
- Surface size at this tag: **537 engine command specs** (unique `cmd!` ids across the 61 `specs()` lists wired into `command_specs()`, `#[cfg(test)]` excluded) and **172 UI commands** (`UI_COMMANDS`, `crates/ui-egui/src/menus.rs:18`). Versus v0.12.0 (527 + 166): **+10 engine** — `document.epubSplit`, `list.bullets`, `list.numbers`, `note.convertFromText`, `note.next`, `note.previous`, `selection.key`, `story.options`, `variables.convertToText`, `variables.convertAllToText` — and **+6 UI** — `app.grepStylesDialog`, `app.hyphenationDialog`, `app.keepOptionsDialog`, `app.nestedStylesDialog`, `view.goBack`, `view.goForward`; **nothing removed**. MCP stays 26 and the CLI subcommands are unchanged. CLI discovery lists engine commands only; a running app's `engine.commands` / MCP `list_commands` also lists UI commands marked `"ui": true`. Discover the live list with `designcraft-cli commands` and `describe`.
- Key Object for alignment (v0.13): `selection.key {id}` makes a selected item the key object (needs ≥ 2 selected); `object.align`'s `to` defaults to `keyObject` while one is set (`crates/engine/src/cmd/edit.rs:275`, `crates/engine/src/cmd/object.rs:685`).

### Platforms — implemented
- macOS, Windows, Linux native (`apps/designcraft`); WebAssembly web build via trunk (`apps/designcraft-web`: WebGPU with a WebGL2 fallback, `?webgl` to force it, `?sample` for the sample magazine). The web build has no control channel, and Save/Export download files instead of writing them (`README.md` §Web). Runtime environment variables: `RUST_LOG`, `WGPU_BACKEND`, `WGPU_POWER_PREF`, `WGPU_ADAPTER_NAME`, `WGPU_VALIDATION_INDIRECT_CALL`, `DESIGNCRAFT_CONTROL_PORT`, `DESIGNCRAFT_CONFIG_DIR`, `DESIGNCRAFT_NO_PREFS`, `DESIGNCRAFT_NO_NATIVE_MENU`, `DESIGNCRAFT_WAYLAND` (Linux) — `README.md` §§Logs, Portable mode; `apps/designcraft/src/{main,profile}.rs`.

## Known limitations and not-implemented

Ranked shortfall list: `docs/gaps.md` (kept current by the maintainers — read it before promising work). Headline items at this tag:

- **Pre-alpha.** The alpha gate is blocked by Smart Text Reflow on the Primary Text Frame adding pages users cannot delete (#165) — `docs/gaps.md` §0, `ROADMAP.md:3`. Threading by hand and autoflow fill-the-following-pages-first work.
- **Basic canvas editing still fails for some users** — object copy/paste on Windows and Linux, right-click context menus, formatting at a caret discarded (`docs/gaps.md` §1).
- **Placed graphic layer options are retained, not rendered.** IDML per-placement layer visibility is preserved and warns on import/preflight/PDF export, but the renderer and PDF exporter still use the asset's composite/default appearance; layer-comp choices and a layer-options UI are missing (`docs/graphic-layer-options.md`, `docs/gaps.md` §19). Placed **PDF** layer choices *are* applied (see above) — do not generalise that to IDML/PSD layer options.
- **INDD/INDT opening is unmeasured on real files**; **INDB/INDL are not read**; no QuarkXPress import (`docs/gaps.md` §§2, 19). **IDML round-trip is not proven on real files** — broad importer coverage, no InDesign-authored corpus metric; opened IDML can reflow (`docs/gaps.md` §§3, 4).
- **EPS is preview-only** — no PostScript interpreter (`crates/images/src/eps.rs`, `docs/gaps.md` §19). **No ExtendScript/UXP compatibility**: InDesign scripts do not run; the script language is DesignCraft's own command language (gap 22). **No plug-in model** (gap 23). **No in-app media playback**.
- **PDF standards:** no PDF/X-1a, PDF/X-3, PDF/UA validation, Adobe `.joboptions` presets, or output-intent choice beyond the built-in profile; PostScript printing is absent (gap 9). **Placed-PDF font repair is missing** (gap 28): export and `validate-pdf` now *detect and name* visible unembedded fonts, but nothing embeds, substitutes or outlines them automatically.
- **HTML export is one basic page; fixed-layout EPUB writes page images** rather than live text and CSS; EPUB splitting exists, but neither output has animation or timing, and both rely on style-derived CSS (gap 17).
- **Hyphenation** for English, Spanish, Portuguese, Norwegian and Greek only; **spelling** English only (gap 13). **No screen-reader exposure**; PDF/UA unverified (gap 25).
- **Startup crashes and blank canvases on some GPU/driver combinations** remain a partly mitigated class (backend fallback + `gpu.json` skip list; gap 5). **Performance**: no incremental composition and no GPU raster — the canvas is CPU-rendered with `vello_cpu`, the GPU only composites the UI (gap 20).
- **Font discovery** still misses fonts that some services/managers activate; disk changes are noticed only on request (`font.reload`) (gap 6). **Localization** is partial: 1,724 strings measured; Japanese 95%, Czech/Polish 99%, Georgian 100%, several 61–85%, Hindi/Indonesian/Korean/Vietnamese absent (`ROADMAP.md` §Languages). A missing string shows English and fails no check.
- **Shortcut import limits**: reads only InDesign Show Set `.txt` (not `.indk`), applies only the Default context (Text for type/text commands), rejects macOS Control-key chords, never changes tool keys, and cannot write/export a set (`crates/ui-egui/src/shortcut_import.rs`).
- **Custom column guides** are horizontal column gutters only; locked by default and `layout.moveColumnGuide` refuses while locked; changing column count or gutter discards the custom positions; a page that changes side of the spine mirrors them (`crates/engine/src/cmd/layout.rs`, `crates/doc/src/page.rs`).
- **`file.close` is not a safe "close tab"**: it closes without asking and discards the document's recovery data (`crates/engine/src/lib.rs:505` `close_document`). The UI's File ▸ Close / tab × asks when the document is dirty; `app.quit` asks per dirty document, while the control method `app.quit` quits without asking (`crates/ui-egui/src/lib.rs:1263`).
- **Claimed but unverified**: README says "every menu item, tool gesture, panel control and dialog" can be driven over the control channel and MCP (`README.md` §Why DesignCraft). The command registry and 26 control methods are broad, but this audit did not launch the GUI; treat a specific dialog as unverified until `ui.dialog.open` / `ui_inspect` confirms it.
- **Stale documentation to distrust**: `crates/pdf/src/lib.rs:28` still says "Not yet: tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content" although those are wired in; `ROADMAP.md:208` and `docs/target-app-parity.md:461` say "~200 commands"; `docs/target-app-parity.md:45` cites 446 engine + 99 UI commands (an older measurement); `docs/user/getting-started/install.md` is stamped `verified: 0.7.1`; `docs/agents.md` and the CLI's `SCRIPT_HELP` say most commands ignore unknown parameters, while the CLI, MCP and control channel reject them (`crates/engine/src/cmd/params.rs:224`, `apps/designcraft-cli/src/main.rs`, `crates/ui-egui/src/control.rs:164`). Verify with `designcraft-cli describe` against your build.

## How to operate

### Launch on macOS
- GUI: `open -a DesignCraft` (installed under `/Applications/DesignCraft.app`, `CFBundleIdentifier ai.storyteller.designcraft`, version 0.13.0 at this pin); to open a file: `open -a DesignCraft brochure.designcraft`. The binary inside the bundle is `/Applications/DesignCraft.app/Contents/MacOS/DesignCraft`.
- Real flags of the desktop binary (`apps/designcraft/src/main.rs`): `--sample`, `--control <port>` (also `DESIGNCRAFT_CONTROL_PORT`), `--version`, `--gpu-skip=<list>` (internal restart bookkeeping), plus any number of file paths.
- **The CLI is not inside the `.app`.** Get it from the separate `designcraft-cli-<version>-macos-universal.zip` release asset, `cargo install --path apps/designcraft-cli --locked`, or `cargo build --release -p designcraft-cli`; do not assume a system-wide `designcraft-cli` exists (it was not installed on the audit machine).
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
designcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR]... [--automation-write-root DIR]...
designcraft-cli perf [--pages N] [--frames N] [--chars N] [--images N] [--runs N] [--strict]
designcraft-cli bench FILE [--runs N]
designcraft-cli validate-pdf FILE.pdf | links | --version
```
- `--page`, `--scale` and `--pdf-options` apply to the `--export`s that **follow** them; one left after the last export is an error.
- `--export` picks the writer from the extension: `.png`/`.jpg`/`.jpeg` (a page), `.pdf`, `.designcraft` (Save As), `.idml`, `.epub`, `.pptx`, `.html`/`.htm`, `.rtf`/`.txt`; an unknown extension is an error and *nothing runs*; a name with no extension is a PNG of the page.
- `run --cmd ID=JSON` uses `$N.path`/`$last.path` references; a params key the command's description doesn't name is an error (checked by the CLI, MCP and control channel).
- `script` prints `{"completed": n, "results": [...]}` plus `failedIndex`/`failedCommand`/`error` and exits non-zero on failure; `--keep-going` records failures as results instead.
- `mcp` roots may each be repeated; a path inside any root of its kind passes. A root left out grants none of that access, and roots plus `--connect` is an error.

### Document and window model
- Several documents open in tabs; each tab is its own `DocState` with its own undo history, selection and (optionally) its own `Document Fonts` scope (`crates/engine/src/lib.rs`, `crates/ui-egui/src/chrome.rs`). A document is spreads → pages → items; text lives in **stories** threaded through text frames; parent pages contribute items behind a page's own (`crates/doc/src/{page,story,item}.rs`).
- **Coordinates are points (1/72 in), y down, in spread space**: on a facing spread the right page starts at `x = page width` (`docs/mcp.md` §Coordinates). **Text offsets are UTF-8 byte offsets**, not character counts (`anchor`, `focus`, `story.replaceRange`, story `length`) — `docs/mcp.md` §Text offsets.
- Commands that create items take `spread`: an integer, or `{"kind":"parent","index":N}` (`crates/engine/src/cmd/mod.rs` `spread_param`). `page` in guide/column commands is the page's **index within its spread**; `document.inspect` page `index` is absolute.
- **Closing:** `file.close {index?}` closes without prompting and discards recovery data; the UI's File ▸ Close / tab × and `app.quit` ask when dirty; the control `app.quit` does not. Save first.

### Recipes for the v0.13 surfaces
```sh
# Explicitly show every layer of the selected placed PDF, then read the state back
designcraft-cli run --in brochure.designcraft \
  --cmd 'object.layerOptions={"useDefaults":false}' \
  --cmd 'object.pdfLayers={}'

# Hide one layer of a placed PDF (ids default to the selection; atomic, validated first)
designcraft-cli run --in brochure.designcraft \
  --cmd 'object.layerOptions={"hidden":["Artwork"]}'

# Split a reflowable EPUB before paragraphs of one style, for this export only
designcraft-cli run --in brochure.designcraft \
  --cmd 'document.epubSplit={"split":{"style":"Heading 1"}}' \
  --export book.epub

# Story-wide hanging punctuation, then a list and a variable converted to text
designcraft-cli run --in brochure.designcraft \
  --cmd 'story.options={"opticalMargin":true,"opticalMarginSize":12}' \
  --cmd 'list.bullets={"on":true}' \
  --cmd 'variables.convertAllToText={"name":"Running Header"}' \
  --export page.pdf
```
- `object.layerOptions` returns `{hidden, useDefaults}`; `useDefaults` cannot be combined with a non-empty `hidden`. Read `object.pdfLayers` — its `overridden` flag separates a per-placement choice from the file's defaults.
- `document.epubSplit` with no `split` is a query; `off`, `"exportTags"` or `{"style": name}` sets it. `style.exportTag {split: true}` marks paragraph styles for `"exportTags"`. After export, unzip the EPUB and count `OEBPS/content*.xhtml` — one file when the split is off, more when it fires (`crates/epub/src/lib.rs` `chapter_file`).
- `story.options` also accepts `story`/`frame`; omit both to use the selection. `type.selectionAttrs` reports the same values as `storyOptions` (`null` where the stories differ). Per-paragraph `ignoreOpticalMargin` (in `type.para` and paragraph styles) opts a paragraph out.
- `selection.key {id}` then `object.align {edge, to?}` — with a key object set, `to` defaults to `keyObject`; a single selected object cannot be the key.
- `list.bullets`/`list.numbers` are toggles: with no `on` they turn off when every selected paragraph already has the list, else on. They also remove the default hanging indent they set when turned off, but never an indent the paragraph already had.

### Guides and column guides — recipes
```sh
# Add a horizontal + vertical guide through a point, move the pair, list them
designcraft-cli run --sample \
  --cmd 'guide.add={"orientation":"both","point":[72,72]}' \
  --cmd 'guide.moveBy={"dx":12,"dy":0}' \
  --cmd 'guide.list={}'

# Unlock, move, re-lock a column gutter, then verify geometry
designcraft-cli run --in brochure.designcraft \
  --cmd 'view.lockColumnGuides={"on":false}' \
  --cmd 'layout.moveColumnGuide={"page":0,"gutter":0,"position":180}' \
  --cmd 'view.lockColumnGuides={"on":true}' \
  --export out.designcraft
```
`gutter` 0 is the gutter between the first two columns; `position` is the gutter's new left edge in spread x. Read `document.inspect` (`columns`, `gutter`, `customColumns`, `columnRects`) to confirm. `view.lockGuides` only stops pointer dragging — put guides on a locked layer to protect them from commands too.

### Open / save / export flows
- Open: `File ▸ Open…` (`Cmd+O`, `file.open {path}`) — content-sniffed; `.idml` and `.indd`/`.indt` route through the IDML interchange module. `file.recentFiles` / `file.openRecent` (and UI `app.openRecent {index}`) back Open Recent.
- Save: `File ▸ Save` (`Cmd+S`, `file.save`) and `Save As…` (`Cmd+Shift+S`, `file.saveAs {path}`) write the native `.designcraft` package; `file.saveACopy` writes a copy without changing the open document; writes are atomic. Save and export dialogs start in the active document's folder (or the last file saved/exported) once known (`apps/designcraft/src/main.rs:283`).
- Recovery: unsaved documents are written to the recovery folder every 30 s by default (`recoveryMinutes`, minimum 5 s) and reopened after a crash (`crates/engine/src/recovery.rs`; `file.recovery.{save,list,open}`, `file.revert`).
- Export: the `file.export*` commands above, or the CLI's `--export`. Every export returns `{path, bytes, …}` plus a `warnings` array where applicable — **read it** (PDF export warns about unsupported graphic layer overrides, mixed gradient colour spaces, and PDF/X-4 checks including visible unembedded fonts).
- Package: `File ▸ Package` (`app.packageDialog`, `Cmd+Alt+Shift+P`; `file.package {dir, idml?, pdf?, instructions?}`) relinks to a `Links` folder with package-relative link paths, copies placed files and document fonts, writes an IDML copy (`idml` defaults true), an optional PDF (`pdf` defaults false) and a report; the report names a placed-PDF layer choice an IDML copy cannot carry (`crates/engine/src/cmd/package.rs`).

### Verified end-to-end examples
```sh
# Headless: build a page and export it three ways (--scale applies to the exports after it)
designcraft-cli run --sample \
  --cmd 'frame.create={"rect":[36,36,540,300],"content":"text","text":"Hello"}' \
  --export page.png --scale 2 --export page@2x.png --export page.pdf

# Discover then call a command (never guess params)
designcraft-cli commands note && designcraft-cli describe note.convertFromText

# Drive a running app (start it with a control port first)
designcraft --sample --control 7979 &
designcraft-cli app document.inspect
designcraft-cli app --method ui.render '{"page":0,"scale":2}'
```
MCP registration (`docs/mcp.md`):
```sh
claude mcp add designcraft -- designcraft-cli mcp \
  --automation-read-root "$PWD" --automation-write-root "$PWD/out"
```

## Working with an AI agent

**Legitimate and productive**
1. **Prepare inputs.** Convert to formats `crates/images` reads (PNG, JPEG, GIF, WebP, TIFF, BMP, PSD composite), author SVG or single-page PDF for vector/print art, write `.docx`/`.rtf`/`.txt`/`.md` (UTF-8 or UTF-16) for copy, and CSV/TSV/XLSX for Data Merge. Generate a test document with `file.newSample`.
2. **Drive it through commands, not pixels.** Prefer `designcraft-cli run --cmd`, `script` with `$N.path` wiring, MCP `batch`, or the control channel. Gesture paths exist (`ui.pointer`, `key`, `text`, `ime`, `dialog_*`), but commands are deterministic and return JSON.
3. **Look at the result.** `render_page`/`export_png`/`ui.render` return or write PNGs — read the image after layout work; `ui.screenshot` gives the whole window.
4. **Inspect programmatically.** `document.inspect` (pages incl. `columnRects`/`customColumns`, items, stories with `overset`, styles, swatches, selection incl. `guides`), `story.get`, `links.list`, `font.list`, `preflight.run {minPpi?}`, `document.preferences`; view state is UI-only (`ui.inspect`). `designcraft-cli describe` gives exact parameter names.
5. **Set up geometry programmatically.** `guide.add`/`guide.move`/`guide.moveBy`, read back with `guide.list`; move column gutters with `layout.moveColumnGuide` after `view.lockColumnGuides {on:false}`, then verify `columnRects`.
6. **Type work.** `story.options` for story-wide hanging punctuation, `list.bullets`/`list.numbers` for list buttons, `note.*` for notes, `variables.convertToText` when a client wants the running headers flattened, `style.exportTag`/`document.epubSplit` before an EPUB deliverable.
7. **Repair and analyse native files.** A `.designcraft` is a zip: unzip, read `document.json`, `meta.json` and `assets/`. **Re-zipping by hand is risky**: the reader requires `document.json`, honours `meta.json`'s version (above 4 is refused), and runs `Document::check()` plus asset wiring on load, so a hand-edited model may be refused. Prefer open → re-save through a command.
8. **Verify exports.** `designcraft-cli validate-pdf out.pdf`, `preflight.run`, `story.get` for overset text, `links.list` for missing images, every export's `warnings`, and an EPUB content-file count after `document.epubSplit`.
9. **Work on throwaway copies.** Copy the project file before a session; isolate a run with `DESIGNCRAFT_CONFIG_DIR` pointed at a scratch folder.

**Do not attempt**
- Do not assume parity: check `docs/gaps.md` and `designcraft-cli describe`. ExtendScript, UXP, `.joboptions` presets, plug-ins and Adobe cloud features do not exist (gaps 9, 22, 23).
- Do not promise layer-aware output for IDML/PSD layer options: only placed-**PDF** layer choices render and export; retained IDML graphic-layer settings warn instead (`docs/graphic-layer-options.md`).
- Do not promise PDF font repair: unembedded fonts in placed PDFs are detected and named, not fixed (gap 28).
- Do not assume the CLI or MCP server is installed: on macOS the `.app` holds only the desktop app. Build or download it first, and say so.
- Do not run `file.close` or the control method `app.quit` on a dirty document — both discard unsaved work and recovery data. The `app.quit` command (and the UI) asks first.
- Do not expect the shortcut importer to read `.indk`, apply non-Default contexts, handle macOS Control-key chords, or write a set; check `changed` and test a shortcut after importing.
- Do not move column guides on a locked document; unlock first and re-lock. Do not interpret EPS/PostScript or expect `.indd`/`.indt` fidelity, INDB/INDL, or QuarkXPress import.
- Do not drive the GUI blind (no screenshot/inspect feedback), and never run `--control` on a port you do not control: the channel has no authentication (`docs/control-protocol.md`).

## Verification protocol

DesignCraft is pre-alpha: treat every export as unverified until you have looked at it.

1. **Throwaway round-trip first.** New document (`file.new` or `--sample`) → one edit → save a `.designcraft` → reopen it (`--in`) → export the same page to PNG *and* PDF → check the PNG visually and the PDF with `validate-pdf` if you asked for `standard: "x4"`. If a step fails or geometry moved, stop and report.
2. **Never trust a silent export.** Read the JSON result (`bytes`, `pages`, `slides`, `warnings`) *and* confirm the file exists and is non-empty. A failed *step* in a non-`--keep-going` script still leaves earlier steps applied in the live app: re-inspect before retrying.
3. **Version and back up per session.** The format version is in `meta.json`; version 4 documents are refused by older readers (`FormatError::TooNew`). Keep a copy at the start of a session; to deliver files to someone on an older build, test one round-trip on their version first.
4. **Update between projects, not during one.** After a launcher update, re-verify the bundle version and build commit: `plutil -p /Applications/DesignCraft.app/Contents/Info.plist | grep -E 'Version|BuildCommit'` (at this pin: `0.13.0`, commit `dcce40fb…`).
5. **Isolate test runs.** `DESIGNCRAFT_CONFIG_DIR` to a scratch folder, `DESIGNCRAFT_NO_PREFS` to avoid writing preferences, and `--automation-read-root`/`--automation-write-root` (repeatable) for MCP.
6. **Prefer re-opening over re-editing.** The reader upgrades and validates on load, so save → reopen is the cheapest proof that an edit produced a valid document.
7. **Verify geometry, not just "no error".** After guide edits read `guide.list`; after `layout.moveColumnGuide` read `document.inspect`'s `columnRects`/`customColumns`. Reopen and confirm they survive (and IDML too, if handing off IDML).
8. **Verify the new typographic and EPUB settings.** After `story.options` re-read `type.selectionAttrs.storyOptions` and check the same text after reopen and through IDML; after `document.epubSplit` unzip the EPUB and count content files, and click one cross-file link target.
9. **Verify a placed-PDF choice in the output.** Export PDF, then check the exported file's optional content (or the warnings) — a choice that could not be applied is an error, and external-only IDML export refuses active choices.

*Verify against your installed version.* The repository at this pin and the installed bundle match exactly; if the launcher has since updated DesignCraft, re-run step 4 and re-check command parameters with `designcraft-cli describe` before relying on them.

## Sources & evidence

- Repository: https://github.com/storytold/designcraft — inspected at tag **v0.13.0**, commit **`dcce40fb8731213c1f8e31cdd23444995afc62ce`** (`git rev-parse HEAD`; `Release 0.13.0`, 2026-10-25), audited 2026-10-26.
- Installed app: `DesignCraft.app` in the system Applications folder, `CFBundleShortVersionString 0.13.0`, `DesignCraftBuildCommit dcce40fb8731213c1f8e31cdd23444995afc62ce`, `LSMinimumSystemVersion 11.0` (`Contents/Info.plist`; inspected, never launched; `Contents/MacOS/DesignCraft --version` prints `designcraft 0.13.0`). The bundle contains only `DesignCraft`; no `designcraft-cli` is installed on the audit machine.
- Read for this skill: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`, `docs/{agents,mcp,control-protocol,gaps,target-app-parity,ui-parity,file-format-parity,localization-parity,graphic-layer-options,pdf-layer-visibility}.md`, `apps/designcraft/src/{main,profile,gpu,logging,control_server,native_menu}.rs`, `apps/designcraft-cli/src/{main,automation_args,perf}.rs`, `crates/format/src/lib.rs`, `crates/engine/src/{lib,script,recovery,io,file_access}.rs`, `crates/engine/src/cmd/*` (incl. `export.rs`, `pdflayers.rs`, `text.rs`, `variables.rs`, `lists.rs`, `editorial.rs`, `edit.rs`, `object.rs`, `file.rs`, `anchored.rs`, `guides.rs`, `layout.rs`, `params.rs`, `package.rs`), `crates/mcp/src/{tools,server,headless,backend}.rs`, `crates/ui-egui/src/{control,menus,chrome,canvas,shortcut_import,page_history}.rs`, `crates/ui-egui/src/panels/{story,properties}.rs`, `crates/doc/src/{page,item,assets}.rs`, `crates/compose/src/{lib,optical}.rs`, `crates/pdf/src/lib.rs`, `crates/pdf/src/pdfx.rs`, `crates/pdf/src/pdfx/fonts.rs`, `crates/pdf/src/optional_content.rs`, `crates/epub/src/lib.rs`, `crates/idml/src/{import,export}.rs`, `crates/images/src/lib.rs`, `crates/textimport/src/lib.rs`.
- Counts were re-measured from this tag's code (`cmd!` ids and `UI_COMMANDS`) and compared against the v0.12.0 release tree: 537 engine / 172 UI / 26 MCP tools / 26 control methods / 10 CLI subcommands. Live discovery beats this document: `designcraft-cli commands`, `designcraft-cli describe ID`, and `docs/gaps.md`.
- Deep automation tables (CLI, scripts, MCP tools, control methods, coordinates, guides/columns, layer options, EPUB split, story options, shortcut import, sample commands): `references/agent-surfaces.md`.

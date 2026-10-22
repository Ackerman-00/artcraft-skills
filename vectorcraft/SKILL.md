---
name: vectorcraft
description: >-
  VectorCraft is a free, open-source, pure-Rust vector illustration app — a clean-room
  reimplementation of Adobe Illustrator for macOS, Windows, Linux, FreeBSD and the web (WASM) —
  with an MCP server, a JSON control channel, a browser JS API and a headless CLI. Use this skill
  whenever the user mentions VectorCraft (or "the vector app", a `.vectorcraft`/`.vctemplate` file,
  or the ArtCraft vector tool), asks what it can do, which formats it opens/saves/exports, its CLI
  flags, control or MCP tools, or its keyboard shortcuts; wants to create, edit, automate, script,
  batch-convert or export vector art with it; needs assets prepared for it (SVG/PDF/EPS/images/
  fonts/`.wasm` plug-ins); wants its output verified or repaired; or troubleshoots it — even when
  the app is not named but the job is Illustrator-style vector work ("draw a logo", "make an SVG",
  "edit this .ai", "trace this bitmap", "convert this DXF").
---

# VectorCraft

## Overview

VectorCraft is a clean-room, open-source reimplementation of the Adobe Illustrator workflow,
written from scratch in pure Rust (`README.md`). It runs natively on macOS, Windows, Linux and
FreeBSD, and in the browser via WebAssembly (`README.md`; `apps/vectorcraft-web/`). Maturity:
**alpha** — self-assessed at ~88% feature breadth (348/375 Illustrator menu items wired, 92.8%;
tools 89/92; Illustrator effects 46/50; Photoshop effects 46/57; 3D 4/4 initial types), ~75%
feature depth and ~62% "ready for real work" against Illustrator 2026 (30.x); `ROADMAP.md` decides
the stage, `docs/target-app-parity.md` explains the method, `docs/gaps.md` is the ranked work list.
Agents can drive all of it: every menu item, tool gesture, panel and dialog is a command reachable
over MCP, a JSON control channel, the browser's `window.vectorcraft`, and a CLI (`AGENTS.md`;
`docs/mcp.md`; `docs/control-protocol.md`). Source: GitHub `storytold/vectorcraft`; installed on
this Mac as VectorCraft.app (`CFBundleIdentifier ai.storyteller.vectorcraft`). **This skill is
pinned to release tag `v0.14.0` (commit `ad0566943ab9741e6356bbc9b53c3cc09895068d`), which is
exactly what the installed bundle ships — verify against your installed version (the desktop
app's `--version`) if it differs.**

Project-wide rules that also bind anyone touching the repo: never run, script or copy from Adobe
applications (clean-room, `AGENTS.md`), no panics in shipped code (clippy-denied, plus
`crates/engine/src/guard.rs` as last line of defence), every asset attributed in `ASSETS.md`.

## Capabilities (verified)

### Documents and UI
- Native format `.vectorcraft` (legacy `.drawcraft` still opens): versioned JSON, `VERSION = 4`
  (down-saves to v1/v2), optional gzip compression, embedded PNG preview, and compact JSON for
  path-heavy documents (~1/5 size) (`crates/format/src/lib.rs`; `docs/mcp.md` › Native files).
  Saves are atomic (temp file + rename); keys written by a newer version survive a save.
- Multiple documents open as **tabs** in one window, each with **artboards**, layers and
  sublayers; dockable/floating panels, user workspaces (`crates/ui-egui/src/state.rs`;
  `docs/control-protocol.md` › `ui.inspect` reports every open document). 40+ panels live in
  `crates/ui-egui/src/panels/` (Layers, Appearance, Properties, Swatches, Gradient, Transparency,
  Character/Paragraph/OpenType/Glyphs, Artboards, History, Links, Libraries, Asset Export, Image
  Trace, Pathfinder, Actions, Variables, CSS Properties, Separations, SVG Interactivity, Magic
  Wand, Navigator, Blend, Pattern Options, Flattener Preview…).
- Export bytes are reproducible: `SOURCE_DATE_EPOCH` replaces the wall clock in PNG, PDF, EPS,
  legacy `.ai`, packaged zips and `.vectorcraft` saves (`ROADMAP.md` 2026-10-18).

### Drawing, paths and paint
- Full tool set (89/92 of Illustrator's tools wired per `ROADMAP.md`; 92 ids in
  `crates/tools/src/catalog.rs`): Pen, Curvature, selection/anchor tools, shape tools,
  pencil/brush/blob brush, eraser, lasso, magic wand, scissors, shape builder, live paint, width
  tool, symbol tools, Dimension tool, Perspective Selection, Touch Type… Tools never mutate the
  document directly — they emit commands, which is what makes gestures replayable by agents
  (`crates/tools/src/lib.rs`; `crates/tools/src/catalog.rs`).
- Exact curve-preserving Pathfinder booleans (linesweeper sweep-line on cubics), Shape Builder
  regions, Live Paint, offset, outline stroke, simplify (with slider + Auto-Simplify), join/average
  (`crates/pathops/src/lib.rs`; `crates/engine/src/cmd/pathops.rs`).
- Appearance stacks (multiple fills/strokes, per-item effects), transparency, blob/opacity masks,
  clipping masks, graphic styles, global/spot swatches, gradients (linear/radial/freeform),
  gradient mesh, patterns, recolor; ~97%-depth appearance area per `ROADMAP.md`; command modules in
  `crates/engine/src/cmd/` (`appearance.rs`, `paint.rs`, `gradient.rs`, `patterncmds.rs`,
  `recolor.rs`, `opacitymask.rs`).
- Brushes (calligraphic, scatter, art, pattern, bristle) with a default library and expansion to
  real objects (`crates/brush/src/lib.rs`).
- Symbols, blends (editable spines), envelopes, radial/grid/mirror **Repeat** (on-canvas mirror
  axis), perspective grid, Intertwine, **Objects on Path**, 9 graph types with graph designs,
  Variables/data sets (`crates/engine/src/cmd/{objects_on_path.rs,graph.rs,variablecmds.rs,
  perspgrid.rs,intertwine.rs}`; `crates/doc/src/{blend.rs,intertwine.rs,variables.rs}`).

### Type
- Point, area and type-on-a-path type, threading from the out port, character/paragraph styles,
  OpenType features (stylistic sets, alternates, figures, super/subscript), vertical type with
  initial CJK support, Hebrew/Arabic bidirectional layout, Thai/Lao/Khmer/Myanmar word breaking,
  Touch Type tool, Hyphenation…/Justification…/Roman Hanging Punctuation/Optical Margin Alignment
  (`crates/text/`; `docs/type-parity.md`; `README.md`).
- Text placed from `.txt`, `.rtf` and Word `.docx` as area type with formatting
  (`docs/file-format-parity.md`; `crates/engine/src/cmd/place/`).

### Effects and 3D
- Live vector effects (Distort & Transform, Path, Convert to Shape, Warp, Scribble, Round
  Corners…) kept in appearance stacks, plus raster effects; **46 of 57** Photoshop-style filters
  ship and **46 of 50** Illustrator effects (SVG Filters submenu and the Effect Gallery dialog are
  the named holes) (`crates/effects/src/lib.rs`; `docs/effects-parity.md`;
  `crates/engine/src/cmd/rasterfx.rs`).
- Initial 3D: live **Revolve, Extrude & Bevel, Inflate, Rotate** with caps, bevels, twist/taper,
  perspective and **1–10 coloured lights** (`MAX_LIGHTS = 10`); faces exported as vector art; no
  materials, and preview uses a painter's algorithm (not solid modelling)
  (`crates/three-d/src/{lib.rs,lights.rs}`; `docs/three-d.md`; `docs/revolve.md`).
- Image Trace (raster → vector) with presets, Shapes/Auto-Grouping/Gradients options and measured
  quality (`crates/trace/src/lib.rs`; `docs/image-trace-quality.md`).

### Files — open/read (implemented)
`document.open` / File › Open reads these 31 extensions — the authoritative list is `OPEN_EXTS` in
`crates/engine/src/cmd/fileio/mod.rs` (~L671): `.vectorcraft`, `.drawcraft`, `.svg`, `.svgz`,
`.pdf`, `.ai`, `.ait`, `.png`, `.jpg/.jpeg`, `.gif`, `.webp`, `.tif/.tiff`, `.bmp`, `.tga/.vda/
.icb/.vst` (Targa), `.psd`, `.psb`, `.vctemplate`, `.dxf`, `.emf`, `.wmf`, `.eps/.epsf`, `.ps`,
`.af`, `.afdesign`, `.afpub`. File › Place additionally reads `.txt`, `.rtf`, `.docx`
(`TEXT_EXTS`/`RTF_EXTS`/`DOCX_EXTS`). Highlights and limits (`docs/file-format-parity.md`):
- **SVG/SVGZ** — strongest format both ways; symbols, patterns, CSS, filters mapped to live
  effects, Inkscape extensions and multi-page artboards; unsupported filters are named in
  `warnings`; `preserveEditing` SVGs reopen as the full document.
- **PDF and `.ai`** — own reader (shared `craft-pdf` interpret backend, `docs/pdf-backend.md`);
  PDF opens with layers, editable text, masks, security, overprint; `.ai` reads Illustrator's
  private editing-data *structure* (layers, groups, gradients, meshes, linked files) and legacy
  PostScript-form `.ai` via a PostScript Level 3 interpreter; Illustrator EPS opens as editable
  vector art.
- **EPS/PS** — own PostScript L2/L3 interpreter and editing-data reader (`crates/eps/`).
- **Affinity** `.af`, `.afdesign`, `.afpub` — native read-only import (no write; `.afphoto` opens
  by content); 51 pinned corpus documents, 33 current `.af` (`crates/affinity/README.md`;
  `docs/affinity-validation.md`).
- **PSD/PSB** open as their **merged image only** (every mode/depth); placing as layers is not
  implemented (`docs/file-format-parity.md`).
- **DXF** (any version; circles/arcs as native entities), **EMF/WMF**, rasters incl. TIFF with
  CCITT Group 3/4 and CMYK ink preservation (`crates/cad/`, `crates/metafile/`).

### Files — save (implemented)
`SAVE_FORMATS` = `vectorcraft`, `template` (`.vctemplate`), `pdf`, `svg`, `svgz`, `ai`
(`crates/engine/src/cmd/fileio/save.rs` L23). Save As `.ai` writes a **PDF-compatible** file by
default, or **legacy version 7** (`aiVersion: "7"` / `convert --ai-version 7`) which keeps layers,
groups, compound paths and editable type, one artboard per file — transparency, live effects and
object names don't survive it (`docs/file-format-parity.md`). It never writes Illustrator's
private editing data (undocumented). Save As Template writes `.vctemplate`; `file.saveAsTemplate`
also writes a PDF-compatible `.ait` (legacy v7 is refused there).

### Files — export (implemented)
Extension-driven `document.export` (`export_extensions()`, `crates/engine/src/cmd/fileio/mod.rs`;
details in `docs/mcp.md` › `export`): `.vectorcraft`, `.vctemplate`, `.svg`, `.svgz`, `.pdf`
(presets, PDF/A-2b, PDF/X-1a/3/4, layers, marks/bleed, ICC, security), `.ai`, `.eps`, `.dxf`
(R12–2018), `.emf`, `.wmf`, `.png`, `.png8` (indexed), `.jpg`, `.webp` (**lossless only**; lossy
is written lossless with a warning), `.gif`, `.tif`, `.bmp`, `.tga`, `.psd` (**layered**), `.txt`.
Exporter **plug-ins** add their own formats (`plugin.<id>`). Plus Export for Screens / Asset
Export incl. TIFF (`crates/engine/src/cmd/fileio/screens.rs`), Export As with `rect` page-area
rasters, CSS Properties export (`crates/engine/src/cmd/css.rs`), Save for Office
(`document.exportForOffice`), Print/Print Tiling/Package through the shared `craft-print` spooler
(`Cargo.toml`; `crates/engine/src/cmd/print.rs`; `docs/print-tiling.md`), and PostScript only via
Print to PostScript (not `document.export`).

### Automation and extensions (implemented)
- **MCP server** (stdio, newline JSON-RPC 2.0, revision `2025-06-18`): `vectorcraft-cli mcp` —
  remote backend (`--connect 127.0.0.1:7979` to a running app: everything) or `--headless`
  (in-process engine + CPU renderer; everything except `inspect_ui`, `type_text`, `open_panel`,
  `screenshot {window:true}`). **32 tools** (`crates/mcp/src/tools.rs`, all unconditional):
  `command_run`/`run_command`/`invoke_menu` (aliases), `command_batch` (≤256 steps, `atomic`,
  `$N.path` references), `command_list`/`list_commands`, `doc_inspect`/`inspect_document` (with
  `ids`/`kind`/`limit`/`offset` scoping), `ui_inspect`/`inspect_ui`, `draw_path`, `draw_shape`,
  `set_paint`, `add_text`, `apply_effect`, `pathfinder`, `transform`, `create_graph`, `text_wrap`,
  `export` (selection/`rect`/cancellable, progress notifications), `render_preview`,
  `select_tool`, `pointer_gesture`, `press_key`, `type_text`, `open_panel`, `screenshot`,
  `open_file`, `save_file`, `undo`, `redo`. Plus **5 prompts** (`poster`, `icon-set`, `recolor`,
  `trace-and-style`, `export-set`), **3 fixed resources + 4 URI templates**
  (`vectorcraft://object/{id}`, `command/{id}`, `effect/{id}`, `swatch/{name}`), completions,
  logging, cancellation and a 2-second busy guard (`docs/mcp.md`). Caps: 16 MiB lines,
  64-message batches, 8 MiB kept step results, 256 MiB app replies.
- **Control channel** — `vectorcraft --control <port>` listens on `127.0.0.1` only, one JSON
  request per line: `engine.execute`, `engine.commands`, `document.inspect`, `ui.inspect`,
  `ui.menu.list`/`ui.menu.invoke`, `ui.contextMenu.list`, `ui.tool.select`/`ui.tool.list`,
  `ui.pointer`, `ui.key/text/move/click/drag/wheel`, `ui.set`, `ui.dialog.set/confirm/cancel`,
  `ui.resize`, `ui.focus`, `ui.screenshot`, `ui.render`, `app.open/save/export/quit`
  (`crates/ui-egui/src/control.rs`; `docs/control-protocol.md`). No authentication — loopback
  only; confine with `--automation-read-root/--automation-write-root`.
- **Browser API** — the web build exposes the same methods as promises on `window.vectorcraft`
  (`request`, `execute`, `commands`, `inspect`, `screenshot`, `openFile`, `captureDownloads`,
  `files`/`readFile`) (`apps/vectorcraft-web/src/api.rs`; `docs/control-protocol.md` › In the
  browser).
- **CLI** `vectorcraft-cli` (`apps/vectorcraft-cli/src/main.rs`): `mcp`, `run` (headless batch,
  `--in FILE --cmd ID --params JSON … --export FILE --scale N`; a step's result is referencable as
  `$N.path`), `commands` (the full command
  catalogue as JSON — the authoritative source of command ids, params docs and **keyboard
  shortcuts**), `convert IN OUT` (`--artboard/--range/--outline-text/--decimals/--replace-lossy/
  --editing-data/--ai-version 7|pdf/--hidden-objects layer|omit|visible/--transparent-images
  flatten|omit`; refuses to overwrite its input when reading it left things out unless
  `--replace-lossy`; reports `importWarnings`), `info FILE` (warnings, artboards, object counts,
  fonts), `bench FILE`, `perf` (performance budgets).
- **Plug-ins**: sandboxed WebAssembly modules (ABI v1, no imports, fuel + memory caps) as object
  **filters**, live **effects**, or **exporters** that add file formats to Export As /
  `document.export`; typed parameters (number/int/bool/choice/text/lists, up to 256); install via
  `plugin.install` / File › Open of a `.wasm` (`docs/plugins.md`; `crates/plugins/`).
- **Actions**: record/play via the Actions panel and the `command.batch` engine command; File ›
  Automate Batch; datasets via `dataset.import` (CSV/TSV; header cells define variables) with
  text/visibility/image/graph variable kinds (`crates/ui-egui/src/panels/actions.rs`;
  `crates/engine/src/cmd/variablecmds.rs`).
- **Script checking**: `script.check` statically analyses reference-app scripts (`.jsx`, `.jsxinc`,
  `.js`, `.jsxbin`) — it checks, never runs them (`crates/scriptcheck/src/lib.rs`;
  `crates/engine/src/cmd/scripts.rs`).

### Platform
- Web build: `apps/vectorcraft-web/` (Trunk; `cargo xtask wasm` gates it). Wasm aborts on panic —
  the native `guard` safety net does not apply there (`crates/engine/src/guard.rs`).
- Localized UI: 24 languages (23 `.tsv` catalogues + English) under `crates/ui-egui/src/i18n/`;
  tests hold the complete ones complete; only Georgian has had a native-speaker review; Hindi and
  Arabic have no catalogue (no right-to-left interface); 12-key-language score 74% measured
  (`ROADMAP.md` › Languages; `docs/localization-parity.md`).
- Experimental, unsupported 64-bit Windows 7 build (`docs/windows7.md`).

## Known limitations and not-implemented

Label guide: repo-admitted gaps (`docs/gaps.md`, `README.md`) — treat them as work the app cannot
be assigned yet.

- **Stage alpha; not a daily driver yet** (~62% ready for real work, 57–67%). The ranked gaps
  (`docs/gaps.md`): #1 G1 interaction-fidelity pass over every tool modifier and small behaviour —
  has **never** been checked side by side with the real app (clean-room forbids it, so "done"
  means "matches the documentation"); #2 G9 Illustrator `.ai`/EPS exchange — layer structure in
  real users' files is flattened or multiplied (#951), guides are lost (#779), some files open
  slowly (#758), live effects/brushes/symbols come in as plain art (#637), and Illustrator's own
  editing data is never written; #3 G10 launch/stability on some Windows 11 and Linux machines;
  #4 G8 hardening at scale (no real-world SVG/PDF/EPS corpus); #5 G11 correctness bugs in core
  tools. Beta also waits on G12 (preferences/panels that don't act), the type-core part of G4 and
  macOS pen pressure (~170–270 h total, `docs/gaps.md` › To beta).
- **Formats not supported at all**: FreeHand, CorelDRAW, DWG (use DXF), HEIC/HEIF, JPEG 2000,
  PICT/PCX/Pixar, Word `.doc`, and 3D export (OBJ/USDA/glTF). No Affinity **write**. PSD/PSB open
  as merged images only; PSD export is layered. No PDF editing beyond VectorCraft's own
  round-trip. `document.export` writes no `.ps` (PostScript is print-only output).
- **3D and Materials**: 4 initial live types only, **no materials**; ~25% depth. Painter's
  algorithm, not solid modelling (`docs/effects-parity.md`; `docs/three-d.md`).
- **Raster effects**: 11 of 57 still missing — Colored Pencil, Dry Brush, Fresco, Paint Daubs,
  Palette Knife, Rough Pastels, Underpainting (Artistic); Conté Crayon, Torn Edges, Water Paper
  (Sketch); and the Effect Gallery dialog (`docs/effects-parity.md`). Also missing from
  Illustrator effects: the SVG Filters submenu; Pathfinder Hard Mix/Soft Mix/Trap.
- **Type**: advanced CJK vertical composition (ruby, mojikumi sets, tate-chu-yoko), spell check,
  Retype, Snap to Glyph (menu stub), variable-font axis UI in the font menu, preserve-font-sizes-
  while-scaling-a-group are missing or partial (`docs/type-parity.md`).
- **Scripting**: reference-app scripting does **not** run — VectorCraft has no script engine
  (`README.md` "What's missing"); `.jsx` files can only be statically checked
  (`crates/scriptcheck`). Automation is MCP/control-channel/CLI instead.
- **Generative AI features**: none (0%, `docs/gaps.md` G18).
- **MCP limits**: stdio only — no Streamable HTTP/SSE, no `resources/subscribe`, no
  `sampling/createMessage` or `elicitation/create`; document reads are refused as busy while a
  long call runs (`docs/mcp.md` › Not implemented).
- **Control port has no authentication** — loopback only; disable it when not in use
  (`docs/control-protocol.md`).
- **Claimed but unverified in this pass**: the ui-parity "done" rows are documentation-based, not
  measured against Illustrator (`docs/ui-parity.md` states this); localization catalogues other
  than Georgian have had no native review; performance figures (README's "20,000 shapes in
  ~27 ms") are project self-reports — measure with `vectorcraft-cli perf` on your machine.
- **Stale-doc note**: `README.md` "What's missing" still lists Variables image/graph kinds and
  dataset import, but `dataset.import` (CSV/TSV) and all four `VariableKind`s exist in code
  (`crates/engine/src/cmd/variablecmds.rs`; `crates/doc/src/variables.rs`) — verify behaviour
  before relying on either side.

## How to operate

**Launch (macOS):**
```sh
open -a VectorCraft                       # or: open -a VectorCraft --args --control 7979
open -a VectorCraft --args --control 7979 --automation-read-root DIR --automation-write-root DIR
```
Desktop flags (`apps/vectorcraft/src/main.rs` L660-680): `--control <port>` (or
`VECTORCRAFT_CONTROL_PORT`; a bad port stops the app with an error), `--automation-read-root
<dir>`, `--automation-write-root <dir>` (confine everything an agent reads/writes;
`VECTORCRAFT_AUTOMATION_READ_ROOT`/`_WRITE_ROOT` env equivalents), `--in-window-menus`
(`VECTORCRAFT_IN_WINDOW_MENUS=1`), `--version`, `-h/--help`; extra arguments are files to open as
tabs. Env: `VECTORCRAFT_CONFIG_DIR` (isolated profile — use this for agent runs),
`VECTORCRAFT_NO_PREFS` (no preference reads/writes), `WGPU_POWER_PREF=high|low` /
`WGPU_ADAPTER_NAME=<substr>` to pick the GPU (`README.md`).

**The CLI is not inside the `.app` on macOS.** It ships as the separate release asset
`vectorcraft-cli-<ver>-macos-universal.zip` (`README.md` › Downloads; `docs/mcp.md` › From an
installed release); it is not on `PATH` by default — build with `cargo build --release -p
vectorcraft-cli`, `cargo install --path apps/vectorcraft-cli --locked`, or unzip the asset.
Launcher-installed app updates are automatic; update only **between** projects.

**Core workflow concepts:** one document per tab (`ui.inspect` lists `documents`/`activeDocument`);
each document has artboards, layers, objects addressed by stable ids; units are points, y down,
origin at the first artboard's top-left; a new document is 612 × 792 (`docs/mcp.md`). Selection +
key object drive most commands; most commands accept explicit `ids`.

**Open → edit → save/export:** open with File › Open / `app.open` / `open_file` (any `OPEN_EXTS`);
save with Save/Save As (`SAVE_FORMATS` above) — a document opened from or saved as SVG/PDF keeps
that format on Save, and the result's `warnings` say what the format loses; export with
`document.export` (extension picks the format; PDF/`.ai` write one page per artboard, rasters one
artboard unless `useArtboards`, with optional `rect` page-area crops). **Always read `warnings`**
— both on import (EPS fallback to preview, unsupported SVG filters…) and on export: they are the
loss report.

**Keyboard shortcuts:** never guess them. The command catalogue carries each command's shortcut:
`vectorcraft-cli commands`, MCP `list_commands`, control `engine.commands`
(`crates/ui-egui/src/shortcuts.rs` resolves them). User shortcut sets import/export as `.kys`
(`shortcutset` commands).

**Preferences / agent-visible folders (macOS):** `Application Support/VectorCraft/` under the
user's home (`ui.json` plus sibling folders Swatches, Graphic Styles, Fonts, Plug-ins, PDF
Presets, Color Profiles, Data Recovery, logs) (`apps/vectorcraft/src/prefs_dir.rs`;
`apps/vectorcraft/src/profile.rs`).

## Working with an AI agent

Prefer the automation surfaces over GUI automation; they are the same engine the UI uses.

- **Live session:** start the app with `--control 7979 [--automation-read-root DIR
  --automation-write-root DIR]`, then either talk the control protocol directly or register the
  MCP bridge: `claude mcp add vectorcraft -- /path/to/vectorcraft-cli mcp --connect 127.0.0.1:7979`
  (the bridge forwards each tool call as one control request, so you watch changes live).
- **Headless:** `vectorcraft-cli mcp --headless` or `vectorcraft-cli run --in FILE --cmd … --export
  OUT` — same commands, no window; the confinement flags imply `--headless` and refuse
  `--connect`, so a live app must confine itself with the same flags.
- **Inspect before editing**: `doc_inspect {depth: 0}` for the skeleton, then scope with
  `ids`/`kind`/`limit`, `document.find {name?, kind?, text?}` to locate nodes, `document.node
  {id, summary: true}` to slice one; read paint with `paint.proxies`; list formats/options with
  `document.formats`. On large documents drill — never dump `document.json`.
- **Draw/edit**: `draw_path` (SVG `d` or points), `draw_shape`, `add_text` (point/area/path,
  `vertical`, `justify`), `set_paint`, `apply_effect`, `pathfinder`, `transform`, `text_wrap`,
  `create_graph`, or any command id via `command_run`; group edits with
  `command_batch {atomic: true}` so one undo step is recorded. Get exact ids/params from
  `commands`/`list_commands` — unknown param keys are rejected with a did-you-mean error before
  anything runs.
- **Prepare inputs for the app**: SVG (cleanest interchange), PDF, EPS, DXF, PNG/JPEG/WebP/TIFF/
  BMP/Targa, PSD/PSB merged images, CSV/TSV for graphs and Variables data sets, `.rtf`/`.docx` for
  area type. Fonts: `text.addFontFiles` copies files into the app's Fonts folder; Japanese/
  Chinese/Arabic/Thai faces also come from the optional craft-fonts build input (`README.md`).
  Reusable logic can ship as a `.wasm` plug-in (ABI v1, no imports; `docs/plugins.md`).
- **Inspect/repair native files**: `.vectorcraft` is documented, versioned JSON (v4; optional gzip
  detected by content; unknown keys from newer versions are preserved by save). Prefer
  `document.save {version: 1|2, compress}` for downgrades over hand-editing; for repairs, open →
  inspect → command → save, and round-trip verify.
- **Verify outputs**: render previews (`render_preview`, `ui.render`, `screenshot`), reopen the
  export (`app.open`, `vectorcraft-cli info`) and diff warnings; `vectorcraft-cli bench/perf` for
  timing budgets. Never trust a silent export.
- **Must NOT**: drive the GUI blind (use control/MCP; `ui.screenshot` needs a presented frame and
  fails when the screen is locked; window geometry is not stable across machines); write `.ai`
  private editing data or Affinity files (not implemented — don't promise them); assume PSD opens
  with layers; run reference-app scripts (not supported); use Adobe apps to create or verify
  anything (repo clean-room rule; produce test art in-repo instead, `AGENTS.md`).

## Verification protocol

Alpha software: verify by round-trip, never by assumption.

1. **Throwaway round-trip test** before any real job: new document → one edit per feature you
   plan to use → save `.vectorcraft` → export the target format → reopen the export in VectorCraft
   *and* in the consuming app (browser for SVG, reader for PDF) → compare. Check `warnings` on
   open **and** export at every step (`convert` returns `importWarnings` beside export warnings).
2. **Master in native, deliver in exchange formats.** Keep the working file as `.vectorcraft` and
   treat SVG/PDF/EPS/`.ai` as deliverables: formats lose data (PDF-compatible `.ai` carries no
   Illustrator editing data; legacy v7 loses transparency/effects/names; EPS flattens opacity;
   DXF approximates gradients/patterns).
3. **Version and back up per session.** Saves are atomic and failed saves keep the old file, but
   a format conversion rewrites your project — keep a dated copy of the native file. `convert`
   refuses to overwrite its input when reading it left things out unless `--replace-lossy` is
   given; take that gate seriously.
4. **Pin versions per project.** The launcher auto-updates the app; alpha behaviour changes
   between releases. Update only between projects, and re-run your round-trip before trusting a
   pipeline after an update.
5. **Guard automation**: run agent sessions with `--automation-read-root/--automation-write-root`
   (both MCP and app), `VECTORCRAFT_CONFIG_DIR` for an isolated profile, and the control port on
   loopback only while in use (it has no authentication).

## Sources & evidence

- Repo: https://github.com/storytold/vectorcraft — inspected at tag **v0.14.0**, commit
  `ad0566943ab9741e6356bbc9b53c3cc09895068d` (2026-10-22), detached worktree, clean tree.
  Installed app verified as the same release by its CLI version (`vectorcraft 0.14.0`);
  the bundle's `CFBundleIdentifier` is `ai.storyteller.vectorcraft`.
- Docs read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`, `docs/gaps.md`,
  `docs/file-format-parity.md`, `docs/mcp.md`, `docs/control-protocol.md`, `docs/plugins.md`,
  `docs/ui-parity.md`, `docs/type-parity.md`, `docs/effects-parity.md`,
  `docs/localization-parity.md`, `docs/pdf-backend.md`.
- Code read: `apps/vectorcraft-cli/src/main.rs`, `apps/vectorcraft/src/main.rs`,
  `apps/vectorcraft/src/prefs_dir.rs`, `crates/mcp/src/{tools.rs,resources.rs}`,
  `crates/engine/src/cmd/fileio/{mod.rs,save.rs,encode.rs}`, `crates/engine/src/cmd/
  {select.rs,objects_on_path.rs,variablecmds.rs,scripts.rs}`, `crates/engine/src/guard.rs`,
  `crates/ui-egui/src/control.rs`, `crates/ui-egui/src/panels/`, `crates/ui-egui/src/i18n/`,
  `crates/format/src/lib.rs`, `crates/three-d/src/{lib.rs,lights.rs}`, `crates/tools/src/
  catalog.rs`, `apps/vectorcraft-web/src/api.rs`.
- Date: 2026-10-22. Companion file: `evidence.md` (claim → evidence map).

---
name: vectorcraft
description: >-
  VectorCraft is a free, open-source, pure-Rust vector illustration app — a clean-room
  reimplementation of Adobe Illustrator for macOS, Windows, Linux, FreeBSD and the web (WASM) —
  with an MCP server, a JSON control channel and a headless CLI. Use this skill whenever the user
  mentions VectorCraft (or "the vector app", a `.vectorcraft`/`.vctemplate` file, or the ArtCraft
  vector tool), asks what it can do, which formats it opens/saves/exports, its CLI flags, control
  or MCP methods, or its keyboard shortcuts; wants to create, edit, automate, script, batch-convert
  or export vector art with it; needs assets prepared for it (SVG/PDF/EPS/images/fonts/`.wasm`
  plug-ins); wants its output verified or repaired; or troubleshoots it — even when the app is not
  named but the job is Illustrator-style vector work ("draw a logo", "make an SVG", "edit this
  .ai", "trace this bitmap", "convert this DXF").
---

# VectorCraft

## Overview

VectorCraft is a clean-room, open-source reimplementation of the Adobe Illustrator workflow,
written from scratch in pure Rust (`README.md`). It runs natively on macOS, Windows, Linux and
FreeBSD, and in the browser via WebAssembly (`README.md`; `apps/vectorcraft-web/`). Maturity:
**alpha** — self-assessed at ~88% feature breadth (348/375 Illustrator menu items wired), ~75%
feature depth and ~62% "ready for real work" against Illustrator 2026 (30.x); `ROADMAP.md`
decides the stage, `docs/target-app-parity.md` explains the method, `docs/gaps.md` is the ranked
work list. Agents can drive all of it: every menu item, tool gesture, panel and dialog is a
command reachable over MCP, a JSON control channel and a CLI (`AGENTS.md`; `docs/mcp.md`).
Source: GitHub `storytold/vectorcraft`; installed on this Mac at `/Applications/VectorCraft.app`
(0.13.1). **This skill is pinned to release tag `v0.13.1` (commit
`904f0fe5227bd987d55319e89a38b4b8f046998c`), which is exactly what the installed bundle ships —
verify against your installed version (`VectorCraft --version`) if it differs.**

Project-wide rules that also bind anyone touching the repo: never run, script or copy from Adobe
applications (clean-room, `AGENTS.md`), no panics in shipped code (clippy-denied, plus
`crates/engine/src/guard.rs` as last line of defence), every asset attributed in `ASSETS.md`.

## Capabilities (verified)

### Documents and UI
- Native format `.vectorcraft` (legacy `.drawcraft` still opens): versioned JSON, `VERSION = 4`,
  saves down to v1/v2, optional gzip compression and embedded PNG preview; path-heavy documents
  are written as compact JSON (~1/5 size) (`crates/format/src/lib.rs`; `docs/mcp.md` › Native
  files). Unlimited undo via structural sharing (`crates/doc/src/lib.rs`).
- Multiple documents open as **tabs** in one window, each with **artboards**, layers and
  sublayers; dockable/floating panels, user workspaces (`crates/ui-egui/src/state.rs`;
  `docs/control-protocol.md` › `ui.inspect` reports every open document).
- Panels implemented in `crates/ui-egui/src/panels/` (Layers, Appearance, Properties, Swatches,
  Gradient, Transparency, Character/Paragraph, Artboards, History, Links, Libraries, Asset
  Export, Image Trace, Distort & Transform, Separations, Variables, CSS Properties, Actions…).

### Drawing, paths and paint
- Full tool set (89/92 of Illustrator's tools wired per `ROADMAP.md`): Pen, Curvature, selection
  and anchor tools, shape tools, pencil/brush, blob brush, eraser, lasso, magic wand, scissors,
  shape builder, live paint, width tool, symbol tools, dimension tool… Tools never mutate the
  document directly — they emit commands, which is what makes gestures replayable by agents
  (`crates/tools/src/lib.rs`; `crates/tools/src/catalog.rs`).
- Exact curve-preserving Pathfinder booleans (linesweeper sweep-line on cubics), Shape Builder
  regions, offset, outline stroke, simplify, join/average (`crates/pathops/src/lib.rs`).
- Appearance stacks (multiple fills/strokes), transparency, blob/opacity masks, clipping masks,
  graphic styles, global/spot swatches, gradients (linear/radial/freeform), patterns, gradient
  97%-depth appearance area per `ROADMAP.md`; command modules in `crates/engine/src/cmd/`
  (`appearance.rs`, `paint.rs`, `gradient.rs`, `patterncmds.rs`, `recolor.rs`, `opacitymask.rs`).
- Brushes (calligraphic, scatter, art, pattern, bristle) with a default library and expansion to
  real objects (`crates/brush/src/lib.rs`).
- Symbols, blends, envelopes, radial/grid/mirror **Repeat**, perspective grid, Intertwine,
  9 graph types, Variables/data merge (`crates/engine/src/cmd/{graph.rs,variablecmds.rs,
  perspgrid.rs,intertwine.rs}`; `crates/doc/src/{blend.rs,intertwine.rs}`).

### Type
- Point, area and type-on-a-path type, threading, character/paragraph styles, OpenType features
  (stylistic sets, alternates, figures, super/subscript), vertical type with initial CJK support,
  Hebrew/Arabic bidirectional layout (`crates/text/`; `docs/type-parity.md`; `README.md`).
- Text can be placed from `.txt`, `.rtf` and Word `.docx` (area type with formatting; list
  numbers/pictures/text boxes left out) (`docs/file-format-parity.md`; `crates/engine/src/cmd/
  place/`).

### Effects and 3D
- Live vector effects (Distort & Transform, Path, Convert to Shape, Warp, Scribble…) kept in
  appearance stacks, plus raster effects (Drop Shadow, glows, blur, feather, Rasterize and
  Photoshop-style filters); **33 of 57** Photoshop-style filters ship (`crates/effects/src/lib.rs`;
  `docs/effects-parity.md`; `crates/engine/src/cmd/rasterfx.rs`).
- Initial 3D: live **Revolve, Extrude & Bevel, Inflate, Rotate** with caps, bevels and 1–10
  coloured lights; faces exported as vector art; no materials, and preview uses a painter's
  algorithm (not solid modelling) (`crates/three-d/src/lib.rs`; `docs/three-d.md`;
  `ROADMAP.md` 2026-10-12/18 entries).
- Image Trace (raster → vector) with presets, quality measured in `docs/image-trace-quality.md`
  (`crates/trace/src/lib.rs`).

### Files — open/read (implemented)
`document.open` / File › Open reads these extensions — the authoritative list is `OPEN_EXTS` in
`crates/engine/src/cmd/fileio/mod.rs` (L660-750): `.vectorcraft`, `.drawcraft`, `.svg`, `.svgz`,
`.pdf`, `.ai`, `.ait`, `.png`, `.jpg/.jpeg`, `.gif`, `.webp`, `.tif/.tiff`, `.bmp`, `.psd`,
`.psb`, `.vctemplate`, `.dxf`, `.emf`, `.wmf`, `.eps/.epsf`, `.ps`, `.af`, `.afdesign`,
`.afpub`. File › Place additionally reads `.txt`, `.rtf`, `.docx` (`PLACE_EXTS`).
Highlights and their limits (`docs/file-format-parity.md`):
- **SVG/SVGZ** — strongest format both ways; symbols, patterns, CSS, filters mapped to live
  effects, Inkscape extensions; unsupported filters are named in `warnings`.
- **PDF and `.ai`** — own reader; PDF opens with layers, editable text, masks, security, overprint;
  `.ai` reads Illustrator's private editing-data *structure* (layers, groups, gradients, meshes,
  linked files) and legacy PostScript-form `.ai` via a PostScript Level 3 interpreter.
- **EPS/PS** — own PostScript L2/L3 interpreter and editing-data reader (`crates/eps/`).
- **Affinity** `.af`, `.afdesign`, `.afpub` — native read-only import (no write; `.afphoto` opens
  by content); 51 pinned files tested (`crates/affinity/`; `docs/affinity-validation.md`).
- **PSD/PSB** open as their **merged image only** (every mode/depth); placing as layers is not
  implemented (`docs/file-format-parity.md`).
- **DXF** (any version; SPLINE closure verified), **EMF/WMF**, raster formats incl. TIFF with
  CCITT Group 3/4, CMYK ink preservation (`crates/cad/`, `crates/metafile/`).

### Files — save (implemented)
`SAVE_FORMATS` = `vectorcraft`, `template` (`.vctemplate`), `pdf`, `svg`, `svgz`, `ai`
(`crates/engine/src/cmd/fileio/save.rs` L23). Save As `.ai` writes a **PDF-compatible** file by
default, or **legacy version 7** (`aiVersion: "7"` / `convert --ai-version 7`) which keeps layers,
groups, compound paths and editable type, one artboard per file — transparency, live effects and
object names don't survive it (`docs/file-format-parity.md`). It never writes Illustrator's
private editing data (undocumented). Save As Template writes `.vctemplate` (or `.ait` via
`file.saveAsTemplate`).

### Files — export (implemented)
Extension-driven `document.export` (`export_extensions()`, `crates/engine/src/cmd/fileio/mod.rs`;
details in `docs/mcp.md` › `export` tool): `.vectorcraft`, `.vctemplate`, `.svg`, `.svgz`, `.pdf`
(presets, PDF/X-1a/3/4, layers, marks/bleed, ICC), `.ai`, `.eps`, `.dxf` (R12–2018), `.emf`,
`.wmf`, `.png`, `.png8` (indexed), `.jpg`, `.webp` (lossless only), `.gif`, `.tif`, `.bmp`,
`.tga` (write-only), `.psd` (**layered**), `.txt`. Plus Export for Screens / Asset Export
(`crates/engine/src/cmd/fileio/screens.rs`), CSS Properties export (`crates/engine/src/cmd/css.rs`), Save for Office, and Print through
the shared `craft-print` spooler (`Cargo.toml`; `crates/engine/src/cmd/print.rs`).

### Automation and extensions (implemented)
- **MCP server** (stdio, newline JSON-RPC 2.0): `vectorcraft-cli mcp` — remote backend
  (`--connect 127.0.0.1:7979` to a running app, everything including UI tools) or `--headless`
  (in-process engine + CPU renderer; everything except `inspect_ui`, `type_text`, `open_panel`,
  `screenshot {window:true}`). Tools include `command_run`, `command_batch`, `doc_inspect`,
  `draw_path`, `draw_shape`, `add_text`, `apply_effect`, `pathfinder`, `transform`, `create_graph`,
  `export`, `render_preview`, `select_tool`, `pointer_gesture`, `press_key`, `undo`/`redo`
  (`docs/mcp.md`). Protocol caps: 16 MiB lines, 64-message batches.
- **Control channel** — `vectorcraft --control <port>` listens on `127.0.0.1` only, one JSON
  request per line: `engine.execute`, `engine.commands`, `document.inspect`, `ui.inspect`,
  `ui.menu.list/invoke`, `ui.tool.select/list`, `ui.pointer`, `ui.key/text/move/click/drag/wheel`,
  `ui.dialog.set/confirm/cancel`, `ui.screenshot`, `ui.render`, `app.open/save/export/quit`
  (`crates/ui-egui/src/control.rs`; `docs/control-protocol.md`). No authentication — loopback
  only; confine with `--automation-read-root/--automation-write-root`.
- **CLI** `vectorcraft-cli` (`apps/vectorcraft-cli/src/main.rs`): `mcp`, `run` (headless batch,
  `--in FILE --cmd ID --params JSON … --export FILE --scale N`, step results referencable as
  `$N.path`), `commands` (prints the full command catalogue as JSON — the authoritative source of
  command ids, params docs and **keyboard shortcuts**), `convert IN OUT` (all save/export formats;
  `--artboard/--range/--outline-text/--decimals/--replace-lossy/--editing-data/--ai-version 7/
  --hidden-objects/--transparent-images`), `info FILE` (import warnings, artboards, object counts,
  fonts), `bench FILE`, `perf` (performance budgets).
- **Plug-ins**: sandboxed WebAssembly modules (ABI v1, no imports, fuel + memory caps) as object
  filters or live effects; install via `plugin.install` / File › Open of a `.wasm`
  (`docs/plugins.md`; `crates/plugins/`).
- **Script checking**: `scriptcheck` statically analyses reference-app scripts (`.jsx`, `.jsxinc`,
  `.js`, `.jsxbin`) — it checks, never runs them (`crates/scriptcheck/src/lib.rs`;
  `docs/mcp.md` › Checking scripts).

### Platform
- Web build: `apps/vectorcraft-web/` (Trunk; `cargo xtask wasm` gates it). Note wasm aborts on
  panic — the native `guard` safety net does not apply there (`crates/engine/src/guard.rs`).
- Localized UI: 20+ catalogues under `crates/ui-egui/src/i18n/*.tsv` (English full; ~10 languages
  full, others partial; no native-speaker review) (`ROADMAP.md`; `docs/localization-parity.md`).

## Known limitations and not-implemented

Label guide: these are repo-admitted gaps (`docs/gaps.md`, `README.md`) — treat them as work the
app cannot be assigned yet.

- **Stage alpha; not a daily driver yet** (~62% ready for real work). The gaps that keep it there
  (ranked, `docs/gaps.md`): #1 interaction-fidelity pass over every tool modifier and small
  behaviour — has **never** been checked side by side with the real app (clean-room forbids it, so
  "done" means "matches the documentation"); #2 Illustrator `.ai`/EPS exchange — layer structure
  in real users' files is flattened or multiplied, guides are lost, some files open 4× slower, and
  Illustrator's own editing data is never written; #3 launch/stability on some Windows 11 and
  Linux machines; #4 hardening at scale (no real-world SVG/PDF/EPS corpus); #5 correctness bugs in
  core tools (Shape Builder Gap Detection, Transform-effect dialog items, some PDF text boxes
  shifting on open, SVG unit handling).
- **Formats not supported at all**: FreeHand, CorelDRAW, DWG (use DXF), HEIC/HEIF, JPEG 2000,
  PICT/PCX/Pixar, Word `.doc`, and 3D export (OBJ/USDA/glTF). No Affinity **write**. PSD/PSB open
  as merged images only; PSD export is layered. No PDF editing beyond VectorCraft's own
  round-trip.
- **3D and Materials**: 4 initial live types only, **no materials**; ~25% depth. Painter's
  algorithm, not solid modelling.
- **Raster effects**: 24 of 57 Photoshop-style filters still missing (no Effect Gallery)
  (`README.md`; `docs/effects-parity.md`).
- **Type**: advanced CJK vertical composition (ruby, mojikumi sets, tate-chu-yoko), Justification…
  options, spell check, Touch Type/Retype/Snap to Glyph, variable-font axis UI filters are missing
  or partial (`docs/type-parity.md`).
- **Scripting**: reference-app scripting does **not** run — VectorCraft has no script engine
  (`README.md` "What's missing"); `.jsx` files can only be statically checked
  (`crates/scriptcheck`). Automation is MCP/control-channel/CLI instead. Actions playback and
  Variables exist as commands (`docs/mcp.md`; `crates/engine/src/cmd/{action_batch.rs,
  variablecmds.rs}`).
- **Generative AI features**: none (0%, `docs/gaps.md` G18).
- **MCP limits**: stdio only — no Streamable HTTP/SSE, no `resources/subscribe`, no
  `sampling/createMessage` or `elicitation/create`; document reads are refused as busy while a
  long export runs (`docs/mcp.md` › Not implemented).
- **Control port has no authentication** — loopback only; disable it when not in use
  (`docs/control-protocol.md`).
- **Claimed but unverified in this pass**: the ui-parity "done" rows are documentation-based, not
  measured against Illustrator (`docs/ui-parity.md` states this explicitly); localization
  catalogues have had no native review (`docs/localization-parity.md`); performance figures
  (README's "20,000 shapes in ~27 ms") are project self-reports — measure with
  `vectorcraft-cli perf` on your machine.

## How to operate

**Launch (macOS):**
```sh
open -a VectorCraft                       # or: open -a VectorCraft --args --control 7979
"/Applications/VectorCraft.app/Contents/MacOS/VectorCraft" --control 7979 [file…]
```
Desktop flags (`apps/vectorcraft/src/main.rs` L648-665): `--control <port>` (or
`VECTORCRAFT_CONTROL_PORT`), `--automation-read-root <dir>`, `--automation-write-root <dir>`
(confine everything an agent reads/writes), `--in-window-menus`, `--version`, `-h/--help`; extra
arguments are files to open as tabs. Env: `VECTORCRAFT_CONFIG_DIR` (isolated profile — use this
for agent runs), `VECTORCRAFT_NO_PREFS` (no preference reads/writes), `WGPU_POWER_PREF=high|low` /
`WGPU_ADAPTER_NAME=<substr>` to pick the GPU (`README.md`).

**The CLI is not inside the `.app` on macOS.** It ships as the separate release asset
`vectorcraft-cli-<ver>-macos-<arch>.zip` (`docs/mcp.md` › From an installed release); on this
machine it is not currently on `PATH` — build with `cargo build --release -p vectorcraft-cli` or
unzip the asset. Launcher-installed app updates are automatic; update only **between** projects.

**Core workflow concepts:** one document per tab (`ui.inspect` lists `documents`/`activeDocument`);
each document has artboards, layers, objects addressed by stable ids; units are points, y down,
origin at the first artboard's top-left (`docs/mcp.md`). Selection + key object drive most
commands; most commands accept explicit `ids`.

**Open → edit → save/export:** open with File › Open / `app.open` / `document.open` (any
`OPEN_EXTS`); save with Save/Save As (`SAVE_FORMATS` above) — a document opened from or saved as
SVG/PDF keeps that format on Save, and the result's `warnings` say what the format loses; export
with `document.export` (extension picks the format; PDF/`.ai` write one page per artboard, rasters
one artboard unless `useArtboards`). **Always read `warnings`** — both on import (EPS fallback to
preview, unsupported SVG filters…) and on export: they are the loss report.

**Keyboard shortcuts:** never guess them. The command catalogue carries each command's shortcut:
`vectorcraft-cli commands`, MCP `list_commands`, control `engine.commands`
(`crates/ui-egui/src/shortcuts.rs` resolves them). User shortcut sets import/export as `.kys`
(`shortcutset` commands).

**Preferences / agent-visible folders (macOS):** `~/Library/Application Support/VectorCraft/`
(`ui.json` plus sibling folders Swatches, Graphic Styles, Fonts, Plug-ins, PDF Presets, Color
Profiles, Data Recovery, logs) (`apps/vectorcraft/src/prefs_dir.rs`; `apps/vectorcraft/src/
profile.rs`).

## Working with an AI agent

Prefer the automation surfaces over GUI automation; they are the same engine the UI uses.

- **Live session:** start the app with `--control 7979 [--automation-read-root DIR
  --automation-write-root DIR]`, then either talk the control protocol directly or register the
  MCP bridge: `claude mcp add vectorcraft -- /path/to/vectorcraft-cli mcp --connect 127.0.0.1:7979`
  (the bridge forwards each tool call as one control request, so you watch changes live).
- **Headless:** `vectorcraft-cli mcp --headless` or `vectorcraft-cli run --in FILE --cmd … --export
  OUT` — same commands, no window; use `--automation-read-root/--automation-write-root` to jail
  file access in both modes.
- **Inspect before editing**: `doc_inspect`/`document.inspect` (skeleton with `depth: 0`, then
  `document.find`/`document.node`), read paint with `paint.proxies`, list formats/options with
  `document.formats`.
- **Draw/edit**: `draw_path` (SVG `d` or points), `draw_shape`, `add_text`, `apply_effect`,
  `pathfinder`, `transform`, or any command id via `command_run`; group edits with
  `command_batch {atomic: true}` so one undo step is recorded. Get exact ids/params from
  `commands`/`list_commands` — unknown param keys are rejected with a did-you-mean error.
- **Prepare inputs for the app**: SVG (cleanest interchange), PDF, EPS, DXF, PNG/JPEG/WebP/TIFF/
  BMP, PSD/PSB merged images, CSV for graphs and Variables data sets, `.rtf`/`.docx` for area
  type. Fonts: `text.addFontFiles` copies files into the app's Fonts folder; Japanese/Chinese/
  Arabic faces also come from the optional craft-fonts build input (`README.md`). Reusable logic
  can ship as a `.wasm` plug-in (ABI v1, no imports; `docs/plugins.md`).
- **Inspect/repair native files**: `.vectorcraft` is documented, versioned JSON (v4; optional
  gzip detected by content; unknown keys from newer versions are preserved by save). Prefer
  `document.save {version: 1|2, compress}` for downgrades over hand-editing; for repairs, open →
  inspect → command → save, and round-trip verify.
- **Verify outputs**: render previews (`render_preview`, `ui.render`, `screenshot`), reopen the
  export (`app.open`, `vectorcraft-cli info`) and diff warnings; `vectorcraft-cli bench/perf` for
  timing budgets. Never trust a silent export.
- **Must NOT**: drive the GUI blind (use control/MCP; `ui.screenshot` needs a presented frame and
  fails when the screen is locked; window geometry is not stable across machines); write `.ai`
  private editing data or Affinity files (not implemented — don't promise them); assume PSD opens
  with layers; run reference-app scripts (not supported); use Adobe apps to create or verify
  anything (repo clean-room rule; also produce test art in-repo instead, `AGENTS.md`).

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
3. **Version and back up per session.** Saves are atomic (temp file + rename; failed saves keep
   the old file — `docs/file-format-parity.md`), but a format conversion rewrites your project —
   keep a dated copy of the native file. `convert` refuses to overwrite its input when reading it
   left things out unless `--replace-lossy` is given; take that gate seriously.
4. **Pin versions per project.** The launcher auto-updates the app; alpha behaviour changes
   between releases. Update only between projects, and re-run your round-trip before trusting a
   pipeline after an update.
5. **Guard automation**: run agent sessions with `--automation-read-root/--automation-write-root`
   (both MCP and app), `VECTORCRAFT_CONFIG_DIR` for an isolated profile, and the control port on
   loopback only while in use (it has no authentication).

## Sources & evidence

- Repo: https://github.com/storytold/vectorcraft — inspected at tag **v0.13.1**, commit
  `904f0fe5227bd987d55319e89a38b4b8f046998c` (2026-10-18), detached HEAD, clean tree.
- Installed app verified: `/Applications/VectorCraft.app`, `CFBundleIdentifier
  ai.storyteller.vectorcraft`, version **0.13.1** (`Contents/Info.plist`) — same release as the
  checked-out tag.
- Docs read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`, `docs/gaps.md`,
  `docs/file-format-parity.md`, `docs/mcp.md`, `docs/control-protocol.md`, `docs/plugins.md`,
  `docs/ui-parity.md`, `docs/type-parity.md`, `docs/effects-parity.md` (referenced).
- Code read: `apps/vectorcraft-cli/src/{main.rs,perf.rs}`, `apps/vectorcraft/src/{main.rs,
  prefs_dir.rs,profile.rs}`, `crates/engine/src/cmd/fileio/{mod.rs,save.rs}`, `crates/engine/src/
  guard.rs`, `crates/ui-egui/src/control.rs`, `crates/format/src/lib.rs`, `crates/{tools,effects,
  three-d,trace,plugins,scriptcheck,cad,metafile,eps,affinity,brush,pathops,doc}/src/lib.rs`,
  `xtask/src/main.rs`, `crates/ui-egui/src/{state.rs,shortcuts.rs}`, `crates/ui-egui/src/panels/`.
- Date: 2026-10-18. Companion file: `evidence.md` (claim → evidence map).

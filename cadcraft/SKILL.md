---
name: cadcraft
description: >-
  CADCraft is an open-source, clean-room AutoCAD-style 2D CAD and drafting app (pure Rust, egui) for
  macOS, Windows, Linux, FreeBSD and the web, with DXF/DWG file support and first-class agent control
  over MCP, a JSON control channel and a headless CLI. Trigger this skill whenever the user mentions
  CADCraft (or "the CAD app"), asks what it can or cannot do, which file formats it opens or writes,
  its keyboard shortcuts or commands, wants to draw, edit, dimension, hatch, lay out or plot a
  drawing, convert/inspect/verify a DXF or DWG, script or automate drafting (AutoLISP, scripts,
  MCP, control channel, cadcraft-cli), prepare assets for it, or troubleshoot it — and also when
  they describe the job without naming the app ("draw a floor plan", "edit this DXF", "convert
  this DWG to PDF/PNG", "put dimensions on this drawing", "check this drawing opens elsewhere").
---

# CADCraft

## Overview

CADCraft is a clean-room, open-source reimplementation of Autodesk AutoCAD (2D drafting first),
written from scratch in Rust (egui/eframe, wgpu) by the ArtCraft team. Source: GitHub
`storytold/cadcraft`, MIT OR Apache-2.0 (`README.md`, `LICENSE-MIT`, `LICENSE-APACHE`). Stage:
**pre-alpha** — the project's own gate says four of AutoCAD's five core workflows do not yet pass
alpha (`ROADMAP.md` line 3, `docs/roadmap.md`). Version at this checkout: **0.8.0**, commit
`714111d` (tag `v0.8.0`), matching the installed `/Applications/CADCraft.app` (Info.plist 0.8.0).
Scale: ~57,000 lines of Rust in 12 library crates and 3 apps, **409 registered commands**
(`docs/architecture.md`, `docs/parity-checklist.md`); menu breadth 280/491 (57%). It runs natively
on macOS/Windows/Linux/FreeBSD and in the browser via WebAssembly (`README.md`; `apps/cadcraft-web`).
The differentiator for agents: every user-visible action is a command reachable identically from the
command line, JSON control channel, MCP and CLI (`crates/engine/src/cmd/mod.rs`).

## Capabilities (verified)

### Drawing and editing (the AutoCAD workflow)
- Draw: LINE, PLINE (arcs, widths), CIRCLE (center/radius/diameter, 2P, 3P), ARC, RECTANG
  (fillet/chamfer), POLYGON, ELLIPSE (+arcs), SPLINE, POINT, XLINE, RAY, DONUT, TEXT, MTEXT
  (`crates/engine/src/cmd/draw.rs`, `draw2.rs`; `README.md` "What works today").
- Modify: ERASE, MOVE, COPY, ROTATE, SCALE, MIRROR, STRETCH, OFFSET, TRIM, EXTEND, FILLET, CHAMFER,
  BREAK, JOIN, EXPLODE, rectangular/polar ARRAY (+associative arrays), draw order, OVERKILL
  (`crates/engine/src/cmd/modify.rs`, `modify2.rs`, `array.rs`, `overkill.rs`).
- Precision: object snaps (endpoint, midpoint, center, geometric center, node, quadrant,
  intersection, insertion, perpendicular, tangent, nearest, deferred tangent/perpendicular), polar
  tracking, ortho, grid snap, direct distance entry, `@dx,dy` / `@d<a` / `#x,y`
  (`crates/engine/src/snap.rs`; `README.md`).
- Command line: prompts with clickable keywords, history, AutoComplete, aliases, right-click
  repeat, transparent commands (`'zoom`), `.scr`-style scripts (`crates/engine/src/lib.rs`,
  `crates/engine/src/cmd/file.rs` run_script; `README.md`).
- Grips: hot grips with Space to cycle Stretch/Move/Rotate/Scale/Mirror; grip menus
  (`crates/engine/src/grips.rs`, `griphot.rs`; `README.md`).
- Layers/properties: Layers palette + Layer Properties Manager, layer tools, Properties palette,
  linetypes, lineweights, ACI and true colour, transparency (`crates/engine/src/cmd/layer/`).
- Annotation: all DIM* commands with DIMSTYLE variables/overrides, associative dimensions, MLEADER,
  leaders, TABLE, TOLERANCE feature-control frames, MTEXT formatting codes, TrueType/OTF/TTC fonts,
  own single-stroke drafting font (`crates/engine/src/cmd/annotate*.rs`, `crates/fonts`).
- Hatch/blocks: pick-point hatch with islands, pattern/solid/gradient from CADCraft's own pattern
  library (23 patterns), BLOCK/INSERT, attributes (+BATTMAN, ATTSYNC, -ATTEDIT, DATAEXTRACTION),
  nested blocks, xrefs (XATTACH/-XREF/XBIND/XOPEN), Block Editor for static blocks (BEDIT etc.),
  groups (`crates/engine/src/cmd/hatch/`, `blocks/`, `groups.rs`, `crates/doc/src/library.rs`).
- Layouts/plotting: paper-space layouts, viewports (polygonal/object/clipped, VPCLIP, per-viewport
  layer freeze), MSPACE/PSPACE, page setups, PLOT, EXPORTPDF, PUBLISH (multi-sheet), plot preview;
  plot styles (CTB/STB) and plotter devices in CADCraft's own JSON formats
  (`crates/engine/src/cmd/layout.rs`, `plotters.rs`, `docs/plot-styles.md`, `docs/plotters.md`).
- Parametric: geometric + dimensional constraints, AUTOCONSTRAIN, PARAMETERS with expressions,
  re-solve after edits (`crates/constraints`, `docs/architecture.md`).
- AutoLISP: loads `.lsp` routines (APPLOAD, `(load)`, drag-and-drop), `(defun c:NAME)` commands,
  `acad.lsp`/`acaddoc.lsp` from the settings `support/` folder, `command`, `entget/entmake/entmod`,
  selection sets, `get…` input, most of the classic function library
  (`docs/autolisp.md`, `crates/engine/src/cmd/lisp.rs`).

### File formats (exact, from code)
- **Open/read**: DXF ASCII and binary, R12–2018, one reader for all versions; pre-2007 files decode
  from `$DWGCODEPAGE`; DWG (R13+ claimed by the acadrust bridge, tested 2000–2018, pre-R13 not
  read); SVG and gzipped SVGZ (shapes, paths, groups, Inkscape layers; no CSS, `use`, text,
  images, fills) (`crates/io/src/lib.rs` `read()`, `dxf_read.rs`, `svg_read.rs`,
  `crates/dwg/src/lib.rs` `is_dwg`).
- **Save/native**: DXF is the native path — write ASCII or binary, versions 2000–2018 (default:
  the file's own `$ACADVER`, 2018 for new drawings); DWG write 2000+ (bridge; DWG floor is 2004
  unless 2000 is asked for); `.dwt` templates are written as DWG content
  (`crates/io/src/lib.rs` `write_with()`/`write_framed()`, `docs/file-format-parity.md`).
- **Export**: SVG, PNG (2400×1600 via CLI; framed window or extents), PDF (vector, embedded
  TrueType subsets, OCG layers, multi-sheet, hyperlinks); EXPORT/EXPORTPDF/PUBLISH/PDFBOOK commands
  and `cadcraft-cli convert` (`crates/io/src/lib.rs`, `crates/io/src/pdf.rs`,
  `crates/engine/src/cmd/exchange.rs`, `crates/engine/src/cmd/layout.rs`).
- **Import**: another DXF/DWG's objects via `import`; user `.lin` / `.pat` / `.pgp`
  (linetype/hatch/alias) files; DWT/DXF templates for NEW/QNEW
  (`crates/engine/src/cmd/exchange.rs`, `docs/file-format-parity.md`).
- **Lossy-save honesty**: SAVE/SAVEAS report the entity types the target file cannot hold
  (`notSaved` in the result, plus a command-line message). DXF keeps unmodelled entities raw; DWG
  drops them (`crates/engine/src/cmd/file.rs` `not_saved()`, `drops_unknown()`, `report_not_saved()`).

### Automation surfaces (all over the same command registry)
- **MCP server** over stdio: `cadcraft-cli mcp` (headless session) or
  `cadcraft-cli mcp --connect 127.0.0.1:PORT [--lazy] [--launch]` (bridged to the running app).
  Tools: `command_line`, `script`, `execute`, `list_commands`, `inspect_drawing`,
  `query_entities`, `render`, `find_text`, `new_drawing`, `open`, `save`, `cancel`, plus
  `screenshot`/`ui_inspect`/`ui_click` when connected; resources `cadcraft://drawing`,
  `cadcraft://commands` (`docs/mcp.md`, `crates/mcp/`).
- **JSON control channel**: desktop app with `--control PORT` (or `CADCRAFT_CONTROL_PORT`), one
  JSON line per request over `127.0.0.1`. Top-level methods: `cmdline.input/script/key/state`,
  `engine.execute`, `engine.commands`, `drawing.inspect`, `ui.inspect`, `ui.elements`,
  `ui.menu.list`/`ui.menu.invoke`, `ui.pointer`, `ui.click`, `ui.move`, `ui.drag`, `ui.key`,
  `ui.text`, `ui.set`, `ui.resize`, `ui.focus`, `ui.screenshot`, `ui.render`, `app.open`,
  `app.save`, `app.quit`, `control.methods`, `ping` (`docs/control-protocol.md`,
  `crates/ui-egui/src/control.rs` METHODS table; kept in step by `crates/ui-egui/tests/control_methods.rs`).
- **CLI** `cadcraft-cli`: `info`, `convert`, `run`, `commands`, `sample`, `mcp`, `perf`,
  `--version` (`apps/cadcraft-cli/src/main.rs`, usage string lines 58–76).
- **Scripts**: `.scr` text through SCRIPT, CLI `--script`, MCP and the control channel
  (`crates/engine/src/cmd/file.rs` run_script).

### Platform notes
- Native macOS universal app; Windows x64/arm64/x86; Linux AppImage/Flatpak/deb/rpm/tar; FreeBSD;
  RISCV64 tar (`README.md` Downloads).
- WebAssembly web build runs the same UI (WebGPU, WebGL2 fallback), **no DWG**, browser storage
  instead of files, `?webgl`, `?cpu`, `?sample` URL flags, `?host=parent` iframe postMessage bridge
  (`apps/cadcraft-web/src/main.rs`, `host.rs`).
- Interface languages: English plus Ukrainian, Brazilian Portuguese, German, Spanish, Czech,
  Russian, French, Simplified Chinese, Italian, Korean, Swedish, Arabic (`crates/ui-egui/src/i18n/`
  `.tsv` catalogs; `docs/localization.md`; selectable via `ui.language`, also over the control
  channel). Engine messages, CLI/MCP replies stay English (`docs/gaps.md` L1).

## Known limitations and not-implemented

Read `docs/gaps.md` (the maintained work list, updated 2026-10-13) before promising anything. The
high-impact ones for an agent:

- **Saving DWG is lossy.** Through the acadrust bridge, custom-class entities/objects, xdata on
  table records and blocks, colour books and reactors are dropped; DXF keeps everything unmodelled
  raw (`docs/gaps.md` top-10 rows 1–2, `docs/file-format-parity.md`). Always check the `notSaved`
  report.
- **No real-file corpus and no AutoCAD verification.** All 36 file tests use synthetic input; no
  CADCraft output has been checked in AutoCAD black-box; a 10 MB DWG took ~2 min to fail
  (`docs/file-format-parity.md` Tests; `docs/gaps.md` FF5/FF6).
- **No 3D at all** — no UCS, 3D views, orbit, solids, surfaces, meshes, sections, visual styles,
  materials, lights, rendering (~150 menu items missing). `3DORBIT`/`ATTACH`/`SHARE` are registered
  only to say "not available yet" (`docs/gaps.md` F24; `crates/engine/src/cmd/exchange.rs`).
- **Geometry precision is approximate for curves**: ellipse/spline intersections, offsets and
  closest points are tessellated; polyline offset ignores bulges (`docs/gaps.md` top-10 row 3,
  `docs/geometry-parity.md`).
- **Ellipse/spline/curve offsets and REGION booleans are limited**; regions are saved as closed
  polylines with CADCraft xdata, not ACIS (`docs/gaps.md` F21).
- **Dynamic blocks**: references from other files are read and their visibility states/lookups can
  be changed; **authoring** parameters/actions is not possible (beta at best) (`docs/gaps.md` F3).
- **XCLIP missing; xrefs cannot be edited in place** (XOPEN opens them); REFEDIT works on block
  references, not xrefs (`docs/gaps.md` F2).
- **SHX fonts are not parsed** — text in SHX styles draws with CADCraft's stroke font or `FONTALT`,
  so metrics differ from AutoCAD; SHX-derived linetype shapes are skipped (`docs/gaps.md` FF8/FF9,
  `README.md` Fonts).
- **No PDF import/underlays, no raster image attach/display** (IMAGE entities survive save/reopen
  but pixels are never loaded), no DWF/DGN/WMF/EPS/ACIS/STL exchange formats (`docs/gaps.md` FF10,
  FF11; `crates/io/src/dxf_image.rs`).
- **No autosave in the web build**; desktop autosave files are DXF (`.sv$`), no `.adt` log
  (`docs/gaps.md` F4; `crates/engine/src/autosave.rs`).
- **AutoLISP lacks** Visual LISP ActiveX (`vlax-`/`vla-`), DCL dialogs, reactors, an APPLOAD
  dialog with Startup Suite; `.fas`/`.vlx`/`.dll`/`.arx` are not supported (`docs/gaps.md` E1,
  `docs/autolisp.md`).
- **MTEXT**: existing MTEXT cannot be edited again (no DDEDIT/MTEDIT), no fields, no spell check;
  stacked fractions show as placeholders (`docs/gaps.md` F9).
- **No Sheet Set Manager, eTransmit, Traces, Activity Insights; no CUI(x)/workspaces, ~150 of
  ~1,000 system variables in SETVAR** (`docs/gaps.md` F23, U10, U12).
- **macOS Finder file-association for `.dxf` is broken** (#158); Open Recent and File > Open work
  (`docs/gaps.md` U13/P3).
- **No CI runs the test suite on PRs** (`docs/gaps.md` S1) — treat green CI as packaging lints
  only.
- **Claimed but unverified (static reading only — no runtime check was possible):** README's
  interactive-quality claims (AutoComplete, "decades of drafting habit" behaviour), "every
  arrowhead" for dimensions, "associative dimensions that follow geometry", MTEXT right-to-left
  shaping/bidi, and per-language font availability (Chinese/Arabic/Korean need an installed font;
  without one the choice is kept but the UI falls back to English, `docs/control-protocol.md`
  "Interface language"). Code paths and catalogs exist for these; exact behaviour is not verifiable
  without running the app. Anything else absent from code and `docs/gaps.md` should also be treated
  as claimed-but-unverified. Uncertain items: the web build's plot-to-PDF raw-bytes bug (#134,
  `docs/gaps.md` S4) and Windows/Linux runtime robustness (`docs/gaps.md` P2).

## How to operate

**Launch (macOS).** The bundle's GUI binary is `/Applications/CADCraft.app/Contents/MacOS/CADCraft`;
launch it with `open -a "CADCraft"` (CADCraft's own MCP `--launch` uses
`open -a CADCraft --args --control PORT`, `crates/mcp/src/backend.rs:138`). Start flags
(`apps/cadcraft/src/main.rs`): `--control <port>`, `--sample`, `--version`/`-V`, and positional
file paths (each opened; `.dxf` from Finder is broken, prefer this). The bundle contains **no
CLI binary** — get `cadcraft-cli` from the release zip `cadcraft-cli-<ver>-macos-universal.zip`
(`packaging/macos/package.sh`, `README.md` Downloads).

Environment variables that matter: `CADCRAFT_CONTROL_PORT`, `CADCRAFT_CONFIG_DIR` (isolated
profile; empty value disables workspace persistence), `RUST_LOG` (e.g. `cadcraft_engine=debug`,
which logs every command-line message), `CADCRAFT_LOCALE`, `CADCRAFT_SYSTEM_CURSOR=1`,
`CADCRAFT_FONTALT`/`CADCRAFT_FONTFALLBACK`, `CADCRAFT_VSYNC`, `CADCRAFT_NO_NATIVE_MENU`
(`apps/cadcraft/src/main.rs`, `README.md`).

**Settings/state (macOS).** `~/Library/Application Support/CADCraft/` holds `logs/cadcraft.log`
(rotates to `cadcraft.1.log`/`cadcraft.2.log`, 16 MiB cap), `autosave/` (`.sv$` drawings, the
`<_instance>_<uid>.lock` liveness file), `support/` (AutoLISP startup files), and the workspace
layout file (`workspace.json` via craft-ui docking; `apps/cadcraft/src/workspace.rs`,
`docs/control-protocol.md`).

**Document model.** One window, many drawings: each open drawing is a document with its own file
tab and model/paper spaces; `document.switch {index}` switches, `close`/`closeall` close with the
unsaved-changes prompt; the canvas panel is protected from docking; panels (Tool Sets, Layers,
Properties, External References, QuickCalc) dock, float and persist (`crates/engine/src/lib.rs`
`docs: Vec<DocState>`, `crates/ui-egui/src/menus.rs` UI_COMMANDS, `docs/control-protocol.md`
"Panel docking").

**Keyboard shortcuts (from source — do not invent others).** `crates/engine/src/cmd/`:
Cmd+N new, Cmd+O open, Cmd+S save, Cmd+Shift+S save as, Cmd+W close, Cmd+P plot, Cmd+Z/Cmd+Shift+Z
undo/redo, Cmd+A select all, Cmd+C/V/X clipboard, Cmd+Shift+C copy with base point, Cmd+Shift+V
paste as block, Delete clear selection (erase), F3 osnap, F5 isoplane, F7 grid, F8 ortho, F9 snap,
F10 polar, F11 object snap tracking, F12 dynamic input. UI-only (`crates/ui-egui/src/menus.rs`):
Cmd+1 Properties, Cmd+3 Tool Sets, Cmd+8 QuickCalc, Cmd+9 command line, F1 help/command reference,
F2 history, Cmd+Q quit.

**Open/save/export flow.** The Open dialog filters DWG/DXF/DWT and SVG/SVGZ (`services()`,
`apps/cadcraft/src/main.rs`); the Save dialog offers DXF, DWG, DWT, SVG, PNG, PDF with the
suggested name's type first (`filters_for_save`). Save (QSAVE/SAVE =
Cmd+S) writes the drawing's own format/version; SAVEAS `{path, version?: 2000|2004|2007|2010|2013|
2018, binary?: bool}`; `document.bytes {format, version, binary}` returns base64 bytes without
touching the file. EXPORT writes dxf|dwg|svg|png|pdf; PLOT/EXPORTPDF write PDF through the plotter
(format and framing from page setup); PUBLISH plots several sheets. In the web build, saves are
downloads; there is no file system, no DWG (`apps/cadcraft-web/src/main.rs`).

**Headless CLI (what an agent will use most).**
```sh
cadcraft-cli info drawing.dxf                       # JSON summary: counts, extents, layers, styles…
cadcraft-cli convert drawing.dxf out.svg            # dxf|dwg|svg|png|pdf; PNG is 2400×1600
cadcraft-cli convert drawing.dwg detail.png --window 0,0,20000,15000   # frame a rectangle
cadcraft-cli run --sample --script 'CIRCLE 22,3 1\n' --save out.dxf --export out.png
cadcraft-cli run drawing.dxf --cmd 'zoom {"mode":"object"}' --export sel.png
cadcraft-cli commands line                          # command catalog (JSON)
cadcraft-cli sample (bracket|floorplan) out.dxf     # built-in sample drawings
cadcraft-cli mcp --connect 127.0.0.1:7979           # bridge MCP to the running app
```
Framing rules: `convert` fits model-space extents; `run --export` uses the current view only if a
command changed it (`zoom`, `pan`, `view.set`), else extents; `--window x0,y0,x1,y1` shows exactly
that rectangle; `--view extents|current` forces one. Level-of-detail: `cadcraft-cli perf [N|FILE]`
prints timing tables. Note CLI PNG/SVG/PDF always render **model space**
(`apps/cadcraft-cli/src/main.rs`, `crates/io/src/lib.rs`).

**Command-first workflow.** Anything the UI can do is a command: `engine.execute {command, params}`
runs the JSON form with no dialogs; typing (`cmdline.input`) drives the interactive prompt machines
exactly like a user (spaces act as Enter; empty text is Enter). Errors inside a command never take
the app down (panic guard in `crates/engine/src/guard.rs`; `Session::execute` restores the drawing
and reports).

## Working with an AI agent

Legitimate and reliable:

- **Prefer the headless surfaces**: `cadcraft-cli` for one-shot work and verification, MCP
  (headless or bridged) for interactive sessions, the control channel when a human is watching the
  same window. Do not drive the GUI blindly; `ui.screenshot` needs a presented frame, so on a
  locked screen use `ui.render` or the CLI (`docs/control-protocol.md`).
- **Author drawings programmatically**: `engine.execute` per entity (or a `.scr` script /
  `cadcraft-cli run --script`) is far more reliable than pointer simulation. Read back with
  `drawing.inspect`/`query_entities` (handles + geometry) and eyeball with `render`.
- **Prepare/convert inputs**: `convert` turns DXF↔DWG↔SVG/PNG/PDF; SVG from design tools can be
  imported (paths/groups only); generate drawings with `run --save`. Check `info`'s JSON before
  assuming contents.
- **Interpret and repair project files**: DXF is a documented text format and the module that maps
  it is `crates/io/src/dxf_read.rs`/`dxf_write.rs`; CADCraft-specific data (constraints,
  associativity, table flags) travels in xdata under CADCraft's app name (`crates/io/src/dxf_ext.rs`).
  For damaged drawings use AUDIT/RECOVER; crash autosaves are `.sv$` DXF files recovered via
  DRAWINGRECOVERY (`crates/engine/src/cmd/audit.rs`, `crates/engine/src/autosave.rs`).
- **Verify exports before reporting success**: re-open the saved file (`cadcraft-cli info`, or
  `open` + `drawing.inspect`), compare entity counts/extents, and check the `notSaved` report on
  every DWG save. `render`/`convert` to PNG lets you look at the result.
- **Report commands with their exact ids** from `engine.commands`/`cadcraft-cli commands` — ids are
  AutoCAD command names lower-cased (`crates/engine/src/cmd/mod.rs`).

What an agent must NOT do:

- Assume DWG/DXF save round-trips losslessly, or that AutoCAD will open CADCraft output cleanly —
  nobody has verified that (see gaps). Keep an untouched copy of every received file.
- Assume 3D, UCS, viewport-editing, PDF underlays, raster image display, SHX metrics, Visual LISP,
  fields or DDE exist. Check `docs/gaps.md` first.
- Invent shortcuts, menu paths, flags or format names: only what is in
  `CommandSpec` (`crates/engine/src/cmd/`), `UI_COMMANDS` (`crates/ui-egui/src/menus.rs`) and the
  CLI usage string exists.
- Edit `.dwg` bytes or expect a CADCraft-proprietary project format — there is none; the drawing
  *is* the DXF/DWG.
- Trust it for production/concurrent work: pre-alpha, no PR CI, known correctness issues
  (`docs/gaps.md` Stability).

## Verification protocol

1. Work throwaway-first: `cadcraft-cli sample bracket /tmp/t.dxf` or `--metric`, draw, save to a
   scratch path, re-open, inspect, delete. Never test on the only copy of a real drawing.
2. After every save, assert on the result: the `notSaved` field / command-line warning must be
   absent (it appears when DWG drops types it cannot write), and `drawing.inspect`'s `skipped`
   count must be 0 after reading (records the reader could not place; `cadcraft-cli convert` prints
   the same as "records could not be read and are left out"). A silent export is not a verified
   export — `crates/engine/src/cmd/file.rs`, `crates/engine/src/cmd/inquiry.rs:305`, `apps/cadcraft-cli/src/main.rs`.
3. Round-trip discipline: new → edit → save → close → reopen → compare counts/extents/layers; then
   export to PNG/SVG and look at it. For CAD-interchange files, when the user has AutoCAD or
   another viewer, open the file there too — CADCraft cannot yet promise interoperability.
4. Version and back up: keep each session's output under a new name or in version control; the app
   has autosave (desktop, SAVETIME) and Drawing Recovery, but the web build has none, and DWG saves
   can drop unmodelled content.
5. Update CADCraft only between projects (launcher auto-updates), and re-check this skill's claims
   when the version moves — this skill describes v0.8.0.

## Sources & evidence

- Repo: https://github.com/storytold/cadcraft (clean-room, MIT OR Apache-2.0).
- Checked out and inspected at `git rev-parse HEAD` = `714111d528acc86dc6b41e03f9a82cabc1066dca`
  (tag `v0.8.0`, commit date 2026-10-17); installed app `/Applications/CADCraft.app` 0.8.0
  (`CFBundleIdentifier ai.storyteller.cadcraft`). Repo and bundle versions match today; the launcher
  auto-updates, so **verify against your installed version**.
- Key files read: `README.md`, `ROADMAP.md`, `Cargo.toml`, `AGENTS.md`; `docs/gaps.md`,
  `docs/file-format-parity.md`, `docs/control-protocol.md`, `docs/mcp.md`, `docs/autolisp.md`,
  `docs/architecture.md`, `docs/parity-checklist.md`, `docs/localization.md`; `apps/cadcraft-cli/src/main.rs`,
  `apps/cadcraft/src/main.rs`, `apps/cadcraft-web/src/main.rs`; `crates/io/src/lib.rs`,
  `crates/dwg/src/lib.rs`, `crates/engine/src/cmd/{mod,file,exchange,layout,lisp,audit,settings,edit}.rs`,
  `crates/ui-egui/src/menus.rs`, `crates/ui-egui/src/control.rs`, `crates/engine/src/{guard,autosave,audit,sample}.rs`,
  `crates/mcp/`, `packaging/macos/package.sh`.
- Shared libraries consulted: `storytold/craft-libs` (`craft-ui` docking/icons, `craft-docpath`
  path policy for xrefs/data links — `Cargo.toml` workspace dependencies).
- Date: 2026-10-18. No build or run was performed for this document (read-only inspection).
  Cross-check `evidence.md` for the claim-by-claim tiering (implemented / partial / claimed).

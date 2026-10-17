---
name: vectorcraft
description: >-
  VectorCraft is the ArtCraft team's clean-room, open-source vector illustration app (a Rust-native
  take on the Adobe Illustrator workflow) for macOS, Windows, Linux, FreeBSD and the browser.
  Trigger this skill whenever the user mentions VectorCraft (or "the vector app", "the Illustrator
  alternative", a `.vectorcraft`/`.vctemplate`/`.drawcraft` file), asks what it can or cannot do,
  which formats it opens or writes, how to script or automate it, how to prepare or convert assets
  for it, how to verify its output, or how to troubleshoot it — even when they don't name the app
  but describe its job: drawing or editing vector art, SVG/PDF/.ai/Pathfinder/artboard work,
  exporting screens/assets, or driving a vector editor with an agent. Also use it before generating
  SVG/PDF/EPS/PSD inputs for VectorCraft, repairing a native project file, or judging whether
  VectorCraft is the right tool for a task.
---

# VectorCraft

## Overview

VectorCraft is a clean-room, pure-Rust reimplementation of the Adobe Illustrator workflow, built by the ArtCraft team and dual-licensed MIT OR Apache-2.0. It runs natively on macOS, Windows, Linux and FreeBSD, and in browsers via WebAssembly. Per its own assessment (never measured against Illustrator — the clean-room rule forbids running it) it is **alpha**: ~88% feature breadth (348/375 menu items wired, 89/92 tools, 30/57 Photoshop-style raster effects, 4/4 initial 3D types), ~75% depth, ~62% ready for real professional work (~65% for a mainstream illustrator) (`ROADMAP.md:10,32`). Source: GitHub `storytold/vectorcraft`; siblings are PhotoCraft, PdfCraft, FilmCraft etc. under the same `crates/` layout. This skill was written from the v0.12.0 release tag `8bc6532`; the installed app bundle on the authoring Mac also reports 0.12.0 — they match at authoring time, but **verify against your installed version**.

## Capabilities (verified)

**Drawing, editing, style (implemented)**
- Full drawing/path surface: Pen, Pencil, Blob Brush, Eraser, shape tools, Live Corners, Width tool/Width Point Edit, Direct/Group Selection, isolation mode, and the **Dimension tool** (linear, angular, radius and diameter measurements that follow the art they measure; `dimension.create`/`dimension.update`/`dimension.applyToAll` — `crates/engine/src/cmd/dimension.rs`, `crates/tools/src/dimension.rs`, `crates/tools/src/catalog.rs:105`).
- Exact curve booleans: Pathfinder (unite, minusFront, intersect, exclude, divide, trim, merge, crop, outline, minusBack) plus Shape Builder and Live Paint (`crates/pathops`, `crates/engine/src/cmd/pathops.rs`, `crates/engine/src/cmd/shaper.rs`).
- Paint and appearance: swatches (global/spot, colour groups, libraries), gradients, freeform gradients, gradient mesh, patterns, brushes, width profiles, multiple fills/strokes per object, transparency, opacity/clipping masks, graphic styles, and **Object › Intertwine** (`object.intertwine.make/edit/release/arrange` — `crates/engine/src/cmd/intertwine.rs`, `crates/ui-egui/src/menus.rs:2483`). Appearance/transparency self-scored 97% (`ROADMAP.md` feature table).
- Live vector effects and **30 of 57** Photoshop-style raster filters (Film Grain, Halftone Pattern, blurs, distort/pixelate/texture/brush-stroke sets etc.; no Effect Gallery) (`crates/effects`, `crates/engine/src/cmd/rasterfx.rs`; `docs/effects-parity.md` §Summary; `docs/gaps.md` G2).
- Initial live 3D effects: Revolve, Extrude & Bevel, Inflate, Rotate — no materials (`crates/three-d`, `ROADMAP.md:32`, `docs/gaps.md` G3).
- Type: point/area/type-on-a-path, character/paragraph styles, threading, Hebrew/Arabic bidirectional layout; the interface ships in 20 languages (English, German, Japanese, Korean, Vietnamese, Traditional and Simplified Chinese, Spanish, French, Hungarian, Italian, Polish, Brazilian Portuguese, Russian, Swedish, Ukrainian, Finnish, Bulgarian, Greek, Czech; `README.md:238-240`, `docs/localization-parity.md`).
- Symbols (Symbol Options now includes Registration and Export Type — `symbol.options`/`symbol.list`), blends, envelopes, radial/grid/mirror Repeat, perspective grid, Image Trace, graphs (9 types), Variables (text, visibility, image and graph kinds) with dataset CSV import/export (`crates/engine/src/cmd/brushsym.rs`, `crates/engine/src/cmd/perspgrid.rs`, `crates/trace`, `crates/engine/src/cmd/graph.rs`, `crates/engine/src/cmd/variablecmds.rs`).
- Layers, artboards, document setup, guides/grids/smart guides/snapping, undo with unlimited structural sharing (`crates/doc`, `crates/engine/src/cmd/layer.rs`, `crates/engine/src/cmd/layerpanel.rs`, `crates/engine/src/cmd/docsetup.rs`).
- Actions (panel, `crates/ui-egui/src/panels/actions.rs`), Print (shared `craft-print` spooler), Package, Links, Data Recovery, Export for Screens/Asset Export including batch exporting with file-name patterns, per-format folders and built-in export presets (`crates/engine/src/cmd/print.rs`, `package.rs`, `links.rs`, `crates/engine/src/cmd/fileio/screens.rs`).

**Formats — import/open (implemented)** — canonical list in `OPEN_EXTS` (`crates/engine/src/cmd/fileio/mod.rs:647`):
- Native: `.vectorcraft`, legacy `.drawcraft` (JSON; readers keyed by magic bytes) — `crates/format/src/lib.rs`, loaded by `crates/engine/src/cmd/fileio/native.rs`.
- Vector/exchange: `.svg`, `.svgz`, `.pdf`, `.ai`, `.ait`, `.eps` (with PostScript fallback to embedded preview), `.dxf`, `.emf`, `.wmf` (`crates/svg`, `crates/pdf`, `crates/eps`, `crates/cad`, `crates/metafile`, `crates/engine/src/cmd/fileio/{svg,pdfimport,eps,dxfimport,metafile}.rs`).
- Raster as documents: `.png`, `.jpg/.jpeg`, `.gif`, `.webp`, `.tif/.tiff`, `.bmp`, `.psd`/`.psb` (PSD/PSB as their merged image) (`crates/engine/src/cmd/fileio/psdread.rs`, `crates/doc` decode paths).
- Affinity: `.af` (Affinity 3), `.afdesign`, `.afpub`, content-detected `.afphoto`; unsupported features are listed in an import warning, and a file whose native data can't be read opens as its embedded preview (`crates/affinity`, `crates/engine/src/cmd/fileio/affinity.rs`, `crates/affinity/README.md`). Validated against a pinned public corpus of real files (`cargo xtask corpus --affinity`, 51 files per `docs/file-format-parity.md`).
- File → Place additionally accepts `.txt` (as area type) — `PLACE_EXTS`/`TEXT_EXTS` (`crates/engine/src/cmd/fileio/mod.rs:693-723`). PDF-side import gained windowed content scanning and explicit incomplete-content errors in 0.12.0 (`ROADMAP.md:3`, `docs/file-format-parity.md`).
- The Open dialog also imports swatch libraries (`.vcswatches`, `.gpl`, `.ase`, `.acb`), graphic-style libraries (`.vcstyles`), Libraries (`.vclibrary`), flattener/PDF/print presets, shortcut sets (`.kys`), scripts and `.wasm` plug-ins (`crates/engine/src/cmd/fileio/mod.rs:733`).
- Explicitly NOT supported, with hints: `.dwg` and PICT (`.pict/.pct/.pic`) (`crates/engine/src/cmd/fileio/dxf.rs:84`, surfaced by `document.formats` → `unsupported`).

**Formats — save (implemented)** — `SAVE_FORMATS` (`crates/engine/src/cmd/fileio/save.rs:23`):
- `.vectorcraft` (default native, JSON, versions 1–4, optional gzip, atomic write via temp file + rename), `.vctemplate`, `.pdf`, `.svg`, `.svgz`, `.ai` (`document.save`/`file.saveAs`/`file.saveCopy`/`file.saveAsTemplate`).
- `.ai` has two flavours (`aiVersion` in `crates/engine/src/cmd/fileio/native.rs:77`): **PDF-compatible** (default) — a PDF carrying the native document so VectorCraft reopens it editable; Illustrator's own editing data is never written — or **legacy version 7** (`aiVersion: "7"`) — the PostScript form written from the published version 7 specification, keeping layers, groups, compound paths, clipping groups, gradients and editable text, one artboard per file, transparency flattened/omitted, object names and live effects lost (`docs/file-format-parity.md` §The main format: `.ai`, `docs/gaps.md` G9).
- Save as Template additionally writes a **PDF-compatible `.ait`** — `TEMPLATE_FORMATS` (`crates/engine/src/cmd/fileio/save.rs:27`).

**Formats — export (implemented)** — `FORMATS` write:true entries + `export_extensions()` (`crates/engine/src/cmd/fileio/mod.rs:510-690`):
- Vector: `svg`, `svgz` (options: styling, outlineText, embed/link images, decimals, minify, preserveEditing, useArtboards, embedFonts, Tiny 1.2, encodings), `pdf` (one page per artboard, PDF/X presets, live text or outlined), `ai`, `eps`, `dxf`, `emf`, `wmf`.
- Raster: `png`, `png8` (indexed), `jpg` (quality/CMYK/image-map), `webp`, `gif`, `tiff`, `bmp`, `tga`, `psd` (layered, with max-editability option). Scale/ppi/artboard range options throughout.
- Other: `txt` (text stories), `vectorcraft`/`template` (native copy/template).

**Automation surface (implemented — this is VectorCraft's strongest area)**
- **Everything is a command**: every user-visible action has an id, label, menu path, shortcut, params doc and enabled-state; ~750 `cmd!` spec entries across `crates/engine/src/cmd/**`; UI-only commands live in `UI_COMMANDS` (`crates/ui-egui/src/menus.rs:54`). Unknown param keys are rejected with "did you mean" suggestions, so misspellings fail loudly (`docs/mcp.md` §Parameter keys).
- **Actions and batch**: `command.batch` runs several commands as one undo step; `action.batch` plays an action's commands on every readable file in a folder (500-file and 8-folder-level caps, no nesting) or on every data set of the document — the Actions panel's Batch… (`crates/engine/src/cmd/fileio/action_batch.rs`, `crates/engine/src/cmd/fileio/mod.rs:185`).
- **CLI** `vectorcraft-cli`: subcommands `mcp`, `run`, `commands`, `convert`, `info`, `bench`, `perf` (`apps/vectorcraft-cli/src/main.rs:136`). `convert` gained `--ai-version 7|pdf`, `--hidden-objects layer|omit|visible`, `--transparent-images flatten|omit` for the legacy `.ai` writer (`apps/vectorcraft-cli/src/main.rs:3-13`).
- **MCP server** (stdio JSON-RPC 2.0, revision 2025-06-18): `vectorcraft-cli mcp [--connect 127.0.0.1:7979 | --headless] [--automation-read-root DIR] [--automation-write-root DIR]`. **32 tools** (`crates/mcp/src/tools.rs:99`): `command_list`/`command_run`/`command_batch` (incl. `$N.path` result references), `doc_inspect`, `render_preview`, `ui_inspect`/`ui_screenshot`, legacy `list_commands`/`run_command`/`inspect_document`/`inspect_ui`, `select_tool`, `pointer_gesture`, `press_key`, `type_text`, `invoke_menu`, `open_panel`, `screenshot`, `open_file`, `save_file`, `export`, `draw_path`, `draw_shape`, `set_paint`, `add_text` (with a `vertical` option), `apply_effect`, `pathfinder`, `transform`, `create_graph`, `text_wrap`, `undo`, `redo`. Limits: 16 MiB lines, 64-message batches, 256-step `command_batch` with 8 MiB of kept results, 256 MiB replies (`docs/mcp.md` §Protocol, §Tools).
- **Control channel**: `vectorcraft --control <port>` (default convention 7979), one JSON request per line on loopback only, no authentication — enable only while in use (`apps/vectorcraft/src/control_server.rs`, `docs/control-protocol.md:5`). Methods include `engine.execute`/`engine.commands`, `document.inspect`, `ui.inspect`, `ui.menu.list/invoke`, `ui.tool.list/select`, `ui.pointer`/`ui.click`/`ui.drag`/`ui.key`/`ui.text`/`ui.wheel`, `ui.dialog.*`, `ui.screenshot`/`ui.render`, `ui.contextMenu.list`, `ui.sampleScreenColor` (macOS + browsers with EyeDropper), `app.open/save/export/quit` (`docs/control-protocol.md:89-149`). Bounded transport: 5 min idle / 30 s partial line / 60 s reply / 16 connections.
- **File clamping**: `--automation-read-root`/`--automation-write-root` (desktop and CLI) confine every path automation reads/writes; the person at the keyboard is not confined (`crates/engine/src/file_access.rs`, `docs/mcp.md` §Confining file access, `docs/control-protocol.md:56`).
- **WASM plug-ins**: sandboxed `.wasm` object filters and live effects (wasmi interpreter, ABI v1, `plugin.*` commands) (`crates/plugins`, `docs/plugins.md`).
- Scripts for the *reference app* (`.jsx`/`.js`/`.jsxinc`/`.jsxbin`) are only **checked/reported**, never run: `script.check` (`crates/engine/src/cmd/scripts.rs:20`, `docs/mcp.md` §Checking scripts).

**Platforms**
- Desktop + WebAssembly web build of the same UI (`apps/vectorcraft-web`, Trunk; WebGPU with WebGL2 fallback; `?webgl` query flag). The web build reads pen and finger input from Pointer Events (Apple Pencil pressure and touch) and has no TCP control server; open/save/export go through the browser File APIs (`apps/vectorcraft-web/src/main.rs:8-13`).
- FreeBSD tarball and Linux AppImage/Flatpak/deb/rpm packaging exist (`packaging/`, `README.md:289-303`).
- Quality gates: `cargo xtask ci` (fmt, clippy with no-panic lints, tests, layer checks, wasm) (`AGENTS.md`).

## Known limitations and not-implemented

Do not assign VectorCraft these jobs; they are verified absent or partial at v0.12.0 (`docs/gaps.md` ranked list, `ROADMAP.md` "What's missing"):

- **No scripting engine**: no way to run ExtendScript/JS/AppleScript inside the app; `script.check` only reports what a foreign script uses. Actions, Variables and Batch exist as commands/panels, but the scripting surface over the command registry is missing (`docs/gaps.md` G6 — its entry is mid-merge and stale; verified against `variablecmds.rs` and `action_batch.rs`).
- **Writing Illustrator-native data**: Illustrator's private editing data is still never written; a PDF-compatible `.ai` opens in Illustrator 2018 without its layers and groups. The new legacy version 7 save keeps layers/groups/type but has no transparency (flattened or omitted), loses object names/live effects, writes one artboard per file, and **waits for testing by users who hand files back** (G9, `docs/file-format-parity.md`).
- **Reading real-world `.ai`/EPS**: layer structure can come in wrong (e.g. 109 layers instead of 14), guides are missing, large files can be slow, and legacy PostScript type and live effects/brushes/symbols don't come in as live objects (G9). 0.12.0 fixed many fidelity bugs (gradients, placement, overprint, soft masks) and hardens hostile files, but the real-file gap remains.
- **Raster effects**: 27 of 57 Photoshop-style filters are still missing and there is no Effect Gallery browser (G2, `docs/effects-parity.md`).
- **3D and Materials**: only the four initial live effects (Revolve/Extrude & Bevel/Inflate/Rotate); materials and advanced 3D missing (G3).
- **Type**: CJK composition for vertical type missing (vertical type itself only initial); hyphenation/justification options and Optical Margin Alignment missing (G4, `docs/type-parity.md`).
- **Generative AI**: 0% — no picture generation, generative recolor or vector generation (G18).
- **Localization gaps**: Hindi, Arabic (no RTL interface) and Indonesian missing; no catalog has had a native-speaker review (G16, `docs/localization-parity.md`).
- **Known correctness gaps** (G1/G11): the interaction-fidelity pass has never been done (clean-room — no side-by-side with Illustrator); Shape Builder still misses some planar regions and gap detection; a few preferences (~15) are stored but inert (G12).
- **Intertwine** (new in 0.12.0): right-click Bring Forward / Send Backward where 3+ objects overlap is missing (G13).
- **Affinity write**: import only; VectorCraft never writes `.af*` files (`crates/affinity/README.md`).
- **DWG/PICT**: explicitly unsupported (see `document.formats` → `unsupported`).
- **Web build**: no control server, no window capture; saves/exports are browser downloads (`apps/vectorcraft-web/src/main.rs`).
- **macOS packaging**: `/Applications/VectorCraft.app` contains only the GUI app; the CLI/MCP binary is a separate release asset (`docs/mcp.md` §From an installed release).
- **MCP is synchronous stdio**: no progress notifications, no cancellation, no subscriptions, no Streamable HTTP/SSE (`docs/mcp.md` §Not implemented).
- **Claimed but unverified** (I could not build/run the app): "20,000 shapes render in about 27 ms at full retina resolution while the interface stays at 120 fps" (`README.md:152`); the idle-machine 50k-path perf budget run is still pending (last measured at 25k paths — G15). Treat the readiness percentages as the project's self-assessment, not measurements.

## How to operate

**Launch on macOS**
```sh
open -a VectorCraft                                   # plain GUI
open -a VectorCraft --args --control 7979             # + JSON control channel
# or directly, to get stderr (recommended when automating):
/Applications/VectorCraft.app/Contents/MacOS/VectorCraft --control 7979 [file.svg …]
```
- Real flags (verified in `apps/vectorcraft/src/main.rs:635-641`): `--control <port>` (or `VECTORCRAFT_CONTROL_PORT`), `--automation-read-root <dir>`, `--automation-write-root <dir>` (env `VECTORCRAFT_AUTOMATION_READ_ROOT`/`_WRITE_ROOT`), `--in-window-menus` (or `VECTORCRAFT_IN_WINDOW_MENUS=1`), `--version`, plus positional files to open. A bad root or port stops the app before any service starts.
- Agent-safe env: `VECTORCRAFT_NO_PREFS=1` (preferences are neither read nor written, and no default Data Recovery folder is set — use for test runs; `apps/vectorcraft/src/main.rs:209-212`), `VECTORCRAFT_CONFIG_DIR=<dir>` (isolated config profile; also honoured by the control channel — `docs/control-protocol.md:10-17`).
- Port 7979 is shared convention with sibling Craft apps: if the log says it failed to bind, pick another port.

**Document model**: one window, multiple documents as tabs (`crates/ui-egui/src/chrome.rs`, `ui.inspect`→`documents`); each document has artboards, layers/sublayers, objects. Coordinates are **points, y down, origin at the first artboard's top-left; a new document is 612×792** (`crates/mcp/src/server.rs:33`, `crates/engine/src/cmd/newdoc.rs:136`). Before interacting, read state: MCP `doc_inspect`/`inspect_document` + `render_preview`; control `ui.inspect`/`document.inspect`; CLI `vectorcraft-cli info FILE`.

**Core workflow** (app, CLI, MCP and control channel all reach the same commands):
1. Open or create: `file.new`, `document.open`/`app.open`, `file.newFromTemplate`. Readable formats list above.
2. Edit **only through commands** (e.g. `shape.rectangle {x,y,width,height}`, `paint.setFill`, `object.align`, `pathfinder.unite`, `dimension.create`, `object.intertwine.make`). Query ids/params rather than guessing: `engine.commands`, `document.formats`, MCP `command_list`, or `vectorcraft-cli commands`. Batch steps can reference earlier results (CLI: `--cmd … --params …`; MCP `command_batch` with `"$1.id"`; engine `crates/engine/src/steps.rs`).
3. Save in a save format (native/PDF/SVG/SVGZ/AI/template; `.ait` via Save as Template) or export in any writable format. The extension picks the format; `format`/`options` override. A document opened from/once saved as SVG or PDF saves as that format again. For `.ai`, choose `aiVersion` (`pdf` default, `7` legacy PostScript) — see the file-format-parity detail above before promising Illustrator round-trips.
4. Batch-process documents with `action.batch` (folder or data sets) or batch-export with Export for Screens (`document.exportForScreens`, `document.exportPresets.list/save/delete`); both are guarded by the automation roots when you use them from automation.
5. Verify: `render_preview`/`ui.render`/`ui.screenshot` (needs a presented frame), `vectorcraft-cli info` (warnings, artboards, fonts), and the replies' `warnings` arrays — **read them**; they name what a format lost and what import left out.
6. Close: `file.close`/`app.quit` open a `saveChanges` dialog when modified (control: answer with `ui.dialog.confirm` / set `discard`).

**Keyboard shortcuts**: do not assume any. Each command's shortcut lives in the registry and is listed by `engine.commands`/`command_list` and `ui.menu.list`; users can override via Edit → Keyboard Shortcuts and import `.kys` shortcut sets (`crates/ui-egui/src/shortcuts.rs`, `crates/engine/src/cmd/shortcutset.rs`). Query before sending keys.

**Headless batch examples**
```sh
vectorcraft-cli run --in examples/dusk-poster.vectorcraft --cmd object.align --params '{"horizontal":"left"}' --export out.svg
vectorcraft-cli convert in.svg out.pdf --range 1-2
vectorcraft-cli convert in.ai out-ai7.ai --ai-version 7 --outline-text   # legacy version 7 writer
vectorcraft-cli info file.ai
```

## Working with an AI agent

Legitimate agent work around VectorCraft:
- **Automate edits**: prefer `vectorcraft-cli mcp --headless` (fast, no GUI, CPU renderer) for generation and conversion, or `--connect 127.0.0.1:7979` when the user wants to watch. Confine with `--automation-read-root`/`--automation-write-root`. Use `command_list` → `command_run` rather than inventing command ids; use the dedicated draw/export tools for common tasks; note MCP protocol caps (16 MiB lines, 64-message batches) when batching.
- **Prepare inputs**: generate SVG (hand-written or from another tool) for open/place; convert sources (raster → PNG/JPG/TIFF/BMP/WebP/GIF, vector → SVG/PDF/EPS/DXF/EMF/WMF) into supported formats with `vectorcraft-cli convert`; check whether a file will import cleanly with `info` first and report its `warnings`.
- **Generate assets in the examples' style**: `examples/*.vectorcraft` were built entirely through the command API, so they are valid reference inputs (and openable documents).
- **Inspect/repair native files**: `.vectorcraft` is JSON (`{"format":"vectorcraft","version":N,…}`) — parseable, diffable, and safe to patch offline for bulk changes. Preserve unknown keys (newer versions keep them via `Document::extra`), keep embedded `data` blobs intact, and prefer repairing through `document.open` + `document.save` so the version/compression rules apply (`crates/format/src/lib.rs`).
- **Verify output**: reopen exports (`info`, `run --in … --cmd document.inspect`), rasterize (`render_preview`), and compare against source geometry; treat empty `warnings` as the pass signal.

Do **not**:
- drive the GUI blind: inspect first (`ui.inspect`), because dialogs, the save sheet and `fileDialog` state change what commands do (`docs/control-protocol.md:120`); on macOS a command needing a file dialog returns `"cancelled"` unless given a `path`.
- assume Illustrator parity: `.ai` round-trips lose Illustrator structure (the legacy v7 save is new and untested by its own project — do not promise it works for a user's file); EPS may open as a preview image; Affinity/PSD/PSB bring reduced data.
- claim a scripting engine, generative AI, DWG import or native Illustrator editing-data write.
- run `action.batch` over a folder outside an automation root, or assume it is transactional across files (per-file undo groups; files whose import warned are not overwritten unless overrides allow it).
- use Adobe applications or their files to test/compare (project-wide clean-room rule, `AGENTS.md`); never launch Illustrator.
- modify `contributors/contributors.json` (generated) or the brand assets in `docs/brand/` (`AGENTS.md`).

## Verification protocol

Alpha-software discipline — apply all of it:
1. **Throwaway round-trip first**: new document → one edit (draw + paint) → `document.save` to a scratch `.vectorcraft` → reopen with `info`/`doc_inspect` → export to SVG/PDF → reopen the export. Confirm the edit survived and warnings are empty. Do this before touching the user's real file.
2. **Never trust a silent export**: always read `warnings` (format losses) and, on import, `importWarnings`. `vectorcraft-cli convert` refuses `OUT == IN` when reading the input left things out unless `--replace-lossy` is given — honour that signal.
3. **Version and back up per session**: keep a dated copy (or git) of the project before bulk/agent edits; `.vectorcraft` files from newer builds can't be read by older ones (readers reject newer versions — `crates/format/src/lib.rs`). When saving for older VectorCraft versions, `version: 1..4` is available; compression needs version ≥ 3, and version 4 may write large data after the JSON.
4. **Save is atomic but only as far as it got**: a failed save keeps the old file and reports in a dialog; the save fallback writes elsewhere first and copies in when a network/folder refuses the usual steps (`docs/file-format-parity.md`; gaps G8). After any failed save/export, verify the file on disk before assuming state.
5. **New legacy `.ai` v7 output is unproven**: if you must hand a file back to an Illustrator user, prefer the default PDF-compatible `.ai` (plain art, no layer promises) or test the v7 file in a reader you trust first — the project itself says it "waits for testing by users who hand files back" (G9).
6. **Update the app only between projects** (launcher auto-updates): a version jump can change rendering/effects subtly; verify one file after updating instead of discovering it mid-project.
7. **On trouble**: logs are `logs/vectorcraft.log` under the settings folder (`apps/vectorcraft/src/logging.rs:5,31`); unsaved work after a crash lands in Data Recovery next to the preferences (`apps/vectorcraft/src/main.rs:866`, `crates/engine/src/cmd/recovery.rs`).

## Sources & evidence

- Repo: https://github.com/storytold/vectorcraft — inspected at the release tag **v0.12.0**, commit `8bc65329286dc1b84aa392997bb205613c3e96cb` ("Merge pull request #2399 from storytold/pr/release-0.12.0", 2026-10-16), 2026-10-17. Installed bundle: `/Applications/VectorCraft.app` `CFBundleShortVersionString` 0.12.0 (`CFBundleIdentifier` `ai.storyteller.vectorcraft`) — matches the inspected commit at authoring time; still verify against your installed version.
- Key files read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`, `docs/gaps.md`, `docs/target-app-parity.md`, `docs/file-format-parity.md`, `docs/effects-parity.md`, `docs/ui-parity.md`, `docs/localization-parity.md`, `docs/mcp.md`, `docs/control-protocol.md`, `docs/plugins.md`, `apps/vectorcraft/src/main.rs`, `apps/vectorcraft/src/logging.rs`, `apps/vectorcraft-cli/src/main.rs`, `apps/vectorcraft-web/src/main.rs`, `crates/mcp/src/tools.rs`, `crates/format/src/lib.rs`, `crates/engine/src/cmd/fileio/{mod,save,native,action_batch,screens,dxf}.rs`, `crates/engine/src/cmd/{mod,dimension,intertwine,variablecmds,scripts}.rs`, `crates/engine/src/cmd/newdoc.rs`, `crates/tools/src/catalog.rs`, `crates/ui-egui/src/{menus,control,chrome}.rs`, `crates/engine/src/file_access.rs`, `crates/affinity/README.md`.
- Companion file: `evidence.md` (claim → path → tier table).

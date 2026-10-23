---
name: cadcraft
description: >-
  CADCraft is an open-source, clean-room AutoCAD-style 2D CAD and drafting app (pure Rust, egui)
  for macOS, Windows, Linux, FreeBSD and the browser, with DXF/DWG file support and first-class
  agent control over MCP, a JSON control channel and a headless CLI. Trigger this skill whenever
  the user mentions CADCraft (or "the CAD app"), asks what it can or cannot do, which file formats
  it opens or writes, its keyboard shortcuts or commands, wants to draw, edit, dimension, hatch,
  block, xref, lay out, plot or export a drawing, convert/inspect/verify a DXF or DWG, script or
  automate drafting (AutoLISP, .scr scripts, .pgp aliases, MCP, control channel, cadcraft-cli),
  prepare assets for it, or troubleshoot it — and also when they describe the job without naming
  the app ("draw a floor plan", "edit this DXF", "convert this DWG to PDF/PNG", "put dimensions on
  this drawing", "check this drawing opens elsewhere").
---

# CADCraft

Audit basis: this checkout is tag `v0.11.0`, commit `8f988f630dd63ce5d9c997f5ef28a09dd1bdfcde`. The installed `/Applications/CADCraft.app` reports version `0.11.0` (bundle id `ai.storyteller.cadcraft`), and its binary prints `cadcraft 0.11.0 (8f988f630dd63ce5d9c997f5ef28a09dd1bdfcde)`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. This skill has no `references/` directory; all detail is here, with repo-relative evidence paths.

## Overview

CADCraft is an open-source (MIT OR Apache-2.0) CAD and drafting application written in Rust (egui/eframe, wgpu) for macOS, Windows, Linux, FreeBSD and the web; source is GitHub `storytold/cadcraft` (`README.md`, `Cargo.toml`, `LICENSE-MIT`, `LICENSE-APACHE`). It is a clean-room reimplementation of Autodesk AutoCAD aimed at AutoCAD 2027, 2D drafting first (`AGENTS.md` clean-room rules, `docs/target-app-parity.md`). Stage: **pre-alpha** (`ROADMAP.md`). Scale at this tag: ≈154,000 lines of Rust source in 12 library crates and 3 apps, **427 registered engine commands**, menu breadth **283/491 (58%)** (`docs/parity-checklist.md:8`; source line count). The differentiator: every user-visible action is a command — an engine `CommandSpec` or a UI-only entry — and engine commands are reachable identically from the command line, JSON control channel, MCP and CLI (`crates/engine/src/cmd/mod.rs:170`, `crates/ui-egui/src/menus.rs:17`).

**Release delta vs v0.10.0:** no commands, MCP tools, control methods, CLI verbs, formats or shortcuts were added or removed — the counts are unchanged (427 engine commands; 15 MCP tools, 12 headless; 27 control methods, 12 headless; 7 CLI verbs; the same format and shortcut sets). v0.11.0 is a correctness/interoperability release: DWG save now writes the current text style's own handle, DWG read drops orphaned DGN line-style components, DXF accepts foreign handles above 2^48 and caps the four symbol tables, layout plot-window corners and the `ACAD_TABLE` `*T` block origin round-trip, MLEADER sizes stop being multiplied by DIMSCALE, the control server backs off after a failed accept, and AutoLISP `=`/`entsel` behaviour is fixed (`crates/dwg/src/lib.rs`, `crates/io/src/dxf_raw.rs`, `crates/io/src/dxf_write.rs`, `crates/engine/src/cmd/annotate.rs`, `apps/cadcraft/src/control_server.rs`, `crates/engine/src/lisp/builtins.rs`).

## Capabilities (verified)

Everything below is implemented and wired to a command/CLI/MCP/control surface unless marked **partial** or **claimed**; `evidence.md` gives the per-claim tier (implemented / partial / claimed-absent).

### Drawing, editing and precision

- **Draw:** LINE, PLINE (arcs, widths), CIRCLE (center/radius/diameter, 2P, 3P), ARC, RECTANG (fillet/chamfer), POLYGON, ELLIPSE (+arcs), SPLINE, POINT, XLINE, RAY, DONUT, TEXT, MTEXT, plus MLINE, REGION and HELIX (`crates/engine/src/cmd/draw.rs`, `draw2.rs`, `draw2/mline.rs`).
- **Modify:** ERASE, MOVE, COPY, ROTATE, SCALE, MIRROR, STRETCH (window/crossing polygons, fence), OFFSET, TRIM, EXTEND, FILLET, CHAMFER, BREAK, JOIN, EXPLODE, rectangular/polar ARRAY (associative arrays, ARRAYEDIT; ARRAYPATH exists but is not associative), draw order, OVERKILL, LENGTHEN, ALIGN, REVERSE, FLATTEN, CHSPACE; Express Tools NCOPY, BREAKLINE, TXT2MTXT, BURST, MOCORO (`cmd/modify.rs`, `modify2.rs`, `array/`, `overkill.rs`, `draw2/breakline.rs`, `txt2mtxt.rs`, `blocks/burst.rs`).
- **Precision:** 14 object snaps (endpoint, midpoint, center, geometric center, node, quadrant, intersection, extension, insertion, perpendicular, parallel, tangent, nearest, apparent intersection) with deferred tangent/perpendicular for the first point of a line; object snap tracking; polar tracking; ortho (hold Shift to invert while held); grid snap; direct distance entry; `@dx,dy`, `@d<a`, `#x,y`; point modifiers FROM/M2P/TK; typed snap overrides (`crates/engine/src/snap.rs:34`, `snap/tracking.rs`, `pointmod.rs`; `docs/gaps.md` U4 leftovers).
- **Command line and grips:** prompts with clickable keywords, history (F2), AutoComplete, aliases (`.pgp` + ALIASEDIT/REINIT), transparent commands, `.scr` scripts; hot grips cycle Stretch/Move/Rotate/Scale/Mirror with Space, with Base point, Copy, Reference and Undo options (`crates/engine/src/cmd/griphot.rs`, `file/pgp.rs`; AutoComplete and right-click repeat have code and tests, but were not exercised in a live window in this audit).
- **Layers and properties:** Layers palette and Layer Properties Manager, layer tools (isolate/freeze/off/lock/match/previous/merge/delete), saved layer states, Properties palette, linetypes, lineweights, ACI/true colour, transparency, OPTIONS dialog with persisted profiles (`cmd/layer/`, `cmd/props.rs`, `crates/ui-egui/src/options/`; `docs/gaps.md` F20).
- **Annotation:** the DIM* family — linear, aligned, angular, arc, diameter, radius, ordinate, jogged, continue, baseline, QDIM, DIMEDIT/DIMTEDIT, DIMBREAK, DIMINSPECT, DIMSTYLE create/update/override, DIMREASSOCIATE/DIMDISASSOCIATE with associative dimensions; MLEADER plus MLEADEREDIT/ALIGN/COLLECT and MLEADERSTYLE; TABLE with formulas, cell styles, TABLEDIT/TABLEEXPORT, table breaking and CSV data links; TOLERANCE feature-control frames; annotative scaling (SCALELISTEDIT, OBJECTSCALE, ANNOVISIBLE); on-canvas MTEXT editor with formatting toolbar; QuickCalc palette (UI-only, Cmd+8); COMPARE (`cmd/annotate*.rs`, `cmd/mleader*.rs`, `cmd/table/`, `cmd/tolerance.rs`, `cmd/annoscale.rs`, `crates/ui-egui/src/palettes/quickcalc.rs`, `cmd/file/compare.rs`; `docs/gaps.md` F7–F12).
- **Hatch, blocks, xrefs:** pick-point HATCH with islands, HATCHEDIT boundary add/remove, 23-pattern library, solid and gradient fills, user `.pat` files; BLOCK/INSERT/ATTDEF, BATTMAN, ATTSYNC, ATTEDIT, DATAEXTRACTION/EATTEXT, nested blocks, groups, WBLOCK, PURGE; xrefs (XATTACH, -XREF, XBIND, XOPEN, overlays, relative paths); Block Editor for static blocks (BEDIT/BSAVE/BSAVEAS/BCLOSE); REFEDIT/REFSET/REFCLOSE in-place block-reference editing; dynamic blocks read from other files with visibility/lookup/custom-property edits and grips (`cmd/hatch/`, `cmd/blocks/` including `bedit.rs`, `refedit.rs`, `dyngrip.rs`; `docs/gaps.md` F2, F3, F13).
- **Layouts and plotting:** paper-space layouts, polygonal/object/clipped viewports (VPCLIP, VPLAYER), MSPACE/PSPACE, page setups, PLOT dialog, Plot Preview, EXPORTPDF, PUBLISH (one PDF per sheet), PDFBOOK (frame polylines → ISO A-series books), plot styles (CTB/STB) and plotter devices in CADCraft's own JSON formats (`cmd/layout.rs`, `plotters.rs`, `exchange.rs`; `docs/plot-styles.md`, `docs/plotters.md`).
- **Parametric:** geometric and dimensional constraints, AUTOCONSTRAIN, CONSTRAINTBAR, DELCONSTRAINT, PARAMETERS with expressions, re-solve after edits (`crates/constraints`, `cmd/constraints.rs`; `docs/geometry-parity.md`).
- **AutoLISP:** `.lsp` via APPLOAD, `(load)`, drag-and-drop, or the `lisp`/`appload` commands; `(defun c:NAME)`; `acad.lsp`/`acaddoc.lsp`/`S::STARTUP` from the settings `support/` folder; `command`, `entget/entmake/entmod`, `ssget` filters, `get…` input, `vl-*` list/string/catch functions, `tblsearch/tblnext` (`docs/autolisp.md`, `cmd/lisp.rs`, `crates/engine/src/lisp/`). No Visual LISP ActiveX (`vlax-`/`vla-`), DCL dialogs or reactors (`docs/gaps.md` E1).

### Files and formats (exact, from code)

- **Open/read:** DXF ASCII R12–2018 (one reader, no version gating) and binary R13+ (R12 binary is not read); pre-2007 files decode from `$DWGCODEPAGE` (`crates/io/src/lib.rs:57` `read()`, `crates/io/src/dxf_read.rs`, `crates/dxf/src/codepage.rs`). DWG R13–2018 by content magic `AC10xx` through the `acadrust` 0.6.4 bridge (MPL-2.0, unmodified; R13/R14 untested, pre-R13 not read) (`crates/dwg/src/lib.rs:11,16`, `crates/dwg/Cargo.toml`). SVG and gzipped SVGZ (shapes, paths, groups, Inkscape layers; no CSS, `use`, fills/text/images — `use`, text and images are named in a read note, while fills/gradients/patterns are silently ignored) (`crates/io/src/svg_read.rs`; `docs/gaps.md` FF14).
- **Save/native:** DXF is the native path — ASCII or binary, versions 2000–2018 (default: the file's own `$ACADVER`, 2018 for a new drawing; a binary DXF stays binary on QSAVE) (`crates/io/src/lib.rs:79` `write_with()`, `crates/engine/src/cmd/file.rs:376`). DWG write 2000–2018, at least 2004 unless 2000 is explicitly asked for (`crates/io/src/lib.rs`). `.dwt` templates save via SAVEAS; NEW/QNEW accept `.dwt`/`.dxf` templates (`cmd/file.rs` templates; `docs/file-format-parity.md` FF3).
- **Unmodelled content:** DXF writes back unknown entities/objects, foreign xdata, extension dictionaries, reactors, layer states and colour books (#528); through **DWG** the bridge still drops custom-class entities/objects, xdata on table records and blocks, entity colour books and reactors. SAVE/SAVEAS report what the target cannot hold in a `notSaved` field and a command-line message (`crates/engine/src/cmd/file.rs:504-575`; `docs/gaps.md` FF1).
- **Import:** another DXF/DWG's objects via `import` (path or base64, optional `at`/`scale`); user `.lin` linetypes, `.pat` hatch patterns and `.pgp` aliases (`cmd/exchange.rs`, `cmd/props/linfile.rs`, `cmd/hatch/patfile.rs`, `cmd/file/pgp.rs`). SVG/SVGZ is read by `open`, not by `import`; SVG geometry becomes centre-line entities in millimetres with the page's top-left corner at the origin and Y up (`crates/io/src/svg_read.rs` module docs). Stored xref/data-link paths are resolved through `craft-docpath`: only local files or the document's own network share are opened; paths to other computers, device paths and non-file URLs are refused (`crates/engine/src/doc_path.rs`).
- **Export:** SVG; PNG 2400×1600 (framed window or extents); vector PDF with embedded TrueType text subsets, OCG layers, multi-sheet output, hyperlinks and plotted transparency. Commands EXPORT, EXPORTPDF, PUBLISH, PDFBOOK, PLOT, PREVIEW and `cadcraft-cli convert` (`crates/io/src/lib.rs:113` `write_framed()`, `crates/io/src/pdf.rs`, `cmd/exchange.rs`, `cmd/layout.rs`). CLI image/PDF export always renders **model space**; paper-space sheets go through PLOT/EXPORTPDF/PUBLISH.

### Automation surfaces (all over the same command registry)

- **Command registry.** `engine.commands` / `cadcraft-cli commands` return id, label, menu path, shortcut, aliases, parameter docs and enabled state. The CLI/headless catalog is the 427 engine commands; the desktop app's catalog adds 56 `UI_COMMANDS` (483 entries) (`crates/engine/src/cmd/mod.rs:170`, `crates/ui-egui/src/menus.rs:17`, `crates/ui-egui/src/control.rs:225`). Ids are AutoCAD command names lower-cased (`cmd/mod.rs` module docs).
- **MCP server (stdio).** `cadcraft-cli mcp` (headless in-process session) or `cadcraft-cli mcp --connect 127.0.0.1:PORT [--lazy] [--launch]` (bridged to the running app; `--launch` opens CADCraft on macOS). `--lazy`/`--launch` require `--connect`; with an unreachable app the call fails with a remedy, never a silent separate drawing (`docs/mcp.md`, `crates/mcp/src/backend.rs:129-142`, `apps/cadcraft-cli/src/main.rs:575-602`). **15 tools** — 12 headless, plus 3 only when connected to the app:

| Tool | Purpose |
|---|---|
| `command_line {text}` | Type at the prompt like a user; spaces act as Enter, empty text = Enter. |
| `script {text}` | Run a multi-line `.scr`-style script. |
| `execute {command, params}` | Any engine command in JSON form; never opens a dialog. |
| `list_commands {filter?}` | Command catalog; filter matches id, label and aliases. |
| `inspect_drawing {entities?, limit?}` | Counts, extents, layers, styles, blocks, layouts, selection, undo, `skipped`. |
| `query_entities {type?, layer?, selected?, window?, crossing?, limit?, offset?}` | Entity pages with handles and geometry; `count` is all matches. |
| `render {width?, height?, fit?, window?}` | PNG of the drawing, returned as image content. |
| `find_text {contains?, layer?, window?, limit?, offset?}` | TEXT/MTEXT/attributes/multileaders with position, height, rotation, style. |
| `new_drawing {metric?}` | New imperial or metric drawing. |
| `open {path}` | Open a drawing (whatever `open` reads). |
| `save {path?}` | Save DXF/DWG; a `.svg`/`.png`/`.pdf` path exports instead. |
| `cancel` | Escape: cancel the running command or clear selection. |
| `screenshot {path?}` *(app only)* | Window PNG; needs a presented frame. |
| `ui_inspect` *(app only)* | Panels, canvas rect, view, cursor, snap, performance. |
| `ui_click {x, y, space?, button?}` *(app only)* | Click in the drawing area; right button = Enter. |

  Resources: `cadcraft://drawing` and `cadcraft://commands`. Arguments are schema-checked (bad/missing arguments are JSON-RPC `-32602`; a failing tool is an `isError` result) (`crates/mcp/src/tools.rs:7-41,151-199`, `crates/mcp/src/server.rs:118-126`).
- **JSON control channel.** Desktop app with `--control PORT` (or `CADCRAFT_CONTROL_PORT`); one JSON object per line over `127.0.0.1:PORT`. **27 top-level methods** in the app, 12 in headless mode: `cmdline.input/script/key/state`, `engine.execute` (alias `command`), `engine.commands`, `drawing.inspect`, `ui.inspect`, `ui.elements`, `ui.menu.list`/`invoke`, `ui.pointer`, `ui.click`, `ui.move`, `ui.drag`, `ui.key`, `ui.text`, `ui.set`, `ui.resize`, `ui.focus`, `ui.screenshot`, `ui.render`, `app.open`/`save`/`quit`, `control.methods`, `ping` (`crates/ui-egui/src/control.rs:191-219`; `docs/control-protocol.md`). Limits: 16 connections, 64 queued requests, 256 MiB/line, 60 s reply timeout (`state: not-run` = safe to resend, `may-have-run` = inspect first), 10 min idle (`apps/cadcraft/src/control_server.rs:22-46`). Panel docking (`ui.dock`/`ui.dock.reset`, panel ids `toolSets`, `layers`, `properties`, `externalReferences`) and `entities {selected:true}` run through `engine.execute`, not as top-level methods. The app's `engine.execute` also runs UI commands; headless runs engine commands only.
- **CLI `cadcraft-cli`** (not inside `/Applications/CADCraft.app`; it ships in the separate `cadcraft-cli-<ver>-macos-universal.zip`): `info`, `convert`, `run`, `commands`, `mcp`, `perf`, `sample`, plus `--version`/`--help`. Full usage is in `apps/cadcraft-cli/src/main.rs:58-77`; framing flags and PNG size are in the same file.

| Command | What it does |
|---|---|
| `info FILE` | Print `drawing.inspect` JSON (counts, extents, layers, styles, blocks, layouts, skipped). |
| `convert IN OUT.(dxf\|dwg\|svg\|png\|pdf) [--window x0,y0,x1,y1 \| --view extents\|current]` | Format conversion / image export; PNG 2400×1600; model space only. |
| `run [FILE \| --sample \| --metric] [--script TEXT] [--script-file F.scr] [--cmd 'id {json}']… [--save OUT] [--export OUT]` | Headless edit session; `--save` writes a drawing, `--export` an image/PDF. |
| `commands [FILTER]` | JSON command catalog; filter matches id or label (MCP also matches aliases). |
| `mcp [--connect HOST:PORT [--lazy] [--launch]]` | MCP server on stdio. |
| `perf [N \| FILE]` | Timing table on a synthetic N-entity drawing, or a display-list build of a file. |
| `sample (bracket\|floorplan) OUT` | Write a built-in sample drawing. |

- **Scripting and import automation:** `.scr` via SCRIPT or `run --script-file`; AutoLISP via `lisp {code, inputs?}` / `appload {path | name, data}`; `.pgp` via `aliasedit`/`reinit`; `.lin` via `linetype {load, file | text, reload?}`; `.pat` via HATCH's `patternFile`/`patternText` or by typing a `.pat` name at its pattern prompt. `import` brings another DXF/DWG's objects in; `export` returns bytes/base64 when `path` is omitted; `document.bytes {format, version, binary}` returns base64 without touching a file (`cmd/file.rs:175`, `cmd/exchange.rs:30-67`).
- **Read-back commands for agents:** `drawing.inspect` (summary + `skipped{count,sections}`), `entities` (filters/paging/`selected:true`), `texts` (readable text, formatting removed), `shapes` (perimeter/area/centroid/winding/self-intersection for closed polylines, circles, full ellipses, closed splines; arcs/bulges exact), `countlist`/`counttable`, `properties`, `list`, `dist`, `id`, `area` (`cmd/inquiry.rs`, `cmd/inquiry/shapes.rs`).

### Platform notes

- Native macOS universal app (signed, notarized DMG; CLI in a separate signed zip); Windows x64/arm64/x86 MSI (DirectX 12 default, `WGPU_BACKEND` to override); Linux x86_64/aarch64/riscv64 in AppImage/Flatpak/deb/rpm/tar; FreeBSD tar (`README.md` Downloads, `packaging/macos/package.sh`).
- WebAssembly build runs the same UI (WebGPU, `?webgl` WebGL2 fallback, `?cpu` canvas mode, `?sample`, `?host=parent` same-origin postMessage bridge). **No DWG**, no autosave, and saves are browser downloads (`apps/cadcraft-web/src/main.rs:4-9,69-99`; `docs/gaps.md` F4, FF12).
- **16 interface languages**: English, Greek, Ukrainian, Brazilian Portuguese, German, Spanish, Czech, Russian, French, Simplified Chinese, Italian, Korean, Swedish, Arabic, Hungarian, Turkish; live switching via `ui.language` (`auto,en,el,uk,pt-BR,de,es,cs,ru,fr,zh,it,ko,sv,ar,hu,tr`). CJK/Arabic/Hangul need an installed matching font; engine messages and CLI/MCP replies stay English (`crates/ui-egui/src/i18n/mod.rs:173`, `docs/localization.md`, `docs/gaps.md` L1). README's status table still lists 15 and omits Greek.
- 3Dconnexion SpaceMouse motion is compiled for Windows/Linux only; the macOS build has status/buttons but no motion (`apps/cadcraft/src/spacemouse.rs` cfg gates; `docs/hardware-parity.md` still lists 3D mice as absent).

## Known limitations and not-implemented

Read `docs/gaps.md` (the maintained work list, last updated 2026-10-16) before promising anything. `docs/roadmap.md`'s alpha-gate table predates the object-snap-tracking, REFEDIT and plot-style landings and is stale row by row; use `docs/gaps.md` and the code. The high-impact limits for an agent:

- **Saving DWG is lossy.** The acadrust bridge drops custom-class entities/objects, xdata on table records and blocks, entity colour books and reactors; DXF keeps unmodelled content raw. Always check the `notSaved` report on every DWG save (`docs/gaps.md` row 1, FF1; `docs/file-format-parity.md`).
- **No real-file corpus and no AutoCAD verification.** The file tests are synthetic; no CADCraft output has been checked in AutoCAD black-box, and a real-file corpus is still an alpha blocker. A 10 MB DWG took ~2 min to fail (#57); limits stop runaway conversions, throughput remains (`docs/file-format-parity.md` Tests; `docs/gaps.md` FF5/FF6).
- **No 3D at all.** No UCS, 3D views, orbit, solids, surfaces, meshes, sections, visual styles, materials, lights or rendering (ROADMAP puts 3D depth at 2%); `3DORBIT` is registered only to say "not available yet", and `ATTACH`/`SHARE` likewise (`docs/gaps.md` F24, `crates/engine/src/cmd/exchange.rs:55-70`). The README tagline says "2D and 3D"; the 3D half is not implemented.
- **Curve geometry is tessellated.** Ellipse/spline intersections, offsets, trims, closest points and snaps are approximations; polyline offsets ignore bulges; tolerances are absolute (one `EPS`), and survey-scale coordinates are untested (`docs/geometry-parity.md`; `docs/gaps.md` row 3).
- **XCLIP is missing; xrefs cannot be edited in place.** XOPEN opens the source; REFEDIT edits block references only. No dynamic-block authoring (parameters/actions); references from other files can change visibility states, lookups, distances and positions through custom properties and grips (`blocks.reference.set`, `blocks.reference.grip`) (`docs/gaps.md` F2, F3).
- **SHX fonts are not parsed.** SHX-style text draws with CADCraft's stroke font or `FONTALT`, so metrics differ from AutoCAD; SHX shapes in linetypes are skipped (`README.md` Fonts; `docs/gaps.md` FF8/FF9).
- **No PDF import/underlays, no raster image attach/display** (IMAGE entities and definitions round-trip but pixels never load), no DWF/DGN/WMF/EPS/ACIS/STL exchange, no DWS standards, no system printers (`docs/gaps.md` FF10/FF11, H3; `docs/file-format-parity.md` "Other formats").
- **Binary plot files are unread.** `.ctb`/`.stb`/`.pc3`/`.pmp` must be recreated in CADCraft's JSON formats; plot styles and device papers work otherwise (`docs/gaps.md` F14, FF9).
- **MTEXT editing is partial.** `TEXTEDIT` (alias `DDEDIT`) replaces TEXT/MTEXT/ATTDEF/dimension text by handle, but there is no in-place formatting editor for an existing MTEXT, no fields (FIELD), no spell check, and stacked fractions show as placeholders (`crates/engine/src/cmd/modify2.rs:81`; `docs/gaps.md` F9 — its "no DDEDIT" wording is stale).
- **No autosave in the web build.** Desktop autosave writes DXF `.sv$` files (SAVETIME default 10 min, 0 off, max 600), Drawing Recovery lists them, and AUDITCTL=1 makes AUDIT write an `.adt` log; the web build has none (`crates/engine/src/autosave.rs:25-29`, `cmd/audit.rs:13-23,143`; `docs/gaps.md` F4).
- **SETVAR covers ~150 of ~1,000 variables**; no Sheet Set Manager, eTransmit, Traces, Markup Import, CUI(x) or workspaces (`docs/gaps.md` F23, U10, U12). No DIMSTYLE manager dialog, and DIMSTYLE variables are partial (`docs/gaps.md` F7).
- **macOS Finder file-association for `.dxf` is broken (#158)**; open positionally or via File > Open (`docs/gaps.md` P3/U13).
- **No PR job runs the project's `cargo xtask ci` gate** (fmt, clippy, tests, assets, layers, wasm). CI has packaging lint, release builds, Nix/FreeBSD/Windows ARM builds, and (new at v0.11.0) SonarCloud static analysis plus CodeRabbit review (`docs/gaps.md` S1; `.github/workflows/`).
- **Web PLOT may show raw PDF bytes (#134)**; Windows/Linux get little runtime testing (P1/P2; `docs/gaps.md` S4).
- **Claimed but unverified here (static reading only):** README's interactive-feel claims (AutoComplete, right-click repeat), "every arrowhead", associative-dimension behaviour, MTEXT bidi/OpenType shaping for Arabic-script text, per-language font availability, and SpaceMouse behaviour on Windows/Linux. Anything absent from both code and `docs/gaps.md` should also be treated as claimed-but-unverified.

## How to operate

**Launch (macOS).** GUI binary is inside `/Applications/CADCraft.app` (`Contents/MacOS/CADCraft`); launch with `open -a "CADCraft"`. Start flags (`apps/cadcraft/src/main.rs:236-244`): `--control <port>` (bare `--control` reuses `CADCRAFT_CONTROL_PORT`), `--sample`, `--version`/`-V`, and positional drawing paths (each opens; prefer this over Finder drag, see P3). CADCraft's own MCP `--launch` runs `open -a CADCraft --args --control PORT` (`crates/mcp/src/backend.rs:134-142`). **The bundle contains no CLI binary** — install `cadcraft-cli` from `cadcraft-cli-<ver>-macos-universal.zip` (`packaging/macos/package.sh:44,104`, `README.md` Downloads).

Environment variables that matter: `CADCRAFT_CONTROL_PORT`, `CADCRAFT_CONFIG_DIR` (isolated profile; an explicitly empty value disables workspace persistence), `CADCRAFT_LOCALE`, `CADCRAFT_SYSTEM_CURSOR=1`, `CADCRAFT_FONTALT`/`CADCRAFT_FONTFALLBACK`, `CADCRAFT_VSYNC`, `CADCRAFT_NO_NATIVE_MENU` (macOS), `WGPU_BACKEND` (Windows troubleshooting), `RUST_LOG` (`cadcraft_engine=debug` logs every command-line message) (`apps/cadcraft/src/main.rs`, `README.md`).

**Settings/state (macOS).** `~/Library/Application Support/CADCraft/` holds `logs/cadcraft.log` (two rotations, 16 MiB cap), `autosave/` (`.sv$` DXF drawings), `support/` (AutoLISP startup files), and `workspace.json` (panel docking/UI choices; 64 KiB cap, versioned; invalid files are reported and left untouched) (`apps/cadcraft/src/main.rs:331-341`, `apps/cadcraft/src/workspace.rs`, `docs/control-protocol.md`).

**Document model.** One window, many drawings: each open drawing is a document with its own file tab and model/paper spaces; `document.switch {index}` switches, `close {index}`/`closeall` close them. Tool Sets, Layers, Properties and External References dock, float and persist; QuickCalc opens as a floating palette (Cmd+8); the canvas is protected (`crates/engine/src/cmd/file.rs`, `crates/ui-egui/src/menus.rs`, `docs/control-protocol.md` "Panel docking").

**Keyboard shortcuts (from source — do not invent others).** Engine `.key()` values: Cmd+N new, Cmd+O open, Cmd+S save, Cmd+Shift+S save as, Cmd+W close, Cmd+P plot, Cmd+Z/Cmd+Shift+Z undo/redo, Cmd+C/V/X clipboard, Cmd+Shift+C copy with base point, Cmd+Shift+V paste as block, Cmd+A select all, Cmd+Shift+A PICKSTYLE, Delete clear selection, F3 osnap, F5 isoplane, F7 grid, F8 ortho, F9 snap, F10 polar, F11 object snap tracking, F12 dynamic input (`crates/engine/src/cmd/settings.rs`, `edit.rs`, `file.rs`, `layout.rs`, `groups/pick.rs`). UI-only (`crates/ui-egui/src/menus.rs`): Cmd+1 Properties, Cmd+3 Tool Sets, Cmd+8 QuickCalc, Cmd+9 command line, F1 command reference, F2 command history, Cmd+Q quit.

**Open/save/export flow.** The Open dialog filters DWG/DXF/DWT and SVG/SVGZ (`apps/cadcraft/src/main.rs:129-136`); the Save dialog offers DXF, DWG, DWT, SVG, PNG, PDF with the suggested name's type first (`filters_for_save`). QSAVE/SAVE (Cmd+S) writes the drawing's own format/version; SAVEAS `{path, version?: 2000|2004|2007|2010|2013|2018, binary?: bool}`; the macOS save panel cannot pick a version per file — use SAVEAS JSON or File ▸ Default Save Format/Version (`docs/gaps.md` FF3). `document.bytes {format, version, binary}` returns base64 without touching a file. EXPORT writes dxf|dwg|svg|png|pdf; PLOT/EXPORTPDF write PDF through the plotter (paper-space sheets, page setups); PUBLISH one PDF per sheet; PDFBOOK builds ISO A-series books from frame polylines. In the web build, saves are downloads; there is no file system and no DWG (`apps/cadcraft-web/src/main.rs`).

**Headless CLI (what an agent will use most).**
```sh
cadcraft-cli info drawing.dxf                       # JSON summary: counts, extents, layers, styles, skipped…
cadcraft-cli convert drawing.dxf out.svg            # dxf|dwg|svg|png|pdf; PNG is 2400×1600
cadcraft-cli convert drawing.dwg detail.png --window 0,0,20000,15000   # frame a rectangle
cadcraft-cli run --sample --script 'CIRCLE 22,3 1\n' --save out.dxf --export out.png
cadcraft-cli run drawing.dxf --script-file setup.scr --save out.dxf
cadcraft-cli run drawing.dxf --cmd 'zoom {"mode":"object"}' --export sel.png
cadcraft-cli commands dim                           # command catalog (JSON), filtered
cadcraft-cli sample floorplan out.dxf               # built-in sample drawings
cadcraft-cli mcp --connect 127.0.0.1:7979           # bridge MCP to the running app
```
Framing rules: `convert` fits model-space extents; `run --export` uses the current view only if a command changed it (`zoom`, `pan`, `view.set`), else extents; `--window x0,y0,x1,y1` shows exactly that rectangle; `--view extents|current` forces one. CLI PNG/SVG/PDF always render **model space** (`apps/cadcraft-cli/src/main.rs`, `crates/io/src/lib.rs`). For paper-space output use PLOT/EXPORTPDF/PUBLISH, not `convert`.

**Command-first workflow.** Anything the UI can do is a command: `engine.execute {command, params}` runs the JSON form with no dialogs; typing (`cmdline.input`) drives the interactive prompt machines exactly like a user (spaces act as Enter except at text prompts; empty text is Enter). A refused command-line line still replies `ok: true` — check the `error` field. Errors inside a command never take the app down (panic guard in `crates/engine/src/guard.rs`; `Session::execute` restores the drawing, `crates/engine/src/lib.rs:887-913`). UI commands (`ui.dock`, `ui.language`, `ui.saveformat`, …) exist only in the app catalog; headless returns "unknown command" for them.

## Working with an AI agent

Legitimate and reliable:

- **Prefer the headless surfaces**: `cadcraft-cli` for one-shot work and verification, MCP (headless or bridged) for interactive sessions, the control channel when a human is watching the same window. Do not drive the GUI blindly; `ui.screenshot` needs a presented frame, so on a locked screen use `ui.render`/`render` or the CLI.
- **Author drawings programmatically**: `engine.execute` per entity, or a `.scr` script / `cadcraft-cli run --script-file`, is far more reliable than pointer simulation. Read back with `drawing.inspect`/`entities` (handles + geometry; `selected:true` reads the current selection), `texts` for room labels/titles, `shapes` for areas/centroids/self-intersections, and eyeball with `render`.
- **Prepare/convert inputs**: `convert` turns DXF/DWG/SVG to DXF/DWG/SVG/PNG/PDF; SVG from design tools imports as paths/groups in millimetres, page top-left at the origin, Y up (fills/gradients/patterns are silently ignored; `use`, text and images are noted on open); generate drawings with `run --save`. Check `info`'s JSON before assuming contents.
- **Interpret and repair project files**: DXF is a documented text format mapped by `crates/io/src/dxf_read.rs`/`dxf_write.rs`; CADCraft-specific data (constraints, associativity, table flags, hatch gradients, plot styles, layer states, handles, multileader style) travels under the `CADCRAFT` xdata app name and `CADCRAFT_*` dictionary entries (`crates/io/src/dxf_ext.rs`). For damaged drawings use AUDIT/RECOVER; crash autosaves are `.sv$` DXF files listed by DRAWINGRECOVERY (`cmd/audit.rs`, `crates/engine/src/autosave.rs`).
- **Verify exports before reporting success**: re-open the saved file (`cadcraft-cli info`, or `open` + `drawing.inspect`), compare entity counts/extents/layers, check `open`'s `warnings`, `drawing.inspect.skipped.count`, and the `notSaved` report on every DWG save. Render to PNG and look at it.
- **Report commands with their exact ids** from `engine.commands`/`cadcraft-cli commands`; ids are AutoCAD command names lower-cased. The app catalog's `ui.*` entries are not engine commands.
- **Counts to expect**: 427 engine commands; 15 MCP tools (12 headless + 3 app-only); 27 control methods app / 12 headless; 7 CLI verbs; 56 UI-only commands.

What an agent must NOT do:

- Assume DWG saves round-trip losslessly, or that AutoCAD will open CADCraft output cleanly — nobody has verified that (see gaps). Keep an untouched copy of every received file; prefer DXF when the user's tooling allows it.
- Assume 3D/UCS, PDF underlays, raster image display, SHX metrics, dynamic-block authoring, XCLIP, xref in-place editing, Visual LISP/DCL/reactors, fields, spell check, sheet sets, eTransmit, Traces or CUI exist. Check `docs/gaps.md` first.
- Invent shortcuts, menu paths, flags or format names: only what is in `CommandSpec` (`crates/engine/src/cmd/`), `UI_COMMANDS` (`crates/ui-egui/src/menus.rs`) and the CLI usage string exists.
- Edit `.dwg` bytes or expect a CADCraft-proprietary project format — there is none; the drawing *is* the DXF/DWG.
- Send UI-only commands to a headless MCP/CLI session, or rely on `screenshot` without a presented frame.
- Call `app.quit` before saving: it quits without the unsaved-changes prompt.
- Trust it for production/concurrent work: pre-alpha, no PR test CI, known correctness issues (`docs/gaps.md` Stability).

## Verification protocol

1. Work throwaway-first: `cadcraft-cli sample bracket scratch/t.dxf` (or `run --metric`), draw, save to a scratch path, re-open, inspect, delete. Never test on the only copy of a real drawing.
2. After every save, assert on the result: the `notSaved` field / command-line warning must be absent (it appears when DWG drops content). After reading, `drawing.inspect.skipped.count` must be 0 for DXF, and `open`'s `warnings` must be empty for DWG/SVG; any entry means records or objects were left out. A silent export is not a verified export — `crates/engine/src/cmd/file.rs`, `crates/engine/src/cmd/inquiry.rs:408`, `apps/cadcraft-cli/src/main.rs`.
3. Round-trip discipline: new → edit → save → close → reopen → compare counts/extents/layers; then export to PNG/SVG/PDF and look at it. For CAD-interchange files, when the user has AutoCAD or another viewer, open the file there too — CADCraft cannot yet promise interoperability.
4. Version and back up: keep each session's output under a new name or in version control; the desktop app has SAVETIME autosave, Drawing Recovery, AUDIT and RECOVER, but the web build has none, and DWG saves can drop unmodelled content.
5. Update CADCraft only between projects (launcher auto-updates), and re-check this skill's claims when the version moves — this skill describes v0.11.0.

## Sources & evidence

- Repo: https://github.com/storytold/cadcraft (clean-room, MIT OR Apache-2.0).
- Inspected at tag `v0.11.0`, commit `8f988f630dd63ce5d9c997f5ef28a09dd1bdfcde` ("Release 0.11.0"), on 2026-10-23. The installed GUI binary prints `cadcraft 0.11.0 (8f988f630dd63ce5d9c997f5ef28a09dd1bdfcde)`. The launcher auto-updates, so **verify against your installed version**.
- Key files read: `README.md`, `ROADMAP.md`, `Cargo.toml`, `AGENTS.md`; `docs/gaps.md`, `docs/file-format-parity.md`, `docs/control-protocol.md`, `docs/mcp.md`, `docs/autolisp.md`, `docs/customization.md`, `docs/architecture.md`, `docs/parity-checklist.md`, `docs/localization.md`, `docs/roadmap.md`, `docs/geometry-parity.md`, `docs/hardware-parity.md`; `apps/cadcraft-cli/src/main.rs`, `apps/cadcraft/src/main.rs`, `apps/cadcraft-web/src/main.rs`; `crates/io/src/lib.rs`, `crates/dwg/src/lib.rs`, `crates/engine/src/cmd/{mod,file,exchange,layout,lisp,audit,settings,edit,inquiry,modify2}.rs`, `crates/engine/src/cmd/file/pgp.rs`, `crates/engine/src/cmd/props/linfile.rs`, `crates/engine/src/cmd/hatch/patfile.rs`, `crates/engine/src/cmd/blocks/{bedit,refedit}.rs`, `crates/engine/src/snap.rs`, `crates/engine/src/snap/tracking.rs`, `crates/engine/src/pointmod.rs`, `crates/engine/src/cmd/griphot.rs`, `crates/ui-egui/src/menus.rs`, `crates/ui-egui/src/control.rs`, `crates/ui-egui/src/i18n/mod.rs`, `crates/mcp/src/tools.rs`, `crates/mcp/src/backend.rs`, `crates/engine/src/autosave.rs`, `packaging/macos/package.sh`.
- Shared libraries consulted: `storytold/craft-libs`, chiefly `craft-docpath` (lexical path policy: a path stored in a drawing may open only a local file or one on the document's own share; remote/device/non-file URLs are refused; re-exported by `crates/engine/src/doc_path.rs`).
- Read-only inspection: no build, no GUI launch, no drawing modified. The only execution was `/Applications/CADCraft.app/Contents/MacOS/CADCraft --version`. Cross-check `evidence.md` for claim-by-claim tiering (implemented / partial / claimed).

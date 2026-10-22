---
name: deckcraft
description: >-
  DeckCraft is the open-source, clean-room PowerPoint-compatible presentation app for macOS
  (also Windows, Linux, FreeBSD and the web): slides, masters, shapes, 3-D, text, tables, charts,
  SmartArt, media, transitions, animations, slide shows, `.pptx`/`.deckcraft` files, PDF/PNG/
  JPEG/GIF export, a JSON control channel, a CLI and an MCP server. Trigger this skill whenever
  the user mentions DeckCraft, `.deckcraft`, or asks to build, edit, inspect, convert, render,
  present, export or troubleshoot a slide deck or presentation — especially when they want it
  automated or scripted, want assets prepared for it, or need its output verified. Also trigger
  when the user describes the job without naming the app ("make a deck", "turn this outline into
  slides", "export these slides to PDF", "why did my PPTX lose its animations?", "drive a
  presentation app with an agent").
---

## Overview

DeckCraft is an open-source (MIT OR Apache-2.0), clean-room reimplementation of Microsoft PowerPoint, written in pure Rust: it builds decks with masters/layouts, shapes, text, tables, charts, SmartArt and media; presents them full screen; and exchanges PowerPoint `.pptx` plus its own `.deckcraft` format (README.md:13; Cargo.toml:7,11). It is **alpha**: v0.9.0, claiming **84% feature breadth** (92% of core features) and **~55% ready for real work** by its own measurement (ROADMAP.md:3,11-17). Native builds target macOS, Windows, Linux (x64/arm64/riscv64) and FreeBSD, plus a WebAssembly build for browsers (README.md:200-252). Source: `github.com/storytold/deckcraft` (Cargo.toml:11).

**Audit basis:** this checkout is tag `v0.9.0`, commit `fe510bdac68118f2c9a714e69d0ff572e3f9a0c7`. The installed `/Applications/DeckCraft.app` reports version `0.9.0` with `DeckCraftBuildCommit` equal to that commit, and its binary prints `deckcraft 0.9.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since: the code moves quickly and some `docs/` pages lag it (see “Sources & evidence”). Deep detail — every command family, shortcut, control method, MCP tool, format option and runtime path — is in `references/commands-and-formats.md`.

## Capabilities (verified)

### Deck structure and design
- **Slides, masters and layouts.** Eleven layout kinds (Title, Title and Content, Section Header, Two Content, Comparison, Title Only, Blank, Content with Caption, Picture with Caption, Title and Vertical Text, Vertical Title and Text) plus `Custom` (`crates/model/src/lib.rs:679-692`). Slide masters, notes master, handout master, placeholder inheritance, sections, notes, comments, headers/footers, custom shows and custom slide sizes are modelled (`crates/model/src/lib.rs`; `crates/engine/src/cmd/slide.rs:13-58`; `crates/engine/src/cmd/design.rs`; `crates/engine/src/cmd/review.rs`).
- **Themes.** Eight built-in themes — DeckCraft, Harbor, Ember, Meadow, Nocturne, Paper, Coral Reef, Slate — each with colour, font and effect schemes and four variants; Browse for Themes imports `.thmx`, `.pptx` or `.potx` (`crates/model/src/theme.rs:155-260`; `crates/engine/src/cmd/design.rs:19-23,148-174`; `crates/pptx/src/lib.rs:71-73`).
- **Starter decks.** Six original starters — Briefing, Lesson, Pitch, Field Notes, Quarterly, Evening Talk — via `file.new {template}` (`crates/engine/src/templates.rs:37-168`; `crates/engine/src/cmd/file.rs:96-105`).
- **Shapes.** 183 shape/connector presets in the catalogue, with adjust handles, glued connectors, freeform/curve/scribble tools, merge operations (union, combine, fragment, intersect, subtract), gradient/picture/pattern fills, dashes, arrowheads, shadows, glow, soft edges and reflections (`crates/geom/src/preset.rs:148+`; `crates/engine/src/cmd/shape.rs`; `crates/engine/src/cmd/merge.rs`; `crates/engine/src/cmd/picture_style.rs`).
- **3-D (new in this release).** Format Shape ▸ 3-D Format/Rotation: 28 camera presets, 12 bevels, 12 materials, light rigs, X/Y/Z rotation, depth and contour. Kept as raw `a:scene3d`/`a:sp3d` XML on the model and round-tripped; edited through `shape.effects {bevel, threeD}` and the Format Shape pane (`crates/engine/src/cmd/three_d.rs:1-80`; `crates/engine/src/cmd/shape.rs:806-854`; `crates/ui-egui/src/panes.rs:774-798`). Bevels, cameras, rotations and face lighting render as approximations; extrusion sides draw under turned cameras (`docs/gaps.md:233-245`).
- **Text.** In-place editing with DrawingML run/paragraph properties, bullets and numbering, columns, autofit (none/shrink/resize), vertical and RTL text, fields, hyperlinks, tab stops, line spacing and text warps (`crates/engine/src/cmd/text.rs`; `crates/engine/src/cmd/format.rs`; `crates/model/src/text.rs`; `crates/geom/src/warp.rs`).
- **Tables.** Styled tables with cell merges, diagonal borders, row/column insert/delete, distribution, heights and borders (`crates/engine/src/cmd/table.rs`; `crates/pptx/tests/corpus_charts.rs`).

### Content
- **Pictures.** PNG, JPEG, GIF (including animated), WebP, BMP and TIFF are decoded; EMF/WMF are drawn through `deckcraft-metafile` when they arrive inside a deck (`crates/render/src/images.rs:119-134`; `crates/metafile/src/lib.rs`; `docs/file-format-parity.md:39-42`). Crop, brightness/contrast, duotone, alpha and artistic effects are modelled (`crates/engine/src/cmd/picture_style.rs`; `crates/engine/src/cmd/artistic.rs`).
- **Charts.** 28 chart types, including the seven Office-2016 `chartEx` types (waterfall, funnel, histogram, Pareto, box & whisker, treemap, sunburst), plus radar, stock, region map (kept and drawn, not offered in the menus) and combo (`crates/model/src/chart.rs:9-41`). Insert with `insert.chart`, edit data with `chart.data`, change type with `chart.type`; six trendline kinds round-trip and are drawn with forecast and equation/R² labels; an unchanged chart's embedded workbook survives save, native and PPTX round-trips (`crates/engine/src/cmd/insert.rs:66-72,106-114`; `docs/gaps.md:166-186`).
- **SmartArt.** A SmartArt graphic is a group whose outline is edited in a Text Pane; 45 layouts and 9 styles, with Add Shape, Promote, Demote, Remove and layout switching; saved to `.pptx` as a real diagram (`crates/engine/src/cmd/smartart.rs:26-74`; `crates/pptx/src/dgm.rs`).
- **Media.** Audio: MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg Vorbis and Opus. Video: H.264, HEVC, VP9 and AV1 in MP4/MOV and WebM/Matroska, software-decoded in pure Rust (`crates/media/src/lib.rs:3-10`; `crates/engine/src/cmd/insert.rs:74-75`).
- **Other insertables.** Lucide 1.56.0 stroke icons as custom shapes (`insert.icon`), WordArt, symbols, date/time fields, slide numbers, photo albums, and an equation dialog that inserts pretty-printed text (not OMML) (`crates/engine/src/icons.rs:3`; `crates/engine/src/cmd/insert.rs:26-114`; `crates/ui-egui/src/dialogs.rs:1712-1719`).

### Presenting
- **48 transitions plus “None”** (49 rows), including Morph, each with effect options; transitions were measured frame-by-frame against PowerPoint video export (`crates/model/src/anim.rs:52-101`; `docs/animation-parity.md:9-40`).
- **Animations.** 106 picker entries: 64 non-path effects (24 entrance, 23 exit, 17 emphasis), 39 motion paths and 3 media controls; start modes, by-paragraph builds, triggers, repeat and bounce end (`crates/model/src/anim.rs:320-437`; `crates/engine/src/cmd/animation.rs`; `docs/animation-parity.md:42-57`).
- **Slide show.** Full-screen show, presenter view in a second window, pen and laser pointer, black/white screens, See All Slides, zoom, hyperlinks/actions, custom shows, rehearse timings and media playback (`crates/ui-egui/src/show.rs:1-60,425-519`; `docs/slideshow-parity.md`). A `.ppsx` handed to the app by the system starts its slide show, as in PowerPoint (`apps/deckcraft/src/main.rs:139`; `docs/file-format-parity.md:19`).
- **Views.** Normal, Outline, Slide Sorter, Notes Page and Reading; slide/notes/handout master views (`crates/ui-egui/src/lib.rs:359-415`).

### Files
- **Native `.deckcraft`:** a zip with a stored `mimetype`, `presentation.json`, `media/<id>` and (new in this release) bounded `chart-parts/<index>` binary entries holding retained chart payloads; format version 1; readers ignore unknown fields, and legacy `.slidecraft` files still open (`crates/format/src/lib.rs:1-29,70,175`). Chart workbooks and retained chart parts now survive `.deckcraft` save/reopen (`crates/engine/tests/chart_native.rs`).
- **PowerPoint `.pptx`:** read and write; `.potx` and `.ppsx` are written with their correct content types, and a handed-over `.ppsx` starts the show (`crates/pptx/src/lib.rs:76-86`). Unknown parts are kept as `Opaque`/raw XML where the model does not understand them (`docs/architecture.md:63-69`). Embedded fonts are read and written; MicroType Express subsets are kept but not drawn (`docs/file-format-parity.md:66`).
- **Outline text:** `.txt` and `.md` import (Markdown headings become slides; `slide.fromOutline`) and `.txt`/`.md` export including table cell text (`crates/engine/src/cmd/file.rs:165-168`; `crates/engine/src/cmd/slide.rs:59`; `crates/format/src/lib.rs:638,1062`).
- **PDF:** slides, notes pages or handouts (1/2/3/4/6/9 per page), Letter/A4/Legal/A3, portrait/landscape, hidden-slide and slide-range options, selectable invisible text layer and bookmarks; slide artwork itself is a raster image (`crates/pdf/src/lib.rs:67-105`; `crates/engine/src/cmd/file.rs:308-330`).
- **Images and GIF:** PNG/JPEG per slide (one, `slide`, or `all`; `transparentBackground` leaves the slide background out; files carry DPI metadata) and an animated GIF of the deck (one frame per slide, per-frame 256-colour palette, 16-3840 px wide, 0.1-600 s per slide, loop or play once, slide range, hidden slides skipped) (`crates/engine/src/cmd/file.rs:518-568`; `crates/engine/src/gif_export.rs:18-35`).
- **AutoRecover:** unsaved presentations are written to a recovery folder and reopened at the next start; saving or closing removes the entry (`crates/engine/src/recovery.rs`; `apps/deckcraft/src/main.rs:244-247`).

### Automation
- **320 commands**, each with id, label, ribbon/menu place, optional shortcut, parameter docs, enabled check and run function, registered in 28 modules (`crates/engine/src/cmd/mod.rs:44-58,148-192`; count of `cmd!` blocks = 320 = 229 journaled+undoable, 55 `noundo`, 36 `query`; ids asserted unique). `Session::execute` is the single dispatch path used by the UI, CLI, control channel and MCP (`crates/engine/src/lib.rs:581`).
- **`deckcraft-cli`:** `info`, `render` (now with `--transparent`), `render-transition`, `convert`, `run`, `commands`, `describe`, `app`, `mcp`, `bench` (now reports peak memory and a PPTX reopen), `links`, `version` (`apps/deckcraft-cli/src/help.rs:9-152`).
- **JSON control channel:** `deckcraft --control PORT` listens on `127.0.0.1` only and speaks one JSON object per line; methods include `engine.execute`, `document.inspect`, `ui.inspect`, `ui.pointer`, `ui.key`, `ui.text`, `ui.dialog.open`, `ui.screenshot`, `ui.render`, `show.start`, `app.open/save/export/quit` (`docs/control-protocol.md`; `apps/deckcraft/src/control_server.rs:42-58`; `crates/ui-egui/src/control.rs:135-375`).
- **MCP:** `deckcraft-cli mcp` serves 25 tools over stdio — `list_commands`, `run_command`, `batch`, `new_presentation`, `open_presentation`, `save_presentation`, `export`, `inspect_document`, `inspect_slide`, `render_slide`, `add_slide`, `go_to_slide`, `add_shape`, `add_text_box`, `set_text`, `insert_picture`, `insert_table`, `insert_chart`, `select`, `pointer`, `select_tool`, `key`, `type_text`, plus `screenshot` and `call_app` in connected mode (`crates/mcp/src/tools.rs:65-291`). It also exposes `deckcraft://document` and `deckcraft://commands` resources (`crates/mcp/src/server.rs:31-32`).
- **File confinement:** `--automation-read-root` / `--automation-write-root` confine every path a command reads or writes; they cannot be combined with `--connect` (`docs/mcp.md:28-78`; `crates/engine/src/file_access.rs`; `crates/engine/src/io.rs:25`).

### Platforms
- **macOS universal app**, signed and notarized; Windows x64/arm64/x86, Linux (AppImage, Flatpak, deb, rpm, tarball; riscv64 tarball), FreeBSD and a static WebAssembly site (`README.md:200-252`).
- Rendering is CPU-side through `vello_cpu`; the UI is `egui`/`eframe` (Cargo.toml:57; `docs/architecture.md`). The web build uses WebGPU with a WebGL2 fallback (`?webgl` forces it), downloads files instead of saving, has no audio output and no TCP control channel (`apps/deckcraft-web/src/main.rs:4-16`; `apps/deckcraft-web/src/web.rs:8`).

## Known limitations and not-implemented

### File exchange and PowerPoint fidelity
- **No external deck corpus.** The seven PPTX round-trip corpus files are decks authored in this repo; fidelity on real corporate decks, templates and fonts is mostly unmeasured, and "opens in PowerPoint without repair" is a docs claim (spot-checked by hand 2026-10-06), not independently verified here (`docs/gaps.md:80-92`; `docs/file-format-parity.md:14,110`).
- **Known PPTX round-trip losses:** media playback options and animation rewind are not written back (#74, #77); a combo chart's secondary value axis is read but not written when the chart is rebuilt; editing a chart drops its embedded workbook (an unchanged chart keeps it); imported SmartArt is redrawn with DeckCraft's simpler layouts (`docs/gaps.md:94-96,166-186,187-199`).
- **Unsupported input formats:** legacy `.ppt`/`.pot`/`.pps` and OpenDocument `.odp` are not read; `.pptm`/`.potm`/`.ppsm` are not supported formats and macros are not preserved or run; password-protected decks fail with a clear error and there is no password protection on save; outline import is `.txt`/`.md`, no RTF (`crates/engine/src/cmd/file.rs:165-176`; `docs/file-format-parity.md:15-27`; `crates/pptx/src/lib.rs:57-59`).

### Pictures and media
- **SVG is not rendered.** `insert.picture` accepts `image/svg+xml`, but the renderer has no SVG decoder, so an inserted SVG is not drawn; use PNG/JPEG. A PPTX that stores a PNG fallback beside its SVG shows that fallback (`crates/engine/src/cmd/insert.rs:366,394`; `crates/render/src/images.rs:119-134`; `docs/gaps.md:101-108`).
- **HEIC is not supported.** EMF/WMF render inside decks but are not sniffed by `insert.picture`; WMA/WMV are recognised but not decoded; online video embeds are not supported (`docs/file-format-parity.md:41-48`; `crates/media/src/lib.rs:8`).
- **Web build is silent:** no `AudioOut`, no TCP control channel, no persisted preferences (`apps/deckcraft-web/src/web.rs:8,114-140`).

### Output
- **PDF artwork is rasterized.** Each slide is placed as an image at print DPI under an invisible real-text layer; text is selectable/searchable but the artwork is not vector (`crates/pdf/README.md:3-6`; `docs/gaps.md:130-134`).
- **No native print dialog.** File ▸ Print builds a PDF and opens it in the system viewer; no printer list, copies, sides or colour selection (`crates/ui-egui/src/lib.rs:807`).
- **No MP4/MOV export.** Only the animated GIF exists: one static frame per slide, no transitions or build animations; caps 500 frames, 3840 px, 200M total pixels (`crates/engine/src/gif_export.rs:18-35`; `docs/gaps.md:141-147`).

### Platform and UI
- **No native macOS menu bar.** `menus::menu_tree()` exists but nothing installs it; use the ribbon, the command palette (Cmd+Shift+P) or commands (`docs/ui-parity.md:22`; `crates/ui-egui/src/menus.rs`).
- **Presenter view is a second window but is not assigned to the second display** (`docs/gaps.md:28,306`).
- **CPU rasterization and software video decode**; no GPU slide rendering or hardware decode (Cargo.toml:57; `docs/hardware-parity.md`).
- **English-only UI**, no string catalogue (`docs/localization-parity.md`). No pinch-zoom; pen pressure works, tilt does not (`docs/gaps.md:309-315`).

### Feature depth
- **Charts are partial:** chart elements and some `chartex` behaviour are thinner than PowerPoint's (`docs/gaps.md:166-186`).
- **Animations are partial:** 64 non-path effects of roughly 190 in PowerPoint; preview plays the slide from the start (`docs/gaps.md:29`; `crates/model/src/anim.rs:320-437`).
- **SmartArt is shallow:** ~200 PowerPoint layouts, picture layouts and 3-D styles are missing (`docs/gaps.md:187-199`).
- **No recording:** the Record tab's Record button is disabled ("needs audio capture") (`crates/ui-egui/src/ribbon.rs:2096-2098`).
- **Equations are not OMML:** the Equation dialog inserts pretty-printed text; OMML is neither read nor written (PR #55 open) (`crates/ui-egui/src/dialogs.rs:1712-1719`; `docs/file-format-parity.md:94`).
- **No AI/cloud features** (Copilot/Designer/Coach); only offline Design Ideas arrangements. **No add-ins or VBA** by policy; MCP/CLI is the automation alternative (`docs/gaps.md:344-352`).

### Automation and data-safety behaviours to know
- **`file.close` closes a dirty document without prompting.** The UI's Close (`app.closePresentation`, Cmd+W) prompts; the raw engine command does not (`crates/engine/src/cmd/file.rs:56,614-619`). Do not call `file.close` on unsaved work.
- **`app.quit` over the control channel quits without asking.** Pass `{"save": true}` to save every open presentation first (`crates/ui-egui/src/control.rs:364-372`).
- **`file.save`/`file.saveAs` without a `path` (and no stored path) ask the UI** and return `{"needsPath": true}`, writing nothing in headless use — always pass `path` (`crates/engine/src/cmd/file.rs:427-441`).
- **Do not use `file.save`/`--save` for `.png`/`.jpg`.** `save_bytes` handles `pptx|potx|ppsx`, outline, `pdf`, `gif` and falls back to native `.deckcraft` zip bytes for anything else — a `.png`/`.jpg` path through `file.save` writes native bytes under the image name (`crates/engine/src/cmd/file.rs:292-300,386-405`). Use `file.export`/`--export`. MCP `save_presentation` and control-channel `app.save` inherit the same trap.
- **`run` stops at the first failing command and saves nothing** (`apps/deckcraft-cli/src/help.rs:93`).
- **The control channel has no authentication.** It binds loopback only; do not expose or port-forward it (`docs/control-protocol.md:3`; `apps/deckcraft/src/control_server.rs:52`).

## How to operate

### Check what is installed
```sh
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --version   # prints: deckcraft 0.9.0
command -v deckcraft-cli                                          # headless CLI is a separate download
```
The `.app` bundle contains no `deckcraft-cli`. The CLI ships as the separate release asset `deckcraft-cli-<ver>-macos-universal.zip` (README.md:204-208; `packaging/macos/package.sh`). Download/unzip it, build it with `cargo build --release -p deckcraft-cli`, or automate through the control channel instead.

### Launch
```sh
open -a DeckCraft                          # normal GUI
open -a DeckCraft --args --sample          # sample deck
open -a DeckCraft /path/to/talk.pptx       # open a file
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --control 7990 --sample
```
GUI flags: `--control PORT`, `--sample`, `--show`, `--help`, `--version`, and file paths; a `.ppsx` given last starts its slide show (`apps/deckcraft/src/main.rs:129-161`). The port can also come from `DECKCRAFT_CONTROL_PORT`. The app opens `.deckcraft`, `.pptx`, `.potx`, `.ppsx`, `.txt`, `.md` (outlines) and applies `.thmx`/`.pptx` themes via `design.browseTheme` (`crates/engine/src/cmd/file.rs:165-176`; `crates/engine/src/cmd/design.rs:148-174`).

### CLI
`deckcraft-cli` is the most reliable automation surface; it needs no window.

| Command | What it does |
|---|---|
| `deckcraft-cli info FILE` | JSON: slides, layouts, theme fonts, sections, slide size (`help.rs:9-18`) |
| `deckcraft-cli render (FILE \| --sample) [--slide N \| --all] [--scale S] [--edit] [--transparent] OUT` | PNG per slide; `--all` writes `slide-01.png…`; default scale 2; `--slide` is 0-based; `--transparent` drops the slide background (`help.rs:19-36`) |
| `deckcraft-cli render-transition FILE --slide N --t T[,T...] [--width PX] OUT.png` | Frames of the transition into slide N (`help.rs:37-50`) |
| `deckcraft-cli convert IN OUT` | Save in OUT's extension: `.deckcraft`, `.pptx`, `.pdf`, `.txt`/`.md`, `.png`/`.jpg` (first slide only), `.gif` (`help.rs:51-60`) |
| `deckcraft-cli run [--in FILE \| --sample] [--cmd ID[=JSON]]... [--save OUT] [--export OUT [--export-params JSON]] [--print]` | Run commands, then save/export (`help.rs:61-95`) |
| `deckcraft-cli commands [FILTER]` / `describe COMMAND` | List command ids/params; explain one (`help.rs:96-115`) |
| `deckcraft-cli app [--port PORT] COMMAND [JSON]` / `--method METHOD [JSON]` | One request to a running `deckcraft --control` (default port 7979) (`help.rs:116-126`) |
| `deckcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR] [--automation-write-root DIR]` | MCP server on stdio (`help.rs:127-140`) |
| `deckcraft-cli bench (FILE \| --sample) [--runs N] [--json]` | Time open/draw/save/PPTX reopen/PDF export and peak memory (`help.rs:141-149`) |

Examples:
```sh
deckcraft-cli commands format.
deckcraft-cli describe shape.insert
deckcraft-cli run --cmd 'slide.new={"layout":"titleOnly","title":"Q3 results"}' \
  --cmd 'shape.insert={"preset":"roundRect","rect":[80,160,320,120],"text":"Revenue"}' \
  --save q3.deckcraft
deckcraft-cli render q3.deckcraft --all --scale 1 out/
deckcraft-cli convert q3.deckcraft q3.pdf
deckcraft-cli run --in q3.deckcraft --export logo.png --export-params '{"transparentBackground": true}'
```
`--print` prints each command's **answer**; it is not a printer flag. `convert` gives no PDF-layout options; use `run --export` or `file.export` for notes/handouts.

### Conventions that prevent most automation bugs
- Coordinates are **points** on a 960×540 (16:9) slide unless the deck says otherwise; a rect is `[x, y, width, height]` (`help.rs:80-84`; `crates/model/src/defaults.rs:17`).
- **Slide indices are 0-based**; image files written by `--all` are named from 1 (`slide-01.png`) (`help.rs:85-86`; `crates/engine/src/cmd/file.rs:548-560`).
- **Shape ids are looked up on the current slide only**; `slide.go` changes the current slide; `slide.new` inserts after the current slide and selects it (pass `at` for an index) (`help.rs:86-90`; `crates/engine/src/cmd/slide.rs:103-160`).
- Commands that add a shape select it; `format.*` acts on the selection, while many shape commands take `ids` directly.
- Text bodies use `\n` for a new paragraph and a leading tab per level for bullets (`crates/engine/src/cmd/slide.rs:126-134`).

### Documents, open/save/export
- One process can hold several presentations; `file.new`/`file.open` add documents, `window.next` cycles the active one, and `view.newWindow` opens a second, non-editing window on the same deck (`crates/engine/src/cmd/file.rs:11-71`; `crates/ui-egui/src/doc_window.rs`).
- **Open:** `file.open {path}` — native `.deckcraft`, `.pptx`/`.potx`/`.ppsx`, `.txt`/`.md` outlines. Open is lenient for PPTX (unknown parts skipped/kept) and background-loaded in the GUI (`crates/engine/src/cmd/file.rs:147-176,228-256`; `docs/architecture.md:63-69`).
- **Save:** `file.save {path, format?: deckcraft|pptx}` / `file.saveAs {path, format?}` / `file.saveTemplate {path}`; the format follows the extension unless `format` is given (`crates/engine/src/cmd/file.rs:32-34,371-386`). **For `.png`/`.jpg`, use `file.export`** (trap above). Writes go to a unique `.saving` sibling renamed over the target, so a failed save never truncates the old file (`crates/engine/src/io.rs:25-52`). If media is damaged, DeckCraft opens an untitled repaired copy and Save cannot overwrite the original path (`crates/engine/src/cmd/file.rs:213,261-286`).
- **Export:** `file.export {path, format?, ...}`. PNG/JPEG: `slide?`/`all?`/`scale?`/`transparentBackground?`; PDF: `layout: slides|notes|handouts`, `perPage`, `paper`, `orientation`, `dpi`, `slides` (range string or indices), `includeHidden`, `textLayer`, `frame`; GIF: `width`, `secondsPerSlide`, `loop`, `slides`, `includeHidden` (`crates/engine/src/cmd/file.rs:36,518-568`). All requested slide indices are validated before any file is written (`crates/engine/src/cmd/file.rs:545-548`).
- **Native format as source of truth:** keep the `.deckcraft` master and treat `.pptx` as an exchange copy. Native save is lossless for DeckCraft's model (chart payloads included); PPTX has the known losses above (`crates/format/src/lib.rs:1-8`; `docs/gaps.md:94-152`).

### Drive a running app
Start `deckcraft --control 7990`, then either `deckcraft-cli app …` or raw JSON lines:
```sh
deckcraft-cli app --port 7990 --method ui.screenshot '{"path":"shot.png"}'
deckcraft-cli app --port 7990 shape.insert '{"preset":"star5","rect":[100,100,200,200]}'
```
```json
{"id":1,"method":"engine.execute","params":{"command":"shape.insert","params":{"preset":"star5","rect":[100,100,200,200]}}}
{"id":2,"method":"ui.screenshot","params":{"path":"shot.png"}}
```
Use `ui.inspect` first to learn window/canvas/slide rects, the active tool, dialogs and documents; `ui.pointer` takes **slide points**, `ui.click`/`ui.drag` take **screen points** (`docs/control-protocol.md:30-52`). The MCP equivalent is `deckcraft-cli mcp --connect 7990`. For headless MCP:
```json
{"mcpServers":{"deckcraft":{"command":"deckcraft-cli",
  "args":["mcp","--automation-read-root","/work/deck","--automation-write-root","/work/deck/out"]}}}
```
Paths outside the roots are refused with ordinary tool errors; `--connect` and roots cannot be combined (`docs/mcp.md:28-78`).

### Environment and logs
- Settings/logs: `~/Library/Application Support/DeckCraft/` (`ui.json`, `prefs.json`, `logs/deckcraft.log`, rotated, capped at 16 MiB); recovery: `…/DeckCraft/Recovery/` (`apps/deckcraft/src/main.rs:60`; `apps/deckcraft/src/logging.rs:35-40`; `crates/engine/src/recovery.rs:26-35`).
- `DECKCRAFT_CONTROL_PORT` sets the control port; `DECKCRAFT_NO_AUDIO=1` plays silently; `DECKCRAFT_NO_PREFS=1` skips preferences; `DECKCRAFT_NO_RECOVERY=1` skips AutoRecover; `RUST_LOG` sets log levels (default `info` for DeckCraft crates, `warn` otherwise) (`apps/deckcraft/src/main.rs:72,86,120-121,177,244`; README.md:137-141).

## Working with an AI agent

### Choose the surface
1. **Headless CLI** (`deckcraft-cli run`, `render`, `convert`, `info`, `mcp`) — best for generating decks, batch exports and verification. No window, no GUI state.
2. **MCP stdio** (`deckcraft-cli mcp`) — best when the agent has an MCP client; use `run_command`/`batch` for anything the 25 tools do not wrap, and `inspect_document`/`inspect_slide` before editing. `batch` stops at the first error unless `keepGoing` is true; tools reject unknown argument names rather than guessing (`crates/mcp/src/tools.rs:311-336`).
3. **Control channel** (`deckcraft --control`) — only when a human and agent must share a live window, or UI-only state (dialogs, selection, screenshots) matters. Always `ui.inspect`/`ui.screenshot` before pointer work; never click blind.

### Prepare inputs
- **Pictures:** PNG, JPEG, WebP, GIF, BMP, TIFF (not SVG, not HEIC). Pre-render logos and icons to PNG with transparency; for overlays on slides, PNG + `transparentBackground` export round-trips.
- **Audio/video:** MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg, Opus; H.264/HEVC/VP9/AV1 in MP4/MOV/WebM/MKV (`crates/media/src/lib.rs:3-10`). Transcode WMA/WMV first.
- **Outlines:** a `.md` file with `#` headings (one slide per heading, list items as bullets) or a tab-indented `.txt` outline imports directly (`crates/format/src/lib.rs`; `slide.fromOutline`).
- **Themes:** `.thmx` or a `.pptx`/`.potx` whose first master holds the theme (`crates/pptx/src/lib.rs:71-73`).

### Inspect, repair and convert
- `.deckcraft` is a zip: inspect `presentation.json`, `media/<id>` and `chart-parts/<index>` with `unzip -l`/`unzip -p`. Repair damaged media by restoring the member; do not rewrite the JSON unless the schema is understood (`crates/format/src/lib.rs:1-29`). Older files with inline chart bytes still load and migrate on save (`docs/architecture.md:70-73`).
- Do **not** hand-edit a `.pptx` zip to "fix" it: use DeckCraft commands and re-export. Unknown PPTX parts are preserved by the writer, but hand-edited XML can break content types or relationships (`docs/architecture.md:63-69`).
- Convert between `.deckcraft`, `.pptx`, `.pdf`, `.txt`/`.md` and images with `convert`, but `convert` writes only the first slide for PNG/JPEG and uses default PDF options (`apps/deckcraft-cli/src/help.rs:51-60`).

### Verify exports
- Read the command result: exports return `{path, bytes}` or `{files}`; assert the file exists and its size is plausible. A zero-byte or missing file is a failure even if the process exited 0 (`crates/engine/src/cmd/file.rs:518-568`).
- Re-open the result: `deckcraft-cli info out.pptx` and compare slide count/titles/layouts; `deckcraft-cli render out.pptx --all` and look at the PNGs.
- For PDF, check page count and extracted text (e.g. `pdftotext`); the text layer is selectable but the artwork is raster (`crates/pdf/README.md:3-6`).
- For `.pptx`, the strongest test is opening it in PowerPoint/Keynote and checking for a repair prompt, animations, media and theme fonts. The project has not tested a real-deck corpus (`docs/gaps.md:80-92`).
- For GIF, verify the `GIF89a` header, dimensions, frame count and delay; transitions/builds are intentionally absent (`crates/engine/src/gif_export.rs:1-10`).

### Do not
- Do not insert SVG, HEIC, or EMF/WMF via `insert.picture` and expect them to draw.
- Do not promise `.ppt`, `.odp`, `.pptm`, macros, password protection or MP4 export.
- Do not call `file.close` or `app.quit` on unsaved work; use `app.quit {"save": true}` or save explicitly.
- Do not use `file.save`/`--save` for `.png`/`.jpg`; use `file.export`/`--export` (otherwise native zip bytes get an image extension).
- Do not assume PDF is vector or that a `.pptx` round-trip is lossless.
- Do not rely on font metrics matching PowerPoint exactly; substitute faces change line breaks. Verify visually.
- Do not expose the control channel beyond loopback; it has no authentication.

## Verification protocol

Alpha software with active auto-updates: verify every deliverable, keep a native master, and never trust a silent export.

1. **Pin the version.** Record `deckcraft --version` and the bundle build commit before work. Update only between projects, not mid-deck; file formats and command sets move between releases (`apps/deckcraft/src/main.rs:163-165`; `/Applications/DeckCraft.app/Contents/Info.plist`).
2. **Work in a throwaway directory.** Copy sources in; never run destructive tests on the only copy of a deck. Keep a `.deckcraft` master plus dated backups.
3. **Round-trip a small test first.** New deck → add one slide, shape, table, chart, picture, transition and note → save `.deckcraft` → export `.pptx` → reopen the `.pptx` → inspect counts and render PNGs. Fix workflow problems before touching the real deck.
4. **Save before every export.** A failed export must not be the only copy of your changes. `file.save` is atomic via a `.saving` sibling; exports are ordinary writes (`crates/engine/src/io.rs:25-52`).
5. **Check every export explicitly.** Existence and non-zero size; images: dimensions (and alpha, when `transparentBackground` was used); PDF: page count and selectable text; PPTX: reopen and render; GIF: header, dimensions, frame count.
6. **Look at the pixels.** `deckcraft-cli render … --all` (or MCP `render_slide`) and inspect the PNGs. Text overflow, missing fonts, blank SVG/EMF pictures and chart scaling are visual failures that a successful exit code will not catch.
7. **Open in the target app.** If PowerPoint is available, open the exported `.pptx` and check for repair prompts and lost animations/media. If not, state that fidelity is unverified rather than claiming parity.
8. **Keep the native file.** The `.deckcraft` master preserves DeckCraft-only constructs (including chart payloads) and is the safest thing to reopen after a failure.
9. **Record what changed.** Note version, command lines/JSON params, export options and any manual GUI steps, so a failed export can be reproduced.

## Sources & evidence

- **Repo:** https://github.com/storytold/deckcraft — tag `v0.9.0`, commit `fe510bdac68118f2c9a714e69d0ff572e3f9a0c7` (`git rev-parse HEAD`), inspected 2026-10-22.
- **Installed bundle:** `/Applications/DeckCraft.app`, `CFBundleIdentifier ai.storyteller.deckcraft`, version `0.9.0`, `DeckCraftBuildCommit` equal to the commit above; `--version` prints `deckcraft 0.9.0`.
- **Key files read:** `README.md`; `ROADMAP.md`; `Cargo.toml`; `docs/{architecture,gaps,file-format-parity,animation-parity,ui-parity,mcp,control-protocol,slideshow-parity,hardware-parity,localization-parity,target-app-parity}.md`; `apps/deckcraft/src/{main,control_server,logging}.rs`; `apps/deckcraft-cli/src/{help,main}.rs`; `apps/deckcraft-web/src/{main,web}.rs`; `crates/engine/src/cmd/{mod,file,slide,insert,shape,text,format,design,table,smartart,animation,transition,review,three_d,richclip}.rs`; `crates/engine/src/{lib,io,recovery,gif_export,icons,templates,file_access}.rs`; `crates/format/src/lib.rs`; `crates/pptx/src/lib.rs`; `crates/pdf/{README.md,src/lib.rs}`; `crates/model/src/{lib,theme,chart,anim}.rs` and `defaults.rs`; `crates/geom/src/preset.rs`; `crates/render/src/{lib,images}.rs`; `crates/media/src/lib.rs`; `crates/mcp/src/{tools,server,headless,backend}.rs`; `crates/ui-egui/src/{lib,show,menus,ribbon,backstage,dialogs,control,panes}.rs`; `packaging/macos/package.sh`.
- **Shared library:** `craft-pdf` is pinned to `storytold/craft-libs` rev `c3487320b2d1de657b860b3c8abb44e1f2b32bd8` with `write` features only (Cargo.toml:60).
- **Docs that are stale (code wins):** `docs/file-format-parity.md` still says `.potx`/`.ppsx` are written with the `.pptx` content type and `.thmx` is unreadable; the code writes `CT_TEMPLATE`/`CT_SHOW` and imports `.thmx` (`crates/pptx/src/lib.rs:76-86`; `crates/engine/src/cmd/design.rs:148-174`). `docs/control-protocol.md` still says a 16 MiB request line; the code allows 256 MiB (`apps/deckcraft/src/control_server.rs:42`). `docs/mcp.md`/`architecture.md` were last reviewed 2026-10-14/18.
- **Not independently verified:** PowerPoint's acceptance of exported `.pptx` without repair on real decks, render fidelity against PowerPoint, and behaviour on decks of unknown provenance. Treat those as claims until you test them.

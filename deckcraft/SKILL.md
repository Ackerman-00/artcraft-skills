---
name: deckcraft
description: >-
  DeckCraft is the open-source, clean-room PowerPoint-compatible presentation app for macOS
  (also Windows, Linux, FreeBSD and the web): slides, masters, shapes, text, tables, charts,
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

DeckCraft is an open-source (MIT OR Apache-2.0), clean-room reimplementation of Microsoft PowerPoint, written in pure Rust: it builds decks with masters/layouts, shapes, text, tables, charts, SmartArt and media; presents them full screen; and exchanges PowerPoint `.pptx` plus its own `.deckcraft` format (README.md:13, 64-80; Cargo.toml:1-8). It is **alpha**: v0.8.0, claiming **84% feature breadth** and **~55% ready for real work** by its own measurement (ROADMAP.md:3, 17-23). Native builds target macOS, Windows, Linux and FreeBSD, with a WebAssembly build for browsers (README.md:201-230). Source: `github.com/storytold/deckcraft` (Cargo.toml:11).

**Audit basis:** this checkout is tag `v0.8.0`, commit `22db9261f9d1a214c296fd390173130c45d76d66`. The installed `/Applications/DeckCraft.app` reports `CFBundleShortVersionString 0.8.0` and `DeckCraftBuildCommit 22db9261f9d1a214c296fd390173130c45d76d66`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since: the code is moving quickly, and some `docs/` pages already lag the code (see the final bullets in “Sources & evidence”).

## Capabilities (verified)

### Deck structure and design
- **Slides, masters and layouts.** Eleven layout kinds (Title, Title and Content, Section Header, Two Content, Comparison, Title Only, Blank, Content with Caption, Picture with Caption, Title and Vertical Text, Vertical Title and Text) plus `Custom` (`crates/model/src/lib.rs:679-710`). Slide masters, notes master, handout master, placeholder inheritance, sections, notes, comments, headers/footers, custom shows and custom slide sizes are modelled (`crates/model/src/lib.rs`; `crates/engine/src/cmd/slide.rs:45-58`; `crates/engine/src/cmd/design.rs:52-61`; `crates/engine/src/cmd/review.rs:13-17`).
- **Themes.** Eight built-in themes — DeckCraft, Harbor, Ember, Meadow, Nocturne, Paper, Coral Reef, Slate — each with colour, font and effect schemes; four variants per theme; Browse for Themes imports `.thmx`, `.pptx` or `.potx` (`crates/model/src/theme.rs:155-175, 178-260`; `crates/engine/src/cmd/design.rs:17-40, 148-174`; `crates/pptx/src/lib.rs:66-69`).
- **Starter decks.** Six original starters — Briefing, Lesson, Pitch, Field Notes, Quarterly, Evening Talk — via `file.new {template}` (`crates/engine/src/templates.rs:37-168`; `crates/engine/src/cmd/file.rs:20`).
- **Shapes.** 183 shape/connector presets in the catalogue, with adjust handles, connectors that stay glued, freeform/curve/scribble tools, merge operations (union, combine, fragment, intersect, subtract), gradient/picture/pattern fills, dashes, arrowheads, shadows, glow, soft edges and reflections (`crates/geom/src/preset.rs:147`; `crates/engine/src/cmd/shape.rs:14-150`; `crates/engine/src/cmd/merge.rs`; `crates/engine/src/cmd/picture_style.rs`).
- **Text.** In-place editing with DrawingML run/paragraph properties, bullets and numbering, columns, autofit (none/shrink/resize), vertical and RTL text, fields, hyperlinks, tab stops, line spacing and text warps (`crates/engine/src/cmd/text.rs:17-90`; `crates/engine/src/cmd/format.rs:18-215`; `crates/model/src/text.rs`; `crates/geom/src/warp.rs`).
- **Tables.** Styled tables with cell merges, diagonal borders, row/column insert/delete, distribution, heights and borders (`crates/engine/src/cmd/table.rs`; `crates/pptx/tests/corpus_charts.rs` covers merged tables and diagonals).

### Content
- **Pictures.** PNG, JPEG, GIF (including animated GIFs), WebP, BMP and TIFF are decoded; EMF/WMF are drawn through `deckcraft-metafile` when they arrive inside a deck (`crates/render/src/images.rs:119-134`; `crates/metafile/src/lib.rs:20-30`; `docs/file-format-parity.md:39-42`). Crop, brightness/contrast, duotone, alpha and some artistic effects are modelled (`crates/engine/src/cmd/picture_style.rs`; `crates/engine/src/cmd/artistic.rs`).
- **Charts.** 28 chart types in the model, including the seven Office-2016 `chartEx` types (waterfall, funnel, histogram, Pareto, box & whisker, treemap, sunburst), plus radar, stock, region map (kept and drawn, not offered in the menus) and combo (`crates/model/src/chart.rs:9-41`). Insert with categories/series (`insert.chart`), edit data with `chart.data` or the Chart Data dialog, change type with `chart.type`; trendlines are drawn (`crates/engine/src/cmd/insert.rs:66-72, 108-114, 1716`; `crates/model/src/chart.rs`; `crates/pptx/src/read/chart.rs`).
- **SmartArt.** A SmartArt graphic is a group whose outline is edited in a Text Pane; 45 layouts and 9 styles, with Add Shape, Promote, Demote, Remove and layout switching; saved to `.pptx` as a real diagram (`crates/engine/src/cmd/smartart.rs:26-80`; `crates/pptx/src/dgm.rs`).
- **Media.** Audio: MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg Vorbis and Opus. Video: H.264, HEVC, VP9 and AV1 in MP4/MOV/WebM/MKV, software-decoded in pure Rust (`crates/media/src/lib.rs:1-25`; `crates/engine/src/cmd/insert.rs:74-75, 319-373`).
- **Other insertables.** Lucide 1.56 stroke icons as custom shapes (`insert.icon`), WordArt, symbols, date/time fields, slide numbers and an equation dialog that inserts styled text (not OMML) (`crates/engine/src/icons.rs`; `crates/engine/src/cmd/insert.rs:26-134`; `crates/ui-egui/src/dialogs.rs:1699-1706`).

### Presenting
- **48 transitions plus “None”** (49 rows), including Morph, with each transition’s effect options (`crates/model/src/anim.rs:52-106`; `docs/animation-parity.md:16-40`).
- **Animations.** 106 picker entries: 64 non-path effects (24 entrance, 23 exit, 17 emphasis), 39 motion paths and 3 media controls; start modes (on click / with previous / after previous), by-paragraph builds, triggers, repeat and bounce end (`crates/model/src/anim.rs:320-437`; `crates/engine/src/cmd/animation.rs`; `docs/animation-parity.md:50-57`).
- **Slide show.** Full-screen show, presenter view in a second window, pen and laser pointer, black/white screens, See All Slides, zoom, hyperlinks/actions, custom shows, rehearse timings and media playback (`crates/ui-egui/src/show.rs:1-40, 430-500`; `crates/engine/src/cmd/review.rs:63-90`; `docs/control-protocol.md:30-52`).
- **Views.** Normal, Outline, Slide Sorter, Notes Page and Reading; slide/notes/handout master views (`crates/ui-egui/src/lib.rs:227-234`; `crates/ui-egui/src/ribbon.rs:154`).

### Files
- **Native `.deckcraft`:** a zip with a stored `mimetype`, `presentation.json` and `media/<id>` entries, format version 1; readers ignore unknown fields, and legacy `.slidecraft` files still open (`crates/format/src/lib.rs:1-24, 56-85`; `crates/format/src/lib.rs:15-18`).
- **PowerPoint `.pptx`:** read and write; `.potx` and `.ppsx` open, and v0.8.0 writes the correct template/slideshow content type (`crates/pptx/src/lib.rs:61-85`; test `crates/pptx/tests/roundtrip.rs:1089`). Unknown parts are kept as `Opaque`/raw XML where the model does not understand them (`docs/architecture.md:64-69`).
- **Outline text:** `.txt` and `.md` import (outline levels; Markdown headings become slides) and `.txt`/`.md` export (`crates/engine/src/cmd/file.rs:149-156`; `crates/format/src/lib.rs:412-523`).
- **PDF:** slides, notes pages or handouts (1/2/3/4/6/9 per page), Letter/A4/Legal/A3, portrait/landscape, hidden-slide and slide-range options, selectable invisible text layer and bookmarks; slide artwork itself is a raster image (`crates/pdf/src/lib.rs:67-105, 451-462`; `crates/engine/src/cmd/file.rs:274-337`).
- **Images and GIF:** PNG/JPEG per slide (one or all), and an animated GIF of the deck (one frame per slide, 16-3840 px wide, 0.1-600 s per slide, loop or play once, slide range, hidden slides skipped) (`crates/engine/src/cmd/file.rs:481-545`; `crates/engine/src/gif_export.rs:1-35`).
- **AutoRecover:** unsaved presentations are written to a recovery folder and reopened at the next start; saving or closing removes the entry (`crates/engine/src/recovery.rs:1-35`; `apps/deckcraft/src/main.rs:240-247`).

### Automation
- **320 commands**, each with id, label, ribbon/menu place, shortcut, parameter docs, enabled check and run function, registered in 28 modules (`crates/engine/src/cmd/mod.rs:161-192`; count of `cmd!` specs = 320). `Session::execute` is the single dispatch path used by the UI, CLI, control channel and MCP (`crates/engine/src/lib.rs:579-600`).
- **`deckcraft-cli`:** `info`, `render`, `render-transition`, `convert`, `run`, `commands`, `describe`, `app`, `mcp`, `bench`, `links`, `version` (`apps/deckcraft-cli/src/main.rs:35-83`; `apps/deckcraft-cli/src/help.rs:8-157`).
- **JSON control channel:** `deckcraft --control PORT` listens on `127.0.0.1` only and speaks one JSON object per line; methods include `engine.execute`, `document.inspect`, `ui.inspect`, `ui.pointer`, `ui.key`, `ui.text`, `ui.dialog.open`, `ui.screenshot`, `ui.render`, `show.start`, `app.open/save/export/quit` (`docs/control-protocol.md:1-52`; `apps/deckcraft/src/control_server.rs:44-58`).
- **MCP:** `deckcraft-cli mcp` serves 25 tools over stdio — `list_commands`, `run_command`, `batch`, `new_presentation`, `open_presentation`, `save_presentation`, `export`, `inspect_document`, `inspect_slide`, `render_slide`, `add_slide`, `go_to_slide`, `add_shape`, `add_text_box`, `set_text`, `insert_picture`, `insert_table`, `insert_chart`, `select`, `pointer`, `select_tool`, `key`, `type_text`, plus `screenshot` and `call_app` in connected mode (`crates/mcp/src/tools.rs:65-290`; `docs/mcp.md:80-104`). It also exposes `deckcraft://document` and `deckcraft://commands` resources (`crates/mcp/src/server.rs:31-32, 157-165`).
- **File confinement:** `--automation-read-root` / `--automation-write-root` confine every path a command reads or writes (open, pictures, audio, video, save, export, render output); they cannot be combined with `--connect` (`docs/mcp.md:28-78`; `apps/deckcraft-cli/src/main.rs:588-635`).

### Platforms
- **macOS 11+ universal app**, signed and notarized; Windows x64/arm64/x86, Linux (AppImage, Flatpak, deb, rpm, tarball), FreeBSD and a static WebAssembly site (`README.md:201-230`; `/Applications/DeckCraft.app/Contents/Info.plist`).
- Rendering is CPU-side through `vello_cpu`; the UI is `egui`/`eframe` (`Cargo.toml:57-71`; `docs/architecture.md:49-60`). The web build uses WebGPU with a WebGL2 fallback and downloads files instead of using save dialogs (`apps/deckcraft-web/src/main.rs:1-25`; `apps/deckcraft-web/src/Cargo.toml:23-25`).

## Known limitations and not-implemented

### File exchange and PowerPoint fidelity
- **No external deck corpus.** All PPTX round-trip tests use decks authored in this repo; fidelity on real corporate decks, templates, SmartArt, `chartex` and embedded fonts is “mostly unknown” by the project’s own admission (`docs/gaps.md:67-92`; `crates/pptx/tests/corpus*.rs`). The claim that exported `.pptx` opens in PowerPoint without repair is a docs claim, not independently verified here (`docs/architecture.md:64-69`).
- **Known PPTX round-trip losses:** media playback options and animation rewind are not written back (#74, #77); a combo chart’s secondary axis is not written when the chart is rebuilt; editing a chart drops its embedded workbook; imported SmartArt is redrawn with DeckCraft’s simpler layout; MicroType Express embedded-font subsets are kept but not drawn (`docs/gaps.md:94-152`; `docs/file-format-parity.md:75-88`).
- **Unsupported input formats:** legacy `.ppt`/`.pot`/`.pps` and OpenDocument `.odp` are not read; `.pptm`/`.potm`/`.ppsm` are not supported formats and their macros are not preserved or run (a macro-enabled package may still be read as plain OOXML); password-protected decks fail with a clear error, and there is no password protection on save (`crates/engine/src/cmd/file.rs:139-163, 340-348`; `docs/file-format-parity.md:17-25, 89-90`; `crates/pptx/src/lib.rs:56-58`).

### Pictures and media
- **SVG is not rendered.** `insert.picture` accepts `image/svg+xml`, but the renderer has no SVG decoder, so an inserted SVG is not drawn; use PNG/JPEG. A PowerPoint file that stores a PNG fallback beside its SVG may still show that fallback (`crates/engine/src/cmd/insert.rs:366-394`; `crates/render/src/images.rs:119-134`; `docs/gaps.md:101-108`).
- **HEIC is not supported.** EMF/WMF render when imported in a deck but are not sniffed by `insert.picture`; WMA/WMV are recognised but not decoded; online video embeds are not supported (`docs/file-format-parity.md:41-48`; `crates/engine/src/cmd/insert.rs:319-373`; `crates/media/src/lib.rs:4-7`).
- **Web build is silent:** it has no `AudioOut`, so media plays without sound; it also has no TCP control channel and does not persist preferences (`apps/deckcraft-web/src/web.rs:114-140`; `apps/deckcraft-web/src/main.rs:8-15`).

### Output
- **PDF artwork is rasterized.** Each slide is placed as an image at print resolution under an invisible real-text layer; text is selectable/searchable, but the artwork is not vector. Large decks produce large PDFs and zoom/print quality follows the raster DPI (`crates/pdf/README.md:3-6`; `docs/gaps.md:130-134`).
- **No native print dialog.** The File ▸ Print page builds a PDF and opens it in the system viewer/browser; there is no printer list, copies, sides or colour selection (`crates/ui-egui/src/lib.rs:806-828`; `docs/ui-parity.md` Print row).
- **No MP4/MOV export.** Only an animated GIF exists; it shows one static frame per slide, with no transitions or build animations (`docs/gaps.md:141-147`; `crates/engine/src/gif_export.rs:1-8`). GIF is capped at 500 frames, 3840 px wide and 200M total pixels (`crates/engine/src/gif_export.rs:29-35`).

### Platform and UI
- **No native macOS menu bar.** `menus::menu_tree()` exists but nothing installs it; use the ribbon, command palette (`Cmd+Shift+P`, `crates/ui-egui/src/lib.rs:396`) or commands (`docs/ui-parity.md:24`; `crates/ui-egui/src/menus.rs:161`).
- **Presenter view is a second window but is not assigned to the second display/projector** (`docs/gaps.md:304`; `crates/ui-egui/src/show.rs:1035-1037, 1757`).
- **CPU rasterization and software video decode**; no GPU slide rendering or hardware decode (`docs/gaps.md:305-308`; `Cargo.toml:57`).
- **English-only UI**, no string catalogue or RTL mirroring (`ROADMAP.md:85-106`).
- **No pinch-zoom**; pen pressure works but tilt does not (`docs/gaps.md:309-314`).

### Feature depth
- **Charts are partial:** data can be edited by command/dialog, but chart elements and some `chartex` behaviour are thinner than PowerPoint’s (`docs/gaps.md:166-185`; `crates/engine/src/cmd/insert.rs:108-114`).
- **Animations are partial:** 64 non-path effects of roughly 190 in PowerPoint; preview plays the slide from the start, not from the selected effect (`docs/gaps.md:29, 201-206`; `crates/model/src/anim.rs:320-437`).
- **SmartArt is shallow:** imported diagrams are redrawn with DeckCraft’s layouts; PowerPoint has ~200 layouts, picture layouts and 3-D styles (`docs/gaps.md:187-199`; `crates/engine/src/cmd/smartart.rs:26-80`).
- **No recording:** the Record tab’s Record button is disabled (“needs audio capture”), and there is no record-slide-show (`crates/ui-egui/src/ribbon.rs:2077-2078`; `docs/gaps.md:272-277`).
- **Equations are not OMML:** the Equation dialog inserts pretty-printed text; OMML is neither read nor written (`crates/ui-egui/src/dialogs.rs:1699-1706`; `docs/file-format-parity.md:78`).
- **No AI/cloud features:** no Copilot/Designer/Speaker Coach/Translate; only offline Design Ideas arrangements (`docs/gaps.md:347-351`; `crates/engine/src/cmd/ideas.rs:1-20`).
- **No add-ins or VBA** by policy; MCP/CLI is the automation alternative (`docs/gaps.md:345`).

### Automation and data-safety behaviours to know
- **`file.close` closes a dirty document without prompting.** The UI’s Close (`app.closePresentation`, `Cmd+W`) prompts; the raw engine command does not (`crates/engine/src/cmd/file.rs:569-574`; `crates/ui-egui/src/lib.rs:388, 715-723`). Do not call `file.close` on unsaved work.
- **`app.quit` over the control channel quits without asking.** Pass `{"save": true}` to save first; otherwise unsaved changes are lost (`crates/ui-egui/src/control.rs:364-372`).
- **`file.save`/`file.saveAs` without a `path` ask the UI for one** and write nothing in headless use; always pass `path` (`crates/engine/src/cmd/file.rs:396-415`).
- **Do not use `file.save`/`--save` for `.png`/`.jpg`.** `save_bytes` has writers for `.pptx`/`.potx`/`.ppsx`, `.pdf`, `.gif`, outline and native, but not for PNG/JPEG; a `.png`/`.jpg` path falls through to native `.deckcraft` zip bytes under the image name (`crates/engine/src/cmd/file.rs:261-268, 340-376`). Use `file.export`/`--export` (or the GUI’s Save As, which routes those types through `export_as`) for images. MCP `save_presentation` and control-channel `app.save` inherit the same trap.
- **`run` stops at the first failing command and saves nothing** (`apps/deckcraft-cli/src/help.rs:92-93`).
- **The control channel has no authentication.** It binds loopback only; do not expose or port-forward it (`docs/control-protocol.md:3-4`; `apps/deckcraft/src/control_server.rs:52`).

## How to operate

### Check what is installed
```sh
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --version   # prints: deckcraft 0.8.0
command -v deckcraft-cli                                          # headless CLI is a separate download
```
The `.app` bundle contains no `deckcraft-cli`. The CLI ships as the separate release asset `deckcraft-cli-<ver>-macos-universal.zip` (`packaging/macos/package.sh:5, 44, 156-167`; README.md:206). On the audit machine `deckcraft-cli` was **not** on `PATH` and not inside the bundle. Download/unzip the CLI, build it with `cargo build --release -p deckcraft-cli`, or automate through the control channel instead.

### Launch
```sh
open -a DeckCraft                          # normal GUI
open -a DeckCraft --args --sample          # sample deck
open -a DeckCraft /path/to/talk.pptx       # open a file
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --control 7990 --sample
```
GUI flags: `--control PORT`, `--sample`, `--show`, `--help`, `--version`, and file paths (`apps/deckcraft/src/main.rs:129-161`; verified by running `--help`). The control port can also come from `DECKCRAFT_CONTROL_PORT`. The app opens `.deckcraft`, `.pptx`, `.potx`, `.ppsx`, `.txt`, `.md` (the last two as outlines) and applies `.thmx`/`.pptx` themes through Design ▸ Browse for Themes (`apps/deckcraft/src/main.rs:95-111`; `crates/engine/src/cmd/file.rs:127-163`; `crates/engine/src/cmd/design.rs:148-174`).

### CLI
`deckcraft-cli` is the most reliable automation surface; it needs no window.

| Command | What it does |
|---|---|
| `deckcraft-cli info FILE` | JSON: slides, layouts, theme fonts, sections, slide size (`help.rs:9-19`) |
| `deckcraft-cli render (FILE \| --sample) [--slide N \| --all] [--scale S] [--edit] OUT` | PNG per slide; `--all` writes `slide-01.png…`; default scale 2; `--slide` is 0-based (`help.rs:20-33`) |
| `deckcraft-cli render-transition FILE --slide N --t T[,T...] [--width PX] OUT.png` | Frames of the transition into slide N (`help.rs:34-47`) |
| `deckcraft-cli convert IN OUT` | Save in OUT’s extension: `.deckcraft`, `.pptx`, `.potx`, `.ppsx`, `.pdf`, `.txt`, `.md`, `.png`/`.jpg` (first slide only), `.gif` (`help.rs:48-57`; `main.rs:404-423`; `crates/engine/src/cmd/file.rs:340-348`) |
| `deckcraft-cli run [--in FILE \| --sample] [--cmd ID[=JSON]]... [--save OUT] [--export OUT [--export-params JSON]] [--print]` | Run commands, then save/export (`help.rs:58-94`) |
| `deckcraft-cli commands [FILTER]` | List command ids/labels/params (`help.rs:95-106`) |
| `deckcraft-cli describe COMMAND` | Explain one command and its parameters (`help.rs:107-115`) |
| `deckcraft-cli app [--port PORT] COMMAND [JSON]` / `--method METHOD [JSON]` | Send one request to a running `deckcraft --control` (`help.rs:116-126`; default port 7979) |
| `deckcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR] [--automation-write-root DIR]` | MCP server on stdio (`help.rs:127-139`) |
| `deckcraft-cli bench (FILE \| --sample) [--runs N] [--json]` | Time open/render/save/PDF (`help.rs:140-149`) |

Examples:
```sh
deckcraft-cli commands format.
deckcraft-cli describe shape.insert
deckcraft-cli run --cmd 'slide.new={"layout":"titleOnly","title":"Q3 results"}' \
  --cmd 'shape.insert={"preset":"roundRect","rect":[80,160,320,120],"text":"Revenue"}' \
  --save q3.deckcraft
deckcraft-cli render q3.deckcraft --all --scale 1 out/
deckcraft-cli convert q3.deckcraft q3.pdf
deckcraft-cli run --in q3.deckcraft --export q3-notes.pdf \
  --export-params '{"layout":"notes","paper":"a4"}'
```
`--print` prints each command’s **answer**; it is not a printer flag (`help.rs:92`). `convert` gives no PDF-layout options; use `run --export` or `file.export` for notes/handouts.

### Conventions that prevent most automation bugs
- Coordinates are **points** on a 960×540 (16:9) slide unless the deck says otherwise; a rect is `[x, y, width, height]`, x right and y down (`help.rs:82-84`; `crates/model/src/defaults.rs:17`).
- **Slide indices are 0-based**; image files written by `--all` are named from 1 (`slide-01.png`) (`help.rs:84-86`; `crates/engine/src/cmd/file.rs:483-514`).
- **Shape ids are looked up on the current slide only**; `slide.go` changes the current slide (`help.rs:86-87`; `crates/engine/src/cmd/slide.rs:26`).
- `slide.new` inserts **after the current slide** and selects the new slide; pass `at` for an explicit index (`crates/engine/src/cmd/slide.rs:103-154`).
- Commands that add a shape select it; `format.*` acts on the selection, while many shape commands take `ids` directly (`help.rs:88-90`).
- Text bodies use `\n` for a new paragraph and a leading tab per level for bullets (`crates/engine/src/cmd/slide.rs:124-133`; `apps/deckcraft-cli/src/help.rs:70-78`).

### Documents, open/save/export
- One process can hold several presentations; `file.new`/`file.open` add documents, `window.next` cycles the active one, and `view.newWindow` opens a second, non-editing window on the same deck (`crates/engine/src/cmd/file.rs:12-71`; `crates/ui-egui/src/doc_window.rs:1-8`).
- **Open:** `file.open {path}`. Native `.deckcraft`, `.pptx`/`.potx`/`.ppsx`, and `.txt`/`.md` outlines. Open is lenient for PPTX (unknown parts skipped/kept), and background-loaded in the GUI (`crates/engine/src/cmd/file.rs:127-163`; `docs/architecture.md:64-69`; `crates/ui-egui/src/opening.rs`).
- **Save:** `file.save {path, format?}` or `file.saveAs {path}`. The format follows the extension unless `format` is given: `.deckcraft`, `.pptx`, `.potx`, `.ppsx`, `.pdf`, `.gif`, `.txt`/`.md` (`crates/engine/src/cmd/file.rs:261-268, 340-376, 396-415`). **For `.png`/`.jpg`, use `file.export` instead:** `save_bytes` has no PNG/JPEG writer, so a `.png`/`.jpg` path through `file.save` writes native zip bytes under the image name; the GUI’s Save As avoids this by routing images through `export_as` (`crates/ui-egui/src/backstage.rs:926-958`). Writes go to a unique `.saving` sibling and are renamed over the target, so a failed save does not truncate the old file (`crates/engine/src/io.rs:20-50`).
- **Export:** `file.export {path, format?, ...}`. PNG/JPEG export the current slide, one `slide`, or `all`; PDF accepts `layout: slides|notes|handouts`, `perPage`, `paper`, `orientation`, `dpi`, `slides` (range string or indices), `includeHidden`, `textLayer`, `frame`; GIF accepts `width`, `secondsPerSlide`, `loop`, `slides`, `includeHidden` (`crates/engine/src/cmd/file.rs:36, 481-545`).
- **Native format as source of truth:** keep the `.deckcraft` master and treat `.pptx` as an exchange copy. Native save is lossless for DeckCraft’s model; PPTX has the known losses above (`crates/format/src/lib.rs:1-3`; `docs/gaps.md:94-152`).

### Drive a running app
Start `deckcraft --control 7990`, then either:
```sh
deckcraft-cli app --port 7990 --method ui.screenshot '{"path":"/tmp/shot.png"}'
deckcraft-cli app --port 7990 shape.insert '{"preset":"star5","rect":[100,100,200,200]}'
```
or speak JSON lines directly to `127.0.0.1:7990`:
```json
{"id":1,"method":"engine.execute","params":{"command":"shape.insert","params":{"preset":"star5","rect":[100,100,200,200]}}}
{"id":2,"method":"ui.screenshot","params":{"path":"/tmp/shot.png"}}
```
Use `ui.inspect` first to learn window/canvas/slide rects, the active tool, open dialogs and documents; `ui.pointer` takes **slide points**, `ui.click`/`ui.drag` take **screen points** (`docs/control-protocol.md:30-52`). The MCP equivalent is `deckcraft-cli mcp --connect 7990` (`docs/mcp.md:1-26`).

For a headless MCP client:
```json
{"mcpServers":{"deckcraft":{"command":"deckcraft-cli",
  "args":["mcp","--automation-read-root","/work/deck","--automation-write-root","/work/deck/out"]}}}
```
Paths outside the roots are refused with ordinary tool errors; `--connect` and roots cannot be combined (`docs/mcp.md:28-78`).

### Environment and logs
- Settings/logs: `~/Library/Application Support/DeckCraft/` (`ui.json`, `prefs.json`, `logs/deckcraft.log`); recovery: `~/Library/Application Support/DeckCraft/Recovery/` (`apps/deckcraft/src/main.rs:56-68`; `crates/engine/src/recovery.rs:25-35`).
- `DECKCRAFT_CONTROL_PORT` sets the control port; `DECKCRAFT_NO_AUDIO=1` plays silently; `DECKCRAFT_NO_PREFS=1` skips loading/saving preferences; `DECKCRAFT_NO_RECOVERY=1` skips AutoRecover; `RUST_LOG` sets log levels (`apps/deckcraft/src/main.rs:70-90, 119-122, 174, 241`; README.md:128-144).

## Working with an AI agent

### Choose the surface
1. **Headless CLI** (`deckcraft-cli run`, `render`, `convert`, `info`, `mcp`) — best for generating decks, batch exports and verification. It needs no window and no GUI state.
2. **MCP stdio** (`deckcraft-cli mcp`) — best when the agent has an MCP client; use `run_command`/`batch` for anything the 25 tools do not wrap, and `inspect_document`/`inspect_slide` before editing. `batch` stops at the first error unless `keepGoing` is true, and tools reject unknown argument names rather than silently using defaults (`crates/mcp/src/tools.rs:334-337, 359-374`).
3. **Control channel** (`deckcraft --control`) — only when a human and agent must share a live window, or when UI-only state (dialogs, selection, screenshots) matters. Always `ui.inspect`/`ui.screenshot` before pointer work; never click blind.

### Prepare inputs
- **Pictures:** PNG, JPEG, WebP, GIF, BMP, TIFF (not SVG, not HEIC). Pre-render logos and icons to PNG with transparency.
- **Audio/video:** MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg, Opus; H.264/HEVC/VP9/AV1 in MP4/MOV/WebM/MKV (`crates/media/src/lib.rs`). Transcode WMA/WMV first.
- **Outlines:** a `.md` file with `#` headings (one slide per heading, list items as bullets) or a tab-indented `.txt` outline imports directly (`crates/format/src/lib.rs:412-523`).
- **Themes:** `.thmx` or a `.pptx`/`.potx` whose first master holds the theme (`crates/pptx/src/lib.rs:66-69`).

### Inspect, repair and convert
- `.deckcraft` is a zip: inspect `presentation.json` and `media/<id>` with `unzip -l`/`unzip -p`. Repair missing media by restoring the member; do not rewrite the JSON unless the schema is understood (`crates/format/src/lib.rs:1-24`). If media is damaged, DeckCraft opens a repaired copy and refuses to overwrite the original path (`crates/engine/src/cmd/file.rs:199-256`).
- Do **not** hand-edit a `.pptx` zip to “fix” it: use DeckCraft commands and re-export. Unknown PPTX parts are preserved by the writer, but hand-edited XML can break content types or relationships (`docs/architecture.md:64-69`).
- Convert between `.deckcraft`, `.pptx`, `.pdf`, `.txt`/`.md` and images with `convert`, but remember `convert` writes only the first slide for PNG/JPEG and uses default PDF options (`apps/deckcraft-cli/src/main.rs:404-423`).

### Verify exports
- Read the command result: exports return `{path, bytes}` or `{files}`; check the file exists and its size is plausible (`crates/engine/src/cmd/file.rs:481-545`). A zero-byte or missing file is a failure even if the process exited 0.
- Re-open the result: `deckcraft-cli info out.pptx` and compare slide count/titles/layouts with the source; `deckcraft-cli render out.pptx --all` and look at the PNGs.
- For PDF, inspect page count and extracted text (e.g. `pdfinfo`, `pdftotext`, Preview); the text layer should be selectable but the artwork is raster (`crates/pdf/README.md:3-6`).
- For `.pptx`, the strongest test is opening it in PowerPoint/Keynote and checking for a repair prompt, animations, media and theme fonts. The project has not tested a real-deck corpus (`docs/gaps.md:67-92`).
- For GIF, verify the `GIF89a` header, dimensions, frame count and delay; transitions/builds are intentionally absent (`crates/engine/src/gif_export.rs:1-8`).

### Do not
- Do not insert SVG, HEIC, EMF/WMF (via `insert.picture`) and expect them to draw.
- Do not promise `.ppt`, `.odp`, `.pptm`, macros, password protection or MP4 export.
- Do not call `file.close` or `app.quit` on unsaved work; use `app.quit {"save": true}` or save explicitly.
- Do not use `file.save`/`--save` for `.png`/`.jpg`; use `file.export`/`--export` (otherwise native zip bytes get an image extension).
- Do not assume PDF is vector or that a `.pptx` round-trip is lossless.
- Do not rely on font metrics matching PowerPoint exactly; substitute faces change line breaks. Verify visually.
- Do not expose the control channel beyond loopback; it has no authentication.

## Verification protocol

Alpha software with active auto-updates: verify every deliverable, keep a native master, and never trust a silent export.

1. **Pin the version.** Record `deckcraft --version` and the bundle build commit before work. Update only between projects, not mid-deck; file formats and command sets move between releases (`apps/deckcraft/src/main.rs:179-181`; `/Applications/DeckCraft.app/Contents/Info.plist`).
2. **Work in a throwaway directory.** Copy sources in; never run destructive tests on the only copy of a deck. Keep a `.deckcraft` master plus dated backups.
3. **Round-trip a small test first.** New deck → add one slide, shape, table, chart, picture, transition and note → save `.deckcraft` → export `.pptx` → reopen the `.pptx` → inspect counts and render PNGs. Fix workflow problems before touching the real deck.
4. **Save before every export.** A failed export must not be the only copy of your changes. `file.save` is atomic via a `.saving` sibling, but exports are ordinary writes (`crates/engine/src/io.rs:20-50`).
5. **Check every export explicitly.** Assert file existence and non-zero size; for images check dimensions; for PDF check page count and selectable text; for PPTX reopen and render; for GIF check header, dimensions and frame count.
6. **Look at the pixels.** `deckcraft-cli render … --all` (or MCP `render_slide`) and inspect the PNGs. Text overflow, missing fonts, blank SVG/EMF pictures and chart scaling are visual failures that a successful exit code will not catch.
7. **Open in the target app.** If PowerPoint is available, open the exported `.pptx` and check for repair prompts and lost animations/media. If not, state that fidelity is unverified rather than claiming parity.
8. **Keep the native file.** PowerPoint export is an exchange copy; the `.deckcraft` master preserves DeckCraft-only constructs and is the safest thing to reopen after a failure.
9. **Record what changed.** Note version, command lines/JSON params, export options and any manual GUI steps, so a failed export can be reproduced.

## Sources & evidence

- **Repo:** https://github.com/storytold/deckcraft — tag `v0.8.0`, commit `22db9261f9d1a214c296fd390173130c45d76d66` (`git rev-parse HEAD`), inspected 2026-10-18.
- **Installed bundle:** `/Applications/DeckCraft.app`, `CFBundleIdentifier ai.storyteller.deckcraft`, version `0.8.0`, `DeckCraftBuildCommit` equal to the commit above. `--version` prints `deckcraft 0.8.0`.
- **Key files read:** `README.md`; `ROADMAP.md`; `Cargo.toml`; `docs/architecture.md`; `docs/gaps.md`; `docs/file-format-parity.md`; `docs/animation-parity.md`; `docs/ui-parity.md`; `docs/mcp.md`; `docs/control-protocol.md`; `apps/deckcraft/src/main.rs`; `apps/deckcraft-cli/src/main.rs`; `apps/deckcraft-cli/src/help.rs`; `crates/engine/src/lib.rs`; `crates/engine/src/cmd/{mod,file,slide,insert,shape,text,format,design,table,smartart,animation,transition,review}.rs`; `crates/engine/src/{io,recovery,gif_export,icons,templates}.rs`; `crates/format/src/lib.rs`; `crates/pptx/src/lib.rs` and `crates/pptx/tests/roundtrip.rs`; `crates/pdf/src/lib.rs` and `crates/pdf/README.md`; `crates/model/src/{lib,theme,chart,anim}.rs`; `crates/geom/src/preset.rs`; `crates/render/src/images.rs`; `crates/media/src/lib.rs`; `crates/mcp/src/{tools,server}.rs`; `crates/ui-egui/src/{lib,show,menus,ribbon,backstage,dialogs,control,doc_window}.rs`; `apps/deckcraft-web/src/{main,web}.rs`; `packaging/macos/package.sh`.
- **Shared library:** `craft-pdf` is pinned to `storytold/craft-libs` rev `c3487320b2d1de657b860b3c8abb44e1f2b32bd8` (`Cargo.toml:60`); its writer uses `write` only (`crates/pdf/README.md:3-12`).
- **Docs that are stale:** `docs/file-format-parity.md` says `.potx`/`.ppsx` are written with the `.pptx` content type and `.thmx` is unreadable; v0.8.0 code writes the correct content types and imports `.thmx` (`crates/pptx/src/lib.rs:76-84`; `crates/engine/src/cmd/design.rs:23, 148-174`). Much of `docs/gaps.md` was last reviewed 2026-10-14, before this release; code wins where they disagree.
- **Not independently verified:** PowerPoint’s acceptance of exported `.pptx` without repair, render fidelity against PowerPoint, and behaviour on real-world decks of unknown provenance. Treat those as claims until you test them.

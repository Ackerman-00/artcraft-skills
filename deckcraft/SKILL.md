---
name: deckcraft
description: >-
  DeckCraft is the ArtCraft open-source, clean-room PowerPoint-compatible presentation app for
  macOS (also Windows, Linux, FreeBSD and the web): slides, masters and layouts, shapes, 3-D,
  text, tables, charts, SmartArt, media, transitions, animations, slide shows, `.pptx`/`.potx`/
  `.ppsx` and `.deckcraft` files, PDF/PNG/JPEG/GIF export, a 12-subcommand CLI, a 25-method JSON
  control channel and a 25-tool MCP server. Trigger this skill whenever the user mentions
  DeckCraft, `.deckcraft`, `deckcraft-cli`, asks what DeckCraft can or cannot do, which formats or
  shortcuts it supports, wants to build, edit, inspect, convert, render, present, export, verify,
  repair or troubleshoot a deck, wants assets prepared for it, or wants it automated or scripted —
  even if the app is not named but the job is presentation work ("make a deck", "turn this outline
  into slides", "export these slides to PDF", "why did my PPTX lose its animations?", "drive a
  presentation app with an agent"). Do not use it for Microsoft PowerPoint itself.
---

Audit basis: this checkout is tag `v0.10.0`, commit `b47195feec0f0fe4220d8943ad1c8add5dad8072`. The installed `/Applications/DeckCraft.app` reports version `0.10.0` (`CFBundleShortVersionString` 0.10.0, `DeckCraftBuildCommit` equal to that commit) and its binary prints `deckcraft 0.10.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Deep detail — every command family, shortcut, control method, MCP tool, format option and runtime path — is in `references/commands-and-formats.md`.

## Overview

DeckCraft is a clean-room, open-source (MIT OR Apache-2.0), pure-Rust presentation application targeting Microsoft PowerPoint parity — and superiority in speed, openness and agent control (AGENTS.md:3-7; README.md; Cargo.toml:9). It builds decks with masters, eleven standard layouts, themes, shapes, text, tables, charts, SmartArt, audio and video; presents them full screen with transitions and animations; and exchanges PowerPoint `.pptx` plus its own `.deckcraft` format (README.md; `crates/model/src`; `crates/pptx`). It is **alpha**: v0.10.0 claims **84% feature breadth** (P0 92%, P1 82%, P2 55%) and **~55% ready for real work** by its own measurement (ROADMAP.md:3,13-24; `docs/parity-checklist.md`). Native builds target macOS, Windows, Linux and FreeBSD, plus a WebAssembly site (README.md §Downloads; `apps/deckcraft-web`). Source: GitHub `storytold/deckcraft` (Cargo.toml:9).

Everything user-visible is a **command with an id**, and `Session::execute` is the single dispatch path used by the ribbon, keyboard, CLI, control channel and MCP (`crates/engine/src/cmd/mod.rs`; `crates/engine/src/lib.rs:581`).

## Capabilities (verified)

### Automation surface at a glance

| Surface | Count at v0.10.0 | Change vs the v0.9.0 skill |
|---|---|---|
| Engine commands (`CommandSpec`) | **320** (229 ordinary + 55 `noundo` + 36 `query`) | unchanged; ids re-counted and unique |
| Command modules (`crates/engine/src/cmd/*.rs` minus `mod.rs`) | **28** | unchanged |
| Engine shortcuts | **57** | unchanged |
| UI-only commands (`UI_COMMANDS`) | **50**, 15 with shortcuts | unchanged |
| CLI subcommands | **12** (`info render render-transition convert run commands describe app mcp bench links version`) | unchanged |
| Control-channel methods | **25** canonical + 2 aliases (`ui.menu.invoke`, `command`) | unchanged |
| MCP tools | **25**, plus `deckcraft://document` and `deckcraft://commands` | unchanged |
| Transitions / animations | **49** rows (48 + None) / **107** entries (24 entrance, 17 emphasis, 23 exit, 40 motion-path incl. Custom Path, 3 media) | animation count corrected from 106 (Custom Path was counted apart); no code change |
| Themes / layouts / presets | **8** themes × 4 colour variants / **11** layouts + `Custom` / **183** shape presets | unchanged |
| Charts / SmartArt / starters | **28** chart types (7 `chartEx`) / **45** layouts, 9 styles, 17 colour sets / **6** starter decks | unchanged |

Every count above was recomputed at this tag from the registries: commands `crates/engine/src/cmd/mod.rs`; transitions and animations `crates/model/src/anim.rs`; themes and layouts `crates/model/src/{theme,lib}.rs`; presets `crates/geom/src/preset.rs`; charts `crates/model/src/chart.rs`; SmartArt and starters `crates/engine/src/{cmd/smartart,templates}.rs`; UI commands and shortcuts `crates/ui-egui/src/lib.rs`; CLI `apps/deckcraft-cli/src/help.rs`; control methods `crates/ui-egui/src/control.rs`; MCP tools `crates/mcp/src/tools.rs`.

New at this tag is the **desktop hand-off**: macOS now declares `.deckcraft`, `.pptx`, `.potx` and `.ppsx` in `CFBundleDocumentTypes`, and `apps/deckcraft/src/apple_events.rs` handles Finder double-click, Open With, Dock drops and quit through the pinned `fmv-macos-events` crate; Windows and Linux declare the same four types, kept equal by a test (`packaging/macos/Info.plist.in`; `packaging/windows/deckcraft.wxs`; `packaging/linux/ai.storyteller.deckcraft.desktop`; `apps/deckcraft/src/main.rs`). Other changes: bad slide indices are rejected instead of falling back to the selection, deleting a shape clears animation triggers that pointed at it, and cut with only a caret is a no-op (`crates/engine/src/cmd/{mod,slide,edit}.rs`). **No command, MCP tool, control method, CLI subcommand, format or shortcut was added or removed**; the counts above are unchanged and were re-counted from the code. See `references/commands-and-formats.md` §“What changed”.

The MCP surface is 25 tools: `list_commands`, `run_command`, `batch`, `new_presentation`, `open_presentation`, `save_presentation`, `export`, `inspect_document`, `inspect_slide`, `render_slide`, `add_slide`, `go_to_slide`, `add_shape`, `add_text_box`, `set_text`, `insert_picture`, `insert_table`, `insert_chart`, `select`, `pointer`, `select_tool`, `key`, `type_text`, `screenshot` and `call_app` (the last two connected-mode only; full table in `references/commands-and-formats.md`).

### Deck structure and design
- **Slides, masters and layouts.** Eleven standard layout kinds (Title, Title and Content, Section Header, Two Content, Comparison, Title Only, Blank, Content with Caption, Picture with Caption, Title and Vertical Text, Vertical Title and Text) plus `Custom` (`crates/model/src/lib.rs:679-692`). Slide masters, notes master, handout master, placeholder inheritance, sections, notes, comments, headers/footers and custom shows are modelled (`crates/model/src`; `crates/engine/src/cmd/{slide,design,review}.rs`).
- **Themes.** Eight original themes — DeckCraft, Harbor, Ember, Meadow, Nocturne, Paper, Coral Reef, Slate — each with colour, font and effect schemes and four colour variants (`crates/model/src/theme.rs:155-260`; `crates/engine/src/cmd/design.rs`). Browse for Themes imports `.thmx`, `.pptx` or `.potx` (`crates/pptx/src/lib.rs::import_theme`; `crates/engine/src/cmd/design.rs`).
- **Starter decks.** Six originals — Briefing, Lesson, Pitch, Field Notes, Quarterly, Evening Talk — via `file.new {template}` / `file.templates` (`crates/engine/src/templates.rs`).
- **Shapes.** 183 preset shape/connector generators in nine categories, with adjust handles, glued connectors, freeform/curve/scribble tools, merge operations, gradient/picture/pattern fills, dashes, arrowheads, shadows, glow, soft edges and reflections (`crates/geom/src/preset.rs`; `crates/engine/src/cmd/{shape,merge,arrange}.rs`).
- **3-D.** Format Shape ▸ 3-D Format/Rotation: 28 camera presets offered, 12 bevels, 12 materials, 15 light rigs, X/Y/Z rotation, depth and contour; `a:scene3d`/`a:sp3d` stay as raw XML and round-trip (`crates/engine/src/cmd/three_d.rs`; `crates/engine/src/cmd/shape.rs::effects`). Rendered approximately — see limitations.
- **Text.** In-place editing with DrawingML run and paragraph properties, bullets and numbering, columns, autofit, vertical and RTL text, fields, hyperlinks, tab stops, line spacing and 40 text warps (`crates/engine/src/cmd/{text,format}.rs`; `crates/model/src/text.rs`; `crates/geom/src/warp.rs`).
- **Tables.** Styled tables with cell merges (including diagonal borders), row/column insert/delete, distribution, widths/heights, borders, cell fill/margins/alignment and draw/erase line (`crates/engine/src/cmd/table.rs`).

### Content
- **Pictures.** PNG, JPEG, GIF (including animated), WebP, BMP and TIFF decode; EMF/WMF draw through `deckcraft-metafile` when they arrive in a deck (`crates/render/src/images.rs`; `crates/metafile/src/lib.rs`). Crop, brightness/contrast, duotone, alpha, artistic effects and compress are modelled (`crates/engine/src/cmd/{shape,artistic,compress}.rs`).
- **Charts.** 28 types, including the seven Office-2016 `chartEx` types (waterfall, funnel, histogram, Pareto, box & whisker, treemap, sunburst), plus radar, stock, region map (kept and drawn, not in menus) and combo (`crates/model/src/chart.rs:9-60`). `insert.chart`, `chart.data`, `chart.type`, `chart.options`; six trendline kinds draw with forecast and equation/R²; an unchanged chart's embedded workbook survives save and native round-trip (`crates/engine/src/cmd/insert.rs`; `docs/gaps.md`).
- **SmartArt.** A graphic is a group whose outline is edited in a Text Pane; 45 layouts, 9 styles, 17 colour sets, Add/Promote/Demote/Remove, layout switching, picture fill and convert-to-shapes; written to `.pptx` as a real diagram (`crates/engine/src/cmd/smartart.rs`; `crates/pptx/src/dgm.rs`).
- **Media.** Audio: MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg Vorbis and Opus. Video: H.264, HEVC, VP9 and AV1 in MP4/MOV and WebM/Matroska, decoded in software in pure Rust (`crates/media/src/lib.rs:3-10`; `crates/engine/src/cmd/insert.rs`).
- **Other insertables.** 70 Lucide 1.56.0 stroke icons as custom shapes (`insert.icon`), WordArt, symbols, date/time fields, slide numbers, photo albums, and an Equation dialog that inserts pretty-printed text (not OMML) (`crates/engine/src/icon_data.rs`; `crates/engine/src/cmd/insert.rs`; `crates/ui-egui/src/dialogs.rs::pretty_equation`).

### Presenting
- **48 transitions plus “None”** (49 rows), including Morph, each with effect options; measured frame by frame against PowerPoint video export (`crates/model/src/anim.rs:52-101`; `docs/animation-parity.md`).
- **Animations.** 107 picker entries: 24 entrance, 17 emphasis, 23 exit, 40 motion-path (39 presets + Custom Path) and 3 media controls; start modes, by-paragraph builds, triggers, repeat and bounce end (`crates/model/src/anim.rs:320-437`; `crates/engine/src/cmd/animation.rs`).
- **Slide show.** Full-screen show, presenter view in a second window, pen and laser pointer, black/white screens, See All Slides, zoom, hyperlinks/actions, custom shows, rehearse timings and media playback (`crates/ui-egui/src/show.rs`; `docs/slideshow-parity.md`). A `.ppsx` given on the command line starts its show (`apps/deckcraft/src/main.rs`; `crates/ui-egui/src/lib.rs::open_from_system`).
- **Views.** Normal, Outline, Slide Sorter, Notes Page and Reading; slide/notes/handout master views (`crates/ui-egui/src/lib.rs`; `crates/engine/src/cmd/design.rs`).

### Files
- **Native `.deckcraft`:** a zip with a stored `mimetype`, `presentation.json`, `media/<id>` and bounded `chart-parts/<index>` entries; format version 1; readers ignore unknown fields, and legacy `.slidecraft` files still open (`crates/format/src/lib.rs`). Load budgets: 2 GiB per entry, 4 GiB total media + chart sidecars, 100 000 items.
- **PowerPoint `.pptx`:** read and write; `.potx` and `.ppsx` are written with their own content types (`crates/pptx/src/lib.rs::export_as`). Unknown parts are kept where the model does not understand them (`docs/architecture.md`). Embedded fonts are read and written; MicroType Express subsets are kept but not drawn.
- **Outline text:** `.txt` and `.md` import (Markdown headings become slides; `slide.fromOutline`, `file.open`) and `.txt`/`.md` export including table cell text (`crates/format/src/lib.rs`; `crates/engine/src/cmd/slide.rs`).
- **PDF:** slides, notes pages or handouts (1/2/3/4/6/9), Letter/A4/Legal/A3, portrait/landscape, hidden-slide and slide-range options, selectable invisible text layer, links and bookmarks; slide artwork itself is a raster image (`crates/pdf/src/lib.rs`; `crates/engine/src/cmd/file.rs::pdf_options`).
- **Images and GIF:** PNG/JPEG per slide (one, `slide`, or `all`; `transparentBackground` leaves the background out; DPI = scale × 72) and an animated GIF of the deck (one frame per slide, per-frame 256-colour palette, 16–3840 px wide, 0.1–600 s per slide, loop or play once, slide range, hidden slides skipped) (`crates/engine/src/cmd/file.rs::export`; `crates/engine/src/gif_export.rs`).
- **AutoRecover:** unsaved presentations are written to a recovery folder and reopened at the next start; saving or closing removes the entry (`crates/engine/src/recovery.rs`; `apps/deckcraft/src/main.rs`).

### Platforms
- **macOS universal app**, signed, notarized and stapled (verified with `codesign`/`spctl`); Windows x64/arm64/x86, Linux (AppImage, Flatpak, deb, rpm, tarball; riscv64 tarball), FreeBSD and a static WebAssembly site (README.md §Downloads; `packaging/`).
- Rendering is CPU-side through `vello_cpu`; the UI is `egui`/`eframe` (Cargo.toml:57; `docs/architecture.md`). The web build uses WebGPU with a WebGL2 fallback (`?webgl`), starts blank or in show with `?blank`/`?show`, downloads files instead of saving, has no audio output and no TCP control channel (`apps/deckcraft-web/src/main.rs`; `apps/deckcraft-web/src/web.rs`).

## Known limitations and not-implemented

### File exchange and PowerPoint fidelity
- **No external deck corpus.** Every PPTX test uses decks authored in this repo; fidelity on real corporate decks, templates, fonts and `chartex` is mostly unmeasured, and “opens in PowerPoint without repair” is a docs claim (hand-checked 2026-10-06), not independently verified here (`docs/gaps.md`; `docs/file-format-parity.md`).
- **Known PPTX round-trip losses:** media playback options and animation rewind are not written back (#74, #77); a combo chart's secondary value axis is read but not written when the chart is rebuilt; editing a chart drops its embedded workbook (an unchanged chart keeps it); imported SmartArt is redrawn with DeckCraft's simpler layouts; relationship-bearing SmartArt/OLE kept only as XML loses drawing and data parts (#203) (`docs/gaps.md`; `docs/file-format-parity.md`).
- **Unsupported input:** legacy `.ppt`/`.pot`/`.pps` and OpenDocument `.odp` are not read; `.pptm`/`.potm`/`.ppsm` are not recognised and macros are neither preserved nor run; password-protected decks fail with a clear error and there is no password protection on save; outline import is `.txt`/`.md`, no RTF (`crates/engine/src/cmd/file.rs::open_other`; `docs/file-format-parity.md`).
- **A Finder-open `.ppsx` does not start its show.** The macOS Apple-event handler opens paths with `open_path`, while only the command-line path (`open_from_system`) checks for `.ppsx`; double-clicked shows open for editing (`apps/deckcraft/src/apple_events.rs`; `apps/deckcraft/src/main.rs`). The progress log and `docs/file-format-parity.md` claim otherwise for the file-association path — verify your build.
- **Internal docs lag the code.** `docs/file-format-parity.md` still says `.potx`/`.ppsx` get the `.pptx` content type and `.thmx` is unreadable; the code writes the correct content types and imports `.thmx`. `docs/animation-parity.md` says 14 exits (code: 23). `docs/gaps.md` says 15 SmartArt layouts/4 styles (code: 45/9/17). Trust the code and `deckcraft-cli describe`.

### Pictures and media
- **SVG is not rendered.** `insert.picture` accepts `image/svg+xml`, but the renderer has no SVG decoder, so an inserted SVG is not drawn; a PPTX that stores a PNG fallback beside its SVG shows that fallback (`crates/engine/src/cmd/insert.rs`; `crates/render/src/images.rs`; `docs/gaps.md`).
- **HEIC is not supported**, WMA/WMV are recognised but not decoded, and online video embeds are not supported (`docs/file-format-parity.md`; `crates/media/src/lib.rs`). EMF/WMF render inside decks but are not sniffed by `insert.picture`.
- **Web build is silent:** no audio output, no TCP control channel, no persisted preferences (`apps/deckcraft-web/src/main.rs`).

### Output
- **PDF artwork is rasterized.** Each slide is placed as a print-DPI image under an invisible real-text layer; text is selectable/searchable but the artwork is not vector (`crates/pdf/src/lib.rs`; `crates/pdf/README.md`; `docs/gaps.md`).
- **No native print dialog.** File ▸ Print (Cmd+P) builds a PDF in the temp folder and opens it in the system viewer; there is no printer list, copies, sides or colour choice (`crates/ui-egui/src/lib.rs::print_pdf`; `docs/ui-parity.md`).
- **No MP4/MOV export.** Only the animated GIF exists: one static frame per slide, no transitions or build animations; caps 500 frames, 3840 px side, 200M total pixels (`crates/engine/src/gif_export.rs`; `docs/gaps.md`).

### Platform and UI
- **No native macOS menu bar.** `menus::menu_tree()` exists but nothing installs it; use the ribbon, the command palette (Cmd+Shift+P) or commands (`crates/ui-egui/src/menus.rs`; `docs/ui-parity.md`).
- **Presenter view is a second window but is not assigned to the second display** (`docs/gaps.md`; `docs/slideshow-parity.md`).
- **CPU rasterization and software video decode**; no GPU slide rendering or hardware decode (Cargo.toml:57; `crates/media`; `docs/hardware-parity.md`).
- **English-only UI**, no string catalogue (`docs/localization-parity.md`; no i18n module under `crates/ui-egui/src`). No pinch-zoom that keeps the point under the pointer; pen pressure works, tilt does not (`docs/gaps.md`; `docs/hardware-parity.md`).

### Feature depth
- **Charts are partial:** chart element editing and some `chartex` behaviour are thinner than PowerPoint's; the secondary axis and stale-workbook issues above (`docs/gaps.md`).
- **Animations are partial:** 64 non-path effects of roughly 190 in PowerPoint; preview plays the slide from the start, not from the selected effect (`docs/gaps.md`; `docs/animation-parity.md`).
- **SmartArt is shallow:** DeckCraft has 45 simple layouts against PowerPoint's ~200, including picture and 3-D styles (`docs/gaps.md`).
- **No recording:** the Record tab's Record button is disabled (“Recording narration needs audio capture”) (`crates/ui-egui/src/ribbon.rs`).
- **Equations are not OMML:** the Equation dialog inserts pretty-printed text; OMML is neither read nor written (`crates/ui-egui/src/dialogs.rs`; `docs/file-format-parity.md`).
- **No AI/cloud features** (Copilot/Designer/Speaker Coach/live captions); only offline Design Ideas arrangements. **No add-ins or VBA** by policy; MCP/CLI is the automation alternative (`docs/gaps.md`).

### Automation and data-safety behaviours to know
- **`file.close` closes a dirty document without prompting.** The UI's Close (`app.closePresentation`, Cmd+W) prompts; the raw engine command does not (`crates/engine/src/cmd/file.rs::close`; `crates/ui-egui/src/lib.rs::close_presentation`). Do not call `file.close` on unsaved work.
- **`app.quit` over the control channel quits without asking.** `{"save": true}` saves every presentation first, but an untitled document still opens a Save dialog, so save explicit paths before quitting (`crates/ui-egui/src/control.rs`).
- **`file.save`/`file.saveAs` without a `path` (and no stored path) ask the UI** and return `{"needsPath": true}`, writing nothing in headless use — always pass `path` (`crates/engine/src/cmd/file.rs::save`).
- **Do not use `file.save`/`run --save` for `.png`/`.jpg`.** `save_bytes` handles `pptx|potx|ppsx`, outline, `pdf`, `gif` and falls back to native `.deckcraft` zip bytes for anything else — a `.png` path writes native bytes under the image name (`crates/engine/src/cmd/file.rs::save_bytes`). Use `file.export`/`--export`/`convert`. MCP `save_presentation` and control-channel `app.save` inherit the trap.
- **`run` stops at the first failing command and saves nothing** (`apps/deckcraft-cli/src/main.rs::run`).
- **The control channel has no authentication.** It binds loopback only; do not expose or port-forward it (`apps/deckcraft/src/control_server.rs`; `docs/control-protocol.md`).

## How to operate

### Check what is installed
```sh
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --version   # prints: deckcraft 0.10.0
command -v deckcraft-cli                                          # headless CLI is a separate download
```
The `.app` bundle contains no `deckcraft-cli`. The CLI ships as the separate signed/notarized release asset `deckcraft-cli-<ver>-macos-universal.zip` (README.md §Downloads; `packaging/macos/package.sh`). Download/unzip it, build it with `cargo build --release -p deckcraft-cli`, or automate through the control channel instead.

### Launch
```sh
open -a DeckCraft                          # normal GUI
open -a DeckCraft --args --sample          # sample deck
open -a DeckCraft talk.pptx                # open a file
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --control 7990 --sample
```
GUI flags: `--control PORT`, `--sample`, `--show`, `--help`, `--version`, and file paths (`apps/deckcraft/src/main.rs`). The port can also come from `DECKCRAFT_CONTROL_PORT`. The app opens `.deckcraft`, `.pptx`, `.potx`, `.ppsx`, `.txt` and `.md` (outlines), and applies `.thmx`/`.pptx`/`.potx` themes via `design.browseTheme` (`crates/engine/src/cmd/file.rs::open_other`; `crates/engine/src/cmd/design.rs`). A `.ppsx` given last on the command line starts its show; a Finder double-click opens it for editing (see limitations).

### CLI
`deckcraft-cli` is the most reliable automation surface; it needs no window. The subcommands and flags below are from `apps/deckcraft-cli/src/help.rs` and `apps/deckcraft-cli/src/main.rs`.

| Command | What it does |
|---|---|
| `deckcraft-cli info FILE` | JSON: slides, layouts, theme fonts, sections, slide size (`document.inspect`) |
| `deckcraft-cli render (FILE \| --sample) [--slide N \| --all] [--scale S] [--edit] [--transparent] OUT` | PNG per slide; `--all` writes `slide-01.png…`; default scale 2; `--slide` 0-based |
| `deckcraft-cli render-transition FILE --slide N --t T[,T...] [--width PX] OUT.png` | Frames of the transition into slide N |
| `deckcraft-cli convert IN OUT` | Save in OUT's extension: `.deckcraft`, `.pptx`/`.potx`/`.ppsx`, `.pdf`, `.txt`/`.md`, `.png`/`.jpg` (first slide), `.gif` |
| `deckcraft-cli run [--in FILE \| --sample] [--cmd ID[=JSON]]... [--save OUT] [--export OUT [--export-params JSON]] [--print]` | Run commands, then save/export; stops and saves nothing on the first error |
| `deckcraft-cli commands [FILTER]` / `describe COMMAND` | List ids/params; explain one |
| `deckcraft-cli app [--port PORT] COMMAND [JSON]` / `--method METHOD [JSON]` | One request to a running `deckcraft --control` (default port 7979) |
| `deckcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR] [--automation-write-root DIR]` | MCP server on stdio |
| `deckcraft-cli bench (FILE \| --sample) [--runs N] [--json]` | Time open/draw/save/PPTX reopen/PDF export and peak memory |

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
`--print` prints each command's **answer**; it is not a printer flag. `convert` gives no PDF-layout options and only the first slide for PNG/JPEG; use `run --export` or `file.export` for notes/handouts and all slides.

### Conventions that prevent most automation bugs
- Coordinates are **points** on a 960×540 (16:9) slide unless the deck says otherwise; a rect is `[x, y, width, height]` (`crates/model/src/defaults.rs`; `apps/deckcraft-cli/src/help.rs`).
- **Slide indices are 0-based**; image files written by `render --all` are named from 1 (`slide-01.png`), while `file.export all` names `stem1.png`, `stem2.png` (`crates/engine/src/cmd/file.rs::export`).
- **Shape ids are looked up on the current slide only**; `slide.go {index}` changes the current slide; `slide.new` inserts after it and selects the new slide (pass `at` for an index) (`apps/deckcraft-cli/src/help.rs`; `crates/engine/src/cmd/slide.rs`).
- Commands that add a shape select it; `format.*` acts on the selection, while many shape commands take `ids` directly.
- Text bodies use `\n` for a new paragraph and a leading tab per level for bullets (`crates/engine/src/cmd/slide.rs`).
- Index parameters are strict on the commands this tag fixed (`slide.duplicate`, `slide.delete`, `slide.move`, `slide.reset`, `slide.hide`, `slide.notes`, `section.add`): a negative or fractional value is an error, not “act on the selection” (`crates/engine/src/cmd/mod.rs::opt_usize_param`). `slide.layout` still treats an invalid `index` as absent and acts on the current selection — pass a valid 0-based index.

### Documents, open/save/export
- One process can hold several presentations; `file.new`/`file.open` add documents, `window.next` cycles the active one, and `view.newWindow` opens a second, non-editing window on the same deck (`crates/engine/src/cmd/file.rs`; `crates/ui-egui/src/doc_window.rs`).
- **Open:** `file.open {path}` — native `.deckcraft`, `.pptx`/`.potx`/`.ppsx`, `.txt`/`.md` outlines. Open is lenient for PPTX (unknown parts skipped/kept, unreadable slides reported in `lostSlides`, damaged files open as a repaired copy) and background-loaded in the GUI (`crates/engine/src/cmd/file.rs`; `crates/ui-egui/src/opening.rs`).
- **Save:** `file.save {path, format?: deckcraft|pptx}` / `file.saveAs {path, format?}` / `file.saveTemplate {path}`; the format follows the extension unless `format` is given. **For `.png`/`.jpg`, use `file.export`.** Writes go to a unique `.saving` sibling renamed over the target, so a failed save never truncates the old file (`crates/engine/src/io.rs`).
- **Export:** `file.export {path, format?, ...}`. PNG/JPEG: `slide?`/`all?`/`scale?`/`transparentBackground?`; PDF: `layout`, `perPage`, `paper`, `orientation`, `dpi`, `slides`, `includeHidden`, `textLayer`, `frame`; GIF: `width`, `secondsPerSlide`, `loop`, `slides`, `includeHidden` (`crates/engine/src/cmd/file.rs`). All requested image indices are validated before any file is written.
- **Native format as source of truth:** keep the `.deckcraft` master and treat `.pptx` as an exchange copy. Native save is lossless for DeckCraft's model (chart payloads included); PPTX has the known losses above (`crates/format/src/lib.rs`; `docs/gaps.md`).

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
Use `ui.inspect` first to learn window/canvas/slide rects, the active tool, dialogs and documents; `ui.pointer` takes **slide points**, `ui.click`/`ui.drag` take **screen points** (`docs/control-protocol.md`; `crates/ui-egui/src/control.rs`). The MCP equivalent is `deckcraft-cli mcp --connect 7990`. For headless MCP:
```json
{"mcpServers":{"deckcraft":{"command":"deckcraft-cli",
  "args":["mcp","--automation-read-root","work/deck","--automation-write-root","work/deck/out"]}}}
```
Paths outside the roots are refused with ordinary tool errors; `--connect` and roots cannot be combined (`docs/mcp.md`; `crates/engine/src/file_access.rs`).

### Environment and logs
- Settings/logs: `~/Library/Application Support/DeckCraft/` (`ui.json`, `prefs.json`, `logs/deckcraft.log`, rotated, capped at 16 MiB); recovery: `…/DeckCraft/Recovery/` (`apps/deckcraft/src/main.rs::config_dir`; `apps/deckcraft/src/logging.rs`; `crates/engine/src/recovery.rs`).
- `DECKCRAFT_CONTROL_PORT` sets the control port; `DECKCRAFT_NO_AUDIO=1` plays silently; `DECKCRAFT_NO_PREFS=1` skips preferences; `DECKCRAFT_NO_RECOVERY=1` skips AutoRecover; `RUST_LOG` sets log levels (default `info` for DeckCraft crates, `warn` otherwise) (`apps/deckcraft/src/main.rs`; README.md §Logs).

## Working with an AI agent

### Choose the surface
1. **Headless CLI** (`deckcraft-cli run`, `render`, `convert`, `info`, `mcp`) — best for generating decks, batch exports and verification. No window, no GUI state.
2. **MCP stdio** (`deckcraft-cli mcp`) — best when the agent has an MCP client; use `run_command`/`batch` for anything the 25 tools do not wrap, and `inspect_document`/`inspect_slide` before editing. A headless server starts with no document: call `new_presentation` or `open_presentation` first. `batch` stops at the first error unless `keepGoing`; tools reject unknown argument names rather than guessing (`crates/mcp/src/tools.rs`; `crates/mcp/src/headless.rs`).
3. **Control channel** (`deckcraft --control`) — only when a human and agent must share a live window, or UI-only state (dialogs, selection, screenshots) matters. Always `ui.inspect`/`ui.screenshot` before pointer work; never click blind.

### Prepare inputs
- **Pictures:** PNG, JPEG, WebP, GIF, BMP, TIFF (not SVG, not HEIC). Pre-render logos and icons to PNG with transparency; for overlays on slides, PNG + `transparentBackground` export round-trips.
- **Audio/video:** MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg, Opus; H.264/HEVC/VP9/AV1 in MP4/MOV/WebM/MKV (`crates/media/src/lib.rs`). Transcode WMA/WMV first.
- **Outlines:** a `.md` file with `#` headings (one slide per heading, list items as bullets) or a tab-indented `.txt` outline imports directly (`crates/format/src/lib.rs`; `slide.fromOutline`).
- **Themes:** `.thmx` or a `.pptx`/`.potx` whose first master holds the theme (`crates/pptx/src/lib.rs::import_theme`).

### Inspect, repair and convert
- `.deckcraft` is a zip: inspect `presentation.json`, `media/<id>` and `chart-parts/<index>` with `unzip -l`/`unzip -p`. Repair damaged media by restoring the member; do not rewrite the JSON unless the schema is understood (`crates/format/src/lib.rs`). Older files with inline chart bytes still load and migrate on save.
- Do **not** hand-edit a `.pptx` zip to “fix” it: use DeckCraft commands and re-export. Unknown PPTX parts are preserved by the writer, but hand-edited XML can break content types or relationships (`docs/architecture.md`).
- Convert between `.deckcraft`, `.pptx`, `.pdf`, `.txt`/`.md` and images with `convert`, but `convert` writes only the first slide for PNG/JPEG and uses default PDF options (`apps/deckcraft-cli/src/help.rs`).

### Verify exports
- Read the command result: exports return `{path, bytes}` or `{files}`; assert the file exists and its size is plausible. A zero-byte or missing file is a failure even if the process exited 0 (`crates/engine/src/cmd/file.rs`).
- Re-open the result: `deckcraft-cli info out.pptx` and compare slide count/titles/layouts; `deckcraft-cli render out.pptx --all` and look at the PNGs.
- For PDF, check page count and extracted text (e.g. `pdftotext`); the text layer is selectable but the artwork is raster (`crates/pdf/README.md`).
- For `.pptx`, the strongest test is opening it in PowerPoint/Keynote and checking for a repair prompt, animations, media and theme fonts. The project has not tested a real-deck corpus (`docs/gaps.md`).
- For GIF, verify the `GIF89a` header, dimensions, frame count and delay; transitions/builds are intentionally absent (`crates/engine/src/gif_export.rs`).

### Do not
- Do not insert SVG, HEIC, or EMF/WMF via `insert.picture` and expect them to draw.
- Do not promise `.ppt`, `.odp`, `.pptm`, macros, password protection or MP4 export.
- Do not call `file.close` or `app.quit` on unsaved work; use `app.quit {"save": true}` only after saving explicit paths, or save each document first.
- Do not use `file.save`/`--save` for `.png`/`.jpg`; use `file.export`/`--export`/`convert` (otherwise native zip bytes get an image extension).
- Do not assume PDF is vector or that a `.pptx` round-trip is lossless.
- Do not rely on font metrics matching PowerPoint exactly; substitute faces change line breaks. Verify visually.
- Do not expose the control channel beyond loopback; it has no authentication.
- Do not trust `docs/` where it contradicts the code (content types, `.thmx`, SmartArt counts, animation exits are stale at this tag).

## Verification protocol

Alpha software with active auto-updates: verify every deliverable, keep a native master, and never trust a silent export.

1. **Pin the version.** Record `deckcraft --version` and the bundle build commit before work. Update only between projects, not mid-deck; formats and command sets move between releases (`apps/deckcraft/src/main.rs`; `/Applications/DeckCraft.app/Contents/Info.plist`).
2. **Work in a throwaway directory.** Copy sources in; never run destructive tests on the only copy of a deck. Keep a `.deckcraft` master plus dated backups.
3. **Round-trip a small test first.** New deck → add one slide, shape, table, chart, picture, transition and note → save `.deckcraft` → export `.pptx` → reopen the `.pptx` → inspect counts and render PNGs. Fix workflow problems before touching the real deck.
4. **Save before every export.** A failed export must not be the only copy of your changes. `file.save` is atomic via a `.saving` sibling; exports are ordinary writes (`crates/engine/src/io.rs`).
5. **Check every export explicitly.** Existence and non-zero size; images: dimensions (and alpha, when `transparentBackground` was used); PDF: page count and selectable text; PPTX: reopen and render; GIF: header, dimensions, frame count.
6. **Look at the pixels.** `deckcraft-cli render … --all` (or MCP `render_slide`) and inspect the PNGs. Text overflow, missing fonts, blank SVG/EMF pictures and chart scaling are visual failures that a successful exit code will not catch.
7. **Open in the target app.** If PowerPoint is available, open the exported `.pptx` and check for repair prompts and lost animations/media. If not, state that fidelity is unverified rather than claiming parity.
8. **Keep the native file.** The `.deckcraft` master preserves DeckCraft-only constructs (including chart payloads) and is the safest thing to reopen after a failure.
9. **Record what changed.** Note version, command lines/JSON params, export options and any manual GUI steps, so a failed export can be reproduced.

## Sources & evidence

- **Repo:** https://github.com/storytold/deckcraft — tag `v0.10.0`, commit `b47195feec0f0fe4220d8943ad1c8add5dad8072` (`git rev-parse HEAD` in this detached worktree), inspected 2026-10-23.
- **Installed bundle:** `/Applications/DeckCraft.app`, `CFBundleIdentifier ai.storyteller.deckcraft`, version `0.10.0`, `DeckCraftBuildCommit` equal to the commit above; `--version` prints `deckcraft 0.10.0`; universal x86_64+arm64, Developer ID signed, notarization ticket stapled, `spctl` accepted.
- **Key files read:** `README.md`; `ROADMAP.md`; `AGENTS.md`; `Cargo.toml`; `docs/{architecture,gaps,file-format-parity,animation-parity,slideshow-parity,ui-parity,hardware-parity,localization-parity,target-app-parity,parity-checklist,roadmap,mcp,control-protocol}.md`; `apps/deckcraft/src/{main,apple_events,control_server,logging,display}.rs`; `apps/deckcraft-cli/src/{main,help}.rs`; `apps/deckcraft-web/src/{main,web}.rs`; `packaging/macos/{Info.plist.in,package.sh}`, `packaging/windows/deckcraft.wxs`, `packaging/linux/ai.storyteller.deckcraft.desktop`; `crates/engine/src/cmd/*.rs` and `crates/engine/src/{lib,keys,io,file_access,guard,recovery,gif_export,icons,icon_data,templates,spell}.rs`; `crates/model/src/{lib,theme,chart,anim,defaults}.rs`; `crates/geom/src/{preset,warp}.rs`; `crates/format/src/lib.rs`; `crates/pptx/src/{lib,opc}.rs`; `crates/pdf/{README.md,src/lib.rs}`; `crates/render/src/{lib,images}.rs`; `crates/metafile/src/lib.rs`; `crates/media/src/lib.rs`; `crates/mcp/src/{tools,server,headless,backend,lib}.rs`; `crates/ui-egui/src/{lib,show,menus,ribbon,backstage,dialogs,control,opening,thumbs,sorter,panes}.rs`; `crates/text/src/lib.rs`.
- **Shared library:** `craft-pdf` is pinned to `storytold/craft-libs` rev `c3487320b2d1de657b860b3c8abb44e1f2b32bd8` with the `write` feature only (Cargo.toml; Cargo.lock). `crates/pdf/README.md` still names an older rev — Cargo.toml/Cargo.lock win.
- **Docs that are stale (code wins):** `docs/file-format-parity.md` on `.potx`/`.ppsx` content types and `.thmx`; `docs/control-protocol.md` on the 16 MiB request line (code: 256 MiB) and its duplicated table rows; `docs/animation-parity.md` on exit-effect and path counts; `docs/gaps.md` on SmartArt layouts/styles; `docs/localization-parity.md` on spelling (Hunspell dictionaries are used, per `crates/engine/src/spell.rs`).
- **Not independently verified:** PowerPoint's acceptance of exported `.pptx` without repair on real decks, render fidelity against PowerPoint, runtime command execution, and any GUI behaviour. Claims here are code/document inspection plus bundle metadata and `--version`/`--help` checks; no GUI was launched and no deck was rendered.

---
name: deckcraft
description: >-
  DeckCraft is the ArtCraft open-source, clean-room PowerPoint-compatible presentation app for
  macOS (also Windows, Linux, FreeBSD and the web): slides, masters and layouts, shapes, 3-D,
  text, tables, charts, SmartArt, media, transitions, animations, slide shows, and `.deckcraft`,
  `.pptx`/`.potx`/`.ppsx`, outline text, Markdown and `.rtf`, PDF/PNG/JPEG/GIF files — driven by 326
  scriptable commands, a 12-subcommand CLI, a 25-method JSON control channel and a 25-tool MCP
  server. Trigger this skill whenever the user mentions DeckCraft, `.deckcraft`, `deckcraft-cli`,
  asks what DeckCraft can or cannot do, which formats or shortcuts it supports, wants to build,
  edit, inspect, convert, render, present, export, verify, repair or troubleshoot a deck, wants
  assets prepared for it, or wants it automated or scripted — even if the app is not named but the
  job is presentation work ("make a deck", "turn this outline into slides", "export these slides
  to PDF", "why did my PPTX lose its animations?", "drive a presentation app with an agent"). Do
  not use it for Microsoft PowerPoint itself.
---

Audit basis: this checkout is tag `v0.11.1`, commit `9ec39267931c0163dd5648c879043edcb9603cb8` (`git rev-parse HEAD` in the pinned clone). The installed `/Applications/DeckCraft.app` reports `CFBundleShortVersionString` 0.11.1, `CFBundleIdentifier` `ai.storyteller.deckcraft` and `DeckCraftBuildCommit` equal to that commit, and its binary prints `deckcraft 0.11.1`, so the bundle matches this source. **Verify against your installed version** (`/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --version`, plus `PlistBuddy -c "Print :DeckCraftBuildCommit"`) — the ArtCraft Launcher auto-updates, and command ids, formats and export options move between releases. Deep detail — every command family, shortcut, control method, MCP tool, format option and runtime path — is in `references/commands-and-formats.md`.

## Overview

DeckCraft is a clean-room, open-source (MIT OR Apache-2.0), pure-Rust presentation application targeting Microsoft PowerPoint for Mac parity — and better speed, openness and agent control (README.md; AGENTS.md; `Cargo.toml`). It builds decks with masters, eleven layouts, eight original themes, shapes, text, tables, charts, SmartArt, audio and video; presents them full screen or in a window with transitions and animations; and exchanges PowerPoint `.pptx` plus its own `.deckcraft` (README.md §"What works today"). It is **alpha**: v0.11.1 still claims **84% feature breadth** (P0 92%, P1 82%, P2 55%) and **~55% ready for real work**, both by its own measurement (ROADMAP.md:16-46; `docs/target-app-parity.md`; `docs/parity-checklist.md`). The workspace is 24 crates plus three apps (`apps/deckcraft`, `apps/deckcraft-cli`, `apps/deckcraft-web`) on Rust edition 2024, `rust-version` 1.95 (`Cargo.toml`; `docs/architecture.md`). Source: GitHub `storytold/deckcraft` (`Cargo.toml:9`).

Everything user-visible is a **command with an id**, and `Session::execute` is the single dispatch path shared by the ribbon, keyboard, CLI, control channel and MCP (`crates/engine/src/lib.rs:609`; `crates/engine/src/cmd/mod.rs`).

## Capabilities (verified)

### Automation surface at a glance

| Surface | Count at v0.11.1 | Change vs the v0.10.0 skill |
|---|---|---|
| Engine commands (`CommandSpec`) | **326** (233 ordinary + 56 `noundo` + 37 `query`), 28 modules, ids unique | **+6** — see below |
| Engine shortcuts | **57** (one real collision: `Cmd+Shift+V`) | unchanged |
| UI-only commands (`UI_COMMANDS`) | **50**, 15 with shortcuts | unchanged |
| CLI subcommands | **12** (`info render render-transition convert run commands describe app mcp bench links version`) | unchanged |
| Control-channel methods | **25** canonical + 2 aliases (`ui.menu.invoke`, `command`) | unchanged |
| MCP tools | **25**, plus resources `deckcraft://document`, `deckcraft://commands` | unchanged |
| Transitions | **49** rows (48 + `none`) | unchanged |
| Animations | **107** picker entries (24 entrance, 17 emphasis, 23 exit, 40 motion-path incl. `customPath`, 3 media) | unchanged |
| Themes / layouts / shape presets | **8** themes × 4 colour variants / **11** layouts + `Custom` / **183** presets in 9 categories | unchanged |
| Charts / SmartArt / starters / icons / text warps | **28** chart types (7 `chartEx` + `RegionMap`) / **45** layouts, 9 styles, 17 colour sets / **6** starter decks / **70** Lucide 1.56.0 icons / **40** warps | unchanged |
| Pattern fills | **48**-preset gallery (54 DrawingML names known) | **new at this tag** |

Every count was recomputed from this tag's code, never copied: commands parsed from every balanced `cmd!(…)` block in `crates/engine/src/cmd/*.rs` (326 blocks, 326 distinct ids, 28 files); shortcuts from the `shortcut` argument of those specs (`crates/engine/src/keys.rs` matches them); UI commands from `crates/ui-egui/src/lib.rs:364`; CLI from `apps/deckcraft-cli/src/help.rs` (`SUBCOMMANDS`); control methods from the dispatch arms in `crates/ui-egui/src/control.rs`; MCP tools from `crates/mcp/src/tools.rs::tool_definitions`; transitions and animations from `crates/model/src/anim.rs` (`TRANSITIONS`, `ANIMATIONS`); themes and variants from `crates/model/src/theme.rs`; layouts from `LayoutType` in `crates/model/src/lib.rs`; presets from `crates/geom/src/preset.rs`; charts from `ChartType` in `crates/model/src/chart.rs`; SmartArt from `crates/engine/src/cmd/smartart.rs`; starters from `crates/engine/src/templates.rs`; icons from `crates/engine/src/icon_data.rs`; warps from `crates/geom/src/warp.rs::CATALOG`; patterns from `crates/ui-egui/src/fillui.rs` (`PATTERN_GALLERY`) and `crates/render/src/pattern.rs`.

**What changed since v0.10.0** (320 commands at that tag): `crates/engine/src/cmd/points.rs` 7 → **11** (`shape.deleteSegment`, `shape.segmentType`, `shape.openPath`, `shape.closePath` — Edit Points segment add/delete and open/close path), `crates/engine/src/cmd/review.rs` 22 → **23** (`review.reject`, reject revisions after Compare), `crates/engine/src/cmd/reuse.rs` 1 → **2** (`slide.reuseList`, pick which slides to reuse). Kind split moved 229/55/36 → 233/56/37. Also new at this tag: **RTF outline read and write** (`crates/format/src/rtf.rs`; `rtf` in `WRITABLE_EXTENSIONS`), the **pattern-fill gallery**, **chart text colour** (`chart.options {textColor}`), **slide-show type `browsed`** (show in a window) round-tripped to PPTX, **EMF+-only metafiles drawn** (`crates/metafile/src/emfplus.rs`), table **cell-range selection** (`crates/engine/src/lib.rs:157`), **AutoFormat as you type** for lists and ordinals (`crates/engine/src/cmd/text.rs::autocorrect`), and a **Columns dialog** (`format.columns` with no fields). No command, MCP tool, control method, CLI subcommand, transition, animation or theme was removed.

The MCP surface is 25 tools: `list_commands`, `run_command`, `batch`, `new_presentation`, `open_presentation`, `save_presentation`, `export`, `inspect_document`, `inspect_slide`, `render_slide`, `add_slide`, `go_to_slide`, `add_shape`, `add_text_box`, `set_text`, `insert_picture`, `insert_table`, `insert_chart`, `select`, `pointer`, `select_tool`, `key`, `type_text`, `screenshot` and `call_app` (the last two connected-mode only; full table in `references/commands-and-formats.md`).

### Deck structure and design
- **Slides, masters and layouts.** Eleven standard layouts (Title, Title and Content, Section Header, Two Content, Comparison, Title Only, Blank, Content with Caption, Picture with Caption, Title and Vertical Text, Vertical Title and Text) plus `Custom` (`LayoutType`, `crates/model/src/lib.rs:686`). Slide/notes/handout masters, placeholder inheritance, sections, notes, comments, headers/footers, custom shows and slide sizes are modelled (`crates/model/src/lib.rs`; `crates/engine/src/cmd/{slide,design,review}.rs`).
- **Themes.** Eight original themes — DeckCraft, Harbor, Ember, Meadow, Nocturne, Paper, Coral Reef, Slate — with colour, font and effect schemes and four colour variants (`crates/model/src/theme.rs::builtin_themes`, `theme_variants`). Design ▸ Browse for Themes imports `.thmx`, `.pptx` or `.potx`; a presentation/template also brings its slide master and layouts and moves slides to the matching layout (`crates/pptx/src/lib.rs::import_theme`; `crates/engine/src/cmd/design.rs::browse_theme`).
- **Starter decks.** Six originals — Briefing, Lesson, Pitch, Field Notes, Quarterly, Evening Talk — via `file.new {template}` / `file.templates` (`crates/engine/src/templates.rs`).
- **Shapes.** 183 preset shape/connector generators in 9 gallery categories, with adjust handles (including partial-circle angle handles), glued connectors, freeform/curve/scribble, ink-to-shape, merge operations, gradient/picture/**pattern** fills, dashes, arrowheads, shadows, glow, soft edges and reflections (`crates/geom/src/preset.rs`; `crates/engine/src/cmd/{shape,merge,arrange,background}.rs`).
- **3-D.** Format Shape ▸ 3-D Format/Rotation: 28 camera presets offered (62 known), 12 bevels, 12 materials, 15 light rigs, X/Y/Z rotation, depth and contour; `a:scene3d`/`a:sp3d` stay as raw XML and round-trip (`crates/engine/src/cmd/three_d.rs`; `crates/engine/src/cmd/shape.rs::effects`). Rendering is approximate — see limitations.
- **Text.** In-place editing with DrawingML run/paragraph properties, bullets and numbering, columns (1–16 via dialog or `format.columns`), autofit, vertical and RTL text, fields, hyperlinks, tab stops, line spacing, 40 WordArt warps and AutoFormat/Smart Quotes (`crates/engine/src/cmd/{text,format}.rs`; `crates/model/src/text.rs`; `crates/geom/src/warp.rs`).
- **Tables.** Styled tables with cell merges (diagonal borders included), row/column insert, delete and distribute, widths/heights, borders, cell fill/margins/alignment, drag- or Shift+arrow range selection, draw/erase line (`crates/engine/src/cmd/table.rs`; `crates/engine/src/lib.rs:157`).

### Content
- **Pictures.** PNG, JPEG, GIF (animated, inside groups too), WebP, BMP, TIFF decode; EMF/WMF draw through `deckcraft-metafile`, including EMF+-only files (`crates/render/src/images.rs`; `crates/metafile/src/emfplus.rs`). Crop, brightness/contrast, duotone, alpha, artistic effects, compress and Set Transparent Colour are modelled (`crates/engine/src/cmd/{shape,artistic,recolor,compress}.rs`).
- **Charts.** 28 types including the seven Office-2016 `chartEx` types, plus radar, stock, region map (kept and drawn, not in menus) and combo; chart text colour, palette, gridlines, data labels, bin options and six trendline kinds with forecast and equation/R² (`crates/model/src/chart.rs`; `crates/engine/src/cmd/insert.rs`; `crates/model/src/trendline.rs`). An unchanged chart keeps its embedded workbook; pattern fills now read and write (`a:pattFill`).
- **SmartArt.** A graphic is a group whose outline is edited in a Text Pane; 45 layouts, 9 styles, 17 colour sets, Add/Promote/Demote/Remove, layout switching, picture fill, convert to/from text or shapes; written to `.pptx` as a real diagram (`crates/engine/src/cmd/smartart.rs`; `crates/pptx/src/dgm.rs`).
- **Media.** Audio: MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg Vorbis, Opus. Video: H.264, HEVC, VP9 and AV1 in MP4/MOV and WebM/Matroska, decoded in software by the repo's own codec crates (`crates/media/src/lib.rs`; `crates/{h264,hevc,vp9,av1,isobmff,matroska,ogg,opus}`). Trim, fades, volume, poster frame and show-media-controls are modelled (`crates/media/src/clip.rs`; `crates/engine/src/cmd/media.rs`).
- **Other insertables.** 70 Lucide 1.56.0 stroke icons as custom shapes (`insert.icon`), WordArt, symbols, date/time fields (13 formats), slide numbers, photo albums (insert and edit), Zoom links, and an Equation dialog that inserts pretty-printed text, not OMML (`crates/engine/src/icon_data.rs`; `crates/engine/src/cmd/insert.rs`; `crates/text/src/datetime.rs`; `crates/ui-egui/src/dialogs.rs::pretty_equation`).

### Presenting
- **48 transitions plus “None”** (49 rows), including Morph with objects/words/characters options (`crates/model/src/anim.rs:52`; `crates/anim/src/transition.rs`; `docs/animation-parity.md`).
- **Animations.** 107 picker entries (24 entrance, 17 emphasis, 23 exit, 40 motion-path including Custom Path, 3 media controls); start modes, by-paragraph builds, click triggers, repeat, auto-reverse and bounce end (`crates/model/src/anim.rs:360`; `crates/anim/src/timeline.rs`; `crates/engine/src/cmd/animation.rs`).
- **Slide show.** Full-screen show or **`browsed`** (in a window), presenter view in a second window, pen and laser pointer, black/white screens, See All Slides, zoom, hyperlinks/actions, custom shows, kiosk looping, rehearse timings and media playback (`crates/ui-egui/src/show.rs::show_fills_screen`; `show.setup {type: speaker|browsed|kiosk}`; `crates/engine/src/cmd/review.rs:75-84`). A `.ppsx` on the command line or from the file association starts its show (`apps/deckcraft/src/main.rs`; `crates/ui-egui/src/lib.rs::open_from_system`).
- **Views.** Normal, Outline, Slide Sorter, Notes Page and Reading; slide/notes/handout master views; Animation Pane with Play From (`crates/ui-egui/src/{lib,sorter,panes,animtimeline}.rs`; `crates/engine/src/cmd/design.rs`).

### Files
- **Native `.deckcraft`:** a zip with a stored `mimetype`, `presentation.json`, `media/<id>` and `chart-parts/<index>` entries; readers ignore unknown fields, and legacy `.slidecraft` files still open (`crates/format/src/lib.rs`). Load budgets: 2 GiB per entry, 4 GiB total media + chart sidecars, 100 000 items (`crates/format/src/lib.rs:27-31`).
- **PowerPoint `.pptx`:** read and write; `.potx` and `.ppsx` are written with their own main content types (`crates/pptx/src/lib.rs::export_as`). Unknown parts are kept where the model does not understand them (`docs/architecture.md`). Embedded fonts are read and written; MicroType Express subsets are kept but not drawn.
- **Outlines:** plain text and Markdown (headings become slides) and now **`.rtf`** — PowerPoint's Outline/RTF save type — imported by content sniffing and by extension, and exported with bold/italic/underline and outline levels (`crates/format/src/rtf.rs`; `crates/engine/src/cmd/file.rs::open_other`, `save_bytes`; `slide.fromOutline`, `file.open`).
- **PDF:** slides, notes pages or handouts (1/2/3/4/6/9), Letter/A4/Legal/A3, portrait/landscape, hidden-slide and slide-range options, selectable invisible text layer, links and bookmarks; slide artwork is a raster image, at most 64M pixels per slide (`crates/pdf/src/lib.rs`; `crates/engine/src/cmd/file.rs::pdf_options`).
- **Images and GIF:** PNG/JPEG per slide (one, `slide`, or `all`; `transparentBackground`; DPI = scale × 72) and an animated GIF of the deck (one frame per slide, 256-colour palette, 16–3840 px wide, 0.1–600 s per slide, loop or play once, slide range incl. `"1-3,5"`, hidden slides skipped, ≤500 frames / ≤200M pixels) (`crates/engine/src/cmd/file.rs::export`; `crates/engine/src/gif_export.rs`).
- **AutoRecover:** unsaved presentations are written to a recovery folder and reopened at the next start; saving or closing removes the entry (`crates/engine/src/recovery.rs`; `apps/deckcraft/src/main.rs`).

### Platforms
- **macOS universal app**, signed, notarized and stapled (Developer ID Application: Learning Machines LLC; `spctl` accepted); Windows x64/arm64/x86, Linux (AppImage, Flatpak, deb, rpm, tarball; riscv64 tarball), FreeBSD and a static WebAssembly site (README.md §Downloads; `packaging/`).
- Rendering is CPU-side through `vello_cpu`; the UI is `egui`/`eframe` 0.36 (`Cargo.toml`; `docs/architecture.md`). The web build uses WebGPU with a WebGL2 fallback (`?webgl`), starts blank or in show with `?blank`/`?show`, downloads instead of saving, has no audio output, no TCP control channel and no persisted preferences (`apps/deckcraft-web/src/main.rs`; `apps/deckcraft-web/src/web.rs`).

## Known limitations and not-implemented

### File exchange and PowerPoint fidelity
- **No external deck corpus.** Every PPTX test uses decks this repo authors; fidelity on real corporate decks, templates, fonts and `chartex` is mostly unmeasured, and “opens in PowerPoint without repair” is a docs claim, not independently verified here (`docs/gaps.md`; `docs/file-format-parity.md`).
- **Known PPTX round-trip losses:** media playback options and animation rewind are not written back (#74, #77); a combo chart's secondary value axis is read but not written when the chart is rebuilt; editing a chart's data drops its embedded workbook (an unchanged chart keeps it); imported SmartArt is redrawn with DeckCraft's simpler layouts; relationship-bearing SmartArt/OLE kept only as XML loses drawing and data parts (#203) (`docs/gaps.md`; `docs/file-format-parity.md`).
- **Unsupported input:** legacy `.ppt`/`.pot`/`.pps`, OpenDocument `.odp` and `.pptm`/`.potm`/`.ppsm` are not read (macros are neither preserved nor run); password-protected decks fail with a clear error and there is no password protection on save; anything else gives “not a presentation DeckCraft can read” (`crates/engine/src/cmd/file.rs::open_other`; `crates/pptx/src/cfb.rs::is_encrypted`; `docs/file-format-parity.md`).
- **A Finder-open `.ppsx` still does not start its show.** `apps/deckcraft/src/apple_events.rs` opens paths with `open_path`, while only the command-line path (`open_from_system`) checks for `.ppsx`; the file-association path documented in `docs/file-format-parity.md` is unverified for the Finder route.
- **Internal docs still lag the code.** `docs/control-protocol.md` says a 16 MiB request line (code: 256 MiB); `docs/animation-parity.md` says 14 exit effects (code: 23); `docs/gaps.md` says 15 SmartArt layouts and 4 styles (code: 45/9/17) and that EMF+ records are not drawn (code: `crates/metafile/src/emfplus.rs` plays them for EMF+-only files); `docs/architecture.md` says 320 commands (code: 326) and 41 dialogs (not re-counted here — uncertain, see `crates/ui-egui/src/dialogs.rs`); `docs/mcp.md` omits `rtf` from the export tool; ROADMAP.md's menu-coverage line cites “226 commands at d556ff9”. Trust the code and `deckcraft-cli commands`/`describe`.

### Pictures and media
- **SVG is not rendered.** `insert.picture` accepts `image/svg+xml`, but no decoder draws it, so an inserted SVG shows nothing and a PPTX that stores a PNG fallback beside its SVG shows that fallback (`crates/engine/src/cmd/insert.rs`; `crates/render/src/images.rs`; `docs/file-format-parity.md`).
- **HEIC is not supported**, WMA is recognised and probed but not decoded, WMV is not playable, and online video embeds are not supported (`crates/media/src/lib.rs`; `docs/file-format-parity.md`). EMF/WMF render inside decks but are not sniffed by `insert.picture`.
- **Web build is silent and stateless:** no audio output, no TCP control channel, no persisted preferences (`apps/deckcraft-web/src/main.rs`).

### Output
- **PDF artwork is rasterized.** Each slide is placed as a print-DPI image (capped at 64M pixels per slide raster) under an invisible real-text layer; text is selectable/searchable but the artwork is not vector (`crates/pdf/src/lib.rs`; `crates/pdf/README.md`; `docs/gaps.md`).
- **No native print dialog.** File ▸ Print (Cmd+P) builds a PDF in the temp folder and opens it in the system viewer; there is no printer list, copies, sides or colour choice (`crates/ui-egui/src/lib.rs::print_pdf`; `docs/ui-parity.md`).
- **No MP4/MOV export.** Only the animated GIF exists: one static frame per slide, no transitions or build animations (`crates/engine/src/gif_export.rs`; `docs/gaps.md`).

### Platform and UI
- **No native macOS menu bar.** `menus::menu_tree()` exists but nothing installs it; use the ribbon, the command palette (Cmd+Shift+P) or commands (`crates/ui-egui/src/menus.rs`; `docs/ui-parity.md`).
- **Presenter view is a second window but is not assigned to the second display** (`docs/gaps.md`; `docs/slideshow-parity.md`).
- **CPU rasterization and software video decode**; no GPU slide rendering or hardware decode (`docs/hardware-parity.md`). **English-only UI**, no string catalogue (`docs/localization-parity.md`). Pen pressure works, tilt does not.

### Feature depth
- **Charts are partial:** chart-element editing and some `chartex` behaviour are thinner than PowerPoint's; the secondary-axis and stale-workbook issues above (`docs/gaps.md`).
- **Animations are partial:** 64 non-path effects of roughly 190 in PowerPoint (`docs/gaps.md`; `docs/animation-parity.md`).
- **SmartArt is shallow:** 45 simple layouts against PowerPoint's ~200, no picture layouts or 3-D styles (`docs/gaps.md`).
- **No recording:** the Record tab's Record button is disabled (“Recording narration needs audio capture”) (`crates/ui-egui/src/ribbon.rs:2136`).
- **Equations are not OMML:** the Equation dialog inserts pretty-printed text; OMML is neither read nor written (`crates/ui-egui/src/dialogs.rs::pretty_equation`).
- **No AI/cloud features** (Copilot/Designer/Speaker Coach/live captions); only offline Design Ideas arrangements. **No add-ins or VBA** by policy; MCP/CLI is the automation alternative (`docs/gaps.md`).

### Automation and data-safety behaviours to know
- **`file.close` closes a dirty document without prompting.** The UI's Close (`app.closePresentation`, Cmd+W) prompts; the raw engine command does not (`crates/engine/src/cmd/file.rs::close`; `crates/ui-egui/src/lib.rs`). Do not call `file.close` on unsaved work.
- **`app.quit` over the control channel quits without asking.** `{"save": true}` saves every presentation first, but an untitled document still opens a Save dialog, so save explicit paths before quitting (`crates/ui-egui/src/control.rs`).
- **`file.save`/`file.saveAs` without a `path` (and no stored path) ask the UI** and return `{"needsPath": true}`, writing nothing in headless use — always pass `path` (`crates/engine/src/cmd/file.rs::save`).
- **Never use `file.save`/`run --save` for `.png`/`.jpg`.** `save_bytes` handles `pptx|potx|ppsx`, outline `txt`, `rtf`, `pdf` and `gif`, and falls back to native `.deckcraft` zip bytes for anything else — a `.png` path writes native bytes under the image name. Use `file.export`/`--export`/`convert`. MCP `save_presentation` and control-channel `app.save` inherit the trap (`crates/engine/src/cmd/file.rs::save_bytes`, `format_for_path`).
- **`run` stops at the first failing command and saves nothing** (`apps/deckcraft-cli/src/main.rs::run`).
- **Reads are bounded and saves follow links:** every path read needs a regular file of at most 2 GiB, and a save canonicalizes the target (so it writes through a symlink) and preserves the existing file's permissions (`crates/engine/src/io.rs::read_file`, `write_file`).
- **The control channel has no authentication.** It binds loopback only; do not expose or port-forward it (`apps/deckcraft/src/control_server.rs`; `docs/control-protocol.md`).

## How to operate

### Check what is installed
```sh
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --version   # prints: deckcraft 0.11.1
command -v deckcraft-cli                                         # headless CLI: a separate download
```
The `.app` bundle contains no `deckcraft-cli` (`ls /Applications/DeckCraft.app/Contents/MacOS` shows only `DeckCraft`). The CLI ships as the separate signed/notarized release asset `deckcraft-cli-<ver>-macos-universal.zip` (README.md §Downloads; `packaging/macos/package.sh`). Download/unzip it, build it with `cargo build --release -p deckcraft-cli`, or automate through the control channel instead.

### Launch
```sh
open -a DeckCraft                          # normal GUI
open -a DeckCraft --args --sample          # sample deck
open -a DeckCraft talk.pptx                # open a file
/Applications/DeckCraft.app/Contents/MacOS/DeckCraft --control 7990 --sample
```
GUI flags: `--control PORT`, `--sample`, `--show`, `--help`, `--version`, and file paths (`apps/deckcraft/src/main.rs`). The port can also come from `DECKCRAFT_CONTROL_PORT`. The desktop parser is hand-rolled: an unknown argument is treated as a file path, so a mistyped flag shows up as a failed open, not a usage error.

### CLI
`deckcraft-cli` is the most reliable automation surface; it needs no window (`apps/deckcraft-cli/src/{main,help}.rs`).

| Command | What it does |
|---|---|
| `info FILE` | JSON: slides, layouts, theme fonts, sections, slide size (`document.inspect`) |
| `render (FILE \| --sample) [--slide N \| --all] [--scale S] [--edit] [--transparent] OUT` | PNG per slide; `--all` writes `slide-01.png…`; default scale 2; `--slide` 0-based |
| `render-transition FILE --slide N --t T[,T...] [--width PX] OUT.png` | Frames of the transition into slide N |
| `convert IN OUT` | Save in OUT's extension: `.deckcraft`, `.pptx`/`.potx`/`.ppsx`, `.pdf`, `.txt`/`.md`/`.rtf`, `.png`/`.jpg` (first slide), `.gif` |
| `run [--in FILE \| --sample] [--cmd ID[=JSON]]... [--save OUT] [--export OUT [--export-params JSON]] [--print]` | Run commands, then save/export; stops and saves nothing on the first error |
| `commands [FILTER]` / `describe COMMAND` | List ids/params; explain one |
| `app [--port PORT] COMMAND [JSON]` / `--method METHOD [JSON]` | One request to a running `deckcraft --control` (default port 7979) |
| `mcp [--connect PORT] [--sample] [--automation-read-root DIR] [--automation-write-root DIR]` | MCP server on stdio |
| `bench (FILE \| --sample) [--runs N] [--json]` | Time open/draw/save/PPTX reopen/PDF export and peak memory |

Examples:
```sh
deckcraft-cli commands format.
deckcraft-cli describe shape.insert
deckcraft-cli run --cmd 'slide.new={"layout":"titleOnly","title":"Q3 results"}' \
  --cmd 'shape.insert={"preset":"roundRect","rect":[80,160,320,120],"text":"Revenue"}' \
  --save q3.deckcraft
deckcraft-cli render q3.deckcraft --all --scale 1 out/
deckcraft-cli convert q3.deckcraft q3.pdf
deckcraft-cli run --in q3.deckcraft --export q3.rtf
```
`--print` prints each command's **answer**; it is not a printer flag. `convert` gives no PDF-layout options and only the first slide for PNG/JPEG; use `run --export` or `file.export` for notes/handouts and all slides.

### Conventions that prevent most automation bugs
- Coordinates are **points** on a 960×540 (16:9) slide unless the deck says otherwise; a rect is `[x, y, width, height]` (`crates/model/src/defaults.rs`; `apps/deckcraft-cli/src/help.rs`).
- **Slide indices are 0-based**; `render --all` names files from 1 (`slide-01.png`), while `file.export all` names `stem1.png`, `stem2.png` (`crates/engine/src/cmd/file.rs::export`).
- **Shape ids are looked up on the current slide only**; `slide.go {index}` changes the current slide; `slide.new` inserts after it and selects the new slide (pass `at` for an index) (`crates/engine/src/cmd/slide.rs`).
- Commands that add a shape select it; `format.*` acts on the selection, while many shape commands take `ids` directly.
- Text bodies use `\n` for a new paragraph and a leading tab per level for bullets (`crates/engine/src/cmd/slide.rs`).
- **Every index parameter is strict now:** a negative or fractional `index`/`from`/`at` is an error, including on `slide.layout` (which treated a bad index as absent at v0.10.0); a valid index past the last slide is also an error (`crates/engine/src/cmd/mod.rs::opt_usize_param`; `crates/engine/src/cmd/slide.rs`).

### Documents, open/save/export
- One process can hold several presentations; `file.new`/`file.open` add documents, `window.next` cycles the active one, and `view.newWindow` opens a second, non-editing window on the same deck (`crates/engine/src/cmd/file.rs`; `crates/ui-egui/src/doc_window.rs`).
- **Open:** `file.open {path}` — native `.deckcraft`, `.pptx`/`.potx`/`.ppsx`, and `.txt`/`.md`/`.rtf` outlines (RTF by content sniffing, not only extension). Open is lenient for PPTX: unknown parts skipped/kept, unreadable slides reported in `lostSlides`, damaged files open as a repaired copy, and media lengths/sizes are filled in from headers (`crates/engine/src/cmd/file.rs`; `crates/ui-egui/src/opening.rs`).
- **Save:** `file.save {path, format?: deckcraft|pptx}` / `file.saveAs {path, format?}` / `file.saveTemplate {path}`; the format follows the extension unless `format` is given. **For `.png`/`.jpg`, use `file.export`.** Writes go to a unique `.saving` sibling renamed over the target, so a failed save never truncates the old file (`crates/engine/src/io.rs`).
- **Export:** `file.export {path, format?, ...}`. PNG/JPEG: `slide?`/`all?`/`scale?`/`transparentBackground?`; PDF: `layout`, `perPage`, `paper`, `orientation`, `dpi`, `slides`, `includeHidden`, `textLayer`, `frame`; GIF: `width`, `secondsPerSlide`, `loop`, `slides`, `includeHidden`; outline: `txt`/`outline`/`rtf` (`crates/engine/src/cmd/file.rs`). All requested image indices are validated before any file is written.
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
Paths outside the roots are refused with ordinary tool errors; a root left out grants none of its access, `--flag=DIR` works, giving the same flag twice is an error, and roots cannot be combined with `--connect` (`apps/deckcraft-cli/src/automation_args.rs`; `crates/engine/src/file_access.rs`; `docs/mcp.md`).

### Environment and logs
- Settings/logs: `~/Library/Application Support/DeckCraft/` (`ui.json`, `prefs.json`, `logs/deckcraft.log`, rotated, capped at 16 MiB); recovery: `…/DeckCraft/Recovery/` (`apps/deckcraft/src/main.rs::config_dir`; `apps/deckcraft/src/logging.rs`; `crates/engine/src/recovery.rs`).
- `DECKCRAFT_CONTROL_PORT` sets the control port; `DECKCRAFT_NO_AUDIO=1` plays silently; `DECKCRAFT_NO_PREFS=1` skips preferences; `DECKCRAFT_NO_RECOVERY=1` skips AutoRecover; `DECKCRAFT_DICTIONARIES` adds dictionary folders; `RUST_LOG` sets log levels (default `info` for DeckCraft crates, `warn` otherwise) (`apps/deckcraft/src/main.rs`; README.md §Logs).

## Working with an AI agent

### Choose the surface
1. **Headless CLI** (`deckcraft-cli run`, `render`, `convert`, `info`, `mcp`) — best for generating decks, batch exports and verification. No window, no GUI state.
2. **MCP stdio** (`deckcraft-cli mcp`) — best when the agent has an MCP client; use `run_command`/`batch` for anything the 25 tools do not wrap, and `inspect_document`/`inspect_slide` before editing. A headless server starts with no document: call `new_presentation` or `open_presentation` first. `batch` stops at the first error unless `keepGoing`; tools reject unknown argument names rather than guessing (`crates/mcp/src/tools.rs`; `crates/mcp/src/headless.rs`).
3. **Control channel** (`deckcraft --control`) — only when a human and agent must share a live window, or UI-only state (dialogs, selection, screenshots) matters. Always `ui.inspect`/`ui.screenshot` before pointer work; never click blind.

### Prepare inputs
- **Pictures:** PNG, JPEG, WebP, GIF, BMP, TIFF (not SVG, not HEIC; EMF/WMF only when already inside a deck). Pre-render logos and icons to PNG with transparency; a PNG with `transparentBackground` export round-trips overlays.
- **Audio/video:** MP3, AAC/M4A, ALAC, WAV, AIFF, CAF, FLAC, Ogg, Opus; H.264/HEVC/VP9/AV1 in MP4/MOV/WebM/MKV (`crates/media/src/lib.rs`). Transcode WMA/WMV first.
- **Outlines:** a Markdown file with `#` headings, a tab-indented plain-text file, or `.rtf` (`\outlinelevel` paragraphs, falling back to `\li` indent) imports directly (`crates/format/src/rtf.rs`; `slide.fromOutline`).
- **Themes:** `.thmx`, or a `.pptx`/`.potx` whose first master holds the theme and layouts (`crates/pptx/src/lib.rs::import_theme`).

### Inspect, repair and convert
- `.deckcraft` is a zip: inspect `presentation.json`, `media/<id>` and `chart-parts/<index>` with `unzip -l`/`unzip -p`. Repair damaged media by restoring the member; do not rewrite the JSON unless the schema is understood (`crates/format/src/lib.rs`). Older files with inline chart bytes still load and migrate on save.
- Do **not** hand-edit a `.pptx` zip to “fix” it: use DeckCraft commands and re-export. Unknown PPTX parts are preserved by the writer, but hand-edited XML can break content types or relationships (`docs/architecture.md`).
- Convert between `.deckcraft`, `.pptx`, `.pdf`, `.txt`/`.md`/`.rtf` and images with `convert`, remembering that `convert` writes only the first slide for PNG/JPEG and uses default PDF options (`apps/deckcraft-cli/src/help.rs`).

### Verify exports
- Read the command result: exports return `{path, bytes}` or `{files}`; assert the file exists and its size is plausible. A zero-byte or missing file is a failure even if the process exited 0 (`crates/engine/src/cmd/file.rs`).
- Re-open the result: `deckcraft-cli info out.pptx` and compare slide count/titles/layouts; `deckcraft-cli render out.pptx --all` and look at the PNGs.
- For PDF, check page count and extracted text (e.g. `pdftotext`); the text layer is selectable but the artwork is raster (`crates/pdf/README.md`).
- For `.pptx` and `.ppsx`, the strongest test is opening it in PowerPoint/Keynote and checking for a repair prompt, animations, media and theme fonts. The project has not tested a real-deck corpus (`docs/gaps.md`).
- For GIF, verify the `GIF89a` header, dimensions, frame count and delay; transitions/builds are intentionally absent (`crates/engine/src/gif_export.rs`).

### Do not
- Do not insert SVG, HEIC, or EMF/WMF via `insert.picture` and expect them to draw.
- Do not promise `.ppt`, `.odp`, `.pptm`, macros, password protection or MP4 export.
- Do not call `file.close` or `app.quit` on unsaved work; use `app.quit {"save": true}` only after saving explicit paths.
- Do not use `file.save`/`--save` for `.png`/`.jpg`; use `file.export`/`--export`/`convert` (otherwise native zip bytes get an image extension).
- Do not assume PDF is vector or that a `.pptx` round-trip is lossless.
- Do not rely on font metrics matching PowerPoint exactly; substitute faces change line breaks. Verify visually.
- Do not expose the control channel beyond loopback; it has no authentication.
- Do not trust `docs/` where it contradicts the code (request-line size, exit-effect count, SmartArt counts, command and dialog counts are stale at this tag).

## Verification protocol

Alpha software with active auto-updates: verify every deliverable, keep a native master, and never trust a silent export.

1. **Pin the version.** Record `deckcraft --version` and `DeckCraftBuildCommit` before work. Update only between projects, not mid-deck; command ids, formats and export options move between releases (`/Applications/DeckCraft.app/Contents/Info.plist`).
2. **Work in a throwaway directory.** Copy sources in; never run destructive tests on the only copy of a deck. Keep a `.deckcraft` master plus dated backups.
3. **Round-trip a small test first.** New deck → one slide, shape, table, chart, picture, transition and note → save `.deckcraft` → export `.pptx` → reopen the `.pptx` → inspect counts and render PNGs. Fix workflow problems before touching the real deck.
4. **Save before every export.** A failed export must not be the only copy of your changes. `file.save` is atomic via a `.saving` sibling; exports are ordinary writes (`crates/engine/src/io.rs`).
5. **Check every export explicitly.** Existence and non-zero size; images: dimensions (and alpha, when `transparentBackground` was used); PDF: page count and selectable text; PPTX: reopen and render; GIF: header, dimensions, frame count; RTF: re-open as an outline.
6. **Look at the pixels.** `deckcraft-cli render … --all` (or MCP `render_slide`) and inspect the PNGs. Text overflow, missing fonts, blank SVG/EMF pictures and chart scaling are visual failures that a successful exit code will not catch.
7. **Open in the target app.** If PowerPoint is available, open the exported `.pptx` and check for repair prompts and lost animations/media. If not, state that fidelity is unverified rather than claiming parity.
8. **Keep the native file.** The `.deckcraft` master preserves DeckCraft-only constructs (including chart payloads) and is the safest thing to reopen after a failure.
9. **Record what changed.** Note version, command lines/JSON params, export options and any manual GUI steps, so a failed export can be reproduced.

## Sources & evidence

- **Repo:** https://github.com/storytold/deckcraft — tag `v0.11.1`, commit `9ec39267931c0163dd5648c879043edcb9603cb8` (`git rev-parse HEAD` in the pinned clone), inspected **2026-10-26**.
- **Installed bundle:** `/Applications/DeckCraft.app`, `CFBundleIdentifier` `ai.storyteller.deckcraft`, version `0.11.1`, `DeckCraftBuildCommit` equal to the commit above; `--version` prints `deckcraft 0.11.1`; universal x86_64+arm64, Developer ID signed, notarization ticket stapled, `spctl` accepted; `CFBundleDocumentTypes` declares `.deckcraft`, `.pptx`, `.potx`, `.ppsx` (same four as `packaging/macos/Info.plist.in`).
- **Key files read:** `README.md`; `ROADMAP.md`; `AGENTS.md`; `Cargo.toml`; `docs/{architecture,gaps,file-format-parity,animation-parity,slideshow-parity,ui-parity,hardware-parity,localization-parity,target-app-parity,parity-checklist,roadmap,mcp,control-protocol}.md`; `packaging/macos/{Info.plist.in,package.sh}`, `packaging/windows/deckcraft.wxs`, `packaging/linux/{ai.storyteller.deckcraft.desktop,nfpm.yaml}`; `apps/deckcraft/src/{main,apple_events,control_server,logging,display}.rs`; `apps/deckcraft-cli/src/{main,help,automation_args}.rs`; `apps/deckcraft-web/src/{main,web}.rs`; `crates/engine/src/{lib,keys,io,file_access,guard,recovery,gif_export,icons,icon_data,templates,spell,thesaurus,links,media_refs}.rs` and `crates/engine/src/cmd/*.rs`; `crates/model/src/{lib,theme,chart,anim,defaults,style,text,table,numfmt,trendline,resolve,edit}.rs`; `crates/geom/src/{preset,warp,morph}.rs`; `crates/anim/src/{lib,show,timeline,transition,morph,path}.rs`; `crates/format/src/{lib,rtf,chart_parts,finite}.rs`; `crates/pptx/src/{lib,opc,dgm,cfb,xml,maps,custgeom,tables}.rs` and `crates/pptx/src/{read,write}/`; `crates/pdf/src/lib.rs` and `crates/pdf/README.md`; `crates/render/src/{lib,images,pattern,chart,chartex,camera,bevel,extrude,light,warp,metafile,table}.rs`; `crates/metafile/src/{lib,emf,emfplus,wmf,canvas}.rs`; `crates/media/src/{lib,audio,video,player,clip,probe}.rs`; `crates/mcp/src/{tools,server,headless,backend}.rs`; `crates/ui-egui/src/{lib,show,menus,ribbon,backstage,dialogs,control,opening,fillui,panes,doc_window,thumbs,sorter,animtimeline}.rs`; `crates/text/src/{lib,datetime,bidi}.rs`.
- **Shared libraries (not cloned):** `craft-media` pinned to `storytold/craft-libs` rev `f0ad6c1e1d297908915f4be315b0fcfc9be7b5d4`, and `craft-pdf` to rev `9f75d3dc19b4b514c4f3d4847ed1ec1b0e86b4ef` with the `write` + `write-simple-text` features (krilla patched to the same rev) — `Cargo.toml`, `Cargo.lock`. Shared-library behaviour beyond these pins is not audited here.
- **Docs that are stale at this tag (code wins):** `docs/control-protocol.md` (16 MiB vs the code's 256 MiB; it also still lists a `show.key` method that has no dispatch arm); `docs/animation-parity.md` (14 exits vs 23); `docs/gaps.md` (15 SmartArt layouts / 4 styles vs 45/9/17; says EMF+ is not drawn); `docs/architecture.md` (320 commands vs 326; 41 dialogs not re-counted); `docs/mcp.md` (export list omits `rtf`); `ROADMAP.md` (“226 commands at d556ff9”).
- **Not independently verified:** PowerPoint's acceptance of exported `.pptx`/`.ppsx` without repair on real decks, render fidelity against PowerPoint, runtime command execution, `deckcraft-cli` execution (not installed on this machine), and any GUI behaviour. Claims here are code and document inspection plus bundle metadata and `--version`/`--help` checks; no GUI was launched and no deck was rendered.

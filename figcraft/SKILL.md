---
name: figcraft
description: >
  FigCraft is an open-source, pure-Rust, offline interface-design, prototyping and whiteboard app (a
  clean-room reimplementation of the Figma Design workflow): frames, auto layout, components,
  styles, variables, vector networks, prototyping, Dev Mode and board files, on macOS, Windows,
  Linux, FreeBSD and the web. Trigger it whenever the user mentions FigCraft or a `.figcraft` file,
  asks what it can or cannot do, which formats it opens or writes, how to script, automate, batch or
  headlessly drive it (figcraft-cli, MCP, the JSON control channel), wants assets prepared for a
  design file, needs output verified or repaired, or asks to troubleshoot it — and when the app is
  not named but the job is one of its jobs: "make a mockup", "design a screen / landing page /
  dashboard", "build a design system", "export these frames to PNG/PDF/SVG", "open this .fig or
  Figma file JSON", "prototype this flow", "hand this off to a developer", "make a retro board".
  Do not guess capabilities from Figma knowledge — FigCraft is not Figma and runs no Figma plugins.
---

Audit basis: this checkout is tag `v0.11.2`, commit `d4a303d4708602a9df1738960852d18b185a616b`
("Release 0.11.2", released 2026-10-25). The installed `/Applications/FigCraft.app` reports version
`0.11.2` (`CFBundleShortVersionString`) and its binary prints `FigCraft 0.11.2
(d4a303d4708602a9df1738960852d18b185a616b)`, so the bundle matches this source exactly.
**Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Deep
operational detail — the full CLI, control-channel and MCP tables, live-session commands and the
server — is in `references/automation-surfaces.md`.

# FigCraft

## Overview

FigCraft is a native, offline interface-design and prototyping app written entirely in Rust
(egui/eframe UI, tiny-skia CPU renderer, no Electron), built clean-room from public documentation
and observed behaviour against Figma Design (`README.md`, `docs/target-app-parity.md`). It is
**alpha**: the README says "about 49%" of the way to replacing proprietary tools, while the measured
table says ~53% ready, ~85% feature breadth and ~94% core-editor breadth (`ROADMAP.md`,
`docs/target-app-parity.md` › Headline). It runs on macOS, Windows, Linux, FreeBSD and in the browser
via WebAssembly; source is GitHub `storytold/figcraft`, MIT OR Apache-2.0. Every user-visible action
is a command in one registry — **597 commands across 60 id namespaces**, covering **212/212
catalogued menu items** (`crates/engine/src/cmd/mod.rs` `registry`, `crates/engine/src/catalog.rs`,
`docs/parity-checklist.md`) — dispatched identically by the UI, CLI, control channel and MCP server.

The v0.11.x line (since the previous audit at v0.10.0) added **board files** — a whiteboarding file
kind with stickies, shapes, connectors and stamps (`crates/doc/src/board.rs`,
`crates/engine/src/board.rs`, `docs/boards-parity.md`; closes `docs/gaps.md` gap 24); the **Dev Mode
tail** (measurements on the canvas, compare with any saved version, inspect-only canvas, import lines
in generated trees: `crates/engine/src/dev_measurements.rs`, `devcompare.rs`); **`data.fill`** and
**`text.fit`** (`crates/engine/src/datafill.rs`, `textfit.rs`); **vector fill rules**; grid track
sizes in `.fig` export; and CLI `--help`/`-h` (`apps/figcraft-cli/src/args.rs`). Commands moved
569 → 597, namespaces 57 → 60, shortcut bindings 151 → 159; the other surfaces (9 CLI subcommands,
17 control methods, 18 MCP tools) kept their shape.

## Capabilities (verified)

**Model and editing**
- Frames, groups, sections, mask groups, rectangles (squircle corners), ellipses with arc/ring handles,
  polygons, stars, lines (arrowheads are stroke caps), text, vector networks, boolean groups,
  components, sets, instances and slices (`crates/doc/src/node.rs` `NodeKind`, `crates/doc/src/props.rs`).
- **Auto layout**: flow, wrap and grid with fixed/hug/`fr` tracks, spans, padding, gaps, Hug/Fill/Fixed
  sizing, min/max sizes, absolute children, baseline cross-align, `contentAlign`
  (`crates/layout/src/lib.rs`, `docs/auto-layout-parity.md`).
- **Vector networks**: Pen/Pencil, vector edit mode (bend, paint bucket, lasso, cut), shape builder,
  editable booleans, per-point radius/handles/caps/joins, variable-width strokes, outline stroke,
  dashes, per-side strokes, brushes and pen pressure, text on a path, pattern fills, and fill rules
  with loop reversal for holes (`vector.fillRule`, `vector.reverseLoop`;
  `crates/engine/src/vectoredit.rs`, `crates/pathops/src/lib.rs`, `crates/engine/src/shapebuilder.rs`).
- **Text**: in-place editing, mixed styles, auto width/height, variable font axes, OpenType features,
  lists, bidi/RTL, HarfRust shaping plus system or `craft-fonts` fonts; missing fonts are reported,
  loadable without install and refittable (`text.missingFonts`, `text.loadFont`, `text.refit`;
  `crates/engine/src/fonts.rs`). `text.fit` shrinks a fixed-width text to the largest size that fits
  `maxLines` (`crates/engine/src/textfit.rs`).
- **Paint and effects**: solid and linear/radial/angular/diamond gradients, image fills with
  adjustments, pattern fills, blend modes, inner/drop shadows, uniform and progressive
  layer/background blur, noise, texture, glass and masks; sRGB or Display P3 with profile conversion
  (`crates/color/src/lib.rs`, `crates/render/src/image_profile.rs`).
- **Components and design systems**: mains, instances with per-layer overrides, sets and variants,
  properties (boolean/text/instance-swap/slot), swap/detach/reset/restore, playground
  (variant/boolean/text/instance-swap; no slot control), paint/text/effect/grid styles, variables
  (colour/number/string/boolean) with modes, aliases, scopes and bindings, JSON/CSS import/export
  (`crates/doc/src/styles.rs`, `crates/engine/src/cmd/variables_io.rs`, `docs/components-parity.md`).
- **Boards (new file kind)**: `File ▸ New board` / `file.newBoard` opens a light-paged board;
  `inspect_document` says `kind: "board"` and `.figcraft` stores the kind (`crates/doc/src/board.rs`
  `FileKind`, `Document.kind`). Nine commands build sticky notes (8 soft colours, author line, text
  shrinking as the note grows), shapes with centred wrapping text, connectors that re-route when
  either end moves, stamps, marker/highlighter/eraser strokes, colour/style setters and
  `board.nextSticky` (`crates/engine/src/board.rs`, `docs/mcp.md` › Boards). Board objects are
  ordinary layers with a `board` field, so rendering, saving, export, copy/paste, undo and live
  sessions work unchanged (`crates/doc/src/board.rs` `BoardItem`); proto/Dev Mode refuse on boards.
- **Prototyping**: 10 trigger kinds, 11 actions (incl. overlay open/swap/close, scroll-to, set
  variable/mode, conditionals), 8 transitions, 13 easings/springs, flows, presentation with device
  frames and live preview; a top-level frame taller than the device scrolls through its whole size
  without an overflow setting (`crates/doc/src/proto.rs`, `crates/ui-egui/src/present.rs`,
  `docs/prototyping-parity.md`).
- **Handoff / Dev Mode**: ready-for-dev status with "Changed" detection and Compare against the
  marked snapshot **or any saved version** (`dev.compare {version}`), annotations, measurements kept
  on the canvas (`devMode.addMeasurement`/`measurements`/`removeMeasurement`), an inspect-only canvas
  and read-only layers panel, generated CSS/HTML/React/Leptos/SwiftUI/Compose with component
  properties as parameters and import lines, Code Connect links, dev resources
  (`crates/engine/src/{codegen,dev_measurements,devcompare,devinspect}.rs`, `docs/dev-mode-parity.md`).
- **In-file review**: comment threads (replies, @mentions, reactions, resolve), named versions with
  preview/restore/duplicate, branches with update-from-main, review and merge
  (`crates/doc/src/comments.rs`, `crates/format/src/lib.rs`, `docs/collaboration-parity.md`).
- **Data pipelines**: `data.fill` repeats a frame once per data row, optionally per output size and
  exporting each copy; with `text.fit` it is a carousel/social-post generator in one command
  (`crates/engine/src/datafill.rs`, `docs/mcp.md` › Filling copies with data).

**Formats it opens (verified in code)**
- `.figcraft` — native zip, or a bare `document.json` (`crates/format/src/lib.rs`).
- `.json` — FigCraft document JSON, or the Figma REST API file response (`GET /v1/files/:key`), plus
  an optional local-variables JSON and an `images/<imageRef>.*` folder (`crates/format/src/rest`).
- `.fig` — best-effort import of Figma's own file, never overwritten by Save; budgets come from the
  file's own size and an import report lists what changed (`crates/format/src/fig`).
- `.svg` — imported as an editable frame; unsupported filters are dropped with a warning
  (`crates/svg`, `docs/file-format-parity.md`).
- Images: `.png`, `.jpg`/`.jpeg`, animated `.gif`, `.webp`, `.bmp`, `.tif`/`.tiff`, with embedded ICC
  profiles honoured (`crates/engine/src/cmd/file.rs`, `crates/render/src/images.rs`).
- PDF is **export-only**; there is no PDF import, no HEIC and no video decode.

**Formats it writes**
- `.figcraft` — native zip: `document.json`, `images/<sha256>`, optional `thumbnail.png`, `versions/`,
  `branches/`, `library/`; staging file plus one atomic rename (`crates/format/src/lib.rs`).
- `.svg`, `.png`, `.jpg`/`.jpeg`, `.webp`, `.pdf` (`crates/doc/src/props.rs`
  `ExportFormat::from_ext`, `apps/figcraft-cli/src/files.rs` `write_doc`).
- `.pdf` — one page per top-level frame, real selectable text, clickable links, bleed/crop marks and
  naive CMYK via `--bleed --crop-marks --bleed-marks --cmyk` (`docs/cli.md`, `crates/pdf`).
- `.fig` — **experimental** whole-document export (`crates/format/src/fig/export.rs`); written files
  open elsewhere with layers, paints, strokes, shadows, vectors, components, text, resized instances,
  variables-with-modes, styles, variable-width strokes and grid tracks intact; effects, images and
  prototypes are unchecked there, and every omission is a `warning`
  (`docs/file-format-parity.md` › Export to `.fig`).
- `.json` — FigCraft JSON is written by `figcraft-cli convert`/`run --out`, **not** by the app's
  Save (Save always writes the native archive; `crates/engine/src/cmd/file.rs` `save_to`).

**Automation surfaces (re-measured at this tag)**
- **`figcraft-cli`** — headless engine with **9 subcommands**: `info`, `export`, `convert`, `render`
  (png/jpg/webp), `run` (JSON/JSONL command scripts), `commands`, `mcp`, `plugin publish`, `perf`
  (`apps/figcraft-cli/src/main.rs` `USAGE`, `docs/cli.md`). Every subcommand takes
  `--no-system-fonts`; `info`/`export`/`convert`/`render`/`run`/`mcp` also take
  `--automation-read-root` and `--automation-write-root`. New since v0.10.0: `--help`/`-h` is
  accepted anywhere among the options and exits 0 (`apps/figcraft-cli/src/args.rs` `CliError::Help`).
- **Control channel** — `figcraft --control <port>`, loopback-only, newline-delimited JSON with
  **17 methods**: `engine.execute`, `engine.commands`, `document.inspect`, `node.get`, `ui.inspect`,
  `ui.pointer`, `ui.key`, `ui.type`, `ui.input`, `ui.menu.invoke`, `ui.set`, `ui.screenshot`,
  `ui.render`, `window.new/list/focus`, `app.quit` (`crates/ui-egui/src/control.rs`,
  `docs/control-protocol.md`). State methods answer while the window is minimised; methods that need
  a drawn frame (`ui.screenshot`, `ui.input`, `window.new`) fail fast (`NEEDS_FRAME`). `ui.set`
  gained `devCompareVersion` in this line.
- **MCP server** — `figcraft-cli mcp` (headless) or `--attach <port>` (drives the running app);
  **18 tools**: `list_commands`, `run_command`, `batch`, `create_node`, `set_properties`,
  `inspect_document`, `get_node`, `select`, `export`, `screenshot`, `open_file`, `save_file`,
  `undo`, `redo`, `pointer`, `key`, `type_text`, `inspect_ui`; **2 resources + 2 templates**
  (`figcraft://document`, `figcraft://commands`, `figcraft://node/{id}`, `figcraft://command/{id}`)
  and **4 prompts** (`mobile_screen`, `design_system`, `landing_page`, `prototype_flow`)
  (`crates/mcp/src/tools.rs` `TOOL_NAMES`, `resources.rs`, `prompts.rs`, `docs/mcp.md`). New since
  v0.10.0: responses are size-bounded — `inspect_document`/`get_node` take `maxBytes` (default 8 MiB,
  the stdio buffer) and `get_node` an `offset`, returning a `truncated` marker instead of overflowing
  a client's read buffer (`crates/mcp/src/tools.rs` `MAX_RESPONSE`, `budget`).
- **Live sessions from a script** — **21 `collab.*` commands** cover host/join/share/publish, cursors,
  chat and spotlight; the headless MCP session and the attached app can host, join and publish, the
  one-shot `run` cannot (no network link) (`crates/engine/src/live.rs`, `online.rs`,
  `docs/mcp.md` › Live sessions); boards sync like any document (`crates/collab/src/board_sync_tests.rs`).
- **Plugins** — sandboxed WebAssembly (wasmi, metered fuel, memory cap, no fs/net/clock), manifest
  permissions, panels, settings and canvas widgets; Rust SDK and **three examples**; `pluginData`
  written by `node.set` reads back through `node.get` (`crates/plugin`, `plugins/examples`, `docs/plugins.md`).
- **Templates** — eight code-built starters (`mobile-app`, `landing-page`, `dashboard`,
  `design-system`, `wireframe-kit`, `social-posts`, `slides`, `icon-set`) via `template.list` and
  `file.newFromTemplate`; five example documents in `examples/` (`crates/engine/src/templates/mod.rs`).
- **Discovery is a command**: `figcraft-cli commands --json` (or MCP `list_commands`) prints every
  command's id, label, menu path, shortcut, undoability and parameter docs.

**Platform and runtime facts**
- WebAssembly build: **yes** (`cargo xtask wasm`, `apps/figcraft-web`); the browser build can join but
  not host sessions, keeps one window, has no system fonts and no accessibility tree
  (`docs/mcp.md`, `docs/hardware-parity.md`).
- Releases package macOS universal, Windows x64/x86/arm64, Linux (AppImage, deb, rpm, Flatpak,
  tarball), FreeBSD and web (`README.md`, `packaging/`).
- Crash discipline: no `unwrap`/`expect`/`panic` in shipped code (clippy denies them), a command guard
  rolls a panicking command back, and recovery copies are written every 10 s (`Cargo.toml`,
  `crates/engine/src/guard.rs`, `apps/figcraft/src/recovery.rs` `INTERVAL`).
- Accessibility: AccessKit names/roles on desktop, F6 cycles toolbar → layers → canvas → properties,
  reduced motion honoured (`crates/ui-egui/src/a11y.rs`).
- One process shows several **windows**, each with tabs, panels and canvas; a first run opens the home
  screen (Recents, Online, Templates) (`crates/ui-egui/src/windows.rs`, `home.rs`).

## Known limitations and not-implemented

Treat these as hard constraints: **partial** means it exists but is visibly incomplete; the rest are
**not implemented** or **claimed only** (docs assert them, code does not). The v0.11.x line closed the
Dev Mode tail and created boards, but no file-fidelity gap.

- **Boards are a first slice**: breadth ~35%, ready ~20% (`docs/boards-parity.md`). Missing: sticky
  size presets/stacks, shape auto-fit and more shapes, curved connectors/waypoints, stamp wheel,
  timer, voting, board widgets and templates, tables, mind maps, washi tape, code blocks, image
  cropping on boards, dot grid, audio/huddles, AI features, `.jam` import/export.
- **No real-Figma-file validation.** Every `.fig` corpus in the repo is synthetic; import is "best
  effort" and nothing has been checked against real documents (`docs/gaps.md` 1 and 3) — do not
  promise fidelity. Missing formats: HEIC images and video fills/triggers (no Rust decoder), `.jam`
  (FigJam) and `.deck` (Slides) out of scope (`docs/file-format-parity.md`).
- **No Figma plugin compatibility.** FigCraft runs its own WASM plugins, not JavaScript Figma plugins;
  widgets take clicks only (no text input, hover or timers) and there is no public plugin catalogue,
  only a self-hosted directory (`docs/gaps.md` 6, `docs/plugins.md`).
- **No AI features at all** and **no spell check** (`docs/gaps.md` 11 and 19).
- **Multiplayer is a preview**: live sessions with sync, cursors, selections, text carets, cursor
  chat, spotlight, per-person undo, join codes and invite links, plus a self-hosted
  `figcraft-server`, but **no accounts and no teams**; codes/links are the access and the server
  stores files unencrypted (`README.md` › Privacy and online sharing).
- **Prototype tail**: no media triggers/actions; controller buttons are read on Windows and in the
  browser but not on macOS, Linux or FreeBSD (`docs/prototyping-parity.md`).
- **Dev Mode tail**: publishing mappings from a code repository and the editor extension are missing;
  the component playground has no slot control (`docs/dev-mode-parity.md`, `docs/gaps.md` 16).
- **CPU canvas, sRGB screen**: Display P3 documents show sRGB-clipped with a gamut warning and
  soft-proof striping (true P3 is blocked upstream in egui-wgpu) (`docs/hardware-parity.md`).
- **Export limits**: SVG and PDF refuse a tree deeper than 256 descendant levels rather than writing
  an incomplete file, and `--cmyk` is the naive `K = 1 − max(R,G,B)` conversion — DeviceCMYK without
  an output intent, so proof against your printer's profile (`docs/file-format-parity.md` › Export,
  `docs/gaps.md` 23).
- **Screen readers have never been run** against the app; the browser build has no accessibility
  tree, and Linux/browser platform QA is still open (`docs/gaps.md` 22 and 8).
- **Localization status is claimed, not verified here**: 19 catalogs are in `crates/ui-egui/locales/`,
  the README lists 13 languages, and `docs/gaps.md` 5 calls only Russian and Turkish reviewed while
  `sv`, `es-419`, `bn`, `fi`, `nl`, `pl` exist beyond the list — treat review status as a claim.
- **Bounds worth knowing**: ≤100 versions and ≤100 branches per file; `document.json` is capped by a
  16× compression-ratio rule within 512 MiB per zip member (4 GiB unpacked on 64-bit, 1 GiB on
  32-bit) (`crates/format/src/lib.rs` `MAX_VERSIONS`, `MAX_BRANCHES`, `DOCUMENT_RATIO`, `MAX_MEMBER`).
- **Counts drift, trust code**: `docs/parity-checklist.md` still says **561** commands (2026-10-17),
  README says "400+", change logs quote "211/211" against the measured 212/212, and
  `docs/architecture.md` says "two example plugins" where `plugins/examples` holds three. This tree
  has **597** unique `spec!` registrations across 60 namespaces; count your build with
  `figcraft-cli commands --json`. Uncertain — see `docs/gaps.md` for the ranked, self-scored list.

## How to operate

**Launch.** Installed app: `/Applications/FigCraft.app`; `open -a FigCraft [file.figcraft]` opens a
file. The bundle declares the `figcraft` document type, SVG, PNG and JPEG types and the
`figcraft://` URL scheme; identifier `ai.storyteller.figcraft` (`packaging/macos/Info.plist.in`,
`/Applications/FigCraft.app/Contents/Info.plist`). To pass flags, run the binary directly:

```sh
"/Applications/FigCraft.app/Contents/MacOS/FigCraft" --control 7979 WORK/project/app.figcraft
"/Applications/FigCraft.app/Contents/MacOS/FigCraft" --control 7979 \
    --automation-read-root WORK/project --automation-write-root WORK/project/out
```

`--control <port>` starts the loopback JSON-lines control server (or set
`FIGCRAFT_CONTROL_PORT`); `--automation-read-root` / `--automation-write-root` (repeatable) confine
every file the channel and windows may read or write; any unknown option — including a mistyped root
flag — stops the app at startup instead of running unconfined (`apps/figcraft/src/args.rs`,
`apps/figcraft/src/main.rs`, `docs/control-protocol.md`). An invite link (`figcraft://join?…`) or a
`file://` URL on the command line opens or joins it.

**There is no CLI inside the macOS bundle.** The GUI app is the only binary in
`/Applications/FigCraft.app/Contents/MacOS/`. Build it with `cargo build --release -p figcraft-cli` →
`target/release/figcraft-cli`; macOS releases ship a separate `figcraft-cli-<version>-macos-<arch>.zip`
(`packaging/macos/package.sh`). On Linux only, `FigCraft.AppImage cli <args>` runs it (`packaging/linux/AppRun`).

**CLI surface** (verified in `apps/figcraft-cli/src/main.rs`, `docs/cli.md`):

```sh
figcraft-cli info app.figcraft [--json]                 # + missingFonts per file
figcraft-cli export app.figcraft -o exports/ --scale 2  # one file per top-level frame
figcraft-cli export app.figcraft -o hero.svg --node "Hero"
figcraft-cli export app.figcraft -o screens.pdf --page "Screens"
figcraft-cli convert in.svg out.figcraft                # by extension
figcraft-cli render app.figcraft -o page.png --scale 2  # png, jpg or webp out
figcraft-cli run build.json --in base.figcraft --out result.figcraft
figcraft-cli commands --filter autoLayout [--json]
```

Every subcommand takes `--no-system-fonts` (or `FIGCRAFT_NO_SYSTEM_FONTS=1`) for reproducible
renders. Exit codes: bad arguments 2, failures 1, success 0 (`--help`/`-h` 0). `--scale` ≤64; pages
shrink to fit 16384 px on `render`; PDF bleed ≤2 in. `export` to a directory writes one file per
top-level frame; an image extension, or `--node`, writes one file. PDF print options
(`--bleed 3mm --crop-marks --bleed-marks --cmyk`) also work.

**Document model.** One process shows several **windows**, each with its own **tabs**, panels and
canvas (`window.new`); a first run opens the **home screen** (Recents, Online, Templates, search).
Files are documents with pages and per-tab unsaved changes. A `.figcraft` also carries a **kind**:
`design` (default) or `board` (`crates/doc/src/board.rs` `FileKind`). Boards get a bottom toolbar,
no Design panel by default and a contextual bar above the selection, and refuse prototyping/Dev
Mode; design files refuse the `board.*` commands.

**Round trip.** Open (`.figcraft` / `.json` / `.fig` / `.svg` / image) → edit (UI, CLI `run`, control
channel, MCP) → **Save** (`.figcraft`, atomic staging + rename) → export (PNG/JPG/SVG/PDF/WebP, or
experimental `.fig`). Saving is never in-place over an imported `.fig`; "Save as" with a `.fig` name
writes an export copy and the document keeps its `.figcraft` path
(`crates/engine/src/cmd/file.rs`); `pref.autoSave` also auto-saves files that have a path.

**Keyboard shortcuts**: do not invent them. The machine-readable list is `figcraft-cli commands
--json` (each command's `shortcut`) or MCP `list_commands`, generated from
`crates/engine/src/keymap.rs` — **159 default bindings in 12 groups** (Essential, Tools, View, Zoom,
Text, Shape, Selection, Edit, Transform, Arrange, Components, Prototype) with macOS and, where they
differ, Windows/Linux keys. The eight board bindings are new here (Q sticky, B shapes, X connector,
M marker, U highlighter, E eraser, W stamp, Shift+Cmd+Enter next sticky; `docs/ui-parity.md`), which
separately tracks **129 documented shortcut rows** (128 bound as documented; 57 undocumented
bindings pinned). The in-app Keyboard shortcuts panel shows the same keymap.

## Working with an AI agent

What an agent can legitimately do:

- **Drive the app headlessly.** `figcraft-cli run` a JSON array (or `.jsonl`) of
  `{"command": id, "params": {…}}`; `{"$step": n}` resolves to the `id` from step `n`'s result, so one
  script builds a whole screen. Scripts are **all-or-nothing and one undo step**; a failed step prints
  `"rolledBack": true` and exits 1 having written nothing (`apps/figcraft-cli/src/files.rs`).
- **Drive the running app** so the user watches: start it with `--control PORT`, then
  `figcraft-cli mcp --attach PORT` (MCP tools) or speak the JSON-lines protocol directly. Attached
  calls are **never replayed** after a transport failure — inspect before retrying an edit
  (`docs/mcp.md`).
- **Confine it.** Pass `--automation-read-root` / `--automation-write-root` to the app, `figcraft-cli
  mcp`, or any `info`/`export`/`convert`/`render`/`run` run. Writes need a write root; reads need
  either; `--attach` plus roots is a usage error (`docs/mcp.md` › Confining file access).
- **Prepare inputs.** Generate or convert assets into formats FigCraft reads: SVG (best editable
  import), PNG/JPG/WebP/GIF/TIFF/BMP. For real Figma work the highest-fidelity path is the REST API
  file JSON plus its local-variables JSON plus an `images/<imageRef>.png` folder — the importer reads
  all three (`docs/mcp.md` › Importing REST API file JSON). PDF is export-only.
- **Generate batches.** `data.fill` + `text.fit` turn one frame and a JSON list of rows into a
  carousel or a set of post sizes with the text fitted — no per-copy editing loop
  (`crates/engine/src/datafill.rs`, `docs/mcp.md` › Filling copies with data).
- **Inspect and repair native files** (cautiously). A `.figcraft` is a plain zip:
  `unzip -p f.figcraft document.json` reads the whole model, `images/<sha256>` holds raw image bytes,
  and `versions/index.json` / `branches/index.json` hold history. Reading is lenient (structural
  problems are repaired and reported) but a newer format version is refused
  (`FormatError::Newer`). Prefer repairing through commands (`document.inspect`, `node.set`,
  `node.get`); if you must hand-edit, keep `format`/`version` and re-zip the *entire* member set.
- **Verify output.** `figcraft-cli info <file> --json` for structure, notes and missing fonts;
  re-open an export (`convert` back to `.figcraft`) to prove it decodes; compare a PNG export at a
  known `--scale` against a `ui.render`; for `.fig` output, re-open it in FigCraft and read the
  `warnings` list.
- **Contribute safely**: FigCraft forbids third-party product iconography or images — never add or
  redraw Figma/Adobe assets, and every asset needs a row in `ATTRIBUTION.md` (`AGENTS.md`).

What an agent must **not** do:

- Do not automate the GUI by clicking blind: use the control channel (`ui.pointer`, `ui.key`,
  `ui.input`, `ui.menu.invoke`, `ui.set`) or commands; programmatic calls never open dialogs.
  `ui.screenshot`, `ui.input` and `window.new` need a visible window (`docs/control-protocol.md`).
- Do not assume a Figma format or feature works. No video fills, no HEIC, no `.jam`/`.deck`, no Figma
  plugins, no AI features; `.fig` is best-effort in, experimental out, and unproven on real files.
- Do not treat the browser build as equivalent: it can join but not host sessions, keeps one window,
  has no system fonts and no accessibility tree; Display P3 is sRGB-clipped on screen.
- Do not put prototyping or board work in the wrong file kind: `proto.*`/`dev.*` refuse on boards and
  `board.*` refuses on design files (`crates/engine/src/board.rs` `NOT_ON_BOARDS`, `NEEDS_BOARD`).
- Do not share to a server uninvited: `collab.share` with `via: "online"` (its default) **publishes
  the document to a server other people run** — only call it when sharing is the request.
- Do not send huge inspection results: MCP responses are capped at 8 MiB by default (`maxBytes`); ask
  for a shallower `depth`, a `get_node` `offset`, or read the document in pieces
  (`crates/mcp/src/tools.rs` `MAX_RESPONSE`).

## Verification protocol

FigCraft is alpha; treat every automated run as untrusted until checked:

1. **Throwaway round trip per session.** From a template (`file.newFromTemplate`) or a copy: create →
   edit → `save_file`/`--out` to `.figcraft` → reopen → export PNG/PDF. Compare `info` node counts
   before and after; a decoder that only reads what it wrote is how the repo tests `.fig` export.
2. **Never trust a silent export.** Watch stderr: exports and imports print `note:` lines for what was
   dropped, `.fig`/REST/SVG imports return `warnings`, and a failed SVG/PDF depth check leaves the
   existing destination intact. Check the exit code.
3. **Version and back up project files.** Ask for the user's document to be committed or copied before
   a batch of automated edits; version history (≤100 versions), branches, auto-save and 10-second
   recovery copies are safety nets, not backups.
4. **Update between projects.** A `.figcraft` written by a newer format version is refused by an older
   one, and a board relies on the `kind` field that older builds do not know — verify the file's kind
   and boards after any downgrade, before trusting a batch run on it.
5. **Scope credentials and sharing.** Live sessions and servers are previews with code/link access and
   no accounts; don't put confidential work on a server you don't run, and the public server keeps the
   file until removed or 30 days unopened (`README.md` › Privacy and online sharing).

## References

- `references/automation-surfaces.md` — command/MCP/control-channel/CLI detail for large jobs: tool and
  method tables, arguments, limits, path confinement, batch semantics, boards, data-fill, server CLI.

## Sources & evidence

- Repo: https://github.com/storytold/figcraft — inspected at tag **v0.11.2**, commit
  **d4a303d4708602a9df1738960852d18b185a616b** ("Release 0.11.2", 2026-10-25); the installed app
  reports the same version and commit. Date inspected: 2026-10-26.
- Delta v0.10.0 → v0.11.2, re-measured rather than copied: **597** commands across **60** namespaces
  (was 569 / 57) and **159** keymap bindings (was 151); the other surfaces kept their shape (9 CLI
  subcommands, 17 control methods, 18 MCP tools + 2 resources + 2 templates + 4 prompts, 212/212 menu
  items, 8 templates, 5 examples, 19 locale catalogs, 3 example plugins). New here, each verified in
  this tree: boards and their 9 commands (`crates/doc/src/board.rs`, `crates/engine/src/board.rs`,
  `docs/boards-parity.md`, `file.newBoard`, seven board tools), `data.fill`
  (`crates/engine/src/datafill.rs`), `text.fit` (`crates/engine/src/textfit.rs`), Dev Mode
  measurements and version compare (`crates/engine/src/dev_measurements.rs`, `devcompare.rs`), vector
  fill rules, `.fig` grid tracks (`crates/format/src/fig/export.rs`), MCP `maxBytes`/`offset` and CLI
  `--help`. The clone is a single-commit shallow checkout, so the delta comes from re-measuring this
  tree against the previous skill's recorded measurements — not local git history.
- Key files read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`; `crates/doc/src/` (`node.rs`,
  `props.rs`, `proto.rs`, `styles.rs`, `board.rs`, `lib.rs`); `crates/{color,layout}/src/lib.rs`;
  `crates/format/src/{lib,library}.rs` and `crates/format/src/fig/{export,kiwi}.rs`;
  `crates/engine/src/{fonts,keymap,catalog,guard,file_access,live,online,board,datafill,textfit,dev_measurements,devcompare,codegen,devinspect}.rs`,
  `cmd/{mod,file,edit,variables_io,section}.rs`, `templates/mod.rs`; `apps/figcraft-cli/src/{main,args,files}.rs`;
  `apps/figcraft/src/{main,args,recovery}.rs`; `apps/figcraft-server/src/{cli,config}.rs`;
  `crates/mcp/src/{tools,resources,prompts,server}.rs`;
  `crates/ui-egui/src/{control,windows,home,a11y,board_bar,present}.rs`;
  `packaging/macos/{Info.plist.in,package.sh}`, `packaging/linux/AppRun`; `plugins/examples/`.
- Docs read (counts re-checked against code where stated): `docs/{cli,mcp,control-protocol,file-format-parity,gaps,target-app-parity,boards-parity,dev-mode-parity,prototyping-parity,components-parity,collaboration-parity,localization-parity,hardware-parity,ui-parity,auto-layout-parity,plugins,parity-checklist,architecture}.md`.
- Shared libraries: FigCraft depends on `craft-docpath` (rev `82a24b0…`) and `craft-window` (rev
  `1f80537…`) from `storytold/craft-libs`, and patches `krilla` to rev `9f75d3d…` (`Cargo.toml`);
  the native format is defined in this repo, not in craft-libs.

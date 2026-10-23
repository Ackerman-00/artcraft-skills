---
name: figcraft
description: >
  FigCraft is an open-source, pure-Rust, offline interface-design and prototyping app (a clean-room
  reimplementation of the Figma Design workflow): frames, auto layout, components and variants,
  styles and variables, vector networks, prototyping, comments, versions and Dev Mode, on macOS,
  Windows, Linux, FreeBSD and the web. Trigger this skill whenever the user mentions FigCraft or a
  `.figcraft` file, asks what FigCraft can or cannot do, which formats it opens or writes, how to
  script, automate, batch or headlessly drive it (figcraft-cli, MCP, the JSON control channel),
  wants assets prepared for a design file, needs its output verified or repaired, or asks to
  troubleshoot it — and also when the app is not named but the job is one of its jobs: "make a
  mockup", "design a screen / landing page / dashboard", "build a design system", "export these
  frames to PNG/PDF/SVG", "open this .fig or Figma file JSON", "prototype this flow", "hand this
  off to a developer". Prefer this skill over generic design-file advice for anything FigCraft
  touches; do not guess capabilities from Figma knowledge — FigCraft is not Figma and does not run
  Figma plugins.
---

Audit basis: this checkout is tag `v0.10.0`, commit `80f916326fb94f3a88cb24e64f396f564a0ebc06`
("Release 0.10.0", 2026-10-22). The installed `/Applications/FigCraft.app` reports version `0.10.0`
(`CFBundleShortVersionString`) and its binary prints `FigCraft 0.10.0
(80f916326fb94f3a88cb24e64f396f564a0ebc06)`, so the bundle matches this source exactly.
**Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Deep
operational detail — the full CLI, control-channel and MCP tables, live-session commands and the
server — is in `references/automation-surfaces.md`.

# FigCraft

## Overview

FigCraft is a native, offline interface-design and prototyping app written entirely in Rust
(egui/eframe UI, tiny-skia CPU renderer, no Electron), built clean-room from public documentation
and observed behaviour against Figma Design as its reference (`README.md` › Under the hood,
`docs/target-app-parity.md`). It is **alpha**: the README says "about 49% of the way to replacing
proprietary tools for real work", while the roadmap's self-graded tables say ~53% ready, ~85%
feature breadth and ~94% core-editor breadth (`README.md`, `ROADMAP.md`,
`docs/target-app-parity.md`). It runs on macOS, Windows, Linux, FreeBSD and in the browser via
WebAssembly; source is GitHub `storytold/figcraft`, MIT OR Apache-2.0. Every user-visible action is
a command in one registry — 569 commands at this tag, covering 212/212 catalogued menu items
(`crates/engine/src/cmd/mod.rs`, `docs/parity-checklist.md`) — dispatched identically by the UI,
CLI, JSON control channel and MCP server, which is the main reason an agent should load this skill.

0.10.0 is a maintenance release: it moves UTC/calendar formatting onto `chrono` with
output-preserving tests (`crates/collab/src/message.rs`, `crates/ui-egui/src/home_recents.rs`),
adds SonarCloud CI and a README icon. **No command, MCP tool, control method, format or shortcut
changed in 0.10.0**; the statements below were re-verified against this tag, not copied forward.

## Capabilities (verified)

**Model and editing**
- Frames, groups, sections, mask groups, rectangles (squircle corners), ellipses with arc/ring
  handles, polygons, stars, lines (arrowheads are stroke caps), text, vector networks, boolean
  groups, components, component sets, instances and slices (`crates/doc/src/node.rs` `NodeKind`;
  `crates/doc/src/props.rs` arrow caps; MCP `create_node`).
- **Auto layout**: horizontal/vertical flow, wrap and grid with fixed/hug/`fr` tracks, spanning
  cells, padding, gaps, Hug/Fill/Fixed sizing, min/max sizes, absolute children, baseline
  cross-align, `contentAlign`, strokes-in-layout (`crates/layout/src/lib.rs`;
  `docs/auto-layout-parity.md`).
- **Vector networks**: Pen and Pencil, vector edit mode (multi-layer editing, bend, paint bucket,
  lasso, cut), shape builder, booleans that stay editable, per-point corner radius, handle
  mirroring, per-point caps/joins, variable-width strokes, outline stroke, dashes, per-side
  strokes, brushes and pen pressure, text on a path, pattern fills (`crates/engine/src/vectoredit.rs`,
  `crates/pathops/src/lib.rs`, `crates/engine/src/shapebuilder.rs`, `docs/mcp.md`).
- **Text**: in-place editing, mixed styles within a paragraph, auto width/height, variable font axes,
  OpenType features, lists, bidi/RTL, HarfRust shaping plus system or `craft-fonts` fonts. Missing
  fonts are reported, can be loaded without installing and refitted (`text.missingFonts`,
  `text.rescanFonts`, `text.loadFont`, `text.refit`; `crates/engine/src/fonts.rs`; `info` prints
  `missingFonts`).
- **Paint and effects**: solid, linear/radial/angular/diamond gradients, image fills with
  adjustments, pattern fills, blend modes, inner/drop shadows, layer/background blur (uniform and
  progressive), noise, texture, glass and masks; sRGB or Display P3 with image profile conversion
  (`crates/color/src/lib.rs`, `crates/doc/src/props.rs`, `crates/render/src/image_profile.rs`).
- **Components and design systems**: mains, instances with per-layer overrides, sets and variants,
  properties (boolean/text/instance-swap/slot), swap/detach/reset/restore, playground
  (variant/boolean/text only), paint/text/effect/grid styles, variables
  (colour/number/string/boolean) with modes, aliases, scopes, bindings and variables inside styles,
  JSON/CSS import/export (`crates/doc/src/styles.rs`, `crates/engine/src/cmd/variables_io.rs`).
- **Prototyping**: triggers (click, hover, press, drag, mouse enter/leave/down/up, delay, key and
  controller button), actions (navigate, overlay open/swap/close, scroll-to, back, open link,
  change-to, set variable/mode, conditionals), easings/springs, flows, presentation with device
  frames, hotspot hints and live preview (`crates/doc/src/proto.rs`, `docs/prototyping-parity.md`).
- **Handoff / Dev Mode**: ready-for-dev status with "Changed" detection and Compare changes,
  annotations in categories, measurements, generated CSS, HTML, React, Leptos, SwiftUI and Compose
  with component properties as parameters, Code Connect links, dev resources
  (`crates/engine/src/codegen.rs`, `crates/engine/src/devinspect.rs`, `docs/dev-mode-parity.md`).
- **In-file review**: comment threads (replies, @mentions, reactions, resolve, unread), named
  versions with preview/restore/duplicate, and branches with update-from-main, review and merge
  (`crates/doc/src/comments.rs`, `crates/format/src/lib.rs`,
  `docs/collaboration-parity.md`).

**Formats it opens (verified in code)**
- `.figcraft` — native zip, or a bare `document.json` (`crates/format/src/lib.rs`).
- `.json` — FigCraft document JSON, or the Figma REST API file response (`GET /v1/files/:key` and
  nodes responses), plus an optional local-variables JSON and an `images/<imageRef>.*` folder beside
  it (`crates/format/src/rest`, `crates/engine/src/cmd/file.rs`).
- `.fig` — best-effort import of Figma's own file, never overwritten by Save; large files open
  within budgets derived from the file's own size; an import report/warnings list what changed
  (`crates/format/src/fig`, `docs/file-format-parity.md`).
- `.svg` — imported as an editable frame; unsupported filters are dropped with a warning
  (`crates/svg`, `docs/file-format-parity.md`).
- Images: `.png`, `.jpg`/`.jpeg`, animated `.gif` (fills play in the presenter/preview), `.webp`,
  `.bmp`, `.tif`/`.tiff`, with embedded ICC profiles honoured (`crates/engine/src/cmd/file.rs`
  extension match, `crates/render/src/images.rs`).
- PDF is **export-only**; there is no PDF import.

**Formats it writes**
- `.figcraft` — native zip: `document.json`, `images/<sha256>`, optional `thumbnail.png`,
  `versions/`, `branches/` and `library/`; written through a staging file plus one atomic rename
  (`crates/format/src/lib.rs` `write_file_atomic`).
- `.svg`, `.png`, `.jpg`/`.jpeg`, `.webp`, `.pdf` (`crates/doc/src/props.rs`
  `ExportFormat::from_ext`, `apps/figcraft-cli/src/files.rs`).
- `.pdf` — one page per top-level frame, real selectable text in subset fonts, clickable links,
  bleed/crop/bleed marks and naive CMYK via `--bleed --crop-marks --bleed-marks --cmyk`
  (`docs/cli.md`, `crates/pdf`).
- `.fig` — **experimental** whole-document export (`crates/format/src/fig/export.rs`); written files
  open in other software with layers, paints, strokes, shadows, vectors, components, text,
  resized/scaled instances, variables-with-modes, styles and symmetric variable-width strokes
  intact; effects, images and prototypes are unchecked there, and every omission is a `warning`
  (`docs/file-format-parity.md` › Export to `.fig`).
- `.json` — FigCraft JSON is written by `figcraft-cli convert`/`run --out`, **not** by the app's
  Save (Save always writes the native archive; `crates/engine/src/cmd/file.rs` `save_to`).

**Automation surfaces (the app's strongest property)**
- **`figcraft-cli`** — headless engine with 9 subcommands: `info`, `export`, `convert`, `render`
  (png/jpg/webp), `run` (JSON/JSONL command scripts), `commands`, `mcp`, `plugin publish`, `perf`
  (`apps/figcraft-cli/src/main.rs`, `docs/cli.md`). Every subcommand takes `--no-system-fonts`;
  `info`/`export`/`convert`/`render`/`run` also take `--automation-read-root` and
  `--automation-write-root`.
- **Control channel** — `figcraft --control <port>`, loopback-only, newline-delimited JSON with 17
  methods: `engine.execute`, `engine.commands`, `document.inspect`, `node.get`, `ui.inspect`,
  `ui.pointer`, `ui.key`, `ui.type`, `ui.input`, `ui.menu.invoke`, `ui.set`, `ui.screenshot`,
  `ui.render`, `window.new/list/focus`, `app.quit` (`crates/ui-egui/src/control.rs`,
  `docs/control-protocol.md`). State methods answer while the window is minimised; drawn-frame
  methods fail fast.
- **MCP server** — `figcraft-cli mcp` (headless) or `--attach <port>` (drives the running app); 18
  tools: `list_commands`, `run_command`, `batch`, `create_node`, `set_properties`,
  `inspect_document`, `get_node`, `select`, `export`, `screenshot`, `open_file`, `save_file`,
  `undo`, `redo`, `pointer`, `key`, `type_text`, `inspect_ui`; 2 resources + 2 resource templates
  (`figcraft://document`, `figcraft://commands`, `figcraft://node/{id}`,
  `figcraft://command/{id}`) and 4 prompts (`mobile_screen`, `design_system`, `landing_page`,
  `prototype_flow`) (`crates/mcp/src/tools.rs`, `resources.rs`, `prompts.rs`, `docs/mcp.md`).
- **Live sessions from a script** — 21 `collab.*` commands cover host/join/share/publish, cursors,
  chat and spotlight; the headless MCP session can host, join and publish, the attached app can do
  all of it, and the one-shot `run` cannot (no network link) (`docs/mcp.md` › Live sessions,
  `crates/engine/src/live.rs`, `crates/engine/src/online.rs`).
- **Plugins** — sandboxed WebAssembly (wasmi, metered fuel, 64 MB memory cap, no
  filesystem/network/clock), JSON manifest permissions, panels and canvas widgets; Rust SDK and
  three examples under `plugins/`; `pluginData` written with `node.set` is read back by `node.get`
  and `document.inspect` (`docs/plugins.md`, `crates/plugin`, `plugins/examples`).
- **Templates** — eight code-built starters (`mobile-app`, `landing-page`, `dashboard`,
  `design-system`, `wireframe-kit`, `social-posts`, `slides`, `icon-set`) via `template.list` and
  `file.newFromTemplate {template}`; five example documents ship in `examples/`
  (`crates/engine/src/templates/mod.rs`).

**Platform and runtime facts**
- WebAssembly build: **yes** (`cargo xtask wasm`, `apps/figcraft-web`); the browser build can join
  but not host live sessions, keeps one window, has no system fonts and no accessibility tree
  (`docs/mcp.md`, `docs/control-protocol.md`, `docs/hardware-parity.md`).
- Releases package macOS universal, Windows x64/x86/arm64, Linux (AppImage, deb, rpm, Flatpak,
  tarball), FreeBSD and web (`README.md`, `packaging/`).
- Crash discipline: no `unwrap`/`expect`/`panic` in shipped code (clippy denies them), commands run
  behind a guard that turns a panic into an error and rolls the document back, and recovery copies
  of unsaved documents are written every 10 s (`Cargo.toml` lints,
  `crates/engine/src/guard.rs`, `apps/figcraft/src/recovery.rs` `INTERVAL`).
- Accessibility: AccessKit names/roles on desktop, F6 cycles toolbar → layers → canvas →
  properties, reduced motion is honoured; the browser has no accessibility tree (`README.md`,
  `crates/ui-egui/src/a11y.rs`).
- One process shows several **windows**, each with tabs, panels and canvas; a first run opens the
  home screen (Recents, Online, Templates) (`crates/ui-egui/src/windows.rs`,
  `crates/ui-egui/src/home.rs`).

## Known limitations and not-implemented

Treat these as hard constraints when assigning work to FigCraft. 0.10.0 closed none of them.

- **No real-Figma-file validation.** Every `.fig` corpus in the repo is synthetic; import is "best
  effort" and nothing has been checked against real-world Figma documents (`docs/gaps.md` gaps 1
  and 3). Do not promise fidelity when importing someone's real `.fig`.
- **`.fig` export is experimental.** Whole-document only. Left out with a warning each: non-colour
  variable bindings as bindings, text styles on part of text, extended collections as their own
  collections, comments, Dev Mode annotations/statuses/resources/code links, plugin data, ruler
  guides, prototype device settings, slot properties and slot content, brush strokes, asymmetric
  strokes (written as outlines), pattern fills, image adjustments, glass settings other than frost,
  springs other than Gentle, set-variable/set-variable-mode/conditional actions, scroll offsets,
  variable font axes, text on a path, nested list levels, OpenType features, fixed/content grid
  tracks, and version history/branches. Effects, images and prototype interactions are unchecked
  in other software (`docs/file-format-parity.md` › Export to `.fig`).
- **Missing formats**: HEIC images and video fills/triggers are not implemented (no Rust decoder);
  `.jam` (FigJam) and `.deck` (Slides) are out of scope (`docs/file-format-parity.md`).
- **No Figma plugin compatibility.** FigCraft runs its own WASM plugins, not JavaScript Figma
  plugins. Widgets take clicks only — no text input, hover or timers — and there is no public
  plugin catalogue (`docs/gaps.md` 6).
- **No AI features at all** and **no spell check** (`docs/gaps.md` 11 and 19).
- **Multiplayer is a preview**: live sessions with sync, cursors, selections, text carets, cursor
  chat, spotlight, per-person undo, join codes and invite links, plus a self-hosted
  `figcraft-server`, but **no accounts and no teams**; codes/links are the access, and the server
  stores files unencrypted (not end-to-end encrypted) (`README.md` › Privacy and online sharing,
  `docs/collaboration-parity.md`).
- **Prototype tail**: no media triggers/actions; controller buttons are not read on macOS, Linux or
  FreeBSD; component playground has no instance-swap/slot controls (`docs/prototyping-parity.md`,
  `docs/components-parity.md`).
- **Dev Mode tail**: import lines inside generated layer trees are missing; the editor extension is
  left to the MCP server (`docs/dev-mode-parity.md`, `docs/gaps.md` 16).
- **CPU canvas, sRGB screen**: rendered on the CPU; Display P3 documents show as sRGB-clipped on
  screen with a gamut warning and soft-proof striping (true P3 is blocked upstream in egui-wgpu)
  (`docs/hardware-parity.md`, `docs/gaps.md` 18).
- **Export limits**: SVG and PDF refuse an export whose visible tree is deeper than 256 descendant
  levels, rather than writing an incomplete file (`docs/file-format-parity.md` › Export).
- **Print**: PDF `--cmyk` is the naive `K = 1 − max(R,G,B)` conversion, DeviceCMYK with no output
  intent — proof against your printer's profile (`docs/cli.md`, `docs/gaps.md` 23).
- **Screen readers have never been run** against the app; the browser build has no accessibility
  tree (`docs/gaps.md` 22).
- **Localization status is claimed, not verified here**: 19 locale catalogs are in the tree
  (`crates/ui-egui/locales/`), while the README lists 13 languages and calls English, Russian and
  Turkish reviewed. `sv`, `es-419`, `bn`, `fi`, `nl` and `pl` exist beyond that list. `docs/gaps.md`
  calls only Russian reviewed and Turkish a catalog, so treat review status as a claim until a
  native speaker confirms it (`README.md`, `docs/localization-parity.md`, `docs/gaps.md` 5).
- **Bounds worth knowing**: at most 100 versions and 100 branches per file; `document.json` is
  capped by a 16× compression-ratio rule within 512 MiB per zip member (4 GiB unpacked on 64-bit,
  1 GiB on 32-bit) (`crates/format/src/lib.rs` `MAX_VERSIONS`, `MAX_BRANCHES`, `DOCUMENT_RATIO`,
  `MAX_MEMBER`).
- **Counts drift**: `docs/parity-checklist.md` still carries the 2026-10-17 measure of **561**
  commands. This tag's tree has **569** unique `spec!` registrations and no command files changed
  between v0.9.0 and v0.10.0, so the published count is eight behind. Count your build with
  `figcraft-cli commands --json`.

Uncertain — see `docs/gaps.md` for the ranked, self-scored list. Platform QA on Linux and the
browser is still open (`docs/gaps.md` 8).

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
`docs/control-protocol.md`). An invite link (`figcraft://join?…`) or a `file://` URL on the command
line opens or joins it.

**There is no CLI inside the macOS bundle.** The GUI app is the only binary in
`/Applications/FigCraft.app/Contents/MacOS/`. Build it with
`cargo build --release -p figcraft-cli` → `target/release/figcraft-cli`; macOS releases ship it as
a separate `figcraft-cli-<version>-macos-<arch>.zip` (`packaging/macos/package.sh`). On Linux only,
`FigCraft.AppImage cli <args>` runs the bundled CLI (`packaging/linux/AppRun`).

**CLI surface** (verified in `apps/figcraft-cli/src/main.rs`, `docs/cli.md`):

```sh
figcraft-cli info app.figcraft [--json]                 # + missingFonts per file
figcraft-cli export app.figcraft -o exports/ --scale 2  # one file per top-level frame
figcraft-cli export app.figcraft -o hero.svg --node "Hero"
figcraft-cli export app.figcraft -o screens.pdf --page "Screens"
figcraft-cli export app.figcraft -o poster.pdf --node "Poster" --bleed 3mm --crop-marks --cmyk
figcraft-cli export app.figcraft -o handoff.fig         # experimental .fig
figcraft-cli convert in.svg out.figcraft                # by extension
figcraft-cli render app.figcraft -o page.png --scale 2  # png, jpg or webp out
figcraft-cli run build.json --in base.figcraft --out result.figcraft
figcraft-cli commands --filter autoLayout [--json]
figcraft-cli mcp [--attach 7979] [--automation-read-root DIR]…
figcraft-cli render in/doc.figcraft -o out/ok.png \
    --automation-read-root in --automation-write-root out
```

Every subcommand takes `--no-system-fonts` (or `FIGCRAFT_NO_SYSTEM_FONTS=1`) for reproducible
renders. Exit codes: bad arguments 2, failures 1, success 0. `--scale` is capped at 64; large pages
shrink to fit 16384 px on `render`; PDF bleed is capped at 2 in. `export` to a directory writes one
file per top-level frame; an output with an image extension, or `--node`, writes one file.

**Document model.** One process shows several **windows**, each with its own **tabs**, panels and
canvas (`window.new`, File ▸ New window). A first run opens the **home screen** (Recents, Online,
Templates, search). Files are documents with pages; unsaved changes are tracked per tab.

**Round trip.** Open (`.figcraft` / `.json` / `.fig` / `.svg` / image) → edit (UI, CLI `run`,
control channel, MCP) → **Save** (`.figcraft`, atomic staging-file + rename) → export
(PNG/JPG/SVG/PDF/WebP, or experimental `.fig`). Saving is never in-place over an imported `.fig`;
"Save as" with a `.fig` name writes an export copy and the document keeps its `.figcraft` path
(`crates/engine/src/cmd/file.rs`).

**Keyboard shortcuts**: do not invent them. The authoritative machine-readable list is
`figcraft-cli commands --json` (each command's `shortcut`) or MCP `list_commands`, generated from
`crates/engine/src/keymap.rs` — **151 default bindings in 12 groups** (Essential, Tools, View, Zoom,
Text, Shape, Selection, Edit, Transform, Arrange, Components, Prototype), each with macOS keys and,
where they differ, Windows/Linux keys. `docs/ui-parity.md` separately tracks **129 documented
shortcut rows** from the public help centre. The in-app Keyboard shortcuts panel shows the same
keymap.

## Working with an AI agent

What an agent can legitimately do:

- **Drive the app headlessly.** `figcraft-cli run` a JSON array (or `.jsonl`) of
  `{"command": id, "params": {…}}`; `{"$step": n}` in a param resolves to the `id` from step `n`'s
  result, so one script can build a whole screen. Scripts are **all-or-nothing and one undo step**;
  a failed step prints `"rolledBack": true` and exits 1 having written nothing (`docs/cli.md`,
  `apps/figcraft-cli/src/files.rs`).
- **Drive the running app** so the user watches: start it with `--control PORT`, then
  `figcraft-cli mcp --attach PORT` (MCP tools) or speak the JSON-lines protocol directly. Attached
  calls are **never replayed** after a transport failure — inspect before retrying an edit
  (`docs/mcp.md`).
- **Confine it.** Pass `--automation-read-root` / `--automation-write-root` to the app, to
  `figcraft-cli mcp`, or to any `info`/`export`/`convert`/`render`/`run` invocation. Writes need a
  write root; reads need either; `--attach` plus roots is a usage error (`docs/mcp.md` › Confining
  file access, `docs/cli.md` › Confining a run).
- **Prepare inputs.** Generate or convert assets into formats FigCraft reads: SVG (best editable
  import), PNG/JPG/WebP/GIF/TIFF/BMP. For real Figma work the highest-fidelity path is the REST API
  file JSON plus its local-variables JSON plus an `images/<imageRef>.png` folder — the importer reads
  all three (`docs/mcp.md` › Importing REST API file JSON). PDF is export-only.
- **Inspect and repair native files** (cautiously). A `.figcraft` is a plain zip:
  `unzip -p f.figcraft document.json` reads the whole model, `images/<sha256>` holds the raw image
  bytes, and `versions/index.json` / `branches/index.json` hold history. Reading is lenient:
  structural problems are repaired on load and reported; a file written by a newer format version
  is refused outright (`FormatError::Newer`). Prefer repairing through commands
  (`document.inspect`, `node.set`, `node.get`) over rewriting the JSON by hand; if you must
  hand-edit, keep `format`/`version` and re-zip the *entire* member set.
- **Verify output.** `figcraft-cli info <file> --json` for structure, notes and missing fonts;
  re-open an export (`convert` back to `.figcraft`) to prove it decodes; compare a PNG export at a
  known `--scale` against a `ui.render`; for `.fig` output, re-open it in FigCraft and read the
  `warnings` list.
- **Contribute safely**: FigCraft forbids third-party product iconography or images — never add or
  redraw Figma/Adobe assets, and every asset needs a row in `ATTRIBUTION.md` (`AGENTS.md`).

What an agent must **not** do:

- Do not automate the GUI by clicking blind: use the control channel (`ui.pointer`, `ui.key`,
  `ui.input`, `ui.menu.invoke`, `ui.set`) or the commands; programmatic calls never open dialogs.
  `ui.screenshot` and `ui.input` need a visible window — a minimised window answers state methods
  but refuses those at once (`docs/control-protocol.md`).
- Do not assume a Figma format or feature works. No video fills, no HEIC, no `.jam`/`.deck`, no
  Figma plugins, no AI features; `.fig` is best-effort in and experimental out.
- Do not promise exact `.fig` round trips or real-Figma-file fidelity: nothing has been measured
  on real files.
- Do not treat the browser build as equivalent: it can join but not host sessions, keeps one
  window, has no system fonts and no accessibility tree.
- Do not rely on on-screen Display P3: documents can hold P3 and exports carry the profile, but the
  canvas shows clipped sRGB with a soft-proof option (`docs/hardware-parity.md`).
- Do not share to a server uninvited: `collab.share` with `via: "online"` (its default)
  **publishes the document to a server other people run** — only call it when sharing is the
  request (`docs/mcp.md` › Live sessions).

## Verification protocol

FigCraft is alpha; treat every automated run as untrusted until checked:

1. **Throwaway round trip per session.** Build from a starter template (`file.newFromTemplate`) or
   a copy: create → edit → `save_file`/`--out` to `.figcraft` → reopen it → export PNG/PDF. Compare
   `info` node counts before and after; a decoder that only reads what it wrote is how the repo's
   own `.fig` export is tested.
2. **Never trust a silent export.** Watch stderr: exports and imports print `note:` lines for what
   was dropped, `.fig`/REST/SVG imports return `warnings` (MCP `open_file`) and fill the Import
   report window, and a failed SVG/PDF depth check leaves the existing destination file untouched
   rather than writing a partial file. Check the exit code.
3. **Version and back up project files.** Ask for the user's document to be committed or copied
   before a batch of automated edits; the app's version history (≤100 versions), branches and
   10-second recovery copies are safety nets, not backups.
4. **Update between projects, not during one.** The launcher auto-updates the app; a format written
   by a newer version is refused by an older one, so don't interleave versions in one project.
5. **Scope credentials and sharing.** Live sessions and servers are preview features with
   code/link-based access and no accounts; don't put confidential work on a server you don't run,
   and remember the public server keeps the file until removed or 30 days unopened (`README.md` ›
   Privacy and online sharing).

## References

- `references/automation-surfaces.md` — command/MCP/control-channel/CLI detail worth loading before
  a large automated job (full tool and method tables, arguments, limits, path confinement, batch
  semantics, collab commands, server CLI).

## Sources & evidence

- Repo: https://github.com/storytold/figcraft — inspected at tag **v0.10.0**, commit
  **80f916326fb94f3a88cb24e64f396f564a0ebc06** ("Release 0.10.0", 2026-10-22). The installed app
  reports the same version and commit. Date inspected: 2026-10-23.
- Delta v0.9.0 → v0.10.0: 12 commits, 14 files, +175/−55 — `chrono` adoption for UTC/calendar
  formatting (`Cargo.toml`, `crates/collab/src/message.rs`, `crates/ui-egui/src/home_recents.rs`),
  SonarCloud CI (`sonarcloud.yml`, `sonar-project.properties`), pinned GitHub Actions, and a README
  app icon. No engine command, format, MCP, control or CLI file changed.
- Key files read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`; `crates/doc/src/`
  (`node.rs`, `props.rs`, `proto.rs`, `styles.rs`); `crates/{color,layout}/src/lib.rs`;
  `crates/format/src/{lib,library}.rs` and the `fig/`/`rest/` module trees; `crates/engine/src/{fonts,keymap,guard,file_access,live,online}.rs`
  and `cmd/{mod,file,edit,variables_io}.rs`; `crates/engine/src/templates/mod.rs`;
  `apps/figcraft-cli/src/{main,files,args}.rs`; `apps/figcraft/src/{main,args,recovery}.rs`;
  `apps/figcraft-server/src/{cli,config}.rs`; `crates/mcp/src/{tools,resources,prompts,server}.rs`;
  `crates/ui-egui/src/{control,windows,home,i18n}.rs`; `docs/{cli,mcp,control-protocol,
  file-format-parity,gaps,target-app-parity,localization-parity,hardware-parity,plugins,
  parity-checklist,ui-parity}.md`; `packaging/macos/package.sh`, `packaging/linux/AppRun`.
- Shared libraries: FigCraft depends on `craft-docpath` (rev `82a24b0…`) and `craft-window` (rev
  `1f80537…`) from `storytold/craft-libs` (`Cargo.toml`); the native format is defined in this
  repo, not in craft-libs.

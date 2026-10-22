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

# FigCraft

## Overview

FigCraft is a native, offline interface-design and prototyping app written entirely in Rust (egui/eframe
UI, tiny-skia CPU renderer, no Electron), built clean-room "from public documentation and observed
behaviour only" against Figma Design as the reference (`README.md` › Under the hood,
`docs/target-app-parity.md`). It is **alpha**: "about 49% of the way to replacing proprietary tools
for real work" by its own estimate (`README.md`), scored ~53% ready, ~85% feature breadth and ~94%
core editor in its self-graded parity tables (`ROADMAP.md`, `docs/target-app-parity.md`). It runs on
macOS, Windows, Linux, FreeBSD and in the browser via WebAssembly (`README.md`, `apps/figcraft-web`).
Source: GitHub `storytold/figcraft`, MIT OR Apache-2.0. Everything the UI can do is a **command**
(212/212 catalogued menu items, 561 registered commands — `docs/parity-checklist.md`), and the same
registry is exposed through the CLI, a JSON control channel and an MCP server, which is the main
reason an agent should load this skill.

The installed app on this Mac reports `FigCraft 0.9.0 (28de91d9ae72fc7fbc2199ac5ee2c8be237980d5)`,
the same commit as the source this skill was written from (tag `v0.9.0`, released 2026-10-21), so
the installed app matches this description exactly; verify against your installed version if the
launcher has since updated it.

## Capabilities (verified)

**Model and editing**
- Frames, groups, sections, masks, rectangles (squircle corners), ellipses with arc/ring handles,
  polygons, stars, lines, arrows, text, vector networks, boolean groups, components, component
  sets, instances, slices — the full node kind list (`crates/doc/src/node.rs` `NodeKind`; create
  list in `docs/mcp.md`, `create_node`). Duplicating a main component now yields an instance
  (`ROADMAP.md` 2026-10-20 #892, `crates/engine/src/cmd/component.rs`).
- **Auto layout**: horizontal/vertical flow, wrap and grid with fixed/`fr`/auto tracks, spanning
  cells, padding, gaps, Hug/Fill/Fixed sizing, min/max sizes, absolute children, baseline
  cross-align, `contentAlign`, strokes-in-layout, reverse z (`docs/mcp.md` › Conventions;
  `crates/layout`). A document dropped on the canvas opens as its own file (#916).
- **Vector networks** with Pen and Pencil, vector edit mode (multi-layer editing, bend, paint
  bucket, lasso, cut), shape builder, booleans that stay editable, per-point corner radius, handle
  mirroring, per-point caps/joins, variable-width strokes with a width tool, outline stroke,
  arrowheads, dashes, per-side strokes, brushes and pen pressure, text on a path, pattern fills
  (`README.md`; `crates/pathops`; `docs/mcp.md` › Editing vectors, Text on a path and pattern
  fills, Brushes and pen pressure).
- **Text** edited in place, mixed styles within a paragraph, auto width/height, variable font axes
  and named instances, OpenType features, lists, bidi/RTL, HarfRust shaping plus system fonts and
  the `craft-fonts` bundle. New in 0.9.0: the app reports **missing fonts** and can load fonts
  without installing them — `text.missingFonts`, `text.rescanFonts`, `text.loadFont {path|data}`,
  `text.refit` (`crates/engine/src/fonts.rs`, `docs/mcp.md` › Conventions; `info` lists
  `missingFonts` per file — `docs/cli.md`).
- **Paint and effects**: solid/linear/radial/angular/diamond gradients, image fills with adjustment
  presets, blend modes, inner/drop shadows, layer/background blur (uniform and progressive), noise,
  texture, glass, masks; sRGB or Display P3 documents with image colour-profile conversion
  (`README.md`; `docs/mcp.md` › Conventions).
- **Components and design systems**: mains, instances with overrides, sets and variants, properties
  (boolean/text/instance-swap/slot), swap, detach, reset, playground, local and library styles
  (paint, text, effect, grid), variables (colour/number/string/boolean) with modes, aliases, scopes
  and bindings, variables inside styles, extended collections, variables import/export as JSON or
  CSS (`docs/mcp.md`, `docs/components-parity.md`).
- **Prototyping**: triggers (click, hover, press, drag, delayed mouse, keys, gamepad), actions
  (navigate, overlay, swap, change-to, scroll-to, back, close, open link, set variable, set
  variable mode, conditionals with expressions), transitions with easing/springs, flows,
  device-frame presentation, hotspot hints, Inspect panel, live preview pane
  (`docs/prototyping-parity.md`, `docs/mcp.md`).
- **Handoff**: ready-for-dev status with Compare changes, annotations in categories, measurements,
  generated CSS, HTML, React, Leptos, SwiftUI and Compose with component properties as parameters,
  Code Connect links, dev resources (`docs/dev-mode-parity.md`, `docs/mcp.md` › Dev Mode).
- **In-file review**: comment threads (replies, @mentions, reactions, resolve), named versions,
  branches with update-from-main, review and merge (`docs/collaboration-parity.md`,
  `crates/format/src/lib.rs`).

**Formats it opens (verified in code)**
- `.figcraft` — its own format (`crates/format/src/lib.rs`).
- `.json` — FigCraft document JSON, or the Figma REST API file response (`GET /v1/files/:key`,
  nodes endpoint responses too) plus an optional local-variables JSON and `images/<imageRef>.png`
  folder beside it; REST import keeps slot layers and their content and reads grid track sizes
  (`crates/format/src/rest`, `docs/file-format-parity.md`). Every CLI subcommand that reads a file
  accepts REST JSON on the fly (`docs/cli.md`).
- `.fig` — best-effort import of Figma's own file, never saved over; large files open within
  budgets derived from the file's own size; an import report lists what changed
  (`crates/format/src/fig`, `docs/file-format-parity.md`). Layers copied in another design app
  paste from the clipboard when its HTML carries a `.fig` canvas (`edit.pasteDesignLayers`,
  refused over 256 MB — `docs/file-format-parity.md` › Import).
- `.svg` — imported as an editable frame; unsupported filters dropped with a warning
  (`crates/svg`, `docs/file-format-parity.md`).
- Images: `.png`, `.jpg`/`.jpeg`, `.gif` (animated fills play in the presenter/preview), `.webp`,
  `.bmp`, `.tif`/`.tiff`, with embedded ICC profiles honoured (`crates/engine/src/cmd/file.rs`
  extension match, `docs/file-format-parity.md` › Import).

**Formats it writes**
- `.figcraft` (native; zip of `document.json` + `images/<sha256>` + `thumbnail.png` + optional
  `versions/`, `branches/` and library entries) (`crates/format/src/lib.rs`).
- `.json` (FigCraft JSON), `.svg`, `.png`, `.jpg`, `.webp`, `.pdf` (one page per top-level frame,
  real selectable text in subset fonts, clickable links, bleed/crop/bleed marks and naive CMYK via
  `--bleed --crop-marks --bleed-marks --cmyk`) (`docs/cli.md`, `crates/pdf`).
- `.fig` — **experimental** whole-document export (`crates/format/src/fig/export.rs`); written
  files have been opened in other software, where layers, fills, gradients, strokes, shadows,
  vectors, components, text, resized/scaled instances, variables with modes and colour bindings,
  styles and symmetric variable-width strokes draw as in FigCraft; effects such as glass and noise,
  images and prototype interactions are still unchecked there; every omission is a `warning`
  (`docs/file-format-parity.md` › Export to `.fig`).
- Export settings per layer with presets (`2x`, `512w`, `512h`); slashes in layer names become
  folders (`docs/mcp.md`, `export` tool).

**Automation surfaces (the app's strongest property)**
- **`figcraft-cli`** — headless engine: `info`, `export`, `convert`, `render` (png/jpg/webp), `run`
  (JSON/JSONL command scripts, all-or-nothing, one undo step), `commands`, `mcp`, `plugin publish`,
  `perf` (`apps/figcraft-cli/src/main.rs`, `docs/cli.md`). New in 0.9.0: every file-touching
  subcommand takes `--automation-read-root`/`--automation-write-root` (`docs/cli.md` › Confining a
  run).
- **Control channel** — `figcraft --control <port>`, loopback-only, newline-delimited JSON with 17
  methods: `engine.execute`, `engine.commands`, `document.inspect`, `node.get`, `ui.inspect`,
  `ui.pointer`, `ui.key`, `ui.type`, `ui.input`, `ui.menu.invoke`, `ui.set`, `ui.screenshot`,
  `ui.render`, `window.new/list/focus`, `app.quit` (`docs/control-protocol.md`,
  `crates/ui-egui/src/control.rs`). Answered while the window is minimised except the ones that
  need a drawn frame.
- **MCP server** — `figcraft-cli mcp` (headless) or `--attach <port>` (drives the running app);
  18 tools: `list_commands`, `run_command`, `batch`, `create_node`, `set_properties`,
  `inspect_document`, `get_node`, `select`, `export`, `screenshot`, `open_file`, `save_file`,
  `undo`, `redo`, `pointer`, `key`, `type_text`, `inspect_ui`; resources `figcraft://document`,
  `figcraft://commands`, `figcraft://node/{id}`, `figcraft://command/{id}`; prompts `mobile_screen`,
  `design_system`, `landing_page`, `prototype_flow` (`crates/mcp/src/tools.rs`, `resources.rs`,
  `prompts.rs`, `docs/mcp.md`).
- **Live sessions from a script** — the headless MCP session can host, join, share with a join
  code and publish files through the `collab.*` commands (`collab.share/host/join/publish/peers/
  files/serverInfo/stop/leave/manageFile`…); the one-shot `run` cannot (no network link)
  (`docs/mcp.md` › Live sessions, `docs/cli.md`).
- **Plugins** — sandboxed WebAssembly (wasmi, metered, no filesystem/network/clock), JSON manifest
  with permissions, panels and canvas widgets; Rust SDK and three examples under `plugins/`;
  `node.set {props: {pluginData}}` writes per-layer data and (new in 0.9.0) `node.get` /
  `document.inspect` read it back (`docs/plugins.md`, `ROADMAP.md` #879, `crates/plugin`).
- **Templates** — eight starter documents built in code (`mobile-app`, `landing-page`, `dashboard`,
  `design-system`, `wireframe-kit`, `social-posts`, `slides`, `icon-set`) via `template.list` and
  `file.newFromTemplate {template}`; a `run` script can start from one (`docs/mcp.md` › Starter
  templates). Five example documents ship in `examples/`.

**Platform and runtime facts**
- WebAssembly build: **yes** (`cargo xtask wasm`, `apps/figcraft-web`); the browser build can join
  live sessions but not host, has no system fonts, and (since 0.9.0) embeds the craft-fonts build
  again so it draws text and lists fonts (#885).
- Releases package macOS universal, Windows x64/x86/arm64, Linux (AppImage/deb/rpm/Flatpak/
  tarball), FreeBSD and web (`README.md`, `packaging/`).
- Crash discipline: no `unwrap`/`expect`/`panic` in shipped code (clippy denies), commands run
  behind a guard that turns a panic into an error and rolls the document back, and recovery copies
  of unsaved documents are written every 10 s (`Cargo.toml` lints, `crates/engine/src/guard.rs`,
  `apps/figcraft/src/recovery.rs` `INTERVAL`).
- Accessibility: AccessKit names/roles on desktop, F6 cycles toolbar → layers → canvas →
  properties, reduced motion honoured; the browser has no accessibility tree (`README.md`,
  `docs/ui-parity.md`).

## Known limitations and not-implemented

Treat these as hard constraints when assigning work to FigCraft.
- **No real-Figma-file validation.** Every corpus in the repo is synthetic; `.fig` import is
  "best effort" and nothing has been checked against real-world Figma documents
  (`docs/gaps.md` gaps 1 and 3). Do not promise fidelity when importing someone's real `.fig`.
- **`.fig` export is experimental.** Whole-document only; a documented list of features is left
  out with a warning each (comments, Dev Mode data, non-colour variable bindings as values, slot
  properties, pattern fills, image adjustments, set-variable/conditional actions, text on a path,
  OpenType features, version history and branches, and more); effects, images and prototypes are
  unchecked in other software (`docs/file-format-parity.md` › Export to `.fig`).
- **Missing formats**: HEIC images and video fills/triggers are not implemented (no Rust decoder);
  `.jam` (FigJam) and `.deck` (Slides) are out of scope (`docs/file-format-parity.md`).
- **No Figma plugin compatibility.** FigCraft runs its own WASM plugins, not JavaScript Figma
  plugins. Widgets take clicks only — no text input, hover or timers
  (`docs/gaps.md` 6, `docs/target-app-parity.md`).
- **No AI features at all** and **no spell check** (`docs/gaps.md` 19, 11).
- **Multiplayer is a preview**: live sessions with sync, cursors, cursor chat, spotlight, per-person
  undo, join codes and invite links, plus a self-hosted `figcraft-server`, but **no accounts and no
  teams**, codes/links are the access, and the server stores files unencrypted (not end-to-end
  encrypted) (`README.md` › Privacy and online sharing, `docs/collaboration-parity.md`).
- **CPU canvas, sRGB screen**: rendered on the CPU; Display P3 documents show as sRGB-clipped on
  screen with a gamut warning and soft-proof striping (true P3 blocked upstream in egui-wgpu)
  (`docs/hardware-parity.md`, `docs/gaps.md` 18).
- **Export limits**: SVG and PDF refuse an export whose visible tree is deeper than 256 descendant
  levels, rather than writing an incomplete file (`docs/file-format-parity.md` › Export).
- **Print**: PDF `--cmyk` is the naive `K = 1 − max(R,G,B)` conversion, DeviceCMYK with no output
  intent — proof against your printer's profile (`docs/cli.md`, `docs/gaps.md` 23).
- **Screen readers have never been run** against the app; the browser build has no accessibility
  tree (`docs/gaps.md` 22).
- **Localization**: English, Russian and Turkish reviewed; Swedish has translated command labels;
  draft catalogs for Spanish (+Latin-American overlay), French, German, Brazilian Portuguese,
  Japanese, Korean, Simplified Chinese, Czech, Indonesian and Georgian — and five further draft
  catalogs new in 0.9.0 (Bengali, Finnish, Dutch, Polish + Georgian) that the README does not yet
  list; engine messages stay English (`README.md` › Under the hood, `crates/ui-egui/locales/`,
  `docs/localization-parity.md`).
- **Bounds worth knowing**: at most 100 versions and 100 branches per file; `document.json` is
  capped by a 16× compression-ratio rule within 512 MiB per zip member (`crates/format/src/lib.rs`
  `MAX_VERSIONS`, `MAX_BRANCHES`, `DOCUMENT_RATIO`, `MAX_MEMBER`).
- Uncertain — see `docs/gaps.md` for the ranked, self-scored list. The 561-command count is the
  latest published measure (2026-10-17); a few commands landed after it — count yours with
  `figcraft-cli commands --json`.

## How to operate

**Launch.** Installed app: `/Applications/FigCraft.app`; `open -a FigCraft [file.figcraft]` opens a
file (it declares the `figcraft` document type, SVG, PNG and JPEG types and the `figcraft://` URL
scheme; identifier `ai.storyteller.figcraft`). To pass flags, run the binary directly:

```sh
"/Applications/FigCraft.app/Contents/MacOS/FigCraft" --control 7979 file.figcraft
"/Applications/FigCraft.app/Contents/MacOS/FigCraft" --control 7979 \
    --automation-read-root WORK/project --automation-write-root WORK/project/out
```

`--control <port>` starts the loopback JSON-lines control server; `--automation-read-root` /
`--automation-write-root` (repeatable) confine every file the channel and windows may read or
write; any unknown option — including a mistyped root flag — stops the app at startup instead of
running unconfined (`apps/figcraft/src/args.rs`, `docs/control-protocol.md`). An invite link
(`figcraft://join?…`) or a `file://` URL on the command line opens or joins it.

**There is no CLI inside the macOS bundle.** The GUI app is the only binary in
`/Applications/FigCraft.app/Contents/MacOS/`. `docs/cli.md` says to build it:
`cargo build --release -p figcraft-cli` → `target/release/figcraft-cli`; macOS releases ship it as
a separate `figcraft-cli-<version>-macos-<arch>.zip` (`packaging/macos/package.sh`). On Linux only,
`FigCraft.AppImage cli <args>` runs the bundled CLI.

**CLI surface** (verified in `apps/figcraft-cli/src/main.rs`, `docs/cli.md`):

```sh
figcraft-cli info app.figcraft [--json]                # + missingFonts per file (0.9.0)
figcraft-cli export app.figcraft -o exports/ --scale 2 # one file per top-level frame
figcraft-cli export app.figcraft -o hero.svg --node "Hero"
figcraft-cli export app.figcraft -o screens.pdf --page "Screens"
figcraft-cli export app.figcraft -o poster.pdf --node "Poster" --bleed 3mm --crop-marks --cmyk
figcraft-cli export app.figcraft -o handoff.fig        # experimental .fig
figcraft-cli convert in.svg out.figcraft               # by extension
figcraft-cli render app.figcraft -o page.png --scale 2 # png, jpg or webp out
figcraft-cli run build.json --in base.figcraft --out result.figcraft
figcraft-cli commands --filter autoLayout [--json]
figcraft-cli mcp [--attach 7979] [--automation-read-root DIR]…
figcraft-cli render in/doc.figcraft -o out/ok.png \
    --automation-read-root in --automation-write-root out   # confine any subcommand (0.9.0)
```

Every subcommand takes `--no-system-fonts` (or `FIGCRAFT_NO_SYSTEM_FONTS=1`) for reproducible
renders. Exit codes: bad arguments 2, failures 1, success 0. `--scale` is capped at 64; pages
shrink to fit 16384 px on `render`.

**Document model.** One process shows several **windows**, each with its own **tabs**, panels and
canvas (`window.new`, File ▸ New window). A first run opens the **home screen** (Recents, Online,
Templates, search). Files are documents with pages; unsaved changes are tracked per tab.

**Round trip.** Open (`.figcraft` / `.json` / `.fig` / `.svg` / image) → edit (UI, CLI `run`,
control channel, MCP) → **Save** (`.figcraft`, atomic staging-file + rename in
`crates/format/src/lib.rs`) → export (PNG/JPG/SVG/PDF/WebP, or experimental `.fig`). Saving is
never in-place over an imported `.fig`; "Save as" with a `.fig` name writes an export copy and the
document keeps its `.figcraft` path.

**Keyboard shortcuts**: do not invent them. The authoritative machine-readable list is
`figcraft-cli commands --json` (each command's `shortcut`) or MCP `list_commands`, generated from
`crates/engine/src/keymap.rs` (151 binding rows in 12 groups — Essential, Tools, View, Zoom, Text,
Shape, Selection, Edit, Transform, Arrange, Components, Prototype — each with macOS keys and,
where they differ, Windows/Linux keys). The in-app Keyboard shortcuts panel shows the same table.

## Working with an AI agent

What an agent can legitimately do:

- **Drive the app headlessly.** `figcraft-cli run` a JSON array (or `.jsonl`) of
  `{"command": id, "params": {…}}`; `{"$step": n}` in a param resolves to the `id` from step `n`'s
  result, so one script can build a whole screen. Scripts are **all-or-nothing and one undo step**;
  a failed step prints `"rolledBack": true` and exits 1 having written nothing (`docs/cli.md`).
- **Drive the running app** so the user watches: start it with `--control PORT`, then
  `figcraft-cli mcp --attach PORT` (MCP tools) or speak the JSON-lines protocol directly. Attached
  calls are **never replayed** after a transport failure — inspect before retrying an edit
  (`docs/mcp.md`).
- **Confine it.** Pass `--automation-read-root` / `--automation-write-root` to the app, to
  `figcraft-cli mcp`, or (new in 0.9.0) to any `info`/`export`/`convert`/`render`/`run` invocation.
  Writes need a write root; reads need either; `--attach` plus roots is a usage error
  (`docs/mcp.md` › Confining file access, `docs/cli.md` › Confining a run).
- **Prepare inputs.** Generate or convert assets into formats FigCraft reads: SVG (best editable
  import), PNG/JPG/WebP/GIF/TIFF/BMP, PDF is **export-only**. For real Figma work the highest
  fidelity path is the REST API file JSON plus its local-variables JSON plus an
  `images/<imageRef>.png` folder — the importer reads all three (`docs/mcp.md` › Importing REST
  API file JSON).
- **Inspect and repair native files** (cautiously). A `.figcraft` is a plain zip: `unzip -p
  f.figcraft document.json` reads the whole model, `images/<sha256>` holds the raw image bytes and
  `versions/index.json` / `branches/index.json` hold history. Reading is lenient: structural
  problems are repaired on load and reported; a file written by a newer format version is refused
  outright (`FormatError::Newer`). Prefer repairing through commands (`document.inspect`,
  `node.set`, `node.get` now round-trips `pluginData`) over rewriting the JSON by hand; if you must
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
- Do not promise exact `.fig` round trips or real-Figma-file fidelity: nothing has been measured on
  real files.
- Do not treat the browser build as equivalent: it can join but not host sessions, has no system
  fonts and no accessibility tree, and keeps one window.
- Do not rely on on-screen Display P3: documents can hold P3 and exports carry the profile, but the
  canvas shows clipped sRGB with a soft-proof option (`docs/hardware-parity.md`).
- Do not share to a server uninvited: `collab.share` with `via: "online"` **publishes the document
  to a server other people run** — only call it when sharing is the request (`docs/mcp.md` › Live
  sessions).

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
  a large automated job (arguments, limits, path confinement, batch semantics, collab commands).

## Sources & evidence

- Repo: https://github.com/storytold/figcraft — inspected at tag **v0.9.0**, commit
  **28de91d9ae72fc7fbc2199ac5ee2c8be237980d5** ("Release 0.9.0", 2026-10-21). The installed app
  reports the same version and commit; its `Info.plist` may lag — trust the app's own
  `--version`/CLI report.
- Date inspected: 2026-10-22.
- Key files read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`, `crates/format/src/lib.rs`,
  `crates/format/src/fig/` (module list), `crates/format/src/rest/` (module list),
  `crates/doc/src/props.rs` (`ExportFormat::from_ext`), `crates/engine/src/cmd/file.rs`,
  `crates/engine/src/fonts.rs`, `crates/engine/src/keymap.rs`, `crates/engine/src/catalog.rs`,
  `apps/figcraft-cli/src/main.rs`, `apps/figcraft-cli/src/args.rs`, `apps/figcraft/src/args.rs`,
  `apps/figcraft/src/recovery.rs`, `apps/figcraft-server/src/cli.rs`, `crates/mcp/src/tools.rs`,
  `crates/mcp/src/resources.rs`, `crates/mcp/src/prompts.rs`, `docs/cli.md`, `docs/mcp.md`,
  `docs/control-protocol.md`, `docs/file-format-parity.md`, `docs/gaps.md`,
  `docs/target-app-parity.md`, `docs/localization-parity.md`, `docs/hardware-parity.md`,
  `docs/plugins.md`, `docs/parity-checklist.md`, `packaging/macos/package.sh`, plus the full diff
  from the previous release tag to v0.9.0 (206 files) to separate new claims from carried-over
  ones.
- Shared libraries: FigCraft depends on `craft-docpath` (rev `82a24b0…`) and — new in 0.9.0 —
  `craft-window` (rev `1f80537…`) from `storytold/craft-libs` (`Cargo.toml`); the native format
  itself is defined in this repo, not in craft-libs.

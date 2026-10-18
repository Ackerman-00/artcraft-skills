---
name: figcraft
description: >
  FigCraft is an open-source, pure-Rust, offline interface-design app (a clean-room reimplementation
  of the Figma design workflow): frames, auto layout, components and variants, styles and variables,
  vector networks, prototyping, comments, versions and Dev Mode, on macOS, Windows, Linux, FreeBSD
  and the web. Trigger this skill whenever the user mentions FigCraft or a `.figcraft` file, asks
  what FigCraft can or cannot do, which formats it opens or writes, how to script, automate, batch or
  headlessly drive it (figcraft-cli, MCP, the JSON control channel), wants assets prepared for a
  design file, needs its output verified or repaired, or asks to troubleshoot it — and also when the
  app is not named but the job is one of its jobs: "make a mockup", "design a screen / landing page /
  dashboard", "build a design system", "export these frames to PNG/PDF/SVG", "open this .fig or Figma
  file JSON", "prototype this flow", "hand this off to a developer". Prefer this skill over generic
  design-file advice for anything FigCraft touches; do not guess capabilities from Figma knowledge —
  FigCraft is not Figma and does not run Figma plugins.
---

# FigCraft

## Overview

FigCraft is a native, offline interface-design app written entirely in Rust (egui/eframe UI, tiny-skia
CPU renderer, no Electron) and developed as a **clean-room reimplementation of the Figma Design
workflow** — not a copy and not affiliated with Figma (`README.md`). It is at **alpha**: the repo says
"about 49% of the way to replacing Figma for real work" (`README.md`) and its own parity doc scores
"ready for real work" at **~53%** with feature breadth ~85% (`ROADMAP.md`, `docs/target-app-parity.md`).
It runs on macOS, Windows, Linux, FreeBSD and in the browser via WebAssembly (`README.md`,
`apps/figcraft-web`). Source: GitHub `storytold/figcraft`, MIT OR Apache-2.0. Everything the UI can do
is a **command**, and the same command registry is exposed through the CLI, a JSON control channel and
an MCP server — so the app is unusually automatable for a design tool, which is the main reason to load
this skill.

The installed app on this Mac is `/Applications/FigCraft.app`, version **0.7.0**, identifier
`ai.storyteller.figcraft`, and its `Info.plist` records build commit `47438dd4…` — the same commit as
the checkout this skill was written from (`git rev-parse HEAD` = tag `v0.7.0`). So the installed app
matches the source described here exactly; verify against your installed version if the launcher has
since updated it.

## Capabilities (verified)

**Model and editing**
- Frames, groups, sections, masks, rectangles, ellipses, polygons, stars, lines, arrows, text, vector
  networks, boolean groups, components, component sets, instances, slices — the full node kind list
  (`crates/doc/src/node.rs` `NodeKind`; create list in `docs/mcp.md`, `create_node`).
- **Auto layout**: horizontal/vertical flow, wrap and grid with fixed/`fr`/auto tracks, cells that
  span, padding, gaps, Hug/Fill/Fixed sizing, min/max sizes, absolute children, baseline cross-align,
  `contentAlign`, strokes-in-layout, reverse z (`docs/mcp.md` › Conventions; `crates/layout`).
- **Vector networks** with the Pen and Pencil tools, vector edit mode, boolean groups whose operands
  stay editable, shape builder, per-point corner radius and handle mirroring, variable-width strokes,
  outline stroke, arrowheads, dashes, per-side strokes (`README.md`; `crates/pathops`).
- **Text** edited in place, mixed styles within a paragraph, auto width/height, variable font axes and
  named instances, OpenType features, per-paragraph lists, bidi/RTL, shaping through HarfRust plus
  system fonts and the optional `craft-fonts` bundle (`CRAFT_FONTS_DIR` build input; `crates/text`).
- **Paint and effects**: solid/linear/radial/angular/diamond gradients, image fills with adjustments
  and presets, blend modes, inner/drop shadows, layer/background blur (uniform and progressive),
  noise, texture, glass, masks; sRGB or Display P3 documents with image colour-profile conversion
  (`README.md`; `docs/mcp.md` › Conventions; `docs/file-format-parity.md`).
- **Components and design systems**: mains, instances with overrides, component sets and variants,
  properties (boolean/text/instance-swap/slot), swap, detach, reset, component playground, local and
  library styles (paint, text, effect, grid), variables (colour/number/string/boolean) with modes,
  aliases, scopes and bindings, variables inside styles, extended collections, variables
  import/export as JSON or CSS custom properties (`docs/mcp.md`, `docs/components-parity.md`).
- **Prototyping**: interactions (click, hover, press, drag, delayed mouse triggers, keys, gamepad),
  actions (navigate, overlay with offsets, swap, change-to, scroll-to, back, close, open link, set
  variable, set variable mode, conditionals with expressions), Smart-Animate-style transitions with
  easing/springs, flows, presentation with device frames, hotspot hints, Inspect panel and a live
  preview pane (`docs/prototyping-parity.md`, `docs/mcp.md`).
- **Handoff**: Dev Mode status (ready-for-dev, changed-since), annotations in categories, Compare
  changes, measurements, generated code in CSS, HTML, React, Leptos, SwiftUI and Compose with
  component properties as parameters, Code Connect links (`docs/dev-mode-parity.md`, `docs/mcp.md`).
- **Review inside a file**: comment threads with replies, @mentions, reactions and resolve; named
  version history; branches with update-from-main, review and merge (`docs/collaboration-parity.md`,
  `crates/format/src/lib.rs`).

**Formats it opens (verified in code)**
- `.figcraft` — its own format (`crates/format/src/lib.rs`).
- `.json` — FigCraft document JSON **or** the Figma public REST API file response (`GET /v1/files/:key`),
  plus a local-variables JSON and an `images/<imageRef>.png` folder beside it (`crates/format/src/rest`).
- `.fig` — best-effort import of Figma's own file (`crates/format/src/fig`); never saved over.
- `.svg` — imported as an editable frame (groups, shapes, text, gradients, masks, effects; unsupported
  filters dropped with a warning) (`crates/svg`, `docs/file-format-parity.md`).
- Images: `.png`, `.jpg`/`.jpeg`, `.gif` (animated fills play in the presenter/preview), `.webp`,
  `.bmp`, `.tif`/`.tiff` (`crates/engine/src/cmd/file.rs`, `docs/file-format-parity.md`).

**Formats it writes**
- `.figcraft` (native; zip of `document.json` + `images/<sha256>` + `thumbnail.png` + optional
  `versions/`, `branches/` and library entries) (`crates/format/src/lib.rs`).
- `.json` (FigCraft JSON), `.svg`, `.png`, `.jpg`, `.webp`, `.pdf` (one PDF page per top-level frame,
  real selectable text in subset fonts, vector shapes/gradients, bleed/crop/bleed marks and naive CMYK
  via `--bleed --crop-marks --bleed-marks --cmyk`) (`docs/cli.md`, `crates/pdf`).
- `.fig` — **experimental** export of the whole document (`crates/format/src/fig/export.rs`); round
  trips through FigCraft's own importer, and written files were opened in other software for layers,
  fills, gradients, strokes, shadows, vectors, components and text; effects, images and prototype
  interactions are unchecked there (`docs/file-format-parity.md`).
- Export settings per layer with presets (`2x`, `512w`, `512h`), slashes in layer names become folders
  (`docs/mcp.md`, `export` tool).

**Automation surfaces (this is the app's strongest property)**
- **`figcraft-cli`** — headless engine: `info`, `export`, `convert`, `render`, `run` (JSON/JSONL
  command scripts, all-or-nothing, one undo step), `commands`, `mcp`, `plugin publish`, `perf`
  (`apps/figcraft-cli/src/main.rs`, `docs/cli.md`).
- **Control channel** — `figcraft --control <port>`, loopback-only, newline-delimited JSON with
  methods `engine.execute`, `engine.commands`, `document.inspect`, `node.get`, `ui.inspect`,
  `ui.pointer`, `ui.key`, `ui.type`, `ui.input`, `ui.menu.invoke`, `ui.set`, `ui.screenshot`,
  `ui.render`, `window.new/list/focus`, `app.quit` (`docs/control-protocol.md`,
  `crates/ui-egui/src/control.rs`).
- **MCP server** — `figcraft-cli mcp` (headless) or `figcraft-cli mcp --attach <port>` (drives the
  running app); 18 tools: `list_commands`, `run_command`, `batch`, `create_node`, `set_properties`,
  `inspect_document`, `get_node`, `select`, `export`, `screenshot`, `open_file`, `save_file`, `undo`,
  `redo`, `pointer`, `key`, `type_text`, `inspect_ui`; resources `figcraft://document`,
  `figcraft://commands`, `figcraft://node/{id}`, `figcraft://command/{id}`; prompts `mobile_screen`,
  `design_system`, `landing_page`, `prototype_flow` (`crates/mcp/src/tools.rs`, `docs/mcp.md`).
- **Plugins** — sandboxed WebAssembly (wasmi interpreter, metered, no filesystem/network/clock) with a
  JSON manifest, permissions, panels and canvas widgets; Rust SDK and three examples under
  `plugins/` (`docs/plugins.md`).
- **Templates** — eight starter documents built in code (`mobile-app`, `landing-page`, `dashboard`,
  `design-system`, `wireframe-kit`, `social-posts`, `slides`, `icon-set`) via
  `file.newFromTemplate {template}` (`docs/mcp.md` › Starter templates).

**Platform and runtime facts**
- WebAssembly build: **yes** (`cargo xtask wasm`, `apps/figcraft-web`, `[profile.web-release]` in
  `Cargo.toml`); the browser build joins live sessions and has no system fonts.
- Five platform targets packaged in releases: macOS universal, Windows x64/x86/arm64, Linux
  (AppImage/deb/rpm/Flatpak/tarball), FreeBSD, web (`README.md`, `packaging/`).
- Crash discipline: no `unwrap`/`expect`/`panic` in shipped code (clippy denies), commands run behind
  a guard that turns a panic into an error and rolls the document back, and recovery copies of unsaved
  documents are written every 10 s to the config folder (`Cargo.toml` lints, `crates/engine/src/guard.rs`,
  `apps/figcraft/src/recovery.rs` `INTERVAL`).
- Accessibility: AccessKit names/roles on desktop, F6 cycles toolbar → layers → canvas → properties,
  reduced motion honoured; the browser has no accessibility tree (`README.md`, `docs/hardware-parity.md`).

## Known limitations and not-implemented

Treat these as hard constraints when assigning work to FigCraft.
- **No real-Figma-file validation.** Every corpus in the repo is synthetic; `.fig` import is
  "best effort" and nothing has been checked against real-world Figma documents
  (`docs/gaps.md` gaps 1 and 3). Do not promise fidelity when importing someone's real `.fig`.
- **`.fig` export is experimental** and leaves out a documented list (comments, Dev Mode data,
  variable publishing/code syntax, plugin data, ruler guides, slot properties, pattern fills, image
  adjustments, set-variable/conditional actions, text on a path, OpenType features, version history and
  branches, and more) — each omission is a `warning`, never silent (`docs/file-format-parity.md`).
- **Missing formats**: HEIC images and video fills/triggers are not implemented (no Rust decoder);
  `.jam` (FigJam) and `.deck` (Slides) are out of scope (`docs/file-format-parity.md`).
- **No Figma plugin compatibility.** FigCraft runs its own WASM plugins, not JavaScript Figma plugins.
  Widgets take clicks only — no text input, hover or timers — and draw frames, text, shapes and images
  only (`docs/target-app-parity.md` area 18).
- **No AI features at all** (scored 0%): no first draft, rename layers, image edit or background
  removal (`docs/target-app-parity.md` area 21, `docs/gaps.md` 19).
- **No spell check** (`docs/gaps.md` 11).
- **Multiplayer is a preview**: live sessions with sync, cursors, cursor chat, spotlight, per-person
  undo and invite links exist, plus a self-hosted `figcraft-server`, but there are **no accounts and no
  teams**, links are the access, and the server stores files unencrypted (not end-to-end encrypted)
  (`README.md` › Privacy, `docs/collaboration-parity.md`).
- **CPU canvas, sRGB screen**: rendered on the CPU; Display P3 documents show as sRGB clipped on
  screen with a gamut warning and soft-proof stripes (true P3 is blocked upstream in egui-wgpu)
  (`docs/hardware-parity.md`).
- **Export limits**: SVG and PDF refuse an export whose visible tree is deeper than 256 descendant
  levels, rather than writing an incomplete file (`docs/file-format-parity.md` › Export).
- **Print**: PDF has no CMYK output intent — `--cmyk` is the naive `K = 1 − max(R,G,B)` formula
  (`docs/cli.md`).
- **Screen readers have never been run** against the app; the browser build has no accessibility tree
  (`docs/gaps.md` 22).
- **Localization**: English (plus reviewed Russian, Turkish, Swedish) and machine drafts of es/fr/de/
  pt-BR/ja/ko/zh-Hans/id/cs that no native speaker has reviewed; engine messages stay English
  (`ROADMAP.md` › Languages).
- **Bounds worth knowing**: at most 100 versions and 100 branches per file; document.json is capped by
  a 16× compression-ratio rule within 512 MiB per member (lower on 32-bit/wasm)
  (`crates/format/src/lib.rs`).
- Uncertain — see `docs/gaps.md` for the ranked, self-scored list and `docs/parity-checklist.md` for
  the measured menu coverage (212/212 items, 561 commands registered).

## How to operate

**Launch.** Installed app: `/Applications/FigCraft.app`; `open -a FigCraft [file.figcraft]` opens a file
(it declares `ai.storyteller.figcraft.document`, SVG, PNG and JPEG types and the `figcraft://` URL
scheme in `Contents/Info.plist`). To pass flags, run the binary directly:

```sh
"/Applications/FigCraft.app/Contents/MacOS/FigCraft" --control 7979 file.figcraft
/Applications/FigCraft.app/Contents/MacOS/FigCraft --control 7979 \
    --automation-read-root /work/project --automation-write-root /work/project/out
```

`--control <port>` starts the loopback JSON-lines control server; `--automation-read-root` /
`--automation-write-root` (repeatable) confine every file the channel and the windows may read or
write (`apps/figcraft/src/args.rs`, `docs/control-protocol.md`). An invite link
(`figcraft://join?…`) on the command line joins that live session.

**There is no CLI inside the macOS bundle.** The GUI app is the only binary in
`/Applications/FigCraft.app/Contents/MacOS/`. `docs/cli.md` tells you to build it:
`cargo build --release -p figcraft-cli` → `target/release/figcraft-cli`; macOS releases ship it as a
separate `figcraft-cli-<version>-macos-<arch>.zip` (`packaging/macos/package.sh`). On Linux only,
`FigCraft.AppImage cli <args>` runs the bundled CLI.

**CLI surface** (verified in `apps/figcraft-cli/src/main.rs`, `docs/cli.md`):

```sh
figcraft-cli info app.figcraft [--json]
figcraft-cli export app.figcraft -o exports/ --scale 2          # one file per top-level frame
figcraft-cli export app.figcraft -o hero.svg --node "Hero"
figcraft-cli export app.figcraft -o screens.pdf --page "Screens"
figcraft-cli export app.figcraft -o poster.pdf --node "Poster" --bleed 3mm --crop-marks --cmyk
figcraft-cli export app.figcraft -o handoff.fig                 # experimental .fig
figcraft-cli convert in.svg out.figcraft                        # by extension
figcraft-cli render app.figcraft -o page.png --scale 2
figcraft-cli run build.json --in base.figcraft --out result.figcraft
figcraft-cli commands --filter autoLayout [--json]
figcraft-cli mcp [--attach 7979] [--automation-read-root DIR]…
```

Every subcommand takes `--no-system-fonts` (or `FIGCRAFT_NO_SYSTEM_FONTS=1`) for reproducible renders.
Exit codes: bad arguments 2, failures 1, success 0. `--scale` is capped at 64 and pages shrink to fit
16384 px on `render`.

**Document model.** One process shows several **windows**, each with its own **tabs**, panels and
canvas (`window.new`, File ▸ New window, a tab dragged off the strip). A first run opens the **home
screen**, which switches between Recents, Online and Templates. The presenter plays prototypes inside
its window. Files are documents with pages; unsaved changes are tracked per tab.

**Round trip.** Open (`.figcraft` / `.json` / `.fig` / `.svg` / image) → edit (UI, CLI `run`, control
channel, MCP) → **Save** (`.figcraft`, atomic staging-file + rename in `crates/format/src/lib.rs`) →
export (PNG/JPG/SVG/PDF/WebP, or experimental `.fig`). Saving is never in-place over an imported `.fig`;
"Save as" with a `.fig` name writes an export copy and the document keeps its `.figcraft` path.

**Keyboard shortcuts**: do not invent them. The authoritative machine-readable list is
`figcraft-cli commands --json` (each command's `shortcut`) or MCP `list_commands`, generated from
`crates/engine/src/keymap.rs` (129 documented bindings: 126 bound, 1 moved off a documented conflict,
2 missing — plus 48 bindings the documentation is silent on; Mac and Windows/Linux keys differ and are
kept in the same table). The in-app Keyboard shortcuts panel shows the same table grouped by Essential/Tools/View/Zoom/Text/Shape/
Selection/Edit/Transform/Arrange/Components.

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
- **Confine it.** Pass `--automation-read-root` / `--automation-write-root` so a runaway agent cannot
  touch the rest of the disk. Writes need a write root; reads need either. Paths are real-path resolved,
  and the app's own folders (preferences, recovery copies, installed plugins) are out of scope
  (`docs/mcp.md` › Confining file access).
- **Prepare inputs.** Generate or convert assets into formats FigCraft reads: SVG (best editable
  import), PNG/JPG/WebP/GIF/TIFF/BMP, PDF is **export-only**, and for real Figma work the highest
  fidelity path is the REST API file JSON plus its local-variables JSON plus an `images/<imageRef>.png`
  folder — the importer reads all three (`docs/mcp.md` › Importing REST API file JSON).
- **Inspect and repair native files** (cautiously). A `.figcraft` is a plain zip: `unzip -p f.figcraft
  document.json | jq '.pages'` reads the whole model, `images/<sha256>` holds the raw image bytes and
  `versions/index.json` / `branches/index.json` hold history. Reading is lenient: structural problems
  are repaired on load and reported; a file written by a newer format version is refused outright
  (`FormatError::Newer`). Prefer repairing through commands (`document.inspect`, `node.set`) over
  rewriting the JSON by hand; if you must hand-edit, keep `format`/`version` and re-zip the *entire*
  member set.
- **Verify output.** `figcraft-cli info <file> --json` for structure and `notes`; re-open an export
  (`convert` back to `.figcraft`) to prove it decodes; compare a PNG export at a known `--scale`
  against the canvas screenshot; for `.fig` output, re-open it with FigCraft and read the `warnings`
  list.
- **Contribute safely**: FigCraft forbids third-party product iconography or images — never add or
  redraw Figma/Adobe assets, and every asset needs a row in `ATTRIBUTION.md` (`AGENTS.md`).

What an agent must **not** do:

- Do not automate the GUI by clicking blind: use the control channel (`ui.pointer`, `ui.key`,
  `ui.input`, `ui.menu.invoke`, `ui.set`) or the commands; programmatic calls never open dialogs.
  `ui.screenshot` and `ui.input` need a visible window — a minimised window answers state methods but
  refuses those (`docs/control-protocol.md`).
- Do not assume a Figma format or feature works. No video fills, no HEIC, no `.jam`/`.deck`, no Figma
  plugins, no AI features; `.fig` is best-effort in and experimental out.
- Do not promise exact `.fig` round trips or real-Figma-file fidelity: nothing has been measured on
  real files.
- Do not treat the browser build as equivalent: one window, no system fonts, no accessibility tree.
- Do not rely on on-screen Display P3; documents can hold P3 and exports carry the profile, the canvas
  shows clipped sRGB with a soft-proof option (`docs/hardware-parity.md`).

## Verification protocol

FigCraft is alpha; treat every automated run as untrusted until checked:

1. **Throwaway round trip per session.** Build from a starter template (`file.newFromTemplate`) or a
   copy: create → edit → `save_file`/`--out` to `.figcraft` → reopen it → export PNG/PDF. Compare
   `info` node counts before and after; a decoder that only reads what it wrote is how the repo's own
   `.fig` export is tested.
2. **Never trust a silent export.** Watch stderr: exports and imports print `note:` lines for what was
   dropped, `.fig`/REST/SVG imports return `warnings`, and a failed SVG/PDF depth check leaves the
   existing destination file untouched rather than writing a partial file. Check the exit code.
3. **Version and back up project files.** Ask the user's document to be committed or copied before a
   batch of automated edits; the app's own version history (≤100 versions), branches and 10-second
   recovery copies are safety nets, not backups.
4. **Update between projects, not during one.** The launcher auto-updates the app; a format written by
   a newer version is refused by an older one, so don't interleave versions in one project.
5. **Scope credentials.** Live sessions and servers are preview features with link-based access and no
   accounts; don't put confidential work on a server you don't run, and remember the public server
   keeps the file until removed or 30 days unopened (`README.md` › Privacy).

## References

- `references/automation-surfaces.md` — command/MCP/control-channel/CLI detail worth loading before a
  large automated job (arguments, limits, path confinement, batch semantics).

## Sources & evidence

- Repo: https://github.com/storytold/figcraft — inspected at tag **v0.7.0**, commit
  **47438dd4a2e8b49a7e6bb3dfd480262dadc37f12** (2026-10-17), which is also the
  `FigCraftBuildCommit` in `/Applications/FigCraft.app/Contents/Info.plist` (version 0.7.0).
- Date written: 2026-10-18.
- Key files read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`, `crates/format/src/lib.rs`,
  `crates/format/src/fig/` (module list), `crates/format/src/rest/` (module list),
  `crates/doc/src/props.rs` (`ExportFormat::from_ext`), `crates/engine/src/cmd/file.rs`,
  `crates/engine/src/catalog.rs`, `crates/engine/src/keymap.rs`, `apps/figcraft-cli/src/main.rs`,
  `apps/figcraft-cli/src/args.rs`, `apps/figcraft-cli/src/files.rs`, `apps/figcraft/src/args.rs`,
  `apps/figcraft/src/main.rs`, `apps/figcraft/src/recovery.rs`, `apps/figcraft-server/src/cli.rs`,
  `crates/mcp/src/tools.rs`, `crates/mcp/src/resources.rs`, `crates/mcp/src/prompts.rs`,
  `docs/cli.md`, `docs/mcp.md`, `docs/control-protocol.md`, `docs/file-format-parity.md`,
  `docs/gaps.md`, `docs/target-app-parity.md`, `docs/roadmap.md`, `docs/architecture.md`,
  `docs/hardware-parity.md`, `docs/plugins.md`, `docs/parity-checklist.md`, `packaging/macos/package.sh`.
- Shared libraries: FigCraft depends on `craft-docpath` from `storytold/craft-libs`
  (`Cargo.toml`, pinned rev `82a24b0…`); the native format itself is defined in this repo, not in
  craft-libs.

# FigCraft skill — evidence table

Repo: https://github.com/storytold/figcraft · inspected commit
`80f916326fb94f3a88cb24e64f396f564a0ebc06` (tag `v0.10.0`, "Release 0.10.0", 2026-10-22) ·
inspected 2026-10-23. The installed `/Applications/FigCraft.app` reports version `0.10.0` and its
binary prints `FigCraft 0.10.0 (80f916326fb94f3a88cb24e64f396f564a0ebc06)`, so bundle and source
match exactly.

The v0.9.0 → v0.10.0 delta is 12 commits, 14 files, +175/−55: `chrono` adoption for UTC/calendar
formatting (with output-preserving tests), SonarCloud CI, pinned GitHub Actions and a README icon.
No engine command, MCP tool, control method, CLI flag or format file changed. Every carried-forward
claim below was re-checked against this tag; claims that could not be re-verified are listed under
"Uncertainties".

Status legend: **implemented** = code path exists and is wired into UI/CLI; **partial** = exists
but visibly incomplete or unverified outside the repo; **claimed** = asserted in docs/README but
not confirmed in code by this review.

| # | Claim | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Source is tag v0.10.0, commit `80f9163…`; installed bundle reports the same version and build SHA | `git rev-parse HEAD`, `git describe --tags`; `/Applications/FigCraft.app/Contents/Info.plist` `CFBundleShortVersionString`; `apps/figcraft/src/main.rs` `--version`; binary output `FigCraft 0.10.0 (80f9163…)` | implemented/verified |
| 2 | 569 commands registered across 57 id prefixes; 212/212 catalogued menu items; published checklist still says 561 (2026-10-17) | `crates/engine/src/cmd/mod.rs` (`all_commands`, module list), `crates/engine/src/cmd/*` + area modules (`spec!`), `docs/parity-checklist.md`; static count of unique `spec!` ids = 569 | implemented (count static; docs measure 8 behind) |
| 3 | MCP server: 18 tools, 2 resources + 2 templates, 4 prompts; headless or `--attach`; protocol 2025-06-18 (older accepted) | `crates/mcp/src/tools.rs` (`TOOL_NAMES`), `resources.rs`, `prompts.rs`, `server.rs` (`PROTOCOL_VERSION`, `SUPPORTED_VERSIONS`), `docs/mcp.md` | implemented |
| 4 | Control channel: 17 methods, loopback JSON-lines, 32 MiB lines, 8 connections, 8-request queues, 60 s timeouts; state methods work minimised, drawn-frame methods fail fast | `crates/ui-egui/src/control.rs` (method match + `NEEDS_FRAME`), `apps/figcraft/src/control_server.rs`, `docs/control-protocol.md` | implemented |
| 5 | `figcraft-cli` has 9 subcommands: info/export/convert/render/run/commands/mcp/plugin publish/perf; `--no-system-fonts`; exit 2/1/0; `--scale` ≤64; render ≤16384 px | `apps/figcraft-cli/src/main.rs` (`USAGE`, dispatch), `apps/figcraft-cli/src/args.rs` (`scale`, `print`), `apps/figcraft-cli/src/files.rs` (`render_page`), `docs/cli.md` | implemented |
| 6 | Shortcuts: 151 default bindings in 12 groups in one keymap; 129 documented shortcut rows tracked separately | `crates/engine/src/keymap.rs` (`KEYS`, `Group::ALL`), `docs/ui-parity.md` | implemented (measured) |
| 7 | `.figcraft` is a zip of `document.json` v1 + `images/<sha256>` + optional thumbnail/versions/branches/library; bare JSON opens; atomic write; newer format refused; ≤100 versions/branches; 512 MiB member, 16× ratio | `crates/format/src/lib.rs` (`EXTENSION`, `VERSION`, `MAX_VERSIONS`, `MAX_BRANCHES`, `DOCUMENT_RATIO`, `MAX_MEMBER`, `write_file_atomic`, `FormatError::Newer`), `crates/format/src/library.rs` | implemented |
| 8 | Opens `.figcraft`, `.json` (FigCraft or REST), `.fig` (best effort), `.svg`, and png/jpg/jpeg/gif/webp/bmp/tif/tiff images; PDF is export-only | `crates/engine/src/cmd/file.rs` (load extension match, SVG/REST/fig paths), `crates/format/src/rest`, `crates/format/src/fig`, `docs/file-format-parity.md` | implemented for the listed set |
| 9 | Writes `.figcraft`, `.svg`, `.png`, `.jpg/.jpeg`, `.webp`, `.pdf`, experimental `.fig`; `.json` only through CLI `convert`/`run --out`, not app Save | `crates/doc/src/props.rs` (`ExportFormat::from_ext`), `apps/figcraft-cli/src/files.rs` (`write_doc`), `crates/engine/src/cmd/file.rs` (`save_to`), `docs/cli.md` | implemented |
| 10 | `.fig` import is best effort, never saved over, budgets from file size, import report/warnings; real-world files untested | `crates/format/src/fig/`, `crates/engine/src/cmd/file.rs` (`load_fig`), `docs/file-format-parity.md` › Documents/Import, `docs/gaps.md` 1 and 3 | partial — synthetic fixtures only |
| 11 | `.fig` export is experimental whole-document; checked in other software for layers/paints/strokes/shadows/vectors/components/text/instances/variables-with-modes/styles/variable-width strokes; effects/images/prototypes unchecked; omissions are warnings | `crates/format/src/fig/export.rs`, `crates/engine/src/fig_export_tests.rs`, `docs/file-format-parity.md` › Export to `.fig` | partial |
| 12 | REST API file JSON import reads pages, layers, components, variables, prototypes, slots and grid tracks, plus local variables and an images folder; SVG imports as an editable frame and drops unsupported filters with warnings | `crates/format/src/rest/`, `crates/svg`, `crates/engine/src/cmd/file.rs`, `docs/file-format-parity.md` | implemented (unit-tested on synthetic files) |
| 13 | Auto layout supports flow/wrap/grid, fixed/hug/fr tracks, spans, padding/gaps, Hug/Fill/Fixed, min/max, absolute children, baseline; vector edit mode, booleans, shape builder, brushes and text on a path exist | `crates/layout/src/lib.rs`, `crates/engine/src/vectoredit.rs`, `crates/pathops`, `crates/engine/src/shapebuilder.rs`, `docs/auto-layout-parity.md`, `docs/mcp.md` | implemented |
| 14 | Components: mains/instances/overrides, sets/variants, boolean/text/instance-swap/slot properties, swap/detach/reset/restore; variables colour/number/string/boolean with modes, aliases, scopes, bindings; styles paint/text/effect/grid; JSON/CSS variable export | `crates/doc/src/node.rs` (`PropDef`), `crates/doc/src/styles.rs`, `crates/engine/src/cmd/component.rs`, `crates/engine/src/cmd/variables_io.rs`, `docs/components-parity.md` | implemented (playground partial) |
| 15 | Prototyping: 10 triggers (no media), 11 actions (no media), all 8 transitions, 13 easings, flows, presentation, overlays, conditionals; controller buttons missing on macOS/Linux/FreeBSD | `crates/doc/src/proto.rs` (`Trigger`, `Action`, `Easing`), `docs/prototyping-parity.md` | implemented with documented tail |
| 16 | Dev Mode: ready-for-dev + Changed + Compare, annotations, measurements, CSS/HTML/React/Leptos/SwiftUI/Compose, Code Connect, dev resources | `crates/engine/src/codegen.rs`, `crates/engine/src/devinspect.rs`, `crates/engine/src/dev_resources.rs`, `crates/engine/src/code_connect.rs`, `docs/dev-mode-parity.md` | implemented (import lines missing) |
| 17 | Live sessions: 21 `collab.*` commands; host/join/share/publish, per-person undo, cursors, text carets, cursor chat, spotlight, remove person; headless can host/join/publish, `run` cannot; server stores files unencrypted, no accounts | `crates/engine/src/live.rs`, `crates/engine/src/online.rs`, `crates/engine/src/collab.rs`, `docs/mcp.md` › Live sessions, `docs/collaboration-parity.md`, `README.md` › Privacy and online sharing | implemented (preview) |
| 18 | Plugins are sandboxed wasmi modules (fuel, 64 MB cap, no fs/net/clock), manifest permissions, panels and widgets; 3 examples; pluginData round-trips | `crates/plugin`, `plugins/sdk`, `plugins/examples/`, `docs/plugins.md`, `crates/engine/src/plugins.rs` | implemented; widgets click-only |
| 19 | 8 built-in templates and 5 example documents; WebAssembly build exists; browser joins but cannot host, one window, no system fonts/a11y tree | `crates/engine/src/templates/mod.rs` (`TEMPLATES`, test asserts 8), `examples/`, `apps/figcraft-web`, `docs/mcp.md`, `docs/control-protocol.md`, `docs/hardware-parity.md` | implemented |
| 20 | Crash discipline (no unwrap/expect/panic in shipped code, command guard rollback, 10 s recovery copies); 19 locale catalogs but review status contradictory; 100 versions/branches and 512 MiB/16× limits | `Cargo.toml` lints, `crates/engine/src/guard.rs`, `apps/figcraft/src/recovery.rs` (`INTERVAL = 10.0`), `crates/ui-egui/locales/`, `crates/format/src/lib.rs`; `README.md`, `docs/gaps.md` 5 | implemented; localization review claimed |

## Uncertainties this review could not resolve from the repo

- **Exact live command count.** A static count of unique `spec!` ids gives 569, and every `specs()`
  module is collected by `all_commands()`. The generated checklist still says 561 (measured
  2026-10-17), eight behind, and no command files changed in the v0.9.0 → v0.10.0 delta. The
  authoritative number is whatever `figcraft-cli commands --json` prints on the build; the skill
  states both and tells the reader to count.
- **`crates/tools` is a dangling workspace dependency.** `Cargo.toml` declares
  `figcraft-tools = { path = "crates/tools" }`, but no `crates/tools` directory exists in the tree.
  Nothing appears to inherit it, so the workspace can still build; it is not a capability.
- **Localization review status conflicts.** `README.md` says English, Russian and Turkish were
  reviewed by native speakers; `docs/gaps.md` calls only Russian reviewed and lists Turkish and
  Swedish as catalogs. The tree has 19 locale files, six more than the README lists. Treat the
  review badge as a claim.
- **`.fig` fidelity remains unmeasured on real files.** All corpora are synthetic; export has been
  opened in other software for a documented subset, but effects, images and prototypes are
  unchecked there (`docs/gaps.md` 1 and 3).
- **Screen readers have never been run** against the app; the browser build has no accessibility
  tree (`docs/gaps.md` 22).
- **Platform QA is incomplete**: Linux and browser passes are still open (`docs/gaps.md` 8); the
  Windows pass is documented (2026-10-11).
- **No build or runtime test was performed for this skill.** The repo was treated read-only, the GUI
  was not launched, and no `cargo` command was run; all counts are static or from the checked-in
  docs. The installed binary was invoked only with `--version`.

# FigCraft skill — evidence table

Repo: https://github.com/storytold/figcraft · inspected commit `47438dd4a2e8b49a7e6bb3dfd480262dadc37f12`
(tag `v0.7.0`, 2026-10-17) · written 2026-10-18. Installed app `/Applications/FigCraft.app` version
0.7.0 with `FigCraftBuildCommit` = the same SHA, so app and source match.

Status legend: **implemented** = code path exists and is wired into UI/CLI; **partial** = exists but
visibly incomplete or unverified outside the repo; **claimed** = asserted in docs/README but not
confirmed in code by this review.

| # | Claim | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Every user-visible behaviour is a command, dispatched identically by menus, shortcuts, CLI, control channel, MCP and plugins | `crates/engine/src/cmd/*` (`spec!`), `docs/architecture.md` › Commands: one path for every surface | implemented |
| 2 | 212/212 catalogued menu items have a command; 561 commands registered | `docs/parity-checklist.md`, `crates/engine/src/catalog.rs` | implemented (measured) |
| 3 | MCP server with 18 tools, 4 resources, 4 prompts; headless or attached to the running app | `crates/mcp/src/tools.rs` (`TOOL_NAMES`), `crates/mcp/src/resources.rs`, `crates/mcp/src/prompts.rs`, `docs/mcp.md` | implemented |
| 4 | Control channel `figcraft --control PORT`, loopback JSON-lines, state methods work while minimised | `apps/figcraft/src/args.rs`, `apps/figcraft/src/control_server.rs`, `crates/ui-egui/src/control.rs`, `docs/control-protocol.md` | implemented |
| 5 | `figcraft-cli` subcommands: info, export, convert, render, run, commands, mcp, plugin publish, perf, each accepting `--no-system-fonts` | `apps/figcraft-cli/src/main.rs` (USAGE + dispatch), `apps/figcraft-cli/src/files.rs`, `docs/cli.md` | implemented |
| 6 | Native format `.figcraft` = zip(`document.json` version 1 + `images/<sha256>` + thumbnail + versions + branches + library), bare JSON also opens, atomic save | `crates/format/src/lib.rs` (`EXTENSION`, `VERSION`, `save_bytes_with_history`, `write_file_atomic`, `load_within`) | implemented |
| 7 | `.fig` (Figma) import, best effort, never saved over | `crates/format/src/fig/` (map.rs, kiwi.rs, network.rs), `docs/file-format-parity.md` | partial — tested only on synthetic fixtures, never real files (`docs/gaps.md` 1 & 3) |
| 8 | `.fig` export, experimental, whole document, omissions returned as warnings | `crates/format/src/fig/export.rs`, `docs/file-format-parity.md` › Export to `.fig` (experimental) | partial — round trips through FigCraft's own importer; effects/images/prototypes unchecked elsewhere |
| 9 | REST API file JSON import incl. local-variables JSON and `images/<imageRef>.png` | `crates/format/src/rest/` (mod.rs, props.rs, proto.rs, variables.rs, text.rs), `docs/mcp.md` › Importing REST API file JSON | implemented |
| 10 | Open formats in code: figcraft, json, fig, svg, png/jpg/jpeg/gif/webp/bmp/tif/tiff; HEIC and video absent | `crates/engine/src/cmd/file.rs` (extension match at the open paths), `docs/file-format-parity.md` (Import table) | implemented for the listed set; HEIC/video explicitly missing |
| 11 | Export formats: png, jpg, svg, webp, pdf (+ experimental fig); SVG/PDF refuse trees deeper than 256 levels | `crates/doc/src/props.rs` (`ExportFormat::from_ext`), `apps/figcraft-cli/src/files.rs`, `docs/file-format-parity.md` › Export | implemented |
| 12 | PDF print options: bleed, crop marks, bleed marks, naive CMYK; one page per top-level frame with real text | `apps/figcraft-cli/src/args.rs` (`Args::print`), `docs/cli.md` | implemented (no CMYK output intent — `docs/gaps.md` 23) |
| 13 | `run` scripts are all-or-nothing and one undo step, with `$step` references between steps | `apps/figcraft-cli/src/files.rs`, `docs/cli.md` › `run`, `crates/engine/src/batch_step_ref_tests.rs`, `batch_rollback_tests.rs` | implemented |
| 14 | File-access confinement via `--automation-read-root` / `--automation-write-root`, enforced through one engine module | `crates/engine/src/file_access.rs` (+ `crates/engine/clippy.toml` ban on `std::fs`), `docs/mcp.md` › Confining file access | implemented |
| 15 | Auto layout: flow, wrap, grid with fixed/`fr`/auto tracks, hug/fill/fixed, min/max, absolute, baseline, contentAlign | `crates/layout`, `crates/engine/src/al_*_tests.rs`, `docs/mcp.md` › Conventions | implemented |
| 16 | Components, variants, overrides, slots, playground, styles and variables with modes/aliases/scopes/bindings | `crates/engine/src/components.rs`, `components_behaviour_tests.rs`, `docs/components-parity.md` | implemented |
| 17 | Prototyping: interactions, actions incl. conditionals/expressions, transitions, flows, device-frame presentation | `crates/engine/src/proto_*.rs`, `crates/engine/src/proto_*_tests.rs`, `docs/prototyping-parity.md` | implemented; media triggers and macOS/Linux controllers missing |
| 18 | Dev Mode: inspect, code generation (CSS/HTML/React/Leptos/SwiftUI/Compose), annotations, ready-for-dev, compare changes | `crates/engine/src/codegen.rs`, `code_connect.rs`, `annotations.rs`, `docs/dev-mode-parity.md` | implemented (import lines in generated trees missing) |
| 19 | Comments, version history (≤100 versions) and branches (≤100) stored in the file | `crates/doc/src/comments.rs`, `crates/engine/src/cmd/comment.rs`, `version_tests.rs`, `crates/format/src/lib.rs` (`MAX_VERSIONS`, `MAX_BRANCHES`, `read_versions`, `read_branches`) | implemented; local to the file, not shared |
| 20 | Keyboard shortcuts: 129 documented bindings, 126 bound, platform-specific Mac vs Other | `crates/engine/src/keymap.rs` (`KEYS`), `keymap_tests.rs`, `shortcut_parity_tests`, `ROADMAP.md` 2026-10-12 entry | implemented (2 documented bindings missing) |
| 21 | Sandboxed WASM plugins (wasmi, metered, no fs/net/clock) with manifest permissions, panels and widgets; three examples; server plugin directory | `crates/plugin`, `plugins/sdk`, `plugins/examples/{counter,swatch-grid,tidy-names}`, `docs/plugins.md` | implemented; widgets take clicks only; Figma plugins do not run |
| 22 | Live sessions (preview): sync, cursors, cursor chat, spotlight, follow, per-person undo, invite links, browser joins; self-hosted `figcraft-server` with edit/view links | `crates/collab`, `crates/collab-net`, `apps/figcraft-server/src/cli.rs`, `docs/collab-protocol.md`, `docs/server.md` | partial — no accounts, no E2E encryption, preview quality |
| 23 | Recovery copies of unsaved documents every 10 s; `file.recover` | `apps/figcraft/src/recovery.rs` (`INTERVAL = 10.0`) | implemented |
| 24 | Never-crash discipline: clippy denies unwrap/expect/panic/todo/unimplemented/unreachable in shipped code; commands run behind a guard that rolls back | `Cargo.toml` (`[workspace.lints.clippy]`), `crates/engine/src/guard.rs` | implemented |
| 25 | WebAssembly build of engine+UI; browser has no system fonts and one window | `apps/figcraft-web`, `Cargo.toml` `[profile.web-release]`, `docs/hardware-parity.md` | implemented (`cargo xtask wasm`) |
| 26 | "About 49% of the way to replacing Figma" / ~53% ready for real work; feature breadth ~85% | `README.md` (49%), `ROADMAP.md` + `docs/target-app-parity.md` (53%, 85%) | claimed — self-graded estimates, explicitly unmeasured on real files |
| 27 | No AI features, no spell check, no FIG plugin compatibility, no HEIC/video | `docs/target-app-parity.md` areas 21, 10, 18; `docs/gaps.md` 19, 11, 12 | verified absent |
| 28 | macOS bundle ships no CLI; CLI is built from source or shipped as a separate zip; Linux AppImage exposes `cli <args>` | `ls /Applications/FigCraft.app/Contents/MacOS` (FigCraft only), `packaging/macos/package.sh` (CLI zip), `docs/mcp.md` (AppImage note) | implemented |

## Uncertainties this review could not resolve from the repo

- Actual fidelity of `.fig` import on real files, and of `.fig` export in other software beyond the
  layer types the docs list as checked (`docs/file-format-parity.md` says effects, images and
  prototypes are unchecked there).
- Whether the 49% (README) and ~53% (ROADMAP/parity) figures should be reconciled — both are self-graded
  and the docs acknowledge no real-file measurement exists.
- Screen-reader behaviour: implemented via AccessKit but `docs/gaps.md` 22 says screen readers were
  never run.
- On-screen Display P3 is blocked upstream (egui-wgpu 8-bit sRGB surface); documents and exports
  still carry P3 — treat on-screen colour as sRGB.

# FigCraft skill — evidence table

Repo: https://github.com/storytold/figcraft · inspected commit `28de91d9ae72fc7fbc2199ac5ee2c8be237980d5`
(tag `v0.9.0`, "Release 0.9.0", 2026-10-21) · inspected 2026-10-22. The installed app reports
`FigCraft 0.9.0 (28de91d9……)`, so app and source match. The v0.7.0→v0.9.0 delta is a single
squashed release commit (206 files, +21,175/−1,356), diffed in full to separate new claims from
carried-over ones.

Status legend: **implemented** = code path exists and is wired into UI/CLI; **partial** = exists but
visibly incomplete or unverified outside the repo; **claimed** = asserted in docs/README but not
confirmed in code by this review.

| # | Claim | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Every user-visible behaviour is a command; 212/212 catalogued menu items, 561 commands registered (published measure 2026-10-17) | `docs/parity-checklist.md`, `crates/engine/src/catalog.rs`, `crates/engine/src/cmd/mod.rs` (`all_commands`) | implemented (measured; a few commands may postdate the measure — count via `commands --json`) |
| 2 | MCP server: 18 tools, 4 resources/templates, 4 prompts; headless or `--attach` | `crates/mcp/src/tools.rs` (`TOOL_NAMES`), `crates/mcp/src/resources.rs`, `crates/mcp/src/prompts.rs`, `docs/mcp.md` | implemented |
| 3 | Control channel: 17 methods, loopback JSON-lines, state methods answered while minimised, drawn-frame methods fail fast | `crates/ui-egui/src/control.rs`, `apps/figcraft/src/control_server.rs`, `docs/control-protocol.md` (+ `ROADMAP.md` #720) | implemented |
| 4 | `figcraft-cli` subcommands info/export/convert/render/run/commands/mcp/plugin publish/perf; `--no-system-fonts` everywhere; exit 2/1/0 | `apps/figcraft-cli/src/main.rs` (USAGE + dispatch), `docs/cli.md` | implemented |
| 5 | NEW in 0.9.0 — `--automation-read-root`/`--automation-write-root` on `info`, `export`, `convert`, `render`, `run` | `docs/cli.md` › Confining a run (new section), `apps/figcraft-cli/src/main.rs` (+78 in the delta) | implemented |
| 6 | NEW in 0.9.0 — missing-fonts: `text.missingFonts`/`text.rescanFonts`/`text.loadFont`/`text.refit` commands; `info` prints `missingFonts`; in-app panel | `crates/engine/src/fonts.rs` (new file in delta), `crates/ui-egui/src/missing_fonts.rs` (new), `docs/cli.md`, `docs/mcp.md` › Conventions | implemented |
| 7 | NEW in 0.9.0 — `node.get`/`document.inspect`/MCP `get_node` report `pluginData`; `node.set {props: {pluginData}}` writes, `null` removes | `ROADMAP.md` 2026-10-20 #879, `crates/engine/src/plugin_data_tests.rs` (new), `docs/plugins.md` | implemented |
| 8 | Native format `.figcraft` = zip(`document.json` version 1 + `images/<sha256>` + thumbnail + versions ≤100 + branches ≤100 + library), bare JSON opens, atomic save, 16× compression rule in 512 MiB member cap | `crates/format/src/lib.rs` (`EXTENSION`, `VERSION`, `MAX_VERSIONS`, `MAX_BRANCHES`, `DOCUMENT_RATIO`, `MAX_MEMBER`, `write_file_atomic`) | implemented |
| 9 | `.fig` import best effort, never saved over; budgets from file size; import report; paste from another design app via clipboard HTML (`edit.pasteDesignLayers`, 256 MB cap) | `crates/format/src/fig/`, `docs/file-format-parity.md` › Import, `docs/gaps.md` 1 | partial — synthetic fixtures only; real files untested (gap 3) |
| 10 | `.fig` export experimental, whole document; checked in other software for layers/fills/gradients/strokes/shadows/vectors/components/text/instances/variables-with-modes/styles; effects, images, prototypes unchecked there; omissions are warnings | `crates/format/src/fig/export.rs`, `docs/file-format-parity.md` › Export to `.fig` | partial — improved since v0.7.0 (was unchecked elsewhere) |
| 11 | Open formats: figcraft, json (FigCraft or REST incl. slots #792 and grid tracks), fig, svg, png/jpg/jpeg/gif/webp/bmp/tif/tiff; HEIC and video absent | `crates/engine/src/cmd/file.rs` (extension match), `crates/format/src/rest/`, `docs/file-format-parity.md` › Import | implemented for the listed set |
| 12 | Export formats png/jpg/jpeg/svg/webp/pdf (+ experimental fig); render also jpg/webp; SVG/PDF refuse trees deeper than 256 levels; PDF bleed ≤ 2 in, page boxes, naive CMYK | `crates/doc/src/props.rs` (`ExportFormat::from_ext`), `apps/figcraft-cli/src/args.rs` (`print`, `scale`), `docs/cli.md`, `docs/file-format-parity.md` › Export | implemented |
| 13 | `run` scripts all-or-nothing, one undo step, `$step` references; can start from a template; no network | `apps/figcraft-cli/src/files.rs`, `docs/cli.md` › `run`, `docs/mcp.md` › Live sessions | implemented |
| 14 | `collab.*`: headless MCP session and attached app can host/join/share-with-code/publish; `run` cannot; `collab.share` online publishes to a server by default | `docs/mcp.md` › Live sessions, `docs/cli.md` (`mcp`), `crates/collab`, `crates/collab-net` | implemented (preview feature) |
| 15 | Auto layout incl. grid tracks/fr/spanning; components/variants/slots; prototyping with gamepad triggers and conditionals; Dev Mode code gen (CSS/HTML/React/Leptos/SwiftUI/Compose) | `crates/layout`, `crates/engine/src/components.rs`, `docs/components-parity.md`, `docs/prototyping-parity.md`, `docs/dev-mode-parity.md` | implemented (documented tails in gaps 15–17) |
| 16 | Keyboard shortcuts: one keymap table, 151 binding rows, 12 groups, Mac vs Windows/Linux variants | `crates/engine/src/keymap.rs` (`KEYS`, `Group::ALL`), `keymap_tests.rs`, `shortcut_parity_tests.rs` | implemented (supersedes the old skill's "129 documented bindings" derivation, which is not in the tree) |
| 17 | Sandboxed WASM plugins (wasmi, metered, no fs/net/clock), manifest permissions, panels/widgets, 3 examples, server plugin directory + `plugin publish` | `crates/plugin`, `plugins/sdk`, `plugins/examples/`, `docs/plugins.md`, `docs/cli.md` › `plugin publish` | implemented; widgets click-only; Figma plugins don't run |
| 18 | Recovery copies every 10 s; never-crash clippy discipline; unknown app option refuses startup | `apps/figcraft/src/recovery.rs` (`INTERVAL = 10.0`), `Cargo.toml` lints, `crates/engine/src/guard.rs`, `apps/figcraft/src/args.rs` | implemented |
| 19 | Parity: README ~49%; ~53% ready, ~85% breadth, ~59% essentials, ~50% mainstream; no AI (0%), no spell check; P3 on screen blocked upstream | `README.md`, `ROADMAP.md`, `docs/target-app-parity.md`, `docs/gaps.md` 7/11/18/19 | claimed — self-graded estimates, unmeasured on real files |
| 20 | WebAssembly build; browser joins but cannot host, no system fonts, embeds craft-fonts again since 0.9.0 (#885) | `apps/figcraft-web`, `Cargo.toml` (`[profile.web-release]`), `ROADMAP.md` #885, `docs/mcp.md` › Fonts | implemented |
| 21 | macOS bundle has no CLI (only `FigCraft` binary); CLI ships as separate zip `figcraft-cli-<version>-macos-<arch>.zip`; AppImage exposes `cli` | `ls /Applications/FigCraft.app/Contents/MacOS`, `packaging/macos/package.sh` (`CLI_ZIP`) | implemented |
| 22 | Templates: 8 built-in starters via `template.list` / `file.newFromTemplate`; 5 example documents in `examples/` | `docs/mcp.md` › Starter templates, `examples/` listing | implemented |
| 23 | NEW in 0.9.0 (UI/behaviour): drop a document on canvas opens it (#916); duplicating a main makes an instance (#892); measure-while-nudging (#894); `uiScale` in `ui.inspect`; `homeSearch` in `ui.set`; double-click frame label renames in place | `ROADMAP.md` 2026-10-20 entries, `docs/control-protocol.md` diff, `crates/ui-egui/src/ui_scale.rs` (new) | implemented |
| 24 | Localization: en/ru/tr reviewed, sv command labels, draft catalogs es(+es-419)/fr/de/pt-BR/ja/ko/zh-Hans/cs/id/ka + new bn/fi/nl/pl (0.9.0); engine messages English | `crates/ui-egui/locales/`, `crates/ui-egui/src/i18n.rs` (`LANGS` generated from all `locales/*.toml`), `docs/localization-parity.md`, `README.md` | implemented (five new catalogs in tree but not yet in README/parity tables) |

## Uncertainties this review could not resolve from the repo

- Exact live command count at v0.9.0: the published 561 is the 2026-10-17 `cargo xtask parity`
  measure; the release commit touched `crates/engine/src/cmd/*` afterwards (behaviour fixes), and
  no newer published count exists. A raw `spec!`-site count (458) does not reconcile with it
  without knowing every registration site, so the skill cites the published number with its date.
- The v0.9.0 `Cargo.toml` declares `figcraft-tools = { path = "crates/tools" }` but no
  `crates/tools` directory exists in the tree; nothing appears to inherit it, so the workspace
  still builds — a dangling declaration, not a capability. Uncertain whether it is intentional.
- Whether the bn/fi/nl/pl catalogs are exposed in the language *picker* is implied (LANGS is
  generated from every `locales/*.toml`) but the README/parity docs still list only Georgian of
  the five — treat the five as in-tree drafts.
- Real-world `.fig` fidelity, and `.fig` export fidelity in other software beyond the documented
  checks, remain unmeasured (`docs/gaps.md` 1 and 3); screen readers have never been run (gap 22).
- The installed app's `Info.plist` CFBundleShortVersionString was reported stale by the tasking;
  it currently reads 0.9.0, but the skill deliberately cites the app's CLI version report instead.

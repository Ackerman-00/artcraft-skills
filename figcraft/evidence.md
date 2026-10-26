# FigCraft skill — evidence table

Repo: https://github.com/storytold/figcraft · inspected at tag **v0.11.2**, commit
**d4a303d4708602a9df1738960852d18b185a616b** ("Release 0.11.2", 2026-10-25) · inspected
2026-10-26. The installed `/Applications/FigCraft.app` reports version `0.11.2`
(`CFBundleShortVersionString`) and its binary prints `FigCraft 0.11.2
(d4a303d4708602a9df1738960852d18b185a616b)`, so bundle and source match exactly.

The checkout is a single-commit shallow clone (no v0.10.0 tag or history locally), so the delta
below is derived by re-measuring this tree and comparing against the previous skill's recorded
measurements — not from local git history. Every count in this table was measured on this tree;
none was copied forward.

Status legend: **implemented** = code path exists and is wired into UI/CLI; **partial** = exists
but visibly incomplete or unverified outside the repo; **claimed** = asserted in the docs or
README but not confirmed in code by this review.

| # | Claim | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Source is tag v0.11.2, commit `d4a303d…`; installed bundle reports the same version and build SHA | `git rev-parse HEAD` = `d4a303d4708602a9df1738960852d18b185a616b`, `git describe --tags` = `v0.11.2`; `/Applications/FigCraft.app/Contents/Info.plist` `CFBundleShortVersionString` 0.11.2; binary prints `FigCraft 0.11.2 (d4a303d…)` | implemented/verified |
| 2 | **597 commands across 60 id namespaces** (v0.10.0 recorded 569 / 57); 45 registry `specs()` collections (plus `vectoredit`'s two private submodule collections) | `crates/engine/src/cmd/mod.rs` `spec!`, `registry` (45 `list.extend(…specs())`, incl. `crate::board`, `crate::datafill`, `crate::textfit`, `crate::dev_measurements`), `crates/engine/src/vectoredit.rs` (chains `transform::specs`, `width::specs`); static count of unique `spec!("id")` = 597, prefixes = 60 | implemented (count static; live count via `figcraft-cli commands --json`) |
| 3 | Menu catalog: 245 entries → 218 items → **212/212** counted by `parity` (2 `collab.*` and 4 `OWN` excluded); 5 of the 212 are UI-layer ids, not engine commands | `crates/engine/src/catalog.rs` `MENU`, `items`, `OWN`, `parity`; `crates/ui-egui/src/menus.rs` (`edit.copyAsText/Css/Svg/Png`); `docs/parity-checklist.md` (generated 2026-10-17) | implemented (recomputed statically, matches doc) |
| 4 | MCP server: **18 tools**, 2 resources + 2 templates, 4 prompts; protocol `2025-06-18` (older accepted); 32 MiB line cap | `crates/mcp/src/tools.rs` `TOOL_NAMES`, `tool_definitions`, `MAX_RESPONSE`; `resources.rs` (`DOC_URI`, `COMMANDS_URI`, templates); `prompts.rs` `PROMPTS` (4); `server.rs` `PROTOCOL_VERSION`, `SUPPORTED_VERSIONS`, `MAX_LINE` | implemented |
| 5 | MCP responses now bounded: `inspect_document`/`get_node` take `maxBytes` (default 8 MiB), `get_node` an `offset`, results carry a `truncated` marker (new since v0.10.0) | `crates/mcp/src/tools.rs` `MAX_RESPONSE`, `MARKER_RESERVE`, `ENVELOPE_RESERVE`, `budget`; tool schemas at `inspect_document`/`get_node` | implemented |
| 6 | Control channel: **17 methods**, loopback, 32 MiB lines, 8 connections, 8-request queues, 60 s timeouts; state methods answer minimised, `ui.screenshot`/`ui.input`/`window.new` fail fast | `crates/ui-egui/src/control.rs` (match arms + `NEEDS_FRAME`, `SHOT_TIMEOUT`), `apps/figcraft/src/control_server.rs` (`MAX_LINE`, `MAX_CONNECTIONS`, `MAX_QUEUED_REQUESTS`, `TIMEOUT`), `docs/control-protocol.md` (17 method headings) | implemented |
| 7 | `figcraft-cli` has **9 subcommands** (info/export/convert/render/run/commands/mcp/plugin publish/perf); `--no-system-fonts` on all; roots on six; exit 2/1/0; `--scale` ≤64; render ≤16384 px; bleed ≤2 in | `apps/figcraft-cli/src/main.rs` (`USAGE`, dispatch, `ROOT_FLAGS`), `apps/figcraft-cli/src/args.rs` (`scale`, `print`), `apps/figcraft-cli/src/files.rs` (`render_page`, `write_doc`), `docs/cli.md` | implemented |
| 8 | New CLI behaviour: `--help`/`-h` anywhere among options returns usage with exit 0, even after a bad option (`CliError::Help`) | `apps/figcraft-cli/src/args.rs`, `apps/figcraft-cli/src/main.rs` | implemented |
| 9 | Shortcuts: **159 default bindings in 12 groups** (v0.10.0: 151); 8 new board bindings | `crates/engine/src/keymap.rs` `Group::ALL` (12), 159 `k(` entries; `docs/ui-parity.md` (129 documented rows, 57 undocumented pinned, board keys Q/B/X/M/U/E/W + Shift+Cmd+Enter) | implemented (measured) |
| 10 | New file kind: **boards**. `file.newBoard`, `Document.kind` = `design|board`, board items on ordinary layers, 9 `board.*` commands + 7 board tools; proto/dev refuse on boards and board commands refuse on design files | `crates/doc/src/board.rs` (`FileKind`, `BoardItem`, `BoardShape`, `Stamp`), `crates/doc/src/lib.rs` (`Document.kind`), `crates/engine/src/board.rs` (`NOT_ON_BOARDS`, `NEEDS_BOARD`, 9 specs), `crates/engine/src/cmd/file.rs` (`file.newBoard`), `docs/boards-parity.md` | implemented; boards are a first slice (~35% breadth) |
| 11 | Dev Mode tail closed: measurements stored on the canvas (`devMode.addMeasurement/measurements/removeMeasurement`), compare against any saved version (`dev.compare {version}`), inspect-only canvas, import lines in generated layer trees, read-only layers panel | `crates/engine/src/dev_measurements.rs`, `crates/engine/src/cmd/section.rs` (`dev.compare`), `crates/engine/src/devcompare.rs`, `crates/engine/src/codegen.rs`, `docs/dev-mode-parity.md` | implemented; publishing mappings + editor extension still missing |
| 12 | `data.fill` fills frame copies from data rows, optional multi-size and export; `text.fit` fits text to `maxLines` (new since v0.10.0) | `crates/engine/src/datafill.rs` (`data.fill`), `crates/engine/src/textfit.rs` (`text.fit`), `docs/mcp.md` › Filling copies with data | implemented |
| 13 | Vector fill rules: `vector.fillRule` + `vector.reverseLoop` (new); total vector commands 42 (was 40) | `crates/engine/src/vectoredit.rs`, `crates/engine/src/vector_fill_rule_tests.rs`; count from `spec!` scan | implemented |
| 14 | Formats read: `.figcraft`, `.json` (FigCraft or REST API + optional variables JSON and `images/`), `.fig` (best effort), `.svg`, png/jpg/jpeg/gif/webp/bmp/tif/tiff; PDF is export-only | `crates/engine/src/cmd/file.rs` `load_with` extension match, `crates/format/src/rest`, `crates/format/src/fig`, `crates/svg`, `docs/file-format-parity.md` | implemented for the listed set |
| 15 | Formats written: `.figcraft`, `.svg`, `.png`, `.jpg/.jpeg`, `.webp`, `.pdf`, experimental `.fig`; `.json` only through CLI `convert`/`run --out`, not app Save | `crates/doc/src/props.rs` `ExportFormat::from_ext`, `apps/figcraft-cli/src/files.rs` `write_doc`, `crates/engine/src/cmd/file.rs` `save_to`, `docs/cli.md` | implemented |
| 16 | `.figcraft` zip: `document.json` (format 1, optional `kind`, imageIndex), `images/<sha256>`, optional `thumbnail.png`, `versions/`, `branches/`, `library/`; atomic staging write; newer format refused; ≤100 versions/branches; 512 MiB member, 16× ratio | `crates/format/src/lib.rs` (`EXTENSION`, `VERSION`, `MAX_VERSIONS`, `MAX_BRANCHES`, `DOCUMENT_RATIO`, `MAX_MEMBER`, `write_file_atomic`, `FormatError::Newer`), `crates/format/src/library.rs` | implemented |
| 17 | `.fig` import is best effort and never saved over; `.fig` export is experimental, whole-document, omissions warned, grid track sizes now written, real files unmeasured | `crates/format/src/fig/` (`export.rs` grid sizing, `kiwi.rs`), `docs/file-format-parity.md` › Documents / Export to `.fig`, `docs/gaps.md` 1 and 3 | partial — synthetic fixtures only |
| 18 | Live sessions: 21 `collab.*` commands; host/join/share/publish, cursors, chat, spotlight; headless MCP can host/join/publish, one-shot `run` cannot; boards sync in sessions | `crates/engine/src/{live,online,collab,invite_links}.rs`, `crates/collab/src/board_sync_tests.rs`, `docs/mcp.md` › Live sessions, `README.md` › Privacy and online sharing | implemented (preview, no accounts) |
| 19 | Templates: 8 starters via `template.list`/`file.newFromTemplate`; 5 example documents `examples/ridgeline-*` + `glass-and-vectors` | `crates/engine/src/templates/mod.rs` `TEMPLATES`, `examples/` | implemented |
| 20 | Plugins: wasmi sandbox (fuel, memory cap, no fs/net/clock), manifest permissions, panels/settings/widgets; **three** examples; self-hosted plugin directory | `crates/plugin`, `plugins/sdk`, `plugins/examples/{counter,swatch-grid,tidy-names}`, `docs/plugins.md` (`plugin.directory.*`) | implemented; widgets click-only, no public catalogue |
| 21 | Crash discipline: no unwrap/expect/panic in shipped code (clippy denies), command guard rolls back, 10 s recovery copies; AccessKit + F6 on desktop | `Cargo.toml` `[workspace.lints.clippy]`, `crates/engine/src/guard.rs`, `apps/figcraft/src/recovery.rs` (`INTERVAL = 10.0`), `crates/ui-egui/src/a11y.rs` | implemented |
| 22 | Maturity per repo docs: alpha, ~53% ready, ~85% feature breadth, ~94% core; boards excluded from the weighted sum (area 22); 19 locale catalogs vs 13 languages listed | `ROADMAP.md` › Headline, `docs/target-app-parity.md` › Headline, `docs/boards-parity.md`, `crates/ui-egui/locales/` (19 files), `README.md` › Under the hood | claimed (self-graded); counts measured |

## Uncertainties this review could not resolve from the repo

- **Exact live command count.** A static count of unique `spec!(` string ids gives **597** and every
  `specs()` module in `crates/engine/src/cmd/mod.rs` is collected (plus `vectoredit` chaining its two
  submodules), so nothing is orphaned. The generated checklist still says 561 (measured 2026-10-17)
  and README says "400+". The authoritative number is whatever `figcraft-cli commands --json` prints
  on your build; the skill states both and tells the reader to count.
- **No local git history.** The clone is shallow (one commit), so no `v0.10.0..HEAD` diff was
  possible. The "changed since v0.10.0" statements come from re-measuring this tree and comparing
  with the previous skill's recorded counts, plus files that the previous audit did not list
  (`crates/doc/src/board.rs`, `crates/engine/src/{board,datafill,textfit,dev_measurements}.rs`,
  `docs/boards-parity.md`) and the release notes the repo's own docs revision tables describe.
  A per-id diff against the v0.10.0 tag was not performed.
- **`crates/tools` is a dangling workspace dependency.** `Cargo.toml` declares
  `figcraft-tools = { path = "crates/tools" }`, but no `crates/tools` directory exists in the tree.
  Nothing appears to inherit it, so the workspace can still build; it is not a capability.
- **Localization review status conflicts.** `README.md` lists 13 languages and says English, Russian
  and Turkish were reviewed by native speakers; `docs/gaps.md` calls only Russian and Turkish
  reviewed; the tree has 19 catalogs (`bn`, `cs`, `de`, `en`, `es`, `es-419`, `fi`, `fr`, `id`, `ja`,
  `ka`, `ko`, `nl`, `pl`, `pt-BR`, `ru`, `sv`, `tr`, `zh-Hans`). Treat the review badge as a claim.
- **`.fig` fidelity remains unmeasured on real files.** All corpora are synthetic; export has been
  opened in other software for a documented subset, but effects, images and prototypes are unchecked
  there (`docs/gaps.md` 1 and 3).
- **Doc drift found and noted inline:** `docs/parity-checklist.md` 561 vs measured 597 commands;
  README "400+ commands"; change-log text "menu breadth 211/211" vs the measured table's 212/212;
  `docs/architecture.md` "two example plugins" vs three in `plugins/examples`; README "about 49%"
  vs the docs' ~53% ready.
- **Screen readers have never been run** against the app; the browser build has no accessibility
  tree (`docs/gaps.md` 22). Platform QA: Linux and browser still open, Windows pass documented
  (`docs/gaps.md` 8).
- **No build or runtime test was performed for this skill.** The repo was treated read-only, the GUI
  was not launched, and no `cargo` command was run; all counts are static or from the checked-in
  docs. The installed binary was invoked only with `--version`, and the bundle's `Info.plist` was
  read.

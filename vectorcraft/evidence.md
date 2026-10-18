# evidence.md — VectorCraft skill claim map (for orchestrator review)

Repo: `storytold/vectorcraft` · tag **v0.13.1** · commit `904f0fe5227bd987d55319e89a38b4b8f046998c`
(2026-10-18) · installed app `/Applications/VectorCraft.app` 0.13.1 (same release).
Tiers: **implemented** (code path exists and is wired into UI/CLI) · **partial/stub** ·
**not implemented** (repo-admitted absent).

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Clean-room pure-Rust reimplementation of Illustrator; macOS/Win/Linux/FreeBSD + WASM web | `README.md` L14–21, L259–261; `apps/vectorcraft-web/`; `xtask/src/main.rs` (`wasm` task) | implemented |
| 2 | Stage alpha; ~88% breadth, ~75% depth, ~62% ready-for-real-work, self-assessed | `ROADMAP.md` L10, L28–43; `docs/target-app-parity.md` | partial (alpha, by design) |
| 3 | Native format `.vectorcraft`/`.drawcraft`, JSON v4, down-save, gzip, preview, compact mode | `crates/format/src/lib.rs` (`VERSION = 4`, `EXTENSION`, `LEGACY_EXTENSION`); `docs/mcp.md` › Native files | implemented |
| 4 | Multi-document tabs, artboards, layers, dockable panels, workspaces | `crates/ui-egui/src/control.rs` (`documents`, `activeDocument`); `crates/ui-egui/src/state.rs` L376–381; `ROADMAP.md` UI.5 entry; `crates/ui-egui/src/panels/` listing | implemented |
| 5 | Tools emit commands; every gesture replayable via control/MCP | `crates/tools/src/lib.rs` (module doc); `AGENTS.md` › Everything is a command | implemented |
| 6 | Curve-preserving Pathfinder booleans, Shape Builder regions, offset/outline/simplify | `crates/pathops/src/lib.rs` (module doc); `crates/engine/src/cmd/pathops.rs` | implemented |
| 7 | Type: point/area/path, threading, styles, OpenType features, vertical (initial CJK), Hebrew/Arabic bidi | `crates/text/src/lib.rs`; `docs/type-parity.md` (summary 80% core / 50% advanced); `README.md` | implemented (advanced type partial) |
| 8 | Live effects + raster effects; 33/57 Photoshop-style filters | `crates/effects/src/lib.rs` (module doc); `docs/effects-parity.md`; `ROADMAP.md` L32 | partial (24 filters missing) |
| 9 | 3D: Revolve, Extrude & Bevel, Inflate, Rotate, 1–10 coloured lights; no materials; painter's algorithm | `crates/three-d/src/lib.rs` (module doc); `ROADMAP.md` 2026-10-12 & L32; `docs/three-d.md` | partial (~25%) |
| 10 | Image Trace with presets and measured quality | `crates/trace/src/lib.rs`; `docs/image-trace-quality.md` | implemented |
| 11 | Open/place formats — exact extension lists | `crates/engine/src/cmd/fileio/mod.rs` `OPEN_EXTS` (L660–688), `PLACE_EXTS` (L719–750), `FORMATS` (L520–657) | implemented |
| 12 | PSD/PSB open as merged image only; PSD export layered | `docs/file-format-parity.md` PSD row; `crates/engine/src/cmd/fileio/psdread.rs`; `FORMATS` (`psd` read+write, `psb` reader) | implemented (with stated loss) |
| 13 | Affinity `.af/.afdesign/.afpub` read-only native import | `crates/affinity/src/lib.rs` (module doc: "Nothing here writes Affinity files"); `docs/affinity-validation.md` | implemented (read-only) |
| 14 | Save formats: vectorcraft, template, pdf, svg, svgz, ai (PDF-compatible default, legacy v7 option) | `crates/engine/src/cmd/fileio/save.rs` `SAVE_FORMATS` L23; `docs/file-format-parity.md` › The main format | implemented |
| 15 | Export formats (extension-driven, 19 exts) incl. layered PSD, png8, targa; Export for Screens; CSS; print via craft-print | `crates/engine/src/cmd/fileio/mod.rs` `export_extensions()`; `fileio/{screens.rs,encode.rs}`; `crates/engine/src/cmd/{css.rs,print.rs}`; root `Cargo.toml` (`craft-print`) | implemented |
| 16 | `.ai` exchange gaps: layer structure in real files, no Illustrator editing data written, no real-file corpus | `docs/gaps.md` › G9; `docs/file-format-parity.md` (known failures #951/#868/#779/#758/#637) | not implemented (blocked, G9) |
| 17 | MCP server: stdio JSON-RPC 2.0, remote/headless backends, tool list, not-implemented list | `docs/mcp.md` (Tools, Not implemented); `crates/mcp/`; `apps/vectorcraft-cli/src/main.rs` (`mcp` subcommand) | implemented (stdio only) |
| 18 | Control channel: loopback JSON-lines, method list, synthetic input budgets, 16 conn limit, no auth | `docs/control-protocol.md`; `crates/ui-egui/src/control.rs`; `apps/vectorcraft/src/control_server.rs` | implemented |
| 19 | CLI subcommands mcp/run/commands/convert/info/bench/perf + flags; `$N.path` step references; `importWarnings` | `apps/vectorcraft-cli/src/main.rs` USAGE L67–119, `run()`/`convert()`; `crates/engine/src/steps` (`vectorcraft_engine::steps::resolve`) | implemented |
| 20 | File-access confinement for agents (read/write roots, link-following rules) | `docs/mcp.md` › Confining file access; `docs/control-protocol.md` › Confining; `crates/engine/src/file_access.rs` (referenced as `file_access`) | implemented |
| 21 | WASM plug-in ABI v1 sandbox (wasmi, no imports, fuel/memory caps) | `docs/plugins.md`; `crates/plugins/src/lib.rs`; root `Cargo.toml` (`wasmi`) | implemented |
| 22 | Scripting for the reference app does **not** run; `scriptcheck` statically analyses `.jsx`/`.jsxbin` | `README.md` › What's missing (scripting); `crates/scriptcheck/src/lib.rs` (checker, "without running any of it"); `docs/mcp.md` › Checking scripts | not implemented (checker implemented) |
| 23 | Never-crash discipline: no-panic lints + engine `guard` rollback (native only; wasm aborts) | root `Cargo.toml` `[workspace.lints.clippy]`; `crates/engine/src/guard.rs` (module doc) | implemented |
| 24 | Localization: 20+ catalogues, ~10 complete, no native review | `crates/ui-egui/src/i18n/*.tsv`; `ROADMAP.md` L100–115; `docs/localization-parity.md` | implemented (review pending) |
| 25 | "20,000 shapes ~27 ms" README figure; budgets checkable via `vectorcraft-cli perf` | `README.md` › Why VectorCraft; `apps/vectorcraft-cli/src/perf.rs` (budget harness, noise caveats) | claimed (self-report; measure locally) |

## Notes for the orchestrator

- No codegraph index exists in this repo; all reads were direct (grep/read) against the v0.13.1
  checkout, which is byte-identical to the installed 0.13.1 app bundle per `Info.plist`
  (`CFBundleShortVersionString` 0.13.1) and the release commit (`git log -1`: "Release 0.13.1").
- `vectorcraft-cli` is **not installed** on this Mac (checked `PATH`, common bin dirs; the `.app`
  bundle holds only the desktop executable) — the skill says to build it or fetch the separate
  macOS CLI release asset, matching `docs/mcp.md`.
- The `docs/file-format-parity.md` summary table lists "PS" as missing while its own format row
  and `FORMATS`/`OPEN_EXTS` show PostScript `.ps` read/place is implemented — the code was
  treated as authoritative and the skill lists `.ps` as supported.
- Tier honesty: ui-parity/type-parity/effects-parity "done" statuses are documentation-derived,
  never side-by-side measured (repo states this); the skill carries that caveat under "claimed but
  unverified".

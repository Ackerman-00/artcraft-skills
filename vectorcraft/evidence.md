# evidence.md — VectorCraft skill claim map (for orchestrator review)

Repo: `storytold/vectorcraft` · tag **v0.14.0** · commit `ad0566943ab9741e6356bbc9b53c3cc09895068d`
("Release 0.14.0", 2026-10-19; a fresh single-commit history — `git log` shows one commit) ·
inspected 2026-10-22 · installed app reports `vectorcraft 0.14.0` (same release).
Tiers: **implemented** (code path exists and is wired into UI/CLI) · **partial/stub** ·
**not implemented** (repo-admitted absent) · **claimed** (self-report, not measured).

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Clean-room pure-Rust Illustrator reimplementation; macOS/Win/Linux/FreeBSD + WASM web | `README.md` L14–26; `apps/vectorcraft-web/`; `xtask/src/main.rs` (`wasm` task) | implemented |
| 2 | Stage alpha; ~88% breadth (348/375 menu items 92.8%, tools 89/92, Ill. effects 46/50, PS effects 46/57, 3D 4/4), ~75% depth, ~62% ready | `ROADMAP.md` L28–43 (headline table); `docs/target-app-parity.md` | partial (alpha, by design; self-assessed) |
| 3 | Native `.vectorcraft`/`.drawcraft`, JSON v4, down-save to v1, gzip, preview, compact mode, atomic saves | `crates/format/src/lib.rs` (`VERSION = 4` L52, `MIN_VERSION` L58, `EXTENSION`/`LEGACY_EXTENSION` L63–65); `docs/mcp.md` › Native files | implemented |
| 4 | Multi-document tabs, artboards, layers, dockable panels, 40+ panels, workspaces | `crates/ui-egui/src/panels/` (42 non-test panel files); `crates/ui-egui/src/control.rs` (`ui.inspect`); `docs/control-protocol.md` L94 | implemented |
| 5 | Tools emit commands; every gesture replayable; 92 tool ids in catalogue | `crates/tools/src/lib.rs`; `crates/tools/src/catalog.rs` (92 `t(...)` ids); `AGENTS.md` › Everything is a command | implemented |
| 6 | Curve-preserving Pathfinder, Shape Builder, Live Paint, offset/outline/simplify (slider) | `crates/pathops/src/lib.rs`; `crates/engine/src/cmd/pathops.rs`; `ROADMAP.md` 2026-10-19 (Simplify slider #2555) | implemented (regions/Gap Detection partial, G11) |
| 7 | Type: point/area/path, threading, styles, OpenType features, vertical (initial CJK), bidi, Thai/Lao/Khmer/Myanmar, Touch Type, Hyphenation/Justification done | `crates/text/`; `docs/type-parity.md` summary (core 80%, advanced 50%) and rows "Touch Type tool: done", "Hyphenation… and Justification…: done" | implemented (advanced type partial) |
| 8 | Live effects + raster effects: 46/57 Photoshop-style, 46/50 Illustrator; Effect Gallery and SVG Filters submenu missing | `docs/effects-parity.md` summary table + Artistic/Sketch missing lists; `crates/effects/src/lib.rs` (`effect_catalog()`) | partial (11 filters + gallery + SVG Filters) |
| 9 | 3D: Revolve, Extrude & Bevel, Inflate, Rotate; 1–10 coloured lights (`MAX_LIGHTS = 10`); no materials; painter's algorithm | `crates/three-d/src/lib.rs` (module doc); `crates/three-d/src/lights.rs` L4; `docs/three-d.md`; `docs/revolve.md` | partial (~25%) |
| 10 | Image Trace with presets and measured quality | `crates/trace/src/lib.rs`; `docs/image-trace-quality.md` | implemented |
| 11 | Open/place extensions — exact lists incl. Targa `.tga/.vda/.icb/.vst`; Place adds `.txt/.rtf/.docx` | `crates/engine/src/cmd/fileio/mod.rs` `OPEN_EXTS` (~L671, 31 entries), `TEXT_EXTS`/`RTF_EXTS`/`DOCX_EXTS`, `PLACE_EXTS` (~L736) | implemented |
| 12 | PSD/PSB open as merged image only; PSD export layered; `.ps` read-only (print writes PostScript, export doesn't) | `crates/engine/src/cmd/fileio/mod.rs` `FORMATS` (`psd` read+write, `psb`/`ps` readers with comments); `docs/file-format-parity.md` | implemented (with stated loss) |
| 13 | Affinity `.af/.afdesign/.afpub` read-only import; 51 pinned corpus documents (33 current `.af`) | `crates/affinity/README.md`; `docs/affinity-validation.md` L133; `docs/affinity-corpus` CI (`.github/workflows/affinity-corpus.yml`) | implemented (read-only) |
| 14 | Save formats: vectorcraft, template, pdf, svg, svgz, ai; PDF-compatible default, legacy v7 option; `.ait` via `file.saveAsTemplate` (no v7) | `crates/engine/src/cmd/fileio/save.rs` `SAVE_FORMATS` L23; `docs/file-format-parity.md` › The main format; `docs/mcp.md` › save_file | implemented |
| 15 | Export formats (19 extensions + `plugin.<id>` exporters) incl. layered PSD, png8, tga, txt; Export for Screens/Asset Export; `rect` page-area rasters; Save for Office; print via craft-print | `crates/engine/src/cmd/fileio/mod.rs` `FORMATS`/`export_extensions()` (L714) + `plugin_formats()`; `docs/mcp.md` export rows; `fileio/screens.rs`; `crates/engine/src/cmd/{print.rs,css.rs}`; root `Cargo.toml` (`craft-print`) | implemented |
| 16 | WebP export lossless only; lossy request warned and written lossless | `crates/engine/src/cmd/fileio/encode.rs` L563–564; `crates/engine/src/cmd/fileio/mod.rs` `lossless` option L397–400 | implemented (with warning) |
| 17 | `.ai` exchange gaps: real-file layer structure (#951), guides (#779), speed (#758), live objects (#637); no Illustrator editing data written (out of scope) | `docs/gaps.md` › G9 (issue numbers in text); `docs/file-format-parity.md` | not implemented (beta blocker) |
| 18 | MCP server: stdio JSON-RPC 2.0 (rev 2025-06-18), remote/headless backends, **32 tools** (aliases share handlers), 5 prompts, 3 resources + 4 templates, completions, logging, cancellation/progress/2 s busy guard, not-implemented list | `crates/mcp/src/tools.rs` (32 unconditional `tool(...)` entries; `dispatch()` L900); `crates/mcp/src/{prompts.rs,resources.rs}`; `docs/mcp.md` (Protocol, Prompts, Resource templates, Long calls, Not implemented) | implemented (stdio only) |
| 19 | `doc_inspect` scoping (`ids`/`kind`/`limit`/`offset`) and `command_batch` 256 steps / `atomic` / `$N.path` | `docs/mcp.md` › Resource templates (scoping) and `command_batch` row; `crates/mcp/src/tools.rs` | implemented |
| 20 | Control channel: loopback JSON-lines; methods incl. new `ui.contextMenu.list`, `ui.resize`/`ui.focus`; synthetic input budgets; no auth | `crates/ui-egui/src/control.rs` (`handle()` match L198–455); `docs/control-protocol.md` method table L91–118 | implemented |
| 21 | Browser `window.vectorcraft` JS API (request/execute/screenshot/openFile/captureDownloads/readFile) | `docs/control-protocol.md` L885–903; `apps/vectorcraft-web/src/api.rs` | implemented |
| 22 | CLI subcommands mcp/run/commands/convert/info/bench/perf + flags (`--ai-version 7|pdf`, `--hidden-objects`, `--transparent-images`, `--replace-lossy`, `importWarnings`) | `apps/vectorcraft-cli/src/main.rs` usage doc L3–10 and `USAGE` const L64–133 | implemented |
| 23 | WASM plug-in ABI v1 sandbox (wasmi, no imports, fuel/memory caps); kinds filter/effect/**exporter**; typed params up to 256 | `docs/plugins.md` (ABI v1, Manifest, exporter `extensions`); `crates/plugins/src/lib.rs`; root `Cargo.toml` (`wasmi`) | implemented |
| 24 | Actions playback via `command.batch` + Actions panel; Automate Batch; `dataset.import` CSV/TSV with header-defined variables; VariableKind text/visibility/image/graph | `docs/mcp.md` `command_batch` note ("what the Actions panel plays"); `crates/ui-egui/src/panels/actions.rs`; `crates/engine/src/cmd/variablecmds.rs` (`dataset.import` L1061, `datasets_csv_bytes` L538); `crates/doc/src/variables.rs` L14–25 | implemented (README "What's missing" is stale here) |
| 25 | Reference-app scripting does **not** run; `script.check` statically analyses `.jsx`/`.jsxbin` | `README.md` › What's missing; `crates/scriptcheck/src/lib.rs`; `crates/engine/src/cmd/scripts.rs` L1–10 | not implemented (checker implemented) |
| 26 | File-access confinement (read/write roots, link rules, implies headless) | `docs/mcp.md` › Confining file access L72–123; `docs/control-protocol.md` › Confining; `crates/engine/src/file_access.rs` | implemented |
| 27 | Localization: 24 languages (23 `.tsv` + English); only Georgian native-reviewed; Hindi/Arabic none; 12-key score 74% | `crates/ui-egui/src/i18n/` (23 tsv files); `docs/localization-parity.md` (key-language table, native-review note); `ROADMAP.md` › Languages | implemented (review pending) |
| 28 | Never-crash discipline: no-panic lints + engine `guard` (native only; wasm aborts) | root `Cargo.toml` `[workspace.lints.clippy]` L106–115; `crates/engine/src/guard.rs` | implemented |
| 29 | Reproducible exports via `SOURCE_DATE_EPOCH`; Background Export progress + Cancel; MCP export cancel/progress | `ROADMAP.md` 2026-10-18 row (#2880, #2564); `docs/mcp.md` › Long calls (#2165, #2171, #2172) | implemented |
| 30 | New features of this cycle: Objects on Path, `select.color`, DXF native CIRCLE/ARC, editable Illustrator EPS, CCITT G3 TIFF, `.ps`/`.epsf` open, web control channel | `crates/engine/src/cmd/objects_on_path.rs` L1–12; `crates/engine/src/cmd/select.rs` L93; `docs/file-format-parity.md` header (DXF #1299, Illustrator 3); `ROADMAP.md` 2026-10-17/18/19 rows | implemented |
| 31 | "20,000 shapes ~27 ms" README figure; budgets checkable via `vectorcraft-cli perf` | `README.md` › Why VectorCraft; `apps/vectorcraft-cli/src/perf.rs` | claimed (self-report; measure locally) |

## Notes for the orchestrator

- All reads were direct (grep/read) against the v0.14.0 checkout; no codegraph index exists in the
  repo. The v0.14.0 tag is one squashed "Release 0.14.0" commit; content matches the 2026-10-19
  tree described in `ROADMAP.md`'s change notes.
- **MCP tool count is 32 and unchanged since v0.12.0** (verified by extracting `tool(...)` names at
  both tags: identical sets, zero added/removed). The names include alias pairs
  (`command_run`/`run_command`/`invoke_menu`, `doc_inspect`/`inspect_document`,
  `ui_inspect`/`inspect_ui`, `command_list`/`list_commands`, `screenshot`/`ui_screenshot`), which
  `docs/mcp.md` confirms are convention-vs-legacy spellings of the same handlers.
- **Count changes vs the v0.12/0.13-era skill text**: Photoshop-style filters 33/57 → **46/57**
  (11 missing + Effect Gallery); Illustrator effects now stated (46/50); menu-item percentage
  92.5% → **92.8%**; localization "20+ catalogues, ~10 full" → **24 languages, most complete,
  74% key-12 measured**; Targa now opens (`.tga/.vda/.icb/.vst` in `OPEN_EXTS`) — was write-only.
- **Old skill citation fixed**: it referenced `crates/engine/src/cmd/action_batch.rs`, which does
  not exist at v0.12.0, v0.13.1 or v0.14.0; Actions playback is the engine `command.batch` plus
  the Actions panel (`crates/ui-egui/src/panels/actions.rs`).
- **Touch Type** and **Hyphenation…/Justification…** moved from "missing" to done
  (`docs/type-parity.md` rows); Retype and Snap to Glyph remain missing.
- **Doc contradictions found (code treated as authoritative)**: (a) `docs/file-format-parity.md`
  summary row lists PS as missing while `FORMATS`/`OPEN_EXTS` read `.ps`; (b) `README.md`
  "What's missing" still lists Variables image/graph kinds and dataset import, but
  `dataset.import` and all four `VariableKind`s exist (marked with a stale-doc note in SKILL.md);
  (c) the macOS CLI asset is named `…-macos-<arch>.zip` in `docs/mcp.md` but
  `…-macos-universal.zip` in `README.md` › Downloads (README used; docs/mcp.md row likely stale).
- `vectorcraft-cli` is **not installed** on this Mac (checked `PATH` and cargo bin); the `.app`
  bundle holds only the desktop executable, matching `docs/mcp.md` › From an installed release.
- Tier honesty: ui-parity/type-parity/effects-parity "done" statuses are documentation-derived,
  never side-by-side measured (the repo states this); the skill carries that caveat under
  "claimed but unverified". Uncertain items are marked inline in SKILL.md (Variables kinds;
  Indonesian catalogue row stale in localization-parity.md while `id.tsv` ships complete per the
  2026-10-17 progress log).

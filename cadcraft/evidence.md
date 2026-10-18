# Evidence table — CADCraft skill (v0.8.0)

Repo: `storytold/cadcraft` at `git rev-parse HEAD` = `714111d528acc86dc6b41e03f9a82cabc1066dca` (tag `v0.8.0`, 2026-10-17).
Installed app: `/Applications/CADCraft.app` version 0.8.0 (`Info.plist`, `CFBundleIdentifier ai.storyteller.cadcraft`).
Inspection was read-only: no build, no run, no GUI launch. Date: 2026-10-18.

Tier key: **implemented** = code path exists and is wired to a command/CLI/MCP surface; **partial** = exists with documented gaps; **claimed/absent** = README/roadmap mention without a usable code path.

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Clean-room AutoCAD reimplementation, MIT OR Apache-2.0, stage pre-alpha | `README.md` (top), `ROADMAP.md:3`, `LICENSE-MIT`/`LICENSE-APACHE`, `AGENTS.md` (clean-room rules) | implemented (status = pre-alpha) |
| 2 | 409 registered commands; every user action is a command (`CommandSpec`) | `docs/parity-checklist.md:7`, `crates/engine/src/cmd/mod.rs:61,167–207`, `docs/architecture.md` "Commands" | implemented |
| 3 | MCP server over stdio, headless or bridged; named tools & resources | `docs/mcp.md`, `crates/mcp/src/server.rs:119–126`, `crates/mcp/src/tests.rs:28,37–68` | implemented |
| 4 | JSON control channel `--control PORT` / `CADCRAFT_CONTROL_PORT`, method table incl. `ui.screenshot`, `ui.render`, `ui.pointer` | `docs/control-protocol.md`, `crates/ui-egui/src/control.rs:191–219` (METHODS), `apps/cadcraft/src/main.rs:228–259` | implemented |
| 5 | CLI: `info`, `convert`, `run`, `commands`, `sample`, `mcp`, `perf`, `--version` with exact flags | `apps/cadcraft-cli/src/main.rs:58–76` (usage), `:644–670` (dispatch), `:553–595` (mcp args) | implemented |
| 6 | DXF read: R12–2018 ASCII **and** binary, one reader, pre-2007 code pages | `crates/io/src/lib.rs:62–75`, `crates/io/src/dxf_read.rs`, `crates/dxf/src/codepage.rs`, `docs/file-format-parity.md:58–67` | implemented (R12 **binary** not read — docs note) |
| 7 | DXF write: 2000–2018 ASCII/binary, R2000 structure, `$ACADVER` set | `crates/io/src/lib.rs:86–107` (`write_with`), `docs/file-format-parity.md:64`, `crates/engine/src/cmd/file.rs:104–120` (`save_options`) | implemented |
| 8 | DWG read/write through the acadrust DXF bridge (R13+ read; 2000+ write, floor 2004) | `crates/dwg/src/lib.rs:3–11` (`is_dwg`, `Limits`, `VERSIONS`), `crates/io/src/lib.rs:97–103`, `docs/file-format-parity.md:30–56` | partial (synthetic tests only; R13 untested; write lossy) |
| 9 | DWG save drops unmodelled content and **reports it** (`notSaved` + command-line message) | `crates/engine/src/cmd/file.rs:500–558` (`not_saved`, `not_saved_message`, `drops_unknown`, `report_not_saved`) | implemented (reporting); dropping itself is the gap `docs/gaps.md` #1 |
| 10 | Export SVG/PNG/PDF; PNG 2400×1600 via CLI; framing (`--window`, `--view`) | `crates/io/src/lib.rs:113–135` (`write_framed`, PNG 2400×1600), `apps/cadcraft-cli/src/main.rs:88–164` (framing) | implemented |
| 11 | SVG/SVGZ import (shapes, paths, groups, Inkscape layers; no CSS/`use`/text/images/fills) | `crates/io/src/svg_read.rs`, `crates/io/src/lib.rs:69–74`, `docs/gaps.md` FF14, `docs/file-format-parity.md:120` | partial |
| 12 | AutoLISP: `.lsp`, APPLOAD, `(load)`, `defun c:`, `acad.lsp`/`acaddoc.lsp`; no vlax/DCL/reactors | `docs/autolisp.md`, `crates/engine/src/cmd/lisp.rs:12,18`, `docs/gaps.md` E1 | partial |
| 13 | Parametric constraints (geometric + dimensional + expressions) | `crates/constraints` (`docs/architecture.md` L2 row), `crates/engine/src/cmd/constraints.rs` | implemented (~50% parity per `ROADMAP.md`) |
| 14 | Layouts/viewports/plotting: PLOT, EXPORTPDF, PUBLISH, plot styles in own JSON | `crates/engine/src/cmd/layout.rs:74–95`, `crates/engine/src/cmd/plotters.rs:402–407`, `docs/plot-styles.md`, `docs/plotters.md` | implemented; binary `.ctb/.stb/.pc3` unread (`docs/gaps.md` F14) |
| 15 | Web build: same UI in WASM, no DWG, no autosave, download/upload + `?host=parent` bridge | `apps/cadcraft-web/src/main.rs:1–8`, `apps/cadcraft-web/src/host.rs`, `docs/gaps.md` F4/P1/FF12 | partial |
| 16 | Desktop autosave `.sv$` + Drawing Recovery + AUDIT/RECOVER | `crates/engine/src/autosave.rs:1–13`, `crates/engine/src/cmd/audit.rs:17–25`, `crates/ui-egui/src/autosave.rs` | implemented (desktop only) |
| 17 | No 3D: UCS, orbit, solids, surfaces, meshes, sections, rendering; `3DORBIT`/`ATTACH`/`SHARE` return "not available yet" | `docs/gaps.md` F24, `crates/engine/src/cmd/exchange.rs:57–70` | claimed/absent (explicitly unavailable) |
| 18 | Dynamic blocks: references read + visibility/lookup edits; authoring missing | `docs/gaps.md` F3, `docs/file-format-parity.md:96` | partial |
| 19 | SHX fonts not parsed (stroke font / `FONTALT` instead; metrics differ) | `README.md` Fonts, `docs/gaps.md` FF8, `crates/fonts` | claimed/absent (no SHX parser) |
| 20 | Ellipse/spline geometry tessellated; polyline offsets ignore bulges | `docs/gaps.md` top-10 row 3, `docs/geometry-parity.md` | partial |
| 21 | Keyboard shortcuts exactly as listed (Cmd+N/O/S/Shift+S/W/P, F3 osnap, F5 isoplane, F7 grid, F8 ortho, F9 snap, F10 polar, F11 tracking, F12 dynamic input, Cmd+1/3/8/9, F1, F2) | `crates/engine/src/cmd/settings.rs:20–51`, `edit.rs`, `file.rs`, `layout.rs:79–82`, `crates/ui-egui/src/menus.rs:17–74` | implemented |
| 22 | macOS packaging: `.app` contains GUI binary only; CLI in separate zip; signed/notarized | `packaging/macos/package.sh:102–167`, `README.md` Downloads (macOS table); verified bundle has no CLI | implemented |
| 23 | Never-crash discipline: panic guard around commands; no unwrap/expect/panic in production code | `crates/engine/src/guard.rs:1–11`, `AGENTS.md` "Never crash", crate-level `#![deny(...)]` headers | implemented |
| 24 | Xrefs: attach/bind/detach/reload; no XCLIP, no in-place xref edit | `crates/engine/src/cmd/blocks/xref.rs`, `docs/gaps.md` F2 | partial |
| 25 | Lossy-save "records could not be read" surfaced as `drawing.inspect` → `skipped`; CLI `convert` prints warning | `crates/engine/src/cmd/inquiry.rs:305`, `apps/cadcraft-cli/src/main.rs:283–291`, `crates/io/tests/skipped_records.rs` | implemented |
| 26 | 13 interface languages; engine/CLI/MCP messages stay English | `crates/ui-egui/src/i18n/*.tsv`, `docs/localization.md`, `docs/gaps.md` L1 | partial |
| 27 | No PR test CI (only packaging/lint/release workflows) | `docs/gaps.md` S1, `.github/workflows/` | claimed/absent |
| 28 | Menu breadth 280/491 (57%), generated 2026-10-12 | `docs/parity-checklist.md:5–8` | measured |

## Spot-check notes / uncertainties

- The SKILL's command/F-key shortcuts were taken from `CommandSpec.key(...)` values, not from a UI
  screenshot — the app was not launched, per the brief.
- `docs/architecture.md` says "295 engine commands … plus about 30 UI-only" (counted 2026-10-10);
  the newer generated checklist says **409 registered commands** (2026-10-12). The skill quotes the
  newer number and points at `cadcraft-cli commands` / `engine.commands` as the authoritative live
  source.
- `ROADMAP.md` (2026-10-10) is slightly behind `docs/gaps.md` (2026-10-13); where they disagree the
  skill prefers `docs/gaps.md` (e.g. block editor and autosave listed as "upcoming" in ROADMAP but
  landed per gaps rows F3/F4).
- Web-build defect "plot shows raw PDF bytes" (#134) is from `docs/gaps.md` S4/P1 and was not
  reproduced (no run); treat as reported-not-verified.
- No claim in the SKILL depends on the installed bundle beyond the version match (0.8.0) and the
  absence of a bundled CLI (`Contents/MacOS/` lists only `CADCraft`).

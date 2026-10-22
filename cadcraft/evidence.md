# Evidence table — CADCraft skill (v0.10.0)

Repo: `storytold/cadcraft` at tag `v0.10.0`, commit `e86eacf094fefda1cdb6ba5137a336f29deb5d99`
("Release 0.10.0"). The released CLI reports `cadcraft 0.10.0 (e86eacf094fefda1cdb6ba5137a336f29deb5d99)`.
Inspection was read-only: no build, no run, no GUI launch. Date: 2026-10-22.

Tier key: **implemented** = code path exists and is wired to a command/CLI/MCP surface; **partial**
= exists with documented gaps; **claimed/absent** = README/roadmap mention without a usable code path.

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Clean-room AutoCAD reimplementation, MIT OR Apache-2.0, stage pre-alpha (4 of 5 core workflows fail the alpha gate) | `README.md` (top, status badge), `ROADMAP.md` "Why pre-alpha", `docs/roadmap.md` "Alpha gate", `LICENSE-MIT`/`LICENSE-APACHE`, `AGENTS.md` (clean-room rules) | implemented (status = pre-alpha) |
| 2 | 427 registered commands; menu breadth 283/491 (58%); every user action is a command (`CommandSpec`) | `docs/parity-checklist.md:8` (generated 2026-10-16 by `cargo xtask parity`), 415 `CommandSpec::new(` sites in `crates/engine/src/cmd/` (counted 2026-10-22), `docs/architecture.md` "Commands" | implemented (live source: `cadcraft-cli commands`) |
| 3 | Scale: ~155k lines of Rust src in 12 crates + 3 apps (+ xtask 1.1k) | counted with `wc -l` on 2026-10-22: crates/src 150,002; apps/src 4,200; xtask 1,097 (`docs/architecture.md`'s "~57,000" predates this and is stale) | measured |
| 4 | MCP server over stdio, headless or bridged (`--connect [--lazy] [--launch]`, no silent headless fallback); tools `command_line, script, execute, list_commands, inspect_drawing, query_entities, render, find_text, new_drawing, open, save, cancel` + `screenshot/ui_inspect/ui_click` bridged; `shapes` via `execute`; resources `cadcraft://drawing`, `cadcraft://commands` | `docs/mcp.md`, `crates/mcp/src/tools.rs:9–40,113–136`, `crates/mcp/src/backend.rs:134–142` (`open -a CADCraft --args --control PORT`), `apps/cadcraft-cli/src/main.rs:575–602` (arg errors) | implemented |
| 5 | JSON control channel: 27 top-level methods (METHODS table incl. `ui.elements`, `ui.render`, `ui.set` with theme/animations/systemCursor/saveFormat/saveVersion/interfaceLanguage); limits 16 conns / 256 MiB / 60 s timeout (`not-run` vs `may-have-run`); `ui.dock`/`ui.dock.reset` and `entities {selected:true}` are commands, not top-level methods | `docs/control-protocol.md`, `crates/ui-egui/src/control.rs:191–219` (METHODS), `crates/ui-egui/tests/control_methods.rs` (keeps table in step) | implemented |
| 6 | CLI: `info`, `convert IN OUT.(dxf|dwg|svg|png|pdf)`, `run [FILE|--sample|--metric] [--script|--script-file|--cmd]… [--save|--export]`, `commands [FILTER]`, `sample (bracket|floorplan)`, `mcp`, `perf [N|FILE]`, `--version`; framing `--window`/`--view`; PNG 2400×1600, model space only | `apps/cadcraft-cli/src/main.rs:57–77` (USAGE), `:113–135` (`write_framed` png 2400×1600), `:328–345` (run flags), `:670–690` (dispatch) | implemented |
| 7 | DXF read: R12–2018 ASCII (no version gating) + binary R13+; pre-2007 `$DWGCODEPAGE` decode; R12 binary not read | `crates/io/src/lib.rs:62–77` (`read()`), `docs/file-format-parity.md` DXF table (R12 binary row) | implemented (R12 binary absent) |
| 8 | DXF write 2000–2018 ASCII/binary (default = file's `$ACADVER`, else 2018); DWG write 2000+ (floor 2004 unless 2000 asked); DWT via SAVEAS; NEW/QNEW from `.dwt`/`.dxf` | `crates/io/src/lib.rs:79–110` (`write_with`, floor-2004 comment), `docs/file-format-parity.md` FF3 row + "Other formats" DWT row | implemented |
| 9 | DWG read via acadrust 0.6.4 bridge (magic `AC10xx` = R13+; 2000–2018 in `VERSIONS`; R13/R14 untested; DGN line-style leftovers skipped on read) | `crates/dwg/src/lib.rs:12–20`, `crates/dwg/Cargo.toml:13`, `docs/file-format-parity.md` DWG table, FF row "#1482" | partial (synthetic tests only) |
| 10 | DXF round-trips unmodelled content raw since #528; DWG still drops custom-class entities/objects, xdata on table records/blocks, entity colour books, reactors; SAVE/SAVEAS report it (`notSaved` + message) | `docs/gaps.md` rows 1–2, FF1; `docs/file-format-parity.md` "Foreign xdata…" row; `crates/engine/src/cmd/file.rs:491–515` (`not_saved_as`, `drops_unknown`, `report_not_saved`) | implemented (reporting); DWG loss is the open gap |
| 11 | Export SVG/PNG/PDF (embedded TrueType subsets, OCG layers, multi-sheet, hyperlinks, plotted transparency); EXPORT/EXPORTPDF/PUBLISH/PDFBOOK; `preview` (Plot Preview) | `crates/io/src/lib.rs:113–135`, `crates/engine/src/cmd/exchange.rs:30–67` (`import`, `export`, `preview`, `publish`, `pdfbook` specs), `docs/file-format-parity.md` PDF row (#567/#571) | implemented |
| 12 | SVG/SVGZ import (shapes, paths, groups, Inkscape layers; no CSS/`use`/fills/text/images; omissions named on open) | `crates/io/src/svg_read.rs`, `docs/gaps.md` FF14 | partial |
| 13 | AutoLISP: `.lsp`, APPLOAD/`(load)`/`lisp`/`appload` JSON, `defun c:`, startup files + `S::STARTUP`/`autoload`, `entget/entmake/entmod`, `ssget` filters, `vl-*` functions; no vlax/vla, DCL, reactors | `docs/autolisp.md` (full function list), `crates/engine/src/cmd/lisp.rs:12,18`, `docs/gaps.md` E1 | partial |
| 14 | Block Editor (BEDIT/BSAVE/BCLOSE) for static blocks; REFEDIT/REFSET/REFCLOSE edit block references in place (not xrefs); XCLIP missing; dynamic-block references read with visibility/lookup edits, no authoring | `crates/engine/src/cmd/blocks/bedit.rs:16`, `crates/engine/src/cmd/blocks/refedit.rs:35`, `docs/gaps.md` F2, F3 (both narrowed for these landings) | partial |
| 15 | Precision incl. object snap tracking, extension/parallel snaps, typed overrides, FROM/M2P/TK (newer `docs/gaps.md`/revision log supersede the stale `docs/roadmap.md` prose that calls them toggles) | `crates/engine/src/snap/tracking.rs`, `crates/engine/src/pointmod.rs:80,325`, `crates/engine/src/cmd/settings.rs:45` (`otrack` F11), `docs/gaps.md` revision 2026-10-11 (#379) | implemented (U4 leftovers remain) |
| 16 | Express Tools NCOPY/BREAKLINE/TXT2MTXT/BURST/MOCORO; ALIASEDIT/REINIT `.pgp`; SCRIPT reads `.scr`; COMPARE + QuickCalc | `crates/engine/src/cmd/modify2.rs:61,65`, `cmd/draw2/breakline.rs:21`, `cmd/txt2mtxt.rs:20`, `cmd/blocks/burst.rs:14`, `cmd/file/pgp.rs:195,200`, `cmd/file.rs:178` (`script`), `cmd/file/compare.rs:63–73`, `docs/gaps.md` E3, E5 | implemented |
| 17 | Plot styles (CTB/STB) and plotter devices in CADCraft's own JSON; binary `.ctb/.stb/.pc3/.pmp` unread; no system printers | `docs/plot-styles.md`, `docs/plotters.md`, `docs/gaps.md` F14, FF9, H3 | partial |
| 18 | 16 interface languages incl. Hungarian, Turkish, Greek; `ui.language` values; engine/CLI/MCP messages stay English; fonts must be installed for CJK/Arabic/Hangul | `crates/ui-egui/src/i18n/mod.rs:176–213` (catalog list), `docs/localization.md` (supported values incl. `tr`, `el`), `docs/gaps.md` L1 | partial |
| 19 | No 3D; `3DORBIT`/`ATTACH`/`SHARE` return "not available yet"; no PDF import/underlays, no raster display, no DWF/DGN/WMF/EPS/ACIS/STL/DWS | `docs/gaps.md` F24, FF10, FF11, `crates/engine/src/cmd/exchange.rs:55–70`, `docs/file-format-parity.md` "Other formats" | claimed/absent (explicitly unavailable) |
| 20 | Keyboard shortcuts exactly as listed (Cmd+N/O/S/Shift+S/W/P, Cmd+Z/Shift+Z, Cmd+C/V/X, Cmd+Shift+C/V, Cmd+A, Cmd+Shift+A PICKSTYLE, Delete, F3/F5/F7/F8/F9/F10/F11/F12; UI: Cmd+1/3/8/9, F1, F2, Cmd+Q) | `crates/engine/src/cmd/settings.rs:15–95`, `cmd/edit.rs:15–59`, `cmd/file.rs:153–175`, `cmd/layout.rs:81`, `cmd/groups/pick.rs:16`, `crates/ui-egui/src/menus.rs:17–80` (UI_COMMANDS) | implemented |
| 21 | macOS packaging: `.app` holds only the GUI binary; CLI is a separate signed/notarized zip | `packaging/macos/package.sh:100–113` (`cp "$WORK/bin/cadcraft" "$APP/Contents/MacOS/CADCraft"` only; `CLI_ZIP` at :44), `README.md` Downloads | implemented |
| 22 | Never-crash discipline: panic guard around commands; input-sized allocation caps | `crates/engine/src/guard.rs`, `docs/architecture.md` "Safety", crate-level `#![deny(...)]` headers | implemented |
| 23 | Desktop autosave `.sv$` DXF + Drawing Recovery + AUDIT/RECOVER + AUDITCTL `.adt` log; none in the web build | `crates/engine/src/autosave.rs:24–25` (`EXT: "sv$"`), `crates/engine/src/cmd/audit.rs:143–146` (`with_extension("adt")`), `docs/gaps.md` F4 | implemented (desktop only) |
| 24 | `drawing.inspect` `skipped` count; refused command lines still reply `ok:true` with `error` | `crates/engine/src/cmd/inquiry.rs:408`, `docs/control-protocol.md` "Command-line replies" | implemented |
| 25 | Web build: same UI, no DWG, no autosave, `?webgl`/`?cpu`/`?sample`, `?host=parent` iframe bridge; plot-raw-PDF-bytes bug (#134) reported not reproduced | `apps/cadcraft-web/src/main.rs:4–9,90–130`, `docs/gaps.md` P1, S4 | partial |
| 26 | Finder `.dxf` association broken (#158); no PR test CI (S1); 10 MB DWG ~2 min (#57); SETVAR ~150 of ~1,000 vars (U10) | `docs/gaps.md` P3/U13, S1, FF6, U10 | claimed/absent (documented gaps) |

## Spot-check notes / uncertainties

- Numbers recomputed for this pin: **427 commands** and **283/491 (58%)** from the generated
  parity checklist (2026-10-15/16); the old skill's 409 / 280/491 (57%) are superseded. `ROADMAP.md`
  still shows the older 245/491 (50%) from 2026-10-10 — the generated checklist is newer and is
  the one quoted.
- `docs/architecture.md`'s line counts (~57k) and command count (295) date from 2026-10-10 and are
  stale; the skill quotes the 2026-10-22 `wc -l` recount and the generated checklist instead.
- `docs/roadmap.md` (updated 2026-10-12) still says object snap tracking/extension/parallel are
  "toggles with no behaviour"; `docs/gaps.md`'s 2026-10-11 revision (#379) and the code
  (`snap/tracking.rs`, `pointmod.rs`) show they landed. The skill follows `docs/gaps.md` + code.
- `docs/control-protocol.md`'s `ui.language` value list omits `tr`/`el`; `docs/localization.md`
  (newer) and `crates/ui-egui/src/i18n/mod.rs` include them — the skill follows those.
- Uncertain (static reading only, no run): README's interactive-feel claims, "every arrowhead",
  associative-dimension behaviour, MTEXT bidi/OpenType shaping, per-language font availability,
  web plot-raw-PDF-bytes (#134), Windows/Linux robustness. All are labeled claimed-but-unverified
  in the SKILL.
- No claim in the SKILL depends on the installed bundle beyond the released CLI version string;
  the bundle was not opened and the stale Info.plist version was not used.

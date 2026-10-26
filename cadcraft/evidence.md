# Evidence table — CADCraft skill (v0.13.0)

Repo: `storytold/cadcraft` at tag `v0.13.0`, commit `1fcf654ea8414ea2ef052ca2b3b77411f2026f78`
("Release 0.13.0", 2026-10-25). The installed `/Applications/CADCraft.app` reports
`CFBundleShortVersionString` 0.13.0 / `ai.storyteller.cadcraft`, and its binary prints
`cadcraft 0.13.0 (1fcf654ea8414ea2ef052ca2b3b77411f2026f78)` — the bundle matches this checkout.
Inspection was read-only: no build, no GUI launch, no drawing modified; the only execution was
`/Applications/CADCraft.app/Contents/MacOS/CADCraft --version`. Date: 2026-10-26.

Tier key: **implemented** = code path exists and is wired to a command/CLI/MCP/control surface;
**partial** = exists with documented gaps; **claimed/absent** = README/roadmap mention without a
usable code path, or explicitly unavailable.

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Tag v0.13.0 at commit `1fcf654…`; installed bundle reports 0.13.0 and the same SHA; pre-alpha, MIT OR Apache-2.0, clean-room AutoCAD 2027 target | `git rev-parse HEAD` / `git describe --tags`; `/Applications/CADCraft.app/Contents/Info.plist`; binary `--version`; `ROADMAP.md:3`; `Cargo.toml`; `AGENTS.md`; `docs/target-app-parity.md` | implemented (status = pre-alpha) |
| 2 | 441 engine commands; 57 UI-only commands (498 app catalog); menu breadth 296/491 (60%), 195 items uncovered; ids are lower-case AutoCAD names | `docs/parity-checklist.md:7`; `crates/engine/src/cmd/mod.rs:171`; `crates/ui-egui/src/menus.rs:17`; `crates/ui-egui/src/control.rs:225` | implemented (live catalog) |
| 3 | 425 static `CommandSpec::new(` sites; the 441 registry count comes from 2 macro-body sites + 18 `gc!`/`dc!` invocations (425 − 2 + 18 = 441) | `grep -r "CommandSpec::new(" crates apps`; `crates/engine/src/cmd/constraints.rs:20-35` (macro bodies), `:38-105` (12 `gc!`, 6 `dc!`); `xtask/src/parity.rs:71-110` (counts live `cadcraft-cli commands`) | implemented (both numbers verified) |
| 4 | MCP over stdio: 15 tools (12 headless + `screenshot`/`ui_inspect`/`ui_click` app-only), resources `cadcraft://drawing`/`cadcraft://commands`, `--connect [--lazy] [--launch]`, no silent headless fallback | `crates/mcp/src/tools.rs:9-44`; `crates/mcp/src/server.rs:119-126`; `crates/mcp/src/backend.rs:129-142`; `apps/cadcraft-cli/src/main.rs:730-760`; `docs/mcp.md` | implemented |
| 5 | Control channel 27 app methods / 12 headless; **every request needs a per-session `token`** (owner-only file `cadcraft-control-<port>.token`); 16 connections, 64 queued, 256 MiB/line, 60 s reply timeout (`not-run`/`may-have-run`), 10 min idle, 30 s write timeout | `crates/ui-egui/src/control.rs:191-219`; `crates/mcp/src/backend.rs:251-263`; `crates/mcp/src/control_token.rs:22`; `apps/cadcraft/src/control_server.rs:22-47`; `docs/control-protocol.md` | implemented |
| 6 | CLI has 7 verbs (`info`, `convert`, `run`, `commands`, `mcp`, `perf`, `sample`) plus `--version`; framing `--window`/`--view` (image output only); `--cmd` `{last}` handle chaining; PNG 2400×1600; CLI images always model space | `apps/cadcraft-cli/src/main.rs:66-92`; `crates/io/src/lib.rs:113` | implemented |
| 7 | DXF read R12–2018 ASCII + binary R13+ (R12 binary not read), code-page decode; DXF write 2000–2018 ASCII/binary, default file `$ACADVER` else 2018, binary stays binary | `crates/io/src/lib.rs:62`; `crates/io/src/dxf_read.rs`; `crates/dxf/src/lib.rs:346-350`; `crates/dxf/src/version.rs:7-20`; `crates/dxf/src/codepage.rs`; `docs/file-format-parity.md` DXF table | implemented |
| 8 | DWG read/write 2000–2018 through `acadrust` 0.6.5 (MPL-2.0, unmodified); magic `AC10xx`; pre-R13 not read; R13/R14 untested; DWG write floor 2004 unless 2000 asked; 512 MB/1 GB size limits | `crates/dwg/Cargo.toml` (`acadrust = "0.6.5"`); `crates/dwg/src/lib.rs:30`; `crates/io/src/lib.rs:86-101`; `docs/file-format-parity.md` DWG table | partial (synthetic tests only) |
| 9 | Unknown DXF content round-trips raw; DWG drops custom-class entities/objects, xdata on table records/blocks, colour books, reactors; SAVE/SAVEAS report `notSaved` + message, and the CLI prints it on stderr for `.dwg`/`.dwt` | `crates/io/src/dxf_raw.rs`; `crates/engine/src/cmd/file.rs:517-575`; `apps/cadcraft-cli/src/main.rs:236-244`; `docs/gaps.md` top-10 row 1, FF1 | implemented (reporting); DWG loss is the open gap |
| 10 | SVG/SVGZ import: shapes, paths, groups, Inkscape layers; geometry in mm, page top-left at origin, Y up; no CSS/use/fills/gradients/patterns/text/images/`rx`,`ry`; all but fills/gradients/patterns named in a read note; 64 MiB decompression guard | `crates/io/src/svg_read.rs:1-15`; `crates/io/src/lib.rs:62-71`; `docs/gaps.md` FF14 | partial |
| 11 | Export SVG, PNG 2400×1600, vector PDF (TrueType subsets, OCG layers, multi-sheet, hyperlinks, transparency); EXPORT/PUBLISH/PDFBOOK return base64 when no path; image export warns about undrawn proxy entities | `crates/io/src/lib.rs:113-135`; `crates/io/src/pdf.rs`; `crates/engine/src/cmd/exchange.rs:38-55`; `crates/engine/src/cmd/layout.rs:79-88`; `apps/cadcraft-cli/src/main.rs:297-330` | implemented |
| 12 | Import DXF/DWG objects (`path` or base64 `data`, `at`, `scale`); `.lin`/`.pat`/`.pgp` user files; `.scr` scripts; AutoLISP `lisp`/`appload` with `.lsp` file browser, `acad.lsp`/`acaddoc.lsp`/`S::STARTUP`; no Visual LISP/DCL/reactors/Startup Suite | `crates/engine/src/cmd/exchange.rs:34`; `crates/engine/src/cmd/props/linfile.rs`; `crates/engine/src/cmd/hatch/patfile.rs`; `crates/engine/src/cmd/file/pgp.rs`; `crates/engine/src/cmd/lisp.rs:12-22`; `apps/cadcraft/src/main.rs:146-152` (`pick_lisp`); `docs/autolisp.md`; `docs/gaps.md` E1 | implemented (AutoLISP partial vs AutoCAD) |
| 13 | Draw/modify command breadth (LINE…HELIX; ERASE…MOCORO; associative arrays, OVERKILL, draw order, Express Tools) | `crates/engine/src/cmd/draw.rs`, `crates/engine/src/cmd/draw2.rs`, `crates/engine/src/cmd/modify.rs`, `crates/engine/src/cmd/modify2.rs`, `crates/engine/src/cmd/array.rs`/`crates/engine/src/cmd/array/`, `crates/engine/src/cmd/overkill.rs`, `crates/engine/src/cmd/draworder.rs`, `crates/engine/src/cmd/draw2/breakline.rs`, `crates/engine/src/cmd/txt2mtxt.rs`, `crates/engine/src/cmd/blocks/burst.rs` | implemented |
| 14 | 14 object snaps, deferred tangent/perpendicular, object snap tracking, polar/ortho (Shift inverts), grid snap, direct distance entry, FROM/M2P/TK, hot grips | `crates/engine/src/snap.rs:34`; `crates/engine/src/snap/tracking.rs`; `crates/engine/src/pointmod.rs`; `crates/engine/src/cmd/griphot.rs`; `docs/gaps.md` U4 leftovers | implemented (U4 leftovers remain) |
| 15 | DIM* family incl. DIMTFILL/DIMTFILLCLR, MLEADER family, TABLE, TOLERANCE, annotative scaling, MTEXT editor, COMPARE + COMPAREEXPORT; TEXTEDIT/DDEDIT replaces text by handle | `crates/engine/src/cmd/annotate*.rs`; `crates/engine/src/cmd/mleader*.rs`; `crates/engine/src/cmd/table/`; `crates/engine/src/cmd/tolerance.rs`; `crates/engine/src/cmd/annoscale.rs`; `crates/engine/src/cmd/file/compare/export.rs:43`; `crates/engine/src/cmd/modify2.rs:81`; `docs/gaps.md` F7–F12, revision 2026-10-24/25 | implemented (F9 MTEXT/field/spell gaps) |
| 16 | Hatch with 23 standard patterns/gradients/HATCHEDIT; BLOCK/INSERT/attributes/groups/WBLOCK/PURGE; xrefs; BEDIT/BSAVE/BCLOSE; REFEDIT/REFSET/REFCLOSE; dynamic-block reference edits and grips; no XCLIP/xref in-place/dynamic-block authoring | `crates/doc/src/library.rs:100-240` (23 patterns); `crates/engine/src/cmd/hatch/`; `crates/engine/src/cmd/blocks/` (`crates/engine/src/cmd/blocks/bedit.rs`, `crates/engine/src/cmd/blocks/refedit.rs:117`, `crates/engine/src/cmd/blocks/dyngrip.rs`, `crates/engine/src/cmd/blocks/xref/`); `docs/gaps.md` F2, F3, F13 | partial |
| 17 | Layouts, viewports (polygonal/object/clipped, VPCLIP/VPLAYER), MSPACE/PSPACE, page setups, PLOT dialog, preview, EXPORTPDF, PUBLISH, PDFBOOK, JSON plot styles/plotters | `crates/engine/src/cmd/layout.rs`, `crates/engine/src/cmd/layout/`, `crates/engine/src/cmd/plotters.rs`, `crates/engine/src/cmd/exchange.rs:43-55`; `docs/plot-styles.md`; `docs/plotters.md`; `docs/gaps.md` F14 | implemented (binary CTB/STB/PC3 unread) |
| 18 | 16 interface languages incl. Greek/Turkish; live switch via `ui.language`, `ui.set interfaceLanguage`, `CADCRAFT_LOCALE`; engine/CLI/MCP messages English; web build same UI but no DWG/autosave, downloads, URL flags; SpaceMouse motion Windows/Linux only | `crates/ui-egui/src/i18n/mod.rs:190`; `docs/localization.md`; `docs/gaps.md` L1; `apps/cadcraft-web/src/main.rs:1-9`; `apps/cadcraft/src/spacemouse.rs`; `docs/hardware-parity.md` | partial |
| 19 | Accessibility: system-cursor option (`ui.set systemCursor`, `CADCRAFT_SYSTEM_CURSOR=1`), animation effects following the OS with `ui.set animations` and `ui.inspect.animations` | `README.md` §Accessibility; `crates/ui-egui/src/options/mod.rs:12`; `crates/ui-egui/src/control.rs:261`; `crates/ui-egui/src/menus.rs:32-36` | implemented |
| 20 | Desktop autosave `.sv$` DXF (SAVETIME 10 default/0 off/600 max, SAVEFILEPATH), Drawing Recovery, AUDIT/RECOVER, AUDITCTL=1 `.adt` logs; panic guard restores the drawing; no web autosave | `crates/engine/src/autosave.rs:24-31`; `crates/engine/src/cmd/audit.rs:13-23`; `crates/engine/src/guard.rs`; `docs/gaps.md` F4 | implemented (desktop only) |
| 21 | Agent read-back commands: `drawing.inspect` (`skipped{count,sections}`), `entities`, `texts`, `shapes` (with `selfCheck`), `usage`, `loops`, `countlist`/`counttable`/`count`, `properties`, `list`, `dist`, `id`, `area` | `crates/engine/src/cmd/inquiry.rs:20-70`; `crates/engine/src/cmd/inquiry/shapes.rs`; `crates/engine/src/cmd/inquiry/loops.rs`; `crates/engine/src/cmd/inquiry/usage.rs` | implemented |
| 22 | Limitations: lossy DWG / no real-file corpus / no AutoCAD check; no 3D (3DORBIT/ATTACH/SHARE refuse); tessellated ellipse/spline; absolute tolerances; XCLIP/xref-in-place/dynamic-block authoring absent; no SHX/PDF import/raster/DWF/DGN/ACIS/STL/DWS/system printers; binary plot files unread; MTEXT fields/spell gaps; ~150/1,000 SETVAR; no Sheet Set/eTransmit/Traces/CUI; Finder `.dxf` association broken; no plug-in API (ObjectARX/.NET); PR-gate row S1 stale against `.github/workflows/ci.yml`; web PDF-bytes bug | `docs/gaps.md` rows 1–3, F2–F4, F7–F9, F14, F23, U10/U12/U13, FF1–FF14, S1/S4, H3, P3, E4; `crates/engine/src/cmd/exchange.rs:56-70`; `docs/geometry-parity.md`; `docs/file-format-parity.md`; `docs/customization.md`; `.github/workflows/ci.yml` | claimed/absent or partial as labelled |

## Automation-surface counts, re-measured at v0.13.0

| Surface | Count | How measured |
|---|---|---|
| Registered engine commands | **441** | `docs/parity-checklist.md:7` (generated 2026-10-25 by `cargo xtask parity`, which counts live `cadcraft-cli commands` output — `xtask/src/parity.rs:71-110`) |
| Static `CommandSpec::new(` call sites | **425** | `grep -rn "CommandSpec::new(" --include=*.rs crates apps \| wc -l` (58 files) |
| Reconciliation | 425 − 2 macro-body sites + 18 macro invocations (`gc!` 12, `dc!` 6) = **441** | `crates/engine/src/cmd/constraints.rs:20-35`; grep counts `^        gc!(` = 12, `^        dc!(` = 6 |
| UI-only commands | **57** | `crates/ui-egui/src/menus.rs:17-74` (`awk` row count inside `UI_COMMANDS`) |
| Desktop app catalog | **498** = 441 + 57 | `crates/ui-egui/src/control.rs:225` `all_commands` |
| Menu breadth / reference items | **296 / 491 (60%)**, 195 uncovered | `docs/parity-checklist.md:7`; leaf count of `xtask/data/menu-catalog.txt` = 491 (re-counted) |
| MCP tools | **15** (12 headless + 3 app-only) | `crates/mcp/src/tools.rs` — 15 `json!({"name": …})` entries, the last 3 inside the `has_ui` branch |
| Control methods | **27** app / **12** headless | `crates/ui-egui/src/control.rs:191-219` (27 table rows); `crates/mcp/src/backend.rs:251-263` (12) |
| CLI verbs | **7** | `apps/cadcraft-cli/src/main.rs:66-92` |
| Hatch patterns / object snaps / languages | **23 / 14 / 16** | `crates/doc/src/library.rs:100` (`standard_patterns`); `crates/engine/src/snap.rs:34`; `crates/ui-egui/src/i18n/mod.rs:190` |
| Rust scale | ≈162,600 lines outside `*/tests/` (206,998 with tests) in 12 crates + 3 apps + `xtask` | `find … -name "*.rs" \| xargs wc -l` |

## What changed since v0.11.0 (measured here, not copied from v0.11.0)

- **Commands 427 → 441** (+14), **menu breadth 283/491 (58%) → 296/491 (60%)**, static sites
  415 → 425, **UI-only commands 56 → 57**. The parity checklist was regenerated 2026-10-25 (the day the tag was
  cut), against 2026-10-15/16 for the v0.11.0-era file (`docs/parity-checklist.md:3`).
- **`acadrust` 0.6.4 → 0.6.5** (`crates/dwg/Cargo.toml`); the v0.11.0 manifest pinned 0.6.4.
- **New command: `COMPAREEXPORT`** — a comparison exported as a new untitled drawing with the two
  object groups (`crates/engine/src/cmd/file/compare/export.rs:43`; `docs/gaps.md` revision
  2026-10-24, `docs/target-app-parity.md` same date).
- **New: DIMTFILL / DIMTFILLCLR** dimension text backgrounds, DIMSTYLE groups 69/70 from R2007,
  a SOLID in the `*D` block for DIMTFILL 2 (`crates/io/tests/it/dimtfill_roundtrip.rs:1-3`;
  `docs/gaps.md` revision 2026-10-24/25).
- **Control-channel authentication token** now required on every request (absent from the v0.11.0
  skill's protocol description); the MCP bridge reads it automatically
  (`crates/mcp/src/control_token.rs`, `docs/control-protocol.md`).
- **APPLOAD `.lsp` file browser** (`apps/cadcraft/src/main.rs:146-152`; `docs/gaps.md` revision
  2026-10-22, `#1820`).
- **Unchanged**: MCP tools 15 (12 headless + 3), control methods 27 app / 12 headless, CLI verbs 7,
  shortcut set, read/write version ranges, PNG 2400×1600, 23 hatch patterns, 14 snaps, 16 languages.

## Spot-check notes / uncertainties

- **425 vs 441 is not a stale doc.** Earlier versions of this skill noted the grep count (415) was
  lower than the generated count (427) without explaining the gap. The mechanism is now verified
  exactly: two `CommandSpec::new(` occurrences live in the `gc!`/`dc!` macro bodies and 18 macro
  invocations expand to 18 specs. Do not "reconcile" the numbers by editing either one; the
  generated 441 is the registry, the 425 is the grep.
- **Stale numbers elsewhere.** `ROADMAP.md:22` still says 245/491 (50%; measured 2026-10-10 and
  mixing UI-only commands into the count, so not comparable with the engine-only 296/491);
  `docs/architecture.md:11` still says "about 57,000 lines … counted 2026-10-10" and lists three
  interface languages; `docs/target-app-parity.md` (2026-10-24) did not re-measure its
  percentages. Use the generated checklist and this recount.
- **acadrust version drift.** `docs/file-format-parity.md:34` says acadrust 0.6.3;
  `crates/dwg/Cargo.toml` pins 0.6.5. The SKILL quotes the manifest.
- **README lags code.** It calls the app "2D and 3D" (no 3D, `docs/gaps.md` F24), says DXF save
  "R2000" and "SVG and PNG" export (code writes DXF/DWG 2000–2018, SVG, PNG and PDF), and lists 15
  interface languages while the code has 16 incl. Greek (`crates/ui-egui/src/i18n/mod.rs:190`).
- **`docs/mcp.md` lists the `shapes` row twice** and mixes three `execute {"command": …}` rows into
  the tool table; the tool count is 15, from `crates/mcp/src/tools.rs`, not from that table.
- **Corrected: PR CI exists.** `docs/gaps.md` S1 says "No CI runs `cargo xtask ci` on pull requests
  (only packaging lint and release builds)", and the v0.11.0 skill repeated it. At this tag
  `.github/workflows/ci.yml` triggers on `pull_request` and pushes to `main` and calls the suite's
  shared `gate.yml@main` from `storytold/craft-common-actions`, whose header comment names
  `cargo xtask ci`; `.github/workflows/sonarcloud.yml` also runs on PRs. The shared gate itself is
  outside this repo and was not inspected, so the SKILL says the gate's pass status is uncertain
  rather than repeating S1. Absence of the gate cannot be claimed any more.
- **Correction carried forward.** `docs/gaps.md` F9 still says existing MTEXT cannot be edited (no
  DDEDIT/MTEDIT), but `TEXTEDIT` exists with alias `DDEDIT` (`crates/engine/src/cmd/modify2.rs:81`) and replaces
  TEXT/MTEXT/ATTDEF/dimension text by handle. What is missing is the in-place formatting editor,
  fields and spell check — the SKILL says that rather than repeating "no DDEDIT".
- **Uncertain — UI-only command identity.** The count is 57 (baseline documented 56) but which
  entry was added cannot be established at this tag: the clone is a single grafted commit
  (`git log` shows one commit, one tag) so there is no v0.11.0 history to diff, and the only new
  UI surface visible in the code is the accessibility block (`View ▸ Accessibility`:
  `ui.toggle.systemcursor`, `ui.animations*`). See `crates/ui-egui/src/menus.rs:17-74`.
- **Uncertain — landing release of `usage` and `loops`.** Both exist as engine commands
  (`crates/engine/src/cmd/inquiry.rs:54-55`) and are documented in `docs/mcp.md`, but the v0.11.0
  skill did not list them and no dated `docs/gaps.md` entry records their landing. Treated as
  present, not as "new".
- **Uncertain — landing release of the control token.** It is required at this tag
  (`apps/cadcraft/src/control_server.rs:229`, `docs/control-protocol.md:12-17`) and the v0.11.0
  skill documented no token, but no dated note records when it landed. Any client written from the
  older skill must add the token; the SKILL says this as a present-tense requirement.
- **Not runtime-tested.** No build or live GUI session was possible under the read-only rule.
  Claims about interactive feel (AutoComplete, right-click repeat, hot grips), associative
  dimensions, "every arrowhead", MTEXT bidi/OpenType shaping, per-language font availability,
  SpaceMouse behaviour on Windows/Linux and acadrust's R13/R14 reads are code/docs claims, labelled
  as such. The installed bundle was used only for `--version`.
- **CLI availability.** `cadcraft-cli` is not on `PATH` on this host and is not inside the `.app`
  (`packaging/macos/package.sh:43-44` puts the GUI binary in the bundle and the CLI in a
  separate signed zip). Agents must install that zip or go through MCP/control in the app.

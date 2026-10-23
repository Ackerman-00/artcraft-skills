# Evidence table — CADCraft skill (v0.11.0)

Repo: `storytold/cadcraft` at tag `v0.11.0`, commit `8f988f630dd63ce5d9c997f5ef28a09dd1bdfcde`
("Release 0.11.0", 2026-10-22). The installed `/Applications/CADCraft.app` reports
`CFBundleShortVersionString` 0.11.0 / `ai.storyteller.cadcraft`, and its binary prints
`cadcraft 0.11.0 (8f988f630dd63ce5d9c997f5ef28a09dd1bdfcde)` — the bundle matches this checkout.
Inspection was read-only: no build, no GUI launch, no drawing modified; the only execution was
`/Applications/CADCraft.app/Contents/MacOS/CADCraft --version`. Date: 2026-10-23.

Tier key: **implemented** = code path exists and is wired to a command/CLI/MCP/control surface;
**partial** = exists with documented gaps; **claimed/absent** = README/roadmap mention without a
usable code path, or explicitly unavailable.

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Tag v0.11.0 at commit `8f988f6…`; installed bundle reports 0.11.0 and the same SHA; pre-alpha, MIT OR Apache-2.0, clean-room AutoCAD target | `git rev-parse HEAD` / `git describe --tags`; `/Applications/CADCraft.app/Contents/Info.plist`; binary `--version`; `ROADMAP.md`; `Cargo.toml`; `AGENTS.md`; `docs/target-app-parity.md` | implemented (status = pre-alpha) |
| 2 | 427 engine commands, 56 UI-only commands (483 app catalog), menu breadth 283/491 (58%); ids are lower-case AutoCAD names | `docs/parity-checklist.md:8`; `crates/engine/src/cmd/mod.rs:170`; `crates/ui-egui/src/menus.rs:17`; `crates/ui-egui/src/control.rs:225`; `cadcraft-cli commands` | implemented (live catalog) |
| 3 | MCP over stdio: 15 tools (12 headless + `screenshot`/`ui_inspect`/`ui_click` app-only), resources `cadcraft://drawing`/`cadcraft://commands`, `--connect [--lazy] [--launch]`, no silent headless fallback | `crates/mcp/src/tools.rs:7-41,151-199`; `crates/mcp/src/server.rs:118-126`; `crates/mcp/src/backend.rs:129-142`; `apps/cadcraft-cli/src/main.rs:575-602`; `docs/mcp.md` | implemented |
| 4 | Control channel 27 app methods / 12 headless; 16 connections, 64 queued, 256 MiB/line, 60 s reply timeout (`not-run`/`may-have-run`), 10 min idle; docking and `entities selected:true` via `engine.execute` | `crates/ui-egui/src/control.rs:191-219`; `apps/cadcraft/src/control_server.rs:22-46`; `crates/mcp/src/backend.rs:198-213`; `docs/control-protocol.md` | implemented |
| 5 | CLI has 7 verbs (`info`, `convert`, `run`, `commands`, `mcp`, `perf`, `sample`) plus `--version`/`--help`; framing `--window`/`--view`; PNG 2400×1600; CLI images always model space | `apps/cadcraft-cli/src/main.rs:58-77,670-710`; `crates/io/src/lib.rs:113-135` | implemented |
| 6 | DXF read R12–2018 ASCII + binary R13+ (R12 binary not read), code-page decode; DXF write 2000–2018 ASCII/binary, default file `$ACADVER` else 2018, binary stays binary | `crates/io/src/lib.rs:57-110`; `crates/io/src/dxf_read.rs`; `crates/dxf/src/version.rs`; `crates/dxf/src/codepage.rs`; `crates/engine/src/cmd/file.rs:297,376`; `docs/file-format-parity.md` DXF table | implemented |
| 7 | DWG read/write R13–2018 through `acadrust` 0.6.4 (MPL-2.0, unmodified); magic `AC10xx`; pre-R13 not read; R13/R14 untested; DWG write floor 2004 unless 2000 asked | `crates/dwg/src/lib.rs:11,16`; `crates/dwg/Cargo.toml`; `crates/io/src/lib.rs:79-110`; `docs/file-format-parity.md` DWG table | partial (synthetic tests only) |
| 8 | Unknown DXF content round-trips raw; DWG drops custom-class entities/objects, xdata on table records/blocks, colour books, reactors; SAVE/SAVEAS report `notSaved` + message | `crates/io/src/dxf_raw.rs`; `crates/engine/src/cmd/file.rs:504-575`; `docs/gaps.md` row 1, FF1; `docs/file-format-parity.md` foreign-data row | implemented (reporting); DWG loss is the open gap |
| 9 | SVG/SVGZ import: shapes, paths, groups, Inkscape layers; geometry in mm, page top-left at origin, Y up; no CSS/use/fills/text/images (`use`, text and images are noted on open; fills/gradients/patterns are silently ignored) | `crates/io/src/svg_read.rs` module docs; `docs/gaps.md` FF14; `crates/io/src/lib.rs:57-68` | partial |
| 10 | Export SVG, PNG 2400×1600, vector PDF (TrueType subsets, OCG layers, multi-sheet, hyperlinks, transparency); commands EXPORT/EXPORTPDF/PLOT/PREVIEW/PUBLISH/PDFBOOK | `crates/io/src/lib.rs:113-135`; `crates/io/src/pdf.rs`; `crates/engine/src/cmd/exchange.rs:30-67`; `crates/engine/src/cmd/layout.rs:79-88`; `docs/file-format-parity.md` PDF row | implemented |
| 11 | Import DXF/DWG objects; `.lin`/`.pat`/`.pgp` user files; `.scr` scripts; AutoLISP `lisp`/`appload`, `acad.lsp`/`acaddoc.lsp`/`S::STARTUP`; no Visual LISP/DCL/reactors | `crates/engine/src/cmd/exchange.rs`; `cmd/props/linfile.rs`; `cmd/hatch/patfile.rs`; `cmd/file/pgp.rs`; `cmd/lisp.rs:12-22`; `docs/autolisp.md`; `docs/customization.md`; `docs/gaps.md` E1 | implemented (AutoLISP partial vs AutoCAD) |
| 12 | Draw/modify command breadth (LINE…HELIX; ERASE…MOCORO; arrays, OVERKILL, draw order, Express Tools) | `crates/engine/src/cmd/draw.rs`, `draw2.rs`, `modify.rs`, `modify2.rs`, `array.rs`/`array/`, `overkill.rs`, `draworder.rs`, `draw2/breakline.rs`, `txt2mtxt.rs`, `blocks/burst.rs` | implemented |
| 13 | 14 object snaps, deferred tangent/perpendicular, object snap tracking, polar/ortho (Shift inverts), grid snap, direct distance entry, FROM/M2P/TK, typed overrides, hot grips | `crates/engine/src/snap.rs:34`; `crates/engine/src/snap/tracking.rs`; `crates/engine/src/pointmod.rs`; `crates/engine/src/cmd/griphot.rs`; `docs/gaps.md` U4 | implemented (U4 leftovers remain) |
| 14 | DIM* family, MLEADER family, TABLE, TOLERANCE, annotative scaling, MTEXT editor, COMPARE; TEXTEDIT/DDEDIT replaces text by handle | `crates/engine/src/cmd/annotate*.rs`; `cmd/mleader*.rs`; `cmd/table/`; `cmd/tolerance.rs`; `cmd/annoscale.rs`; `cmd/modify2.rs:81`; `cmd/file/compare.rs`; `docs/gaps.md` F7–F12 | implemented (F9 MTEXT/field/spell gaps) |
| 15 | Hatch with 23 patterns/gradients/HATCHEDIT; BLOCK/INSERT/attributes/groups/WBLOCK/PURGE; xrefs; BEDIT/BSAVE/BCLOSE; REFEDIT/REFSET/REFCLOSE; dynamic-block reference edits and grips; no XCLIP/dynamic-block authoring | `crates/doc/src/library.rs:100-165` (23 patterns); `crates/engine/src/cmd/hatch/`; `cmd/blocks/` (`bedit.rs`, `refedit.rs`, `dyngrip.rs`, `xref/`); `docs/gaps.md` F2, F3, F13 | partial |
| 16 | Layouts, viewports (polygonal/object/clipped, VPCLIP/VPLAYER), MSPACE/PSPACE, page setups, PLOT dialog, preview, EXPORTPDF, PUBLISH, PDFBOOK, JSON plot styles/plotters | `crates/engine/src/cmd/layout.rs`, `layout/`, `plotters.rs`, `exchange.rs`; `docs/plot-styles.md`; `docs/plotters.md`; `docs/gaps.md` F14 | implemented (binary CTB/STB/PC3 unread) |
| 17 | 16 interface languages incl. Greek/Turkish; live switch; engine/CLI/MCP messages English; web build same UI but no DWG/autosave, downloads, URL flags; SpaceMouse motion Windows/Linux only | `crates/ui-egui/src/i18n/mod.rs:173`; `docs/localization.md`; `docs/gaps.md` L1; `apps/cadcraft-web/src/main.rs:4-9,69-99`; `apps/cadcraft/src/spacemouse.rs`; `docs/hardware-parity.md` | partial |
| 18 | Desktop autosave `.sv$` DXF (SAVETIME 10 default/0 off/600 max), Drawing Recovery, AUDIT/RECOVER, AUDITCTL=1 `.adt` logs; panic guard restores the drawing; no web autosave | `crates/engine/src/autosave.rs:25-29`; `crates/engine/src/cmd/audit.rs:13-23,143`; `crates/engine/src/lib.rs:454-455,887-913`; `crates/engine/src/guard.rs`; `docs/gaps.md` F4 | implemented (desktop only) |
| 19 | Limitations: lossy DWG/no real-file corpus/no AutoCAD check; no 3D; tessellated ellipse/spline; absolute tolerances; XCLIP/xref-in-place/dynamic-block authoring absent; no SHX/PDF import/raster/DWF/DGN/ACIS/STL/DWS; binary plot files unread; MTEXT fields/spell gaps; ~150/1000 SETVAR; no Sheet Set/eTransmit/Traces/CUI; Finder `.dxf` association broken; no PR `xtask ci`; web PDF-bytes bug | `docs/gaps.md` rows 1–3, F2–F4, F7–F9, F14, F23, U10/U12/U13, FF1–FF14, S1/S4, P1–P3, H3; `docs/geometry-parity.md`; `docs/file-format-parity.md`; `docs/roadmap.md` (stage) | claimed/absent or partial as labelled |
| 20 | v0.11.0 fixes: DWG current text style handle, DGN component skip, DXF handles >2^48 and table caps, plot-window corners, ACAD_TABLE `*T` origin, MLEADER DIMSCALE, control accept backoff, AutoLISP `=`/`entsel`; macOS bundle holds only the GUI binary and the CLI is a separate signed zip | `git diff v0.10.0..v0.11.0`; `crates/dwg/src/lib.rs`; `crates/io/src/dxf_raw.rs`; `crates/io/src/dxf_write.rs`; `crates/engine/src/cmd/annotate.rs`; `apps/cadcraft/src/control_server.rs`; `crates/engine/src/lisp/{builtins,input}.rs`; `packaging/macos/package.sh:44,104`; `README.md` Downloads | implemented |

## Spot-check notes / uncertainties

- **Counts unchanged from v0.10.0.** The v0.11.0 tree differs from v0.10.0 in 32 files; no
  `CommandSpec` list, `crates/mcp/src/tools.rs`, `crates/ui-egui/src/control.rs`, CLI dispatch,
  format mapping or shortcut table changed. 427 / 15 (12 headless) / 27 (12 headless) / 7 stand.
  The parity checklist was generated 2026-10-15/16, before the tag, but the registry it measures
  is unchanged by the 32-file diff.
- **427 vs 415 literal sites.** `rg "CommandSpec::new\\("` finds 415 call sites; the generated
  checklist and live `cadcraft-cli commands` say 427 because some commands are built
  programmatically (for example `regions::specs()` and alias specs). Quote the generated/live
  number, not the grep count.
- **Stale numbers elsewhere.** `docs/architecture.md` still says ~57,000 lines and 295 commands
  (2026-10-10); `ROADMAP.md`/`docs/target-app-parity.md` still quote 245/491 (50%) from the older
  measurement. The generated `docs/parity-checklist.md` (283/491) and the source recount
  (≈154k lines, 12 crates + 3 apps) are newer.
- **Stale alpha-gate prose.** `docs/roadmap.md` says object snap tracking/extension/parallel are
  toggles with no behaviour and that REFEDIT is missing; `docs/gaps.md` revision entries and the
  code (`snap/tracking.rs`, `cmd/blocks/refedit.rs`, plot styles) show those landed. `ROADMAP.md`
  still labels the project pre-alpha; use that stage, but not the old per-row reasons.
- **acadrust version mismatch in docs.** `docs/file-format-parity.md` says acadrust 0.6.3;
  `crates/dwg/Cargo.toml` pins 0.6.4. The SKILL quotes the manifest.
- **README lags code.** It calls the app "2D and 3D" (no 3D: `docs/gaps.md` F24), says DXF write
  R2000 and "SVG and PNG" export (code writes DXF 2000–2018 and PDF too), and lists 15 interface
  languages (code has 16 incl. Greek).
- **Corrected previous-skill claim.** `docs/gaps.md` F9 says existing MTEXT cannot be edited
  (no DDEDIT/MTEDIT), but `TEXTEDIT` exists with alias `DDEDIT` (`cmd/modify2.rs:81`) and replaces
  TEXT/MTEXT/ATTDEF/dimension text by handle. What is missing is the in-place formatting editor,
  fields and spell check — the SKILL says that rather than repeating "no DDEDIT".
- **Hardware doc vs code.** `docs/hardware-parity.md` lists 3D mice as absent on every platform;
  `apps/cadcraft/src/spacemouse.rs` compiles motion only for Windows/Linux (macOS has
  status/buttons). The SKILL follows the code and says so.
- **Read notes vs skipped records.** `open` returns `warnings` from `drawing.read_notes` (DWG
  skipped objects, SVG omissions); `drawing.inspect.skipped` counts DXF records the reader could
  not place. They are different fields — the verification protocol checks both.
- **Not runtime-tested.** No build or live GUI session was possible under the read-only rule.
  Claims about interactive feel (AutoComplete, right-click repeat, hot grips), associative
  dimensions, "every arrowhead", MTEXT bidi/OpenType shaping, per-language font availability and
  Windows/Linux robustness are code/docs claims, labelled as such in the SKILL. The installed
  bundle was used only for `--version`.
- **CLI availability.** `cadcraft-cli` is not on `PATH` on this host and is not inside the `.app`
  (packaging scripts put the GUI binary in the bundle and the CLI in a separate zip). Agents must
  install the CLI zip or use MCP/control through the app.

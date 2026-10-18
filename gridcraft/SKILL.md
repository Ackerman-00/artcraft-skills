---
name: gridcraft
description: >-
  GridCraft is an open-source, clean-room Rust reimplementation of Microsoft Excel: a fast spreadsheet
  app for macOS (also Windows, Linux, BSD and the web) that reads and writes real Excel .xlsx files,
  and that can be driven headlessly by agents through a CLI, an MCP server and a live JSON control
  channel. Use this skill whenever the user mentions GridCraft by name; asks what it can do or which
  formats, keyboard shortcuts, commands or worksheet functions it has; wants to create, edit, convert,
  calculate, print or export spreadsheets with it; wants to automate or script it (MCP, CLI, control
  channel, recorded scripts); needs assets or data prepared for it (make/convert .xlsx, CSV, TSV, JSON,
  or convert .xls/.xlsb/.ods into .xlsx); wants its output verified, repaired or round-tripped
  (gridcraft-cli check); or reports a symptom (crash, wrong formula result, formatting lost on save,
  Excel saying "we found a problem with some content"). Trigger it even when the app is not named but
  the job is Excel-style spreadsheet work — "make me an Excel file", "add a formula column", "sort and
  filter this sheet", "pivot this data", "export this workbook to PDF", "read the values out of this
  spreadsheet". Do not assume Excel feature parity from Excel knowledge; check this skill first.
---

# GridCraft

## Overview

GridCraft is an open-source, clean-room reimplementation of Microsoft Excel's workflow, written in pure
Rust by the ArtCraft team; the source lives at `github.com/storytold/gridcraft` (README.md). XLSX is the
native format, and an engine-first architecture makes every ribbon button, menu item, dialog, keystroke
and mouse gesture a *command* that agents can run over a JSON control channel, an MCP server, or the
headless CLI (`README.md` §"For agents"; `AGENTS.md`). Maturity is **alpha**: the core workflow (open
XLSX → edit/format → sort/filter → chart/pivot → print to PDF → save XLSX) works end to end, but the
project's own assessment is ~50% "ready for real work" (ROADMAP.md headline numbers). It runs on macOS
11+, Windows, Linux, BSD and the browser via WebAssembly; this skill was written against release
**v0.8.0**, the exact commit (`823c5658`) shipped in the installed app bundle.

## Capabilities (verified)

### Core workbook and editing
- Multiple workbooks open in one OS window ("documents"), plus sheet tabs, names, freeze panes,
  outlining; three built-in samples `sales`, `budget`, `grades` — `crates/engine/src/sample.rs`,
  `crates/engine/src/cmd/file.rs` (`file.new`), `docs/ui-parity.md` (no multiple windows per workbook).
- Full command surface: 274 of the 290 Excel ribbon/menu ids in the catalog are implemented (94.5%) —
  `crates/engine/src/catalog.rs`, generated `docs/parity-checklist.md`. The CLI prints the live list:
  `gridcraft-cli commands`. Examples: `cell.set`, `home.bold`, `insert.chart`, `data.sortAscending`.
- Formatting: fonts, borders, fills, alignment, merges, Excel's number-format language
  (`crates/numfmt`), styles/themes, conditional formatting (`crates/engine/src/cf.rs`), data validation,
  and pass-through of unmodelled workbook parts — `crates/xlsx/src/passthrough.rs`.
- Tables, comments/notes and threaded comments, hyperlinks, pictures (floating and in-cell rich-value
  pictures: `docs/cell-pictures.md`), shapes/text boxes, checkboxes (`insert.checkbox`,
  `cell.toggleCheckbox`), freehand ink on the Draw tab (`draw.pen`/`draw.lasso`/`draw.eraser`,
  `crates/model/src/features.rs` `Shape` ink points), sparklines (line/column/win-loss:
  `crates/model/src/features.rs` `SparklineKind`, `crates/chart/src/sparkline.rs`).
- AutoSave toggle in the title bar (saves after each change when the workbook has a file) —
  `crates/ui-egui/src/ribbon.rs` `title_bar`.

### Formulas and calculation
- 513 of Excel's 523 worksheet functions by name (504 working, 96.4%), including dynamic arrays and
  spilling, LET, LAMBDA, MAP/REDUCE/SCAN/BYROW/BYCOL/MAKEARRAY, structured table references,
  iterative calculation for circular references — `docs/function-parity.md`, `crates/functions/src/`,
  `crates/calc/src/`.
- Evaluate without editing: `gridcraft-cli eval '=SUM(A1:A9)' --in book.xlsx` or the `formulas.evaluate`
  command (`apps/gridcraft-cli/src/main.rs::eval`).
- The CLI can act as a calculation oracle/tester: `gridcraft-cli check <files-or-dir>` recalculates
  every formula, compares against the file's cached values, and round-trips the workbook through
  GridCraft's own XLSX writer comparing ~15 categories (values, formulas, tables, charts, pivots…) —
  `docs/cli.md` §`check`, `apps/gridcraft-cli/src/check.rs`. Exit 1 on any difference; `--json` emits
  schema `gridcraft-check/1`.

### Files it reads and writes
- **XLSX is native** (read/write): cells, formulas (shared/array/dynamic), styles, themes, merges,
  conditional formats, validation, tables, comments/threaded comments, hyperlinks, names, freeze
  panes, outlines, print settings, pictures, shapes (incl. ink as DrawingML polylines), sparklines,
  PivotTables (caches and tables), protection, calc settings — `crates/engine/src/io.rs`,
  `crates/xlsx/src/{read,write,sheet_read,sheet_write}.rs`, `docs/file-format-parity.md`.
- `.xlsm`/`.xltm` keep their VBA project byte-for-byte (macros are **never run**); `.xltx`/`.xltm`
  templates save with the template content type — `crates/xlsx/src/lib.rs` (`XlsxKind`), `write.rs`,
  `io.rs` comments.
- **Import-only**: `.xls` (BIFF8; values, formulas, number formats, merges, sizes, names — no fonts/
  fills/borders/charts/pictures/CF/validation) `crates/xlsx/src/xls/`; `.xlsb` and `.ods`
  (worksheet **values only**, cached formula results) `crates/xlsx/src/{xlsb,ods}.rs`.
- **Text/data**: CSV and TSV/TXT (delimiter detection; writes the *displayed* text, General keeps full
  numeric precision) `crates/xlsx/src/csv.rs`, `io.rs::csv`; JSON workbook (debug format, serde of the
  internal model) `io.rs`; HTML export (one sheet as a table; refuses >100,001 rows) `io.rs::to_html`.
- **PDF export** from a sheet (own PDF 1.7 writer, 14 standard fonts, no embedding) —
  `crates/pdf/src/lib.rs`, `crates/engine/src/cmd/print.rs::export_pdf`.
- **Password-encrypted `.xlsx` open** (Agile and Standard [MS-OFFCRYPTO] schemes) via `password`
  parameter; the workbook opens without a save path and is saved **without** the password —
  `crates/xlsx/src/crypto.rs`, `io.rs`, `docs/control-protocol.md`.
- **Save is refused** for `.xls`, `.xlsb`, `.ods` (import-only) — `io.rs::save_bytes_as`.

### Charts, pivots, analysis
- 25 chart kinds (column/bar/line/pie/doughnut/area/scatter/bubble/radar/histogram/waterfall/funnel/
  treemap/sunburst/box-whisker/stock/combo…) with a Chart Design tab, Format pane, Recommended Charts
  (own heuristic), trendlines, PivotCharts — `crates/model/src/features.rs` `ChartKind`,
  `crates/chart/src/`, `docs/chart-parity.md`.
- PivotTables: field list, Filters/Rows/Columns/Values areas, report filters, layouts, date grouping,
  show-values-as, calculated fields, grand totals; round-trip to/from XLSX —
  `crates/engine/src/cmd/pivot.rs`, `crates/xlsx/src/pivot.rs`, `docs/parity-checklist.md`
  (PivotTable Analyze 13/13, Design 4/4).
- Data tools: sort, AutoFilter (incl. filter-by-value/colour, top-10, custom), advanced filter, remove
  duplicates, text-to-columns, Flash Fill, group/ungroup/subtotals, consolidate, scenario manager,
  Goal Seek, data table — `crates/engine/src/cmd/{data,whatif}.rs`.
- Solver (Simplex LP + Evolutionary + local nonlinear; Answer/Limits reports; no Sensitivity report),
  Forecast Sheet, Analysis ToolPak (13 of 19 tools) — `crates/engine/src/cmd/{solver,forecast,analysis}.rs`,
  `docs/gaps.md` §13.
- Native printing and print preview via the shared `craft-print` library (pinned git rev in
  `apps/gridcraft/Cargo.toml`), plus Page Setup, Page Break Preview and Page Layout (paper) view —
  `crates/engine/src/cmd/print.rs`, `docs/control-protocol.md` §Native printing.

### Automation surface (the reason to read this skill)
- **CLI** `gridcraft-cli` (headless; *not* inside the app bundle — install separately): `info`,
  `convert` (to `.xlsx`/`.csv`/`.tsv`/`.json`/`.html`), `eval`, `cat`, `run` (scripted `--cmd`/`--script`
  steps over a workbook, `--out`), `check`, `commands`, `functions`, `mcp`, `send`, `version` —
  `apps/gridcraft-cli/src/main.rs`, `docs/cli.md`.
- **MCP server** over stdio (`gridcraft-cli mcp [--in FILE | --sample NAME]`, or `--connect PORT` to
  drive a running app) with tools `execute_command`, `read_range`, `write_range`, `set_cell`, `get_cell`,
  `evaluate_formula`, `format_range`, `insert_chart`, `create_table`, `sort_range`, `filter`,
  `open_workbook`/`save_workbook`/`new_workbook`, `undo`/`redo`, `screenshot` (remote/desktop only),
  `list_commands`, `list_functions`, `inspect_workbook`, `select` — `crates/mcp/src/tools.rs`, `docs/mcp.md`.
- **Control channel**: the desktop app started with `--control <port>` (or `GRIDCRAFT_CONTROL_PORT`)
  accepts newline-delimited JSON on `127.0.0.1`: `engine.execute`, `document.inspect`, `sheet.read`,
  real pointer/keyboard input (`ui.click`, `ui.drag`, `ui.key`, `ui.text`), editor driving
  (`ui.edit.*`), dialogs (`ui.dialog`), ribbon/backstage (`ui.ribbon`, `ui.backstage`), `ui.screenshot`
  (PNG), `app.open`/`app.save`/`app.quit` — `crates/ui-egui/src/control.rs`, `docs/control-protocol.md`.
- **Recorded scripts** on the Automate tab: record → save → run/delete (`automate.recordActions`,
  `automate.newScript`, `automate.runScript`, …) — `crates/engine/src/cmd/extra.rs`.
- **Web (WebAssembly)**: same UI crate via eframe web runner, `trunk build --release` → `dist/web`;
  URL flags `?sample=`, `?webgl`, `?host=parent`; no TCP control channel in the browser —
  `apps/gridcraft-web/src/main.rs`.
- Programmatic calls **never open dialogs**: a command with missing file params returns an error like
  "programmatic calls never open dialogs" instead (`crates/engine/src/lib.rs::execute_headless`).

## Known limitations and not-implemented

- **No write support** for `.xls`, `.xlsb`, `.ods` (import only); `.xls` import lacks fonts, fills,
  borders, charts, pictures, comments, CF, validation, freeze panes; `.xlsb`/`.ods` import values only,
  formula cells use their last saved values — `crates/engine/src/io.rs`, `docs/file-format-parity.md`.
- **Encryption is read-only**: GridCraft cannot save a password-protected file, and encrypted `.xls`
  (FILEPASS) or RC4 files are refused — `docs/gaps.md` §7.
- **Macros never run** and VBA is dropped on open unless saving as `.xlsm`/`.xltm` (kept byte-for-byte,
  not executed) — `docs/gaps.md` §21.
- **Real-Excel fidelity is unproven**: nobody has confirmed Excel opens GridCraft's output without a
  repair prompt across a real corpus; some unmodelled XLSX content (slicers, slicer caches, timelines,
  the data model, query tables attached to tables, unmodelled `extLst`) is dropped on save. Slicers can
  be created in-app (thin front-end over filters: `crates/engine/src/cmd/slicer.rs`) but are not
  written to XLSX. Chart sheets are preserved unchanged but cannot be viewed/edited/created —
  `docs/gaps.md` §1/§3, `docs/file-format-parity.md`, `docs/chart-parity.md`.
- **Charts are shallow**: no 3-D types, axis scaling (min/max/log), error bars, data tables under
  charts, per-point formatting, full data labels; several kinds (stock, combo, treemap, sunburst, box &
  whisker, waterfall, funnel) "lose their kind in XLSX" (open PRs #158/#161); charts can't be resized
  (#190) — `docs/chart-parity.md`.
- **Scale limits**: ~100 MB XLSX files fail to open (#175); recalculation is single-threaded;
  whole-sheet operations on huge ranges are bounded/refused (HTML export caps at 100,001 rows; CSV at
  512 MiB) — `docs/gaps.md` §2, `crates/engine/src/io.rs`.
- **No Power Query editor** (only `data.getData` from CSV/TSV/JSON arrays of objects), no connections
  refresh, no data model, no `data.fromHtml` (HTML *import* is missing; the keytip table reserves it
  as "pending", `crates/ui-egui/src/keytips/keytip_table/generated.rs`), no Solver Sensitivity report
  or AllDifferent constraints — `docs/gaps.md` §12/§13, `crates/engine/src/cmd/extra.rs`.
- **HTML input**: a `.html` path opened via `file.open` is treated as delimited text, not parsed HTML
  (`io.rs` falls through to `read_csv`) — docs/file-format-parity.md's "read via Get Data ▸ From HTML"
  is not backed by code (uncertain — see `crates/xlsx/src/`, no HTML reader exists).
- **Non-Latin text**: PDF export can't render CJK/Arabic/Devanagari/Thai (standard PDF fonts only, no
  embedding); Arabic/Devanagari shaping missing in the grid — `docs/gaps.md` §5, `crates/pdf/src/lib.rs`.
- **One OS window**: `view.newWindow` opens a *copy of the workbook* as another document, not a
  second window; `view.arrangeAll` is a no-op — `crates/engine/src/cmd/extra.rs`, `docs/gaps.md` §20.
- **No live formulas in non-English input**: interface languages exist (11 variants in
  `crates/ui-egui/src/i18n.rs`) but only chrome is translated; formula names/separators stay English
  canonical (`docs/control-protocol.md`, `docs/formula-input.md`); Spanish input mode exists as a
  formula-entry aid only.
- **Localization maturity**: translation coverage is partial (ribbon-level), per `docs/gaps.md` §11;
  README's "89% ribbon / 17 chart types" numbers are stale — the generated `docs/parity-checklist.md`
  (94.5%) and `docs/chart-parity.md` (25 kinds) are authoritative.
- No VBA/Office Scripts/plugin or custom-function API; no collaboration/co-authoring; no mobile build;
  no accessibility tree for the grid; no in-app AI (`docs/gaps.md` §16/§18/§21-23).

## How to operate

### macOS launch and flags
- Launch: `open -a GridCraft`; open a document: `open -a GridCraft /path/book.xlsx` (Finder
  double-click and `open` arrive as Apple events — `apps/gridcraft/src/apple_events.rs`).
- Binary (for flags/environment): `/Applications/GridCraft.app/Contents/MacOS/GridCraft [--control PORT]
  [--sample budget|sales|grades] [files…]` — `apps/gridcraft/src/main.rs` (usage doc-comment).
  `--sample` without a name opens `sales`; `--version` prints `GridCraft 0.8.0`.
- Environment: `GRIDCRAFT_CONTROL_PORT=<port>` (same as `--control`), `GRIDCRAFT_NO_PREFS=1` (no
  settings/logs written — the mode for agents' test runs), `RUST_LOG` for log directives.
- Logs: `~/Library/Application Support/GridCraft/logs/gridcraft.log` (rotated `.1`/`.2`, 16 MiB cap)
  next to `ui.json`/`prefs.json` — README.md §Logs.

### The CLI (install separately)
The app bundle ships no CLI; install with `cargo install --path apps/gridcraft-cli` from a source
checkout, or the release zip `gridcraft-cli-<ver>-macos-universal.zip` (README.md Downloads,
`docs/cli.md`). Common calls:

```sh
gridcraft-cli info book.xlsx [--json]
gridcraft-cli convert in.xls out.xlsx [--sheet Sales]     # xlsx/csv/tsv/json/html by extension
gridcraft-cli eval '=XLOOKUP("b",{"a","b"},{1,2})'        # → 2
gridcraft-cli cat book.xlsx --range A1:F20 [--formulas|--csv]
gridcraft-cli run --in book.xlsx --cmd 'cell.set={"cell":"D2","input":"=B2*C2"}' \
    --cmd 'edit.fillDown={"range":"D2:D20"}' --out book.xlsx --print A1:D5
gridcraft-cli check corpus/ --json                        # calc oracle + XLSX round-trip fidelity
gridcraft-cli commands --search chart                     # every command and its params doc
gridcraft-cli send 7979 engine.execute '{"command":"home.bold","params":{"range":"A1:C1"}}'
```

A `--cmd` is `id`, `id={json}` or `id {json}`; `--script` reads one step per line (blank/# lines
skipped). The first failing step stops the run with a non-zero exit (`docs/cli.md` §`run`).

### Control channel (drive the running app)
```sh
/Applications/GridCraft.app/Contents/MacOS/GridCraft --sample sales --control 7979
# then, newline-delimited JSON to 127.0.0.1:7979:
{"id":1,"method":"engine.execute","params":{"command":"cell.set","params":{"cell":"B2","input":"=SUM(A1:A9)"}}}
{"id":2,"method":"ui.screenshot","params":{"path":"/tmp/shot.png"}}
```
`ui.inspect` first (ribbon tab, editor, open dialog, message, grid rect) then act with `ui.click`/
`ui.drag`/`ui.key`/`ui.text`/`ui.edit.*`/`ui.dialog`; `ui.screenshot` returns PNG (needs a visible
window). `app.open {path, password?}` opens files; `file.open` with a password-protected workbook
returns an error without the password, never a dialog (`docs/control-protocol.md`).

### MCP (for agent tool-calling)
```sh
claude mcp add gridcraft -- gridcraft-cli mcp                     # headless in-process session
claude mcp add gridcraft-app -- gridcraft-cli mcp --connect 7979 # drive the visible app
```
Tools and resources per `docs/mcp.md` (protocol `2025-06-18`; older clients answered in their own
version). Results are one pretty-JSON text block; failures set `isError: true`.

### Document model, save/export flow
- One window, multiple documents; switch with the Window menu / `window.activate {index}`; hide with
  `view.hideWindow`. Sheet tabs at the bottom. File → New opens the Backstage (New blank or
  `budget`/`sales`/`grades` samples; pages: home, new, open, info, saveAs, print, export, options,
  close — `docs/ui-parity.md`).
- Save (`file.save`/`file.saveAs`/⌘S/⇧⌘S): `.xlsx` by default; the extension picks the format
  (`.csv`, `.tsv`, `.json`, `.html`, `.pdf`). `.pdf` saves a print of the sheet (Page Setup applies)
  and does not mark the workbook saved. `file.saveBytes {format}` returns base64 without writing.
- Exports: `file.exportPdf {path?}` (no path → base64 + page count), `file.exportCsv {path, sheet?}`,
  `file.exportHtml {path}`, `file.printPreview`, and on the desktop `ui.printSettings` /
  `ui.printSubmit` (native printer jobs via craft-print).

### Keyboard essentials (verified)
- ⌘S save, ⇧⌘S Save As, ⌘O open, ⌘N new, ⌘W close, ⌘Z/⇧⌘Z undo/redo, ⌘Y redo — `crates/ui-egui/src/ribbon.rs::shortcut`.
- ⌘B/⌘I/⌘U bold/italic/underline; Ctrl+1 Format Cells; ⌘D fill down; ⌘R fill right; ⌘E Flash Fill;
  ⌘T table; ⌘K insert link; Ctrl+Shift+L filter; F2 edit — `ribbon.rs`, `keymap.rs`, `grid.rs`.
- Excel-for-Mac variants are mapped in `crates/ui-egui/src/keymap.rs` (⌘ vs Control differences).
- Key tips: press **F10** (macOS; Fn+F10 if needed), then sequence letters; a 364-sequence table covers
  all tabs (per control badges) — `crates/ui-egui/src/keytips/keytips.json`, `docs/ui-parity.md`.
  (README's "initial Home-only key tips" is stale.)

## Working with an AI agent

**Prefer headless over GUI.** For "read/write/convert/verify" jobs use `gridcraft-cli` (or MCP) on
files — no window, no prefs, deterministic. Drive the GUI over the control channel only when the task
is genuinely about the UI (dialogs with no command equivalent, visual state, screenshots, printing).
Never drive the GUI blind: `ui.inspect` / `ui.screenshot` before and after, and act on what they show.

Legitimate agent work:
- **Prepare inputs**: build `.xlsx` from commands (`gridcraft-cli run --script steps.jsonl`), convert
  `.xls`/`.xlsb`/`.ods`/CSV/TSV into `.xlsx` (`convert`), or generate CSV/TSV/JSON and import with
  `data.getData`. All GridCraft inputs must end up in a supported read format (`io.rs::FileKind`).
- **Interpret/repair project files**: XLSX is the native format and is documented in code
  (`crates/xlsx/src/`); the `.json` workbook is a debug serialization of the internal model — treat it
  as unstable, never a long-lived interchange format. "Repair" means: open in GridCraft, inspect
  (`info`, `check`), fix with commands, save as `.xlsx`. Do not promise recovery of parts GridCraft
  doesn't model (slicers, timelines, data model, chart sheets beyond pass-through).
- **Verify exports honestly**: run `gridcraft-cli check` on round-tripped files, compare `cat`/`info`
  output against expectations, check PDF page counts. A zero exit from `check` means *GridCraft*
  agrees with itself and the cached values — it does not prove Excel will open the file cleanly
  (explicitly unverified, `docs/gaps.md` §1).
- **Scripts**: recorded scripts (`automate.*`) capture and replay commands; they are a convenience
  layer over the same command ids, not a separate API.

Must NOT attempt:
- Writing `.xls`/`.xlsb`/`.ods` or saving password protection; expecting macros to run; expecting
  slicers/timelines to survive a save; assuming HTML import; assuming multiple windows per workbook.
- Editing `.xlsx` with raw XML surgery on files that contain unmodelled parts (slicer caches, VML,
  custom XML) — GridCraft's own writer is the only supported path, and even it drops parts it doesn't
  model once it rewrites them; prefer read-only analysis of such files.
- Treating formula input as locale-independent without checking `docs/formula-input.md` (canonical
  English syntax is what files and APIs use).

## Verification protocol (alpha discipline)

1. **Throwaway round-trip before any real work**: new workbook → the exact edit → save `.xlsx` →
   reopen in GridCraft → `gridcraft-cli check file.xlsx`. Add the source file itself to `check` when
   testing formula fidelity (it recalculates and compares against Excel-cached values).
2. **Never trust a silent export**: CSV/HTML/PDF exports are one-shot (`file.exportCsv` etc.) with no
   diff UI. Re-open or re-import the artifact, or inspect it (`cat`, PDF page count, open the PDF in
   another reader). Remember PDF export cannot render non-Latin text.
3. **Version and back up**: keep the previous version of any workbook you edit; GridCraft is alpha and
   autosave/recovery has not been soaked (`docs/gaps.md` §10). For agent runs, files are safer than
   GUI state — save after each logical step (`--out`) rather than at the end.
4. **Update between projects, not during**: the app auto-updates via the ArtCraft Launcher; update,
   then re-run your round-trip before a new task (`README.md` Downloads; repo is the source of truth
   for what a given version can do).

## Sources & evidence

- Repo: https://github.com/storytold/gridcraft — inspected at tag **v0.8.0**, commit
  `823c56582d00be91e31b4f7f3680496cf89e84fb` ("Release 0.8.0", 2026-10-17). The installed app at
  `/Applications/GridCraft.app` reports `CFBundleShortVersionString` 0.8.0
  (`ai.storyteller.gridcraft`) — repo and installed version match; if your installed version differs,
  verify against your installed version.
- Date of inspection: 2026-10-18. Repo treated read-only.
- Key files read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`, `docs/{cli,mcp,control-protocol,parity-checklist,function-parity,chart-parity,file-format-parity,gaps,ui-parity,cell-pictures}.md`,
  `apps/gridcraft-cli/src/main.rs`, `apps/gridcraft/src/main.rs`, `crates/engine/src/{io.rs,lib.rs,sample.rs,catalog.rs}`,
  `crates/engine/src/cmd/*.rs`, `crates/xlsx/src/lib.rs`, `crates/mcp/src/{tools.rs,tests.rs}`,
  `crates/ui-egui/src/{control.rs,keymap.rs,ribbon.rs}`, `crates/model/src/features.rs`,
  `crates/pdf/src/lib.rs`, `packaging/macos/Info.plist.in`, `/Applications/GridCraft.app/Contents/Info.plist`.
- Shared library: `craft-print` is pinned from `storytold/craft-libs`
  (`rev d27646a5f7c8b4fc85d9dd3213b8c88b58e0088d`, verified present in the local checkout) — used for
  native print submission; PDF generation stays in GridCraft (`apps/gridcraft/Cargo.toml`,
  `craft-libs/crates/print`).
- Deeper per-topic reference: `docs/target-app-parity.md` (authoritative assessment),
  `docs/gaps.md` (ranked work list), `docs/architecture.md` (layering).

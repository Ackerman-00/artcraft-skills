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
XLSX → edit/format → sort/filter → chart/pivot → print to PDF → save XLSX) works end to end, and the
project estimates feature breadth ~75% but only ~50% "ready for real work" (ROADMAP.md headline
numbers). It runs on macOS 11+, Windows, Linux, BSD and the browser via WebAssembly; this skill was
written against release **v0.10.0**, the exact version the installed app reports (`GridCraft 0.10.0`).

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
- Tables, notes and threaded comments (replies, resolved state, shown/hidden), hyperlinks, pictures
  (floating and in-cell rich-value pictures: `docs/cell-pictures.md`, PNG/JPEG only; no `IMAGE()`
  function), shapes/text boxes (8 shape kinds vs Excel's ~170), checkboxes (`insert.checkbox`,
  `cell.toggleCheckbox`), freehand ink on the Draw tab with Ink to Shape (`draw.pen`, `draw.stroke`,
  `draw.lasso`, `draw.eraser`, `draw.inkToShape` — `crates/engine/src/cmd/draw.rs`), sparklines
  (line/column/win-loss: `crates/model/src/features.rs` `SparklineKind`).
- AutoSave toggle in the title bar (saves after each change when the workbook has a file) —
  `crates/ui-egui/src/ribbon.rs` `title_bar`.

### Formulas and calculation
- 513 of Excel's 523 worksheet functions by name (504 working, 96.4%), including dynamic arrays and
  spilling, LET, LAMBDA, MAP/REDUCE/SCAN/BYROW/BYCOL/MAKEARRAY, structured table references,
  iterative calculation for circular references — `docs/function-parity.md` ("Measured" line),
  `crates/functions/src/`, `crates/calc/src/`.
- Evaluate without editing: `gridcraft-cli eval '=SUM(A1:A9)' --in book.xlsx` or the `formulas.evaluate`
  command (`apps/gridcraft-cli/src/main.rs::eval`).
- The CLI is a calculation oracle/tester: `gridcraft-cli check <files-or-dir> [--tolerance 1e-9]
  [--max-report N]` recalculates every formula, compares against the file's cached values (skipping
  volatile formulas and files saved with `fullCalcOnLoad`), then round-trips the workbook through
  GridCraft's own XLSX writer comparing 14 categories (package, sheets, values, formulas, numFmts,
  merges, tables, condFormats, validations, charts, comments, hyperlinks, pivots, names) and validates
  the package the way Excel's repair would — `docs/cli.md` §`check`,
  `apps/gridcraft-cli/src/check.rs` (`Diffs::new` list). Exit 1 on any difference; `--json` emits
  schema `gridcraft-check/1`; mismatches roll up by function and by signature (`number → #SPILL!`).

### Files it reads and writes
- **XLSX is native** (read/write): cells, formulas (shared/array/dynamic), styles, themes, merges,
  conditional formats, validation, tables, notes/threaded comments, hyperlinks, names, freeze panes,
  outlines, print settings, pictures, shapes (incl. ink as DrawingML polylines), sparklines,
  PivotTables (caches and tables), Allow-Edit-Ranges protection, calc settings —
  `crates/engine/src/io.rs`, `crates/xlsx/src/{read,write,sheet_read,sheet_write}.rs`,
  `docs/file-format-parity.md`. Strict Open XML files open but always save as transitional.
- `.xlsm`/`.xltm` keep their VBA project byte-for-byte (macros are **never run**); `.xltx`/`.xltm`
  save with the template content type — `crates/xlsx/src/lib.rs` (`XlsxKind`), `write.rs`, `io.rs`.
- **Import-only**: `.xls` (BIFF8; values, formulas, number formats, merges, sizes, names, calc and
  sheet-display settings — no fonts/fills/borders/charts/pictures/comments/CF/validation) with chart,
  macro and dialog sheets skipped — `crates/xlsx/src/xls/`; `.xlsb` and `.ods` (worksheet **values
  only**, cached formula results) `crates/xlsx/src/{xlsb,ods}.rs`. `.xlt` opens as `.xls`.
- **Text/data**: CSV and TSV/TXT/TAB (delimiter detection, UTF-8/UTF-16/Windows-1252; writes the
  *displayed* text, General keeps full numeric precision; a workbook opened as CSV keeps its
  separator on save; output refused over 512 MiB) `crates/xlsx/src/csv.rs`, `io.rs::csv`;
  `file.open {csvAsText: true}` keeps every field as text (`io.rs`). JSON workbook (debug serde of
  the internal model) `io.rs`. HTML export (one sheet as a table; refuses >100,001 rows) `io.rs::to_html`.
- **PDF export** from a sheet (own PDF 1.7 writer, 14 standard fonts, no embedding) —
  `crates/pdf/src/lib.rs`, `crates/engine/src/cmd/print.rs::export_pdf`.
- **Password-encrypted `.xlsx` open** (Agile AES + Standard encryption, [MS-OFFCRYPTO]) via a
  `password` parameter; the workbook opens without a save path and is saved **without** the password;
  RC4/Extensible/encrypted-`.xls` refused — `crates/xlsx/src/crypto.rs`, `io.rs`,
  `docs/control-protocol.md`.
- **Save is refused** for `.xls`, `.xlsb`, `.ods` (import-only) — `io.rs::save_bytes_as`.

### Charts, pivots, analysis
- 25 chart kinds (column/bar/line/pie/doughnut/area/scatter/bubble/radar/histogram/waterfall/funnel/
  treemap/sunburst/box-whisker/stock/combo…) with a Chart Design tab, Format pane, Recommended Charts
  (own heuristic, live previews), trendlines (six types, read/written/drawn), PivotCharts
  (`insert.pivotChart`, bound to a PivotTable's report) — `crates/model/src/features.rs` `ChartKind`
  (25 variants), `crates/chart/src/`, `docs/chart-parity.md`.
- PivotTables: field list, Filters/Rows/Columns/Values areas, report filters, layouts, date grouping,
  show-values-as, calculated fields, values on rows, grand totals; round-trip to/from XLSX —
  `crates/engine/src/cmd/pivot.rs`, `crates/xlsx/src/pivot.rs`, `docs/parity-checklist.md`
  (PivotTable Analyze 13/13, Design 4/4).
- Data tools: sort, AutoFilter (by value/colour, top-10, custom), advanced filter, remove duplicates,
  text-to-columns, Flash Fill, group/ungroup/subtotals, consolidate, scenario manager
  (`data.scenario*`), Goal Seek (`data.goalSeek`), data table — `crates/engine/src/cmd/{data,whatif}.rs`.
- Solver (`data.solver`: Simplex LP with integer/binary branch-and-bound, augmented-Lagrangian local
  nonlinear, Evolutionary; Answer and Limits reports), Forecast Sheet with hindcast
  (`data.forecastSheet`), Analysis ToolPak (13 of 19 tools) —
  `crates/engine/src/cmd/{solver,forecast,analysis,whatif}.rs`, `docs/gaps.md` §13.
- Native printing and print preview via the shared `craft-print` library (pinned git rev in
  `apps/gridcraft/Cargo.toml`; printer choice, copies, duplex, grayscale), Page Setup, Page Break
  Preview and Page Layout view (paper view, rulers with draggable margins, in-place header/footer
  editing) — `crates/engine/src/cmd/print.rs`, `docs/control-protocol.md` §Native printing,
  `docs/ui-parity.md`.

### Automation surface (the reason to read this skill)
- **CLI** `gridcraft-cli` (headless; *not* inside the app bundle — install separately): `info`,
  `convert` (to `.xlsx`/`.csv`/`.tsv`/`.json`/`.html`), `eval`, `cat`, `run` (scripted `--cmd`/
  `--script` steps over a workbook, `--out`, `--print`, `--sheet`, `--csv`, `--formulas`, `--quiet`),
  `check`, `commands`, `functions` (`--search`, `--category`), `mcp`, `send`, `version` —
  `apps/gridcraft-cli/src/main.rs`, `docs/cli.md`.
- **MCP server** over stdio (`gridcraft-cli mcp [--in FILE | --sample NAME]`, or `--connect PORT` to
  drive a running app) with 21 tools: `execute_command`, `read_range`, `write_range`, `set_cell`,
  `get_cell`, `evaluate_formula`, `format_range`, `insert_chart`, `create_table`, `sort_range`,
  `filter`, `open_workbook`/`save_workbook`/`new_workbook`, `undo`/`redo`, `screenshot` (remote only),
  `list_commands`, `list_functions`, `inspect_workbook`, `select` — `crates/mcp/src/tools.rs`,
  `docs/mcp.md`. Resources: `gridcraft://workbook`, `gridcraft://commands`, `gridcraft://functions`.
- **Control channel**: the desktop app started with `--control <port>` (or `GRIDCRAFT_CONTROL_PORT`)
  accepts newline-delimited JSON on `127.0.0.1`: `engine.execute`, `engine.commands`, `engine.journal`
  (replayable; passwords excluded), `document.inspect`, `sheet.read`, `cell.get`, real pointer and
  keyboard input (`ui.click`, `ui.move`, `ui.drag`, `ui.cell.click`, `ui.cell.drag`, `ui.key`,
  `ui.text`), editor driving (`ui.edit.*`), dialogs (`ui.dialog`, `ui.dialog.set/confirm/cancel`),
  ribbon/backstage (`ui.ribbon`, `ui.backstage` via `engine.execute`), `ui.screenshot` (PNG;
  animations settle first), `ui.set`, `ui.resize`, `ui.focus`, `app.open`/`app.save`/`app.quit` —
  `crates/ui-egui/src/control.rs`, `docs/control-protocol.md`.
- **Recorded scripts** on the Automate tab: record → save → run/delete (`automate.recordActions`,
  `automate.newScript`, `automate.allScripts`, `automate.runScript`, `automate.deleteScript`) —
  `crates/engine/src/cmd/extra.rs`.
- **Web (WebAssembly)**: same UI crate via eframe web runner, `trunk build --release` → `dist/web`;
  URL flags `?sample=`, `?webgl`, `?host=parent` (iframe integration with an `&author=` name); no TCP
  control channel in the browser — `apps/gridcraft-web/src/main.rs`.
- Programmatic calls **never open dialogs**: a command with missing file params returns an error like
  "programmatic calls never open dialogs" instead (`crates/engine/src/lib.rs::execute_headless`).
- Interface languages: 11 built in (`en es zh ja ko ru pt-BR de cs fr sr`), but only chrome is
  translated (~12% of ~2,200 strings each; pt-BR ~42%); formula names/separators stay en-US canonical;
  `app.language.set` switches at runtime — `crates/ui-egui/src/i18n.rs` (`Language::ALL`),
  `docs/localization-parity.md`, `docs/control-protocol.md`. Spanish input mode is a formula-entry aid
  only (`docs/formula-input.md`).

## Known limitations and not-implemented

- **No write support** for `.xls`, `.xlsb`, `.ods` (import only); `.xls` import lacks fonts, fills,
  borders, charts, pictures, comments, CF, validation, freeze panes; `.xlsb`/`.ods` import values only,
  formula cells use their last saved values — `crates/engine/src/io.rs`, `docs/file-format-parity.md`.
- **Encryption is read-only**: GridCraft cannot save a password-protected file, and encrypted `.xls`
  (FILEPASS) or RC4 files are refused — `docs/gaps.md` §7.
- **Macros never run** and VBA is dropped on open unless saving as `.xlsm`/`.xltm` (kept byte-for-byte,
  not executed) — `docs/gaps.md` §21.
- **Real-Excel fidelity is unproven**: nobody has confirmed Excel opens GridCraft's output without a
  repair prompt across a real corpus; some unmodelled XLSX content (slicers and slicer caches,
  timelines, the data model, query tables attached to tables, unmodelled `extLst`) is dropped on save.
  Slicers can be created in-app (thin front-end over filters: `crates/engine/src/cmd/slicer.rs`) but
  are not written to XLSX (`crates/xlsx/src/passthrough.rs` lists `slicer`/`slicerCache` as dropped).
  Chart sheets are preserved unchanged (written back in place) but cannot be viewed/edited/created —
  `docs/gaps.md` §1/§3, `docs/file-format-parity.md`, `docs/chart-parity.md`.
- **Charts are shallow**: no 3-D types, axis scaling (min/max/log), error bars, data tables under
  charts, per-point formatting, full data labels; several kinds (stock, combo, treemap, sunburst,
  box-whisker, waterfall, funnel) "lose their kind in XLSX" (open PRs #158/#161); charts cannot be
  resized (#190; move and delete work) — `docs/chart-parity.md`, `docs/gaps.md` §4.
- **Scale limits**: ~100 MB XLSX files fail to open (#175); recalculation is single-threaded;
  whole-sheet operations on huge ranges are bounded/refused (HTML export caps at 100,001 rows; CSV/TSV
  at 512 MiB — refused, not truncated) — `docs/gaps.md` §2, `crates/engine/src/io.rs`,
  `crates/xlsx/src/csv.rs` (`MAX_CSV_BYTES`).
- **No Power Query editor** (only `data.getData` from CSV/TSV/JSON arrays of objects), no connections
  refresh, no data model, no `data.fromHtml`; no Solver Sensitivity/Population reports, AllDifferent
  constraints, Options dialog or Load/Save Model — `docs/gaps.md` §12/§13, `crates/engine/src/cmd/extra.rs`.
- **HTML input**: a `.html` path opened via `file.open` is treated as delimited text, not parsed HTML
  (`io.rs` falls through to `read_csv`); the HTML-table import `docs/file-format-parity.md` mentions
  under Get Data is not backed by a reader (uncertain — see `crates/xlsx/src/`, no HTML reader exists).
- **Non-Latin text**: PDF export can't render CJK/Arabic/Devanagari/Thai (standard PDF fonts only, no
  embedding); Arabic/Devanagari shaping missing in the grid; no bidi (right-to-left sheets mirror the
  grid, text stays LTR inside its box) — `docs/gaps.md` §5, `docs/localization-parity.md`,
  `crates/pdf/src/lib.rs`.
- **One OS window**: `view.newWindow` opens a *copy of the workbook* as another document, not a
  second window; `view.arrangeAll` is a no-op — `crates/engine/src/cmd/extra.rs`, `docs/gaps.md` §20.
- No VBA/Office Scripts/plugin or custom-function API; no collaboration/co-authoring; no mobile build;
  no accessible tree for the grid; no in-app AI (`docs/gaps.md` §16/§18/§21-23). Inserted icons lose
  their artwork on save (#551); no Office InkML import; 18 functions missing, 9 stubs (all CUBE,
  WEBSERVICE, FILTERXML) — `docs/gaps.md` §15/§17.
- Repo docs contain stale duplicate lines (e.g. `docs/gaps.md` §19 still says CSV writes raw values
  and templates save with the workbook content type; both were fixed — `io.rs::csv` writes displayed
  text, `crates/xlsx/src/tests/roundtrip.rs` tests the template content types). Prefer generated docs
  (`docs/parity-checklist.md`) and code over prose.

## How to operate

### macOS launch and flags
- Launch: `open -a GridCraft`; open a document: `open -a GridCraft /path/book.xlsx` (Finder
  double-click and `open` arrive as Apple events — `apps/gridcraft/src/apple_events.rs`); files dropped
  on the window open too (`apps/gridcraft/src/main.rs`).
- Binary (for flags/environment): `/Applications/GridCraft.app/Contents/MacOS/GridCraft [--control PORT]
  [--sample budget|sales|grades] [files…]` — `apps/gridcraft/src/main.rs` (usage doc-comment).
  `--sample` without a name opens `sales`; `--version` prints `GridCraft 0.10.0`.
- Environment: `GRIDCRAFT_CONTROL_PORT=<port>` (same as `--control`), `GRIDCRAFT_NO_PREFS=1` (no
  settings/logs written — the mode for agents' test runs), `RUST_LOG` for log directives,
  `GRIDCRAFT_NO_NATIVE_MENU` to skip the native menu.
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
gridcraft-cli functions --category statistical            # function list with signatures
gridcraft-cli send 7979 engine.execute '{"command":"home.bold","params":{"range":"A1:C1"}}'
```

A `--cmd` is `id`, `id={json}` or `id {json}`; `--script` reads one step per line in the same forms or
as `{"command":…, "params":…}` JSON objects (blank/# lines skipped). The first failing step stops the
run with a non-zero exit (`docs/cli.md` §`run`).

### Control channel (drive the running app)
```sh
/Applications/GridCraft.app/Contents/MacOS/GridCraft --sample sales --control 7979
# then, newline-delimited JSON to 127.0.0.1:7979:
{"id":1,"method":"engine.execute","params":{"command":"cell.set","params":{"cell":"B2","input":"=SUM(A1:A9)"}}}
{"id":2,"method":"ui.screenshot","params":{"path":"shot.png"}}
```
`ui.inspect` first (ribbon tab, editor, open dialog, Backstage page, message, grid rect) then act with
`ui.click`/`ui.drag`/`ui.key`/`ui.text`/`ui.edit.*`/`ui.dialog*`; `ui.screenshot` returns PNG (needs a
visible window). `app.open {path, password?}` opens files; `file.open` on a password-protected
workbook returns an error without the password, never a dialog (`docs/control-protocol.md`).

### MCP (for agent tool-calling)
```sh
claude mcp add gridcraft -- gridcraft-cli mcp                     # headless in-process session
claude mcp add gridcraft-app -- gridcraft-cli mcp --connect 7979 # drive the visible app
```
Protocol `2025-06-18` (older clients answered in their own version). Results are one pretty-JSON text
block; failures set `isError: true` (`docs/mcp.md`).

### Document model, save/export flow
- One window, multiple documents; switch with the Window menu / `window.activate {index}`; hide with
  `view.hideWindow`. Sheet tabs at the bottom. File opens the Backstage (pages: home, new with the
  three samples, open with recents, info, saveAs, print, export, options, close — `docs/ui-parity.md`).
- Save (`file.save`/`file.saveAs`/⌘S/⇧⌘S): `.xlsx` by default; the extension picks the format
  (`.csv`, `.tsv`, `.json`, `.html`, `.pdf`). `.pdf` saves a print of the sheet (Page Setup applies)
  and does not mark the workbook saved. `file.saveBytes {format}` returns base64 without writing.
- Exports: `file.exportPdf {path?}` (no path → base64 + page count), `file.exportCsv {path, sheet?}`,
  `file.exportHtml {path}`, `file.printPreview`, and on the desktop `ui.printSettings` /
  `ui.printSubmit` (native printer jobs via craft-print; poll `ui.printSettings` until not busy).

### Keyboard essentials (verified)
- ⌘S save, ⇧⌘S Save As, ⌘O open, ⌘N new, ⌘W close, ⌘Z/⇧⌘Z undo/redo, ⌘Y redo — `crates/ui-egui/src/ribbon.rs::shortcut`.
- ⌘B/⌘I/⌘U bold/italic/underline; Ctrl+1 Format Cells; ⌘D fill down; ⌘R fill right; ⌘E Flash Fill;
  ⌘T table; ⌘K insert link; Ctrl+Shift+L filter; F2 edit; Ctrl+Shift+number formats; Ctrl+Shift+&
  outline border — `ribbon.rs`, `keymap.rs`, `grid.rs`. 59 command shortcuts plus grid/editor keys;
  Excel-for-Mac variants mapped in `keymap.rs`.
- Key tips: press **F10** (macOS; Fn+F10 if needed; letters also work with left Alt held), then
  sequence letters; a 364-sequence table covers all tabs (per-control badges) —
  `crates/ui-egui/src/keytips/keytips.json` (364 entries), `docs/ui-parity.md` §Keyboard.
  (README's "initial Home-only key tips" prose is stale.)

## Working with an AI agent

**Prefer headless over GUI.** For "read/write/convert/verify" jobs use `gridcraft-cli` (or MCP) on
files — no window, no prefs, deterministic. Drive the GUI over the control channel only when the task
is genuinely about the UI (dialogs with no command equivalent, visual state, screenshots, printing).
Never drive the GUI blind: `ui.inspect` / `ui.screenshot` before and after, and act on what they show.

Legitimate agent work:
- **Prepare inputs**: build `.xlsx` from commands (`gridcraft-cli run --script steps.jsonl`), convert
  `.xls`/`.xlsb`/`.ods`/CSV/TSV into `.xlsx` (`convert`), or generate CSV/TSV/JSON and import with
  `data.getData`. All GridCraft inputs must end up in a supported read format (`io.rs::FileKind`).
  Use `csvAsText` when leading zeros and digit-only identifiers must survive import.
- **Interpret/repair project files**: XLSX is the native format and is documented in code
  (`crates/xlsx/src/`); the `.json` workbook is a debug serialization of the internal model — treat it
  as unstable, never a long-lived interchange format. "Repair" means: open in GridCraft, inspect
  (`info`, `check`), fix with commands, save as `.xlsx`. Do not promise recovery of parts GridCraft
  doesn't model (slicers, timelines, data model, chart-sheet editing).
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
- Exporting non-Latin text to PDF and expecting it to appear (the 14 standard PDF fonts cannot).

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

- Repo: https://github.com/storytold/gridcraft — inspected at tag **v0.10.0**, commit
  `2ebdf164c2c9c536122e0a2cffe79078b5c818ac` ("Release 0.10.0", 2026-10-21). The installed app reports
  `GridCraft 0.10.0` (the bundle's `CFBundleShortVersionString` is stale — trust the app/CLI version).
  If your installed version differs, verify against your installed version.
- Date of inspection: 2026-10-22. Repo treated read-only.
- Key files read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`, `docs/{cli,mcp,control-protocol,
  parity-checklist,function-parity,chart-parity,file-format-parity,gaps,ui-parity,localization-parity,
  hardware-parity,roadmap,cell-pictures,formula-input}.md`, `apps/gridcraft-cli/src/{main.rs,check.rs}`,
  `apps/gridcraft/src/main.rs`, `apps/gridcraft-web/src/main.rs`, `crates/engine/src/{io.rs,lib.rs,
  sample.rs,catalog.rs}`, `crates/engine/src/cmd/*.rs`, `crates/xlsx/src/lib.rs`, `crates/xlsx/src/csv.rs`,
  `crates/xlsx/src/crypto.rs`, `crates/xlsx/src/passthrough.rs`, `crates/mcp/src/tools.rs`,
  `crates/ui-egui/src/{control.rs,keymap.rs,ribbon.rs,i18n.rs,keytips/keytips.json}`,
  `crates/model/src/features.rs`, `crates/pdf/src/lib.rs`.
- Shared library: `craft-print` is pinned from `storytold/craft-libs`
  (`rev d27646a5f7c8b4fc85d9dd3213b8c88b58e0088d`, verified present in the local checkout) — used for
  native print submission; PDF generation stays in GridCraft (`apps/gridcraft/Cargo.toml`,
  `craft-libs/crates/print`).
- Deeper per-topic reference: `docs/target-app-parity.md` (authoritative assessment),
  `docs/gaps.md` (ranked work list), `docs/architecture.md` (layering), `docs/roadmap.md` (beta gates).

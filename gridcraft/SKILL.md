---
name: gridcraft
description: >-
  GridCraft is an open-source, clean-room Rust reimplementation of Microsoft Excel: a spreadsheet
  app for macOS (also Windows, Linux, BSD and the web) that reads and writes real .xlsx files and
  can be driven headlessly through a CLI, an MCP server and a live JSON control channel. Use this
  skill whenever the user mentions GridCraft by name; asks what it can do or which formats,
  keyboard shortcuts, commands or worksheet functions it has; wants to create, edit, convert,
  calculate, print or export spreadsheets with it; wants to automate or script it (MCP, CLI,
  control channel, recorded scripts); needs inputs prepared for it (build or convert .xlsx, CSV,
  TSV, JSON, or convert .xls/.xlsb/.ods into .xlsx); wants its output verified, repaired or
  round-tripped (gridcraft-cli check); or reports a symptom (crash, wrong formula result,
  formatting lost on save, Excel saying "we found a problem with some content"). Trigger it even
  when the app is not named but the job is Excel-style spreadsheet work — "make me an Excel file",
  "add a formula column", "sort and filter this sheet", "pivot this data", "export this workbook to
  PDF", "read the values out of this spreadsheet". Do not assume Excel parity from Excel knowledge;
  check this skill first.
---

# GridCraft

**Audit basis:** this checkout is tag `v0.12.1`, commit `f86aec12dabc744b5f75e1033f87bfe685e78481` ("Release 0.12.1", 2026-10-25). The installed `/Applications/GridCraft.app` reports version `0.12.1` (`CFBundleShortVersionString`, `CFBundleIdentifier ai.storyteller.gridcraft`), its `GridCraftBuildCommit` is the same SHA `f86aec12dabc744b5f75e1033f87bfe685e78481`, and its binary prints `GridCraft 0.12.1`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Counts and formats below were re-derived from this tag's code and generated docs; every claim carries a repo-relative pointer.

## Overview

GridCraft is an open-source, clean-room reimplementation of Microsoft Excel's workflow in pure Rust (README.md), by the ArtCraft team; source: `github.com/storytold/gridcraft`. XLSX is the native document format, and the architecture is engine-first: every ribbon button, menu item, dialog OK, keystroke and mouse gesture is a *command* (`crates/engine/src/cmd/`), reachable over a JSON control channel, an MCP server and a headless CLI (README.md §"For agents: MCP, CLI and the control channel"; `docs/architecture.md`). Maturity is **alpha**: the core workflow (open XLSX → edit/format → sort/filter → chart/pivot → print to PDF → save XLSX) works end to end, but the project's own estimate is ~75% feature breadth and ~50% "ready for real work" (`docs/target-app-parity.md` summary; ROADMAP.md). It runs natively on macOS 11+, Windows, Linux and BSD, and in the browser via WebAssembly (`apps/gridcraft-web`).

## Capabilities (verified)

### Core workbook and editing
- Several workbooks open at once inside one OS window ("documents"); the Window menu lists them (`view.switchWindows`) and `window.activate {index}` switches. Sheet tabs, defined names, freeze panes, outline groups, hidden sheets, tab colours — `crates/engine/src/cmd/{file,sheet,extra}.rs`. One window only; see limitations.
- Three built-in samples `budget`, `sales`, `grades`: `file.new {sample}`, CLI `--sample`, URL `?sample=` (`crates/engine/src/sample.rs`).
- **353 engine commands** (346 at v0.11.1; +7 — see the automation section for the added ids); **275 of the 291 Excel catalog ids** implemented, 94.5% (unchanged) — `crates/engine/src/cmd/*.rs`, `crates/engine/src/catalog.rs` (`CATALOG`, `parity()`), generated `docs/parity-checklist.md`.
- Formatting: fonts, fills, borders, alignment, merges, Excel's number-format language (`crates/numfmt`), cell styles and themes, conditional formatting (CellIs, expression, text, top-10, above-average, time period, duplicate/unique, colour scale, data bar, icon set) and data validation (whole, decimal, list, date, time, text length, custom) — `crates/engine/src/cmd/{format,insert}.rs`, `crates/model/src/features.rs` (`CfRule`, `ValidationKind`).
- Tables (structured references, header/total rows, banded rows, style gallery, Resize Table, remove duplicates), notes and threaded comments with replies/resolution/timestamps, hyperlinks, pictures floating or inside a cell (PNG/JPEG only), shapes and text boxes (9 kinds: rectangle, rounded rectangle, ellipse, triangle, line, arrow, text box, icon, ink), checkboxes, freehand ink with Ink to Shape, sparklines (line/column/win-loss) — `crates/engine/src/cmd/{insert,extra,draw}.rs`, `crates/model/src/features.rs` (`ShapeKind`, `SparklineKind`), `docs/cell-pictures.md`.
- Editing: fill handle (drag; right-drag opens Copy Cells / Fill Series / Fill Formatting Only / Fill Without Formatting / Series…), AutoFill, Flash Fill, Paste Special (values/formats/formulas/comments, transpose, Paste Link), Format Painter, Find/Replace, Go To and Go To Special, Watch Window, undo/redo with bounded history — `crates/engine/src/cmd/{edit,whatif}.rs`, `crates/ui-egui/src/grid.rs`.
- New at v0.12.1: **Auto Fill Options** button after a left-drag (`crates/engine/src/cmd/edit.rs::auto_fill`, params `mode` incl. `days|weekdays|months|years`), date fills keep the time of day; **Go To** lists every sheet's defined names (`Sheet2!Name`), keeps the references entered and takes several comma-separated targets (`edit.goTo` `{reference|list:true, record?}`, `crates/engine/src/cmd/edit.rs`); **Paste Name** dialog on F3 (`formulas.pasteName {name|list, at?}`) and **Use in Formula** menu (`formulas.useInFormula {name}`); Ctrl+click follows a hyperlink instead of extending the selection.
- Background error checking: a constant whose text would be a number gets Excel's green corner, a warning button naming the problem, and Convert to Number (`formulas.convertToNumber`); the Error Checking arrow opens a Circular References submenu naming one cell per loop; the status bar quotes sheet names that need quotes — `crates/ui-egui/src/grid.rs`, `crates/engine/src/cmd/formulas.rs`.
- AutoSave switch in the title bar, persisted across restarts; it saves only workbooks that already have a file. Closing the window with unsaved work asks first (`crates/ui-egui/src/{lib,ribbon}.rs`, `UiState::autosave`).
- Slicers exist as in-sheet filter widgets over one table column (`insert.slicer`, `slicer.toggle|selectAll|clear|delete`), but are **not** written to XLSX (`crates/engine/src/cmd/slicer.rs`, `crates/xlsx/src/passthrough.rs`).

### Formulas and calculation
- **513 of Excel's 523 worksheet functions by name, 504 working (96.4%)** — unchanged since v0.11.1 — including dynamic arrays and spilling, LET/LAMBDA (a self-calling LAMBDA stops at 140 calls with `#NUM!`), MAP/REDUCE/SCAN/BYROW/BYCOL/MAKEARRAY, GROUPBY/PIVOTBY, structured table references, iterative calculation for circular references — `docs/function-parity.md` ("Measured" line), `crates/functions/src/*.rs` (491 `f!` specs), `crates/calc/src/eval.rs` (`SPECIAL_FUNCTIONS`).
- Evaluate without editing: `gridcraft-cli eval '=SUM(A1:A9)' --in book.xlsx` or `formulas.evaluate` / `evaluate_formula`. A formula that could not be typed into a cell (parse error, wrong argument count) is an error that says why, not a silent `#VALUE!` (`crates/engine/src/cmd/formulas.rs::evaluate`; `apps/gridcraft-cli/src/main.rs::eval`).
- Calculation settings travel with the workbook: automatic / automaticExceptTables / manual, iterative on/off, max iterations and max change (`formulas.calculationOptions`; `crates/model/src/workbook.rs`).
- New hardening at v0.12.1: accounting negatives such as `$(1,234)` and `(5)%` read as negative numbers when typed, coerced or passed to VALUE; `INDEX(A1:C3,2)` with one index on a 2-D reference is `#REF!` as in Excel; REGEXREPLACE bounds each replacement; 16-million-cell budget charged before scanning (`crates/functions/src/{text,lookup,math}.rs`, `crates/calc/src/eval.rs`, `docs/function-parity.md` revision history).

### Files it reads and writes
- **`.xlsx` is native read/write**: cells, shared/array/dynamic formulas, styles, themes (including per-script typefaces), merges, conditional formats, validation, tables, notes (with box position and size) and threaded comments, hyperlinks, names, freeze panes, outlines, print settings, pictures (shared media written once), shapes incl. ink, sparklines, PivotTables, sheet/workbook protection and Allow Edit Ranges, calc settings, `<workbookPr showObjects>` — `crates/engine/src/io.rs`, `crates/xlsx/src/{read,write,sheet_read,sheet_write}.rs`, `docs/file-format-parity.md`.
- **Pass-through on save** (kept byte-for-byte when their owner survives): custom document properties, ribbon customisation, custom XML, external workbook links (never followed or refreshed), data connections, sheet query tables, printer settings, form/ActiveX controls, OLE objects, sheet backgrounds with their VML, header/footer pictures, and chart sheets — `crates/xlsx/src/passthrough.rs`.
- `.xlsm` / `.xltm` keep their VBA project byte-for-byte; macros are **never executed**. `.xltx`/`.xltm` save with the template content type — `crates/xlsx/src/lib.rs` (`XlsxKind`), `crates/xlsx/src/write.rs`, test `macros_are_saved_only_into_xlsm` in `crates/engine/src/io.rs`.
- **Import-only**: `.xls`/`.xlt` (BIFF8: values, formulas, number formats, merges, sizes, names, calc and sheet-display settings from WINDOW2; chart/macro/dialog sheets skipped), `.xlsb` and `.ods` (worksheet values and cached formula results only) — `crates/xlsx/src/xls/`, `crates/xlsx/src/{xlsb,ods}.rs`, `docs/{xlsb,ods}-import.md`.
- **Text/data**: CSV and TSV/TXT/TAB with delimiter/encoding detection (UTF-8/UTF-16, likely Windows-1256 Arabic, otherwise Windows-1252); writes the *displayed* text, keeps the separator a file was opened with, refuses output over 512 MiB; `file.open {csvAsText:true}` keeps every field as text — `crates/xlsx/src/csv.rs`, `crates/engine/src/io.rs::csv`. `.json` is a debug serde dump of the internal model (unstable, not an interchange format). HTML exports one sheet as a table (pictures as data-URI images, charts as inline SVG; refuses more than 100,001 rows) — `crates/engine/src/io.rs::to_html` (`HTML_EXPORT_MAX_ROWS`).
- **`.pdf` export**: own PDF 1.7 writer (no dependencies); `file.exportPdf {path?, sheets?: active|all, range?, fitToPage?}` returns `{pages, bytes, path}` or base64; `file.print` returns the same PDF; the CLI `convert` accepts `.pdf`. `http(s)` hyperlinks and internal cell destinations become real PDF link annotations; `file:` links are omitted — `crates/pdf/src/lib.rs`, `crates/engine/src/cmd/print.rs`, `apps/gridcraft-cli/src/main.rs::convert`.
- **Password-encrypted `.xlsx` open** (Agile AES and Standard encryption, [MS-OFFCRYPTO]) via a `password` param; the workbook opens with no save path and always saves **unencrypted**. New at v0.12.1: the Agile `dataIntegrity` HMAC is verified before plaintext is returned (#2425). RC4/Extensible and encrypted `.xls` are refused — `crates/xlsx/src/crypto.rs`, `crates/engine/src/io.rs`.
- **Save is refused** for `.xls`, `.xlsb`, `.ods` with an explanatory message (`crates/engine/src/io.rs::save_bytes_as`). Content wins over the extension: an ODS/XLSB package is imported as what it is; an XLSX package is never misread as ODS/XLSB.
- Hard caps: 512 MB per decompressed XLSX part and 1 GB per package (`crates/xlsx/src/package.rs`), 2 GB per file read (`crates/engine/src/io.rs::MAX_READ_BYTES`), 100,001 HTML rows, 512 MiB CSV/TSV output (`crates/xlsx/src/csv.rs::MAX_CSV_BYTES`), 16,000,000 cells per array result (`crates/calc/src/eval.rs::MAX_CELLS`).

### Charts, PivotTables and analysis
- **26 `ChartKind`s** (25 at v0.11.1; added 100% Stacked Area, `AreaStacked100`): column/bar/line/pie/doughnut/area/scatter/bubble/radar/histogram/waterfall/funnel/treemap/sunburst/box-whisker/stock/combo and subtypes; chartex parts for histogram/box-whisker/waterfall/funnel/treemap/sunburst, six trendline types, PivotCharts (`insert.pivotChart`), Recommended Charts, Select Data, Switch Row/Column, Change Type/Colours/Layout — `crates/model/src/features.rs` (`ChartKind`, `TrendlineKind`), `crates/xlsx/src/{chart,chartex}.rs`, `crates/engine/src/cmd/{insert,extra}.rs`, `docs/chart-parity.md`.
- Chart objects move and resize: drag the bottom-right corner or use `chart.set {at, width, height}` (`crates/ui-egui/src/grid.rs` `Drag::Object`, `crates/ui-egui/src/panes.rs`). All 2-D kinds survive the XLSX round trip; area charts saved as `percentStacked` open as 100% stacked.
- PivotTables: field list, Filters/Rows/Columns/Values areas, report filters, layouts, date grouping, show-values-as, calculated fields, values on rows, grand totals (`rowGrandTotals`/`colGrandTotals`), styles, refresh, change source; round-trip to/from XLSX — `crates/engine/src/cmd/pivot.rs`, `crates/xlsx/src/pivot.rs`. New at v0.12.1: **Show Details** (`pivot.showDetails {cell?}`, also double-click or the cell menu) lists the source records on a new sheet, and **Enable show details** (`pivot.options {enableShowDetails}`, XLSX `enableDrill`) can turn it off.
- Data tools: sort (multi-key), AutoFilter (values/colour/top-10/custom, grows the range when a value is typed in the row below), Advanced Filter, remove duplicates, text-to-columns, Flash Fill, group/ungroup/subtotals, consolidate, scenario manager, Goal Seek, data table — `crates/engine/src/cmd/{data,whatif}.rs`, `docs/parity-checklist.md` (Data 23/28). New at v0.12.1: **Outline Settings** (`data.outlineSettings {summaryBelow?, summaryRight?}`, XLSX `outlinePr`) and **Show Outline Symbols** (`view.showOutlineSymbols {on?}`, Ctrl+8).
- Solver (`data.solver`: Simplex LP with integer/binary branch-and-bound, augmented-Lagrangian nonlinear method, Evolutionary; Answer and Limits reports), Forecast Sheet with hindcast (`data.forecastSheet`), Analysis ToolPak (`data.analysisToolPak`, 13 of Excel's 19 tools) — `crates/engine/src/cmd/{solver,forecast,analysis}.rs`.
- Printing: native macOS/Windows/Linux printing through the pinned shared `craft-print` library (printer choice, copies, duplex, grayscale), Page Setup, Page Break Preview, Page Layout view with rulers, draggable margins and in-place header/footer editing; printing follows Scale with Document and Align with Page Margins — `apps/gridcraft/Cargo.toml`, `apps/gridcraft/src/print.rs`, `crates/engine/src/cmd/print.rs`, `docs/ui-parity.md`.
- Conditional formatting's New Formatting Rule formula box takes references clicked or dragged on the grid (#2348), recorded as absolute references — `crates/ui-egui/src/dialogs.rs`.

### Automation surface (the reason to read this skill)
Counts at this tag, with v0.11.1 in brackets: **353 engine commands** (346); **275/291 catalog ids** (unchanged); **21 MCP tools** (21); **11 CLI subcommands** (11); **31 documented control-channel methods** (31) with 34 dispatch arms including aliases; **15 UI-only command ids** served by `engine.commands` (14 — added `view.expandFormulaBar`); **70 shortcut bindings on command specs** (68); **365 key-tip sequences** (365); **19 interface languages** (19); **26 chart kinds** (25); **513/523 worksheet functions** (513/523); **3 MCP resources** (3); **14 `check` round-trip categories** (14).

- **CLI `gridcraft-cli`** (headless; the app bundle ships no CLI): `info`, `convert`, `eval`, `cat`, `check`, `run`,
  `commands`, `functions`, `mcp`, `send`, `version` — `apps/gridcraft-cli/src/main.rs` (USAGE), `docs/cli.md`.
- `check` is the one to remember: it recalculates every formula against the file's Excel-cached values (skipping
  volatile formulas and `fullCalcOnLoad` files), then writes and re-reads the workbook through GridCraft's own XLSX
  writer and compares 14 categories — package, sheets, values, formulas, numFmts, merges, names, tables, condFormats,
  validations, charts, comments, hyperlinks, pivots — and validates the package (content types, relationship
  targets/ids). Flags `--tolerance 1e-9` and `--max-report N`; exit 1 on any difference, 2 on a usage error; `--json`
  emits schema `gridcraft-check/1`; discovery caps at depth 32 and 100,000 files and reports omissions as failures
  (`apps/gridcraft-cli/src/check.rs`).
- **MCP server** over stdio, protocol `2025-06-18` (older `2025-03-26`/`2024-11-05` clients are answered in their own version); headless (`--in FILE | --sample NAME`) or remote (`--connect PORT`). 21 tools:

| Tool | Does |
|---|---|
| `execute_command` | any command id + params |
| `list_commands` | ids, labels, ribbon paths, shortcuts, param docs; `search?` |
| `inspect_workbook` | sheets, used ranges, tables, charts, names, selection, history |
| `read_range` | `range?`, `sheet?`, `formulas?`, `formatted?` |
| `write_range` | `range`, 2-D `values`; strings starting `=` are formulas |
| `set_cell` / `get_cell` | enter one cell / value, formula, display text, style, merge, comment, link |
| `evaluate_formula` | `formula`, optional `cell`; never changes the sheet |
| `select` | `range`, `active?` (comma-separated areas allowed) |
| `format_range` | bold, italic, underline, font name/size/colour, fill, number format, alignment, wrap, border presets |
| `insert_chart` | `range`, `type`, `subtype?`, `title?`, `at?` |
| `create_table` | `range`, `style?`, `header?`, `name?` |
| `sort_range` | `keys` (`"B"`, `"B desc"` or `{column, order}`), `range?`, `header?` |
| `filter` | `column`, `range?`, `values?`, `custom?`, `top?`, `blanks?`, `clear?` |
| `open_workbook` / `save_workbook` / `new_workbook` | path / path? / sample? |
| `undo` / `redo` | `steps?` |
| `screenshot` | `path`; remote/desktop only |
| `list_functions` | `search?`, `category?` |

Resources: `gridcraft://workbook`, `gridcraft://commands`, `gridcraft://functions`; `prompts/list` is empty. `gridcraft-mcp` is also a library (`Server::new(Box::new(Headless::new()))`, `Remote::connect`) — `crates/mcp/src/{tools,server,headless,backend}.rs`, `docs/mcp.md`. The MCP crate was untouched at this tag, so its tool set is identical to v0.11.1.

- **Control channel**: the app started with `--control <port>` (or `GRIDCRAFT_CONTROL_PORT`) accepts newline-delimited
  JSON on `127.0.0.1`; each line gets one reply line.
  - Read state: `engine.execute`, `engine.commands` (also lists UI-only ids), `engine.journal` (10,000 entries / 64 MB,
    passwords stripped), `document.inspect`, `sheet.read`, `cell.get`, `selection.stats`, `ui.inspect`.
  - Drive: `ui.click|drag|move`, `ui.cell.click|drag`, `ui.key|text`, `ui.edit.begin|text|commit|cancel`, `ui.ribbon`,
    `ui.dialog|set|confirm|cancel`, `ui.message.dismiss`, `ui.menu.invoke`.
  - Window/app: `ui.screenshot` (PNG, animations settled), `ui.set`, `ui.resize`, `ui.focus`, `app.open|save|quit`.
  - `ui.backstage {page: home|new|open|info|saveAs|print|export|options|account|close}` and `ui.ribbonTab` are commands;
    any other method that is a command id runs that command — `crates/ui-egui/src/control.rs`, `docs/control-protocol.md`.
    Limits and failure modes are in "How to operate".
- **UI-only commands** reachable over `engine.execute`/MCP (`engine.commands` marks them `"ui": true`): `ui.ribbonTab`, `view.collapseRibbon`, `view.expandFormulaBar` (new, Ctrl+Shift+U), `view.darkMode`, `view.theme {mode: system|light|dark}`, `view.animations`, `options.autoComplete`, `view.interfaceScale {percent: 75–200|"auto"}`, `ui.dialog`, `ui.backstage`, `ui.printSettings`, `ui.printSubmit`, `app.language.set`, `app.language.english`, `app.language.japanese` — `crates/ui-egui/src/control.rs` (`engine.commands` arm).
- **Recorded scripts** (Automate tab): `automate.recordActions {stop?, name?}` records into a recording buffer
  (`crates/engine/src/record.rs`; 100,000 steps / 64 MB cap, each step keeps its document, sheet and selection);
  `automate.newScript {name, commands}`, `automate.allScripts` (also reports a preserved `(VBA)` project as never
  executed), `automate.runScript {name, trusted?}`, `automate.trustScripts {trusted?}`, `automate.deleteScript {name}`.
  - A workbook opened from a file that carries scripts starts untrusted; `runScript` refuses until trusted for the
    session. Steps may not call `file.*`, `link.*` or `window.*` or pass a `path`, and run inside a filesystem sandbox.
  - Scripts are stored in the workbook as the hidden defined name `_sc_scripts`, so they round-trip XLSX
    (`crates/engine/src/cmd/extra.rs`, `crates/engine/src/io.rs::ScriptSandbox`).
  - New at v0.12.1: `automate.stopAction` stops a left-running undo group and restores the workbook and its undo history.
- **New engine building blocks** (v0.12.1): undo groups (`automate.stopAction`, above), the recording buffer above,
  document `Trust` (`Trust::FromFile` vs new content, so an opened file's scripts never run by accident;
  `crates/engine/src/lib.rs`), and a chunked hidden-name stash `_gc_<key>_<n>` that splits long data across Excel-legal
  names, escapes XML-illegal characters and caps one item at 4,194,304 characters / 10,000 items
  (`crates/engine/src/cmd/stash.rs`).
  - Today scripts and custom views still use the single `_sc_*` name; `formulas.defineName` and `formulas.deleteName`
    refuse a name the stash occupies unless `force: true` (`crates/engine/src/cmd/formulas.rs`).
- **Web build**: same UI crate via eframe web runner, `trunk build --release` → `dist/web`; URL flags `?sample=`, `?webgl`, `?host=parent&author=`; preferences in `localStorage`; no TCP control channel (Open uses the browser picker, Save downloads) — `apps/gridcraft-web/src/main.rs`.
- **Programmatic calls never open dialogs**: `file.open`/`file.save`/`data.getData`/`data.fromTextCsv` without a file path return "missing `path`…: programmatic calls never open dialogs" (`crates/engine/src/lib.rs::execute_headless`).
- **Interface languages**: 19 (`Language::ALL`): en, es, el, zh, ja, ko, ru, pt, de, cs, fr, sr, tr, pl, it, uk, vi, nl, ro. Catalogs differ in completeness: ja 1,102 entries, ro 1,010, el/it/pl/uk 965, pt 959, cs 532, nl 513, then 400–455; untranslated strings fall back to English; command ids, document text, formulas and number formats stay English/en-US. `app.language.set {language|code}` switches at runtime; the desktop follows the system language until a choice is saved; missing translations are reported by `cargo xtask i18n-report` and never fail a check (`crates/ui-egui/src/i18n.rs`, `crates/ui-egui/src/i18n/*.rs`, `docs/localization-parity.md`).

## Known limitations and not-implemented

- **Partial:** `.xls` import covers values, formulas, number formats, merges, sizes, names, print area/titles, calc settings and WINDOW2 sheet-display options; no fonts, fills, borders, charts, pictures, comments, conditional formats, validation, hyperlinks or freeze panes; chart/macro/dialog sheets are skipped, BIFF5 and FILEPASS files refused. `.xlsb`/`.ods` import values and cached formula results only. None of the three is ever written (`crates/xlsx/src/xls/mod.rs`, `crates/xlsx/src/{xlsb,ods}.rs`, `crates/engine/src/io.rs`).
- **Encryption is read-only**: Agile and Standard `.xlsx` open with a password; saves are always unencrypted and have no save path, so Save asks where to go. RC4/Extensible and encrypted `.xls` are refused (`crates/xlsx/src/crypto.rs`, `docs/gaps.md` §7).
- **Macros never run.** VBA is carried byte-for-byte only into `.xlsm`/`.xltm`; any other save drops it. GridCraft's recorded scripts are not VBA (`crates/engine/src/io.rs` test `macros_are_saved_only_into_xlsm`).
- **Excel-repair-free output is unproven**: no real corpus and no Excel verification. Unmodelled content is dropped when its owner is rewritten — slicers and slicer caches, timelines, the data model, query tables attached to tables, unmodelled `extLst`; chart sheets are passed through unchanged but cannot be viewed, edited or created (`docs/gaps.md` §1/§3, `crates/xlsx/src/passthrough.rs`).
- **Slicers/timelines:** slicers can be created and clicked in-sheet but are not saved to XLSX; timelines are catalogued (`insert.timeline`) but not implemented (`crates/engine/src/cmd/slicer.rs`, `docs/parity-checklist.md`).
- **Charts are shallow:** no 3-D types, no axis options (min/max/log/units), no error bars, no per-point formatting; data labels and gridlines are just booleans; ~26 of Excel's ~60 subtypes (~43%), chart sheets are not editable. Move and resize do work; area charts now keep 100% stacking (`docs/chart-parity.md`, `crates/model/src/features.rs`).
- **PivotTables:** no calculated items, `GETPIVOTDATA`, timelines, value/label filters, number grouping or data-model pivots; Show Details and Enable show details exist but have no Options dialog (command only); XLSX round-trip has not been checked in Excel (`crates/engine/src/cmd/pivot.rs`, `docs/gaps.md` §8).
- **No Power Query or data model:** Get & Transform is only From Text/CSV (`data.fromTextCsv`), Get Data (`data.getData`: CSV/TSV or a JSON array of objects) and From Table/Range; Queries & Connections lists imported tables; Refresh All refreshes PivotTables only. No From Web, Stocks, Geography, Relationships or Analyze Data (`crates/engine/src/cmd/extra.rs`, `docs/parity-checklist.md` missing list).
- **Scale:** recalculation is single-threaded; the project reports ~100 MB workbooks failing to open (#175). Whole-range work is capped and refuses with an error instead of hanging (file caps above; `crates/calc/src/eval.rs` `MAX_CELLS`).
- **Text:** no complex shaping (Arabic, Devanagari, Thai) and no bidi; a right-to-left sheet mirrors the grid and HTML export, but text stays LTR inside its box and printing/PDF are not mirrored. PDF export sets characters outside WinAnsi in a predefined, **non-embedded** Adobe-GB1 CID font (STSong-Light / UniGB-UTF16-H): Chinese is tested; Japanese/Korean coverage depends on that font (uncertain — inspect the PDF); Arabic/Devanagari/Thai have no glyphs there (`crates/pdf/src/lib.rs`, `crates/pdf/src/tests.rs`, `docs/localization-parity.md`).
- **One OS window:** `view.newWindow` clones the workbook into another document (title suffix `:2`); `view.arrangeAll` does nothing (`crates/engine/src/cmd/extra.rs`).
- **Accessibility:** AccessKit is enabled but grid cells and the ribbon are not exposed as an accessible tree; Check Accessibility (`review.checkAccessibility`) is a basic scan (missing alt text, merged cells, default sheet names); no high-contrast mode (`docs/gaps.md` §18, `crates/engine/src/cmd/review.rs`).
- **No VBA/Office Scripts/add-in or custom-function API, no collaboration/co-authoring, no mobile build, no in-app AI** (`docs/gaps.md` §16/§21–23).
- **Functions:** 18 of Excel's 523 names are absent (including GETPIVOTDATA, IMAGE, STOCKHISTORY, TRANSLATE, DETECTLANGUAGE, CALL, REGISTER.ID, RTD, COPILOT, PY) and 9 are error stubs (7 CUBE functions, WEBSERVICE, FILTERXML) — `docs/function-parity.md`, `crates/functions/src/info.rs`.
- **HTML is export-only:** opening `.html`/`.htm` with `file.open` falls through to the CSV/TSV reader, so a saved web page opens as delimited text, not as a table (`crates/engine/src/io.rs::open_plain`).
- **Objects:** inserted icons lose their artwork on XLSX save (#551); Office InkML is not imported; pictures must be PNG/JPEG (`docs/gaps.md` §17, `crates/engine/src/cmd/insert.rs`).
- **Save semantics:** only `.xlsx` and `.json` saves clear the dirty flag and become the document's file; `.csv/.tsv/.html/.pdf` are exports that leave the workbook dirty. `file.close {force:true}` and the control-channel `app.quit` discard unsaved changes without asking (`crates/engine/src/cmd/file.rs::save`, `crates/ui-egui/src/control.rs`, `crates/ui-egui/src/lib.rs::guard_window_close`).
- **Groundwork, not a feature:** `crates/ui-egui/src/code_editor.rs` (new at v0.12.1, Python and LaTeX syntax colours) is exported from `widgets` but no dialog uses it yet — there is still no Python-in-cells (`PY`) or equation editor. The Multi-line formula bar and ribbon overflow arrows/split button are UI-only (not commands).
- **Stale repo prose** (verify against code, not docs): README says "89% of standard ribbon commands" while the
  generated checklist says 275/291 = 94.5%, and its key-tip paragraph still calls the support "initial";
  `docs/target-app-parity.md` still reports 274/290 and "313 command ids".
- More stale rows: `docs/gaps.md` §5 (PDF fonts), §9 ("59 command shortcuts"), §11 ("no localization at all"), §13
  ("`data.solver`, `data.analysisToolPak` missing"), §19 (CSV "raw values") and its "charts can't be resized"/§8
  missing-command rows all contradict the code; `docs/ui-parity.md` still says 59 shortcuts and a 364-sequence key-tip
  table (code: 70 and 365); `docs/file-format-parity.md` says the Agile data-integrity HMAC is not checked (it is,
  #2425); `docs/control-protocol.md`'s language/Backstage notes lag `crates/ui-egui/src/i18n.rs` and
  `crates/ui-egui/src/backstage.rs`; `docs/function-parity.md`'s category table totals 505/496 while its "Measured"
  line says 513/504. Prefer code and the generated `docs/parity-checklist.md`.

## How to operate

### macOS launch, flags, environment
- `open -a GridCraft`; `open -a GridCraft book.xlsx` — Finder double-clicks and `open` arrive as Apple events, and files dropped on the window open too (`apps/gridcraft/src/apple_events.rs`, `apps/gridcraft/src/main.rs`).
- The binary takes only these flags: `/Applications/GridCraft.app/Contents/MacOS/GridCraft [--control PORT] [--sample budget|sales|grades] [files…]`; `--version` prints `GridCraft 0.12.1`. There is no other CLI surface in the bundle (`apps/gridcraft/src/main.rs`).
- Environment: `GRIDCRAFT_CONTROL_PORT=<port>` (same as `--control`), `GRIDCRAFT_NO_PREFS=1` (reads/writes no `ui.json`/`prefs.json` and keeps no log file — the mode for agent test runs), `GRIDCRAFT_NO_NATIVE_MENU`, `RUST_LOG` (env_logger-style directives; default gridcraft crates `info`, everything else `warn`).
- Settings and logs live under `Library/Application Support/GridCraft/` in the user's home: `ui.json`, `prefs.json`, and `logs/gridcraft.log`, rotated to `.1`/`.2` at each start, 16 MiB cap (`apps/gridcraft/src/{main,logging}.rs`, README.md §Logs).

### The CLI (installed separately)
The bundle ships no CLI. Install with `cargo install --path apps/gridcraft-cli` from a source checkout, or the release zip `gridcraft-cli-<ver>-macos-universal.zip` (README.md Downloads; `docs/cli.md`).

```sh
gridcraft-cli info book.xlsx [--json]
gridcraft-cli convert in.xls out.xlsx [--sheet Sales]     # .xlsx/.csv/.tsv/.json/.html/.pdf by extension
gridcraft-cli eval '=XLOOKUP("b",{"a","b"},{1,2})'        # → 2
gridcraft-cli cat book.xlsx --range A1:F20 [--formulas|--csv]
gridcraft-cli run --in book.xlsx --cmd 'cell.set={"cell":"D2","input":"=B2*C2"}' \
    --cmd 'edit.fillDown={"range":"D2:D20"}' --out book.xlsx --print A1:D5
gridcraft-cli check corpus/ --json --tolerance 1e-9       # calc oracle + XLSX round-trip fidelity
gridcraft-cli commands --search chart                     # every command and its params doc
gridcraft-cli functions --category statistical            # function list with signatures
gridcraft-cli send 7979 engine.execute '{"command":"home.bold","params":{"range":"A1:C1"}}'
```

- `run` flags: `--in FILE | --sample NAME`, repeated `--cmd`, `--script FILE`, `--out FILE`, repeated `--print RANGE|used`, `--sheet`, `--quiet`, `--csv`, `--formulas`. A `--cmd` is `id`, `id={json}` or `id {json}`; a script has one step per line in the same forms or as `{"command":…,"params":…}` objects; blank lines and lines starting with `#` or `//` are skipped. The first failing step stops the run with a non-zero exit (`apps/gridcraft-cli/src/main.rs::run`).
- `convert` refuses an unknown output extension; `.pdf` goes through `file.exportPdf` and reports bytes/pages.
- `check` never writes next to its inputs. Exit 0 means every file opened, every checked formula matched its cached value and every round trip was clean; `--json` output is schema `gridcraft-check/1` (`apps/gridcraft-cli/src/check.rs`).

### MCP
```sh
claude mcp add gridcraft -- gridcraft-cli mcp                     # headless in-process session
claude mcp add gridcraft-app -- gridcraft-cli mcp --connect 7979 # drive the visible app
```
Results are one text block holding pretty JSON; failures set `isError: true`. Unknown tools, missing/wrong arguments are JSON-RPC `-32602`; malformed JSON `-32700`; unknown methods `-32601` (`crates/mcp/src/server.rs`, `docs/mcp.md`). The remote backend uses a 30 s socket timeout: after a timeout, re-read the state instead of retrying blind (`crates/mcp/src/backend.rs`).

### Control channel (drive the running app)
```sh
/Applications/GridCraft.app/Contents/MacOS/GridCraft --sample sales --control 7979
# then, newline-delimited JSON to 127.0.0.1:7979:
{"id":1,"method":"engine.execute","params":{"command":"cell.set","params":{"cell":"B2","input":"=SUM(A1:A9)"}}}
{"id":2,"method":"ui.screenshot","params":{"path":"shot.png"}}
```
- Run `ui.inspect` first (ribbon tab, editor, open dialog, Backstage page, message, grid rect, scroll, perf) and act on what it shows; `ui.inspect` also reports `documents` and the active index. `ui.screenshot` needs a presented frame: if the window is hidden/minimised it answers "no frame was presented before the screenshot timeout; make the window visible, use `ui.focus`, then retry" (`crates/ui-egui/src/control.rs`).
- Limits: 64 MiB per request line; 10,000 queued synthetic pointer events; the server waits 60 s for the UI, then reports a timeout. A request the client abandoned is dropped unrun; if the app had already started it, the reply says the outcome is unknown — read the cell/state before retrying (`apps/gridcraft/src/control_server.rs`, `crates/ui-egui/src/control.rs`).
- The port is unauthenticated and binds localhost only. Do not expose it; any local process can run every command.
- `ui.dialog.confirm` sends exactly what the dialog's OK sends; `ui.dialog.cancel` closes it; dialogs without an OK command return "this dialog has no OK command; drive it with its own commands".

### Document model and save/export flow
- One window, several documents; the Window menu (`view.switchWindows`, `window.activate`, `view.hideWindow`) switches/hides them. Sheet tabs at the bottom. File opens the Backstage with 9 pages: home, new (three samples), open (recents), info, saveAs, print, export, options, account (`crates/ui-egui/src/backstage.rs`).
- Save (`file.save`, `file.saveAs`, ⌘S, ⇧⌘S): the extension picks the format — `.xlsx` (default), `.csv`, `.tsv`, `.json`, `.html`, `.pdf`; a `.pdf` save exports the sheet and leaves the document dirty, unsaved and pointing at its old file. `file.saveBytes {format}` returns base64 without writing (formats: xlsx/csv/tsv/json/html) (`crates/engine/src/cmd/file.rs`).
- Exports: `file.exportPdf {path?, sheets?: active|all, range?, fitToPage?}` (no path → base64 + page count), `file.exportCsv {path, sheet?}`, `file.exportHtml {path}`, `file.printPreview {page?, sheets?}`, and on the desktop `ui.printSettings` / `ui.printSubmit` (native jobs via craft-print; poll `ui.printSettings` until not busy) (`crates/engine/src/cmd/{file,print}.rs`, `docs/control-protocol.md`).
- Opening a `.xls`/`.xlsb`/`.ods` produces a document titled `<name> (imported).xlsx` with no save path; opening an already-open path just switches to it; a password-decrypted workbook also has no save path (`crates/engine/src/cmd/file.rs::open`).

### Keyboard essentials (verified)
- 70 shortcut bindings on command specs (68 at v0.11.1; added F3 → Paste Names and Ctrl+8 → Show Outline Symbols),
  plus a wider keymap table for number formats, borders, F-keys and Alt/Option combinations.
- Essentials: ⌘S save, ⇧⌘S Save As, ⌘O open, ⌘N new, ⌘W close, ⌘Z undo, ⌘Y redo; ⌘B/⌘I/⌘U; ⌘1 Format Cells (Ctrl+1 on
  Windows); ⌘D fill down, ⌘R fill right; ⌃E Flash Fill (⌘E centres); ⌘T table; ⌘K link; Ctrl+Shift+L filter; F2 edit;
  F3 Paste Name (when the workbook has names); Ctrl+Shift+4 currency; Ctrl+Shift+7 outline border; Ctrl+` show formulas;
  F9 calculate; Ctrl+[ / Ctrl+] select precedents/dependents (add Shift for every level); Ctrl+6 hide/show objects;
  Ctrl+8 outline symbols; Ctrl+Shift+U expand/collapse the formula bar — `crates/ui-egui/src/{ribbon,keymap,grid}.rs`,
  `docs/ui-parity.md` §Shortcut audit.
- Key tips: F10 on any platform (Fn+F10 if needed) or left Alt on Windows/Linux/BSD, then sequence letters; 365 sequences cover every ribbon tab, including `F` → File view. README's "initial support" sentence is stale (`crates/ui-egui/src/keytips/keytips.json`, `crates/ui-egui/src/keytips.rs`).
- The macOS native menu has Tools ▸ Command Palette… (⌘⇧P), which opens the `commandSearch` dialog (`apps/gridcraft/src/native_menu.rs`, `crates/ui-egui/src/dialogs.rs`).

## Working with an AI agent

**Prefer headless over GUI.** For read/write/convert/verify jobs use `gridcraft-cli` (or MCP) on files: no window, no preferences (set `GRIDCRAFT_NO_PREFS=1` if you launch the app), deterministic. Drive the GUI over the control channel only when the task is genuinely about the UI: dialogs with no command equivalent, visual state, screenshots, native printing. Never drive blind — `ui.inspect`/`ui.screenshot` before and after, and act on what they show.

Legitimate agent work:
- **Prepare inputs.** Build `.xlsx` from commands (`gridcraft-cli run --script steps.jsonl`), convert `.xls`/`.xlsb`/`.ods`/CSV/TSV into `.xlsx`, or generate CSV/TSV/JSON and import with `data.fromTextCsv`/`data.getData`. Use `file.open {csvAsText:true}` when leading zeros and digit-only identifiers must survive. Remember an import opens as an unsaved "(imported).xlsx".
- **Interpret/repair files.** XLSX is native and documented in code (`crates/xlsx/src/`); the `.json` workbook is a debug serialization, not a long-lived interchange format. "Repair" means: open in GridCraft, inspect (`info`, `check`), fix with commands or formulas, save as `.xlsx`. Do not promise recovery of parts GridCraft does not model (slicers, timelines, data model, chart-sheet editing).
- **Verify exports honestly.** Run `gridcraft-cli check` on round-tripped files, compare `cat`/`info` output against expectations, check PDF page counts and links. A zero exit from `check` means GridCraft agrees with itself and with the file's cached values; it does **not** prove Excel will open the file without a repair prompt (explicitly unverified, `docs/gaps.md` §1).
- **Scripts.** Recorded scripts are a convenience layer over the same command ids, not a separate API. A workbook received from elsewhere carries its scripts as a hidden name; nothing runs until the workbook is trusted (`automate.trustScripts`, or `runScript {trusted:true}` once), and script steps cannot touch files, links or windows — run those commands directly. A leftover undo group blocks undo/redo: clear it with `automate.stopAction`.

Must NOT attempt:
- Writing `.xls`/`.xlsb`/`.ods`, or saving password protection; expecting macros to run; expecting slicers/timelines to survive a save; assuming HTML import; assuming multiple windows per workbook.
- Raw XML surgery on `.xlsx` files that contain unmodelled parts (slicer caches, VML, custom XML): GridCraft's own writer is the supported path, and even it drops parts it does not model once it rewrites them. Prefer read-only analysis of such files.
- Treating formulas as locale-independent without checking `docs/formula-input.md`: Spanish input/display exists, but files, commands and APIs use canonical English names and `,` separators.
- Promising PDF output for Arabic, Devanagari or Thai (no glyphs in the CID font, no shaping); verify CJK output visually first.
- Calling `app.quit` or `file.close {force:true}` while a workbook has unsaved changes: both discard them silently. Save first.

## Verification protocol (alpha discipline)

1. **Throwaway round-trip before real work**: new workbook → the exact edit → save `.xlsx` → reopen (or `gridcraft-cli info`/`cat`) → `gridcraft-cli check file.xlsx`. Add the source file itself to `check` when testing formula fidelity: it recalculates and compares against Excel-cached values.
2. **Never trust a silent export.** CSV/HTML/PDF are one-shot exports with no diff UI. Re-read or re-import the artifact (`cat`, `--json`, PDF page count/links, open the PDF elsewhere). Remember PDF export cannot be assumed to render Arabic/Devanagari/Thai.
3. **Version and back up.** Keep the previous copy of any workbook you edit; autosave covers only workbooks that already have a file, and there is no crash-recovery soak (`docs/gaps.md` §10). For agent runs, save after each logical step (`--out`) rather than at the end.
4. **Update between projects, not during.** The app auto-updates through the ArtCraft Launcher; update, then re-run your round-trip before a new task. The repo at a tag is the source of truth for what a version can do.
5. **After a control/MCP timeout, re-read state** (`cell.get`, `sheet.read`, `document.inspect`) before retrying: a queued request is dropped, but one already taken may still finish.
6. **Trust deliberately.** Do not call `automate.trustScripts` on a workbook you did not create unless the user asked you to run its scripts.

## Sources & evidence

- Repo: https://github.com/storytold/gridcraft — inspected at tag **v0.12.1**, commit `f86aec12dabc744b5f75e1033f87bfe685e78481` ("Release 0.12.1", 2026-10-25). The installed `/Applications/GridCraft.app` reports `0.12.1`, its `GridCraftBuildCommit` is that SHA and its binary prints `GridCraft 0.12.1`. If your installed version differs, verify against it.
- Date of inspection: 2026-10-26. Repo treated read-only (not built or modified).
- Key files read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`, `docs/{cli,mcp,control-protocol,parity-checklist,function-parity,chart-parity,file-format-parity,gaps,ui-parity,localization-parity,hardware-parity,target-app-parity,architecture,cell-pictures,formula-input,xlsb-import,ods-import}.md`,
  `apps/gridcraft-cli/src/{main.rs,check.rs}`,
  `apps/gridcraft/src/{main.rs,control_server.rs,logging.rs,apple_events.rs,native_menu.rs}`,
  `apps/gridcraft-web/src/{main.rs,web.rs}`, `crates/engine/src/{io.rs,lib.rs,sample.rs,catalog.rs,record.rs}`,
  `crates/engine/src/cmd/*.rs` (incl. `stash.rs`, new at this tag),
  `crates/xlsx/src/{lib.rs,read.rs,write.rs,csv.rs,crypto.rs,passthrough.rs,pivot.rs,chart.rs,chartex.rs,package.rs}`,
  `crates/xlsx/src/{xls,xlsb.rs,ods.rs}`, `crates/pdf/src/{lib.rs,tests.rs}`,
  `crates/mcp/src/{tools.rs,server.rs,backend.rs}`,
  `crates/ui-egui/src/{control.rs,keymap.rs,ribbon.rs,lib.rs,dialogs.rs,grid.rs,tabs.rs,i18n.rs,backstage.rs,code_editor.rs,theme.rs,formula_bar.rs}`,
  `crates/ui-egui/src/i18n/*.rs`, `crates/ui-egui/src/keytips/keytips.json`,
  `crates/model/src/{features.rs,workbook.rs,sheet.rs}`, `crates/functions/src/`, `crates/calc/src/eval.rs`,
  `apps/gridcraft/Cargo.toml`.
- Counts were re-measured from code, not prose: commands by unique `cmd!` ids plus the one literal `CommandSpec`; catalog coverage by intersecting `crates/engine/src/catalog.rs` with registered ids (matches the generated `docs/parity-checklist.md`); functions by `f!` specs plus `SPECIAL_FUNCTIONS`; keytips by the `sequences` array; shortcuts by each `cmd!` spec's shortcut argument; languages by `Language::ALL`.
- Shared library: `craft-print` pinned from `storytold/craft-libs` at revision `d27646a5f7c8b4fc85d9dd3213b8c88b58e0088d` (`apps/gridcraft/Cargo.toml`) for native print submission; PDF generation stays in GridCraft (`crates/pdf`).
- Deeper per-topic reference (repo docs): `docs/target-app-parity.md` (authoritative assessment, some counts stale), `docs/gaps.md` (ranked work list, partly stale), `docs/architecture.md` (layering; 2026-10-24 row lists the new engine building blocks), `docs/roadmap.md` (beta gates), `docs/parity-checklist.md` (generated from the catalog).

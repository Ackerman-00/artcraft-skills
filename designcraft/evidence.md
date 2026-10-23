# evidence.md — DesignCraft SKILL.md claim audit

App: **DesignCraft** (`storytold/designcraft`) · Tag **v0.12.0** · HEAD
`5e8ef678321cfdd2d18927e2af94d58e5f9d8836` · inspected 2026-10-23.

Installed bundle `DesignCraft.app` reports `CFBundleShortVersionString 0.12.0` and
`DesignCraftBuildCommit 5e8ef678321cfdd2d18927e2af94d58e5f9d8836` — **identical to the repository
HEAD** — and `Contents/MacOS/DesignCraft --version` prints `designcraft 0.12.0`; no HEAD/installed
divergence exists at this pin. The bundle was inspected (Info.plist, `--version` only), never
launched. `designcraft-cli` is **not** installed on this machine (`which designcraft-cli` → not
found).

Status legend: **implemented** = code path exists and is wired into the UI/CLI/control surfaces;
**partial** = code exists but visibly incomplete (what is missing is named); **claimed** = stated
in docs/README but not confirmed in code; **not implemented** = absent by design or not yet built.

| # | Claim in SKILL.md | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Page-layout/publishing app in pure Rust targeting InDesign 2026 parity; clean-room; MIT OR Apache-2.0; pre-alpha | `README.md` (tagline, "written in Rust", "runs on macOS, Windows, Linux and the web"), `AGENTS.md:1-3` ("clean-room… targeting Adobe InDesign parity"), `ROADMAP.md:3` ("Stage: pre-alpha"), `Cargo.toml:7-10` (`version = "0.12.0"`, `license = "MIT OR Apache-2.0"`, `rust-version = "1.95"`), `docs/target-app-parity.md` headline (~80% breadth, ~47% ready) | implemented (maturity/percentages are the maintainers' estimates) |
| 2 | Runs natively on macOS/Windows/Linux and as WebAssembly; web has no control channel and downloads saves/exports | `apps/designcraft/`, `apps/designcraft-web/` (trunk; `README.md` §Web: WebGPU/WebGL2, `?webgl`, `?sample`, "Save and Export download the file. The web build has no control channel") | implemented |
| 3 | Every user-visible action is a command with JSON params; UI, CLI, control and MCP share `Session::execute` | `crates/engine/src/lib.rs` (module doc and `execute`), `crates/engine/src/cmd/mod.rs:167` (`command_specs()`), `crates/ui-egui/src/control.rs:149` (`handle_request`), `crates/mcp/src/tools.rs` | implemented |
| 4 | **527** engine command specs + **166** UI commands at v0.12.0; +6 engine / +2 UI vs v0.11.0, none removed; MCP remains 26 | Recomputed this session with a brace-aware `#[cfg(test)]` block remover: unique `cmd!` ids = **521** at v0.11.0 → **527** at v0.12.0 (+`guide.select`, `guide.selectAll`, `guide.deselect`, `guide.moveBy`, `layout.moveColumnGuide`, `view.lockColumnGuides`; 0 removed), across 61 `specs()` lists; `UI_COMMANDS` = **164 → 166** (+`view.lockGuides`, `window.importShortcuts`); `crates/mcp/src/tools.rs:83` `tool_definitions` = 26. The previous skill's 485 does not match the v0.11.0 tree: a brace-aware count gives 521, so 485 was an undercount (likely from truncating at the first `#[cfg(test)]`, which can precede the specs) | implemented (counts code-derived; discover live with `commands` / `engine.commands`) |
| 5 | Ruler guides: add/list/select/select-all/move/moveBy/delete/deleteAll; selected like objects; dragged guide snaps, Shift=ticks, Cmd=no snap; `view.lockGuides` only blocks pointer dragging | `crates/engine/src/cmd/guides.rs` (specs and handlers: `add`, `move`, `move_by`, `select`, `select_all`, `deselect`, `delete`, `delete_all`, `create_guides`, `lock_column_guides`); `crates/doc/src/selection.rs` (`GuideSel`, `Selection.guides`); `crates/ui-egui/src/canvas.rs` (`guide_drag`, `guide_spot`, column-guide drag); `crates/tools/src/snap.rs` (`Gesture::Guide`); `crates/ui-egui/src/guide_selection_tests.rs`; `crates/engine/src/cmd/guides.rs` `check_editable` / `Guide::editable_in` | implemented (GUI drag/selection verified by tests and code, not by launching the app) |
| 6 | Custom column guides: per-page positions, `layout.moveColumnGuide`, 216 max, inspect fields, IDML `ColumnsPositions`/`ColumnGuideLocked`, locked by default, mirroring across the spine | `crates/doc/src/page.rs:46` (`MAX_COLUMNS = 216`), `valid_column_positions`, `Columns::{edges,with_gutter_moved,mirrored}`; `crates/engine/src/cmd/layout.rs` (`layout.moveColumnGuide` spec at ~434, handler ~894, `column_guides_unlocked`); `crates/engine/src/cmd/inspect.rs:88-90` (`gutter`, `customColumns`, `columnRects`); `crates/doc/src/lib.rs:402-405,472` (`column_guides_locked`, default true); `crates/idml/src/{import,export}.rs` (`ColumnsPositions`, `ColumnGuideLocked`); `crates/doc/src/build.rs` (inserted pages, side changes) | implemented (IDML round-trip tested synthetically; no real InDesign file corpus) |
| 7 | `window.importShortcuts` reads InDesign Show Set `.txt` (UTF-8/UTF-16, Mac/Win names, ≤8 MiB), applies Default (Text for type/text commands), reports changed/conflicts/skipped/unmatched/unreadable; tools fixed; no `.indk`, no write | `crates/ui-egui/src/shortcut_import.rs` (module doc, `MAX_BYTES`, `decode`, `parse`, `read_keys`, `import` :359, report fields), `crates/ui-egui/src/menus.rs` UI command entry; `docs/file-format-parity.md` keyboard-shortcuts row; `docs/target-app-parity.md:420` | implemented; **partial** vs InDesign (one context, no Control chords, no set export) |
| 8 | Layout/document model: spreads, parents, sections, layers, typed frames, threaded stories; page setup/presets/bleed/slug; multi-document tabs and activation | `crates/doc/src/{page,story,item}.rs`; `crates/engine/src/cmd/{layout,thread}.rs`; `crates/engine/src/cmd/file.rs` (`file.new`, `file.activate`, `file.close`, `document.list`), `crates/ui-egui/src/menus.rs` (`window.nextDocument` Cmd+F6, `window.previousDocument` Cmd+Shift+F6) | implemented |
| 9 | Styles/swatches/wrap/corners/transparency/ICC; interactions (Pathfinder, compound/clipping, tables, footnotes/endnotes/notes, xref, index, TOC, variables, conditional text, track changes, data merge, XML, articles, libraries, books, object states, buttons/forms, transitions) | `crates/engine/src/cmd/*` (61 `specs()` lists; see `command_specs()`), `crates/doc/src/{styles,item}.rs`, `crates/engine/src/cmd/{colorsettings,conditions,changes,datamerge,xml,articles,library,book,states,buttons,transitions}.rs` | implemented (breadth; depth per feature varies) |
| 10 | Text engine: Knuth–Plass + single-line composer, dictionary hyphenation, bidi/RTL, CJK/mojikumi, vertical type, ruby/kenten/warichu/tate-chu-yoko; column rules and span columns | `crates/compose/src/{lib,breaker}.rs`, `crates/compose/src/{hyphen,bidi,mojikumi,ruby,kenten,warichu}.rs`; `crates/doc/src/item.rs` `column_rule*`; `crates/ui-egui/src/dialogs.rs` span-columns dialog; `crates/idml/src/*` column rules/span; `ROADMAP.md` text rows | implemented |
| 11 | Fonts: own DB, shaping/outlines, variable-font instances, `Document Fonts` folder (case-insensitive), `font.reload` | `crates/fonts/src/fontdb.rs`; `crates/engine/src/cmd/fonts.rs` (`font.list`, `font.replace`, `font.reload`); `crates/engine/src/cmd/file.rs` `load_document_fonts` / `document_fonts_folder` | implemented |
| 12 | Open/import: content-sniffed `.designcraft`/IDML/INDD/INDT; images PNG/JPEG/GIF/WebP/TIFF/BMP/PSD/SVG/PDF/EPS preview; text `.txt`/`.text`/`.md`/`.docx`/`.rtf`/XLSX/Tagged Text; media poster frames; `.ase`/ICC/XML/`.dclib`/`.dcbook`/page-of-document | `crates/engine/src/cmd/file.rs` `open_path` and `file.place` params; `crates/idml/src/import.rs`; `crates/engine/src/cmd/interchange.rs`; `crates/images/src/lib.rs` (`mime`, `is_pdf/is_psd/is_svg/is_eps`); `crates/textimport/src/lib.rs:94` (`is_text_file`); `crates/doc/src/item.rs:838` (`media_mime`); `crates/engine/src/cmd/{style,colorsettings,xml,library,book}.rs` | implemented (EPS preview only) |
| 13 | `.indd`/`.indt` convert to IDML in memory via indd-utils; INDB/INDL unread; real-file fidelity unmeasured | `crates/engine/src/cmd/interchange.rs` (`is_indd`, `indd::convert`, conversion warnings); `Cargo.toml` (`indd = { git = "…/indd-utils", branch = "main" }`); `docs/gaps.md` §2 | partial |
| 14 | Native `.designcraft`: zip with `mimetype` (stored first), `document.json`, `assets/<id>.<ext>`, `meta.json`, optional `preview.png`; VERSION 3, writer stays at 2 unless EPS; legacy JSON opens; limits 100k/256 MiB/1 GiB/4 GiB; non-finite geometry unsaveable; extension appended; atomic writes | `crates/format/src/lib.rs:1-26,90,164-170`; `crates/engine/src/cmd/file.rs` `with_document_extension`; `crates/engine/src/io.rs` (atomic write) | implemented |
| 15 | PDF export: selectable text with embedded subsets, DeviceCMYK/RGB/Gray, spot `/Separation`, bleed/marks/page info, pages or spreads, `none|x4|a2b`, tagged structure tree, flattener, links/outlines, interactive options, booklet, `validate-pdf` | `crates/pdf/src/lib.rs:1-28` (feature list; final "Not yet" line is stale), `crates/pdf/src/pdfx.rs:210` (`check_pdfx4`), `crates/engine/src/cmd/export.rs:12-14` (`file.exportPdf`), `crates/engine/src/cmd/export.rs` (`file.printBooklet`), `apps/designcraft-cli/src/main.rs` (`validate-pdf`) | implemented (no X-1a/X-3/UA/.joboptions) |
| 16 | EPUB 3 reflowable and fixed layout; HTML one self-contained page; PPTX editable slides | `crates/epub/src/lib.rs` (`export_epub`, `export_fixed_epub`, `export_html`), `crates/pptx/src/lib.rs`, `crates/engine/src/cmd/export.rs:15-31` | implemented; EPUB fixed-layout and HTML **partial** (page images; one page) |
| 17 | PNG/JPEG page render; IDML export; text `.txt`/`.rtf`/tagged; XML; print via craft-print | `crates/render/src/lib.rs`, `apps/designcraft-cli/src/main.rs` `Export::of`, `crates/engine/src/cmd/interchange.rs` (`file.exportIdml`), `crates/engine/src/cmd/export.rs` (`file.exportText`), `crates/engine/src/cmd/xml.rs` (`file.exportXml`), `crates/engine/src/cmd/print.rs`, `Cargo.toml` (`craft-print`) | implemented |
| 18 | CLI subcommands (`run`, `commands`, `describe`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`, `--version`); export routing by extension; options after the last export are an error; separate macOS CLI asset | `apps/designcraft-cli/src/main.rs` (USAGE, `Export::of`, `option_after_last_export`, dispatch); `packaging/macos/package.sh:5,44`; `docs/mcp.md` §From an installed release | implemented (packaging fact verified locally: `.app` contains only `DesignCraft`) |
| 19 | MCP server: stdio JSON-RPC 2025-06-18 (+older), 26 tools, headless vs connected, UI-only commands/error, automation roots | `crates/mcp/src/{tools,server,headless,backend}.rs` (`PROTOCOL_VERSION`, `SUPPORTED_VERSIONS`, `tool_definitions` :83, `dispatch` :555); `crates/engine/src/file_access.rs`; `apps/designcraft-cli/src/automation_args.rs`; `docs/mcp.md` §§Modes, Confining file access | implemented |
| 20 | Control channel: loopback JSON lines, 4 MiB/16 connections/no auth, `engine.execute`, `ui.*`, `app.*`, `window.panel.*`; bounded click/drag; `app.quit` skips the save prompt | `apps/designcraft/src/control_server.rs` (`MAX_LINE`, `MAX_CONNECTIONS`), `crates/ui-egui/src/control.rs` (`handle_request` :149, `ui.set` keys, `app.quit`), `docs/control-protocol.md` §§tables, Click and drag limits, Shared panel docking | implemented |
| 21 | Scripts: one command per line, `$N.path`/`$last`/`${…}`/`$$`; `script.run` restores state on failure; CLI/MCP/control validate params | `crates/engine/src/script.rs`; `crates/engine/src/cmd/scripts.rs`; `apps/designcraft-cli/src/main.rs` (`SCRIPT_HELP`, `check_params` at `--cmd`); `crates/mcp/src/headless.rs`; `crates/ui-egui/src/control.rs:164`; `crates/engine/src/cmd/params.rs` | implemented |
| 22 | Package writes package-relative `Links/` links, copies placed files/fonts, IDML copy (default), optional PDF (default off), report | `crates/engine/src/cmd/package.rs` (`file.package` spec, `write_links` `relative_to`, font copy, report) | implemented |
| 23 | Crash recovery every 30 s by default (minimum 5 s), recovery folder, reopen after crash; `file.revert`/`saveACopy` | `crates/ui-egui/src/lib.rs:1143-1146` (`recovery_minutes`, clamp 5 s), `crates/engine/src/lib.rs:316` (`recovery_minutes: 0.5`), `crates/engine/src/recovery.rs`, `crates/engine/src/cmd/file.rs`; `docs/mcp.md`/`ROADMAP` recovery rows | implemented |
| 24 | `file.close` closes without asking and discards recovery data; UI Close asks; control `app.quit` quits without asking | `crates/engine/src/lib.rs:505-524` (`close_document`, `recovery::discard_document`), `crates/ui-egui/src/menus.rs:2473-2486` (comment + dirty check), `docs/control-protocol.md` (`app.quit`) | implemented (behaviour verified in code; no GUI run) |
| 25 | `docs/gaps.md` remaining limits (alpha blocker #165, basic editing, INDD/IDML unmeasured, EPS preview, no ExtendScript/UXP/plug-ins, PDF standards, HTML/EPUB depth, hyphenation/spelling, accessibility, GPU startup, performance, fonts, localization) | `docs/gaps.md` §§0-25 (unchanged since v0.11.0, last updated 2026-10-17), `ROADMAP.md` §Languages, `docs/target-app-parity.md`, `README.md` §§Graphics backend, Why DesignCraft | implemented as stated (some may be stale vs v0.12 fixes) |
| 26 | Installed app = repo HEAD | `Contents/Info.plist` → `CFBundleShortVersionString 0.12.0`, `DesignCraftBuildCommit 5e8ef678…`; `Contents/MacOS/DesignCraft --version` → `designcraft 0.12.0`; `git rev-parse HEAD` in the worktree → same SHA | implemented (verified) |

## Changes between v0.11.0 and v0.12.0 (tag diff)

- **Engine commands 521 → 527 (+6), UI commands 164 → 166 (+2), MCP 26 (unchanged), CLI
  subcommands unchanged.** Added engine ids: `guide.select`, `guide.selectAll`, `guide.deselect`,
  `guide.moveBy`, `layout.moveColumnGuide`, `view.lockColumnGuides`. Added UI ids: `view.lockGuides`,
  `window.importShortcuts`. Nothing removed.
- **New automation-visible feature areas**: ruler-guide selection/moving/snapping/locks; per-page
  custom column guides (including `layout.moveColumnGuide`, `document.inspect` `gutter`/
  `customColumns`/`columnRects`, IDML `ColumnsPositions`/`ColumnGuideLocked`); InDesign Show Set
  shortcut import (`window.importShortcuts`).
- **Other user-visible differences present in this tree** (merged from main; not all first introduced
  in v0.12.0): Paragraph Rule Above offset now runs from the first line's baseline to the rule's
  bottom edge (`crates/compose/src/lib.rs:1863`); autoflow counts only the pages page breaks ask for
  (`crates/engine/src/cmd/place_text.rs` tests); copied objects put a placeholder on the system
  clipboard and paste with Ctrl+V on Linux/Windows (`crates/engine/src/cmd/edit.rs`); PDF/A keeps
  placed images, PDF/X-4 gives RGB images sRGB and skips interpolation, damaged PNG/GIF/WebP images
  are skipped rather than fatal, mixed gradient colour spaces warn instead of aborting; EPUB/HTML
  metadata is escaped (`crates/epub/src/lib.rs`); Word import keeps tracked moves (`w:moveTo`) and
  RTF/Tagged Text keep characters past U+FFFF (`crates/textimport`); macOS has a Language submenu
  and rebuilds the native menu when the language or shortcuts change
  (`apps/designcraft/src/native_menu.rs`); menus/dialogs remain reachable at larger UI scales.
- **Count correction vs the previous skill**: the previous revision reported 485 engine commands;
  a brace-aware count of the same v0.11.0 tree gives **521**. The difference is an extraction
  undercount (truncating at the first `#[cfg(test)]` removes specs that follow an early test
  module), not a release change. This revision reports 521 → 527.
- **Docs not updated at this tag**: `docs/agents.md`, `docs/mcp.md` and `docs/control-protocol.md`
  were not changed for the new guide/column/shortcut commands. The command registry is the source
  of truth (`designcraft-cli describe`); `docs/file-format-parity.md` does mention the shortcut-set
  import.

## Documentation-discrepancy notes (kept honest in SKILL.md)

| Discrepancy | Where | What the code says |
|---|---|---|
| "Not yet: tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content" | `crates/pdf/src/lib.rs:28` (still present at this tag) | Outdated: tagged structure tree and standards in `crates/pdf/src/export.rs`, hyperlinks in `crates/pdf/src/links.rs`, forms in `crates/pdf/src/forms.rs`, page transitions in `crates/pdf/src/transitions.rs`, optional-content layer options in `crates/engine/src/cmd/pdflayers.rs` |
| "~200 commands, all reachable through the JSON control channel" | `ROADMAP.md:180` | Registry has 527 `cmd!` registrations plus 166 `UI_COMMANDS` at this tag (see row 4) |
| "Command surface (measured): 446 engine commands + 99 UI commands" | `docs/target-app-parity.md:45` | Dated measurement (2026-10-10); the registry has 527 + 166 at this tag |
| Front-matter "verified: 0.7.1" and "0.7.1" examples | `docs/user/getting-started/install.md` | Bundle and workspace are at 0.12.0 (`Cargo.toml:7`, Info.plist) |
| "Most commands ignore parameters they don't know instead of rejecting them" | `docs/agents.md` (repeated in `SCRIPT_HELP`) | The CLI, MCP and control channel call `check_params` and reject unknown keys (`crates/engine/src/cmd/params.rs`, `apps/designcraft-cli/src/main.rs`, `crates/mcp/src/headless.rs`, `crates/ui-egui/src/control.rs:164`). `Session::execute` itself checks only in `#[cfg(test)]`, so the in-app Scripts panel is the exception |
| `docs/gaps.md` last updated 2026-10-17 | `docs/gaps.md` header | Predates the v0.12.0 release; a few entries may be stale (e.g. object clipboard work in v0.12), but the alpha blocker and the structural gaps remain |

## Uncertain / not verified (no stronger claim made in SKILL.md)

- **Runtime GUI behaviour** (menu layout, guide dragging, shortcut dialog, column-guide drag) was
  not exercised because the brief forbids launching the app. Claims come from the source, tests
  (`crates/ui-egui/src/guide_selection_tests.rs`) and the maintainers' `ROADMAP.md` progress log.
- **Exact engine-command count**: 527 unique `cmd!` ids by a brace-aware extraction; every `cmd!`
  occurrence in `crates/engine/src/cmd` is inside a `specs()` list and there are no duplicates, but
  a macro-generated id outside that shape would be missed. Live discovery is authoritative.
- **Shortcut import quality on real InDesign sets**: the parser and matching rules are read in code;
  no real Show Set corpus was run, so the match rate and label edge cases are unmeasured.
- **Column guides on real IDML**: the importer/exporter and tests are synthetic; no
  InDesign-authored corpus with custom column positions was available.
- **`view.lockGuides` persistence**: `UiState` is serialized to `ui.json` and
  `apps/designcraft/src/main.rs` points at it; not verified by a running app.
- **`file.close` on a dirty document**: code shows `close_document` discards recovery data and the
  UI's `close_document` wrapper is what asks; the exact engine state after a close was not run.
- **New v0.12 fixes in `docs/gaps.md`**: the gaps file was not updated for this release, so some
  entries may lag the code (noted where it matters).

# evidence.md — DesignCraft SKILL.md claim audit

App: **DesignCraft** (`storytold/designcraft`) · Tag **v0.13.0** · HEAD
`dcce40fb8731213c1f8e31cdd23444995afc62ce` · audited 2026-10-26.

Installed bundle `DesignCraft.app` reports `CFBundleShortVersionString 0.13.0`,
`DesignCraftVersion 0.13.0` and `DesignCraftBuildCommit
dcce40fb8731213c1f8e31cdd23444995afc62ce` — **identical to the repository HEAD** — and
`Contents/MacOS/DesignCraft --version` prints `designcraft 0.13.0`; no HEAD/installed divergence
exists at this pin. The bundle was inspected (Info.plist, `--version` only), never launched, and
contains only `DesignCraft` — `designcraft-cli` is **not** installed on this machine (`command -v`
finds nothing). Counts below were re-derived from this tag's source and compared against the public
v0.12.0 release tree, fetched only to diff identifiers (the clone is shallow: one commit).

Status legend: **implemented** = code path exists and is wired into the UI/CLI/control surfaces;
**partial** = code exists but visibly incomplete (what is missing is named); **claimed** = stated
in docs/README but not confirmed in code; **not implemented** = absent by design or not yet built.

| # | Claim in SKILL.md | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Page-layout/publishing app in pure Rust aiming at InDesign 2026 parity; clean-room; MIT OR Apache-2.0; pre-alpha; ~80% breadth, ~47% ready | `README.md` (tagline, "written in Rust", platforms), `AGENTS.md`, `ROADMAP.md:3` ("Stage: pre-alpha", ~5–7 h to alpha), `Cargo.toml` (`version = "0.13.0"`, `license`), `docs/target-app-parity.md` §Headline | implemented (maturity/percentages are the maintainers' estimates) |
| 2 | Runs natively on macOS/Windows/Linux and as WebAssembly via trunk; web has no control channel and downloads saves/exports | `apps/designcraft/`, `apps/designcraft-web/`, `README.md` §Web | implemented |
| 3 | Every user-visible action is a command; UI, CLI, control and MCP share `Session::execute` | `crates/engine/src/cmd/mod.rs:167` (`command_specs`), `crates/engine/src/lib.rs:529` (`execute`), `crates/ui-egui/src/control.rs:149` (`handle_request`), `crates/mcp/src/tools.rs:83` (`tool_definitions`) | implemented |
| 4 | **537** engine command specs across 61 `specs()` lists + **172** UI commands at v0.13.0; +10 engine / +6 UI vs v0.12.0, none removed; MCP stays 26; control stays 26; CLI subcommands unchanged (10) | Recomputed this session: brace-aware `#[cfg(test)]` removal, then every `cmd!`/`cmd!(query …)`/`cmd!(noundo …)` id under `crates/engine/src/cmd` (61 wired `v.extend(<mod>::specs())` in `crates/engine/src/cmd/mod.rs`) = **537** unique ids, 0 duplicates, no `cmd!` outside that directory; `UI_COMMANDS` array at `crates/ui-egui/src/menus.rs:18` parsed tuple-by-tuple = **172**. v0.12.0 tree measured the same way: 527 and 166. Added engine ids: `document.epubSplit`, `list.bullets`, `list.numbers`, `note.convertFromText`, `note.next`, `note.previous`, `selection.key`, `story.options`, `variables.convertToText`, `variables.convertAllToText`; added UI ids: `app.grepStylesDialog`, `app.hyphenationDialog`, `app.keepOptionsDialog`, `app.nestedStylesDialog`, `view.goBack`, `view.goForward`. `crates/mcp/src/tools.rs` and `crates/ui-egui/src/control.rs` are unchanged files at this tag | implemented (counts code-derived; discover live with `commands` / `engine.commands`) |
| 5 | Layout/document model: spreads, parents, sections, layers, typed frames, threaded stories; page setup/presets/bleed/slug; multi-document tabs | `crates/doc/src/{page,story,item}.rs`; `crates/engine/src/cmd/{layout,thread,file}.rs`; `crates/ui-egui/src/menus.rs` (`window.nextDocument` Cmd+F6) | implemented |
| 6 | Ruler guides: add/list/select/select-all/move/moveBy/delete/deleteAll/createGuides, caps 10 000 guides and rows/columns ≤ 1000; guide snapping; `view.lockGuides` only blocks the pointer | `crates/engine/src/cmd/guides.rs` (`MAX_GUIDES_CREATED`/`MAX_GUIDES_NAMED` :20/:25, `layout.createGuides` params :130), `crates/ui-egui/src/canvas.rs`, `crates/tools/src/snap.rs` | implemented (GUI drag verified by code/tests, not by launching the app) |
| 7 | Custom column guides: per-page positions, `layout.moveColumnGuide`, `MAX_COLUMNS` 216, inspect fields, IDML `ColumnsPositions`/`ColumnGuideLocked`, locked by default, mirrored across the spine | `crates/doc/src/page.rs:46`, `crates/engine/src/cmd/layout.rs`, `crates/engine/src/cmd/inspect.rs`, `crates/doc/src/lib.rs` (`column_guides_locked`), `crates/idml/src/{import,export}.rs` | implemented (IDML synthetic tests; no real-file corpus) |
| 8 | **v0.13 page history**: `view.goBack`/`view.goForward` (Cmd+PageUp/PageDown) retrace page jumps at the current zoom; new jump drops the pages ahead; scrolling adds no entry; deleted pages skipped | `crates/ui-egui/src/page_history.rs` (`visit`/`can_go`/`go`), `crates/ui-egui/src/menus.rs:259`, `crates/ui-egui/src/canvas.rs` (`go_through_history`) | implemented |
| 9 | Styles/swatches/wrap/corners/transparency/ICC; interactions incl. Pathfinder, tables, footnotes/endnotes/notes, xref, index, TOC, variables, conditional text, track changes, data merge, XML, articles, libraries, books, object states, buttons/forms, transitions, Flex Layout | `crates/engine/src/cmd/*` (61 `specs()` lists), `crates/doc/src/{styles,item}.rs`, `crates/engine/src/cmd/{colorsettings,conditions,changes,xml,articles,library,book,states,buttons,transitions,flex}.rs`, `crates/engine/src/cmd/datamerge/` | implemented (breadth; depth per feature varies) |
| 10 | **v0.13 placed-PDF layer choices**: `object.layerOptions {ids?, hidden, useDefaults?}` — `useDefaults:false` with `[]` = explicitly all on, legacy `[]` = file defaults; `object.pdfLayers` reports `{name, visible, default, overridden}`; explicit choice validated by one real rewrite per source before edits (atomic); `useDefaults` cannot combine with `hidden` | `crates/engine/src/cmd/pdflayers.rs` (both specs, validation before `s.edit`), `crates/doc/src/item.rs` (`pdf_layer_override`, `pdf_hidden_layers`), `docs/pdf-layer-visibility.md` | implemented (override application to output described in row 11) |
| 11 | Output honours placed-PDF choices: plain and PDF/X-4 keep vector artwork + optional content with per-placement overrides (repeated placements, booklet, book-merge); PDF/A-2b export-only 300 ppi raster copy; embedded IDML stores a variant per placement, external-only export rejects active choices; package report names a lost choice | `crates/pdf/src/optional_content.rs`, `crates/engine/src/cmd/{export,package}.rs`, `crates/idml/src/export.rs`, `docs/pdf-layer-visibility.md`, `docs/gaps.md` §19 | implemented per docs/code; no independent print-fidelity check |
| 12 | **v0.13 IDML graphic-layer options retained per placement** (`GraphicLayerOption`/`GraphicLayer`): scalar attributes, layer order, parent/child links, names, visibility and view/export/print flags survive import → native save/reopen → IDML export; retained settings produce import/preflight/PDF warnings | `crates/doc/src/assets.rs:48` (`has_graphic_layer_options`), `crates/idml/src/{import,export}.rs`, `docs/graphic-layer-options.md` | **partial** — preservation only; the renderer/PDF exporter still use the composite appearance, no layer-options UI |
| 13 | Native `.designcraft` zip: `mimetype` stored first, `document.json`, one `assets/` entry per referenced file, `meta.json`, optional `preview.png`; reader VERSION 4 (v0.12.0: 3); `required_version` keeps 2/3 unless graphic-layer options or explicit all-on PDF layers are present; limits 100 000 entries / 256 MiB JSON / 1 GiB asset / 4 GiB total; non-finite geometry unsaveable; extension appended; atomic writes | `crates/format/src/lib.rs:29` (`VERSION`), `:75` (`required_version`), `:179-185` (limits), `crates/engine/src/cmd/file.rs` (`with_document_extension`), `crates/engine/src/io.rs`, `Cargo.toml` (`craft-atomic`) | implemented |
| 14 | Text engine: Knuth–Plass + single-line composer with cache; optical kerning from outlines; dictionary hyphenation; bidi/RTL/kashida/digits; CJK mojikumi/kinsoku; vertical type, ruby, kenten, warichu, tate-chu-yoko | `crates/compose/src/{lib,breaker,optical}.rs`, `crates/compose/src/hyphen/`, `crates/compose/src/{bidi,mojikumi,ruby,kenten,warichu}.rs`, `ROADMAP.md` progress log | implemented |
| 15 | **v0.13 Story-level Optical Margin Alignment**: `story.options {story?, frame?, opticalMargin?, opticalMarginSize?}` (0.1–1296 pt, default 12) hangs punctuation/edges for every paragraph except `ignoreOpticalMargin`; Story panel; `type.selectionAttrs.storyOptions`; IDML `StoryPreference/@OpticalMarginAlignment`/`@OpticalMarginSize`/`IgnoreEdgeAlignment`; Paragraph panel menu has Ignore Optical Margin | `crates/engine/src/cmd/text.rs:108` and handler :1020, `crates/engine/src/cmd/style.rs` (`ignoreOpticalMargin` in paragraph style params), `crates/ui-egui/src/panels/story.rs`, `docs/ui-parity.md` (Story panel row) | implemented (table cells and footnotes do not take the story setting — stated in `ROADMAP.md` log) |
| 16 | **v0.13 Hyphenation Settings dialog** (`app.hyphenationDialog`) sets limits, zone, Better Spacing↔Fewer Hyphens, Hyphenate Capitalized/Last Word/Across Column with Preview as one undo step; new documents start with those three off in `[Basic Paragraph]`, opened/imported files keep theirs | `crates/ui-egui/src/menus.rs` (`app.hyphenationDialog`), `crates/engine/src/cmd/file.rs:240` (`new_document` sets `hyph_capitalized`/`hyph_last_word`/`hyph_across_column` false) and its `hyphenation_default_tests` | implemented |
| 17 | **v0.13 list buttons**: `list.bullets` / `list.numbers {on?}` apply the default hanging indent (18 pt / −18 pt) to paragraphs with no indents and remove it on toggle-off if it is still as applied | `crates/engine/src/cmd/lists.rs` (specs :18 and :27, `apply_list` :79), `docs/target-app-parity.md` §Working-today ("Bulleted and Numbered List buttons") | implemented |
| 18 | **v0.13 notes**: `note.convertFromText {author?}` moves selected text into a new note; `note.next`/`note.previous` move the caret after the neighbouring note's anchor and are unavailable in table cells/footnotes | `crates/engine/src/cmd/editorial.rs` (specs :41, :106, :115), `ROADMAP.md` 2026-10-24 entries | implemented |
| 19 | **v0.13 Convert Variable to Text**: `variables.convertToText` (selected instances) and `variables.convertAllToText {name}` (whole document) replace instances with the value each shows on its page; variable stays defined | `crates/engine/src/cmd/variables.rs` (specs :77, :86), `docs/target-app-parity.md` §Working-today | implemented |
| 20 | **v0.13 Key Object**: `selection.key {id}` makes a selected item (≥ 2 selected) the Align key object; toggling clears it; `object.align`'s `to` defaults to `keyObject` while one is set | `crates/engine/src/cmd/edit.rs` (spec :275, handler), `crates/engine/src/cmd/object.rs:685` (align params) | implemented |
| 21 | **v0.13 EPUB Split Document**: `document.epubSplit {split?}` stored with the document (off / `exportTags` / `{style}`), `file.exportEpub {split}` per-export override, `style.exportTag {split}` marks styles, navigation/note links cross files, IDML `EPubExportPreference` | `crates/engine/src/cmd/export.rs:19` (`document.epubSplit`), `:15` (`file.exportEpub` params incl. `split`), `crates/epub/src/lib.rs:42` (`EpubSplit`), `:1063` (`starts_chapter`), `crates/engine/src/cmd/style.rs` (`split` in `style.exportTag`) | implemented |
| 22 | PDF export: selectable text with embedded subsets, DeviceCMYK/RGB/Gray, spot `/Separation`, bleed/marks/page info, pages or spreads, `none|x4|a2b`, tagged structure tree, flattener, links/outlines, interactive options, `created` for reproducible files, booklet | `crates/engine/src/cmd/export.rs:12` (`file.exportPdf`, `created` param), `crates/pdf/src/lib.rs` (feature list; its final "Not yet" line :28 is stale), `crates/engine/src/cmd/export.rs:45` (`file.printBooklet`) | implemented (no X-1a/X-3/UA/.joboptions) |
| 23 | **v0.13 `validate-pdf`** reports visible unembedded fonts (incl. placed PDF forms) with names/pages; render-mode-3 text exempt; PDF/X-4 export warns about the same; checks cover version, output intent, Info/XMP, interpolation, encryption, trim boxes, Type 3 fonts, device RGB under CMYK | `crates/pdf/src/pdfx.rs:212` (`check_pdfx4`), `crates/pdf/src/pdfx/fonts.rs:16` (`unembedded_fonts`), `apps/designcraft-cli/src/main.rs` (`validate_pdf`), `docs/agents.md` §PDF/X-4 validation, `docs/gaps.md` §28 | implemented as **detection**; font repair remains missing (gap 28) |
| 24 | Import/open: content-sniffed `.designcraft`/IDML/INDD/INDT; images PNG/JPEG/GIF/WebP/TIFF/BMP/PSD/SVG/PDF/EPS preview; text `.txt`/`.text`/`.md`/`.docx`/`.rtf`/XLSX/Tagged Text (plain text UTF-8 or UTF-16); media poster frames; `.ase`/ICC/XML/`.dclib`/`.dcbook`/page-of-document | `crates/engine/src/cmd/file.rs` (`open_path`, `file.place`), `crates/idml/src/import.rs`, `crates/engine/src/cmd/interchange.rs`, `crates/images/src/lib.rs` (`mime`, `is_pdf/is_psd/is_svg/is_eps`), `crates/textimport/src/lib.rs:96`, `crates/textimport/src/tagged.rs:106` (`decode`), `crates/doc/src/item.rs` (`media_mime`), `crates/engine/src/cmd/{style,colorsettings,xml,library,book}.rs` | implemented (EPS preview only; INDB/INDL unread) |
| 25 | Other writers: EPUB 3 reflowable + fixed layout, one-page HTML, editable PPTX, PNG/JPEG page render, IDML (`embedImages`), Text `.txt`/`.rtf`/tagged, XML, print via craft-print | `crates/epub/src/lib.rs`, `crates/pptx/src/lib.rs`, `crates/render/src/lib.rs`, `crates/engine/src/cmd/{interchange,export,xml,print}.rs`, `apps/designcraft-cli/src/main.rs` (`Export::of`, `export`) | implemented; fixed-layout EPUB and HTML **partial** (page images; one page) |
| 26 | CLI: 10 subcommands (`run`, `commands`, `describe`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`) + `--version`; export routing by extension; options after the last export are an error; macOS CLI is a separate release asset; v0.13 repeatable automation roots in both spellings; `validate-pdf` gained font checks | `apps/designcraft-cli/src/main.rs` (module doc, `USAGE`, `Export::of`, `option_after_last_export`, dispatch), `apps/designcraft-cli/src/automation_args.rs:15` (`consume`), `apps/designcraft-cli/src/perf.rs` (perf/bench flags), `README.md` §Downloads, `docs/mcp.md` | implemented (packaging verified: the `.app` contains only `DesignCraft`) |
| 27 | MCP server: stdio JSON-RPC 2025-06-18 (+2025-03-26, 2024-11-05), 26 tools, same names/schemas as v0.12.0, headless vs connected, automation roots, resources `designcraft://document`/`commands` | `crates/mcp/src/{tools,server,headless,backend}.rs` (`PROTOCOL_VERSION`, `SUPPORTED_VERSIONS`, `tool_definitions` :83), `crates/engine/src/file_access.rs`, `apps/designcraft-cli/src/automation_args.rs`, `docs/mcp.md` | implemented (`tools.rs` is byte-identical to v0.12.0) |
| 28 | Control channel: loopback JSON lines, 4 MiB lines, 16 connections, no auth, 26 methods (`engine.execute`/`ui.menu.invoke`/`command`, `engine.commands`, `document.inspect`, `ui.*`, `app.*`), bounded click/drag, `app.quit` skips the save prompt | `apps/designcraft/src/control_server.rs` (`MAX_LINE` :22, `MAX_CONNECTIONS` :24), `crates/ui-egui/src/control.rs:149` (`handle_request`), `:118` (`MAX_PENDING_POINTER_EVENTS` 10 003), `crates/ui-egui/src/lib.rs:1263` (`handle_quit`), `docs/control-protocol.md` | implemented (`control.rs` and `control_server.rs` unchanged from v0.12.0) |
| 29 | Scripts: one command per line, `$N.path`/`$last`/`${…}`/`$$`; `script.run` restores state on failure; CLI/MCP/control validate params against the command's description | `crates/engine/src/script.rs`, `crates/engine/src/cmd/scripts.rs`, `apps/designcraft-cli/src/main.rs` (`SCRIPT_HELP`, `check_params` :327), `crates/mcp/src/headless.rs:110`, `crates/ui-egui/src/control.rs:164`, `crates/engine/src/cmd/params.rs:224` | implemented |
| 30 | Shortcut import reads InDesign Show Set `.txt` (UTF-8/UTF-16, Mac/Win names, ≤ 8 MiB), applies the Default context (Text for type/text commands), reports changed/conflicts/skipped/unmatched/unreadable; tools fixed; no `.indk`, no write | `crates/ui-egui/src/shortcut_import.rs` (`MAX_BYTES` :17, `import` :359), `crates/ui-egui/src/menus.rs`, `docs/file-format-parity.md` | implemented; **partial** vs InDesign (one context, no Control chords, no set export); file unchanged from v0.12.0 |
| 31 | Package writes `Links/` package-relative paths, copies placed files/fonts, IDML copy (default on), optional PDF (default off), report; names a lost placed-PDF layer choice | `crates/engine/src/cmd/package.rs`, `docs/pdf-layer-visibility.md`, `docs/gaps.md` §3 | implemented |
| 32 | Recovery every 30 s by default (minimum 5 s), reopen after crash; `file.revert`/`saveACopy`; save/export dialogs start in the active document's folder (v0.13, #1653) | `crates/engine/src/lib.rs:316` (`recovery_minutes: 0.5`), `crates/ui-egui/src/lib.rs:1215` (max 5 s floor), `crates/engine/src/recovery.rs`, `apps/designcraft/src/main.rs:283` (`save_dialog_start`) and its test :627 | implemented |
| 33 | `file.close` closes without asking and discards recovery data; UI Close and `app.quit` ask per dirty document; control `app.quit` quits without asking | `crates/engine/src/lib.rs:505` (`close_document`), `crates/ui-egui/src/lib.rs:1263` (`handle_quit`, `quit_without_asking`), `crates/ui-egui/src/control.rs` (`app.quit`), `docs/control-protocol.md` | implemented (code-level; no GUI run) |
| 34 | `docs/gaps.md` remaining limits at this tag (alpha blocker #165; basic editing; INDD/IDML unmeasured; EPS preview; no ExtendScript/UXP/plug-ins; PDF standards + gap 28 font repair; HTML/EPUB depth; hyphenation/spelling; accessibility; GPU startup; performance; fonts; localization) | `docs/gaps.md` §§0–28 (header "Last updated 2026-10-24"), `ROADMAP.md` §Languages, `docs/target-app-parity.md`, `docs/graphic-layer-options.md`, `docs/pdf-layer-visibility.md` | implemented as stated |
| 35 | Installed app = repo HEAD | `Contents/Info.plist` → `CFBundleShortVersionString 0.13.0`, `DesignCraftBuildCommit dcce40fb…`; `Contents/MacOS/DesignCraft --version` → `designcraft 0.13.0`; `git rev-parse HEAD` in the worktree → same SHA | implemented (verified) |
| 36 | **v0.13 new-document hyphenation defaults**: `[Basic Paragraph]` has Hyphenate Capitalized Words, Last Word and Across Column off; imported files keep their values | `crates/engine/src/cmd/file.rs:240` (`new_document`), test `new_documents_hyphenate_no_capitalized_last_or_column_end_words_and_imports_keep_theirs` | implemented |

## Changes between v0.12.0 and v0.13.0 (tag diff)

- **Engine commands 527 → 537 (+10), UI commands 166 → 172 (+6), MCP 26 (unchanged),
  control methods 26 (unchanged), CLI subcommands (unchanged).** Added engine ids:
  `document.epubSplit`, `list.bullets`, `list.numbers`, `note.convertFromText`, `note.next`,
  `note.previous`, `selection.key`, `story.options`, `variables.convertToText`,
  `variables.convertAllToText`. Added UI ids: `app.grepStylesDialog`, `app.hyphenationDialog`,
  `app.keepOptionsDialog`, `app.nestedStylesDialog`, `view.goBack`, `view.goForward`. Nothing
  removed. `crates/mcp/src/tools.rs`, `crates/ui-egui/src/control.rs` and
  `apps/designcraft/src/control_server.rs` are byte-identical to v0.12.0.
- **Native format 3 → 4.** One reader capability covers retained placed-graphic layer options and
  explicit all-on placed-PDF layer choices (`crates/format/src/lib.rs:25-29`, `required_version`
  :75). Documents needing neither keep their version 2/3 requirement.
- **New feature areas at this tag:** placed-PDF layer choices (all-on vs file defaults, vector
  export, PDF/A-2b raster path, embedded-IDML variants, package report); per-placement IDML
  graphic-layer option retention with import/preflight/PDF warnings (not rendered); EPUB Split
  Document; Story Options optical margin alignment + per-paragraph Ignore Optical Margin; Convert
  Variable to Text; list buttons with the default hanging indent; Notes Previous/Next/Convert to
  Note; Key Object; Go Back/Forward page history; new-document hyphenation defaults; Relative to
  Spine for custom anchored objects; save/export dialogs remembering the folder; PDF/X-4 visible
  unembedded font detection; repeatable `--automation-read-root`/`--automation-write-root`.
- **Behaviour fixes in the same tree** (from the ROADMAP progress log): autoflow fills the pages
  that follow before adding pages; baseline grid Relative To applied; anchored text frames compose
  on their host page and grid; text-frame custom baseline grid parsed in the right order;
  hyphenation across a column boundary honoured; optical margin alignment on lines with tabs; style
  rename/group keeps Export Tagging; Quick Apply hides interface commands that need a value.
- **Docs updated at this tag:** `docs/gaps.md` (gap 28 added, gap 26 shrunk, gap 16 note),
  `docs/target-app-parity.md` (font detection, list buttons, Convert Variable to Text, autoflow),
  `docs/ui-parity.md` (Story panel, text Control panel A/¶ modes, Properties ••• expansion),
  `docs/file-format-parity.md` (font detection), `docs/localization-parity.md` (missing
  translations reported, never fatal), `docs/mcp.md` (repeatable roots), plus new
  `docs/graphic-layer-options.md` and `docs/pdf-layer-visibility.md`. `README.md` and
  `docs/control-protocol.md` are unchanged.

## Documentation-discrepancy notes (kept honest in SKILL.md)

| Discrepancy | Where | What the code says |
|---|---|---|
| "Not yet: tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content" | `crates/pdf/src/lib.rs:28` (still present) | Outdated: tagged structure tree and standards in `crates/pdf/src/export.rs`, hyperlinks in `crates/pdf/src/links.rs`, forms/transitions in `crates/pdf/src/{forms,transitions}.rs`, optional content in `crates/pdf/src/optional_content.rs` |
| "~200 commands, all reachable through the JSON control channel" | `ROADMAP.md:208`, `docs/target-app-parity.md:461` | Registry has 537 `cmd!` registrations plus 172 `UI_COMMANDS` at this tag (row 4) |
| "Command surface (measured): 446 engine commands + 99 UI commands" | `docs/target-app-parity.md:45`, `docs/ui-parity.md:20` | Dated measurement (2026-10-10); the registry has 537 + 172 at this tag |
| Front-matter "verified: 0.7.1" and 0.7.1 examples | `docs/user/getting-started/install.md` | Bundle and workspace are at 0.13.0 (`Cargo.toml`, Info.plist) |
| "Most commands ignore parameters they don't know instead of rejecting them" | `docs/agents.md`, `SCRIPT_HELP` in `apps/designcraft-cli/src/main.rs` | The CLI, MCP and control channel call `check_params` and reject unknown keys (`crates/engine/src/cmd/params.rs:224`, `crates/ui-egui/src/control.rs:164`). `Session::execute` itself checks only in `#[cfg(test)]`, so the in-app Scripts panel is the exception |
| Gap 16 lists "149 of 482" and then "150 of 482" in duplicate lines | `docs/gaps.md` §16 | A duplicated/edited block; treat the menu-dump numbers as the maintainers' 2026-10-10 measurement, not as a live count |

## Uncertain / not verified (no stronger claim made in SKILL.md)

- **Runtime GUI behaviour** (menu layout, guide dragging, page history, Story panel, placed-PDF
  layer dialogs, shortcut dialog) was not exercised because the brief forbids launching the app.
  Claims come from source, tests (`crates/ui-egui/src/page_history.rs`,
  `crates/ui-egui/src/guide_selection_tests.rs`, panel tests) and the maintainers' ROADMAP log.
- **Exact engine-command count**: 537 unique ids by a brace-aware extraction; every `cmd!`
  occurrence in `crates/engine/src/cmd` is inside a `specs()` list, there are no duplicates and no
  `cmd!` outside that directory, but a macro-generated id outside that shape would be missed.
  `designcraft-cli commands` on a built binary is authoritative.
- **Placed-PDF layer export fidelity**: the code and `docs/pdf-layer-visibility.md` describe vector
  optional-content output and 300 ppi PDF/A raster copies; no exported file was inspected here, so
  viewer/RIP behaviour is unmeasured.
- **IDML graphic-layer rendering**: retention and warnings are code + docs + a 205-document local
  metadata check reported in `docs/graphic-layer-options.md`; appearance against InDesign is
  explicitly not claimed by the maintainers.
- **EPUB split quality on real books**: `starts_chapter`/`split_chapters` and navigation are read in
  code; no real book was exported and validated here.
- **Shortcut import quality on real InDesign sets**: parser and matching rules read in code; no real
  Show Set corpus was run, so match rate and label edge cases are unmeasured.
- **`validate-pdf` font detection**: implemented and documented (#909); not exercised on a real
  placed-PDF export in this audit.
- **Upstream craft-libs behaviour** (printing, ICC, atomic writes, PDF writer) is pinned by
  `Cargo.toml` revs and not vendored in this clone; not audited (craft-pdf rev
  `9f75d3dc19b4b514c4f3d4847ed1ec1b0e86b4ef`, crafted libs at their pinned revs — uncertain — see `Cargo.toml`).

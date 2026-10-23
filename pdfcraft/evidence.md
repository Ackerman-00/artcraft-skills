# PdfCraft — evidence table

Audit basis: this checkout is tag `v0.12.0`, commit `39844f06b58bc96bae72d3fb56faaa3b6201c945` ("Release 0.12.0", 2026-10-22). The installed
`/Applications/PdfCraft.app` reports `CFBundleShortVersionString = 0.12.0` and
`PdfCraftBuildCommit = 39844f06b58bc96bae72d3fb56faaa3b6201c945`; its binary prints
`pdfcraft 0.12.0`. The bundle therefore matches this source exactly. Inspection date: 2026-10-23.
The checkout was not modified or built; the app was only version-checked from its bundle and
binary (no GUI window).

Tier: **implemented** = code path exists and is wired into UI/CLI; **partial** = present but
visibly incomplete or limited; **claimed** = stated in README/docs but not confirmed in code.

| # | Capability claim | Evidence | Tier |
|---|---|---|---|
| 1 | Installed 0.12.0 bundle is the inspected release commit | `Contents/Info.plist` `CFBundleShortVersionString` and `PdfCraftBuildCommit`; binary `--version` → `pdfcraft 0.12.0`; `git rev-parse HEAD` = `39844f06…` | implemented (environment) |
| 2 | Automation surface: **175** JSON-Schema tools (+4 vs 171 at v0.11.0) and **204** commands (+3 vs 201) | `crates/automation/src/tools.rs:117` (`tools()`), 175 `t(...)` registrations; added `form_add_field_table` (`:372`), `form_calculation_order` (`:447`), `layer_set` (`:805`), `standards_remove_id` (`:1129`), none removed (machine diff against `git show v0.11.0:…`). `crates/engine/src/commands.rs:165`, 204 entries; added `form.add.text_table` (`:299`), `form.calculation_order` (`:281`), `view.page_gaps` (`:207`) | implemented |
| 3 | Page gaps: gapless continuous display with a command, launch flags, control-channel set/state, and no PDF edit | `crates/ui-egui/src/canvas.rs:186` (`show_page_gaps`), `:1539` (`set_page_gaps`); command `crates/engine/src/commands.rs:207`; `set_option` `crates/ui-egui/src/lib.rs:2619` (`page-gaps`, `default-page-gaps`); `crates/ui-egui/src/control.rs:683` (`page_gaps` state); `docs/page-display.md` | implemented |
| 4 | New bookmarks can target a place on the page, and a bookmark made with ⌘B lands where the reader is | `bookmark_add` schema at `crates/automation/src/tools.rs:293` (`top`/`left` in displayed-page points); `crates/ui-egui/tests/it/bookmark_position.rs:1` (#3865); destination model `crates/ui-egui/src/panels.rs:644` | implemented |
| 5 | Text-field tables: 1–100 rows × 1–50 columns, per-column name patterns, relative widths/gaps, atomic | `form_add_field_table` at `crates/automation/src/tools.rs:372`; `crates/forms/src/table.rs:1` (`MAX_ROWS = 100`, `MAX_COLUMNS = 50`, all-or-nothing); command `form.add.text_table`; UI `crates/ui-egui/src/field_table_ui.rs` | implemented |
| 6 | Form calculation order: read order with formula reads and stale/cycle/not-listed issues; set, move or fix order; recalculates | `form_calculation_order` at `crates/automation/src/tools.rs:447`; `crates/forms/src/calc_order.rs:1` (`reads`, `issues`, `extra`, `fixed()`); `Document::calculation_order` at `crates/engine/src/lib.rs:622`; command `form.calculation_order`; UI `crates/ui-egui/src/calc_order_ui.rs` | implemented (cycles reported, not repaired) |
| 7 | `layer_set` shows/hides optional-content groups for rendering; it is a view setting, file unchanged | `layer_set` at `crates/automation/src/tools.rs:805`; `crates/automation/src/layers.rs:1`; `Session::set_layer_visible`; render cache invalidated after a change | implemented |
| 8 | `standards_remove_id` removes PDF/A (`pdfaid:`) or PDF/X (`GTS_PDFX…`) identification; fails when nothing is declared | `standards_remove_id` at `crates/automation/src/tools.rs:1129`; `crates/organize/src/lib.rs:727` (`remove_standard_id`, both standards); Standards panel PDF/A removal at `crates/ui-egui/src/standards_ui.rs:56` | implemented (removal only) |
| 9 | Printing obeys permissions: Print disabled when forbidden, low-quality-only capped at 150 dpi; `duplex=printer`, `as_image`, US #10 envelope | `crates/engine/src/lib.rs:711` (`allows_printing`), `:4537` (low-res 150 dpi); `print_pdf` checks and rasterizes; `crates/automation/src/printing.rs:1`; command `print.dialog` needs `Needs::Printing` (`crates/engine/src/commands.rs:193`); schema at `crates/automation/src/tools.rs:528` | implemented (raster cap) |
| 10 | Compare panel filters text changes vs visual differences; text compare requires copying permission | `crates/ui-egui/src/compare_ui.rs:27` (`show_text`, `show_visual`), `:115` (Show:), `:145`/`:325`; `Session::compare` at `crates/engine/src/compare.rs:51` checks `check_copying` on both documents; `docs/gaps.md` gap 21 | implemented (filters) / partial (finer change types) |
| 11 | Save in place is an incremental append; a new path is a full rewrite; writes are atomic; `flatten_fill_sign` bakes Fill & Sign first | `doc_save_with` `crates/automation/src/lib.rs:1036`; `publish_save`; `write_incremental` `crates/cos/src/writer.rs:189`; `write_atomically` `crates/platform/src/staging.rs:126`; `docs/architecture.md` §Data model and editing | implemented |
| 12 | Redaction removes content and verifies; faux-redaction audit is paint-order/colour-aware and fails closed; CLI exits non-zero | `crates/redact/src/lib.rs:597` ("Verify: nothing readable may remain…"); `redact_apply` at `crates/automation/src/tools.rs:487`; `doc_audit_redactions` at `:517`; CLI `audit` in `apps/pdfcraft-cli/src/main.rs:170` | implemented |
| 13 | Signatures: `.p12/.pfx`, Keychain, Windows store; PAdES B-B; certification levels; timestamp tokens validated but no TSA configuration in app/CLI | `sign_document` at `crates/automation/src/tools.rs:739`; `crates/sign/src/pdf.rs` timestamp validation; `crates/sign/src/timestamp.rs:1`; engine `sign_with_timestamp`/`timestamp_document` at `crates/engine/src/lib.rs:5083`/`:5103`; `docs/gaps.md` gap 10 | partial |
| 14 | Standards: PDF/A verify/convert only 2b/3b; no PDF/X or PDF/UA verification, no Preflight | `crates/preflight/src/lib.rs:31` (`Level::{A2b,A3b}`), `:174` (`declared` reads declarations only); `pdfa_verify`/`pdfa_convert` at `crates/automation/src/tools.rs:1119`/`:1126`; Preflight catalog entry `Planned("M11")` in `crates/engine/src/catalog.rs`; `docs/gaps.md` gap 9 | partial |
| 15 | OCR adds an invisible searchable layer but reads only unaccented Latin (`en`); models required | `crates/ocr/src/lib.rs:27` (`LANGUAGES = [("en","English")]`), `:33` (model error/`PDFCRAFT_MODELS`); `ocr_recognize` at `crates/automation/src/tools.rs:1175`; `docs/gaps.md` gap 7 | partial |
| 16 | Create PDFs from blank/images/text; 12 convertible extensions; text is WinAnsi-only; Office export only `.docx/.pptx/.html/.rtf`; no Office import | `crates/create/src/lib.rs:490` (`CONVERTIBLE` 12); `doc_create` at `crates/automation/src/tools.rs:1243`; `OfficeFormat::from_extension` at `crates/engine/src/compare.rs:149`; `doc_export_office` at `crates/automation/src/tools.rs:1116`; `docs/gaps.md` gap 8 | implemented (pages) / partial (text, Office) |
| 17 | Existing-text editing improved: in-place paragraphs/lines, formatting panel, arbitrary image rotation, header/footer shrink/font, measurement ratios, stable paragraph numbers; rotated text/vector/structure still missing | `text_edit` at `crates/automation/src/tools.rs:1335`; `docs/editing-existing-text.md` (including §Paragraph numbers); `crates/ui-egui/src/format_text_ui.rs:1`; `image_edit` `rotate_by` at `crates/automation/src/tools.rs:1299`; `doc_header_footer` `shrink`/`font` at `:916`; `measure_scale` ratio at `:659`; `docs/gaps.md` gap 3 | partial |
| 18 | Interface: 34 languages (English + 33 catalogs), 11 added vs v0.11.0; Chinese release glyphs and Arabic RTL layout remain limited | `crates/ui-egui/src/i18n/mod.rs:162` (`LANGUAGES: [LangInfo; 34]`); 33 `.tsv` catalogs; added ca, ckb, fi, hi, id, ko, lo, nb, ro, sq, th (machine diff vs `git show v0.11.0:crates/ui-egui/src/i18n/mod.rs`); `docs/gaps.md` gaps 5 and 14; `docs/localization-parity.md` | partial |
| 19 | Three automation front doors share one table; control channel has 17 opt-in loopback/token methods; the macOS app ships no CLI | CLI usage `apps/pdfcraft-cli/src/main.rs:57` (14 documented subcommands plus internal `check-one`); MCP `crates/automation/src/mcp.rs`, `docs/mcp.md`; 17 methods at `crates/ui-egui/src/control.rs:279`; `Contents/MacOS` holds only `PdfCraft`; `README.md` §Downloads lists the separate CLI zip | implemented |
| 20 | Rendering is borrowed and unmeasured against Acrobat; the web build lacks recovery/control transport/`ui.open`; the whole file is held in memory | `docs/gaps.md` gaps 2, 12, 13; `vendor/README.md` (hayro 0.7.1, hayro-syntax 0.7.2, hayro-interpret 0.7.0, new hayro-cmap 0.1.0); `crates/ui-egui/src/recovery.rs:9`; `crates/ui-egui/src/control.rs` wasm branches; `crates/fonts/build.rs:1` | partial |

## Notes and discrepancies found while verifying

- Counts changed as expected against the previous skill: tools **171 → 175** (+4, none removed) and
  commands **201 → 204** (+3, none removed). The control-channel method count is unchanged at 17;
  the CLI subcommand set is unchanged (14 documented plus the internal `check-one` worker).
  The previous skill's `171`/`201` were correct at v0.11.0, not at this tag.
- Internal parity docs lag the code at v0.12.0:
  - `docs/target-app-parity.md` row N still says "141 automation tools" (the real count is 175) and
    its Compare row now correctly says side-by-side and Text/Visual filter shipped.
  - `docs/gaps.md` gap 14 still says Hindi, Indonesian and Korean catalogs are missing;
    `hi.tsv`, `id.tsv` and `ko.tsv` exist (2,752 lines each) and are registered in `LANGUAGES`
    at this tag, so the gap text is stale even if some strings remain unreviewed.
  - `docs/gaps.md` gap 18 still lists "print as image" as missing; `doc_print` has `as_image`
    with a 72–600 dpi range and `crates/automation/src/printing.rs:144` implements the raster path.
  - `docs/target-app-parity.md` L Print also lists "print as image" as missing for the same reason.
  Code and the tool schema were trusted over these docs; the discrepancies are recorded here
  rather than silently resolved.
- `docs/gaps.md` gap 10 remains accurate for the *application* surface: there is no
  timestamp-server setting, no PKCS #11 on macOS/Linux, and no online revocation. The engine does
  contain transport-free TSA APIs (`sign_with_timestamp`, `timestamp_document`), and signature
  validation now checks embedded RFC 3161 tokens; neither is exposed by `sign_document` or a CLI
  subcommand. Do not promise timestamped signing from the CLI.
- `docs/localization-parity.md` reports 0% for Hindi, Indonesian and Korean even though the
  catalogs now contain thousands of translated rows. Its own note says the key union is a moving
  target and the table carries dates; the code registry (34 languages) is the authoritative count.
  The table still correctly flags Chinese release faces and Arabic RTL layout as unresolved.
- Line references moved between v0.11.0 and v0.12.0. Re-derived at this tag: `doc_save_with`
  918 → 1036, `write_atomically` 104 → 126, redaction verification 548 → 597, `write_incremental`
  180 → 189, `DocView::set_page_gaps` new at 1539, `tools()` start stays 117, `COMMANDS` start
  163 → 165. `AUTOSAVE_SECS` stays 28.
- The release commit is exactly the tag (`git rev-parse HEAD` = `39844f06…`, `git describe --tags`
  = `v0.12.0`), and the working tree was clean when inspected.
- The previous skill's command-line flag list was re-checked: the four new `set_option` keys at
  this tag are `page-gaps`, `default-page-gaps`, `thumbnail-zoom` and `always-default-view`; no key
  was removed. `--dialog` values and `--quick` families are unchanged.
- The new `view.page_gaps` command has no `ToolDef` at this tag. `command_run id=view.page_gaps` fails
  with `command "view.page_gaps" has no headless tool`; only the app command, the control channel
  (`ui.set key=page-gaps`) and the `--page-gaps` launch flag reach it. The two new form commands do
  map to tools. This is recorded as a limitation in SKILL.md rather than hidden.
- The previous skill said a second launch routes files to the running instance on all desktops.
  The code is more precise: the socket handoff is Windows and Linux/BSD; macOS routes Finder opens
  through Apple events (`apps/pdfcraft/src/single_instance.rs:1`; `apps/pdfcraft/src/apple_events.rs`).
  SKILL.md now states both.

## Confidence

- **High** for automation counts and names (machine-diffed against `git show v0.11.0`), command
  ids/shortcuts, new tool schemas, launch flags, save/print/redaction mechanics, control-channel
  methods, and packaging: all read directly from code at the inspected commit, and the installed
  bundle's build commit matches the pin exactly.
- **Medium** for the new form calculation order and text-field-table behaviour, print-permission
  enforcement and the improved redaction audit: the code paths, schemas and tests exist, but this
  audit did not execute them on a document; run `pdfcraft-cli tools` and a throwaway form before
  relying on edge cases (cycles, locked fields, permission bits).
- **Medium-low** for rendering/text fidelity, Office export quality, OCR accuracy and localization
  usability: the repo's own gap list calls them unmeasured, basic or partial, and no independent
  measurement was performed for this skill.
- **Uncertain where docs and code disagree:** the discrepancies above are stated in place. The
  repo is the source of truth; the installed 0.12.0 bundle matches it, but a launcher update could
  change that.

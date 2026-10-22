# PdfCraft — evidence table

Inspected commit `3e3064532f04fd6ec769c6bd7b2c97464757970e` (tag `v0.11.0`, released 2026-10-21).
Installed app `/Applications/PdfCraft.app` reports version 0.11.0 and
`PdfCraftBuildCommit = 3e3064532f04fd6ec769c6bd7b2c97464757970e` (binary `--version` prints
`pdfcraft 0.11.0`), so the bundle and checkout match. Inspection date: 2026-10-22.
Tier: **implemented** = wired into UI/CLI and code path present; **partial** = present but visibly
incomplete or limited; **claimed** = stated in README/docs but not confirmed in code.

| # | Capability claim | Evidence | Tier |
|---|---|---|---|
| 1 | Installed 0.11.0 bundle is the inspected checkout | `/Applications/PdfCraft.app/Contents/Info.plist` `CFBundleShortVersionString`, `PdfCraftBuildCommit`; binary `--version` = `pdfcraft 0.11.0`; `git rev-parse HEAD` = `3e30645…` | implemented (environment) |
| 2 | Automation surface: **171** JSON-Schema tools (+1 vs 170 at v0.9.0: `page_reverse`; none removed/retitled) and a **201**-command registry (+1: `page.reverse`) | `crates/automation/src/tools.rs:117` (`tools()`) — 171 `t("name", "title", …)` registrations, counted with a multiline-aware match; `crates/engine/src/commands.rs:163` (`COMMANDS`) — 201 `c(...)`/`ct(...)` entries; `tools.rs:227` and `commands.rs:365` for the additions | implemented |
| 3 | Save in place is an incremental append; Save As/new path is a full rewrite (garbage-collected unless signed); writes are atomic; `flatten_fill_sign` bakes Fill & Sign first | `crates/automation/src/lib.rs:918` (`doc_save_with`); `crates/cos/src/writer.rs:180` (`write_incremental`); `crates/platform/src/staging.rs:104` (`write_atomically`); `docs/architecture.md` §Data model step 4 | implemented |
| 4 | Unsaved work is autosaved every 60 s and offered for recovery after a crash; encrypted docs stay encrypted | `crates/ui-egui/src/recovery.rs:28` (`AUTOSAVE_SECS = 60.0`), module docs (:9 encrypted) | implemented (native; web has no store) |
| 5 | Combine keeps bookmarks, links, form fields, layer defaults and attachments; field-name conflicts resolve by rename/merge; split by count, pages, bookmarks or size | `crates/organize/src/import.rs` (fields :46, layers :17); `doc_combine` at `crates/automation/src/tools.rs:245` (`field_conflicts`), `doc_split` at `:272` | implemented |
| 6 | Create PDF from blank, images and text; 12 convertible extensions; text creation is WinAnsi-only | `crates/create/src/lib.rs:490` (`CONVERTIBLE` = png/jpg/jpeg/tif/tiff/gif/bmp/jp2/j2k/jpx/txt/text); `doc_create` at `crates/automation/src/tools.rs:1193` ("Western European (WinAnsi) characters only") | implemented (text partial) |
| 7 | Export pages as PNG/JPEG/TIFF at a chosen DPI (CLI render also writes `.pam`, stamps DPI); Office export: `.docx`, `.pptx`, `.html/.htm`, `.rtf`; no `.xlsx`/SVG/EPS/PS | `crates/engine/src/export.rs` (`encode_image` now takes dpi); `doc_export_images` at `tools.rs:919`; `crates/engine/src/compare.rs:129` (`OfficeFormat`); `apps/pdfcraft-cli/src/main.rs` `render`; gap 8 in `docs/gaps.md` | implemented (pages) / partial (office, basic/lossy) |
| 8 | Form/comment data import/export through `.xfdf`, `.fdf`, `.xml`, `.xdp`, `.csv`, `.txt/.tab/.tsv` | `crates/xfdf/src/lib.rs:52` (`Format::from_extension`); `doc_export_data`/`doc_import_data` at `crates/automation/src/tools.rs:413,416` | implemented |
| 9 | OCR produces a searchable image but reads only unaccented Latin (`en`); models required | `crates/ocr/src/lib.rs:27` (`LANGUAGES = [("en","English")]`), `:33` (models error, `PDFCRAFT_MODELS`); `ocr_recognize` at `crates/automation/src/tools.rs:1125` | partial |
| 10 | PDF/A verify/convert only 2b and 3b; no PDF/UA verification anywhere; no Preflight | `crates/preflight/src/lib.rs:31` (`Level::{A2b,A3b}`); `pdfa_verify`/`pdfa_convert`; `declared()` at `crates/preflight/src/lib.rs:174` is declaration-reading only; Preflight catalog entry `Planned("M11")` at `crates/engine/src/catalog.rs:409` | partial |
| 11 | CLI `info` reports declared PDF/A level, PDF/UA part and output intents; `text`/`render` use the laid-out dynamic-XFA pages; `text` honours copy permission | `apps/pdfcraft-cli/src/main.rs` `info` (`pdfa`, `pdfua`, `output_intents`, `pdf_pages`, `acroform_fields`, `custom_properties`), `text` (`check_copying`, `doc.display` for XFA), `render` (XFA display copy); `docs/target-app-parity.md` row F ("CLI info, text and render use the laid-out dynamic pages (#1645)") | implemented |
| 12 | Redaction removes content and verifies nothing readable remains; separate faux-redaction audit; CLI audit exits non-zero | `crates/redact/src/lib.rs:548` ("Verify: nothing readable may remain under a region"); `redact_apply`/`doc_audit_redactions` in `crates/automation/src/tools.rs`; `apps/pdfcraft-cli/src/main.rs` `audit` | implemented |
| 13 | Signatures: `.p12/.pfx`, macOS Keychain, Windows store; PAdES B-B; certification levels; no TSA/smart-card controls | `sign_document` at `crates/automation/src/tools.rs:699` (`certify` enum at `:712`); `crates/sign/src/cms.rs:291` (PAdES B-B); no `tsa` argument; gap 10 in `docs/gaps.md` | partial |
| 14 | Compare text + visual regions, side-by-side view (auto when the old tab is open and width ≥ 1000), PDF report, mark differences as comments | `doc_compare`/`doc_compare_report`/`doc_compare_mark` in `crates/automation/src/tools.rs`; `crates/ui-egui/src/compare_ui.rs:207` (width gate), `:112` ("Side by side") | implemented (no filters/page ranges) |
| 15 | Accessibility checker with 32 rules in 7 categories; text-only auto-tagging; report | `accessibility_check` at `crates/automation/src/tools.rs:940`; `accessibility_autotag_apply` at `:935`; `crates/a11y/src/lib.rs:3` ("the 32 rules in Acrobat's seven categories"), `:44` (7 categories); gap 11 in `docs/gaps.md` | partial |
| 16 | MCP server is opt-in, stdio-only, no port, with separate read/write roots and compact mode (`tool_search`/`tool_call`) | `apps/pdfcraft-cli/src/main.rs:57` (`USAGE`); `crates/automation/src/mcp.rs:60-61` (`TOOL_SEARCH`, `TOOL_CALL`); `docs/mcp.md` (incl. new install/registration section) | implemented |
| 17 | UI control channel is opt-in, loopback-only, token-authenticated; 17 methods incl. inspect/click/type/key/command/screenshot/quit/dock | `crates/ui-egui/src/control.rs:278-298` (method dispatch), `:4` (loopback-only), `:786` ("transport (native only)"); `README.md` §Driving the app itself (:310) | implemented (native only) |
| 18 | Desktop packaging/behaviour facts: the macOS `.app` contains no `pdfcraft-cli` (separate `pdfcraft-cli-<ver>-macos-universal.zip`); a second launch hands files to the running instance; window size/position restored | Bundle listing: `Contents/MacOS` holds only `PdfCraft`; `crates/automation/README.md:103` §From an installed release; `README.md` §Downloads (:498-499); `apps/pdfcraft/src/single_instance.rs:2` (#282, #317, #1726); `crates/ui-egui/src/window_state.rs` | implemented |
| 19 | Existing-text editing is improved but still limited (Latin good; CJK/RTL/rotated/vector/structure gaps); text no face can show is refused; web build has no crash recovery, no control-channel transport, no `ui.open`, browser print only, subset font embed | `docs/gaps.md` gaps 3; `docs/editing-existing-text.md`; `text_edit` at `crates/automation/src/tools.rs:1284` ("Text that no available font can show is refused"); `crates/ui-egui/src/recovery.rs:9`; `crates/ui-egui/src/control.rs:297` (`ui.open`), `:786`; `crates/fonts/build.rs:3-4` | partial |

## Notes and discrepancies found while verifying

- `docs/target-app-parity.md` is still stale in the same places noted at v0.9.0: line 67 says
  "184 registered commands, 141 automation tools" and row N still lists "side-by-side compare" as
  missing, while this tag has 171 tools, 201 commands and `compare_ui::side_by_side`. Code was
  trusted over the doc.
- The README tagline changed at v0.11.0: it no longer says "clean-room reimplementation of Adobe
  Acrobat" (now "modern PDF reader and editor"), and the Adobe trademark footnote was removed. The
  parity target is still Acrobat Pro in `docs/target-app-parity.md` and `ROADMAP.md` ("Target:
  Adobe Acrobat Pro (Acrobat DC, continuous track 26.002.21931, macOS)"); SKILL.md describes both.
- `docs/gaps.md` is byte-identical between v0.9.0 and v0.11.0 (`git diff` empty), so every gap
  number/citation carried over unchanged; line references into code were re-derived at this tag
  (e.g. redaction verify comment moved 493 → 548, staging `write_atomically` 73 → 104,
  `AUTOSAVE_SECS` 25 → 28).
- `page_duplicate` gained an `at` insertion position (absent at `git show v0.9.0:…/tools.rs`).
- Launch-option keys in `set_option` are identical between v0.9.0 and v0.11.0 (none added or
  removed); `--quick` accepts the same broad set at both tags. The v0.11.0 SKILL.md simply lists
  them more completely.
- Interface catalogs: 22 `.tsv` files under `crates/ui-egui/src/i18n/` at v0.11.0 (23 at v0.9.0).
  Not used for any claim (localization readiness is not asserted in SKILL.md).
- README and ROADMAP still quote different readiness percentages (README "57% of the features
  tracked … 94% of core essentials"; ROADMAP alpha→beta ~25%). SKILL.md says "alpha" and does not
  quote a percentage.

## Confidence

- **High** for automation surface (tool/command counts machine-diffed against `git show v0.9.0`),
  command ids/shortcuts, file formats, save/redaction/signature mechanics, CLI behaviour, control
  channel, and packaging: all read directly from code at the inspected commit, and the installed
  bundle commit matches the pin exactly.
- **Medium** for rendering/text fidelity and Office export quality: docs state them, but the repo's
  own gap list says they are unmeasured or basic (`docs/gaps.md` gaps 2, 8, 12).
- **Medium-low** for OCR accuracy, XFA fidelity, and large-file performance: documented limits
  exist, but no independent measurement was performed for this skill.

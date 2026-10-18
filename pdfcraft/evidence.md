# PdfCraft — evidence table

Inspected commit `645016addcfb9078c557f0189559ab47cdcee057` (tag `v0.9.0`, 2026-10-17).
Installed app `/Applications/PdfCraft.app` reports version 0.9.0 and
`PdfCraftBuildCommit = 645016addcfb9078c557f0189559ab47cdcee057`, so the bundle and checkout match.
Tier: **implemented** = wired into UI/CLI and code path present; **partial** = present but visibly
incomplete or limited; **claimed** = stated in README/docs but not confirmed in code.

| # | Capability claim | Evidence | Tier |
|---|---|---|---|
| 1 | Installed 0.9.0 bundle is the inspected checkout | `/Applications/PdfCraft.app/Contents/Info.plist` `CFBundleShortVersionString`, `PdfCraftBuildCommit`; `git rev-parse HEAD` = `645016a…` | implemented (environment) |
| 2 | Automation surface: **170** JSON-Schema tools and a **200**-command registry with menus/shortcuts | `crates/automation/src/tools.rs:117` (`tools()`) — 170 unique `t("name"` definitions; `crates/engine/src/commands.rs:163` (`COMMANDS`) — 200 `c(...)`/`ct(...)` entries | implemented |
| 3 | Save in place is an incremental append; Save As/new path is a full rewrite; writes are atomic | `crates/automation/src/lib.rs:906-935` (`doc_save_with`: `full` defaults to `!same_file`); `crates/cos/src/writer.rs:180` (`write_incremental`); `crates/platform/src/staging.rs:73` (`write_atomically`) | implemented |
| 4 | Unsaved work is autosaved every 60 s and offered for recovery after a crash; encrypted docs stay encrypted | `crates/ui-egui/src/recovery.rs:25` (`AUTOSAVE_SECS = 60.0`), module docs | implemented (native; web has no store) |
| 5 | Combine keeps bookmarks, links, form fields, layer defaults and attachments; split by count, pages, bookmarks or size | `crates/organize/src/import.rs:904-1040` (attachments, layers, fields, outline); `doc_combine`/`doc_split` at `crates/automation/src/tools.rs:242,269` | implemented |
| 6 | Create PDF from blank, images and text; 12 convertible extensions; text creation is WinAnsi-only | `crates/create/src/lib.rs:489` (`CONVERTIBLE` = png/jpg/jpeg/tif/tiff/gif/bmp/jp2/j2k/jpx/txt/text); `doc_create` at `crates/automation/src/tools.rs:1188-1205` ("Western European (WinAnsi) characters only") | implemented (text partial) |
| 7 | Export pages as PNG, JPEG or TIFF at a chosen DPI, including unsaved edits | `crates/engine/src/export.rs:162` (`ImageFormat`); `doc_export_images` at `crates/automation/src/tools.rs:914`; CLI `render` also writes `.pam` (`apps/pdfcraft-cli/src/main.rs:581-605`) | implemented |
| 8 | Office export: `.docx`, `.pptx`, `.html/.htm`, `.rtf`; no `.xlsx`/SVG/EPS/PS | `crates/engine/src/compare.rs:126-148` (`OfficeFormat`); `doc_export_office`; gap 8 in `docs/gaps.md` | partial (basic/lossy) |
| 9 | Form/comment data import/export through `.xfdf`, `.fdf`, `.xml`, `.xdp`, `.csv`, `.txt/.tab/.tsv` | `crates/xfdf/src/lib.rs:49-59` (`Format::from_extension`); `doc_export_data`/`doc_import_data` at `crates/automation/src/tools.rs:408,411` | implemented |
| 10 | OCR produces a searchable image but reads only unaccented Latin (`en`) | `crates/ocr/src/lib.rs:27` (`LANGUAGES = [("en","English")]`); `ocr_recognize` schema enum `["en"]` at `crates/automation/src/tools.rs:1127`; models required (`ocr_status`) | partial |
| 11 | PDF/A verify/convert only 2b and 3b; no Preflight | `crates/preflight/src/lib.rs:31` (`Level::{A2b,A3b}`); `pdfa_verify`/`pdfa_convert`; Preflight catalog entry `Planned("M11")` at `crates/engine/src/catalog.rs:408` | partial |
| 12 | Redaction removes content and verifies nothing readable remains; separate faux-redaction audit; CLI audit exits non-zero | `crates/redact/src/lib.rs:493` ("Verify: nothing readable may remain"); `redact_apply` at `crates/automation/src/tools.rs:442`; `doc_audit_redactions` at `:472`; `apps/pdfcraft-cli/src/main.rs:169-192` | implemented |
| 13 | Signatures: `.p12/.pfx`, macOS Keychain, Windows store; PAdES B-B; certification levels; no TSA/smart-card controls | `sign_document` schema at `crates/automation/src/tools.rs:694-747`; `crates/sign/src/cms.rs:291` (PAdES B-B); `crates/sign/src/keys.rs:95` (SHA-256/384); no `tsa` argument; gap 10 in `docs/gaps.md` | partial |
| 14 | Compare text + visual regions, side-by-side view, PDF report, mark differences as comments | `doc_compare`/`doc_compare_report`/`doc_compare_mark` at `crates/automation/src/tools.rs:1091-1100`; `crates/ui-egui/src/compare_ui.rs:112` ("Side by side"), `:207-214` (auto side-by-side when the old tab is open and width ≥ 1000) | implemented (no filters/page ranges) |
| 15 | Accessibility checker with 32 rules in 7 categories; text-only auto-tagging; report | `accessibility_check` description at `crates/automation/src/tools.rs:935`; `accessibility_autotag_apply` at `:930`; `crates/a11y/{autotag.rs,report.rs,structure.rs}`; gap 11 in `docs/gaps.md` | partial |
| 16 | MCP server is opt-in, stdio-only, no port, with separate read/write roots and compact mode | `apps/pdfcraft-cli/src/main.rs:57-80` (`USAGE`); `docs/mcp.md`; `crates/automation/src/mcp.rs` | implemented |
| 17 | UI control channel is opt-in, loopback-only, token-authenticated; inspect/click/type/key/command/screenshot/quit | `crates/ui-egui/src/control.rs:279-350` (method dispatch), `:777` ("transport (native only)"); `apps/pdfcraft/src/main.rs:487-511` (owner-only control file); `README.md` §Driving the app itself | implemented (native only) |
| 18 | The macOS `.app` contains no `pdfcraft-cli`; CLI is a separate release zip | Bundle listing: `Contents/MacOS` holds only `PdfCraft`; `which pdfcraft-cli` empty; `crates/automation/README.md` §From an installed release | implemented (packaging fact) |
| 19 | Existing-text editing is improved but still limited (Latin good; CJK/RTL/rotated/vector/structure gaps) | `docs/gaps.md` gap 3; `docs/editing-existing-text.md`; `text_edit` description at `crates/automation/src/tools.rs:1279`; refusal for text no available face can show | partial |
| 20 | Web build has no crash recovery, no control channel transport, no `ui.open`, browser print only | `crates/ui-egui/src/recovery.rs:10`; `crates/ui-egui/src/control.rs:769` (`ui.open` wasm arm), `:777`; `crates/ui-egui/src/web_print.rs` | partial |

## Notes and discrepancies found while verifying

- `docs/target-app-parity.md` is stale in at least two places: it says "141 automation tools" and
  lists "side-by-side compare" as missing. HEAD has 170 tools and `compare_ui::side_by_side`.
  Code was trusted over the doc.
- `docs/file-format-parity.md`'s OCR table says camera images (edges, perspective) are missing, but
  `page_enhance_camera` exists and `crates/engine/src/camera.rs` warps a photographed page to an
  upright rectangle; the cleanup path is `camera_clean.rs`. Code was trusted over the doc.
- Gap 5 (Chinese UI boxes) is nuanced: desktop builds fall back to an installed Chinese face
  (`crates/ui-egui/src/system_fonts.rs:5`, `theme.rs:231`), while the web build has no installed
  fonts. Do not state "Chinese UI is broken everywhere".
- README and ROADMAP quote different readiness percentages (README "57% of features / 49% overall",
  ROADMAP "≈67% tier-weighted / 56.9% unweighted"). This skill therefore says "alpha" and does not
  quote a percentage.
- `docs/localization.md` contains several duplicated, mutually inconsistent status paragraphs; the
  authoritative list in `crates/ui-egui/src/i18n/*.tsv` has 23 catalogs. Not used for any claim.

## Confidence

- **High** for automation surface, command ids/shortcuts, file formats, save/redaction/signature
  mechanics, control channel, and packaging: all read directly from code at the inspected commit.
- **Medium** for rendering/text fidelity and Office export quality: docs state them, but the repo's
  own gap list says they are unmeasured or basic (`docs/gaps.md` gaps 2, 8, 12).
- **Medium-low** for OCR accuracy, XFA fidelity, and large-file performance: documented limits
  exist, but no independent measurement was performed for this skill.

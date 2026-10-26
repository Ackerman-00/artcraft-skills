# PdfCraft — evidence table

Audit basis: this checkout is tag `v0.14.0`, commit `5a78b223871add8e3883856205cc653d741e0e94` ("Release 0.14.0", published 2026-10-25). The installed
`/Applications/PdfCraft.app` reports `CFBundleShortVersionString = 0.14.0`, bundle id `ai.storyteller.pdfcraft`,
`LSMinimumSystemVersion = 11.0` and `PdfCraftBuildCommit = 5a78b223871add8e3883856205cc653d741e0e94`; its binary prints
`pdfcraft 0.14.0`. The bundle therefore matches this source exactly. Inspection date: 2026-10-26.
The checkout was not modified or built; the app was only version-checked from its bundle and binary (no GUI window).

Tier: **implemented** = code path exists and is wired into UI/CLI; **partial** = present but visibly incomplete or limited;
**claimed** = stated in README/docs but not confirmed in code; **absent** = no code path found.

| # | Capability claim | Evidence | Tier |
|---|---|---|---|
| 1 | Installed 0.14.0 bundle is the inspected release commit | `/Applications/PdfCraft.app/Contents/Info.plist` `CFBundleShortVersionString`, `PdfCraftBuildCommit`; binary `--version` → `pdfcraft 0.14.0`; `git rev-parse HEAD` = `5a78b223…` | implemented (environment) |
| 2 | Automation surface: **179** JSON-Schema tools (+4 vs 175 at v0.12.0), none removed | `crates/automation/src/tools.rs:120` (`tools()`), 179 `t(...)` registrations, 179 `.with(...)`; added `attachment_add`, `attachment_delete`, `bookmark_set_style`, `content_copy` by machine diff against the published `v0.12.0` file | implemented |
| 3 | Command registry: **205** command ids (+1 vs 204), none removed | `crates/engine/src/commands.rs:165` (`COMMANDS`), 205 `c(...)`/`ct(...)` entries; the added id is `edit.attach` (machine diff against `v0.12.0`) | implemented |
| 4 | 71 commands map to a tool; `view.page_gaps` still has none | `ToolDef::command` (`.cmd(…)`) 71 unique ids, all present in `COMMANDS`; `command_run` on an unmapped id fails with "has no headless tool" (`crates/automation/src/conventions.rs:15`); no `page_gaps` tool in `crates/automation/src/tools.rs` | implemented (with a documented gap) |
| 5 | CLI: 14 documented subcommands + internal `check-one`, 25 option names, unchanged since v0.12.0 | `apps/pdfcraft-cli/src/main.rs:57` (`USAGE`), dispatch at `:110`; `--flag` name set identical to the published v0.12.0 file | implemented |
| 6 | UI control channel: 17 methods, loopback + random token, owner-only file checks, dock operations | `crates/ui-egui/src/control.rs:282` (`ui.state`, … 17 methods); `apps/pdfcraft-cli/src/main.rs` `read_control_file` (refuses symlink, non-regular file, foreign-owned/group-readable file); `ui.dock` operation text at `crates/ui-egui/src/control.rs:766` | implemented |
| 7 | Interface: 34 languages (English + 33 catalogs), unchanged | `crates/ui-egui/src/i18n/mod.rs:162` (`LANGUAGES: [LangInfo; 34]`), 33 `.tsv` catalogs; identical list to v0.12.0; `docs/localization.md` describes per-language status | partial (Chinese release glyphs, Arabic RTL, no translated help) |
| 8 | MCP server: stdio only, 4 resource templates + 2 resources, `--compact` = 15 core tools + `tool_search`/`tool_call`, 16 MiB request cap, root confinement | `crates/automation/src/mcp.rs:45` (`COMPACT_CORE_TOOLS`, 15 entries), `:10`–`:11` (implemented JSON-RPC methods), resource templates at `:453`–`:459`, `MAX_LINE_BYTES` 16 MiB, `crates/automation/src/file_access.rs` (UNC/device names refused by name) | implemented |
| 9 | Save in place = incremental append; new path = full rewrite; atomic staging; `flatten_fill_sign` bakes Fill & Sign first | `crates/cos/src/writer.rs:199` (`write_incremental`), `crates/platform/src/staging.rs:126` (`write_atomically`), `doc_save` schema (`crates/automation/src/tools.rs`), `docs/architecture.md` §Data model and editing | implemented |
| 10 | Attachments: add and delete document-level attachments; **no** extraction tool | `attachment_add`/`attachment_delete` at `crates/automation/src/tools.rs` and `crates/automation/src/lib.rs:841`; `crates/organize/src/attachments.rs` (`add_attachment`, `delete_attachment`); command `edit.attach`; UI open/save in `crates/ui-egui/src/panels.rs:665`; no `attachment_*` getter in `tools()` | implemented (add/delete) / absent (extract) |
| 11 | `content_copy` pastes an added text box/image into the same or another document; headless only | `content_copy` at `crates/automation/src/tools.rs`; `crates/automation/src/content.rs:217`; engine `Edit::PasteContent` at `crates/engine/src/lib.rs:1847`; no `PasteContent` use under `crates/ui-egui/src`; `ROADMAP.md` (2026-10-23) says desktop keys/menus follow separately | implemented (engine/CLI) / partial (no UI) |
| 12 | Comment threads follow `/IRT`; shared `/NM` ids refused; per-reply status/checkmark; arrow-key nudge; "Keep tool selected" pin | `crates/render/src/inspect.rs:574` (`thread_tops`), `crates/automation/src/comments.rs:153` (`comment_target`), `:226` (thread build); `comment_ref` id note in `crates/automation/src/tools.rs`; `crates/ui-egui/src/comments.rs:1871` (arrow keys), `:2199` (pin), `comment-tool-pinned` in `set_option` | implemented |
| 13 | Bookmarks carry colour and bold/italic, settable and reported | `bookmark_set_style` in `crates/automation/src/tools.rs`; `crates/organize/src/outline.rs:46`–`:49`, `:636` (`set_bookmark_color`), `:647` (`set_bookmark_style`); `bookmark_list` description reports them | implemented |
| 14 | Custom document properties through `doc_set_info` (Document Properties ▸ Custom) | `doc_set_info` description (`crates/automation/src/tools.rs`), dialog value `custom` in `set_option` (`crates/ui-egui/src/lib.rs`), `docs/pdf-spec-parity.md` §14.3 ("custom properties listed, added, changed and deleted … partial") | implemented / partial |
| 15 | Forms: dotted parent names, calculation order, text-field tables | `form_add_field`/`form_set_props` descriptions in `crates/automation/src/tools.rs`; `crates/forms/src/calc_order.rs`; `crates/forms/src/table.rs` (100 × 50 caps); `crates/ui-egui/src/calc_order_ui.rs`, `crates/ui-egui/src/field_table_ui.rs` | implemented (cycles reported, not repaired) |
| 16 | Accessibility: 32 rules, tag property edits incl. table `summary` and TH `scope`; no reading-order/table editor | `crates/a11y/src/lib.rs` (32 rules, 7 categories), `crates/a11y/src/tags.rs`, `accessibility_set_tag_property` enum `summary`/`scope` in `crates/automation/src/tools.rs`, `docs/gaps.md` gap 11 | partial |
| 17 | Redaction: 5 patterns, Italian labelled phone numbers, faux-redaction audit bounded and copy-permission aware | `crates/redact/src/patterns.rs:16` (`PATTERNS`), phone-label handling in `crates/redact/src/patterns.rs`; `crates/audit/src/lib.rs` (crash-safe limits, `copying`, report budget), `doc_audit_redactions`/`pdfcraft-cli audit` | implemented |
| 18 | Print: 21 paper presets, paper sent as spooler `media`, booklet sets duplex, permissions enforced/≤150 dpi | `crates/print/src/lib.rs:295` (`PAPERS`, 21), `crates/automation/src/printing.rs` (`paper_named`, `spool_job`, `job_duplex`), `doc_print` description, `crates/engine/src/lib.rs` permission checks | implemented |
| 19 | Office export improved (table spans/grid widths, soft-mask Decode) but still lossy; no Office import | `crates/export/src/lib.rs`, `OfficeFormat::from_extension` at `crates/engine/src/compare.rs:156`, `doc_export_office` description (`truncated_pages`, 50-deep/50 000 forms), `CONVERTIBLE` at `crates/create/src/lib.rs:516` (no office/postscript extensions), `docs/gaps.md` gap 8 | partial |
| 20 | `doc_optimize` adds `compatibility`, `object_streams`, `lzw_to_flate`; signed documents refused | `doc_optimize` schema/description in `crates/automation/src/tools.rs`; `crates/optimize/src/lib.rs` | implemented |
| 21 | Hostile-file bounds: one decode budget per page walk (256 MiB, 50 000 forms), audit budget, MCP line cap | `crates/cos/src/budget.rs:11` (`MAX_PAGE_DECODED`), `:28` (`DecodeBudget`), `crates/audit/src/lib.rs` budget, `crates/automation/src/mcp.rs` `MAX_LINE_BYTES` | implemented |
| 22 | UI/platform additions: macOS per-file PDF association recovery (v0.13.0), Copy Image / Copy Image in Original Format, restore last view, expanded All tools view | `crates/ui-egui/src/macos_association.rs` (v0.13.0 release notes); `crates/engine/src/copy_image.rs`, `crates/ui-egui/src/canvas.rs:4113`–`:4141`; `crates/ui-egui/src/last_view.rs` (`MAX_REMEMBERED` 100, default on); `crates/ui-egui/src/all_tools_ui.rs`, `set_option` key `tools` value `full` | implemented (UI only; no tool for Copy Image or last view) |
| 23 | Web build partial: browser print dialog, no recovery store, no control transport, subset of fonts | `crates/ui-egui/src/web_print.rs`, `crates/ui-egui/src/recovery.rs` ("The web build has no recovery store yet"), native-only control code in `crates/ui-egui/src/control.rs`, `crates/fonts/build.rs` wasm face subset; `apps/pdfcraft-web` | partial |
| 24 | Rendering is vendored hayro and fidelity is unmeasured against Acrobat | `docs/gaps.md` gap 2, `vendor/README.md` (hayro 0.7.1, hayro-interpret 0.7.0, hayro-syntax 0.7.2, hayro-cmap 0.1.0); README rendering claims are unverified here | partial / claimed |
| 25 | OCR reads only unaccented Latin (`en`); batch duplicate outputs refused | `crates/ocr/src/lib.rs:27` (`LANGUAGES = [("en","English")]`), `ocr_status`/`PDFCRAFT_MODELS`, `ocr_recognize_files` description; `docs/gaps.md` gap 7 | partial |
| 26 | Signatures: PAdES B-B, `.p12`/Keychain/Windows store, trust bundles, offline CRL/OCSP + DSS, but no TSA setting or online fetching | `crates/sign/src/cms.rs:369`, `crates/sign/src/pdf.rs`, `crates/sign/src/timestamp.rs`, `crates/sign/src/revocation.rs`, `crates/sign/src/dss.rs`; engine-only `sign_with_timestamp`/`timestamp_document` at `crates/engine/src/lib.rs:5318`; `sign_trust` description; `docs/gaps.md` gap 10 | partial |
| 27 | Standards: PDF/A-2b/3b only, no PDF/X or PDF/UA verification, no Preflight | `crates/preflight/src/lib.rs:31` (`Level::{A2b,A3b}`), `pdfa_verify`/`pdfa_convert` descriptions, `crates/engine/src/catalog.rs` Preflight `Planned("M11")`; `docs/gaps.md` gap 9 | partial |

## Notes and discrepancies found while verifying

- **The previous skill's counts were correct for v0.12.0 but are stale here.** Re-measured at this tag: tools
  **175 → 179**, commands **204 → 205**, control methods **17 → 17**, interface languages **34 → 34**, CLI subcommands
  and flags unchanged. The four new tools are `attachment_add`, `attachment_delete`, `bookmark_set_style`,
  `content_copy`; the one new command is `edit.attach`. Nothing was removed or renamed.
- **Where the docs disagree with the code**, code wins: `docs/architecture.md`, `docs/ui-parity.md` and
  `docs/target-app-parity.md` still print "141 automation tools" (and "184 registered commands"), `docs/roadmap.md`
  M13 says 123 tools, and `docs/gaps.md` gaps 14 and 18 still list shipped work (Hindi/Indonesian/Korean catalogs,
  print-as-image) as missing. README's MCP section says "about ten core tools"; `COMPACT_CORE_TOOLS` has **15**.
- **Catalogue vs tool table**: `crates/engine/src/catalog.rs` lists 150 UI entries in 24 groups and 5 categories.
  At v0.12.0 it marked 32 entries/groups planned; now 31 — `Attach file` (M12) became `Ready` alongside
  `attachment_add`. Planned badges work in both directions: whole groups are badged planned (Edit a PDF M7,
  Protect a PDF M8, Use print production M11, Add search index M12, Use JavaScript M6) while several items inside
  them are `Ready` and do work. Neither a badge nor a tile is a capability verdict; the tool table is.
- **Line references moved between v0.11.0, v0.12.0 and v0.14.0.** Re-derived at this tag: `tools()` stays at 120,
  `COMMANDS` stays at 165, the dispatch in `crates/ui-egui/src/control.rs` starts at 282, `set_option` at 2885, `write_incremental` at 199,
  `write_atomically` at 126, redaction verification comment at 679, `thread_tops` at 574, `PAPERS` at 295,
  `CONVERTIBLE` at 516, `from_extension` at 156, `AUTOSAVE_SECS` at 28.
- **Shallow clone, no local history.** The checkout is a single-commit shallow worktree, so "what changed" was
  established by fetching the published `v0.12.0` files (`crates/automation/src/tools.rs`, `crates/engine/src/commands.rs`,
  `crates/engine/src/catalog.rs`, `crates/ui-egui/src/control.rs`, `crates/ui-egui/src/i18n/mod.rs`, `apps/pdfcraft-cli/src/main.rs`, `crates/create/src/lib.rs`,
  `crates/engine/src/compare.rs`, the `docs/` directory) from the tag and diffing them locally, plus the GitHub compare range
  `v0.12.0...v0.14.0` and the release notes for v0.13.0/v0.14.0. No clone file was modified.
- **The v0.12.0 → v0.14.0 delta is mostly hardening.** v0.13.0 shipped the macOS association recovery; v0.14.0 is
  dominated by bounds against hostile files (decode budget, audit budget, bounded Office-export form reads, MCP line
  cap, bounded form-data/XFA/script work) plus small features (attachment tools, bookmark colour/style, `content_copy`,
  per-reply comment status, accessibility `summary`/`scope`, custom properties, print paper/duplex fixes, FormCalc
  `Str()`/unit-name fixes, `sign_list` visibility for hidden/NoView signature fields). Treat v0.14.0 as a stability
  release, not a new-feature release.
- **FreeBSD aarch64** was dropped from v0.13.0 (CI time limit) and packaged again in v0.14.0; the README's FreeBSD
  table lists only x86_64. Not a macOS-relevant fact, recorded for completeness.
- **`view.page_gaps` still has no headless tool** at this tag (same as v0.12.0): only the app command, the control
  channel (`ui.set key=page-gaps`) and `--page-gaps` reach it. `command_run id=view.page_gaps` fails with
  "has no headless tool". This is recorded as a limitation rather than hidden.
- **`content_copy` is not reachable from the desktop**: the engine edit (`Edit::PasteContent`) and the automation tool
  exist, but no menu id, shortcut or UI call site was found; `ROADMAP.md` says the desktop keys and menus follow in
  separate PRs. Do not tell a user Edit ▸ Paste copies an added text box yet.
- **Attachment extraction is still missing.** The Attachments panel opens or saves an attachment
  (`crates/ui-egui/src/panels.rs:665`), and `attachment_data` exists in `crates/render`, but no automation tool exposes
  it. `doc_info` only lists names/keys.

## Confidence

- **High** for automation counts and names, command ids/shortcuts, CLI surface, control-channel methods, MCP surface,
  save/print/redaction/attachment mechanics, and packaging: all read directly from code at the inspected commit, the
  installed bundle's build commit matches the pin exactly, and every count was machine-diffed against v0.12.0.
- **Medium** for the behavioural details of the new pieces (comment thread resolution, `content_copy` cross-document
  paste, print paper/duplex on real queues, accessibility summary/scope, custom properties): code paths, schemas and
  tests exist, but this audit did not execute them on a document. Run a throwaway round trip before relying on edge
  cases.
- **Medium-low** for rendering/text fidelity, Office export quality, OCR accuracy and localization usability: the
  repo's own gap list calls them unmeasured, basic or partial, and no independent measurement was performed here.
- **Uncertain where docs and code disagree:** the drifts above are stated in place. The repo is the source of truth;
  the installed 0.14.0 bundle matches it now, but a launcher update could change that.

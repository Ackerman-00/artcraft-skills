# WordCraft skill — evidence table

Audit basis: tag **v0.10.0**, commit **`9130181a5fdaee2293e67756fd5458c601489f3c`** ("Release 0.10.0", 2026-10-22). Installed `/Applications/WordCraft.app`: `CFBundleShortVersionString` = `CFBundleVersion` = `0.10.0`, bundle id `ai.storyteller.wordcraft`; its binary prints `wordcraft 0.10.0 (9130181a)`. Lines below are from that tag. v0.9.0..v0.10.0 (1,547 commits) was diffed; rows marked **[new in 0.10]** changed since the previous skill.

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier | Notes |
|---|---|---|---|---|
| 1 | Clean-room Word reimplementation, alpha, MIT OR Apache-2.0, repo `storytold/wordcraft`, version 0.10.0 | README.md:17,372; ROADMAP.md:3; Cargo.toml:7,9 | implemented (self-described; licence files present) | `Cargo.toml:7` is `version = "0.10.0"` |
| 2 | Registry holds **638 commands**; +5 vs 0.9 (`file.listTemplates`, `format.underlineColor`, `text.insertTab`, `view.formatShapePane`, `view.fullScreenView`), none removed | 638 `CommandSpec::new(` entries across `crates/engine/src/cmd/*.rs` (50 modules + `mod.rs`), counted from source 2026-10-23; `crates/engine/src/cmd/mod.rs::registry` | implemented (counted) | The repo's own counts are stale: README.md:105,200 = 422; ROADMAP.md:21,28 = 493/508 and 433; docs/mcp.md:106 = "over 270" |
| 3 | Catalog **498/513 (97.1%)**, floor enforced by test | docs/parity-checklist.md:5; `crates/engine/src/catalog.rs:583–588` (`parity_floor`) | implemented (generated doc + test) | Was 492/507 (97.0%) at v0.9.0 |
| 4 | 50 command modules | `crates/engine/src/cmd/*.rs` (51 files incl. `mod.rs`) | implemented | Previous skill said 48 |
| 5 | Formats opened: docx, docm, dotx, dotm, doc, dot, txt, md, markdown, html, htm, rtf, odt, tex, latex, ltx, xml, wcraft.json, json; unknown/extensionless open by content with encoding detection, else refused | `crates/engine/src/io.rs:9–29` (OPEN_EXTS), `:316–330` (`open_by_content`), `crates/formats/src/lib.rs` | implemented | Unchanged in 0.10 |
| 6 | Formats saved: docx, docm, dotx, dotm, pdf, txt, md, html, rtf, odt, tex, png, json, xml; Word XML (Flat OPC) / Word 2003 XML via `.xml` (+`--format wordml2003`) | `crates/engine/src/io.rs:31` (SAVE_EXTS), `:52–62` (`ExportOptions`), `crates/engine/src/io_ext.rs` | implemented | Unchanged in 0.10 |
| 7 | Password `.docx` opens/saves (agile); a file opened with a password is saved with it again; exports that cannot carry one stay plain; CLI `--password`/`--password-file`/`WORDCRAFT_PASSWORD` | `crates/docx/src/crypt.rs`; apps/wordcraft-cli/src/main.rs:57–61,129–140 | implemented (synthetic tests) | `.doc` AES refused; XOR/RC4/RC4 CryptoAPI open, untested on Word-written files (`crates/docbin/src/lib.rs:85–92`) |
| 8 | Pictures: PNG, JPEG, GIF, WebP, BMP, TIFF, WMF/EMF; not SVG/ICO/HEIC | `crates/engine/src/cmd/insert.rs:230–241` (`image_ext`, TIFF magic); Cargo.toml:56 (`tiff` feature); `crates/metafile`; docs/file-format-parity.md:59 | implemented (code) | Doc row 59 still lists TIFF as unsupported — stale |
| 9 | Personal templates: `file.listTemplates` (≤500, ≤64 categories, one subfolder level, network folder refused, read root applies), `file.newFromTemplate` (untitled, dirty, attached), `file.saveTemplate`, GUI `ui.saveAsTemplate` **[new in 0.10]** | `crates/engine/src/cmd/user_templates.rs:1–13,17–30`; `crates/engine/src/cmd/tools.rs:490–510`; `crates/ui-egui/src/lib.rs:1730–1733`; docs/ui-parity.md:286 | implemented | `listTemplates` without `dir` errors when no folder is saved (`user_templates.rs:68–74`) |
| 10 | `file.saveTemplate` appends `.dotx` unless the path ends `.dotx`/`.dotm`; `out.docx` → `out.docx.dotx`; `file.new` ignores unknown template names and yields a blank document | `crates/engine/src/cmd/tools.rs:502–506`; `crates/engine/src/cmd/file.rs:196–204` | implemented | Footguns, not bugs: Word-like naming and silent fallback |
| 11 | New commands work as described: underline colour (`w:u/@w:color`), literal tab (`Alt+Tab` macOS / `Mod+Tab`), Full Screen View (pages alone, exclusive with Focus), Format Shape pane | `crates/engine/src/cmd/format.rs:105–106,371–379`; `crates/engine/src/cmd/text.rs:21–22`; `crates/engine/src/cmd/view.rs:53–59,118–122`; `crates/ui-egui/src/format_shape.rs:79–84` | implemented | — |
| 12 | New fidelity: shape gradients/transparency, Word signature lines kept, table style band sizes, tracked table/row/cell/section property changes, content-control save speed (32k: 3.6 s → 0.1 s), radar charts drawn, HTML ruby R/W, RTF East Asian code pages, ODT column widths + master-page headers | docs/file-format-parity.md:3,56,58,118,257,259,262; docs/gaps.md:59,67,74,75; `crates/docx/src/read/chart.rs:5,83,152–164`; `crates/formats/src/html.rs:7,13–14` | implemented | docs/file-format-parity.md:109 still lists radar as undrawn — stale |
| 13 | MCP server, stdio, **16 tools** + `wordcraft://document`, `wordcraft://commands`; app-only `screenshot`/`click`/`key`/`ui_inspect` | `crates/mcp/src/tools.rs:55–135` (definitions; `call_tool` :168); `crates/mcp/src/server.rs:28–29`; docs/mcp.md:102–122 | implemented | Unchanged count and shape vs 0.9 |
| 14 | CLI: 10 subcommands (`convert info text inspect render run commands parity mcp zotero`) and the flag set listed; `run --script` JSON jobs (4 MiB cap, paths vs script folder, 64 outputs max, fails before writing) | apps/wordcraft-cli/src/main.rs:16–67 (USAGE), :70 (`SUBCOMMANDS`), :486–530; apps/wordcraft-cli/src/script.rs:1–21,24–30 | implemented | Unchanged vs 0.9 |
| 15 | Control channel: JSON lines on loopback, per-window key `<settings>/control-key.local-<port>` mode 0600, `auth`, 30 s idle, 19 methods + command-id fallthrough | docs/control-protocol.md:19,36–49,51–70; `crates/control-key/src/lib.rs`; `crates/ui-egui/src/control.rs:131–282` | implemented | Unchanged vs 0.9 |
| 16 | Cautions: `ui.key`/`ui.text` queue (`{"queued": true}`), `ui.focus` activates; `file.close` errors on unsaved changes unless `force`; `review.trackChanges` without `value` toggles | docs/control-protocol.md:78–98; `crates/engine/src/cmd/review.rs` (`trackChanges`) | implemented (documented behaviour) | Carried forward because re-verified in docs and dispatch code |
| 17 | **27 interface languages** (was 21); gaps.md:65 row still says 21 — stale | `crates/ui-egui/src/i18n/mod.rs:55` (`LANGUAGES: [LangInfo; 27]`) | implemented | Slovenian catalog is the newest (ROADMAP.md:5) |
| 18 | Proofing **11 variants**: En, En-Gb, En-Ca, Pl, Pt, It, Hr, Tr, Ru, Cs, Id; dictionaries not bundled; Bulgarian/German hyphenation only | `crates/proof/src/lang.rs:65–77`; docs/spelling-dictionaries.md; docs/gaps.md:63 | implemented (partial vs Word's ~120 proofing tools) | Was 9 at v0.9; `PROOFED` now also lists Cs and Id |
| 19 | 60 modal dialogs vs Word's ~100 | docs/gaps.md:61,139; `crates/ui-egui/src/dialogs.rs:145` | partial | Was 59 |
| 20 | Blocking gaps #1–#7: DOCX real-world corpus, ink/OLE rendering, crashes/freezes, pagination, content-controls/moves, print depth, dialog depth | docs/gaps.md:55–61,88 | claimed (README/ROADMAP self-assessment) + implemented shortfalls | Gap #1 contradicted by a 251-document corpus note (docs/layout-parity.md:283, docs/file-format-parity.md:311) — flagged as uncertain |
| 21 | `.doc` read-only, Word 6/95 refused; no PDF Reflow, MHT, Works/WordPerfect; no VBA/add-ins/cloud/co-authoring; no in-app AI | `crates/docbin/src/lib.rs:1–8`; docs/gaps.md:68,79,80,82,84 | implemented (read) / not implemented (rest) | — |
| 22 | One document per window, no tabs; View Side by Side/Arrange All missing | `crates/ui-egui/src/lib.rs:524–525` (single `Session`); docs/gaps.md:83 | implemented (single document) / not implemented (window commands) | — |
| 23 | WebAssembly build CI-checked, no TCP control channel, browser Open/Save; `?sample`/`?webgl` | apps/wordcraft-web/src/main.rs:1–8; xtask `wasm` step | implemented (not exercised by this agent) | — |
| 24 | Recovery desktop-only, no plaintext copies for protected files, none headless/CLI/web; explicit documents keep the editor when discovery finishes | docs/recovery.md:1–31; docs/gaps.md:5 | implemented (documented limits) | — |
| 25 | Desktop automation unconfined; headless MCP confinement flags are an error with `--connect` | docs/mcp.md:87 | implemented (headless only) | — |
| 26 | Save path: exclusive temp sibling, sync, replace; failed save keeps original | docs/file-format-parity.md:180–183 ("Native save-path guarantees"); `crates/engine/tests/safe_save.rs` | implemented | Field reliability still under gap #3 (docs/gaps.md:14) |
| 27 | Default shortcuts 140 (macOS) / 158 (Linux/Windows) of ~250; mail-merge sources limited to CSV/TSV/TXT/xlsx/xlsm/xls/ods | docs/gaps.md:78,81; `crates/formats/src/sheet.rs` | implemented (partial) | Carried forward, re-verified in the gaps table |
| 28 | Headless UI screenshots via `ui_shot` example (JSONL: requests, `{"shot"}`, `{"steps"}`, `{"wait"}`, `{"empty"}`) | `crates/ui-egui/examples/ui_shot.rs:1–13` | implemented | — |

## Repository contradictions found (and how the skill handles them)

| Contradiction | Where | Handling in SKILL.md |
|---|---|---|
| Command count 422 / 433 / "over 270" vs 638 in source | README.md:105,200; ROADMAP.md:28; docs/mcp.md:106 | Counts quoted from source; docs called stale |
| Catalog 493/508 vs generated 498/513 | ROADMAP.md:21 vs docs/parity-checklist.md:5 | Uses the generated checklist |
| Gap #1 says no real-world DOCX corpus; revision logs cite a 251-document corpus | docs/gaps.md:55 vs docs/layout-parity.md:283, docs/file-format-parity.md:311 | Stated as uncertain, not resolved |
| Radar charts "drawn (#1890)" vs still listed among undrawn types | docs/gaps.md:67 vs docs/file-format-parity.md:109 | Code wins (`crates/docx/src/read/chart.rs`); stale row flagged |
| Interface languages 27 in code vs 21 in the gaps row | `crates/ui-egui/src/i18n/mod.rs:55` vs docs/gaps.md:65 | 27 stated; stale row flagged |
| TIFF accepted by code vs "not yet: SVG, TIFF" | `crates/engine/src/cmd/insert.rs:230–241` vs docs/file-format-parity.md:59 | Code wins; stale row flagged |
| Duplicated gaps rows (#19/#20/#21 twice, different text) | docs/gaps.md:72–78 | Cites the later, updated row |

## Notes for the orchestrator

- Spot-check first: row 2 (recount `CommandSpec::new(` in `crates/engine/src/cmd/*.rs`), row 9–10
  (template semantics and the `.dotx` append), row 12 (radar vs the stale parity row), row 17–18
  (language/proofing counts).
- No claim comes from running the app: nothing was launched, built or modified. The installed
  bundle was version-checked only (`Info.plist`, `--version` output recorded from the binary).
- The previous skill's 16 MCP tools, 10 CLI subcommands and control-channel shape were re-checked
  and are unchanged at this tag; only the counts in the table moved.

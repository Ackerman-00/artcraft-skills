# evidence.md — DesignCraft SKILL.md claim audit

App: **DesignCraft** (`storytold/designcraft`) · Tag **v0.9.0** · HEAD `7cb8b12507def48fb9346e5004340b5e8e4cfcb7` · inspected 2026-10-18.
Installed bundle `/Applications/DesignCraft.app` reports `CFBundleShortVersionString 0.9.0` and
`DesignCraftBuildCommit 7cb8b12507def48fb9346e5004340b5e8e4cfcb7` — **identical to the repository HEAD**
so no HEAD/installed divergence exists at this tag. The bundle was inspected (Info.plist only), never launched.
`designcraft-cli` is **not** installed on this machine (`which designcraft-cli` → not found).

Status legend: **implemented** = code path exists and is wired into the UI/CLI/control surfaces;
**partial** = code exists but visibly incomplete (what is missing is named); **claimed** = stated in docs/README but not confirmed in code.

| # | Claim in SKILL.md | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Clean-room reimplementation of Adobe InDesign in pure Rust; MIT OR Apache-2.0 | `README.md` (`<h1>DesignCraft` + "clean-room reimplementation of Adobe InDesign, rebuilt in pure Rust"), `Cargo.toml` (`license = "MIT OR Apache-2.0"`, `rust-version = "1.95"`), `LICENSE-MIT`, `LICENSE-APACHE` | implemented |
| 2 | Runs on macOS/Windows/Linux and in the browser as WebAssembly | `apps/designcraft-web/Cargo.toml` (eframe `wgpu` + wasm deps), `README.md` §Web (`trunk build --release`, WebGPU with WebGL2 fallback, `?webgl`, `?sample`, "The web build has no control channel") | implemented |
| 3 | Stage is pre-alpha; the alpha gate is blocked by Primary Text Frame autoflow (#165) | `ROADMAP.md:3` ("Stage: pre-alpha"), `docs/gaps.md` §0 ("**ALPHA BLOCKER**"), `docs/target-app-parity.md` headline table ("Stage: pre-alpha (fails the core-workflow gate…)") | implemented (project state) |
| 4 | Every user-visible action is a command with JSON params, reachable from UI, CLI, control channel and MCP | `crates/engine/src/lib.rs:5` (module doc), `crates/engine/src/cmd/mod.rs:166` (`command_specs()` gathering 60 module `specs()` lists), `crates/ui-egui/src/control.rs:169` (`engine.execute`, `engine.commands`, …) | implemented |
| 5 | ≈483 engine command specs + 139 UI commands at this tag | grep of `cmd!` registrations outside `#[cfg(test)]` = **483** across 60 files in `crates/engine/src/cmd/`; `crates/ui-egui/src/menus.rs:18` `UI_COMMANDS` = **139** entries. `docs/target-app-parity.md` measured 446 + 99 at 2026-10-10 — the doc figure is older, the skill says counts are approximate | implemented (count approximate, both numbers given) |
| 6 | Native `.designcraft` = zip with `mimetype` (stored, first), `document.json`, `assets/<id>.<ext>`, `meta.json`, optional `preview.png`; MIME `application/vnd.designcraft+zip`; latest version 3; legacy single-JSON with base64 `assetData` still opens | `crates/format/src/lib.rs:1-30` (`MIME`, `VERSION = 3`), `save_with_preview` (:62), `load` (:156), `load_legacy_json` (:290), `upgrade` (:244), read limits (:163-170) | implemented |
| 7 | Saves append `.designcraft` when the extension is missing; writes are atomic | `crates/engine/src/cmd/file.rs:167` (`with_document_extension`), `:562-570` (`file_save` → `designcraft_engine::atomic::write_atomic`), `apps/designcraft/src/main.rs:316` (desktop `write` service) | implemented |
| 8 | IDML import **and** export | `crates/idml/src/import.rs`, `crates/idml/src/export.rs`, `crates/engine/src/cmd/interchange.rs` (`file.exportIdml`, `file.openIdml`) | implemented |
| 9 | `.indd`/`.indt` open by converting to IDML in memory (indd-utils); INDB/INDL are not read; fidelity unmeasured on real files | `crates/engine/src/cmd/interchange.rs` (`is_indd`, `open_idml`), `Cargo.toml:74` (`indd = { git = "…/indd-utils", branch = "main" }`), `docs/gaps.md` §2 ("Its conversion warnings join `warnings`" / "tests use synthetic bytes only. INDB and INDL are still not read") | partial |
| 10 | PDF export: real selectable text, DeviceCMYK/RGB, spot Separations, marks/bleed, pages or spreads, PDF/X-4 output intent with built-in checks, PDF/A-2b, tagged PDF, flattener | `crates/pdf/src/export.rs` (`tagged` structure tree at :212-226, :730-754), `crates/pdf/src/pdfx.rs:201` (`check_pdfx4`), `crates/engine/src/cmd/export.rs:12` (`file.exportPdf` param doc: `standard: "none"\|"x4"\|"a2b"`, `marks`, `flatten`, `tagged`, `media`), `apps/designcraft-cli/src/main.rs:155` (`validate-pdf`) | implemented |
| 11 | EPUB 3 reflowable **and** fixed layout | `crates/epub/src/lib.rs`; `crates/engine/src/cmd/export.rs:15-22` (`file.exportEpub`, `file.exportFixedEpub`); `docs/gaps.md` §17 ("fixed-layout EPUB writes page images, not live text and CSS") | partial (fixed layout = page images + text) |
| 12 | PowerPoint export as editable slides | `crates/pptx/src/{lib,slide,table,text,fonts}.rs`; `crates/engine/src/cmd/export.rs:29` (`file.exportPptx`, `lineBreaks`, `rasterize`, `embedFonts`) | implemented |
| 13 | PNG/JPEG page rendering from CLI/MCP/control | `crates/render/src/lib.rs:414` (`render_page`), `apps/designcraft-cli/src/main.rs:386` (`export()` → `to_png`/`to_jpeg`), `docs/control-protocol.md` (`ui.render`), `docs/mcp.md` (`render_page`, `export_png`) | implemented |
| 14 | CLI subcommands `run`, `commands`, `describe`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`; `--export` routes on extension and refuses unknown ones | `apps/designcraft-cli/src/main.rs` (`USAGE` :42, dispatch :99-142, `Export::of` :264, `run` :283, `script` :428, `mcp` :167) | implemented |
| 15 | MCP server over stdio with the listed tools, plus read/write root confinement | `crates/mcp/src/tools.rs` (tool names at :89-421, dispatch :558+), `apps/designcraft-cli/src/automation_args.rs` (`--automation-read-root`/`--automation-write-root`), `docs/mcp.md` §Confining file access | implemented |
| 16 | Control channel: loopback-only JSON lines, `engine.execute` + `ui.*` methods, 4 MiB line cap, 16 connections, no auth; bound click/drag budgets | `apps/designcraft/src/control_server.rs` (`MAX_LINE`, `MAX_CONNECTIONS`, request-only reading), `crates/ui-egui/src/control.rs:169+`, `docs/control-protocol.md` §§Click and drag limits | implemented |
| 17 | Script language with `$N.path`/`$last`/`${…}` references, one command per line, run as one undo step | `crates/engine/src/script.rs`, `crates/engine/src/cmd/scripts.rs` (`script.run {text}`), `docs/agents.md` | implemented |
| 18 | Place/open: PNG, JPEG, GIF, WebP, TIFF, BMP, PSD composite, SVG, PDF page + crop box, AI (PDF-compatible), EPS **preview only** | `crates/engine/src/cmd/file.rs:134-141` (`file.place` param doc; `pdfPage`, `pdfCrop`), `crates/images/src/lib.rs`, `crates/images/src/eps.rs`, `docs/gaps.md` §19 ("EPS is shown through its preview only (no PostScript interpreter)") | implemented, EPS partial |
| 19 | Text import `.txt`, `.docx`, `.rtf`, `.md`, `.xlsx`, Tagged Text; CSV/TSV/TXT/XLSX for Data Merge | `crates/textimport/src/{docx,rtf,xlsx,tagged,export}.rs`, `crates/engine/src/cmd/place_text.rs`, `crates/engine/src/cmd/datamerge/`, `docs/agents.md` §Data merge | implemented |
| 20 | Crash recovery (timer + recovery folder, reopen unsaved) and a last-resort panic guard that turns an escaped panic into an error without losing the document | `crates/engine/src/recovery.rs` (module doc: `<uid>.designcraft` + `<uid>.json`, per-run lock folders), `crates/engine/src/guard.rs` (module doc + `Session::guarded`), `apps/designcraft/src/main.rs:120` (`preserve_documents_on_exit`) | implemented |
| 21 | No ExtendScript/UXP compatibility — the script language is DesignCraft's own; no plug-in model | `docs/gaps.md` §22 ("not compatible"), §23 ("any plug-in model" missing); `crates/engine/src/cmd/scripts.rs` (command-language scripts only) | not implemented (by design) |
| 22 | No PDF/X-1a, PDF/X-3, PDF/UA validation, Adobe `.joboptions` presets, PostScript printing | `docs/gaps.md` §9, §10; `crates/engine/src/cmd/export.rs:12` lists only `standard: "none"\|"x4"\|"a2b"` | not implemented |
| 23 | Hyphenation limited (English, Spanish, Portuguese, Norwegian, Greek), spelling English-only | `docs/gaps.md` §13, `ROADMAP.md` (Spanish `hyph-es.tex` via `hypher`) | partial |
| 24 | On macOS the CLI is a **separate** release asset, not inside the `.app`; the installed bundle holds only the desktop binary | `docs/mcp.md` §From an installed release (macOS row), `packaging/macos/package.sh` (writes `designcraft-cli-<version>-macos-<arch>.zip`), local check `which designcraft-cli` → not found, `ls /Applications/DesignCraft.app/Contents/MacOS/` → `DesignCraft` only | implemented (packaging fact, verified locally) |
| 25 | Installed app = repo HEAD (so the skill describes the shipped build) | `/Applications/DesignCraft.app/Contents/Info.plist` → `DesignCraftBuildCommit 7cb8b12507def48fb9346e5004340b5e8e4cfcb7`, `CFBundleShortVersionString 0.9.0`; `git rev-parse HEAD` in the repo → same SHA | implemented (verified) |

## Documentation-discrepancy notes (kept honest in SKILL.md)

| Discrepancy | Where | What the code says |
|---|---|---|
| "Not yet: tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content" | `crates/pdf/src/lib.rs` module doc | Outdated: tagged structure tree in `crates/pdf/src/export.rs:212-226`, hyperlinks in `crates/pdf/src/links.rs`, optional-content layer options in `crates/engine/src/cmd/pdflayers.rs` |
| "~200 commands, all reachable through the JSON control channel" | `ROADMAP.md` (Working today list) | Registry has ~483 `cmd!` registrations plus 139 `UI_COMMANDS` at this tag (see row 5) |
| Link to `docs/parity.md` | `ROADMAP.md:189` | The file does not exist; the checklist is `docs/parity-checklist.md` (`cargo xtask parity`, `xtask/src/parity.rs`) |
| Front-matter "verified: 0.7.1" and "DesignCraft 0.7.1" in the description | `docs/user/getting-started/install.md` | Bundle and workspace are at 0.9.0 (`Cargo.toml`, Info.plist) |
| `docs/target-app-parity.md` breadth/"ready" percentages and the 446+99 command split | `docs/target-app-parity.md` (dated 2026-10-10/16) | Self-labelled estimates with ranges; treated as estimates in SKILL.md, not as measurements of this tag |

## Uncertain / not verified (no claim made in SKILL.md)

- Exact engine-command count at HEAD: `cmd!` registrations outside `#[cfg(test)]` = 483, but a few
  registrations could sit in helper code rather than a `specs()` list — reported as "≈483", with the
  older documented figure alongside.
- Behaviour of the *installed* macOS `.app` at runtime (locking, menus, GPU): deliberately not launched per
  the brief, so all runtime claims in SKILL.md come from `docs/agents.md`, `docs/mcp.md`,
  `docs/control-protocol.md` and the source, not from observing the GUI.
- Real-file InDesign input fidelity (INDD/IDML): the repo itself states this is unmeasured
  (`docs/gaps.md` §§2, 3); SKILL.md repeats that, does not claim fidelity.
- `docs/user/` prose pages other than `install.md` were listed, not read in depth.

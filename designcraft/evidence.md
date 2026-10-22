# evidence.md — DesignCraft SKILL.md claim audit

App: **DesignCraft** (`storytold/designcraft`) · Tag **v0.11.0** · HEAD `4d62a501c18fb3cf453c6e9f19f15cbc9c558e26` · inspected 2026-10-22.
Installed bundle `DesignCraft.app` reports `CFBundleShortVersionString 0.11.0` and
`DesignCraftBuildCommit 4d62a501c18fb3cf453c6e9f19f15cbc9c558e26` — **identical to the repository
HEAD**, and `Contents/MacOS/DesignCraft --version` prints `designcraft 0.11.0`; no HEAD/installed
divergence exists at this pin. The bundle was inspected (Info.plist, `--version` only), never launched.
`designcraft-cli` is **not** installed on this machine (`which designcraft-cli` → not found).

Changes between the previous pin (v0.9.0, `7cb8b125…`) and this one, verified by tag diff:
engine commands **+`font.reload`** (Type › Reload Fonts, `crates/engine/src/cmd/fonts.rs`) and
**+`layout.parents.delete`** (`crates/engine/src/cmd/layout.rs`); nothing removed. Non-command
changes: File › Package writes package-relative link paths (#340); View › Screen Mode Bleed/Slug
became real preview modes; Greek hyphenation patterns actually compiled in; swatch tint applies to
placed greyscale/bitmap images (IDML `<Image FillColor>`); threading into a frame inside a group
(gap 27 closed); A0–A2 poster presets; `docs/mcp.md` gained a persistent-CLI-install section and
`docs/control-protocol.md` a panel-docking section.

Count corrections vs the previous skill revision: engine commands 483 → **485**; UI commands
**164** (the previously reported 139 was a line-based undercount — the same string-aware count
gives 164 at v0.9.0 too, i.e. UI_COMMANDS did not change between the tags). MCP tools remain 26.

Status legend: **implemented** = code path exists and is wired into the UI/CLI/control surfaces;
**partial** = code exists but visibly incomplete (what is missing is named); **claimed** = stated
in docs/README but not confirmed in code.

| # | Claim in SKILL.md | Evidence (repo-relative) | Status |
|---|---|---|---|
| 1 | Page-layout/publishing app in pure Rust aiming at full InDesign 2026 parity; MIT OR Apache-2.0 | `README.md:14` ("page layout and publishing… built in pure Rust" — the older "clean-room reimplementation of Adobe InDesign" phrasing is gone from README), `ROADMAP.md:12,226` ("aims at full Adobe InDesign parity"), `Cargo.toml:9` (`license = "MIT OR Apache-2.0"`, `rust-version = "1.95"`), `LICENSE-MIT`, `LICENSE-APACHE` | implemented |
| 2 | Runs on macOS/Windows/Linux and in the browser as WebAssembly | `apps/designcraft-web/` (trunk build; `apps/designcraft-web/src/main.rs`), `README.md` §Web (`?webgl`, `?sample`, "The web build has no control channel", Save/Export download) | implemented |
| 3 | Stage is pre-alpha; the alpha gate is blocked by Primary Text Frame autoflow (#165); ~80% breadth / ~47% ready | `ROADMAP.md:3`, `docs/gaps.md` §0 ("**ALPHA BLOCKER**", estimate 5–7 h), `docs/target-app-parity.md` headline table (all figures labelled estimated/measured bounds) | implemented (project state; percentages are the maintainers' estimates) |
| 4 | Every user-visible action is a command with JSON params, reachable from UI, CLI, control channel and MCP | `crates/engine/src/lib.rs:3-6` (module doc), `crates/engine/src/cmd/mod.rs:166` (`command_specs()` gathering 61 module `specs()` lists), `crates/ui-egui/src/control.rs:149` (`handle_request`) | implemented |
| 5 | 485 engine command specs + 164 UI commands at this tag | unique `cmd!` ids outside `#[cfg(test)]` extracted per tag: **483 at v0.9.0 → 485 at v0.11.0** (+`font.reload`, +`layout.parents.delete`; 0 removed) across 61 `specs()` lists; `crates/ui-egui/src/menus.rs:18` `UI_COMMANDS` = **164** entries (string-aware count; same count at v0.9.0). `docs/target-app-parity.md` "Command surface (measured)" still cites 446 + 99 from 2026-10-10 | implemented (counts recomputed from code; doc figure older) |
| 6 | Native `.designcraft` = zip with `mimetype` (stored, first), `document.json`, `assets/<id>.<ext>`, `meta.json`, optional `preview.png`; MIME `application/vnd.designcraft+zip`; VERSION 3, but the writer stays at version 2 unless EPS assets are present; legacy single-JSON with base64 `assetData` still opens; limits 100 000 entries / 256 MiB JSON / 1 GiB asset / 4 GiB total; non-finite geometry is `Unsaveable` | `crates/format/src/lib.rs:1-8` (layout), `:23` (MIME), `:26` (`VERSION = 3`), `:72-74` (Unsaveable), `:90` (EPS→3 else 2), `:156-160` (`load` zip/legacy), `:164-170` (limits); `load_legacy_json`, `upgrade` later in the file | implemented |
| 7 | Saves append `.designcraft` when the extension is missing; writes are atomic | `crates/engine/src/cmd/file.rs:167` (`with_document_extension`), `crates/engine/src/io.rs:113` (`crate::atomic::write_atomic`), `Cargo.toml:78` (`craft-atomic` from craft-libs) | implemented |
| 8 | IDML import **and** export | `crates/idml/src/import.rs`, `crates/idml/src/export.rs`, `crates/engine/src/cmd/interchange.rs:19` (`file.exportIdml`) | implemented |
| 9 | `.indd`/`.indt` open by converting to IDML in memory (indd-utils); INDB/INDL are not read; DesignCraft-side fidelity unmeasured on real files | `crates/engine/src/cmd/file.rs:465-477` (`open_path` routes via `is_indd`), `Cargo.toml:73` (`indd = { git = "…/indd-utils", branch = "main" }`), `docs/gaps.md` §2 (indd-utils reports 96.9% of IDML values on ~650 pairs, but "what DesignCraft draws from those files is unmeasured"; "INDB and INDL are still not read") | partial |
| 10 | PDF export: real selectable text, DeviceCMYK/RGB/Gray, spot Separations, marks/bleed, pages or spreads, `standard: "none"|"x4"|"a2b"` with built-in PDF/X-4 checks, PDF/A-2b, tagged PDF, flattener, interactive options, booklet imposition | `crates/pdf/src/lib.rs:10-27` (feature list incl. `/Separation`, marks, standards), `crates/pdf/src/pdfx.rs:210` (`check_pdfx4`), `crates/engine/src/cmd/export.rs:11-13` (`file.exportPdf` params incl. `compressImages`, `tagged`, `media`), `crates/engine/src/cmd/export.rs:22-26` (`file.printBooklet`) | implemented |
| 11 | EPUB 3 reflowable **and** fixed layout (fixed = page images + text, not live CSS) | `crates/epub/src/lib.rs`; `crates/engine/src/cmd/export.rs:15-21` (`file.exportEpub` with `fixedLayout`, `file.exportFixedEpub`); `docs/gaps.md` §17 | partial (fixed layout = page images + text) |
| 12 | PowerPoint export as editable slides | `crates/pptx/src/`; `crates/engine/src/cmd/export.rs:29-31` (`file.exportPptx`, `lineBreaks`, `rasterize`, `embedFonts`) | implemented |
| 13 | PNG/JPEG page rendering from CLI/MCP/control | `crates/render/src/lib.rs:414` (`render_page`), `apps/designcraft-cli/src/main.rs` (`run` → export by extension), `docs/control-protocol.md` (`ui.render`), `docs/mcp.md` (`render_page`, `export_png`) | implemented |
| 14 | CLI subcommands `run`, `commands`, `describe`, `script`, `app`, `mcp`, `perf`, `bench`, `validate-pdf`, `links`, `--version`; `--export` routes on extension and refuses unknown ones | `apps/designcraft-cli/src/main.rs:3-20` (module doc), `:42` (`USAGE`), dispatch in `main()` (verified this session) | implemented |
| 15 | MCP server over stdio with 26 tools, plus read/write root confinement | `crates/mcp/src/tools.rs:83` (`tool_definitions`, 26 tools enumerated), dispatch :555; `crates/engine/src/file_access.rs`; `apps/designcraft-cli/src/automation_args.rs`; `docs/mcp.md` §Confining file access | implemented |
| 16 | Control channel: loopback-only JSON lines, `engine.execute` + `ui.*`/`app.*` methods, 4 MiB line cap, 16 connections, no auth; bounded click/drag gestures; panel docking via `window.panel.*` UI commands | `apps/designcraft/src/control_server.rs:22,24`, `crates/ui-egui/src/control.rs:149+`, `docs/control-protocol.md` §§tables, Click and drag limits, Shared panel docking | implemented |
| 17 | Script language with `$N.path`/`$last`/`${…}`/`$$` references, one command per line; `script.run` restores state on failure | `crates/engine/src/script.rs`, `crates/engine/src/cmd/scripts.rs:1-35` (rollback comment + `run_script`), `apps/designcraft-cli/src/main.rs:45-75` (`SCRIPT_HELP`), `docs/agents.md` | implemented |
| 18 | Place/open: PNG, JPEG, GIF, WebP, TIFF, BMP, PSD composite, SVG, PDF page + crop box, AI (PDF-compatible), EPS **preview only**; media mp4/m4v/mov/webm/ogv/mp3/m4a/wav/ogg/oga/aac as poster frames (no playback) | `crates/engine/src/cmd/file.rs:134-140` (`file.place` params; `pdfPage`, `pdfCrop`), `crates/images/src/lib.rs` (`mime`, `is_pdf/is_psd/is_svg`), `crates/images/src/eps.rs`, `crates/doc/src/item.rs:839-850` (`media_mime`), `docs/gaps.md` §19 | implemented; EPS partial |
| 19 | Text import `.txt`/`.text`, `.docx`, `.rtf`, `.md`, `.xlsx`, Tagged Text; CSV/TSV/TXT/XLSX for Data Merge; `data.merge` creates a new document | `crates/textimport/src/lib.rs:94-96` (`is_text_file`), `crates/textimport/src/{docx,rtf,xlsx,tagged}.rs`, `crates/engine/src/cmd/datamerge/`, `docs/agents.md` §Data merge | implemented |
| 20 | New at this pin: `font.reload` and `layout.parents.delete`; Package writes package-relative links; Bleed/Slug screen modes preview; Colour Theme tool; QR codes; math expressions; ICC colour management (craft-cms, Coated FOGRA39 built-in CMYK) | `crates/engine/src/cmd/fonts.rs:30`, `crates/engine/src/cmd/layout.rs` (`layout.parents.delete`), ROADMAP progress log 2026-10-16/17/18, `crates/engine/src/cmd/qr.rs:16` (`object.qrCode`), `crates/engine/src/cmd/mathexpr.rs:40`, `crates/engine/src/cmd/color_theme.rs:11-15`, `crates/engine/src/cmd/colorsettings.rs:36-44`, `Cargo.toml:83` (`craft-cms`), craft-libs `crates/cms/src/synth.rs:26-27` (Coated FOGRA39 built-in) | implemented |
| 21 | Crash recovery (timer, recovery folder, reopen unsaved) and a panic guard | `crates/engine/src/recovery.rs`, `crates/engine/src/guard.rs`, ROADMAP "Crash recovery… every 30 s" | implemented |
| 22 | No ExtendScript/UXP compatibility — the script language is DesignCraft's own; no plug-in model | `docs/gaps.md` §22 ("not compatible"), §23 ("any plug-in model"); `crates/engine/src/cmd/scripts.rs` (command-language scripts only) | not implemented (by design) |
| 23 | No PDF/X-1a, PDF/X-3, PDF/UA validation, Adobe `.joboptions` presets, PostScript printing | `docs/gaps.md` §9, §10; `crates/engine/src/cmd/export.rs:12` lists only `standard: "none"|"x4"|"a2b"` | not implemented |
| 24 | Hyphenation limited to English, Spanish, Portuguese, Norwegian, Greek; spelling English-only | `docs/gaps.md` §13; ROADMAP progress log 2026-10-16 (Greek patterns were "never compiled in" before, now are) | partial |
| 25 | On macOS the CLI is a **separate** release asset, not inside the `.app` | `docs/mcp.md` §From an installed release (macOS row), `packaging/macos/package.sh:5` (`designcraft-cli-<version>-macos-<arch>.zip`), local check `which designcraft-cli` → not found, `ls <bundle>/Contents/MacOS/` → `DesignCraft` only | implemented (packaging fact, verified locally) |
| 26 | Installed app = repo HEAD (so the skill describes the shipped build) | `Contents/Info.plist` → `DesignCraftBuildCommit 4d62a501c18fb3cf453c6e9f19f15cbc9c558e26`, `CFBundleShortVersionString 0.11.0`; `Contents/MacOS/DesignCraft --version` → `designcraft 0.11.0`; `git rev-parse HEAD` in the worktree → same SHA | implemented (verified) |

## Documentation-discrepancy notes (kept honest in SKILL.md)

| Discrepancy | Where | What the code says |
|---|---|---|
| "Not yet: tagged PDF, bookmarks, hyperlinks, overprint, layers as optional content" | `crates/pdf/src/lib.rs:28` (still present at this tag) | Outdated: tagged structure tree and standards in `crates/pdf/src/export.rs`, hyperlinks in `crates/pdf/src/links.rs`, forms in `crates/pdf/src/forms.rs`, page transitions in `crates/pdf/src/transitions.rs`, optional-content layer options in `crates/engine/src/cmd/pdflayers.rs` |
| "~200 commands, all reachable through the JSON control channel" | `ROADMAP.md:180` | Registry has 485 `cmd!` registrations plus 164 `UI_COMMANDS` at this tag (see row 5) |
| Link to `docs/parity.md` | `ROADMAP.md` (old revision-history entry at :599) | Fixed at this tag for the live text (`ROADMAP.md:189` now points at `docs/parity-checklist.md`, which exists); only the dated history line still names the old path |
| Front-matter "verified: 0.7.1" and "0.7.1" examples | `docs/user/getting-started/install.md` | Bundle and workspace are at 0.11.0 (`Cargo.toml:7`, Info.plist) |
| Localization "German and Japanese complete" (previous skill revision) | `ROADMAP.md` §Languages at this tag | Table now scores Japanese 95% ("partial") and German 83%; Czech/Polish 99%, Georgian 100%; SKILL.md uses the current table |
| `docs/target-app-parity.md` percentages and the 446+99 command split | `docs/target-app-parity.md` (dated 2026-10-10/16) | Self-labelled estimates/ranges with an older command measurement; treated as estimates in SKILL.md, not as measurements of this tag |

## Uncertain / not verified (no claim made in SKILL.md)

- Exact engine-command count at HEAD: unique ids outside `#[cfg(test)]` = 485 by automated
  extraction; a registration could in principle be missed by the extraction or duplicated by a
  helper, so SKILL.md also says to discover the live list with `designcraft-cli commands`.
- UI_COMMANDS: two counting methods gave 164 and 165 (one multi-line entry counted differently);
  SKILL.md says 164, flagged as approximate alongside the doc's older 99.
- Behaviour of the *installed* macOS `.app` at runtime (locking, menus, GPU): deliberately not
  launched per the brief, so all runtime claims in SKILL.md come from `docs/agents.md`,
  `docs/mcp.md`, `docs/control-protocol.md` and the source, plus the bundle's `--version`.
- Real-file InDesign input fidelity (INDD/IDML): the repo itself states this is unmeasured
  (`docs/gaps.md` §§2, 3); SKILL.md repeats that, does not claim fidelity.
- `docs/user/` prose pages other than `install.md` were listed, not read in depth.
- `ui.set` key list: the control-protocol table names a subset (brightness…fit) while prose
  mentions `closePanel`/`dockExpanded` and the previous revision's list also had `status`,
  `controlBar`; the table in `references/agent-surfaces.md` reproduces the doc's union —
  uncertain at key level; check `ui.inspect`/the method handler for the authoritative set.

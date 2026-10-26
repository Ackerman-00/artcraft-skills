# evidence.md — VectorCraft skill claim map (for orchestrator review)

Repo: `storytold/vectorcraft` · tag **v0.17.0** · commit `43313f9451de7ab5b909801006b8881458f2bf04`
("Release 0.17.0", 2026-10-25) · inspected **2026-10-26** · installed `/Applications/VectorCraft.app`
reports `0.17.0` (`CFBundleIdentifier ai.storyteller.vectorcraft`) and its desktop binary prints
`vectorcraft 0.17.0`. Shallow clone (`git rev-parse HEAD` = the SHA above, single commit, tag `v0.17.0`),
so `v0.15.0..v0.17.0` could not be diffed with git; the delta below was located from the docs' dated
revision rows (2026-10-23/24, after the v0.15.0 release of 2026-10-22) and then re-verified in code.

Tiers: **implemented** (code path exists and is wired into UI/CLI) · **partial** (code exists but visibly
incomplete — the missing part is named) · **not implemented** (repo-admitted absent) · **claimed**
(self-report, not measured).

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Clean-room pure-Rust Illustrator reimplementation; macOS/Windows/Linux/FreeBSD + WASM web; alpha at ~88% breadth (353/375 menu items, 89/92 tools, 44/50 vector effects, 57/57 Photoshop effects, 4/4 3D) | `README.md` L21-24, L232-255; `apps/vectorcraft-web/`; `docs/target-app-parity.md` (Last updated 2026-10-24, headline table) | implemented; parity numbers claimed/self-assessed |
| 2 | Native `.vectorcraft`/`.drawcraft`, JSON `VERSION = 4`, down-save to v1/v2, gzip, PNG preview, atomic saves, unknown newer keys preserved | `crates/format/src/lib.rs` L53-66; `crates/format/src/atomic.rs`; `docs/mcp.md` › Native files | implemented |
| 3 | **805 engine command specs** = 789 `cmd!` sites + 16 table-built character/paragraph style specs | `crates/engine/src/cmd/` (94 files, 789 non-test `cmd!(` calls, 0 inside `#[cfg(test)]`); `crates/engine/src/cmd/textstyles.rs` L49-111 (`spec()`, `style_cmds!` = 8 specs × 2 kinds); `crates/engine/src/cmd/mod.rs` L196 (`cmd!`), L204 (`command_specs()`) | implemented (runtime count from `engine.commands`) |
| 4 | **343 UI commands**, all ids unique | `crates/ui-egui/src/menus.rs` L54 `UI_COMMANDS` (165 multi-line + 178 single-line entries; parsed and de-duplicated) | implemented |
| 5 | **32 MCP tools** (27 distinct handlers + 5 alias names: `run_command`, `inspect_document`, `inspect_ui`, `list_commands`, `ui_screenshot`), 5 prompts, 3 fixed resources + 4 URI templates, caps 16 MiB/64/256/8 MiB/256 MiB, protocol 2025-06-18 (+2026-07-28 hints) | `crates/mcp/src/tools.rs` L115-513 (`tool_definitions`), L1218-1219 (`MAX_COMMAND_BATCH_STEPS = 256`, `MAX_COMMAND_BATCH_BYTES = 8 MiB`); `crates/mcp/src/server.rs` L21-23, L42-47 (`MAX_LINE_BYTES = 16 MiB`, `MAX_BATCH_MESSAGES = 64`, `DEFAULT_BUSY_AFTER = 2 s`); `crates/mcp/src/backend.rs` L31 (`MAX_REPLY_BYTES = 256 MiB`); `crates/mcp/src/prompts.rs`, `crates/mcp/src/resources.rs` | implemented (stdio only) |
| 6 | **28 control methods** (29 accepted strings with the `command` alias); loopback only, no auth; 4 MiB line, 16 connections, 60 s reply, 300 s idle | `crates/ui-egui/src/control.rs` L205-475 (match arms); `apps/vectorcraft/src/control_server.rs` L26-56 (`MAX_LINE = 4 MiB`, `MAX_CONNECTIONS = 16`, `REPLY_WAIT = 60 s`, idle 300 s); `docs/control-protocol.md` L92-109 | implemented |
| 7 | **7 CLI subcommands** with the exact flags listed; `run --commands FILE\|-` (64 MiB / 100,000 steps, `$N.path`); `convert` refuses lossy overwrite without `--replace-lossy`, reports `importWarnings` | `apps/vectorcraft-cli/src/main.rs` L67-170 (USAGE + dispatch), L182-236 (`mcp`), L245-305 (`convert`), L344-522 (`run`, caps), L524-568 (`bench`); `apps/vectorcraft-cli/src/perf.rs` L343-352 (`perf`) | implemented |
| 8 | Open: **31 `OPEN_EXTS`**, Place adds `.txt/.rtf/.docx` (**34**); writable **20 formats → 19 export extensions** + `plugin.<id>`; catalogue **24 formats** (22 readable); `SAVE_FORMATS` **6**, `TEMPLATE_FORMATS` 2 | `crates/engine/src/cmd/fileio/mod.rs` L674-705 (`OPEN_EXTS`), L731-737 (`TEXT/RTF/DOCX`), L525+ (`FORMATS`: 21 entries + 3 `reader()` = 24), `export_extensions()`; `crates/engine/src/cmd/fileio/save.rs` L24, L28 | implemented |
| 9 | **57 Photoshop-style filters** = 56 `PIXEL_EFFECTS` + `blur.gaussian`; Effect Gallery with 6 raster categories, stack, preview, one undo step | `crates/effects/src/pixel/mod.rs` L47 (`PIXEL_EFFECTS: [&str; 56]`); `crates/effects/src/lib.rs` L361 (`blur.gaussian`); `crates/ui-egui/src/dialogs/effect_gallery.rs` L17 (`CATEGORIES`, 6) | implemented; gallery deliberately excludes Blur/Pixelate/Sharpen/Video groups |
| 10 | Effect catalogue **116** entries; Pathfinder 12 + **Trap** = 13; **Apply SVG Filter** still a stub | `crates/effects/src/lib.rs` L220-872 (`effect_catalog`: 86 literal + 15 `WARP_STYLES` + 12 `PATHFINDER_EFFECTS` + Trap + Crop Marks + Rasterize); `crates/effects/src/group.rs` L24-37; `crates/effects/src/trap.rs` L44; `crates/ui-egui/src/menus.rs` L4147 (`todo("Apply SVG Filter…")`) | implemented except Apply SVG Filter |
| 11 | 3D Revolve / Extrude & Bevel / Inflate / Rotate, 1–10 coloured lights, 4 lighting presets; **no materials** (`Materials…` placeholder) | `crates/three-d/src/lights.rs` L4 (`MAX_LIGHTS = 10`); `crates/engine/src/cmd/effectcmd.rs` L59 (`effect.lightingPreset`); `crates/ui-egui/src/menus.rs` L4146, L4160 (`todo("Materials…")`); `docs/three-d.md` | partial (~25% depth; painter's algorithm) |
| 12 | **92 tool ids**; 42 panel modules; 25 interface languages (24 `.tsv` + English); 12-key score ~82% | `crates/tools/src/catalog.rs` (92 `t(...)` ids); `crates/ui-egui/src/panels/mod.rs` (42 `pub mod`); `crates/ui-egui/src/i18n/` (24 `.tsv` catalogues); `docs/localization-parity.md` L42 | implemented (89/92 wired per parity doc; only Georgian native-reviewed) |
| 13 | Type: threading with ports, Ruby kept through outlines/EPS/EMF/legacy `.ai`, **COLR v0/v1** and **OpenType SVG** colour fonts as vector art, bitmap emoji in effects/Expand | `crates/text/src/colr.rs`, `crates/text/src/svg_glyph.rs`, `crates/text/src/bitmap.rs`; `crates/engine/src/cmd/typecmd.rs`; `docs/type-parity.md` rows 2026-10-23/24 | implemented; CPAL palette variables, CJK vertical composition, spell check still open |
| 14 | **New**: Pathfinder Trap, Global Edit, symbol libraries (13 ids), artboard Show Center Mark / Cross Hairs / Video Safe Areas / video PAR, Distance Guides, part-path Simplify, macOS pen pressure, PDF tiling patterns, SVG foreign namespaces, PDF import glyph-width spacing | `crates/effects/src/trap.rs`; `crates/engine/src/cmd/globaledit.rs` L56-71; `crates/ui-egui/src/menus.rs` L777-797; `crates/engine/src/cmd/layer.rs` L128, L146, L839-841; `crates/engine/src/cmd/prefscmds.rs` L237; `crates/engine/src/cmd/pathops.rs` L837; `apps/vectorcraft/src/mac_tablet.rs`; `crates/pdf/src/export.rs` L624-637; `crates/svg/src/export.rs` L668; `docs/file-format-parity.md` 2026-10-23/24 | implemented (macOS pen pressure untried on hardware per G14) |
| 15 | Formats: SVG strongest; PDF/`.ai` own reader + editing data; EPS/PS PostScript interpreter; Affinity read-only (51 pinned, 33 current `.af`); PSD/PSB merged image only; DXF/EMF/WMF | `crates/eps/`; `crates/cad/`; `crates/metafile/`; `crates/affinity/README.md`; `docs/affinity-validation.md`; `docs/file-format-parity.md` | implemented (with the stated per-format losses; no Affinity write) |
| 16 | Automation extras: plug-ins (WASM ABI v1, 256 params), Actions + `action.batch`, `dataset.import` CSV/TSV, `script.check` (never runs scripts), `SOURCE_DATE_EPOCH` reproducibility, no-panic `guard` | `crates/plugins/src/manifest.rs` L13 (`MAX_PARAMS = 256`); `docs/plugins.md`; `crates/engine/src/cmd/variablecmds.rs` L780; `crates/doc/src/variables.rs` L14-23; `crates/engine/src/cmd/scripts.rs` L17 (`EXTS`); `crates/scriptcheck/src/`; `crates/doc/src/metadata.rs` L88-108; `crates/engine/src/guard.rs` | implemented (reference-app scripts still cannot run) |
| 17 | Browser API: 9 promise calls on `window.vectorcraft` | `apps/vectorcraft-web/src/api.rs::install` (request, execute, commands, inspect, screenshot, openFile, captureDownloads, files, readFile) | implemented (web build) |
| 18 | Limits: no script engine, no materials, no Affinity write, MCP stdio-only and no `resources/subscribe`/`sampling`, control port unauthenticated, artboard background colour not exported, accessibility limited | `README.md` "What's missing"; `docs/mcp.md` L326-338; `docs/control-protocol.md`; `crates/engine/src/cmd/layer.rs` L146; `docs/gaps.md` G3/G6/G18/G19 | not implemented (repo-admitted) |

## Count deltas vs the v0.15.0 skill (all re-measured here)

| Count | v0.15.0 skill said | v0.17.0 measured | Basis |
|---|---|---|---|
| Engine `cmd!` specs | 780 | **789** (+9) | non-test `cmd!(` grep |
| Table-built specs | "plus table-built" (uncounted) | **16** (`textstyles.rs`) | 8 `spec()` × 2 kinds |
| Engine command specs total | not stated | **805** | 789 + 16 |
| UI commands | 325 | **343** (+18) | parsed `UI_COMMANDS` entries |
| MCP tools | 32 | **32** (unchanged) | `tool_definitions()` |
| MCP prompts / resources | 5 / 3+4 | 5 / 3+4 | `prompts.rs`, `resources.rs` |
| Control methods | 28 (29 with alias) | **28** (29) | match arms in `control.rs` |
| Browser API calls | 9 | **9** | `api.rs` |
| CLI subcommands | 7 | **7** | `main.rs` dispatch |
| Open extensions | 31 (Place 34) | **31** (34) | `OPEN_EXTS`, `PLACE_EXTS` |
| Save formats | 6 | **6** | `SAVE_FORMATS` |
| Export formats / extensions | 20 / 19 | **20 / 19** | `FORMATS` write + `export_extensions()` |
| Photoshop filters | 57/57 | **57** (56 + `blur.gaussian`) | `PIXEL_EFFECTS` |
| Pathfinder live effects | 12 (Trap missing) | **12 + Trap = 13** | `PATHFINDER_EFFECTS`, `trap.rs` |
| Tools / panels / languages | 92 / 42 / 25 | **92 / 42 / 25** | `crates/tools/src/catalog.rs`, `crates/ui-egui/src/panels/mod.rs`, `crates/ui-egui/src/i18n/` |

Nothing was removed from the automation surface at this tag: every v0.15.0 surface is still present with
the same or a larger count. The +9 `cmd!` and +18 UI commands are the Trap, Global Edit, symbol-library,
artboard-option and part-Simplify additions listed in the SKILL's Capabilities section.

## Notes for the orchestrator

- **Method**: `git rev-parse HEAD` for the pin; counts derived by parsing the source (`cmd!` sites excluding
  `#[cfg(test)]` modules, `tool_definitions()` entries, `UI_COMMANDS` tuples, `#[wasm_bindgen]`-free
  `install()` closures, format arrays with a brace matcher), never copied from the previous skill or from
  README/docs. No build, no cargo test, no GUI launch; the bundle was read with `Info.plist` and
  `--version` only. `vectorcraft-cli` is **not installed** on this Mac and the `.app` bundle holds only the
  desktop binary, so CLI behaviour is documented from source, not executed.
- **Biggest corrections to the previous skill**: (1) **Pathfinder Trap exists** (`crates/effects/src/trap.rs`,
  effect `pathfinder.trap` + panel command `object.pathfinder.trap`) — the v0.15.0 skill listed it as a
  missing catalogue entry; (2) **COLR/OpenType-SVG colour fonts are implemented** (`crates/text/src/colr.rs`,
  `svg_glyph.rs`) where the previous skill said they were unsupported; (3) the previous skill's MCP tool list
  named only 28 of the 32 tools (it missed `list_commands`, `inspect_document`, `inspect_ui`,
  `ui_screenshot`) — the count 32 was right, the enumeration was incomplete; (4) `UI_COMMANDS` was 325 and
  is now 343 (re-counted, not carried); (5) macOS pen pressure is implemented (`mac_tablet.rs`) but still
  listed under G14 as untried on hardware.
- **Doc contradictions found** (code treated as authoritative, all flagged in SKILL.md): `README.md`
  "What's missing" still lists scripting + "the rest of Variables (image and graph kinds, dataset import)"
  although `dataset.import` and all four `VariableKind`s exist, and lists 3D beyond Revolve although three
  more 3D types ship (materials genuinely do not); `ROADMAP.md` prints 348/375, 46/50 and 74% where
  `docs/target-app-parity.md` says 353/375 and 44/50 and `docs/localization-parity.md` measures ~82%;
  `docs/file-format-parity.md` lists PS as missing while `FORMATS`/`OPEN_EXTS` read `.ps`;
  `docs/effects-parity.md` carries conflicting vector-effect totals (44/50, 46/50, 49/50 in the same file).
- **Uncertain items**: the live engine command count (805 is a source-level count; some specs may be built
  conditionally, so `engine.commands` is authoritative at runtime); which 3 of the 92 tools are unwired
  (the parity doc says 89/92 without naming them); the exact vector-effect percentage (44/50 vs 46/50 vs
  49/50 — the SKILL names the concrete holes instead: only Apply SVG Filter is missing); whether the
  Effect Gallery is exposed in the WASM build (the dialog is egui UI code, not checked in WASM); per-filter
  visual fidelity of the 57 approximate raster filters (docs call them approximations).

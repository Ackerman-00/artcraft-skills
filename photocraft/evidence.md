# PhotoCraft — evidence ledger (tag v0.16.0)

Audit basis: this checkout is tag **`v0.16.0`**, commit **`b1794c6e0608ccfc887213dcf58398977c5cb75e`** ("Release 0.16.0"; the
clone is shallow and holds exactly this commit, so `v0.12.0…v0.16.0` diffs were unavailable and every delta below was
re-measured here and compared against the previous skill and the repo's own revision histories). Inspection date
**2026-10-26**. Installed `/Applications/PhotoCraft.app` = 0.16.0 (`CFBundleShortVersionString`, bundle id
`ai.storyteller.photocraft`, min macOS 11.0), binary prints `photocraft 0.16.0 (b1794c6e0, 2026-10-25)`; the GUI was
never launched. No `references/` directory ships — SKILL.md carries the body, this file carries the per-claim evidence.

## 1. Capability claims → evidence → tier

Tier legend: **implemented** = code path exists and is wired into UI/CLI/automation; **partial** = code exists with a
named gap; **claimed-only** = said in docs/README but absent or contradicted by code.

| # | Claim | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | 631/631 Photoshop menu items dispatch a command | `docs/parity-checklist.md:5`; floor `FLOOR: usize = 631` at `crates/ui-egui/src/parity.rs:10` | implemented |
| 2 | 67 tools in the toolbox; Art History Brush is the only missing classic tool | `crates/ui-egui/src/state.rs:209` `pub const ALL: [Tool; 67]`; `docs/gaps.md` G6 ("Missing (1 of 68)") | implemented |
| 3 | 16 adjustment-layer kinds, each also a destructive `image.adjustments.*` command | `crates/engine/src/commands.rs:1364` `const ADJ` (16 tuples) → loop at `:1409-1450` pushes 2 specs each | implemented |
| 4 | 10 layer-effect kinds, several instances per kind | `crates/doc/src/effects.rs:277` `pub enum Effect`; commands via `crates/engine/src/layer_style.rs` `style_cmd!` (10) | implemented |
| 5 | 34 blend modes (PassThrough + 27 Photoshop + 6 Paint.NET) | `crates/color/src/blend.rs:11-51` (`PAINT_NET_MODES: [BlendMode; 6]` at `:51`) | implemented |
| 6 | 124 `filter.*` command ids = 63 registered pairwise (`filters.rs` 30 + `filters_ext.rs` 33) + 47 Filter Gallery filters + `filter.filterGallery` + 13 workspace/lifecycle ids | `crates/engine/src/filters.rs:408`, `filters_ext.rs:595`, `gallery_cmds.rs:174` (47 rows in `crates/algo/src/artistic.rs` `gallery!`; its doc comment also says "47 artistic filters"), `crates/engine/src/distort_cmds.rs:30` (`LIQUIFY`), `lens_cmds.rs:25-26` (`WIDE`, `RAW`), `vp_cmds.rs:15` (`VP = "filter.vanishingPoint"`), plus `filter.blurGallery.*` (5), `filter.lastFilter`, `filter.convertForSmartFilters` | implemented |
| 7 | 54 PSD smart-filter classes map to 49 distinct commands both ways | `crates/io/src/smart_map.rs:141` `struct Known`, first entry `:155`; `grep -c 'Known {'` = 54, unique `command:` values = 49. `docs/file-format-parity.md` PSD row says "53 mapped" (stale by one) | implemented |
| 8 | 114 Photoshop action-event mappings; nesting to 16 levels | `crates/engine/src/atn_cmds.rs:3405` `const EVENTS` = 56 `ev!` + 14 `adjustment_event!` + 2 `clipping_event!` + 42 bare `Event {`; `crates/engine/src/actions_cmds.rs:191` "action nesting exceeds 16 levels". `docs/gaps.md`/`docs/file-format-parity.md` say 112 (2026-10-12 entry, stale) | implemented |
| 9 | 16 `actions.*` commands | ids `actions.{list,get,record,stop,play,move,delete,toggle,rename,load,save,insert,dialog,assignSet,setColor,conditional}` in `crates/engine/src/actions_cmds.rs`, `actions_edit_cmds.rs` | implemented |
| 10 | `.pcraft` = manifest `format_version` 1 + content-addressed zstd tiles/blobs, atomic save | `crates/format/src/manifest.rs:18` `pub const FORMAT_VERSION: u32 = 1`; `crates/format/src/atomic.rs`; `crates/format/src/migrate.rs` | implemented |
| 11 | 22 codec formats; read-only PCX, XPM, DICOM, IFF; AVIF write-only behind a feature; HEIF read-only behind a feature | `crates/codecs/src/format.rs:7` (`enum Format`), `:73` `ASYMMETRIC_EXCEPTIONS`, `:108` `ALL: [Format; 22]`, `:266-267` Pcx/Xpm `read: true, write: false`; `crates/codecs/README.md` matrix | implemented |
| 12 | Import-only layered readers: PDN, KRA/KRZ, XCF/XCF.GZ, Affinity, SVG; writable targets refused | `crates/io/src/lib.rs:398-455` (`import_stages`), `:514-586` (`export_stages` refusals for pdn/affinity/kra/xcf); `crates/io/src/xcf.rs`, `kra.rs`, `pdn.rs`, `affinity.rs`, `svg.rs` | implemented |
| 13 | PSD/PSB read+write with enforced corpus floors 190/256, 249/309, 148/170 (+ round-trip floors) | `crates/io/tests/it/corpus.rs:151` (mixed 148/169), `:155` (psd-tools 249/308), `:159` (photoshop 190/258); `docs/scorecard.md:10` | implemented, fidelity partial (G1) |
| 14 | Export As = 6 formats; Save for Web = 5 | `crates/engine/src/export_preset_cmds.rs:13` `const FORMATS`; `crates/engine/src/web_cmds.rs:46-50` | implemented |
| 15 | 8 CLI subcommands, 9 export flags, exit codes 0/1/2 | `apps/photocraft-cli/src/args.rs:31-40` (`enum Command`), `:44-83` (`ExportArgs`), `apps/photocraft-cli/src/lib.rs:41-66` | implemented |
| 16 | 26 MCP tools + 2 MCP resources | `crates/automation/src/server.rs:610` `#[tool_router]` → 26 `async fn` tool bodies (:612-1016); `crates/automation/src/server/conventions.rs:7-8,63-90` resources `photocraft://document`, `photocraft://commands` | implemented |
| 17 | 28 control-channel methods, auth-first, 1 MiB request / 60 s reply / 16 connections | `crates/ui-egui/src/control.rs` dispatch (unknown-method arm at `:1345`); `apps/photocraft/src/control_server.rs`; `crates/automation/src/security.rs:15-29`; `docs/control-protocol.md` "Methods" | implemented |
| 18 | Headless `serve`/`rpc` exposes 19 methods | `crates/automation/src/rpc.rs:42-61` `pub const METHODS` (19 entries), dispatch `:86-190` | implemented |
| 19 | Automation budgets: 8 MiB reply, 5 MiB PNG, 2048 preview side, 64 M pixels, 256 batch steps | `crates/automation/src/budgets.rs:13-19`; `crates/automation/src/security.rs:21` | implemented |
| 20 | Wasm plug-in ABI v1: 5 commands, no WASI, 32 MiB module, 512 MiB memory, 50 M fuel + 4 000/sample, 60 s | `crates/plugins/src/runtime.rs:14,45-47`; `crates/engine/src/plugin_cmds.rs:19,273-319`; `docs/plugins.md:41-47` | implemented |
| 21 | Automation is fail-closed for 14 filesystem commands; desktop also refuses `image.mode.*` | `crates/automation/src/workspace.rs:745` `filesystem_commands_fail_closed` (14 ids) and the `authorize_desktop_engine_command` asserts below it | implemented |
| 22 | Camera raw: DNG/CR2/NEF/ARW/PEF/RW2, uncompressed ORF/RAF; CR3 preview only | `crates/raw/src/lib.rs:34-41`; `crates/raw/src/cr3.rs:1-5` ("extracts camera JPEGs and orientation, not CRX sensor data"); `docs/file-format-parity.md` Camera raw table (CR3 "detected, unsupported") | partial |
| 23 | Print through in-process IPP, portal, spooler or PDF; `file.printers` lists queues | `crates/engine/src/print_cmds.rs:15,190,1275`; `crates/ipp`; `docs/printing.md` | implemented |
| 24 | Video-lite: 7 `timeline.*` commands + `file.export.renderVideo` | `crates/engine/src/timeline_cmds.rs:140`; `crates/engine/src/video_cmds.rs` (`file.export.renderVideo`) | implemented |
| 25 | In-app update check (once per launch, opt-out, not in Flatpak) | `crates/engine/src/updates_cmds.rs:117`; `docs/scorecard.md` DIST-220-1 partial (landed 2026-10-22, #5485) | partial (no periodic recheck) |
| 26 | No AI/generative features; no native PS plug-ins (.8BF/CEP/UXP); ABI v2 missing | `docs/scorecard.md` AUTO-219-6/7 marked "missing"; no ONNX runtime or `ml` crate in `Cargo.toml`; `crates/plugins/src/runtime.rs:14` `ABI_VERSION: i32 = 1`; `docs/gaps.md` G15/G16 | not implemented (verified absent) |
| 27 | Workspaces that are still dialogs: Select and Mask, Content-Aware Fill, Vanishing Point; Path Blur a dialog | `docs/gaps.md` G7; `crates/engine/src/smartselect_cmds.rs`; `crates/engine/src/gallery_cmds.rs` (Blur Gallery) | partial |
| 28 | Type on a path = rigid glyph placement only | `crates/engine/src/type_extra_cmds.rs` (`type.attachToPath`); `docs/gaps.md` G8 TYPE-218-1 | partial |

## 2. Automation-surface counts: previous skill (v0.12.0) → this tag (v0.16.0)

Every row was re-measured from this checkout; nothing is copied from the previous skill or from README/docs.

| Surface | Prev skill (0.12.0) | v0.16.0 (measured) | Change / how measured |
|---|---:|---:|---|
| CLI subcommands | 8 | **8** | unchanged; `apps/photocraft-cli/src/args.rs:31-40` |
| CLI export flags | 7 | **9** | +`--tiff-compression none\|lzw\|zip`, +`--jpeg-format baseline\|optimized\|progressive`; also +`--in-place` on `convert`/`run` (`args.rs:44-83`) |
| CLI completions / man pages | — | **5 shells + per-subcommand man pages** | new surface: `apps/photocraft-cli/examples/man-and-completions.rs`, shipped by the Linux/FreeBSD packaging |
| MCP tools | 22 enumerated (+`doc_select`/`doc_close` in prose = 24) | **26** | +`doc_replace_smart_object`; `doc_render_preview` counted as its own registry entry; `crates/automation/src/server.rs:612-1016` |
| MCP resources | not mentioned | **2** | new: `photocraft://document`, `photocraft://commands`; `crates/automation/src/server/conventions.rs:7-8,63-90` |
| Control-channel methods | 28 | **28** | unchanged (previous list was correct); `crates/ui-egui/src/control.rs` |
| Headless `serve`/rpc methods | 18 | **19** | +`doc.replaceSmartObject`; `crates/automation/src/rpc.rs:42-61` |
| Engine command registry | no number (README "500+") | **~854, uncertain** | 822 non-test registration sites (`spec!`/`cmd!`/`filter_cmd!`/`style_cmd!`/`kind_spec!`/`stack_spec!` or a bare `CommandSpec {`, macro bodies and test files excluded) + 32 generated from the 16-entry `ADJ` table. Under-counts `style_specs!`/`gallery_specs!` expansions (each returns a `Vec`), so **uncertain — see `crates/engine/src/commands.rs:538` `build()` and the per-module `specs()` functions**; authoritative live count is `photocraft-cli commands \| wc -l` |
| Menu items live | 631/631 | **631/631** | unchanged; `crates/ui-egui/src/parity.rs:10`, `docs/parity-checklist.md:5` |
| Tools | 67 | **67** | unchanged; `crates/ui-egui/src/state.rs:209` |
| Adjustment-layer commands | 16 (+16 destructive) | **16 (+16)** | unchanged; `crates/engine/src/commands.rs:1364-1450` |
| Layer effects | 10 | **10** | unchanged; `crates/doc/src/effects.rs:277` |
| Blend modes | 34 | **34** | unchanged; `crates/color/src/blend.rs:11-51` |
| `filter.*` commands | not counted | **124** | 30 `filters.rs` + 33 `filters_ext.rs` + 47 Filter Gallery + `filter.filterGallery` + 13 workspace/lifecycle ids; gallery table `crates/algo/src/artistic.rs` |
| PSD smart-filter classes / commands | "41 filters map both ways" | **54 classes → 49 commands** | `crates/io/src/smart_map.rs` `Known` entries; docs say 53 (stale) |
| Action event mappings | 92 (prev skill) / 112 (docs) | **114** | `crates/engine/src/atn_cmds.rs:3405` |
| `actions.*` commands | 9 | **16** | +`load/save/insert/dialog/assignSet/setColor/conditional` |
| Codec formats | 16 named, no count (DICOM/PCX/IFF listed as unsupported) | **22** | `crates/codecs/src/format.rs:108`; PCX, XPM, DICOM and Amiga IFF are readable now, and **Cineon gained a writer** |
| Layered importers | PDN, KRA, Affinity, SVG, ORA | **+XCF/.xcf.gz** | `crates/io/src/xcf.rs`, `docs/xcf.md` |
| Preferences | 171 settings, 24 dead | **177 settings, 20 dead** | `docs/scorecard.md:12,188` (generated by `xtask`) |
| Plug-in commands / ABI | 5, v1 | **5, v1** | unchanged; `crates/engine/src/plugin_cmds.rs`, `crates/plugins/src/runtime.rs:14` |

## 3. Things that could not be verified (stated as uncertain in SKILL.md)

- **Exact engine command count.** Two table macros expand to several `CommandSpec`s at compile time, and some ids are
  built through a `const` instead of a literal — `crates/engine/src/magnetic_cmds.rs:20` `CMD = "select.magneticLasso"`,
  `crates/engine/src/plugin_cmds.rs:19` `RUN = "plugin.run"`, `crates/engine/src/vp_cmds.rs:15` `VP`,
  `crates/engine/src/distort_cmds.rs:30` `LIQUIFY`, `crates/engine/src/lens_cmds.rs:25-26` `WIDE`/`RAW` — so a static
  count brackets it at roughly 850. Use `photocraft-cli commands | wc -l` on the installed build. Known sources of
  uncertainty: `crates/engine/src/type_styles_cmds.rs` (`style_specs!`), `crates/engine/src/gallery_cmds.rs`
  (`gallery_specs!`), and the const-built ids above.
- **Open-issue count.** `ROADMAP.md:43` says 953 open (measured 2026-10-13); `docs/gaps.md` G3 says 579 (2026-10-10).
  Both are checkpoints, not live data — treat as "hundreds", and read GitHub for the current number.
- **Feature-breadth / readiness percentages.** `ROADMAP.md:20-30` (~76% / ~45%) were measured at 0.6.0 on 2026-10-10 and
  have not been recomputed; do not present them as 0.16.0 measurements.
- **PSD oracle set size.** The Photoshop-authored floor is 190 of **256** in `docs/scorecard.md:10` but the round-trip floor
  column shows 258 files; `crates/io/tests/it/corpus.rs:159` enforces `pass_floor: 190, roundtrip_floor: 258`. Cite the
  floor, not the total.

## 4. Doc-vs-code drift found at this tag (code wins)

| Doc statement | Code reality |
|---|---|
| `ROADMAP.md:22` "menus 628/628, tools 56/68, formats 13+4 of 31" | 631/631 live (`docs/parity-checklist.md:5`), 67 `Tool::ALL` (`state.rs:209`), 22 codecs + layered formats |
| `docs/architecture.md:17` and `docs/roadmap.md:53` "~700 commands"; `README.md:230` "500+ commands" | ~854 registration sites (static) — both are floors |
| `docs/gaps.md` / `docs/file-format-parity.md` "112 `.atn` events" | 114 rows in `EVENTS` |
| `docs/file-format-parity.md` "ours only" table: Krita `.kra`, GIMP `.xcf` read = **no** | `crates/io/src/kra.rs` / `xcf.rs` import them; `docs/xcf.md` and `docs/kra.md` document the readers |
| `docs/file-format-parity.md` PSD row "53 smart filters mapped" | 54 `Known` classes / 49 commands in `crates/io/src/smart_map.rs` |
| `docs/scorecard.md` AUTO-219-2 note "90 Photoshop events" | 114 rows (note is hand-written prose; the scorecard's generated numbers are trustworthy, its notes can lag) |
| `docs/gaps.md:271` "24 of 171 preferences" vs `:3` change note "25 of 166" | `docs/scorecard.md:12` generated count: 20 of 177 |

## 5. Verification commands (read-only, reproduce the counts)

```sh
git -C <clone> rev-parse HEAD                       # b1794c6e0608ccfc887213dcf58398977c5cb75e
sed -n '10p' crates/ui-egui/src/parity.rs           # FLOOR: usize = 631
sed -n '5p' docs/parity-checklist.md                # 631 of 631 menu items live
sed -n '209p' crates/ui-egui/src/state.rs           # pub const ALL: [Tool; 67]
sed -n '43,61p' crates/automation/src/rpc.rs | grep -c '"'   # 19 headless METHODS
sed -n '611,1016p' crates/automation/src/server.rs | grep -c '#\[tool'   # 26 MCP tools
grep -c 'Known {' crates/io/src/smart_map.rs        # 54 PSD smart-filter classes
awk '/^const EVENTS: /,/^];/' crates/engine/src/atn_cmds.rs | grep -cE '(ev!|adjustment_event!|clipping_event!|Event \{)'   # 114 action-event rows
sed -n '108p' crates/codecs/src/format.rs           # pub const ALL: [Format; 22]
sed -n '18p' crates/format/src/manifest.rs          # pub const FORMAT_VERSION: u32 = 1
sed -n '31,40p' apps/photocraft-cli/src/args.rs     # 8 CLI subcommands
photocraft-cli commands | wc -l                     # authoritative engine command count
```

## 6. Files read for this audit

`README.md`, `ROADMAP.md`, `Cargo.toml`, `AGENTS.md`, `docs/{architecture,control-protocol,mcp,scorecard,gaps,roadmap,parity-checklist,file-format-parity,plugins,printing,batch-naming,ora,xcf,kra,pdn,smart-filters,shape-strokes,hardware-parity,development}.md`,
`apps/photocraft/src/{launch_args,app_dirs,control_server,single_instance,gpu_startup}.rs`,
`apps/photocraft-cli/src/{lib,args,document,batch,automation,actions,output}.rs`, `apps/photocraft-cli/examples/man-and-completions.rs`,
`crates/engine/src/{commands,atn_cmds,actions_cmds,adjust_cmds,filters,filters_ext,gallery_cmds,layer_style,plugin_cmds,print_cmds,photo_cmds,timeline_cmds,video_cmds,export_preset_cmds,web_cmds,prefs,build_info,updates_cmds,kys,adjust_params}.rs`,
`crates/ui-egui/src/{state,parity,control,menu_catalog}.rs`, `crates/doc/src/{effects,lib}.rs`, `crates/color/src/blend.rs`,
`crates/algo/src/artistic.rs`, `crates/codecs/src/format.rs`, `crates/codecs/README.md`,
`crates/io/src/{lib,psd_import,psd_export,xcf,kra,pdn,affinity,ora,tiff_layers,pdf,svg,smart_map}.rs`, `crates/io/tests/it/corpus.rs`,
`crates/format/src/{manifest,migrate,atomic,autosave}.rs`, `crates/raw/src/{lib,cr3}.rs`, `crates/plugins/src/{runtime,manifest}.rs`,
`crates/automation/src/{server,server/conventions,rpc,security,budgets,workspace,args,bridge,headless,files}.rs`,
`/Applications/PhotoCraft.app/Contents/Info.plist` (read only; no GUI launch).

Shared libraries were not cloned: `storytold/craft-libs` is pinned in `Cargo.toml` (`craft-ui` `5c874d51eeb3de70e735c8ce87a59a7dedd47675`, `craft-print` `3d37da389a3618ab9b76109da11416e9ca4ea719`, `craft-docpath` `82a24b006eefa036b43c09a67fb9a3fbd17ffe63`, `craft-jpeg` `6e7f28518dd1cb57e1624bdc269c3c14316b13ae`); no shared-library behaviour is claimed here.

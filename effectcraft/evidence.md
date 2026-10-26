# EffectCraft — evidence table

Checkout: `storytold/effectcraft` at tag **`v0.17.0`**, commit
`362474a843ddb67555d4c2d19ad6a590388aad0e` (inspected 2026-10-26). The worktree was clean and was
not built or modified. Installed bundle `/Applications/EffectCraft.app` reports version `0.17.0`,
bundle id `ai.storyteller.effectcraft`, `EffectCraftBuildCommit` =
`362474a843ddb67555d4c2d19ad6a590388aad0e`, minimum macOS 11.0; `Contents/MacOS` holds only
`EffectCraft` (no CLI). Its binary prints `effectcraft 0.17.0`. No GUI was launched; only
`--version` was run.

Tiers: **implemented** = code path exists and is wired into UI/CLI/commands; **partial** = exists
with named limits; **claimed** = docs/README say it but no code path was found; **not implemented**
= no code path.

## The 20 claims that matter most

| # | Capability claim | Evidence | Tier |
|---:|---|---|---|
| 1 | Native `.ecproj` is versioned JSON (schema 2) with `savedBy`, `activeComp`/`openComps`/`compTimes`, items, render queue; save validates by re-reading and writes atomically; a newer `savedBy` warns that unknown settings are lost on save | `crates/project/src/lib.rs:35,54-80,1601-1640`; `crates/engine/src/commands/file.rs:86-120` | implemented |
| 2 | `.ecprojx` is a lossless XML copy of the project; opened like `.ecproj`; a project opened from XML saves as XML again; XML nesting capped at 128 | `crates/engine/src/xml_project.rs`; `crates/engine/src/commands/file.rs:43-96` | implemented |
| 3 | Autosave, crash recovery, MCP `--autosave` checkpoints, and open-time repair of out-of-range project values (size ≤ 30,000 px, fps 0.001–1000, pixel aspect 0.1–10, motion-blur samples 2–64) | `crates/engine/src/autosave.rs`; `crates/project/src/limits.rs:17-29`; `crates/engine/src/commands/file.rs:49-70,96`; `docs/agents.md` §Keeping headless work | implemented |
| 4 | **672** engine command ids in the registry plus **111** UI-only ids; no command is a disabled stub | `crates/engine/src/commands/mod.rs:155-241` (80 `specs()` modules); `crates/ui-egui/src/menus.rs:29-141` (`uic!`); `crates/engine/src/commands/stubs.rs` (empty `specs()`) | implemented (two dispatch tiers: headless engine ids vs live-app UI ids) |
| 5 | MCP server with **36 tools** (27 headless + 9 bridge-only), two resources, protocol versions 2025-06-18/2025-03-26/2024-11-05, render progress and cancellation | `crates/automation/src/tools.rs:542-979`; `crates/automation/src/server.rs:14,278-284`; `docs/mcp.md` | implemented |
| 6 | Localhost JSON control channel with **24** dispatch methods, 127.0.0.1 only, ≤ 16 connections, 60 s request timeout, 4 MiB line cap, no authentication | `crates/ui-egui/src/control.rs:172-490`; `apps/effectcraft/src/control_server.rs:21-23,63`; `docs/control-protocol.md` | implemented |
| 7 | CLI with **12** subcommands (`info commands exec run props get set render-frame render bench script mcp`), `run --args-file`, JSON output, headless/bridge modes, per-codec render flags, `--queue`, `--progress`, MCP confinement roots | `apps/effectcraft-cli/src/main.rs:2-37,94-200,459-633,521-527`; `docs/agents.md` §CLI | implemented |
| 8 | Render Queue writes **13** formats: H.264, HEVC, AV1, ProRes, uncompressed MOV, WebM, PNG/JPEG/TIFF/EXR sequences, GIF, WAV, AIFF; queued items default to Work Area | `crates/project/src/render_queue.rs:531-545,368` | implemented |
| 9 | Single-frame layered PSD output and multi-layer OpenEXR (ProEXR) output | `crates/engine/src/commands/frame_export.rs:1-12,111` | implemented |
| 10 | Lottie import/export for `.json` and `.lottie`, with a `warnings` list for inexpressible features | `crates/engine/src/commands/lottie.rs:9-30,61-65`; `crates/lottie/src/lib.rs` | implemented |
| 11 | Timeline interchange in FCP7 XML, FCPXML, OTIO, EDL, AAF and OMF; native `.prproj` explicitly rejected; optional ProRes 4444 pre-render (`none` / `unsupported` / `all`) | `crates/interchange/src/lib.rs:1-26`; `crates/interchange/src/export.rs:19-39`; `crates/engine/src/commands/timeline.rs` | implemented (pre-render fidelity depends on `prerender`) |
| 12 | **307** registered effects, **3032** parameters (2984 visible; hidden params also counted), **280** GPU-capable, all 32-bit float, **21** categories, **0** marked partial | `docs/effects.md:6-10` (generated from `crates/effects/src/catalog.rs`, test-enforced by `effects_doc_is_current` at `crates/effects/src/catalog.rs:173-182`) | implemented |
| 13 | **38** blend modes and **9** Layer Styles plus Blending Options/Global Light | `crates/color/src/blend.rs:52`; `crates/project/src/styles.rs:3-11,28-40` | implemented |
| 14 | Keyframes (linear/Bezier/hold, per-side speed/influence, auto/continuous Bezier, roving), Graph Editor, time remap/stretch/reverse/freeze; JavaScript expressions on `boa` with the AE object model | `crates/keyframe/src/lib.rs:9,60-120`; `crates/engine/src/commands/prop.rs:1369-1389`; `crates/engine/src/commands/layer_time.rs:253`; `crates/expr/src/lib.rs:14-25`; `docs/scripting-parity.md` | implemented |
| 15 | Text (point/paragraph, style runs, variable fonts and named instances, text animators), shapes (trim/repeater/round corners/offset/zig zag/twist/wiggle/merge/gradient stroke), masks (**7** modes, feather, expansion, vertex editing, Mask Interpolation) | `crates/engine/src/commands/{text_edit,text_anim,mask,mask_interp,paths}.rs`; `crates/project/src/props.rs:217-243`; `crates/text/src/fonts.rs:57-63` | implemented |
| 16 | Classic 3D and Advanced 3D; one/two-node cameras with DOF; Parallel/Spot/Point/Ambient/Environment lights; ray-cast shadows; PBR, six primitives and imported models | `crates/gpu/src/lib.rs:1-12`; `crates/engine/src/commands/model3d.rs`; `crates/ui-egui/src/menus.rs:405-407`; `docs/agents.md` §Pitfalls (Environment light) | implemented |
| 17 | Tracking (point/transform/stabilize/affine/perspective), mask and face tracking, Warp Stabilizer, 3D Camera Tracker, Roto Brush with optional MobileSAM, Object Matte with disk cache, Paint/Liquify/Puppet, Content-Aware Fill, Auto-trace, Scene Edit Detection | `crates/engine/src/commands/{track,warp_cmds,camera_cmds,mask_interp,roto_cmds,paint,liquify,puppet,content_fill,autotrace,scene_detect}.rs`; `crates/effects/src/{roto,object_matte,face_track}.rs` | implemented (AE fidelity unmeasured; Auto-trace is synchronous, the other two are background jobs) |
| 18 | **New in 0.17.0:** `effect.pickCryptomatte` / `effect.cryptomatteAt` (Cryptomatte eyedropper in effect space, `replace`/`add`/`remove`, one undo step, refuses expression-driven Selections) and `layer.replaceSource` (Layer ▸ Replace Source; keeps name, timing, transforms, keys, expressions, effects, masks, switches, parenting, track matte) | `crates/engine/src/commands/effect.rs:250-290,731-746`; `crates/engine/src/commands/layer.rs:317-400`; `crates/effects/src/crypto_select.rs`; `crates/engine/src/tests_crypto_pick.rs`, `crates/engine/src/tests_replace_source.rs` | implemented |
| 19 | Import registry: stills `png jpg jpeg gif webp tif tiff bmp exr tga hdr psd psb svg pdf ai eps` (17); video `mp4 m4v mov mkv webm mxf`; models `gltf glb obj stl fbx`; audio from FilmCraft (`wav wave bwf aif aiff mp3 mp2 m4a aac flac ogg opus`); DPX/Cineon; data `json csv tsv` | `crates/media/src/lib.rs:62-70`; `crates/media/src/dpx.rs`; `crates/engine/src/commands/file.rs` | implemented (per-format caveats in `docs/file-format-parity.md`) |
| 20 | **54** built-in animation presets (8 text animators, 23 backgrounds, 23 transitions), `.ecpreset` save/apply, `.ectemplate` ZIP templates; Scripting/ScriptUI; `.wasm` plug-ins; `window.effectcraft` web build | `crates/engine/presets/*.json` (23+8+23); `crates/engine/src/commands/animation.rs:16-17`; `crates/engine/src/commands/essential.rs:11-12,860-882`; `crates/script/src/lib.rs`; `crates/plugin/src/lib.rs:4-35`; `apps/effectcraft-web/src/api.rs`; `docs/web.md:387-399` | implemented (named scripting and web gaps below) |

## Verified absences (searched; no code path found)

| Claim | Evidence | Tier |
|---|---|---|
| Open/write `.aep` / `.aepx` | `docs/file-format-parity.md:25-26`; no reader/parser found under `crates/` or `apps/` | **not implemented** |
| Read `.ffx`, `.mogrt`, `.aet`, `.ars`, `.aom` | `docs/file-format-parity.md:27-30`; own `.ecpreset` and `.ectemplate` instead | **not implemented** |
| Host After Effects SDK plug-ins (`.aex`/`.plugin`) or read `.prproj` | `docs/gaps.md` gaps 19/23; `crates/interchange/src/lib.rs:24-26`; no host/reader found | **not implemented** |
| Hardware video decode/encode (VideoToolbox, NVENC, Quick Sync, VA-API) | `docs/gaps.md` gap 15; no platform codec calls under `crates/` or `apps/` | **not implemented** |
| 16-bpc uncompressed, AVI, lossless single-file video, MXF output, DNxHR, DPX/TGA/PSD sequences, ProRes RAW | `docs/file-format-parity.md:99-106`; `OutputFormat::ALL` is the 13 listed above | **not implemented** |
| `.jsxbin`, Startup/Shutdown script folders, script shortcuts, Legacy ExtendScript mode, BridgeTalk messaging | `docs/scripting-parity.md`; `docs/plugins.md` | **not implemented** (`.jsxbin` is explicitly refused) |

## Counts at a glance (all re-measured at this tag)

| Thing | Count | Evidence |
|---|---:|---|
| Engine command ids | **672** | `crates/engine/src/commands/mod.rs:155-241`; 672 unique `cmd!`/`query!` ids across `crates/` |
| UI-only command ids | 111 (`timeline` 53, `tool` 15, `view` 12, `window` 11, `viewer` 8, `playback` 5, `app` 4, `flowchart` 2, `markers` 1) | `crates/ui-egui/src/menus.rs:29` (`UI_COMMANDS`, `uic!`) |
| Disabled stub commands | 0 (the stub module returns an empty list) | `crates/engine/src/commands/stubs.rs` |
| MCP tools | 36 (27 headless + 9 bridge-only) | `crates/automation/src/tools.rs:542-979`, `bridge_only: true` count = 9 |
| Control-channel dispatch methods | 24 (in 21 arms) | `crates/ui-egui/src/control.rs:172-490` |
| CLI subcommands | 12 | `apps/effectcraft-cli/src/main.rs:94-200,459-633` |
| CLI value flags / boolean flags | 43 / 17 | `apps/effectcraft-cli/src/main.rs:139-200` (`VALUED` 43, `FLAGS` 17) |
| Render Queue formats | 13 | `crates/project/src/render_queue.rs:531` |
| Effects / parameters / GPU / categories / partial | 307 / 3032 / 280 / 21 / 0 | `docs/effects.md:6-10` (generated, test-enforced) |
| Blend modes | 38 | `crates/color/src/blend.rs:52` |
| Layer Styles | 9 | `crates/project/src/styles.rs:28-40` |
| Mask modes | 7 | `crates/project/src/props.rs:217-243` |
| Built-in animation presets | 54 (8 + 23 + 23) | `crates/engine/presets/*.json` |
| Menu languages / panel catalogs | 11 / 8 | `crates/ui-egui/src/i18n.rs:18`; `crates/ui-egui/src/i18n/ui.rs:69-78` |
| Panel kinds / named workspaces | 36 / 15 | `crates/ui-egui/src/dock.rs:14-58,281-297` |
| Import extensions (stills / video / models) | 17 / 6 / 5 | `crates/media/src/lib.rs:62-70` |
| Timeline interchange formats | 6 | `crates/interchange/src/lib.rs:1-26` |

## Changes from v0.15.0 to v0.17.0

The clone is shallow (one commit), so the comparison is a **tree diff against the `v0.15.0` tag**,
not `git log`: ~**354** changed/added/removed files and ~**12,200** changed lines, excluding
images and `Cargo.lock`. The test layout moved from `tests/*.rs` to `tests/it/<module>.rs` across
crates, which accounts for many of the renames.

| Area | Change | Evidence |
|---|---|---|
| Commands | 669 → **672** ids. Added `effect.pickCryptomatte` and `effect.cryptomatteAt` (#473) and `layer.replaceSource` (#991, #813). Nothing removed | `crates/engine/src/commands/{effect,layer}.rs`; `docs/agents.md` (new Cryptomatte cookbook row) |
| CLI | `run --args-file F` reads one argument per line (Windows 32,767-character command lines); no subcommand or other flag added or removed | `apps/effectcraft-cli/src/main.rs:9,100,153,521-527` |
| Localization | Georgian (`ka`) added: 11 menu catalogs (628 rows each), 8 panel catalogs, effect names and categories; native-speaker reviewed. Korean/Italian still absent | `crates/ui-egui/src/i18n.rs:18`; `crates/ui-egui/src/i18n/ui.rs:69-78`; `crates/ui-egui/src/i18n/effects.rs`; `ROADMAP.md:138`; `docs/localization-parity.md:93` |
| UI panel reveal | Reveal Layer Source in Project (`layer.revealSource`) emits a `project.reveal` frontend event; the UI opens the Project panel, clears its search, expands folders and selects the item | `crates/engine/src/commands/layer_menu.rs:771-782,928`; `crates/ui-egui/src/menus.rs:950-961`; `docs/footage.md:73-82` |
| Timeline | A row control (A/V switches, Switches column, label swatch, Modes cell) clicked on one of several selected layers applies to the whole selection, one undo step (#1849); a hidden null/camera/light is not picked in the viewer (#1769); a shape group's inner Contents row is elided | `crates/ui-egui/src/panels/timeline.rs`; `docs/ui-parity.md:20,53` |
| Composition Settings | Resolution popup with frame size and memory per 8bpc frame (#2167) | `docs/target-app-parity.md:691-694`; `crates/ui-egui/src/panels/comp_settings.rs:98-100,384-390`; `crates/ui-egui/src/panels/dialogs.rs:431-433` |
| Preferences | `general.createSplitLayersAbove` now defaults on, as in After Effects | `docs/preferences.md:94-95`; `crates/engine/src/prefs.rs` |
| Fidelity | First effect-level comparisons against After Effects 2026 renders: Tint, Tritone, Black & White, Exposure, Levels (Individual Controls), Curves, Luma Key, Extract, 4-Color Gradient, Fill within 1–3/255; Brightness & Contrast up to 6.2/255 | `docs/effects-parity.md:18,33-38`; `crates/effects/src/{color_fx,color2,keying,generate}.rs` |
| CI | `.github/workflows/ci.yml` added: `cargo xtask ci` on every push to `main` and every PR via `storytold/craft-common-actions`; `cargo xtask ci` now runs `cargo nextest run` and `missing_translations_report` | `.github/workflows/ci.yml:1-27`; `docs/testing.md:8-16` |
| Renderer | The window's wgpu device requests `MemoryHints::MemoryUsage`; Advanced 3D shading/rendering and the GPU shader changed | `apps/effectcraft/src/main.rs:374-387`; `crates/render/src/three_d/adv/`, `crates/gpu/src/shaders/advanced3d.wgsl` |
| Unchanged surfaces | `crates/media/src/lib.rs`, `crates/project/src/render_queue.rs`, `crates/interchange/src/`, `crates/project/src/styles.rs`, `crates/color/src/blend.rs`, `crates/ui-egui/src/dock.rs`, `crates/automation/src/tools.rs`, `crates/automation/src/server.rs`, `crates/ui-egui/src/control.rs`, `docs/effects.md`, `docs/mcp.md` are byte-identical to v0.15.0 → those counts cannot have drifted | tree diff |

## Corrections vs the previous (v0.15.0) skill

| Previous claim | What the v0.17.0 code shows | Evidence |
|---|---|---|
| 669 engine commands | **672** (+`effect.pickCryptomatte`, `effect.cryptomatteAt`, `layer.replaceSource`) | `crates/engine/src/commands/mod.rs`; macro count |
| 34 panel kinds | **36**: 34 plain variants plus the parameterised `ScriptPanel(u32)` and `Viewer(u32)` | `crates/ui-egui/src/dock.rs:14-58` |
| Panel catalogs in 7 languages | **8** — `ka` was added; `docs/gaps.md` gap 16 still says 7 | `crates/ui-egui/src/i18n/ui.rs:69-78`; `docs/gaps.md:75` |
| Menu catalogs in 10 languages | **11** (Georgian added) | `crates/ui-egui/src/i18n.rs:18` |
| "No PR workflow runs the repo's full `cargo xtask ci` gate" | A CI gate exists at this tag (`.github/workflows/ci.yml`); `docs/gaps.md` gap 3 still claims none | `.github/workflows/ci.yml`; `docs/gaps.md:41,62` |
| `setValue` dimension check at `crates/script/src/prelude.js` line 869 in v0.15.0 | Now line **876** (same behavior) | `crates/script/src/prelude.js:876` |
| Control methods lived in `crates/ui-egui/src/control.rs:172-460` at v0.15.0 | Arms now run to **490** (same 24 methods) | `crates/ui-egui/src/control.rs:172-490` |
| Crate tests cited directly under `tests/` | Tests moved one level down into `tests/it/` modules (e.g. the UI agent audit test is now `crates/ui-egui/tests/it/ui_agent_audit.rs`) | `docs/control-protocol.md:54`; `tests/it/` trees |
| "Everything the UI does is an engine command" | Still two tiers: 672 engine ids + 111 UI-only ids; `project.reveal` is a frontend **event**, not a registered UI command | `crates/ui-egui/src/menus.rs:29,950-961` |

## Docs-vs-code discrepancies at this tag

| Claim in docs | What the code shows | Evidence |
|---|---|---|
| `README.md` (3 places), `docs/gaps.md`, `docs/architecture.md`, `docs/roadmap.md`, `docs/hardware-parity.md` say 306 effects | Registry, generated `docs/effects.md` and `app.capabilities` say **307** | `README.md:23,129,231`; `docs/gaps.md:34`; `docs/architecture.md:3,32`; `docs/effects.md:6`; `crates/engine/src/commands/query.rs:181-202` |
| `docs/effects-parity.md` says 306 effects / 3,017 parameters (and per-row table totals) | **307 / 3032** | `docs/effects-parity.md:14,17`; `docs/effects.md:6` |
| `docs/target-app-parity.md` says "411 registered engine commands" | **672** engine ids, plus 111 UI-only | `docs/target-app-parity.md:72`; `crates/engine/src/commands/mod.rs` |
| `docs/gaps.md` gap 16 says panels in 7 languages, menus 628 rows | Panel catalogs are **8** (Spanish `es` and Georgian `ka` both exist) | `docs/gaps.md:75`; `crates/ui-egui/src/i18n/ui.rs:69-78` |
| `docs/gaps.md` gap 3/4 says no CI workflow runs `cargo xtask ci` on PRs | `.github/workflows/ci.yml` runs it on pushes and PRs | `docs/gaps.md:41,62`; `.github/workflows/ci.yml` |
| `docs/gaps.md` gap 18 says "no relink when a project moves"; `docs/file-format-parity.md:34` repeats it for `.ecproj` | `footage.relink`, `footage.missing`, `file.relinkFootage` and moved-project search exist; relative paths resolve against the project folder | `crates/engine/src/commands/relink.rs`, `crates/engine/src/commands/relink_moved.rs`, `crates/engine/src/doc_path.rs` |
| `docs/effects.md` header says 3032 parameters while its table sums to 2984 | Not a bug: the header counts all params, the table omits `ParamUi::Hidden` ones | `crates/effects/src/catalog.rs:128-182` |
| `packaging/macos/Info.plist.in` declares a QOI document type; the installed bundle carries it too | `STILL_EXTENSIONS` has no `qoi` and no import path references it | `packaging/macos/Info.plist.in`; `crates/media/src/lib.rs:62-63` |
| `docs/preferences.md:33` lists 9 `general.language` values (`system`, `en`, `ja`, `zh-hans`, `zh-hant`, `uk`, `es`, `pt-br`, `ka`) | `CATALOG_CODES` has **11** menu catalogs: `de`, `fr`, `ru` and `cs` are selectable in code but unlisted in the doc | `docs/preferences.md:33`; `crates/ui-egui/src/i18n.rs:18` |

## Environment checks

| Check | Result | Evidence |
|---|---|---|
| Installed version / build | 0.17.0, commit `362474a843ddb67555d4c2d19ad6a590388aad0e` | `/Applications/EffectCraft.app/Contents/Info.plist` (`CFBundleShortVersionString`, `EffectCraftBuildCommit`) |
| Bundle id / minimum OS | `ai.storyteller.effectcraft`; macOS 11.0 | the same `/Applications/EffectCraft.app/Contents/Info.plist` (`CFBundleIdentifier`, `LSMinimumSystemVersion`) |
| Binary version text | `effectcraft 0.17.0` | `/Applications/EffectCraft.app/Contents/MacOS/EffectCraft --version` (exits before a window) |
| CLI inside the bundle | absent — only `EffectCraft` in `Contents/MacOS` | bundle listing; `docs/agents.md` §From an installed release |
| GUI launched during authoring | no | — |
| Worktree built or modified | no | `git status --short` empty; no build or test commands run |
| Clone depth | 1 commit (shallow, tag `v0.17.0`); change list derived from a tree diff against the `v0.15.0` tag source | `git log --oneline`, `git tag` |

## What was not verified live

- **No render, no GUI and no `effectcraft-cli` run.** The macOS bundle ships no CLI and nothing was
  built, so CLI/MCP/control behavior above is read from source, tests and docs, not exercised.
- **No After Effects comparison.** Effect and keyframe fidelity claims are taken from the
  repository's dated docs (`docs/effects-parity.md`, `docs/fidelity/README.md`), not measured here.
- **No real media round-trip.** Codec/format limits are from the registry, encoder options and
  `docs/file-format-parity.md`; they were not tested against sample files.
- **Shared libraries (`craft-libs`, `filmcraft`) are not in this clone.** Their behavior (audio
  extension list, timeline interchange parsers) is taken from the pinned revisions in `Cargo.toml`
  and from this repo's use of them, not audited.

## How to spot-check

```sh
git rev-parse HEAD                          # 362474a843ddb67555d4c2d19ad6a590388aad0e
git describe --tags --exact-match HEAD      # v0.17.0

rg -n "pub const SCHEMA_VERSION" crates/project/src/lib.rs               # 2
rg -n "pub const ALL: \[OutputFormat; 13\]" crates/project/src/render_queue.rs
rg -n "pub const ALL: \[BlendMode; 38\]" crates/color/src/blend.rs
rg -n "pub const ALL: \[MaskMode; 7\]" crates/project/src/props.rs
rg -n "pub const STYLES" crates/project/src/styles.rs                    # 9 entries
rg -n "const CATALOG_CODES" crates/ui-egui/src/i18n.rs                   # 11 languages
rg -n "fn specs" crates/engine/src/commands/stubs.rs                     # returns vec![]

python3 - <<'EOF'
import re, pathlib
ids = []
for p in pathlib.Path("crates").rglob("*.rs"):
    ids += re.findall(r'\b(?:cmd|query)!\(\s*"([^"]+)"', p.read_text(errors="ignore"))
print("engine commands:", len(ids), "unique:", len(set(ids)))         # 672 / 672
ui = open("crates/ui-egui/src/menus.rs").read()
print("UI-only ids:", len(set(re.findall(r'uic!\(\s*"([^"]+)"', ui))))  # 111
print("registry modules:", open("crates/engine/src/commands/mod.rs").read().count("v.extend("))  # 80
EOF

python3 - <<'EOF'
import re
t = open("crates/automation/src/tools.rs").read()
block = t[t.index("static TOOLS"):]
print("MCP tools:", len(re.findall(r'ToolDef \{\s*name: "', block)))    # 36
print("bridge-only:", len(re.findall(r"bridge_only: true", block)))      # 9
h = open("crates/ui-egui/src/control.rs").read()
h = h[h.index("pub fn handle"):]
print("control methods:", len(set(re.findall(r'"((?:engine|ui|render|app)\.[a-z][a-z0-9.]*)"', h))))  # 24
EOF

python3 - <<'EOF'
import re
t = open("docs/effects.md").read()
rows = [l for l in t.splitlines() if re.match(r'^\| .*\| `ec\.', l)]
print("effects:", len(rows),                           # 307
      "visible params:", sum(int(l.split('|')[3]) for l in rows),  # 2984 (header: 3032)
      "GPU:", sum(1 for l in rows if '| GPU |' in l),  # 280
      "categories:", len(re.findall(r'^## ', t, re.M)))  # 21
EOF

python3 - <<'EOF'
import json, re
for f in ("backgrounds", "text_animators", "transitions"):
    print(f, len(json.load(open(f"crates/engine/presets/{f}.json"))["presets"]))  # 23 8 23
dock = open("crates/ui-egui/src/dock.rs").read()
print("workspaces:", len(re.findall(r'"([^"]+)"', dock[dock.index("pub const WORKSPACES"):dock.index("];", dock.index("pub const WORKSPACES"))])))  # 15
EOF

rg -n "306 effects|306 registered|411 registered|panels in 7|no CI workflow" README.md docs/*.md | head
```

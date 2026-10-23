# EffectCraft — evidence table

Checkout: `storytold/effectcraft` at tag **`v0.15.0`**, commit
`15b8a916c528e73d48f7a9cb4ff58276c7a2d3dd` (tag commit dated 2026-10-22; inspected 2026-10-23).
The worktree was clean and was not built or modified. Installed bundle
`/Applications/EffectCraft.app` reports version `0.15.0`, bundle id `ai.storyteller.effectcraft`,
`EffectCraftBuildCommit` = `15b8a916c528e73d48f7a9cb4ff58276c7a2d3dd`, universal `x86_64`+`arm64`,
minimum macOS 11.0; `Contents/MacOS` holds only `EffectCraft` (no CLI). Its binary prints
`effectcraft 0.15.0`. No GUI was launched; only `--version` was run.

Tiers: **implemented** = code path exists and is wired into UI/CLI/commands; **partial** = exists
with named limits; **claimed** = docs/README say it but no code path was found; **not implemented**
= no code path.

## The 20 claims that matter most

| # | Capability claim | Evidence | Tier |
|---:|---|---|---|
| 1 | Native `.ecproj` is versioned JSON (schema 2) with `savedBy`, `activeComp`/`openComps`/`compTimes`, items, render queue; save validates by re-reading and writes atomically; a newer schema is refused | `crates/project/src/lib.rs:34,59,1549-1581`; `crates/engine/src/lib.rs:144`; `crates/engine/src/commands/file.rs:43-110` | implemented |
| 2 | `.ecprojx` is a lossless XML copy of the project; opened like `.ecproj`; a project opened from XML saves as XML again; XML nesting capped at 128 | `crates/engine/src/xml_project.rs:1-30`; `crates/engine/src/commands/file.rs:43-91` | implemented |
| 3 | Autosave, crash recovery, MCP `--autosave` checkpoints, and open-time repair of out-of-range project values (size ≤ 30,000 px, fps 0.001–1000, pixel aspect 0.1–10) | `crates/engine/src/autosave.rs`; `crates/project/src/limits.rs:16-25`; `crates/engine/src/commands/file.rs:49-65`; `docs/agents.md` §Keeping headless work | implemented |
| 4 | 669 engine command ids in the registry plus 111 UI-only ids; every menu item, shortcut, panel gesture, CLI call, MCP call and control request dispatches one of them | `crates/engine/src/commands/mod.rs:155-235`; `crates/ui-egui/src/menus.rs:29`; `docs/architecture.md` §6; `crates/ui-egui/tests/ui_agent_audit.rs` | implemented (two dispatch tiers: headless engine ids vs live-app UI ids) |
| 5 | MCP server with 36 tools (27 headless + 9 bridge-only), two resources, protocol versions 2025-06-18/2025-03-26/2024-11-05, render progress and cancellation | `crates/automation/src/tools.rs:542`; `crates/automation/src/server.rs:14,224-233,278-279`; `docs/mcp.md` | implemented |
| 6 | Localhost JSON control channel with 24 dispatch methods, 127.0.0.1 only, ≤ 16 connections, 60 s request timeout, 4 MiB line cap, no authentication | `crates/ui-egui/src/control.rs:172-460`; `apps/effectcraft/src/control_server.rs:21-23`; `docs/control-protocol.md` | implemented |
| 7 | CLI with 12 subcommands (`info commands exec run props get set render-frame render bench script mcp`), JSON output, headless/bridge modes, per-codec render flags, `--queue`, `--progress`, MCP confinement roots | `apps/effectcraft-cli/src/main.rs:94-192,300-705`; `docs/agents.md` §CLI; `docs/mcp.md` §Confining file access | implemented |
| 8 | Render Queue writes 13 formats: H.264, HEVC, AV1, ProRes, uncompressed MOV, WebM, PNG/JPEG/TIFF/EXR sequences, GIF, WAV, AIFF | `crates/project/src/render_queue.rs:501-545` (`OutputFormat::ALL` = 13) | implemented |
| 9 | Single-frame layered PSD output and multi-layer OpenEXR (ProEXR) output | `crates/engine/src/commands/frame_export.rs:220-240`; `crates/engine/src/menus.rs:706-709` | implemented |
| 10 | Lottie import/export for `.json` and `.lottie`, with a `warnings` list for inexpressible features | `crates/engine/src/commands/lottie.rs:24-65`; `crates/lottie/src/lib.rs` | implemented |
| 11 | Timeline interchange in FCP7 XML, FCPXML, OTIO, EDL, AAF and OMF; native `.prproj` explicitly rejected; optional ProRes 4444 pre-render (`none` / `unsupported` / `all`) | `crates/interchange/src/lib.rs:1-29,99-115`; `crates/engine/src/commands/timeline.rs:20-30,143-159`; `crates/interchange/src/export.rs:19-39` | implemented (pre-render fidelity depends on `prerender`) |
| 12 | 307 registered effects, 3032 parameters (2984 visible; hidden params also counted), 280 GPU-capable, all 32-bit float, 21 categories, 0 marked partial | `docs/effects.md:6-10` (generated from `crates/effects/src/catalog.rs` and checked by `effects_doc_is_current`); `crates/effects/src/lib.rs:485-529`; `crates/effects/src/catalog.rs:10` (`PARTIAL` empty) | implemented |
| 13 | 38 blend modes and 9 Layer Styles plus Blending Options/Global Light | `crates/color/src/blend.rs:9-52`; `crates/project/src/styles.rs:28-40` | implemented |
| 14 | Keyframes (linear/Bezier/hold, per-side speed/influence, auto/continuous Bezier, roving), Graph Editor, time remap/stretch/reverse/freeze; JavaScript expressions on `boa` with the AE object model | `crates/keyframe/src/lib.rs:60-120`; `crates/engine/src/commands/prop.rs:1364-1384`; `crates/engine/src/commands/layer_time.rs:230-255`; `crates/expr/src/lib.rs`; `docs/scripting-parity.md` | implemented |
| 15 | Text (point/paragraph, style runs, variable fonts and named instances, text animators), shapes (trim/repeater/round corners/offset/zig zag/twist/wiggle/merge/gradient stroke), masks (7 modes, feather, expansion, vertex editing, Mask Interpolation) | `crates/engine/src/commands/{text_edit,text_anim,mask,mask_interp,paths}.rs`; `crates/project/src/build.rs:493-598`; `crates/project/src/props.rs:217-243`; `crates/text/src/fonts.rs:57-63` | implemented |
| 16 | Classic 3D and Advanced 3D; one/two-node cameras with DOF; Parallel/Spot/Point/Ambient/Environment lights; ray-cast shadows; PBR, six primitives and imported models | `crates/gpu/src/lib.rs:1-12`; `crates/project/src/lib.rs:612-629`; `crates/project/src/build.rs:616-624`; `crates/engine/src/commands/model3d.rs:384-397`; `docs/agents.md` §Pitfalls (Environment light) | implemented |
| 17 | Tracking (point/transform/stabilize/affine/perspective), mask and face tracking, Warp Stabilizer, 3D Camera Tracker, Roto Brush with optional MobileSAM, Object Matte with disk cache, Paint/Liquify/Puppet, Content-Aware Fill, Auto-trace, Scene Edit Detection | `crates/engine/src/commands/{track,warp_cmds,camera_cmds,mask_interp,roto_cmds,paint,liquify,puppet,content_fill,autotrace,scene_detect}.rs`; `crates/effects/src/{roto,object_matte,face_track}.rs` | implemented (AE fidelity unmeasured; Auto-trace is synchronous, the other two are background jobs) |
| 18 | Import registry: stills `png jpg jpeg gif webp tif tiff bmp exr tga hdr psd psb svg pdf ai eps`; video `mp4 m4v mov mkv webm mxf`; models `gltf glb obj stl fbx`; audio from FilmCraft (`wav wave bwf aif aiff mp3 mp2 m4a aac flac ogg opus`); DPX/Cineon; data `json csv tsv` | `crates/media/src/lib.rs:62-70`; `crates/media/src/dpx.rs:1-20`; `crates/engine/src/commands/file.rs:558-564` | implemented (per-format caveats in `docs/file-format-parity.md`) |
| 19 | 54 built-in animation presets (8 text animators, 23 backgrounds, 23 transitions), `.ecpreset` save/apply, `.ectemplate` ZIP templates with `manifest.json`, `project.ecproj`, `media/`, `poster.png` | `crates/engine/presets/{backgrounds,text_animators,transitions}.json` (23+8+23); `crates/engine/src/commands/animation.rs:16-17,470-484`; `crates/engine/src/commands/essential.rs:8-12,860-870` | implemented |
| 20 | Scripting/ScriptUI, WebAssembly plug-ins and the web build: `.jsx`/`.js` AE object model, ScriptUI panels, `#include`, `app.scheduleTask`, `Socket`; `.wasm`/`.wat` plug-in API v1 in `wasmi`; `window.effectcraft` over OPFS/IndexedDB | `crates/script/src/lib.rs`, `crates/script/src/prelude.js`; `docs/plugins.md`; `crates/plugin/src/lib.rs`; `apps/effectcraft-web/src/api.rs`; `docs/web.md:380-407` | implemented (named scripting and web gaps below) |

## Verified absences (searched; no code path found)

| Claim | Evidence | Tier |
|---|---|---|
| Open/write `.aep` / `.aepx` | `docs/file-format-parity.md:25-26`; no reader/parser found under `crates/` or `apps/` | **not implemented** |
| Read `.ffx`, `.mogrt`, `.aet`, `.ars`, `.aom` | `docs/file-format-parity.md:27-30`; own `.ecpreset` and `.ectemplate` instead | **not implemented** |
| Host After Effects SDK plug-ins (`.aex`/`.plugin`) or read `.prproj` | `docs/gaps.md` gaps 19/23; `crates/interchange/src/lib.rs:27`; no host/reader found | **not implemented** |
| Hardware video decode/encode (VideoToolbox, NVENC, Quick Sync, VA-API) | `docs/gaps.md` gap 15; no platform codec calls under `crates/` or `apps/` | **not implemented** (open PR #819 is not in this tag) |
| 16-bpc uncompressed, AVI, lossless single-file video, MXF output, DNxHR, DPX/TGA/PSD sequences, ProRes RAW | `docs/file-format-parity.md:99-106`; `OutputFormat::ALL` is the 13 listed above | **not implemented** |
| `.jsxbin`, Startup/Shutdown script folders, script shortcuts, Legacy ExtendScript mode, BridgeTalk messaging | `docs/scripting-parity.md`; `docs/plugins.md` | **not implemented** (`.jsxbin` is explicitly refused) |

## Counts at a glance (all re-verified at this tag)

| Thing | Count | Evidence |
|---|---:|---|
| Engine command ids | 669 | `crates/engine/src/commands/mod.rs:155-235`; every `cmd!`/`query!` in `crates/engine/src` is in a registered `specs()` module |
| UI-only command ids | 111 | `crates/ui-egui/src/menus.rs:29` (`UI_COMMANDS`, `uic!`) |
| MCP tools | 36 (27 headless + 9 bridge-only) | `crates/automation/src/tools.rs:542`, `bridge_only: true` count = 9 |
| Control-channel dispatch methods | 24 | `crates/ui-egui/src/control.rs:172-460` |
| CLI subcommands | 12 | `apps/effectcraft-cli/src/main.rs:94-160` |
| Render Queue formats | 13 | `crates/project/src/render_queue.rs:531-545` |
| Effects / parameters / GPU / categories / partial | 307 / 3032 / 280 / 21 / 0 | `docs/effects.md:6-10` (generated, test-enforced) |
| Blend modes | 38 | `crates/color/src/blend.rs:9-52` |
| Layer Styles | 9 | `crates/project/src/styles.rs:28-40` |
| Built-in animation presets | 54 (8 + 23 + 23) | `crates/engine/presets/*.json` |
| Menu languages / panel catalogs | 10 / 7 | `crates/ui-egui/src/i18n.rs:16`; `crates/ui-egui/src/i18n/ui.rs:43-60` |
| Panel kinds / named workspaces | 34 / 15 | `crates/ui-egui/src/dock.rs:14-58,281-297` |

## Changes from v0.14.0 to v0.15.0

`git diff --stat v0.14.0 v0.15.0` touches **19 files, +280/−51**. `v0.14.0` is a root snapshot
commit, so `git log v0.14.0..v0.15.0` reports the whole history since that snapshot; the tree diff is
the meaningful comparison. There is **no new command, MCP tool, control method, format or shortcut**:
`apps/effectcraft-cli/src/main.rs`, `crates/automation/src/tools.rs`, `crates/ui-egui/src/control.rs`,
`crates/project/src/render_queue.rs`, `crates/effects/` and `crates/media/src/lib.rs` are unchanged.

| Area | Change | Evidence |
|---|---|---|
| Precomp cycles | `Project::comp_contains` now uses a stack + seen-set instead of recursion, so a damaged A⇄B cycle cannot exhaust the stack; regression covers cycles, 2^40 diamond paths and a 20,000-comp chain | `crates/project/src/lib.rs:1478-1504`; `crates/project/src/tests.rs:212-269`; `crates/engine/src/tests_limits.rs:105-140` |
| Shape paths | `path::rect` treats a NaN minimum size as zero roundness instead of calling `f64::clamp` with a NaN bound | `crates/path/src/lib.rs:133-140`; test at `:356` |
| Expressions | `sampleImage` uses `saturating_add` for pixel-coordinate loop bounds so a huge sample point cannot overflow | `crates/expr/src/sample.rs:99-105`; test `sample_image_huge_point_is_transparent` |
| Feathers | Deleting the first vertex of a closed path now merges the old closing segment into segment 0 correctly | `crates/keyframe/src/value.rs:82-100`; `crates/keyframe/tests/feather_remove.rs` |
| Color | `hsv_to_rgb` treats an f32 hue that wraps to exactly 6.0 as 0 (tiny negative hues were magenta) | `crates/color/src/lib.rs:141-150`; test `hsv_to_rgb_tiny_negative_hue_is_red` |
| Scripting | `setValue` rejects an array whose length is neither the property dimension nor 2-for-3D, matching After Effects instead of truncating/broadcasting | `crates/script/src/prelude.js:869-877`; `crates/script/src/tests.rs` |
| Tests / CI / packaging | Windows-safe ffmpeg fixture rename; Stills test Unix-gated; SonarCloud workflow, Dependabot, HTTPS-only curl downloads, README app icon, Linux packaging tweak, version bump | `.github/workflows/sonarcloud.yml`; `crates/media/tests/footage.rs:40-50`; `crates/engine/src/doc_path/tests.rs:34-38`; `README.md`; `Cargo.toml` |

## Corrections and deeper coverage vs the previous (v0.14.0) skill

| Previous claim | What the v0.15.0 code shows | Evidence |
|---|---|---|
| Control channel has 23 methods | **24** dispatch arms. The old text listed 24 names but miscounted; `control.rs` is unchanged between the tags | `crates/ui-egui/src/control.rs:172-460` |
| Panel catalogs in 6 languages | **7** — `i18n/ui.rs` has a Spanish catalog too, and it existed at v0.14.0 (the old skill undercounted; `docs/gaps.md` is stale) | `crates/ui-egui/src/i18n/ui.rs:43-60,3886` |
| "Everything the UI does is an engine command" | Two tiers: **669 engine ids** run headless; **111 UI-only ids** (`tool.*`, `view.*`, `window.*`, `playback.*`, `timeline.*`, `app.*`) dispatch only in the live app via `ui.menu.invoke`/`engine.execute` fallback | `crates/ui-egui/src/menus.rs:29,312-332`; `crates/ui-egui/src/control.rs:176-188` |
| Content-Aware Fill, Auto-trace and Scene Edit Detection are background jobs | Content-Aware Fill and Scene Edit Detection spawn background tasks with `wait`; **Auto-trace is synchronous** (`layer.autoTrace`) | `crates/engine/src/commands/autotrace.rs:72-202`; `content_fill.rs:299-309`; `scene_detect.rs:104-105` |
| Scripts may read files only in the project's folder | Reads are allowed under the **script's own folder** and the project's folder; other reads, writes and network need Settings ▸ Scripting & Expressions ▸ Allow Scripts to Write Files and Access Network | `crates/script/src/scriptfile.rs:39-49`; `crates/script/src/runtime.rs:364-380` |
| Single-frame output is layered PSD | Also **multi-layer OpenEXR (ProEXR)**: composite R,G,B,A plus `<layer>.R/G/B/A` per layer | `crates/engine/src/commands/frame_export.rs:220-240`; `crates/engine/src/menus.rs:706-709` |
| CLI flags under-listed | `props` also accepts `--depth`; `exec --list`, `--schemas`, `--filter`, `--enabled`, `--flat` exist; `render-frame` also has `frame` as an alias | `apps/effectcraft-cli/src/main.rs:94-192,500-620` |
| 307 effects vs README 306 | Still 307; the generated doc and `app.capabilities` are the source of truth | `docs/effects.md:6`; `crates/engine/src/commands/query.rs:187-202` |
| 0.14.0 stability | v0.15.0 fixes specific crash/panic classes (above) but the 12 Oct audit still lists the six open crash reports; do not treat 0.15.0 as a stability guarantee | `docs/gaps.md` gap 3; changes table above |

## Docs-vs-code discrepancies at this tag

| Claim in docs | What the code shows | Evidence |
|---|---|---|
| `README.md` and `docs/gaps.md` say 306 effects (also `docs/hardware-parity.md` "280 of 306" and `docs/architecture.md` "306 effects") | Registry, generated `docs/effects.md` and `app.capabilities` report **307** | `README.md:23,129,231`; `docs/gaps.md:34`; `docs/effects.md:6`; `crates/engine/src/commands/query.rs:187,202` |
| `docs/target-app-parity.md` says "411 registered engine commands" (measured at `origin/main` 1446e27, 10 Oct 2026) | The registry has **669**; 111 more UI-only ids exist separately | `docs/target-app-parity.md:72`; `crates/engine/src/commands/mod.rs:155-235`; `crates/ui-egui/src/menus.rs:29` |
| `docs/gaps.md` gap 16 says panel catalogs in 6 languages | **7** catalogs (ja, zh-hans, zh-hant, uk, pt-br, cs, es) | `docs/gaps.md:75`; `crates/ui-egui/src/i18n/ui.rs:43-60` |
| `docs/gaps.md` gap 18 says "no relink when a project moves" | `footage.relink`, `file.relinkFootage`, `footage.missing` and moved-project candidate search exist; relative paths resolve against the project folder on open | `crates/engine/src/commands/relink.rs`; `relink_moved.rs`; `crates/engine/src/doc_path.rs:1-8,127` |
| `docs/file-format-parity.md` native `.ecproj` row says "absolute footage paths, no relinking (gap 18)" | Stale for the same reason: relinking and relative-path resolution exist | `docs/file-format-parity.md:34`; evidence above |
| Bundle declares a QOI image type | `STILL_EXTENSIONS` has no `qoi`; no import path references it | `packaging/macos/Info.plist.in:110-123`; `crates/media/src/lib.rs:62-63` |
| `docs/target-app-parity.md` / `docs/gaps.md` are dated 10–13 Oct 2026, before this tag | Counts, issue numbers and crash lists are snapshots; re-check the runtime/registry before quoting them | `docs/gaps.md:3`; `docs/target-app-parity.md:71-75` |
| `docs/effects.md` header says 3032 parameters while its table sums to 2984 | Not a bug: the header counts all params (`e.params.len()`), the table omits `ParamUi::Hidden` ones | `crates/effects/src/catalog.rs:130-160` |
| No CI gate on PRs | Still no `cargo xtask ci` workflow; SonarCloud static analysis was added in 0.15.0 | `.github/workflows/`; `docs/gaps.md` gap 4 |

## Environment checks

| Check | Result | Evidence |
|---|---|---|
| Installed version / build | 0.15.0, commit `15b8a916c528e73d48f7a9cb4ff58276c7a2d3dd` | `/Applications/EffectCraft.app/Contents/Info.plist` (`CFBundleShortVersionString`, `EffectCraftBuildCommit`) |
| Bundle id / architecture / minimum OS | `ai.storyteller.effectcraft`; universal `x86_64`+`arm64`; macOS 11.0 | `Info.plist` (`CFBundleIdentifier`, `LSMinimumSystemVersion`); `lipo -archs` on the binary |
| Binary version text | `effectcraft 0.15.0` | `/Applications/EffectCraft.app/Contents/MacOS/EffectCraft --version` (exits before a window) |
| CLI inside the bundle | absent — only `EffectCraft` in `Contents/MacOS` | bundle listing; `docs/agents.md` §From an installed release |
| GUI launched during authoring | no | — |
| Worktree built or modified | no | `git status --short` empty; no build commands run |

## What was not verified live

- **No render, no GUI and no `effectcraft-cli` run.** The macOS bundle ships no CLI and nothing was
  built, so CLI/MCP/control behavior above is read from source, tests and docs, not exercised.
- **No After Effects comparison.** Fidelity, AE-format compatibility and issue-tracker state are
  taken from the repository's dated docs (`docs/gaps.md`, `docs/fidelity/README.md`), not measured.
- **No real media round-trip.** Codec/format limits are from the registry, encoder options and
  `docs/file-format-parity.md`; they were not tested against sample files.

## How to spot-check

```sh
git rev-parse HEAD
git describe --tags --exact-match HEAD

rg -n "pub const SCHEMA_VERSION" crates/project/src/lib.rs              # 2
rg -n "pub const ALL: \[OutputFormat; 13\]" crates/project/src/render_queue.rs
rg -n "pub const ALL: \[BlendMode; 38\]" crates/color/src/blend.rs
rg -n "pub const STYLES" crates/project/src/styles.rs                   # 9 entries
rg -n "const CATALOG_CODES" crates/ui-egui/src/i18n.rs                  # 10 menu languages

python3 - <<'EOF'
import re, pathlib
ids = []
for p in pathlib.Path("crates").rglob("*.rs"):
    ids += re.findall(r'\b(?:cmd|query)!\(\s*"([^"]+)"', p.read_text(errors="ignore"))
print("engine commands:", len(ids), "unique:", len(set(ids)))     # 669 / 669
ui = open("crates/ui-egui/src/menus.rs").read()
print("UI-only ids:", len(set(re.findall(r'uic!\(\s*"([^"]+)"', ui))))  # 111
EOF

python3 - <<'EOF'
import re
t = open("crates/automation/src/tools.rs").read()
block = t[t.index("static TOOLS"):]
print("MCP tools:", len(re.findall(r'ToolDef \{\s*name: "', block)))   # 36
print("bridge-only:", len(re.findall(r"bridge_only: true", block)))     # 9
EOF

python3 - <<'EOF'
import re
h = open("crates/ui-egui/src/control.rs").read()
h = h[h.index("pub fn handle"):]
lines = [l for l in h.splitlines() if re.match(r'^\s{8}"(engine|ui|render|app)\.', l)]
print("control methods:", sum(len(re.findall(r'"(?:engine|ui|render|app)\.[a-z.]+"', l)) for l in lines))  # 24
EOF

python3 - <<'EOF'
import json
for f in ("backgrounds", "text_animators", "transitions"):
    print(f, len(json.load(open(f"crates/engine/presets/{f}.json"))["presets"]))  # 23 8 23
EOF

rg -n "306 effects|411 registered|panel catalogs|no relink|qoi" README.md docs/*.md packaging/macos/Info.plist.in | head
```

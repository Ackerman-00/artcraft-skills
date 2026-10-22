# EffectCraft — evidence table

Checkout: `storytold/effectcraft` at tag `v0.14.0`, commit
`26b40199b72121aa7f4e55a63718e1b4dd48a859` (inspected 2026-10-22). Installed bundle
`ai.storyteller.effectcraft` reports version 0.14.0 and the same `EffectCraftBuildCommit`; its
`Contents/MacOS` holds only the app binary (no CLI). No GUI was launched.

Tiers: **implemented** = code path exists and is wired into UI/CLI/commands; **partial** = exists
with named limits; **claimed** = docs/README say it but code could not be found; **not
implemented** = no code path.

| # | Capability claim | Evidence | Tier |
|---:|---|---|---|
| 1 | Native project `.ecproj` is versioned JSON (schema 2) with `savedBy`, `activeComp`/`openComps`/`compTimes`, items, render queue; save validates by re-reading and writes atomically; newer schema refused on open | `crates/project/src/lib.rs:34,1363-1381,1540-1567`; `crates/engine/src/lib.rs:144`; `crates/engine/src/commands/file.rs:49-52,86-91` | implemented |
| 2 | `.ecprojx` is a lossless XML copy of the project; opened like `.ecproj`; a project opened from XML saves as XML again | `crates/engine/src/xml_project.rs`; `crates/engine/src/commands/file.rs:45-48,86-91` | implemented |
| 3 | Autosave, crash recovery, MCP `--autosave` checkpoints, and open-time repair of out-of-range project values (size ≤ 30,000 px, fps 0.001–1000, pixel aspect 0.1–10) | `crates/engine/src/autosave.rs`; `docs/preferences.md`; `crates/project/src/limits.rs:16-25`; `crates/engine/src/commands/file.rs:57-65`; `docs/agents.md` §Keeping headless work | implemented |
| 4 | Render Queue writes 13 formats: H.264, HEVC, AV1, ProRes, uncompressed MOV, WebM, PNG/JPEG/TIFF/EXR sequences, GIF, WAV, AIFF | `crates/project/src/render_queue.rs:501-545` (`OutputFormat::ALL` = 13) | implemented |
| 5 | Single-frame layered PSD output (Composition ▸ Save Frame As ▸ Photoshop Layers) via the `effectcraft-psd` writer | `crates/engine/src/commands/frame_export.rs:1-4,224` | implemented |
| 6 | Lottie import/export for `.json` and `.lottie`, with a warnings list for inexpressible features | `crates/engine/src/commands/lottie.rs:24-51`; `crates/lottie/src/lib.rs` | implemented |
| 7 | Timeline interchange in FCP7 XML, FCPXML, OTIO, EDL, AAF and OMF; native `.prproj` explicitly rejected; optional ProRes 4444 pre-render (`prerender: none|unsupported|all`) | `crates/interchange/src/lib.rs:1-18`; `crates/engine/src/commands/timeline.rs:143-148` | implemented (pre-render fidelity depends on `prerender`) |
| 8 | 307 registered effects, 3032 parameters, 280 GPU-capable, all 32-bit float, 21 categories, 0 marked partial; `app.capabilities` reports the same | `docs/effects.md:6-10` (generated from the registry by `effects_doc_is_current`); `crates/effects/src/lib.rs:485-529`; `crates/effects/src/catalog.rs:9` (`PARTIAL` empty); `crates/engine/src/commands/query.rs:181-202` | implemented |
| 9 | 38 blend modes and 9 Layer Styles plus Blending Options/Global Light | `crates/color/src/blend.rs:9-52` (38 variants); `crates/project/src/styles.rs:28-40` | implemented |
| 10 | Layer kinds and 3D: footage, precomp, solid, text, shape, null, camera, light, 3D model, primitive; Classic 3D and Advanced 3D renderers; Parallel/Spot/Point/Ambient/Environment lights | `crates/project/src/lib.rs`; `crates/gpu/src/lib.rs:1-12`; `docs/agents.md` §Pitfalls (Environment light) | implemented |
| 11 | Keyframes (linear/Bezier/hold, ease/velocity, roving), Graph Editor, time remap/stretch/reverse/freeze | `crates/keyframe/src/lib.rs`; `crates/engine/src/commands/prop.rs:1364-1384`; `crates/engine/src/commands/layer_time.rs:253` | implemented |
| 12 | JavaScript expressions with the AE object model (incl. `propertyGroup`, text style API), and `.jsx`/`.js` scripting with ScriptUI panels, `Socket`, `$.evalFile`, `#include`, `app.scheduleTask` | `crates/expr/src/lib.rs`; `crates/script/src/lib.rs`; `docs/scripting-parity.md` | implemented; partial vs AE (no `.jsxbin`, startup/shutdown scripts, script shortcuts) |
| 13 | Motion/mask/face tracking, Warp Stabilizer, 3D Camera Tracker, Roto Brush (MobileSAM optional), Object Matte, Content-Aware Fill, Auto-trace, Scene Edit Detection, Paint/Liquify/Puppet | `crates/engine/src/commands/{track,warp_cmds,camera_cmds,roto_cmds,content_fill,autotrace,scene_detect,paint,liquify,puppet}.rs`; `crates/effects/src/{roto,object_matte,face_track,warp_stab,camera_tracker}.rs` | implemented (AE fidelity unmeasured) |
| 14 | GPU compositor on wgpu (Metal/Vulkan/Direct3D 12/WebGPU); CPU reference; app defaults to GPU, headless CLI to CPU unless `--gpu` | `crates/gpu/src/lib.rs:1-3`; `apps/effectcraft-cli/src/main.rs` (USAGE); `docs/architecture.md` | implemented |
| 15 | CLI with 12 subcommands (`info commands exec run props get set render-frame render bench script mcp`), JSON output, headless by default; `--progress` for render; per-codec encoder flags; `--automation-read-root`/`--automation-write-root` for MCP | `apps/effectcraft-cli/src/main.rs:87-127,162-192`; `docs/mcp.md` | implemented |
| 16 | MCP server with 36 tools (27 headless, 9 bridge-only: `screenshot`, `ui_click/ui_drag/ui_elements/ui_inspect/ui_key/ui_set/ui_type`, `control`) and two resources; render progress notifications and cancellation | `crates/automation/src/tools.rs` (36 `ToolDef`s, 9 `bridge_only: true`); `docs/mcp.md` | implemented |
| 17 | Localhost JSON control channel for the live UI: 23 methods incl. `engine.execute`, `ui.menu.invoke`, `render.frame`, `ui.inspect/elements/set/click/move/drag/scroll/key/type/screenshot/resize/focus/playback`, `ui.panel.show/close`, `ui.viewer.locate/hit`, `ui.timeline.locate`, `app.quit`; no authentication, ≤ 16 connections, 60 s timeout | `crates/ui-egui/src/control.rs:176-458`; `docs/control-protocol.md` | implemented |
| 18 | WebAssembly build with OPFS/IndexedDB storage and `window.effectcraft` (`execute`, `request`, `renderFrame`, `screenshot`, `addFile`, `files`, `readFile`, `saveToBrowser`, `listStored`, `flush`, `info`) | `apps/effectcraft-web`; `docs/web.md:380-407,483-492` | implemented (not the installed macOS app) |
| 19 | Import registry: stills `png jpg jpeg gif webp tif tiff bmp exr tga hdr psd psb svg pdf ai eps`; video `mp4 m4v mov mkv webm mxf`; models `gltf glb obj stl fbx`; audio from FilmCraft (`wav wave bwf aif aiff mp3 mp2 m4a aac flac ogg opus`); DPX/Cineon; data `json csv tsv` | `crates/media/src/lib.rs:61-70`; `crates/media/src/dpx.rs`; `crates/engine/src/commands/file.rs:559` | implemented (named per-format caveats in `docs/file-format-parity.md`) |
| 20 | `.aep` / `.aepx` / `.mogrt` / `.ffx` / AE SDK plug-ins / `.prproj` import | `README.md` (proprietary formats not supported); `docs/file-format-parity.md:21-34`; `docs/gaps.md` gap 1; no reader found by search over `crates/` and `apps/` | **not implemented** |
| 21 | Hardware video decode/encode and pro output formats (16-bpc, AVI, MXF output, DNxHR, DPX/TGA/PSD sequences, ProRes RAW) | `docs/gaps.md` gaps 15/17/22; `docs/file-format-parity.md` | **not implemented** (pure-Rust encoders only; AVI listed in Media Browser without a demuxer) |
| 22 | 54 built-in animation presets (8 text animators, 23 backgrounds, 23 transitions) vs AE's 621 `.ffx` | `crates/engine/presets/{backgrounds,text_animators,transitions}.json` (23+8+23 counted); `docs/gaps.md` gap 7 | implemented (breadth gap acknowledged) |
| 23 | Variable fonts: `text.fonts` lists families/styles/`variable`, named instances by PostScript name, per-axis `variations`, `EFFECTCRAFT_FONT_DIRS` | `crates/text/src/fonts.rs`, `variable.rs`, `font_dirs.rs`; `docs/agents.md` §Text | implemented |
| 24 | Menus localized in 10 languages (ja, zh-hans, zh-hant, uk, es, pt-br, ru, fr, de, cs); panels in 6 | `crates/ui-egui/src/i18n.rs:16` (`CATALOG_CODES`); `docs/gaps.md` gap 16 | implemented (partial depth; Korean/Italian absent) |

## Docs-vs-code discrepancies at this tag

| Claim in docs | What the code shows | Evidence |
|---|---|---|
| `docs/gaps.md` gap 18: "no relink when a project moves" | `footage.relink`, `file.relinkFootage`, and automatic moved-project candidate search exist | `crates/engine/src/commands/relink_moved.rs`; `relink.rs` |
| `README.md` advertises 306 effects (three places) | Generated `docs/effects.md` and `app.capabilities` report 307 | `README.md`; `docs/effects.md:6`; `crates/engine/src/commands/query.rs:187,202`; `crates/effects/src/lib.rs:485-529` |
| Bundle declares a QOI image type | `STILL_EXTENSIONS` does not include `qoi`; no code path references it | `packaging/macos/Info.plist.in:112-123`; `crates/media/src/lib.rs:61-63` |
| `docs/gaps.md` dimension table says "All 306 effects" | Registry count is 307 | `docs/gaps.md` (breadth row); `docs/effects.md:6` |
| `docs/preferences.md` shows `general.language` with 8 choices | `CATALOG_CODES` has 10 languages (adds ru, fr, de, cs) | `docs/preferences.md`; `crates/ui-egui/src/i18n.rs:16` (uncertain which surface is stale — runtime `prefs.pages` is the arbiter) |

## Changes verified between v0.11.1 (previous skill pin) and v0.14.0

`git diff --stat v0.11.1 v0.14.0`: 133 files, +7016/−504 (only the squashed release commits are
visible in this shallow worktree, so per-feature attribution is from the diff, not per-PR history).

- Unchanged counts, re-verified from code: effects 307/3032/280 GPU/21 categories/0 partial;
  render formats 13; blend modes 38; layer styles 9; presets 54; MCP tools 36/27/9; CLI
  subcommands 12.
- CLI: `--progress` (render progress on stderr) is the one new option vs v0.11.1
  (`git diff v0.11.1 v0.14.0 -- apps/effectcraft-cli/src/main.rs`). The per-codec render flags and
  `script --eval` already existed in v0.11.1; the old skill under-listed them.
- Control channel: the full 23-method surface (incl. `ui.move`, `ui.scroll`, `ui.panel.*`,
  `ui.screenshot`, `ui.resize`, `ui.focus`, `ui.viewer.*`, `ui.timeline.locate`, workspaces) was
  already in v0.11.1 — no new method strings in the diff; the old skill under-documented it.
- Grew between the pins (diff hotspots): text/fonts (variable-font instances, `text.fonts`
  `variable`/`rescan`, `crates/text/src/{fonts,font_dirs,sfnt}.rs`), localization (panel
  catalogs `crates/ui-egui/src/i18n/ui.rs`), 3D model import (`crates/model/src/{fbx,gltf}.rs`),
  media probe, text range-selector handles in the viewer, GPU advanced-3D shading, scripting
  socket/match names, `prefs.rs` (window graphics fallback, idle caching).
- Both tags ship the same docs drift (README 306 vs registry 307; gap 18 relinking; QOI).

## Environment checks

| Check | Result | Evidence |
|---|---|---|
| Installed version / build | 0.14.0, commit `26b40199b72121aa7f4e55a63718e1b4dd48a859` | `/Applications/EffectCraft.app/Contents/Info.plist` (`CFBundleShortVersionString`, `EffectCraftBuildCommit`) |
| Architecture / minimum OS | universal `x86_64` + `arm64`; macOS 11.0 | `lipo -archs` on `Contents/MacOS/EffectCraft`; `LSMinimumSystemVersion` |
| CLI inside the bundle | absent — only `EffectCraft` in `Contents/MacOS`; no `effectcraft-cli` on `PATH` | bundle listing; `docs/agents.md` macOS row |
| GUI launched during authoring | no | — |

## How to spot-check

```sh
git rev-parse HEAD                 # 26b40199b72121aa7f4e55a63718e1b4dd48a859
rg -n "pub const SCHEMA_VERSION" crates/project/src/lib.rs          # 2
rg -n "pub const ALL: \[OutputFormat; 13\]" crates/project/src/render_queue.rs
rg -n "ships .* effects" docs/effects.md                            # 307 / 3032
rg -c 'ToolDef \{' crates/automation/src/tools.rs                   # 38 ToolDef literals incl. helper (36 listed tools)
rg -n "CATALOG_CODES" crates/ui-egui/src/i18n.rs                    # 10 languages
python3 - <<'EOF'
import json
for f in ("backgrounds","text_animators","transitions"):
    print(f, len(json.load(open(f"crates/engine/presets/{f}.json"))["presets"]))
EOF
awk '/pub enum BlendMode/,/^}/' crates/color/src/blend.rs | grep -cE '^\s+[A-Z][A-Za-z0-9]*,'   # 38
rg -n "aep|aepx|mogrt|ffx" crates apps --glob '!**/tests/**' | rg -i "import|open" | head
```

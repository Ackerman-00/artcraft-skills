---
name: effectcraft
description: >-
  EffectCraft is an open-source, pure-Rust motion-graphics, compositing and VFX app for macOS,
  Windows, Linux and the web — a clean-room, After Effects-shaped studio with compositions,
  layers, keyframes, 307 effects, expressions, Classic/Advanced 3D, tracking, roto, a render queue
  and Lottie, driven by a CLI, an MCP server, a localhost JSON control channel and JavaScript
  scripting. Trigger this skill whenever the user mentions EffectCraft, `.ecproj`/`.ecprojx`/
  `.ectemplate`/`.ecpreset`, `effectcraft-cli`, its MCP tools or control channel; asks what it can
  or cannot do, which formats/shortcuts it has, or how to script, batch, render, verify, repair or
  troubleshoot it; or describes the job without naming the app ("make a title card", "animate this
  logo", "key this green screen", "render a ProRes", "export Lottie", "open this .aep"). Also use
  it when choosing between EffectCraft and FilmCraft, or preparing/verifying assets for it. Do not
  assume After Effects project files open: they do not.
---

# EffectCraft

Audit basis: this checkout is tag `v0.15.0`, commit `15b8a916c528e73d48f7a9cb4ff58276c7a2d3dd`. The installed `/Applications/EffectCraft.app` reports version `0.15.0` and its binary prints `effectcraft 0.15.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. No `references/` directory ships with this skill: every claim is cited inline to the repository.

## Overview

EffectCraft is a free, open-source, clean-room reimplementation of Adobe After Effects 2026 for motion graphics and visual effects: compositions, layers, keyframes, 307 effects, layer styles, expressions, Classic and Advanced 3D, tracking, roto/paint, a render queue and Lottie/timeline interchange. It is pure Rust with no FFmpeg; media codecs come from the sibling FilmCraft project, pinned by revision (`Cargo.toml`). It is **alpha**: the repo self-rates ≈91% feature breadth but ≈45% "ready for real work" (`docs/gaps.md:15-28`, `docs/target-app-parity.md`, `crates/engine/src/commands/query.rs:202`). FilmCraft is the editing/NLE sibling; EffectCraft is the compositor. Source: GitHub `storytold/effectcraft`, MIT OR Apache-2.0.

`v0.15.0` is a hardening release, not a feature release: `git diff v0.14.0 v0.15.0` touches 19 files (+280/−51) and adds no command, MCP tool, control method, format or shortcut. It fixes a precomp-cycle stack overflow (#1237), a NaN shape-path panic, a `sampleImage` integer overflow, feather points on the first vertex, a tiny-negative-hue HSV bug, and makes script array setters reject wrong dimensions like After Effects does (`crates/project/src/lib.rs:1478`, `crates/path/src/lib.rs:133`, `crates/expr/src/sample.rs:99`, `crates/keyframe/src/value.rs:82`, `crates/script/src/prelude.js:869`).

## Capabilities (verified)

### Project and document model

- **Native `.ecproj`** is versioned, pretty-printed JSON headed by `savedBy` and `schema` (currently 2), with `activeComp`/`openComps`/`compTimes`, `settings`, `items`, `nextId`, `renderQueue`, render templates and preferences (`crates/project/src/lib.rs:34,59,1549-1567`). Saving re-reads the text before writing and writes atomically, so a save cannot produce a file the app cannot open (`crates/project/src/lib.rs:1545-1563`, `crates/engine/src/lib.rs:144`).
- **XML project copy `.ecprojx`** is the same data as `EffectCraftProject` XML (lossless, element-per-value, nesting capped at 128); Save a Copy As XML writes it, `file.open` reads it back, and a project opened from XML saves as XML again (`crates/engine/src/xml_project.rs`, `crates/engine/src/commands/file.rs:43-91`).
- **Autosave, crash recovery and MCP checkpoints**; `mcp --autosave` writes a checkpoint after each mutating call (`crates/engine/src/autosave.rs`, `docs/agents.md` §Keeping headless work). Out-of-range values (size > 30,000 px, frame rate outside 0.001–1000, pixel aspect outside 0.1–10) are repaired on open and reported, not rejected (`crates/project/src/limits.rs:16-25`, `crates/engine/src/commands/file.rs:49-65`).
- **One project per app process**, with compositions open as tabs restored from `openComps`; 34 panel kinds and 15 named workspaces, and any panel can move to its own native window (`crates/ui-egui/src/dock.rs:14-58,281-297`, `crates/ui-egui/src/menus.rs:523-532`, `docs/architecture.md` §3).

### Composition, animation, expressions

- **Compositions** use exact integer `Tick` time at 254,016,000,000 ticks/s; `comp.new` defaults to 1920×1080, 29.97 fps, 10 s, and accepts `renderer: classic3D|advanced3D` (`crates/time/src/lib.rs:1-22`, `crates/engine/src/commands/comp.rs:101-112`). Every AE layer kind exists: footage, precomp, solid, text, shape, null, camera, light, 3D model, parametric primitive; adjustment layers are solids with the adjustment switch (`crates/project/src/lib.rs:667-724,765`). Parenting, track mattes, all **38 blend modes** and motion blur are in the document model (`crates/color/src/blend.rs:9-52`).
- **Keyframes**: linear/Bezier/hold, per-side speed and influence (Easy Ease), auto/continuous Bezier, roving keys, Keyframe Velocity/Interpolation, and a Graph Editor with value and speed graphs (`crates/keyframe/src/lib.rs:60-120`, `crates/engine/src/commands/prop.rs:1364-1384`). Time remap/stretch/reverse/freeze are `layer.*` commands (`crates/engine/src/commands/layer_time.rs:253`).
- **Expressions** run on `boa` with the AE object model (`thisComp`, `wiggle`, `loopOut`, `valueAtTime`, `sampleImage`, `propertyGroup`, text style API) and AE legacy array maths (`crates/expr/src/lib.rs`, `docs/scripting-parity.md`).

### Effects, text, shapes, masks

- **307 registered effects**, 3032 parameters, 280 GPU-capable, all 32-bit float, 21 categories, 0 marked partial, plus 9 Layer Styles with Global Light (`docs/effects.md:6-10`, generated from `crates/effects/src/lib.rs:485-529` and checked by `effects_doc_is_current`; `crates/project/src/styles.rs:28-40`). The README's "306" is one behind the registry (`README.md:23,129,231`).
- **54 built-in animation presets** (8 text animators, 23 backgrounds, 23 transitions) and `.ecpreset` save/apply (`crates/engine/presets/*.json`, `docs/gaps.md` gap 7).
- **Text, shapes and masks**: point/paragraph text with style runs, variable fonts (named instances by PostScript name, per-axis `variations`), text animators; shape operators (trim, repeater, round corners, offset, zig zag, twist, wiggle, merge, gradient stroke); masks with 7 modes, feather, expansion, vertex editing and Mask Interpolation (`crates/engine/src/commands/{text_edit,text_anim,mask,mask_interp,paths}.rs`, `crates/project/src/build.rs:493-598`, `crates/project/src/props.rs:217-243`, `crates/text/src/fonts.rs:57-63`).

### 3D, tracking, roto and paint

- **Classic 3D and Advanced 3D**: 3D layers, one/two-node cameras with depth of field, Parallel/Spot/Point/Ambient/Environment lights, ray-cast shadows; Advanced 3D adds PBR materials, six primitives (cube, sphere, plane, torus, cone, cylinder), imported models and environment lighting (`crates/gpu/src/lib.rs:1-12`, `crates/engine/src/commands/model3d.rs:384-397`, `docs/agents.md` §Pitfalls — Environment light).
- **Tracking**: point/transform tracking, stabilize, affine/perspective corner-pin tracks, mask tracking including face outline/detailed features, Warp Stabilizer, and a 3D Camera Tracker that creates cameras, solids, nulls, text and shadow catchers (`crates/engine/src/commands/{track,warp_cmds,camera_cmds,mask_interp}.rs`).
- **Roto Brush and Object Matte**: stroke/propagate/freeze with optional MobileSAM or classical fallback; `objectMatte.apply/propagate/freeze` for click/box segmentation with disk-cached mattes; face tracking with optional MediaPipe Face Landmarker. Paint strokes/clone source, Liquify and all five puppet pin kinds are commands too (`crates/engine/src/commands/{roto_cmds,paint,liquify,puppet}.rs`, `crates/effects/src/{roto,object_matte,face_track}.rs`). **Content-Aware Fill and Scene Edit Detection** run as background jobs with `wait`; **Auto-trace** is a synchronous command (`crates/engine/src/commands/{content_fill,autotrace,scene_detect}.rs`).

### Import formats (only what the code registers)

| Kind | Extensions / route | Evidence |
|---|---|---|
| Stills | `png jpg jpeg gif webp tif tiff bmp exr tga hdr psd psb svg pdf ai eps` (animated WebP as footage) | `crates/media/src/lib.rs:62-63` |
| Film scans | `dpx cin` (8/10/12/16-bit; log shown as stored) | `crates/media/src/dpx.rs:1-20` |
| Video | `mp4 m4v mov mkv webm mxf`; H.264, HEVC, VP9, AV1, ProRes, DNxHD, MPEG-2, MJPEG; MXF OP1a/OP-Atom | `crates/media/src/lib.rs:67`, `docs/file-format-parity.md` |
| Audio | `wav wave bwf aif aiff mp3 mp2 m4a aac flac ogg opus` (FilmCraft `AUDIO_EXTENSIONS`) | `crates/media/src/lib.rs:65` |
| 3D models | `gltf glb obj stl fbx` (glTF: meshes/PBR/skins/animations; FBX 7.x: meshes/materials only) | `crates/media/src/lib.rs:70`, `crates/model/src/fbx.rs:1-19` |
| Data | `json csv tsv` as data footage (plain `file.import`; Lottie needs `file.importLottie`) | `crates/engine/src/commands/file.rs:558-564` |
| Lottie | `.json`, `.lottie` via `file.importLottie` | `crates/engine/src/commands/lottie.rs:29-65` |
| Timelines | `.xml` (FCP7), `.fcpxml`, `.otio`, `.edl`, `.aaf`, `.omf` | `crates/interchange/src/lib.rs:1-18` |
| Color / fonts | LUTs `.cube .3dl .csp .spi1d/.spi3d`, CDL; bundled + installed fonts, `EFFECTCRAFT_FONT_DIRS`, variable fonts via `text.fonts` | `docs/file-format-parity.md:93`, `crates/text/src/font_dirs.rs` |

`.json` through plain `file.import` is **data footage**, not Lottie — use `file.importLottie`. PSD/PDF/AI/EPS import as footage or as a composition (`importAs`); PSD groups become precomps, text becomes editable, effects map best-effort to Layer Styles (`crates/engine/src/psd_import.rs:1-12`, `crates/engine/src/commands/file.rs:334-355`).

### Export formats

The Render Queue writes **13 formats** (`crates/project/src/render_queue.rs:531-545`):

| Family | Formats |
|---|---|
| Video | H.264 MP4 (+AAC), HEVC MP4 (`hvc1`, Main/Main 10), AV1 MP4 (`av01`), ProRes MOV (Proxy→4444 XQ; 4444 with alpha), uncompressed 8-bit MOV, WebM (VP9 or AV1 + Opus) |
| Stills | PNG, JPEG, TIFF, OpenEXR (32-bit float) sequences; animated GIF |
| Audio | WAV, AIFF (16-bit PCM) |

Render Settings/Output Modules cover quality, resolution, time span, frame rate, proxy use, effects/solo/guide/depth overrides, colour depth, field rendering + 3:2 pulldown, motion blur, frame blending, skip existing frames, storage overflow, crop/ROI/resize, extra outputs, post-render actions and logs (`crates/project/src/render_queue.rs:324-382,1027-1065`).

- **Single frames** also export as a layered PSD (Composition ▸ Save Frame As ▸ Photoshop Layers) or a multi-layer OpenEXR (ProEXR) (`crates/engine/src/commands/frame_export.rs:220-240`).
- **Lottie** `.json`/`.lottie` with a `warnings` list for what Lottie cannot express (`crates/engine/src/commands/lottie.rs:24-51`, `crates/lottie/src/lib.rs`).
- **Timeline interchange** `.xml` (FCP7 default), `.fcpxml`, `.otio`, `.edl`, `.aaf`, `.omf`; `prerender: none|unsupported|all` chooses what becomes ProRes 4444 media instead of clips (`crates/engine/src/commands/timeline.rs:143-159`, `crates/interchange/src/export.rs:19-39`).
- **Essential Graphics template `.ectemplate`** is a ZIP (`manifest.json`, `project.ecproj`, `media/`, `poster.png`); **animation preset `.ecpreset`** is JSON tagged `effectcraftAnimationPreset` (`crates/engine/src/commands/essential.rs:8-12,860-870`, `crates/engine/src/commands/animation.rs:16-17`).

### Automation and platform

- **CLI** `effectcraft-cli`: 12 subcommands (`info commands exec run props get set render-frame render bench script mcp`) with `--json`, `--project`, `--demo`, `--empty`, `--save`, `--save-as`, `--bridge`, `--gpu`, per-codec render flags, `--queue` and `--progress` (`apps/effectcraft-cli/src/main.rs:94-160`).
- **MCP** over stdio: **36 tools** — 27 headless and 9 bridge-only (`screenshot`, `ui_inspect`, `ui_elements`, `ui_click`, `ui_drag`, `ui_key`, `ui_type`, `ui_set`, `control`) — plus `effectcraft://document` and `effectcraft://commands`; render progress notifications and cancellation (`crates/automation/src/tools.rs:542`, `crates/automation/src/server.rs:14,224-233`, `docs/mcp.md`).
- **Control channel**: `effectcraft --control <port>` (or `EFFECTCRAFT_CONTROL_PORT`) speaks newline JSON on `127.0.0.1`: **24 dispatch methods** including `engine.execute`, `ui.menu.invoke`, `engine.commands`, `ui.menu.list`, `render.frame`, `ui.inspect/elements/set/screenshot/click/move/drag/scroll/key/type`, `ui.panel.show/close`, `ui.playback`, `ui.resize`, `ui.focus`, `ui.viewer.locate/hit`, `ui.timeline.locate`, `app.quit` (`crates/ui-egui/src/control.rs:172-460`, `docs/control-protocol.md`).
- **Two command tiers**: 669 engine command ids (`crates/engine/src/commands/mod.rs:155-235`) plus 111 UI-only ids (`tool.*`, `view.*`, `window.*`, `playback.*`, `timeline.*`, `app.*`) in `crates/ui-egui/src/menus.rs:29`; the live app dispatches UI-only ids through `ui.menu.invoke`/`engine.execute`, while headless CLI/MCP can run only the 669 engine ids.
- **Scripts/ScriptUI**: `.jsx`/`.js` with the AE object model (`app.project`, match names, `Socket`, `$.evalFile`, `#include`, `app.scheduleTask`), dockable ScriptUI panels that reopen at launch; `script.run`, `file.runScript`, CLI `script FILE.jsx` and `script --eval CODE` (`docs/plugins.md`, `docs/scripting-parity.md`, `crates/script/src/lib.rs`).
- **WebAssembly effect plug-ins**: `.wasm`/`.wat`, API v1, sandboxed in `wasmi` with no imports; the settings `Plug-ins` folder loads at startup (`crates/plugin/src/lib.rs`, `apps/effectcraft/src/main.rs:235-238`, `docs/plugins.md` §Effect plug-ins).
- **Web build** (`apps/effectcraft-web`) runs the same engine/UI as WASM with OPFS/IndexedDB storage and `window.effectcraft` (`request`, `execute`, `commands`, `inspect`, `renderFrame`, `screenshot`, `addFile`, `files`, `readFile`, `saveToBrowser`, `listStored`, `removeStored`, `flush`, `info`, `workerFrameCheck`); it is not the installed macOS app (`docs/web.md:380-407`).
- **GPU**: a wgpu compute compositor for Metal/Vulkan/Direct3D 12/WebGPU (Direct3D 12 is reported failing on some Windows GPUs, `docs/hardware-parity.md`, #613); CPU is the reference, the desktop uses the GPU by default when available, headless CLI/MCP use the CPU unless `--gpu` (`crates/gpu/src/lib.rs:1-3`, `crates/project/src/lib.rs:254-257`, `apps/effectcraft-cli/src/main.rs:344-350`).
- **Localization**: menus in 10 languages (ja, zh-hans, zh-hant, uk, es, pt-br, ru, fr, de, cs); panel/tooltip catalogs in 7 (ja, zh-hans, zh-hant, uk, es, pt-br, cs) (`crates/ui-egui/src/i18n.rs:16`, `crates/ui-egui/src/i18n/ui.rs:43-60`).

## Known limitations and not-implemented

- **After Effects projects will not open.** No `.aep`/`.aepx` reader, no `.ffx` presets, no `.mogrt` templates, no `.aet`/`.ars`/`.aom`, no AE SDK plug-ins (`.aex`/`.plugin`). Only `.ecproj`/`.ecprojx`, `.ecpreset` and `.ectemplate` are native (`docs/file-format-parity.md:21-34`, `docs/gaps.md` gaps 1/19/23).
- **Fidelity against After Effects is mostly unmeasured.** One live comparison exists (scalar ease, 8 cases, 168 samples, all passing); everything else is self-graded (`docs/fidelity/README.md`, `docs/gaps.md` gap 2). Never promise AE-identical renders.
- **Alpha stability.** The 12 Oct 2026 audit lists six open crash reports (#580, #501, #426, #341, #234, #879); no PR workflow runs the repo's full `cargo xtask ci` gate (SonarCloud static analysis was added in 0.15.0). 0.15.0 fixed the precomp-cycle overflow and several panic classes — re-check the tracker rather than treating this skill as a stability guarantee (`docs/gaps.md` gaps 3/4, `.github/workflows/`).
- **No hardware video decode/encode** (VideoToolbox, NVENC, Quick Sync, VA-API). HEVC/AV1 have no B-frames, multi-reference or SAO/CDEF, so files are larger; Opus has no FEC/DTX (`docs/gaps.md` gaps 15/22).
- **Output/import gaps**: no 16-bpc uncompressed, AVI, lossless single-file video, MXF output, DNxHR, DPX/Targa/Photoshop sequences or ProRes RAW; no USD/USDZ, Substance `.sbsar`, camera raw, HEIF/AVIF, BRAW/R3D/ARRIRAW (`docs/file-format-parity.md:99-112`, `docs/gaps.md` gap 17).
- **FBX/DPX/PDF caveats**: FBX is 7.x only, with no animation, skinning, cameras or lights; DPX/Cineon log values are shown as stored (no log-to-linear); PDF/AI/EPS import lacks JPX/JBIG2 and Illustrator procset EPS (`crates/model/src/fbx.rs:1-19`, `docs/file-format-parity.md:37-58`).
- **Scripting gaps**: no `.jsxbin`, no Startup/Shutdown script folders, no script shortcuts, no Legacy ExtendScript engine mode, no inter-application BridgeTalk messaging (`docs/scripting-parity.md`, `docs/plugins.md`).
- **The macOS `.app` contains no CLI** — get the universal `effectcraft-cli` from its separate release zip or build it (`docs/agents.md` §From an installed release). **The control channel has no authentication**, binds `127.0.0.1`, serves at most 16 connections, times out at 60 s and rejects lines over 4 MiB, and lets anyone who reaches it run commands, read the project and take screenshots (`docs/control-protocol.md`, `apps/effectcraft/src/control_server.rs:21-23`).
- **Docs drift — trust code/runtime.** `docs/gaps.md` gap 18 still says no relinking, but `footage.relink`/`file.relinkFootage` and moved-project search exist (`crates/engine/src/commands/relink.rs`, `relink_moved.rs`). `README.md` and `docs/gaps.md` say 306 effects; the registry says 307. `docs/target-app-parity.md` says 411 commands; the registry has 669. `docs/gaps.md` says panel catalogs in 6 languages; the code has 7. The bundle declares QOI, which `STILL_EXTENSIONS` omits (`packaging/macos/Info.plist.in:110-123`, `crates/media/src/lib.rs:62-63`).

## How to operate

### Launch (macOS)

```sh
open -a EffectCraft                                  # empty Untitled Project (not the demo)
open -a EffectCraft Project.ecproj                   # open a project
open -a EffectCraft --args --control 9877 --demo     # agent-driven window + demo project
/Applications/EffectCraft.app/Contents/MacOS/EffectCraft --control 9877 --demo
```

Flags: `--control <1-65535>` (or `EFFECTCRAFT_CONTROL_PORT`), `--demo`, `--empty`, `--home`, `--version`; after `--` every argument is a file (a bare file opens a project or imports media). Unknown options exit 1 before the window opens (`apps/effectcraft/src/main.rs:59-105`). The app starts **empty** by default, unlike most one-shot CLI commands, which start with the demo.

### CLI

`effectcraft-cli` is a separate macOS release zip (signed/notarized) or `cargo build --release -p effectcraft-cli`; it is **not** inside the `.app`. Verify with `effectcraft-cli --version`; this pin is 0.15.0. If the launcher updates the app, re-read `effectcraft-cli commands --json`. `<comp>` is an id, name or `-` (active comp); `<layer>` is an id, `#n` or name; values are JSON (`50`, `[960,540]`, `"#ff0000"`) or bare strings.

| Subcommand | What it does |
|---|---|
| `info` | version, mode (headless/bridge), command and effect counts, project and active comp |
| `commands` / `exec --list` | list engine commands; `--filter TEXT`, `--enabled`, `--schemas` |
| `exec <id> [json]` | run one command (`--params` or positional JSON) |
| `run <id> [json] …` | run several in order, stopping at the first error |
| `props <comp> <layer>` | property tree with paths; `--flat`, `--time S`, `--depth N` |
| `get` / `set <comp> <layer> <path> [value]` | read/write one property; `--time S`, `--expression E` |
| `render-frame` | PNG frame (`frame.png` by default); `--time/--frame`, `--max-side/--scale`, `--transparent` |
| `render` | one comp (`--comp`, `--out`, codec flags) or the project queue (`--queue`); `--progress` |
| `bench` | render timings, GPU vs CPU, or `--ops` everyday-operation timings |
| `script FILE.jsx` | run AE-style JavaScript; `--eval CODE` for inline code |
| `mcp` | MCP server on stdio; `--autosave`, `--bridge PORT`, `--automation-read-root`, `--automation-write-root` |

- **Most commands open the demo project** unless you pass `--project F.ecproj`, a positional `*.ecproj`, or `--empty`. `commands`, `script` and `mcp` start empty; MCP starts empty by default.
- `--save` writes back to the opened project, `--save-as F` writes a copy; without either, headless edits are memory-only. `--json` prints one compact JSON document; errors become `{"error": …}` and exit 1; usage errors exit 2 before running. `--gpu` attaches the GPU compositor; CPU is the default.
- `--autosave` is MCP-only; `--bridge PORT` drives `effectcraft --control PORT` and cannot be combined with `--project`/`--demo`; `render` refuses bridge mode (`apps/effectcraft-cli/src/main.rs:336-349,626-627,693-694`).
- `render` needs `--out` (or `--queue`); a relative `--out` is against the **working directory**, while queued outputs resolve against the project folder. `render --comp …` renders exactly one item and disables the project's other queue items; `render --queue` uses the project's queue settings. `--progress` prints `progress <done> <total> <elapsed> <left>` lines on stderr when stderr is not a terminal (`apps/effectcraft-cli/src/main.rs:689-706`).
- `render-frame` accepts `--time`, `--frame`, `--max-side`, `--scale`, `--transparent`. `--template T.ectemplate --values values.json` renders one Essential Graphics instance (values ≤ 1 MiB); it cannot combine with `--project`, `--demo`, `--bridge`, `--queue` or `--comp` (`apps/effectcraft-cli/src/template.rs:9-41`).
- `mcp --automation-read-root DIR / --automation-write-root DIR` (repeatable) confine agent file access; scripts and UI-driving tools are refused while confined (`docs/mcp.md`).

### MCP

`effectcraft-cli mcp` serves JSON-RPC 2.0 over stdio, one message per line, protocol versions 2025-06-18, 2025-03-26 and 2024-11-05 (clients declaring `2026-07-28` also get completion/cache hints) (`crates/automation/src/server.rs:14,281-284`, `docs/mcp.md`). It has **36 tools**:

| Group | Tools |
|---|---|
| Commands | `list_commands`, `describe_command`, `execute_command`, `command_list`, `command_run`, `batch`, `command_batch` |
| Project / properties | `get_project`, `doc_inspect`, `get_comp`, `get_layer`, `get_property`, `set_property`, `add_keyframe`, `add_effect`, `list_effects`, `list_fonts`, `get_state` |
| Files / history / scripting | `open_project`, `save_project`, `undo`, `redo`, `history`, `run_script`, `script_ui` |
| Render | `render_frame`, `render_preview` |
| Bridge-only (9) | `screenshot`, `ui_inspect`, `ui_elements`, `ui_click`, `ui_drag`, `ui_key`, `ui_type`, `ui_set`, `control` |

Resources `effectcraft://document` and `effectcraft://commands` return the same JSON as `doc_inspect` and `command_list` (`crates/automation/src/server.rs:224-233,278-279`). Tools with optional file outputs are annotated conservatively; unknown top-level arguments return JSON-RPC `-32602` naming the accepted keys; a tool failure, or any result with `failed` > 0, sets `isError` (`docs/mcp.md`). `batch` is atomic (one undo step, `$N.key` references); `command_batch` stops at the first error by default, each step its own undo step. A `renderQueue.render` call with `_meta.progressToken` emits progress notifications and can be cancelled; a second render is refused while one runs (`docs/mcp.md` §Progress and cancellation).

### Control channel

`effectcraft --control 9877` (or `EFFECTCRAFT_CONTROL_PORT=9877`) accepts one JSON object per line, `{"id":1,"method":"engine.execute","params":{...}}`, and replies `{"id":1,"ok":true,"result":...}`. **24 methods**:

| Group | Methods |
|---|---|
| Engine / menus | `engine.execute`, `ui.menu.invoke`, `engine.commands`, `ui.menu.list` |
| Render | `render.frame` |
| Inspect / set | `ui.inspect`, `ui.elements`, `ui.set`, `ui.screenshot` |
| Input | `ui.click`, `ui.move`, `ui.drag`, `ui.scroll`, `ui.key`, `ui.type` |
| Panels / playback | `ui.panel.show`, `ui.panel.close`, `ui.playback`, `ui.resize`, `ui.focus` |
| Viewer / timeline | `ui.viewer.locate`, `ui.viewer.hit`, `ui.timeline.locate` |
| App | `app.quit` |

`engine.execute` runs engine commands exactly as headless; UI-only ids and `ui.menu.invoke` go through the menu dispatcher (some open dialogs). `ui.elements` lists widgets drawn in the last frame `{id,label,rect}`; `ui.screenshot` returns a PNG. The channel is loopback-only, has no authentication, serves at most 16 connections, times out after 60 s and closes on a line over 4 MiB (`docs/control-protocol.md`, `apps/effectcraft/src/control_server.rs:21-23`).

### Document model and workflow

One project per app process in one main window; compositions open as tabs and are restored with the project (`crates/project/src/lib.rs:53-69`, `docs/architecture.md` §3). Panels follow After Effects (Project, Composition, Timeline, Effect Controls, Properties, Effects & Presets, Character, Paragraph, Align, Info, Preview, Audio, Render Queue and more), dock/float, and any panel can move to its own native window. Each layer carries a property tree addressed by paths such as `transform/position`, `effects/#1/blurriness` or `@<uid>`.

1. Create a composition (`comp.new`) and add layers (`layer.new*`, `file.import`).
2. Animate (`prop.set`/`prop.addKey`; `timeBase: "comp"` for comp seconds on offset or stretched layers) and ease (`keys.select` + `keys.easyEase` in one session).
3. Apply effects (`effect.apply`), edit `effects/#1/...`, preview and save.
4. Export via `renderQueue.add` + `renderQueue.render`, or Lottie/timeline/template commands.

```sh
effectcraft-cli exec comp.new '{"name":"Main","width":1920,"height":1080,"frameRate":30,"duration":3}' --empty --save-as main.ecproj
effectcraft-cli exec layer.newText '{"text":"Hello","name":"Title","size":160,"fill":"#ffffff"}' main.ecproj --save
effectcraft-cli run main.ecproj \
  prop.addKey '{"layer":"Title","path":"transform/position","time":0,"value":[-400,540]}' \
  prop.addKey '{"layer":"Title","path":"transform/position","time":1,"value":[960,540]}' \
  keys.select '{"keys":[{"layer":"Title","path":"transform/position","time":0},{"layer":"Title","path":"transform/position","time":1}]}' \
  keys.easyEase '{"which":"both"}' --save
effectcraft-cli render main.ecproj --comp Main --out title.mp4 --format h264 --progress
```

Each headless CLI invocation is a new session: edits survive only if saved, and editor state such as key selection never does; group selection-dependent steps in one `run` (or one MCP session).

### Open / save / export, exact formats

- **Open** `.ecproj`, `.ecprojx`, or `.xml` whose root is `EffectCraftProject`; `file.importProject` merges another project instead (`crates/engine/src/commands/file.rs:43-52`, `import_project.rs`). **Save** `.ecproj`, or XML when the path is `.ecprojx`/`.xml`; Save a Copy, Save a Copy As XML and Increment and Save exist (`crates/engine/src/commands/file.rs:86-91,727-753`).
- **Export** the 13 Render Queue formats, single-frame layered PSD or ProEXR, Lottie `.json`/`.lottie`, timeline formats, `.ectemplate`, `.ecpreset`. A `.xml` path is ambiguous: `file.open` expects an EffectCraft XML project, while `file.importTimeline` expects FCP7 XML — use `.ecprojx` for projects.
- **Rejected**: `.prproj` (convert to FCP7 XML in Premiere first) and every AE-native format above (`crates/interchange/src/lib.rs:27`, `docs/file-format-parity.md:21-34`).

### Keyboard shortcuts (only verified ones)

`Cmd+N` New Composition, `Cmd+Alt+N` New Project, `Cmd+O` Open, `Cmd+S` Save, `Cmd+Shift+S` Save As, `Cmd+M` (or `Cmd+Shift+/`) Add to Render Queue, `Cmd+I` Import, `Cmd+K` Composition Settings, `Cmd+Shift+X` Trim Comp to Work Area, `Cmd+Alt+;` Settings, `F9` Easy Ease (`Shift+F9` in, `Cmd+Shift+F9` out), `Cmd+Alt+K` Keyframe Interpolation, `Cmd+Shift+K` Keyframe Velocity, `Cmd+Alt+H` Toggle Hold, `Cmd+Alt+T` Enable Time Remapping, `Cmd+G`/`Cmd+Shift+G` Group/Ungroup Shapes (command registry `shortcut` fields, e.g. `crates/engine/src/commands/file.rs:727-738`, `prop.rs:1364-1384`, `paths.rs:529-530`). Property reveals `A/P/S/R/T/M/F/E/L/U`, their double presses and `Alt+Shift+A/P/S/R/T` keying are in `docs/agents.md` §Timeline. Shortcuts are command data and can be listed/remapped with `shortcuts.list`/`shortcuts.set`; for anything else read `effectcraft-cli commands --json` — do not invent shortcuts.

## Working with an AI agent

### Choose the surface

- **Headless (preferred)**: `effectcraft-cli exec/run` for one-shots or `effectcraft-cli mcp` for a persistent session. Headless MCP starts empty; add `--demo` or `--project`; `mcp --autosave` checkpoints dirty work after each mutating call (`docs/agents.md` §MCP setup).
- **Live app**: start `effectcraft --control 9877`, then `mcp --bridge 9877` or the raw control channel; bridge mode adds `screenshot`/`ui_*` to MCP, while the CLI has no UI-input tools (its `exec` can still invoke menu-style ids through the app) (`docs/control-protocol.md`). **Web**: no TCP channel; use `window.effectcraft` (`docs/web.md:380-407`).

### Prepare inputs

- Convert unsupported sources: camera raw/AVI/BRAW/R3D/USDZ/Substance → H.264/ProRes/WebM or PNG/EXR/TIFF sequences; 3D → glTF/GLB/OBJ/STL/FBX 7.x; audio → WAV/AIFF; data → JSON/CSV/TSV.
- Image sequences: pass one numbered file with `sequence: true` (or import the folder) so the run is one footage item; missing numbers become colour bars. Keep media next to the project: paths are stored as given, and relative ones resolve against the project folder on open (`docs/footage.md`, `crates/engine/src/doc_path.rs`).
- Query `list_fonts`/`text.fonts` first and use a listed family and style (variable fonts expose named instances and accept PostScript names); extra fonts come from `EFFECTCRAFT_FONT_DIRS`.

### Inspect and repair project files

- `.ecproj` is documented by the code, not a public spec: `savedBy`, `schema`, `settings`, `items`, `nextId`, `renderQueue` (`crates/project/src/lib.rs:1549-1567`). Item, layer and property ids share one counter; keep `nextId` above every id. Never bump `schema`; a newer schema is refused rather than rendered wrongly (`crates/project/src/lib.rs:1578-1581`).
- Prefer commands over JSON surgery: `info`, `props`, `get` and `exec` validate through the same reader the app uses. After a hand edit, reopen and check the `repaired` list in `file.open`'s result (`crates/engine/src/commands/file.rs:49-65`).
- For moved media: `footage.missing`, `footage.relink {item, path}` (also relinks other missing files in the same place) or `file.relinkFootage {folder, dryRun}`; do not rewrite paths blindly (`crates/engine/src/commands/relink.rs`, `relink_moved.rs`). `.ectemplate` (ZIP) and `.ecpreset` (tagged JSON) are inspectable, but re-export through the app after edits (`essential.rs:860-870`, `animation.rs:16-17`).
- With cyclic or damaged precomps, 0.15.0 walks the graph with a seen-set instead of recursing, so opening, adding and rendering no longer exhaust the stack (#1237); still avoid hand-building cycles.

### Scripting

- Scripts run against the AE object model; `run_script`/`script` keep edits (wrap in `app.beginUndoGroup()`/`endUndoGroup()` to undo them all). The CLI `script` exits 1 with `file:line:col`; MCP `run_script` returns the error object (`docs/agents.md` §Pitfalls, `apps/effectcraft-cli/src/main.rs:399-440`).
- Reads are allowed under the script's own folder and the project folder; writes and network require Settings ▸ Scripting & Expressions ▸ Allow Scripts to Write Files and Access Network (`crates/script/src/scriptfile.rs:39-49`, `crates/script/src/runtime.rs:364-380`).
- Since 0.15.0, setting an array property to the wrong length throws `Array is not of the correct dimension`; two values are legal for a 3D property (`z = 0`), matching After Effects (`crates/script/src/prelude.js:869-877`). Pad or trim arrays in generated scripts.

### Verify exports

- Read the result: `renderQueue.render` returns per-item statuses; CLI `render` exits 1 if any item failed, and `exec`/`run` treat a failed render as an error (`apps/effectcraft-cli/src/main.rs:655-663`).
- Re-import the output and render a frame (`file.import`, `render_frame`) to prove it decodes; use `--transparent`/`transparent: true` for alpha (`docs/agents.md` §Cookbook).
- Lottie: inspect `warnings`; timeline: inspect `warnings`, `missing` and `prerendered` (`prerender: none` omits layers a timeline cannot represent, `unsupported` (default) pre-renders those to ProRes 4444, `all` pre-renders every visual layer; `crates/engine/src/commands/lottie.rs:24-26`, `crates/interchange/src/export.rs:19-39`).
- Odd comp sizes: H.264/HEVC dimensions round down to even (`crates/project/src/render_queue.rs:599-603`).

### Do not

- Try to open `.aep`/`.aepx`/`.aex`/`.ffx`/`.mogrt`/`.prproj`; there is no reader. Convert timelines to FCP7 XML in Premiere first; expect only `.wasm` plug-ins, `.ecpreset` and `.ectemplate` (`docs/plugins.md`, `docs/file-format-parity.md`).
- Drive the GUI without `--control` (no UI-scripting fallback; discover widgets with `ui.elements`), edit a `.ecproj` the app has open (it will overwrite your changes), or expose the control port (no authentication) (`docs/control-protocol.md`).

### Concurrency and safety

- Save early; `open_project`/`file.newProject` replaces a dirty project without a prompt. Without `--autosave`, MCP work is memory-only (`docs/agents.md` §Keeping headless work, §Pitfalls).
- After a broken bridge connection, mutating calls have an **unknown outcome**; inspect before retrying. `batch` is atomic and rolls back on a failing step; `command_batch` stops at the first error by default (`docs/mcp.md`, `docs/agents.md` §MCP setup).
- Scripts may read files only in their own or the project's folder and cannot write or use the network unless Settings ▸ Scripting & Expressions allows it; confine agent file access with `--automation-read-root` / `--automation-write-root` (`docs/agents.md` §CLI, `docs/mcp.md`).

## Verification protocol

Alpha-software discipline; run this for every delegated task.

1. **Copy first.** Work on a scratch `.ecproj` (`--save-as` / Save a Copy), never the only copy; update the app only between projects.
2. **Round-trip in a fresh process.** New → comp/layers/keyframes/effects → save → reopen via `info --project` → render a frame and a short movie. A save that cannot be read back is a bug; report it.
3. **Check both artifacts.** A `render-frame` PNG at a known time and the final MP4/MOV/sequence; confirm dimensions, duration/frame count, audio and alpha, and for sequences every `#####` frame. Read `renderQueue.render` statuses; check the output file exists and is non-zero.
4. **Check the time span.** Queued items default to **Work Area**; CLI `render` defaults to the whole comp unless `--work-area`. An empty render is usually this, not a codec failure (`crates/project/src/render_queue.rs:368`).
5. **Check format constraints.** H.264/HEVC even dimensions; ProRes 4444 for alpha; WebM VP9 for VP9 alpha; WAV/AIFF are 16-bit PCM; EXR is 32-bit float (`crates/project/src/render_queue.rs:531-603`).
6. **Interchange and Lottie:** inspect warnings/missing/prerendered, re-import the result, and open Lottie in an independent player if available. Record versions and `savedBy`.
7. **Report, don't hide.** Give the exact command, version, file and observed result. Fidelity differences against After Effects are expected and are the most useful report.

## Sources & evidence

- Repository: `https://github.com/storytold/effectcraft`; inspected tag `v0.15.0`, commit `15b8a916c528e73d48f7a9cb4ff58276c7a2d3dd` (`git rev-parse HEAD`, 2026-10-23; tag commit dated 2026-10-22). Fast-moving alpha — verify against your installed version (`effectcraft-cli --version`; the app's `Info.plist` `EffectCraftBuildCommit`).
- Installed app at this pin: version 0.15.0, bundle `ai.storyteller.effectcraft`, build commit `15b8a916c528e73d48f7a9cb4ff58276c7a2d3dd`, universal `x86_64`+`arm64`, macOS 11.0+. `Contents/MacOS` holds only the app binary (no CLI). No GUI was launched; only `--version` was run.
- Read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`; the `docs/` set (`agents`, `mcp`, `control-protocol`, `architecture`, `file-format-parity`, `gaps`, `target-app-parity`, `preferences`, `footage`, `plugins`, `scripting-parity`, `web`, `effects`, `fidelity/README`); the CLI and app entry points (`apps/effectcraft-cli/src/{main,template}.rs`, `apps/effectcraft/src/{main,control_server}.rs`); `crates/project/src/{lib,render_queue,styles,limits}.rs`; the engine command modules cited above; `crates/{media,interchange,lottie,expr,keyframe,plugin,automation}/src`, `crates/effects/src/{lib,catalog}.rs`, `crates/color/src/blend.rs`, `crates/ui-egui/src/{control,i18n,dock,menus}.rs`, `crates/engine/presets/*.json`; source, generated docs, tests and bundle metadata only.

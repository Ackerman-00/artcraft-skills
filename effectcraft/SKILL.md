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

Audit basis: this checkout is tag `v0.17.0`, commit `362474a843ddb67555d4c2d19ad6a590388aad0e`. The installed `/Applications/EffectCraft.app` reports version `0.17.0` (`CFBundleShortVersionString`, and `EffectCraftBuildCommit` = the same commit) and its binary prints `effectcraft 0.17.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. No `references/` directory ships with this skill: every claim is cited inline to the repository.

## Overview

EffectCraft is a free, open-source, clean-room reimplementation of Adobe After Effects 2026 for motion graphics and visual effects: compositions, layers, keyframes, 307 effects, layer styles, expressions, Classic and Advanced 3D, tracking, roto/paint, a render queue and Lottie/timeline interchange. It is pure Rust with no FFmpeg; media codecs come from the sibling FilmCraft project, pinned by revision (`Cargo.toml`). It is **alpha**: the repo self-rates ≈91% feature breadth but ≈45% "ready for real work" (`docs/gaps.md:15-28`, `docs/target-app-parity.md`). FilmCraft is the editing/NLE sibling; EffectCraft is the compositor. Source: GitHub `storytold/effectcraft`, MIT OR Apache-2.0.

`v0.17.0` is a broad maintenance release with two new content features, not a parity jump. A tree comparison against `v0.15.0` (the previous skill's pin) shows ~354 changed/added/removed files and ~12,200 changed lines, but **no change to the effect registry**: 307 effects / 3032 parameters / 280 GPU / 21 categories stand. What is new for agents: **`layer.replaceSource`** (Layer ▸ Replace Source, Alt-drag and Cmd+Opt+/) and the **Cryptomatte picker** (`effect.pickCryptomatte`, `effect.cryptomatteAt`, #473), taking the engine registry from 669 to **672** ids; a `run --args-file` CLI flag; Georgian (`ka`) localization (11 menu catalogs, 8 panel catalogs); a real PR CI gate (`cargo xtask ci`, `.github/workflows/ci.yml`); Reveal Layer Source in Project; timeline row controls that act on the whole layer selection (#1849); and a Composition Settings Resolution popup (#2167).

## Capabilities (verified)

### Project and document model

- **Native `.ecproj`** is versioned, pretty-printed JSON headed by `savedBy` and `schema` (currently 2), with `activeComp`/`openComps`/`compTimes`, `settings`, `items`, `nextId`, `renderQueue`, render templates and preferences (`crates/project/src/lib.rs:35,54-80,1601-1640`). Saving re-reads the text before writing and writes atomically, so a save cannot produce a file the app cannot open; a project whose `savedBy` is a newer version still opens, with a warning that settings this version does not know are lost if you save (`crates/engine/src/commands/file.rs:86-120`).
- **XML project copy `.ecprojx`** is the same data as `EffectCraftProject` XML (lossless, element-per-value, nesting capped at 128); Save a Copy As XML writes it, `file.open` reads it back, and a project opened from XML saves as XML again (`crates/engine/src/xml_project.rs`, `crates/engine/src/commands/file.rs:43-96`).
- **Autosave, crash recovery and MCP checkpoints**; `mcp --autosave` writes a checkpoint after each mutating call (`crates/engine/src/autosave.rs`, `docs/agents.md` §Keeping headless work). Out-of-range values (size > 30,000 px, frame rate outside 0.001–1000, pixel aspect outside 0.1–10, motion-blur samples 2–64) are repaired on open and reported in the result's `repaired` list, not rejected (`crates/project/src/limits.rs:17-29`, `crates/engine/src/commands/file.rs:49-70`).
- **One project per app process**, with compositions open as tabs restored from `openComps`; **36 panel kinds** (34 plain + `ScriptPanel(u32)` and `Viewer(u32)`) and **15 named workspaces**, and any panel can move to its own native window (`crates/ui-egui/src/dock.rs:14-58,281-297`, `docs/architecture.md` §3).

### Composition, animation, expressions

- **Compositions** use exact integer `Tick` time at 254,016,000,000 ticks/s; `comp.new` defaults to 1920×1080, 29.97 fps, 10 s, and accepts `renderer: classic3D|advanced3D` (`crates/time/src/lib.rs:1-22`, `crates/engine/src/commands/comp.rs:103-104`). Layer kinds cover footage, precomp, solid, text, shape, null, camera, light, 3D model and parametric primitive; adjustment layers are solids with the adjustment switch (`crates/project/src/lib.rs` layer model).
- **Parenting, track mattes, all 38 blend modes and motion blur** are in the document model (`crates/color/src/blend.rs:52`).
- **Keyframes**: linear/Bezier/hold, per-side speed and influence (Easy Ease), auto/continuous Bezier, roving keys, Keyframe Velocity/Interpolation, and a Graph Editor with value and speed graphs (`crates/engine/src/commands/prop.rs:1369-1389`, `docs/ui-parity.md` Timeline row). Time remap/stretch/reverse/freeze are `layer.*` commands (`crates/engine/src/commands/layer_time.rs:253`).
- **Expressions** run on `boa` with the AE object model (`thisComp`, `thisLayer`, `thisProperty`, `valueAtTime`, `velocityAtTime`, `wiggle`, `temporalWiggle`, `smooth`, `loopIn/Out`, `sampleImage`, `sourceRectAtTime`, `nearestKey`, `propertyGroup`, text style API) and AE legacy array maths (`crates/expr/src/lib.rs:14-25`, `docs/scripting-parity.md`).

### Effects, text, shapes, masks

- **307 registered effects, 3032 parameters, 280 GPU-capable, all 32-bit float, 21 categories, 0 marked partial**, plus 9 Layer Styles with Global Light (`docs/effects.md:6-10`, generated from `crates/effects/src/catalog.rs` and checked by the `effects_doc_is_current` test at `crates/effects/src/catalog.rs:173-182`; `crates/project/src/styles.rs:28-40`). The README's "306" is one behind the registry (`README.md:23,129,231`). Effects are addressed by id (`ec.<category>.<name>`) or display name.
- **54 built-in animation presets** (8 text animators, 23 backgrounds, 23 transitions) and `.ecpreset` save/apply; the preset file is JSON tagged `effectcraftAnimationPreset` (`crates/engine/presets/*.json`, `crates/engine/src/commands/animation.rs:16-17`).
- **Text, shapes and masks**: point/paragraph text with style runs, variable fonts (named instances by PostScript name, per-axis `variations`), text animators; shape operators (trim, repeater, round corners, offset, zig zag, twist, wiggle, merge, gradient stroke); masks with **7 modes**, feather, expansion, vertex editing and Mask Interpolation (`crates/engine/src/commands/{text_edit,text_anim,mask,mask_interp,paths}.rs`, `crates/project/src/props.rs:217-243`, `crates/text/src/fonts.rs:57-63`).

### 3D, tracking, roto and paint

- **Classic 3D and Advanced 3D**: 3D layers, one/two-node cameras with depth of field, Parallel/Spot/Point/Ambient/Environment lights, ray-cast shadows; Advanced 3D adds PBR materials, six primitives (cube, sphere, plane, torus, cone, cylinder), imported models and environment lighting (`crates/gpu/src/lib.rs:1-12`, `crates/engine/src/commands/model3d.rs`, `docs/agents.md` §Pitfalls — Environment light). "New 3D Primitive" with no parameters opens its dialog (`crates/ui-egui/src/menus.rs:405-407`).
- **Tracking**: point/transform tracking, stabilize, affine/perspective corner-pin tracks, mask tracking including face outline/detailed features, Warp Stabilizer, and a 3D Camera Tracker that creates cameras, solids, nulls, text and shadow catchers (`crates/engine/src/commands/{track,warp_cmds,camera_cmds,mask_interp}.rs`).
- **Roto Brush and Object Matte**: stroke/propagate/freeze with optional MobileSAM or classical fallback; `objectMatte.apply/propagate/freeze` for click/box segmentation with disk-cached mattes; face tracking with optional MediaPipe Face Landmarker. Paint strokes/clone source, Liquify and all five puppet pin kinds are commands too (`crates/engine/src/commands/{roto_cmds,paint,liquify,puppet}.rs`). **Content-Aware Fill and Scene Edit Detection** run as background jobs with `wait`; **Auto-trace** is synchronous (`crates/engine/src/commands/{content_fill,autotrace,scene_detect}.rs`).
- **Cryptomatte picking (new in 0.17.0)**: `effect.pickCryptomatte {layer?, effect, x, y, mode: replace|add|remove, scale?}` replaces/edits the effect's Selection with the ID under a point in effect space, in one undo step; `effect.cryptomatteAt` only reports `{name, hash, layer, selected}` (a `query!`). Both refuse a Selection driven by an expression (`crates/engine/src/commands/effect.rs:250-290,731-746`, `crates/effects/src/crypto_select.rs`, `crates/engine/src/tests_crypto_pick.rs`).
- **Replace Source (new in 0.17.0)**: `layer.replaceSource {layers?, item: id|name}` (defaults to the Project-panel selection) swaps a footage/precomp/solid layer's source while keeping name, timing, transforms, keyframes, expressions, effects, masks, switches, parenting and track matte; folders, data files and 3D models are refused, and a comp cannot contain itself (`crates/engine/src/commands/layer.rs:317-400`, `crates/engine/src/tests_replace_source.rs`). `layer.revealSource` (Layer ▸ Reveal ▸ Reveal Layer Source in Project) emits a `project.reveal` frontend event that the live UI handles by opening the Project panel on the item (`crates/engine/src/commands/layer_menu.rs:771-782,928`, `crates/ui-egui/src/menus.rs:952`).

### Import formats (only what the code registers)

| Kind | Extensions / route | Evidence |
|---|---|---|
| Stills | `png jpg jpeg gif webp tif tiff bmp exr tga hdr psd psb svg pdf ai eps` (17; animated WebP as footage) | `crates/media/src/lib.rs:62-63` |
| Film scans | `dpx cin` (8/10/12/16-bit; log shown as stored) | `crates/media/src/dpx.rs` |
| Video | `mp4 m4v mov mkv webm mxf`; H.264, HEVC, VP9, AV1, ProRes, DNxHD, MPEG-2, MJPEG; MXF OP1a/OP-Atom | `crates/media/src/lib.rs:67`, `docs/file-format-parity.md` |
| Audio | `wav wave bwf aif aiff mp3 mp2 m4a aac flac ogg opus` (FilmCraft `AUDIO_EXTENSIONS`) | `crates/media/src/lib.rs:65` |
| 3D models | `gltf glb obj stl fbx` (glTF: meshes/PBR/skins/animations; FBX 7.x: meshes/materials only) | `crates/media/src/lib.rs:70`, `crates/model/src/fbx.rs` |
| Data | `json csv tsv` as data footage (plain `file.import`; Lottie needs `file.importLottie`) | `crates/engine/src/commands/file.rs` |
| Lottie | `.json`, `.lottie` via `file.importLottie`; export `file.exportLottie` | `crates/engine/src/commands/lottie.rs:61-65` |
| Timelines | `.xml` (FCP7), `.fcpxml`, `.otio`, `.edl`, `.aaf`, `.omf` | `crates/interchange/src/lib.rs:1-26` |
| Color / fonts | LUTs `.cube .3dl .csp .spi1d/.spi3d`, CDL; bundled + installed fonts, `EFFECTCRAFT_FONT_DIRS` | `docs/file-format-parity.md:93`, `crates/text/src/font_dirs.rs` |

`.json` through plain `file.import` is **data footage**, not Lottie — use `file.importLottie`. PSD/PDF/AI/EPS import as footage or as a composition (`importAs`); PSD groups become precomps, text becomes editable, effects map best-effort to Layer Styles (`crates/engine/src/psd_import.rs`). The macOS bundle declares a QOI document type that `STILL_EXTENSIONS` does not implement (`packaging/macos/Info.plist.in`, `crates/media/src/lib.rs:62-63`).

### Export formats

The Render Queue writes **13 formats** (`crates/project/src/render_queue.rs:531-545`):

| Family | Formats |
|---|---|
| Video | H.264 MP4 (+AAC), HEVC MP4 (`hvc1`, Main/Main 10), AV1 MP4 (`av01`), ProRes MOV (Proxy→4444 XQ; 4444 with alpha), uncompressed 8-bit MOV, WebM (VP9 or AV1 + Opus) |
| Stills | PNG, JPEG, TIFF, OpenEXR (32-bit float) sequences; animated GIF |
| Audio | WAV, AIFF (16-bit PCM) |

Render Settings/Output Modules cover quality, resolution, time span (**Work Area by default**, `crates/project/src/render_queue.rs:368`), frame rate, proxy use, effects/solo/guide/depth overrides, colour depth, field rendering + 3:2 pulldown, motion blur, frame blending, skip existing frames, storage overflow, crop/ROI/resize, extra outputs, post-render actions and logs (`crates/project/src/render_queue.rs:324-382,1027-1065`).

- **Single frames** also export as a layered PSD (Composition ▸ Save Frame As ▸ Photoshop Layers) or a multi-layer OpenEXR (ProEXR) (`crates/engine/src/commands/frame_export.rs:1-12,111`).
- **Lottie** `.json`/`.lottie` with a `warnings` list for what Lottie cannot express (`crates/engine/src/commands/lottie.rs:9-30`, `crates/lottie/src/lib.rs`).
- **Timeline interchange** `.xml` (FCP7 default), `.fcpxml`, `.otio`, `.edl`, `.aaf`, `.omf`; `prerender: none|unsupported|all` chooses what becomes ProRes 4444 media instead of clips (`crates/engine/src/commands/timeline.rs`, `crates/interchange/src/export.rs`).
- **Essential Graphics template `.ectemplate`** is a ZIP (a manifest.json, the project JSON, a media folder and poster.png); **animation preset `.ecpreset`** is JSON tagged `effectcraftAnimationPreset` (`crates/engine/src/commands/essential.rs:11-12,860-882`, `crates/engine/src/commands/animation.rs:16-17`).

### Automation and platform (counts re-measured at this tag)

| Surface | Count at v0.17.0 | vs v0.15.0 | Evidence |
|---|---:|---|---|
| Engine command ids | **672** | 669 → **+3**: `effect.pickCryptomatte`, `effect.cryptomatteAt`, `layer.replaceSource` | `crates/engine/src/commands/mod.rs:155-241` registers 80 modules; 672 unique `cmd!`/`query!` ids across `crates/` |
| UI-only command ids | 111 | unchanged (no adds/removes) | `crates/ui-egui/src/menus.rs:29` (`uic!`) |
| MCP tools | 36 (27 headless + 9 bridge-only) | unchanged, identical tool names | `crates/automation/src/tools.rs:542-979` |
| Control-channel methods | 24 (21 dispatch arms, some with two names) | unchanged, identical set | `crates/ui-egui/src/control.rs:172-490` |
| CLI subcommands | 12 | unchanged; new `run --args-file` flag | `apps/effectcraft-cli/src/main.rs:459-633` |
| Render Queue formats | 13 | unchanged | `crates/project/src/render_queue.rs:531` |
| Effects / params / GPU / categories / partial | 307 / 3032 / 280 / 21 / 0 | unchanged | `docs/effects.md:6-10` |
| Blend modes | 38 | unchanged | `crates/color/src/blend.rs:52` |
| Layer Styles | 9 | unchanged | `crates/project/src/styles.rs:28-40` |
| Menu languages / panel catalogs | **11 / 8** | 10 → 11 menus, 7 → 8 panels: Georgian `ka` added | `crates/ui-egui/src/i18n.rs:18`, `crates/ui-egui/src/i18n/ui.rs:69-78` |

- **CLI** `effectcraft-cli`: the 12 subcommands are `info commands exec run props get set render-frame render bench script mcp`, with `--json`, `--project`, `--demo`, `--empty`, `--save`, `--save-as`, `--bridge`, `--gpu`, per-codec render flags, `--queue` and `--progress` (`apps/effectcraft-cli/src/main.rs:2-37,94-200`). **New:** `run --args-file F` reads one argument per line (Windows' 32,767-character limit; `apps/effectcraft-cli/src/main.rs:153,521-527`).
- **MCP** over stdio: **36 tools** — 27 headless and 9 bridge-only (`screenshot`, `ui_inspect`, `ui_elements`, `ui_click`, `ui_drag`, `ui_key`, `ui_type`, `ui_set`, `control`) — plus resources `effectcraft://document` and `effectcraft://commands`; protocol versions 2025-06-18 / 2025-03-26 / 2024-11-05, with completion hints for clients declaring 2026-07-28 (`crates/automation/src/tools.rs:542`, `crates/automation/src/server.rs:14,278-284`, `docs/mcp.md`).
- **Control channel**: `effectcraft --control <port>` (or `EFFECTCRAFT_CONTROL_PORT`) speaks newline JSON on `127.0.0.1`: **24 methods** — `engine.execute`, `ui.menu.invoke`, `engine.commands`, `ui.menu.list`, `render.frame`, `ui.inspect/elements/set/screenshot/click/move/drag/scroll/key/type`, `ui.panel.show/close`, `ui.playback`, `ui.resize`, `ui.focus`, `ui.viewer.locate/hit`, `ui.timeline.locate`, `app.quit` (`crates/ui-egui/src/control.rs:172-490`, `docs/control-protocol.md`).
- **Two command tiers**: 672 engine ids run headless (CLI/MCP/`engine.execute`); 111 UI-only ids (`timeline.*` 53, `tool.*` 15, `view.*` 12, `window.*` 11, `viewer.*` 8, `playback.*` 5, `app.*` 4, `flowchart.*` 2, `markers.*` 1) dispatch only in the live app. No command is a disabled stub: `crates/engine/src/commands/stubs.rs` returns an empty list ("Every After Effects menu entry has a real command now").
- **Scripts/ScriptUI**: `.jsx`/`.js` with the AE object model (`app.project`, match names, `Socket`, `$.evalFile`, `#include`, `app.scheduleTask`), dockable ScriptUI panels that reopen at launch; `script.run`, `file.runScript`, CLI `script FILE.jsx` and `script --eval CODE` (`docs/plugins.md`, `docs/scripting-parity.md`, `crates/script/src/lib.rs`).
- **WebAssembly effect plug-ins**: `.wasm`/`.wat`, API v1, sandboxed in `wasmi` with no imports (`crates/plugin/src/lib.rs:4-35`, `docs/plugins.md` §Effect plug-ins).
- **Web build** (`apps/effectcraft-web`) runs the same engine/UI as WASM with OPFS/IndexedDB storage and `window.effectcraft` (`request`, `execute`, `commands`, `inspect`, `renderFrame`, `screenshot`, `workerFrameCheck`, `addFile`, `files`, `readFile`, `saveToBrowser`, `listStored`, `removeStored`, `flush`, `info`); it is not the installed macOS app (`docs/web.md:387-399`, `apps/effectcraft-web/src/api.rs`).
- **GPU**: a wgpu compute compositor for Metal/Vulkan/Direct3D 12/WebGPU (Direct3D 12 is reported failing on some Windows GPUs, `docs/hardware-parity.md`); CPU is the reference; the desktop attaches the GPU compositor whenever the device is created and falls back to CPU compositing with a note otherwise (`crates/ui-egui/src/lib.rs:780-806`); headless CLI/MCP render on the CPU and say so unless started with `--gpu`, which needs a usable adapter (`crates/gpu/src/lib.rs:1-3`, `apps/effectcraft-cli/src/main.rs:344-350,373-378`).
- **CI**: `.github/workflows/ci.yml` now runs `cargo xtask ci` on every push to `main` and every pull request through the shared `storytold/craft-common-actions` gate (new in this release; `docs/gaps.md` gap 3 still claims no PR gate — stale).
- **Localization**: menus in **11** languages (cs, de, es, fr, pt-br, ru, uk, ka, ja, zh-hans, zh-hant); panel/tooltip catalogs in **8** (ja, zh-hans, zh-hant, uk, pt-br, cs, es, ka). Georgian is new and native-speaker reviewed; Korean and Italian remain absent (`crates/ui-egui/src/i18n.rs:18`, `crates/ui-egui/src/i18n/ui.rs:69-78`, `ROADMAP.md:138`).

## Known limitations and not-implemented

- **After Effects projects will not open.** No `.aep`/`.aepx` reader, no `.ffx` presets, no `.mogrt` templates, no `.aet`/`.ars`/`.aom`, no AE SDK plug-ins (`.aex`/`.plugin`). Only `.ecproj`/`.ecprojx`, `.ecpreset` and `.ectemplate` are native (`docs/file-format-parity.md:21-34`, `docs/gaps.md` gaps 1/19/23).
- **Fidelity against After Effects is mostly unmeasured.** The one live comparison (scalar ease, 8 cases, 168 samples) still passes, and this release adds the first *effect* comparisons: Tint, Tritone, Black & White, Exposure, Levels (Individual Controls), Curves, Luma Key, Extract, 4-Color Gradient and Fill match After Effects 2026 renders within 1–3/255, Brightness & Contrast up to 6.2/255. Everything else is self-graded — never promise AE-identical renders (`docs/fidelity/README.md`, `docs/effects-parity.md:18`).
- **Alpha stability.** `docs/gaps.md` still lists open crash reports (#580, #501, #426, #341, #234, #879); a PR CI gate now exists but this tag is not a stability guarantee. Re-check the tracker rather than quoting this skill (`docs/gaps.md` gaps 3/4, `.github/workflows/ci.yml`).
- **No hardware video decode/encode** (VideoToolbox, NVENC, Quick Sync, VA-API). HEVC/AV1 have no B-frames, multi-reference or SAO/CDEF, so files are larger; Opus has no FEC/DTX (`docs/gaps.md` gaps 15/22).
- **Output/import gaps**: no 16-bpc uncompressed, AVI, lossless single-file video, MXF output, DNxHR, DPX/Targa/Photoshop sequences or ProRes RAW; no USD/USDZ, Substance `.sbsar`, camera raw, HEIF/AVIF, BRAW/R3D/ARRIRAW (`docs/file-format-parity.md:99-112`, `docs/gaps.md` gap 17).
- **FBX/DPX/PDF caveats**: FBX is 7.x only, with no animation, skinning, cameras or lights; DPX/Cineon log values are shown as stored (no log-to-linear); PDF/AI/EPS import lacks JPX/JBIG2 and Illustrator procset EPS (`crates/model/src/fbx.rs`, `docs/file-format-parity.md:37-58`).
- **Scripting gaps**: no `.jsxbin`, no Startup/Shutdown script folders, no script shortcuts, no Legacy ExtendScript engine mode, no inter-application BridgeTalk messaging (`docs/scripting-parity.md`, `docs/plugins.md`).
- **The macOS `.app` contains no CLI** — get the universal `effectcraft-cli` from its separate release zip or build it (`docs/agents.md` §From an installed release). **The control channel has no authentication**, binds `127.0.0.1`, serves at most 16 connections, times out at 60 s and rejects lines over 4 MiB; anyone who reaches it can run commands, read the project and take screenshots (`docs/control-protocol.md`, `apps/effectcraft/src/control_server.rs:21-23,63`).
- **Docs drift — trust code/runtime.** `README.md`, `docs/gaps.md`, `docs/architecture.md`, `docs/effects-parity.md` (306/3017) and `docs/hardware-parity.md` say 306 effects; the registry is 307/3032. `docs/target-app-parity.md:72` says 411 commands; the registry has 672. `docs/gaps.md` gap 16 says 7 panel catalogs; the code has 8, and gap 3 says no PR CI gate; `.github/workflows/ci.yml` exists. `docs/file-format-parity.md:34` still says no relinking; `footage.relink`/`file.relinkFootage` exist (`crates/engine/src/commands/relink.rs`, `crates/engine/src/commands/relink_moved.rs`).
- **`.prproj` is not read or written** — convert to FCP7 XML in Premiere first (`crates/interchange/src/lib.rs:24-26`).

## How to operate

### Launch (macOS)

```sh
open -a EffectCraft                                  # empty Untitled Project (not the demo)
open -a EffectCraft Project.ecproj                   # open a project
open -a EffectCraft --args --control 9877 --demo     # agent-driven window + demo project
/Applications/EffectCraft.app/Contents/MacOS/EffectCraft --control 9877 --demo
```

Flags: `--control <1-65535>` (or `EFFECTCRAFT_CONTROL_PORT`), `--demo`, `--empty`, `--home`, `--version`; after `--` every argument is a file (a bare file opens a project or imports media). Unknown options exit 1 before the window opens; macOS `-psn_…` is ignored (`apps/effectcraft/src/main.rs:59-105`). The app starts **empty** by default, unlike most one-shot CLI commands, which start with the demo.

### CLI

`effectcraft-cli` is a separate macOS release zip (signed/notarized) or `cargo build --release -p effectcraft-cli`; it is **not** inside the `.app`. Verify with `effectcraft-cli --version`; this pin is 0.17.0. If the launcher updates the app, re-read `effectcraft-cli commands --json`. `<comp>` is an id, name or `-` (active comp); `<layer>` is an id, `#n` or name; values are JSON (`50`, `[960,540]`, `"#ff0000"`) or bare strings.

| Subcommand | What it does |
|---|---|
| `info` | version, mode (headless/bridge), command and effect counts, project and active comp |
| `commands` / `exec --list` | list engine commands; `--filter TEXT`, `--enabled`, `--schemas` |
| `exec <id> [json]` | run one command (`--params` or positional JSON) |
| `run <id> [json] …` | run several in order, stopping at the first error; `--args-file F` reads the arguments from a file |
| `props <comp> <layer>` | property tree with paths; `--flat`, `--time S`, `--depth N` |
| `get` / `set <comp> <layer> <path> [value]` | read/write one property; `--time S`, `--expression E` |
| `render-frame` | PNG frame (`frame.png` by default); `--time/--frame`, `--max-side/--scale`, `--transparent` |
| `render` | one comp (`--comp`, `--out`, codec flags) or the project queue (`--queue`); `--progress` |
| `bench` | render timings, GPU vs CPU, or `--ops` everyday-operation timings |
| `script FILE.jsx` | run AE-style JavaScript; `--eval CODE` for inline code |
| `mcp` | MCP server on stdio; `--autosave`, `--bridge PORT`, `--automation-read-root`, `--automation-write-root` |

- **Most commands open the demo project** unless you pass `--project F.ecproj`, a positional `*.ecproj`, or `--empty`. `commands`, `script` and `mcp` start empty; MCP starts empty by default.
- `--save` writes back to the opened project, `--save-as F` writes a copy; without either, headless edits are memory-only. `--json` prints one compact JSON document; errors become `{"error": …}` and exit 1; usage errors exit 2 before running. `--gpu` attaches the GPU compositor; CPU is the default.
- `--autosave` is MCP-only; `--bridge PORT` drives `effectcraft --control PORT` and cannot be combined with `--project`/`--demo`; `render` refuses bridge mode.
- `render` needs `--out` (or `--queue`); a relative `--out` is against the **working directory**, while queued outputs resolve against the project folder. `render --comp …` renders exactly one item and disables the project's other queue items; `--progress` prints `progress <done> <total> <elapsed> <left>` lines on stderr when stderr is not a terminal.
- `render-frame` accepts `--time`, `--frame`, `--max-side`, `--scale`, `--transparent`. `--template T.ectemplate --values values.json` renders one Essential Graphics instance (values ≤ 1 MiB); it cannot combine with `--project`, `--demo`, `--bridge`, `--queue` or `--comp` (`apps/effectcraft-cli/src/template.rs`).
- `mcp --automation-read-root DIR / --automation-write-root DIR` (repeatable) confine agent file access; scripts and UI-driving tools are refused while confined (`docs/mcp.md`).

### MCP

`effectcraft-cli mcp` serves JSON-RPC 2.0 over stdio, one message per line. It has **36 tools**:

| Group | Tools |
|---|---|
| Commands | `list_commands`, `describe_command`, `execute_command`, `command_list`, `command_run`, `batch`, `command_batch` |
| Project / properties | `get_project`, `doc_inspect`, `get_comp`, `get_layer`, `get_property`, `set_property`, `add_keyframe`, `add_effect`, `list_effects`, `list_fonts`, `get_state` |
| Files / history / scripting | `open_project`, `save_project`, `undo`, `redo`, `history`, `run_script`, `script_ui` |
| Render | `render_frame`, `render_preview` |
| Bridge-only (9) | `screenshot`, `ui_inspect`, `ui_elements`, `ui_click`, `ui_drag`, `ui_key`, `ui_type`, `ui_set`, `control` |

Resources `effectcraft://document` and `effectcraft://commands` return the same JSON as `doc_inspect` and `command_list` (`crates/automation/src/server.rs:278-279`). Unknown top-level arguments return JSON-RPC `-32602` naming the accepted keys; a tool failure, or any result with `failed` > 0, sets `isError`. `batch` is atomic (one undo step, `$N.key` references); `command_batch` stops at the first error by default, each step its own undo step. A `renderQueue.render` call with `_meta.progressToken` emits progress notifications and can be cancelled; a second render is refused while one runs (`docs/mcp.md` §Progress and cancellation).

### Control channel

`effectcraft --control 9877` accepts one JSON object per line, `{"id":1,"method":"engine.execute","params":{...}}`, and replies `{"id":1,"ok":true,"result":...}`. **24 methods**: engine/menus (`engine.execute`, `ui.menu.invoke`, `engine.commands`, `ui.menu.list`), render (`render.frame`), inspect (`ui.inspect`, `ui.elements`, `ui.set`, `ui.screenshot`), input (`ui.click`, `ui.move`, `ui.drag`, `ui.scroll`, `ui.key`, `ui.type`), panels/playback (`ui.panel.show`, `ui.panel.close`, `ui.playback`, `ui.resize`, `ui.focus`), viewer/timeline (`ui.viewer.locate`, `ui.viewer.hit`, `ui.timeline.locate`) and `app.quit`. `engine.execute` runs engine commands exactly as headless; UI-only ids and `ui.menu.invoke` go through the menu dispatcher (some open dialogs). `ui.elements` lists widgets drawn in the last frame `{id,label,rect}`; `ui.screenshot` returns a PNG.

### Document model and workflow

One project per app process in one main window; compositions open as tabs and are restored with the project. Panels follow After Effects (Project, Composition, Timeline, Effect Controls, Properties, Effects & Presets, Character, Paragraph, Align, Info, Preview, Audio, Render Queue and more), dock/float, and any panel can move to its own native window. Each layer carries a property tree addressed by paths such as `transform/position`, `effects/#1/blurriness` or `@<uid>`.

1. Create a composition (`comp.new`) and add layers (`layer.new*`, `file.import`, `layer.replaceSource` to swap a source).
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

- **Open** `.ecproj`, `.ecprojx`, or `.xml` whose root is `EffectCraftProject`; `file.importProject` merges another project instead. **Save** `.ecproj`, or XML when the path is `.ecprojx`/`.xml`; Save a Copy, Save a Copy As XML and Increment and Save exist (`crates/engine/src/commands/file.rs:43-96,736-760`).
- **Export** the 13 Render Queue formats, single-frame layered PSD or ProEXR, Lottie `.json`/`.lottie`, timeline formats, `.ectemplate`, `.ecpreset`. A `.xml` path is ambiguous: `file.open` expects an EffectCraft XML project, while `file.importTimeline` expects FCP7 XML — use `.ecprojx` for projects.
- **Rejected**: `.prproj` and every AE-native format above.

### Keyboard shortcuts (only verified ones)

`Cmd+N` New Composition (`crates/engine/src/commands/comp.rs:281`), `Cmd+K` Composition Settings (`crates/engine/src/commands/comp.rs:290`), `Cmd+Shift+X` Trim Comp to Work Area (`crates/engine/src/commands/comp.rs:296`), `Cmd+Alt+N` New Project, `Cmd+O` Open, `Cmd+S` Save, `Cmd+Alt+Shift+S` Increment and Save, `Cmd+Shift+S` Save As, `Cmd+I` Import (`crates/engine/src/commands/file.rs:736-747`), `Cmd+M` / `Cmd+Shift+/` Add to Render Queue (`crates/engine/src/commands/render_queue.rs:1001`), `F9` Easy Ease / `Shift+F9` in / `Cmd+Shift+F9` out, `Cmd+Alt+K` Keyframe Interpolation, `Cmd+Shift+K` Keyframe Velocity, `Cmd+Alt+H` Toggle Hold (`crates/engine/src/commands/prop.rs:1369-1389`), `Cmd+Alt+T` Enable Time Remapping (`crates/engine/src/commands/layer_time.rs:253`), `Cmd+G`/`Cmd+Shift+G` Group/Ungroup Shapes (`crates/engine/src/commands/paths.rs:529-530`), `Cmd+Alt+;` Settings (`crates/engine/src/menus.rs:492`), `Cmd+Opt+/` Replace Source with the selected Project item (`docs/footage.md:123-131`). Property reveals `A/P/S/R/T/M/F/E/L/U`, their double presses and `Alt+Shift+A/P/S/R/T` keying are in `docs/agents.md` §Timeline. Shortcuts are command data and can be listed/remapped with `shortcuts.list`/`shortcuts.set`; for anything else read `effectcraft-cli commands --json` — do not invent shortcuts.

## Working with an AI agent

### Choose the surface

- **Headless (preferred)**: `effectcraft-cli exec/run` for one-shots or `effectcraft-cli mcp` for a persistent session. Headless MCP starts empty; add `--demo` or `--project`; `mcp --autosave` checkpoints dirty work after each mutating call (`docs/agents.md` §MCP setup).
- **Live app**: start `effectcraft --control 9877`, then `mcp --bridge 9877` or the raw control channel; bridge mode adds `screenshot`/`ui_*` to MCP, while the CLI has no UI-input tools (its `exec` can still invoke menu-style ids through the app). **Web**: no TCP channel; use `window.effectcraft` (`docs/web.md:387-399`).

### Prepare inputs

- Convert unsupported sources: camera raw/AVI/BRAW/R3D/USDZ/Substance → H.264/ProRes/WebM or PNG/EXR/TIFF sequences; 3D → glTF/GLB/OBJ/STL/FBX 7.x; audio → WAV/AIFF; data → JSON/CSV/TSV.
- Image sequences: pass one numbered file with `sequence: true` (or import the folder) so the run is one footage item; missing numbers become colour bars. Keep media next to the project: relative paths resolve against the project folder on open (`docs/footage.md`, `crates/engine/src/doc_path.rs`).
- Query `list_fonts`/`text.fonts` first and use a listed family and style (variable fonts expose named instances and accept PostScript names); extra fonts come from `EFFECTCRAFT_FONT_DIRS`.

### Inspect and repair project files

- `.ecproj` is documented by the code, not a public spec: `savedBy`, `schema`, `activeComp`, `openComps`, `settings`, `items`, `nextId`, `renderQueue` (`crates/project/src/lib.rs:35,54-80,1601-1640`). Item, layer and property ids share one counter; keep `nextId` above every id. Never bump `schema`; a newer schema is warned about rather than rendered wrongly.
- Prefer commands over JSON surgery: `info`, `props`, `get` and `exec` validate through the same reader the app uses. After a hand edit, reopen and check the `repaired` list in `file.open`'s result (`crates/engine/src/commands/file.rs:49-70`).
- For moved media: `footage.missing`, `footage.relink {item, path}` (also relinks other missing files in the same place) or `file.relinkFootage {folder, dryRun}`; do not rewrite paths blindly (`crates/engine/src/commands/relink.rs`, `crates/engine/src/commands/relink_moved.rs`). `.ectemplate` (ZIP) and `.ecpreset` (tagged JSON) are inspectable, but re-export through the app after edits.
- `layer.revealSource` is the safe way to find a layer's Project item in the UI; text/shape/null/camera/light/3D-primitive layers have none and it refuses them. Headless it returns the item ids instead (`crates/engine/src/commands/layer_menu.rs:771-782`).

### Scripting

- Scripts run against the AE object model; `run_script`/`script` keep edits (wrap in `app.beginUndoGroup()`/`endUndoGroup()` to undo them all). The CLI `script` exits 1 with `file:line:col`; MCP `run_script` returns the error object.
- Reads are allowed under the script's own folder and the project folder; writes and network require Settings ▸ Scripting & Expressions ▸ Allow Scripts to Write Files and Access Network (`crates/script/src/scriptfile.rs:41-50`).
- Setting an array property to the wrong length throws `Array is not of the correct dimension`; two values are legal for a 3D property (`z = 0`), matching After Effects (`crates/script/src/prelude.js:876`). Pad or trim arrays in generated scripts.

### Verify exports

- Read the result: `renderQueue.render` returns per-item statuses; CLI `render` exits 1 if any item failed.
- Re-import the output and render a frame (`file.import`, `render_frame`) to prove it decodes; use `--transparent`/`transparent: true` for alpha.
- Lottie: inspect `warnings`; timeline: inspect `warnings`, `missing` and `prerendered` (`prerender: none` omits layers a timeline cannot represent, `unsupported` (default) pre-renders those to ProRes 4444, `all` pre-renders every visual layer).
- Odd comp sizes: H.264/HEVC dimensions round down to even (`crates/project/src/render_queue.rs:599-603`).

### Do not

- Try to open `.aep`/`.aepx`/`.aex`/`.ffx`/`.mogrt`/`.prproj`; there is no reader. Convert timelines to FCP7 XML in Premiere first; expect only `.wasm` plug-ins, `.ecpreset` and `.ectemplate`.
- Drive the GUI without `--control` (no UI-scripting fallback; discover widgets with `ui.elements`), edit a `.ecproj` the app has open (it will overwrite your changes), or expose the control port (no authentication).

### Concurrency and safety

- Save early; `open_project`/`file.newProject` replaces a dirty project without a prompt. Without `--autosave`, MCP work is memory-only.
- After a broken bridge connection, mutating calls have an **unknown outcome**; inspect before retrying. `batch` is atomic and rolls back on a failing step; `command_batch` stops at the first error by default.
- Scripts may read files only in their own or the project's folder and cannot write or use the network unless Settings ▸ Scripting & Expressions allows it; confine agent file access with `--automation-read-root` / `--automation-write-root`.

## Verification protocol

Alpha-software discipline; run this for every delegated task.

1. **Copy first.** Work on a scratch `.ecproj` (`--save-as` / Save a Copy), never the only copy; update the app only between projects.
2. **Round-trip in a fresh process.** New → comp/layers/keyframes/effects → save → reopen via `info --project` → render a frame and a short movie. A save that cannot be read back is a bug; report it.
3. **Check both artifacts.** A `render-frame` PNG at a known time and the final MP4/MOV/sequence; confirm dimensions, duration/frame count, audio and alpha, and for sequences every `#####` frame. Read `renderQueue.render` statuses; check the output file exists and is non-zero.
4. **Check the time span.** Queued items default to **Work Area**; CLI `render` defaults to the whole comp unless `--work-area`. An empty render is usually this, not a codec failure (`crates/project/src/render_queue.rs:368`).
5. **Check format constraints.** H.264/HEVC even dimensions; ProRes 4444 for alpha; WebM VP9 for VP9 alpha; WAV/AIFF are 16-bit PCM; EXR is 32-bit float.
6. **Interchange and Lottie:** inspect warnings/missing/prerendered, re-import the result, and open Lottie in an independent player if available. Record versions and `savedBy`.
7. **Report, don't hide.** Give the exact command, version, file and observed result. Fidelity differences against After Effects are expected and are the most useful report.

## Sources & evidence

- Repository: `https://github.com/storytold/effectcraft`; inspected tag `v0.17.0`, commit `362474a843ddb67555d4c2d19ad6a590388aad0e` (`git rev-parse HEAD`, 2026-10-26). Fast-moving alpha — verify against your installed version (`effectcraft-cli --version`, and `EffectCraftBuildCommit` in `/Applications/EffectCraft.app/Contents/Info.plist`).
- Installed app at this pin: version 0.17.0, bundle `ai.storyteller.effectcraft`, build commit `362474a843ddb67555d4c2d19ad6a590388aad0e`, minimum macOS 11.0; `Contents/MacOS` holds only the app binary (no CLI). No GUI was launched; only `--version` was run.
- Read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`, `.github/workflows/ci.yml`; the `docs/` set (`agents`, `mcp`, `control-protocol`, `architecture`, `file-format-parity`, `gaps`, `target-app-parity`, `preferences`, `footage`, `plugins`, `scripting-parity`, `web`, `effects`, `effects-parity`, `fidelity/README`); the CLI and app entry points (`apps/effectcraft-cli/src/{main,template}.rs`, `apps/effectcraft/src/{main,control_server}.rs`); `crates/project/src/{lib,render_queue,styles,limits}.rs`; the engine command modules cited above; `crates/{media,interchange,lottie,expr,keyframe,plugin,automation,script}/src`, `crates/effects/src/{lib,catalog,crypto_select}.rs`, `crates/color/src/blend.rs`, `crates/ui-egui/src/{control,i18n,dock,menus}.rs`, `crates/engine/presets/*.json`; source, generated docs, tests and bundle metadata only. Counts were re-measured from code (and, for the change list, by comparing the `v0.15.0` tree with this one); no build, test or render was run.

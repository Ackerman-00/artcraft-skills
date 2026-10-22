---
name: effectcraft
description: >-
  EffectCraft is a macOS (also Windows/Linux/Web) motion-graphics, compositing and VFX app — a
  clean-room, pure-Rust reimplementation of Adobe After Effects 2026 — for compositions, layers,
  keyframes, effects, text, shapes, 3D, tracking and rendering. Trigger this skill whenever the
  user mentions EffectCraft, .ecproj/.ecprojx/.ectemplate/.ecpreset files, or effectcraft-cli;
  asks what it can do or which file formats/shortcuts it has; wants to troubleshoot it; or asks to
  create, edit, animate, composite, render, convert, inspect, verify or automate a motion graphic,
  title card, logo animation, green-screen composite or VFX shot — even when they do not name the
  app ("make a title card", "animate this logo", "render this comp", "export a ProRes", "export
  Lottie", "open this .aep"). Also use it when choosing between EffectCraft and FilmCraft, or when
  preparing or verifying assets for EffectCraft.
---

## Overview

EffectCraft is a free, open-source, clean-room reimplementation of Adobe After Effects 2026 for
motion graphics and visual effects: compositions, layers, keyframes, 307 effects, layer styles,
expressions, Classic and Advanced 3D, tracking, a render queue and Lottie interchange, written in
pure Rust with no FFmpeg (`README.md`, `Cargo.toml`). It is **alpha**: ≈91% feature breadth but
only ≈45% "ready for real work" (`crates/engine/src/commands/query.rs:202`, `docs/gaps.md:15-28`).
It is the compositor of the ArtCraft family; FilmCraft is the editing/NLE sibling, not this app.

Source: `github.com/storytold/effectcraft`, MIT OR Apache-2.0. This skill was written against
**v0.14.0**, commit `26b40199b72121aa7f4e55a63718e1b4dd48a859`, which is also the installed
`/Applications/EffectCraft.app` (bundle `ai.storyteller.effectcraft`, universal, macOS 11+; its
`EffectCraftBuildCommit` matches this commit). Three entry points drive the same engine commands:
the CLI (`effectcraft-cli`), an MCP server, and a localhost JSON control channel for the live GUI
(`docs/agents.md`); everything the UI does is an engine command with an id and JSON params
(`crates/engine/src/commands/mod.rs`).

## Capabilities (verified)

### Project and document model

- **Native `.ecproj`** is versioned, pretty-printed JSON, headed by `savedBy` and `schema`
  (currently 2), with `activeComp`/`openComps`/`compTimes`, `settings`, `items`, `nextId`,
  `renderQueue`, render templates and preferences (`crates/project/src/lib.rs:34,1363-1381`).
  Saving re-reads the text before writing and writes atomically, so a save cannot produce a file
  the app cannot open (`lib.rs:1540-1543`, `crates/engine/src/lib.rs:144`).
- **XML project copy `.ecprojx`** is the same data as `EffectCraftProject` XML; Save a Copy As XML
  writes it and `file.open` reads it back; a project opened from XML saves as XML again
  (`crates/engine/src/xml_project.rs`, `file.rs:45-48,86-91`).
- **Autosave, crash recovery and MCP checkpoints**; MCP adds `mcp --autosave`
  (`crates/engine/src/autosave.rs`, `docs/agents.md` §Keeping headless work). Out-of-range values
  (size > 30,000 px, frame rate outside 0.001–1000, pixel aspect outside 0.1–10) are repaired on
  open and reported, not rejected (`crates/project/src/limits.rs:16-25`, `file.rs:57-65`).

### Composition, animation, effects

- **Compositions** use exact rational frame rates and integer `Tick` time; `comp.new` defaults to
  1920×1080, 29.97 fps, 10 s, with `renderer: classic3D|advanced3D`
  (`crates/engine/src/commands/comp.rs:104-112`). **Every AE layer kind** exists: footage,
  precomp, solid, text, shape, null, camera, light, 3D model, parametric primitive; adjustment
  layers are solids with the adjustment switch; parenting, track mattes, all **38 blend modes**
  and motion blur are in the document model (`crates/color/src/blend.rs:9-52`).
- **Keyframes**: linear/Bezier/hold, per-side speed and influence (Easy Ease), auto/continuous
  Bezier, roving keys, Keyframe Velocity/Interpolation, and a Graph Editor with value and speed
  graphs (`crates/keyframe/src/lib.rs`, `crates/engine/src/commands/prop.rs:1364-1384`). Time
  remap/stretch/reverse/freeze are `layer_time` commands (`crates/engine/src/commands/layer_time.rs:253`).
- **Expressions** run on `boa` with the AE object model (`thisComp`, `wiggle`, `loopOut`,
  `valueAtTime`, `sampleImage`, `propertyGroup`, text style API) and AE legacy array maths
  (`crates/expr/src/lib.rs:1-10`, `docs/scripting-parity.md`).
- **Text, shapes and masks**: point/paragraph text with style runs, variable fonts (named
  instances by PostScript name, per-axis `variations`), text animators; shape operators (trim,
  repeater, round corners, offset, zig zag, twist, wiggle, merge, gradient stroke); masks with
  modes, feather, expansion, vertex editing and Mask Interpolation
  (`crates/engine/src/commands/{layer,text_edit,text_anim,mask,mask_interp}.rs`, `crates/text/src/fonts.rs`).
- **307 registered effects** (3032 parameters, 280 GPU-capable, all 32-bit float, 21 categories,
  0 marked partial) plus 9 Layer Styles with Global Light (`docs/effects.md:6-10` — generated from
  the registry, `crates/effects/src/lib.rs:485-529`, `catalog.rs:9`,
  `crates/project/src/styles.rs:28-40`). The README's "306" is one behind the registry;
  `app.capabilities` reports 307 (`crates/engine/src/commands/query.rs:181-202`).
- **54 built-in animation presets** (8 text animators, 23 backgrounds, 23 transitions) and
  `.ecpreset` save/apply (`crates/engine/presets/*.json`, `docs/gaps.md` gap 7).

### 3D, tracking, roto and paint

- **Classic 3D and Advanced 3D**: 3D layers, one/two-node cameras with depth of field,
  Parallel/Spot/Point/Ambient/Environment lights, ray-cast shadows; Advanced 3D adds PBR
  materials, primitives, imported models and environment lighting (`crates/gpu/src/lib.rs:1-12`,
  `crates/engine/src/commands/model3d.rs`, `docs/agents.md` §Pitfalls — Environment light).
- **Tracking**: point/transform tracking (`track.*`), stabilize, affine/perspective corner-pin
  tracks, mask tracking including face outline/detailed features, Warp Stabilizer, and a 3D
  Camera Tracker that creates cameras, solids, nulls, text and shadow catchers
  (`crates/engine/src/commands/{track,warp_cmds,camera_cmds}.rs`).
- **Roto Brush and Object Matte**: stroke/propagate/freeze with optional MobileSAM or classical
  fallback; `objectMatte.apply/propagate/freeze` for click/box segmentation with disk-cached
  mattes; face tracking with optional MediaPipe Face Landmarker. Paint strokes/clone source,
  Liquify and all five puppet pin kinds are commands too
  (`crates/engine/src/commands/{roto_cmds,paint,liquify,puppet}.rs`,
  `crates/effects/src/{roto,object_matte,face_track}.rs`). **Content-Aware Fill, Auto-trace and
  Scene Edit Detection** are background-job commands
  (`crates/engine/src/commands/{content_fill,autotrace,scene_detect}.rs`).

### Import formats (only what the code registers)

| Kind | Extensions / route | Evidence |
|---|---|---|
| Stills | `png jpg jpeg gif webp tif tiff bmp exr tga hdr psd psb svg pdf ai eps` (animated WebP as footage) | `crates/media/src/lib.rs:61-63` |
| Film scans | `dpx cin` (8/10/12/16-bit; log shown as stored) | `crates/media/src/dpx.rs`, `docs/file-format-parity.md` |
| Video | `mp4 m4v mov mkv webm mxf`; H.264, HEVC, VP9, AV1, ProRes, DNxHD, MPEG-2, MJPEG; MXF OP1a/OP-Atom | `crates/media/src/lib.rs:66`, `docs/file-format-parity.md` |
| Audio | `wav wave bwf aif aiff mp3 mp2 m4a aac flac ogg opus` (FilmCraft `AUDIO_EXTENSIONS`) | `crates/media/src/lib.rs:65` |
| 3D models | `gltf glb obj stl fbx` (glTF: meshes/PBR/skins/animations; FBX 7.x: meshes/materials only, no animation/skinning) | `crates/media/src/lib.rs:70`, `docs/file-format-parity.md` |
| Data | `json csv tsv` as data footage (plain `file.import`; Lottie needs `file.importLottie`) | `crates/engine/src/commands/file.rs:559-564` |
| Lottie | `.json`, `.lottie` via `file.importLottie` | `crates/engine/src/commands/lottie.rs:29-51` |
| Timelines | `.xml` (FCP7), `.fcpxml`, `.otio`, `.edl`, `.aaf`, `.omf` | `crates/interchange/src/lib.rs:1-18` |
| Color / fonts | LUTs `.cube .3dl .csp .spi1d/.spi3d` CDL; bundled + installed fonts, `EFFECTCRAFT_FONT_DIRS`, variable fonts via `text.fonts` | `docs/file-format-parity.md`, `crates/text/src/font_dirs.rs` |

`.json` through plain `file.import` is **data footage**, not Lottie — use `file.importLottie`.
PSD/PDF/AI/EPS import as footage or as a composition (`importAs`); PSD groups become precomps,
text becomes editable, effects map best-effort to Layer Styles
(`crates/engine/src/psd_import.rs`, `crates/engine/src/commands/file.rs:334-354`).

### Export formats

The Render Queue writes **13 formats** (`crates/project/src/render_queue.rs:501-545`):

| Family | Formats |
|---|---|
| Video | H.264 MP4 (+AAC), HEVC MP4 (`hvc1`, Main/Main 10), AV1 MP4 (`av01`), ProRes MOV (Proxy→4444 XQ; 4444 with alpha), uncompressed 8-bit MOV, WebM (VP9 or AV1 + Opus) |
| Stills | PNG, JPEG, TIFF, OpenEXR (32-bit float) sequences; animated GIF; single frame also as **layered PSD** (Composition ▸ Save Frame As ▸ Photoshop Layers) |
| Audio | WAV, AIFF (16-bit PCM) |

Render Settings/Output Modules cover quality, resolution, time span, frame rate, proxy use,
effects/solo/guide/depth overrides, color depth, field rendering + 3:2 pulldown, motion blur, skip
existing frames, storage overflow, crop/ROI/resize, extra outputs, post-render actions and logs
(`crates/project/src/render_queue.rs:324-360`).

- **Lottie** `.json`/`.lottie` with a `warnings` list for what Lottie cannot express
  (`crates/engine/src/commands/lottie.rs:24-51`, `crates/lottie/src/lib.rs`).
- **Timeline interchange** `.xml` (FCP7 default), `.fcpxml`, `.otio`, `.edl`, `.aaf`, `.omf`;
  `prerender: none|unsupported|all` chooses what becomes ProRes 4444 media instead of clips
  (`timeline.rs:143-148`, `crates/interchange/src/lib.rs:1-18`).
- **Essential Graphics template `.ectemplate`** is a ZIP (`manifest.json`, `project.ecproj`,
  `media/`, `poster.png`); **animation preset `.ecpreset`** is JSON tagged
  `effectcraftAnimationPreset` (`essential.rs:11,860-870`, `animation.rs:16-17`).

### Automation and platform

- **CLI** `effectcraft-cli`: `info/commands/exec/run/props/get/set/render-frame/render/bench/
  script/mcp` with `--json`, `--project`, `--demo`, `--empty`, `--save`, `--save-as`, `--bridge`,
  `--gpu`; `render` exposes per-codec flags (`--bitrate --prores --profile --level
  --rate-control --video-quality --keyint --webm-codec --audio-bitrate --opus-app --audio`) and
  `--progress` (`apps/effectcraft-cli/src/main.rs:87-127,131-192`).
- **MCP** over stdio: 36 tools (27 headless, 9 bridge-only: `screenshot`, the seven `ui_*`, and
  `control`) plus `effectcraft://document`/`commands` resources; progress notifications and
  cancellation for renders (`crates/automation/src/tools.rs`, `docs/mcp.md`).
- **Control channel**: `effectcraft --control <port>` (or `EFFECTCRAFT_CONTROL_PORT`) speaks
  newline JSON on `127.0.0.1`: `engine.execute`, `ui.menu.invoke`, `engine.commands`,
  `ui.menu.list`, `render.frame`, `ui.inspect`, `ui.elements`, `ui.set`, `ui.panel.show/close`,
  `ui.playback`, `ui.resize`, `ui.focus`, `ui.screenshot`, `ui.click/move/drag/scroll/key/type`,
  `ui.viewer.locate/hit`, `ui.timeline.locate`, `app.quit`, plus window/workspace commands
  (`crates/ui-egui/src/control.rs:176-458`, `docs/control-protocol.md`).
- **Scripts/ScriptUI**: `.jsx`/`.js` with the AE object model (`app.project`, match names,
  `Socket`, `$.evalFile`, `#include`, `app.scheduleTask`), dockable ScriptUI panels that reopen at
  launch, `script.run`, `file.runScript`, CLI `script FILE.jsx` and `script --eval CODE`
  (`docs/plugins.md`, `docs/scripting-parity.md`, `crates/script/src/lib.rs`).
- **WebAssembly effect plug-ins**: `.wasm`/`.wat`, API v1, sandboxed in `wasmi`; the settings
  `Plug-ins` folder loads at startup (`crates/plugin/src/lib.rs`, `apps/effectcraft/src/main.rs:235-238`).
- **Web build** (`apps/effectcraft-web`) runs the same engine/UI as WASM with OPFS/IndexedDB
  storage and `window.effectcraft` (`execute`, `request`, `renderFrame`, `screenshot`, `addFile`,
  `files`, `saveToBrowser`, `listStored`, `flush`, `info`); it is not the installed macOS app.
  The wgpu compute compositor covers Metal/Vulkan/Direct3D 12/WebGPU; CPU is the reference,
  desktop defaults to GPU, headless CLI is CPU unless `--gpu`
  (`docs/web.md:380-407`, `crates/gpu/src/lib.rs:1-3`).
- **Localization**: menus in 10 languages (ja, zh-hans, zh-hant, uk, es, pt-br, ru, fr, de, cs);
  panels translated for 6 (`crates/ui-egui/src/i18n.rs:16`, `docs/gaps.md` gap 16).

## Known limitations and not-implemented

- **After Effects projects will not open.** No `.aep`/`.aepx` reader, no `.ffx` presets, no
  `.mogrt` templates, no `.aet`/`.ars`/`.aom`, no AE SDK plug-ins (`.aex`/`.plugin`).
  Only `.ecproj`/`.ecprojx`, `.ecpreset` and `.ectemplate` are native
  (`docs/file-format-parity.md:21-34`, `docs/gaps.md` gaps 1/19/23).
- **Fidelity against After Effects is mostly unmeasured.** One live comparison exists (scalar
  ease, 168 samples, all passing); everything else is self-graded (`docs/gaps.md` gap 2,
  `docs/fidelity/`). Never promise AE-identical renders.
- **No hardware video decode/encode** (VideoToolbox, NVENC, Quick Sync, VA-API). HEVC/AV1 have no
  B-frames, multi-reference or SAO/CDEF, so files are larger (`docs/gaps.md` gaps 15/22).
- **Output/import gaps**: no 16-bpc uncompressed, AVI (listed in the Media Browser but no
  demuxer), lossless single-file video, MXF output, DNxHR, DPX/Targa/Photoshop sequences or ProRes
  RAW; no USD/USDZ, Substance `.sbsar`, camera raw, HEIF/AVIF, BRAW/R3D/ARRIRAW
  (`docs/file-format-parity.md`, `docs/gaps.md` gap 17).
- **FBX/DPX/PDF caveats**: FBX is 7.x only, with no animation, skinning, cameras or lights;
  DPX/Cineon log values are shown as stored (no log-to-linear); PDF/AI/EPS import lacks JPX/JBIG2
  and Illustrator procset EPS (`docs/file-format-parity.md`).
- **Scripting gaps**: no `.jsxbin`, no Startup/Shutdown script folders, no script shortcuts, no
  Legacy ExtendScript engine mode (`docs/scripting-parity.md`, `docs/plugins.md`).
- **Alpha stability**: crash reports open as of the 12 Oct 2026 audit (#580, #501, #426, #341,
  #234, #879); Linux/Windows lag macOS; no CI gate on PRs (`docs/gaps.md` gaps 3/4/6).
- **The macOS `.app` contains no CLI** — get the universal `effectcraft-cli` from its separate
  release zip or build it (`docs/agents.md`). **The control channel has no authentication**, binds
  `127.0.0.1`, serves at most 16 connections, and lets anyone who reaches it run commands, read
  the project and take screenshots (`docs/control-protocol.md`).
- **Docs drift — trust code/runtime.** `docs/gaps.md` gap 18 still says no relinking, but
  `footage.relink`/`file.relinkFootage` and moved-project search exist
  (`crates/engine/src/commands/relink.rs`, `relink_moved.rs`). `README.md` says 306 effects; the
  registry and `app.capabilities` say 307. The bundle declares QOI, which `STILL_EXTENSIONS`
  omits (`packaging/macos/Info.plist.in:112-123`, `crates/media/src/lib.rs:61-63`).

## How to operate

### Launch (macOS)

```sh
open -a EffectCraft                                  # empty Untitled Project (not the demo)
open -a EffectCraft /path/to/Project.ecproj          # open a project
open -a EffectCraft --args --control 9877 --demo     # agent-driven window + demo project
/Applications/EffectCraft.app/Contents/MacOS/EffectCraft --control 9877 --demo --home
```

Flags: `--control <1-65535>` (or `EFFECTCRAFT_CONTROL_PORT`), `--demo`, `--empty`, `--home`,
`--version`; after `--` every argument is a file (a bare file opens a project or imports media).
Unknown options exit 1 before the window opens (`apps/effectcraft/src/main.rs:59-101`). The app
starts **empty** by default, unlike most one-shot CLI commands, which start with the demo.

### CLI

`effectcraft-cli` is a separate macOS release zip (signed/notarized) or
`cargo build --release -p effectcraft-cli`; it is **not** inside the `.app`. Verify with
`effectcraft-cli --version`; this pin is 0.14.0. If the launcher updates the app, re-read
`effectcraft-cli commands --json`. `<comp>` is an id, name or `-` (active comp); `<layer>` is an
id, `#n` or name; values are JSON (`50`, `[960,540]`, `"#ff0000"`) or bare strings.

- **Most commands open the demo project** unless you pass `--project F.ecproj`, a positional
  `*.ecproj`, or `--empty`. `commands`, `script` and `mcp` start empty.
- `--save` writes back to the opened project, `--save-as F` writes a copy; without either,
  headless edits are memory-only. `--json` prints one compact JSON document; errors become
  `{"error": …}` and exit 1; usage errors exit 2 before running. `--gpu` attaches the GPU
  compositor; CPU is the default.
- `--autosave` is MCP-only; `--bridge PORT` drives `effectcraft --control PORT` and cannot be
  combined with `--project`/`--demo`; `render` refuses bridge mode (`main.rs:340-344,626-627,693-694`).
- `render` needs `--out` (or `--queue`); a relative `--out` is against the **working directory**,
  while queued outputs resolve against the project folder. `render --comp …` renders exactly one
  item; `render --queue` uses the project's queue settings. `--progress` prints
  `progress <done> <total> <elapsed> <left>` lines on stderr (`main.rs:689-706`).
- `render-frame` writes `frame.png` by default; accepts `--time`, `--frame`, `--max-side`,
  `--scale`, `--transparent`. `--template T.ectemplate --values values.json` renders one Essential
  Graphics instance (values ≤ 1 MiB); it cannot combine with `--project`, `--demo`, `--bridge`,
  `--queue` or `--comp` (`apps/effectcraft-cli/src/template.rs:69`).
- `mcp --automation-read-root DIR / --automation-write-root DIR` (repeatable) confine agent file
  access; scripts and UI-driving tools are refused while confined (`docs/mcp.md`).

### Document model and workflow

One project per app process in one window; compositions open as tabs and are restored with the
project (`crates/project/src/lib.rs:53`, `docs/architecture.md` §3). Panels follow After Effects
(Project, Composition, Timeline, Effect Controls, Effects & Presets, Character, Paragraph, Align,
Info, Preview, Audio, Render Queue), dock/float, and any panel can move to its own native window.
Each layer carries a property tree addressed by paths such as `transform/position`,
`effects/#1/blurriness` or `@<uid>`.

1. Create a composition (`comp.new`) and add layers (`layer.new*`, `file.import`).
2. Animate (`prop.set`/`prop.addKey`; `timeBase: "comp"` for comp seconds on offset or stretched
   layers) and ease (`keys.select` + `keys.easyEase` in one session).
3. Apply effects (`effect.apply`), edit their `effects/#1/...` paths, preview and save.
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

Each headless CLI invocation is a new session: edits survive only if saved, and editor state such
as key selection never does; group selection-dependent steps in one `run` (or one MCP session).

### Open / save / export, exact formats

- **Open** `.ecproj`, `.ecprojx`, or `.xml` whose root is `EffectCraftProject`;
  `file.importProject` merges instead (`file.rs:45-52`). **Save** `.ecproj`, or XML when the path
  is `.ecprojx`; Save a Copy As XML and Increment and Save exist (`file.rs:86-91`).
- **Export** the 13 Render Queue formats, single-frame layered PSD, Lottie `.json`/`.lottie`,
  timeline formats, `.ectemplate`, `.ecpreset`. A `.xml` path is ambiguous: `file.open` expects an
  EffectCraft XML project, while `file.importTimeline` expects FCP7 XML — use `.ecprojx` for
  projects.

### Keyboard shortcuts (only verified ones)

`Cmd+N` New Composition, `Cmd+Alt+N` New Project, `Cmd+O` Open, `Cmd+S` Save, `Cmd+Shift+S` Save
As, `Cmd+M` (or `Cmd+Shift+/`) Add to Render Queue, `Cmd+I` Import, `Cmd+K` Composition Settings,
`Cmd+Shift+X` Trim Comp to Work Area, `Cmd+Alt+;` Settings, `F9` Easy Ease (`Shift+F9` in,
`Cmd+Shift+F9` out), `Cmd+Alt+K` Keyframe Interpolation, `Cmd+Shift+K` Keyframe Velocity,
`Cmd+Alt+H` Toggle Hold, `Cmd+Alt+T` Enable Time Remapping (command registry `shortcut` fields,
e.g. `crates/engine/src/commands/file.rs:727-738`, `prop.rs:1364-1384`). Property reveals
`A/P/S/R/T/M/F/E/L/U`, their double presses and `Alt+Shift+A/P/S/R/T` keying are in `docs/agents.md`
§Timeline. For anything else, read `effectcraft-cli commands --json`; do not invent shortcuts.

## Working with an AI agent

### Choose the surface

- **Headless (preferred)**: `effectcraft-cli exec/run` for one-shots or `effectcraft-cli mcp` for
  a persistent session. Headless MCP starts empty; add `--demo` or `--project`; `mcp --autosave`
  checkpoints dirty work after each mutating call (`docs/agents.md` §MCP setup).
- **Live app**: start `effectcraft --control 9877`, then `mcp --bridge 9877` or the raw control
  channel; bridge mode adds `screenshot`/`ui_*` and the CLI cannot drive UI
  (`docs/control-protocol.md`). **Web**: no TCP channel; use `window.effectcraft`
  (`docs/web.md:380-407`).

### Prepare inputs

- Convert unsupported sources: camera raw/AVI/BRAW/R3D/USDZ/Substance → H.264/ProRes/WebM or
  PNG/EXR/TIFF sequences; 3D → glTF/GLB/OBJ/STL/FBX 7.x; audio → WAV/AIFF; data → JSON/CSV/TSV.
- Image sequences: pass one numbered file with `sequence: true` (or import the folder) so the run
  is one footage item; missing numbers become color bars. Keep media next to the project: stored
  paths are absolute, and relative paths resolve against the project folder on open
  (`docs/footage.md`, `crates/engine/src/doc_path.rs`).
- Query `list_fonts`/`text.fonts` first and use a listed family and style (variable fonts expose
  named instances and accept PostScript names); extra fonts come from `EFFECTCRAFT_FONT_DIRS`.

### Inspect and repair project files

- `.ecproj` is documented by the code, not a public spec: `savedBy`, `schema`, `settings`,
  `items`, `nextId`, `renderQueue` (`crates/project/src/lib.rs:1363-1381`). Item, layer and
  property ids share one counter; keep `nextId` above every id. Never bump `schema`; a newer
  schema is refused rather than rendered wrongly (`crates/project/src/lib.rs:1565-1567`).
- Prefer commands over JSON surgery: `info`, `props`, `get` and `exec` validate through the same
  reader the app uses. After a hand edit, reopen and check the `repaired` list in `file.open`'s
  result (`crates/engine/src/commands/file.rs:49-65`).
- For moved media: `footage.missing`, `footage.relink {item, path}` (also relinks other missing
  files in the same place) or `file.relinkFootage {folder, dryRun}`; do not rewrite paths blindly
  (`crates/engine/src/commands/relink.rs`, `relink_moved.rs`). `.ectemplate` (ZIP) and `.ecpreset`
  (tagged JSON) are inspectable, but re-export through the app after edits
  (`essential.rs:860-870`, `animation.rs:16-17`).

### Verify exports

- Read the result: `renderQueue.render` returns per-item statuses; CLI `render` exits 1 if any
  item failed, and `exec`/`run` treat a failed render as an error (`apps/effectcraft-cli/src/main.rs:662`).
- Re-import the output and render a frame (`file.import`, `render_frame`) to prove it decodes; use
  `--transparent`/`transparent: true` for alpha (`docs/agents.md` §Cookbook).
- Lottie: inspect `warnings`; timeline: inspect `warnings`, `missing` and `prerendered`
  (`prerender: none` omits layers a timeline cannot represent, `unsupported` (default) pre-renders
  those to ProRes 4444, `all` pre-renders every visual layer; `lottie.rs:24-26`,
  `crates/interchange/src/lib.rs`).
- Odd comp sizes: H.264/HEVC dimensions round down to even
  (`crates/project/src/render_queue.rs:599-603`).

### Do not

- Try to open `.aep`/`.aepx`/`.aex`/`.ffx`/`.mogrt`/`.prproj`; there is no reader. Convert
  timelines to FCP7 XML in Premiere first; expect only `.wasm` plug-ins, `.ecpreset` and
  `.ectemplate` (`docs/plugins.md`, `docs/file-format-parity.md`).
- Drive the GUI without `--control` (no UI-scripting fallback; discover widgets with
  `ui.elements`), edit a `.ecproj` the app has open (it will overwrite your changes), or expose
  the control port (no authentication) (`docs/control-protocol.md`).

### Concurrency and safety

- Save early; `open_project`/`file.newProject` replaces a dirty project without a prompt. Without
  `--autosave`, MCP work is memory-only (`docs/agents.md` §Keeping headless work, §Pitfalls).
- After a broken bridge connection, mutating calls have an **unknown outcome**; inspect before
  retrying. `batch` is atomic and rolls back on a failing step; `command_batch` stops at the
  first error by default (`docs/mcp.md`, `docs/agents.md` §MCP setup).
- Scripts may read files only in the project's folder and cannot write or use the network unless
  Settings ▸ Scripting & Expressions allows it; confine agent file access with
  `--automation-read-root` / `--automation-write-root` (`docs/agents.md` §CLI, `docs/mcp.md`).

## Verification protocol

Alpha-software discipline; run this for every delegated task.

1. **Copy first.** Work on a scratch `.ecproj` (`--save-as` / Save a Copy), never the only copy;
   update the app only between projects.
2. **Round-trip in a fresh process.** New → comp/layers/keyframes/effects → save → reopen via
   `info --project` → render a frame and a short movie. A save that cannot be read back is a bug; report it.
3. **Check both artifacts.** A `render-frame` PNG at a known time and the final MP4/MOV/sequence;
   confirm dimensions, duration/frame count, audio and alpha, and for sequences every `#####`
   frame. Read `renderQueue.render` statuses; check the output file exists and is non-zero.
4. **Check the time span.** Queued items default to **Work Area**; CLI `render` defaults to the
   whole comp unless `--work-area`. An empty render is usually this, not a codec failure
   (`render_queue.rs:368`).
5. **Check format constraints.** H.264/HEVC even dimensions; ProRes 4444 for alpha; WebM VP9 for
   VP9 alpha; WAV/AIFF are 16-bit PCM; EXR is 32-bit float (`render_queue.rs:501-603`).
6. **Interchange and Lottie:** inspect warnings/missing/prerendered, re-import the result, and
   open Lottie in an independent player if available. Record versions and `savedBy`.
7. **Report, don't hide.** Give the exact command, version, file and observed result. Fidelity
   differences against After Effects are expected and are the most useful report.

## Sources & evidence

- Repository: `https://github.com/storytold/effectcraft`; inspected tag `v0.14.0`, commit
  `26b40199b72121aa7f4e55a63718e1b4dd48a859` (`git rev-parse HEAD`, 2026-10-22). Fast-moving
  alpha — verify against your installed version (`effectcraft-cli --version`; the app's
  `Info.plist` `EffectCraftBuildCommit`).
- Installed app at this pin: version 0.14.0, bundle `ai.storyteller.effectcraft`, build commit
  `26b40199b72121aa7f4e55a63718e1b4dd48a859`, universal `x86_64`+`arm64`, macOS 11+. Written
  2026-10-22; no GUI was launched.
- Read: `README.md`, `Cargo.toml`, `ROADMAP.md`, `AGENTS.md`; the `docs/` set (`agents`, `mcp`,
  `control-protocol`, `architecture`, `file-format-parity`, `gaps`, `target-app-parity`,
  `preferences`, `footage`, `plugins`, `scripting-parity`, `web`, `effects`); the CLI and app
  entry points (`apps/effectcraft-cli/src/{main,template}.rs`,
  `apps/effectcraft/src/{main,control_server}.rs`); `crates/project/src/{lib,render_queue,styles,
  limits}.rs`; the engine command modules cited above; `crates/{media,interchange,lottie,expr,
  keyframe,plugin,automation}/src`, `crates/effects/src/{lib,catalog}.rs`,
  `crates/color/src/blend.rs`, `crates/ui-egui/src/{control,i18n}.rs`,
  `crates/engine/presets/*.json`; source, generated docs, tests and bundle metadata only.

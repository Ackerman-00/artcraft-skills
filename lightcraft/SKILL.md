---
name: lightcraft
description: LightCraft is a native photo library and non-destructive raw developer — an open-source, clean-room reimplementation of Adobe Lightroom — written in pure Rust (macOS app at /Applications/LightCraft.app, plus a separate `lightcraft-cli` and a WebAssembly web build). Trigger this skill whenever the user mentions LightCraft, `.lcpreset`, a LightCraft library folder (`catalog.snap` / `catalog.log`), `lightcraft-cli`, or the LightCraft control/MCP server; asks what LightCraft can import, develop or export (RAW: DNG/CR2/CR3/ARW/NEF/RAF/RW2/ORF/PEF/SRW; export: JPEG/PNG/TIFF/WebP/AVIF/JPEG XL/PSD/DNG/original); asks about its menus or keyboard shortcuts; wants to automate, script, batch-render or agent-drive it (CLI `run`/`render`/`snapshot`/`merge`/`mcp`, JSON-lines control channel on 127.0.0.1, MCP tools); wants to prepare inputs, migrate a Lightroom Classic catalog, or repair a library folder; wants exports, XMP sidecars or camera colour profiles verified; or troubleshoots it. Trigger even when the app is not named but the job is photo-library or raw-development work — "cull this shoot", "develop this RAW", "apply a preset and export JPEGs", "import my Lightroom catalog", "why won't this CR3 open" — and prefer this skill over generic Lightroom advice, because LightCraft's formats and gaps differ from Adobe's in ways that matter.
---

# LightCraft

## Overview

LightCraft is a photo **library** plus a non-destructive **raw developer** — an open-source, clean-room
reimplementation of Adobe Lightroom Classic (the repo's stated target is Lightroom Classic 15.5 /
Lightroom 9.6), written from scratch in pure Rust with no C dependencies and no Adobe assets
(`README.md:21`, `ROADMAP.md:5`). Its three surfaces are the desktop app
(`apps/lightcraft`, eframe + wgpu + native macOS menus), `lightcraft-cli` (headless render, batch
commands, MCP server, UI snapshots), and a WebAssembly build of the same UI (`apps/lightcraft-web`).

**Maturity: alpha.** The project self-reports ~81.6% feature breadth against its Lightroom checklist but
only **~61% "ready for real work"**, ~51% for a mainstream practitioner (`ROADMAP.md:3`, `ROADMAP.md:15-20`).
The gap is quality and coverage — camera colour calibration, render fidelity, some raw formats, AI masks —
not missing buttons. Treat it as a working tool whose output must be verified, not as a Lightroom substitute.

Source: GitHub `storytold/lightcraft`, MIT OR Apache-2.0 (`Cargo.toml:8-10`). This skill documents
checkout `4f0b110bcbd2e350c6d97b47f1d824c2222295c4` (tag `v0.9.1`); the installed
`/Applications/LightCraft.app` reports the same version and build commit in its `Info.plist`
(`CFBundleShortVersionString 0.9.1`, `LightCraftBuildCommit 4f0b110…`). **verify against your installed
version** — the launcher auto-updates, and capability drift between releases is real.

## Capabilities (verified)

### Library and catalog — implemented

- The library **is a folder**, not a file format: `catalog.snap` (JSON snapshot) + `catalog.log`
  (append-only, CRC-32'd JSON-lines op log), plus `presets.json`, `view.json`, `prefs.json`, `thumbs/`
  and `Originals/` for copy-imported photos (`crates/engine/src/library.rs:1-15`).
- Crash-safe persistence: every top-level command persists and fsyncs before it returns; a torn final
  record is dropped and repaired on load; a failed write replies
  `"saved in memory but not written to disk: …; LightCraft will retry"` and stays queued
  (`crates/catalog/src/journal.rs:1-40`, `docs/control-protocol.md:137-147`).
- **One writer per library** — `catalog.lock`; a headless `--library` run on a folder the desktop app
  has open fails with "This library is already open in LightCraft (process N …)" (`docs/mcp.md:19-22`).
- Default location `~/Pictures/LightCraft Library` (`LIGHTCRAFT_LIBRARY` overrides)
  (`crates/engine/src/library.rs:61-70`).
- Albums, folders, smart albums (rule trees), stacks incl. auto-stack, virtual copies, versions,
  history, ratings/flags/labels, filter bar, field-aware search, sort, justified + square grids,
  filmstrip (`README.md:337`, `crates/engine/src/cmd/{organize,library,filters,query}.rs`).
- Compare and Survey culling views with synced zoom (`README.md:338`).
- Faces: XMP face names, face boxes and the People view work with no model; detection (YuNet) and
  recognition (SFace/AuraFace) are **opt-in model downloads**, run by LightCraft's own pure-Rust CPU
  interpreter (`docs/faces.md:6-24`, `crates/engine/src/cmd/face_{detect,recognize,models}.rs`).

### Import — implemented, with format caveats

- Importable extensions are a single list in `crates/engine/src/import.rs:36-43`: `jpg jpeg png tif tiff
  webp dng cr2 cr3 nef nrw arw raf orf rw2 rwl raw pef srw psd jxl gif bmp heic heif avif iiq crw mrw
  x3f kdc mos erf 3fr fff mef`. Support is decided by **file extension only**
  (`crates/engine/src/import.rs` `is_supported`).
- Modes **Add** (reference in place) / **Copy** / **Move** into the library, with rename and folder
  templates and duplicate detection (`crates/engine/src/import.rs:45-55`, `README.md:351`).
- **Decoded from sensor data** (verified per-model as of this release): DNG, Canon CR2/CR3 (lossless CRX
  Bayer + version 0x100/0x200 C-RAW), Sony ARW, Nikon NEF (uncompressed + lossless/lossy compressed),
  Fujifilm RAF (uncompressed and lossless/lossy compressed, Bayer and X-Trans), Panasonic RW2 / Leica
  RWL / Panasonic RAW, Pentax PEF, Olympus ORF (uncompressed, 12.8 bpp), Samsung SRW (uncompressed)
  (`README.md:345`, `docs/raw-parity.md:13-27`).
- Anything it cannot decode **falls back to the embedded camera JPEG preview** and is flagged
  `previewOnly` in `catalog.query` (`docs/mcp.md:232-241`).
- HEIC/HEIF decodes only when built with the `heif` feature — off by default, on in the official
  packaging (`apps/lightcraft/Cargo.toml:14-18`, `packaging/macos/package.sh:65`). AVIF is recognised but
  **not decoded** (`crates/engine/src/import.rs:41`).
- `library.importLightroom` / File ▸ Import Lightroom Catalog… — one-way and approximate
  (`docs/lightroom-catalog-import.md`, `docs/control-protocol.md:158-168`).

### Develop / Edit — implemented

- ~122 named develop sliders in one spec table (id, label, section, min, max, default, step) plus indexed
  Point Color controls (`crates/develop/src/controls.rs:141-166` and the `controls!` block at :170;
  `INDEXED` at :296). Sections: Light, Curve, Color, Mixer, BwMix, Grading, Effects, Vignette, Grain,
  Detail, Optics, Geometry, Profile, Calibration, PointColor, RedEye (`crates/develop/src/controls.rs:14-31`).
- Colour math is OkLCh-based; the pipeline is scene-referred linear Rec.2020 32-bit float with a filmic
  shoulder for raw and pass-through for untouched JPEGs (`README.md:75-105`, `README.md:298-299`).
- Masking: brush, linear/radial gradients, luminance and colour range, plus Subject / Sky / Background /
  People as **classical heuristics** (not AI) — combine with Add / Subtract / Intersect, invert; 15 local
  adjustments per mask (`README.md:340`, `docs/gaps.md:22`).
- Object / Describe masks use **SAM 3** through the optional model (not bundled); every other mask type
  works without it (`docs/ai-masks.md:6-9`).
- Crop & straighten (auto straighten, aspect ratios, flips, 90° rotations), Geometry transforms,
  Upright Auto/Level/Vertical/Full/Guided (`README.md:341`, `README.md:354`).
- Heal / Clone spots with auto source, Visualize Spots, Red Eye and Pet Eye (`README.md:347`).
- Photo Merge: HDR (auto-align, deghost), Panorama (spherical/cylindrical/perspective, boundary warp,
  auto crop), HDR Panorama → DNG; `lightcraft-cli merge hdr|panorama|hdr-panorama|hdr-batch`
  (`README.md:355`, `apps/lightcraft-cli/src/main.rs:83-90`).
- Deterministic re-renders across versions via **process versions** (V1 frozen, V2 current)
  (`docs/process-versions.md`).
- GPU: the whole develop pipeline as wgpu compute kernels on Metal/Vulkan/DX12, checked against the CPU
  within 1/255, with CPU fallback on device limits or errors (`README.md:356`, `docs/gpu-pipeline.md`).

### Presets, profiles, versions — implemented

- 18 built-in presets with an Amount slider; copy/paste/sync of chosen settings groups
  (`README.md:165-169`).
- LightCraft's own preset file is `.lcpreset` (`crates/engine/src/presets.rs:14`). Importing also accepts
  XMP presets, legacy `.lrtemplate`, Luminar `.lmp`/`.mplumpack`, `.zip` bundles and `.cube` LUT profiles
  (`crates/engine/src/presets.rs:158`, `docs/file-format-parity.md`).
- Adobe `.dcp` camera profiles and `.lcp` lens profiles are **deliberately never used** (clean-room policy)
  (`docs/file-format-parity.md`).

### Export — implemented

- Formats, from `ExportFormat` (`crates/engine/src/export.rs:14-64`): `jpeg png tiff psd webp avif jxl
  original dng rendereddng`. `psd` is a **flat** PSD (8/16-bit, no layers); `original` copies the file
  plus an XMP sidecar carrying the edits; `dng` writes a raw with edits embedded; `rendereddng` bakes the
  render into a linear 16-bit float DNG.
- Validated options (`crates/engine/src/export.rs:860-960`): `quality 1-100`, `bitDepth 8|10|16|32`,
  `colorSpace srgb|displayP3|adobeRgb|proPhoto|rec2020`, `metadata all|allExceptCamera|copyright|none`,
  `sharpen none|screen|matte|glossy`, `tiffCompression none|lzw|zip|deflate`,
  `dngCompression lossless|deflate|uncompressed|lossy`, `conflict unique|overwrite|skip`, resize by
  `longEdge|shortEdge|width|height|megapixels|percent` with `dontEnlarge`, `ppi`, `limitKb`, watermark,
  `hdr` / `hdrTransfer pq|hlg`, `jxlLossless`.
- File naming and folder-organization templates share one token set — `{name} {num} {seq:3} {date}
  {date:%Y%m%d} {folder} {camera} {lens} {iso} {rating} {title} {creator} {ext}`; unknown tokens stay as
  typed, illegal characters become `-`, and no target is ever overwritten (`crates/engine/src/rename.rs:1-20`).
- Contact sheet PDF (`crates/engine/src/contact_sheet.rs`) and Print-module layouts to a colour-managed
  PDF with the four layout styles (`README.md:257-284`, `docs/gaps.md:32`).
- Slideshow module: PDF / JPEG sequence / AV1 video in MP4 or WebM, no audio
  (`docs/control-protocol.md:95-96`).
- macOS only: `addToPhotos: true` (+ `photosAlbum`) hands exported files to Apple Photos
  (`docs/mcp.md:322-337`).

### Interchange — implemented

- XMP sidecars read and write, manual (⌘S) or automatic; LightCraft's own fields plus the full develop
  state as `lc:settings` under `http://ns.lightcraft.app/lc/1.0/`; foreign namespaces (`crs:`, `xmpMM:`, …)
  are kept byte for byte and an existing sidecar is merged into, never replaced (`docs/xmp-interop.md`).
- Reading Adobe `crs:` develop settings is **approximate** and reports per-photo warnings
  (`docs/xmp-interop.md`, `README.md:353`).
- GPX track logs, keyword list import/export, MWG face regions, focus points
  (`docs/file-format-parity.md`, `docs/focus-points.md`).
- macOS: Photo ▸ Edit In… writes a `-Edit` TIFF (default) or flat PSD copy, stacks it, and opens it in
  PhotoCraft if installed (`crates/engine/src/cmd/convert.rs:111+` and :413).

### Automation surface — implemented (the strongest part of the app)

- **Everything is a command.** 370 engine command specs (`crates/engine/src/cmd/mod.rs:139-182`; counted
  from the `cmd!` entries across `crates/engine/src/cmd/*.rs`) plus 183 UI commands in `UI_COMMANDS`
  (`crates/ui-egui/src/menus.rs:61`, counted from that array). `engine.commands` returns id, label, menu
  path, shortcut, parameter doc and current enablement; the MCP server and CLI both consume it.
- **Control channel**: `lightcraft --control 7980` (or `LIGHTCRAFT_CONTROL_PORT`) serves JSON-lines on
  `127.0.0.1:PORT`, loopback only, **no authentication**, requests answered on the UI thread with a 60 s
  timeout; a request that has not started and draws no frame for 5 s is failed and never retried
  (`docs/control-protocol.md:1-29`).
- **MCP server**: `lightcraft-cli mcp [--demo | --library DIR | FILES…]` headless, or
  `lightcraft-cli mcp --connect 127.0.0.1:7980` to drive the live app (adds screenshots, clicks, keys,
  pointer gestures). Hand-written JSON-RPC over stdio, protocol `2025-06-18`
  (`docs/mcp.md:1-14`, `docs/mcp.md:162-209`).
- **CLI subcommands** (`apps/lightcraft-cli/src/main.rs:28-114`, dispatch at :159-179): `run`, `mcp`,
  `render`, `snapshot`, `merge`, `synth-merge`, `denoise-serve`, `commands`, `controls`, `calibrate`,
  `--version`/`--help`.
- **Headless UI snapshots** need no window and no GPU: `lightcraft-cli snapshot --demo --script tour.jsonl
  -o out.png --size 1600x1000` (`apps/lightcraft-cli/src/main.rs:69-82`, `docs/control-protocol.md:242-282`).
- `lightcraft-cli calibrate` fits per-camera-model colour profiles from raws + their embedded JPEGs
  (`apps/lightcraft-cli/src/main.rs:107-112`).

### Platform — implemented

- Native macOS / Windows / Linux, FreeBSD tarball, static-site WebAssembly build running the same UI
  (WebGL2 via eframe's glow backend), with a persistent browser library in OPFS/IndexedDB
  (`README.md:516-561`, `docs/web.md:1-10`).
- 12+ interface languages via Edit ▸ Language (`README.md:429-430`, `crates/ui-egui/locales/`).
- Portable mode (`portable.txt` / `LightCraft.portable` beside the executable) and isolated automation
  profiles via `LIGHTCRAFT_CONFIG_DIR` (`apps/lightcraft/src/main.rs:766-790`,
  `docs/control-protocol.md:31-39`).

## Known limitations and not-implemented

Read this before proposing work. Each item is the project's own admission or a code path that is absent.

**Gaps that change what you can promise a user**

- **Camera colour is estimated, not measured.** Raws start from a per-file fit to the camera JPEG, 5 bundled
  profiles, or 52 spectral matrices; other raws fall back to a neutral matrix. The project's own measured ΔE
  against the camera JPEG is 2.9–10 (`docs/gaps.md:18`, `docs/raw-parity.md:25`).
- **No lens profile database.** Only in-file data (DNG opcodes, Panasonic/Leica RW2/RWL distortion, named
  Sony/Nikon corrections); Adobe's 3,635 profiles are never used — deliberately (`docs/gaps.md:25`, `docs/raw-parity.md:26`).
- **Render fidelity is unmeasured**: tone, highlights, texture/clarity/dehaze, NR and sharpening are tuned by
  eye, so edits imported from Lightroom will not look identical (`docs/gaps.md:20`).
- **Raw formats that open as a preview only**: compressed Olympus ORF (every OM/Olympus body since ~2008),
  Nikon High-Efficiency (HE / HE★) NEF, some CR3 variants (`crx.rs` refuses vertical-tile C-RAW, partial subband,
  multi-tile 0x200, adaptive low-frequency gains), compressed SRW, and the long tail IIQ / Hasselblad / X3F /
  CRW / MRW / GPR / old FinePix (`docs/gaps.md:19`, `docs/gaps.md:23-24`, `docs/gaps.md:37`).
- **PSD import is the merged composite only** — no layers, no layer styles; LightCraft writes flat PSDs. `.psb`
  is *not* importable: the codec parses PSB (`crates/codecs/src/psd.rs:49`) but `psb` is absent from
  `EXTENSIONS` and support is extension-based (`crates/engine/src/import.rs:36-43`, `docs/file-format-parity.md`).
- **AVIF cannot be imported** (no permissive pure-Rust AV1 decoder); AVIF is export-only
  (`docs/gaps.md:42`, `docs/file-format-parity.md`).

**Features that are partial or stubbed**

- **AI masks**: Subject, Sky, People, Background and Landscape are heuristics, not models; only Object and
  Describe use SAM 3, and **the model is not bundled** — without it those two offer a download and every other
  mask still works (`docs/gaps.md:22`, `docs/ai-masks.md:6-9`).
- **AI Denoise ships no weights**: models live in a per-user `denoise-models` folder and must be installed from
  an ONNX file with a `denoise-model.json` manifest; this build offers no downloads (`docs/denoise.md:14-24`).
  Bayer-only, and it does not run on merged linear DNGs (`docs/gaps.md:45`).
- **Absent: Super Resolution, Raw Details, content-aware/generative remove, reflections and distraction
  removal** (`docs/gaps.md:28-29`).
- **Print module**: no identity plate / watermark / page numbers / crop marks, no Auto Layout for Custom
  Package, no direct printer output or Page Setup — it produces a PDF (`docs/gaps.md:32`).
- **HDR display (EDR / Windows HDR) is not implemented**; HDR editing, the headroom limit and SDR rendition
  work, but you edit blind on an HDR monitor (`docs/gaps.md:31`). Export does support ISO 21496-1 gain-map JPEG,
  PQ AVIF and float TIFF (`README.md:349`).
- **Localization**: 9 of 15 shipped languages are partial; lower-layer errors stay English; no RTL or
  complex-script shaping (`docs/gaps.md:38`, `ROADMAP.md:79-99`).
- **Web build**: WebGPU is in progress, Safari/Firefox untested, JXL export native-only (`README.md:358`).

**Not implemented (do not assign)**

- Video (playback, trim, edits, export); Map view, Book module, publish services, tethered capture; any
  Lightroom plug-in ecosystem (`docs/gaps.md:33-36`).
- **No document file format.** LightCraft has no "save as" for an edited photo — the library folder is the unit
  of persistence and edits live in the catalog and/or an XMP sidecar. Note `packaging/macos/Info.plist.in:70`
  declares an exported "LightCraft Document" type with extension `pcraft`: that is a stale copy of PhotoCraft's
  extension, and no `.pcraft` handling exists in this repo. Do not try to open such a file as a LightCraft
  document.
- Rendering to DNG from the catalog UI, and AVIF import (`docs/gaps.md:42`).
- A measured camera-calibration database and a lens database; per-model verification is also thin — 545 of 1,446
  Adobe models verified, ~85% of photographers on a verified body (`docs/gaps.md:27`, `docs/raw-parity.md:13-27`).

## How to operate

**Launch (macOS).** `open -a LightCraft` for the GUI, or the binary directly when you need flags:
`/Applications/LightCraft.app/Contents/MacOS/LightCraft`. Real flags, all parsed in
`apps/lightcraft/src/main.rs:857-877` and documented at :766-790:

```
lightcraft [OPTIONS] [FILES/FOLDERS…]      # positional paths are imported at launch
  --library DIR    open (or create) this library (default ~/Pictures/LightCraft Library)
  --no-demo        don't seed a new library with the procedural demo photos
  --memory         throwaway in-memory session (alias --demo); writes nothing
  --control PORT   serve the JSON-lines control channel on 127.0.0.1:PORT
  --version, --help
```

Environment: `LIGHTCRAFT_LIBRARY`, `LIGHTCRAFT_CONTROL_PORT`, `LIGHTCRAFT_CONFIG_DIR` (isolated settings
profile), `LIGHTCRAFT_GPU_BACKEND=dx12|vulkan|metal|auto|off`, `LIGHTCRAFT_GPU=0`, `LIGHTCRAFT_LOG` /
`RUST_LOG`, `LIGHTCRAFT_NO_PREFS`, `LIGHTCRAFT_SAM3_DIR`, `LIGHTCRAFT_SAM3_MIRRORS`
(`apps/lightcraft/src/main.rs:766-790`). Logs: `~/Library/Application Support/LightCraft/logs/lightcraft.log`
on macOS, rotated on each start (`README.md:432-446`).

**The CLI is a separate download on macOS.** The `.app` contains only the desktop app
(`docs/mcp.md:93-101`); there is no `lightcraft-cli` in the bundle and none on `PATH` on a stock install.
Get it from the release assets (`lightcraft-cli-<ver>-macos-universal.zip`) or
`cargo build --release -p lightcraft-cli`. Use the CLI and the app from the same release.

**Window/document model.** One process = one window = one open library. There are no per-photo documents
and no tabs. Switching libraries is File ▸ Open Library… (`app.openLibrary`, ⌘O); File ▸ New Library…
(`app.newLibrary`). The workspace is a grid view (Photo Grid / Square Grid / People) and a Detail view,
with a filmstrip, and side panels (Library, Tools, Presets) that can be regrouped, split, floated inside
the window and saved (`README.md:637`, `docs/control-protocol.md:284-301`).

**Keyboard (verified against the command registry — do not invent others).** From
`crates/ui-egui/src/menus.rs:61+` and `docs/library-shortcuts.md`: `G` grid toggle, `D` detail, `N` survey,
`E` Edit panel, `C` Crop & Rotate, `M` Masking, `H` Remove, `I` Info, `K` Keywords, `Shift+P` Presets,
`Shift+V` Versions, `\` show original, `Y` before/after, `Shift+Y` split, `Z` toggle zoom, `J` clipping,
`A` Visualize Spots, `O` mask overlay, `Cmd+Z` undo, `Cmd+0` fit, `Cmd+Alt+0` 100%, `F` full-screen
preview, `Shift+F` filter bar, `/` filmstrip, `0`–`5` rating, `6`–`9` labels, `P` pick, `X` reject,
`U` unflag, `[`/`]` step rating, `Enter` open/done, `Esc` back to grid. **All keys are user-remappable**
(Help ▸ Keyboard Shortcuts, `app.setShortcut`); `Cmd+,` and `Cmd+Q` are reserved
(`crates/ui-egui/src/shortcuts.rs:19-20`).

**Open / save / export.** Import with File ▸ Import Photos… (`Cmd+Shift+I`) or by passing paths on the
command line. There is nothing to "save": each command persists, and File ▸ Automatically Write Changes
into XMP (`library.toggleAutoWriteXmp`, `crates/engine/src/cmd/xmp.rs:123`; preference command
`library.xmpPreferences`) or ⌘S (`photo.saveMetadataToFile`) writes sidecars.
Export with File ▸ Export… (`dialog.export`), Photo ▸ Edit In ▸ Edit in PhotoCraft / Edit in Other Editor
(`photo.editInPhotoCraft` ⌘⇧E, `photo.editInExternal` ⌥⌘E), File ▸ Contact Sheet PDF…, File ▸ Print… /
Print to PDF…, View ▸ Export Slideshow…, or the equivalent commands. The export itself is always
`app.export` with the option set above (`crates/engine/src/export.rs:860-960`).

**Driving it as an agent — the three supported routes**

1. One-shot CLI (best for batch work, no session state):
   ```sh
   lightcraft-cli run --import ~/Photos/shoot \
       develop.set control=light.exposure value=0.7 develop.auto \
       app.export path=/tmp/out longEdge=2048 colorSpace=displayP3
   lightcraft-cli run --library ~/lc-lib library.select ids=[3] develop.get
   lightcraft-cli run --connect 127.0.0.1:7980 ui.set view=detail ui.screenshot path=/tmp/ui.png
   lightcraft-cli render in.dng -o out.jpg --set light.exposure=0.5 --size 2048 --quality 92
   ```
   One JSON line per command (`{command, ok, result|error, ms}`); non-zero exit on failure; a bare word
   starts the next command, `key=value` values parse as JSON when they can
   (`docs/mcp.md:282-312`, `apps/lightcraft-cli/src/main.rs:28-53`).
2. Control channel (best for interacting with a live UI, or for external controllers):
   `{"id":1,"method":"engine.execute","params":{"command":"develop.set","params":{"values":{"light.highlights":-45}}}}`.
   Discover identifiers with `engine.commands`, `develop.controls`, `ui.widgets`; never hard-code
   translated labels or widget positions (`docs/control-protocol.md:170-234`).
3. MCP (`lightcraft-cli mcp`): helpers such as `import`, `query_photos`, `set_develop`, `crop`,
   `render_photo`, `export`, plus one generated tool per command (`cmd_develop_set`) unless `--compact`
   (`docs/mcp.md:162-209`).

**Look at the result.** Any UI work must be verified visually: `lightcraft-cli snapshot --demo
--script tour.jsonl -o out.png` or `{"method":"ui.screenshot","params":{"path":"a.png","headless":true}}`.
Before capturing, poll `ui.inspect` until `loupe.pending` is false and the render queues are empty
(`docs/control-protocol.md:52-58`).

## Working with an AI agent

**Legitimate agent work**

- Pre-generate or convert inputs into supported formats before touching the library: downsample/re-encode
  with any tool, produce JPEG/PNG/TIFF/DNG, and let LightCraft import. There is no ingest conversion step
  in LightCraft itself — an unsupported file stays unsupported.
- Batch develop and export through `lightcraft-cli run --import …`, or against a persistent library with
  `--library DIR` so ratings and edits survive between calls (`docs/mcp.md:289-300`).
- Batch-render one image with a settings JSON: `lightcraft-cli render in.dng -o out.jpg --settings
  look.json` (a partial develop-settings object, or a single-preset `.lcpreset`/XMP file) plus
  `--set control=value` (`apps/lightcraft-cli/src/main.rs:54-68`, :640-668).
- Inspect and repair library files: `catalog.snap` and `catalog.log` are documented, CRC-checked JSON
  (`crates/catalog/src/journal.rs:1-40`), and the loader already handles torn appends and damaged records;
  back the folder up before editing anything by hand.
- Verify exports by reading the returned `{path, width, height, bytes, sidecars}` and then the file itself;
  the encoder is pure (bytes in, bytes out) so it is testable without a window
  (`crates/engine/src/export.rs:1-5`).
- Read XMP sidecars to understand another tool's edits; LightCraft preserves foreign namespaces
  (`docs/xmp-interop.md`).
- Rebuild camera colour profiles from a user's own raws with `lightcraft-cli calibrate` (Sony ARW, Nikon
  NEF, Fujifilm RAF; needs ≥5 usable photos per model) (`apps/lightcraft-cli/src/main.rs:107-112`).

**Do not**

- Do not launch the GUI and drive it with OS-level synthetic input (osascript/System Events, cliclick):
  it goes to whatever window is frontmost. Use the control channel, `lightcraft-cli snapshot`, or MCP
  connect mode. `repo AGENTS.md` ("Never send OS-level synthetic input").
- Do not assume the CLI exists — on macOS it is a separate download, not inside the `.app`.
- Do not assume a library can be opened by two programs at once (`catalog.lock`); use `--connect` instead.
- Do not assume Adobe assets or formats work: `.dcp`, `.lcp`, `.lrtemplate`-as-output, Lightroom plug-ins.
  `.lrtemplate` is import-only; `.dcp`/`.lcp` are deliberately unsupported.
- Do not promise AI subject/sky masks, AI denoise or super resolution out of the box — they need optional
  models the user installs.
- Do not promise that a raw will develop from sensor data; check the format list above and expect
  preview-only for compressed ORF, HE NEF and some CR3 variants.
- Do not treat a returned command result as proof of a correct image. Nothing here validates the pixels.

## Verification protocol

LightCraft is alpha; its library is crash-safe but its output is not self-checking. For every non-trivial
task:

1. **Throwaway round-trip first.** Make a scratch library (`--library /tmp/lc-test`, or `lightcraft-cli
   run --demo`), import one file, change one slider, export, then reopen the export in LightCraft or any
   other viewer and confirm dimensions and pixels. Only then run the real batch.
2. **Never trust a silent export.** `app.export` reports per-file `{path, width, height, bytes, sidecars}`
   and can report `gpuFallback`; a size/resolution mismatch or a zero-byte file is the failure you would
   otherwise miss. `format: "original"` also writes an XMP sidecar — check for it before assuming the
   folder is unchanged.
3. **Check the render, not just the command.** `ok: true` means the command ran. Poll `ui.inspect` for
   `loupe.pending == false` (or `loupe.failed` for the reason) and take a screenshot/PNG before declaring
   success (`docs/control-protocol.md:52-58`).
4. **Version and back up per session.** Copy the whole library folder before a bulk operation; the catalog
   is an append-only log, so a copied folder is a complete restore point. File ▸ Back Up Library…
   (`file.backupLibrary`) exists for this. Use `--memory` when you only want to experiment — it writes
   nothing at all (`apps/lightcraft/src/main.rs:774`).
5. **Separate the app and the CLI release.** They must come from the same release
   (`docs/mcp.md:65-67`). Update the app between projects, never mid-project, and re-run step 1 after any
   update — the launcher auto-updates, and a new build can change rendering (that is exactly what process
   versions exist for; `docs/process-versions.md`).
6. **Know your single-writer rule.** Any `--library` headless run fails while the desktop app holds that
   library. Reserve it in your plan, or drive the open app with `--connect`.
7. **Treat the control port as a local privilege.** It has no authentication and can run any command;
   only enable it for a task that needs it, on loopback (`docs/control-protocol.md:27-28`).

## Sources & evidence

- Repo: https://github.com/storytold/lightcraft — inspected checkout
  **`4f0b110bcbd2e350c6d97b47f1d824c2222295c4`** (tag `v0.9.1`, `git rev-parse HEAD`, clean tree),
  2026-10-18. Installed app `/Applications/LightCraft.app` is version 0.9.1 with
  `LightCraftBuildCommit = 4f0b110bcbd2e350c6d97b47f1d824c2222295c4` in its `Info.plist`, i.e. the same
  build. Bundle id `ai.storyteller.lightcraft`.
- Files read for this skill: `README.md`, `ROADMAP.md`, `Cargo.toml`, `apps/lightcraft/Cargo.toml`,
  `apps/lightcraft/src/main.rs`, `apps/lightcraft-cli/src/main.rs`, `crates/engine/src/{import,export,library,
  presets,rename}.rs`, `crates/engine/src/cmd/{mod,convert,xmp,edit}.rs`, `crates/develop/src/controls.rs`,
  `crates/catalog/src/journal.rs`, `crates/codecs/src/{heif,sniff,psd}.rs`, `crates/ui-egui/src/{menus,
  shortcuts}.rs`, `packaging/macos/{Info.plist.in,package.sh}`, `omastore.toml`, `docs/mcp.md`,
  `docs/control-protocol.md`, `docs/gaps.md`, `docs/parity-checklist.md`, `docs/file-format-parity.md`,
  `docs/raw-parity.md`, `docs/xmp-interop.md`, `docs/process-versions.md`, `docs/denoise.md`,
  `docs/ai-masks.md`, `docs/faces.md`, `docs/web.md`, `docs/architecture.md`, `docs/library-shortcuts.md`,
  `docs/showcase/{run.py,demo.jsonl}`.
- Shared library `storytold/craft-libs` (read-only reference)
  provides `craft-ui` (pinned rev `5c874d51…`) and `craft-docpath` (`Cargo.toml:13-14`); LightCraft's own
  formats are documented in this repo, so nothing outside it was needed.
- Evidence tiers: **implemented** (the code path exists and is reachable from UI/CLI/command),
  **partial/stub** (exists but visibly incomplete — what is missing is stated), **not implemented**
  (absent or explicitly out of scope).

**Uncertain / not verified in this pass**

- Whether an explicit `library.import` of a single `.psb` path can bypass `is_supported` — uncertain, see
  `crates/engine/src/import.rs` (`is_supported` is extension-only, so it should not).
- Exact rendered output fidelity (tone, colour, sharpening) — the project itself states it is unmeasured
  (`docs/gaps.md:20`); this skill makes no claim about it.
- The `heif` feature's presence in a given user's build: the official macOS package enables it
  (`packaging/macos/package.sh:65`) and the installed binary contains heic-rs strings, but a `cargo build`
  from source without `--features heif` will not decode HEIC.
- Runtime behaviour of the GUI, menus and dialogs: nothing was launched during this pass; all GUI claims
  come from the command registry, the control protocol document and the packaging metadata.

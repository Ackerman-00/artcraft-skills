---
name: lightcraft
description: LightCraft is a native photo library and non-destructive raw developer — an open-source, clean-room reimplementation of Adobe Lightroom Classic — written in pure Rust (macOS app at /Applications/LightCraft.app, plus a separate `lightcraft-cli` and a WebAssembly web build). Trigger this skill whenever the user mentions LightCraft, `.lcpreset`, a LightCraft library folder (`catalog.snap` / `catalog.log`), `lightcraft-cli`, or the LightCraft control/MCP server; asks what LightCraft can import, develop or export (RAW: DNG/CR2/CR3/ARW/NEF/RAF/RW2/ORF/PEF/SRW; export: JPEG/PNG/TIFF/WebP/AVIF/JPEG XL/PSD/DNG/original); asks about its menus or keyboard shortcuts; wants to automate, script, batch-render or agent-drive it (CLI `run`/`render`/`snapshot`/`merge`/`calibrate`/`denoise-serve`, JSON-lines control channel on 127.0.0.1, MCP tools, `print.*`/`slideshow.*` commands); wants to prepare inputs, migrate a Lightroom Classic catalog, repair a library folder, fit camera colour profiles from raws, or use a lensfun lens database; wants exports, XMP sidecars or camera colour verified; or troubleshoots it. Trigger even when the app is not named but the job is photo-library or raw-development work — "cull this shoot", "develop this RAW", "apply a preset and export JPEGs", "import my Lightroom catalog", "why won't this CR3 open" — and prefer this skill over generic Lightroom advice, because LightCraft's formats and gaps differ from Adobe's in ways that matter.
---

# LightCraft

## Overview

LightCraft is a photo **library** plus a non-destructive **raw developer** — an open-source, clean-room reimplementation of Adobe Lightroom Classic 15.5 / Lightroom 9.6 (the repo's stated target, `ROADMAP.md:5`, `docs/target-app-parity.md:3`), written from scratch in pure Rust with no C dependencies and no Adobe assets (`README.md:21`, `AGENTS.md`). Its three surfaces are the desktop app (`apps/lightcraft`, eframe + wgpu + native macOS menus), `lightcraft-cli` (headless render, batch commands, MCP server, UI snapshots), and a WebAssembly build of the same UI (`apps/lightcraft-web`).

**Maturity: alpha.** The project self-reports 81.6% feature breadth over its 532-row Lightroom checklist but only **~61% "ready for real work"**, ~51% for a mainstream practitioner, ~65% for essentials use (`ROADMAP.md:15-19`). The gap is quality and coverage — camera colour calibration, render fidelity, some raw formats, AI masks — not missing buttons. Treat it as a working tool whose output must be verified, not as a Lightroom substitute.

Source: GitHub `storytold/lightcraft`, MIT OR Apache-2.0 (`Cargo.toml:6-9`). This skill documents tag **v0.11.0** (commit `ec0cda9a6f320e3b32f659f16718f7bce6c3f12f`); the installed `/Applications/LightCraft.app` is that same version (its binary's `--version` prints `lightcraft 0.11.0`). **verify against your installed version** — the launcher auto-updates, and capability drift between releases is real.

## Capabilities (verified)

### Library and catalog — implemented

- The library **is a folder**, not a file format: `catalog.snap` (JSON snapshot) + `catalog.log` (append-only, CRC-32'd JSON-lines op log, compacted in the background when it grows), plus `presets.json`, `view.json`, `prefs.json`, `thumbs/` and `Originals/` for copy-imported photos (`crates/engine/src/library.rs:1-24`; `crates/catalog/src/journal.rs`).
- Crash-safe persistence: every top-level command is journalled and fsynced before it replies; a torn final record is repaired on load; a failed write replies `"saved in memory but not written to disk: …; LightCraft will retry"` and keeps retrying — `ui.inspect` → `unsaved` and a top-bar icon report it (`docs/control-protocol.md:137-147`). **One writer per library** (`catalog.lock`): a headless `--library` run on a folder the app has open fails with "This library is already open in LightCraft (process N …)" (`docs/mcp.md:19-22`). Default location `~/Pictures/LightCraft Library` (`LIGHTCRAFT_LIBRARY` overrides) (`crates/engine/src/library.rs:33,61-68`).
- Albums in folders, smart albums (rule trees), stacks incl. auto-stack, virtual copies, versions, history, ratings/flags/labels, filter bar, field-aware search, sort, justified + square grids, filmstrip, and a **Local** mode that browses a disk folder without importing it (edits go to XMP sidecars; "Add to My Photos" adopts the photo) (`crates/engine/src/cmd/{organize,library,filters,query,browse}.rs`; `crates/engine/src/cmd/browse.rs:1-9`).
- Compare and Survey culling views with synced zoom, auto-advance, instant previews (`README.md` feature table).
- **Long-running tasks land in one activity stack**, visible to agents as `activity.list` / `activity.cancel` (imports, exports, merges, downloads, face scans); quitting asks first (`docs/background-tasks.md:1-10`).
- Faces: XMP face names, editable face boxes and the People view work with no model; detection (YuNet) and recognition (SFace/AuraFace) are **opt-in model downloads**, run by LightCraft's own pure-Rust CPU interpreter (`docs/faces.md:6-24`).
- Focus points: `photo.inspect` carries `meta.focus` when the file records one; View ▸ Show Focus Point (⌥F), zoom-to-focus, and a background `photo.readFocusPoints` sweep for older imports (Sony α1 and A7S III first) (`docs/control-protocol.md:117-123`, `docs/focus-points.md`).

### Import — implemented, with format caveats

- Importable extensions are one list of 36 in `crates/engine/src/import.rs` (`EXTENSIONS`): `jpg jpeg png tif tiff webp dng cr2 cr3 nef nrw arw raf orf rw2 rwl raw pef srw psd jxl gif bmp heic heif avif iiq crw mrw x3f kdc mos erf 3fr fff mef`. Support is decided by **file extension only** (`is_supported` there). Modes **Add** (reference in place) / **Copy** / **Move** into `Originals/`, with rename and folder templates and duplicate detection (`crates/engine/src/import.rs`).
- **Decoded from sensor data**: DNG, Canon CR2/CR3 (lossless CRX Bayer + version 0x100/0x200 C-RAW; R5 Mark II / R6 Mark II adaptive-QP C-RAW fixed), Sony ARW, Nikon NEF (uncompressed + lossless/lossy compressed, incl. lossy-after-split), Fujifilm RAF (uncompressed and lossless/lossy compressed, Bayer and X-Trans), Panasonic RW2 / Leica RWL / Panasonic RAW (all raw formats), Pentax PEF, Olympus ORF (uncompressed, 12.8 bpp), Samsung SRW (uncompressed), Epson ERF, Mamiya MEF (`README.md` RAW row, `docs/raw-parity.md:13-45`, `docs/cr3.md`, `docs/raf-compression.md`).
- Per-model coverage (measured, `docs/raw-parity.md:17-27`): of Adobe's 1,446 models, **545 verified**, 651 unverified-but-expected, **212 preview-only**, 38 unsupported; **~94% of photographers' cameras fully decode, ~85% on a verified body**.
- Anything it cannot decode **falls back to the embedded camera JPEG** and is flagged `previewOnly`; the app rechecks those photos in the background on version change; headless callers use `library.recheckPreviewOnly` (`docs/mcp.md:235-243`). Network-friendly preview reads take only header + embedded-JPEG ranges, not the sensor data (56.5 MB → 5.9 MB on the test share) (`docs/raw-preview-reads.md:1-13`).
- HEIC/HEIF decode only when built with the `heif` feature — off by default for HEVC-patent reasons, on in the official packaging (the installed binary contains HEIC decoder strings). AVIF is recognised but **not decoded** (`apps/lightcraft/Cargo.toml:16-18`, `packaging/macos/package.sh:65`, `crates/engine/src/import.rs`).
- `library.importLightroom` / File ▸ Import Lightroom Catalog… — one-way and approximate; main-file pages are read on demand up to 16 GiB (`docs/lightroom-catalog-import.md`, `docs/gaps.md:30`).

### Develop / Edit — implemented

- **122 named develop sliders** in one spec table (id, label, section, min, max, default, step, decimals, track) plus **8 indexed Point Color** specs addressed as `pointColor.<i>.<control>` (`crates/develop/src/controls.rs:170` `controls!` block; `INDEXED` at :296). Sections: Light, Curve, Color, Mixer, BwMix, Grading, Effects, Vignette, Grain, Detail, Optics, Geometry, Profile, Calibration, PointColor, RedEye (`crates/develop/src/controls.rs:14-31`).
- Colour math is OkLCh-based; the pipeline is scene-referred linear Rec.2020 32-bit float with a filmic shoulder for raw and pass-through for untouched JPEGs (`README.md:76-105`).
- Masking: brush (straight strokes via ⇧-click; `mask.brushStroke {connect: true}` for agents), linear/radial gradients, luminance and colour range, plus Subject / Sky / Background as **classical heuristics** (not AI) — combine with Add / Subtract / Intersect, invert; **17 local adjustments** per mask + Amount (`README.md` masking section, `docs/ai-masks.md`).
- Object / Describe masks use **SAM 3** through an optional model (not bundled; `LIGHTCRAFT_SAM3_DIR`); every other mask type works without it (`docs/ai-masks.md:6-9`).
- Crop & straighten (aspect ratios stay portrait after rotations now), Geometry transforms, Upright Auto/Level/Vertical/Full/Guided, and Constrain Crop that tightens the actual crop (`README.md` crop section, `docs/whats-new.md` 2026-10-15).
- Heal / Clone spots with auto source, non-generative Fill (PatchMatch), editable spot pins, Visualize Spots, Red Eye and Pet Eye (`README.md` Remove row).
- Photo Merge: HDR (auto-align, deghost incl. moving lights, deterministic order, bracket batching), Panorama (spherical/cylindrical/perspective, boundary warp, auto crop, full resolution up to 512 MP / 65,000 px), HDR Panorama → DNG; commands `merge.hdr|panorama|hdrPanorama|hdrBatch`; `lightcraft-cli merge hdr|panorama|hdr-panorama|hdr-batch` (`docs/merge.md:1-37`).
- Deterministic re-renders across versions via **process versions** (V1 frozen, V2 current; `develop.updateProcess`) (`docs/process-versions.md`, `crates/develop/src/settings.rs`).
- GPU: the whole develop pipeline as wgpu compute kernels on Metal/Vulkan/DX12, checked against the CPU within 1/255, with CPU fallback on device limits or errors (`docs/gpu-pipeline.md`, `README.md`).
- AI Denoise: per-photo switch, Bayer RAW only, **no weights bundled** (user-installed ONNX + `denoise-model.json`), results cached under `<library>/denoise/`; `lightcraft-cli denoise-serve` serves tiles to other machines over LAN/VPN (`LIGHTCRAFT_DENOISE_URL`/`_TOKEN`) (`docs/denoise.md:14-24`, `apps/lightcraft-cli/src/main.rs` USAGE).

### Presets, profiles, lens data — implemented

- **41 built-in presets** with an Amount slider (0–200%); copy/paste/sync of chosen settings groups (`crates/engine/src/presets.rs:215` `builtin()`). LightCraft's own preset file is `.lcpreset` (`crates/engine/src/presets.rs:14`). Importing also accepts XMP presets, legacy `.lrtemplate`, Luminar `.lmp`/`.mplumpack`, `.zip` bundles, `.cube` LUT profiles, and local-adjustment effect presets (Lightroom `.lrtemplate`/`.xmp`, LightCraft `.lceffect`) (`crates/engine/src/presets.rs:158`, `crates/engine/src/cmd/mask_effect_files.rs:19`, `crates/engine/src/cmd/lut_profiles.rs`).
- Camera colour starts from DNG matrices, guarded per-file fits to the camera JPEG, **8 bundled profiles** (Sony ILCA-99M2, ILCE-7CR, ILCE-7M4; Fujifilm X-H2S, X-T4; Nikon Z 6II, Z 8, D5300 in `assets/camera-profiles/`), 52 spectral matrices, or a neutral fallback. `lightcraft-cli calibrate` fits per-camera profiles from a user's own raws (`docs/raw-parity.md:24-25`, `docs/camera-preview-colour.md`).
- **Lens profiles from a user-supplied lensfun XML database**: set `LIGHTCRAFT_LENSFUN_DIR`; distortion, TCA and vignetting are matched from EXIF and applied through the same profile-corrections path. No database is bundled (lensfun is CC-BY-SA); Adobe `.dcp`/`.lcp` are **deliberately never used** (clean-room policy) (`crates/lensdb/src/lib.rs:1-14`, `crates/engine/src/lens_profiles.rs:15`, `docs/lens-profiles.md:1-14`, `docs/file-format-parity.md`).

### Export and output modules — implemented

- Formats, from `ExportFormat` (`crates/engine/src/export.rs:16-33`): `jpeg png tiff psd webp avif jxl original dng rendereddng`. `psd` is a **flat** PSD (8/16-bit, no layers); `original` copies the file plus an XMP sidecar carrying the edits; `dng` writes a raw with edits embedded (uncompressed, LJ92, Deflate or lossy JPEG tiles); `rendereddng` bakes the render into a linear 16-bit float DNG.
- Validated options (`crates/engine/src/export.rs:614-680` struct, :716-733 keys, :1089 quality clamp): `quality 1-100`, `bitDepth 8|10|16|32` (per format), `colorSpace srgb|displayP3|adobeRgb|proPhoto|rec2020` with embedded ICC, `metadata all|allExceptCamera|copyright|none`, `sharpen none|screen|matte|glossy` + amount, `tiffCompression none|lzw|zip|deflate`, `dngCompression lossless|deflate|uncompressed|lossy`, `conflict unique|overwrite|skip`, resize by `longEdge|shortEdge|width|height|megapixels|percent` with `dontEnlarge`, `ppi`, `limitKb`, text/image `watermark`, `hdr` with `hdrTransfer pq|hlg` (gain-map JPEG, PQ/HLG AVIF, PQ PNG/JPEG XL, float TIFF), `jxlLossless|jxlEffort|jxlProgressive`, `destinationMode: "sameAsOriginal"`, and macOS-only `addToPhotos` + `photosAlbum` (`docs/mcp.md` export helper, `docs/apple-photos.md`).
- File-naming and folder templates share one token set — `{name} {num} {seq:3} {date} {date:%Y%m%d} {folder} {camera} {lens} {iso} {rating} {title} {creator} {ext}`; unknown tokens stay as typed, illegal characters become `-`, and no target is ever overwritten (`crates/engine/src/rename.rs:1-20`).
- Contact Sheet PDF: A4/Letter, rows/columns, captions, 150 dpi sRGB; limits 1,000 photos, 100 pages, 256 MiB; atomic replace (`crates/engine/src/contact_sheet.rs:87-154`, `README.md` agents section).
- Print module, all as `print.*` commands (`print.get/set/reset`, `print.cell.add/move/resize/delete/stack/photo/page`, `print.layout.autoLayout`, `print.exportPdf`, `print.template.*`): Single Image, Contact Sheet, Picture Package (Auto Layout) and Custom Package, Zoom to Fill / Rotate to Fit, border and stroke, paper 4×6 to 13×19 and A3–A5 or custom, margins, rulers, saved templates, printer/paper ICC profiles, rendering intent, black point compensation, 8/16-bit colour-managed PDF; Page Options (page numbers, page info, crop marks) print on Single Image and Contact Sheet (`crates/engine/src/cmd/print.rs:340-343`, `README.md` print section, `docs/gaps.md:32`).
- Slideshow: playback plus background export to PDF (page per slide), numbered JPEG sequence, or AV1 video in MP4/WebM (no audio, ≤2 h); layouts, overlays, title screens and templates are commands (`slideshow.layout/overlays/titles/preview/templates.*/export/exportStatus`) (`docs/control-protocol.md:87-97`, `docs/slideshow.md`).

### Interchange — implemented

- XMP sidecars read and write, manual (⌘S `photo.saveMetadataToFile`) or automatic (`library.xmpPreferences {autoWrite, naming: stem|full}`); LightCraft's own fields plus the full develop state as `lc:settings` under `http://ns.lightcraft.app/lc/1.0/`; owned properties are replaced, capture time/GPS only when LightCraft has a value, **foreign namespaces kept byte for byte**, existing sidecar merged into, never replaced; writes are atomic; failed writes to an unreachable folder retry, and `library.retrySidecars` forces them (`docs/xmp-interop.md`).
- Reading Adobe `crs:` develop settings is **approximate** and reports per-photo warnings; Lightroom radial masks apply inside the circle as Lightroom does (`docs/xmp-interop.md`, `docs/whats-new.md` 2026-10-14).
- GPX track logs, offline reverse geocoding (GeoNames towns ≥15k; `metadata.reverseGeocode {maxDistance}`), keyword list import/export, MWG face regions (`crates/engine/src/cmd/geocode.rs`, `docs/file-format-parity.md`, `docs/focus-points.md`).
- macOS: Photo ▸ Edit In ▸ Edit in PhotoCraft / Edit in Other Editor renders a 16-bit `<name>-Edit.tif` (default; or flat `.psd`, or 8-bit) next to the original, stacks it, and opens it in the external editor; Edit Copy for External Editor takes at most 50 photos (`crates/engine/src/cmd/convert.rs:123-156,395-398`).

### Automation surface — implemented (the strongest part of the app)

- **Everything is a command.** 370 engine command specs (counted from `cmd!` entries across `crates/engine/src/cmd/*.rs`; wired by 37 `specs()` sources in `crates/engine/src/cmd/mod.rs:140-183`) plus 183 UI commands in `UI_COMMANDS` (`crates/ui-egui/src/menus.rs:61`). `engine.commands` returns id, label, menu path, shortcut, parameter doc and current enablement; the MCP server, CLI and control channel all consume it.
- **Control channel**: `lightcraft --control 7980` (or `LIGHTCRAFT_CONTROL_PORT`) serves JSON-lines on `127.0.0.1:PORT`, loopback only, **no authentication**, at most 16 connections; requests are answered on the UI thread with a 60 s timeout; a request that has not started and draws no frame for 5 s is failed and never retried; a malformed line closes the connection (`docs/control-protocol.md:1-29`). Methods cover engine/UI commands, `ui.inspect`, widgets and pointer gestures, `ui.dock` panel docking, clipboard, slideshow control, and headless-CPU screenshots (`docs/control-protocol.md:60-98,242-282,284-301`).
- **MCP server**: `lightcraft-cli mcp [--demo | --library DIR | FILES…]` headless, or `lightcraft-cli mcp --connect 127.0.0.1:7980` to drive the live app (adds screenshots, clicks, keys, clipboard, pointer gestures; reconnects after an app restart). Hand-written JSON-RPC over stdio, protocol `2025-06-18` (older revisions accepted). Helpers (`import`, `query_photos`, `set_develop`, `crop`, `render_photo`, `export`, …), shared core tools (`command_list`, `command_run`, `command_batch`, `doc_inspect`, `render_preview`), resources (`lightcraft://library`, `lightcraft://photo/active`, …), one generated `cmd_*` tool per command unless `--compact`, and export progress/cancellation (`docs/mcp.md:1-14,129-212,245-262,342-367`).
- **CLI subcommands** (`apps/lightcraft-cli/src/main.rs` USAGE + dispatch): `run`, `mcp`, `render`, `snapshot`, `merge`, `synth-merge`, `denoise-serve`, `commands`, `controls`, `calibrate`, `--version`/`--help`. `run` takes `--demo|--library DIR|--connect [ADDR]`, repeatable `--import`, a `--script FILE|-` of JSON lines, and `--keep-going`; `render` takes `--set control=value`, `--settings look.json|.lcpreset|.xmp`, `--preset ID`, `--size`, `--quality`, and any export option via `--opt KEY=VALUE`.
- **Headless UI snapshots** need no window and no GPU: `lightcraft-cli snapshot --demo --script tour.jsonl -o out.png --size 1600x1000 --scale 2` (`docs/control-protocol.md:242-282`).
- `lightcraft-cli calibrate [--max N] [--out DIR]` fits per-camera-model colour profiles from raws + their embedded JPEGs (Sony ARW, Nikon NEF, Fujifilm RAF; ≥5 usable photos per model; output `<config>/camera-profiles` or `$LIGHTCRAFT_CAMERA_PROFILES`) (`apps/lightcraft-cli/src/main.rs` USAGE).

### Platform — implemented

- Native macOS / Windows / Linux (deb/rpm/AppImage/Flatpak/tarball, riscv64 tarball), FreeBSD tarball, and a static-site WebAssembly build running the same UI (WebGL2 via eframe's glow backend) with a persistent browser library in OPFS/IndexedDB; WebGPU and Safari/Firefox testing are in progress; JXL export is native-only (`docs/web.md:1-8`, `README.md` downloads/platform rows). 14 interface languages via Edit ▸ Language (`crates/ui-egui/locales/`).
- Portable mode (`portable.txt` beside the executable) and isolated automation profiles via `LIGHTCRAFT_CONFIG_DIR` (`docs/control-protocol.md:31-39`, `apps/lightcraft/src/main.rs` HELP).
- Display colour management: macOS screen profile, Linux colord, or a chosen ICC file via Settings ▸ Display (`app.displayProfile` for agents) (`docs/display-profiles.md`).

## Known limitations and not-implemented

Read this before proposing work. Each item is the project's own admission or a code path that is absent.

**Gaps that change what you can promise a user**

- **Camera colour is estimated, not measured.** Raws start from a per-file fit to the camera JPEG, the 8 bundled profiles, or 52 spectral matrices; other raws fall back to a neutral matrix. The project's own measured ΔE against the camera JPEG is 2.9–10 (`docs/gaps.md:18`, `docs/raw-parity.md:24-25`). Note: `docs/gaps.md`/`docs/raw-parity.md` still say "5 bundled profiles" — `assets/camera-profiles/` has 8.
- **No bundled lens database.** Only in-file data (DNG opcodes, Panasonic/Leica RW2/RWL distortion, named Sony/Nikon corrections) plus the opt-in `LIGHTCRAFT_LENSFUN_DIR` database above; Adobe's 3,635 profiles are never used — deliberately. lensfun matching is automatic only (no manual picker), raws only, no fisheye distortion, and not yet validated against real photos (`docs/gaps.md:25`, `docs/lens-profiles.md:40-45`).
- **Render fidelity is unmeasured**: tone, highlights, texture/clarity/dehaze, NR and sharpening are tuned by eye, so edits imported from Lightroom will not look identical (`docs/gaps.md:20`).
- **Raw formats that open as a preview only**: compressed Olympus ORF (66 of 78 Olympus/OM models), Nikon High-Efficiency (HE / HE★) NEF, some CR3 variants (`crx.rs` refuses vertical-tile C-RAW, partial subband, multi-tile 0x200, adaptive low-frequency gains), compressed SRW, and the long tail IIQ / Hasselblad / X3F / CRW / MRW / GPR / old FinePix (`docs/gaps.md:19,23-24,37`).
- **PSD import is the merged composite only** — no layers, no layer styles; LightCraft writes flat PSDs. `.psb` is *not* importable: the codec parses PSB (`crates/codecs/src/psd.rs`) but `psb` is absent from `EXTENSIONS` and support is extension-based (`crates/engine/src/import.rs`).
- **AVIF cannot be imported** (no permissive pure-Rust AV1 decoder); AVIF is export-only (`docs/file-format-parity.md`, `docs/gaps.md:42`).

**Features that are partial or stubbed**

- **AI masks**: Subject, Sky, People, Background and Landscape are heuristics, not models; only Object and Describe use SAM 3, and **the model is not bundled** — without it those two offer a download and every other mask still works (`docs/gaps.md:22`, `docs/ai-masks.md:6-9`).
- **AI Denoise ships no weights**: user-installed ONNX + manifest; the default build offers no downloads (the optional RawNIND weights are GPL-3.0 and gated behind a release policy). Bayer-only, and it does not run on merged linear DNGs (`docs/denoise.md:14-24`, `docs/gaps.md:45`).
- **Absent: Super Resolution, Raw Details, content-aware/generative remove, reflections and distraction removal** (`docs/gaps.md:28-29`).
- **Print module**: no identity plate / watermark / photo-info overlays, no Cut Guides, no Auto Layout for *Custom* Package (Picture Package has it), no direct printer output or Page Setup, no JPEG output — it produces a colour-managed PDF (`docs/gaps.md:32`).
- **HDR display (EDR / Windows HDR) is not implemented**; HDR editing, the headroom limit and SDR rendition work, but you edit blind on an HDR monitor (`docs/gaps.md:31`). Export supports gain-map JPEG, PQ/HLG AVIF, PQ PNG/JPEG XL and float TIFF (`crates/engine/src/export.rs:587-612`, `README.md` HDR row).
- **Slideshow**: music and a dedicated module editor are missing (`README.md` slideshow row).
- **Localization**: 9 of 15 shipped languages are partial; lower-layer errors stay English; no RTL or complex-script shaping (`docs/gaps.md:38`). **Web build**: WebGPU in progress, Safari/Firefox untested, JXL export native-only (`README.md`, `docs/web.md`).

**Not implemented (do not assign)**

- Video (playback, trim, edits, export — clips are catalogued only); Map view, Book module, publish services, tethered capture; any Lightroom plug-in ecosystem (`docs/gaps.md:33-36`).
- **No document file format.** LightCraft has no "save as" for an edited photo — the library folder is the unit of persistence and edits live in the catalog and/or an XMP sidecar. (Earlier releases' macOS bundle declared a stale PhotoCraft `.pcraft` type; that declaration is **removed** at this release — `packaging/macos/Info.plist.in:54-57` states LightCraft has no document type of its own.)
- Rendering to DNG from the catalog UI (the `rendereddng` *export format* exists), and AVIF import (`docs/gaps.md:42`).
- A measured camera-calibration database and a bundled lens database; per-model verification is thin — 545 of 1,446 Adobe models verified, ~85% of photographers on a verified body (`docs/gaps.md:27`). Tests in CI run on FreeBSD only; macOS/Windows/Linux package but don't test (`docs/gaps.md:26`).

## How to operate

**Launch (macOS).** `open -a LightCraft` for the GUI, or the binary directly when you need flags: `/Applications/LightCraft.app/Contents/MacOS/LightCraft`. Real flags, parsed in `apps/lightcraft/src/main.rs` (HELP block):

```
lightcraft [OPTIONS] [FILES/FOLDERS…]      # positional paths are imported at launch
  --library DIR    open (or create) this library (default ~/Pictures/LightCraft Library)
  --no-demo        don't seed a new library with the procedural demo photos
  --memory         throwaway in-memory session (alias --demo); writes nothing
  --control PORT   serve the JSON-lines control channel on 127.0.0.1:PORT
  --version, --help
```

Environment: `LIGHTCRAFT_LIBRARY`, `LIGHTCRAFT_CONTROL_PORT`, `LIGHTCRAFT_CONFIG_DIR` (isolated settings profile), `LIGHTCRAFT_GPU_BACKEND=dx12|vulkan|metal|auto|off`, `LIGHTCRAFT_GPU=0`, `LIGHTCRAFT_LOG`/`RUST_LOG`, `LIGHTCRAFT_NO_PREFS`, `LIGHTCRAFT_NO_NATIVE_MENU`, `LIGHTCRAFT_SAM3_DIR`, `LIGHTCRAFT_SAM3_MIRRORS`, `LIGHTCRAFT_LENSFUN_DIR`, `LIGHTCRAFT_CAMERA_PROFILES`, `LIGHTCRAFT_DENOISE_MODELS|_URL|_TOKEN` (`apps/lightcraft/src/main.rs` HELP; CLI USAGE). Logs: `~/Library/Application Support/LightCraft/logs/lightcraft.log` on macOS, rotated on each start, 16 MiB cap (`README.md` logs section).

**The CLI is a separate download on macOS.** The `.app` contains only the desktop app (`docs/mcp.md:93-101`); there is no `lightcraft-cli` in the bundle and none on `PATH` on a stock install. Get it from the release assets (`lightcraft-cli-<ver>-macos-universal.zip`) or `cargo build --release -p lightcraft-cli`. Use the CLI and the app from the same release.

**Window/document model.** One process = one window = one open library. There are no per-photo documents and no tabs. Switching libraries is File ▸ Open Library… (`app.openLibrary`, ⌘O). The workspace is a grid view (Photo Grid / Square Grid / People) and a Detail view with a filmstrip; the Library / Tools / Presets panels can be regrouped, split and floated inside the window (`ui.dock`, `ui.dock.reset`) (`docs/control-protocol.md:284-301`). If the library can't be opened the app starts an empty in-memory session and asks (`ui.inspect` → `libraryProblem`); pointing Open Library at a Lightroom catalog offers the importer instead (`docs/control-protocol.md:150-168`).

**Keyboard (verified against the command registry and docs — do not invent others).** `G` grid, `D` detail, `N` survey, `E` Edit panel, `C` Crop & Rotate, `M` Masking, `H` Remove, `I` Info, `K` Keywords, `Shift+P` Presets, `Shift+V` Versions, `\` show original, `Y` before/after, `Shift+Y` split, `Z` toggle zoom (centres on the focus point when it has one), `J` clipping, `A` Visualize Spots, `O` mask overlay, `F` full-screen preview, `Shift+F` filter bar, `/` filmstrip, `V` black & white, `0`–`5` rating, `6`–`9` labels, `P` pick, `X` reject, `U` unflag, `` ` `` cycle flag, `[`/`]` step rating, `Shift+0-9/P/X/U` apply-and-advance, `=`/`-` grid thumbnail size, `⌥F` focus point overlay, `Enter` open/done, `Cmd+Z` undo (`crates/ui-egui/src/menus.rs` `UI_COMMANDS`; `crates/engine/src/cmd/library.rs:765,794-800`; `crates/engine/src/cmd/develop.rs:476`; `docs/library-shortcuts.md`). **All keys are user-remappable** (Help ▸ Keyboard Shortcuts, `app.setShortcut`); `Cmd+,` and `Cmd+Q` are reserved (`crates/ui-egui/src/shortcuts.rs:17`).

**Open / save / export.** Import with File ▸ Import Photos… (⌘⇧I, `file.addPhotos`) or by passing paths on the command line. There is nothing to "save": each command persists, and File ▸ Automatically Write Changes into XMP (`library.xmpPreferences`) or ⌘S (`photo.saveMetadataToFile`) writes sidecars. Export with File ▸ Export… (`dialog.export`), Photo ▸ Edit In (⇧⌘E / ⌥⌘E), File ▸ Contact Sheet PDF…, File ▸ Print… / Print to PDF…, View ▸ Export Slideshow…, or the equivalent commands. The export itself is always `app.export` with the option set above (`crates/engine/src/export.rs:614-680`).

**Driving it as an agent — the three supported routes**

1. One-shot CLI (best for batch work, no session state):
   ```sh
   lightcraft-cli run --import ~/Photos/shoot \
       develop.set control=light.exposure value=0.7 develop.auto \
       app.export path=outdir longEdge=2048 colorSpace=displayP3
   lightcraft-cli run --library ~/lc-lib library.select ids=[3] develop.get
   lightcraft-cli run --demo --script steps.jsonl --keep-going   # JSON lines; stdin works too
   lightcraft-cli run --connect 127.0.0.1:7980 ui.set view=detail ui.screenshot path=ui.png
   lightcraft-cli render in.dng -o out.jpg --set light.exposure=0.5 --size 2048 --quality 92
   lightcraft-cli render in.dng -o out.tif --opt colorSpace=displayP3 --opt bitDepth=16
   lightcraft-cli merge hdr-batch ~/Pictures/brackets            # every bracket set in the folder
   ```
   One JSON line per command (`{command, ok, result|error, ms}`); non-zero exit on failure; a bare word starts the next command, `key=value` values parse as JSON when they can (`docs/mcp.md:285-303`, `apps/lightcraft-cli/src/main.rs` USAGE).
2. Control channel (best for interacting with a live UI, or for external controllers): `{"id":1,"method":"engine.execute","params":{"command":"develop.set","params":{"values":{"light.highlights":-45}}}}`. Discover identifiers with `engine.commands`, `develop.controls`, `ui.widgets`; never hard-code translated labels or widget positions. Group slider bursts in `develop.beginInteraction` / `develop.endInteraction` (one undo step) (`docs/control-protocol.md:60-98,170-235`).
3. MCP (`lightcraft-cli mcp`): helpers plus `command_list` / `command_run` / `command_batch` / `doc_inspect` / `render_preview`, resources for polling, and one generated tool per command unless `--compact` (`docs/mcp.md:129-212`).

**Look at the result.** Any UI work must be verified visually: `lightcraft-cli snapshot --demo --script tour.jsonl -o out.png` or `{"method":"ui.screenshot","params":{"path":"a.png","headless":true}}`. Before capturing, poll `ui.inspect` until `loupe.pending` is false and the render queues are empty (`docs/control-protocol.md:52-58`).

## Working with an AI agent

**Legitimate agent work**

- Pre-generate or convert inputs into supported formats before touching the library: downsample/re-encode with any tool, produce JPEG/PNG/TIFF/DNG, and let LightCraft import. There is no ingest conversion step in LightCraft itself — an unsupported file stays unsupported.
- Batch develop and export through `lightcraft-cli run --import …`, or against a persistent library with `--library DIR` so ratings and edits survive between calls (`docs/mcp.md:296-298`).
- Batch-render one image with a settings JSON: `lightcraft-cli render in.dng -o out.jpg --settings look.json` (a partial develop-settings object, or a single-preset `.lcpreset`/XMP file) plus `--set control=value` and `--opt` for export options (`apps/lightcraft-cli/src/main.rs` USAGE).
- Inspect and repair library files: `catalog.snap` and `catalog.log` are documented, CRC-checked JSON (`crates/catalog/src/journal.rs`), and the loader already handles torn appends and damaged records; back the folder up before editing anything by hand.
- Verify exports by reading the returned `{path, width, height, bytes, sidecars}` and then the file itself; the encoder is pure (bytes in, bytes out) so it is testable without a window (`crates/engine/src/export.rs:1-5`).
- Read XMP sidecars to understand another tool's edits; LightCraft preserves foreign namespaces (`docs/xmp-interop.md`).
- Rebuild camera colour profiles from a user's own raws with `lightcraft-cli calibrate` (`docs/camera-preview-colour.md`). Enable lens corrections from the user's own lensfun database by setting `LIGHTCRAFT_LENSFUN_DIR` before launch (`docs/lens-profiles.md`).
- Drive output modules as commands: `export.contactSheet` (`paper`, `columns`, `rows`, `captions`, `ids`, `landscape`), the `print.*` family, and `slideshow.export` with `activity.list` progress (`README.md` agents section, `docs/control-protocol.md:87-97`).
- macOS only: hand files to Apple Photos with `app.export {addToPhotos: true, photosAlbum}` or `export.addToPhotos {paths}` — the first run triggers a macOS permission prompt for the controlling process (`docs/apple-photos.md`).

**Do not**

- Do not launch the GUI and drive it with OS-level synthetic input (osascript/System Events, cliclick): it goes to whatever window is frontmost. Use the control channel, `lightcraft-cli snapshot`, or MCP connect mode (repo `AGENTS.md`: "Never send OS-level synthetic input").
- Do not assume the CLI exists — on macOS it is a separate download, not inside the `.app`.
- Do not assume a library can be opened by two programs at once (`catalog.lock`); use `--connect` instead.
- Do not assume Adobe assets or formats work: `.dcp`, `.lcp`, `.lrtemplate`-as-output, Lightroom plug-ins. `.lrtemplate` is import-only; `.dcp`/`.lcp` are deliberately unsupported.
- Do not promise AI subject/sky masks, AI denoise or super resolution out of the box — they need optional models the user installs (denoise weights are simply absent from the default build).
- Do not promise that a raw will develop from sensor data; check the format list above and expect preview-only for compressed ORF, HE NEF and some CR3 variants.
- Do not treat a returned command result as proof of a correct image. Nothing here validates the pixels.

## Verification protocol

LightCraft is alpha; its library is crash-safe but its output is not self-checking. For every non-trivial task:

1. **Throwaway round-trip first.** Make a scratch library (`--library` pointed at a fresh folder, or `lightcraft-cli run --demo`), import one file, change one slider, export, then reopen the export in LightCraft or any other viewer and confirm dimensions and pixels. Only then run the real batch.
2. **Never trust a silent export.** `app.export` reports per-file `{path, width, height, bytes, sidecars}` and can report `gpuFallback`; a size/resolution mismatch or a zero-byte file is the failure you would otherwise miss. `format: "original"` also writes an XMP sidecar — check for it before assuming the folder is unchanged.
3. **Check the render, not just the command.** `ok: true` means the command ran. Poll `ui.inspect` for `loupe.pending == false` (or `loupe.failed` for the reason) and take a screenshot/PNG before declaring success (`docs/control-protocol.md:52-58`).
4. **Version and back up per session.** Copy the whole library folder before a bulk operation; the catalog is an append-only log, so a copied folder is a complete restore point. File ▸ Back Up Library… (`file.backupLibrary`) exists for this (on the web build it refuses while saves are failing). Use `--memory` when you only want to experiment — it writes nothing at all.
5. **Separate the app and the CLI release.** They must come from the same release (`docs/mcp.md:65-67`). Update the app between projects, never mid-project, and re-run step 1 after any update — the launcher auto-updates, and a new build can change rendering (that is exactly what process versions exist for; `docs/process-versions.md`).
6. **Know your single-writer rule.** Any `--library` headless run fails while the desktop app holds that library. Reserve it in your plan, or drive the open app with `--connect`.
7. **Treat the control port as a local privilege.** It has no authentication and can run any command; only enable it for a task that needs it, on loopback (`docs/control-protocol.md:27`).

## Sources & evidence

- Repo: https://github.com/storytold/lightcraft — inspected tag **v0.11.0**, commit **`ec0cda9a6f320e3b32f659f16718f7bce6c3f12f`** (detached worktree at the tag; `git rev-parse HEAD`), 2026-10-22. Installed app `/Applications/LightCraft.app` reports `lightcraft 0.11.0` (`--version`) and bundle id `ai.storyteller.lightcraft` — the same release. Its `Info.plist` version field is not authoritative; trust the binary's `--version`. **verify against your installed version** — the launcher auto-updates and users may lag or lead this pin.
- Files read for this skill: `README.md`, `ROADMAP.md`, `Cargo.toml`, `apps/lightcraft/Cargo.toml`, `apps/lightcraft/src/main.rs`, `apps/lightcraft-cli/src/main.rs`, `crates/engine/src/{import,export,library,presets,rename,lens_profiles,camera_preview,contact_sheet}.rs`, `crates/engine/src/cmd/{mod,convert,xmp,print,browse,geocode,mask_effect_files,lut_profiles,library,develop}.rs`, `crates/develop/src/{controls,settings}.rs`, `crates/catalog/src/journal.rs`, `crates/lensdb/src/lib.rs`, `crates/codecs/src/{psd,png}.rs`, `crates/ui-egui/src/{menus,shortcuts}.rs`, `crates/ui-egui/locales/`, `packaging/macos/{Info.plist.in,package.sh}`, `assets/camera-profiles/`, and `docs/`: `mcp`, `control-protocol`, `gaps`, `target-app-parity`, `raw-parity`, `file-format-parity`, `xmp-interop`, `process-versions`, `denoise`, `ai-masks`, `faces`, `web`, `lens-profiles`, `display-profiles`, `apple-photos`, `raw-preview-reads`, `background-tasks`, `merge`, `slideshow`, `library-shortcuts`, `focus-points`, `whats-new`, `lightroom-catalog-import`, `gpu-pipeline` (all `.md`).
- Shared library `storytold/craft-libs` (read-only reference) provides `craft-ui` (pinned rev `5c874d51…`) and `craft-docpath` (pinned rev `82a24b0…`) (`Cargo.toml:13-14`); LightCraft's own formats are documented in this repo, so nothing outside it was needed.
- Evidence tiers: **implemented** (the code path exists and is reachable from UI/CLI/command), **partial/stub** (exists but visibly incomplete — what is missing is stated), **not implemented** (absent or explicitly out of scope). See `evidence.md` beside this file for the claim-by-claim table.

**Uncertain / not verified in this pass**

- Whether an explicit `library.import` of a single `.psb` path can bypass `is_supported` — uncertain, see `crates/engine/src/import.rs` (`is_supported` is extension-only, so it should not).
- Exact rendered output fidelity (tone, colour, sharpening) — the project itself states it is unmeasured (`docs/gaps.md:20`); this skill makes no claim about it.
- The `heif` feature's presence in a *given* user's build: the official macOS package enables it (`packaging/macos/package.sh:65`) and the installed binary contains HEIC decoder strings, but a `cargo build` from source without `--features heif` will not decode HEIC.
- Two project docs disagree with code at this tag and were followed from code instead: `docs/gaps.md`/`docs/raw-parity.md` say "5 bundled profiles" (8 exist in `assets/camera-profiles/`), and `docs/file-format-parity.md` marks PSD write ⬜ and "no HLG" while `crates/engine/src/export.rs` implements flat-PSD export and `hdrTransfer pq|hlg`.
- Runtime behaviour of the GUI, menus and dialogs: nothing was launched during this pass; all GUI claims come from the command registry, the control-protocol document and the packaging metadata.

---
name: photocraft
description: PhotoCraft is the ArtCraft clean-room, pure-Rust reimplementation of Adobe Photoshop — layers, masks, adjustment layers, layer styles, live type, vectors, smart objects and real PSD read/write, with every action exposed as an engine command that the UI, a headless CLI, a JSON control channel and an MCP server all drive. Trigger this skill whenever the user mentions PhotoCraft, asks what it can or cannot do, which file formats it reads or writes, its keyboard shortcuts, how to script, automate or batch it, how to prepare assets for it, how to inspect, verify or repair a .pcraft or PSD it produced, or how to troubleshoot it — and also when they never name the app but describe the job, such as "edit this photo", "open this PSD", "make a transparent PNG", "batch-resize a folder of images", "remove the background with a quick selection" or "check what is in this layered file". It is early alpha — never promise Photoshop-grade PSD fidelity, AI features or a stable UI, and prefer the headless CLI and MCP over driving the GUI blind.
---

# PhotoCraft

## Overview

PhotoCraft is an open-source, native image editor: "Image editing; an open-source, clean-room reimplementation of Adobe Photoshop, rebuilt in pure Rust" (`README.md:13`), dual-licensed MIT/Apache-2.0, from the `storytold` org (repo `storytold/photocraft`). The desktop app is egui/eframe on wgpu with a CPU compositor as the reference oracle; the same Rust compiles to WebAssembly for the browser build (`apps/photocraft-web`, `Cargo.toml` `wasm-release` profile, `cargo xtask wasm`). Everything user-visible is an engine command, so the UI, `photocraft-cli`, the JSON control channel and the MCP server run the same code (`README.md:226`, `crates/engine/src/commands.rs`). Maturity is **early alpha**: ~76% feature breadth, ~45% "ready for real work" measured against Photoshop 2026 at 0.6.0, 953 open issues (2026-10-13) (`ROADMAP.md:5-30`, `docs/target-app-parity.md`); the six-workflow alpha gate passes (`docs/roadmap.md` "Alpha gate"). Every Photoshop menu item is *wired* — 631/631 live, enforced by `FLOOR = 631` (`crates/ui-egui/src/parity.rs:10`) — but wiring is not behaviour. The source inspected here is tag `v0.12.0` (commit `6a2d027ee2e7ca12afd248544ed2262b0fa078dd`, 2026-10-21), exactly the installed `/Applications/PhotoCraft.app`.

## Capabilities (verified)

### Editing core

- **Documents and colour**: RGB, Grayscale, CMYK and Lab at 8/16/32-bit float, plus Bitmap, Indexed, Duotone and Multichannel; ICC colour management in pure Rust with Assign/Convert to Profile, rendering intents, black point compensation, soft proofing and Gamut Warning (`README.md:198-201`, `crates/cms`, `crates/engine/src/adjust_cmds.rs` — CMYK/Lab adjustments composite on the stored inks, 2026-10-13 fixes in `docs/gaps.md` revision history).
- **Layers, done properly**: pixel layers, groups, clipping masks, pixel and vector masks (with Density/Feather properties), fill layers (solid/gradient/pattern), adjustment layers, live smart objects with smart filters and lossless transforms/warps/perspective (projective placement, `docs/scorecard.md` FILE-215-6 done), alpha channels, Quick Mask, layer comps, artboards, advanced blending (knockout, CPU render; GPU falls back) (`README.md:192-193`, `crates/doc`, `crates/engine`, `docs/scorecard.md` FILE-215-*).
- **16 adjustment-layer commands**: `layer.newAdjustmentLayer.{blackWhite, brightnessContrast, channelMixer, colorBalance, colorLookup, curves, exposure, gradientMap, hueSaturation, invert, levels, photoFilter, posterize, selectiveColor, threshold, vibrance}` — **Color Lookup is new** (.cube/.3dl/.look files or built-in looks; `crates/engine/src/adjust_cmds.rs:100-139`, id built from `CMD = "colorLookup"` at line 106). Destructive-only extras: Shadows/Highlights, Replace Color, Match Color, HDR Toning, Desaturate, Equalize (`adjust_cmds.rs:1-5`). On a smart object, Image › Adjustments records a re-editable smart filter (`adjust_cmds.rs:259`, FILE-215-4 done).
- **10 layer effects**, several instances per kind: DropShadow, InnerShadow, OuterGlow, InnerGlow, Stroke, ColorOverlay, GradientOverlay, PatternOverlay, Satin, BevelEmboss; contour curves with `.shc` import/export (`crates/doc/src/effects.rs:261-292`, `docs/scorecard.md` FILE-215-15 partial).
- **Blend modes**: PassThrough (groups) + 27 Photoshop blend modes + 6 Paint.NET variants (`crates/color/src/blend.rs:11-43`).
- **67 tools** including Remove, Spot/Healing Brush, Patch, Content-Aware Move (with Transform On Drop and coarse-then-exact live preview), Mixer Brush, Magnetic Lasso, Object/Quick Selection, Select Subject, Pen/Freeform/Curvature Pen, shapes, Type and Type Mask, Frame, Slice (`crates/ui-egui/src/state.rs:141` — `pub const ALL: [Tool; 67]`). Of Photoshop's classic 68, only Art History Brush is missing (`docs/gaps.md` G6, corrected 2026-10-13); the README's "15 missing tools" counts the full Photoshop 2026 toolbox — a known doc discrepancy.
- **Selections**: marquee/lasso/wand, `select.quick`, `select.object`, `select.subject`, `select.sky`, `select.colorRange`, `select.focusArea`, `select.refineEdge`, `select.magneticLasso`; Select and Mask is a dialog with live view modes and a Refine Edge Brush, not a workspace (`crates/engine/src/smartselect_cmds.rs`, `crates/ui-egui/src/menus.rs`, `docs/scorecard.md` TOOL-214-1 partial).
- **Filters** with live in-dialog preview: `crates/engine/src/filters.rs`, `filters_ext.rs`, `gallery_cmds.rs`; Field/Iris/Tilt-Shift/Spin Blur are edited on-canvas with Photoshop-style pins (Path Blur is still a dialog — `docs/gaps.md` G7); filters on a smart object become re-editable smart filters, and **41 filters map to PSD filterFX both ways** (`docs/file-format-parity.md` FILE-215-2, `crates/io/src/smart_map.rs`).
- **Type**: point and paragraph text on canvas, Character/Paragraph controls, manual + optical kerning with PSD round trip, variable-font axis sliders, `type.warpText` with live preview, OpenType feature buttons, `type.resolveMissingFonts`; **type on a path is partial** — glyphs place rigidly along the curve (`type.attachToPath`/`detachFromPath`, `crates/engine/src/type_extra_cmds.rs:332-362,699`) but the caret does not follow and PSD saves it as point text (`docs/scorecard.md` TYPE-218-1). Headless type editing exists: `type.editText`, `type.hitTest`, `type.caret`, `type.navigate` (`docs/control-protocol.md`, FILE-215/AUTO-219-9 done).
- **Vectors**: Pen/Freeform/Curvature tools, insert/delete/convert anchor, paths panel, work paths, shape layers with stroke controls and corner-radius handles, path-to-selection; SVG opens as editable shape layers or a vector smart object (`crates/io/src/svg.rs`, `docs/scorecard.md` FILE-215-9).
- **Actions**: record/replay, `actions.list/get/record/stop/play/move/delete/toggle/rename`, nested calls to 16 levels with cycle rejection, sets with dialog toggles and Insert Stop, function-key bindings, Photoshop `.atn` import/export — the `EVENTS` table holds 92 entries and the generated scorecard counts 90 events mapped both ways; unmapped steps are kept verbatim and fail at playback by name (`crates/engine/src/atn_cmds.rs:2674`, `docs/scorecard.md` AUTO-219-2; older prose in `docs/gaps.md` says 112 — trust the scorecard/code).
- **Photomerge**: `file.automate.photomerge` with reposition/perspective layouts, as a cancellable background job (`crates/engine/src/photo_cmds.rs:487-909`; real-world quality validation still open, `docs/roadmap.md` M12).
- **Print**: File › Print renders one flattened PDF page and hands off via `lp`/the Windows spooler, or the new in-process pure-Rust IPP client (`crates/ipp` — works inside the Flatpak without `lp`), or the Linux print portal, or to a PDF file; `file.printers` lists queues, `"dryRun": true` previews the job (`docs/printing.md`, `crates/engine/src/print_cmds.rs:14-15,190`).
- **Video-lite**: `timeline.create` and `file.export.renderVideo` (PNG sequence or animated GIF; animated GIFs open as frame sequences through New Video Layer from File) (`crates/engine/src/timeline_cmds.rs:71`, `video_cmds.rs:406-466`, `docs/file-format-parity.md` GIF row).

### Files — read / write

- **Native**: `.pcraft` (zip of STORE entries or a directory) = `manifest.json` (format version 1, migrations in `crates/format/src/migrate.rs`) + content-addressed BLAKE3/zstd `tiles/` and `blobs/` + `thumb.png` + `composite/preview.png`; incremental, atomic (temp/fsync/rename) saves, crash-recovery autosaves (`crates/format/src/lib.rs:1-60`, `crates/format/src/atomic.rs`, `autosave.rs`).
- **Read + write**: PSD and PSB (layers, groups, masks, vector masks, adjustment and fill layers, effects, text, shapes, smart objects as embedded SoLd+lnk2, smart filters, alpha channels, slices, comps; streaming) — `crates/io/src/psd_import.rs`, `psd_export.rs`, `crates/psd`; **export auto-switches to PSB above an estimated 2 GB** (`docs/scorecard.md` REL-212-2 done); optional image previews written into the PSD (`crates/io/src/lib.rs` export path). OpenRaster `.ora` with layers/groups/blend modes (`crates/io/src/ora.rs`); layered TIFF (Photoshop layer data, both byte orders; extra alpha channels and a Quick Mask are not written) (`crates/io/src/tiff_layers.rs`); and via `photocraft-codecs`: PNG (8/16-bit), JPEG, TIFF (8/16/32f, BigTIFF), WebP (lossless + own lossy VP8), GIF, BMP, TGA, ICO, **DDS (read + write: uncompressed or BC1/BC2/BC3, optional full mip chain — new writer)**, Netpbm (PBM/PGM/PPM/PAM/PFM), QOI, OpenEXR (f16/f32), Radiance HDR, FITS (header cards kept), DPX (8/10/12/16-bit read and write), Cineon (read-only) (`crates/codecs/README.md` capability matrix; export dispatch `crates/io/src/lib.rs` `export_stages`).
- **Save keeps what it opened**: a JPEG's quality is estimated from its quantisation tables and reused; a WebP keeps lossy-at-its-quality or lossless (`docs/file-format-parity.md` JPEG/WebP rows, #2399).
- **Read-only imports**: Paint.NET PDN3 (editable layers, 14 blend modes), Krita `.kra`/`.krz`, Affinity `.af`/`.afdesign`/`.afphoto`/`.afpub` (own `crates/affinity` crate: pages/artboards, layers, vectors, text, images, masks; damaged files fall back to the embedded preview), SVG, DDS (top mip of a 2D texture), Cineon, HEIC/HEIF (pure-Rust `heic-rs` in the new `crates/heif`, behind the `heif` feature, on in official builds), and camera raws; import-only writers refuse with a naming error (`crates/io/src/lib.rs:1-60` and the `export_stages` PDN/Affinity/KRA refusals, `crates/io/src/pdn.rs`, `kra.rs`, `affinity.rs`, `svg.rs`, `crates/codecs/README.md`).
- **Camera raw decode**: DNG (uncompressed, deflate, lossless-JPEG, **lossy-JPEG (compression 34892, now decodes)** and JPEG XL, CFA and LinearRaw), CR2, TIFF/EP raws (NEF, ARW, PEF), Nikon compressed NEF (lossless and lossy), Sony cRAW, Panasonic RW2, uncompressed Olympus ORF, uncompressed Fujifilm RAF (Bayer and X-Trans); measured per-camera profiles/image areas (Nikon D4, D5100, D90); a per-file colour look is fitted to the camera's own JPEG when there is no calibration; everything else reports Unsupported, and CR3 gives only its embedded JPEG preview + orientation, not sensor data (`crates/raw/src/lib.rs:29-37,92-241`, `docs/file-format-parity.md` Camera raw table).
- **PDF**: write only, one flattened RGB/Gray/CMYK page with ICC — Save As / Save a Copy / CLI, print, and artboards-to-PDF (`crates/io/src/pdf.rs:1-12`, `docs/file-format-parity.md` Photoshop PDF row).
- **Export As** formats: `png`, `jpg`, `webp`, `tif`, `tga`, `ico`, with Photoshop's six resample methods remembered (`crates/engine/src/export_preset_cmds.rs:13`, `docs/scorecard.md` FILE-215-18 done). **Save for Web**: `gif`, `png8`, `png24`, `jpeg`, `wbmp`, with editable colour tables (`crates/engine/src/web_cmds.rs:40-66`, `docs/control-protocol.md`). Quick Export as PNG (`crates/engine/src/shell_commands.rs`).
- **Depth honesty**: `caps(format)` and `fidelity_warnings` report what an export will lose before it is written; CLI and desktop surface those as warnings (`crates/codecs/README.md`).

### Automation surfaces

- **One command registry**: 631/631 menu items live (`crates/ui-egui/src/parity.rs:10`, `docs/parity-checklist.md`). Wiring is not behaviour; check `enabled`/`disabledReason`/`needsDocument` per command (`docs/control-protocol.md`).
- **CLI `photocraft-cli`** — 8 subcommands, all flags enforced (unknown flag = usage error, exit 2): `convert`, `info`, `run`, `batch`, `droplet`, `commands`, `mcp`, `serve`; plus `--version` (`apps/photocraft-cli/src/lib.rs:14-107`). New export flags: `--dds-compression <none|bc1|bc2|bc3>` and `--dds-mipmaps` on convert/run/batch (lib.rs:18-53).
- **Control channel**: `photocraft --control <port>` serves authenticated JSON lines on `127.0.0.1` only; first frame must be `{"id":"auth","method":"auth","params":{"token":"<64 hex>"}}`; 60-second reply timeout. Methods include `engine.execute` (with `wait: false` background jobs), `engine.commands`, `jobs.list/cancel`, `ui.inspect`, `ui.set`, `ui.menu.invoke/list`, `ui.pointer`, `ui.click`, `ui.move`, `ui.key`, `ui.type`, `ui.resize`, `ui.focus`, `ui.context.choose`, `ui.dialog.*`, `ui.screenshot`, `ui.window.open/close`, `ui.gpu.simulateLoss`, `app.open`, `app.save` (now with `tgaBits`/`ddsCompression`/`ddsMipmaps`), `app.quit` (`docs/control-protocol.md`, `apps/photocraft/src/control_server.rs`, `crates/ui-egui/src/control.rs`).
- **MCP**: `photocraft-cli mcp` runs headless; `--bridge 127.0.0.1:<port>` wraps a running app (bridge-only: `ui_*`, `control_call`; headless-only: `doc_select`, `doc_close`). Tools: `command_list`, `command_run`, `command_batch`, `doc_inspect`, `doc_open/new/place/save/export/export_layers/export_data_sets/import_data_sets`, `render_preview`, `jobs_list/jobs_cancel`, `session_list`, `ui_inspect`, `ui_screenshot`, `ui_pointer`, `ui_menu_invoke`, `ui_set`, `control_call` (`docs/mcp.md`, `docs/control-protocol.md` "MCP bridge" table). Scripted agent acceptance tasks run over MCP in `crates/automation/tests/agent_tasks.rs` and `agent_tasks_more.rs`.
- **Headless server**: `photocraft-cli serve` (stdio or `--port`) answers `engine.execute`, `engine.commands`, `jobs.list/cancel`, `doc.open/new/place/save/inspect/render/select/close/exportLayers/exportDataSets/importDataSets`, `session.list`, `batch`, `methods`; an `index` param targets a document without switching (`docs/control-protocol.md` "Headless server", `crates/automation/src/rpc.rs`).
- **Plug-ins**: WebAssembly ABI v1 — `plugin.install/run/remove/reload/list`, wasmi sandbox, no WASI/filesystem/network, 32 MiB module, 512 MiB memory, 50M-instruction fuel (+4,000 per sample), 60 s budget per run (`docs/plugins.md`). ABI v2 (panels, progress) is missing.
- **Batch/droplets**: `photocraft-cli batch` applies an actions JSON, an Actions set (steps may call sibling actions; self-calls stop), or a `.atn` set (`--action` picks by name) to a folder, with `{name}/{serial}/{date}` output templates; `.pcdroplet` droplets run via `file.automate.runDroplet` (`apps/photocraft-cli/src/lib.rs:388-443`, `crates/engine/src/automate_cmds.rs`, `docs/batch-naming.md`).

### Platform

- macOS, Windows (x64/x86/ARM64), Linux, FreeBSD natives and a WebAssembly web build (`README.md` Downloads; `docs/scorecard.md` DIST rows — FreeBSD tarball layout checked but not yet produced by a release run).
- GPU compositor on wgpu (Metal/Vulkan/DX12/WebGPU) with CPU fallback, `--safe-gpu`, automatic driver-crash fallback and `ui.gpu.simulateLoss` for testing (`apps/photocraft/src/gpu_startup.rs`, `docs/control-protocol.md`).
- Pen tablets: pressure/tilt/rotation on macOS (isolated AppKit monitor crate), Windows (`WM_POINTER` via winit; tilt/rotation still missing), Linux X11 (XInput2), web (Pointer Events); native Wayland tablet-v2 still open (`crates/tablet`, `docs/gaps.md` G12).

## Known limitations and not-implemented

Read this before assigning work — several of these are the reason agents should not promise Photoshop behaviour.

- **Alpha, by measurement**: ~45% "ready for real work" and 953 open issues (2026-10-13) (`ROADMAP.md`); of the committed performance baseline's 60 scenarios, 3 are within budget, 22 over budget or failing, 9 tracked only, 22 not run and 4 not measurable — including a GPU-validation crash when nudging in a 150-layer document (P12) and a 954 s Content-Aware Scale against a 3 s target (`docs/scorecard.md` Performance).
- **PSD fidelity is the blocking gap (G1)**: enforced corpus floors are *minimums* — Photoshop-authored oracles 188/256 render-pass (round-trip floor 258), psd-tools 249/309 (round trip 308), io corpus 148/170 (round trip 169) (`crates/io/tests/corpus.rs:151-159`); the README's measured numbers are 307/309 and 169/170 renders (`README.md:220`). A re-saved PSD is **not byte-identical** to its source (only the standalone `photocraft-psd` crate reproduces corpus files byte for byte), and no test opens exports in a third-party editor (FILE-216-4). Photoshop refusing our files is reported in #1281, #2469 (`docs/gaps.md` G1).
- **No AI/generative features**: no `ml` crate and no ONNX runtime in the workspace; "ML backend not started" (`docs/roadmap.md` M10); no Neural Filters, generative fill/expand, sky replacement ML or generative Remove mode. Classical substitutes exist (Select Subject via GrabCut/max-flow, Remove tool by non-local patch completion) (`docs/gaps.md` G15, TOOL-213-19).
- **No native Photoshop plug-ins**: `.8BF`, CEP and UXP are not hosted; only the Wasm plug-in ABI v1 (`docs/gaps.md` G16, `docs/plugins.md`).
- **Workspaces that are dialogs, not workspaces (G7)**: Select and Mask opens a dialog; no Content-Aware Fill sampling workspace; Vanishing Point has a plane editor but no clone/paste-in-plane; Path Blur is a parameter dialog (`docs/gaps.md` G7, `docs/scorecard.md` TOOL-214-14/15).
- **Type depth (G8)**: type on a path saves as point text in PSD; no paragraph-direction UI; no Numerals/Stylistic Sets submenus; PSD does not round-trip variable-font axis values (`docs/scorecard.md` Type rows).
- **Formats absent or partial**: no PDF import (#2541), no Photoshop EPS/DCS; AVIF read missing and AVIF write only behind the non-default `avif` build feature; JPEG XL only inside DNG; JP2, DICOM, PCX, Pixar, IFF, WBMP (as a save format), MPO/JPS, PICT, Scitex CT, Photoshop Raw and Cloud PSD unsupported; Cineon has no writer (`crates/codecs/README.md`, `docs/file-format-parity.md`). Affinity, Krita and PDN are import-only. GIF opens first-frame-only via File › Open (use New Video Layer from File for frames); APNG keeps the first frame; per-frame GIF delays are not persisted (`docs/file-format-parity.md` PNG/GIF rows).
- **Camera raw partial**: unsupported variants fall back to the embedded JPEG preview; "lossy after split" NEF no; no `.xmp` sidecars; CR3 sensor data no (`crates/raw/src/lib.rs`, `docs/file-format-parity.md` Camera raw).
- **Dead preferences**: 24 of 171 settings do nothing, including `integrations.control_port` and the `raw_defaults` block (`docs/scorecard.md` "Workspace and UI" prefs audit).
- **Automation is fail-closed**: ambient filesystem commands are refused — `file.open/openAs/save/saveAs/saveACopy`, `file.export.saveForWebLegacy`, `pattern.import`, smart-object export/replace/relink, `measurementLog.export`, `edit.colorSettings`; path params of other commands (`layer.exportAs`, `filter.distort.displace`, preset imports, plug-in install, `layer.setAdjustment {"file": …}`) are refused too; `prefs.set` rejects whole-preference updates and file-backed sections (`colorSettings`, `scriptEvents`, `historyLog`, `plugIns`, `scratchDisks`); the **desktop app additionally refuses `image.mode.*`** (it could load profile files) (`crates/automation/src/workspace.rs` `filesystem_commands_fail_closed` test, `docs/control-protocol.md`).
- **Localization**: UI strings translated (12 key languages, 8 more shipped) but engine messages stay English; Hindi, Arabic (RTL shell only) and Vietnamese are 0% (`ROADMAP.md` Languages).
- **No in-app update check** (`docs/scorecard.md` DIST-220-1 missing — updates come from the ArtCraft Launcher / release downloads); Windows builds are unsigned so far (DIST-2).
- **Windows**: PSB over 4 GB via the app's File › Open is still issue #375, though a generated 4.38 GB PSB round-trips through the io layer on Windows (`docs/file-format-parity.md` PSB row, `crates/io/tests/large_files.rs`).
- **Wayland**: no drag-and-drop (winit 0.30 limit) and XWayland fractional scaling is blurred (`README.md:285`).
- Docs lag code between releases (the roadmap still carries pre-0.10 measurements; scorecard/parity-checklist are generated and fresher). Verify against your installed version before asserting a feature is missing.

## How to operate

### Launch (macOS)

```sh
open -a PhotoCraft                        # normal GUI launch
open -a PhotoCraft /path/to/file.psd      # open a file in the running instance
open -a PhotoCraft --args --control 7878 --control-token-file "$HOME/.photocraft/control.token" \
     --automation-read-root "$PWD" --automation-write-root "$PWD"
```

- Binary: `/Applications/PhotoCraft.app/Contents/MacOS/PhotoCraft`; the app bundle contains **no CLI** — get `photocraft-cli` from the release zip (`photocraft-cli-<ver>-macos-universal.zip`, signed and notarized), `cargo install --path apps/photocraft-cli --locked`, or the Linux `.deb`/`.rpm` (`/usr/bin/photocraft-cli`).
- App options (verified in `apps/photocraft/src/main.rs` usage text, lines 168-198): `-h/--help`, `--version`, `--safe-gpu`, `--in-window-menus`, `--new-instance`, `--present-mode <fifo|autovsync|novsync>`, `--frame-latency <1..3>`, `--stroke-trace <stderr|file.csv>`, `--control <port>`, `--control-token <64-hex>`, `--control-token-file <path>`, `--automation-read-root <dir>`, `--automation-write-root <dir>`, `--`. Env equivalents exist (`PHOTOCRAFT_CONTROL_PORT`, `PHOTOCRAFT_CONTROL_TOKEN`, …, `PHOTOCRAFT_CONFIG_DIR`).
- If no token is given, a fresh one is generated and printed to stderr; a token file is created with mode 0600. Treat it as a credential: the token grants the whole non-filesystem control surface, and the protocol is unencrypted loopback (`docs/control-protocol.md` security note).
- Do not launch the GUI just to inspect a file: use the CLI (below). macOS does not render occluded windows, so live screenshots steal focus (`ui.screenshot` raises the window by default; `docs/development.md`).

### Headless CLI

Build or run from source: `cargo run -p photocraft-cli -- <subcommand>`.

```sh
photocraft-cli convert in.psd out.pcraft [--format <ext>] [--quality 1-100] [--tiff-layers] \
    [--tga-bits 24|32] [--dpx-bits 8|10|12|16] [--dds-compression none|bc1|bc2|bc3] [--dds-mipmaps]
photocraft-cli info out.pcraft [--compact]                 # JSON: size, mode, depth, layer tree, warnings
photocraft-cli run in.png --cmd layer.new.layer --params '{"name":"Ink"}' \
                        --cmd filter.blur.gaussianBlur --params '{"radius":3}' \
                        --out out.psd [--format <ext>] <same export flags>
photocraft-cli run --new '{"width":800,"height":600,"background":"white"}' --cmd document.inspect --out new.pcraft
photocraft-cli batch --actions actions.json [--action <name>] --in ./raw --out ./graded [--format jpg] [--in-place]
photocraft-cli droplet job.pcdroplet ./images [--out ./done]
photocraft-cli commands [--json] [--filter blur]
photocraft-cli mcp [--bridge 127.0.0.1:7878] [--control-token <64-hex> | --control-token-file <path>] \
                   [--automation-read-root <dir>] [--automation-write-root <dir>]
photocraft-cli serve [--port <port>] [--control-token <64-hex> | --control-token-file <path>] \
                   [--automation-read-root <dir>] [--automation-write-root <dir>]
```

Behaviour that bites: each `--params` must follow its `--cmd`; `run` needs exactly one of `<file>` or `--new <json>`; every command's JSON result is one line on stdout while warnings go to stderr (missing fonts are reported once per run by `convert`, `run` and `info`); exit codes are 0 ok / 1 failure / 2 usage; `batch` refuses an `--out` equal to `--in` unless `--in-place` (canonicalized, so symlinks count) and refuses to overwrite a same-named output; `--quality` sets JPEG and lossy WebP (without it WebP is lossless) (`apps/photocraft-cli/src/lib.rs`).

### Document and window model

One window holds the open documents as tabs (the control channel exposes them as `window.document.<index>` in tab order); `ui.window.open` adds an extra window. On Windows and Linux a second launch hands its files to the running instance as new tabs; `--new-instance` and any `--control` launch start a separate process (macOS relies on LaunchServices). (`apps/photocraft/src/main.rs:13-15`, `docs/control-protocol.md`.)

### Open / save / export flow

- Open: File › Open (`Cmd+O`), drag-and-drop, or the CLI. Save (`Cmd+S`) writes back to the document's own `.psd`, `.psb` or `.pcraft`; Save As (`Cmd+Shift+S`) picks the format from the file extension — `.pcraft` for the lossless native bundle, PSD/PSB for Photoshop handoff, any writable codec extension for flat output, `.pdf` for one flattened page. Long opens/saves run as cancellable background jobs with progress (`docs/control-protocol.md` "Background jobs").
- Over the control channel or MCP use `app.open` / `app.save` (or `doc.*` on serve/MCP) with paths **relative to the automation roots** — the refused ambient commands are listed under Known limitations. Embedded smart objects are the exception that works: `layer.smartObjects.editContents`, `layer.smartObjects.saveContents`, `layer.smartObjects.convertToLayers` run over automation (pathless forms only; save nested objects from the deepest contents outward) (`docs/control-protocol.md` "Embedded Smart Objects", `crates/automation/src/workspace.rs`).
- Export As (`Cmd+Alt+Shift+W`) offers png/jpg/webp/tif/tga/ico with resample methods; Save for Web offers gif/png8/png24/jpeg/wbmp; Quick Export as PNG is one menu item away.
- Keyboard shortcuts: the authoritative tables are `crates/engine/src/shell_commands.rs` (shell + tool defaults) and `crates/ui-egui/src/menu_catalog.rs` (menu items). Verified examples: `Cmd+F` Search…, `Cmd+J` Layer via Copy (`menu_catalog.rs:257`), `Cmd+D` Deselect (`:507`), `Cmd+O`/`Cmd+S`/`Cmd+Shift+S` (`shell_commands.rs:21-23`), `Cmd+Alt+Shift+W` Export As (`:26`), `F7` Layers, `F6` Color, `F5` Brush Settings (`:54-58`). Photoshop shortcut sets import/export through `edit.keyboardShortcuts` (`.kys`, including Photoshop's live installed set on first launch).

### State on disk

- macOS settings dir: `~/Library/Application Support/Photocraft/` — `preferences.json`, `Presets/` (brushes as `.pcbrushes` + content-addressed `tips/`, the Actions list as `actions.json`, gradient presets), and `ui.ron` for window/dock geometry; crash recovery next to it in `Recovery/`. Override with `PHOTOCRAFT_CONFIG_DIR`; portable mode (a `portable.txt` or `PhotoCraft.portable` marker beside the executable) keeps everything in `<exe dir>/PhotoCraftData/` (`apps/photocraft/src/app_dirs.rs:10-11,481`, `docs/control-protocol.md` "Preferences").
- Recovery autosaves are `<Recovery>/<key>.pcraft` directory bundles plus `<key>.json` metadata; the entry is deleted only when the document is saved or closed, and recovery is offered at the next launch. Autosave interval: preference `fileHandling.autosaveMinutes`, default 10, valid 1-240 (`crates/format/src/autosave.rs`, `crates/engine/src/prefs.rs:453,477,1133`).

## Working with an AI agent

Preferred ladder — use the highest rung that answers the question:

1. **Headless CLI** for convert/inspect/batch; it needs no GUI and no token.
2. **MCP headless** (`photocraft-cli mcp --automation-read-root … --automation-write-root …`) when the task is a sequence of engine commands with inspection; without roots it has no file authority (by design).
3. **Control channel on a live app** when UI state, dialogs, pointer gestures or screenshots are genuinely required.
4. **GUI pointer events last** — `ui.pointer`/`ui.key` are validated and replayable, but they depend on window focus on macOS.

Legitimate work:

- **Prepare inputs**: convert any supported source to `.pcraft`/PSD/PNG (or DDS textures with `--dds-compression`), resize/grade via `batch`, generate actions JSON or droplets, pre-export assets for other Craft apps.
- **Read and interpret documents**: `photocraft-cli info <file>` JSON (size, mode, depth, layer tree, warnings) or `document.inspect`, `layer.list`, `document.pixel` over MCP/control. `.pcraft` `manifest.json` is plain JSON and can be read directly.
- **Verify exports**: reopen with `photocraft-cli info`, read stderr warnings, probe pixels (`document.pixel`), compare size/alpha. Do not byte-compare a re-saved PSD to its source: PhotoCraft rewrites image resources, layer records and the composite on save (unknown PSD blocks are carried through verbatim), so only reopening the file tells you it is right.
- **Repair by regeneration, not by hand**: `.pcraft` tiles/blobs are content-addressed (BLAKE3) zstd objects — never edit them in place. Rebuild from the source image, an earlier bundle, or the app: a bundle written by a newer format version is refused with a clear error (`crates/format/src/lib.rs` `FormatError::TooNew`, `migrate.rs`).
- **Batch safely**: `batch` will not silently overwrite and fails a file whose nested action fails; MCP `command_batch` is not atomic (earlier steps stay applied), so inspect history afterwards and undo per history entry. Long steps accept `wait: false` and are polled/cancelled through `jobs.list`/`jobs.cancel`.

Do not: assign the app AI/generative work, expect Photoshop to always open its PSD exports, assume a format is supported because Photoshop has it, drive the GUI blind when a headless command exists, run two instances that share one recovery folder, apply whole-Preferences updates over the control channel (change individual keys with `prefs.set`), use `image.mode.*` from desktop automation, or rely on doc statements that the code contradicts (docs lag by weeks — trust the source).

## Verification protocol

PhotoCraft is alpha: verify every artefact, never trust a silent export.

1. **Round-trip smoke test** before trusting any output (in a scratch directory):
   `photocraft-cli run --new '{"width":64,"height":64,"background":"white"}' --cmd layer.new.layer --out t.pcraft`
   then `photocraft-cli info t.pcraft`, then `photocraft-cli convert t.pcraft t.png` and open `t.png` in another viewer. For edits, add a command between `--new` and `--out` and read the per-command JSON lines.
2. **Read warnings.** Fidelity warnings (bit-depth reduction, CMYK→RGB, dropped layers, missing fonts) print to stderr on `convert`/`run`/`batch` and appear in `info`/`app.save` `warnings`. An export without a warning is the only export you should believe.
3. **Version projects.** Keep the `.pcraft` for lossless re-edits and hand Photoshop the PSD/PSB; keep the original source. PhotoCraft's re-saved PSD is not byte-identical and older/newer formats migrate on load.
4. **Update only between projects.** A version bump can change how files save. This skill documents 0.12.0 (`v0.12.0`, commit `6a2d027ee`); if the installed app differs, re-verify format and command claims against the new build (`photocraft --version` prints version, commit and build date, `crates/engine/src/build_info.rs`).
5. **Prefer reversible operations.** Work on copies (`image.duplicate` or `history.newDocument` creates a new active document), inspect `document.inspect` history, and remember automation saves never fire script events.

## Sources & evidence

- Repo: https://github.com/storytold/photocraft — inspected at tag `v0.12.0`, commit `6a2d027ee2e7ca12afd248544ed2262b0fa078dd` (2026-10-21); date of inspection 2026-10-22.
- Installed app: `/Applications/PhotoCraft.app` — its CLI reports `photocraft 0.12.0 (6a2d027ee, 2026-10-21)`, matching this pin; `CFBundleShortVersionString` 0.12.0, bundle id `ai.storyteller.photocraft`, minimum macOS 11.0 (`Contents/Info.plist`; the app was not launched). Users with other builds may lag or lead this release — verify against your installed version.
- Key files read: `README.md`, `ROADMAP.md`, `Cargo.toml`, `AGENTS.md`, `apps/photocraft/src/main.rs`, `apps/photocraft/src/app_dirs.rs`, `apps/photocraft-cli/src/lib.rs`, `crates/engine/src/commands.rs`, `atn_cmds.rs`, `adjust_cmds.rs`, `export_preset_cmds.rs`, `web_cmds.rs`, `shell_commands.rs`, `photo_cmds.rs`, `video_cmds.rs`, `print_cmds.rs`, `prefs.rs`, `build_info.rs`, `crates/ui-egui/src/state.rs`, `parity.rs`, `menu_catalog.rs`, `crates/doc/src/effects.rs`, `crates/color/src/blend.rs`, `crates/format/src/lib.rs`, `autosave.rs`, `crates/io/src/lib.rs`, `pdf.rs`, `crates/io/tests/corpus.rs`, `crates/codecs/README.md`, `crates/raw/src/lib.rs`, `crates/heif/src/lib.rs`, `crates/ipp/src/lib.rs`, `crates/automation/src/workspace.rs`, `crates/automation/tests/agent_tasks.rs`, `agent_tasks_more.rs`, `docs/control-protocol.md`, `docs/mcp.md`, `docs/scorecard.md`, `docs/gaps.md`, `docs/roadmap.md`, `docs/parity-checklist.md`, `docs/file-format-parity.md`, `docs/plugins.md`, `docs/printing.md`, `docs/batch-naming.md`.
- Shared libraries: `storytold/craft-libs`, pinned by git revision in `Cargo.toml` (`craft-ui` rev `5c874d51…`, `craft-print` rev `3d37da38…`, `craft-docpath` rev `82a24b00…`); consulted to confirm the pinning relationship, not for app behaviour.

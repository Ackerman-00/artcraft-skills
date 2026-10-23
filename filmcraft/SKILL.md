---
name: filmcraft
description: FilmCraft is an open-source, professional non-linear video editor (editing, multicam, colour, effects, titles, captions, audio mixing, export) written in pure Rust, mirroring Adobe Premiere Pro's workflow, for macOS/Windows/Linux and the web. Trigger this skill whenever the user mentions FilmCraft (or "fcproj"/".fcproj", "filmcraft-cli", the FilmCraft control channel or MCP server, "window.filmcraft"), asks what it can or cannot do, which formats it reads or writes, how to script or automate it, how to prepare or convert media for it, how to verify or repair its exports and project files, or troubleshoot it — and also when they never name the app but describe the job — "cut this footage", "make a rough cut", "export an H.264 MP4", "grade this clip", "add captions to this video", "hand an EDL/AAF to an editor", "drive a video editor from an agent". Prefer this skill over generic NLE knowledge for anything FilmCraft touches; do not assume Premiere-only capabilities (`.prproj` import, plug-ins, upload destinations) exist here.
---

# FilmCraft

**Audit basis:** this checkout is tag `v0.11.0`, commit `74242b51d675514da12d9bbf6b331ef2e6399211` (detached worktree, release commit 2026-10-22). The installed `/Applications/FilmCraft.app` reports version `0.11.0`, its `Info.plist` records `FilmCraftBuildCommit` = the same commit, and its binary prints `filmcraft 0.11.0`, so the bundle matches this source exactly. **Verify against your installed version** if the ArtCraft Launcher has auto-updated since. Deep detail lives in `references/cli-and-protocol.md` (CLI, control channel, MCP, command cheat sheet) and `references/formats.md` (import/export tables, `.fcproj`, interchange).

## Overview

FilmCraft is an open-source, professional non-linear video editor written from scratch in pure Rust: its panels, workspaces, tools and shortcut conventions mirror Adobe Premiere Pro, and its codecs, containers and renderer are its own (README.md; clean-room rules in `AGENTS.md` §2). The parity target is Premiere Pro 2026 **26.5.2**, tracked in `docs/target-app-parity.md`, and the project describes itself as **alpha** (README.md "Status"). It runs natively on macOS, Windows and Linux, as a FreeBSD 14 x86_64 tarball (the aarch64 build was dropped in this release), and in the browser via WebAssembly (`docs/releasing.md:45-56`, `apps/filmcraft-web`, `docs/web.md`). The engine is headless and command-driven: the egui UI, `filmcraft-cli`, a JSON-lines control channel and an MCP server dispatch the same command ids (`docs/architecture.md` §1, `crates/engine/src/commands.rs`). Source: GitHub `storytold/filmcraft`.

## Capabilities (verified)

### Editing (implemented)

- Three-point editing: Source monitor In/Out → `source.insert` (`,`) / `source.overwrite` (`.`); `sequence.lift` (`;`) / `sequence.extract` (`'`) (`crates/engine/src/commands.rs:2056`, `:2080`, `:2086`, `:2576-2577`).
- Trim tools and modes: ripple, roll, slip, slide, rate-stretch, razor (`timeline.razor`, `crates/engine/src/commands.rs:2845`); Trim Monitor plus deterministic dynamic trimming (`trim.shuttle` / `trim.tick` / `trim.shuttleStop`, `crates/engine/src/trim.rs`, `crates/ui-egui/src/panels/trim_monitor.rs`).
- Add Edit (⌘K), ripple delete/close gap, nesting, markers with colour/name/duration and `markers.exportCsv` (UTF-8 CSV; 100 000-marker and 16 MiB caps, `crates/engine/src/marker_export.rs:11-12`), scene edit detection (`clip.sceneEditDetection`), subclips, sync/merge clips, multicam source sequences with live angle switching (`crates/engine/src/multicam.rs`).
- **Exact integer time**: 254 016 000 000 ticks per second; 23.976/29.97-DF/59.94 are exact rationals (`crates/time/src/lib.rs:20`); commands accept `ticks`, `seconds`, `frame` or `timecode`.
- Undo is copy-on-write snapshots with a **200-step history limit** per project (`s.history.limit = 200` in `crates/engine/src/commands.rs:1144`, `:1158`); continuous gestures merge into one step (`History::merge_key`, `crates/engine/src/lib.rs:228-236`). History panel included.
- Track colour labels via `timeline.setTrack {label}` (`crates/engine/src/commands.rs:2859-2863`); `inspect_sequence` reports `label` per track (`:4280`).
- Four shortcut presets: FilmCraft Default, Premiere Pro Compatible, Final Cut Pro Compatible, Avid Media Composer Compatible (`crates/engine/src/shortcuts.rs:63`; tables in `crates/engine/src/shortcut_presets.rs`).
- Workspaces: Editing, Assembly, Color, Effects, Audio, Captions and Graphics, All Panels (`crates/ui-egui/src/menus.rs:111-117`); **28 dockable panel kinds** (`PanelKind::ALL`, `crates/ui-egui/src/dock.rs:14-46`); docking/floating is scriptable (`window.dockPanel`, `window.floatPanel`, `window.dockAction` — `docs/control-protocol.md:179-181`).
- Text panel with Transcript / Captions / Graphics tabs (`crates/ui-egui/src/panels/text.rs:1-19`); Project Notes saved in the project (`project.notes` / `project.setNotes`, `crates/engine/src/panels.rs:343-368`).

### Colour, effects, motion (implemented; some effects approximate)

- Lumetri-style colour: Basic Correction, Creative looks (eight built-in Look choices: Teal & Orange, Warm Film, Cool Blue, Bleach Bypass, Faded Matte, Monochrome, Golden Hour, Night), RGB + hue/sat/luma curves, three-way wheels, HSL Secondary, Vignette; LUT import/export for `.cube` (1D/3D/shaper) and `.3dl` (`crates/engine/src/color.rs:79`, `:219-224`; `crates/project/src/effect.rs:421-428`; `crates/color/src/lut.rs:1-8`).
- **93 video effects across 16 folders** (test `premiere_26_video_effects_catalogue`, `crates/project/src/effect/vfx.rs:1251-1263`); **53 audio effects** (`PREMIERE_AUDIO_EFFECTS`, `crates/project/src/effect/audio.rs:578`); **84 video transitions + 21 Legacy** in 10 folders (`crates/project/src/vtransition.rs:413-417`).
- Blend modes: **27 entries** including Normal (`BLEND_MODES`, `crates/project/src/effect.rs:144`). The README says "26 blend modes" — the code has 27.
- Keyframes: linear, Bézier, auto/continuous Bézier, hold, ease in/out; value and velocity graphs; keyframable effect parameters, masks and graphic properties (`crates/project/src/keyframe.rs`, `crates/engine/src/masks.rs`, `docs/graphics.md`).
- Compositing: wgpu GPU compositor (Metal/Vulkan/DX12/WebGPU) with a CPU reference renderer the GPU path is tested against (`crates/gpu`, `README.md` "Effects and motion").
- **Approximate, not exact**: Warp Stabilizer is 2-D, Morph Cut has no face tracking (`docs/gaps.md` G18); AI effects (Object Mask, Generative Extend) do not exist (G12).

### Audio (implemented)

- Loudness meters to ITU-R BS.1770 / EBU R128 (momentary/short-term/integrated + true peak), matching ffmpeg's `ebur128` to 0.1 LU per the authors' measurement (README.md "Audio").
- Own DSP: EQ, filters, dynamics, true-peak limiter, delay, reverb, DeNoise, DeHummer, pitch shift; keyframable, latency-compensated (`crates/audio-dsp`).
- Audio Track Mixer / Clip Mixer with faders, pan, five insert slots per track, sends, submixes, and Read/Latch/Touch/Write automation recorded during playback (`crates/engine/src/mixer.rs`, `docs/control-protocol.md`).
- Essential Sound (Dialogue/Music/SFX/Ambience, loudness auto-match, ducking that writes keyframes) via `essentialSound.*` (`crates/engine/src/essential_sound.rs`).
- Audio-clock playback (sound card is master) and voice-over recording with punch-in (`crates/ui-egui/src/lib.rs`, `crates/engine/src/voiceover.rs`). **New in 0.11.0**: a failed/lost audio output is reopened every 2 s while playing instead of staying silent (`AUDIO_RETRY_S`, `crates/ui-egui/src/lib.rs:266`, `:1123`).
- 0.11.0 hardening: a damaged MP4 AAC packet is rendered as silence over its own span instead of allocating its untrusted duration (`crates/codecs/src/mp4.rs:103`, `:495-512`).

### Titles, graphics, captions, transcripts (implemented, with build gates)

- Text engine (OpenType shaping, kerning, ligatures, bidi), Type/Shape/Pen tools, graphic clips with text/shape layers, `.fcgt` graphics templates (`crates/text`, `crates/engine/src/graphics.rs`, `crates/engine/src/graphic_templates.rs`). `.mogrt` is refused by design (`docs/target-app-parity.md`). Graphic layer properties are keyframable and animated in Properties/Effect Controls (`docs/graphics.md:15-19`).
- Caption tracks in Subtitle / CEA-608 / CEA-708 / Teletext (`crates/project/src/caption.rs:18-31`). Import and export **SRT, WebVTT, SCC, MCC, EBU STL, TTML, DFXP** (7 formats: `crates/captions/src/lib.rs:49`), and burn captions into exports (`burnCaptions`, `captionSidecar: "srt"|"vtt"`; `crates/engine/src/export_tools.rs:277`, `:315`). The README names only SRT/WebVTT/SCC.
- Text-based editing: `transcript.*` commands work, **but recognition needs a `whisper` build**; official releases build with no features, so `transcript.generate` returns an explicit "speech-to-text is not available in this build" error (`crates/engine/src/transcript.rs:59-61`; `packaging/macos/package.sh:61`). Import a transcript with `transcript.set`.
- Text-to-speech narration: `tts.*` with built-in **Basic Female / Basic Male** formant voices; Kokoro-82M neural voices need the `neural-voices` feature (off in releases) plus a download (`apps/filmcraft/Cargo.toml:12-16`, `crates/tts/README.md`).
- Interface localisation: English + 11 catalogues (de, es, fr, id, it, ja, ko, pt-BR, ru, uk, zh-CN); German covers the full Spanish catalogue (3 590 entries); errors/CLI/MCP stay English (`crates/ui-egui/src/i18n/`, `docs/localization-parity.md`).

### Import and open (implemented — exact lists)

- Extension lists are code, not docs: `STILL_EXTENSIONS`, `AUDIO_EXTENSIONS`, `VIDEO_EXTENSIONS` (`crates/media/src/lib.rs:175-178`).
- Container openers, in order: MP4/MOV, Matroska/WebM, MXF, Ogg, MPEG-TS/PS + MPEG-1/2 ES, APV, AVI, Y4M, standalone audio (`crates/codecs/src/lib.rs:135-138`); plus a streaming `reader_openers` registry for platform sources (`:157-165`). Stills/animated images/WAV fall back in `crates/media`.
- Video decoded: H.264 (8-bit 4:2:0 software; High 10/4:2:2 only through OS hardware), HEVC Main/Main 10, VP8, VP9, AV1, ProRes, DNxHD/HR, MPEG-2/1, MJPEG, APV, uncompressed; VP9/Opus/AV1 also from MP4 (`docs/codec-parity.md:18-24`).
- Audio decoded: AAC-LC, AC-3, **E-AC-3 (partial — plays the 5.1 core; no AHT, enhanced coupling or 7.1 dependent substreams, `docs/codec-parity.md:45`)**, Opus, Vorbis, MP1/MP2/MP3, FLAC, ALAC, PCM (`crates/ac3`, `crates/codecs/src/audio.rs`).
- Stills incl. EXR, DPX, Targa, DNG/CinemaDNG, Radiance HDR; animated GIF/APNG import as clips (`crates/media/src/still/`, `crates/media/src/animated.rs`). Image sequences: `file.importImageSequence`, CLI `probe --image-sequence`.
- **AVI is implemented** (AVI 1.0 + OpenDML; MJPEG/H.264/HEVC/uncompressed + PCM/MP3/MP2/AC-3) — `crates/avi/README.md`, `avi::opener` in `crates/codecs/src/lib.rs:136`. **Doc drift**: `docs/file-format-parity.md:43` still says "no demuxer (#598)". Trust the code.

### Native project format and durability (implemented)

- `.fcproj` = UTF-8 JSON with `format: "filmcraft.project"` and an explicit `schema_version`, currently **15** (14 migrations v1→v15, `crates/format/src/lib.rs:62-66`); every version from 1 migrates on load and newer files are refused, not half-read. **Doc drift**: the example in `docs/project-files.md:11` still shows `schema_version: 13`.
- Media referenced by path (never embedded), with size + first/last-MiB fingerprints for relinking (`docs/project-files.md`; stored-path policy in `crates/engine/src/doc_path.rs`).
- **Atomic saves** (temp file → fsync → rename → fsync dir) for projects, auto-saves, recovery snapshots and preferences (`crates/format/src/atomic.rs`, `docs/project-files.md:88-99`). 0.11.0 added `atomic_write_new` (no-clobber publication) for extracted audio (`crates/format/src/atomic.rs:49-75`).
- Auto-save ring (default every 5 min, 20 versions) **plus** a crash-recovery journal written ~1 s after each edit and restored after a crash (`docs/project-files.md:113-180`). **New in 0.11.0**: auto-save names gain a `-<unix seconds>` suffix (`<name>-YYYY-MM-DD_HH-MM-SS-<unix>.fcproj`) so a DST clock change cannot reorder or overwrite them; old names still list (`crates/format/src/autosave.rs:61`, `docs/project-files.md:128-131`).
- Offline media never blocks opening: missing files render a "MEDIA NOT FOUND" slate, audio is silent, Link Media appears (`docs/project-files.md`). Repair with `media.findMissing` / `media.relink` / `media.autoRelink` / `media.search` (`crates/engine/src/relink.rs`).
- Proxies (ProRes Proxy/LT or H.264 presets), ingest (copy/transcode/createProxies), Project Manager collect/consolidate; exports always use full resolution, never the proxy (`docs/project-files.md`, `crates/engine/src/proxies.rs:46-63`).

### Export (implemented)

- Export formats are the `Format` enum (`crates/export/src/lib.rs:64-134`, 21 variants): H.264, HEVC, AV1, ProRes, DNxHR, APV, MJPEG, PNG/TIFF/BMP/JPEG/Targa/DPX/EXR sequences, GIF, WAV, AIFF, AAC (`.m4a` or ADTS `.aac`), FLAC, MXF OP1a, MXF OP-Atom.
- Availability is machine-dependent and queryable: `export.formats` reports `available` per format (`crates/engine/src/export_tools.rs:1112-1123`). **HEVC has no software encoder** — it is offered only where VideoToolbox (macOS) or NVENC (Windows) registers a probe (`crates/platform/src/lib.rs:70-100`). **AV1 registers no encoder on any platform**, so despite the enum variant `av1` is effectively unavailable (`crates/export/src/lib.rs:253-255`; `grep register_format_probe` finds only HEVC).
- **39 built-in presets** ("Match Source – Adaptive High Bitrate" is default; counted in `builtin_presets`, `crates/export/src/presets.rs:95-190`, default at `:35`), plus user presets in `<data dir>/export-presets.json`.
- Export queue as background jobs with progress/ETA/cancel, Quick Export, render previews (`export.queue.*`, `export.quick`, `jobs.list`, `jobs.cancel`; `crates/engine/src/export_tools.rs`, `crates/engine/src/previews.rs`).
- Hardware encoding: H.264 via VideoToolbox (macOS) or NVENC (Windows/Linux, opt-in); **HEVC export is hardware-only** — NVENC writes Main 8-bit SDR and Main 10 HDR (PQ/HLG), VideoToolbox writes Main 8-bit SDR (`crates/platform/src/hardware_encode.rs`, `README.md` "Status", issue #30).
- Options include `burnCaptions`, `captionSidecar`, `alpha`, `exrCompression`, `loudnessLufs`, `hardwareEncoding`, `gpuRendering`, `range: entire|inOut|workArea|custom` (`crates/engine/src/commands.rs:1599-1603`). **`workArea` needs a work area in the project file**: no UI or command sets one (`grep work_area crates/engine/src` finds only the export reader), so it errors with "the sequence has no work area" — use `inOut` or `custom` (`crates/engine/src/export_tools.rs:355`).
- Offline media in an export is reported, not hidden: the result lists `offlineMedia`, stderr names each item, exit status 1 unless `--allow-offline` (`apps/filmcraft-cli/src/main.rs:529-556`, `docs/agents.md:105-132`).

### Interchange (implemented; partly unvalidated)

- Import **and** export: CMX 3600 EDL, Final Cut Pro 7 XML (`xmeml` v4/v5), FCPXML 1.9–1.11, OpenTimelineIO JSON, AAF (Edit Protocol, embedded/consolidated audio), OMF 2.0; Avid Log Exchange (ALE) export only; markers CSV export only (`markers.exportCsv`) (`crates/interchange/src/lib.rs:1-16`, `crates/interchange/src/ale.rs:78`).
- Detection sniffs content before trusting the extension (AAF/OMF structured storage, `<xmeml`/`<fcpxml`, `"OTIO_SCHEMA"`, EDL headers — `crates/interchange/src/lib.rs:110-138`). Every importer merges as one undoable step and returns a report of what could not be represented (`crates/engine/src/interchange.rs:55-90`).
- 0.11.0: AAF/OMF embedded audio is written **without overwriting** an existing file; collisions get `name (2).wav`, `name (3).wav` … and the media item points at the new name (`crates/engine/src/interchange.rs:30-52`).
- **Unvalidated in the wild**: AAF/OMF have never been opened in Media Composer/Pro Tools; FCP7 XML import of a Premiere sequence was measured at 97 s (`docs/gaps.md` G15).

### Automation surface (implemented)

- CLI `filmcraft-cli` with **11 subcommands**: `exec`, `run`, `commands`, `describe`, `inspect`, `import`, `export`, `render`, `probe`, `bench-decode`, `mcp` (`apps/filmcraft-cli/src/main.rs:63-145`).
- **New in 0.11.0 — local CLI waits for exports**: `exec file.exportMedia` and each line of `run` force `wait: true` unless the params say exactly `"wait": false`, because the process exits afterwards and a background export would never be written (`apps/filmcraft-cli/src/main.rs:171-190`; `crates/automation/src/long_job.rs:18`).
- Control channel: `filmcraft --control <port>` or `FILMCRAFT_CONTROL_PORT`; one JSON object per line on 127.0.0.1 — engine commands, UI inspection, synthetic input, screenshots, `perf.stats` (`apps/filmcraft/src/control_server.rs`, `crates/ui-egui/src/control.rs`, `docs/control-protocol.md`).
- MCP server on stdio, headless or via `--bridge`: **17 tools** (`command_list`, `command_run`, `command_batch`, `doc_inspect`, `render_preview`, `project_inspect`, `sequence_inspect`, `media_import`, `render_frame`, `ui_inspect`, `ui_elements`, `ui_click`, `ui_drag`, `ui_key`, `ui_type`, `ui_screenshot`, `ui_control`) and **2 resources** (`filmcraft://document`, `filmcraft://commands`) (`crates/automation/src/server.rs:317-560`, `:645-666`, `docs/agents.md:57-77`, `.mcp.json`).
- Long MCP exports: `command_run {"id":"file.exportMedia","params":{…,"wait":true}}` emits `notifications/progress` and stops on `notifications/cancelled`, deleting partial output; without `wait` it returns `{job, path, poll: "jobs.list", cancel: "jobs.cancel"}` (`crates/automation/src/long_job.rs`, `docs/agents.md:105-132`).
- Web build exposes the same engine as JS promises: `window.filmcraft.{execute,request,commands,inspect,screenshot,importFiles,importUrl,openProject,files,readFile,info}` (`docs/web.md:107-124`, `apps/filmcraft-web/src/api.rs`).
- **Counts (unchanged from v0.10.0)**: 11 CLI subcommands, 17 MCP tools, 21 export formats, 39 presets, 7 caption formats, 7 workspaces, 28 panels, 4 shortcut presets. Diffing every quoted dotted id in `crates/engine/src` between v0.10.0 and v0.11.0 shows **no command ids added or removed** (the only new dotted string is the filename `protected.wav`). Static extraction at this tag finds **626 unique engine command ids** (576 from `cmd!`/`query!`/`spec(`/`query(`, including the ids inside `align_cmd!`, `arrange_cmd!` and `label_cmd!`, plus 50 generated by `camera_keys!`, `tt!` and `sc!`) and **212 UI-only ids** in `crates/ui-egui/src` (`uic!`). The README claims ">650 engine commands" — higher than this static count, so enumerate with `filmcraft-cli commands` / `command_list` at runtime (not run here — the repo was read-only).

## Known limitations and not-implemented

Do not assign these to FilmCraft; they are absent from the code or gated off in releases.

- **`.prproj` cannot be opened or written** (`grep -ri prproj crates apps` finds nothing; `docs/gaps.md` G2 — the stated beta blocker). Import Premiere work through FCP7 XML, AAF or OTIO.
- **No plug-in hosting**: no VST3/Audio Units, OpenFX, UXP or Adobe plug-in APIs (`docs/gaps.md` G11). Settings ▸ Plugins only offers a developer-mode toggle and says "No plugins are installed" (`crates/engine/src/settings.rs:1316-1321`).
- **Delivery codecs**: H.264 is the only software delivery encoder (plus ProRes/DNxHR/APV/MJPEG). HEVC needs hardware (VideoToolbox on macOS, NVENC on Windows — not Linux); **AV1 has no encoder**; no MPEG-2/DVD/Blu-ray/DCP, no MP3 or WMV/FLV writes, no interlaced encoding (`docs/gaps.md` G13, `crates/export/src/lib.rs:253-255`, `crates/platform/src/nvenc/export.rs:212-216`).
- **Camera RAW is DNG only**: no R3D, ARRIRAW, Sony RAW/X-OCN, Canon RAW, BRAW, ProRes RAW, JPEG 2000/XS MXF (`docs/gaps.md` G10).
- **10-bit / 4:2:2 camera H.264 and HEVC decode only through OS hardware**; without a hardware decoder there is no software fallback (`docs/gaps.md` G3, `docs/codec-parity.md:18-19`).
- **Stills that will not open**: PSD, HEIF/HEIC, AI/EPS, ICO; EXR only scan-line none/RLE/ZIPS/ZIP/PXR24 (no PIZ/B44/DWA/tiled/deep) (`docs/file-format-parity.md:57-63`).
- **No caption codecs embedded in the video stream** (CEA-608/708 in H.264 SEI or MXF) — burn-in and sidecar export only (`docs/file-format-parity.md`).
- **One project at a time.** `file.closeAllOtherProjects` exists only to report "only one project is open" (`crates/engine/src/project_tools.rs:90-91`). Sequences open in Timeline tabs; there are no Productions.
- **No work area bar**: `docs/keyboard.md:64` says so, and no command sets `work_area`, so the export range `workArea` is unusable in practice (see Export above).
- **Speech to text is off in official builds** (`docs/gaps.md` G19); import a transcript with `transcript.set`. **Kokoro neural TTS voices are off in official builds** (`neural-voices` feature).
- **Export destinations beyond "Media File" do not exist.** The README screenshot alt text advertises YouTube, Vimeo, TikTok, Instagram and FTP destinations; the code registers exactly one, `export.destination.mediaFile` (`crates/ui-egui/src/panels/export_mode.rs:204`). "YouTube 1080p Full HD" etc. are **presets**, not upload destinations.
- **AI features are minimal**: no Object Mask, Generative Extend, media-intelligence search, caption translation, model-based Enhance Speech or auto colour (`docs/gaps.md` G12; no such code in `crates/engine/src`).
- **UI/UX gaps**: this list is not exhaustive, but verified examples at this tag are no work area bar and no Productions (both above). **Do not repeat older gap lists blindly**: `docs/gaps.md` G8 and `docs/ui-parity.md` (last reviewed 2026-10-10) still claim "no on-monitor transform handles", "no Effect Controls divider/row lines" and "no marquee in the Project panel"; the v0.11.0 code has all three (`crates/ui-egui/src/panels/transform_handles.rs`, `effect_controls.rs:319-327`, `project_views.rs:581-652`), and continuous timeline thumbnails exist (`timeline.rs:3310`). Track names are settable with `timeline.setTrack {name}` (`crates/engine/src/commands.rs:2859-2863`) even though G8 lists renaming as missing.
- **Windows and Linux are far less tested than macOS** (`docs/gaps.md` G9); **the web app shell is incomplete** — file access, WebCodecs decode, browser audio; image-sequence export drops frames in Chrome (`docs/gaps.md` G20, `docs/web.md`).
- **Performance**: colour grading, keys and export rendering run on the CPU; GPU compositing is partial (README.md "Status").
- **FreeBSD aarch64 is not in the 0.11.0 release** (release notes); x86_64 is.
- **Command total**: the README's "more than 650 engine commands" (README.md:233) is **not confirmed** by static extraction (626 unique engine ids + 212 UI ids); it may count further registrations. Enumerate with `filmcraft-cli commands` on a built binary.
- **Known doc drift (trust the code)**: file-format-parity AVI row (`docs/file-format-parity.md:43`), project-files schema example (`:11`, says 13; code writes 15), README "26 blend modes" (code 27) and "around 30 transitions" (code 84+21), README "Not yet: … E-AC-3" (codec-parity.md:45 documents a 75 %-complete E-AC-3 decoder), `docs/gaps.md` G8/`ui-parity.md` UI rows, and `docs/target-app-parity.md` "45 crates" (the workspace has 50 crates + 3 apps).

## How to operate

**Launch (macOS).** `open -a FilmCraft` or `open -a FilmCraft cut.fcproj`. A `.fcproj` argument opens as a project; any other file is imported as media; the extension match is case-insensitive (`apps/filmcraft/src/args.rs:120-124`). Binary: `/Applications/FilmCraft.app/Contents/MacOS/FilmCraft`; the bundle is universal (Apple silicon + Intel), minimum macOS 11.0, app id `ai.storyteller.filmcraft`, documents UTI `ai.storyteller.filmcraft.project` (`packaging/macos/package.sh:38`, `packaging/macos/Info.plist.in:15-16,37-38,71-88`, installed `Info.plist`).

**Desktop flags** (from the `USAGE` string, `apps/filmcraft/src/args.rs:7-26`; an unknown option is an error, not a file name):

```
filmcraft [options] [project.fcproj | media files...]
  --control <port>      localhost JSON-lines control server   (FILMCRAFT_CONTROL_PORT)
  --control-input-only  accept widget input only from the control server (needs --control)
  --demo | --empty      demo project or empty project
  --recover | --no-recover
  --data-dir <dir>      auto-save, crash recovery and logs    (FILMCRAFT_DATA_DIR)
  --graphics <mode>     default | dx12 (Windows) | software (Windows, Linux)
  --version             print version   -h/--help  print help
```

Started with `--control`, the app opens without stealing focus (`docs/control-protocol.md`). **New in 0.11.0**: Cmd+Q now routes through `app.quit` so unsaved changes prompt before quitting; `--control-input-only` still ignores native menu commands except Quit (`apps/filmcraft/src/native_menu.rs:26-30`, `crates/ui-egui/src/lib.rs:1849`).

**Data directory (macOS):** `~/Library/Application Support/FilmCraft` — `preferences.json`, `Auto-Save/`, `Recovery/`, `Logs/filmcraft.log` (and `crash-<day>.log`), `Media Cache/`, user export and effect presets (`crates/engine/src/autosave.rs:506-521`, `apps/filmcraft/src/logging.rs:34-36`).

**The CLI is not inside the .app.** On macOS `filmcraft-cli` ships as a separate release asset (`filmcraft-cli-<version>-macos-universal.zip`) — `docs/agents.md:48`, `docs/releasing.md:47` — or build it: `cargo run --release -p filmcraft-cli -- commands`.

**CLI shape** (full reference: `references/cli-and-protocol.md`):

```sh
filmcraft-cli commands razor                    # find command ids
filmcraft-cli describe timeline.razor           # one command: menu, shortcut, params, enabled now
filmcraft-cli --demo inspect sequence           # project/sequence as JSON, no window
filmcraft-cli --project cut.fcproj --save exec timeline.razor seconds=3.5
filmcraft-cli --project cut.fcproj --save import a.mov b.wav
filmcraft-cli --project cut.fcproj export out.mp4 --preset "YouTube 1080p Full HD" --start 0 --end 10
filmcraft-cli export --list-presets prores
filmcraft-cli --project cut.fcproj render --seconds 2.5 --out frame.png
filmcraft-cli --bridge 127.0.0.1:9876 exec window.workspace.color   # drive the running app
filmcraft-cli mcp --demo                                            # MCP on stdio, headless
```

Values parse as JSON when they can (`3.5`, `true`, `[1,2]`), else strings; dotted keys nest (capped at 64 levels, `apps/filmcraft-cli/src/args.rs`). Numeric options must be finite — a typo is a usage error, not a silent default (`apps/filmcraft-cli/src/main.rs`). Exit status: 0 success, 1 a command failed or offline media was drawn without `--allow-offline`, 2 usage error (`HELP`, `apps/filmcraft-cli/src/main.rs:63-145`).

**Document model.** One project per running app; sequences are the timelines and open in Timeline tabs. Panels dock/float; 28 panel kinds; workspaces are named layouts (save/reset in `Window ▸ Workspaces`).

**Core workflow.** Import media (⌘I or `file.import`) → build a sequence (`file.newSequence` / `file.newSequenceFromClip`) → edit on the timeline → save `.fcproj` (⌘S; `file.save` / `file.saveAs` ⇧⌘S / `file.saveCopy` ⌥⌘S) → export (`File ▸ Export ▸ Media…`, `file.exportMedia`, or `export.quick`). Verified keys: `Cmd+Z`/`Cmd+Shift+Z` undo/redo, `Cmd+K` Add Edit, `Cmd+S` save, `Cmd+O` open, `Cmd+I` import, `Alt+Shift+1..6` workspaces (`crates/engine/src/commands.rs:1493-1503,1616-1617`, `crates/ui-egui/src/menus.rs:111-117`).

**Time.** Ticks everywhere: 254 016 000 000 per second (`crates/time/src/lib.rs:20`). Commands accept `ticks`, `seconds`, `frame` or `timecode`.

## Working with an AI agent

Legitimate and effective:

- **Headless round trips** with `filmcraft-cli` (no window, no GUI state): import → edit via `exec`/`run` → `export` → verify. `run script.jsonl` takes one `{"id","params"}` per line (`#` comments allowed) and stops at the first failure unless `--keep-going` (`apps/filmcraft-cli/src/main.rs:361-387`).
- **Drive the live app** through `--control <port>` or `filmcraft-cli mcp --bridge 127.0.0.1:9876`: run commands, inspect `ui.elements` for automation ids, click/drag/type, screenshot the window or one panel, then `edit.undo` if wrong. Element ids come from the previously rendered frame; after a layout change retry on the next frame (`docs/agents.md`).
- **Enumerate before you guess**: never invent command ids, parameter names or shortcuts. `commands`, `describe <id>` and `command_list` are authoritative and return enablement state.
- **Prepare and convert inputs**: generate test media with ffmpeg (allowed as an external oracle — never linked into the app, `AGENTS.md` §2); convert unsupported sources (`.prproj`, WMV, HEIC, PSD, R3D…) into what FilmCraft reads: FCP7 XML/AAF/OTIO for timelines, ProRes/H.264 MP4 or image sequences for media.
- **Interpret and repair project files**: `.fcproj` is documented JSON with a migration chain and atomic writes — read it, diff it, reason about it. Repair by relinking media through commands (`media.findMissing`, `media.relink`, `media.autoRelink`, `media.search`), not by editing paths while the app has the project open.
- **Verify exports outside the app**: `ffprobe`/`ffmpeg -i` for streams, duration, frame count, A/V sync; check exit status, the `offlineMedia` array, and the written path (the format may change the extension: `out.mp4` exported as APV becomes `out.mp4.mov` — `apps/filmcraft-cli/src/main.rs`, `written_paths`).
- **Follow background exports correctly**: local `file.exportMedia` calls block unless `wait:false`; with the bridge, without `wait`, use the returned `poll: "jobs.list"` / `cancel: "jobs.cancel"` hints. `export.queue.list` lists only the Export Queue, not direct exports (`crates/engine/src/export_tools.rs:546-556`, `docs/agents.md:105-132`). Do not pass `wait:false` to a one-shot local CLI process unless you keep it alive: it exits and the render is lost.
- **Batch production**: `export.queue.add … start=true wait=true` for several deliverables; `jobs.list` for progress/ETA; `jobs.cancel` to stop (`crates/engine/src/export_tools.rs:1156-1172`).
- **Import AAF/OMF repeatedly**: embedded audio is extracted next to the document without clobbering; the media item may point at `name (2).wav` (`crates/engine/src/interchange.rs:30-52`). Read the import result, do not assume the original name.
- **Check the audio path**: audio-device loss during playback is retried every 2 s while the clock continues on the wall clock; a machine with no output still plays picture (`crates/ui-egui/src/lib.rs:266`, `:1146-1155`).

Must not attempt:

- Do not assume `.prproj`, Premiere projects, plug-ins, upload destinations, Whisper transcription or Kokoro voices exist in the installed build.
- Do not drive the GUI blind: read `ui.elements`/`ui.inspect` before clicking by id, and screenshot to confirm. The window may stay behind other windows (by design).
- Do not leave the control port open when idle: it is **loopback-only but has no authentication**, serves 16 connections at once, and a non-JSON line closes the connection (`docs/control-protocol.md:9-17`).
- Do not hand-edit a `.fcproj` to look like a newer schema or copy a `schema_version` forward; older builds refuse newer files, and corrupted fields become "a damaged file" errors (`docs/project-files.md:79-86`).
- Do not expect the headless MCP server to be sandboxed: it can read and write wherever the user can; there are no confinement flags (`docs/agents.md:17-19`).
- Do not commit screenshots of Adobe products or use Adobe artwork when producing documentation assets (repo rule `AGENTS.md` §1).

## Verification protocol

FilmCraft is alpha and estimates itself "~56% ready for real work". Assume every step can silently produce a wrong-but-valid file:

1. **Throwaway round trip first.** New project → import one clip → place → export → `ffprobe` the output → reopen the project in a second process and check `inspect` matches. Only then touch real work.
2. **Never trust a silent export.** Check the exit status, the `offlineMedia` list and the message naming the written files. `filmcraft-cli export` exits 1 when it drew placeholder frames for offline media unless you passed `--allow-offline`.
3. **Read the result as media, not as a file.** Check duration, frame count, frame rate, audio channels and a couple of decoded frames; do not take codec correctness on faith for a deliverable.
4. **Version and back up per session.** Auto-save and the recovery journal are safety nets, not backups. `file.saveAs` / `file.saveCopy` before risky operations; the first save over an upgraded project keeps `<name> (schema vN backup).fcproj`.
5. **Mind the schema.** A project saved by a newer build cannot be opened by an older one (it is refused). Update apps only *between* projects.
6. **Do not trust parity docs or the README over the code.** They drift (AVI row, schema example, blend-mode and transition counts, the G8/UI-parity gap list — all stale at this tag). When a doc and the code disagree, the code wins; when both are silent, write "uncertain" and test.
7. **Record the exact build** you tested (version + commit, e.g. 0.11.0 / `74242b51…`) — bug reports with real footage and a build id are what the project asks for.

## Sources & evidence

- Repo: https://github.com/storytold/filmcraft — inspected at **tag `v0.11.0`, commit `74242b51d675514da12d9bbf6b331ef2e6399211`** (detached worktree, `git rev-parse HEAD`), **2026-10-23**. The installed app reports `filmcraft 0.11.0` and its `Info.plist` records the same build commit, so the bundle is this release; users on other builds may lag or lead this pin — verify against your installed version (`filmcraft --version`).
- Files read: `README.md`, `Cargo.toml`, `AGENTS.md`, `ROADMAP.md`, `.mcp.json`, `apps/filmcraft/{Cargo.toml,src/args.rs,src/main.rs,src/native_menu.rs,src/logging.rs}`, `apps/filmcraft-cli/{Cargo.toml,src/args.rs,src/main.rs}`, `apps/filmcraft-web/src/api.rs`, `docs/{agents,control-protocol,project-files,architecture,keyboard,gaps,target-app-parity,file-format-parity,codec-parity,captions,graphics,transcripts,web,releasing,localization-parity}.md`, `crates/engine/src/{commands.rs,project_tools.rs,transcript.rs,marker_export.rs,export_tools.rs,settings.rs,multicam.rs,shortcuts.rs,panels.rs,interchange.rs,relink.rs,proxies.rs,trim.rs}`, `crates/automation/src/{server.rs,long_job.rs}`, `crates/export/src/{lib.rs,presets.rs}`, `crates/interchange/src/lib.rs`, `crates/media/src/lib.rs`, `crates/codecs/src/{lib.rs,mp4.rs,audio.rs}`, `crates/format/src/{lib.rs,atomic.rs,autosave.rs}`, `crates/project/src/{effect.rs,effect/vfx.rs,effect/audio.rs,vtransition.rs,caption.rs}`, `crates/captions/src/lib.rs`, `crates/ui-egui/src/{menus.rs,dock.rs,lib.rs,control.rs,i18n/}`, `crates/ui-egui/src/panels/{export_mode.rs,settings.rs,text.rs,effect_controls.rs,project_views.rs,trim_monitor.rs}`, `crates/platform/src/{lib.rs,hardware_encode.rs}`, `packaging/macos/{package.sh,Info.plist.in}`, plus `git diff v0.10.0..v0.11.0` (53 files, +2468/−136) and the v0.11.0 release notes.
- Shared library consulted: `storytold/craft-libs` (`craft-docpath` stored-path policy in `crates/engine/src/doc_path.rs`; `craft-ui` docking/layout components).
- See `evidence.md` in this directory for the claim → evidence table, the corrections against the v0.10.0 skill, and how to re-verify.

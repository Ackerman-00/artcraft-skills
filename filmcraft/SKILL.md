---
name: filmcraft
description: FilmCraft is an open-source, professional non-linear video editor (video editing, colour, audio, export) written from scratch in pure Rust, mirroring Adobe Premiere Pro's workflow, for macOS/Windows/Linux and the web. Trigger this skill whenever the user mentions FilmCraft (or "fcproj", "filmcraft-cli", the FilmCraft control channel/MCP server), asks what it can or cannot do, which formats it reads or writes, how to script or automate it, how to prepare or convert media for it, how to verify or repair its exports and project files, or troubleshoot it — and also when they never name the app but describe the job: "cut this footage", "make a rough cut", "export an H.264 MP4", "grade this clip", "add captions to this video", "hand an EDL/AAF to an editor", "drive a video editor from an agent". Prefer this skill over generic NLE knowledge for anything FilmCraft touches; do not assume Premiere-only capabilities (e.g. `.prproj` import) exist here.
---

# FilmCraft

## Overview

FilmCraft is a non-linear video editor: an open-source, **professional NLE whose panels, workspaces, tools and shortcut conventions mirror Adobe Premiere Pro**, written from scratch in pure Rust — codecs included (README.md:26-28; parity is measured against Premiere Pro 2026 26.5.2 in `docs/target-app-parity.md`; the clean-room rules are `AGENTS.md` §2). Native on macOS, Windows and Linux (a FreeBSD tarball ships per release) and in the browser via WebAssembly (`apps/filmcraft-web`, `docs/web.md`). Own H.264/HEVC/VP8/VP9/AV1/ProRes/DNxHD-DNxHR/APV/MJPEG/MPEG-1-2/AAC/AC-3+E-AC-3/Opus codecs and own containers (MP4/MOV, Matroska/WebM, MXF, MPEG-TS/PS, AVI, Ogg); MP3, FLAC, ALAC and Vorbis decode through the `symphonia` crate for now (README.md "Formats and codecs"), and no FFmpeg is linked or bundled (`Cargo.toml`, `AGENTS.md` §2).

Architecture: a layered Cargo workspace (50 crates + 3 apps, `ls crates apps`; table in `docs/architecture.md`) with a **headless engine** — every feature is an engine command reachable without a window (`docs/architecture.md` §1). The egui UI, the CLI, a JSON-lines control channel and an MCP server all dispatch the same command ids (`crates/ui-egui/src/menus.rs`, `apps/filmcraft-cli/src/main.rs`, `crates/automation/src/server.rs`).

**Maturity: alpha.** The project's own parity assessment (2026-10-10, against Premiere Pro 26.5.2) is **~86% feature breadth, ~56% "ready for real work"** (`docs/target-app-parity.md`, README.md "Status"). Treat every export and every project file as needing verification.

Source: GitHub `storytold/filmcraft`. This skill was written from tag **v0.10.0**, commit `cdf43fd366e378da266cb6d3c94549a45244be1f` (2026-10-19); the installed app on this Mac reports `filmcraft 0.10.0` — the installed build is this build. App id `ai.storyteller.filmcraft`; macOS deployment target 11.0 (`packaging/macos/package.sh:38`, `packaging/macos/Info.plist.in:16`).

Deep detail lives in `references/cli-and-protocol.md` (CLI + control channel + MCP) and `references/formats.md` (import/export tables, useful command ids).

## Capabilities (verified)

### Editing (implemented)

- Three-point editing: Source monitor In/Out → `source.insert` (`,`) / `source.overwrite` (`.`); `sequence.lift` (`;`) / `sequence.extract` (`'`) (`crates/engine/src/commands.rs:2576-2577`, `:2080`, `:2086`).
- Trim tools and modes: ripple, roll, slip, slide, rate stretch, razor (`timeline.razor`, `commands.rs:2845`); trim mode + Trim Monitor + deterministic dynamic trimming (`trim.shuttle`/`trim.tick`/`trim.shuttleStop` — `docs/control-protocol.md`, `crates/engine/src/trim.rs`).
- Add Edit (`sequence.addEdit`, ⌘K), ripple delete / close gap, nesting, markers with colours/names/durations, `markers.exportCsv` (UTF-8 CSV, 100 000-marker / 16 MiB caps — `crates/engine/src/marker_export.rs:12`, `:41`), scene edit detection, subclips, sync/merge clips, multicam source sequences with live angle switching (`crates/engine/src/multicam.rs`).
- **Exact integer time**: 254 016 000 000 ticks per second; 23.976/29.97-DF/59.94 are exact (`docs/architecture.md`; every command accepts `ticks`, `seconds`, `frame` or `timecode`).
- Unlimited undo on copy-on-write snapshots; new projects keep 200 history steps (`crates/engine/src/commands.rs:1140-1144`, inside `file.newProject`); History panel.
- Track colour labels settable from automation (`timeline.setTrack` now takes `label`; `crates/engine/src/commands.rs:2860-2910` — new in 0.10.0).
- Keyboard Shortcuts editor with four presets: FilmCraft Default, Premiere Pro Compatible, Final Cut Pro Compatible, Avid Media Composer Compatible (`crates/engine/src/shortcuts.rs:59-62`, `crates/engine/src/shortcut_presets.rs`).
- Workspaces: Editing, Assembly, Color, Effects, Audio, Captions and Graphics, All Panels (`crates/ui-egui/src/menus.rs:111-117`); 28 dockable panel kinds (`crates/ui-egui/src/dock.rs:14-46`); docking/floating is scriptable (`window.dockPanel`, `window.floatPanel`, `window.dockAction` — `docs/control-protocol.md`). New in 0.10.0: `view.resetInterfaceZoom` (`crates/ui-egui/src/menus.rs`).

### Colour, effects, motion (implemented; some effects approximate)

- Colour panel: Basic Correction, Creative looks (eight built-in, code-written transforms), RGB + hue/sat/luma curves, three-way colour wheels, HSL Secondary, Vignette; LUT import/export (`.cube`, `.3dl`) via `lut.*`/`lumetri.*` (`docs/control-protocol.md` "Colour", `crates/engine/src/color.rs`).
- **93 video effects across 16 folders**, asserted by test `premiere_26_video_effects_catalogue` (`crates/project/src/effect/vfx.rs:1262-1263`); **53 audio effects** (`crates/project/src/effect/audio.rs:578`); **84 video transitions (+21 Legacy) in 10 folders**, asserted at `crates/project/src/vtransition.rs:416-417`.
- Blend modes: **27 entries** including Normal (`BLEND_MODES`, `crates/project/src/effect.rs:144-172`). The README's "26 blend modes" undercounts its own code — trust the code.
- Keyframes: linear, Bezier, auto/continuous Bezier, hold, ease in/out; value and velocity graphs; keyframable effect parameters and masks (`crates/project/src/keyframe.rs`, `crates/engine/src/masks.rs`).
- Compositing: wgpu GPU compositor (Metal/Vulkan/DX12/WebGPU) with a CPU reference renderer the GPU path is tested against (`crates/gpu/`, `docs/architecture.md` principle 5).
- **Approximate, not exact**: Warp Stabilizer is 2-D, Morph Cut has no face tracking, object masks (Premiere 26 AI) do not exist (`docs/gaps.md` G18, G12).

### Audio (implemented)

- Loudness meters to ITU-R BS.1770 / EBU R128 (momentary/short-term/integrated + true peak); the integrated reading matches ffmpeg's `ebur128` to 0.1 LU (README.md "Audio" — authors' measurement).
- Own DSP effects (EQ, filters, dynamics, true-peak limiter, delay, reverb, DeNoise, DeHummer, pitch shift), keyframable, latency-compensated (`crates/audio-dsp`).
- Track Mixer / Clip Mixer, submixes, sends, five insert slots per track, Read/Latch/Touch/Write automation recorded during playback; everything scriptable (`mixer.*`, `clipMixer.*` — `docs/control-protocol.md`).
- Essential Sound panel (Dialogue/Music/SFX/Ambience, loudness auto-match, ducking that writes keyframes) via `essentialSound.*` (`crates/engine/src/essential_sound.rs`).
- Audio-clock playback (sound card is master) (README.md "Audio"); voice-over recording with punch-in (`crates/engine/src/voiceover.rs`).

### Titles, graphics, captions, transcripts (implemented, with build caveats)

- Text engine (OpenType shaping, kerning, ligatures, bidi), Type/Shape/Pen tools, graphic clips, `.fcgt` graphics templates (`crates/text`, `crates/engine/src/graphics.rs`, `crates/engine/src/graphic_templates.rs`). `.mogrt` is refused by design (`docs/target-app-parity.md`).
- Caption tracks in Subtitle / CEA-608 / CEA-708 / Teletext. Import and export **SRT, WebVTT, SCC, MCC, EBU STL, TTML/DFXP**, and **burn captions into exports** (`crates/captions/src/{srt,vtt,scc,mcc,stl,ttml,cea608,burn}.rs`). The README's captions bullet names only SRT/WebVTT/SCC — the code has all seven formats.
- Text-based editing: `transcript.*` commands — **but recognition needs a `whisper` build**; official releases are built without it, so `transcript.generate` returns "speech-to-text is not available in this build (built without the `whisper` feature); import a transcript with transcript.set instead" (`crates/engine/src/transcript.rs:61`; `packaging/macos/package.sh` builds with no `--features`). Import a transcript with `transcript.set`.
- Text-to-speech narration: `tts.*` with built-in **Basic Female/Basic Male** formant voices. Kokoro-82M neural voices need the `neural-voices` feature (off in releases) plus a download (`crates/tts/README.md`, `apps/filmcraft/Cargo.toml:13-19`).
- Interface localisation: English + 11 catalogues (de, es, fr, id, it, ja, ko, pt-BR, ru, uk, zh-CN). German now covers the whole interface (~100%, ROADMAP.md); uk/ru partial; errors/CLI/MCP stay English (`crates/ui-egui/src/i18n/`).

### Import and open (implemented — exact lists)

- Extension lists are code, not docs: `STILL_EXTENSIONS`, `AUDIO_EXTENSIONS`, `VIDEO_EXTENSIONS` (`crates/media/src/lib.rs:175-179`).
- Openers registered in order: MP4/MOV, Matroska/WebM, MXF, Ogg, MPEG-TS/PS + MPEG-1/2 ES, APV, AVI, Y4M, standalone audio (`crates/codecs/src/lib.rs:135-138`); then stills/animated images/WAV fallbacks (`crates/media/src/lib.rs`).
- Video decoded: H.264 (8-bit 4:2:0 software; High 10/4:2:2 via OS hardware), HEVC Main/Main 10, VP8, VP9, AV1, ProRes, DNxHD/HR, MPEG-2/1, MJPEG, APV, uncompressed; VP9/Opus/AV1 also read from MP4 (`docs/codec-parity.md`, crate READMEs).
- Audio decoded: AAC-LC, AC-3 and **E-AC-3 (partial — plays the 5.1 core: independent substream only, no AHT/enhanced coupling/7.1 dependent substreams, `docs/codec-parity.md:45`)**, Opus, Vorbis, MP1/MP2/MP3, FLAC, ALAC, PCM (`crates/ac3`, `crates/codecs/src/audio.rs`).
- Stills incl. EXR, DPX, Targa, DNG/CinemaDNG, Radiance HDR; animated GIF/APNG as clips (`crates/media/src/still/`, `crates/media/src/animated.rs`). Image sequences: `file.importImageSequence`, CLI `probe --image-sequence`.
- **AVI is implemented** (AVI 1.0 + OpenDML; MJPEG/H.264/HEVC/uncompressed + PCM/MP3/MP2/AC-3) — `crates/avi/README.md`, `crates/codecs/src/lib.rs` (`avi::opener`). **Doc drift**: `docs/file-format-parity.md:43` still says AVI has "no demuxer (#598)". Trust the code.

### Native project format and durability (implemented)

- `.fcproj` = UTF-8 JSON with `format: "filmcraft.project"` and an explicit `schema_version`, currently **15** (14 migrations v1→v15, `crates/format/src/lib.rs:62-66`); every version from 1 migrates on load; newer files are refused, not half-read. **Doc drift**: the example in `docs/project-files.md:11` still shows `"schema_version": 13` — the code is authoritative.
- Media referenced by path (never embedded); items carry a size + first/last-MiB fingerprint for relinking (`docs/project-files.md`).
- **Atomic saves** (temp file → fsync → rename → fsync dir) for projects, auto-saves, recovery snapshots and preferences (`docs/project-files.md:88-99`).
- Auto-save ring (default every 5 min, 20 versions) **plus** a crash-recovery journal written ~1 s after each edit, restored after a crash (`docs/project-files.md:113-173`).
- Offline media never blocks opening: missing files render a "MEDIA NOT FOUND" slate, audio is silent, Link Media appears (`docs/project-files.md:261-316`).
- Proxies (ProRes Proxy/LT or H.264 presets), ingest (copy/transcode/createProxies), Project Manager collect/consolidate; export always uses full resolution, never the proxy (`docs/project-files.md:318-409`).

### Export (implemented)

- Export formats are the `Format` enum (`crates/export/src/lib.rs:64-133`): H.264, HEVC, AV1 (both hardware-encoder-gated), ProRes, DNxHR, APV, MJPEG, PNG/TIFF/BMP/JPEG/Targa/DPX/EXR sequences, GIF, WAV, AIFF, AAC (`.m4a` or ADTS `.aac`), FLAC, MXF OP1a, MXF OP-Atom.
- **39 built-in presets** ("Match Source – Adaptive High Bitrate" default, YouTube/Vimeo/4K, ProRes family, DNxHR, APV, MXF, image sequences, GIF, audio-only), user presets in `<data dir>/export-presets.json` (`crates/export/src/presets.rs:95-190`).
- Export queue as background jobs with progress/ETA/cancel; Quick Export (`export.queue.*`, `export.quick`, `jobs.list`, `jobs.cancel`); render previews with a green/yellow/red render bar (README.md "Export", `crates/engine/src/previews.rs`).
- Hardware encoding: H.264 via VideoToolbox (macOS) or NVENC (Windows/Linux, opt-in); **HEVC export is hardware-only** — NVENC writes Main 8-bit SDR and Main 10 HDR (PQ/HLG), VideoToolbox writes Main 8-bit SDR (`crates/platform/src/hardware_encode.rs`, README.md "Status", issue #30).
- Options include `burnCaptions`, `captionSidecar: "srt"|"vtt"`, `alpha`, `exrCompression`, `loudnessLufs`, `hardwareEncoding`, `range: entire|inOut|workArea|custom` (`crates/engine/src/commands.rs:1599-1607`).
- Offline media in an export is reported, not hidden: result lists `offlineMedia`, stderr names each item, exit status 1 unless `--allow-offline` (`apps/filmcraft-cli/src/main.rs`, `docs/agents.md:223-230`).

### Interchange (implemented; partly unvalidated)

- Import **and** export: CMX 3600 EDL, Final Cut Pro 7 XML (`xmeml` v4/v5), FCPXML 1.9–1.11, OpenTimelineIO JSON, AAF (Edit Protocol, embedded/consolidated audio), OMF 2.0 (export); Avid Log Exchange (export) (`crates/interchange/src/lib.rs:1-12`).
- Every importer returns a report of what could not be represented, and merges as one undoable step.
- **Unvalidated in the wild**: AAF/OMF have never been opened in Media Composer/Pro Tools; FCP7 XML import of a Premiere sequence was measured at 97 s (`docs/gaps.md` G15).

### Automation surface (implemented)

- CLI `filmcraft-cli`: `exec`, `run`, `commands`, `describe`, `inspect`, `import`, `export`, `render`, `probe`, `bench-decode`, `mcp` (`apps/filmcraft-cli/src/main.rs:63-140`).
- Control channel: `filmcraft --control <port>` (or `FILMCRAFT_CONTROL_PORT`), JSON per line on 127.0.0.1 — engine commands, UI inspection, synthetic input, screenshots, `perf.stats` (`apps/filmcraft/src/control_server.rs`, `crates/ui-egui/src/control.rs`, `docs/control-protocol.md`).
- MCP server on stdio, headless or via `--bridge`: tools `command_list`, `command_run`, `command_batch`, `doc_inspect`, `render_preview`, `project_inspect`, `sequence_inspect`, `media_import`, `render_frame`, `ui_inspect`, `ui_elements`, `ui_click`, `ui_drag`, `ui_key`, `ui_type`, `ui_screenshot`, `ui_control`; resources `filmcraft://document`, `filmcraft://commands` (`crates/automation/src/server.rs:317-560`, `:645-666`, `docs/agents.md:57-77`, `.mcp.json`).
- Web build exposes the same engine as JS promises: `window.filmcraft.{execute,request,commands,inspect,screenshot,importFiles,importUrl,openProject,files,readFile,info}` (`docs/web.md`).
- New in 0.10.0 automation: `file.exportMedia` without `wait` returns `{job, path, poll: "jobs.list", cancel: "jobs.cancel"}` (`crates/engine/src/export_tools.rs:549-556`); MCP `doc_inspect` pins the sequence inspect to the `activeSequence` id it just reported, so the pair is consistent even if tabs switch mid-call (`crates/automation/src/server.rs:288-298`).

## Known limitations and not-implemented

Do not assign these to FilmCraft; they are absent from the code.

- **`.prproj` cannot be opened or written** (`grep -ri prproj crates apps` finds nothing; `docs/gaps.md` G2 — the stated beta blocker). Import Premiere work through FCP7 XML, AAF or OTIO.
- **No plugin hosting**: no VST3/Audio Units, no OpenFX (`docs/gaps.md` G11).
- **Delivery codecs**: H.264 is the main software delivery encoder (plus ProRes/DNxHR/APV/MJPEG). HEVC export needs a hardware encoder; **no HEVC or AV1 software encoder exists** (`crates/export/src/lib.rs` doc comments, `docs/gaps.md` G13). No MPEG-2/DVD/Blu-ray/DCP, no MP3 or WMV/FLV writes.
- **Camera RAW is DNG only**: no R3D, ARRIRAW, Sony RAW/X-OCN, Canon RAW, BRAW, ProRes RAW, JPEG 2000/XS MXF (`docs/gaps.md` G10).
- **10-bit / 4:2:2 camera H.264 and HEVC decode only through OS hardware**; without a hardware decoder there is no software fallback (`docs/gaps.md` G3, `docs/codec-parity.md`).
- **Stills that will not open**: PSD, HEIF/HEIC, AI/EPS, ICO; EXR only the listed compressions (no PIZ/B44/DWA/tiled/deep) (`docs/file-format-parity.md`).
- **No caption codecs embedded in the video stream** (CEA-608/708 in H.264 SEI or MXF) — burn-in and sidecar export only (`docs/file-format-parity.md`).
- **One project at a time.** `file.closeAllOtherProjects` exists only to report "only one project is open" (`crates/engine/src/project_tools.rs:90-91`). Sequences open in Timeline tabs.
- **Speech to text is off in official builds** (`docs/gaps.md` G19); import a transcript with `transcript.set`. **Kokoro neural TTS voices are off in official builds** (`neural-voices` feature).
- **Export destinations beyond "Media File" do not exist.** The README screenshot alt text (README.md:197) advertises YouTube, Vimeo, TikTok, Instagram and FTP destinations; the code has exactly one, `export.destination.mediaFile` (`crates/ui-egui/src/panels/export_mode.rs:204`). "YouTube 1080p Full HD" etc. are **presets**, not upload destinations.
- **AI features are minimal**: no Object Mask, no Generative Extend, no media-intelligence search, no caption translation, no model-based Enhance Speech (`docs/gaps.md` G12).
- **UI fidelity gaps** (`docs/gaps.md` G8): no on-monitor transform handles, no filmstrip thumbnails, no marquee selection in the Project panel, Effect Controls lacks keyframe zoom/row lines; no work area bar (`docs/keyboard.md:64`); no Productions.
- **Windows and Linux are far less tested than macOS** (`docs/gaps.md` G9); **the web app shell is incomplete** — file access, WebCodecs decode, browser audio; image-sequence export drops frames in Chrome (`docs/gaps.md` G20).
- **Performance**: Lumetri, keys and export rendering run on the CPU; GPU compositing is partial (README.md "Status").
- **Claimed but unverified in code**: "more than 650 engine commands" (README.md:226). Static counting finds 219 `cmd!`/`query!` plus 363 `spec(...)` registrations in `crates/engine/src`; the exact total is uncertain — enumerate with `filmcraft-cli commands` on a built binary.
- **Known doc drift (trust the code)**: file-format-parity AVI row (:43), project-files schema example (:11, says 13; code writes 15), README "26 blend modes" (code has 27), README "around 30 transitions" (tests assert 84+21), README "Not yet: … E-AC-3" (codec-parity.md:45 documents a 75%-complete E-AC-3 decoder).

## How to operate

**Launch (macOS).** `open -a FilmCraft` or `open -a FilmCraft "/path/to/edit.fcproj"`. A `.fcproj` argument opens as a project; any other file is imported as media; the extension match is case-insensitive (`apps/filmcraft/src/args.rs:119-124`).

**Desktop flags** (from the `USAGE` string in `apps/filmcraft/src/args.rs:7-26`; an unknown option is an error, not a file name):

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

Started with `--control`, the app opens without stealing focus (`docs/control-protocol.md`).

**Data directory (macOS):** `~/Library/Application Support/FilmCraft` — `preferences.json`, `Auto-Save/`, `Recovery/`, `Logs/filmcraft.log`, `Media Cache/`, user export and effect presets (`docs/project-files.md`).

**The CLI is not inside the .app.** On macOS `filmcraft-cli` ships as a separate release asset (`filmcraft-cli-<version>-macos-<arch>.zip`) — `docs/agents.md:48` — or build it: `cargo run --release -p filmcraft-cli -- commands`.

**CLI shape** (full reference: `references/cli-and-protocol.md`):

```sh
filmcraft-cli commands razor                    # find command ids
filmcraft-cli describe timeline.razor           # one command: menu, shortcut, params, enabled now
filmcraft-cli --demo inspect sequence           # project/sequence as JSON, no window
filmcraft-cli --project p.fcproj --save exec timeline.razor seconds=3.5
filmcraft-cli --project p.fcproj --save import a.mov b.wav
filmcraft-cli --project p.fcproj export out.mp4 --preset "YouTube 1080p Full HD" --start 0 --end 10
filmcraft-cli export --list-presets prores
filmcraft-cli --project p.fcproj render --seconds 2.5 --out frame.png
filmcraft-cli --bridge 127.0.0.1:9876 exec window.workspace.color   # drive the running app
filmcraft-cli mcp --demo                                            # MCP on stdio, headless
```

Values parse as JSON when they can (`3.5`, `true`, `[1,2]`), else strings; dotted keys nest (capped at 64 levels, `apps/filmcraft-cli/src/args.rs:6,90`). Numeric options must be finite numbers — a typo is a usage error, not a silent default (`apps/filmcraft-cli/src/main.rs:556-561`). Exit status: 0 success, 1 a command failed or offline media was drawn without `--allow-offline`, 2 usage error.

**Document model.** One project per running app; sequences are the timelines and open in Timeline tabs. Panels dock/float; 28 panel kinds; workspaces are named layouts.

**Core workflow.** Import media (⌘I or `media_import`) → build a sequence (`file.newSequence`) → edit on the timeline → save `.fcproj` (⌘S) → export (`File ▸ Export ▸ Media…` or `export.quick`). Key ids: `Cmd+Z`/`Cmd+Shift+Z` undo/redo, `Cmd+K` Add Edit, `⌥⌘K` Keyboard Shortcuts, `⌥⇧1..6` workspaces.

**Time.** Ticks everywhere: 254 016 000 000 per second. Commands accept `ticks`, `seconds`, `frame` or `timecode`.

## Working with an AI agent

Legitimate and effective:

- **Headless round trips** with `filmcraft-cli` (no window, no GUI state): import → edit via `exec`/`run` → `export` → verify. `run script.jsonl` takes one `{"id", "params"}` per line, `#` comments allowed, `--keep-going` continues past failures.
- **Drive the live app** through `--control <port>` or `filmcraft-cli mcp --bridge 127.0.0.1:9876`: run commands, inspect `ui.elements` for automation ids, click/drag/type, screenshot the window or one panel, then `edit.undo` if wrong. Element ids come from the previously rendered frame; after a layout change retry on the next frame (`docs/agents.md`).
- **Enumerate before you guess**: never invent command ids, parameter names or shortcuts. `commands`, `describe <id>`, and `command_list` are authoritative and return enablement state.
- **Prepare and convert inputs**: generate test media with ffmpeg (allowed as an external oracle — never linked into the app, `AGENTS.md` §2); convert unsupported sources (`.prproj`, WMV, HEIC, PSD, R3D…) into what FilmCraft reads: FCP7 XML/AAF/OTIO for timelines, ProRes/H.264 MP4 or image sequences for media.
- **Interpret and repair project files**: `.fcproj` is documented JSON with a migration chain and atomic writes — read it, diff it, reason about it. Repair by relinking media through commands (`media.findMissing`, `media.relink`, `media.autoRelink`, `media.search`), not by editing paths while the app has the project open.
- **Verify exports outside the app**: `ffprobe`/`ffmpeg -i` for streams, duration, frame count, A/V sync; check exit status, the `offlineMedia` array, and the written path (the format may change the extension: `out.mp4` exported as APV becomes `out.mp4.mov` — `apps/filmcraft-cli/src/main.rs`, `format_for`/rename logic).
- **Follow background exports correctly**: without `wait`, use the returned `poll: "jobs.list"` / `cancel: "jobs.cancel"` hints. `export.queue.list` lists only the Export Queue, not direct exports — poll `jobs.list` for those (`crates/engine/src/export_tools.rs:549-556`, `docs/agents.md:123-129`).
- **Batch production**: `export.queue.add … start=true wait=true` for several deliverables; `jobs.list` for progress/ETA; `jobs.cancel` to stop.

Must not attempt:

- Do not assume `.prproj`, Premiere projects, plugins, upload destinations, Whisper transcription or Kokoro voices exist in the installed build.
- Do not drive the GUI blind: read `ui.elements`/`ui.inspect` before clicking by id, and screenshot to confirm. The window may stay behind other windows (by design).
- Do not leave the control port open when idle: it is **loopback-only but has no authentication**, 16 connections at once, and a non-JSON line closes the connection (`docs/control-protocol.md:9-17`).
- Do not hand-edit a `.fcproj` to look like a newer schema or copy a `schema_version` forward; older builds refuse newer files, corrupted fields become "a damaged file" errors (`docs/project-files.md:79-86`).
- Do not expect the headless MCP server to be sandboxed: it can read and write wherever the user can; there are no confinement flags (`docs/agents.md:17-19`).
- Do not commit screenshots of Adobe products or use Adobe artwork when producing documentation assets (repo rule `AGENTS.md` §1).

## Verification protocol

FilmCraft is alpha and estimates itself "~56% ready for real work". Assume every step can silently produce a wrong-but-valid file:

1. **Throwaway round trip first.** New project → import one clip → place → export → `ffprobe` the output → reopen the project in a second process and check `inspect` matches. Only then touch real work.
2. **Never trust a silent export.** Check the exit status, the `offlineMedia` list and the message naming the written files. `filmcraft-cli export` exits 1 when it drew placeholder frames for offline media unless you passed `--allow-offline`.
3. **Read the result as media, not as a file.** Check duration, frame count, frame rate, audio channels and a couple of decoded frames; do not take codec correctness on faith for a deliverable.
4. **Version and back up per session.** Auto-save and the recovery journal are safety nets, not backups. `file.saveAs` / `file.saveCopy` before risky operations.
5. **Mind the schema.** A project saved by a newer build cannot be opened by an older one (it is refused). Update apps only *between* projects; keep the `<name> (schema vN backup).fcproj` the first save-over creates.
6. **Do not trust parity docs or the README over the code.** They drift (AVI row, schema example, blend-mode count — all stale right now). When a doc and the code disagree, the code wins; when both are silent, write "uncertain" and test.
7. **Record the exact build** you tested (version + commit, e.g. 0.10.0 / `cdf43fd…`) — bug reports with real footage and a build id are what the project asks for.

## Sources & evidence

- Repo: https://github.com/storytold/filmcraft — inspected at **tag v0.10.0, commit `cdf43fd366e378da266cb6d3c94549a45244be1f`** (detached worktree, `git rev-parse HEAD`), **2026-10-22**. The installed app reports `filmcraft 0.10.0`, i.e. this exact release; users on other builds may lag or lead this pin — verify against your installed version (`filmcraft --version`).
- Files read: `README.md`, `Cargo.toml`, `AGENTS.md`, `ROADMAP.md`, `.mcp.json`, `apps/filmcraft/{Cargo.toml,src/args.rs}`, `apps/filmcraft-cli/{Cargo.toml,src/args.rs,src/main.rs}`, `apps/filmcraft-web/`, `docs/{agents,control-protocol,project-files,architecture,keyboard,gaps,target-app-parity,file-format-parity,codec-parity,captions,web,releasing}.md`, `crates/engine/src/{commands.rs,project_tools.rs,transcript.rs,marker_export.rs,export_tools.rs,settings.rs,multicam.rs,shortcuts.rs}`, `crates/export/src/{lib.rs,presets.rs}`, `crates/interchange/src/lib.rs`, `crates/media/src/lib.rs`, `crates/codecs/src/{lib.rs,mp4.rs,audio.rs}`, `crates/format/src/lib.rs`, `crates/project/src/{effect.rs,effect/vfx.rs,effect/audio.rs,vtransition.rs}`, `crates/captions/src/*`, `crates/ac3/README.md`, `crates/platform/src/hardware_encode.rs`, `crates/tts/README.md`, `crates/ui-egui/src/{menus.rs,dock.rs,control.rs,i18n/}`, `crates/ui-egui/src/panels/{export_mode.rs,mod.rs}`, `crates/automation/src/server.rs`, `packaging/macos/{package.sh,Info.plist.in}`, plus `git diff v0.9.0..v0.10.0` (one release commit, 100 files).
- Shared library consulted: `storytold/craft-libs` (`craft-docpath` — stored-path policy, `crates/engine/src/doc_path.rs`; `craft-ui` — shared egui docking/theme components).
- See `evidence.md` in this directory for the claim → evidence table, and `references/` for the CLI/control-channel reference and the format tables.

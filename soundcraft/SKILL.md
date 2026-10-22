---
name: soundcraft
description: >-
  SoundCraft is a clean-room, pure-Rust digital audio workstation (a Pro Tools-style DAW) for
  macOS, Windows, Linux, FreeBSD and the browser: multitrack audio and MIDI editing, a full
  mixer with built-in and third-party CLAP/VST3/AU plug-ins, automation, recording, bounce/export,
  video and surround — all scriptable through a command layer reachable from the CLI, a JSON
  control channel and an MCP server. Trigger this skill whenever the user mentions SoundCraft,
  asks what it can or cannot do, which audio/session/MIDI formats it reads or writes, its
  keyboard shortcuts, or how to launch, automate, inspect or troubleshoot it — and equally when
  they do not name it but describe the job ("edit this multitrack session", "bounce a mix to
  WAV", "record takes from my interface", "convert audio", "drive a DAW from an agent"). Do not
  infer SoundCraft behaviour from Pro Tools knowledge: read this first.
---

# SoundCraft

## Overview

SoundCraft is an open-source, pure-Rust digital audio workstation: a clean-room reimplementation
of the Avid Pro Tools workflow (recording, editing, mixing, automation, bounce) that also runs in
a browser (`README.md`, `docs/target-app-parity.md`). It is a Cargo workspace of layered crates
plus three entry points — desktop app, `soundcraft-cli`, and a WebAssembly build
(`docs/architecture.md`, `Cargo.toml` workspace members). It is **pre-alpha**: measured menu
breadth is 482/512 of the target's menu leaves (94.1%; engine alone 397/512), about 70 % feature
presence, ~40 % ready for real work, and three core workflows fail the alpha gate — recording
from a chosen interface/buffer, recording MIDI from a controller, and session interchange with
Pro Tools (AAF/OMF/`.ptx`) (`ROADMAP.md`, `docs/roadmap.md` "Alpha gate"). Source:
`github.com/storytold/soundcraft` (organisation `storytold`). This skill describes the
**v0.11.0** release tag (commit `b74fca0fb0f8b4a8474c447c1b6043a5028a5de2`); the installed
`SoundCraft.app` this was checked against reports `SoundCraft 0.11.0` from `--version`. Verify
against your installed version — the Launcher auto-updates and your build may lag or lead this pin.

## Capabilities (verified)

Everything user-visible is a **command**: id, label, menu path, shortcut, parameter doc,
enabled-reason (`crates/engine/src/cmd/mod.rs`; 395 command specs — 394 via the `cmd!` macro plus
one direct struct — across the 30 modules registered in `command_specs()`, 32 files under
`crates/engine/src/cmd/`). Every surface — menus, keyboard, CLI, control channel, MCP —
dispatches the same ids.

### Editing and arrangement
- Edit window with tracks/clips/waveforms, Mix window, movable/dockable panels (Tracks/Groups,
  Clips, MIDI Editor, Memory Locations, Undo History) with `ui.dock`/`ui.dock.reset`
  (`crates/ui-egui/src/docking.rs`, `crates/ui-egui/src/menus.rs`, `docs/control-protocol.md`
  "Panel docking").
- Edit modes Shuffle, Slip, Spot, Grid, Grid-Relative; tools Zoom, Trim, Selector, Grabber,
  Scrubber, Pencil, Smart (`crates/model/src/session.rs`, `enum EditMode`, `enum Tool`).
- Fades and crossfades in five shapes — Linear, EqualPower, SCurve, Exponential, Logarithmic
  (`crates/model/src/clip.rs`, `enum FadeShape`).
- Cut/copy/paste/duplicate/repeat/shift/insert-silence/separate (selection, grid, transients)/
  heal/consolidate/strip-silence/nudge; Tab to Transient (`edit.tab`, with a transient cache),
  Zoom Toggle (`view.zoom_toggle`), loop, quantize-to-grid, clip gain, clip effects, edit locks,
  colour, ratings (`crates/engine/src/cmd/edit.rs`, `edit_more.rs`, `clip.rs`, `clip_more.rs`,
  `tab.rs`, `zoom_toggle.rs`).
- Commands Keyboard Focus: single-key editing in the Edit window (A/S trim, B separate, X/C/V,
  R/T zoom, …), set with `options.keyboard_focus {commands|clips|groups|none}`
  (`crates/ui-egui/src/shortcuts.rs` `commands_focus`, `crates/engine/src/cmd/options.rs`).
- Playlists and comping, clip groups `.scgrp`, Clip List, track folders, VCA masters, track
  freeze/commit/bounce, file-based track presets (`track.save_preset`/`track.load_preset`, JSON)
  (`crates/engine/src/cmd/track.rs`, `track_more.rs`, `clip_list.rs`,
  `crates/engine/src/clip_group_file.rs`).
- Import selected tracks from another session: `file.import_session_data {path, tracks?}`
  (`crates/engine/src/cmd/setup_more.rs`).
- Undo/redo for every document command, with an undo history (`engine.history`)
  (`crates/engine/src/cmd/mod.rs`, `query.rs`; `docs/architecture.md` "Commands and undo").
- Automation: breakpoints for volume, pan, mute, sends and any plug-in parameter; Write, Touch,
  Latch, Touch-Latch, Trim modes; thin, glide, coalesce to/from clip gain
  (`crates/model/src/automation.rs`, `crates/engine/src/cmd/edit_more.rs`, `mix.rs`).

### Mixing and plug-ins
- 10 inserts and 10 sends per track (`crates/model/src/mixer.rs`, `INSERT_SLOTS`/`SEND_SLOTS`),
  busses, aux inputs, master faders, VCAs, routing folders, solo modes, mute/solo groups, phase
  invert, input trim, pre/post sends, automatic plug-in delay compensation
  (`crates/mix/`, `docs/architecture.md`).
- 27 built-in plug-ins: 24 processors (EQ 1/7-band, channel strip, compressor, expander/gate,
  de-esser, maximizer, room & plate reverb, mod delay, chorus, flanger, phaser, saturator, lo-fi,
  rectifier, pitch shifter, time shift, gain, trim, invert, DC removal, signal generator, dither)
  and 3 instruments (subtractive synth, drum synth, sampler) (`crates/dsp/src/plugins/mod.rs`
  `REGISTRY`). Every processor can run offline as AudioSuite (`crates/engine/src/cmd/audiosuite.rs`);
  user presets save per plug-in (`plugin_state.rs`, `mix.insert_state`).
- Third-party hosting in-process: CLAP, VST3 and macOS Audio Units, instances created off the
  audio thread, state saved in the session (`crates/clap-host/src/lib.rs`,
  `crates/vst3-host/src/lib.rs`, `crates/au-host/src/lib.rs`; `docs/plugin-parity.md`).
  Discovery commands `engine.clap_plugins {rescan?}` / `engine.vst3_plugins {rescan?}`; ids
  `clap:<id>`, `vst3:<class id hex>`, `au:<type>:<subtype>:<manufacturer>`
  (`crates/engine/src/cmd/clap.rs`, `vst3.rs`). Plug-in editor windows: CLAP floating (embedded
  only on Windows), VST3 on macOS and Windows; AU has no editors (G-05).

### Recording
- Record arm, input monitoring, punch on selection or on the fly, pre/post-roll, loop recording
  with a playlist per take, destructive/track-punch modes
  (`crates/ui-egui/src/lib.rs` `arm_recorder`/`plan_recording`, `crates/engine/src/io.rs`
  `plan_takes`/`plan_recording`, `crates/engine/src/cmd/options.rs`).
- Takes stream to disk while recording, one WAV per take, header rewritten every second so a
  crash leaves a playable file (`crates/playback/src/record.rs` module doc, `Recorder::arm`,
  `write_takes`).
- Device choice: audio system / output / input device, sample rate and buffer size are selectable
  and kept with preferences (`crates/playback/src/devices.rs` `AudioConfig`,
  `crates/ui-egui/src/windows.rs` `ui.audio_device`); ASIO behind the opt-in `asio` build feature.
- Autosave with crash recovery (`crates/engine/src/autosave.rs`; `Backups/` beside the session on
  overwrite, `crates/engine/src/io.rs` `back_up`).

### MIDI, notation, instruments, time
- Instrument and MIDI tracks, piano-roll MIDI editor with velocity lane and event list, note
  add/edit/delete/move, quantize, input quantize, step input (`event.step_input`), transpose,
  real-time properties, MIDI track offsets, retrospective record
  (`crates/engine/src/cmd/midi.rs`, `event.rs`, `event_more.rs`; `crates/ui-egui/src/midi_editor.rs`).
- `mix.sampler_load {track?, path, params?}` / `mix.sampler_clear` put an audio file on the
  built-in Sampler across the keyboard (root note, key range, loop mode)
  (`crates/engine/src/cmd/sampler.rs`).
- Standard MIDI File import/export (type 0/1) (`crates/midi/src/smf.rs`,
  `crates/engine/src/cmd/file.rs` `file.import_midi`/`file.export_midi`).
- Score Editor, MusicXML export for notation programs, printable SVG score
  (`crates/engine/src/score.rs`; `file.export_sibelius`, `file.send_to_sibelius`,
  `file.print_score`).
- Monophonic audio-to-MIDI pitch tracking (`edit.copy_audio_as_midi`, `track.extract_midi`;
  `crates/engine/src/cmd/audio_midi.rs`, `track_more.rs`); chord detection to markers
  (`event.extract_chords`, `crates/engine/src/cmd/event_more.rs`).
- Timebases Bars|Beats, Min:Secs, Timecode (drop-frame included), Feet+Frames, Samples; tempo and
  meter maps with linear/parabolic/S-curve ramps; key signatures; Identify Beat; Beat Detective;
  Elastic Audio warping (`crates/time/`, `crates/engine/src/cmd/clip.rs`
  `clip.elastic_properties`, `event.beat_detective`, `event.identify_beat`).

### Audio file formats
- **Read:** WAV (PCM 8/16/24/32, float 32/64, `WAVE_FORMAT_EXTENSIBLE`, RF64/BW64, BWF `bext`,
  unfinalised recording WAVs) and AIFF/AIFC via native readers; FLAC, MP3, Ogg Vorbis, AAC/ALAC
  in MP4/M4A, CAF, Matroska and ADPCM/A-law/µ-law variants through symphonia
  (`crates/audio-io/src/lib.rs` module doc and `detect_format`).
- **Write:** WAV/BWF (RF64 above 4 GiB), AIFF / AIFF-C `fl32`, FLAC — `ENCODE_EXTENSIONS =
  "wav, aif, aiff, flac"` (`crates/audio-io/src/lib.rs`), with TPDF dither (`encode`,
  `EncodeOptions`).
- Waveform overviews (`crates/audio-io/src/peaks.rs`) and `.scgrp` clip-group files with their
  audio (`crates/engine/src/clip_group_file.rs`).

### Session format
- Native session: **`.scraft`** — pretty-printed serde JSON with `format_version` (currently 1;
  newer files are refused, `crates/model/src/session.rs` `FORMAT_VERSION`, `to_json`, `from_json`),
  plus a sibling `Audio Files/` folder holding 32-bit float WAV of any in-memory audio on save,
  and `Backups/` receiving timestamped copies before an overwrite
  (`crates/engine/src/io.rs` `save_session`, `write_session`, `back_up`).
- Stored media paths are only followed when local or on the session's own network share
  (`io::stored_path` → `craft_docpath`; shared library `storytold/craft-libs`,
  `craft-libs/crates/docpath`).
- `.scraftz` bundle (zip: the `.scraft` plus its `Audio Files/`) is the **browser** session
  format (`io.rs` `BUNDLE_EXTENSION`, `session_bundle`, `open_session_bytes`;
  `apps/soundcraft-web/src/main.rs`). Desktop saves folders with `.scraft`; the desktop's open
  dialog and drop handler route `.scraft`/audio/MIDI by extension and do not open `.scraftz`
  (`apps/soundcraft/src/main.rs` `open_path`).

### Export and bounce
- `file.bounce_mix`: WAV/AIFF/FLAC at 16/24/32-bit float, dither, normalisation, optional
  `source` = a bus, `fold_down: "stereo"` for surround, and a report of `peak_db`, `lufs` and
  `true_peak_db` (`crates/engine/src/cmd/file.rs` `bounce`; `crates/dsp/src/meter.rs`).
- `file.bounce_stems` (one file per track), `file.export_clips` (clips as files),
  `file.export_midi`, `file.export_session_text`, `file.export_selected_tracks_as_session`,
  MusicXML/SVG score, `.scgrp` clip groups (`crates/engine/src/cmd/file.rs`).

### Video and surround
- Video track with thumbnails and a Video window; pure-Rust decoding of H.264 (Baseline/Main/High
  8-bit 4:2:0), Apple ProRes (422 Proxy/LT/Standard/HQ, 4444/XQ) and Motion JPEG; unsupported
  codecs open but return "unsupported" for frames (`crates/video/src/lib.rs`).
- Surround/immersive mixing: main/bus formats stereo, LCR, Quad, 5.0/5.1/6.1/7.0/7.1/7.1.2/
  5.1.4/7.1.4/9.1.6 and Ambisonics order 1–7, surround panners with divergence/height,
  object/bed routing, Renderer window (`crates/engine/src/cmd/surround.rs`,
  `crates/model/src/mixer.rs` `ChannelFormat::Ambisonics`, `crates/ui-egui/src/extra_windows.rs`).

### Scripting and agent surfaces (a first-class feature here)
- `soundcraft-cli` subcommands `info`, `convert`, `run`, `script`, `commands`, `describe`, `app`,
  `mcp`, `parity`, `plugins` (`apps/soundcraft-cli/src/main.rs`); `script` also takes
  `--keep-going` (in code, missing from the usage block).
- Desktop control channel: `soundcraft --control <port>` (or `SOUNDCRAFT_CONTROL_PORT`), newline
  JSON over TCP on 127.0.0.1, printing `SOUNDCRAFT_CONTROL_PORT=<port>` on start
  (`apps/soundcraft/src/control_server.rs`). Methods: `engine.execute` (alias `command`),
  `engine.commands`, `engine.parity`, `session.inspect`, `ui.inspect/set/menu.list/menu.invoke/
  click/drag/scroll/zoom/move/key/text/screenshot/dock/dock.reset/theme`, `app.quit`
  (`docs/control-protocol.md`).
- MCP server over stdio with tools `list_commands`, `execute`, `batch` (up to 1000 calls,
  `keep_going`; larger batches rejected before execution), `inspect_session`, `new_session`,
  `open_session`, `save_session`, `import_audio`, `bounce_mix`, `parity`, and (with `--connect`)
  `screenshot`, `ui_inspect`, `ui_set`, `menu_invoke`, `click`, `drag`, `key`; resources
  `soundcraft://session`, `soundcraft://commands` (`crates/automation/src/mcp.rs`,
  `docs/mcp.md`).
- Confinement flags `--automation-read-root` / `--automation-write-root` restrict every path a
  command reads or writes (MCP only; the desktop control channel is not confined)
  (`apps/soundcraft-cli/src/automation_args.rs`, `crates/engine/src/file_access.rs`,
  `docs/mcp.md`).
- Offscreen UI rendering for screenshots without a window:
  `cargo run -p soundcraft-ui-egui --example ui_shot -- out.png script.jsonl`
  (`crates/ui-egui/examples/ui_shot.rs`).

### Platforms
- Native builds for macOS (universal, signed+notarized, hardened runtime), Windows x64/x86/arm64
  (DirectX 12 by default; `WGPU_BACKEND` to troubleshoot), Linux (AppImage, deb, rpm, Flatpak,
  tar.gz, riscv64 tarball) and FreeBSD; plus a WebAssembly build (`README.md` "Downloads"). The
  web build has no TCP control channel and no filesystem; it saves `.scraftz` downloads and takes
  `?webgl`/`?empty` URL flags (`apps/soundcraft-web/src/main.rs`).

## Known limitations and not-implemented

Do not assign these; they are absent at v0.11.0 (mostly confirmed by `docs/gaps.md` and by search
in code):

- **No MIDI device I/O at all** — no CoreMIDI/ALSA/WinMM layer, so no recording from a keyboard,
  no live playing of instruments from hardware, no MIDI out, no MIDI clock/MTC
  (`docs/gaps.md` G-02; no `midir`-style dependency in `Cargo.toml`).
- **No Pro Tools interchange**: no `.ptx`, no AAF, no OMF import or export (G-03). The closest is
  `file.import_session_data` between SoundCraft sessions.
- **Audio interface depth**: per-channel I/O routing (I/O Setup), a single duplex stream on one
  clock, latency reporting and record-offset compensation are missing; the mix runs in fixed
  512-sample blocks; `setup.playback_engine`'s stored device/buffer are not used by playback
  (`docs/gaps.md` G-01, `docs/architecture.md` "Audio"). Input-device choice is coded but not yet
  verified on macOS (`docs/hardware-parity.md`).
- **All audio is decoded into RAM** (no disk streaming): every source is decoded whole into the
  `SourcePool` on import/open/record-stop, which bounds very long sessions
  (`crates/engine/src/io.rs` `decode_source`/`add_source`; `docs/gaps.md` G-06). Note: the gaps
  and hardware-parity docs still say "recording into RAM" — stale: takes stream to disk
  (`crates/playback/src/record.rs`) and are decoded into RAM when the take ends
  (`io::add_recording`).
- **Not every plug-in format is fully usable**: AAX can never be hosted (Avid SDK/PACE, owner
  decision); the signed macOS build lacks the library-validation entitlement, so hardened runtime
  refuses third-party VST3 bundles (`packaging/macos/entitlements.plist` has only audio-input;
  `docs/plugin-parity.md`); AU editor windows are not hosted, embedded CLAP GUIs exist only on
  Windows, VST3 editors only on macOS/Windows (`docs/plugin-parity.md` hosting table); no
  external sidechain/key input (a compressor's "sidechain" is an internal detector high-pass
  only, `crates/dsp/src/plugins/dynamics.rs`); plug-ins run in-process, so a crashing plug-in can
  take the session down.
- **No compressed export** (MP3/AAC/M4A/Ogg), though those decode for import (`docs/gaps.md` G-21).
- **English only** — no string catalog, no CJK/RTL handling (`docs/gaps.md` G-09).
- **No control surfaces** (HUI/MCU/EUCON) and **no external sync** (MTC/LTC, video reference);
  `setup.midi_beat_clock` and friends store flags only (G-10, G-11).
- **No immersive delivery**: no ADM BWF, Atmos renderer integration or binaural; surround mixing
  itself exists (G-12).
- **Video**: no HEVC/AV1/DNxHD/DNxHR decode, no video export/bounce-with-video, no external
  timecode (G-17).
- **Session management**: `session.save_template` and file-based `track.save_preset` exist, but
  there is no template browser, no workspace/sound browser and no batch rename (G-16 — that doc
  still says track presets don't exist at all; it lags `track.save_preset`).
- **No speech-to-text** (settings command only), no fidelity harness against the incumbent, no
  translations (G-07, G-18).
- **`.scraftz` is a browser format**: the CLI and `session.open` expect `.scraft` folders; the
  bundle reader `open_session_bytes` is reached from the web runner, not the desktop's
  open/drop paths (`crates/engine/src/io.rs`; `apps/soundcraft/src/main.rs` `open_path`).
- Not implemented menu areas visible in the parity report include most of `Window`
  (engine-side) and catalog `AudioSuite` leaves counted as engine commands (the UI layer aliases
  them onto the single `audiosuite.process` command, `crates/ui-egui/src/menus.rs` `AUDIOSUITE`),
  plus Avid cloud/collaboration items (`docs/parity-checklist.md`).
- **Docs lag the code** in places: `docs/plugin-parity.md` says "26 processors + 2 instruments"
  while the registry has 27; `docs/gaps.md` G-06/`docs/hardware-parity.md` still say takes are
  held in RAM. Trust the code paths cited here, then `soundcraft-cli describe`.

## How to operate

### Launch on macOS
- App binary: `/Applications/SoundCraft.app/Contents/MacOS/SoundCraft`; `open -a "SoundCraft"`,
  or pass arguments with `open -a "SoundCraft" --args --demo`.
- Flags the app itself parses (`apps/soundcraft/src/main.rs`): `--demo` / `--sample` (alias),
  `--no-audio` (no output player — use for UI test runs), `--control <port>` (0 = pick a free
  port and print it), `--version`/`-V`, and positional files: a `.scraft` opens as a session,
  `.mid`/`.midi`/`.smf` imports as MIDI, anything else imports as audio.
- Env: `SOUNDCRAFT_CONTROL_PORT` (control port), `SOUNDCRAFT_CONFIG_DIR` (nonempty value = the
  complete settings dir — `ui.json`, `Autosave/`, `Presets/`, `logs/`; empty value disables
  settings entirely), `SOUNDCRAFT_NO_PREFS` (no prefs, no log file — recommended for agent test
  runs), `RUST_LOG` (log levels). macOS settings live under
  `~/Library/Application Support/SoundCraft/` (`apps/soundcraft/src/config.rs`; `README.md`
  "Logs"). The log file `logs/soundcraft.log` rotates to `soundcraft.1.log` each launch (16 MiB
  cap) and captures engine panics, failed devices and plug-in state errors — attach it to bug
  reports.
- `soundcraft-cli` is **not** inside the app bundle: it ships separately
  (`soundcraft-cli-<ver>-macos-universal.zip`), or build with
  `cargo run --release -p soundcraft-cli -- …`.

### Document and window model
One session per running app; `session.new`/`session.open` replace it (title shows the session
name and a dirty `*`). Edit and Mix are separate views with independent panel layouts; Mix can be
shown in a separate native window; specialist windows (Transport, Big Counter, MIDI Editor, Score,
Renderer, Video…) are separate hosts. There are no tabs for multiple sessions
(`crates/ui-egui/src/menus.rs`, `docs/control-protocol.md` "Panel docking").

### Core workflow and exact flows
- Edit: select tracks/range or clips, then `edit.*` commands; positions accept samples, seconds
  (`{"seconds": 2.5}`) or time strings (`"bars_beats:5|1|000"`, `"min_secs:0:12.500"`,
  `"timecode:00:00:10:00"`, `"samples:48000"`); tracks by id or name, clips by id
  (`docs/control-protocol.md` "Positions and references").
- Open/save: `session.open {path}` → `.scraft`; `session.save`/`session.save_as {path, replace?}`
  (refuses to overwrite another file unless `replace: true`); `session.close`, `session.save_copy`,
  `session.save_template`, `session.revert`; `session.new {name?, sample_rate?, bit_depth?,
  template?: blank|demo}` (`crates/engine/src/cmd/file.rs`). Opening reports missing media as
  warnings instead of failing.
- Import: `file.import_audio {path | paths: [..], track?, at?, new_tracks?}`,
  `file.import_midi {path, at?, tempo_map?}`, `file.import_video {path, at?}`,
  `file.import_clip_groups {path, track?, at?}`, `file.import_session_data {path, tracks?}`.
- Export: `file.bounce_mix {path, format?: wav|aiff|flac, bit_depth?: 16|24|32f, start?, end?,
  source?, normalize?, dither?, fold_down?}`, `file.bounce_stems {dir, …}`,
  `file.export_clips {dir, clips?, format?: wav}`, `file.export_midi {path, tracks?}`,
  `file.export_session_text {path?}`, `file.export_sibelius {path, tracks?}` (MusicXML),
  `file.print_score {path?, tracks?}` (SVG).
- Headless one-liner:
  `soundcraft-cli run --demo --cmd 'mix.volume={"track":"Kick","db":-6}' --bounce out.wav
  --save out.scraft --inspect` (`--start`/`--end` bound the bounce).
- Drive a running app:
  `soundcraft --demo --control 7801 & soundcraft-cli app --port 7801 mix.solo '{"track":"Bass"}'`.
- Discover commands: `soundcraft-cli commands [FILTER]`, `soundcraft-cli describe ID`,
  `engine.commands` over the control channel, or the MCP `list_commands` tool. Keyboard
  shortcuts: the in-app **Setup › Keyboard Shortcuts** window (`window.shortcuts`); verified
  examples from `crates/ui-egui/src/shortcuts.rs` — Space play/stop, Shift+Space half-speed,
  Cmd+Space or F12 record, F1–F4 edit modes (hold F4 with F1–F3 = Snap; Alt+1–4 also work),
  F5–F10 tools, Enter new memory location, Cmd+= Mix/Edit, Cmd+Ctrl+S search, Tab/Alt+Tab
  clip/transient navigation, Cmd+Shift+N new tracks, Cmd+S/O/N, Cmd+E separate, Cmd+D duplicate,
  Cmd+Z undo, Cmd+Shift+K export clips, Cmd+Alt+B bounce mix; plus the Commands Focus single-key
  set above.
- Inspect work: `session.inspect {detail}` over the control channel, MCP `inspect_session`, or
  `soundcraft-cli run --demo --inspect`. `session.audio_health` checks loaded media, sample-rate
  mismatches and clip source bounds across all playlists (`crates/engine/src/cmd/health.rs`).

## Working with an AI agent

Legitimate, evidence-checkable things an agent can do around SoundCraft:

- **Prepare and convert inputs.** Use `soundcraft-cli convert IN OUT [--bit-depth 16|24|32f]
  [--rate HZ] [--normalize]` to land assets in WAV/AIFF/FLAC before import
  (`apps/soundcraft-cli/src/main.rs` `convert`). Probe any file first with
  `soundcraft-cli info FILE` (JSON probe for audio, session summary for `.scraft`).
- **Drive it headlessly** with `soundcraft-cli run`/`script` or the MCP server; check work with
  `session.inspect` rather than trusting a command's exit status. Every command is undoable except
  queries and view settings (`docs/mcp.md` "Conventions"). To list third-party plug-ins without
  the GUI: `engine.clap_plugins` / `engine.vst3_plugins` (add `{"rescan": true}` after installs).
- **Read and repair `.scraft` files.** They are JSON (`format_version` 1): you may parse, diff and
  patch them, but bump nothing and keep unknown fields; a file with a version newer than the app
  supports is refused (`crates/model/src/session.rs`). Prefer the app's own commands
  (`session.open` → `session.save`) over hand-editing when the app is available, and never edit a
  session while the app has it open.
- **Verify exports.** `file.bounce_mix` returns `path`, `bytes`, `seconds`, `peak_db`, `lufs`,
  `true_peak_db` (`crates/engine/src/cmd/file.rs` `bounce`). Check that the output file exists and
  has plausible duration/level; a silent export is a real failure mode, so read the numbers back.
- **Automate UI acceptance with the control channel** (`ui.screenshot`, `ui.click`, `ui.drag`,
  `ui.scroll`, `ui.zoom`, `ui.key`, `ui.text`, `ui.menu.invoke`, `ui.menu.list`, `ui.inspect`,
  `ui.dock`), but run with `--no-audio` and never arm/enable recording in a smoke test — `--no-audio`
  disables output only, not recording input (`docs/control-protocol.md` "Isolated automation
  profiles").
- **What not to attempt:** driving the GUI blind (inspect first); assuming AAF/OMF/`.ptx`,
  MIDI-hardware or MP3/AAC export exist; expecting a `.scraftz` bundle to open on the desktop;
  expecting more than the default input device without user setup; reading or copying Pro Tools
  resources — SoundCraft is clean-room and its menu/format names come only from black-box
  observation (`AGENTS.md`).

## Verification protocol

SoundCraft is pre-alpha and its docs lag the code in places (see the limitations above and
`evidence.md`). For any real task:

1. **Round-trip on a throwaway session first**: `session.new` → make one edit → `session.save` to
   a scratch path → `session.open` the file back → `file.bounce_mix` → confirm the returned
   levels are non-silent and the file exists. Do this before touching a user's session.
2. **Never trust a silent export**: a bounce that writes a file can still be empty or misaligned;
   compare `peak_db`/`lufs` with expectations, and re-open the bounce with `soundcraft-cli info`.
3. **Back up and version project files per session** — copy the whole session folder
   (`.scraft` + `Audio Files/`), not just the `.scraft`; and remember saves write `Backups/` only
   on overwrite of an existing file.
4. **One session at a time**: `session.open`/`session.new` replace the open document; run agents
   with an isolated profile (`SOUNDCRAFT_CONFIG_DIR` to a fresh dir) so autosave/recovery doesn't
   mix with the user's work.
5. **Update apps only between projects**: the Launcher auto-updates SoundCraft, and this skill is
   pinned to v0.11.0 — re-check the version (`--version`, or the About window) before relying on a
   detail, especially formats and command parameters.
6. **Prefer inspecting over guessing**: `soundcraft-cli commands <filter>` and `describe ID` give
   the authoritative parameter schema of the build you are talking to.

## Sources & evidence

- Repo: https://github.com/storytold/soundcraft — inspected at tag **v0.11.0**, commit
  `b74fca0fb0f8b4a8474c447c1b6043a5028a5de2`, on 2026-10-22. Installed app on the authoring Mac
  reports `SoundCraft 0.11.0` (`--version`); `CFBundleIdentifier` `ai.storyteller.soundcraft`.
  Verify against your installed version — installed users may lag or lead this pin.
- Read: `README.md`, `ROADMAP.md`, `AGENTS.md`, `Cargo.toml`,
  `apps/soundcraft/src/main.rs`, `apps/soundcraft/src/config.rs`,
  `apps/soundcraft/src/control_server.rs`, `apps/soundcraft-cli/src/main.rs`,
  `apps/soundcraft-cli/src/automation_args.rs`, `apps/soundcraft-web/src/main.rs`,
  `crates/engine/src/io.rs`, `crates/engine/src/autosave.rs`,
  `crates/engine/src/clip_group_file.rs`, `crates/engine/src/score.rs`,
  `crates/engine/src/cmd/*.rs` (file, track, track_more, mix, edit, edit_more, event, event_more,
  options, transport, health, instrument, sampler, surround, audio_midi, midi, query, tab,
  zoom_toggle, clap, vst3, plugin_state, setup_more), `crates/model/src/session.rs`,
  `crates/model/src/mixer.rs`, `crates/model/src/clip.rs`, `crates/model/src/automation.rs`,
  `crates/audio-io/src/lib.rs`, `crates/dsp/src/plugins/mod.rs`,
  `crates/playback/src/record.rs`, `crates/playback/src/devices.rs`, `crates/video/src/lib.rs`,
  `crates/midi/src/`, `crates/automation/src/mcp.rs`, `crates/clap-host/src/lib.rs`,
  `crates/vst3-host/src/lib.rs`, `crates/au-host/src/lib.rs`, `crates/ui-egui/src/menus.rs`,
  `crates/ui-egui/src/shortcuts.rs`, `crates/ui-egui/src/control.rs`,
  `crates/ui-egui/examples/`, `packaging/macos/entitlements.plist`, and the docs
  `docs/control-protocol.md`, `docs/mcp.md`, `docs/architecture.md`, `docs/gaps.md`,
  `docs/roadmap.md`, `docs/target-app-parity.md`, `docs/file-format-parity.md`,
  `docs/plugin-parity.md`, `docs/hardware-parity.md`, `docs/parity-checklist.md`.
- Shared library consulted: `storytold/craft-libs` (`craft-docpath` for stored-path rules,
  `craft-ui` for shared controls), pinned by rev in the workspace `Cargo.toml`.
- Counts recomputed from source at the pin: 395 command specs (`cmd!` macro + 1 direct struct),
  27 plug-ins in `REGISTRY`, 512-leaf menu catalog, `ENCODE_EXTENSIONS = "wav, aif, aiff, flac"`,
  `FORMAT_VERSION = 1`, MCP `MAX_BATCH_CALLS = 1000`.
- Evidence table: `evidence.md` next to this file.

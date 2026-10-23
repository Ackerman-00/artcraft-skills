# FilmCraft — evidence table (for orchestrator review)

App: **FilmCraft**, repo `storytold/filmcraft`, inspected at **tag `v0.11.0` / commit
`74242b51d675514da12d9bbf6b331ef2e6399211`** (`git rev-parse HEAD`, detached worktree, release commit
2026-10-22), on **2026-10-23**. The installed `/Applications/FilmCraft.app` reports `0.11.0` and its
`Info.plist` records `FilmCraftBuildCommit = 74242b51d675514da12d9bbf6b331ef2e6399211`, i.e. the installed
bundle is this tag. Paths below are repo-relative. Nothing was built or launched: all claims are static
code/doc evidence (the bundle's `Info.plist` and `--version` were the only executions).

| # | Claim in SKILL.md | Evidence | Tier |
|---|---|---|---|
| 1 | Installed bundle == tag v0.11.0 (version 0.11.0, same build commit) | `Info.plist` keys `CFBundleShortVersionString`, `FilmCraftBuildCommit`; `filmcraft --version` prints `filmcraft 0.11.0`; `Cargo.toml:6` | implemented (audit basis) |
| 2 | Open-source NLE mirroring Premiere Pro, pure Rust, own codecs, no FFmpeg linked | `README.md` headline/“Formats and codecs”; `AGENTS.md` §2; `Cargo.toml` (no ffmpeg dep; `crates/testkit` mentions ffmpeg only as an oracle) | implemented |
| 3 | Parity target Premiere 2026 26.5.2; alpha; ~86 % breadth / ~56 % ready | `docs/target-app-parity.md:1-22`; `README.md:290-304` | authors' measurement (not re-measured here) |
| 4 | 50 crates + 3 apps, workspace version 0.11.0 | `ls crates` → 50; `ls apps` → filmcraft, filmcraft-cli, filmcraft-web; `Cargo.toml:6`; **drift**: `docs/target-app-parity.md:22` says “45 crates” (measured 2026-10-10) | implemented (drift flagged) |
| 5 | Headless engine; UI, CLI, control channel and MCP dispatch the same command ids | `docs/architecture.md` §1; `crates/engine/src/commands.rs:49-54`; `crates/ui-egui/src/menus.rs`; `apps/filmcraft-cli/src/main.rs`; `crates/automation/src/server.rs:263-306` | implemented |
| 6 | Command-id counts: **626 unique engine ids** by static extraction (576 from `cmd!`/`query!`/`spec(`/`query(`, incl. ids inside `align_cmd!`/`arrange_cmd!`/`label_cmd!`, + 50 from `camera_keys!`/`tt!`/`sc!`) + 212 UI-only `uic!` ids; README claims “>650 engine commands” — **not confirmed statically** | Python extraction over `crates/engine/src/**/*.rs` and `crates/ui-egui/src`; macro call sites counted (`align_cmd!` 18, `arrange_cmd!` 4, `label_cmd!` 16, `camera_keys!` 1–9 → 18, `tt!` 16, `sc!` 16; 38 of those already matched by the `cmd!(` suffix); `README.md:233`; comparing every quoted dotted id between v0.10.0 and v0.11.0 finds no command id added/removed (only `protected.wav`) | static count — runtime list not available (no build) |
| 7 | CLI: 11 subcommands (`exec`, `run`, `commands`, `describe`, `inspect`, `import`, `export`, `render`, `probe`, `bench-decode`, `mcp`), documented options, exit 0/1/2 | `apps/filmcraft-cli/src/main.rs:63-145` (`HELP`), dispatch `:289-511`; unchanged count vs v0.10.0 | implemented |
| 8 | **New in 0.11.0:** local `exec`/`run` force `wait: true` on `file.exportMedia` unless params say exactly `"wait": false`; a one-shot process can otherwise lose a background render | `apps/filmcraft-cli/src/main.rs:171-190`; `crates/automation/src/long_job.rs:18` (`LONG_COMMANDS` = `["file.exportMedia"]`); release notes PR #2388 | implemented |
| 9 | MCP: 17 tools + 2 resources, headless/bridge split, strict arguments, progress/cancel | `crates/automation/src/server.rs:317-560` (17 `#[tool]` fns), `:645-666` (resources), `docs/agents.md:57-100`; count unchanged vs v0.10.0 | implemented |
| 10 | Control channel: JSON-lines on loopback, 16 connections, 4 MiB line cap, no auth, non-JSON closes; `app.quit` method skips prompt while the command asks | `docs/control-protocol.md:9-43`; `apps/filmcraft/src/control_server.rs`; `crates/ui-egui/src/control.rs:463-468`; `crates/ui-egui/src/panels/clip_dialogs.rs:96-130` | implemented |
| 11 | Editing: three-point insert/overwrite, lift/extract, ripple/roll/slip/slide/razor, Trim Monitor + dynamic trim, Add Edit, nest, subclips, sync/merge, multicam, markers CSV caps | `crates/engine/src/commands.rs:2056,2080,2086,2576-2577,2845`; `crates/engine/src/{trim,multicam,sync}.rs`; `crates/engine/src/marker_export.rs:11-12`; `crates/ui-egui/src/panels/trim_monitor.rs` | implemented |
| 12 | Exact integer time 254 016 000 000 ticks/s; copy-on-write undo with a **200-step** limit (not unlimited) | `crates/time/src/lib.rs:20`; `crates/engine/src/lib.rs:228-236`; `commands.rs:1144,1158` (`history.limit = 200`) | implemented (correction vs v0.10 skill) |
| 13 | Effect catalogue: 93 video effects / 16 folders; 53 audio effects; 84 transitions + 21 Legacy; 27 blend modes (README says 26/“around 30”) | test assertions `crates/project/src/effect/vfx.rs:1251-1263`; `effect/audio.rs:578`; `vtransition.rs:413-417`; `effect.rs:144` (27 counted); `README.md:145-146` | implemented (README drift flagged) |
| 14 | Import lists and openers; AVI implemented though `docs/file-format-parity.md:43` says “no demuxer” | `crates/media/src/lib.rs:175-178`; `crates/codecs/src/lib.rs:135-138,157-165`; `crates/avi/README.md` and `avi::opener`; stale row at `docs/file-format-parity.md:43` | implemented (contradiction flagged) |
| 15 | Codecs: H.264 8-bit software / 10-bit+422 hardware; HEVC hardware-only (macOS VT, Windows NVENC, not Linux); **AV1 decoder only, no encoder/probe anywhere**; E-AC-3 partial 5.1 core | `docs/codec-parity.md:18-24,45`; `crates/export/src/lib.rs:253-255`; `crates/platform/src/lib.rs:70-100`; `crates/platform/src/nvenc/export.rs:212-216`; `crates/ac3/README.md` | implemented (AV1 correction) |
| 16 | `.fcproj` = UTF-8 JSON, schema **15** (14 migrations), newer refused, first save over upgraded file keeps `(schema vN backup)`; atomic writes; auto-save ring + recovery journal; **new auto-save names carry `-<unix seconds>`** | `crates/format/src/lib.rs:62-66`; `crates/format/src/atomic.rs:1-75`; `crates/format/src/autosave.rs:61,72-105`; `docs/project-files.md:70-99,113-180`; stale example at `docs/project-files.md:11` (says 13) | implemented (doc drift flagged) |
| 17 | Export: 21 formats, 39 built-in presets (default Match Source – Adaptive High Bitrate), queue/jobs/progress/ETA/cancel, hardware encoding, offline media reported with exit 1 unless `--allow-offline` | `crates/export/src/lib.rs:64-134,253-255`; `crates/export/src/presets.rs:35,95-190` (39 counted); `crates/engine/src/export_tools.rs:546-556,1112-1123,1156-1172`; `apps/filmcraft-cli/src/main.rs:529-556`; unchanged counts vs v0.10.0 | implemented |
| 18 | Interchange: EDL, FCP7 XML, FCPXML 1.9–1.11, OTIO, AAF, OMF import+export; ALE export only; content sniffing; one undo step; **new: embedded AAF/OMF audio never overwrites (numbered names)** | `crates/interchange/src/lib.rs:1-16,110-138`; `crates/interchange/src/ale.rs:78`; `crates/engine/src/interchange.rs:30-90`; `docs/gaps.md` G15 (never validated in Avid/Pro Tools) | implemented; AAF/OMF unvalidated externally |
| 19 | Captions: 7 file formats + Subtitle/CEA-608/CEA-708/Teletext tracks; burn-in and SRT/VTT sidecar; no embedded caption codecs | `crates/captions/src/lib.rs:49`; `crates/project/src/caption.rs:18-31`; `crates/engine/src/export_tools.rs:277,315`; `docs/file-format-parity.md` | implemented |
| 20 | Release gates and limits: Whisper + Kokoro off in official builds; one project at a time; no `.prproj`; no plug-in hosting; one export destination; no work area bar (so `range: workArea` fails); ~212 UI ids; 28 panels / 7 workspaces / 4 shortcut presets; 11 i18n catalogues | `crates/engine/src/transcript.rs:59-61`; `packaging/macos/package.sh:61`; `apps/filmcraft/Cargo.toml:12-16`; `crates/engine/src/project_tools.rs:90-91`; `grep -ri prproj` → none; `crates/engine/src/settings.rs:1316-1321`; `crates/ui-egui/src/panels/export_mode.rs:204`; `crates/engine/src/export_tools.rs:355` + `docs/keyboard.md:64`; `crates/ui-egui/src/dock.rs:14-46`; `menus.rs:111-117`; `shortcuts.rs:63`; `crates/ui-egui/src/i18n/*.tsv` (11) | implemented as limits/gates |

## What changed in v0.11.0 (verified from the diff + release notes)

`git diff v0.10.0..v0.11.0` is **53 files, +2468/−136**. The user-visible/automation changes:

1. **CLI waits for exports** (#2342): local `exec`/`run` set `wait: true` on `file.exportMedia` unless the
   params say `false` (`apps/filmcraft-cli/src/main.rs:171-190`).
2. **Cmd+Q asks to save** (#1943): the native Quit item runs the `app.quit` command instead of
   `terminate:` (`apps/filmcraft/src/native_menu.rs:26-30`); control-only mode still honours Quit
   (`crates/ui-egui/src/lib.rs:1849`).
3. **Audio output recovers** (#2503): a failed/lost device is reopened every 2 s while playback continues
   on the wall clock (`AUDIO_RETRY_S`, `crates/ui-egui/src/lib.rs:266,1146-1155`).
4. **Auto-save ordering survives DST** (#1955): filenames gain `-<unix seconds>`; rotation sorts by real
   time; old names still list (`crates/format/src/autosave.rs:61,72-105`, `docs/project-files.md:128-131`).
5. **AAF/OMF extraction never clobbers**: `atomic_write_new` + numbered names (`crates/format/src/atomic.rs:49-75`,
   `crates/engine/src/interchange.rs:30-52`, `crates/engine/src/lib.rs:105-121,170-186`).
6. **Damaged MP4 audio**: failed AAC packets no longer allocate their declared duration; silence over the
   packet span (`crates/codecs/src/mp4.rs:103,495-512`).
7. **Decoder hardening + fuzz tests** for H.264, HEVC, AV1, VP8, VP9, ProRes, DNx, APV, MPEG-2 (new
   `tests/fuzz_hostile.rs`, AV1 level 6.x limits, MPEG-2 allocation caps).
8. **FreeBSD aarch64 dropped** from the release (release notes; x86_64 still ships).

**No counts changed** vs the v0.10.0 skill: 11 CLI subcommands, 17 MCP tools, 21 export formats, 39 presets,
7 caption formats, 7 workspaces, 28 panels, 4 shortcut presets. Diffing extracted engine command ids between
the two tags shows **no ids added or removed**.

## Corrections against the v0.10.0 skill

1. **Undo is not unlimited**: `s.history.limit = 200` (`crates/engine/src/commands.rs:1144`). Copy-on-write
   snapshots, continuous gestures merged, but the stack is capped at 200 steps.
2. **AV1 export is effectively absent**, not merely hardware-gated: no encoder or format probe is registered
   on any platform (`crates/platform/src/lib.rs:70-100`), so `Format::available(Av1)` is always false.
3. **HEVC export is not available on Linux**: the NVENC HEVC factory refuses non-Windows
   (`crates/platform/src/nvenc/export.rs:212-216`), and no HEVC format probe is registered there.
4. **Auto-save names changed** in 0.11.0 (unix-seconds suffix) — carried forward in `references/formats.md`.
5. **`docs/gaps.md` G8 / `docs/ui-parity.md` are stale**: on-monitor transform handles
   (`crates/ui-egui/src/panels/transform_handles.rs`), the Effect Controls divider/row lines
   (`effect_controls.rs:319-327`), Project-panel marquee (`project_views.rs:581-652`) and continuous
   timeline thumbnails (`timeline.rs:3310`) all exist at this tag. The skill no longer repeats those as gaps
   and warns against trusting that list.
6. **Track names are settable** with `timeline.setTrack {name}` (`commands.rs:2859-2863`) even though G8
   lists track renaming as missing.
7. **FreeBSD**: v0.11.0 ships x86_64 only (aarch64 dropped), so the skill no longer implies both.

## Doc drift carried forward deliberately (code wins)

- AVI: `docs/file-format-parity.md:43` says “no demuxer (#598)”; the AVI demuxer is implemented and wired.
- `.fcproj` example: `docs/project-files.md:11` shows `schema_version: 13`; the code writes 15.
- README “26 blend modes” (code: 27) and “around 30 transitions” (tests: 84 + 21 Legacy).
- README “Not yet: … E-AC-3” (codec-parity.md:45 documents a 75 % decoder that plays the 5.1 core).
- `docs/target-app-parity.md:22` “45 crates” (workspace has 50 + 3 apps).
- `docs/gaps.md` G8 / `docs/ui-parity.md` UI rows (see corrections above).
- `docs/gaps.md` G13 still lists PXR24 EXR as missing; `docs/file-format-parity.md:58` and
  `crates/media` read PXR24 (revision history records the 2026-10-12 addition).

## Verification method and open items

- Read-only: the repo was not modified, built or committed; the GUI app was not launched. App-side evidence
  came from the bundle's `Info.plist` and `--version`; everything else is static source/doc reading.
- Not verified at runtime (no built binary here): the exact engine command total, per-machine
  `export.formats` availability, export timings, and MCP/control behaviour on a live app.
- The repo's own readiness estimate (~56 %) is an author measurement, not re-measured in this audit.

## How to re-verify quickly

```sh
git checkout v0.11.0 && git rev-parse HEAD                 # 74242b51d675514da12d9bbf6b331ef2e6399211
sed -n '175,178p' crates/media/src/lib.rs                  # import extension lists
sed -n '62,66p' crates/format/src/lib.rs                   # SCHEMA_VERSION = 15
sed -n '64,134p' crates/export/src/lib.rs                  # 21 export formats
grep -c '^        p(' crates/export/src/presets.rs          # 39 presets (inside builtin_presets)
grep -n 'n, 93' crates/project/src/effect/vfx.rs
grep -n 'CATALOGUE.len(), 16' crates/project/src/effect/vfx.rs
grep -n 'counts\[..10\]' crates/project/src/vtransition.rs
sed -n '171,190p' apps/filmcraft-cli/src/main.rs           # 0.11 export wait default
sed -n '26,30p' apps/filmcraft/src/native_menu.rs          # Cmd-Q -> app.quit
sed -n '61,75p' crates/format/src/autosave.rs              # new auto-save naming
filmcraft --version                                        # installed build
```

## How to re-verify the counts (needs a build)

```sh
cargo run --release -p filmcraft-cli -- commands | wc -l    # engine command list (authoritative)
cargo run --release -p filmcraft-cli -- export --list-presets | jq length
```

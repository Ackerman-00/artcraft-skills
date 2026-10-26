# FilmCraft — evidence table (for orchestrator review)

App: **FilmCraft**, repo `storytold/filmcraft`, audited at **tag `v0.13.0` / commit
`30536bc5d0ddf690f2181b7b97182db8658a6038`** (`git rev-parse HEAD` in a disposable shallow clone, release
commit 2026-10-25), on **2026-10-26**. The installed `/Applications/FilmCraft.app` reports `0.13.0`, its
Info.plist records `FilmCraftBuildCommit = 30536bc5d0ddf690f2181b7b97182db8658a6038`, and
`Contents/MacOS/FilmCraft --version` prints `filmcraft 0.13.0`, so the bundle is this tag. Paths below are
repo-relative. Nothing was built or launched: all claims are static code/doc evidence (the bundle's
Info.plist and `--version` were the only executions). The GUI was never launched.

| # | Claim in SKILL.md | Evidence | Tier |
|---|---|---|---|
| 1 | Installed bundle == tag v0.13.0 (version 0.13.0, same build commit) | installed Info.plist keys `CFBundleShortVersionString`, `FilmCraftBuildCommit`; `filmcraft --version` → `filmcraft 0.13.0`; `Cargo.toml:6` (`version = "0.13.0"`) | implemented (audit basis) |
| 2 | Open-source NLE mirroring Premiere Pro, pure Rust, own codecs, no FFmpeg linked | `README.md` headline/"Formats and codecs"; `AGENTS.md` §2; `Cargo.toml` (no ffmpeg dependency; `crates/testkit` uses it only as an oracle) | implemented |
| 3 | Parity target Premiere 2026 26.5.2; alpha; ~86 % breadth / ~56 % ready | `docs/target-app-parity.md:15,173,296-302`; `README.md` "Status" | authors' measurement (not re-measured) |
| 4 | 50 crates + 3 apps, workspace version 0.13.0 | `crates/` listing (50 dirs); `apps/` (filmcraft, filmcraft-cli, filmcraft-web); `Cargo.toml:6`; **drift**: `docs/target-app-parity.md:22` still says "45 crates" | implemented (drift flagged) |
| 5 | Headless engine; UI, CLI, control channel and MCP dispatch the same command ids | `docs/architecture.md` §1; `crates/engine/src/commands.rs` (`CommandSpec`, `Session::execute`); `crates/ui-egui/src/menus.rs`; `apps/filmcraft-cli/src/main.rs`; `crates/automation/src/server.rs` | implemented |
| 6 | **662 statically registered engine command ids** (653 source literals + 9 `multicam.selectCamera1..9`), **+9 / −0 vs v0.11.0** (same script at v0.11.0: 653) | extraction script below over `crates/engine/src/**/*.rs` (test files excluded), matching `cmd!`/`query!`/`query`/`spec`/`align_cmd!`/`arrange_cmd!`/`label_cmd!`/`tt!`/`sc!` first literals plus `CommandSpec { id: "…" }` and `camera_keys!(1..9)`. Added ids: `captions.duplicate` (`crates/engine/src/captions.rs`), `history.clear`, `history.deleteRedoable`, `sequence.setWorkArea`, `sequence.setWorkAreaIn`, `sequence.setWorkAreaOut`, `sequence.workAreaBar` (`crates/engine/src/commands.rs:1671-1672,2334-2385`), `sequence.duplicateFrames`, `sequence.showDuplicateFrameMarkers` (`crates/engine/src/sequence_tools.rs:113-130`). A broader diff of *every quoted dotted string* in `crates/engine/src` (1 174 ids at v0.11.0 → 1 188 at v0.13.0) adds 14 and removes 0 (the extras beyond the 9 command ids are the test-fixture filenames `kept.mov`/`linked.mov`/`outside.mov` and the two mixer ids the engine's shortcut tables name). README's ">650 engine commands" is now consistent with 662 | static count — runtime list not available (no build); previous round's 626 used a narrower pattern (it excluded module-local `spec()`/`query()` helpers and `CommandSpec{}` literals) |
| 7 | **215 UI-only command ids** in `crates/ui-egui/src`, +3 (212 at v0.11.0) | `uic!` extraction: added `mixer.meterInputOnly`, `mixer.showHideTracks` (`crates/ui-egui/src/panels/keyboard.rs:131-132`), `view.transparencyGrid` (`crates/ui-egui/src/menus.rs:95`) | static count |
| 8 | CLI: **12 subcommand words = 11 functional subcommands + `help`** (unchanged), documented options, exit 0/1/2, offline-media exit 1 | `apps/filmcraft-cli/src/main.rs:63-145` (`HELP`), dispatch `:317-520`, `check_offline` `:577-585` | implemented |
| 9 | MCP: **17 tools + 2 resources** (unchanged); progress/cancel; strict arguments; screenshots now owner-only temp dir | `crates/automation/src/server.rs` `#[tool_router]` impl (17 handler fns), `:612-613` resource URIs, `:567-580` temp-dir screenshot; `docs/agents.md` §1 | implemented |
| 10 | **New in 0.13.0 — control channel requires `FILMCRAFT_CONTROL_TOKEN`**: 64 hex chars, per-request `token`, constant-time compare, listener closed without it; 4 MiB lines, 16 connections, 120 s socket / 60 s UI-reply timeouts | `apps/filmcraft/src/control_server.rs:22-41,101,130-141`; `crates/automation/src/bridge.rs` (sends the env token); `docs/control-protocol.md:4-24`; `docs/agents.md` §2 | implemented |
| 11 | Work area bar implemented (4 commands, UI bar + ⏎ hit-test, export `range: workArea`) — **previous gap closed** | `crates/engine/src/commands.rs:2334-2385`; `crates/engine/src/work_area_tests.rs:27-41,102`; `crates/ui-egui/src/panels/timeline.rs` (`Hit::WorkArea`, `timeline.workArea`); `crates/ui-egui/tests/it/timeline_work_area_ui.rs`; `crates/engine/src/export_tools.rs:337-365`; `docs/keyboard.md` work-area row | implemented |
| 12 | History-panel pruning (`history.deleteRedoable`, `history.clear`, panel menu, Backspace in Premiere preset, OK dialog) | `crates/engine/src/commands.rs:1671-1672`; `crates/engine/src/lib.rs:247-260`; `crates/ui-egui/src/panels/misc.rs` (`route_history`, `history_panel_menu`); `crates/engine/src/shortcut_presets.rs:267`; `crates/engine/src/history_tests.rs` | implemented |
| 13 | Duplicate-frame markers: `sequence.showDuplicateFrameMarkers`, query `sequence.duplicateFrames`, 10 colours, 1 000 000-frame budget, timeline stripes | `crates/engine/src/sequence_tools.rs:110-130,405-500`; `crates/ui-egui/src/panels/timeline.rs` (`timeline.duplicateFrames.*`) | implemented |
| 14 | Caption editing: razor, ⌥-drag duplicate, copy/cut/paste of captions, Text list follows playhead | `crates/engine/src/captions.rs:169-230`; `crates/engine/src/commands.rs:1673-1697`; `crates/ui-egui/src/panels/timeline_captions.rs:212-245`; `docs/captions.md`; tests `crates/ui-egui/tests/it/caption_razor_ui.rs`, `crates/ui-egui/tests/it/caption_copy_paste_ui.rs`, `crates/ui-egui/tests/it/caption_list_follow_ui.rs` | implemented |
| 15 | Mixer Show/Hide Tracks + Meter Input(s) Only (UI ids, Premiere keys Cmd+Alt+T / Ctrl+Shift+I); monitor Transparency Grid | `crates/ui-egui/src/panels/keyboard.rs:131-132,214-215`; `crates/ui-egui/src/panels/mixer.rs:226-240`; `crates/engine/src/shortcut_presets.rs:356-357`; `crates/ui-egui/src/menus.rs:95`, `docs/monitors.md` | implemented |
| 16 | Editing core unchanged and present: three-point insert/overwrite, lift/extract, trims, Add Edit, nest, subclips, sync/merge, multicam 1–9, exact ticks (254 016 000 000/s), 200-step undo | `crates/engine/src/{commands,trim,multicam,sync}.rs`; `crates/time/src/lib.rs:20`; `s.history.limit = 200` (`crates/engine/src/commands.rs:1187,4525`) | implemented |
| 17 | Effect catalogue unchanged: 93 video effects / 16 folders, 53 audio effects, 84 transitions + 21 Legacy, 27 blend modes; **10 camera log curves** now (8 at v0.11.0: +F-Log, F-Log2) | assertions `crates/project/src/effect/vfx.rs:1251-1263`; `crates/project/src/effect/audio.rs:578`; `crates/project/src/vtransition.rs:413-417`; `crates/project/src/effect.rs:144-172`; `LogCurve::ALL`, `crates/color/src/log.rs:52-63` | implemented |
| 18 | Import surface unchanged (extension lists, 9 container openers) **plus animated WebP** as a clip | `crates/media/src/lib.rs:175-179`; `crates/codecs/src/lib.rs:134-137,157-165`; `crates/media/src/animated.rs:1-118`; README formats table (updated to name WebP) | implemented |
| 19 | Containers/bit I/O now come from **craft-media** (craft-libs pin `f0ad6c1e…`): `crates/isobmff`, `crates/matroska`, `crates/bitstream` are re-export shims | `Cargo.toml:76`; `crates/isobmff/src/lib.rs:1-7`; `crates/matroska/src/lib.rs:1-7`; `crates/bitstream/src/lib.rs:1-5`; `crates/{isobmff,matroska,bitstream}/Cargo.toml` (`craft-media` features) | implemented as a move; deeper container behaviour not auditable here |
| 20 | `.fcproj` = UTF-8 JSON, schema **15** (14 migrations), newer refused, atomic writes, auto-save ring + recovery journal; 0.13.0 load hardening (8 MiB LUT cap, frame-size check, `next_id` repair) | `crates/format/src/lib.rs:62-66,216-280,398`; `crates/format/src/{atomic,autosave}.rs`; `crates/project/src/lib.rs:1327`; `docs/project-files.md`; stale example at `docs/project-files.md:11` (says 13) | implemented (doc drift flagged) |
| 21 | Export: **21 formats**, **39 built-in presets** (default "Match Source – Adaptive High Bitrate"), queue/jobs/ETA/cancel, HEVC hardware-only, **AV1 never available**, offline media reported with exit 1 unless `--allow-offline`, UI greys unavailable formats with a reason | `Format::ALL`, `crates/export/src/lib.rs:272-294`; `crates/export/src/presets.rs:35,95-190` (39 `p(` entries); `crates/platform/src/lib.rs:70-100`; `crates/engine/src/export_tools.rs`; `apps/filmcraft-cli/src/main.rs:577-585`; `crates/ui-egui/src/panels/export_mode.rs` | implemented |
| 22 | Interchange unchanged: EDL, FCP7 XML, FCPXML 1.9–1.11, OTIO, AAF, OMF import+export; ALE export only; markers CSV; content sniffing; one undo step; embedded audio names never clobber and keep separators | `crates/interchange/src/lib.rs:1-16,110-138`; `crates/engine/src/interchange.rs:27-90`; `crates/engine/src/marker_export.rs:11-12`; `docs/gaps.md` G15 | implemented; AAF/OMF unvalidated externally |
| 23 | Limits/gates still true: no `.prproj`, no plug-in hosting, DNG-only RAW, hardware-only 10-bit/4:2:2 decode, no embedded caption codecs, one project at a time, one export destination, Whisper/Kokoro off in releases, minimal AI, Windows/Linux less tested, incomplete web shell | `docs/gaps.md` G2/G3/G10/G11/G12/G13/G19/G20; `grep -ri prproj crates apps` → none; `crates/engine/src/project_tools.rs:90-92`; `crates/ui-egui/src/panels/export_mode.rs:204`; `crates/engine/src/transcript.rs:59-61`; `crates/tts/src/lib.rs:50`; `apps/filmcraft/Cargo.toml:16-18`; `packaging/macos/package.sh:61` | implemented as limits/gates |
| 24 | `effects.setParam` refuses values outside a parameter's hard range (new) | `crates/engine/src/commands.rs:3186-3193` | implemented |

## Count re-measurement at v0.13.0 (script and results)

Method: for each `.rs` file under `crates/engine/src` (excluding `*_tests.rs`), read the file at the tag and
collect the first string literal of every registry call; count unique ids; add the 9 ids generated by
`camera_keys!` in `crates/engine/src/multicam.rs`.

```python
import re, subprocess, collections
TAG = "v0.13.0"          # run once with "v0.11.0" for the baseline
files = [f for f in subprocess.run(["git","ls-tree","-r","--name-only",TAG,"crates/engine/src"],
         capture_output=True, text=True).stdout.splitlines()
         if f.endswith(".rs") and not f.rsplit("/",1)[-1].endswith("_tests.rs")]
pat  = re.compile(r'\b(cmd!|query!|query|spec|align_cmd!|arrange_cmd!|label_cmd!|tt!|sc!)\s*\(\s*"([A-Za-z][A-Za-z0-9_.\-]*)"')
pat2 = re.compile(r'CommandSpec\s*\{\s*id:\s*"([A-Za-z][A-Za-z0-9_.\-]*)"')
ids = collections.defaultdict(set)
for f in files:
    t = subprocess.run(["git","show",f"{TAG}:{f}"], capture_output=True, text=True).stdout
    for m in pat.finditer(t):  ids[m.group(2)].add(f)
    for m in pat2.finditer(t): ids[m.group(1)].add(f)
    for m in re.finditer(r'camera_keys!\(([^)]*)\)', t):
        for n in re.findall(r'\d+', m.group(1)): ids["multicam.selectCamera"+n].add(f)
print(len(ids))          # v0.13.0: 662   v0.11.0: 653
```

Result: **662** at v0.13.0 vs **653** at v0.11.0 (+9, −0). UI-only `uic!` ids: **215** vs **212** (+3).
Runtime enumeration (`filmcraft-cli commands`, MCP `command_list`) is authoritative and was not run here.

Fixed counts re-measured from code: 11 functional CLI subcommands (+ `help` = 12 subcommand words); 17 MCP tools + 2 resources; 23 control-channel
methods; 21 export formats (`Format::ALL`); 39 presets (`p(` calls inside `builtin_presets`); 7 caption
formats (`Format::ALL` in `crates/captions/src/lib.rs:49`); 28 panel kinds (`PanelKind::ALL`); **9 built-in
workspaces** (`WORKSPACES`, `crates/ui-egui/src/dock.rs:180`); 4 shortcut presets (`BUILTIN_PRESETS`);
12 UI languages (en + 11 `.tsv`); project schema 15; 93/16 video effects, 53 audio effects, 84+21
transitions, 27 blend modes; 10 camera log curves.

## Corrections against the v0.11.0 skill

1. **Workspaces: 9, not 7.** The previous skill counted the seven entries of the Window ▸ Workspaces *menu*
   (`crates/ui-egui/src/menus.rs:113-119`) and called them "workspaces". `WORKSPACES` has had nine since at
   least v0.11.0; Learning and Review are real built-in layouts exposed as keyboard-only commands
   (`window.workspace.learning` / `.review`, Alt+Shift+7/8, `crates/ui-egui/src/panels/keyboard.rs:69-70`).
2. **Work area bar: implemented, not missing.** The previous skill listed "no work area bar" and "`range:
   workArea` unusable" as gaps. At v0.13.0 there are four work-area commands, a draggable bar, ruler
   hit-testing and a working export range (`crates/engine/src/work_area_tests.rs`).
3. **History-panel Delete and the mixer's Show/Hide Tracks + Meter Input(s) Only are implemented now**
   (`docs/keyboard.md` removed them from its skipped-shortcut table). The previous skill's "no track
   visibility dialog, no input metering" and "history states cannot be deleted" no longer hold.
4. **Control channel is no longer unauthenticated.** The previous skill said "loopback only, no
   authentication — enable only while needed". v0.13.0 requires `FILMCRAFT_CONTROL_TOKEN` (64 hex) on the
   listener and on every request, with constant-time comparison and per-connection timeouts. This is the
   single most important operational change for agents using `--bridge`/MCP.
5. **Command count: 662 static ids at this tag (previously 626 with a narrower pattern).** The old 626
   excluded module-local `spec()`/`query()` helpers and `CommandSpec{}` literals; the new extraction also
   yields 653 at v0.11.0, so the *delta* (+9) is method-independent. The README's ">650" is now consistent
   with the static count instead of exceeding it.
6. **Caption editing grew** (razor, ⌥-drag duplicate, copy/cut/paste, playhead-following list) and animated
   **WebP** now imports as a clip — both were absent at v0.11.0.
7. **Fujifilm F-Log / F-Log2** join the log-curve set (10, was 8), so `clip.interpretFootage` accepts them.
8. **Error behaviour change to rely on:** `effects.setParam` now errors on out-of-range values instead of
   storing them (a factor where a percentage is meant is refused).

## Doc drift carried forward deliberately (code wins)

- AVI: `docs/file-format-parity.md:43` says "no demuxer (#598)"; `avi::opener` is wired in
  `crates/codecs/src/lib.rs:136` and `crates/avi/README.md` documents An AVI 1.0/OpenDML demuxer.
- `.fcproj` example: `docs/project-files.md:11` shows `schema_version: 13`; the code writes 15.
- README "26 blend modes" (code: 27) and "around 30 transitions" (tests: 84 + 21 Legacy).
- README "Not yet: … E-AC-3" (`docs/codec-parity.md:45` documents a 75 % decoder that plays the 5.1 core).
- `docs/target-app-parity.md:22` "45 crates" (workspace has 50 crates + 3 apps).
- `docs/roadmap.md` M6 "24 built-in presets" (code: 39).
- `docs/architecture.md` still lists `isobmff`/`matroska`/`bitstream` as in-repo L0 crates; they are thin
  re-exports of `craft-media` at this tag.
- `docs/ui-parity.md` (last reviewed 2026-10-10) and `docs/gaps.md` G8: several rows have lagged the code
  across rounds (transform handles, Effect Controls lines, Project marquee, work area). The skill says so and
  no longer repeats those rows as gaps.
- `docs/gaps.md` G13 still lists PXR24 EXR as missing; `docs/file-format-parity.md:58` and `crates/media`
  read PXR24.

## What changed in v0.13.0 (verified from the diff; v0.12.0 was a 7-file ProRes-alpha follow-up)

`git diff --stat v0.11.0..v0.13.0` = **521 files, +9 577/−10 972** (most deletions are `crates/isobmff` and
`crates/matroska` moving to craft-media, plus the `tests/` → `tests/it/` reorganisation). User-visible /
automation changes:

1. **Control-channel authentication** (`FILMCRAFT_CONTROL_TOKEN`), connection timeouts, bridged token
   (`apps/filmcraft/src/control_server.rs`, `crates/automation/src/bridge.rs`, `docs/control-protocol.md`).
2. **Work area bar**: 4 commands, UI bar/menu/hit-test, usable `range: workArea` export.
3. **Duplicate-frame markers**: 2 commands + query, background computation and timeline stripes.
4. **History panel pruning**: `history.deleteRedoable` (with OK dialog, Backspace in Premiere preset) and
   `history.clear`.
5. **Caption editing**: razor, ⌥-drag duplicate, clip-style copy/cut/paste, Text-list
   follow-the-playhead (`crates/engine/src/captions.rs`, `crates/edit/src/captions.rs`).
6. **Mixer parity**: `mixer.showHideTracks`, `mixer.meterInputOnly` + keys; **monitor Transparency Grid**
   (`view.transparencyGrid`) and alpha-aware live sequence rendering.
7. **Animated WebP import** (`crates/media/src/animated.rs`).
8. **Fujifilm F-Log / F-Log2** colour spaces (`crates/color/src/log.rs`).
9. **ProRes 4444/XQ alpha final-run conformance** + native macOS HD decode validation (`ROADMAP.md`
   2026-10-22, `crates/prores/README.md`).
10. **Hardening**: `effects.setParam` range validation, host-photo overlay pixel budget, proxy output names
    reserved exclusively and cleaned on failure, AAF/OMF export buffer caps, Project Manager uses resolved
    media paths, LUT/frame-size/`next_id` validation on project load, MCP screenshots in an owner-only temp
    dir, `chrono`-based date formatting with 400-year range extension, larger fuzz/robustness suites.

## Verification method and open items

- Read-only: the repo was not modified, built or committed; the GUI app was not launched. App-side evidence
  came from the bundle's Info.plist and `--version`; everything else is static source/doc reading.
- Not verified at runtime (no built binary here): the exact engine command total, per-machine
  `export.formats` availability, export timings, live MCP/control behaviour, and the `craft-media` container
  behaviour behind the pin.
- The repo's own readiness estimate (~56 %) is an author measurement, not re-measured in this audit.

## How to re-verify quickly

```sh
git checkout v0.13.0 && git rev-parse HEAD                 # 30536bc5d0ddf690f2181b7b97182db8658a6038
git diff --stat v0.11.0..v0.13.0 | tail -1                 # 521 files, +9577/−10972
sed -n '175,179p' crates/media/src/lib.rs                  # import extension lists
sed -n '62,66p' crates/format/src/lib.rs                   # SCHEMA_VERSION = 15
sed -n '272,294p' crates/export/src/lib.rs                 # 21 export formats
grep -cE '^\s+p\(' crates/export/src/presets.rs             # 39 presets (inside builtin_presets)
grep -n 'n, 93' crates/project/src/effect/vfx.rs            # 93 video effects
grep -n 'CATALOGUE.len(), 16' crates/project/src/effect/vfx.rs
grep -n 'counts\[..10\]' crates/project/src/vtransition.rs  # 84 transitions (+21 legacy)
grep -n 'BLEND_MODES' crates/project/src/effect.rs          # 27 blend modes
grep -n 'WORKSPACES' crates/ui-egui/src/dock.rs             # 9 built-in workspaces
grep -n 'PanelKind; 28' crates/ui-egui/src/dock.rs          # 28 panels
grep -n 'LogCurve; 10' crates/color/src/log.rs              # 10 camera log curves
sed -n '31,41p' apps/filmcraft/src/control_server.rs        # token requirement
grep -n 'history.deleteRedoable\|sequence.workAreaBar' crates/engine/src/commands.rs
filmcraft --version                                         # installed build
```

## How to re-verify the counts (needs a build)

```sh
cargo run --release -p filmcraft-cli -- commands | wc -l    # engine command list (authoritative)
cargo run --release -p filmcraft-cli -- export --list-presets | jq length
```

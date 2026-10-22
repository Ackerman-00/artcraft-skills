# FilmCraft — evidence table (for orchestrator review)

App: **FilmCraft**, repo `storytold/filmcraft`, inspected at **tag v0.10.0 / commit `cdf43fd366e378da266cb6d3c94549a45244be1f`**
(`git rev-parse HEAD`, release commit dated 2026-10-19), date **2026-10-22**. The installed app reports
`filmcraft 0.10.0` via its CLI, so the installed build is the inspected build. Paths below are repo-relative.
All numbers were recomputed from the v0.10.0 code; `git diff v0.9.0..v0.10.0` (one commit, 100 files) was
reviewed in full to catch behaviour changes.

| # | Claim in SKILL.md | Evidence | Tier |
|---|---|---|---|
| 1 | Professional NLE mirroring Premiere conventions; pure Rust; no FFmpeg inside; parity tracked vs Premiere 26.5.2 | `README.md` (headline, "Formats and codecs", "Status"); `AGENTS.md` §2; `docs/target-app-parity.md` header | implemented |
| 2 | Headless engine; one command registry behind UI + CLI + control channel + MCP | `docs/architecture.md` §1; `crates/engine/src/commands.rs` (`build()`); `crates/ui-egui/src/menus.rs`; `apps/filmcraft-cli/src/main.rs:63` | implemented |
| 3 | 50 crates + 3 apps, workspace version 0.10.0, edition 2024 | `ls crates apps` → 50 dirs; `Cargo.toml:6` (`version = "0.10.0"`); crate table `docs/architecture.md` | implemented |
| 4 | Desktop flags `--control/--control-input-only/--demo/--empty/--recover/--no-recover/--data-dir/--graphics/--version/-h` | `apps/filmcraft/src/args.rs:7-26` (`USAGE`); `.fcproj` detection case-insensitive `:119-124` | implemented |
| 5 | CLI subcommands `exec/run/commands/describe/inspect/import/export/render/probe/bench-decode/mcp` | `apps/filmcraft-cli/src/main.rs:63-140` (`HELP`); dispatch in `main.rs` | implemented |
| 6 | Dotted param keys capped at 64 nesting levels (new in 0.10.0); numeric options must be finite | `apps/filmcraft-cli/src/args.rs:6,90` + test `:151-158`; `finite_opt` in `apps/filmcraft-cli/src/main.rs:556-561` | implemented |
| 7 | Export format list: h264, hevc*, av1*, prores, dnxhr, apv, mjpeg, png/tiff/bmp/jpg/tga/dpx/exr, gif, wav, aiff, aac, flac, mxf-op1a, mxf-opatom (21) | `crates/export/src/lib.rs:64-133` (`enum Format`), `from_name`; `*` = hardware-gated via `register_encoder` | implemented (`hevc`/`av1` hardware-gated) |
| 8 | **39** built-in export presets, default "Match Source – Adaptive High Bitrate" (old skill said ~44 — corrected) | counted 39 `p(` calls in `builtin_presets()` `crates/export/src/presets.rs:95-190`; same count verified at v0.9.0 | implemented |
| 9 | HEVC export hardware-only; NVENC: Main 8-bit SDR + Main 10 HDR PQ/HLG; VideoToolbox: Main 8-bit SDR; H.264 HW encode macOS/NVENC opt-in | `crates/platform/src/hardware_encode.rs`, `crates/platform/src/videotoolbox_encode.rs`; README.md "Status"; issue #30 links | implemented |
| 10 | `file.exportMedia` without `wait` returns `{job, path, poll: "jobs.list", cancel: "jobs.cancel"}` (new in 0.10.0); `export.queue.list` shows only the queue | `crates/engine/src/export_tools.rs:549-556`; `docs/agents.md:123-129` | implemented |
| 11 | `.fcproj` = UTF-8 JSON; `SCHEMA_VERSION` = **15** (14 migrations v1→v15); newer files refused (old skill said 13 — corrected) | `crates/format/src/lib.rs:62-66` (`MIGRATIONS`, `SCHEMA_VERSION = MIGRATIONS.len()+1`); refusal text `docs/project-files.md:79-86`; doc example `docs/project-files.md:11` stale at 13 | implemented (doc drift flagged) |
| 12 | Atomic saves; auto-save ring; crash-recovery journal restored after a crash | `crates/format/src/atomic.rs`, `crates/format/src/autosave.rs`, `docs/project-files.md:88-173` | implemented |
| 13 | Import extension lists (stills/audio/video), `is_importable` membership | `crates/media/src/lib.rs:175-179` | implemented |
| 14 | Container openers order (mp4, mkv, mxf, ogg, mpeg, apv, avi, y4m, audio); new streaming `reader_openers` registry | `crates/codecs/src/lib.rs:135-138`, reader registry `:138-165` | implemented |
| 15 | AVI demuxer implemented (AVI 1.0 + OpenDML) while `docs/file-format-parity.md:43` still says "no demuxer (#598)" | `crates/avi/README.md`; `avi::opener` in `crates/codecs/src/lib.rs:135-138`; stale row at `docs/file-format-parity.md:43` | implemented (contradiction flagged) |
| 16 | 93 video effects / 16 folders; 53 audio effects; 84 video transitions +21 Legacy; README's "around 30 transitions" undercounts | test assertions `crates/project/src/effect/vfx.rs:1262-1263`, `crates/project/src/effect/audio.rs:578` (`[&str; 53]`), `crates/project/src/vtransition.rs:416-417` | implemented |
| 17 | 27 blend modes (README says 26 — README undercounts) | `BLEND_MODES` at `crates/project/src/effect.rs:144-172`, 27 entries counted | implemented |
| 18 | E-AC-3 decode partial: independent substream 5.1 core; no AHT / enhanced coupling / 7.1 dependent substreams (README "Not yet: E-AC-3" is imprecise) | `crates/ac3/README.md`; `crates/codecs/src/audio.rs:31,166,343-345`; `docs/codec-parity.md:45` | implemented (partial, quantified) |
| 19 | Interchange: EDL, FCP7 XML (xmeml v4/v5), FCPXML 1.9–1.11, OTIO, AAF, OMF 2.0 import/export; ALE export | `crates/interchange/src/lib.rs:1-12`; unchanged v0.9.0→v0.10.0 | implemented; AAF/OMF **never validated in Avid/Pro Tools** (`docs/gaps.md` G15) |
| 20 | Captions: 7 formats (SRT, WebVTT, SCC, MCC, STL, TTML, DFXP) + burn-in; README bullet names only 3 | `crates/captions/src/` (8 modules); `Format` enum in `crates/captions/src/lib.rs:34-47`; `docs/captions.md` | implemented (README abbreviation noted) |
| 21 | TTML tick timing: absent `tickRate` now uses effective frame rate × subFrameRate as a rational (new in 0.10.0) | `crates/captions/src/ttml.rs` (`Timing.tick_rate: FrameRate`); `crates/captions/README.md` "TTML tick timing" | implemented |
| 22 | Speech-to-text needs `whisper` feature; explicit error string; releases pass no `--features`; `neural-voices` likewise off | `crates/engine/src/transcript.rs:61`; `apps/filmcraft/Cargo.toml:13-19`; `packaging/macos/package.sh` (`cargo build --release --locked` with no features); `docs/gaps.md` G19 | implemented-as-gated / **not in releases** |
| 23 | MCP: 17 tools (`command_list`…`ui_control`), resources `filmcraft://document` + `filmcraft://commands`; `doc_inspect` pins sequence to reported active id (new in 0.10.0) | `crates/automation/src/server.rs:317-560` (tool fns), `:645-666` (resources), `:288-298` + tests (pinning) | implemented |
| 24 | Control channel: loopback-only, no auth, 16 connections, non-JSON line closes the connection; focus policy | `docs/control-protocol.md:9-17`, `:54-75`; `apps/filmcraft/src/control_server.rs`; doc unchanged v0.9.0→v0.10.0 | implemented |
| 25 | Headless MCP not confined: no folder-confinement flags | `docs/agents.md:17-19` | implemented (deliberate) |
| 26 | `.prproj` cannot be opened or written; stated beta blocker | `grep -ri prproj crates apps` → no matches; `docs/gaps.md` G2 ("Blocks beta: **yes**") | not implemented (roadmap) |
| 27 | No plugin hosting; no caption codecs embedded in the video stream; camera RAW = DNG only | `docs/gaps.md` G11/G10; `docs/file-format-parity.md`; `crates/dng` | not implemented |
| 28 | One project per app instance | `crates/engine/src/project_tools.rs:90-91` (`file.closeAllOtherProjects` → "only one project is open") | implemented (deliberate limit) |
| 29 | Export destinations: exactly one, `export.destination.mediaFile`; README image alt text advertises five that don't exist | `crates/ui-egui/src/panels/export_mode.rs:204`; `README.md:197` | claimed (docs) / **not implemented** |
| 30 | "more than 650 engine commands" | `README.md:226`; static count: 219 `cmd!`/`query!` + 363 `spec(` in `crates/engine/src/*.rs`; only in-code assertion is `> 90` (`crates/engine/src/tests.rs:618`) | claimed — exact total uncertain, enumerate with `filmcraft-cli commands` |
| 31 | Workspaces Editing…All Panels (7); 28 panel kinds; 4 shortcut presets; `view.resetInterfaceZoom` new in 0.10.0 | `crates/ui-egui/src/menus.rs:111-121`; `crates/ui-egui/src/dock.rs:14-46` (`ALL: [PanelKind; 28]`, unchanged since v0.9.0); `crates/engine/src/shortcuts.rs:59-62`; `menus.rs` diff | implemented |
| 32 | Track colour labels via `timeline.setTrack {label}`; tracks report `label` in `inspect_sequence` (new in 0.10.0) | `crates/engine/src/commands.rs:2860-2910`, `inspect_sequence` `:4277+` diff | implemented |
| 33 | macOS packaging: deployment target 11.0; app id `ai.storyteller.filmcraft`; `filmcraft-cli` ships as a separate asset | `packaging/macos/package.sh:38`; `packaging/macos/Info.plist.in:16`; `docs/agents.md:48` | implemented (packaging) |
| 34 | Localization: English + 11 catalogues; German now ~100% interface (new in 0.10.0); uk/ru partial; G14 = 3 languages missing (Hindi, Arabic, Vietnamese) | `crates/ui-egui/src/i18n/` (11 .tsv); `ROADMAP.md` language table diff; `docs/gaps.md` G14 diff | implemented (varying depth) |
| 35 | Parity numbers ~86% breadth / ~56% ready (re-measured 2026-10-10 vs Premiere 26.5.2) | `README.md` "Status"; `docs/target-app-parity.md` headline table | authors' assessment (not re-measured here) |

## Notes the orchestrator should spot-check

1. **Count corrections vs the old (v0.9.0) skill**: export presets ~44 → **39** (recounted; the old figure was wrong,
   the list itself is unchanged); schema 13 → **15** (real change); transitions now quantified **84 + 21 Legacy**
   (old skill didn't quote a number); blend modes stay **27** (code) against a README that says 26.
2. **README vs code discrepancies carried forward deliberately**: AVI (file-format-parity.md:43 stale),
   schema example (project-files.md:11 stale at 13), blend modes (README 26 vs code 27), transitions
   (README "around 30" vs test 84+21), E-AC-3 (README "Not yet" vs codec-parity.md:45 "75%, plays the 5.1 core").
   The skill always names the discrepancy instead of picking a side silently.
3. **What actually changed in 0.10.0** (verified from the one release commit, 100 files, +6254/−286): schema v15;
   track colour labels + `inspect_sequence.label`; `view.resetInterfaceZoom` + Ctrl+Plus chord;
   `appearance.animations` setting; export result `poll`/`cancel` hints (#1544); MCP `doc_inspect` sequence
   pinning (#1477) and u64 active-id handling; CLI dotted-key depth cap + finite-number options; SDR `colr`
   sample entries (#2142); TTML rational tick timing; German i18n ~100%; caption Properties panel in the
   Properties panel; multicam selection falls back to the Timeline (#1362). No crates added or removed;
   no formats or CLI subcommands added or removed.
4. **Verification depth.** The repo's own readiness estimate is "~56%"; no automated output-fidelity comparison
   against Premiere exists (`docs/gaps.md` G1). The skill's Verification protocol is written for that reality.
5. **Nothing was executed.** The repo was read-only (no build, no app launch); all claims are static-code
   evidence. Runtime numbers (fps, LU agreement, MB/s) are attributed to the repo's own measurements.

## How to re-verify quickly

```sh
git checkout cdf43fd366e378da266cb6d3c94549a45244be1f   # or tag v0.10.0
git rev-parse HEAD
sed -n '175,179p' crates/media/src/lib.rs               # import extension lists
sed -n '62,66p' crates/format/src/lib.rs                # SCHEMA_VERSION = 15
sed -n '64,133p' crates/export/src/lib.rs               # export formats
grep -n 'n, 93' crates/project/src/effect/vfx.rs        # 93-effect assertion
grep -n '84' crates/project/src/vtransition.rs          # transition counts
grep -c 'p(' crates/export/src/presets.rs               # presets (count inside builtin_presets)
filmcraft --version                                     # installed build
```

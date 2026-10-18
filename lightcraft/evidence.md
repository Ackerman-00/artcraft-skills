# evidence.md — LightCraft

Spot-check table for the orchestrator. Repo `storytold/lightcraft`, checkout
`4f0b110bcbd2e350c6d97b47f1d824c2222295c4` = tag `v0.9.1`, clean tree, inspected 2026-10-18.
The installed `/Applications/LightCraft.app` is the same build (`Info.plist` →
`CFBundleShortVersionString 0.9.1`, `LightCraftBuildCommit 4f0b110bcbd2e350c6d97b47f1d824c2222295c4`).

Tier legend: **implemented** = code path exists and is reachable from UI / CLI / command registry;
**partial** = exists but visibly incomplete (what is missing is stated); **claimed** = asserted in
README/docs but not confirmed in code.

| # | Capability claim | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Library is a folder: `catalog.snap` + `catalog.log` (append-only CRC-32 JSON-lines op log), `presets.json`, `view.json`, `prefs.json`, `thumbs/`, `Originals/` | `crates/engine/src/library.rs:1-15`; `crates/catalog/src/journal.rs:1-40` | implemented |
| 2 | One writer per library (`catalog.lock`); headless `--library` fails while the app has it open | `crates/catalog/src/lock.rs`; `docs/mcp.md:19-22`; `apps/lightcraft-cli/src/main.rs:130-140` | implemented |
| 3 | Default library `~/Pictures/LightCraft Library`, overridable by `LIGHTCRAFT_LIBRARY` | `crates/engine/src/library.rs:61-70` | implemented |
| 4 | Importable extensions are one extension-only list of 34 formats (`jpg … mef`) | `crates/engine/src/import.rs:36-43` (`EXTENSIONS`, `is_supported`) | implemented |
| 5 | Import modes Add / Copy / Move with rename + folder templates and duplicate detection | `crates/engine/src/import.rs:45-55`; `crates/engine/src/rename.rs:1-20` | implemented |
| 6 | Raw decode from sensor data: DNG, CR2, CR3 (lossless CRX + 0x100/0x200 C-RAW), ARW, NEF, RAF incl. X-Trans, RW2/RWL/RAW, PEF, ORF 12.8bpp, SRW; per-model counts 545 verified / 212 preview-only / 38 unsupported of 1,446 | `README.md:345`; `docs/raw-parity.md:13-27` | implemented (coverage partial) |
| 7 | Undecodable raws fall back to the embedded camera JPEG (`previewOnly`) | `docs/mcp.md:232-241`; `crates/engine/src/camera_preview.rs` | implemented |
| 8 | HEIC/HEIF decode only with the `heif` feature (off by default, on in official packaging) | `crates/codecs/src/heif.rs:17,24,37`; `apps/lightcraft/Cargo.toml:14-18`; `packaging/macos/package.sh:65` | implemented (build-flag gated) |
| 9 | AVIF is recognised but not decoded on import | `crates/engine/src/import.rs:41`; `docs/file-format-parity.md` | partial |
| 10 | ~122 named develop sliders in one spec table + indexed Point Color controls; 16 named sections | `crates/develop/src/controls.rs:141-166`, `:170` (`controls!`), `:296` (`INDEXED`), `:14-31` (Section) | implemented |
| 11 | Everything is a command: 370 engine command specs + 183 `UI_COMMANDS` | `crates/engine/src/cmd/mod.rs:139-182`; `crates/ui-egui/src/menus.rs:61` | implemented |
| 12 | Export formats `jpeg png tiff psd webp avif jxl original dng rendereddng`; `psd` = flat, no layers; `original` = file + XMP sidecar | `crates/engine/src/export.rs:14-64` | implemented |
| 13 | Export option validation: bitDepth 8/10/16/32, colour spaces srgb/displayP3/adobeRgb/proPhoto/rec2020, metadata policy, sharpen, tiff/dng compression, conflict policy, resize modes, ppi, watermark, HDR transfer | `crates/engine/src/export.rs:860-960` | implemented |
| 14 | File-naming / folder tokens shared by rename, import and export; never overwrite a target | `crates/engine/src/rename.rs:1-20`; `docs/mcp.md:170` | implemented |
| 15 | Control channel: JSON-lines on loopback, no auth, 60 s reply timeout, 5 s no-frame failure, 16 connections | `docs/control-protocol.md:1-29`; `apps/lightcraft/src/control_server.rs`; `crates/ui-egui/src/control.rs` | implemented |
| 16 | MCP server over stdio, headless or `--connect` to the live app; protocol `2025-06-18`; per-command tools `cmd_*` | `docs/mcp.md:1-14`, `:162-209`; `crates/mcp/` | implemented |
| 17 | CLI subcommands and the exact usage text (`run`, `mcp`, `render`, `snapshot`, `merge`, `synth-merge`, `denoise-serve`, `commands`, `controls`, `calibrate`) | `apps/lightcraft-cli/src/main.rs:28-114`; dispatch `:159-179` | implemented |
| 18 | Headless UI snapshot without window or GPU (`--demo --script tour.jsonl -o out.png --size WxH`) | `apps/lightcraft-cli/src/main.rs:69-82`, `:766-933`; `docs/control-protocol.md:242-282` | implemented |
| 19 | Desktop app flags: `--library`, `--no-demo`, `--memory`/`--demo`, `--control PORT`, `--version`, `--help`, plus positional paths imported at launch | `apps/lightcraft/src/main.rs:766-790`, `:857-877` | implemented |
| 20 | XMP sidecars: write/read, `lc:settings` exact round trip, `crs:` read approximate, foreign namespaces preserved byte for byte, merge-never-replace, atomic write, `.bak` on unreadable sidecar | `docs/xmp-interop.md` | implemented |
| 21 | Presets: `.lcpreset` native; import XMP / `.lrtemplate` / `.lmp` / `.mplumpack` / `.zip` / `.cube`; Adobe `.dcp` and `.lcp` deliberately never used | `crates/engine/src/presets.rs:14`, `:158`; `docs/file-format-parity.md` | implemented |
| 22 | AI masks: Object/Describe use SAM 3 via an optional, unbundled model; Subject/Sky/People/Background/Landscape are classical heuristics | `docs/ai-masks.md:6-9`; `docs/gaps.md:22`; `crates/engine/src/cmd/masks.rs`; `crates/segment/` | partial |
| 23 | AI Denoise ships no weights; user installs an ONNX model + `denoise-model.json`; Bayer only; not on merged DNGs | `docs/denoise.md:14-24`; `docs/gaps.md:45` | partial |
| 24 | Camera colour is estimated (per-file fit to camera JPEG / 5 bundled profiles / 52 spectral matrices / neutral fallback), ΔE 2.9–10 | `docs/gaps.md:18`; `docs/raw-parity.md:25` | partial |
| 25 | No lens profile database (only in-file corrections) — 3,635 Adobe profiles vs 0 ours | `docs/gaps.md:25`; `docs/raw-parity.md:26` | not implemented |
| 26 | Render fidelity unmeasured; tone/NR/sharpening tuned by eye; only process V1 and V2 exist | `docs/gaps.md:20`; `docs/process-versions.md` | partial |
| 27 | Not implemented: video, Map view, Book module, publish services, tethered capture, Lightroom plug-ins, HDR display, Super Resolution / Raw Details / generative remove | `docs/gaps.md:28-37`; `ROADMAP.md:35-36` | not implemented |
| 28 | Lightroom Classic `.lrcat` import is one-way and approximate | `docs/lightroom-catalog-import.md`; `docs/gaps.md:30` | partial |
| 29 | WebAssembly build of the same UI, WebGL2, persistent library in OPFS/IndexedDB; WebGPU and Safari/Firefox in progress | `docs/web.md:1-10`; `README.md:358`; `apps/lightcraft-web/` | implemented (partial) |
| 30 | No document file format; the `pcraft` "LightCraft Document" type in the macOS bundle is stale (PhotoCraft's extension) and unused by the code | `packaging/macos/Info.plist.in:70`; `grep -rn pcraft` over `crates/`/`apps/` matches only a test temp-dir name | claimed (packaging only) |

## Notes for the reviewer

- Two independent counts back the automation claim: 370 `cmd!` entries inside the `specs()`
  functions wired together in `crates/engine/src/cmd/mod.rs:139-182`, and 183 tuples inside
  `UI_COMMANDS` in `crates/ui-egui/src/menus.rs:61`.
- The claimed-vs-code mismatch on `.pcraft` (#30) is the only place where shipped packaging metadata
  and source disagree; it is flagged in SKILL.md rather than silently repeated.
- Nothing in this skill comes from running the app: no GUI was launched, no binary driven. Claims about
  windows, menus and dialogs derive from the command registry, the control-protocol document, the
  command/UI tables and the packaging metadata only.
- `lightcraft-cli` is **not** installed on this machine and not inside the `.app`; the SKILL.md says so
  and points at the release asset / `cargo build -p lightcraft-cli`.
- Line numbers were taken from the files as read at the cited commit; `docs/parity-checklist.md` is the
  project's own row-by-row tracker and `docs/gaps.md` its ranked gap list — both are better evidence than
  a percentage for any specific feature question.

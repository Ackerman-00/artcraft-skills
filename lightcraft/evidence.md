# evidence.md — LightCraft

Spot-check table for the orchestrator. Repo `storytold/lightcraft`, tag **v0.11.0**, commit
`ec0cda9a6f320e3b32f659f16718f7bce6c3f12f`, clean detached worktree, inspected 2026-10-22. The installed
`/Applications/LightCraft.app` is the same release (its binary's `--version` prints `lightcraft 0.11.0`;
bundle id `ai.storyteller.lightcraft`; its `Info.plist` version field is stale-looking and was not trusted).

Tier legend: **implemented** = code path exists and is reachable from UI / CLI / command registry;
**partial** = exists but visibly incomplete (what is missing is stated); **claimed** = asserted in
README/docs but not confirmed in code.

| # | Capability claim | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Library is a folder: `catalog.snap` + `catalog.log` (append-only CRC-32 JSON-lines op log, background compaction), `presets.json`, `view.json`, `prefs.json`, `thumbs/`, `Originals/`; per-command journal + fsync; failed saves retry and surface via `ui.inspect` → `unsaved` | `crates/engine/src/library.rs:1-24`; `crates/catalog/src/journal.rs`; `docs/control-protocol.md:137-147` | implemented |
| 2 | One writer per library (`catalog.lock`); headless `--library` fails while the app has it open; `--connect` is the workaround | `docs/mcp.md:19-22`; `apps/lightcraft-cli/src/main.rs` (`library_error`, LibraryInUse message) | implemented |
| 3 | Default library `~/Pictures/LightCraft Library`, overridable by `LIGHTCRAFT_LIBRARY` | `crates/engine/src/library.rs:33,61-68` | implemented |
| 4 | Importable extensions are one extension-only list of **36** (`jpg … mef`, incl. `heic heif avif` entries that fail without the `heif` feature) | `crates/engine/src/import.rs` (`EXTENSIONS`, `is_supported`) | implemented |
| 5 | Raw per-model coverage measured: of 1,446 Adobe models, 545 verified / 651 unverified / 212 preview-only / 38 unsupported; ~94% of photographers fully decode, ~85% on a verified body | `docs/raw-parity.md:17-27` (headline + method) | implemented (coverage partial) |
| 6 | Raw decode from sensor data: DNG, CR2, CR3 (lossless CRX + 0x100/0x200 C-RAW, R5M2/R6M2 adaptive-QP fixed), ARW, NEF (uncompressed + lossless + lossy-after-split), RAF (uncompressed + compressed, Bayer + X-Trans), RW2/RWL/Panasonic RAW, PEF, ORF 12.8bpp, SRW uncompressed, ERF, MEF | `README.md` RAW row; `docs/raw-parity.md`; `docs/cr3.md`; `docs/raf-compression.md` | implemented (variants partial) |
| 7 | Undecodable raws fall back to the embedded camera JPEG (`previewOnly`); background recheck on version change; headless `library.recheckPreviewOnly`; sparse header+preview reads for network shares | `docs/mcp.md:235-243`; `docs/raw-preview-reads.md:1-13` | implemented |
| 8 | HEIC/HEIF decode only with the `heif` build feature (off by default, HEVC patents; on in official packaging; installed binary contains HEIC strings) | `apps/lightcraft/Cargo.toml:16-18`; `packaging/macos/package.sh:65`; `strings` on installed binary | implemented (build-flag gated) |
| 9 | AVIF recognised but not decoded on import; export-only | `crates/engine/src/import.rs`; `docs/file-format-parity.md` (AVIF row) | partial |
| 10 | **122** named develop sliders in one spec table + **8** indexed Point Color specs; 16 sections | `crates/develop/src/controls.rs:14-31` (Section), `:170` (`controls!`), `:296` (`INDEXED`) | implemented |
| 11 | Everything is a command: **370** engine command specs (37 `specs()` sources) + **183** `UI_COMMANDS` | `crates/engine/src/cmd/mod.rs:130-183`; `crates/ui-egui/src/menus.rs:61` | implemented |
| 12 | Export formats `jpeg png tiff psd webp avif jxl original dng rendereddng`; flat PSD; `original` = file + XMP sidecar; `dng` incl. lossy JPEG tiles; `rendereddng` = linear 16-bit float DNG | `crates/engine/src/export.rs:16-33`; `docs/file-format-parity.md` DNG row | implemented |
| 13 | Export option validation: quality clamp 1–100, bitDepth 8/10/16/32 per format, colour spaces srgb/displayP3/adobeRgb/proPhoto/rec2020, metadata policy, sharpen + amount, tiff/dng compression, conflict policy, six resize modes + dontEnlarge, ppi, limitKb, watermark, `hdr` + `hdrTransfer pq|hlg`, jxl options, `destinationMode: "sameAsOriginal"`, macOS `addToPhotos`/`photosAlbum` | `crates/engine/src/export.rs:614-680,716-733,1089`; `docs/mcp.md` export helper; `docs/apple-photos.md` | implemented |
| 14 | File-naming / folder tokens shared by rename, import and export; no target ever overwritten (file-identity collision check) | `crates/engine/src/rename.rs:1-20` | implemented |
| 15 | Control channel: JSON-lines on loopback, no auth, 60 s reply timeout, 5 s no-frame failure, max 16 connections, malformed line closes connection; `ui.dock` panel docking; `ui.clipboard`; headless-CPU `ui.screenshot` | `docs/control-protocol.md:1-29,60-98,242-282,284-301` | implemented |
| 16 | MCP server over stdio (protocol `2025-06-18`, older accepted), headless or `--connect`; helpers + shared core tools (`command_list/run/batch`, `doc_inspect`, `render_preview`); resources; per-command `cmd_*` tools unless `--compact`; export progress/cancellation | `docs/mcp.md:1-14,129-212,245-262,342-367`; `crates/mcp/` | implemented |
| 17 | CLI subcommands `run mcp render snapshot merge synth-merge denoise-serve commands controls calibrate`; `run --script/--keep-going`; `render --set/--settings/--preset/--opt`; `merge hdr-batch`; `denoise-serve` LAN/VPN tile serving | `apps/lightcraft-cli/src/main.rs` (USAGE + dispatch) | implemented |
| 18 | Headless UI snapshot without window or GPU (`--demo --script tour.jsonl -o out.png --size WxH --scale S`) | `docs/control-protocol.md:242-282`; `apps/lightcraft-cli/src/main.rs` (snapshot) | implemented |
| 19 | Desktop app flags `--library --no-demo --memory/--demo --control PORT --version --help` + positional imports; env `LIGHTCRAFT_LIBRARY/_CONTROL_PORT/_CONFIG_DIR/_GPU_BACKEND/_GPU/_LOG/_NO_PREFS/_NO_NATIVE_MENU/_SAM3_DIR/_SAM3_MIRRORS/_LENSFUN_DIR/_CAMERA_PROFILES/_DENOISE_*` | `apps/lightcraft/src/main.rs` (HELP block, arg match); `apps/lightcraft-cli/src/main.rs` USAGE | implemented |
| 20 | XMP sidecars: read/write manual + auto, `lc:settings` exact round trip incl. process, owned-property list, foreign namespaces preserved byte for byte, merge-never-replace, capture-time precedence, naming stem|full, atomic write, retry after share returns (`library.retrySidecars`), `crs:` read approximate with per-photo warnings, Lightroom radial masks inside circle | `docs/xmp-interop.md`; `docs/whats-new.md` (2026-10-14, 2026-10-18) | implemented |
| 21 | Presets: **41** built-in with Amount 0–200%; `.lcpreset` native; import XMP / `.lrtemplate` / `.lmp` / `.mplumpack` / `.zip` / `.cube` LUTs / local-adjustment effects (`.lrtemplate`, `.xmp`, `.lceffect`); Adobe `.dcp`/`.lcp` deliberately never used | `crates/engine/src/presets.rs:14,158,215`; `crates/engine/src/cmd/mask_effect_files.rs:19`; `crates/engine/src/cmd/lut_profiles.rs` | implemented |
| 22 | Camera colour: DNG matrices, guarded camera-JPEG fits, **8** bundled profiles (ILCA-99M2, ILCE-7CR, ILCE-7M4, X-H2S, X-T4, Z 6II, Z 8, D5300), 52 spectral matrices, neutral fallback; `lightcraft-cli calibrate` fits per-model profiles (≥5 photos; `LIGHTCRAFT_CAMERA_PROFILES`) | `assets/camera-profiles/` (8 files); `docs/raw-parity.md:24-25`; `apps/lightcraft-cli/src/main.rs` (calibrate); `docs/camera-preview-colour.md` | implemented (measured colour partial, ΔE 2.9–10) |
| 23 | Lens corrections from a **user-supplied lensfun XML database** via `LIGHTCRAFT_LENSFUN_DIR` (distortion/TCA/vignetting, EXIF matching, DNG-opcode conversion); nothing bundled; limits: raws only, automatic matching, no fisheye, unvalidated vs real photos | `crates/lensdb/src/lib.rs:1-14`; `crates/engine/src/lens_profiles.rs:15`; `docs/lens-profiles.md` | implemented (partial — no bundled DB, no manual picker) |
| 24 | AI masks: Object/Describe use SAM 3 via an optional, unbundled model (`LIGHTCRAFT_SAM3_DIR`); Subject/Sky/Background(/People/Landscape) are classical heuristics; 17 local adjustments + Amount per mask; straight brush strokes `mask.brushStroke {connect: true}` | `docs/ai-masks.md:6-9`; `docs/gaps.md:22`; `README.md` masking section | partial |
| 25 | AI Denoise ships no weights; user-installed ONNX + `denoise-model.json`; Bayer only; not on merged DNGs; `denoise-serve` distributes tiles over LAN/VPN with token auth | `docs/denoise.md:14-24`; `docs/gaps.md:45`; `apps/lightcraft-cli/src/main.rs` USAGE (denoise-serve) | partial |
| 26 | Process versions: V1 frozen, V2 current; `develop.updateProcess`; copy/paste/presets never carry the process; unknown newer number renders with latest | `docs/process-versions.md`; `crates/develop/src/settings.rs` | implemented |
| 27 | Photo Merge: HDR (align, deghost incl. moving lights, deterministic), Panorama (3 projections, boundary warp, auto crop, up to 512 MP / 65,000 px), HDR Panorama → DNG; `merge.hdrBatch` per bracket set; `lightcraft-cli merge hdr|panorama|hdr-panorama|hdr-batch` | `docs/merge.md:1-37`; `apps/lightcraft-cli/src/main.rs` USAGE | implemented |
| 28 | Print module as `print.*` commands: 4 layout styles, Picture Package Auto Layout, cells, templates, printer/paper ICC + intent + BPC, 8/16-bit colour-managed PDF, Page Options on Single Image/Contact Sheet; missing: identity plate/watermark/photo-info overlays, Cut Guides, Custom Package Auto Layout, direct printing, JPEG output | `crates/engine/src/cmd/print.rs:340-343` + command ids; `docs/gaps.md:32`; `README.md` print section | implemented (partial — page overlays/direct print ⬜) |
| 29 | Slideshow: playback plus background export PDF / JPEG sequence / AV1 video MP4|WebM, no audio, ≤2 h; layouts/overlays/titles/templates as commands with previews; music and module editor missing | `docs/control-protocol.md:87-97`; `docs/slideshow.md`; `README.md` slideshow row | implemented (partial — music/module editor ⬜) |
| 30 | Contact Sheet PDF: A4/Letter, captions, 150 dpi sRGB; limits 1,000 photos / 100 pages / 256 MiB; atomic replace; `export.contactSheet` command | `crates/engine/src/contact_sheet.rs:87-154`; `README.md` agents section | implemented |
| 31 | Focus points: `meta.focus` in `photo.inspect`, View ▸ Show Focus Point (⌥F), zoom-to-focus, background `photo.readFocusPoints`; Sony α1 / A7S III only for now | `docs/control-protocol.md:117-123`; `docs/focus-points.md`; `docs/whats-new.md` 2026-10-14 | implemented (partial — camera coverage thin) |
| 32 | Local folder browsing without import (Lightroom "Local" tab): probed in place, edits to sidecars, "Add to My Photos", hidden locations restored one at a time | `crates/engine/src/cmd/browse.rs:1-9`; `docs/whats-new.md` 2026-10-19 | implemented |
| 33 | Not implemented: video editing, Map view, Book module, publish services, tethered capture, Lightroom plug-ins, HDR display, Super Resolution / Raw Details / generative remove | `docs/gaps.md:28-36`; `ROADMAP.md` features table | not implemented |
| 34 | No document file format; the macOS bundle declares **no** UTI types at this release (the old stale PhotoCraft `.pcraft` declaration is removed, issue #1951 explained in-tree) | `packaging/macos/Info.plist.in:54-57` | implemented (as "none declared") |
| 35 | Lightroom Classic `.lrcat` import is one-way and approximate; on-demand main-file reads up to 16 GiB; Open Library on a catalog folder offers the importer | `docs/lightroom-catalog-import.md`; `docs/gaps.md:30`; `docs/control-protocol.md:158-168` | partial |
| 36 | WebAssembly build of the same UI, WebGL2, persistent library in OPFS/IndexedDB; WebGPU + Safari/Firefox in progress; JXL export native-only | `docs/web.md:1-8`; `README.md` platform rows | implemented (partial) |
| 37 | Maturity self-assessment: 81.6% checklist breadth (532 rows), ready ~61% full / ~51% practitioner / ~65% essentials; stage alpha, beta ~340–600 h away | `ROADMAP.md:3,15-19`; `docs/target-app-parity.md` headline | claimed (project's own measured/estimated numbers) |
| 38 | Display colour management: macOS screen profile, Linux colord, chosen ICC via `app.displayProfile`; headless sessions stay sRGB | `docs/display-profiles.md` | implemented |
| 39 | Activity stack: one registry for long-running tasks, `activity.list` / `activity.cancel`, quit protection | `docs/background-tasks.md:1-10`; `docs/control-protocol.md:84-85` | implemented |
| 40 | Keyboard: `G D N E C M H I K Shift+P Shift+V \ Y Shift+Y Z J A O F Shift+F / V` and rating/flag keys `0-5 6-9 P X U ` `[ ]` (+advance with Shift), grid size `=` `-`, ⌥F focus overlay; reserved `Cmd+,` `Cmd+Q`; all remappable | `crates/ui-egui/src/menus.rs` (UI_COMMANDS); `crates/engine/src/cmd/library.rs:765,794-800`; `crates/engine/src/cmd/develop.rs:476`; `docs/library-shortcuts.md`; `crates/ui-egui/src/shortcuts.rs:17` | implemented |

## Notes for the reviewer

- Counts recomputed from source at v0.11.0: 36 import extensions, 122 + 8 develop controls, 370 engine
  `cmd!` specs (37 `specs()` sources in `cmd/mod.rs:140-183`), 183 `UI_COMMANDS` tuples, 10 export formats,
  41 built-in presets, 8 bundled camera profiles, 14 interface languages (13 non-English locale catalogs),
  10 CLI subcommands. The 370/183/122 counts are identical to the previous pin's counts (recounted, not
  carried forward); the extension count corrects the previous evidence.md's "34" (the list itself is
  unchanged between v0.9.1 and v0.11.0 — the old count was a miscount).
- Actual v0.9.1 → v0.11.0 delta is small (190 files, +7,690/−941; `git diff --stat v0.9.1 v0.11.0`):
  JXL decode hardening, geocode `maxDistance`, preset-save failure surfaced as unsaved, portrait crop
  ratios, hidden-Local restore, plist pcraft removal, export bitDepth/known-keys hardening (#1952),
  Lightroom-catalog and reload work. Most capabilities the previous skill lacked (print, slideshow, focus
  points, Local browse, lensfun lensdb, display profiles, activity stack) already existed at v0.9.1 —
  verified via `git show v0.9.1:<path>` — so this skill adds them as corrections, not version changes.
- Where docs and code disagreed at this tag, the code was followed and the disagreement recorded in
  SKILL.md's uncertainty list: "5 bundled profiles" (gaps/raw-parity docs) vs 8 in `assets/camera-profiles/`;
  `docs/file-format-parity.md` PSD-write ⬜ and "no HLG" vs `ExportFormat::Psd` and `HdrCurve::Hlg` in
  `crates/engine/src/export.rs`.
- `lightcraft-cli` is **not** installed on this machine and not inside the `.app`; SKILL.md says so and
  points at the release asset / `cargo build -p lightcraft-cli`.
- Nothing in this skill comes from running the app: no GUI was launched. The installed binary was only
  inspected read-only (`--version` via its binary path, `strings` for the HEIC feature, bundle id via
  `defaults read`).
- Line numbers were taken from the files as read at the cited commit; `docs/parity-checklist.md` is the
  project's own row-by-row tracker and `docs/gaps.md` its ranked gap list — both are better evidence than
  a percentage for any specific feature question.

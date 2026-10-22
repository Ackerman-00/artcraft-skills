# FilmCraft file formats — what the code actually reads and writes

Version: repo tag **v0.10.0**, commit `cdf43fd366e378da266cb6d3c94549a45244be1f` (inspected 2026-10-22).
Every list below is read out of the code, not the marketing docs. Where a doc contradicts the code, the
contradiction is named and the code wins.

## Import extension lists (authoritative)

`crates/media/src/lib.rs:175-179`:

```rust
STILL_EXTENSIONS = ["png","jpg","jpeg","gif","webp","tif","tiff","bmp","tga","dpx","exr","hdr","dng"]
AUDIO_EXTENSIONS = ["wav","wave","bwf","aif","aiff","mp3","mp2","m4a","aac","flac","ogg","opus"]
VIDEO_EXTENSIONS = ["mp4","m4v","mov","mkv","webm","avi","mxf","mts","m2ts","m2t","ts","mpg","mpeg",
                    "vob","mod","tod","m2v","m1v","mpv","3gp","y4m","apv"]
```

Unchanged since v0.9.0. `is_importable()` is exactly membership in those three lists (the Media Browser and
drag/drop filter on it). Files that fail to open still import with an error per file.

Container openers, in the order they are tried (`crates/codecs/src/lib.rs:135-138`):
`mp4` (MP4/MOV), `mkv` (Matroska/WebM), `mxf` (OP1a/OP-Atom), `ogg`, `mpeg` (TS/PS/ES), `apv`, `avi`, `y4m`,
`audio` (standalone compressed audio). Then `filmcraft_media` falls back to: OpenEXR sniff, Radiance HDR sniff,
WAV, animated GIF/APNG, generic stills. Since v0.10.0 there is also a streaming `reader_openers` registry
(index on open, samples on demand) used for platform media sources such as the web app's WebCodecs MP4
(`crates/codecs/src/lib.rs:138-165`).

## Video codecs

| Codec | Decode | Encode | Evidence |
|---|:--:|:--:|---|
| H.264/AVC | yes (8-bit 4:2:0 software; High 10/4:2:2 only via OS hardware) | yes (own encoder; High/Main/Baseline, CABAC, B-frames, CRF/CBR/VBR/2-pass; hardware via VideoToolbox on macOS or NVENC on Windows/Linux, opt-in) | `crates/h264`, `crates/h264enc`, `crates/platform/src/videotoolbox_encode.rs` |
| HEVC/H.265 | yes (Main, Main 10) | **hardware only**: NVENC writes Main 8-bit SDR and Main 10 HDR (PQ/HLG); VideoToolbox writes Main 8-bit SDR; no software encoder | `crates/hevc`, `crates/export/src/lib.rs` (Format doc comments), issue #30 |
| AV1 | yes (Main profile, 8/10-bit 4:2:0 + mono, film grain, superres) | none in the code; the `av1` export format is offered only where a hardware encoder registers one | `crates/av1`, `crates/export/src/lib.rs` |
| VP8 / VP9 | yes (VP9: profiles 0–3, 8/10/12-bit, 4:2:0–4:4:4); both also read from MP4 | none | `crates/vp8`, `crates/vp9` |
| Apple ProRes | yes (Proxy…4444 XQ) | yes (presets 422/LT/HQ/4444/4444 XQ; format doc: "422 HQ unless the settings pick another flavour") | `crates/prores`, `crates/export/src/presets.rs` |
| Avid DNxHD/HR | yes (ST 2019-1, all CIDs) | yes (DNxHR in MOV/MXF) | `crates/dnx` |
| APV (RFC 9924) | yes | yes (422-10/422-12/444-10/444-12 profiles) | `crates/apv` |
| MJPEG | yes | yes | `crates/codecs` (AVI/QuickTime), `crates/export` |
| MPEG-1 / MPEG-2 video | yes | none | `crates/mpeg2v`, `crates/codecs/src/mpeg.rs` |
| Uncompressed RGB/YUV | yes (AVI) / Y4M | via Y4M only | `crates/codecs/src/{avi,y4m}.rs` |
| DNG / CinemaDNG | yes (TIFF container, uncompressed + lossless JPEG) | none | `crates/dng` |

Not decodable: DivX/Xvid (MPEG-4 Part 2), DV/DVCPRO, camera RAW other than DNG, HEIF/HEIC, PSD, JPEG 2000.
10-bit / 4:2:2 camera H.264 and HEVC need OS hardware decode — no software fallback (`docs/gaps.md` G3).

## Audio codecs

Decode: AAC-LC, AC-3, **E-AC-3 (partial — independent substream, 5.1 core; no AHT, enhanced coupling or 7.1
dependent substreams: `docs/codec-parity.md:45`; the README's "Not yet: … E-AC-3" line is imprecise)**, Opus
(SILK/CELT/hybrid/multistream), Vorbis, MP1/MP2/MP3, FLAC, ALAC, PCM, WAV/BWF. Evidence: `crates/ac3`
(AC-3 + E-AC-3, ATSC A/52 incl. Annex E), `crates/codecs/src/audio.rs`.
Encode (`crates/export/src/lib.rs`): AAC-LC (MP4/MOV, `.m4a`, ADTS `.aac`), PCM (WAV/AIFF/MOV/MXF),
FLAC (RFC 9639, `flacLevel` 0–8), and the audio inside H.264/HEVC/ProRes/DNxHR/APV/MJPEG exports.
MP3 is **read-only** (`docs/file-format-parity.md` audio table).

## Still images and sequences

Read: PNG, JPEG, GIF, WebP, TIFF, BMP, TGA (incl. RLE/colour maps), DPX (luma/RGB/RGBA, 8–16-bit, packed
10/12-bit, Y'CbCr), OpenEXR (scan-line: none/RLE/ZIPS/ZIP/PXR24, half/float/uint), Radiance HDR, DNG.
Animated GIF and APNG import as clips with transparency (`crates/media/src/animated.rs`).
Write (as numbered sequences): PNG, TIFF, BMP, JPEG, TGA, DPX (10-bit), OpenEXR (half float, linear;
uncompressed/RLE/ZIPS/ZIP, or `alpha: true` for RGBA), plus animated GIF (`Format` enum,
`crates/export/src/lib.rs:64-133`).
No PSD, PIZ/B44/DWA EXR, HEIC.

## Captions and subtitles

`crates/captions/src/`: `srt.rs`, `vtt.rs`, `scc.rs`, `mcc.rs` (608+708), `stl.rs` (EBU STL), `ttml.rs`
(TTML/IMSC1/DFXP), `cea608.rs`, `burn.rs` (layout + burn-in). Seven import/export formats — the README's
captions bullet names only SRT/WebVTT/SCC, but the `Format` enum (`crates/captions/src/lib.rs:34-47`) has all
seven, plus Teletext/CEA-608/CEA-708 caption *tracks*.
`captions.import` auto-detects by extension and content; `captions.export` takes
`format: "srt|vtt|scc|mcc|stl|ttml|dfxp"` or infers it from the path, plus `track` and `dropFrame`
(`crates/engine/src/captions.rs`). CEA-608/708 embedded in a video stream are **not** read or written;
use burn-in (`burnCaptions: true`) or a sidecar (`captionSidecar: "srt"|"vtt"`).
New in v0.10.0: TTML tick timing — an absent `ttp:tickRate` with `ttp:frameRate` present now derives a
rational ticks-per-second (effective frame rate × subFrameRate), so 29.97-based TTML is frame-exact
(`crates/captions/src/ttml.rs`, `crates/captions/README.md` "TTML tick timing").

## Project file — `.fcproj`

- UTF-8 JSON envelope: `{"format": "filmcraft.project", "schema_version": 15, "generator": …, "project": {…}, "view": {…}}`
  (`crates/format/src/lib.rs:62-66`). **The example in `docs/project-files.md:11` still shows 13 — stale; the
  code writes 15** (14 migrations, `MIGRATIONS` = v1→v2 … v14→v15). Compact on write.
- Reading: migrations `MIGRATIONS[i]` upgrade v*i+1* → v*i+2*; the current build reads **every version from 1
  to 15**; newer versions are refused with an explicit message (`docs/project-files.md:79-86`).
- `view` (open sequences, active sequence, zoom/scroll/playhead per sequence) sits beside the project, is not
  undoable and does not dirty the project.
- Media is by path only; each item also stores a size + first/last-MiB fingerprint (`MediaClip::identity`) used
  by relinking.
- Writes are atomic (temp in the same directory → fsync → rename → fsync dir) — projects, auto-saves, recovery
  snapshots, preferences (`docs/project-files.md:88-99`).
- Stored paths from documents are opened only when local or on the document's own network share
  (`crates/engine/src/doc_path.rs`, built on `craft-docpath`); other paths become offline items.

Related files: auto-saves `Auto-Save/<name>-<timestamp>.fcproj`; recovery
`Recovery/<started>-<pid>[-n]/{snapshot.fcproj,session.json,lock}`; preferences `<data dir>/preferences.json`
(schema version 2; new in 0.10.0: `appearance.animations`); effect presets `<data dir>/effect-presets.json`;
user export presets `<data dir>/export-presets.json`; graphics templates `.fcgt`; label colour presets
`<data dir>/Label Presets/*.json`.

## Interchange

| Format | Extensions | Import | Export | Module |
|---|---|:--:|:--:|---|
| Final Cut Pro 7 XML (`xmeml` v4/v5) | `.xml` | yes | yes | `crates/interchange/src/fcp7.rs` |
| FCPXML 1.9–1.11 | `.fcpxml`, `.fcpxmld` | yes | yes | `fcpxml.rs` |
| OpenTimelineIO | `.otio` | yes | yes | `otio.rs` |
| CMX 3600 EDL | `.edl` | yes | yes | `edl.rs` |
| AAF (Edit Protocol, MS-CFB) | `.aaf` | yes | yes | `aaf/` (`crates/cfb`) |
| OMF Interchange 2.0 | `.omf`, `.omfi` | yes | yes | `omf/` |
| Avid Log Exchange | `.ale` | no | yes | `ale.rs` |
| Markers CSV | `.csv` | – | yes | `crates/engine/src/marker_export.rs` (100 000-marker / 16 MiB caps) |

Unchanged since v0.9.0. Format detection sniffs content (AAF/OMF structured storage, `<xmeml`/`<fcpxml`
headers) before trusting the extension (`crates/interchange/src/lib.rs`). Imports merge as one undoable step
and return a report of everything that could not be represented. AAF/OMF have never been validated in
Media Composer / Pro Tools (`docs/gaps.md` G15).

## Export formats (`crates/export/src/lib.rs:64-133`)

`h264`, `hevc*`, `av1*`, `prores`, `dnxhr`, `apv`, `mjpeg`, `png`, `tiff`, `bmp`, `jpg`, `tga`, `dpx`, `exr`,
`gif`, `wav`, `aiff`, `aac`, `flac`, `mxf-op1a`, `mxf-opatom` — `*` = offered only when a platform hardware
encoder registers one (`Format::available`, `register_encoder`). Container by format: MP4/MOV (H.264, HEVC,
AV1, ProRes, DNxHR, APV, MJPEG), MXF OP1a (DNxHR, ProRes, H.264 + PCM, start timecode), MXF OP-Atom
(picture + one mono PCM file per channel), numbered stills, GIF, WAV/AIFF/AAC/FLAC.
New in v0.10.0: SDR ProRes/DNxHR/APV MOV/MP4 also write a `colr` sample entry — Apple's media stack reads
colour only from that box (#2142, `crates/export/src/lib.rs:520-532`).

**39 built-in presets** (`crates/export/src/presets.rs:95-190`, count recomputed — the previous skill's "~44"
was an overcount): Match Source – Adaptive High/Medium/Low Bitrate (default first), High Quality 1080p/2160p,
YouTube 1080p/2160p, Vimeo 1080p/2160p, Social Vertical 1080×1920, Apple ProRes 422 HQ/422/LT/Proxy/4444/4444
Alpha/4444 XQ, Avid DNxHR HQ/SQ/LB, APV 422-10/422-12, MXF OP1a DNxHR HQ/ProRes 422 HQ/H.264, MXF OP-Atom
DNxHR, PNG/TIFF/BMP/JPEG/Targa/DPX/OpenEXR Sequences, Animated GIF 640×360, Waveform Audio 48k 16/24-bit,
AIFF, AAC, FLAC.

A format may change the output extension: exporting `out.mp4` as APV writes `out.mp4.mov`
(`apps/filmcraft-cli/src/main.rs`, export path handling) — always read the returned `path`.

## Proxies, ingest, Project Manager

Proxy presets (`docs/project-files.md`): `prores_proxy_quarter` (default), `prores_proxy_half`,
`prores_lt_half`, `h264_quarter`, `h264_half`; written to `<media folder>/Proxies/<name>_Proxy.<ext>`.
Ingest actions: `copy`, `transcode`, `createProxies`, `copyAndCreateProxies` (`project.ingestSettings`).
Project Manager modes `collect` and `consolidate` with `handles` (frames) and transcode presets
`prores_lt`, `prores_hq`, `h264`; `dryRun` returns the plan and disk estimate.
`Export always uses full resolution`, never the proxy (`docs/project-files.md`).

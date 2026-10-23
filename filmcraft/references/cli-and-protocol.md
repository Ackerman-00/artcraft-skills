# FilmCraft CLI, control channel and MCP — reference

Transcribed from the **v0.11.0** source, commit `74242b51d675514da12d9bbf6b331ef2e6399211` (inspected 2026-10-23).
Every flag, tool and method below exists in the code; where a value comes from a doc rather than code, the
path is given. Changes since v0.10.0 are marked **New in 0.11.0**.

## 1. `filmcraft-cli`

Source of truth for the flags: the `HELP` const in `apps/filmcraft-cli/src/main.rs:63-145`. Parser:
`apps/filmcraft-cli/src/args.rs` (options may appear anywhere; `--` ends options; `-V` in the subcommand
position is a version query). `filmcraft-cli --version` prints `filmcraft-cli 0.11.0`.

```
filmcraft-cli [OPTIONS] <SUBCOMMAND> [ARGS]

SUBCOMMANDS
  exec <id> [key=value ...]     run one command; prints its result as JSON
  exec <id> '<json params>'     same, params as one JSON object
  run <script.jsonl | ->        commands, one {"id","params"} per line (# comments ok), in order:
                                file.exportMedia waits for its file before the next line and before
                                exit unless its params say "wait": false
  commands [filter] [--json]    list commands (id, label, shortcut, params)
  describe <id>                 one command as JSON (menu, shortcut, params, enabled now)
  inspect [project|sequence]    project tree or active sequence as JSON (default: both)
  import <file>...              import media into the project
  export <out> [--preset name] [--format f] [--range r] [--start s --end s] [--settings json]
         [--gpu-rendering auto|off] [--scale f] [--quality 0-100] [--no-audio] [--queue] [--allow-offline]
  export --list-presets [query] list export presets (name, category, format) as JSON
  render --seconds S --out f.png [--scale 0.5] [--allow-offline]
  probe <media> [--image-sequence]      media info as JSON (MXF/Ogg/BWF/image-sequence details)
  bench-decode <media> [--frames N]
  mcp                                   MCP server on stdio (headless, or --bridge)
  help | --version

OPTIONS
  --project <cut.fcproj>   open this project first (headless)
  --demo                   open the built-in demo project (headless)
  --save                   save the project back to --project when done
  --save-as <cut.fcproj>   save to this path when done
  --bridge <127.0.0.1:PORT>  send commands to the running app (`filmcraft --control PORT`)
  --data-dir <dir>         FilmCraft data directory for user export presets (headless)
  --keep-going             `run`: report failing lines and continue
  --compact                one-line JSON output
```

Notes (all verified in code):

- `export` always writes through `file.exportMedia` with `wait: true` (or `export.queue.add` with
  `start: true, wait: true` for `--queue`), then prints the result and a stderr line
  `exported <paths> in <s>s` (`apps/filmcraft-cli/src/main.rs:413-477`).
- **New in 0.11.0:** the local backend forces `wait: true` on `file.exportMedia` — for `exec` and for
  every line of `run` — unless the params contain exactly `"wait": false`. The comment says why: the
  process exits after the command, so a background export would never be written (#2342,
  `apps/filmcraft-cli/src/main.rs:171-190`, `crates/automation/src/long_job.rs:18`). A `wait: false`
  export from a one-shot local process can therefore be lost; use it only with `--bridge` or when
  something keeps the process alive.
- `--format` resolves through `Format::from_name` (`crates/export/src/lib.rs:136-162`):
  `h264|hevc|av1|prores|dnxhr|apv|mjpeg|mxf-op1a|mxf-opatom|png|tiff|bmp|jpg|tga|dpx|exr|gif|wav|aiff|aac|flac`,
  plus aliases (`mp4`, `mov`, `dnx`, `mxf`, `opatom`, `jpeg`, `targa`, `openexr`…). Without `--format`,
  `--preset` wins; otherwise the format is guessed from the extension (`format_for`:
  `mp4|m4v`→h264, `mov`→prores, `mxf`→mxf-op1a, `png`, `gif`, `wav`, `tif|tiff`→tiff, `bmp`, `aif|aiff`→aiff,
  `m4a|aac`→aac). An unknown extension without `--format` is a usage error. The `HELP` text abbreviates
  the list — the enum is authoritative.
- `--start`/`--end` imply `range: "custom"` and are forwarded as `startSeconds`/`endSeconds`;
  `--range entire|inOut|workArea`. `workArea` fails when the sequence has no work area, and nothing in
  the app sets one (`crates/engine/src/export_tools.rs:355`). `--no-audio` sets `audio: false`;
  `--settings` is ExportSettings JSON merged over the preset; `--gpu-rendering` sets `gpuRendering`
  (`off|auto`), validated by the export command (`crates/engine/src/export_tools.rs:265-274`).
- Values in `key=value` parse as JSON when possible (`3.5`, `true`, `[1,2]`, `{"a":1}`), else strings;
  dotted keys nest (capped at 64 levels). Numeric options (`--seconds`, `--scale`) must be finite.
- Exit status: `0` success; `1` a command failed, saving failed, or an export/render drew offline media
  without `--allow-offline`; `2` usage error. A closed stdout (`| head`) is not an error.
- `--bridge` refuses `--project`/`--demo`: open projects in the app instead (`exec file.open path=…`).
- `render` is headless-only; with `--bridge` use the MCP `render_frame` tool or `exec ui.*` commands.
- `mcp` accepts only `--bridge`, `--project`, `--demo`, `--data-dir`; any other option is a usage error.
- `probe` needs `--image-sequence` to treat its argument as the first numbered still of a sequence.
- `import` makes paths absolute without resolving symlinks; `import` stores no Windows `\\?\` paths.

## 2. Desktop control channel

`filmcraft --control 9876` (or `FILMCRAFT_CONTROL_PORT=9876`) — loopback only, one JSON object per line in,
one JSON reply per line out. Full table: `docs/control-protocol.md` (unchanged v0.10.0→v0.11.0); transport
`apps/filmcraft/src/control_server.rs`; handlers `crates/ui-egui/src/control.rs`.

| Method | Params | Notes |
|---|---|---|
| `engine.execute` / `ui.menu.invoke` | `{command, params}` | any engine or UI command id |
| `engine.commands` / `ui.menu.list` | – | engine registry / UI menu tree |
| `ui.inspect` | – | tool, workspace, dock, timeline view, playback, fps, settings draft, panels… |
| `ui.elements` | `{prefix?}` | every on-screen interactive element: id, label, rect |
| `ui.set` | `{tool, workspace, mode, theme, focused, playbackRes, timeline:{pps,scroll,fit,thumbnails}, program:{…}, source:{…}, clipDialog:{…}, menuDialog:{…}, panels:{scopes,timecode,reference,events,progress}, export:{…}, projectPanel:{…}, mediaBrowser:{…}, keyframeSelection:[…], settings, gfxTemplates, tts}` | merges into UI state |
| `ui.panel.show` / `ui.panel.close` | `{panel}` | |
| `ui.click` / `ui.move` | `{id}` or `{x,y}`, `button`, `count`, `modifiers` | synthetic pointer input |
| `ui.drag` | `{from, to, steps, modifiers}` | press–move–release |
| `ui.scroll` | `{id|x,y, dx, dy, modifiers}` | wheel/trackpad |
| `ui.key` / `ui.type` | `{key}` (`Cmd+K`, `Space`) / `{text}` | keyboard |
| `ui.timeline.hit` / `ui.timeline.locate` | `{x,y,modifiers?}` / `{clip, edge?}` | hit-testing; `kind` is the trim a press would start |
| `ui.playback` | `{action: play\|stop\|toggle, speed?}` | |
| `ui.screenshot` | `{path?, panel?}` | PNG of the window or one panel; fails after 10 s with no presented frame |
| `ui.resize`, `app.quit` | `{width,height}` / `{}` | `app.quit` (control method) quits without the save prompt; the **command** `app.quit` asks first |
| `ui.focus` | `{}` / `{id}` | `{}` activates the OS window; `{id}` focuses a widget |
| `perf.stats` | – | decode/playback/frames/monitor/ui/process counters (cumulative — diff two readings) |

Rules of thumb (`docs/control-protocol.md`):

- A line that is not a JSON object with a string `method` gets one error reply and the connection is
  closed (also for invalid UTF-8 and lines over 4 MiB — an HTTP request cannot smuggle a command in).
- Max 16 concurrent connections; **no authentication** — enable the port only while you need it.
- Started with `--control`, the app opens without activating itself and UI requests bring the window
  forward without making it key; only `ui.focus {}` activates it. `--control-input-only` (needs
  `--control`) ignores real keyboard, pointer, file drops and menu commands — **New in 0.11.0:** except
  `app.quit`, so Quit still works (`crates/ui-egui/src/lib.rs:1849`).
- Commands that act on a selection are disabled until something is selected, unless you name targets
  (`clips`/`clip`, `items`/`item`); naming targets leaves the selection alone.
- Tracks are ids or names (`"V1"`, `"A2"`); naming a missing track is an error, never a fallback track.
- `ui.elements` describes the last rendered frame; after a layout change, retry on the next frame.

## 3. MCP server

`filmcraft-cli mcp` (stdio). Headless: `--demo` or `--project cut.fcproj` (neither = empty project), plus
`--data-dir`. Bridge: `--bridge 127.0.0.1:9876` to the running app. `.mcp.json` registers both, pointing
at `target/release/filmcraft-cli`.

Tools — **17**, unchanged from v0.10.0 (`crates/automation/src/server.rs:317-560`, `docs/agents.md:57-77`):

| Tool | Mode | Purpose |
|---|---|---|
| `command_list` | both | every command: id, label, menu, shortcut, params, enabled now (`filter`, `enabled_only`) |
| `command_run` | both | run one command `{id, params}`; edits are undoable |
| `command_batch` | both | `{steps:[{id,params?}], stop_on_error?}` → `{completed, failed, results}` |
| `doc_inspect` | both | project tree + active sequence in one call |
| `render_preview` | both | same as `render_frame` |
| `project_inspect` | both | bins and items with ids, types, durations; active sequence |
| `sequence_inspect` | both | tracks, clips (`start`/`end`, `sourceIn`/`sourceOut`, `speed`, `reverse`, `gainDb`), effects, transitions, markers, playhead, selection |
| `media_import` | both | import files by absolute path (`paths`, optional `bin`, `image_sequence`) |
| `render_frame` | both | PNG of the program frame at `seconds` (headless renders; bridge screenshots the Program monitor); read-only |
| `ui_inspect` | bridge | UI state: tool, workspace, panels, zoom, playback, fps |
| `ui_elements` | bridge | on-screen interactive elements with id, label, rect (`prefix` filter) |
| `ui_click` | bridge | click by `id` or `x`,`y`; `button`, `count`, `modifiers` |
| `ui_drag` | bridge | press–move–release between points or element ids |
| `ui_key` | bridge | key or shortcut: `Space`, `Cmd+K`, `Shift+Delete` |
| `ui_type` | bridge | type text into the focused field |
| `ui_screenshot` | bridge | PNG of the window or one `panel` |
| `ui_control` | bridge | call any control-channel method directly (`ui.set`, `ui.scroll`, `ui.timeline.locate`, …) |

Resources: `filmcraft://document`, `filmcraft://commands` (both `application/json`).

Mode split: `command_*`, `doc_inspect`, `project_inspect`, `sequence_inspect`, `media_import`,
`render_preview`, `render_frame` work headless and bridged; `ui_*` need the bridge (a live window).

Behaviour worth relying on:

- Every tool carries `title` + `readOnlyHint`/`destructiveHint`/`idempotentHint`/`openWorldHint`.
- Unknown tool arguments are `-32602` errors naming the accepted ones; unknown lines are `-32700` and the
  server keeps serving; a panicking command is reported as `internal error: …` and the session stays usable.
- `command_batch` runs `{steps:[{id,params?}], stop_on_error?}` (default stop) and returns
  `{completed, failed, results}`; each edit is its own undo step.
- `doc_inspect` pins `sequence.inspect` to the `activeSequence` id it just reported, so the pair is
  consistent even if tabs switch mid-call (`crates/automation/src/server.rs:288-298`).
- Long exports: `command_run {"id":"file.exportMedia","params":{…,"wait":true}}` runs as a background job,
  reports `notifications/progress` when the request carried `_meta.progressToken`, and
  `notifications/cancelled` stops the encode, deletes partial output and sends no response. Without
  `wait`, the result is `{job, path, poll: "jobs.list", cancel: "jobs.cancel"}`. `jobs.list` carries
  `progress`, `etaSeconds`, `finished`, `result`; `export.queue.list` lists the Export Queue only
  (`crates/automation/src/long_job.rs`, `crates/engine/src/export_tools.rs:546-556`,
  `docs/agents.md:105-132`).
- Headless MCP is **not** confined to a folder; any option other than the four above is rejected (exit 2).

Typical agent loop (`docs/agents.md`): `project_inspect` / `sequence_inspect` → ids → `command_run` →
`render_frame` or `ui_screenshot` → inspect → `edit.undo` if wrong.

## 4. Commands worth memorising

Project/media: `file.newProject`, `file.open`, `file.save`/`file.saveAs`/`file.saveCopy`/`file.revert`,
`file.newSequence`, `file.newSequenceFromClip`, `file.import`, `file.importImageSequence`,
`file.listAutoSaves`, `file.recoveryList`, `file.recover`, `file.projectManager`, `media.status`,
`media.findMissing`, `media.relink`, `media.autoRelink`, `media.search`, `media.makeOffline`,
`media.createProxies`/`attachProxies`/`toggleProxies`, `project.ingestSettings`,
`project.notes`/`project.setNotes`.

Editing: `source.insert`, `source.overwrite`, `sequence.lift`, `sequence.extract`, `sequence.addEdit`,
`timeline.move`, `timeline.razor`, `timeline.place`, `timeline.setTrack` (name, label, mute, solo, lock),
`edit.undo`, `edit.redo`, `edit.pasteInsert`, `trim.selectEditPoint`, `trim.shuttle`, `trim.tick`,
`trim.shuttleStop`, `clip.replaceFromBin`, `clip.audioGain`, `clip.makeSubclip`, `clip.synchronize`,
`clip.mergeClips`, `clip.sceneEditDetection`, `markers.*`, `markers.exportCsv`.

Look/audio/text: `effects.list`, `effects.apply`, `effects.setParam`, `lumetri.setInputLut`,
`lumetri.setLook`, `lumetri.setSection`, `lut.import`, `mixer.*`, `clipMixer.set`, `essentialSound.*`,
`captions.*`, `transcript.*`, `tts.*`, `graphics.*` (templates: `graphics.template.list/apply/export/install/remove/set`, `file.exportGraphicsTemplate`).

Output: `file.exportMedia`, `file.exportFrame`, `export.queue.add/start/list/stop/cancel/retry/remove/move/clear`,
`export.quick`, `export.presets.*`, `export.formats` (per-format `available`), `export.resolve`,
`jobs.list`, `jobs.cancel`, `perf.stats`, `file.exportEdl`, `file.exportFcp7Xml`, `file.exportFcpxml`,
`file.exportOtio`, `file.exportAaf`, `file.exportOmf`, `file.exportAle`, `file.importAaf` (also accepts OMF).

UI/app: `tool.*`, `playback.*`, `view.*` (incl. `view.resetInterfaceZoom`), `window.workspace.*`,
`window.panel.*`, `window.dockPanel`, `window.floatPanel`, `window.dockAction`,
`app.settings.<category>` (general, appearance, audio, audioHardware, autoSave, color, graphics, labels,
media, mediaAnalysis, mediaCache, memory, playback, plugins, timeline, trim),
`prefs.get`/`prefs.set`/`prefs.reset`/`prefs.schema`, `shortcuts.*`, `command.list`.

`file.exportMedia` parameters (registry, `crates/engine/src/commands.rs:1599-1603`):
`path` (required), `preset`, `settings` (ExportSettings JSON), `format`, `audioCodec: auto|aac|pcm|flac`,
`flacLevel` 0–8, `width`, `height`, `fps`, `bitrateKbps`, `bitrateMode: cbr|vbr1Pass|vbr2Pass|crf`, `crf` 0–51,
`hardwareEncoding: off|auto`, `scale`, `audio`, `quality` 0–100, `burnCaptions`, `alpha`,
`exrCompression: none|rle|zips|zip`, `captionSidecar: srt|vtt`, `loudnessLufs`, `proresProfile`,
`dnxProfile`, `apvProfile`, `mxfVideoCodec`, `sequence`, `range: entire|inOut|workArea|custom`,
`startSeconds`, `endSeconds`, `wait` (default **false** at the engine; the local CLI forces true).

## 5. Building (developers)

```sh
cargo build --release -p filmcraft -p filmcraft-cli   # app + CLI (packaging/macos/package.sh)
cargo run --release -p filmcraft -- --control 9876
cargo xtask ci        # fmt, lints, tests, layering, asset attribution, wasm check
cargo xtask web       # WebAssembly site into target/web/dist
cargo xtask parity    # menu/effects parity against a local plan/premiere reference
```

`CRAFT_FONTS_DIR=<craft-fonts checkout>` adds the shared font set (optional; official releases embed it —
`packaging/macos/package.sh`, README "Get started"). Release builds pass no `--features`, so `whisper` and
`neural-voices` are **off** in shipped binaries.

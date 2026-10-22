# DesignCraft agent surfaces at a glance

All paths are repo-relative to https://github.com/storytold/designcraft.

Verified at tag v0.11.0, commit `4d62a501c18fb3cf453c6e9f19f15cbc9c558e26`, 2026-10-22.

## 1. CLI (`designcraft-cli`)

Source: `apps/designcraft-cli/src/main.rs` (module doc lines 3–20; the `USAGE` const at line 42;
subcommand dispatch in `main`). Not inside the macOS `.app` — install the separate
`designcraft-cli-<ver>-macos-*.zip` release asset, `cargo install --path apps/designcraft-cli
--locked` (`docs/mcp.md` §From source), or build `cargo build --release -p designcraft-cli`
(`docs/mcp.md`; `packaging/macos/package.sh`).

```text
designcraft-cli run [--in FILE | --sample] [--cmd ID[=JSON]]... [--page N] [--scale S]
                    [--pdf-options JSON] [--export OUT] [--all-pages DIR]
designcraft-cli commands [FILTER]        # all commands as JSON
designcraft-cli describe COMMAND         # label, menu, shortcut, params for one command
designcraft-cli script [FILE|-] [--in FILE | --sample] [--connect PORT]
                       [--save OUT] [--export OUT] [--keep-going]
designcraft-cli app [--port PORT] COMMAND [JSON]
designcraft-cli app [--port PORT] --method METHOD [JSON]
designcraft-cli mcp [--connect PORT] [--sample]
                    [--automation-read-root DIR] [--automation-write-root DIR]
designcraft-cli perf [--pages N] [--frames N] [--chars N] [--images N] [--runs N] [--strict]
designcraft-cli bench FILE [--runs N]
designcraft-cli validate-pdf FILE.pdf    # built-in PDF/X-4 checks
designcraft-cli links
designcraft-cli --version
```

- `run`: `--page`, `--scale` and `--pdf-options` apply to the exports that follow them; one after
  the last export is an error, and a bad export extension fails before anything runs.
  `--export` writes the type its extension names: `.png` or no extension (a page; `.jpg`/`.jpeg` →
  JPEG), `.pdf`, `.designcraft` (Save As), `.idml`, `.epub`, `.pptx`, `.html`/`.htm`, and
  `.rtf`/`.txt` (the story being edited or of the selected frame); any other extension is an error.
  `--cmd id={"json"}` runs commands with `$N.path` result references; results print as JSON, and a
  params key the command's description doesn't name is an error. `--all-pages DIR` writes
  `page-001.png`… at the current scale.
- `app` defaults to port 7979 (`--port`/`--connect`); `--method` calls any control-channel method.
- `mcp`: the two automation roots confine every file the agent's commands read (open, placed images,
  data sources, libraries) and write (save, export, package), links followed; a root left out grants
  none of its access. They confine the in-process server only, so combining them with `--connect`
  is an error.
- `script --save` is Save As after the script succeeds; `--export` routes like `run` but
  `.designcraft` writes a copy (`file.saveACopy`).
- Exit status is non-zero on failure; `script --keep-going` records errors per step instead.
- `perf`/`bench` measure budgets on a synthetic stress document or a real file
  (`apps/designcraft-cli/src/perf.rs`).

## 2. Script syntax (`designcraft-cli script`)

Source: `apps/designcraft-cli/src/main.rs` `SCRIPT_HELP` (lines 45–75); `crates/engine/src/script.rs`;
`docs/agents.md`.

```text
command.id {"param": 1}            # one step per line; also command.id={json} or bare id
{"command": "command.id", "params": {...}}    # JSON-lines form, or a JSON array
# comment / // comment             # blank lines skipped; UTF-8 ± BOM; LF or CRLF
```

- `"$N.path"` = value at `path` of step N's result (0-based; comments/blank lines are not
  steps); `"$last.path"` = previous step; `"${N.path}"` interpolates inside a longer string;
  `"$$"` writes a literal `$`; any other string starting with `$` stays as written (GREP groups
  like `"$1-$2"`, `"$$1"`).
- Text parameters: `\n` = new paragraph, `\u2028` = forced line break (`\u000b`, Word's line
  break, is read as one too), `\t` = tab.
- Result: `{"completed": n, "results": [...]}`, plus `failedIndex`/`failedCommand`/`error` on
  failure; `--keep-going` converts failures to `{"error": …, "command": …}` results.
- MCP `batch` accepts the same script text or `commands: [{command, params}]`.
- `script.run` (the Scripts panel) runs the same text as one undo step and restores the document,
  selection and history when a step fails, so a half-run script never sticks
  (`crates/engine/src/cmd/scripts.rs`).

## 3. MCP tools (`designcraft-cli mcp`)

Source: `crates/mcp` (`tools.rs` — `tool_definitions` :83, `dispatch` :555; `server.rs`, `headless.rs`,
`backend.rs`); `docs/mcp.md`.
Protocol: newline-delimited JSON-RPC 2.0 on stdin/stdout (`2025-06-18`, also `2025-03-26`,
`2024-11-05`); logs on stderr. An argument a tool doesn't take, and a command `params` key the
command doesn't name, are invalid-params errors; `execute` and `batch` check every step
before the first runs.

- Headless: in-process `designcraft_engine::Session`, starts with an empty Letter document;
  `--sample` opens the sample magazine. `--automation-read-root`/`--automation-write-root` confine
  file access (in-process only; see §1).
- Connected: `--connect PORT` (or `HOST:PORT`) proxies to the running app; window tools
  (`screenshot`, `click`, `drag`, `menu_list`, `ui_inspect`, `ui_set`, `dialog_*`) return an
  error in headless mode (`docs/mcp.md` "Modes"). A failed request is not resent: inspect the
  document before retrying (`docs/mcp.md`).

| Tool | Purpose |
|---|---|
| `list_commands` | every command (id, label, menu, shortcut, params, enabled), with `filter` / `enabledOnly` |
| `execute` | run any command `{command, params}` |
| `batch` | ordered commands or script text; stops at first error (`failedIndex`) |
| `inspect_document` | pages, spreads, items, stories (overset), layers, styles, swatches, selection |
| `get_story` / `set_story_text` | read a story (text, frames, paragraphs, lines, overset) / replace its text |
| `new_document` | `file.new` presets or `sample: true` |
| `open_document` / `save_document` | native `.designcraft` files |
| `place_image` | image from path or base64 into a frame or a new one |
| `render_page` / `export_png` | page → image content / file (JPEG by extension) |
| `screenshot` | whole window (connected only) |
| `select_tool`, `pointer`, `key`, `type_text`, `ime` | tools and input events (`pointer` events: `down`/`drag`/`up`/`move`/`doubleclick`, `space: doc\|screen`, per-event `mods`/`clicks`; `ime` preedit/commit) |
| `click`, `drag`, `menu_list`, `ui_inspect`, `ui_set`, `dialog_set/confirm/cancel` | connected only |

Resources: `designcraft://document`, `designcraft://commands` (`docs/mcp.md`). `app.links` returns
the community links; `help.about {tab?}` opens the About window in the running app.

## 4. Control channel (`designcraft --control PORT`)

Source: `apps/designcraft/src/control_server.rs` (`MAX_LINE` :22 = 4 MiB, `MAX_CONNECTIONS` :24 = 16);
`crates/ui-egui/src/control.rs` (`handle_request` :149); `docs/control-protocol.md`. Start with
`designcraft --control PORT` or `DESIGNCRAFT_CONTROL_PORT`. JSON lines on `127.0.0.1`; one
request/one reply per line (the reply echoes the request's `id`).
Rules that matter: only requests are read; a line that is not a JSON object with a string `method`
gets one error reply and the connection is closed, so anything after it on that connection never
runs; max 16 connections (further ones get an error line); lines are capped at 4 MiB; no
authentication (enable only while in use); the web build has no control channel. Clients that get
an error reply should reconnect (`docs/control-protocol.md`).

| Method | Params / purpose |
|---|---|
| `engine.execute` / `ui.menu.invoke` | `{command, params}`; `ui.menu.invoke` without params acts like choosing the menu item (opens dialogs); an unknown params key is an error |
| `engine.commands` | full command list |
| `document.inspect` | pages, spreads, items, stories (overset), styles, swatches, selection, `canUndo` |
| `ui.inspect` | tool, UI state, view, canvas rect, window, documents, dialog, perf |
| `ui.menu.list` / `ui.tool.list` / `ui.tool.select` | menus / tools |
| `ui.pointer` | `{events:[{kind: down\|drag\|up\|move\|doubleclick, x, y, space? ("screen"\|"canvas"; default doc points), clicks?, mods?}], mods?}` through the active tool; returns selection, tool, cursor |
| `ui.key` / `ui.text` | `{key, shift?, alt?, cmd?, ctrl?}` synthetic key / `{text}` inserts at the explicit caret, or types into a focused field or dialog |
| `ui.ime` | `{preedit?, active?: [start, end], commit?}` input-method events as the system IME sends them (marked text in place, then the committed text) |
| `ui.paste` | `{text}`: what Ctrl/Cmd+V delivers (text, or SVG markup as editable paths); the system clipboard is never read |
| `ui.move` / `ui.click` / `ui.drag` | real egui pointer input in screen points (reaches widgets/menus/dialogs); `button?`, `count?` (1–255), `steps?` (drag, default 8) |
| `ui.set` | brightness, panel, status, rulers, guides, frameEdges, baselineGrid, documentGrid, textThreads, screenMode, zoom, page (1-based), fit, controlBar, closePanel, dockExpanded |
| `ui.dialog.open` / `.set` / `.confirm` / `.cancel` | open a dialog by id (`{id, fields?}`) and fill/close it |
| `ui.resize` / `ui.focus` | window size / focus |
| `ui.screenshot` / `ui.render` | window PNG / headless page render (page 0-based, scale, bleed; PNG, or base64 without a path) |
| `app.open` / `app.save` / `app.export` | files (export = PNG of a page) |
| `app.quit` | quits without asking; the ⌘Q command asks |

Notes: default shortcuts owned by the macOS native menu (incl. Command-Z) are skipped by the
egui shortcut handler; after a drag wait for both the expected document state and
`document.inspect.canUndo` before testing undo; `ui.key` does not synthesize Cocoa menu events —
use `ui.menu.invoke` to test a menu command (`docs/control-protocol.md`). `ui.click`/`ui.drag`
validate the whole gesture before queuing input: at most 10,003 pending events; a click uses
1 + 2×`count`, a drag 1 + `steps` + 2×`count`; over-budget requests return `ok: false` and leave
the queue unchanged.

Panel docking is driven by UI commands through `engine.execute` (`docs/control-protocol.md` §Shared
panel docking): `window.panel.move {panel, anchor, zone?: tab|center|left|right|top|bottom, before?}`,
`window.panel.float {panel, x?, y?, width?, height?}`, `window.panel.dock {panel, anchor?, zone?,
before?}`, `window.panel.activate {panel}`, `window.panel.close {panel}`, and
`window.panel.layout {action}` with the shared MoveFloating/ResizeSplit/Move/SetStackOpen schema.

Headless window screenshots with no visible window:
`cargo run -p designcraft-ui-egui --example ui_shot -- script.jsonl`
(`crates/ui-egui/examples/ui_shot.rs`; documented in `docs/control-protocol.md`): each line is a
control request, `{"shot": "out.png"}` or `{"steps": n}`; a first line `{"empty": true}` skips the
sample document.

## 5. Coordinates and text offsets

- Points (1/72 in), y down, spread space; page indices for `render_page`/`export_png` are
  0-based; commands that create items take `spread` (body index,
  `{"kind":"parent","index":0}`, or `{"kind":"doc","index":n}`) (`docs/mcp.md`). `pointer`
  events may use `"space": "screen"` (egui points, see `ui_inspect` → `canvasRect`).
- Story text positions are UTF-8 byte offsets (é = 2 bytes; — and は = 3): `anchor`/`focus`,
  `start`/`end`, `pos`, story `length`, overset position; an offset inside a character snaps to
  its start — except in `story.replaceRange`, where it, an `end` past the story, or a crossed
  range is an error that leaves the story unchanged (`docs/mcp.md` "Text offsets").

## 6. Sample commands that create content

| Command | Params (from the command registry) |
|---|---|
| `file.new` | `{preset?, intent?, units?, width?, height?, pages?, startPage?, facingPages?, columns?, gutter?, margins?, bleed?, slug?, title?, primaryTextFrame?}` |
| `file.newSample` | `{}` — multi-page magazine (`crates/engine/src/sample.rs`) |
| `frame.create` | `{spread?, rect: [x0,y0,x1,y1], shape?, content?, sides?, starInset?, text?, caret?, vertical?}` → `{id, story?}` |
| `text.thread` | `{from?, to?, rect?, spread?, autoflow?}` → `{story, from, to, overset, pagesAdded}` |
| `text.unthread` / `text.removeFromThread` | `{frame?, side?}` / `{frame?}` |
| `file.place` | `{path\|base64, name?, frame?, spread?, x?, y?, width?, height?, pdfPage?, pdfCrop?, loadCursor?, layoutPage?, page?, rect?, autoflow?, removeStyles?, styleMap?, styleConflicts?, link?}` — text files and `.xlsx` flow into frames/tables |
| `file.exportPdf` | `{path?, pages?, flatten?, spreads?, fullScreen?, bookmarksPanel?, pageLayout?, view?, advanceSeconds?, bleed?, marks?, standard?: "none"\|"x4"\|"a2b", compressImages?, tagged?, media?, title?, author?}` → `{path, bytes, pages, warnings}` |
| `file.exportEpub` / `file.exportFixedEpub` | `{path?, title?, author?, language?, identifier?, coverImage?, tocTitle?, cover?, embedFonts?, fixedLayout?}` / `{path?, title?, author?, language?}` |
| `file.exportPptx` / `file.exportHtml` | `{path?, pages?, lineBreaks?: keep\|reflow, rasterize?, embedFonts?, title?, author?}` / `{path?, title?, language?}` |
| `file.exportIdml` | `{path?, embedImages? (default true)}` — also `file.exportText`, `file.exportXml`, `file.printBooklet` |
| `object.qrCode` | `{type?: url\|text\|sms\|email\|vcard, content, …, color?, rect?, spread?}` → `{id, content}` (`crates/engine/src/cmd/qr.rs`) |
| `math.insert` / `math.svg` | `{latex, size?, x?, y?, spread?}` — LaTeX subset inline or as a frame / `{latex, size?}` → `{svg, width, height}` (`crates/engine/src/cmd/mathexpr.rs`) |
| `color.extractTheme` → `swatch.addColorTheme` | `{id?}` → up to five colours from a placed raster (≤16 Mpx; no PDF/SVG) / `{colors, name?}` as one undoable colour group (`crates/engine/src/cmd/color_theme.rs`; `docs/agents.md`) |
| `color.settings` / `color.loadProfile` / `color.convert` | RGB/CMYK working spaces, intent, black-point compensation; ICC `.icc`/`.icm`; convert through the working spaces (`crates/engine/src/cmd/colorsettings.rs`) |
| `data.source.select` → `data.merge` | link CSV/TSV/xlsx, then merge into a new document; the template is left unchanged and the old `spread` parameter is an error (`docs/agents.md`) |
| `font.reload` | `{}` — re-read fonts installed, edited or removed while running; documents recompose (`crates/engine/src/cmd/fonts.rs`) |
| `layout.parents.delete` | `{id}` — delete a parent page; overrides survive as plain objects, undo restores everything (`crates/engine/src/cmd/layout.rs`; `docs/agents.md`) |

Ground truth for params: `designcraft-cli describe <command-id>` — the `params` field is the
command's own documentation string (`crates/engine/src/cmd/mod.rs` `CommandSpec.params`); the
automation boundaries validate keys against it (`crates/engine/src/cmd/params.rs`).

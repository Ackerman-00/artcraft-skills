# DeckCraft — commands, shortcuts, control methods, MCP tools and file formats (agent reference)

**Pin:** tag `v0.8.0`, commit `22db9261f9d1a214c296fd390173130c45d76d66` — the code shipped in DeckCraft 0.8.0.
**Verified:** 2026-10-18 against the working tree at that commit. All citations are repo-relative (`path:line`).

---

## Command families

Everything DeckCraft does is a command. A command is a `CommandSpec` with
`id`, `label`, ribbon/menu place, optional shortcut, a parameter doc, an enabled check and a run
function (`crates/engine/src/cmd/mod.rs:44-58`). Ids follow PowerPoint's ribbon and menu structure
(`crates/engine/src/cmd/mod.rs:1`).

The `cmd!` macro has three forms (`crates/engine/src/cmd/mod.rs:148-158`):

- `cmd!(id, …)` — journaled and undoable (an ordinary edit);
- `cmd!(noundo id, …)` — journaled, not undoable (navigation, save, playback, settings);
- `cmd!(query id, …)` — neither journaled nor undoable (read-only queries).

`command_specs()` (`crates/engine/src/cmd/mod.rs:161-195`) builds the registry once, concatenating
the per-family `specs()` functions in this order (lines 165-192):
file, edit, slide, reuse, insert, smartart, shape, background, picture_style, recolor, arrange,
selection, merge, points, text, format, design, ideas, transition, animation, table, find, review,
inspect, media, artistic, zoom, compress. That order is also the tie-break order when two commands
share a shortcut (see `Cmd+Shift+V` below). `Session::execute` is the single dispatch path every
surface uses — UI, keyboard, CLI, control channel, MCP
(`crates/engine/src/lib.rs:579-581`, panic-guarded via `crates/engine/src/guard.rs`).

**Total: 320 commands**, counted as `cmd!(…)` invocations across `crates/engine/src/cmd/*.rs`:
**228** ordinary + **56** `noundo` + **36** `query`. Command ids are unique (asserted by a test at
`crates/engine/src/tests.rs:3550`), and `docs/architecture.md:23` reports the same number.

| Family module (`crates/engine/src/cmd/…`) | `specs()` at | Commands | Covers |
|---|---|---|---|
| `file.rs` | 9 | 21 | new, open, save, save as/template, export, info, render, color at, close, properties, AutoRecover, revert, next window |
| `edit.rs` | 13 | 12 | undo/redo, clipboard (cut/copy/paste, paste text), duplicate, delete, select all, deselect |
| `slide.rs` | 12 | 21 | new/duplicate/delete/move/layout/reset/hide/notes/rename, sections, outline import, navigation (go/next/previous/first/last), select slides |
| `reuse.rs` | 17 | 1 | Reuse Slides (insert slides from another presentation) |
| `insert.rs` | 14 | 23 | text box, picture, photo album, table, chart (+ type/data/options), audio, video, WordArt, slide number, date/time, symbol, hyperlink, SmartArt, icons, preset shapes, action buttons/actions |
| `smartart.rs` | 161 | 13 | SmartArt outline (Text Pane), add/promote/demote, layout switching, `smartArt.nodes` query |
| `shape.rs` | 12 | 27 | connect, freeform, ink to shape, sites, move/resize/rotate/flip, adjust, change, smooth corners, fill, line, effects, quick style, rename, alt text, visibility, lock, default, crop, picture adjust/reset/change, media options |
| `background.rs` | 17 | 1 | Remove Background |
| `picture_style.rs` | 12 | 2 | Picture Styles gallery + apply |
| `recolor.rs` | 11 | 3 | Recolor presets + Set Transparent Color + gallery |
| `arrange.rs` | 10 | 19 | order (bring/send), group/ungroup/regroup, align, distribute, rotate, flip, nudge, guides |
| `selection.rs` | 11 | 3 | Selection pane: select, Show All, Hide All |
| `merge.rs` | 21 | 1 | Merge Shapes (union, combine, fragment, intersect, subtract via `op`) |
| `points.rs` | 16 | 7 | Edit Points: enter/exit, add/delete/move point, points query, close/open path |
| `text.rs` | 15 | 15 | text edit/insert/delete/move caret/select, autocorrect, commit, fonts used |
| `format.rs` | 14 | 48 | character formatting (font, size, bold…, caps, case, spacing, language, highlight, shadow/outline/warp, transparency), paragraph formatting (align, RTL, bullets/numbering, indent, line spacing, tabs, columns, direction, anchor, autofit, wrap, margins), ruler state, `font.add`, `font.rescan` |
| `design.rs` | 15 | 24 | themes, variants, colors, fonts, effects, background, slide size, header/footer, masters, handouts, notes master |
| `ideas.rs` | 13 | 2 | Design Ideas gallery + apply |
| `transition.rs` | 12 | 6 | transition set, effect options, apply all, duration, gallery |
| `animation.rs` | 11 | 11 | animation add/set/remove/move, start mode, gallery, `animation.get` |
| `table.rs` | 10 | 21 | rows/columns, merge/split, distribute, cell size, borders, styles, select cells |
| `find.rs` | 12 | 2 | Find, Replace (slide text, table cells, notes) |
| `review.rs` | 11 | 22 | comments, spelling, thesaurus, dictionary, accessibility, revisions, compare, slide show start/end/presenter |
| `inspect.rs` | 10 | 4 | `document.inspect`, `slide.inspect`, `shape.inspect`, `commands.list` |
| `media.rs` | 11 | 8 | play/pause/stop/toggle, seek, GIF play, media info |
| `artistic.rs` | 26 | 1 | Artistic Effects (pencil sketch, blur, grain…, on the CPU) |
| `zoom.rs` | 19 | 1 | Insert ▸ Zoom (Summary/Section/Slide Zoom) |
| `compress.rs` | 14 | 1 | Compress Pictures (downsample to a target resolution) |

Notes for agents:

- List commands with `deckcraft-cli commands [FILTER]`, explain one with
  `deckcraft-cli describe COMMAND` (`apps/deckcraft-cli/src/help.rs:95-115`), or query
  `commands.list` / `engine.commands` at runtime.
- Queries (`query`) are free to call and safe in loops; `noundo` commands change the document but
  cannot be undone — save points (`file.save`, `mark_saved`) discard the document's recovery entry
  (`crates/engine/src/cmd/file.rs:378-390`).
- UI-only commands (views, panes, dialogs, palette) live separately in `UI_COMMANDS`
  (`crates/ui-egui/src/lib.rs:359-415`, 50 entries); they are runnable through
  `engine.commands`/`app.run` in the desktop app but are rejected headlessly (see MCP).

## Verified keyboard shortcuts

Shortcuts come from four sources in code:

1. **Engine command registry** — the `shortcut` field of each `CommandSpec`, matched by
   `shortcut_matches` (`crates/engine/src/keys.rs:10-21`) in `Session::key`
   (`crates/engine/src/keys.rs:51-167`; lookup at line 161). `Cmd` matches Command on macOS and
   Ctrl elsewhere; `Alt` matches Option/Alt.
2. **UI-only shortcuts** — matched in `menus.rs::ui_shortcut`
   (`crates/ui-egui/src/menus.rs:11-79`) and declared in `UI_COMMANDS`
   (`crates/ui-egui/src/lib.rs:359-415`).
3. **Implicit key handling** — text editing and navigation keys hard-wired in `Session::key`
   (`crates/engine/src/keys.rs:51-167`, `text_key` at 173-211).
4. **Slide show keys** — `crates/ui-egui/src/show.rs:425-519` (`keyboard`).

**57 engine commands carry a shortcut.** The two lists (engine + UI) overlap deliberately: the UI
intercepts some keys before the engine.

### Engine registry shortcuts (57)

| Command | Keys | Source |
|---|---|---|
| `file.new` | Cmd+N | `crates/engine/src/cmd/file.rs:11` |
| `file.open` | Cmd+O | `crates/engine/src/cmd/file.rs:21` |
| `file.save` | Cmd+S | `crates/engine/src/cmd/file.rs:32` |
| `file.saveAs` | Cmd+Shift+S | `crates/engine/src/cmd/file.rs:33` |
| `file.close` | Cmd+W | `crates/engine/src/cmd/file.rs:56` |
| `window.next` | Cmd+` | `crates/engine/src/cmd/file.rs:71` |
| `edit.undo` | Cmd+Z | `crates/engine/src/cmd/edit.rs:15` |
| `edit.redo` | Cmd+Y | `crates/engine/src/cmd/edit.rs:16` |
| `edit.cut` | Cmd+X | `crates/engine/src/cmd/edit.rs:17` |
| `edit.copy` | Cmd+C | `crates/engine/src/cmd/edit.rs:18` |
| `edit.paste` | Cmd+V | `crates/engine/src/cmd/edit.rs:19` |
| `edit.pasteText` | Cmd+Shift+V | `crates/engine/src/cmd/edit.rs:37` |
| `edit.duplicate` | Cmd+D | `crates/engine/src/cmd/edit.rs:38` |
| `edit.delete` | Delete | `crates/engine/src/cmd/edit.rs:39` |
| `edit.selectAll` | Cmd+A | `crates/engine/src/cmd/edit.rs:40` |
| `edit.deselect` | Escape | `crates/engine/src/cmd/edit.rs:41` |
| `format.bold` | Cmd+B | `crates/engine/src/cmd/format.rs:18` |
| `format.italic` | Cmd+I | `crates/engine/src/cmd/format.rs:19` |
| `format.underline` | Cmd+U | `crates/engine/src/cmd/format.rs:20` |
| `format.strikethrough` | Cmd+Shift+X | `crates/engine/src/cmd/format.rs:29` |
| `format.superscript` | Cmd+Shift+= | `crates/engine/src/cmd/format.rs:38` |
| `format.subscript` | Cmd+= | `crates/engine/src/cmd/format.rs:39` |
| `format.grow` | Cmd+Shift+. | `crates/engine/src/cmd/format.rs:42` |
| `format.shrink` | Cmd+Shift+, | `crates/engine/src/cmd/format.rs:43` |
| `format.case` | Shift+F3 | `crates/engine/src/cmd/format.rs:64` |
| `format.clear` | Cmd+Space | `crates/engine/src/cmd/format.rs:83` |
| `format.fontDialog` | Cmd+T | `crates/engine/src/cmd/format.rs:84` |
| `format.alignLeft` | Cmd+L | `crates/engine/src/cmd/format.rs:130` |
| `format.alignCenter` | Cmd+E | `crates/engine/src/cmd/format.rs:131` |
| `format.alignRight` | Cmd+R | `crates/engine/src/cmd/format.rs:132` |
| `format.justify` | Cmd+J | `crates/engine/src/cmd/format.rs:133` |
| `format.indent` | Tab | `crates/engine/src/cmd/format.rs:152` |
| `format.outdent` | Shift+Tab | `crates/engine/src/cmd/format.rs:153` |
| `format.painter` | Cmd+Shift+C | `crates/engine/src/cmd/format.rs:213` |
| `format.painterApply` | Cmd+Shift+V | `crates/engine/src/cmd/format.rs:214` |
| `arrange.bringToFront` | Cmd+Shift+] | `crates/engine/src/cmd/arrange.rs:24` |
| `arrange.bringForward` | Cmd+] | `crates/engine/src/cmd/arrange.rs:25` |
| `arrange.sendBackward` | Cmd+[ | `crates/engine/src/cmd/arrange.rs:26` |
| `arrange.sendToBack` | Cmd+Shift+[ | `crates/engine/src/cmd/arrange.rs:27` |
| `arrange.group` | Cmd+Alt+G | `crates/engine/src/cmd/arrange.rs:37` |
| `arrange.ungroup` | Cmd+Alt+Shift+G | `crates/engine/src/cmd/arrange.rs:38` |
| `arrange.regroup` | Cmd+Alt+J | `crates/engine/src/cmd/arrange.rs:39` |
| `insert.hyperlink` | Cmd+K | `crates/engine/src/cmd/insert.rs:97` |
| `media.play` | Alt+P | `crates/engine/src/cmd/media.rs:13` |
| `comment.add` | Cmd+Alt+M | `crates/engine/src/cmd/review.rs:13` |
| `review.spelling` | F7 | `crates/engine/src/cmd/review.rs:37` |
| `show.fromStart` | Cmd+Shift+Enter | `crates/engine/src/cmd/review.rs:63` |
| `show.fromCurrent` | Cmd+Enter | `crates/engine/src/cmd/review.rs:64` |
| `slide.new` | Cmd+Shift+N | `crates/engine/src/cmd/slide.rs:14` |
| `slide.next` | PageDown | `crates/engine/src/cmd/slide.rs:27` |
| `slide.previous` | PageUp | `crates/engine/src/cmd/slide.rs:28` |
| `slide.first` | Home | `crates/engine/src/cmd/slide.rs:29` |
| `slide.last` | End | `crates/engine/src/cmd/slide.rs:30` |
| `animation.painter` | Alt+Shift+C | `crates/engine/src/cmd/animation.rs:52` |
| `animation.painterApply` | Alt+Shift+V | `crates/engine/src/cmd/animation.rs:61` |
| `text.edit` | Enter | `crates/engine/src/cmd/text.rs:27` |
| `text.delete` | Backspace | `crates/engine/src/cmd/text.rs:60` |

One collision is real: `edit.pasteText` and `format.painterApply` both declare **Cmd+Shift+V**.
Because `command_specs()` lists `edit` before `format` (`crates/engine/src/cmd/mod.rs:165-180`),
the key path resolves to `edit.pasteText`; run `format.painterApply` by id to paste formatting.

### UI-only shortcuts

Declared in `UI_COMMANDS` (`crates/ui-egui/src/lib.rs:359-415`, 15 entries carry a shortcut) and
matched in the UI: `view.gridlines` Shift+F9, `view.guides` Alt+F9, `view.zoomIn` Cmd+=,
`view.zoomOut` Cmd+-, `review.thesaurusPane` Shift+F7, `view.collapseRibbon` Cmd+F1,
`show.start` F5, `app.backstage` Alt+F, `app.closePresentation` Cmd+W, `app.print` Cmd+P,
`app.palette` Cmd+Shift+P, `app.preferences` Cmd+,, `app.pasteSpecial` Cmd+Alt+V, `app.find` Cmd+F,
`app.replace` Cmd+H.

`menus.rs::ui_shortcut` (`crates/ui-egui/src/menus.rs:11-79`) handles these directly and additionally:
Cmd+A over the slides list selects all slides (13-17), F5/Shift+F5 start the show from the start /
current slide and Cmd+Enter / Cmd+Shift+Enter do the same (18-31), Cmd+S save and Cmd+Shift+S Save
As dialog (32-36), Alt+F File tab (38-44), Cmd+P Print page (45-51), Cmd+W close (52-55), Cmd+O
open dialog (56), Cmd+Alt+V Paste Special dialog (57-60), Cmd+Shift+P command palette (61),
Cmd+, preferences (62), Cmd+= / Cmd++ / Cmd+- zoom and Cmd+0 fit (63-65), Cmd+F1 collapse ribbon
(66), Shift+F9 gridlines / Alt+F9 guides (67-68), Cmd+K hyperlink dialog (69-72), Cmd+F find and
Cmd+H replace (73-74).

### Implicit keys in the engine (`crates/engine/src/keys.rs`)

- **While editing text:** Enter = new paragraph, Shift+Enter = line break, Escape = `text.exit`,
  Tab at paragraph start = indent/outdent (else inserts a tab; inside a table Tab = next cell,
  Shift+Tab = previous, and Tab in the last cell adds a row — `crates/engine/src/keys.rs:71-91,288-310`).
  Arrows/Home/End/Backspace/Delete map to `text.move`/`text.delete` with word/line/paragraph
  semantics by platform (`crates/engine/src/keys.rs:171-211`); Cmd+] / Cmd+[ grow/shrink the font (`crates/engine/src/keys.rs:176-183`).
- **A shape selected, not editing:** arrows nudge (`shape.move`) 6 pt, Alt 1 pt (92-104);
  Backspace/Delete = `edit.delete` (105-109); Enter/F2 = `text.edit` (110-113); Escape =
  `edit.deselect` (114-117); Tab cycles the selection (118-121).
- **Nothing selected, not editing:** PageDown/Down/Right = `slide.next`; PageUp/Up/Left =
  `slide.previous`; Home = `slide.first`; End = `slide.last`; Enter = `slide.new`; Tab cycles the
  selection (125-142). Only after this does the registry lookup run (143-165).
- Freeform drawing and Edit Points end on Enter/Escape (`crates/engine/src/keys.rs:57-64`). Typing on a single
  selected shape replaces its text (`type_text`, `crates/engine/src/keys.rs:214-226`).

### Slide show keys (`crates/ui-egui/src/show.rs:425-519`)

Next: Right/Down/Space/PageDown/N/Enter. Previous: Left/Up/Backspace/PageUp/P (Cmd+P toggles the
pen). Escape/Minus backs out (Escape first clears a typed slide number). Home/End first/last.
B or `.` black screen, W or `,` white screen, E erases ink. Cmd+L laser, Cmd+A arrow pointer.
Digits 0–9 type a slide number (Backspace deletes a digit, Enter jumps). G opens See All Slides
(while it is open only G, Escape and Minus work), Z arms zoom, T pause/resumes the presenter
timer, R resets it, `[` and `]` change the notes size.

## Control channel methods

Start it with `deckcraft --control PORT` (`apps/deckcraft/src/main.rs:129-136`; the port can also
come from `DECKCRAFT_CONTROL_PORT`, line 174). The server binds `127.0.0.1` only
(`apps/deckcraft/src/control_server.rs:52`) and speaks JSON lines: one request object per line,
one reply per line (`docs/control-protocol.md:3-4`). A line that is not a JSON object with a string
`method` (HTTP, text, binary) gets one error reply and the connection closes
(`apps/deckcraft/src/control_server.rs:138-171`). Resource bounds, `Limits::default()`
(`apps/deckcraft/src/control_server.rs:37-49`): 16 concurrent connections, 256 MiB request line,
64 queued requests, 600 s idle, 30 s reply-write block, 60 s UI wait. (`docs/control-protocol.md:16-21`
still says a 16 MiB line — stale; the code allows 256 MiB for base64 media payloads.)

The authoritative method list is the dispatch in `crates/ui-egui/src/control.rs:135-375`:

| Method (aliases) | Params | What it does |
|---|---|---|
| `engine.execute` / `ui.menu.invoke` / `command` | `{command, params}` | Run any command (engine or UI) — the same path as everything else |
| `engine.commands` | — | Every command: id, label, menu, shortcut, params doc, enabled reason |
| `document.inspect` | — | Slides, sections, layouts, shapes, selection |
| `ui.inspect` | — | UI state, tool, window/canvas/slide rects, dialog, backstage page, `home`, show state, `animPreview`, documents, perf |
| `ui.pointer` | `{events:[{kind: down\|drag\|up\|move\|doubleclick\|tripleclick\|contextclick, x, y, mods?, pressure?}], mods?}` | Pointer input in slide points through the active tool (same code as the mouse) |
| `ui.key` | `{key, shift?, alt?, cmd?}` | One key press through the engine (also drives a running show) |
| `ui.text` | `{text}` | Type text (into the edited text or the selected shape) |
| `ui.ime` | `{preedit, active?:[start,end]}` or `{commit}` | Input-method composition through egui |
| `ui.tool.select` | `{tool, preset?}` | `select`, `text`, `textBox`, `shape` (+preset), a preset name, `pen`, `highlighter`, `eraser` |
| `ui.move` / `ui.click` / `ui.drag` | screen points (`click`: `button?, count?`; `drag`: `toX, toY, steps?`) | Real egui pointer input — reaches every widget, menu and pane |
| `ui.set` | `{tab?, view?, pane?, zoom?, dark?, notes?, ribbonCollapsed?, formatTab?}` | UI state (returns the full state) |
| `ui.dialog.open` / `ui.dialog.close` | `{id, fields?}` | Open/close a dialog by id, optionally pre-filling fields |
| `ui.screenshot` | `{path?}` | PNG of the whole window (base64 when no path) |
| `ui.render` | `{slide?, scale?, path?, edit?}` | Render a slide (works headlessly) |
| `ui.resize` / `ui.focus` | `{width, height}` / — | Window control |
| `show.start` | `{from?, custom?, reading?}` | Start the slide show (from a slide, a custom show, or the configured start) |
| `show.end` | — | End the slide show |
| `app.open` | `{path}` | Open a presentation file |
| `app.save` | `file.save` params | Save (dialog-equivalent `{}` may request a path) |
| `app.export` | `file.export` params | Export (`{path, layout, perPage}` for PDF, `{path, width, secondsPerSlide, loop}` for GIF…) |
| `app.quit` | `{save?}` | Quit (`{"save": true}` saves first) |

Notes:

- `show.key` appears in the module comment (`crates/ui-egui/src/control.rs:15`) but is **not**
  handled by the dispatch match — at v0.8.0, show keystrokes go through `ui.key`
  (`crates/ui-egui/src/control.rs:166-181`).
- `docs/control-protocol.md:30-52` repeats several rows (`ui.inspect`, `ui.pointer`, `ui.key`) —
  the code above is authoritative.
- From a shell, `deckcraft-cli app [--port PORT] COMMAND [PARAMS]` or `--method METHOD [PARAMS]`
  sends one request; the default port is **7979** (`apps/deckcraft-cli/src/help.rs:117-126`;
  `crates/mcp/src/lib.rs:29`).
- MCP headless mode (`deckcraft-cli mcp` without `--connect`) accepts only a subset:
  `engine.execute` / `command` / `ui.menu.invoke`, `engine.commands`, `document.inspect`,
  `ui.pointer`, `ui.key`, `ui.text`, `ui.tool.select`, `ui.render` (alias `app.renderSlide`),
  `app.open`, `app.save`, `app.export`, and a stub `ui.inspect`; every other `ui.*`/`app.*`
  method returns a "needs the desktop app" error (`crates/mcp/src/headless.rs:146-179`; message at
  `crates/mcp/src/headless.rs:24`).

## MCP tools

`deckcraft-cli mcp` serves Model Context Protocol on stdio — headless by default, or
connected to the app with `--connect PORT` (also `host:port`); `--sample` opens the sample deck
(`apps/deckcraft-cli/src/help.rs:127-139`; `apps/deckcraft-cli/src/main.rs:588-615`). Protocol
revision **2025-06-18** (`crates/mcp/src/server.rs:11`), also accepting `2025-03-26` and
`2024-11-05` (line 12). Capabilities: tools + resources; two resources are exposed —
`deckcraft://document` and `deckcraft://commands` (`crates/mcp/src/server.rs:31-32,156-166`), no
resource templates.

**25 tools** (`tool_definitions()`, `crates/mcp/src/tools.rs:65-291`). "RO" = carries
`readOnlyHint: true` in its annotations; "app" = needs connected mode (`APP_ONLY`,
`crates/mcp/src/tools.rs:63`). `screenshot` and `call_app` are the app-only pair; everything else
works headlessly.

| Tool | Mode | Maps to | Source |
|---|---|---|---|
| `list_commands` | RO | `engine.commands` (+ `filter`) | `crates/mcp/src/tools.rs:67` |
| `run_command` | | `engine.execute` | `crates/mcp/src/tools.rs:74` |
| `batch` | | several commands, stops at first error unless `keepGoing` | `crates/mcp/src/tools.rs:84` |
| `new_presentation` | | `file.new` (`theme`, `blank`) | `crates/mcp/src/tools.rs:94` |
| `open_presentation` | | `file.open` | `crates/mcp/src/tools.rs:101` |
| `save_presentation` | | `file.save` | `crates/mcp/src/tools.rs:108` |
| `export` | | `file.export` (png/jpeg/pptx/deckcraft/outline/pdf/gif and all options) | `crates/mcp/src/tools.rs:115` |
| `inspect_document` | RO | `document.inspect` | `crates/mcp/src/tools.rs:149` |
| `inspect_slide` | RO | `slide.inspect` | `crates/mcp/src/tools.rs:156` |
| `render_slide` | RO | `ui.render`, returned as an image block | `crates/mcp/src/tools.rs:163` |
| `add_slide` | | `slide.new` (layout, title, body) | `crates/mcp/src/tools.rs:173` |
| `go_to_slide` | | `slide.go` | `crates/mcp/src/tools.rs:180` |
| `add_shape` | | `shape.insert` (+ `shape.fill`/`shape.line` when given) | `crates/mcp/src/tools.rs:187` |
| `add_text_box` | | `insert.textBox` + `format.size/color/align` | `crates/mcp/src/tools.rs:197` |
| `set_text` | | `text.set` | `crates/mcp/src/tools.rs:207` |
| `insert_picture` | | `insert.picture` (path or base64) | `crates/mcp/src/tools.rs:214` |
| `insert_table` | | `insert.table` | `crates/mcp/src/tools.rs:224` |
| `insert_chart` | | `insert.chart` | `crates/mcp/src/tools.rs:234` |
| `select` | | `edit.select` | `crates/mcp/src/tools.rs:244` |
| `pointer` | | `ui.pointer` | `crates/mcp/src/tools.rs:251` |
| `select_tool` | | `ui.tool.select` | `crates/mcp/src/tools.rs:261` |
| `key` | | `ui.key` | `crates/mcp/src/tools.rs:268` |
| `type_text` | | `ui.text` | `crates/mcp/src/tools.rs:275` |
| `screenshot` | RO, app | `ui.screenshot` as an image block | `crates/mcp/src/tools.rs:282` |
| `call_app` | app | any control-channel method | `crates/mcp/src/tools.rs:283` |

- Arguments are strict: a key not in the tool's schema is refused with the expected list
  (`unknown_argument_error`, `crates/mcp/src/tools.rs:311-332`); keys inside `run_command`'s
  `params` belong to the command.
- Connected mode validates replies (numeric `id`, boolean `ok`, exactly one of `result`/`error`),
  caps a reply at 16 MiB and reconnects rather than replaying (`crates/mcp/src/backend.rs:11`;
  `docs/mcp.md:8-14`).
- File confinement: `--automation-read-root DIR` / `--automation-write-root DIR` confine every path
  a command reads (open, pictures, audio, video) and writes (save, export every format, render
  output) to those folders, links followed; they apply to the in-process server only and conflict
  with `--connect` (`apps/deckcraft-cli/src/automation_args.rs`; `crates/engine/src/file_access.rs`;
  all engine file I/O goes through `crates/engine/src/io.rs`).
- The server's system prompt for clients summarises the intended flow:
  `new_presentation → add_slide → add_shape/add_text_box/insert_picture/insert_chart →
  inspect_slide → render_slide → save_presentation` (`crates/mcp/src/server.rs:21-28`).

## Save/export formats

**Open / read** (`crates/engine/src/cmd/file.rs:132-163`):

| Input | Recognised by | Notes |
|---|---|---|
| `.deckcraft` | zip whose leading bytes carry the mimetype `application/vnd.storyteller.deckcraft+zip` (`crates/format/src/lib.rs:98-100`) | Native format; legacy `.slidecraft` mimetype still read (`crates/format/src/lib.rs:17`); unknown fields ignored (`crates/format/src/lib.rs:1-4`) |
| `.pptx` / `.potx` / `.ppsx` | OOXML: zip with `[Content_Types].xml` (`crates/pptx/src/lib.rs:49-54`) | Read via `pptx::import`; then repaired (`crates/engine/src/cmd/file.rs:140-143`) |
| password-protected OOXML | `cfb::is_encrypted` (`crates/pptx/src/lib.rs:57-59`) | Refused with a clear message (`crates/engine/src/cmd/file.rs:145-147`) |
| `.txt` / `.md` | by extension (`crates/engine/src/cmd/file.rs:148-161`) | Outline import — Markdown headings become slides (`crates/format/src/lib.rs:412` and `:472`) |
| `.thmx` (theme; also `.pptx`/`.potx` theme) | `design.browseTheme {path} \| {name, data}` (`crates/engine/src/cmd/design.rs:18-26,163`) | Applies the theme |

**Native `.deckcraft` layout** (`crates/format/src/lib.rs:15-20,56-85`): a zip with a stored
`mimetype` entry, a deflated `presentation.json` manifest
(`{format:"deckcraft", version:1, generator, presentation}`) and `media/<id>` entries (stored when
already compressed). Load budgets: 2 GiB per entry, 4 GiB total media, 100 000 media items
(`crates/format/src/lib.rs:22-26`).

**Save** (`file.save {path?, format?: deckcraft|pptx}`, `file.saveAs {path, format?}`,
`file.saveTemplate {path}`; `crates/engine/src/cmd/file.rs:32-34`): the format comes from `format?`, else from the path's
extension (`format_for_path`, `crates/engine/src/cmd/file.rs:355-376`). Extensions DeckCraft can write are listed in
`WRITABLE_EXTENSIONS = ["deckcraft","pptx","potx","ppsx","pdf","png","jpg","jpeg","gif","txt","md"]`
(`crates/engine/src/cmd/file.rs:340`). `save_bytes` understands `pptx|potx|ppsx`, `outline|txt`, `pdf`, `gif`, and
falls back to the native format for anything else (`crates/engine/src/cmd/file.rs:260-269`) — so **`file.save` to a
`.png` path writes native zip bytes**, not an image; use `file.export` for images (a real trap for
agents). The CLI refuses unknown output extensions for `convert`/`run --save`/`--export` up front
(`apps/deckcraft-cli/src/main.rs:425-431`).

**Export** (`file.export`, `crates/engine/src/cmd/file.rs:36,481-546`):

| Format | Options (all optional unless shown) | Bounds / defaults |
|---|---|---|
| `png` / `jpeg` | `slide?: index`, `all?: bool`, `scale?: px per pt` | one slide or all; `scale` default 2, clamped 0.01–16 and to the renderer's max side (`crates/engine/src/cmd/file.rs:426-430`); JPEG quality 92 with DPI metadata (`crates/engine/src/cmd/file.rs:443-446`); multiple slides are written as `name1.ext, name2.ext…` (`crates/engine/src/cmd/file.rs:502-514`) |
| `pptx` / `potx` / `ppsx` / `deckcraft` | — | content type differs for potx/ppsx (`crates/pptx/src/lib.rs:80-87`) |
| `outline` / `txt` | — | plain-text outline (`crates/format/src/lib.rs:492`) |
| `pdf` | `layout?: slides\|notes\|handouts`, `perPage?: 1\|2\|3\|4\|6\|9`, `paper?: letter\|a4\|legal\|a3`, `orientation?: portrait\|landscape`, `dpi?`, `slides?: [index]\|"1-3,5"`, `includeHidden?`, `textLayer?`, `frame?` | defaults: slides layout, 6-per-page handouts, letter portrait, dpi 200 (clamped 36–600), hidden excluded, text layer on, frame on (`crates/engine/src/cmd/file.rs:277-304`; `crates/pdf/src/lib.rs:55-105`). Slide artwork is rasterized — slides are placed as images at the DPI — and a selectable real-text overlay is drawn over it; bookmarks, links and notes pages come from the exporter (`crates/pdf/README.md:1-6`; `crates/pdf/src/lib.rs:75`) |
| `gif` | `width?: px 16–3840 \| small\|medium\|large\|extraLarge`, `secondsPerSlide?: 0.1–600`, `loop?: bool`, `slides?`, `includeHidden?` | width default medium 960 (presets 640/960/1280/1920), 5 s per slide, loop forever by default; one frame per slide, no transitions/builds animated; ≤500 frames and ≤200M total pixels (`crates/engine/src/gif_export.rs:20-36,93-120`); result reports `frames, width, height, secondsPerSlide` (`crates/engine/src/cmd/file.rs:522-538`) |

Read-back queries: `file.info` (path, format, dirty, slide counts, properties), `file.render`
(slide → PNG base64) and `file.saveBytes` (in-memory encode) round out the file family
(`crates/engine/src/cmd/file.rs:37-46`). PDF paper list is printed by `describe file.export` from
`crates/pdf/src/lib.rs:100-105`.

## Paths

All values are per-user runtime paths, not repo paths.

| What | Location | Source |
|---|---|---|
| Settings directory (`ui.json`, `prefs.json`, `logs/`) | macOS `~/Library/Application Support/DeckCraft`; Windows `%APPDATA%\DeckCraft`; Linux `$XDG_CONFIG_HOME/deckcraft` or `~/.config/deckcraft` | `apps/deckcraft/src/main.rs:56-68` |
| Log file | `<settings>/logs/deckcraft.log`, rotated to `deckcraft.1.log`/`deckcraft.2.log`, capped at 16 MiB | `apps/deckcraft/src/logging.rs:6,33-40` |
| Recovery folder | macOS `~/Library/Application Support/DeckCraft/Recovery`; Windows `%APPDATA%\DeckCraft\Recovery`; Linux `$XDG_DATA_HOME/deckcraft/recovery` or `~/.local/share/deckcraft/recovery` | `crates/engine/src/recovery.rs:26-35` |
| Recovery entries | `<uid>.deckcraft` + `<uid>.json` (`{path, title, saved, owner}`); per-instance locks `owner-<instance>.lock` | `crates/engine/src/recovery.rs:7-15,57-59` |
| Dictionaries | `DECKCRAFT_DICTIONARIES` first; macOS `~/Library/Application Support/DeckCraft/Dictionaries`, `~/Library/Spelling`, `/Library/Spelling`; Windows `%APPDATA%\DeckCraft\Dictionaries`; Linux `<xdg data>/deckcraft/dictionaries`, `<xdg data>/hunspell`, `/usr/share/hunspell`, `/usr/share/myspell[/dicts]`, `/usr/local/share/hunspell`, `/app/share/hunspell` | `crates/engine/src/spell.rs:481-501` |
| User dictionary | `<settings>/Dictionaries/user.dic` (one word per line) | `crates/engine/src/spell.rs:581-599` |
| Fonts (system scan) | macOS `/System/Library/Fonts`, `/Library/Fonts`, `~/Library/Fonts`, Office cloud-font caches and app DFonts, MobileAsset font dirs; Windows `%WINDIR%\Fonts`, `%LOCALAPPDATA%\Microsoft\Windows\Fonts`; Linux `/usr/share/fonts`, `/usr/local/share/fonts`, `~/.fonts`, `~/.local/share/fonts`, XDG dirs, `/run/host/*`, fontconfig entries | `crates/fonts/src/fontdb.rs:480-533` |
| Save temporary | `<path>.<pid>.<n>.saving` beside the destination, renamed over it, removed on failure | `crates/engine/src/io.rs:25-52` |

Environment variables:

| Variable | Effect | Source |
|---|---|---|
| `DECKCRAFT_CONTROL_PORT` | default port when `--control` is not given | `apps/deckcraft/src/main.rs:174` |
| `DECKCRAFT_NO_PREFS` | don't load or save `ui.json`/`prefs.json` | `apps/deckcraft/src/main.rs:64,84` |
| `DECKCRAFT_DICTIONARIES` | extra dictionary folders (OS path list) | `crates/engine/src/spell.rs:483` |
| `RUST_LOG` | log filter (default `warn,deckcraft*=info`) | `apps/deckcraft/src/logging.rs:281,40` |
| `DECKCRAFT_WAYLAND`, `DISPLAY`, `WAYLAND_DISPLAY` | Linux display backend selection | `apps/deckcraft/src/display.rs:49-51` |
| `CRAFT_FONTS_DIR` | build-time checkout of `storytold/craft-fonts` to embed fonts | `crates/fonts/build.rs:17` |
| `DECKCRAFT_BUILD_SHA`, `DECKCRAFT_BUILD_DATE` | set by the release workflow; shown in About | `crates/ui-egui/src/dialogs.rs:2626-2630` |

Launch surfaces:

- App: `deckcraft [--control PORT] [--sample] [--show] [FILE...]` plus `--help`/`--version`
  (`apps/deckcraft/src/main.rs:129-136`). The sample presentation is generated in code
  (`--sample`; `crates/engine/src/sample.rs`).
- CLI: `deckcraft-cli` with subcommands `info`, `render`, `render-transition`, `convert`, `run`,
  `commands`, `describe`, `app`, `mcp`, `bench`, `links`, `version`
  (`apps/deckcraft-cli/src/help.rs:8-157`); `render` writes `slide-01.png…` per slide with `--all`,
  `convert` writes whatever `WRITABLE_EXTENSIONS` names (`apps/deckcraft-cli/src/help.rs:20-57`).
- MCP: `deckcraft-cli mcp [--connect PORT] [--sample] [--automation-read-root DIR]
  [--automation-write-root DIR]` (`apps/deckcraft-cli/src/help.rs:127-139`).

---

Total commands found at v0.8.0 (`22db9261f9d1a214c296fd390173130c45d76d66`): **320**.

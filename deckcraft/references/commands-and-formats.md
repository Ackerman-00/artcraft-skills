# DeckCraft — commands, shortcuts, control methods, MCP tools and file formats (agent reference)

**Pin:** tag `v0.9.0`, commit `fe510bdac68118f2c9a714e69d0ff572e3f9a0c7` — the code shipped in DeckCraft 0.9.0.
**Verified:** 2026-10-22 against the worktree at that tag. All citations are repo-relative (`path:line`).

---

## Command families

Everything DeckCraft does is a command. A command is a `CommandSpec` with id, label, ribbon/menu place,
optional shortcut, a parameter doc, an enabled check and a run function (`crates/engine/src/cmd/mod.rs:44-58`).
Ids follow PowerPoint's ribbon and menu structure.

The `cmd!` macro has three forms (`crates/engine/src/cmd/mod.rs:148-158`):

- `cmd!(id, …)` — journaled and undoable (an ordinary edit);
- `cmd!(noundo id, …)` — journaled, not undoable (navigation, save, playback, settings);
- `cmd!(query id, …)` — neither journaled nor undoable (read-only queries).

`command_specs()` (`crates/engine/src/cmd/mod.rs:161-192`) builds the registry once, concatenating the
per-family `specs()` functions in this order: file, edit, slide, reuse, insert, smartart, shape, background,
picture_style, recolor, arrange, selection, merge, points, text, format, design, ideas, transition,
animation, table, find, review, inspect, media, artistic, zoom, compress. That order is also the tie-break
when two commands share a shortcut (see `Cmd+Shift+V` below). `Session::execute` is the single dispatch
path every surface uses — UI, keyboard, CLI, control channel, MCP (`crates/engine/src/lib.rs:581`,
panic-guarded via `crates/engine/src/guard.rs`).

**Total: 320 commands**, counted as `cmd!(…)` blocks across `crates/engine/src/cmd/*.rs`:
**229** ordinary + **55** `noundo` + **36** `query`; all ids unique (recounted; `docs/architecture.md:23`
reports the same number). (`three_d.rs` and `richclip.rs` in the same directory hold helpers, not commands:
3-D scene/bevel handling and HTML↔body clipboard conversion, used by `shape.effects` and `edit.paste`.)

| Family module (`crates/engine/src/cmd/…`) | `specs()` at | Commands | Covers |
|---|---|---|---|
| `file.rs` | 9 | 21 | new (theme/template), open, save/saveAs/saveTemplate/saveBytes, export, info, render, close, properties, AutoRecover (`file.recovery.*`), revert, color at, next window |
| `edit.rs` | 13 | 12 | undo/redo, clipboard (cut/copy/paste — paste accepts `{text?, html?, scope?}` rich HTML from other apps), pasteSpecial (`as: destinationTheme\|keepSource\|picture\|text`), pasteText, duplicate, delete, select all/deselect/select |
| `slide.rs` | 12 | 21 | new/duplicate/delete/move/layout/reset/hide/notes/rename, sections, `slide.fromOutline`, navigation (go/next/previous/first/last), select slides, color at |
| `reuse.rs` | 19 | 1 | Reuse Slides (insert slides from another presentation) |
| `insert.rs` | 14 | 23 | text box, picture, photo album (+edit), table, chart (+ `chart.type`, `chart.data`, options), audio, video, WordArt, slide number, date/time, symbol, hyperlink, SmartArt, icons, preset shapes, action buttons |
| `smartart.rs` | 161 | 13 | SmartArt outline (Text Pane), add/promote/demote, layout switching, `smartArt.nodes` query |
| `shape.rs` | 12 | 27 | connect, freeform, ink to shape, sites, move/resize/rotate/flip, adjust, change, smooth corners, fill, line, effects (shadow/glow/reflection/soft edges/**bevel + 3-D**), quick style, rename, alt text, visibility, lock, default, crop, picture adjust, media options, size and position |
| `background.rs` | 17 | 1 | Remove Background |
| `picture_style.rs` | 12 | 2 | Picture Styles gallery + apply |
| `recolor.rs` | 11 | 3 | Recolor presets + Set Transparent Color + gallery |
| `arrange.rs` | 10 | 19 | order (bring/send), group/ungroup/regroup, align, distribute, rotate, flip, nudge, guides, reorder |
| `selection.rs` | 11 | 3 | Selection pane: select, Show All, Hide All |
| `merge.rs` | 21 | 1 | Merge Shapes (union, combine, fragment, intersect, subtract via `op`) |
| `points.rs` | 16 | 7 | Edit Points: enter/exit, add/delete/move point, points query, close/open path |
| `text.rs` | 15 | 15 | text edit/insert/delete/move caret/select, autocorrect, commit, fonts used |
| `format.rs` | 14 | 48 | character formatting (font, size, bold…, caps, case, spacing, language, highlight, shadow/outline/warp, transparency), paragraph formatting (align, RTL, bullets/numbering, indent, line spacing, tabs, columns, direction, anchor, autofit, wrap, margins), ruler state, `font.add`, `font.rescan` |
| `design.rs` | 15 | 24 | themes, variants, colors, fonts, effects, `design.browseTheme` (.thmx/.pptx/.potx), background, slide size, header/footer, masters, handouts, notes master |
| `ideas.rs` | 13 | 2 | Design Ideas gallery + apply |
| `transition.rs` | 12 | 6 | transition set, effect options, apply all, duration, gallery |
| `animation.rs` | 11 | 11 | animation add/set/remove/move, start mode, timing, gallery, `animation.get` |
| `table.rs` | 10 | 21 | rows/columns, merge/split, distribute, cell size, borders, styles, select cells |
| `find.rs` | 12 | 2 | Find, Replace (slide text, table cells, notes) |
| `review.rs` | 11 | 22 | comments, spelling, thesaurus, dictionary, accessibility, revisions, compare, slide show start/end/presenter |
| `inspect.rs` | 10 | 4 | `document.inspect`, `slide.inspect`, `shape.inspect`, `commands.list` |
| `media.rs` | 11 | 8 | play/pause/stop/toggle, seek, GIF play, media info |
| `artistic.rs` | 26 | 1 | Artistic Effects (pencil sketch, blur, grain…, on the CPU) |
| `zoom.rs` | 19 | 1 | Insert ▸ Zoom (Summary/Section/Slide Zoom) |
| `compress.rs` | 14 | 1 | Compress Pictures (downsample to a target resolution) |

Notes for agents:

- List commands with `deckcraft-cli commands [FILTER]`, explain one with `deckcraft-cli describe COMMAND`
  (`apps/deckcraft-cli/src/help.rs:96-115`), or query `commands.list` / `engine.commands` at runtime.
- Queries (`query`) are free to call and safe in loops; `noundo` commands change the document but cannot
  be undone — save points (`file.save`) discard the document's recovery entry (`crates/engine/src/cmd/file.rs:409-421`).
- UI-only commands (views, panes, dialogs, palette, Quick Access Toolbar) live separately in `UI_COMMANDS`
  (`crates/ui-egui/src/lib.rs:359-415`, 50 entries); they are runnable through `engine.commands`/`app.run`
  in the desktop app but are rejected headlessly.

## Verified keyboard shortcuts

Sources in code: (1) the engine registry's `shortcut` field, matched by `shortcut_matches`
(`crates/engine/src/keys.rs:10-21`) in `Session::key` (lookup at `keys.rs:161`); (2) UI-only shortcuts in
`UI_COMMANDS` matched by `menus.rs::ui_shortcut` (`crates/ui-egui/src/menus.rs:11-79`); (3) implicit keys
hard-wired in `Session::key`/`text_key` (`crates/engine/src/keys.rs:51-211`); (4) slide-show keys
(`crates/ui-egui/src/show.rs:425-519`). `Cmd` matches Command on macOS and Ctrl elsewhere; `Alt` matches
Option/Alt. **57 engine commands carry a shortcut.**

### Engine registry shortcuts (57)

- **File:** `file.new` Cmd+N (`file.rs:11`) · `file.open` Cmd+O (21) · `file.save` Cmd+S (32) ·
  `file.saveAs` Cmd+Shift+S (33) · `file.close` Cmd+W (56) · `window.next` Cmd+` (71)
- **Edit:** `edit.undo` Cmd+Z · `edit.redo` Cmd+Y · `edit.cut` Cmd+X · `edit.copy` Cmd+C ·
  `edit.paste` Cmd+V · `edit.pasteText` Cmd+Shift+V · `edit.duplicate` Cmd+D · `edit.delete` Delete ·
  `edit.selectAll` Cmd+A · `edit.deselect` Escape (`edit.rs:15-41`)
- **Format:** `format.bold` Cmd+B · italic Cmd+I · underline Cmd+U · `format.strikethrough` Cmd+Shift+X ·
  superscript Cmd+Shift+= · subscript Cmd+= · grow Cmd+Shift+. · shrink Cmd+Shift+, · `format.case` Shift+F3 ·
  `format.clear` Cmd+Space · `format.fontDialog` Cmd+T · alignLeft Cmd+L · alignCenter Cmd+E ·
  alignRight Cmd+R · justify Cmd+J · indent Tab · outdent Shift+Tab · `format.painter` Cmd+Shift+C ·
  `format.painterApply` Cmd+Shift+V (`format.rs:18-214`)
- **Arrange:** `arrange.bringToFront` Cmd+Shift+] · bringForward Cmd+] · sendBackward Cmd+[ ·
  sendToBack Cmd+Shift+[ · group Cmd+Alt+G · ungroup Cmd+Alt+Shift+G · regroup Cmd+Alt+J (`arrange.rs:24-39`)
- **Slides:** `slide.new` Cmd+Shift+N (`slide.rs:14`) · `slide.next` PageDown · `slide.previous` PageUp · `slide.first` Home · `slide.last` End (27-30)
- **Insert/review/media/animation:** `insert.hyperlink` Cmd+K (`insert.rs:97`) · `media.play` Alt+P (`media.rs:13`) · `comment.add` Cmd+Alt+M · `review.spelling` F7 (`review.rs:13,37`) · `show.fromStart` Cmd+Shift+Enter · `show.fromCurrent` Cmd+Enter (`review.rs:63-64`) · `animation.painter` Alt+Shift+C · `animation.painterApply` Alt+Shift+V (`animation.rs:52,61`) · `text.edit` Enter · `text.delete` Backspace (`text.rs:27,60`)

One collision is real: `edit.pasteText` and `format.painterApply` both declare **Cmd+Shift+V**. Because
`command_specs()` lists `edit` before `format`, the key path resolves to `edit.pasteText`; run
`format.painterApply` by id to paste formatting.

### UI-only shortcuts (15 of the 50 `UI_COMMANDS` entries)

`view.gridlines` Shift+F9 · `view.guides` Alt+F9 · `view.zoomIn` Cmd+= · `view.zoomOut` Cmd+- ·
`review.thesaurusPane` Shift+F7 · `view.collapseRibbon` Cmd+F1 · `show.start` F5 · `app.backstage` Alt+F ·
`app.closePresentation` Cmd+W · `app.print` Cmd+P · `app.palette` Cmd+Shift+P · `app.preferences` Cmd+, ·
`app.pasteSpecial` Cmd+Alt+V · `app.find` Cmd+F · `app.replace` Cmd+H (`crates/ui-egui/src/lib.rs:359-415`).
`menus.rs::ui_shortcut` handles these plus: Cmd+A over the slides list selects all slides, F5/Shift+F5 and
Cmd+Enter/Cmd+Shift+Enter start the show, Cmd+S/Cmd+Shift+S save dialogs, Cmd+0 fit, Cmd+K hyperlink dialog.

### Implicit keys in the engine (`crates/engine/src/keys.rs`)

- **Editing text:** Enter = new paragraph, Shift+Enter = line break, Escape = `text.exit`, Tab at paragraph
  start = indent/outdent (inside a table Tab = next cell, Shift+Tab = previous, Tab in the last cell adds a
  row — `keys.rs:71-91,288-310`). Arrows/Home/End/Backspace/Delete map to `text.move`/`text.delete`;
  Cmd+]/Cmd+[ grow/shrink the font (`keys.rs:171-211`).
- **Shape selected:** arrows nudge 6 pt (Alt 1 pt), Backspace/Delete = `edit.delete`, Enter/F2 = `text.edit`,
  Escape = `edit.deselect`, Tab cycles the selection (92-121).
- **Nothing selected:** PageDown/Down/Right = `slide.next`; PageUp/Up/Left = `slide.previous`; Home/End =
  first/last; Enter = `slide.new`; Tab cycles the selection (125-142). Only then does the registry lookup run.
- Freeform and Edit Points end on Enter/Escape (57-64). Typing on a single selected shape replaces its text
  (`type_text`, 214-226).

### Slide show keys (`crates/ui-egui/src/show.rs:425-519`)

Next: Right/Down/Space/PageDown/N/Enter. Previous: Left/Up/Backspace/PageUp/P (Cmd+P toggles the pen).
Escape/Minus backs out (Escape first clears a typed slide number). Home/End first/last. B or `.` black
screen, W or `,` white screen, E erases ink. Cmd+L laser, Cmd+A arrow pointer. Digits 0-9 type a slide
number, Enter jumps. G opens See All Slides (while open only G/Escape/Minus work), Z arms zoom, T pauses the
presenter timer, R resets it, `[`/`]` change the notes size.

## Control channel methods

Start with `deckcraft --control PORT` (or `DECKCRAFT_CONTROL_PORT`; `apps/deckcraft/src/main.rs:129-177`).
The server binds `127.0.0.1` only (`apps/deckcraft/src/control_server.rs:52`) and speaks JSON lines: one
request object per line, one reply per line. A non-JSON line gets one error reply and the connection closes.
Limits (`Limits::default()`, `control_server.rs:37-49`): 16 concurrent connections, **256 MiB** request line
(`control_server.rs:42` — `docs/control-protocol.md:12,17` still says 16 MiB; stale), 64 queued requests,
600 s idle, 30 s reply-write block, 60 s UI wait.

The authoritative method list is the dispatch in `crates/ui-egui/src/control.rs:135-375`:

| Method (aliases) | Params | What it does |
|---|---|---|
| `engine.execute` / `ui.menu.invoke` / `command` | `{command, params}` | Run any command (engine or UI) |
| `engine.commands` | — | Every command: id, label, menu, shortcut, params doc, enabled reason |
| `document.inspect` | — | Slides, sections, layouts, shapes, selection |
| `ui.inspect` | — | UI state, tool, window/canvas/slide rects, dialog, backstage page, `home`, show state, documents, perf |
| `ui.pointer` | `{events:[{kind: down\|drag\|up\|move\|doubleclick\|tripleclick\|contextclick, x, y, mods?, pressure?}]}` | Pointer input in **slide points** through the active tool |
| `ui.key` / `ui.text` / `ui.ime` | `{key, shift?, alt?, cmd?}` / `{text}` / `{preedit, active?}\|{commit}` | One key press (also drives a running show) / type text / IME composition |
| `ui.tool.select` | `{tool, preset?}` | `select`, `text`, `textBox`, `shape`(+preset), a preset name, `pen`, `highlighter`, `eraser` |
| `ui.move` / `ui.click` / `ui.drag` | screen points (`click`: `button?, count?`; `drag`: `toX, toY, steps?`) | Real egui pointer input — reaches every widget, menu and pane |
| `ui.set` | `{tab?, view?, pane?, zoom?, dark?, notes?, ribbonCollapsed?, formatTab?}` | UI state (returns the full state) |
| `ui.dialog.open` / `ui.dialog.close` | `{id, fields?}` | Open/close a dialog by id, optionally pre-filling fields |
| `ui.screenshot` | `{path?}` | PNG of the whole window (base64 when no path) |
| `ui.render` | `{slide?, scale?, path?, edit?}` | Render a slide (works headlessly) |
| `ui.resize` / `ui.focus` | `{width, height}` / — | Window control |
| `show.start` / `show.end` | `{from?, custom?, reading?}` / — | Start (from a slide, a custom show, or the configured start) / end the show |
| `app.open` / `app.save` / `app.export` | `{path}` / `file.save` params / `file.export` params | File operations; `app.save` with `{}` may request a path dialog |
| `app.quit` | `{save?}` | Quit without asking; `{"save": true}` saves every presentation first (`control.rs:364-372`) |

Notes:

- `show.key` appears in the module comment (`crates/ui-egui/src/control.rs:17`) but is **not** handled by
  the dispatch — show keystrokes go through `ui.key` (`control.rs:166-181`).
- From a shell: `deckcraft-cli app [--port PORT] COMMAND [PARAMS]` or `--method METHOD [PARAMS]`; default
  port **7979** (`apps/deckcraft-cli/src/help.rs:116-126`).
- MCP headless mode (`deckcraft-cli mcp` without `--connect`) accepts only a subset: `engine.execute` /
  `command` / `ui.menu.invoke`, `engine.commands`, `document.inspect`, `ui.pointer`, `ui.key`, `ui.text`,
  `ui.tool.select`, `ui.render` (alias `app.renderSlide`), `app.open`, `app.save`, `app.export`, and a stub
  `ui.inspect`; every other `ui.*`/`app.*` method returns a "needs the desktop app" error
  (`crates/mcp/src/headless.rs:24,148-179`).

## MCP tools

`deckcraft-cli mcp` serves MCP on stdio — headless by default, or connected with `--connect PORT`
(`host:port` allowed); `--sample` opens the sample deck. Protocol revision **2025-06-18**, also accepting
`2025-03-26` and `2024-11-05` (`crates/mcp/src/server.rs:11-12`). Two resources: `deckcraft://document`,
`deckcraft://commands` (`server.rs:31-32`); no resource templates.

**25 tools** (`tool_definitions()`, `crates/mcp/src/tools.rs:65-291`). "RO" = `readOnlyHint`; "app" =
connected-mode only (`APP_ONLY`, `tools.rs:63`).

| Tool | Mode | Maps to | `tools.rs` |
|---|---|---|---|
| `list_commands` | RO | `engine.commands` (+ `filter`) | 67 |
| `run_command` | | `engine.execute` | 74 |
| `batch` | | several commands; stops at first error unless `keepGoing` | 84 |
| `new_presentation` | | `file.new` (`theme`, `blank`) | 94 |
| `open_presentation` / `save_presentation` | | `file.open` / `file.save` | 101, 108 |
| `export` | | `file.export` (png/jpeg/pptx/deckcraft/outline/pdf/gif and all options) | 115 |
| `inspect_document` / `inspect_slide` | RO | `document.inspect` / `slide.inspect` | 149, 156 |
| `render_slide` | RO | `ui.render`, returned as an image block | 163 |
| `add_slide` / `go_to_slide` | | `slide.new` (layout, title, body) / `slide.go` | 173, 180 |
| `add_shape` | | `shape.insert` (+ `shape.fill`/`shape.line` when given) | 187 |
| `add_text_box` | | `insert.textBox` + `format.size/color/align` | 197 |
| `set_text` | | `text.set` | 207 |
| `insert_picture` | | `insert.picture` (path or base64) | 214 |
| `insert_table` / `insert_chart` | | `insert.table` / `insert.chart` | 224, 234 |
| `select` / `pointer` | | `edit.select` / `ui.pointer` | 244, 251 |
| `select_tool` / `key` / `type_text` | | `ui.tool.select` / `ui.key` / `ui.text` | 261-275 |
| `screenshot` | RO, app | `ui.screenshot` as an image block | 282 |
| `call_app` | app | any control-channel method | 283 |

- Arguments are strict: a key not in the tool's schema is refused with the expected list
  (`unknown_argument_error`, `tools.rs:311-332`); keys inside `run_command`'s `params` belong to the command.
- Connected mode validates replies, caps a reply at 16 MiB (`crates/mcp/src/backend.rs:11`) and reconnects
  rather than replaying.
- File confinement: `--automation-read-root DIR` / `--automation-write-root DIR` confine every path a
  command reads (open, pictures, audio, video) and writes (save, export, render output), links followed;
  they apply to the in-process server only and conflict with `--connect`
  (`apps/deckcraft-cli/src/help.rs:127-140`; `crates/engine/src/file_access.rs`; all engine file I/O goes
  through `crates/engine/src/io.rs`).
- The server's system prompt summarises the intended flow: `new_presentation → add_slide →
  add_shape/add_text_box/insert_picture/insert_chart → inspect_slide → render_slide → save_presentation`
  (`crates/mcp/src/server.rs:21-28`).

## Save/export formats

**Open / read** (`crates/engine/src/cmd/file.rs:165-176`):

| Input | Recognised by | Notes |
|---|---|---|
| `.deckcraft` | zip whose stored `mimetype` is `application/vnd.storyteller.deckcraft+zip` (`crates/format/src/lib.rs:17-20`) | Native; legacy `.slidecraft` mimetype still read; unknown fields ignored; `chart-parts/<index>` entries hold retained chart payloads (`crates/format/src/lib.rs:1-29,70,175`) |
| `.pptx` / `.potx` / `.ppsx` | OOXML zip with `[Content_Types].xml` (`crates/pptx/src/lib.rs:49-54`) | Read via `pptx::import`, then repaired (`crates/engine/src/cmd/file.rs:228-256`) |
| password-protected OOXML | `cfb::is_encrypted` (`crates/pptx/src/lib.rs:57-59`) | Refused with a clear message |
| `.txt` / `.md` | by extension | Outline import — Markdown headings become slides (`slide.fromOutline`) |
| `.thmx` (theme; also `.pptx`/`.potx`) | `design.browseTheme {path} \| {name, data}` (`crates/engine/src/cmd/design.rs:19-23,148-174`) | Applies the theme, importing its format-scheme media |

Load budgets for native files: 2 GiB per entry, 4 GiB total media + chart sidecars, 100 000 items
(`crates/format/src/lib.rs:25-29`).

**Save** (`file.save {path?, format?: deckcraft|pptx}`, `file.saveAs {path, format?}`,
`file.saveTemplate {path}`; `crates/engine/src/cmd/file.rs:32-34,427-441`): the format comes from `format?`,
else from the path's extension (`format_for_path`, `file.rs:386-405`). `WRITABLE_EXTENSIONS =
["deckcraft","pptx","potx","ppsx","pdf","png","jpg","jpeg","gif","txt","md"]` (`file.rs:371`).
`save_bytes` understands `pptx|potx|ppsx`, `outline|txt`, `pdf`, `gif`, and falls back to the **native**
format for anything else (`file.rs:292-300`) — so `file.save` to a `.png` path writes native zip bytes; use
`file.export` for images. The CLI refuses unknown output extensions for `convert`/`run --save`/`--export`
up front.

**Export** (`file.export`, `crates/engine/src/cmd/file.rs:36,518-568`):

| Format | Options (all optional unless shown) | Bounds / defaults |
|---|---|---|
| `png` / `jpeg` | `slide?: index`, `all?: bool`, `scale?: px per pt`, `transparentBackground?: bool (png only)` | `scale` default 2, clamped 0.01-16; JPEG quality 92; PNG `pHYs`/JPEG JFIF density = scale × 72 dpi; multiple slides written as `name1.ext, name2.ext…`; all indices validated before any write |
| `pptx` / `potx` / `ppsx` / `deckcraft` | — | potx/ppsx get their own content types (`crates/pptx/src/lib.rs:82-86`) |
| `outline` / `txt` | — | plain-text outline, includes table cell text (`crates/format/src/lib.rs:638,1062`) |
| `pdf` | `layout?: slides\|notes\|handouts`, `perPage?: 1\|2\|3\|4\|6\|9`, `paper?: letter\|a4\|legal\|a3`, `orientation?`, `dpi?`, `slides?: [index]\|"1-3,5"`, `includeHidden?`, `textLayer?`, `frame?` | defaults: slides layout, 6-per-page handouts, letter portrait, dpi 200 (clamped 36-600), hidden excluded, text layer on, frame on (`crates/engine/src/cmd/file.rs:308-330`; `crates/pdf/src/lib.rs:55-105`). Slide artwork is rasterized at the DPI under a selectable real-text overlay (`crates/pdf/README.md:1-6`) |
| `gif` | `width?: px 16-3840 \| small\|medium\|large\|extraLarge`, `secondsPerSlide?: 0.1-600`, `loop?`, `slides?`, `includeHidden?` | width default medium 960 (presets 640/960/1280/1920), 5 s per slide, loop forever; one frame per slide, per-frame 256-colour palette; ≤500 frames and ≤200M total pixels (`crates/engine/src/gif_export.rs:18-35`); result reports `frames, width, height, secondsPerSlide` |

Read-back queries: `file.info`, `file.render {slide?, scale?, edit?, transparentBackground?} → {png: base64,
width, height}` and `file.saveBytes {format?: deckcraft|pptx} → {data: base64}` (`crates/engine/src/cmd/file.rs:35-46`).

## Paths

Per-user runtime paths, not repo paths.

| What | Location | Source |
|---|---|---|
| Settings (`ui.json`, `prefs.json`, `logs/`) | macOS `~/Library/Application Support/DeckCraft`; Windows `%APPDATA%\DeckCraft`; Linux `$XDG_CONFIG_HOME/deckcraft` or `~/.config/deckcraft` | `apps/deckcraft/src/main.rs:56-68` |
| Log file | `<settings>/logs/deckcraft.log`, rotated to `deckcraft.1.log`/`deckcraft.2.log`, capped at 16 MiB | `apps/deckcraft/src/logging.rs:35-40,129` |
| Recovery folder + entries | macOS `~/Library/Application Support/DeckCraft/Recovery`; Windows `%APPDATA%\DeckCraft\Recovery`; Linux `$XDG_DATA_HOME/deckcraft/recovery` — `<uid>.deckcraft` + `<uid>.json`, per-instance `owner-<instance>.lock` | `crates/engine/src/recovery.rs` |
| Dictionaries | `DECKCRAFT_DICTIONARIES` first; macOS `~/Library/Application Support/DeckCraft/Dictionaries`, `~/Library/Spelling`, `/Library/Spelling`; Linux `<xdg data>/deckcraft/dictionaries`, `<xdg data>/hunspell`, `/usr/share/hunspell`, `/usr/share/myspell[/dicts]`, `/usr/local/share/hunspell` | `crates/engine/src/spell.rs:483-500` |
| User dictionary | `<settings>/Dictionaries/user.dic`, one word per line | `crates/engine/src/spell.rs:581-599` |
| Fonts (system scan) | macOS `/System/Library/Fonts`, `/Library/Fonts`, `~/Library/Fonts`, Office cloud-font caches; Windows `%WINDIR%\Fonts`, `%LOCALAPPDATA%\Microsoft\Windows\Fonts`; Linux `/usr/share/fonts`, `~/.fonts`, XDG dirs, fontconfig entries | `crates/fonts/src/fontdb.rs:487-533` |
| Save temporary | `<path>.<pid>.<n>.saving` beside the destination, created exclusively, renamed over it, removed on failure | `crates/engine/src/io.rs:25-52` |

Environment variables:

| Variable | Effect | Source |
|---|---|---|
| `DECKCRAFT_CONTROL_PORT` | default port when `--control` is not given | `apps/deckcraft/src/main.rs:177` |
| `DECKCRAFT_NO_PREFS` | don't load or save `ui.json`/`prefs.json` | `apps/deckcraft/src/main.rs:72,86` |
| `DECKCRAFT_NO_AUDIO` | play media silently (no audio output) | `apps/deckcraft/src/main.rs:120-121` |
| `DECKCRAFT_NO_RECOVERY` | skip AutoRecover writes and the recovery prompt | `apps/deckcraft/src/main.rs:244` |
| `DECKCRAFT_DICTIONARIES` | extra dictionary folders (OS path list) | `crates/engine/src/spell.rs:483` |
| `RUST_LOG` | log filter (default `info` for DeckCraft crates, `warn` otherwise) | `apps/deckcraft/src/logging.rs` |
| `DECKCRAFT_WAYLAND`, `DISPLAY`, `WAYLAND_DISPLAY` | Linux display backend selection | `apps/deckcraft/src/display.rs:51` |
| `CRAFT_FONTS_DIR` | build-time checkout of `storytold/craft-fonts` to embed fonts | `crates/fonts/build.rs:14` |
| `DECKCRAFT_BUILD_SHA`, `DECKCRAFT_BUILD_DATE` | set by the release workflow; shown in About | `crates/ui-egui/src/dialogs.rs:2640-2643` |

Launch surfaces:

- App: `deckcraft [--control PORT] [--sample] [--show] [FILE...]` plus `--help`/`--version`; a `.ppsx`
  given last starts its slide show (`apps/deckcraft/src/main.rs:129-161`); the sample deck is generated in
  code (`crates/engine/src/sample.rs`).
- CLI: `deckcraft-cli` subcommands `info`, `render`, `render-transition`, `convert`, `run`, `commands`,
  `describe`, `app`, `mcp`, `bench`, `links`, `version` (`apps/deckcraft-cli/src/help.rs:9-152`); MCP flags
  `--connect PORT`, `--sample`, `--automation-read-root DIR`, `--automation-write-root DIR` (`help.rs:127-140`).

---

Total commands found at v0.9.0 (`fe510bdac68118f2c9a714e69d0ff572e3f9a0c7`): **320**
(229 ordinary + 55 noundo + 36 query).

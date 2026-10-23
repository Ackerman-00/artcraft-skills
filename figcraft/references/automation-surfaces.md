# FigCraft automation surfaces — operational detail

Load this when a job is bigger than a couple of command calls. Everything here is from the v0.10.0
tree (commit `80f916326fb94f3a88cb24e64f396f564a0ebc06`, tag `v0.10.0`, 2026-10-22); the v0.9.0 →
v0.10.0 delta changed no command, MCP tool, control method, CLI flag or format. Repo-relative paths
only; no machine paths are named.

## 1. Three ways in, one command registry

Every user-visible behaviour is a command in `crates/engine/src/cmd/*` (plus the area modules) with
an id, label, parameter docs and an undo flag (`spec!` macro). The menus, shortcuts, Actions palette,
CLI, control channel, MCP server and WASM plugins all dispatch the same ids (`docs/architecture.md`
› Commands). This tag registers **569 commands** — unique `spec!` ids across 57 id prefixes; the
generated parity checklist still carries the 2026-10-17 measure of 561, eight behind. All 212
catalogued menu items have a command (`crates/engine/src/cmd/mod.rs` `all_commands`,
`docs/parity-checklist.md`; count your build with `figcraft-cli commands --json`).

Largest namespaces: `text` 56, `view` 48, `vector` 40, `object` 28, `select`/`file`/`collab`/
`component`/`tool` 21 each, `proto` 20, `library`/`variable` 18 each.

Discovery, in order of usefulness to an agent:

```sh
figcraft-cli commands --filter component      # id, label, params, shortcut, * = undoable
figcraft-cli commands --json --filter style   # {id, label, params, menu, shortcut, undoable}
```

MCP equivalents: `list_commands {filter}` and the resource `figcraft://command/<id>`.

## 2. `figcraft-cli`

Build: `cargo build --release -p figcraft-cli` → `target/release/figcraft-cli`.
Not inside the macOS `.app` (only the Linux AppImage bundles it as `FigCraft.AppImage cli …`); macOS
releases ship a separate `figcraft-cli-<version>-macos-<arch>.zip`.

| Subcommand | Notes |
|---|---|
| `info <file> [--json]` | Pages, node counts, top-level frames, styles/variables/images. Repairs and import warnings go to stderr as `note:` lines (`notes` in JSON). `missing font` lines / `missingFonts: [{family, layers}]` for fonts the file names that aren't installed. |
| `export <file> -o <out> [--format png\|jpg\|svg\|webp\|pdf\|fig] [--scale N] [--page NAME] [--node ID\|NAME] [--bleed LENGTH] [--crop-marks] [--bleed-marks] [--cmyk]` | `-o` directory → one file per top-level frame (or per top-level layer when there are no frames); `-o` with an image extension → one file for `--node` or the whole page. `--node` takes an id (`12` or `0:12`) or a layer name. Format = `--format`, else the extension, else png. `--scale` default 1, max 64. `--bleed` takes points or `3mm`/`0.125in`, up to 2 in; it also sets the PDF page boxes (MediaBox/BleedBox/TrimBox). A visible tree deeper than 256 descendant levels fails SVG/PDF without touching an existing destination file. |
| `convert <in> <out>` | Format by extension, both ways. In: `.figcraft`, `.json` (FigCraft or REST API), `.fig`, `.svg`, `.png/.jpg/.jpeg/.webp/.gif/.tif/.tiff/.bmp`. Out: `.figcraft`, `.json` (FigCraft JSON), `.svg`, `.png/.jpg/.webp`, `.pdf`, `.fig`. |
| `render <file> -o <out> [--scale N] [--page NAME]` | Whole page with its background, as png, jpg or webp; large pages scale down to fit 16384 px. |
| `run <script.json\|script.jsonl> [--in <file>] [--out <file>]` | Headless command script; one JSON result line per step; **all-or-nothing, one undo step**. No network: it cannot host or join live sessions. |
| `commands [--json] [--filter TEXT]` | The command catalog. |
| `mcp [--attach PORT] [--automation-read-root DIR]… [--automation-write-root DIR]…` | MCP on stdio, headless or attached. The headless session can host, join and publish live sessions (`collab.*`) and use plugin directories (`plugin.directory.*`). |
| `plugin publish <folder> --server ws://host:port/[?key=KEY]` | Publishes a plugin folder to a `figcraft-server` directory; the key comes from the address or `FIGCRAFT_SERVER_KEY` (never printed). Prints name, version, size and SHA-256. |
| `perf [--layers N[,N…]] [--instances N[,N…]]` | Synthetic benchmark tables. Layer sizes clamp to 10–2,000,000; instance workloads default 2000 and cap at 100,000. |

Every subcommand accepts `--no-system-fonts` (or `FIGCRAFT_NO_SYSTEM_FONTS=1`) for
machine-identical text layout, e.g. in CI. Exit code 2 = bad arguments (usage printed), 1 =
failure, 0 = success.

`info`, `export`, `convert`, `render` and `run` also take `--automation-read-root DIR` /
`--automation-write-root DIR` (each repeatable; the folders must exist) and confine every file that
subcommand touches — a run given only a read root cannot write at all (`docs/cli.md` › Confining a
run).

Script shapes accepted by `run`: a JSON array of `{"command": id, "params": {…}}`, an object
`{"commands": […]}` (as `command.batch` takes), or JSON lines (blank lines and `//` comments
skipped). Ids are assigned in order — a new document's first page is id 1, so the first created
layer is 2 — and `{"$step": n}` (zero-based) resolves to the `id` from step *n*'s result, with
`{"$step": n, "field": "…"}` for another field. A script can start from a starter template:
`file.newFromTemplate {template}` as its first step makes the template the document the rest of the
script (and `--out`) acts on. A failing step prints `{"step":i,"command":…,"ok":false,"error":…,
"rolledBack":true}` and exits 1; earlier steps are taken back and `--out` is not written.

## 3. Control channel (`figcraft --control PORT`)

Loopback only (`127.0.0.1`), newline-delimited JSON, one reply per request, in order. The port can
also come from `FIGCRAFT_CONTROL_PORT`. Implementation: `crates/ui-egui/src/control.rs` (methods),
`apps/figcraft/src/control_server.rs` (socket); documented in `docs/control-protocol.md`.

Limits that matter to a client:
- request line ≤ 32 MiB before the newline; a line that is not JSON ends the connection;
- at most 8 active connections, 8 queued requests per queue, 60 s inactivity timeouts on socket
  reads/writes and a 60 s UI timeout; a full queue answers `control request queue is full`;
- methods that need a **drawn** frame (`ui.screenshot`, `ui.input`, `window.new` when the browser
  or a screen reader forces one window) fail at once when the window is minimised or hidden, while
  every state method (`engine.execute`, `document.inspect`, `node.get`, `ui.inspect`, `ui.pointer`,
  `ui.key`, `ui.type`, `ui.set`, `ui.render`, `window.list`) keeps working (~0.1 s per request
  while minimised).

Coordinates are page units, y down. `x`/`y` in `node.create`/`node.set` are relative to the parent
frame (groups have no coordinate space of their own). Every method takes an optional `window` id
(0 = main; `window.list` enumerates).

| Method | Params / result |
|---|---|
| `engine.execute` | `{command, params?}` → the command's result. Same ids as menus/CLI/MCP. |
| `engine.commands` | `{}` → the command catalog. |
| `document.inspect` | `{depth?, allPages?}` → document JSON. |
| `node.get` | `{id, depth?}` → one layer, including `pluginData` and Dev Mode fields when present. |
| `ui.inspect` | `{}` → panels, tool, canvas work/latency, presenter/preview, import report, focus region, `uiScale`, windows. |
| `ui.pointer` | `{kind, x, y, to?, steps?, shift?, alt?, cmd?, ctrl?, pressure?, pressureTo?}` — mouse/pen gesture with the current tool. |
| `ui.key` | `{key, shift?, alt?, cmd?, ctrl?}` — a key or shortcut as if typed on the canvas. |
| `ui.type` | `{text}` — type into the text editor. |
| `ui.input` | `{events}` — raw window events: move/down/up/key/text/scroll/leave, `{hold:{alt?,shift?,cmd?}}`, `{gamepad:…}`. Needs a drawn frame. |
| `ui.menu.invoke` | `{id}` — invoke a menu item by command id. |
| `ui.set` | Panel/mode switches: right/left tabs, theme, home section/search/recents view/sort, Actions palette, main menu, variables editor, layer filter, style picker, prototype editor, context menu, comment panel, Dev Mode compare, plugins window, icon gallery, and more (`docs/control-protocol.md` has the full key list). Returns the new `ui.inspect`. |
| `ui.screenshot` | `{path?}` → PNG of the whole window with UI chrome; without `path`, base64 `{format:"png",width,height,data}`. Needs a visible window. |
| `ui.render` | `{path?, scale?, ids?}` → PNG of the document without UI chrome; works without a visible window. |
| `window.new` | `{path?, index?}` → `{window}`; moves an open file or opens a path/new file. Browser/screen-reader builds keep one window. |
| `window.list` | `{}` → every window with tabs, active file and focus. |
| `window.focus` | `{id}` → bring a window forward; later requests go there. |
| `app.quit` | `{}` — close the app without asking about unsaved changes. |

```
{"id":1,"method":"engine.execute","params":{"command":"shape.rectangle","params":{"x":10,"y":10,"width":100,"height":50}}}
{"id":1,"ok":true,"result":{"id":2}}
{"id":2,"method":"engine.execute","params":{"command":"node.set","params":{"ids":[2],"props":{"fill":"#FF6B6B","cornerRadius":8}}}}
{"id":3,"method":"ui.screenshot","params":{"path":"shot.png"}}
{"id":4,"method":"document.inspect","params":{"depth":4}}
```

Without a `path`, `ui.screenshot` / `ui.render` return the PNG as base64, so an attached agent writes
no temporary files.

## 4. MCP server

Speaks newline-delimited JSON-RPC 2.0 over stdio (protocol `2025-06-18`; `2025-03-26` and
`2024-11-05` accepted). Incoming lines are capped at 32 MiB before the newline. 18 tools, two
resources plus two resource templates, four prompts (`crates/mcp/src/tools.rs`, `resources.rs`,
`prompts.rs`, `server.rs`; `docs/mcp.md`).

Client config (MCP clients usually need an absolute path; substitute your own):

```json
{"mcpServers": {"figcraft": {"command": "<path to figcraft-cli>", "args": ["mcp"]},
                "figcraft-app": {"command": "<path to figcraft-cli>", "args": ["mcp", "--attach", "7979"]}}}
```

Headless = an in-process session with one untitled document, CPU renders, no window. Attached =
drives the running app, so the user sees the work.

| Tool | What it does |
|---|---|
| `list_commands {filter?}` | Every command: id, label, menu, shortcut, undoable, params doc. |
| `run_command {command, params}` | Run any command. One undo step for a mutating command; a failure leaves the document unchanged. Programmatic calls never open dialogs. |
| `batch {commands:[{command,params}], label?}` | Several commands as one undo step (`command.batch`), all-or-nothing for documents and their state. `{"$step": n}` references an earlier step's `id`. Preferences, clipboard, tool state and UI requests are not rolled back. |
| `create_node {type, x?, y?, width?, height?, parent?, index?, name?, text?, path?, props?}` | Create a frame, rectangle, ellipse, polygon, star, line, arrow, text, vector, section, component or slice; returns `{id, node}`. |
| `set_properties {ids?, props}` | `node.set` on layers: geometry, fills, strokes, effects, radius, auto layout, sizing, constraints, masks, Dev Mode status, text, `pluginData`, etc. Returns the updated layers. |
| `inspect_document {depth?, allPages?}` | The document as JSON: layer tree, styles, variables, selection, undo history. |
| `get_node {id, depth?}` | One layer as JSON; `pluginData` when written with `set_properties`. |
| `select {ids}` | Replace the selection (`[]` deselects). |
| `export {ids?, format?, scale?\|size?, path?, bleed?, cropMarks?, bleedMarks?, cmyk?, contentsOnly?, includeBoundingBox?, svgOutlineText?, svgIdAttribute?, svgSimplifyStroke?}` | png/jpg/svg/webp/pdf, or `fig` (whole file, experimental). Without `path`, images come back as image content, SVG as text, others as base64. |
| `screenshot {ids?, scale?, maxSize?, window?}` | PNG of the page/layers scaled to fit `maxSize` (default 1600). `window: true` captures the attached app window; headless renders the document. |
| `open_file {path, variables?}` | Open `.figcraft`, `.json` (FigCraft/REST), `.fig` (best effort), `.svg` or an image. Returns `summary`, `warnings` or `repairs`. |
| `save_file {path?}` | Save as `.figcraft`; `path` required first time. A `.fig` path writes an experimental export copy and leaves the native path/unsaved state alone. |
| `undo` | Undo the last change (one command, batch or gesture). |
| `redo` | Redo the last undone change. |
| `pointer {kind, x, y, to?, steps?, tool?, shift?, alt?, cmd?, pressure?, pressureTo?}` | Mouse/pen gesture in page coordinates: click, double, drag, down, move, up, hover. |
| `key {key, shift?, alt?, cmd?}` | A shortcut or key as if typed on the canvas; while editing text, editing keys go to the editor. |
| `type_text {text, id?}` | Type into the text being edited, or replace text layer `id`'s contents. |
| `inspect_ui {}` | Tool, view, status, panels, timings and the app's windows when attached. |

Resources: `figcraft://document`, `figcraft://commands`, `figcraft://node/{id}`,
`figcraft://command/{id}`. Prompts: `mobile_screen`, `design_system`, `landing_page`,
`prototype_flow` — each returns a step-by-step plan naming tools and verification.

Semantics an agent must respect:
- one mutation = one undo step; `batch` makes several steps one, **all-or-nothing** for documents
  and their state; failed inner steps are removed from the journal;
- programmatic calls never open dialogs (they are dropped);
- attached calls are never auto-replayed after a transport failure — the error says the operation
  may already have completed, so inspect before retrying; an idle-closed connection is replaced on
  the next call;
- `screenshot {window: true}` needs a visible window; `screenshot` without `window` renders the
  document instead;
- headless text uses built-in plus system fonts (`--no-system-fonts` /
  `FIGCRAFT_NO_SYSTEM_FONTS=1` pins the built-ins for CI); attached, the app's fonts apply.

## 5. File-access confinement

```sh
figcraft-cli mcp --automation-read-root WORK/project --automation-write-root WORK/project/out
figcraft --control 7979 --automation-read-root WORK/project --automation-write-root WORK/project/out
figcraft-cli render in/doc.figcraft -o out/ok.png --automation-read-root in --automation-write-root out
```

- reads must be inside a read **or** write root; writes only inside a write root; everything else
  is refused with a readable error and nothing is written;
- the roots must be existing folders or the server/app stops at startup (as does any unknown app
  option — a mistyped flag never leaves the app running unconfined);
- every engine file access goes through `crates/engine/src/file_access.rs` (clippy forbids
  `std::fs` elsewhere in the engine), so commands added later are covered too;
- `--attach` plus roots is a usage error: the app does the confining, so start it with the flags;
- path resolution follows symlinks; a non-existent tail must be plain names; a refusal deliberately
  does not reveal what exists outside. Recent files outside the roots are never listed or opened;
- not confined: the files named on the app's own command line at startup (later saves of them are
  confined), and the app's own folders (preferences, recovery copies, plugins installed from a
  plugin directory).

## 6. Document and format details

`.figcraft` (zip) members, from `crates/format/src/lib.rs`:

| Member | Content |
|---|---|
| `document.json` | `{format:"figcraft", version:1, imageIndex:[{hash,width,height}], …document}` — default-valued fields omitted |
| `images/<sha256>` | Raw encoded image bytes (stored, not deflated) |
| `thumbnail.png` | Optional |
| `versions/index.json`, `versions/<id>.json` | Version history, oldest first, ≤100 versions |
| `branches/index.json`, `branches/<id>/{base,head}.json`, `branches/<id>/versions/` | Branches, ≤100 |
| `library/manifest.json`, `library/document.json`, `library/images/<sha256>` | Present when the file was published as a library |

Reading: a bare `document.json` also opens; structural problems are repaired and reported through
`issues`; a `version` newer than 1 is refused (`FormatError::Newer`); damaged version/library entries
are skipped with a note. `document.json` is capped by a 16× compression-ratio rule within the
512 MiB per-member cap (4 GiB unpacked on 64-bit, 1 GiB on 32-bit). Writing: staging file + one
atomic rename (`write_file_atomic`), so a reader sees the old or the complete new file.

Import warnings surface per format: `.fig`, REST JSON and SVG return `warnings` (MCP `open_file`)
and `note:` lines (CLI), and fill the app's Import report window (only for files the *user* opened;
commands and MCP `open_file` return the counts as `summary` instead).

Export surfaces:
- `file.export` formats: png, jpg, svg, pdf, webp, and fig (whole file, experimental);
- `file.exportLayers` writes every layer once per export setting, with suffixes/folders, or the
  Inspect assets (icons as SVG, images as PNG);
- `file.exportFramesPdf` writes every top-level frame of a page, one PDF page each;
- `convert` adds `.json` (FigCraft JSON) and `.figcraft` output; the app's Save always writes the
  native archive, and a `.fig` path on Save/Save as writes an export copy without changing the
  document's native path.

## 7. Live sessions from a script (`collab.*`)

There are **21 `collab.*` commands** at this tag. The headless MCP session and the attached app can
host, join and publish; the app can do all of them; the one-shot `run` cannot (no network link). The
web build can only join.

| Group | Commands |
|---|---|
| Host/join/share | `collab.host` (port 47900 default, `bind: local\|lan\|IP`), `collab.share {via?, access?, server?, name?, port?, bind?}`, `collab.join {code\|link}`, `collab.stop`, `collab.leave` |
| Publishing | `collab.publish {server, name?, key?}`, `collab.serverInfo {server}`, `collab.manageFile {file, action: links\|createLink\|revoke\|share\|unshare\|rename\|remove, server?, owner?}`, `collab.files {refresh?}`, `collab.openFile {file, server?}`, `collab.forgetFile {file, server?}`, `collab.recoverFile {path, file, server?, session, client, seq}`, `collab.report {reason}` |
| Presence/inspection | `collab.peers`, `collab.diff {against?}`, `collab.follow {client?}`, `collab.spotlight {on?}`, `collab.removePerson {client}`, `collab.cursor {x?,y?}`, `collab.cursorChat {text?}` |

`collab.registerLinks {on?}` is app-level: it makes the Windows build the opener of `figcraft://`
invite links (macOS and Linux packages declare the scheme at install time).

**Caution:** `collab.share` with `via: "online"` (its default) publishes the document to a server
other people run — the public default unless Preferences name another. Only call it when sharing is
the request; prefer `collab.host` (local, no server) for a demo. Codes and links are the only access;
there are no accounts. The server stores files unencrypted, and the default public server keeps a
file until removed or 30 days unopened.

## 8. Server (preview)

`figcraft-server` (`cargo build --release -p figcraft-server`; releases ship a Linux build) has
subcommands: `serve` (default), `key [--rotate]`, `check`, `files [list] [--sort size\|age\|idle]`,
`files remove`, `links list\|create\|revoke`, `plugins [list\|remove] [--version N]`, `reports`,
`block-ip`, `unblock-ip`, `blocked` (`apps/figcraft-server/src/cli.rs`, `docs/server.md`).

Config keys include `listen` (default `127.0.0.1:47900`), `data` (default `figcraft-data`),
`public_url`, `max_files`, `max_file_mb`, `max_links`, `max_connections`, `max_people`,
`compact_after`/`compact_mb`, `max_plugins`/`max_plugin_mb`/`max_plugins_mb`, `open_publish`,
`operator_contact`, `terms_url`, `trusted_proxy`, `idle_days`, `max_total_mb`, and the per-address
limits `max_files_per_ip`, `max_mb_per_ip`, `max_connections_per_ip`, `connects_per_minute`,
`publishes_per_hour`, `messages_per_second` (`apps/figcraft-server/src/config.rs`). `GET /healthz`
answers `ok`. Deploy on a Linux box with a TLS reverse proxy; the desktop app connects over `wss://`
with certificates verified (`FIGCRAFT_CA_FILE` for a private authority).

## 9. Recipes that match the semantics

Build a screen headlessly, then export it:

```json
[
  {"command": "file.newFromTemplate", "params": {"template": "mobile-app"}},
  {"command": "frame.create", "params": {"preset": "iPhone 16", "x": 0, "y": 0, "name": "Home"}},
  {"command": "node.create", "params": {"type": "text", "parent": {"$step": 1}, "x": 24, "y": 64,
    "text": "Welcome", "props": {"fontSize": 32, "fontStyle": "Bold"}}}
]
```

```sh
figcraft-cli run build.json --out home.figcraft
figcraft-cli export home.figcraft -o out/ --format png --scale 2
figcraft-cli info home.figcraft --json
```

Attach to a running app and verify after each change (replace `2` with the id your create call
returned):

```json
{"id":1,"method":"engine.execute","params":{"command":"layout.add","params":{"ids":[2],"direction":"vertical"}}}
{"id":2,"method":"document.inspect","params":{"depth":3}}
{"id":3,"method":"ui.render","params":{"ids":[2],"path":"out/card.png"}}
```

Use `document.inspect`/`get_node` after every batch, and `screenshot`/`ui.render` before declaring a
design done. A failed command is not a partial success: check `ok`, then inspect the document.

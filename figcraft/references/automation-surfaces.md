# FigCraft automation surfaces — operational detail

Load this when a job is bigger than a couple of command calls. All of it is from the v0.7.0 tree
(commit `47438dd4a2e8b49a7e6bb3dfd480262dadc37f12`).

## 1. Three ways in, one command registry

Every user-visible behaviour is a command in `crates/engine/src/cmd/*` with an id, label, parameter
docs and an undo flag (`spec!` macro). The menus, shortcuts, Actions palette, CLI, control channel,
MCP server and WASM plugins all dispatch the same ids (`docs/architecture.md` › Commands). The
catalog carries 212/212 of the reference menu items and 561 registered commands
(`docs/parity-checklist.md`).

Discovery, in order of usefulness to an agent:

```sh
figcraft-cli commands --filter component      # human-readable: id, label, params, shortcut, * = undoable
figcraft-cli commands --json --filter style   # machine-readable: {id, label, params, menu, shortcut, undoable}
```

MCP equivalents: `list_commands {filter}` and the resource `figcraft://command/<id>`.

## 2. `figcraft-cli`

Build: `cargo build --release -p figcraft-cli` → `target/release/figcraft-cli`.
Not inside the macOS `.app` (only the Linux AppImage bundles it).

| Subcommand | Notes |
|---|---|
| `info <file> [--json]` | Pages, node counts, top-level frames, styles/variables/images. Repairs and import warnings go to stderr as `note:` lines (`notes` in JSON). |
| `export <file> -o <out> [--format png\|jpg\|svg\|webp\|pdf\|fig] [--scale N] [--page NAME] [--node ID\|NAME] [--bleed LENGTH] [--crop-marks] [--bleed-marks] [--cmyk]` | `-o` directory → one file per top-level frame; `-o` with an image extension → one file for `--node` or the whole page. `--node` accepts an id (`12` or `0:12`) or a layer name. Format = `--format`, else the extension, else png. `--scale` default 1, max 64. |
| `convert <in> <out>` | Format by extension, both ways: `.figcraft`, `.json` (FigCraft or REST API), `.fig`, `.svg`, `.png/.jpg/.jpeg/.webp/.gif/.tif/.bmp` in; `.figcraft`, `.json`, `.svg`, `.png/.jpg/.webp`, `.pdf`, `.fig` out. |
| `render <file> -o <out.png> [--scale N] [--page NAME]` | Whole page with its background; large pages scale down to fit 16384 px. |
| `run <script.json\|script.jsonl> [--in <file>] [--out <file>]` | Headless command script; one JSON result line per step; **all-or-nothing, one undo step**. |
| `commands [--json] [--filter TEXT]` | The command catalog. |
| `mcp [--attach PORT] [--automation-read-root DIR]… [--automation-write-root DIR]…` | MCP on stdio, headless or attached. |
| `plugin publish <folder> --server ws://host:port/[?key=KEY]` | Publishes a plugin folder to a `figcraft-server` directory; key read from the address or `FIGCRAFT_SERVER_KEY`. |
| `perf [--layers N[,N…]] [--instances N[,N…]]` | Synthetic benchmark tables. |

Every subcommand accepts `--no-system-fonts` (or `FIGCRAFT_NO_SYSTEM_FONTS=1`) for machine-identical
text layout, e.g. in CI. Exit code 2 = bad arguments (usage printed), 1 = failure, 0 = success.

Script shapes accepted by `run`: a JSON array of `{"command": id, "params": {…}}`, an object
`{"commands": […]}` (as `command.batch` takes), or JSON lines (blank lines and `//` comments skipped).
Ids are assigned in order — a new document's first page is id 1, so the first created layer is 2 —
and `{"$step": n}` (zero-based) resolves to the `id` from step *n*'s result, with
`{"$step": n, "field": "…"}` for another field.

## 3. Control channel (`figcraft --control PORT`)

Loopback only (`127.0.0.1`), newline-delimited JSON, one reply per request, in order.
Implementation: `crates/ui-egui/src/control.rs` (methods), `apps/figcraft/src/control_server.rs`
(socket); documented in `docs/control-protocol.md`.

Limits that matter to a client:
- request line ≤ 32 MiB before the newline; a line that is not JSON ends the connection;
- at most 8 active connections, 8 queued requests per queue, 60 s inactivity timeouts on socket
  reads/writes and a 60 s UI timeout; a full queue answers `control request queue is full`;
- methods that need a **drawn** frame (`ui.screenshot`, `ui.input`, `window.new` when the browser or a
  screen reader forces one window) fail immediately when the window is minimised or hidden, while
  state methods (`engine.execute`, `document.inspect`, `node.get`, `ui.inspect`, `ui.pointer`,
  `ui.key`, `ui.type`, `ui.set`, `ui.render`, `window.list`) keep working.

Coordinates are page units, y down. `x`/`y` in `node.create`/`node.set` are relative to the parent
frame. Every method takes an optional `window` id (0 = main; `window.list` enumerates).

```
{"id":1,"method":"engine.execute","params":{"command":"shape.rectangle","params":{"x":10,"y":10,"width":100,"height":50}}}
{"id":1,"ok":true,"result":{"id":2}}
{"id":2,"method":"engine.execute","params":{"command":"node.set","params":{"ids":[2],"props":{"fill":"#FF6B6B","cornerRadius":8}}}}
{"id":3,"method":"ui.screenshot","params":{"path":"/tmp/shot.png"}}
{"id":4,"method":"document.inspect","params":{"depth":4}}
```

Without a `path`, `ui.screenshot` / `ui.render` return the PNG as base64, so an attached agent writes
no temporary files.

## 4. MCP server

Speaks newline-delimited JSON-RPC 2.0 over stdio (protocol `2025-06-18`; `2025-03-26` and
`2024-11-05` accepted). 18 tools, four resources, four prompts (`crates/mcp/src/tools.rs`,
`resources.rs`, `prompts.rs`; `docs/mcp.md`).

Client config (absolute path required):

```json
{"mcpServers": {"figcraft": {"command": "/path/to/figcraft-cli", "args": ["mcp"]},
                "figcraft-app": {"command": "/path/to/figcraft-cli", "args": ["mcp", "--attach", "7979"]}}}
```

Headless = an in-process session with one untitled document, CPU renders, no window.
Attached = drives the running app, so the user sees the work.

Semantics an agent must respect:
- one mutation = one undo step; `batch` makes several steps one, **all-or-nothing** for documents and
  their state (preferences, clipboard, tool state and UI requests are not rolled back);
- a failing command leaves the document as it was; failed inner batch steps are removed from the
  journal;
- programmatic calls never open dialogs (they are dropped);
- attached calls are never auto-replayed after a transport failure — the error says the operation may
  already have completed, so inspect before retrying;
- `screenshot {window: true}` needs a visible window; `screenshot` without `window` renders the
  document instead.

## 5. File-access confinement

```sh
figcraft-cli mcp --automation-read-root /work/project --automation-write-root /work/project/out
figcraft --control 7979 --automation-read-root /work/project --automation-write-root /work/project/out
```

- reads must be inside a read **or** write root; writes only inside a write root; everything else is
  refused with a readable tool error and nothing is written;
- the roots must be existing folders or the server/app stops at startup;
- every engine file access goes through `crates/engine/src/file_access.rs` (clippy forbids `std::fs`
  elsewhere in the engine), so commands added later are covered too;
- `--attach` plus roots is a usage error: the app does the confining, so start it with the flags;
- not confined: the files named on the app's own command line at startup, and the app's own folders
  (preferences, recovery copies, installed plugins);
- path resolution follows symlinks; a non-existent tail must be plain names; a refusal deliberately
  does not reveal what exists outside.

## 6. Document and format details

`.figcraft` (zip) members, from `crates/format/src/lib.rs`:

| Member | Content |
|---|---|
| `document.json` | `{format: "figcraft", version: 1, imageIndex: [{hash,width,height}], …document}` — default-valued fields omitted |
| `images/<sha256>` | Raw encoded image bytes (stored, not deflated) |
| `thumbnail.png` | Optional |
| `versions/index.json`, `versions/<id>.json` | Version history, oldest first, ≤100 versions |
| `branches/index.json`, `branches/<id>/{base,head}.json`, `branches/<id>/versions/` | Branches, ≤100 |
| library entries | Present when the file was published as a library |

Reading: a bare `document.json` also opens; structural problems are repaired and reported through
`issues`; a `version` newer than 1 is refused (`FormatError::Newer`); damaged version/library entries
are skipped with a note. Writing: staging file + one atomic rename (`write_file_atomic`), so a reader
sees the old or the complete new file, never a partial one.

Import warnings surface per format: `.fig`, REST JSON and SVG return `warnings` (MCP `open_file`)
and `note:` lines (CLI).

## 7. Server (preview)

`figcraft-server` (`cargo build --release -p figcraft-server`; releases ship a Linux build) has its
own subcommands: `serve` (default), `key [--rotate]`, `check`, `files [list] [--sort size|age|idle]`,
`files remove`, `links list|create|revoke`, `plugins [list|remove]`, `reports`, `block-ip`,
`unblock-ip`, `blocked`. Config keys include `listen`, `data`, `public_url`, `max_files`,
`max_file_mb`, `max_links`, `max_connections`, `max_people`, limits per IP and per minute, plus
`open_publish`, `operator_contact`, `terms_url`, `idle_days` for a public server (`apps/figcraft-server/src/cli.rs`,
`docs/server.md`). `GET /healthz` answers `ok`. Deploy on a Linux box with a TLS reverse proxy; the
desktop app connects over `wss://` with certificates always verified (`FIGCRAFT_CA_FILE` for a
private authority).

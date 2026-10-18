# WordCraft skill — evidence table

Repo inspected read-only at HEAD `f2e15cf8f899a79899a2d9595ca4ce7df1e5ea22` (tag v0.8.0, "Release 0.8.0"),
2026-10-18. Installed bundle `/Applications/WordCraft.app` = same commit (`Info.plist`
`WordCraftBuildCommit`). Lines below are from that tree.

| # | Claim in SKILL.md | Evidence (repo-relative) | Tier |
|---|---|---|---|
| 1 | Clean-room reimplementation of Microsoft Word; alpha; MIT OR Apache-2.0; repo storytold/wordcraft | README.md:13; ROADMAP.md:3,44–52; Cargo.toml:9,11 | implemented (self-described; license files present) |
| 2 | 487/502 (97.0%) of the Word ribbon/menu catalog has live commands; floor enforced by test | docs/parity-checklist.md:5; `crates/engine/src/catalog.rs::parity_floor` (asserts ≥ 90.4%) | implemented (generated doc + test) |
| 3 | Command counts are inconsistent across docs (422 README / 433 ROADMAP / "over 270" mcp.md) | README.md:98; ROADMAP.md:26; docs/mcp.md:85 | claimed (numbers), registry itself implemented — `crates/engine/src/cmd/mod.rs::registry`, list with `wordcraft-cli commands` |
| 4 | Dogfooded .docx read+write (ECMA-376), incl. Strict read; .docm/.dotx/.dotm with macros kept, never run | `crates/docx/src/lib.rs` (read/write/write_as, read_xml); `crates/engine/src/io_ext.rs:9,26–28`; docs/file-format-parity.md:38–40 | implemented (synthetic tests only — gap #1, "never tested on real-world files") |
| 5 | `.doc`/`.dot` Word 97-2003 read-only; Word 6/95 refused; no writer | `crates/docbin/src/lib.rs:1–9` ("There is no writer"); docs/file-format-parity.md:41; docs/gaps.md:40 | implemented (read), not implemented (write) |
| 6 | Formats opened: docx, docm, dotx, dotm, doc, dot, txt, md, markdown, html, htm, rtf, odt, tex, latex, ltx, xml, json, *.wcraft.json | `crates/engine/src/io.rs:9–29` OPEN_EXTS; `crates/formats/src/lib.rs::EXTENSIONS` | implemented |
| 7 | Formats saved: docx, docm, dotx, dotm, pdf, txt, md, html, rtf, odt, tex, png, json, xml | `crates/engine/src/io.rs:31` SAVE_EXTS; `crates/engine/src/io_ext.rs:24–39` | implemented |
| 8 | PDF export with selectable text/links/bookmarks (krilla via pinned craft-pdf); Print Markup mode | `crates/engine/src/io_ext.rs:33–36`; Cargo.toml:55; docs/file-format-parity.md:42 | implemented (~80% fidelity estimated by repo) |
| 9 | Password-protected `.docx` opens and saves (agile encryption); `.doc` password support documented inconsistently | `crates/docx/src/crypt.rs` (encrypt/decrypt/check_password exported, engine test `password_protected_documents_round_trip`); docs/file-format-parity.md rows 52 vs 54–55 contradict each other | implemented (docx, synthetic tests); `.doc` = **uncertain — see docs/file-format-parity.md** |
| 10 | CLI subcommands and flags as documented | `apps/wordcraft-cli/src/main.rs:15–57` (USAGE), `:305–521` (dispatch), `:226–246` (option tables), `:558–567` (exit codes) | implemented |
| 11 | `render` defaults page 1, scale 2.0; `convert *.png` exports page 1 only; failure leaves no output file | apps/wordcraft-cli/src/main.rs:320–321, 351–359, 869–892 (test `render_and_run_valid_options_and_defaults_produce_files`) | implemented |
| 12 | MCP server on stdio with the listed tools + resources; app-only screenshot/click/key/ui_inspect | `crates/mcp/src/tools.rs:55–155`, `:168–275`; docs/mcp.md:81–102 | implemented |
| 13 | Headless MCP file confinement via `--automation-read-root`/`--automation-write-root`; error with `--connect`; desktop app not confined | apps/wordcraft-cli/src/main.rs:205–223, 436–478, tests 643–726; docs/mcp.md:27–79 | implemented (headless only) |
| 14 | Control channel: JSON lines on 127.0.0.1, per-window key, method list, key file path/mode | docs/control-protocol.md:3–72; `crates/control-key/src/lib.rs` (settings_dir, key_path); `apps/wordcraft/src/control_server.rs:1–10` | implemented (desktop app only; web has none) |
| 15 | `file.close` errors on unsaved changes over control channel unless `{"force":true}` | docs/control-protocol.md:79–86; `crates/engine/src/cmd/file.rs:112–118` | implemented |
| 16 | `review.trackChanges` toggles when `value` is omitted (footgun); `--author`/`file.setAuthor` name the agent | docs/mcp.md:18–25; `crates/engine/src/cmd/review.rs:27`; `crates/engine/src/cmd/file.rs:122–124`; cli test `author_flag_names_the_headless_session` | implemented |
| 17 | Macros record/replay command sequences | `crates/engine/src/cmd/tools.rs:349–363`; README.md:162–163 | implemented |
| 18 | Desktop app flags `--sample`, `--control PORT`, `[FILE…]`; bad port exits 2 | `apps/wordcraft/src/main.rs:266–302` | implemented |
| 19 | `wordcraft-cli` is a separate release artifact, not inside the app bundle | packaging/macos/package.sh:5,44,206–217; `/Applications/WordCraft.app/Contents/MacOS/` contains only `WordCraft`; nothing named wordcraft-cli on this machine's PATH/Applications (checked) | implemented (packaging); install state = **not installed here** |
| 20 | WebAssembly build exists, checked in CI; no TCP control channel in the web build; trunc flags `?sample`, `?webgl` | `apps/wordcraft-web/src/main.rs:1–8`; apps/wordcraft-web/Trunk.toml; xtask/src/main.rs:124–153 (`wasm` step in `ci`) | implemented (repo states web works; not exercised by this agent) |
| 21 | Local recovery of unsaved work, desktop only; headless sessions create none; unencrypted; newest edits can be lost | docs/recovery.md:1–56; engine test scope listed at docs/recovery.md:67–70 | implemented (documented limits) |
| 22 | Native printing via craft-print (`ui.printSettings`, `ui.printSubmit`, `file.printPdf`); print-dialog depth gap | docs/control-protocol.md:88–103; `crates/ui-egui/src/printing.rs:14–17`; docs/gaps.md:32 | implemented (partial parity per gaps #6) |
| 23 | Silent loss: charts/SmartArt/OLE cannot be edited; native ink forms dropped; no 3D models; no legacy form fields | docs/gaps.md:30,31,39; docs/file-format-parity.md:89–92 | partial / not implemented |
| 24 | RTF/ODT/HTML write fidelity ~50–60%; Word 2003 XML write drops shapes/charts/equations etc. | docs/file-format-parity.md:44–50 | partial |
| 25 | Proofing only English, Polish, Portuguese, Italian, Croatian, Turkish, Russian (+Czech spelling); 54 dialogs vs ~100 | docs/gaps.md:35,33 | partial |
| 26 | Mail merge sources: csv/tsv/txt (+encodings), xlsx/xlsm/xls/ods; no Outlook/Access/email merge | `crates/formats/src/sheet.rs`; crates/engine/src/cmd/mailings.rs:335,456; docs/gaps.md:47 | implemented (partial per gaps #21) |
| 27 | One document per window, no tabs; no Side-by-Side window commands yet | `crates/ui-egui/src/lib.rs:420–421` (single `Session`); docs/gaps.md:52 | implemented (single-doc model) / not implemented (window commands) |
| 28 | Headless UI screenshots via `cargo run -p wordcraft-ui-egui --example ui_shot` | `crates/ui-egui/examples/ui_shot.rs:1–14` | implemented |
| 29 | Logs at `<settings>/logs/wordcraft.log`, rotated, `RUST_LOG` honoured | README.md:165–182; `apps/wordcraft/src/logging.rs` (663 lines) | implemented |
| 30 | Zotero integration requires the Zotero desktop app | `crates/zotero` (Command enum, client, bridge); docs/zotero.md:1–30; cli `zotero` subcommand main.rs:479–516 | implemented (external dependency) |

Notes for the orchestrator:
- Rows 4, 9, 23–26 are the ones an agent reviewer should spot-check; the repo is unusually
  self-honest, but its own docs carry stale rows (e.g. file-format-parity.md row 52 vs 54–55 on
  encryption; several "README claims" such as the 422-command count drift from ROADMAP.md).
- No claim in SKILL.md comes from running the app: nothing was launched, built or modified.
  Every statement traces to a file path above.

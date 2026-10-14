# ArtCraft Skill Authoring Brief (universal — one agent per app repo)

You are one of 13 parallel agents. Your job: produce an evidence-grounded SKILL.md that teaches an AI coding agent **what one ArtCraft desktop app can and cannot do, and how to use/drive it correctly** on macOS. Ironclad means: **every claim traceable to the repo — zero fabrication.**

## Your inputs
- The app's source repo is the CURRENT WORKING DIRECTORY (`--dir` was set for you). Treat it read-only — never modify, build, or commit anything.
- Shared libraries live in the `craft-libs` repo, cloned alongside the app repos in your working directory (see MAINTENANCE.md Step 1) — it holds shared file formats and components used across all Craft apps; consult it when the app repo alone doesn't explain a file format or shared behavior.
- The app is also installed on the authoring machine at `/Applications/<AppName>.app` (installed via ArtCraft Launcher, auto-update on). You may inspect the bundle's `Contents/Info.plist` (version, CFBundleIdentifier) — but **do not launch the GUI app**; the agent reading your skill later must not depend on live GUI state.

## Grounding rules (violating these = failed task)
1. Read at minimum: `README.md`, `Cargo.toml` (workspace members, dependencies), any `docs/` directory, and the CLI/argument-parsing code (search for `clap`, `Parser`, `Args`, `std::env::args`).
2. Every capability you document must have an evidence pointer: a repo-relative file path (e.g. `crates/pc-core/src/export/png.rs`) and, where useful, a symbol or line reference. Add the pointer in parentheses after the claim.
3. Actively separate three tiers and label them: **implemented** (code path exists and is wired into UI/CLI), **partial/stub** (code exists but visibly incomplete — say what's missing), **not implemented / roadmap** (claimed in README or issue templates but absent from code).
4. File formats: only list extensions the code actually reads/writes (grep for extension strings, `save`, `open`, `export`, `import`). Name the module that handles each.
5. Never invent keyboard shortcuts, menu labels, CLI flags, or format names. If the README mentions a feature you cannot find in code, put it under "claimed but unverified".
6. The repo is HEAD of main; the installed app may be older (launcher ships releases). Where HEAD may be ahead of the installed release, add one line: "verify against your installed version".
7. If you are uncertain about something after searching, write "uncertain — see <file>" instead of guessing. Honesty about gaps is required, not optional.

## Required SKILL.md structure (uniform across all 13 skills)
YAML frontmatter:
- `name`: the app name, lowercase (e.g. `photocraft`) — must match the directory name.
- `description`: pushy trigger text (models under-trigger skills). State what it does AND when to trigger: whenever the user mentions this app by name, asks about its capabilities/file formats/keyboard shortcuts, wants to automate or script it, prepare assets for it, verify its output, or troubleshoot it — even if they don't name the app but describe its job (e.g. "edit this photo" → photocraft skill).

Body sections, in this order (keep total under ~400 lines; push deep detail into optional `references/*.md` files next to SKILL.md and point to them):
1. `## Overview` — 3–6 sentences: what it is, the clean-room target it reimplementation-style mirrors (from the repo description, e.g. "clean-room reimplementation of Avid Pro Tools"), maturity (alpha/in-development), and where the source lives (GitHub org `storytold`, repo name).
2. `## Capabilities (verified)` — grouped bullets, each with its evidence path. Cover: core editing/creation features, import/open formats, save/native project format, export formats, any scripting/CLI/automation surface, platform notes (WebAssembly build? yes/no per repo).
3. `## Known limitations and not-implemented` — what the app cannot do yet (from TODOs, stubs, missing modules, README admissions). This section prevents agents from assigning the app impossible work.
4. `## How to operate` — launch on macOS (`open -a "<AppName>"`; binary path), any real CLI flags found in code, the main document/window model (one doc? tabs?), core workflow concepts (layers, tracks, keyframes — whatever applies), and the open/save/export flow with exact format names.
5. `## Working with an AI agent` — what an agent can legitimately do around the app: prepare inputs (generate/importable assets, batch-convert sources into supported formats), interpret/repair native project files (if format is documented in code), verify exports, and what it must NOT attempt (drive the GUI blind, assume unsupported formats).
6. `## Verification protocol` — the alpha-software discipline: throwaway round-trip test (new → edit → save → export → reopen elsewhere), never trust a silent export, version/backup project files per session, update apps only between projects.
7. `## Sources & evidence` — repo URL, key files read (paths), HEAD commit SHA you inspected (`git rev-parse HEAD` in the repo), and the date.

## Also produce (for the orchestrator's review, not for installation)
Write `evidence.md` next to SKILL.md: a table of the 10–20 most important capability claims → evidence file path → implemented/partial/claimed. This lets the orchestrator spot-check you.

## Output locations (exactly)
- `/tmp/artcraft-skills/<appname>/SKILL.md`
- `/tmp/artcraft-skills/<appname>/evidence.md`
(`<appname>` = your app's lowercase repo name, e.g. `photocraft`.)

## Style
Imperative, concise, examples over rules. Explain *why* a caution matters when non-obvious. No marketing language. The reader is an AI agent, not a human tourist.

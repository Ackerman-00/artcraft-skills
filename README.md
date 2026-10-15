# ArtCraft Agent Skills

**Thirteen evidence-verified agent skills — plain `SKILL.md` files following the [agentskills.io](https://agentskills.io) standard — that teach AI coding agents to drive the [ArtCraft](https://getartcraft.com) creative suite. Built for Claude Code, OpenAI Codex & ChatGPT desktop, OpenCode, Devin, CommandCode and ZCode.**

<p align="center">
  <img src="assets/app-logos-marquee.svg" alt="The thirteen ArtCraft apps scrolling past: PhotoCraft, LightCraft, VectorCraft, FigCraft, DesignCraft, WordCraft, DeckCraft, GridCraft, PdfCraft, EffectCraft, FilmCraft, SoundCraft and CADCraft" width="100%">
</p>

ArtCraft is the open-source, pure-Rust, clean-room creative suite from the [`storytold`](https://github.com/storytold) organization (Photoshop-, Illustrator-, Premiere-, Lightroom-, Acrobat-, After Effects-, InDesign-, Figma-, Word-, Pro Tools-, PowerPoint-, AutoCAD- and Excel-style apps, all installable via the [ArtCraft Launcher](https://github.com/storytold/craft-launcher)).

Each skill teaches an AI coding agent **what one app can really do, what it cannot do yet, and how to drive it correctly** — through the app's first-class automation surface (headless CLI, [MCP](https://modelcontextprotocol.io) (Model Context Protocol) server, localhost JSON control channel) rather than blind GUI automation. Mention an app or one of its file formats — `.psd`, `.pptx`, `.xlsx`, `.docx`, `.dxf` — and the matching skill triggers.

**Works with:** any agent that implements the [agentskills.io](https://agentskills.io) `SKILL.md` standard — Claude Code, OpenAI Codex & ChatGPT desktop, OpenCode, Devin, CommandCode, ZCode and more. One command per agent:

| Agent | Install | Skill directory it scans |
|---|---|---|
| OpenAI Codex · ChatGPT desktop | `bash install.sh` | `~/.agents/skills/` |
| ZCode | `bash install.sh` | `~/.agents/skills/` (also `~/.zcode/skills/`) |
| Devin | `bash install.sh` | `~/.agents/skills/` |
| CommandCode | `bash install.sh` | `~/.agents/skills/` (also `~/.commandcode/skills/`) |
| Claude Code | `bash install.sh --claude` | `~/.claude/skills/` |
| OpenCode | `bash install.sh --opencode` | `~/.config/opencode/skills/` |
| claude.ai · Claude Desktop | zip upload (Settings → Capabilities → Skills) | per-chat upload |
| Windows (any of the above) | `.\install.ps1` (`-Claude`, `-OpenCode`) | `%USERPROFILE%\` equivalents |

The SKILL.md files are plain Markdown + shell, so any agent that can read files can use them. Full per-agent options are under [Install](#install) below.

## Install

Clone once, then pick the target that matches your agent:

```sh
git clone https://github.com/midasmatterhorn/artcraft-skills.git
cd artcraft-skills
```

### One paste: let your coding agent do it

Copy this into your agent (Claude Code, Codex, ChatGPT, OpenCode, Devin, CommandCode, ZCode, or any coding agent):

```text
Clone https://github.com/midasmatterhorn/artcraft-skills.git into a temporary directory, then install the skills for the agent I'm using now:
- Windows: run `.\install.ps1`; if you are Claude Code use `.\install.ps1 -Claude`, if you are OpenCode use `.\install.ps1 -OpenCode`, and add `-Force` to overwrite existing installs.
- OpenCode (macOS/Linux): run `bash install.sh --opencode`, which installs into ~/.config/opencode/skills/.
- Claude Code (macOS/Linux): run `bash install.sh --claude`, which installs into ~/.claude/skills/.
- Everyone else (OpenAI Codex, ChatGPT desktop, ZCode, Devin, CommandCode, or any other SKILL.md-standard agent): run `bash install.sh`; the default target is ~/.agents/skills/, which those agents scan natively.
Verify the install: all 13 skill directories must be present under the target directory, each containing SKILL.md and agents/openai.yaml. Print the target directory you used.
Then tell me to restart my agent session so the new skills are discovered.
```

Works as-is in Claude Code, Codex, OpenCode, Devin, CommandCode and ZCode; any SKILL.md-standard agent can follow it too.

### Standard agents (Codex, ChatGPT, ZCode, Devin, CommandCode)

```sh
bash install.sh            # default target: ~/.agents/skills/
```

`~/.agents/skills/` is the shared directory that OpenAI Codex, ChatGPT desktop, ZCode, Devin and CommandCode all scan natively (ZCode also reads `~/.zcode/skills/`; CommandCode also reads `~/.commandcode/skills/`). Every skill ships an `agents/openai.yaml` sidecar so the Codex/ChatGPT UI shows the proper display name and description. CommandCode users can alternatively install natively with `cmd skills add midasmatterhorn/artcraft-skills --global`.

Invoke a skill explicitly with `$photocraft` (or `$wordcraft`, …), or let implicit triggering fire when you mention an app or an extension like `.psd`, `.pptx`, `.xlsx`, `.docx` or `.dxf`. If a freshly installed skill doesn't show up, restart your agent.

### Claude Code

```sh
bash install.sh --claude   # copies all 13 skills into ~/.claude/skills/
```

`--claude` targets Claude Code's user-scoped `~/.claude/skills/` directory (a project-scoped `.claude/skills/` works the same way). Prefer symlinks when you want `git pull` to keep skills current:

```sh
ln -s "$PWD/photocraft" ~/.claude/skills/photocraft   # repeat for each skill
```

### OpenCode

```sh
bash install.sh --opencode   # copies all 13 skills into ~/.config/opencode/skills/
```

`--opencode` targets OpenCode's global skills directory `~/.config/opencode/skills/`, where they are discovered for every project. To scope skills to a single project instead, symlink them into that project's `.opencode/skills/` directory:

```sh
ln -s "$PWD/photocraft" .opencode/skills/photocraft   # repeat for each skill
```

As with Claude Code, symlinks mean `git pull` keeps the installed skills current.

### claude.ai / Claude Desktop

Zip a skill folder and upload it via **Settings → Capabilities → Skills**:

```sh
cd artcraft-skills && zip -r photocraft.skill.zip photocraft
```

### Windows (PowerShell / WSL)

Native Windows: after cloning, run the PowerShell installer (`install.ps1`):

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1   # or .\install.ps1 in an existing PowerShell session
```

`-Claude` targets Claude Code's `%USERPROFILE%\.claude\skills` and `-OpenCode` targets OpenCode's `%USERPROFILE%\.config\opencode\skills`; the default is `%USERPROFILE%\.agents\skills` (scanned natively by Codex, ChatGPT desktop, ZCode, Devin and CommandCode on Windows), and `-Force` overwrites existing installs.

On WSL or Git Bash the bash installer works unchanged (`bash install.sh`, `--claude`, `--opencode`) — no need for `install.ps1` there. The skill folders are plain Markdown; only the paths inside the docs are written macOS-first (see the Platforms note below).

### Manual / other agents

Copy or symlink any skill folder into the directory your agent reads — the format is the portable SKILL.md standard, so nothing here is Claude-, Codex- or OpenCode-specific. `install.sh` also accepts `--force` to overwrite existing installs (e.g. `bash install.sh --force`).

Skills trigger automatically when you mention an app or its file formats (`.psd`, `.pptx`, `.xlsx`, `.docx`, `.dxf`, `.deckcraft`, `.scraft`, …), or force one in-session with `/photocraft` (Claude Code) or `$photocraft` (Codex).

> **Platforms:** Installing works the same on macOS, Linux and Windows (targets above), and the SKILL.md format itself is OS-agnostic. The skill *bodies*, however, were authored against macOS app installs: launch and paths sections cite `/Applications/<App>.app` and `~/Library/Application Support/...`. The apps ship native Windows and Linux builds with the same CLI/MCP/command surfaces (binary names gain `.exe` on Windows; config and log paths move under `%APPDATA%`/`%LOCALAPPDATA%` on Windows and `~/.local/state` etc. on Linux) — so treat the macOS paths as the conceptual location and check the app's own docs/output for exact equivalents on your OS.

## The skills

One skill per app across the whole Craft App Suite — the same from-scratch Rust tools the [ArtCraft Launcher](https://github.com/storytold/craft-launcher) installs:

| App | What it's for | Skill | Skill based on | Learn more |
|---|---|---|---|---|
| <img src="assets/icons/photocraft.png" width="32" alt="PhotoCraft icon" align="absmiddle"> **[PhotoCraft](https://github.com/storytold/photocraft)** | Image editing: layers, masks, type and real PSD files | [`photocraft`](photocraft) | 0.8.2 @ `7250e6e` | [Website](https://getartcraft.com/apps/photocraft) |
| <img src="assets/icons/lightcraft.png" width="32" alt="LightCraft icon" align="absmiddle"> **[LightCraft](https://github.com/storytold/lightcraft)** | Photo library and raw development | [`lightcraft`](lightcraft) | 0.8.0 @ `16dbb90` | [Website](https://getartcraft.com/apps/lightcraft) |
| <img src="assets/icons/vectorcraft.png" width="32" alt="VectorCraft icon" align="absmiddle"> **[VectorCraft](https://github.com/storytold/vectorcraft)** | Vector illustration | [`vectorcraft`](vectorcraft) | 0.11.0 @ `0a33cff` | [Website](https://getartcraft.com/apps/vectorcraft) |
| <img src="assets/icons/figcraft.png" width="32" alt="FigCraft icon" align="absmiddle"> **[FigCraft](https://github.com/storytold/figcraft)** | Interface design and prototyping | [`figcraft`](figcraft) | 0.6.0 @ `833f0d2` | [Website](https://getartcraft.com/apps/figcraft) |
| <img src="assets/icons/designcraft.png" width="32" alt="DesignCraft icon" align="absmiddle"> **[DesignCraft](https://github.com/storytold/designcraft)** | Page layout and publishing | [`designcraft`](designcraft) | 0.8.0 @ `11a51d5` | [Website](https://getartcraft.com/apps/designcraft) |
| <img src="assets/icons/wordcraft.png" width="32" alt="WordCraft icon" align="absmiddle"> **[WordCraft](https://github.com/storytold/wordcraft)** | Word processing and documents | [`wordcraft`](wordcraft) | 0.7.0 @ `fc41918` | [Website](https://getartcraft.com/apps/wordcraft) |
| <img src="assets/icons/deckcraft.png" width="32" alt="DeckCraft icon" align="absmiddle"> **[DeckCraft](https://github.com/storytold/deckcraft)** | Presentations and slide decks | [`deckcraft`](deckcraft) | 0.7.0 @ `d78e657` | [Website](https://getartcraft.com/apps/deckcraft) |
| <img src="assets/icons/gridcraft.png" width="32" alt="GridCraft icon" align="absmiddle"> **[GridCraft](https://github.com/storytold/gridcraft)** | Spreadsheets and data | [`gridcraft`](gridcraft) | 0.7.0 @ `d9d09f0` | [Website](https://getartcraft.com/apps/gridcraft) |
| <img src="assets/icons/pdfcraft.png" width="32" alt="PdfCraft icon" align="absmiddle"> **[PdfCraft](https://github.com/storytold/pdfcraft)** | Reading, organizing and protecting PDFs | [`pdfcraft`](pdfcraft) | 0.8.0 @ `9931329` | [Website](https://getartcraft.com/apps/pdfcraft) |
| <img src="assets/icons/effectcraft.png" width="32" alt="EffectCraft icon" align="absmiddle"> **[EffectCraft](https://github.com/storytold/effectcraft)** | Motion graphics and visual effects | [`effectcraft`](effectcraft) | 0.9.2 @ `549e9d8` | [Website](https://getartcraft.com/apps/effectcraft) |
| <img src="assets/icons/filmcraft.png" width="32" alt="FilmCraft icon" align="absmiddle"> **[FilmCraft](https://github.com/storytold/filmcraft)** | Video editing, color and sound | [`filmcraft`](filmcraft) | 0.7.2 @ `cee1feb` | [Website](https://getartcraft.com/apps/filmcraft) |
| <img src="assets/icons/soundcraft.png" width="32" alt="SoundCraft icon" align="absmiddle"> **[SoundCraft](https://github.com/storytold/soundcraft)** | Audio recording and editing | [`soundcraft`](soundcraft) | 0.7.0 @ `3a28a65` | [Website](https://getartcraft.com/apps/soundcraft) |
| <img src="assets/icons/cadcraft.png" width="32" alt="CADCraft icon" align="absmiddle"> **[CADCraft](https://github.com/storytold/cadcraft)** | Computer-aided design | [`cadcraft`](cadcraft) | 0.7.0 @ `fc4e983` | [Website](https://getartcraft.com/apps/cadcraft) |

*Skill based on* names the app release and commit each skill was written and verified against; the apps are early-alpha and move fast, so every skill also carries a *verify against your installed version* note.

Each skill directory contains:

- **`SKILL.md`** — the skill: overview, verified capabilities (tiered implemented / partial / not-implemented, each with a `file:line` evidence pointer into the app repo), known limitations, how to operate (launch, CLI usage, document model, formats), what an AI agent may and may not attempt, an alpha-software verification protocol, and the exact sources inspected.
- **`evidence.md`** — capability → evidence map used to audit the skill.
- **`references/`** (some apps) — deeper tables (commands, formats, shortcuts).
- **`agents/openai.yaml`** — Codex/ChatGPT UI metadata (display name, short description).

## Why these are trustworthy

Every capability claim is traceable to the app's source code. The skills were authored by one AI agent per repo (DeepSeek V4.1 Flash, max reasoning effort, via [OpenCode](https://opencode.ai)) against a pinned commit, then machine-audited: every cited file path resolved, every `Sources & evidence` SHA matched the audited tree, and headline claims (PSD read/write, XLSX function parity, PPTX round-trip, DXF/DWG, effect counts, MCP surfaces) were spot-checked against code. No capability is documented without a file:line pointer; uncertainty is labeled `uncertain`, never guessed.

The full method, including the regeneration recipe, lives alongside the skill sources (not in this repo).

## Provenance & maintenance

- Apps and their repos move fast (early-alpha, frequent releases; installed bundles often lag repo HEAD). Each skill names the exact commit it describes and carries a *verify against your installed version* note.

## Related

- Apps: https://getartcraft.com/apps · Source: https://github.com/storytold
- Launcher: https://github.com/storytold/craft-launcher

## License

MIT — see [LICENSE](LICENSE). These skills are original documentation about the ArtCraft apps (MIT OR Apache-2.0); they contain no third-party or Adobe assets and are clean-room-safe. ArtCraft and the app names belong to the ArtCraft/storytold project.

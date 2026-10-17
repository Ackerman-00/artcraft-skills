# AGENTS.md — ArtCraft Skills archive

You are a coding agent. This folder is the persistence archive of the
[artcraft-skills](https://github.com/midasmatterhorn/artcraft-skills) project: 13
evidence-verified skills for the ArtCraft desktop apps. If the user asks you to
install, update, or verify these skills, do it for the agent **you** are running as.

## Install (pick your target)

From the packaged release in this folder — the 13 skill folders sit at the zip root:

```sh
# Default: OpenAI Codex, ChatGPT desktop, ZCode, Devin, CommandCode, Gemini CLI (~/.agents/skills)
unzip -o "releases/artcraft-skills-v1.0.1.zip" -d ~/.agents/skills/

# Claude Code
unzip -o "releases/artcraft-skills-v1.0.1.zip" -d ~/.claude/skills/

# OpenCode
unzip -o "releases/artcraft-skills-v1.0.1.zip" -d ~/.config/opencode/skills/

# Gemini CLI
unzip -o "releases/artcraft-skills-v1.0.1.zip" -d ~/.gemini/skills/

# Google Antigravity
unzip -o "releases/artcraft-skills-v1.0.1.zip" -d ~/.gemini/config/skills/
```

Windows PowerShell:

```powershell
Expand-Archive releases\artcraft-skills-v1.0.1.zip -DestinationPath $HOME\.agents\skills   # or .claude\skills / .config\opencode\skills / .gemini\skills / .gemini\config\skills
```

Or from source (latest state):

```sh
git clone https://github.com/midasmatterhorn/artcraft-skills.git && cd artcraft-skills
bash install.sh              # default → ~/.agents/skills/  (add --claude, --opencode, --gemini or --antigravity to retarget)
.\install.ps1                # Windows; -Claude / -OpenCode / -Gemini / -Antigravity switches, -Force to overwrite
```

## Verify

All 13 skill directories must exist under the chosen target — `cadcraft`, `deckcraft`,
`designcraft`, `effectcraft`, `figcraft`, `filmcraft`, `gridcraft`, `lightcraft`,
`pdfcraft`, `photocraft`, `soundcraft`, `vectorcraft`, `wordcraft` — each containing
`SKILL.md` and `agents/openai.yaml`. Print the target directory you used, then tell the
user to restart their agent session so the skills are discovered.

## Windows: driving the GUI apps live

Agents on Windows often spawn processes in a non-interactive window station
(`CREATE_NO_WINDOW`); the ArtCraft GUI apps (egui/DirectX) exit immediately with code 0
and no window when launched that way. To edit on screen while the user watches, have the
**user** launch the app interactively and attach to it over the control channel:

```cmd
cmd.exe /c start "" "C:\Program Files\<App>\<app>.exe" --control <port>
```

Then connect a TCP socket to `127.0.0.1:<port>` and send one JSON request per line.
Authentication differs per app — check the app's SKILL.md before connecting:

- **PhotoCraft**: pass `--control-token <64-hex>` (or `--control-token-file <path>`) at launch.
- **WordCraft**: read the key from `%APPDATA%\<App>\control-key.local-<port>` (mode 0600, deleted on exit).
- **PdfCraft**: launch with `--control FILE` — the file holds the loopback port and per-launch token.
- **All other apps**: loopback-only, unauthenticated — enable only while in use.

Send UTF-8 **without a BOM**: the control servers treat a BOM-prefixed first line as
malformed JSON and close the connection. Windows PowerShell 5.1 pipes add a BOM — use raw
sockets, `pwsh` (`utf8NoBOM`), or set `[Console]::OutputEncoding` explicitly. On macOS and
Linux the apps launch normally; this note is Windows-specific.

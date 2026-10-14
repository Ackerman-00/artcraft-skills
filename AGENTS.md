# AGENTS.md — ArtCraft Skills archive

You are a coding agent. This folder is the persistence archive of the
[artcraft-skills](https://github.com/midasmatterhorn/artcraft-skills) project: 13
evidence-verified skills for the ArtCraft desktop apps. If the user asks you to
install, update, or verify these skills, do it for the agent **you** are running as.

## Install (pick your target)

From the packaged release in this folder — the 13 skill folders sit at the zip root:

```sh
# Default: OpenAI Codex, ChatGPT desktop, ZCode, Devin, CommandCode (~/.agents/skills)
unzip -o "releases/artcraft-skills-v1.0.0.zip" -d ~/.agents/skills/

# Claude Code
unzip -o "releases/artcraft-skills-v1.0.0.zip" -d ~/.claude/skills/

# OpenCode
unzip -o "releases/artcraft-skills-v1.0.0.zip" -d ~/.config/opencode/skills/
```

Windows PowerShell:

```powershell
Expand-Archive releases\artcraft-skills-v1.0.0.zip -DestinationPath $HOME\.agents\skills   # or .claude\skills / .config\opencode\skills
```

Or from source (latest state):

```sh
git clone https://github.com/midasmatterhorn/artcraft-skills.git && cd artcraft-skills
bash install.sh              # default → ~/.agents/skills/  (add --claude or --opencode to retarget)
.\install.ps1                # Windows; -Claude / -OpenCode switches, -Force to overwrite
```

## Verify

All 13 skill directories must exist under the chosen target — `cadcraft`, `deckcraft`,
`designcraft`, `effectcraft`, `figcraft`, `filmcraft`, `gridcraft`, `lightcraft`,
`pdfcraft`, `photocraft`, `soundcraft`, `vectorcraft`, `wordcraft` — each containing
`SKILL.md` and `agents/openai.yaml`. Print the target directory you used, then tell the
user to restart their agent session so the skills are discovered.

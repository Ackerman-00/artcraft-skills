# Maintenance: regenerate the skills against new repo HEADs

The ArtCraft apps move fast. When a skill's pinned commit drifts far from reality (or the
launcher updates the apps across a version boundary), regenerate all 13 skills and re-audit
them with the steps below. Everything runs locally; the only dependencies are `git`, `gh`
(optional), and the [OpenCode CLI](https://opencode.ai) ≥ 1.18.29 with the
`opencode-go/deepseek-v4.1-flash` model. Windows users run the regeneration commands from WSL or Git Bash (paths as written), or adapt them for PowerShell; nothing else in the file assumes macOS.

The one external input is [`brief/artcraft-skill-brief.md`](brief/artcraft-skill-brief.md) —
the authoring brief every agent reads. Keep it next to this file.

## Step 1 — Refresh shallow clones

```sh
WORK="$HOME/artcraft-repos"   # any scratch dir with ~2 GB free
mkdir -p "$WORK" && cd "$WORK"
for r in photocraft vectorcraft filmcraft lightcraft pdfcraft effectcraft designcraft \
         figcraft wordcraft soundcraft deckcraft cadcraft gridcraft craft-libs; do
  if [ -d "$r/.git" ]; then git -C "$r" fetch --depth 1 origin main && git -C "$r" reset --hard FETCH_HEAD
  else git clone --depth 1 "https://github.com/storytold/$r.git"; fi
done
for r in photocraft vectorcraft filmcraft lightcraft pdfcraft effectcraft designcraft \
         figcraft wordcraft soundcraft deckcraft cadcraft gridcraft; do
  echo "$r $(git -C $r rev-parse HEAD)"; done | tee /tmp/artcraft-heads.txt
```

## Step 2 — Stage brief and outputs

```sh
cp /path/to/artcraft-skills/brief/artcraft-skill-brief.md /tmp/artcraft-skill-brief.md
rm -rf /tmp/artcraft-skills && mkdir -p /tmp/artcraft-skills/logs
```

## Step 3 — Dispatch one agent per repo (max reasoning effort)

```sh
cd "$WORK"
declare -A label=( [photocraft]=PhotoCraft [lightcraft]=LightCraft [vectorcraft]=VectorCraft \
  [figcraft]=FigCraft [designcraft]=DesignCraft [wordcraft]=WordCraft [deckcraft]=DeckCraft \
  [gridcraft]=GridCraft [pdfcraft]=PdfCraft [effectcraft]=EffectCraft [filmcraft]=FilmCraft \
  [soundcraft]=SoundCraft [cadcraft]=CADCraft )
for app in "${!label[@]}"; do
  mkdir -p "/tmp/artcraft-skills/$app"
  opencode run -m opencode-go/deepseek-v4.1-flash --variant max \
    --dir "$PWD/$app" --title "artcraft-skill-$app" \
    "You are the ${label[$app]} skill agent. First read /tmp/artcraft-skill-brief.md and follow it exactly for the app whose source is the current working directory (GitHub repo storytold/$app, app name ${label[$app]}, installed at /Applications/${label[$app]}.app). Read the repo yourself: README, Cargo.toml, docs, CLI parsing, file format code, feature modules. Write /tmp/artcraft-skills/$app/SKILL.md and /tmp/artcraft-skills/$app/evidence.md exactly as the brief requires. Finish by printing 3 lines: top capabilities, biggest verified gaps, confidence in evidence coverage." \
    > "/tmp/artcraft-skills/logs/$app.log" 2>&1 &
done
wait
ls /tmp/artcraft-skills/*/SKILL.md | wc -l   # expect 13
```

If a run dies with "database is locked" or its log has no final line, re-run that app's command.

## Step 4 — Audit (this is what keeps the skills ironclad)

```sh
cd "$WORK"
APPS="photocraft lightcraft vectorcraft figcraft designcraft wordcraft deckcraft gridcraft pdfcraft effectcraft filmcraft soundcraft cadcraft"

# a) Structure: frontmatter + 7 required sections
for app in $APPS; do
  s=/tmp/artcraft-skills/$app/SKILL.md
  [ "$(head -1 $s)" = "---" ] || echo "BAD FRONTMATTER: $app"
  [ "$(awk '/^name:/{print $2; exit}' $s)" = "$app" ] || echo "BAD NAME: $app"
  n=$(grep -cE '^## (Overview|Capabilities|Known limitations|How to operate|Working with an AI agent|Verification protocol|Sources)' $s)
  [ "$n" -eq 7 ] || echo "MISSING SECTIONS ($n/7): $app"
done

# b) Evidence paths: every cited path must exist in the repo (exact or basename-find)
for app in $APPS; do
  for p in $(grep -oE '\`[A-Za-z0-9_./-]+\.(rs|toml|md)\`' /tmp/artcraft-skills/$app/SKILL.md | tr -d '\`' | sort -u); do
    case "$p" in evidence.md|references/*) continue;; esac
    if [[ "$p" == */* ]]; then [ -f "$app/$p" ] || echo "BROKEN [$app]: $p"
    else find "$app" -name "$p" -not -path '*/target/*' | grep -q . || echo "BROKEN [$app]: $p"; fi
  done
done

# c) SHA: skill must cite the HEAD it was generated against
for app in $APPS; do
  actual=$(git -C $app rev-parse HEAD)
  grep -q "${actual:0:7}" /tmp/artcraft-skills/$app/SKILL.md || echo "SHA NOT CITED [$app]: ${actual:0:7}"
done

# d) Headline spot-checks (adapt as features move)
grep -rli psd photocraft --include='*.rs' | head -3
grep -rln pptx deckcraft --include='*.rs' | head -3
grep -rln dxf  cadcraft  --include='*.rs' | head -3
ls */crates/mcp 2>/dev/null
```

Fix or re-dispatch anything flagged before installing.

## Step 5 — Install / publish

```sh
for app in $APPS; do
  dst="$HOME/.agents/skills/$app"; mkdir -p "$dst"
  cp /tmp/artcraft-skills/$app/SKILL.md "$dst/SKILL.md"
  [ -f /tmp/artcraft-skills/$app/evidence.md ] && cp /tmp/artcraft-skills/$app/evidence.md "$dst/"
  [ -d /tmp/artcraft-skills/$app/references ] && cp -R /tmp/artcraft-skills/$app/references "$dst/"
done
```

Then update the version table in this repo's `README.md` (Cargo.toml `version` + HEAD SHA per
app) and open a PR or push to `main`.

## Contributing improved skills

PRs welcome. Requirements: every capability claim keeps its file:line evidence pointer, the
`Sources & evidence` section cites the exact commit you inspected, and uncertain claims say so
instead of guessing. Run the Step 4 audit on your own draft before opening the PR.

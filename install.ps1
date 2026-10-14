# Install the ArtCraft agent skills into an agent skills directory.
# Usage: .\install.ps1 [-Force] [-Claude] [-OpenCode]
#   default target $HOME\.agents\skills\ — scanned natively by OpenAI Codex,
#   ChatGPT desktop, ZCode, Devin, CommandCode on Windows; -Claude targets
#   $HOME\.claude\skills\ for Claude Code; -OpenCode targets
#   $HOME\.config\opencode\skills\ for OpenCode. PowerShell 5.1+, no modules.
param([switch]$Force, [switch]$Claude, [switch]$OpenCode)

$ErrorActionPreference = 'Stop'
$dest = Join-Path $HOME '.agents\skills'
if ($Claude)   { $dest = Join-Path $HOME '.claude\skills' }
if ($OpenCode) { $dest = Join-Path $HOME '.config\opencode\skills' }
$skills = 'photocraft lightcraft vectorcraft figcraft designcraft wordcraft deckcraft gridcraft pdfcraft effectcraft filmcraft soundcraft cadcraft' -split ' '

New-Item -ItemType Directory -Force -Path $dest | Out-Null
$installed = 0; $skipped = 0
foreach ($s in $skills) {
    if ($s -notmatch '^[a-z]+$') { [Console]::Error.WriteLine("refusing bad skill name: $s"); exit 1 }
    $target = Join-Path $dest $s
    if ((Test-Path $target) -and -not $Force) {
        Write-Host "skip  $s (already installed — use -Force to overwrite)"
        $skipped++
    } else {
        Remove-Item -Recurse -Force -Path $target -ErrorAction SilentlyContinue
        Copy-Item -Recurse -Force -Path (Join-Path $PSScriptRoot $s) -Destination $target
        Write-Host "install  $s -> $target"
        $installed++
    }
}
Write-Host "done: $installed installed, $skipped skipped. Restart your agent session to pick them up."

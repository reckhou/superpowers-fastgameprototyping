# codex-install.ps1 - Install Superpower-FastPrototype skills as Codex CLI slash commands.
#
# Walks .\skills\*\SKILL.md  -> ~/.codex/prompts/use-<name>.md
# Walks .\commands\*.md      -> ~/.codex/prompts/<name>.md
# Idempotent: safe to re-run after adding new skills.
# Requires: Windows Developer Mode (for cross-volume symlinks).
#
# Note: a subset of skills (writing-plans, executing-plans, subagent-driven-development,
# dispatching-parallel-agents) rely on Claude Code's Agent / subagent / plan-mode
# primitives, which Codex does not have. They will load under Codex but their
# tool calls may fail or behave differently. See README for details.

$ErrorActionPreference = 'Stop'

# Resolve repo root from this script's location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
$promptsDir = Join-Path $env:USERPROFILE '.codex\prompts'

Write-Host "Superpower-FastPrototype -> Codex CLI" -ForegroundColor Cyan
Write-Host "  Source:  $repoRoot"
Write-Host "  Target:  $promptsDir"
Write-Host ""

# Ensure prompts dir exists
if (-not (Test-Path $promptsDir)) {
    New-Item -ItemType Directory -Path $promptsDir -Force | Out-Null
    Write-Host "Created $promptsDir" -ForegroundColor Green
}

function Set-Symlink {
    param(
        [string]$LinkName,
        [string]$TargetPath,
        [string]$OwnedPrefix
    )

    $linkPath = Join-Path $promptsDir "$LinkName.md"

    if (-not (Test-Path $TargetPath)) {
        Write-Host "  [skip] $LinkName -- target missing" -ForegroundColor Yellow
        return [pscustomobject]@{ Status='skip'; Name=$LinkName }
    }

    if (Test-Path $linkPath) {
        $existing = Get-Item $linkPath -Force
        if ($existing.LinkType -eq 'SymbolicLink') {
            if ($existing.Target -eq $TargetPath) {
                return [pscustomobject]@{ Status='ok'; Name=$LinkName }
            }
            # Symlink exists with different target. Only overwrite if it points
            # inside our own repo (e.g. file moved within Superpower). Never
            # overwrite cross-repo links — that silently steals prompt names
            # from another project's installer.
            if ($existing.Target -like "$OwnedPrefix*") {
                Remove-Item $linkPath -Force
            } else {
                Write-Host "  [conflict] $LinkName -- already points to $($existing.Target), leaving as-is" -ForegroundColor DarkYellow
                return [pscustomobject]@{ Status='conflict'; Name=$LinkName; Existing=$existing.Target }
            }
        } else {
            Write-Host "  [conflict] $LinkName -- regular file exists, leaving as-is" -ForegroundColor DarkYellow
            return [pscustomobject]@{ Status='conflict'; Name=$LinkName }
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $TargetPath -ErrorAction Stop | Out-Null
        Write-Host "  [link] $LinkName" -ForegroundColor Green
        return [pscustomobject]@{ Status='created'; Name=$LinkName }
    } catch {
        Write-Host "  [FAIL] $LinkName -- $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{ Status='fail'; Name=$LinkName }
    }
}

$results = @()

# ---- Skills: skills/<name>/SKILL.md -> use-<name>.md ----
Write-Host "Linking skills (as /use-<name>)..." -ForegroundColor Cyan
$skillsDir = Join-Path $repoRoot 'skills'
if (Test-Path $skillsDir) {
    Get-ChildItem -Path $skillsDir -Directory | Sort-Object Name | ForEach-Object {
        $name = $_.Name
        $skillFile = Join-Path $_.FullName 'SKILL.md'
        if (Test-Path $skillFile) {
            $results += Set-Symlink -LinkName "use-$name" -TargetPath $skillFile -OwnedPrefix $repoRoot
        } else {
            Write-Host "  [skip] $name -- no SKILL.md in folder" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [skip] no skills/ directory" -ForegroundColor Yellow
}

# ---- Commands: commands/<name>.md -> <name>.md ----
Write-Host "Linking commands..." -ForegroundColor Cyan
$commandsDir = Join-Path $repoRoot 'commands'
if (Test-Path $commandsDir) {
    Get-ChildItem -Path $commandsDir -File -Filter *.md | Sort-Object Name | ForEach-Object {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $results += Set-Symlink -LinkName $name -TargetPath $_.FullName -OwnedPrefix $repoRoot
    }
} else {
    Write-Host "  [skip] no commands/ directory" -ForegroundColor Yellow
}

# ---- Summary ----
Write-Host ""
$ok        = ($results | Where-Object Status -eq 'ok'       | Measure-Object).Count
$created   = ($results | Where-Object Status -eq 'created'  | Measure-Object).Count
$skip      = ($results | Where-Object Status -eq 'skip'     | Measure-Object).Count
$conflict  = ($results | Where-Object Status -eq 'conflict' | Measure-Object).Count
$fail      = ($results | Where-Object Status -eq 'fail'     | Measure-Object).Count

Write-Host "Summary: $created created, $ok already current, $conflict conflicts, $skip skipped, $fail failed" -ForegroundColor Cyan

if ($conflict -gt 0) {
    Write-Host "Conflicts (existing prompt names owned by another project — left untouched):" -ForegroundColor DarkYellow
    $results | Where-Object Status -eq 'conflict' | ForEach-Object {
        if ($_.Existing) { Write-Host "  - $($_.Name) -> $($_.Existing)" }
        else             { Write-Host "  - $($_.Name)" }
    }
    Write-Host "  To use Superpower's version, rename the colliding skill folder or" -ForegroundColor DarkYellow
    Write-Host "  remove the existing prompt symlink first." -ForegroundColor DarkYellow
}

if ($fail -gt 0) {
    Write-Host "Failures (likely cause: Developer Mode disabled or admin shell required):" -ForegroundColor Red
    $results | Where-Object Status -eq 'fail' | ForEach-Object { Write-Host "  - $($_.Name)" }
    exit 1
}

Write-Host ""
Write-Host "Codex CLI now has Superpower prompts available as /use-<skill> and /<command>." -ForegroundColor Green
Write-Host "Caveat: skills that depend on Claude's Agent/subagent/plan-mode primitives" -ForegroundColor DarkYellow
Write-Host "(writing-plans, executing-plans, subagent-driven-development," -ForegroundColor DarkYellow
Write-Host "dispatching-parallel-agents) may not run fully under Codex." -ForegroundColor DarkYellow

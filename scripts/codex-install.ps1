# codex-install.ps1 - Install Superpower-FastPrototype skills for Codex CLI.
#
# Walks .\skills\<name>\        -> folder symlink ~/.agents/skills/<name>
# Walks .\commands\<name>.md    -> file symlink ~/.agents/skills/<name>/SKILL.md
# Idempotent: safe to re-run after adding new skills.
# Requires: Windows Developer Mode (for cross-volume symlinks).
#
# Codex CLI reads user-authored skills from $HOME/.agents/skills/ — NOT
# ~/.codex/prompts/. (The latter is documented for a different Codex variant
# and is unused by Codex CLI 0.130.0.) Skills appear in the /skills menu
# after restart. See https://developers.openai.com/codex/skills
#
# Conflict safety: this installer only overwrites symlinks whose target lives
# inside the Superpower repo. Cross-repo collisions (e.g. with AXIOM-Notes'
# installer placing a skill of the same name) are reported, not silently
# replaced — preventing invisible skill drift.
#
# Caveat: a subset of skills (subagent-driven-development,
# dispatching-parallel-agents, plan-mode-dependent parts of writing-plans /
# executing-plans) rely on Claude Code's Agent tool / subagent / plan-mode
# primitives, which Codex does not have. They will load under Codex but
# parts of their tool calls may degrade or fail.

$ErrorActionPreference = 'Stop'

# Resolve repo root from this script's location
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = Split-Path -Parent $scriptDir
$skillsRoot = Join-Path $env:USERPROFILE '.agents\skills'

Write-Host "Superpower-FastPrototype -> Codex CLI (~/.agents/skills/)" -ForegroundColor Cyan
Write-Host "  Source:  $repoRoot"
Write-Host "  Target:  $skillsRoot"
Write-Host ""

if (-not (Test-Path $skillsRoot)) {
    New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
    Write-Host "Created $skillsRoot" -ForegroundColor Green
}

function Install-FolderSymlink {
    param(
        [string]$SkillName,
        [string]$TargetFolder
    )

    $linkPath = Join-Path $skillsRoot $SkillName

    if (-not (Test-Path $TargetFolder)) {
        Write-Host "  [skip] $SkillName -- target missing: $TargetFolder" -ForegroundColor Yellow
        return [pscustomobject]@{ Status='skip'; Name=$SkillName }
    }

    if (Test-Path $linkPath) {
        $existing = Get-Item $linkPath -Force
        if ($existing.LinkType -eq 'SymbolicLink') {
            if ($existing.Target -eq $TargetFolder) {
                return [pscustomobject]@{ Status='ok'; Name=$SkillName }
            }
            if ($existing.Target -like "$repoRoot*") {
                Remove-Item $linkPath -Force -Recurse
            } else {
                Write-Host "  [conflict] $SkillName -- already points to $($existing.Target)" -ForegroundColor DarkYellow
                return [pscustomobject]@{ Status='conflict'; Name=$SkillName; Existing=$existing.Target }
            }
        } else {
            Write-Host "  [conflict] $SkillName -- regular folder in place" -ForegroundColor DarkYellow
            return [pscustomobject]@{ Status='conflict'; Name=$SkillName }
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $TargetFolder -ErrorAction Stop | Out-Null
        Write-Host "  [link] $SkillName  (folder)" -ForegroundColor Green
        return [pscustomobject]@{ Status='created'; Name=$SkillName }
    } catch {
        Write-Host "  [FAIL] $SkillName -- $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{ Status='fail'; Name=$SkillName }
    }
}

function Install-FileInFolder {
    param(
        [string]$SkillName,
        [string]$TargetFile
    )

    $skillDir = Join-Path $skillsRoot $SkillName
    $linkPath = Join-Path $skillDir 'SKILL.md'

    if (-not (Test-Path $TargetFile)) {
        Write-Host "  [skip] $SkillName -- target missing: $TargetFile" -ForegroundColor Yellow
        return [pscustomobject]@{ Status='skip'; Name=$SkillName }
    }

    if (Test-Path $linkPath) {
        $existing = Get-Item $linkPath -Force
        if ($existing.LinkType -eq 'SymbolicLink') {
            if ($existing.Target -eq $TargetFile) {
                return [pscustomobject]@{ Status='ok'; Name=$SkillName }
            }
            if ($existing.Target -like "$repoRoot*") {
                Remove-Item $linkPath -Force
            } else {
                Write-Host "  [conflict] $SkillName -- already points to $($existing.Target)" -ForegroundColor DarkYellow
                return [pscustomobject]@{ Status='conflict'; Name=$SkillName; Existing=$existing.Target }
            }
        } else {
            Write-Host "  [conflict] $SkillName -- regular file in place" -ForegroundColor DarkYellow
            return [pscustomobject]@{ Status='conflict'; Name=$SkillName }
        }
    }

    if (-not (Test-Path $skillDir)) {
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
    }

    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $TargetFile -ErrorAction Stop | Out-Null
        Write-Host "  [link] $SkillName" -ForegroundColor Green
        return [pscustomobject]@{ Status='created'; Name=$SkillName }
    } catch {
        Write-Host "  [FAIL] $SkillName -- $($_.Exception.Message)" -ForegroundColor Red
        return [pscustomobject]@{ Status='fail'; Name=$SkillName }
    }
}

$results = @()

# ---- Skills: skills/<name>/ -> folder symlink ~/.agents/skills/<name> ----
Write-Host "Installing skills (folder symlinks)..." -ForegroundColor Cyan
$srcSkills = Join-Path $repoRoot 'skills'
if (Test-Path $srcSkills) {
    Get-ChildItem -Path $srcSkills -Directory | Sort-Object Name | ForEach-Object {
        $skillFile = Join-Path $_.FullName 'SKILL.md'
        if (Test-Path $skillFile) {
            $results += Install-FolderSymlink -SkillName $_.Name -TargetFolder $_.FullName
        } else {
            Write-Host "  [skip] $($_.Name) -- no SKILL.md inside folder" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [skip] no skills/ directory" -ForegroundColor Yellow
}

# ---- Commands: commands/<name>.md -> ~/.agents/skills/<name>/SKILL.md ----
Write-Host "Installing commands (as skills)..." -ForegroundColor Cyan
$srcCommands = Join-Path $repoRoot 'commands'
if (Test-Path $srcCommands) {
    Get-ChildItem -Path $srcCommands -File -Filter *.md | Sort-Object Name | ForEach-Object {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $results += Install-FileInFolder -SkillName $name -TargetFile $_.FullName
    }
} else {
    Write-Host "  [skip] no commands/ directory" -ForegroundColor Yellow
}

# ---- Summary ----
Write-Host ""
$ok       = ($results | Where-Object Status -eq 'ok'       | Measure-Object).Count
$created  = ($results | Where-Object Status -eq 'created'  | Measure-Object).Count
$skip     = ($results | Where-Object Status -eq 'skip'     | Measure-Object).Count
$conflict = ($results | Where-Object Status -eq 'conflict' | Measure-Object).Count
$fail     = ($results | Where-Object Status -eq 'fail'     | Measure-Object).Count

Write-Host "Summary: $created created, $ok already current, $conflict conflicts, $skip skipped, $fail failed" -ForegroundColor Cyan

if ($conflict -gt 0) {
    Write-Host "Conflicts (skills owned by another repo's installer):" -ForegroundColor DarkYellow
    $results | Where-Object Status -eq 'conflict' | ForEach-Object {
        if ($_.Existing) { Write-Host "  - $($_.Name) -> $($_.Existing)" }
        else             { Write-Host "  - $($_.Name)" }
    }
    Write-Host "  To use Superpower's version, remove the existing symlink at" -ForegroundColor DarkYellow
    Write-Host "  ~/.agents/skills/<name> then re-run this installer." -ForegroundColor DarkYellow
}

if ($fail -gt 0) {
    Write-Host "Failures (likely cause: Developer Mode disabled or admin shell required):" -ForegroundColor Red
    $results | Where-Object Status -eq 'fail' | ForEach-Object { Write-Host "  - $($_.Name)" }
    exit 1
}

Write-Host ""
Write-Host "Restart Codex and type /skills to see Superpower's skills." -ForegroundColor Green
Write-Host "Caveat: subagent-driven-development, dispatching-parallel-agents," -ForegroundColor DarkYellow
Write-Host "and parts of writing-plans / executing-plans rely on Claude-specific" -ForegroundColor DarkYellow
Write-Host "primitives and may not run fully under Codex." -ForegroundColor DarkYellow

[CmdletBinding()]
param(
    [ValidateSet("Global", "Project", "Both")]
    [string]$Scope = "Global",

    [ValidateSet("codex", "claude", "all")]
    [string]$Target = "codex",

    [string]$ProjectPath = (Get-Location).Path,

    [string]$HomeDir = $HOME,

    [switch]$NoBackup,

    [switch]$ForceProjectAgentsFile
)

$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Get-Location).Path
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$ClaudeGlobalStartMarker = "<!-- agent-kit:claude-global:start -->"
$ClaudeGlobalEndMarker = "<!-- agent-kit:claude-global:end -->"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Copy-KitDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        return
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

function Backup-Path {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    if ($NoBackup -or -not (Test-Path -LiteralPath $Path)) {
        return
    }

    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $name = Split-Path -Leaf $Path
    Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupRoot $name) -Recurse -Force
}

function Merge-ClaudeGlobalBlock {
    param(
        [Parameter(Mandatory = $true)][string]$TargetClaudeMd,
        [Parameter(Mandatory = $true)][string]$BlockBody,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    $block = "$ClaudeGlobalStartMarker`n$BlockBody`n$ClaudeGlobalEndMarker"

    if (-not (Test-Path -LiteralPath $TargetClaudeMd)) {
        $parent = Split-Path -Parent $TargetClaudeMd
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Write-Utf8NoBom -Path $TargetClaudeMd -Content ($block + "`n")
        return
    }

    Backup-Path -Path $TargetClaudeMd -BackupRoot $BackupRoot

    $existing = [System.IO.File]::ReadAllText($TargetClaudeMd)
    $pattern = [regex]::Escape($ClaudeGlobalStartMarker) + "[\s\S]*?" + [regex]::Escape($ClaudeGlobalEndMarker)

    if ([regex]::IsMatch($existing, $pattern)) {
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block }
        $updated = [regex]::Replace($existing, $pattern, $evaluator)
    }
    else {
        $trimmed = $existing.TrimEnd("`r", "`n")
        $separator = if ($trimmed -eq "") { "" } else { "`n`n" }
        $updated = $trimmed + $separator + $block + "`n"
    }

    Write-Utf8NoBom -Path $TargetClaudeMd -Content $updated
}

function Install-Global {
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HomeDir ".codex" }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $codexHome "backups\codex-agent-kit-$stamp"

    New-Item -ItemType Directory -Path $codexHome -Force | Out-Null

    foreach ($name in @("agents", "skills", "workflows", "rules", "scripts")) {
        Backup-Path -Path (Join-Path $codexHome $name) -BackupRoot $backupRoot
        Copy-KitDirectory -Source (Join-Path $RepoRoot $name) -Destination (Join-Path $codexHome $name)
    }

    foreach ($name in @("ARCHITECTURE.md", "CODEX.md")) {
        $sourceFile = Join-Path $RepoRoot $name
        if (Test-Path -LiteralPath $sourceFile) {
            Backup-Path -Path (Join-Path $codexHome $name) -BackupRoot $backupRoot
            Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $codexHome $name) -Force
        }
    }

    $agentsFile = Join-Path $RepoRoot "AGENTS.md"
    if (Test-Path -LiteralPath $agentsFile) {
        Backup-Path -Path (Join-Path $codexHome "AGENTS.md") -BackupRoot $backupRoot
        Copy-Item -LiteralPath $agentsFile -Destination (Join-Path $codexHome "AGENTS.md") -Force
    }

    Write-Host "Installed Codex Agent Kit globally at $codexHome"
    if (-not $NoBackup -and (Test-Path -LiteralPath $backupRoot)) {
        Write-Host "Backup written to $backupRoot"
    }
}

function Install-Project {
    $resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
    $agentRoot = Join-Path $resolvedProject ".agent"
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $resolvedProject ".agent-backups\codex-agent-kit-$stamp"

    New-Item -ItemType Directory -Path $agentRoot -Force | Out-Null

    foreach ($name in @("agents", "skills", "workflows", "rules", "scripts")) {
        Backup-Path -Path (Join-Path $agentRoot $name) -BackupRoot $backupRoot
        Copy-KitDirectory -Source (Join-Path $RepoRoot $name) -Destination (Join-Path $agentRoot $name)
    }

    foreach ($name in @("ARCHITECTURE.md", "CODEX.md")) {
        $sourceFile = Join-Path $RepoRoot $name
        if (Test-Path -LiteralPath $sourceFile) {
            Backup-Path -Path (Join-Path $agentRoot $name) -BackupRoot $backupRoot
            Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $agentRoot $name) -Force
        }
    }

    $rootAgents = Join-Path $resolvedProject "AGENTS.md"
    if ((-not (Test-Path -LiteralPath $rootAgents)) -or $ForceProjectAgentsFile) {
        Backup-Path -Path $rootAgents -BackupRoot $backupRoot
        Set-Content -LiteralPath $rootAgents -Encoding UTF8 -Value @"
# Project Agent Instructions

This workspace includes Codex Agent Kit in `.agent/`.

Before using a specialist persona or workflow:

1. Read `.agent/ARCHITECTURE.md` for available agents, skills, and workflows.
2. For an explicit `@agent-name` request, read `.agent/agents/<agent-name>.md`.
3. For an explicit skill request, read `.agent/skills/<skill-name>/SKILL.md`.
4. When an agent file declares `skills:` in frontmatter, load only the relevant listed skill files.

Native Codex subagents are runtime workers, not these markdown personas. Use these markdown files as specialist instruction profiles.
"@
    }

    Write-Host "Installed Codex Agent Kit for project at $agentRoot"
    if (-not $NoBackup -and (Test-Path -LiteralPath $backupRoot)) {
        Write-Host "Backup written to $backupRoot"
    }
}

function Install-ClaudeShared {
    param(
        [Parameter(Mandatory = $true)][string]$ClaudeRoot,
        [Parameter(Mandatory = $true)][string]$ClaudeMdPath,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    New-Item -ItemType Directory -Path $ClaudeRoot -Force | Out-Null

    $dirMap = @(
        @{ Source = "agents"; Dest = "agents" },
        @{ Source = "skills"; Dest = "skills" },
        @{ Source = "workflows"; Dest = "commands" },
        @{ Source = "scripts"; Dest = "scripts" }
    )

    foreach ($pair in $dirMap) {
        $destPath = Join-Path $ClaudeRoot $pair.Dest
        Backup-Path -Path $destPath -BackupRoot $BackupRoot
        Copy-KitDirectory -Source (Join-Path $RepoRoot $pair.Source) -Destination $destPath
    }

    $rulesSource = Join-Path $RepoRoot "rules\CLAUDE.md"
    if (Test-Path -LiteralPath $rulesSource) {
        $rulesDestDir = Join-Path $ClaudeRoot "rules"
        New-Item -ItemType Directory -Path $rulesDestDir -Force | Out-Null
        $rulesDest = Join-Path $rulesDestDir "CLAUDE.md"
        Backup-Path -Path $rulesDest -BackupRoot $BackupRoot
        Copy-Item -LiteralPath $rulesSource -Destination $rulesDest -Force
    }

    $archSource = Join-Path $RepoRoot "ARCHITECTURE.md"
    if (Test-Path -LiteralPath $archSource) {
        $archDest = Join-Path $ClaudeRoot "ARCHITECTURE.md"
        Backup-Path -Path $archDest -BackupRoot $BackupRoot
        Copy-Item -LiteralPath $archSource -Destination $archDest -Force
    }

    $globalSource = Join-Path $RepoRoot "CLAUDE.global.md"
    if (Test-Path -LiteralPath $globalSource) {
        $blockBody = ([System.IO.File]::ReadAllText($globalSource)).Trim("`r", "`n")
        Merge-ClaudeGlobalBlock -TargetClaudeMd $ClaudeMdPath -BlockBody $blockBody -BackupRoot $BackupRoot
    }
}

function Install-ClaudeGlobal {
    $claudeHome = Join-Path $HomeDir ".claude"
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $claudeHome "backups\codex-agent-kit-claude-$stamp"

    Install-ClaudeShared -ClaudeRoot $claudeHome -ClaudeMdPath (Join-Path $claudeHome "CLAUDE.md") -BackupRoot $backupRoot

    Write-Host "Installed Claude Code target globally at $claudeHome"
    if (-not $NoBackup -and (Test-Path -LiteralPath $backupRoot)) {
        Write-Host "Backup written to $backupRoot"
    }
}

function Install-ClaudeProject {
    $resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
    $claudeDir = Join-Path $resolvedProject ".claude"
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $resolvedProject ".agent-backups\codex-agent-kit-claude-$stamp"

    Install-ClaudeShared -ClaudeRoot $claudeDir -ClaudeMdPath (Join-Path $resolvedProject "CLAUDE.md") -BackupRoot $backupRoot

    Write-Host "Installed Claude Code target for project at $claudeDir"
    if (-not $NoBackup -and (Test-Path -LiteralPath $backupRoot)) {
        Write-Host "Backup written to $backupRoot"
    }
}

function Invoke-CodexTarget {
    if ($Scope -in @("Global", "Both")) {
        Install-Global
    }
    if ($Scope -in @("Project", "Both")) {
        Install-Project
    }
}

function Invoke-ClaudeTarget {
    if ($Scope -in @("Global", "Both")) {
        Install-ClaudeGlobal
    }
    if ($Scope -in @("Project", "Both")) {
        Install-ClaudeProject
    }
}

switch ($Target) {
    "codex" { Invoke-CodexTarget }
    "claude" { Invoke-ClaudeTarget }
    "all" { Invoke-CodexTarget; Invoke-ClaudeTarget }
}

[CmdletBinding()]
param(
    [ValidateSet("Global", "Project", "Both")]
    [string]$Scope = "Global",

    [string]$ProjectPath = (Get-Location).Path,

    [switch]$NoBackup,

    [switch]$ForceProjectAgentsFile
)

$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Get-Location).Path
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

function Install-Global {
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
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

if ($Scope -in @("Global", "Both")) {
    Install-Global
}

if ($Scope -in @("Project", "Both")) {
    Install-Project
}

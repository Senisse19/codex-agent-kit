# Codex Agent Kit

Reusable AG Kit agents, skills, workflows, rules, and helper scripts — installable for both **OpenAI Codex CLI** and **Claude Code**.

This repository is intentionally a clean distribution package. It does not contain Codex or Claude auth files, logs, sessions, caches, SQLite state, or local runtime data.

## What Is Included

- `agents/`: AG Kit-style specialist personas such as `backend-specialist`, `frontend-specialist`, and `security-auditor`.
- `skills/`: `SKILL.md` folders, compatible with both Codex and Claude Code skill loading.
- `workflows/`: Markdown prompt procedures. For Codex these are read as workflow prompts; for Claude Code they are already authored as slash commands (`description` frontmatter + `$ARGUMENTS`) and install straight into `commands/`.
- `rules/`: Global rule files — `rules/CODEX.md` for Codex, `rules/CLAUDE.md` for Claude Code.
- `scripts/`: Optional helper scripts used by some skills/workflows.
- `ARCHITECTURE.md`: AG Kit reference doc (agents/skills/workflows map) copied into both Codex and Claude Code installs.
- `CODEX.md`: Codex-only reference doc copied into Codex installs.
- `AGENTS.md`: Global instruction file that teaches Codex how to use these personas. Not copied for the Claude Code target.
- `CLAUDE.global.md`: A single block of global orchestration instructions (model-delegation rules) merged into Claude Code's `CLAUDE.md`, between `<!-- agent-kit:claude-global:start -->` / `<!-- agent-kit:claude-global:end -->` markers. Only the content inside those markers is ever touched.

## Choosing a Target

Both installers accept a target:

- `codex` (default) — installs into `$CODEX_HOME` (or `<project>/.agent/`), unchanged from previous releases.
- `claude` — installs into `~/.claude` (or `<project>/.claude/` + `<project>/CLAUDE.md`).
- `all` — runs both installs in one pass.

## Important Limitation

Codex CLI currently loads `skills/` natively from `$CODEX_HOME/skills`.

The files in `agents/` are markdown instruction profiles, not native subagent types in the Codex "Subagents" screen. That screen lists active runtime subagents only. To use one of these personas, mention it explicitly:

```text
@backend-specialist review this API design
@frontend-specialist improve this React view
@security-auditor review the current diff
```

For lightweight, checklist-style reviews without invoking a full persona, point Codex at the `code-review-checklist` skill instead:

```text
Use the code-review-checklist skill to review the current diff
```

If you want a native runtime subagent to use a persona, ask explicitly:

```text
Use a subagent worker with the @backend-specialist instructions to inspect the API layer.
```

## Codex CLI — Global Installation

PowerShell:

```powershell
.\install.ps1 -Scope Global
```

Bash:

```bash
./install.sh --scope global
```

This copies:

- `agents/` to `$HOME/.codex/agents`
- `skills/` to `$HOME/.codex/skills`
- `workflows/` to `$HOME/.codex/workflows`
- `rules/` to `$HOME/.codex/rules`
- `scripts/` to `$HOME/.codex/scripts`
- `ARCHITECTURE.md` to `$HOME/.codex/ARCHITECTURE.md`
- `CODEX.md` to `$HOME/.codex/CODEX.md`
- `AGENTS.md` to `$HOME/.codex/AGENTS.md`

Existing files are backed up before being overwritten.

## Codex CLI — Project Installation

PowerShell:

```powershell
.\install.ps1 -Scope Project -ProjectPath C:\path\to\project
```

Bash:

```bash
./install.sh --scope project --project-path /path/to/project
```

This installs the kit into `<project>/.agent/`. If the project does not already have `AGENTS.md`, the installer creates one that points Codex to `.agent/`.

## Claude Code

Claude Code loads these kinds of files natively, per the [official docs](https://docs.claude.com/en/docs/claude-code/):

- `~/.claude/agents/*.md` (or `<project>/.claude/agents/*.md`) as **subagents**. Every agent in `agents/` uses `model: inherit` in its frontmatter, so the orchestrator/caller is expected to pass the `model` explicitly when delegating — the delegation rules for that live in `CLAUDE.global.md`.
- `~/.claude/skills/<name>/SKILL.md` (or `<project>/.claude/skills/...`) as **skills**.
- `~/.claude/commands/*.md` (or `<project>/.claude/commands/...`) as **slash commands**. The files under `workflows/` are already authored in that format (`description` frontmatter + `$ARGUMENTS`), so they install directly.
- `~/.claude/CLAUDE.md` (or `<project>/CLAUDE.md`) as **memory**. The installer never overwrites this file wholesale — it only replaces (or appends) the block between the `<!-- agent-kit:claude-global:start -->` / `<!-- agent-kit:claude-global:end -->` markers with the contents of `CLAUDE.global.md`. Anything else in that file (e.g. your own tool instructions) is left untouched.
- `~/.claude/rules/*.md` (or `<project>/.claude/rules/...`) as additional memory. `rules/CLAUDE.md` is copied here.

### Global Installation

PowerShell:

```powershell
.\install.ps1 -Target claude -Scope Global
```

Bash:

```bash
./install.sh --target claude --scope global
```

This copies:

- `agents/` to `$HOME/.claude/agents`
- `skills/` to `$HOME/.claude/skills`
- `workflows/` to `$HOME/.claude/commands`
- `rules/CLAUDE.md` to `$HOME/.claude/rules/CLAUDE.md`
- `scripts/` to `$HOME/.claude/scripts`
- `ARCHITECTURE.md` to `$HOME/.claude/ARCHITECTURE.md`
- `CLAUDE.global.md` merged into `$HOME/.claude/CLAUDE.md` (created if missing, markers replaced/appended otherwise)

`AGENTS.md`, `CODEX.md`, and `rules/CODEX.md` are Codex-only and are never copied for the Claude target. Existing files are backed up before being overwritten, and the installer never deletes files it didn't create (your own commands/agents/skills stay put).

### Project Installation

PowerShell:

```powershell
.\install.ps1 -Target claude -Scope Project -ProjectPath C:\path\to\project
```

Bash:

```bash
./install.sh --target claude --scope project --project-path /path/to/project
```

This installs into `<project>/.claude/{agents,skills,commands,rules,scripts}` and `<project>/.claude/ARCHITECTURE.md`, and merges `CLAUDE.global.md` into `<project>/CLAUDE.md` (same marker logic as above).

### Installing Both Targets

```powershell
.\install.ps1 -Target all -Scope Global
```

```bash
./install.sh --target all --scope global
```

## Updating

Pull the latest changes and rerun the installer for whichever target(s) you use:

```bash
git pull --ff-only
./install.sh --scope global            # Codex
./install.sh --target claude --scope global   # Claude Code
```

or:

```powershell
git pull --ff-only
.\install.ps1 -Scope Global                    # Codex
.\install.ps1 -Target claude -Scope Global      # Claude Code
```

## Safety Notes

- Do not commit your real `$HOME/.codex` or `$HOME/.claude` directory.
- Do not commit `auth.json`, logs, sessions, SQLite files, caches, or `.env` files.
- Review new skills before publishing. `SKILL.md` frontmatter must be valid YAML and include `name` and `description`.

## Repository Layout

```text
codex-agent-kit/
|-- agents/
|-- skills/
|-- workflows/
|-- rules/
|   |-- CODEX.md
|   `-- CLAUDE.md
|-- scripts/
|-- ARCHITECTURE.md
|-- CODEX.md
|-- AGENTS.md
|-- CLAUDE.global.md
|-- install.ps1
|-- install.sh
|-- README.md
`-- SECURITY.md
```

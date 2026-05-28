# Codex Agent Kit

Reusable Codex agents, skills, workflows, rules, and helper scripts.

This repository is intentionally a clean distribution package. It does not contain Codex auth files, logs, sessions, caches, SQLite state, or local runtime data.

## What Is Included

- `agents/`: AG Kit-style specialist personas such as `backend-specialist`, `frontend-specialist`, and `code-reviewer`.
- `skills/`: Codex-compatible `SKILL.md` folders.
- `workflows/`: Markdown workflow prompts.
- `rules/`: Global rule files.
- `scripts/`: Optional helper scripts used by some skills/workflows.
- `ARCHITECTURE.md` and `CODEX.md`: AG Kit reference docs copied into project installs.
- `AGENTS.md`: Global instruction file that teaches Codex how to use these personas.

## Important Limitation

Codex CLI currently loads `skills/` natively from `$CODEX_HOME/skills`.

The files in `agents/` are markdown instruction profiles, not native subagent types in the Codex "Subagents" screen. That screen lists active runtime subagents only. To use one of these personas, mention it explicitly:

```text
@backend-specialist review this API design
@frontend-specialist improve this React view
@code-reviewer review the current diff
```

If you want a native runtime subagent to use a persona, ask explicitly:

```text
Use a subagent worker with the @backend-specialist instructions to inspect the API layer.
```

## Global Installation

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

## Project Installation

PowerShell:

```powershell
.\install.ps1 -Scope Project -ProjectPath C:\path\to\project
```

Bash:

```bash
./install.sh --scope project --project-path /path/to/project
```

This installs the kit into `<project>/.agent/`. If the project does not already have `AGENTS.md`, the installer creates one that points Codex to `.agent/`.

## Updating

Pull the latest changes and rerun the installer:

```bash
git pull --ff-only
./install.sh --scope global
```

or:

```powershell
git pull --ff-only
.\install.ps1 -Scope Global
```

## Safety Notes

- Do not commit your real `$HOME/.codex` directory.
- Do not commit `auth.json`, logs, sessions, SQLite files, caches, or `.env` files.
- Review new skills before publishing. `SKILL.md` frontmatter must be valid YAML and include `name` and `description`.

## Repository Layout

```text
codex-agent-kit/
|-- agents/
|-- skills/
|-- workflows/
|-- rules/
|-- scripts/
|-- ARCHITECTURE.md
|-- CODEX.md
|-- AGENTS.md
|-- install.ps1
|-- install.sh
|-- README.md
`-- SECURITY.md
```

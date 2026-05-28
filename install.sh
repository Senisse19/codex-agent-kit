#!/usr/bin/env bash
set -euo pipefail

SCOPE="global"
PROJECT_PATH="$(pwd)"
NO_BACKUP="false"
FORCE_PROJECT_AGENTS_FILE="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="${2:-}"
      shift 2
      ;;
    --project-path)
      PROJECT_PATH="${2:-}"
      shift 2
      ;;
    --no-backup)
      NO_BACKUP="true"
      shift
      ;;
    --force-project-agents-file)
      FORCE_PROJECT_AGENTS_FILE="true"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  ./install.sh --scope global
  ./install.sh --scope project --project-path /path/to/project
  ./install.sh --scope both --project-path /path/to/project

Options:
  --no-backup                    Skip backup before copying
  --force-project-agents-file     Overwrite project AGENTS.md after backup
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

copy_kit_directory() {
  local source="$1"
  local destination="$2"

  [[ -d "$source" ]] || return 0
  mkdir -p "$destination"
  cp -R "$source"/. "$destination"/
}

backup_path() {
  local path="$1"
  local backup_root="$2"

  [[ "$NO_BACKUP" == "false" ]] || return 0
  [[ -e "$path" ]] || return 0

  mkdir -p "$backup_root"
  cp -R "$path" "$backup_root"/
}

install_global() {
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local backup_root="$codex_home/backups/codex-agent-kit-$stamp"

  mkdir -p "$codex_home"

  for name in agents skills workflows rules scripts; do
    backup_path "$codex_home/$name" "$backup_root"
    copy_kit_directory "$SCRIPT_DIR/$name" "$codex_home/$name"
  done

  for name in ARCHITECTURE.md CODEX.md; do
    if [[ -f "$SCRIPT_DIR/$name" ]]; then
      backup_path "$codex_home/$name" "$backup_root"
      cp "$SCRIPT_DIR/$name" "$codex_home/$name"
    fi
  done

  if [[ -f "$SCRIPT_DIR/AGENTS.md" ]]; then
    backup_path "$codex_home/AGENTS.md" "$backup_root"
    cp "$SCRIPT_DIR/AGENTS.md" "$codex_home/AGENTS.md"
  fi

  echo "Installed Codex Agent Kit globally at $codex_home"
  if [[ "$NO_BACKUP" == "false" && -d "$backup_root" ]]; then
    echo "Backup written to $backup_root"
  fi
}

install_project() {
  local resolved_project
  resolved_project="$(cd "$PROJECT_PATH" && pwd)"
  local agent_root="$resolved_project/.agent"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  local backup_root="$resolved_project/.agent-backups/codex-agent-kit-$stamp"

  mkdir -p "$agent_root"

  for name in agents skills workflows rules scripts; do
    backup_path "$agent_root/$name" "$backup_root"
    copy_kit_directory "$SCRIPT_DIR/$name" "$agent_root/$name"
  done

  for name in ARCHITECTURE.md CODEX.md; do
    if [[ -f "$SCRIPT_DIR/$name" ]]; then
      backup_path "$agent_root/$name" "$backup_root"
      cp "$SCRIPT_DIR/$name" "$agent_root/$name"
    fi
  done

  local agents_file="$resolved_project/AGENTS.md"
  if [[ ! -f "$agents_file" || "$FORCE_PROJECT_AGENTS_FILE" == "true" ]]; then
    backup_path "$agents_file" "$backup_root"
    cat > "$agents_file" <<'EOF'
# Project Agent Instructions

This workspace includes Codex Agent Kit in `.agent/`.

Before using a specialist persona or workflow:

1. Read `.agent/ARCHITECTURE.md` for available agents, skills, and workflows.
2. For an explicit `@agent-name` request, read `.agent/agents/<agent-name>.md`.
3. For an explicit skill request, read `.agent/skills/<skill-name>/SKILL.md`.
4. When an agent file declares `skills:` in frontmatter, load only the relevant listed skill files.

Native Codex subagents are runtime workers, not these markdown personas. Use these markdown files as specialist instruction profiles.
EOF
  fi

  echo "Installed Codex Agent Kit for project at $agent_root"
  if [[ "$NO_BACKUP" == "false" && -d "$backup_root" ]]; then
    echo "Backup written to $backup_root"
  fi
}

case "$SCOPE" in
  global)
    install_global
    ;;
  project)
    install_project
    ;;
  both)
    install_global
    install_project
    ;;
  *)
    echo "Invalid scope: $SCOPE. Use global, project, or both." >&2
    exit 1
    ;;
esac

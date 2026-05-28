# Global Agent Instructions

This Codex home includes AG Kit-style specialist personas in `~/.codex/agents/`.

These markdown files are not native Codex subagent types. Treat them as reusable specialist instruction profiles:

1. When the user explicitly mentions `@agent-name`, read `~/.codex/agents/<agent-name>.md`.
2. If that agent frontmatter has `skills:`, read only the relevant `~/.codex/skills/<skill>/SKILL.md` files needed for the task.
3. Native Codex subagents remain runtime workers. If the user asks to delegate to a specialist, spawn a native worker and include the relevant agent markdown instructions in the worker prompt.
4. To list available AG Kit personas, inspect `~/.codex/agents/*.md`.

Global skills live in `~/.codex/skills/` and are loaded by Codex when their `SKILL.md` frontmatter is valid.

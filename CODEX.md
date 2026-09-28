# CODEX.md - AG Kit

> Root-level reference doc installed alongside `ARCHITECTURE.md`. This file orients Codex (and anyone reading the install) to how AG Kit is organized for the Codex CLI.

---

## What This Kit Provides

- `agents/` - specialist persona instruction profiles (`@agent-name` mentions).
- `skills/` - `SKILL.md` knowledge modules, loaded on demand via agent frontmatter.
- `workflows/` - reusable prompt procedures.
- `rules/CODEX.md` - the full behavioral ruleset (request classification, agent routing protocol, Socratic gate, checklist scripts). Read it before doing substantial work; treat it as always-on guidance for this workspace.
- `scripts/` - helper scripts invoked by skills/workflows.

## Where To Start

1. Read `ARCHITECTURE.md` for the full map of agents, skills, and workflows.
2. Read `rules/CODEX.md` for the behavioral protocol (agent routing, Socratic gate, quality checklist).
3. For an explicit `@agent-name` request, read `agents/<agent-name>.md`.
4. When an agent's frontmatter declares `skills:`, read only the listed `skills/<skill>/SKILL.md` files needed for the task.

## Native Subagents vs. Personas

The files in `agents/` are markdown instruction profiles, not native Codex "Subagents." To use one, mention it explicitly (`@backend-specialist review this API design`) or ask Codex to spawn a native worker using the persona's instructions.

See `rules/CODEX.md` for the complete, enforceable rule set.

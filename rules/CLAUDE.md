---
trigger: always_on
---

# AG Kit — Agents, Skills & Quality Gates

> Catalog and quality rules for the agents in `~/.claude/agents/`, skills in `~/.claude/skills/` and scripts in `~/.claude/scripts/`.
> **Who executes and with which model** is defined in `~/.claude/CLAUDE.md` → *Orquestração de Agentes*, which wins any conflict.
> Full system map: `~/.claude/ARCHITECTURE.md` (consult when you need details not listed here).

---

## 1. Request Flow

1. **Classify** the request (table below).
2. **Socratic Gate** (section 2) when the request is not a plain question.
3. **Route** to a subagent (section 3) with a model chosen by the delegation criteria.
4. **Verify and close** (section 6).

| Request type | Trigger keywords                                  | Action                                                    |
| ------------ | ------------------------------------------------- | --------------------------------------------------------- |
| Question     | "what is", "how does", "explain", "como funciona" | Answer directly — no delegation, no file changes          |
| Survey/Intel | "analyze", "list files", "overview"               | `Explore` agent (`haiku`)                                 |
| Simple code  | "fix", "add", "change" (single file)              | Delegate (`haiku` or `sonnet`)                            |
| Complex code | "build", "create", "implement", "refactor"        | Plan in `.claude/tmp/{task-slug}.md` → delegate           |
| Design/UI    | "design", "UI", "page", "dashboard", "tela"       | Plan in `.claude/tmp/{task-slug}.md` → delegate (`fable`) |
| Slash cmd    | `/create`, `/orchestrate`, `/debug`               | Command-specific flow                                     |

---

## 2. Socratic Gate

Every non-question request passes the gate **before any delegation or implementation**.

| Request type        | Strategy       | Required action                                    |
| ------------------- | -------------- | -------------------------------------------------- |
| New feature / build | Deep discovery | Ask at least 3 strategic questions                 |
| Code edit / bug fix | Context check  | Confirm understanding + ask impact questions       |
| Vague / simple      | Clarification  | Ask purpose, users and scope                       |
| Full orchestration  | Gatekeeper     | No subagents until the user confirms the plan      |
| Direct "proceed"    | Validation     | Even with answers given, ask 2 edge-case questions |

- **Never assume:** if even 1% is unclear, ask.
- **Spec-heavy requests** (user answers 1, 2, 3...): don't skip the gate — ask about trade-offs or edge cases instead.
- Full protocol: skill `brainstorming`.

---

## 3. Agent Routing

Pick the `subagent_type` by domain; the model comes from the delegation criteria. A user `@agent` mention overrides the choice.

| Domain                                       | `subagent_type`                                  |
| -------------------------------------------- | ------------------------------------------------ |
| Backend, API, server, integrations           | `backend-specialist`                             |
| Database: tables, relationships, queries     | `database-architect`                             |
| Web UI (React, Next.js)                      | `frontend-specialist`                            |
| Mobile (iOS, Android, React Native, Flutter) | `mobile-developer` — never `frontend-specialist` |
| Bug, error, crash                            | `debugger`                                       |
| Unit/integration tests                       | `test-engineer`                                  |
| E2E, pipelines                               | `qa-automation-engineer`                         |
| Security audit                               | `security-auditor`                               |
| Authorized offensive testing                 | `penetration-tester`                             |
| Deploy, infra, CI/CD                         | `devops-engineer`                                |
| Performance                                  | `performance-optimizer`                          |
| Legacy code, refactor planning               | `code-archaeologist`                             |
| Planning, task breakdown                     | `project-planner`                                |
| Requirements, user stories                   | `product-manager` / `product-owner`              |
| SEO / GEO                                    | `seo-specialist`                                 |
| Games                                        | `game-developer`                                 |
| Documentation (only when explicitly asked)   | `documentation-writer`                           |
| Broad codebase search                        | `Explore`                                        |
| Anything else, final code review             | `general-purpose`                                |

- Don't spawn the `orchestrator` agent: the main session already is the orchestrator.
- `code-reviewer` is specific to the Anthropic Cookbook repo — don't use it for general reviews.

---

## 4. Quality Standards

Include these in every delegation prompt (the subagent does not see this file).

- **Language:** reply in the user's language; code, comments and identifiers in English.
- **Agent & skills:** follow the agent's own `.md` rules and load the skills in its `skills:` frontmatter —
  read `~/.claude/skills/<skill>/SKILL.md` first, then only the sections relevant to the task.
  Priority: `CLAUDE.md` > agent `.md` > `SKILL.md`.
- **Read → Understand → Apply:** before coding, know the goal of the agent/skill, the principles to apply and how the result differs from generic output.
- **Clean code:** skill `clean-code` — concise, direct, self-documenting, no over-engineering.
- **Testing:** mandatory; pyramid (unit > integration > E2E) with the AAA pattern.
- **Performance:** measure first; follow current Core Web Vitals standards.
- **Security:** never commit or log secrets; verify secret handling on every change.
- **File dependencies:** if the project has `CODEBASE.md`, check dependent files and update them together.
- **Design:** Purple Ban, Template Ban, anti-cliché and Deep Design Thinking rules live in
  `~/.claude/agents/frontend-specialist.md` and `~/.claude/agents/mobile-developer.md`.

---

## 5. Modes

| Mode   | Behavior                                                                          |
| ------ | --------------------------------------------------------------------------------- |
| `plan` | 4 phases, no code before phase 4 (`project-planner` may support the analysis)     |
| `ask`  | Focus on understanding; ask questions                                             |
| `edit` | Execute through delegation; check `.claude/tmp/{task-slug}.md` first if it exists |

Plan phases: **1. Analysis** (research, questions) → **2. Planning** (`{task-slug}.md`, task breakdown) →
**3. Solutioning** (architecture and design, no code) → **4. Implementation** (code + tests, delegated).

Multi-file or structural change → offer a `{task-slug}.md`; single-file fix → delegate directly.

---

## 6. Verification & Final Checklist

**Trigger:** "final checks", "checagem final", "rode todos os testes", "son kontrolleri yap" or similar.

| Stage        | Command                                                | Purpose                        |
| ------------ | ------------------------------------------------------ | ------------------------------ |
| Manual audit | `python ~/.claude/scripts/checklist.py .`              | Priority-based project audit   |
| Pre-deploy   | `python ~/.claude/scripts/verify_all.py . --url <URL>` | Full suite + performance + E2E |

Priority order: **Security → Lint → Schema → Tests → UX → SEO → Lighthouse/E2E**.

- A task is not finished until the checks applicable to the project pass.
- On failure, delegate the fixes — **Critical** blockers (security, lint) first.

Individual scripts — `python ~/.claude/skills/<skill>/scripts/<script>.py`:

| Script                         | Skill                 | When to use          |
| ------------------------------ | --------------------- | -------------------- |
| `security_scan.py`             | vulnerability-scanner | Always before deploy |
| `lint_runner.py`               | lint-and-validate     | Every code change    |
| `type_coverage.py`             | lint-and-validate     | Typed codebases      |
| `test_runner.py`               | testing-patterns      | After logic change   |
| `schema_validator.py`          | database-design       | After DB change      |
| `api_validator.py`             | api-patterns          | After API change     |
| `ux_audit.py`                  | frontend-design       | After UI change      |
| `accessibility_checker.py`     | frontend-design       | After UI change      |
| `react_performance_checker.py` | nextjs-react-expert   | After React change   |
| `i18n_checker.py`              | i18n-localization     | After text/UI change |
| `seo_checker.py`               | seo-fundamentals      | After page change    |
| `geo_checker.py`               | geo-fundamentals      | After content change |
| `mobile_audit.py`              | mobile-design         | After mobile change  |
| `lighthouse_audit.py`          | performance-profiling | Before deploy        |
| `playwright_runner.py`         | webapp-testing        | Before deploy        |

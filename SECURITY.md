# Security Policy

This repository is public. Treat every committed file as public information.

## Do Not Commit

- Codex authentication files such as `auth.json`
- `.env` or other secret files
- API keys, OAuth tokens, passwords, cookies, or private keys
- Session logs, SQLite state, cache directories, or generated runtime data
- Customer data or private project source code

## Before Publishing Changes

Run a secret-oriented search:

```powershell
rg -n --hidden --glob '!.git/**' "(sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|api[_-]?key|access[_-]?token|refresh[_-]?token|password|secret)"
```

Validate skill frontmatter:

```powershell
npx --yes js-yaml skills/lint-and-validate/SKILL.md
```

For full validation, parse only the YAML frontmatter from every `SKILL.md`.

## Reporting

If you find a secret in the repository history, rotate the credential immediately. Removing it from the latest commit is not enough once it has been pushed to a public remote.

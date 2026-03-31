# Skills Template Repo

This repository contains a reusable VS Code Copilot skills bundle.

## Structure

- `.github/skills/` - all installed skills (126 folders currently)
- `scripts/sync-skills.ps1` - sync script to refresh skills from upstream

## Usage

1. Copy `.github/skills` into any project root.
2. Open VS Code in that project.
3. Use natural language triggers in Copilot Chat (for example: review, security, django, python-testing).

## Create your GitHub template repo

```powershell
git init
git add .
git commit -m "chore: initialize skills template repo"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Then in GitHub settings, enable **Template repository**.

## Update skills from upstream

```powershell
./scripts/sync-skills.ps1
```

The script only refreshes `.github/skills` from upstream repo:

- Upstream: `https://github.com/affaan-m/everything-claude-code`
- Path: `skills`

## Notes

- Skills are workspace-level assets (not true user-global assets).
- For multi-project reuse, this template repo is the recommended workflow.

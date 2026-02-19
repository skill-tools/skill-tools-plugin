# skill-tools-plugin — Claude Code Plugin

Claude Code plugin for auto-linting and checking SKILL.md files. Provides slash commands and a PostToolUse hook.

## Structure

- `.claude-plugin/plugin.json` - Plugin metadata (name, description, author, homepage)
- `commands/check.md` - `/skill-tools:check` slash command
- `commands/lint.md` - `/skill-tools:lint` slash command
- `hooks/hooks.json` - Hook config (PostToolUse on Write|Edit)
- `hooks/post-write-lint.sh` - Auto-lint hook (runs after every SKILL.md edit)
- `scripts/setup.sh` - Dependency checker + npx cache warmer
- `skills/skill-quality/SKILL.md` - Guidance skill for writing high-quality SKILL.md files
- `tests/test-hook.sh` - 19 tests for hook behavior

## Version Pinning

skill-tools version is pinned in 4 places (defense against supply chain attacks):
1. `hooks/post-write-lint.sh` — `SKILL_TOOLS_VERSION="0.2.2"`
2. `scripts/setup.sh` — `SKILL_TOOLS_VERSION="0.2.2"`
3. `commands/check.md` — `npx --yes skill-tools@0.2.2`
4. `commands/lint.md` — `npx --yes skill-tools@0.2.2`

ALL 4 MUST BE UPDATED TOGETHER ON VERSION BUMPS.

## Current State

- **Plugin version:** 0.1.1
- **Pinned skill-tools:** 0.2.2
- **Lint rules referenced:** 9
- **Validation checks referenced:** 20

## Ecosystem Context

This repo is a downstream consumer of skill-tools. See `/Users/piyush/GitHub/CLAUDE.md` for the full cross-repo dependency graph.

```
skill-tools (v0.2.2) ──→ skill-tools-plugin (this repo, v0.1.1)
                     ──→ skills.menu (Astro site)
                     ──→ bap (v0.2.0)
```

## ASSOCIATED REPOS

WHEN MAKING CHANGES TO THIS REPO, CHECK IF ANY OF THESE REPOS NEED UPDATES TOO:

| Repo | Path | What to sync |
|------|------|-------------|
| **skill-tools** | `/Users/piyush/GitHub/skill-tools` | Core toolchain. This plugin pins a specific version. On skill-tools releases: bump version pin in all 4 files, update rule/check counts, bump plugin version + changelog |
| **skills.menu** | `/Users/piyush/GitHub/skills.menu` | Website. Both this plugin and the site reference the same version numbers and rule counts — keep in sync |
| **bap** | `/Users/piyush/GitHub/bap` | Browser Agent Protocol. No direct dependency |

CHANGES THAT REQUIRE CROSS-REPO UPDATES:
- **Plugin version bump** → No cross-repo impact (self-contained)
- **New slash command added** → Consider: skills.menu (could document the plugin)
- **skill-tools version pin changed here** → Also check: skills.menu (should have same version in package.json and docs)

# skill-tools

A Claude Code plugin for validating, linting, and scoring Agent Skill (SKILL.md) files.

The plugin's main feature is an auto-lint hook that runs after every SKILL.md edit, feeding results back to Claude as context so it can self-correct quality issues in the same turn.

## Install

Inside Claude Code:

```
/install-plugin https://github.com/skill-tools/skill-tools-plugin
```

For local development:

```bash
claude --plugin-dir /path/to/skill-tools-plugin
```

### Prerequisites

- **Node.js 18+** and **npx**
- **jq** — `brew install jq` (macOS) or `apt install jq` (Linux)

After installing, run the dependency checker to verify and pre-warm the cache:

```bash
bash /path/to/skill-tools-plugin/scripts/setup.sh
```

## Commands

| Command | What it does |
|:--------|:-------------|
| `/skill-tools:lint <path>` | Lint for quality issues — description clarity, examples, error handling, heading structure |
| `/skill-tools:check <path>` | Full report: validate + lint + score (0–100) in one pass |

If `<path>` is omitted, the command finds all SKILL.md files in the project.

## Auto-lint hook

A PostToolUse hook watches for Write and Edit tool calls. When the target file is a SKILL.md, the hook:

1. Runs `skill-tools lint --format json` (no ANSI, machine-readable)
2. Builds a plain-text summary from the JSON
3. Returns it as `additionalContext` so Claude sees the results immediately

The hook is pinned to `skill-tools@0.2.0` to avoid supply chain risk. It silently skips if dependencies are missing — it never blocks edits.

## Skill: quality guidance

The `skill-quality` skill activates when working on SKILL.md files. It teaches the thinking behind good skills rather than restating the linter's rules:

- Why descriptions matter for agent selection
- How to write instructions that guide well (examples, error handling, structure)
- When to split large skills using progressive disclosure
- Common lint failures and the reasoning behind each fix

## Testing

Run the test suite:

```bash
bash tests/test-hook.sh
```

This tests hook input validation, JSON output structure, graceful degradation, and plugin manifest correctness.

## Plugin structure

```
skill-tools-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── check.md
│   └── lint.md
├── hooks/
│   ├── hooks.json
│   └── post-write-lint.sh
├── skills/
│   └── skill-quality/
│       └── SKILL.md
├── scripts/
│   └── setup.sh
├── tests/
│   └── test-hook.sh
├── CHANGELOG.md
├── LICENSE
├── .gitignore
└── README.md
```

## Version management

The `skill-tools` npm package version is pinned in three places:

- `hooks/post-write-lint.sh` — `SKILL_TOOLS_VERSION` variable
- `scripts/setup.sh` — `SKILL_TOOLS_VERSION` variable
- `commands/*.md` — version in the `npx` commands

To update, change all three. Search for the old version string to find them.

## License

MIT — see [LICENSE](LICENSE).

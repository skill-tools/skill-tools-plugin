# Changelog

## 0.1.1 — 2026-02-13

### Changed
- Bump pinned skill-tools version from 0.2.0 to 0.2.2
- Update lint rule count from 8 to 9 (added `description-length-optimal`)
- Update validation check count from 16 to 20 (added `name-matches-directory`, `compatibility-type`, `compatibility-length`, `license-type`)
- Add description length rule to lint command docs

## 0.1.0 — 2026-02-12

Initial release.

### Added
- **Auto-lint hook** — PostToolUse hook that lints SKILL.md files after every Write/Edit, returning results as plain-text context for Claude
- **`/skill-tools:lint`** — Slash command for on-demand quality linting with rule explanations
- **`/skill-tools:check`** — Full quality report (validate + lint + score) in one pass
- **`skill-quality` skill** — Guidance for writing high-quality skills, focused on description writing, instruction design, and common pitfalls
- **Dependency checker** (`scripts/setup.sh`) — Verifies Node.js 18+, npx, and jq are available
- **Test suite** (`tests/test-hook.sh`) — 19 tests covering hook behavior, input validation, JSON output, and plugin structure

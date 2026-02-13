#!/usr/bin/env bash
# post-write-lint.sh — PostToolUse hook for auto-linting SKILL.md files.
#
# Fires on every Write|Edit. Checks if the target is a SKILL.md, and if so,
# runs skill-tools lint and returns a plain-text summary as context for Claude.
#
# Design decisions:
#   - Uses --format json to avoid ANSI escape codes in additionalContext
#   - Validates FILE_PATH before passing to subprocess (defense in depth)
#   - Silently exits on any missing dependency — never blocks edits
#   - Pinned to a specific skill-tools version to avoid supply chain risk

set -euo pipefail

SKILL_TOOLS_VERSION="0.2.2"

# --- dependency check ---------------------------------------------------
for cmd in jq npx; do
  if ! command -v "$cmd" &>/dev/null; then
    exit 0
  fi
done

# --- read hook input -----------------------------------------------------
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only act on SKILL.md files
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

if [[ "$(basename "$FILE_PATH")" != "SKILL.md" ]]; then
  exit 0
fi

# Validate the path looks like a real filesystem path (defense in depth)
if [[ "$FILE_PATH" =~ [[:cntrl:]] ]] || [[ ! "$FILE_PATH" =~ ^/ ]]; then
  exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# --- run lint (JSON output, no ANSI) -------------------------------------
LINT_JSON=$(npx --yes "skill-tools@${SKILL_TOOLS_VERSION}" lint --format json "$FILE_PATH" 2>/dev/null) || true

if [[ -z "$LINT_JSON" ]]; then
  exit 0
fi

# Verify we got valid JSON back
if ! echo "$LINT_JSON" | jq empty 2>/dev/null; then
  exit 0
fi

# --- build a clean plain-text summary ------------------------------------
# lint output is an array of results (one per file). We only lint one file.
RESULT=$(echo "$LINT_JSON" | jq '.[0] // empty')

if [[ -z "$RESULT" ]] || [[ "$RESULT" == "null" ]]; then
  exit 0
fi

WARNINGS=$(echo "$RESULT" | jq '[.diagnostics[]? | select(.severity == "warning")] | length')
INFOS=$(echo "$RESULT" | jq '[.diagnostics[]? | select(.severity == "info")] | length')
ERRORS=$(echo "$RESULT" | jq '[.diagnostics[]? | select(.severity == "error")] | length')
TOTAL=$(echo "$RESULT" | jq '.diagnostics | length')

SKILL_DIR=$(basename "$(dirname "$FILE_PATH")")

if [[ "$TOTAL" == "0" ]]; then
  SUMMARY="skill-tools lint: all 9 rules passed for ${SKILL_DIR}/SKILL.md"
else
  MESSAGES=$(echo "$RESULT" | jq -r '.diagnostics[]? | "  [\(.severity)] \(.ruleId // "unknown"): \(.message)"')
  SUMMARY="skill-tools lint: ${ERRORS} error(s), ${WARNINGS} warning(s), ${INFOS} info(s) in ${SKILL_DIR}/SKILL.md
${MESSAGES}"
fi

ESCAPED=$(echo "$SUMMARY" | jq -Rs .)

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": ${ESCAPED}
  }
}
EOF

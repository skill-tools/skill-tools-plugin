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
#   - Uses node (not jq) for JSON parsing — node is already required for npx

set -euo pipefail

SKILL_TOOLS_VERSION="0.2.2"

# --- dependency check ---------------------------------------------------
for cmd in node npx; do
  if ! command -v "$cmd" &>/dev/null; then
    exit 0
  fi
done

# --- read hook input -----------------------------------------------------
INPUT=$(cat)
FILE_PATH=$(node -e "
  try {
    const d = JSON.parse(process.argv[1]);
    const p = d && d.tool_input && d.tool_input.file_path;
    if (p) process.stdout.write(p);
  } catch {}
" -- "$INPUT" 2>/dev/null) || true

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

# --- build a clean plain-text summary and output JSON --------------------
SKILL_DIR=$(basename "$(dirname "$FILE_PATH")")

LINT_JSON="$LINT_JSON" SKILL_DIR="$SKILL_DIR" node -e "
  try {
    const results = JSON.parse(process.env.LINT_JSON);
    const r = results && results[0];
    if (!r) process.exit(0);

    const diags = r.diagnostics || [];
    const errors = diags.filter(d => d.severity === 'error').length;
    const warnings = diags.filter(d => d.severity === 'warning').length;
    const infos = diags.filter(d => d.severity === 'info').length;
    const dir = process.env.SKILL_DIR;

    let summary;
    if (diags.length === 0) {
      summary = 'skill-tools lint: all 9 rules passed for ' + dir + '/SKILL.md';
    } else {
      const msgs = diags.map(d =>
        '  [' + d.severity + '] ' + (d.ruleId || 'unknown') + ': ' + d.message
      ).join('\n');
      summary = 'skill-tools lint: ' + errors + ' error(s), ' + warnings +
        ' warning(s), ' + infos + ' info(s) in ' + dir + '/SKILL.md\n' + msgs;
    }

    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PostToolUse',
        additionalContext: summary
      }
    }));
  } catch {}
" 2>/dev/null || true

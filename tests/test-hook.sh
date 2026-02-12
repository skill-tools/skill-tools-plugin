#!/usr/bin/env bash
# test-hook.sh — Tests for post-write-lint.sh
#
# Usage: bash tests/test-hook.sh
#
# Tests the hook script's behavior with various inputs without requiring
# the actual skill-tools npm package (uses mocked npx for most tests).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK="$PLUGIN_ROOT/hooks/post-write-lint.sh"

PASSED=0
FAILED=0
TOTAL=0

# --- helpers --------------------------------------------------------------

pass() {
  PASSED=$((PASSED + 1))
  TOTAL=$((TOTAL + 1))
  echo "  ✓ $1"
}

fail() {
  FAILED=$((FAILED + 1))
  TOTAL=$((TOTAL + 1))
  echo "  ✗ $1"
  if [[ -n "${2:-}" ]]; then
    echo "    $2"
  fi
}

run_hook() {
  # Runs the hook with the given JSON on stdin.
  # Returns the hook's stdout. Exit code is always 0 (hook should never fail hard).
  echo "$1" | bash "$HOOK" 2>/dev/null || true
}

# --- setup ----------------------------------------------------------------

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Create a minimal valid SKILL.md for tests that need a real file
mkdir -p "$TMPDIR/test-skill"
cat > "$TMPDIR/test-skill/SKILL.md" <<'SKILLEOF'
---
name: test-skill
description: >-
  A test skill for unit tests. Use when running the test suite.
---

# Test Skill

## Instructions

This is a test skill used by the hook test suite.

### Example

```bash
echo "hello"
```

### Error Handling

If the test fails, check that the hook script is executable.
SKILLEOF

echo "Running hook tests..."
echo ""

# --- test: non-SKILL.md file produces no output ---------------------------

OUTPUT=$(run_hook '{"tool_input": {"file_path": "/tmp/foo.ts"}}')
if [[ -z "$OUTPUT" ]]; then
  pass "non-SKILL.md file: silent exit"
else
  fail "non-SKILL.md file: expected no output" "got: $OUTPUT"
fi

# --- test: missing file_path produces no output ---------------------------

OUTPUT=$(run_hook '{"tool_input": {}}')
if [[ -z "$OUTPUT" ]]; then
  pass "missing file_path: silent exit"
else
  fail "missing file_path: expected no output" "got: $OUTPUT"
fi

# --- test: empty input produces no output ---------------------------------

OUTPUT=$(run_hook '{}')
if [[ -z "$OUTPUT" ]]; then
  pass "empty input: silent exit"
else
  fail "empty input: expected no output" "got: $OUTPUT"
fi

# --- test: nonexistent SKILL.md produces no output ------------------------

OUTPUT=$(run_hook '{"tool_input": {"file_path": "/tmp/nonexistent/SKILL.md"}}')
if [[ -z "$OUTPUT" ]]; then
  pass "nonexistent SKILL.md: silent exit"
else
  fail "nonexistent SKILL.md: expected no output" "got: $OUTPUT"
fi

# --- test: relative path rejected ----------------------------------------

OUTPUT=$(run_hook '{"tool_input": {"file_path": "relative/SKILL.md"}}')
if [[ -z "$OUTPUT" ]]; then
  pass "relative path: rejected (silent exit)"
else
  fail "relative path: expected no output" "got: $OUTPUT"
fi

# --- test: path with control characters rejected --------------------------

OUTPUT=$(run_hook "{\"tool_input\": {\"file_path\": \"/tmp/evil\\n/SKILL.md\"}}")
if [[ -z "$OUTPUT" ]]; then
  pass "path with control chars: rejected (silent exit)"
else
  fail "path with control chars: expected no output" "got: $OUTPUT"
fi

# --- test: valid SKILL.md produces JSON output ----------------------------
# This test requires npx and skill-tools to be available.

if command -v npx &>/dev/null && command -v jq &>/dev/null; then
  OUTPUT=$(run_hook "{\"tool_input\": {\"file_path\": \"$TMPDIR/test-skill/SKILL.md\"}}")
  if [[ -n "$OUTPUT" ]]; then
    # Verify it's valid JSON
    if echo "$OUTPUT" | jq empty 2>/dev/null; then
      pass "valid SKILL.md: produces valid JSON"

      # Verify structure
      HAS_CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext // empty')
      if [[ -n "$HAS_CONTEXT" ]]; then
        pass "valid SKILL.md: has additionalContext"
      else
        fail "valid SKILL.md: missing additionalContext" "got: $OUTPUT"
      fi

      HAS_EVENT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.hookEventName // empty')
      if [[ "$HAS_EVENT" == "PostToolUse" ]]; then
        pass "valid SKILL.md: hookEventName is PostToolUse"
      else
        fail "valid SKILL.md: wrong hookEventName" "got: $HAS_EVENT"
      fi
    else
      fail "valid SKILL.md: output is not valid JSON" "got: $OUTPUT"
    fi
  else
    # Empty output means npx couldn't resolve skill-tools — skip gracefully
    echo "  ● valid SKILL.md: skipped (skill-tools not cached, npx may need to download)"
  fi
else
  echo "  ● integration tests skipped (npx or jq not available)"
fi

# --- test: hooks.json is valid JSON ---------------------------------------

if jq empty "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null; then
  pass "hooks.json: valid JSON"
else
  fail "hooks.json: invalid JSON"
fi

# --- test: hooks.json has correct structure --------------------------------

MATCHER=$(jq -r '.hooks.PostToolUse[0].matcher // empty' "$PLUGIN_ROOT/hooks/hooks.json")
if [[ "$MATCHER" == "Write|Edit" ]]; then
  pass "hooks.json: matcher is Write|Edit"
else
  fail "hooks.json: wrong matcher" "expected Write|Edit, got: $MATCHER"
fi

TIMEOUT=$(jq -r '.hooks.PostToolUse[0].hooks[0].timeout // empty' "$PLUGIN_ROOT/hooks/hooks.json")
if [[ "$TIMEOUT" -ge 30 ]]; then
  pass "hooks.json: timeout is >= 30s ($TIMEOUT)"
else
  fail "hooks.json: timeout too low" "got: $TIMEOUT"
fi

# --- test: plugin.json is valid -------------------------------------------

if jq empty "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
  pass "plugin.json: valid JSON"
else
  fail "plugin.json: invalid JSON"
fi

PLUGIN_NAME=$(jq -r '.name // empty' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
if [[ -n "$PLUGIN_NAME" ]]; then
  pass "plugin.json: has name field ($PLUGIN_NAME)"
else
  fail "plugin.json: missing name"
fi

PLUGIN_VERSION=$(jq -r '.version // empty' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
if [[ "$PLUGIN_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  pass "plugin.json: valid semver ($PLUGIN_VERSION)"
else
  fail "plugin.json: missing or invalid version" "got: $PLUGIN_VERSION"
fi

# --- test: hook script is executable --------------------------------------

if [[ -x "$HOOK" ]]; then
  pass "post-write-lint.sh: is executable"
else
  fail "post-write-lint.sh: not executable"
fi

# --- test: skill SKILL.md has required frontmatter ------------------------

if [[ -f "$PLUGIN_ROOT/skills/skill-quality/SKILL.md" ]]; then
  # Check for name and description in frontmatter
  if head -10 "$PLUGIN_ROOT/skills/skill-quality/SKILL.md" | grep -q "^name:"; then
    pass "skill SKILL.md: has name in frontmatter"
  else
    fail "skill SKILL.md: missing name in frontmatter"
  fi
  if head -10 "$PLUGIN_ROOT/skills/skill-quality/SKILL.md" | grep -q "^description:"; then
    pass "skill SKILL.md: has description in frontmatter"
  else
    fail "skill SKILL.md: missing description in frontmatter"
  fi
else
  fail "skill SKILL.md: file not found"
fi

# --- test: LICENSE file exists --------------------------------------------

if [[ -f "$PLUGIN_ROOT/LICENSE" ]]; then
  pass "LICENSE: file exists"
else
  fail "LICENSE: file missing"
fi

# --- summary --------------------------------------------------------------

echo ""
echo "──────────────────────────────────────"
echo "$TOTAL tests | $PASSED passed | $FAILED failed"

if [[ "$FAILED" -gt 0 ]]; then
  echo ""
  echo "FAIL"
  exit 1
else
  echo ""
  echo "OK"
  exit 0
fi

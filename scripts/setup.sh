#!/usr/bin/env bash
# setup.sh — Check that dependencies are available for skill-tools-plugin.
#
# Run this after installing the plugin to verify everything works.
# Also pre-warms the npx cache so the first hook invocation is fast.

set -euo pipefail

SKILL_TOOLS_VERSION="0.2.2"
OK=true

echo "Checking dependencies for skill-tools-plugin..."
echo ""

# Node.js
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
  if [[ "$NODE_MAJOR" -ge 18 ]]; then
    echo "  ✓ Node.js $NODE_VERSION"
  else
    echo "  ✗ Node.js $NODE_VERSION (need 18+)"
    OK=false
  fi
else
  echo "  ✗ Node.js not found — install from https://nodejs.org"
  OK=false
fi

# npx
if command -v npx &>/dev/null; then
  echo "  ✓ npx $(npx --version 2>/dev/null || echo '(version unknown)')"
else
  echo "  ✗ npx not found — usually included with Node.js"
  OK=false
fi

# jq (used by the auto-lint hook)
if command -v jq &>/dev/null; then
  echo "  ✓ jq $(jq --version 2>/dev/null || echo '(version unknown)')"
else
  echo "  ✗ jq not found — the auto-lint hook needs it"
  echo "    Install: brew install jq  (macOS) or apt install jq  (Linux)"
  OK=false
fi

if [[ "$OK" != true ]]; then
  echo ""
  echo "Some dependencies are missing. Fix the items marked ✗ above."
  exit 1
fi

# Pre-warm the npx cache so the hook's first run is fast
echo ""
echo "Pre-warming skill-tools cache..."
if npx --yes "skill-tools@${SKILL_TOOLS_VERSION}" --version &>/dev/null 2>&1; then
  echo "  ✓ skill-tools@${SKILL_TOOLS_VERSION} cached and ready"
else
  echo "  ✗ Could not download skill-tools@${SKILL_TOOLS_VERSION}"
  echo "    Check your network connection and try again"
  exit 1
fi

echo ""
echo "All good. The plugin is ready to use."

---
description: Lint a SKILL.md file for quality issues — description clarity, examples, error handling, heading structure
argument-hint: <path-to-SKILL.md>
allowed-tools:
  - Bash
  - Glob
---

# Lint Skill Files

Check an Agent Skill file (SKILL.md) for quality issues beyond basic spec compliance.

## Arguments

The user provided: $ARGUMENTS

## Instructions

1. **Resolve the target.** If the user gave a path, use it directly. If no path was provided, use Glob with the pattern `**/SKILL.md` to find all skill files in the project. Exclude any inside `node_modules`.

2. **Run lint.** For each resolved file:

```bash
npx --yes skill-tools@0.2.2 lint "<resolved-path>"
```

3. **Interpret the results.** The output shows a pass/fail checklist of these rules:

| Rule | What it checks |
|:-----|:---------------|
| Description specificity | No vague verbs like "manage" or "handle" |
| Description length | Optimal length between 50–300 chars for metadata tier budget |
| Trigger keywords | Has "Use when..." or action verbs so agents know when to invoke |
| Progressive disclosure | Large files split reference material into subdirectories |
| No hardcoded paths | Uses relative paths or env vars, not absolute paths |
| No secrets | No API keys, tokens, or passwords embedded |
| Examples | At least one code block or numbered steps |
| Error handling | Guidance on failures, retries, or troubleshooting |
| Heading hierarchy | No skipped heading levels (e.g., H1 followed by H3) |

4. **Give actionable advice.** For each failing rule, explain *why* it matters (not just that it failed) and suggest a concrete fix the user can make right now. Prioritize warnings over info items.

## If lint fails to run

If the file can't be parsed at all, suggest running `/skill-tools:check` which includes validation and will identify structural problems. If `npx` isn't available, tell the user they need Node.js 18+ installed.

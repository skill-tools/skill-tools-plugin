---
description: Run validate + lint + score on a SKILL.md file — full quality report in one pass
argument-hint: <path-to-SKILL.md>
allowed-tools:
  - Bash
  - Glob
---

# Full Skill Check

Run all three quality tools — validate, lint, and score — against an Agent Skill file in a single pass.

## Arguments

The user provided: $ARGUMENTS

## Instructions

1. **Resolve the target.** If the user gave a path, use it directly. If no path was provided, use Glob with the pattern `**/SKILL.md` to find all skill files in the project. Exclude any inside `node_modules`.

2. **Run check.** For each resolved file:

```bash
npx --yes skill-tools@0.2.2 check "<resolved-path>"
```

3. **Present a layered summary.** The output covers three sections:

**Validation** (20 spec checks) — Does the file have valid frontmatter, required fields (name, description), correct encoding, no binary content, name-matches-directory, compatibility and license field types? If validation fails, lint and score results may be incomplete — those issues must be fixed first.

**Lint** (9 quality rules) — Description specificity, description length, trigger keywords, progressive disclosure, no hardcoded paths, no secrets, examples, error handling, heading hierarchy. For any failures, explain why the rule matters and what to change.

**Score** (0–100 across 5 dimensions) — Description Quality (30pts), Instruction Clarity (25pts), Spec Compliance (20pts), Progressive Disclosure (15pts), Security (10pts).

4. **Give a verdict.** Based on the results:

| Condition | Verdict |
|:----------|:--------|
| Validation passes, no lint warnings, score 75+ | Ready to ship |
| Validation passes, minor lint issues, score 60–74 | Almost there — list top fixes |
| Validation errors or multiple lint warnings, score below 60 | Needs work — prioritize fixes |

5. **Suggest next steps.** Name the 2–3 changes that would improve quality the most, in priority order. Be specific — "add a code block showing the primary command" is better than "add examples".

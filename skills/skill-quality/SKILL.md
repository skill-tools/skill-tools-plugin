---
name: skill-quality
description: >-
  Guide for writing high-quality SKILL.md files. Use when creating, improving,
  or debugging Agent Skills — covers descriptions, instructions, and common
  pitfalls.
---

# Writing Good Skills

This guide helps you write SKILL.md files that agents actually pick up and use well. It focuses on *why* things matter, not just what the spec says.

## The Two Jobs of a Skill File

A SKILL.md does two things:

1. **Gets selected** — The agent reads the `description` to decide whether this skill matches what the user asked for. If the description is vague, the agent skips it.
2. **Guides execution** — Once selected, the agent follows the markdown body as instructions. If the instructions are ambiguous, the agent guesses (badly).

Every quality issue traces back to one of these two jobs failing.

## Frontmatter That Works

```yaml
---
name: deploy-vercel
description: >-
  Deploy web applications to Vercel. Use when the user wants to publish,
  ship, or deploy a site. Runs vercel CLI, configures project settings,
  and reports the live URL.
---
```

### Name

Kebab-case, 1–64 characters. Think of it as a function name — short, specific, no ambiguity.

### Description — The Most Important Field

The description is how agents decide whether to load your skill. Write it as if you're answering: "When should an agent reach for this?"

**Think about it this way:** An agent sees dozens of skills. It scans descriptions looking for a match. Your description needs to win that split-second decision.

What works:

- Start with what the skill *does* (a specific verb, not "manages" or "handles")
- Add "Use when..." to spell out the trigger conditions
- Include the vocabulary your users would actually type ("publish", "ship", "deploy" — not just "deploy")

What doesn't work:

- "Manages deployment workflows" — vague, no trigger, agents can't distinguish this from ten other skills
- "Helps with Vercel" — what kind of help? Agents need to know the *action*

## Instructions That Guide Well

### Show, Don't Just Tell

Agents learn from examples much better than from abstract rules. Every skill should include at least one concrete example — a code block, a numbered walkthrough, or a before/after comparison.

```bash
vercel --prod --yes
```

The agent now knows the exact command shape, flags, and style — that's much more useful than a paragraph explaining what `vercel` does.

### Cover What Goes Wrong

If you don't tell the agent how to handle failures, it will either retry forever or give up silently. Include a section on common failure modes:

- What errors the user might see
- Which ones are retryable vs. need user intervention
- What to check first (credentials? network? config?)

### Heading Hierarchy

Headings must not skip levels. This isn't just pedantry — parsers use heading hierarchy to understand document structure, and skipped levels break that.

Valid: `H1 → H2 → H3` or `H1 → H2 → H3 → H2 → H3` (going back up is fine).

Invalid: `H1 → H3` skips H2. The fix is to either demote the H3 to H2 or add the missing H2 between them.

## Keeping Skills Focused

If your SKILL.md is getting long (over ~2,000 words), the agent has to process a lot of context to find what it needs. Split reference material into a `references/` subdirectory and keep the main file focused on the core workflow:

```
my-skill/
├── SKILL.md           # Core instructions (~1,000 words)
└── references/
    ├── api-details.md # Detailed API reference
    └── examples.md    # Extended examples
```

The main SKILL.md can tell the agent to read a references file for the full parameter list — this keeps the primary instructions scannable.

## Security Basics

Two rules that lint enforces and that matter:

- **No absolute paths.** Use relative paths or environment variables. Hardcoded paths like a home directory break for everyone else.
- **No secrets.** API keys, tokens, passwords — none of these belong in a skill file. Use environment variables or tell the agent to ask the user.

## Checking Your Work

Run the quality tools to catch issues before they bite you:

```bash
# Quick spec check — does the file parse correctly?
npx --yes skill-tools@0.2.2 validate ./my-skill/SKILL.md

# Quality lint — description, examples, error handling, headings
npx --yes skill-tools@0.2.2 lint ./my-skill/SKILL.md

# Full picture — validate + lint + score in one pass
npx --yes skill-tools@0.2.2 check ./my-skill/SKILL.md
```

Or use the slash commands: `/skill-tools:lint`, `/skill-tools:check`.

## Common Fixes

**"Description uses vague verbs"** — Replace "manages" or "handles" with the actual action: deploy, test, build, create, analyze, review, format, lint.

**"No trigger keywords"** — Add "Use when..." and include synonyms of the action verb that users would naturally type.

**"No examples"** — Add a code block showing the key command or a numbered walkthrough of the workflow.

**"No error handling"** — Add a short section listing 2–3 common failure modes and what the agent should do about each.

**"Heading level skipped"** — Insert the missing heading level. If you have `# Title` followed by `### Section`, add a `## Parent Section` between them.

# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Warp, etc.) working in this repository.

## What this repo is

A **Claude Code / OpenCode skill** implemented entirely as Markdown. The runtime artifact is `SKILL.md`: the agent reads its YAML frontmatter (metadata + allowed tools) followed by the editor prompt. There is no build step and no code to run.

## Key files

- `SKILL.md` — the skill itself. YAML frontmatter (`name`, `description`, `allowed-tools`) followed by the core rules, quick checks, and scoring guidelines. **This is the source of truth.**
- `references/phrases.md` — phrases to remove (openers, jargon, adverbs, meta-commentary)
- `references/structures.md` — structural patterns to avoid (contrasts, fragmentation, false agency)
- `references/examples.md` — before/after transformations
- `README.md` — for humans: installation, usage, overview

## The maintenance contract

This skill is adapted from [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop). When updating:

- Keep `SKILL.md` in sync with upstream changes when applicable.
- Reference files (`references/*.md`) should stay consistent with the core rules in `SKILL.md`.
- Preserve valid YAML frontmatter (formatting and indentation).
- The prompt below the frontmatter is the product. Edit it like a careful instruction document, not code.

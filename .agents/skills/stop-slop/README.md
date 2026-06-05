# Stop Slop

A skill for Claude Code and OpenCode that removes AI tells from prose.

Detects and eliminates predictable AI writing patterns: throat-clearing openers, business jargon, binary contrasts, passive voice, false agency, and more.

## Installation

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/hardikpandya/stop-slop.git ~/.claude/skills/stop-slop
```

Or copy from this repo:

```bash
cp -r .agents/skills/stop-slop ~/.claude/skills/
```

## Usage

```bash
/stop-slop

[paste your AI text here]
```

Or ask the model to apply the skill directly:

```
Please apply stop-slop to this text: [your text]
```

## What it catches

| Category | Examples |
|----------|----------|
| **Banned phrases** | Throat-clearing openers, emphasis crutches, business jargon, all adverbs, vague declaratives, meta-commentary |
| **Structural clichés** | Binary contrasts, negative listings, dramatic fragmentation, rhetorical setups, false agency, narrator-from-a-distance voice, passive voice |
| **Sentence-level rules** | No Wh- sentence starters, no em dashes, no staccato fragmentation, no lazy extremes, active voice required |

## Scoring

Rate 1-10 on each dimension:

| Dimension | Question |
|-----------|----------|
| Directness | Statements or announcements? |
| Rhythm | Varied or metronomic? |
| Trust | Respects reader intelligence? |
| Authenticity | Sounds human? |
| Density | Anything cuttable? |

Below 35/50: revise.

## Directory Structure

```
stop-slop/
├── SKILL.md                # Core instructions
├── AGENTS.md               # Agent maintenance guide
├── README.md               # This file
├── LICENSE                 # MIT license
└── references/
    ├── phrases.md          # Phrases to remove
    ├── structures.md       # Structural patterns to avoid
    └── examples.md         # Before/after transformations
```

## Attribution

Based on [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) by Hardik Pandya. MIT license.

## License

MIT

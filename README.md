# de-complect Agent Skill

An Agent Skill that helps AI coding agents **remove braided complexity** from design documents and
implementation branches — the way Rich Hickey's *Simple Made Easy* means simple: one fold,
un-braided, not "familiar" or "fewer files."

## Overview

This repository provides an Agent Skill for Claude Code and other compatible AI agents. It teaches
the agent to find where independent concerns are twisted together — defensive checks, sentinels,
tri-state configs, scattered validation, speculative abstraction, stored-but-derivable state — and
cut those braids so each concern hangs straight down.

It runs on two kinds of target:

- **A design document** (plan, ADR, spec, handoff doc) — the deliverable is a disentangled rewrite
  to a sibling `<basename>.simplified.md`, led by a simplification memo.
- **An implementation branch** — after a feature lands, before merge — the deliverable is a series
  of small, behavior-preserving cuts, each with a named surviving enforcer for every invariant it
  removes.

This is a **quality** pass, not a bug hunt. It preserves the document's intent and scope, and
preserves code behavior; genuine correctness bugs are surfaced separately, never fixed here.

## Installation

### One-line install (curl | bash)

```bash
curl -fsSL https://raw.githubusercontent.com/danverbraganza/de-complect/main/install.sh | bash
```

This downloads the skill into `~/.claude/skills/de-complect/`. Override the destination with
`CLAUDE_SKILLS_DIR`.

### With [just](https://just.systems)

```bash
just install
```

### Manually

Copy the `de-complect/` directory into your skills directory — either global:

```bash
cp -r de-complect/ ~/.claude/skills/de-complect/
```

or into a single project:

```bash
cp -r de-complect/ /path/to/your/project/.claude/skills/de-complect/
```

## Usage

Once installed, the skill activates when you ask an agent to "simplify", "de-complect", "untangle",
"remove cruft", "make erroneous states unrepresentable", or "clean up" a design doc or a branch —
or when a diff is thick with defensive checks, sentinels, and stored-but-derivable state.

## Skill Contents

```
de-complect/
└── SKILL.md    # The de-complect pass: radar, razors, process, and self-check gates
```

## Key ideas

1. **Simple ≠ easy** — simple is one fold (objective); easy is near-at-hand (relative). Every
   "simpler" claim is interrogated: does it reduce interleaving, or only familiarity and keystrokes?
2. **Judge the artifact, not the construct** — evaluate each braid by its cost to reasoning, change,
   and debugging, not by whether it looks like a familiar shape.
3. **No named survivor → not redundant → restore it** — every removed guard must name what now
   enforces its invariant.
4. **Relocation is not removal** — a check moved into a helper still called everywhere is the same
   braid in a tidier costume.
5. **Clean is a valid result** — report "clean" rather than inventing a finding to justify the pass.

## Contributing

Contributions are welcome. Keep the skill a **quality** pass — disentangling, behavior-preserving —
and route correctness findings to a dedicated bug-hunting review.

## License

MIT

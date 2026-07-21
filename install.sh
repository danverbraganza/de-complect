#!/usr/bin/env bash
# de-complect — one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/danverbraganza/de-complect/main/install.sh | bash
#
# Downloads the de-complect Agent Skill into your Claude skills directory.
# Override the destination with CLAUDE_SKILLS_DIR, or the source with DE_COMPLECT_RAW.
set -euo pipefail

RAW="${DE_COMPLECT_RAW:-https://raw.githubusercontent.com/danverbraganza/de-complect/main}"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}/de-complect"

mkdir -p "$DEST"
curl -fsSL "$RAW/de-complect/SKILL.md" -o "$DEST/SKILL.md"

echo "Installed de-complect skill to $DEST"

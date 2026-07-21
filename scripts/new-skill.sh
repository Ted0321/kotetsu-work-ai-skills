#!/usr/bin/env bash
# Create a new skill skeleton under skills/<id>/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ID="${1:-}"
TITLE="${2:-}"

if [[ -z "$ID" ]]; then
  echo "Usage: bash scripts/new-skill.sh <skill-id> [日本語タイトル]"
  echo "Example: bash scripts/new-skill.sh deliverable-review 資料レビュー"
  exit 1
fi

if [[ ! "$ID" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "ERROR: skill-id must be kebab-case (e.g. deliverable-review)"
  exit 1
fi

DEST="$ROOT/skills/$ID"
if [[ -e "$DEST" ]]; then
  echo "ERROR: already exists: $DEST"
  exit 1
fi

TITLE="${TITLE:-$ID}"
mkdir -p "$DEST/examples"
cp "$ROOT/skills/_template/SKILL.md" "$DEST/SKILL.md"
cp "$ROOT/skills/_template/README.md" "$DEST/README.md"
cp "$ROOT/skills/_template/examples/sample_input_output.md" "$DEST/examples/"

# light personalize
DATE="$(date +%Y-%m-%d)"
# README title
sed -i "s/^# （スキル名）/# ${TITLE}/" "$DEST/README.md" 2>/dev/null || \
  sed -i '' "s/^# （スキル名）/# ${TITLE}/" "$DEST/README.md"
# SKILL name frontmatter + heading
if grep -q 'name: skill-id-here' "$DEST/SKILL.md"; then
  sed -i "s/name: skill-id-here/name: ${ID}/" "$DEST/SKILL.md" 2>/dev/null || \
    sed -i '' "s/name: skill-id-here/name: ${ID}/" "$DEST/SKILL.md"
fi
sed -i "s/^# スキル名/# ${TITLE}/" "$DEST/SKILL.md" 2>/dev/null || \
  sed -i '' "s/^# スキル名/# ${TITLE}/" "$DEST/SKILL.md"
# remove template-only internal flag (keeps the new skill publicly discoverable)
sed -i '/^metadata:$/,/^  internal: true$/d' "$DEST/SKILL.md" 2>/dev/null || \
  sed -i '' '/^metadata:$/,/^  internal: true$/d' "$DEST/SKILL.md"

# append catalog stub if not present
if ! grep -q "| ${ID} |" "$ROOT/CATALOG.md"; then
  echo "| ${DATE} | ${ID} | ${TITLE} | draft | [skills/${ID}](./skills/${ID}/) | （一言を書く） |" >> "$ROOT/CATALOG.md"
fi

echo "Created: $DEST"
echo "Next:"
echo "  1. Edit $DEST/SKILL.md"
echo "  2. Fill examples"
echo "  3. Fix CATALOG.md one-liner"
echo "  4. git add skills/${ID} CATALOG.md && git commit && git push"

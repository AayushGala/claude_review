#!/usr/bin/env bash
# Remove the review tool from ~/.claude/.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

rm -f "${CLAUDE_DIR}/commands/self-review-start.md"
rm -f "${CLAUDE_DIR}/commands/self-review-apply.md"
rm -f "${CLAUDE_DIR}/commands/self-review-finish.md"
rm -rf "${CLAUDE_DIR}/scripts/review"

echo "Uninstalled review tool from ${CLAUDE_DIR}."

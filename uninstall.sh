#!/usr/bin/env bash
# Remove the review tool from ~/.claude/.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

rm -f "${CLAUDE_DIR}/commands/start-review.md"
rm -f "${CLAUDE_DIR}/commands/address-comments.md"
rm -f "${CLAUDE_DIR}/commands/finish-review.md"
rm -rf "${CLAUDE_DIR}/scripts/review"

echo "Uninstalled review tool from ${CLAUDE_DIR}."

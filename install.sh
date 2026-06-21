#!/usr/bin/env bash
# Install the review tool into ~/.claude/ so Claude Code picks it up.
# Run from the repo root: ./install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/scripts/review"

cp "${REPO_DIR}/commands/"*.md "${CLAUDE_DIR}/commands/"
cp "${REPO_DIR}/scripts/review/"*.sh "${CLAUDE_DIR}/scripts/review/"
chmod +x "${CLAUDE_DIR}/scripts/review/"*.sh

echo "Installed:"
echo "  ${CLAUDE_DIR}/commands/{self-review-start,self-review-apply,self-review-finish}.md"
echo "  ${CLAUDE_DIR}/scripts/review/{start,fetch-comments,commit-push,finish}.sh"
echo ""
echo "Open a Claude Code session and try /self-review-start on a feature branch."

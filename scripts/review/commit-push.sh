#!/usr/bin/env bash
# Stage, commit (as "review: round N"), and push the review branch.
# Prints "no-changes" and exits 0 if nothing to commit.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != review/* ]]; then
  echo "ERROR: not on a review branch (current: $BRANCH)" >&2
  exit 1
fi

# Resolve BASE from cached session, or fall back to gh.
SESSION_DIR=$(review_session_dir)
if [[ -f "$SESSION_DIR/current.json" ]]; then
  BASE=$(jq -r .base "$SESSION_DIR/current.json")
else
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  BASE=$(gh pr list --repo "$REPO" --head "$BRANCH" --state open \
    --json baseRefName --jq '.[0].baseRefName')
fi

git add -A
if git diff --cached --quiet; then
  echo "no-changes"
  exit 0
fi

# Count commits already on the review branch since BASE, +1 for this one.
COUNT=$(git rev-list --count "origin/$BASE..HEAD" 2>/dev/null || echo 0)
ROUND=$((COUNT + 1))

git commit -m "review: round $ROUND"
git push
git rev-parse --short HEAD

#!/usr/bin/env bash
# Start a review session: create review/<branch>, push, open draft PR within the fork.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

BASE=$(git branch --show-current)
if [[ -z "$BASE" ]]; then
  echo "ERROR: not on any branch (detached HEAD?)" >&2
  exit 1
fi
if [[ "$BASE" == review/* ]]; then
  echo "ERROR: already on a review branch ($BASE). Run /finish-review first." >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
REVIEW_BRANCH="review/$BASE"

# Commit any pending work on BASE so the review starts from a clean tree.
git add -A
if ! git diff --cached --quiet; then
  git commit -m "wip: pre-review baseline"
fi

# Make sure BASE is pushed to origin (so PR has a base to point at).
if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push -u origin "$BASE"
else
  git push
fi

# Create the review branch.
if git show-ref --verify --quiet "refs/heads/$REVIEW_BRANCH"; then
  echo "ERROR: local branch $REVIEW_BRANCH already exists. Delete it or rename it first." >&2
  exit 1
fi
git checkout -b "$REVIEW_BRANCH"
git push -u origin "$REVIEW_BRANCH"

# Open draft PR inside the fork.
PR_URL=$(gh pr create \
  --repo "$REPO" \
  --base "$BASE" \
  --head "$REVIEW_BRANCH" \
  --title "Review: $BASE" \
  --body "Throwaway review PR. Comment inline on the Files tab. Run /address-comments to apply, /finish-review to squash-merge." \
  --draft)

echo "$PR_URL"

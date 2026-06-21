#!/usr/bin/env bash
# Start a review session: create review/<branch>, push, open draft PR within the repo.
# All work-in-progress (uncommitted changes + local-only commits) is moved onto
# review/<branch>. BASE on origin stays untouched — it's the "approved" baseline.
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

if git show-ref --verify --quiet "refs/heads/$REVIEW_BRANCH"; then
  echo "ERROR: local branch $REVIEW_BRANCH already exists. Delete it or rename it first." >&2
  exit 1
fi

# Make sure BASE exists on origin — the PR needs a base to point at.
git fetch origin "$BASE" 2>/dev/null || true
if ! git show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
  echo "ERROR: $BASE doesn't exist on origin. Push it first: git push -u origin $BASE" >&2
  exit 1
fi

# Detect what's "to be reviewed": uncommitted changes and/or local-only commits.
HAS_UNCOMMITTED=0
[[ -n "$(git status --porcelain)" ]] && HAS_UNCOMMITTED=1
AHEAD=$(git rev-list --count "origin/$BASE..HEAD" 2>/dev/null || echo 0)

if [[ "$HAS_UNCOMMITTED" == "0" && "$AHEAD" == "0" ]]; then
  echo "ERROR: nothing to review — working tree is clean and $BASE matches origin/$BASE." >&2
  exit 1
fi

# Snapshot HEAD; this becomes the tip of the review branch.
WORK_TIP=$(git rev-parse HEAD)

# Move uncommitted out of the way so we can switch branches cleanly.
STASHED=0
if [[ "$HAS_UNCOMMITTED" == "1" ]]; then
  git stash push -u -m "review-start" >/dev/null
  STASHED=1
fi

# Roll BASE back to origin — local-only commits live on the review branch instead.
if [[ "$AHEAD" != "0" ]]; then
  git reset --hard "origin/$BASE"
fi

# Create review branch from the saved work tip.
git checkout -b "$REVIEW_BRANCH" "$WORK_TIP"

# Pop stash on the review branch and commit the uncommitted changes.
if [[ "$STASHED" == "1" ]]; then
  git stash pop >/dev/null
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "wip: pre-review baseline"
  fi
fi

# Final sanity: there must be at least one commit ahead of origin/$BASE.
if [[ "$(git rev-list --count "origin/$BASE..HEAD")" == "0" ]]; then
  echo "ERROR: review branch ended up identical to origin/$BASE (nothing to review)" >&2
  exit 1
fi

git push -u origin "$REVIEW_BRANCH"

PR_URL=$(gh pr create \
  --repo "$REPO" \
  --base "$BASE" \
  --head "$REVIEW_BRANCH" \
  --title "Review: $BASE" \
  --body "Throwaway review PR. Comment inline on the Files tab. Run /address-comments to apply, /finish-review to squash-merge." \
  --draft)

echo "$PR_URL"

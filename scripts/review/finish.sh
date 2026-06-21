#!/usr/bin/env bash
# Squash-merge the review PR into its base branch, delete the review branch,
# switch back to base, and pull. Takes the squash subject as $1 (required).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

SUBJECT="${1:-}"
if [[ -z "$SUBJECT" ]]; then
  echo "ERROR: squash commit subject required as first argument" >&2
  exit 1
fi

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != review/* ]]; then
  echo "ERROR: not on a review branch (current: $BRANCH)" >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

PR_JSON=$(gh pr list --repo "$REPO" --head "$BRANCH" --state open \
  --json number,baseRefName --jq '.[0]')
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
  echo "ERROR: no open PR found for branch $BRANCH in $REPO" >&2
  exit 1
fi
PR=$(jq -r .number <<<"$PR_JSON")
BASE=$(jq -r .baseRefName <<<"$PR_JSON")

# Drafts must be marked ready before they can be merged.
gh pr ready "$PR" --repo "$REPO" >/dev/null 2>&1 || true

gh pr merge "$PR" --repo "$REPO" --squash --delete-branch --subject "$SUBJECT"

git checkout "$BASE"
git pull origin "$BASE"
git branch -D "$BRANCH" 2>/dev/null || true

rm -rf "$(review_session_dir)" 2>/dev/null || true

SHA=$(git rev-parse --short HEAD)
echo "merged: $BASE is now at $SHA"

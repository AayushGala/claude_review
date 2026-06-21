#!/usr/bin/env bash
# Fetch comments on the active review PR that were created after the last commit
# on the review branch. Emits one comment per line as TSV:
#   KIND<TAB>PATH<TAB>LINE<TAB>USER<TAB>BODY_FIRST_LINE<TAB>ID
# KIND is "inline" or "issue".  For "issue" comments PATH/LINE are "-".
# Full bodies are written to /tmp/review-comments-<id>.txt for the caller to read.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != review/* ]]; then
  echo "ERROR: not on a review branch (current: $BRANCH)" >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

PR_JSON=$(gh pr list --repo "$REPO" --head "$BRANCH" --state open \
  --json number,baseRefName,url --jq '.[0]')
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
  echo "ERROR: no open PR found for branch $BRANCH in $REPO" >&2
  exit 1
fi
PR=$(jq -r .number <<<"$PR_JSON")
BASE=$(jq -r .baseRefName <<<"$PR_JSON")
URL=$(jq -r .url <<<"$PR_JSON")

# Normalize last-commit time to UTC ISO 8601 (`...Z`) so lexicographic
# comparison against GitHub's `created_at` (always UTC) is correct.
LAST_TS_UNIX=$(git log -1 --format=%ct)
if date -u -r 0 >/dev/null 2>&1; then
  LAST_TS=$(date -u -r "$LAST_TS_UNIX" +"%Y-%m-%dT%H:%M:%SZ")  # BSD/macOS
else
  LAST_TS=$(date -u -d "@$LAST_TS_UNIX" +"%Y-%m-%dT%H:%M:%SZ")  # GNU/Linux
fi

# Cache PR metadata where the caller can find it.
mkdir -p /tmp/review-session
cat >/tmp/review-session/current.json <<EOF
{"repo":"$REPO","pr":$PR,"base":"$BASE","branch":"$BRANCH","url":"$URL","last_commit_ts":"$LAST_TS"}
EOF

# Wipe any leftover full-body files from previous runs.
rm -f /tmp/review-session/body-*.txt

emit() {
  local kind="$1" path="$2" line="$3" user="$4" body="$5" id="$6"
  local first
  first=$(printf '%s' "$body" | head -n1 | tr -d '\t' | cut -c1-200)
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" "$path" "$line" "$user" "$first" "$id"
  printf '%s' "$body" >"/tmp/review-session/body-$id.txt"
}

# Inline review comments.
gh api "repos/$REPO/pulls/$PR/comments" --paginate \
  --jq ".[] | select(.created_at > \"$LAST_TS\") | [.id, .path, (.line // .original_line // 0), .user.login, .body] | @json" \
| while IFS= read -r row; do
    id=$(jq -r '.[0]' <<<"$row")
    path=$(jq -r '.[1]' <<<"$row")
    line=$(jq -r '.[2]' <<<"$row")
    user=$(jq -r '.[3]' <<<"$row")
    body=$(jq -r '.[4]' <<<"$row")
    emit inline "$path" "$line" "$user" "$body" "$id"
  done

# Issue-level (PR-level) comments.
gh api "repos/$REPO/issues/$PR/comments" --paginate \
  --jq ".[] | select(.created_at > \"$LAST_TS\") | [.id, .user.login, .body] | @json" \
| while IFS= read -r row; do
    id=$(jq -r '.[0]' <<<"$row")
    user=$(jq -r '.[1]' <<<"$row")
    body=$(jq -r '.[2]' <<<"$row")
    emit issue "-" "-" "$user" "$body" "$id"
  done

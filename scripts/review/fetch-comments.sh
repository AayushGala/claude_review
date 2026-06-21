#!/usr/bin/env bash
# Fetch all unresolved review threads on the active review PR.
# Emits one thread per line as TSV:
#   inline<TAB>PATH<TAB>LINE<TAB>USER<TAB>BODY_FIRST_LINE<TAB>ID
# where ID is the databaseId of the thread's first comment. The full body
# (entire conversation in the thread, formatted as "@user: text" joined by
# "---") is written to /tmp/review-session/body-<ID>.txt so the caller can
# read it without TSV truncation.
#
# Only inline comments are supported. PR-level ("issue") comments have no
# resolution state in GitHub and would loop forever, so they're ignored.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != review/* ]]; then
  echo "ERROR: not on a review branch (current: $BRANCH)" >&2
  exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=${REPO%%/*}
NAME=${REPO##*/}

PR_JSON=$(gh pr list --repo "$REPO" --head "$BRANCH" --state open \
  --json number,baseRefName,url --jq '.[0]')
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
  echo "ERROR: no open PR found for branch $BRANCH in $REPO" >&2
  exit 1
fi
PR=$(jq -r .number <<<"$PR_JSON")
BASE=$(jq -r .baseRefName <<<"$PR_JSON")
URL=$(jq -r .url <<<"$PR_JSON")

SESSION_DIR=$(review_session_dir)
mkdir -p "$SESSION_DIR"
cat >"$SESSION_DIR/current.json" <<EOF
{"repo":"$REPO","pr":$PR,"base":"$BASE","branch":"$BRANCH","url":"$URL"}
EOF
rm -f "$SESSION_DIR"/body-*.txt 2>/dev/null || true

gh api graphql \
  -f query='
    query($owner:String!, $name:String!, $pr:Int!) {
      repository(owner:$owner, name:$name) {
        pullRequest(number:$pr) {
          reviewThreads(first:100) {
            nodes {
              isResolved
              comments(first:50) {
                nodes {
                  databaseId
                  path
                  line
                  originalLine
                  body
                  author { login }
                }
              }
            }
          }
        }
      }
    }' \
  -f owner="$OWNER" -f name="$NAME" -F pr="$PR" \
| jq -c '
    .data.repository.pullRequest.reviewThreads.nodes
    | map(select(.isResolved == false and (.comments.nodes | length) > 0))
    | .[]
    | {
        id:   .comments.nodes[0].databaseId,
        path: .comments.nodes[0].path,
        line: (.comments.nodes[0].line // .comments.nodes[0].originalLine // 0),
        user: .comments.nodes[0].author.login,
        body: (.comments.nodes | map("@\(.author.login): \(.body)") | join("\n---\n"))
      }' \
| while IFS= read -r row; do
    id=$(jq -r .id <<<"$row")
    path=$(jq -r .path <<<"$row")
    line=$(jq -r .line <<<"$row")
    user=$(jq -r .user <<<"$row")
    body=$(jq -r .body <<<"$row")
    first=$(printf '%s' "$body" | head -n1 | tr -d '\t' | cut -c1-200)
    printf 'inline\t%s\t%s\t%s\t%s\t%s\n' "$path" "$line" "$user" "$first" "$id"
    printf '%s' "$body" >"$SESSION_DIR/body-$id.txt"
  done

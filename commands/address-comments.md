---
description: Fetch new review PR comments and apply the requested changes
---

Apply the new review comments on the active review PR.

1. Run `~/.claude/scripts/review/fetch-comments.sh` via Bash. If it exits non-zero, print stderr and stop.

2. The stdout is one comment per line, TSV: `KIND<TAB>PATH<TAB>LINE<TAB>USER<TAB>BODY_FIRST_LINE<TAB>ID`. If there are zero lines, print "No new comments to address." and stop.

3. Print the comment list to the user as a short table (one row per comment: `path:line — first line of body`) so they see what you're about to act on.

4. For each comment, read the **full body** from `/tmp/review-session/body-<ID>.txt` (the script wrote it there to avoid TSV truncation). Then:
   - For `inline` comments: read the file at `PATH` around `LINE` and apply the change the reviewer is asking for.
   - For `issue` comments: treat the body as general guidance — figure out where it applies and act on it.
   - Treat each comment as a direct instruction from the human reviewer. Do exactly what they're asking; no scope creep.
   - If a comment is genuinely ambiguous, ask the user before editing rather than guessing.

5. Once all edits are done, run `~/.claude/scripts/review/commit-push.sh` via Bash. Its stdout is either `no-changes` (informational comments only) or the short SHA of the new commit.

6. Print a one-line summary: `Addressed N comments → <sha>. Open <pr url> → Files changed → "View changes since your last review" to see only this round.` (Get the PR url from `/tmp/review-session/current.json`.)

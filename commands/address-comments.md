---
description: Fetch new review PR comments and apply the requested changes
---

Apply unresolved inline comments on the active review PR.

1. Run `~/.claude/scripts/review/fetch-comments.sh` via Bash. If it exits non-zero, print stderr and stop.

2. The stdout is one unresolved thread per line, TSV: `inline<TAB>PATH<TAB>LINE<TAB>USER<TAB>BODY_FIRST_LINE<TAB>ID`. If there are zero lines, print "No unresolved comments to address." and stop.

3. Print the list to the user as a short table (one row per thread: `path:line — first line of body`) so they see what you're about to act on.

4. For each thread, read the **full conversation** from `/tmp/review-session/body-<ID>.txt` — it contains every comment in the thread formatted as `@user: text` joined by `---`. Read the whole thread (not just the first message) before acting: later replies may supersede the original request. Then:
   - Read the file at `PATH` around `LINE`.
   - If the requested change is already applied (e.g. you addressed it in a prior round but the reviewer didn't resolve the thread), make no edits — `commit-push.sh` will report `no-changes` for that thread.
   - Otherwise apply exactly what the reviewer is asking for. No scope creep.
   - If the conversation is genuinely ambiguous, ask the user before editing rather than guessing.

5. Once all edits are done, run `~/.claude/scripts/review/commit-push.sh` via Bash. Its stdout is either `no-changes` or the short SHA of the new commit.

6. Print a one-line summary: `Addressed N threads → <sha>. Open <pr url> → Files changed → "View changes since your last review" to see only this round. Resolve threads on GitHub once you're satisfied so they don't reappear next round.` (Get the PR url from `/tmp/review-session/current.json`.)

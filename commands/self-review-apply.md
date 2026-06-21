---
description: Fetch new review PR comments and apply the requested changes
---

Apply unresolved inline comments on the active review PR.

1. Run `~/.claude/scripts/review/fetch-comments.sh` via Bash. If it exits non-zero, print stderr and stop.

2. The stdout is one unresolved thread per line, TSV: `inline<TAB>PATH<TAB>LINE<TAB>USER<TAB>BODY_FIRST_LINE<TAB>ID`. If there are zero lines, print "No unresolved comments to address." and stop.

3. Print the list to the user as a short table (one row per thread: `path:line — first line of body`) so they see what you're about to act on.

4. For each thread, read the **full conversation** from `$(git rev-parse --git-dir)/review-session/body-<ID>.txt` — it contains every comment in the thread formatted as `@user: text` joined by `---`. Read the whole thread (not just the first message) before acting: later replies may supersede the original request. Then read the file at `PATH` around `LINE` and use judgment — don't blindly apply every comment:

   - **The comment is a question** (e.g. "why does this work?", "where does X live?") → answer in chat. Don't edit.
   - **You disagree with the suggestion, or the current code is already valid** → say so in chat with your reasoning. Don't edit. The reviewer can then resolve the thread or push back.
   - **The requested change is already applied** (e.g. you addressed it in a prior round but the reviewer didn't resolve the thread) → make no edits. Mention it briefly so the user knows to resolve the thread.
   - **Genuinely ambiguous** → ask the user before editing rather than guessing.
   - **Clear, actionable, and you agree with it** → apply exactly what the reviewer asked for. No scope creep.

5. Once all edits are done, run `~/.claude/scripts/review/commit-push.sh` via Bash. Its stdout is either `no-changes` or the short SHA of the new commit.

6. Print a one-line summary: `Addressed N threads → <sha>. Open <pr url> → Files changed → "View changes since your last review" to see only this round. Resolve threads on GitHub once you're satisfied so they don't reappear next round.` (Get the PR url from `$(git rev-parse --git-dir)/review-session/current.json`.)

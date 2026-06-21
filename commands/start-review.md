---
description: Start a review session — create a review branch and a draft PR within the fork
---

Run `~/.claude/scripts/review/start.sh` via Bash.

If the script exits non-zero, print the stderr verbatim and stop — do not try to fix git state. If it succeeds, the last line of stdout is the PR URL; print it on its own line so it's clickable.

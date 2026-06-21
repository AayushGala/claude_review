---
description: Squash-merge the review PR into the clean branch and clean up
---

Finalize the review session.

1. Look at the current branch name (must start with `review/`). Derive a suggested squash commit subject from the part after `review/` (e.g. `review/feature-add-foo` → `Add foo`).

2. Ask the user: "Squash commit subject? (default: `<suggestion>`)" — accept their input or fall back to the suggestion.

3. Run `~/.claude/scripts/review/finish.sh "<chosen subject>"` via Bash. If it exits non-zero, print stderr and stop.

4. Print the script's last line of stdout (the merged-SHA summary) and remind the user they can now `gh pr create` against upstream the normal way.

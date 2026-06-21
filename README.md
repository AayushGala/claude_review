# claude_review

A lightweight code-review loop for Claude Code that uses GitHub's native PR UI as the review surface — so you can comment on Claude's changes inline (like any normal PR) and have Claude apply the comments in the next round.

No custom UI to build, no diff engine to maintain. GitHub already solved comment anchoring, threading, resolution, and the "View changes since your last review" diff. This tool just wires Claude Code into that flow.

## How it works

1. You're on a feature branch with some changes (yours or Claude's, committed or not).
2. `/start-review` — creates a throwaway `review/<branch>` branch, pushes it, opens a **draft PR inside your repo** (`review/<branch>` → `<branch>`).
3. You open the PR in GitHub and leave inline comments on the Files tab — anything you'd want changed.
4. `/address-comments` — fetches comments created since the last commit on the review branch, Claude applies each one, then commits as `review: round N` and pushes. Refresh the PR and use **"View changes since your last review"** to see only this round's diff.
5. Repeat step 3-4 as many rounds as you want.
6. `/finish-review` — squash-merges the review PR into `<branch>` with one clean commit and deletes the throwaway branch.

Your normal flow (fork → upstream, or branch → main) is unchanged. The review PR is just an internal staging step that lives entirely inside whichever repo you're in.

## Install

```bash
git clone <this repo>
cd claude_review
./install.sh
```

Copies the three slash commands into `~/.claude/commands/` and the four shell scripts into `~/.claude/scripts/review/`. Slash commands are inert until you type them — no hooks, no background behavior.

## Requirements

- `gh` (GitHub CLI), authenticated (`gh auth status` should be green)
- `git`
- `jq`

## What's in this repo

```
commands/             # slash commands (instructions Claude reads)
  start-review.md
  address-comments.md
  finish-review.md
scripts/review/       # deterministic shell — git/gh plumbing
  start.sh
  fetch-comments.sh
  commit-push.sh
  finish.sh
install.sh            # copies the above into ~/.claude/
```

The slash commands do the minimum — call a script, then for `/address-comments` only, let Claude interpret each comment and edit the relevant files. Everything mechanical (branch detection, PR lookup, comment fetching, commit messaging, push, squash-merge) lives in the shell scripts where it can't drift.

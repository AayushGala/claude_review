#!/usr/bin/env bash
# Shared helpers for the review scripts.
#
# Defines a `gh` shell function that routes through `op plugin run -- gh`
# when the 1Password CLI is installed (so users with gh creds stored in
# 1Password don't need to set GH_TOKEN), and falls through to the real
# gh binary otherwise. Source this file from every review script.

gh() {
  if command -v op >/dev/null 2>&1; then
    op plugin run -- gh "$@"
  else
    command gh "$@"
  fi
}

# Per-checkout session directory. Lives inside .git/ so multiple concurrent
# review sessions (different repos, or different worktrees of the same repo)
# don't collide on shared state.
review_session_dir() {
  local git_dir
  git_dir=$(git rev-parse --git-dir)
  # rev-parse may return a relative path (".git") — resolve to absolute.
  case "$git_dir" in
    /*) ;;
    *) git_dir="$(pwd)/$git_dir" ;;
  esac
  echo "$git_dir/review-session"
}

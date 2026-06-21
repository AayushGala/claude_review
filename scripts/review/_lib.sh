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

#!/usr/bin/env bash
# Prints a key that is the same in every worktree of one repo.
# The origin URL comes first because two repos with the same folder name can live in different organizations.
set -euo pipefail

repo_path="${1:-.}"

if origin_url=$(git -C "$repo_path" remote get-url origin 2>/dev/null); then
  owner_and_repo=$(printf '%s' "$origin_url" \
    | sed -E 's#\.git$##; s#^[a-z+]+://([^/@]+@)?[^/]+/##; s#^[^@]+@[^:]+:##; s#^v3/##; s#/_git/#/#')
  printf '%s\n' "$owner_and_repo" | tr '/' '-' | tr '[:upper:]' '[:lower:]'
  exit 0
fi

common_git_dir=$(git -C "$repo_path" rev-parse --path-format=absolute --git-common-dir)
basename "$(dirname "$common_git_dir")" | tr '[:upper:]' '[:lower:]'

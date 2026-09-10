# claude-skills

Personal Claude Code skills — reusable slash commands for my day-to-day workflow.

## Skills

### Review

| Skill | Command | Description |
|-------|---------|-------------|
| session-review | `/session-review` | Compile a PR-style review of every repo touched this session, verify each finding, and produce a fix plan |
| session-review-loop | `/session-review-loop` | Run session-review, fix confirmed blocking issues, re-review, and repeat until clean (round-capped), then prune comments |
| review-pr-comments | `/review-pr-comments` | Triage PR review comments in plan mode: investigate each one, reject invalid ones with a reason, plan fixes for the rest |
| review-pr-comments-loop | `/review-pr-comments-loop` | Triage PR comments and implement the valid fixes directly, then hand off to session-review-loop to catch regressions |

### Explanation

| Skill | Command | Description |
|-------|---------|-------------|
| explain | `/explain [<topic>]` | Recap the conversation in plain language, stepping through the relevant code with concrete examples |
| explain-diff | `/explain-diff [<ref>]` | Generate a self-contained HTML walkthrough of a git diff — background, intuition, code tour, and an interactive quiz |

### Housekeeping

| Skill | Command | Description |
|-------|---------|-------------|
| prune-comments | `/prune-comments [--strict\|--all] [<paths>]` | Delete comments that narrate *what* the code does, keeping only those explaining a non-obvious *why*. Works on the working diff by default |
| remove-comments | `/remove-comments [<paths>]` | prune-comments in strict mode: delete every comment on a line this branch added, except tool directives, license headers, and XML doc comments |
| resume-plan | `/resume-plan` | List and load previously saved plans from `~/.claude/plans/`, filtered to the current repo |
| find-session | `/find-session <pattern>` | Search past session logs for a keyword and print a `claude --resume` command for the session you pick |

### Sound notifications

| Skill | Command | Description |
|-------|---------|-------------|
| peon-ping-toggle | `/peon-ping-toggle` | Turn peon-ping sounds on or off, and apply any peon-ping config change |
| peon-ping-config | — | Model-invoked helper that edits the peon-ping config: volume, active pack, pack rotation, and sound categories |

The `-loop` variants edit code directly — invoking one is the authorization to do so.

`/prune-comments --all` covers every source file in the repo, not only the diff. `--strict --all` is refused.

## Installation

Copy (or symlink) the skill directories you want into your `~/.claude/skills/` directory. Claude Code picks them up automatically.

`find-session` also needs the `claude-find` script on your PATH (it lives in the dotfiles repo at `~/.local/bin/claude-find`), plus `rg` and `jq`.

The peon-ping skills need the peon-ping tool and its config at `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping/config.json`.

## License

MIT — see [LICENSE](LICENSE).

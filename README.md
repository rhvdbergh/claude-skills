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
| prune-comments | `/prune-comments [<paths>]` | Delete comments that narrate *what* the code does, keeping only those explaining a non-obvious *why* |
| resume-plan | `/resume-plan` | List and load previously saved plans from `~/.claude/plans/`, filtered to the current repo |

The `-loop` variants edit code directly — invoking one is the authorization to do so.

## Installation

Copy (or symlink) the skill directories you want into your `~/.claude/skills/` directory. Claude Code picks them up automatically.

## License

MIT — see [LICENSE](LICENSE).

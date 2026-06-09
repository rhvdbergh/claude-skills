# claude-skills

Personal Claude Code skills — reusable slash commands for my day-to-day workflow.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| resume-plan | `/resume-plan` | List and load previously saved plans from `~/.claude/plans/` |
| review-pr-comments | `/review-pr-comments` | Triage PR review comments: investigate each one, mark invalid with a rebuttal, plan fixes for valid ones |
| session-review | `/session-review` | Run a pre-merge code review across all repos touched in the current session |

## Installation

Copy (or symlink) the skill directories you want into your `~/.claude/skills/` directory. Claude Code picks them up automatically.

## License

MIT — see [LICENSE](LICENSE).

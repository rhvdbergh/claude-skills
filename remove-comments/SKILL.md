---
name: remove-comments
description: Delete every comment on a line this branch added, except tool directives, license headers, and XML doc comments. The aggressive form of prune-comments.
user_invocable: true
disable-model-invocation: true
---

Run `~/.claude/skills/prune-comments/SKILL.md` in strict mode.

Read that file now and follow it, with `--strict` on. Pass through any paths the user gave.
`--all` is refused in strict mode.

---
name: resume-plan
description: List saved plans in ~/.claude/plans and load one to resume working on it. Use when the user wants to pick up a previous plan, continue past work, or see what plans they have. Filters to the current repo by default.
user_invocable: true
---

# resume-plan

Load a previously saved plan from `~/.claude/plans/` and resume or revise it.

## Steps

### 1. Determine repo context

Run:
```bash
basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "no-repo"
```

Store the result as `<repo>`.

### 2. List plans

Run:
```bash
ls -t ~/.claude/plans/*.md 2>/dev/null
```

This returns files sorted newest-first.

### 3. Filter

- **Default:** keep only files whose basename starts with `<repo>_`.
- **If an arg was passed** (e.g. `/resume-plan consent`): instead filter to files whose basename contains the arg substring (case-insensitive). Skip the repo filter in this case.
- **If zero matches** after filtering: inform the user ("No plans found matching `<filter>` in repo `<repo>`."), then offer to show all plans or try a different filter. Stop here.
- **"show all" escape hatch:** if the user passes `all` as the arg, skip all filters and list everything.

### 4. Present options

Take the first 4 matches. Use `AskUserQuestion` to let the user pick one. Label each option with just the filename (no directory prefix). If there are more than 4 matches, mention the count in the question text and suggest narrowing with a filter arg.

### 5. Read and summarize

Read the chosen plan file. Provide a 2–4 sentence summary: what repo/task it covers, the main approach, and roughly how far along it seemed.

### 6. Ask what to do next

Ask the user (plain text, not AskUserQuestion):
- **(a) Resume** — proceed with executing the plan as written.
- **(b) Revise** — enter plan mode so the plan can be updated before execution.

Act on their response.

#### If the user chooses Revise

1. Check whether a session plan file path is available (the harness provides it in the plan-mode system reminder, e.g. `~/.claude/plans/can-you-see-the-mutable-deer.md`).
2. If a session plan file path is present, **copy the loaded plan's full contents into that file** using the Write tool before entering plan mode. This ensures `/plan` shows the plan content and any inline edits are tracked by the harness.
3. Enter plan mode.
4. Remind the user: when exiting plan mode, rename the session file to the canonical format `<repo>_<YYYY-MM-DD>_<descriptive-slug>.md` inside `~/.claude/plans/` (overwriting the original if the slug matches). The `<repo>` is the value from step 1; use today's date.

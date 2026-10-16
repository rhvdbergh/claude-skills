---
name: prep-compact
description: Prepare for /compact so no important session detail is lost. Writes a full retention brief into the conversation and to a file, then puts a ready-to-paste `/compact …` command on the clipboard. Use when the user types /prep-compact, or asks to get ready for compaction, save the session context before compacting, or write compact instructions.
user_invocable: true
---

# prep-compact

`/compact` is a built-in CLI command. A skill or tool call cannot run it; only the user can. This skill does everything up to that point, so the user only pastes and presses Enter.

The brief goes in two places on purpose:

- **In the reply.** The compactor summarizes the conversation, so text in the last reply is the text it is told to keep.
- **In a file.** The summary can still lose detail. The file is the full copy that Claude re-reads after compaction.

## Steps

### 1. Collect the facts

Check the current state with read-only tools before writing anything. Never fill the brief from memory where a command can confirm it.

- `pwd`, `git rev-parse --show-toplevel`, `git rev-parse --abbrev-ref HEAD`, `git status --short` (skip when not in a git repo).
- `git worktree list` when the session used worktrees.
- Background processes and agents this session started that still run.

### 2. Write the retention brief

Write the brief in the reply, under the heading `## Retention brief`. Include every section that applies; leave out empty ones. Be specific: exact paths, ids, names, numbers, error text. Leave out narration of how the session went.

1. **Goal** — what the user wants, in one to three sentences. Quote the user's own words where the wording matters.
2. **Location** — repo, worktree path, branch, and the directory to work in.
3. **Plan** — the plan file path, which steps are done, which step is in progress, and every `%%` note still open.
4. **Decisions** — each decision made, with the reason, and options the user rejected (so they do not come back).
5. **User rules for this task** — corrections and preferences the user gave in this session that are not in any CLAUDE.md.
6. **Changes so far** — files created, edited, or deleted, one line each with what changed.
7. **Verification state** — the last build and test results, with pass and fail counts and the exact error text of any failure.
8. **Open threads** — unanswered questions, things blocked on the user (for example codegen to run), and running processes, agents, or review ids (wisplet `rv_…`) with what each one waits for.
9. **Key references** — ticket links, PR numbers, URLs, function and type names that the next step needs.
10. **Next step** — the exact next action.

### 3. Save the brief to a file

Save the same brief to `~/.claude/compact-briefs/<repo>_<YYYY-MM-DD>_<slug>.md`:

- `<repo>` is the basename of `git rev-parse --show-toplevel`, or `no-repo` outside a git repo.
- `<slug>` is a short kebab-case name for the task.
- If the file exists, overwrite it only when it is from this same session; otherwise add `-2`, `-3`, and so on.

### 4. Build the `/compact` command

Build one line, with no line breaks, so the paste runs as a slash command:

```
/compact Keep the "Retention brief" from the last assistant message in full: every path, id, decision, rule, test result, open thread and the next step, word for word where possible. After compaction, re-read <absolute brief file path> before doing anything else.
```

Replace `<absolute brief file path>` with the real path from step 3. Expand `~` to the full home path.

### 5. Copy it to the clipboard

Run `printf '%s' '<the command>' | pbcopy` (macOS). If `pbcopy` is not available or fails, say so.

### 6. Report

End the reply with:

- The brief file path.
- The `/compact …` line in a code block, so the user can copy it by hand if the clipboard step failed.
- One line: "Copied to clipboard. Paste and press Enter to compact." (Only if step 5 succeeded.)

Do not make code changes, commits, or ticket updates in this skill.

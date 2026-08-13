---
name: review-pr-comments-loop
description: Triage PR review comments, implement fixes for valid ones directly, then hand off to session-review-loop to catch regressions from those fixes before declaring done.
user_invocable: true
disable-model-invocation: true
---

## Purpose

Combine PR-comment triage with a closing self-review: investigate each reviewer comment, implement fixes for the valid ones directly (no plan-mode gate — invoking this skill is the authorization), compile the rejection list for the reviewer, then run `session-review-loop` on the resulting diff so any bug the fixes themselves introduce gets caught and closed out before you're done.

## Input

Same as review-pr-comments: comments passed as arguments after the slash command, or the most recent numbered/bulleted block of text in the conversation. Preserve the original numbering or bullet labels throughout.

## Status line

The status line shows this skill's progress while it runs. Write the state file after every step below:

```bash
mkdir -p ~/.claude/skill-status
jq -n --arg skill "review-pr-comments-loop" --arg detail "<detail>" --argjson ts "$(date +%s)" \
  '{skill:$skill, detail:$detail, updated_at:$ts}' \
  > ~/.claude/skill-status/"$CLAUDE_CODE_SESSION_ID".json
```

Step 5 hands off to `session-review-loop`, which overwrites this same file with its own progress — don't clear it before that handoff. If this skill stops before reaching step 5 (nothing to fix, or aborted), clear it yourself: `rm -f ~/.claude/skill-status/"$CLAUDE_CODE_SESSION_ID".json`.

## Steps

### 1. Parse and investigate

Write status: `detail="triaging <N> comment(s)"`.

Extract each distinct review comment, assigning/preserving its original number. For **every** comment, read the relevant files and grep for the symbols, patterns, or logic the reviewer mentions — do not rely on memory or assumptions. Verdict per comment:

- **Valid** — the issue the reviewer describes genuinely exists in the current code. Fix it.
- **Invalid** — the code already handles this correctly, the reviewer misread the code, the concern doesn't apply, or the suggested change would be incorrect/harmful. Write a one- or two-sentence rebuttal referencing the specific file:line that disproves the comment.

### 2. Fix valid comments directly

Write status: `detail="fixing <k>/<N> valid comments"`.

For each Valid comment, implement the fix in the repo now — no plan-mode gate, this skill runs to completion. Keep each fix scoped to that comment; no drive-by refactors.

### 3. Verify

Write status: `detail="verifying fixes"`.

Run typecheck/lint/build and the relevant test suite for files touched in step 2. Note anything that fails for reasons unrelated to these fixes rather than blocking on it.

### 4. Save the reviewer rejection list

Save only the Invalid comments — numbered per their original labels, each with its rebuttal — to `~/.claude/plans/pr-review-triage-<YYYY-MM-DD>.md`. This file is for copy-pasting back to the reviewer, not an execution plan. State the filename.

If every comment was Valid, note "All comments were valid — no rejections" instead of writing an empty file.

### 5. Hand off to session-review-loop

Write status: `detail="handing off to session-review-loop"` (it will immediately overwrite this with its own progress).

Invoke the `session-review-loop` skill now via the Skill tool. It independently re-reviews the full session diff — including the fixes just made in step 2 — and iterates, fixing any confirmed issue it finds, until a round comes back clean or its own round cap is hit. Do not duplicate its logic here; let it own its full flow, including clearing the status file when it finishes.

### 6. Final report

Report: comment-by-comment verdicts, the filename of the saved rejection list, and `session-review-loop`'s own summary (rounds run, fixes applied per round, remaining advisory notes).

## Constraints

- Do not invent fixes for comments you have not investigated.
- Keep rebuttals factual and collegial; cite file paths and line numbers where they strengthen the case.
- Adhere to the user's `%%` annotation convention: if `%%` markers appear in any file this skill touches, address them before finalising.

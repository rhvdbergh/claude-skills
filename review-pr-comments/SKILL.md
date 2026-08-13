---
name: review-pr-comments
description: Triage PR review comments in plan mode — investigate each one, mark invalid ones with a reason, plan fixes for valid ones, and compile a rejection list for the reviewer.
user_invocable: true
---

## Purpose

Triage a list of PR review comments. For each comment, investigate the actual codebase state to determine whether the comment is valid. Produce a plan that addresses valid comments and clearly rejects invalid ones, then summarise all rejections for the reviewer.

## Input

The PR review comments are either:
- Provided as arguments after the slash command (e.g. `/review-pr-comments <pasted text>`), or
- The most recent block of numbered/bulleted text in the conversation.

Preserve the original numbering or bullet labels throughout.

## Steps

### 1. Enter plan mode

Call `EnterPlanMode` immediately. All analysis and planning happens inside plan mode.

### 2. Parse the comments

Extract each distinct review comment from the input. Assign it a number that matches the original (1, 2, 3 … or the bullet label used by the reviewer). If the input has no explicit numbers, number them sequentially.

### 3. Investigate each comment

For **every** comment, read the relevant files and grep for the symbols, patterns, or logic the reviewer mentions. Do not rely on memory or assumptions — verify against the current codebase state.

Determine the verdict:

- **Valid** — the issue the reviewer describes genuinely exists in the current code. Plan a concrete fix.
- **Invalid** — the code already handles this correctly, the reviewer misread the code, the concern does not apply to this codebase, or the suggested change would be incorrect/harmful. Write a one- or two-sentence rebuttal that references the specific file and line (or pattern) that disproves the comment.

### 4. Structure the plan

Produce a plan document with two sections:

#### Section A — Comment-by-comment assessment

For each comment, in original order:

```
## Comment N — <one-line summary of the reviewer's point>
**Verdict:** Valid | Invalid
**Reason:** <for Invalid: rebuttal with file:line evidence>
**Fix steps:** <for Valid only: concrete, ordered steps — files to touch, functions/methods affected, the exact change to make. Write this so it can be executed directly, not summarized further.>
```

#### Section B — Rejection list (for the reviewer)

A numbered list containing only the **Invalid** comments, using their original numbers, with a one- or two-sentence plain-language rebuttal for each. This section is ready to copy-paste back to the reviewer.

```
### Comments we are not actioning

N. <rebuttal>
N. <rebuttal>
```

If every comment is valid, write "All comments are valid — no rejections." in Section B.

### 5. Save the reviewer rejection list

Save Section B alone to `~/.claude/plans/pr-review-triage-<YYYY-MM-DD>.md` and state the filename. This file is for copy-pasting back to the reviewer — it is not the execution plan.

### 6. Exit plan mode with the fix plan

Call `ExitPlanMode` with a plan built from Section A's **Valid** comments only, using their fix steps verbatim. This is the plan the user approves to go straight into execution — it must contain only actionable fix steps, no rebuttals, no invalid-comment discussion.

If every comment was Invalid, skip `ExitPlanMode` and report that no fixes are needed — do not exit plan mode with an empty plan.

## Constraints

- Do not make any code edits before the plan is approved via `ExitPlanMode` — investigation and planning only.
- Do not invent fixes for comments you have not investigated.
- Keep rebuttals factual and collegial; cite file paths and line numbers where they strengthen the case.
- Fix steps must be concrete enough to execute without re-deriving the approach — name the files, functions, and the change itself.
- Adhere to the user's `%%` annotation convention: if `%%` markers appear in the plan file, address them before finalising.

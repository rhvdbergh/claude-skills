---
name: session-review-loop
description: Iterate session-review's self-review until no blocking issues remain — fix confirmed issues, re-review the diff, repeat, then prune comments as a final pass. Advisory/nitpick findings are reported but never block the loop.
user_invocable: true
disable-model-invocation: true
---

## Purpose

Run session-review's pre-merge review, but instead of only reporting findings, close the loop: fix every confirmed blocking issue, re-review the resulting diff, and repeat until a round comes back clean or a round cap is hit. This skill edits code directly — invoking it is the authorization to do so, same as any other auto-mode work.

## Round cap

Maximum 5 rounds. If blocking issues remain after round 5, stop and hand the rest to the user rather than looping further.

## Status line

The status line shows this skill's progress while it runs. Keep a running `fixes_total` count in your own working memory across rounds (starts at 0, add each round's Confirmed-fix count to it), and write it to the state file after every step below:

```bash
mkdir -p ~/.claude/skill-status
jq -n --arg skill "session-review-loop" --arg detail "<detail>" --argjson ts "$(date +%s)" \
  '{skill:$skill, detail:$detail, updated_at:$ts}' \
  > ~/.claude/skill-status/"$CLAUDE_CODE_SESSION_ID".json
```

Clear it when the loop ends (clean, capped, or aborted):

```bash
rm -f ~/.claude/skill-status/"$CLAUDE_CODE_SESSION_ID".json
```

## Steps

### 1. Identify touched repositories and diff scope

Write status: `detail="round <N>/5 · scoping diff"`.

Same as session-review steps 1–2: list every repo touched this session, confirm each is a git repo, and establish the diff scope (current branch, base branch, merge-base):

```bash
git -C <path> rev-parse --abbrev-ref HEAD
git -C <path> merge-base HEAD origin/main 2>/dev/null \
  || git -C <path> merge-base HEAD origin/master 2>/dev/null \
  || git -C <path> merge-base HEAD origin/develop 2>/dev/null
git -C <path> diff <merge-base>...HEAD --stat
```

Re-run this at the start of every round — the diff grows as fixes land; the merge-base itself doesn't change mid-loop.

### 2. Spawn one review agent per repository

Write status: `detail="round <N>/5 · reviewing (<fixes_total> fixes so far)"`.

Same prompt template as session-review step 3: call `Agent` with `subagent_type: Explore`, one per repo, all sent in a single message so they run in parallel. Flag bugs, edge cases, type/null safety, broken API contracts, missing test coverage, security concerns, and misleading naming — nothing else.

### 3. Independently verify each finding

Before trusting any finding, re-check it yourself against the actual file/line and confirm it's introduced by this diff, not pre-existing. Verdict per finding:

- **Confirmed** — real, reproducible, in-scope. Fix it this round.
- **Not confirmed / advisory** — misread, pre-existing and unrelated, or a nitpick (style preference, naming bikeshed, non-functional suggestion). Log it under Notes; never fix it and never let it trigger another round.

### 4. Fix confirmed issues

Write status: `detail="round <N>/5 · fixing <k> confirmed issue(s)"`.

For each Confirmed finding, make the fix directly in the repo now — no plan-mode gate, this skill runs to completion. Keep each fix scoped to the finding it addresses; no drive-by refactors. Add this round's fix count to `fixes_total`.

### 5. Verify the fixes

Write status: `detail="round <N>/5 · verifying (<fixes_total> fixes so far)"`.

Run whatever this stack has for the files touched this round: typecheck, lint, build, relevant test suite. If a check fails for a reason unrelated to this round's fix (pre-existing environment/tooling issue), note it and continue rather than blocking the loop on it.

### 6. Decide: repeat or stop

- Zero Confirmed findings this round, across all repos → the loop is clean. Go to step 7.
- Confirmed findings this round, and you're under the round cap → go back to step 1 for a fresh review of the now-larger diff.
- Round cap hit with Confirmed findings still open → stop looping and go to step 7, carrying the remainder into the report.

### 7. Prune comments

Write status: `detail="pruning comments"`.

Run this once, after the loop has terminated — whether it closed clean or hit the cap. The rounds above add code and comments of their own; this is the pass that cleans them up.

Read `~/.claude/skills/prune-comments/SKILL.md` and follow its steps directly. Do not call it via the `Skill` tool — it is marked `disable-model-invocation`, so only the user can invoke it that way. Scope it to the diff this loop produced, per-repo, using the merge-base already established in step 1.

This step never reopens the loop. If pruning breaks a check, restore the offending comment and re-verify, but do not start another review round. Keep prune-comments' report — it goes into step 8 as its own section.

### 8. Save and report

Clear the status file (see Status line above) — the loop is done, running or capped.

Save the full record — every round's Confirmed fixes, the accumulated Notes, and the comment-pruning report from step 7 — to `~/.claude/session-reviews/session-review-loop-<YYYY-MM-DD>.md`, creating the directory if needed. Report inline: rounds run, fixes applied per round, remaining advisory notes, whether the loop closed clean or hit the cap, and the pruning summary as a final section.

## Constraints

- Never spend a round on advisory/nitpick findings — they go to Notes and stay there; they never block or extend the loop.
- Don't widen scope beyond what the diff and confirmed findings call for.
- If a fix would require a DB migration, a `docker compose` command, or anything session-review's underlying checks would normally ask about, ask before doing it — the round cap governs review iteration, not destructive operations.

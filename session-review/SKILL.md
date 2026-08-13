---
name: session-review
description: Compile a PR-style review of all repos touched this session. Suggest this command to the user when a significant coding task or feature implementation appears complete.
disable-model-invocation: true
---

## Purpose

Review all changes made across repositories this session as if each touched branch were about to be merged into its base branch. Independently verify each flagged issue, then produce a ready-to-execute fix plan for confirmed issues and a separate notes list for everything else.

## Steps

### 1. Identify touched repositories

From the session conversation, list every repository path where files were read, created, or modified. Confirm each is a git repo. If uncertain about a path, verify with Bash before including it.

### 2. Establish diff scope for each repository

For each repo, run these commands to determine the review surface:

```bash
git -C <path> rev-parse --abbrev-ref HEAD
git -C <path> merge-base HEAD origin/main 2>/dev/null \
  || git -C <path> merge-base HEAD origin/master 2>/dev/null \
  || git -C <path> merge-base HEAD origin/develop 2>/dev/null
git -C <path> diff <merge-base>...HEAD --stat
```

Record: repo path, current branch, base branch, merge-base commit, changed files.

### 3. Spawn one review agent per repository

Call `Agent` with `subagent_type: Explore` for each repo. Send all agents in a **single message** so they run in parallel. Use this prompt template (substitute actual values):

---
You are doing a pre-merge code review. Repository: `<path>`. Branch `<branch>` diverged from `<base-branch>` at `<merge-base>`.

Run `git -C <path> diff <merge-base>...HEAD` to see all changes. Also read any files where the diff alone lacks enough context to judge correctness.

Flag the following — nothing else:
- Bugs and logic errors
- Missing null/edge-case handling
- Type or null safety issues
- Broken API contracts or event shapes
- Missing or inadequate test coverage for changed code
- Security concerns (injection, data exposure, auth gaps)
- Naming that actively misleads a reader

Return a flat list. Each item: severity (`blocking` or `advisory`), file path and line reference where applicable, one-sentence description.
---

### 4. Independently verify each finding

Findings from step 3 are unverified claims, not facts — the finder agent can be wrong. Before any finding is allowed into the plan, re-check it yourself: read the actual file and line, confirm the described bug genuinely exists in the current code, and confirm the diff (not pre-existing code outside the diff) introduced it.

Determine a verdict per finding:

- **Confirmed** — the issue is real and reproducible from the code as written. Plan a concrete fix.
- **Not confirmed** — the finder misread the code, the issue is pre-existing and unrelated to this session's changes, or the concern doesn't apply. Note the reason in one sentence; do not include it in the fix plan.

### 5. Compile results

Merge all verified findings. Group by repository. Within each repo, split into two groups:

- **Confirmed fixes** — each with concrete, ordered fix steps (files to touch, functions/methods affected, the exact change). Write these so they can be executed directly, not summarized further.
- **Notes** — advisory findings and anything Not confirmed, each with a one-sentence reason. These are informational only and never enter the executable plan.

Remove duplicates.

### 6. Save the full report

Save the compiled review (both Confirmed fixes and Notes, across all repos) to `~/.claude/session-reviews/session-review-<YYYY-MM-DD>.md`, creating the directory if it does not exist. State the filename.

### 7. Exit plan mode with the fix plan

Call `ExitPlanMode` with a plan built from the **Confirmed fixes** only, across all repos, using their fix steps verbatim. This is the plan the user approves to go straight into execution — no advisory items, no notes, no unconfirmed findings.

If no findings were Confirmed, skip `ExitPlanMode` and report that no fixes are needed.

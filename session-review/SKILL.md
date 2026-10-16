---
name: session-review
description: Compile a PR-style review of all repos touched this session, including an architecture review against each repo's pattern map. Suggest this command to the user when a significant coding task or feature implementation appears complete.
user_invocable: true
disable-model-invocation: true
---

## Purpose

Review all changes made across repositories this session as if each touched branch were about to be merged into its base branch. Independently verify each flagged issue, then produce a ready-to-execute fix plan for confirmed issues and a separate notes list for everything else. Finish with two review checks from `~/.claude/skills/shared/review-checks.md` (duplication and complexity delta) and the architecture review from `~/.claude/skills/arch-review/SKILL.md` (pattern conformance, dependency direction, responsibility placement, coupling, contracts, and data ownership).

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
git -C <path> diff <merge-base> --stat
git -C <path> ls-files --others --exclude-standard
```

`git diff <merge-base>` compares the working tree with the merge-base, so it holds committed, staged, and unstaged changes together. It does not show untracked files, so `ls-files` lists them. Treat each untracked file as a new file.

Record: repo path, current branch, base branch, merge-base commit, changed files, untracked files.

### 3. Spawn one review agent per repository

Call `Agent` with `subagent_type: Explore` for each repo. Send all agents in a **single message** so they run in parallel. Use this prompt template (substitute actual values):

---
You are doing a pre-merge code review. Repository: `<path>`. Branch `<branch>` diverged from `<base-branch>` at `<merge-base>`.

Run `git -C <path> diff <merge-base>` to see all changes, committed and uncommitted. These untracked files are new files that the diff does not show; read each one in full: `<untracked files>`. Also read any files where the diff alone lacks enough context to judge correctness.

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

### 6. Run the review checks

Call `Agent` with `subagent_type: Explore` for each repo, all in a **single message**. Use this prompt template:

---
Read `~/.claude/skills/shared/review-checks.md` and run only its Duplication and Complexity checks on repository `<path>`, for the diff `git -C <path> diff <merge-base>` plus these untracked files, which count as new files: `<untracked files>`. Skip Precedent and Ownership. Return the Duplication Check and Complexity Delta tables from its **Tables** section, every command you ran, and a summary line in the format of its **Summary line** section that holds only those two counts.
---

Pattern precedent and responsibility boundaries are not run here, because step 7 checks them against the pattern map of the repo.

Treat each flag as an unverified claim, as in step 4: read the cited file:line and confirm it. Drop a flag that does not hold, and add it to Notes with a one-sentence reason.

Review-check results are information, not fixes. They never enter the Confirmed fixes or the bug table.

### 7. Run the architecture review

Read `~/.claude/skills/arch-review/SKILL.md` and follow its steps 2 to 8 for each repo, in session mode. Use the scope from step 2 of this skill in place of its step 1. Skip its steps 9 and 10, because step 8 of this skill saves one report for the whole review.

Its step 7 already verifies each finding. Sort the findings that survive:

- **Blocking** findings go into the Confirmed fixes of their repo. Write concrete, ordered fix steps in the same form as step 5. The "Direction for the fix" of the finding is where the steps start, not a replacement for them.
- **Advisory** findings go into Notes, each with its label or check, its file:line, and a one-sentence reason.
- Proposed architecture tests, proposed map entries, pattern map changes, pattern map disagreements, Observations, Dropped, and Scope notes are information for the report in step 8. They never enter the Confirmed fixes.

Record the summary line in the format from step 10 of `arch-review/SKILL.md`, and the path of the pattern map.

### 8. Save the full report

Save the compiled review (both Confirmed fixes and Notes, across all repos) to `~/.claude/session-reviews/session-review-<YYYY-MM-DD>.md`, creating the directory if it does not exist. Add two more sections, each with a subsection per repo:

- `## Review checks`: the summary line from step 6 and its two tables.
- `## Architecture review`: the summary line and the pattern map path from step 7, then the sections of the report template in step 9 of `arch-review/SKILL.md`, from **Pattern conformance** to **Scope notes**. Keep every section, also when it is empty, and write "None" in an empty one.

State the filename.

### 9. Show the review checks and the architecture review

Print both in the terminal before you exit plan mode, also when no fix is needed:

- per repo, the review-check summary line and the architecture summary line
- each review-check flag on one line: check, file:line, one-sentence reason
- each architecture finding on one line, blocking first: severity, label or check, file:line, one-sentence reason
- the pattern map path, and the number of pattern map changes and disagreements

If a repo has no flags and no findings, print its two summary lines only.

### 10. Exit plan mode with the fix plan

Call `ExitPlanMode` with a plan built from the **Confirmed fixes** only, across all repos, using their fix steps verbatim. This is the plan the user approves to go straight into execution — no advisory items, no notes, no unconfirmed findings.

After the fix sections, add a `## Review checks (information only)` section with, per repo: the review-check summary line and its two tables, the architecture summary line, the proposed architecture tests, and the pattern map disagreements. Give the report path from step 8 for the rest. It is for the user to read in the plan; it holds no fix steps, and nothing in it is executed. It comes before any `## Notes and answers` section and before the Comment Policy section, which stays last.

If no findings were Confirmed, skip `ExitPlanMode` and report that no fixes are needed. The review checks and the architecture review are already in the terminal from step 9 and in the report from step 8.

---
name: prep-pr
description: Fill in the repo's pull request template (or a short default) with the work done this session — ticked checkboxes, the known ticket number, and the latest /runbook results — and save it to ~/.claude/pr-prep/. Use when the user types /prep-pr.
user_invocable: true
disable-model-invocation: true
---

## Purpose

Write the PR description the user would submit for this session's work, so opening the PR is a paste. The skill never creates the PR and never reads a ticket tracker.

## Steps

### 1. Identify the session's work

From the session conversation, list every repository where files were created or modified. Each repo is its own PR, so run the steps below once per repo. For each one:

```bash
git -C <path> rev-parse --abbrev-ref HEAD
git -C <path> merge-base HEAD origin/main 2>/dev/null \
  || git -C <path> merge-base HEAD origin/master 2>/dev/null \
  || git -C <path> merge-base HEAD origin/develop 2>/dev/null
git -C <path> diff <merge-base> --stat
git -C <path> ls-files --others --exclude-standard
```

`git diff <merge-base>` (no `...HEAD`) includes uncommitted work, which the PR will carry once it is committed. Use the conversation for why the work was done and the diff for what it does.

### 2. Find the template

Search the same places as `gh pr create`, ignoring case:

```bash
find <path>/.github <path> <path>/docs -maxdepth 1 -type f -iname 'pull_request_template*' 2>/dev/null
find <path>/.github <path> <path>/docs -maxdepth 2 -type f -ipath '*/pull_request_template/*.md' 2>/dev/null | sort -u
```

- **None found** → use the default in step 6.
- **One found** → use it.
- **More than one** → ask the user which one with `AskUserQuestion`, labeling each option with its path relative to the repo root.

### 3. Find the ticket number

Use a ticket number only when it is already known:

- it came up in the conversation, or
- the branch name contains one: a key like `FW-3838`, or a ClickUp id like `CU-868g6hpjy`.

Never look a ticket up — no ClickUp, Linear, Jira, or `gh issue` call, for the number or for anything else. Link the ticket only when the conversation already gave its URL; otherwise write the bare key. If no number is known, leave the ticket field empty.

### 4. Find the manual test results

```bash
ls -t ~/.claude/runbook-tests/<repo>_*.md 2>/dev/null | head -1
```

If a file exists, copy its summary line and its results table verbatim into the template's testing section. If the template has no testing section, add a `## Manual testing` section for it. If no file exists, the manual-testing part says "Not run".

### 5. Fill in the template

Keep the template's headings, order, and checklist items. Then:

- Replace every placeholder with real content. Delete every instruction comment (`<!-- … -->`).
- Write each section in as few words as carry the point: bullets over prose, no restating the diff line by line, no claims the session cannot back.
- Tick a checkbox only when the session or the diff shows it is true (tests added → the diff adds test files; docs updated → the diff touches docs). Leave the rest unticked; never tick something nobody did, such as "tested on staging".
- A section that does not apply gets "N/A".
- A field about the ticket's state in the tracker (status, sprint, QA sign-off) stays empty.

### 6. Default when there is no template

```markdown
## Summary

- <what changed and why, 1–3 bullets>

## Ticket

<key or link>

## Changes

- <one bullet per area: API, UI, data, config>

## Testing

- Automated: <test files added or changed, or "None">
- Manual: <runbook summary line and table, or "Not run">

## Notes for reviewers

- <migrations, config, deploy order, or known gaps>
```

Leave out **Ticket** when no number is known, and **Notes for reviewers** when there is nothing to note.

### 7. Save and report

- **Directory:** `~/.claude/pr-prep/` (create it if missing).
- **Filename:** `<repo>_<YYYY-MM-DD>_<descriptive-slug>.md`, where `<repo>` is the basename of `git -C <path> rev-parse --show-toplevel`. If the file exists, append `-2`, `-3`, … to the slug instead of overwriting.

The file holds the PR body only. Report per repo:

- the saved path
- a suggested PR title (under 70 characters)
- the template used, or "default"
- the ticket number and where it came from (conversation or branch), or "none known"
- the runbook file used, or "none"
- the command to open the PR: `gh pr create --title "<title>" --body-file <path>`

---
name: find-session
description: Search past Claude Code sessions by keyword and produce a resume command for the one you pick. Use when the user wants to find, recall, or resume an earlier session, or asks whether something was discussed before. Filters to the current repo by default.
user_invocable: true
---

# find-session

Find an earlier Claude Code session that mentions a pattern, then hand the user the
command to resume it.

This skill wraps the `claude-find` script (`~/.local/bin/claude-find`, alias `cf`),
which searches the JSONL session logs under `~/.claude/projects/`.

**You cannot resume a session yourself.** `claude --resume` needs a fresh terminal.
The skill ends by printing the command for the user to run.

## Arguments

`/find-session <pattern> [all]`

- `<pattern>` — a ripgrep regex, matched case-insensitively. Required.
- `all` — skip the repo filter and search every project.

## Steps

### 1. Get the pattern

If the user passed no pattern, ask for one in plain text and stop until they answer.
Do not guess a pattern from the conversation.

### 2. Determine repo context

Run:

```bash
basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "no-repo"
```

Store the result as `<repo>`.

### 3. Search

Run:

```bash
claude-find "<pattern>" 25
```

Each result block holds a title, a `cd <cwd>; claude --resume <id>` line, and a
snippet. Results are newest-first by session mtime.

If the output is `No matches for: <pattern>`, tell the user, and suggest a shorter or
less specific pattern. Stop here.

### 4. Filter

- **Default:** keep only results whose `cd` path ends in `/<repo>`, or contains
  `/<repo>/` (this keeps worktrees of the same repo).
- **If the user passed `all`,** or `<repo>` is `no-repo`: keep everything.
- **If the filter leaves zero results:** say so, then show the unfiltered list instead.

### 5. Present options

Take the first 4 results. Use `AskUserQuestion` to let the user pick one. Label each
option with the session title. Put the snippet in the option description, trimmed to
one readable line — strip the JSON escaping so it reads as text.

If more than 4 results survive the filter, say how many there are, and suggest a
narrower pattern.

### 6. Summarize the pick

The session file is `~/.claude/projects/<slug>/<id>.jsonl`. Find it with:

```bash
ls ~/.claude/projects/*/<id>.jsonl
```

Read the user's prompts from it to build the summary:

```bash
jq -r 'select(.type=="user") | .message.content
       | if type=="string" then . else [.[] | select(.type=="text") | .text] | join(" ") end' \
   <file> 2>/dev/null | head -20
```

`.message.content` is a string on some records and an array of blocks on others, so the
`if` branch is needed. The first entries are often slash-command scaffolding rather than
the user's words — skip lines that start with `<command` or `Base directory for this skill`.

Give a 2–4 sentence summary: what the session was about, what was decided, and where
it appeared to stop.

### 7. Print the resume command

End with the resume command on its own line, in a bash block, so the user can copy it:

```bash
cd <cwd>; claude --resume <id>
```

Tell the user to run it in a new terminal.

## Notes

- The search covers the raw session log, so it matches tool output and file contents,
  not only what the user typed. A common word returns noise. Prefer a distinctive term.
- Claude Code deletes old session logs on a retention schedule. A session that this
  skill cannot find may already be gone.

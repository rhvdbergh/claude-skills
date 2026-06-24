---
name: explain
description: Explain the salient points of the previous conversation in really easy terms, stepping through the relevant code with concrete examples. Use when the user types /explain (optionally /explain <topic> to focus on one part), or asks for a plain-language walkthrough of what was just done.
user_invocable: true
---

# explain

Recap the previous conversation in plain, easy-to-understand language, then step through the relevant code with a concrete example at each step.

## Steps

### 1. Determine scope

- **No argument** (plain `/explain`): explain the entire previous conversation's salient points.
- **With argument** (e.g. `/explain the auth changes`): narrow the explanation to just that topic or area. Only cover parts of the conversation relevant to the argument.

If there is no meaningful prior conversation to explain, say so and ask what the user would like explained. Stop here.

### 2. Identify the salient points

Read the conversation and extract the key things that happened: what problem was being solved, what approach was chosen, and what changed. Keep this to the most important points — leave out noise and tangents.

### 3. Verify the code

Before explaining any code, use read-only tools to confirm what is actually in the files right now:

- Use the `Read` tool to read relevant files.
- Use `Bash` (for `grep` or `git diff` output) if it helps locate or confirm what changed.

**Never explain from memory alone.** If the code has changed since the conversation, explain the current state of the file and note the discrepancy.

Do not edit, create, or delete any files. This step is observation only.

### 4. Give the plain-English summary

Write a short (3–6 sentences) overview of the salient points in really easy terms — as if explaining to someone who has never seen this code before. Avoid jargon; when a technical term is unavoidable, define it in parentheses right there.

Example phrasing:
> "We were trying to fix a bug where users got logged out unexpectedly. The root cause was that the session token wasn't being refreshed before it expired. We updated one function so it now checks how much time is left and asks for a new token when less than 5 minutes remain."

### 5. Step through the code with examples

For each file or logical area that was touched, do the following:

1. **Name the file and what it does** — one sentence on its role in the system.
2. **Explain what changed and why** — in plain terms, no assumptions about prior knowledge.
3. **Give a concrete example** — show a before/after snippet, a sample input/output, or a walkthrough of what happens when the code runs. Make the example as simple and specific as possible.

Repeat for each meaningful change. Sequence them in the order they are most logical to understand (e.g. data model → service → API → UI), not necessarily the order they were discussed.

### 6. Close with a one-line takeaway

End with a single sentence summarising what the whole session achieved, in plain English.

Example:
> "In short: the login system now keeps users logged in automatically instead of kicking them out after an hour."

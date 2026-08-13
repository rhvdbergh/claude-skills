---
name: explain-diff
description: Generate a rich HTML explanation of a git diff — background, intuition, code walkthrough, and an interactive quiz — saved to ~/.claude/diff-explanations/. Use when the user types /explain-diff [<ref>].
user_invocable: true
---

# explain-diff

Generate a structured, educational explanation of a git diff and write it as a self-contained HTML file. No dependencies required.

## Steps

### 1. Determine the diff ref

- **With argument** (e.g. `/explain-diff main..feature/auth`): use the provided git ref exactly.
- **No argument**: default to `main...HEAD` (changes on the current branch since it diverged from main).

```bash
git rev-parse --show-toplevel
git branch --show-current
git diff <ref> --stat
```

If the diff is empty, tell the user and stop.

### 2. Get the diff

```bash
git diff <ref>
git diff <ref> --name-only
```

Skip generated files, lock files, migration files, and `.snap` files.

### 3. Read surrounding context

For each changed file (up to 8 files), use the Read tool to read the full file. Note the file's role in the system and how the changed lines fit into the larger context. Never explain from the diff alone.

### 4. Derive slug and output path

- **Slug**: branch name with `/`, `_`, spaces replaced by `-`, lowercased, truncated to 40 chars. If on main or detached HEAD, derive a 3-word kebab-case summary from the changes.
- **Output path**: `~/.claude/diff-explanations/<repo>_<YYYY-MM-DD>_<slug>.html`

Each run always creates a new file — never overwrite an existing one.

```bash
mkdir -p ~/.claude/diff-explanations
```

### 5. Write the HTML file

Use the Write tool to write a single self-contained HTML file to the output path. The file must have no external dependencies — all CSS and JS inline.

#### Structure

The page has four sections:

1. **Background** — 2–4 sentence overview of the changed code's role, what it does before and after, and why the change matters.

2. **Intuition** — The key concept driving the change, explained simply. Include a concrete toy example showing the effect of the change, rendered as a before/after code comparison.

3. **Code Walkthrough** — One entry per changed file (logical order: data model → service → API → UI, not diff order). Each entry has: file path, one-sentence role, plain-English explanation of what changed and why, and a before/after code block where relevant.

4. **Quiz** — 5 multiple-choice questions testing genuine comprehension. Each question has 4 options (A–D). Clicking an option reveals whether it is correct and shows a one-sentence explanation. Only one reveal per question.

#### Design

- Clean, readable design with a neutral light background and good typography.
- Page width: `.page` starts at `width: 860px; max-width: calc(100vw - 4rem); margin: 0 auto`. A fixed drag handle (`.resize-handle`, 6px wide, `cursor: ew-resize`) is positioned at the right edge of `.page` via JS. Dragging it adjusts `page.style.width`; the new width is persisted in `localStorage`. The handle turns indigo on hover/drag. On `window resize`, reposition the handle. Multiply mouse delta by 2 (since the centered page expands symmetrically) and clamp between 400px and `window.innerWidth - 64`.
- Syntax-highlighted code blocks: dark background (`#1e1e1e`), monospace font, appropriate token colors (keywords blue, strings green, comments grey, types teal). Apply highlighting via a small inline JS function — no external libraries.
- Before/after code blocks side by side (`flex-direction: row; flex-wrap: wrap`), each side `flex: 1 1 300px`. Each `pre` block uses `overflow-x: auto` so long lines scroll horizontally rather than wrapping.
- Quiz options styled as clickable buttons. On click: correct answer turns green with a checkmark, wrong answers turn red with an ✗. Explanation appears below. Disable all options after one is chosen.
- Section headers use a clear visual hierarchy. Use a subtle left border or colored rule to distinguish sections.
- `<title>` set to the explanation title. `<meta name="description">` set to a one-line summary.

#### Content guidelines

- Write in the style of Martin Kleppmann: clear, precise, builds intuition before detail.
- Define any jargon inline in parentheses the first time it appears.
- Keep code snippets short — enough to illustrate the point, not the full function.
- Quiz questions should test genuine comprehension, not trivia. Medium difficulty.

### 6. Report

Tell the user:
- The full path to the saved file
- How to open it: `open <path>`

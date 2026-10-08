---
name: explain-diff
description: Generate a rich HTML explanation of a git diff — background, intuition, code walkthrough, four review sections (duplication, complexity delta, pattern precedent with blame authors, responsibility boundaries), and an interactive quiz — saved to ~/.claude/diff-explanations/. Use when the user types /explain-diff [<ref>].
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

### 4. Gather evidence for the review sections

Read `~/.claude/skills/shared/review-checks.md` and follow its **Evidence** section for the diff from step 1. Collect the evidence now, before you write the page.

### 5. Derive slug and output path

- **Slug**: branch name with `/`, `_`, spaces replaced by `-`, lowercased, truncated to 40 chars. If on main or detached HEAD, derive a 3-word kebab-case summary from the changes.
- **Output path**: `~/.claude/diff-explanations/<repo>_<YYYY-MM-DD>_<slug>.html`

Each run always creates a new file — never overwrite an existing one.

```bash
mkdir -p ~/.claude/diff-explanations
```

### 6. Write the HTML file

Use the Write tool to write a single self-contained HTML file to the output path. The file must have no external dependencies — all CSS and JS inline.

#### Structure

The page has eight sections. Sections 1–3 are the main explanation. Sections 4–7 are the review sections: one per table in the **Tables** section of `review-checks.md`, in the same order, always present, even when a section has no finding. Section 8 is the quiz.

1. **Background** — 2–4 sentence overview of the changed code's role, what it does before and after, and why the change matters.

2. **Intuition** — The key concept driving the change, explained simply. Include a concrete toy example showing the effect of the change, rendered as a before/after code comparison.

3. **Code Walkthrough** — One entry per changed file (logical order: data model → service → API → UI, not diff order). Each entry has: file path, one-sentence role, plain-English explanation of what changed and why, and a before/after code block where relevant.

4. **Duplication Check** — whether existing code overlaps what the diff adds.

5. **Complexity Delta** — what the diff adds and removes in locks, abstractions, and indirection, with the net verdict.

6. **Pattern Precedent** — where else the repo uses the main pattern of the diff, with blame authors and dates.

7. **Responsibility Boundaries** — which layer and which repo owns each part of the changed behavior.

8. **Quiz** — 5 multiple-choice questions testing genuine comprehension. Each question has 4 options. Clicking an option reveals whether it is correct and shows a one-sentence explanation. Only one reveal per question. See **Quiz construction** below — the answer must not be guessable from its position or its length.

#### Design

- Clean, readable design with a neutral light background and good typography.
- Page width: `.page` starts at `width: 860px; max-width: calc(100vw - 4rem); margin: 0 auto`. A fixed drag handle (`.resize-handle`, 6px wide, `cursor: ew-resize`) is positioned at the right edge of `.page` via JS. Dragging it adjusts `page.style.width`; the new width is persisted in `localStorage`. The handle turns indigo on hover/drag. On `window resize`, reposition the handle. Multiply mouse delta by 2 (since the centered page expands symmetrically) and clamp between 400px and `window.innerWidth - 64`.
- Syntax-highlighted code blocks: dark background (`#1e1e1e`), monospace font, appropriate token colors (keywords blue, strings green, comments grey, types teal). Apply highlighting via a small inline JS function — no external libraries.
- Before/after code blocks side by side (`flex-direction: row; flex-wrap: wrap`), each side `flex: 1 1 300px`. Each `pre` block uses `overflow-x: auto` so long lines scroll horizontally rather than wrapping.
- Quiz options styled as clickable buttons, built by JS from the shuffled option data (see **Quiz construction**). On click: correct answer turns green with a checkmark, wrong answers turn red with an ✗. Explanation appears below. Disable all options after one is chosen.
- Section headers use a clear visual hierarchy. Use a subtle left border or colored rule to distinguish sections.
- Give the four review sections a different left-border color from the main explanation, and put a small "Review" label above the first one, so the reader sees where the explanation ends.
- Review tables: full width, zebra rows, `font-size: 0.9em`, file:line cells in monospace. Wrap each table in a container with `overflow-x: auto`.
- Flags (as the **Flags** section of `review-checks.md` defines them) get an amber badge. A section with no flags shows a grey "No findings" badge next to its header.
- `<title>` set to the explanation title. `<meta name="description">` set to a one-line summary.

#### Content guidelines

- Write in the style of Martin Kleppmann: clear, precise, builds intuition before detail.
- Define any jargon inline in parentheses the first time it appears.
- Keep code snippets short — enough to illustrate the point, not the full function.
- Quiz questions should test genuine comprehension, not trivia. Medium difficulty. At least one question must come from the review sections.

#### Quiz construction

A reader must not be able to pick the answer without understanding the change. Two tells give the answer away: the position of the correct option, and its length. Remove both.

**Data shape.** Do not hard-code the option order in the HTML. Emit each question as data, with the options in authoring order and the correct one marked by a flag:

```js
const QUIZ = [
  {
    question: "...",
    options: [
      { text: "...", correct: true,  why: "..." },
      { text: "...", correct: false, why: "..." },
      { text: "...", correct: false, why: "..." },
      { text: "...", correct: false, why: "..." }
    ]
  }
];
```

**Shuffle at render time.** On page load, shuffle each question's options with a Fisher-Yates shuffle before you build the buttons. Derive the A–D letter from the shuffled index, never from the authoring order. Because the correct option carries a flag, the shuffle cannot break the scoring.

**Length parity.** The shuffle fixes position. It does not fix length, so you must write the options to the same size:

- Every option of one question must be within about 20% of the others in word count.
- Write all four options first, then trim the longest and expand the shortest until they match.
- Put the reason the answer is correct in the `why` field, not in the option text. The `why` field is only shown after the click, so it cannot leak the answer.
- Give every wrong option a real claim about the code. Do not write a short wrong option that is obviously a placeholder.
- Use the same grammar for all four options: if one starts with a verb, all start with a verb.

**Check before you save.** For each question, count the words of each option and compare. If one option is the longest in more than two of the five questions, rewrite it.

### 7. Report

Tell the user:
- The full path to the saved file
- How to open it: `open <path>`
- The review-check summary line (see **Summary line** in `review-checks.md`)

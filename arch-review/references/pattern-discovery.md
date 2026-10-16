# Pattern discovery

How to find the architecture patterns of one repo and write them to its pattern map. The pattern map describes the base branch, never the change under review. If the change were in the scan, a new pattern in the change would count as precedent for itself.

## Contents

1. Read the base branch without a checkout
2. Sources, strongest first
3. Categories
4. When an inferred pattern counts
5. Two patterns at once
6. Pattern map format
7. Refresh rules

## 1. Read the base branch without a checkout

Never check out, fetch, or pull. Read the base ref that is already local (for example `origin/main`) and record its SHA. A stale base ref is acceptable; the map header states which commit it describes.

```bash
git -C <repo> rev-parse <base-ref>
git -C <repo> ls-tree -r --name-only <base-ref>
git -C <repo> show <base-ref>:<path>
git -C <repo> grep -n "<marker>" <base-ref> -- <pathspec>
```

`git grep` against a ref prints `<ref>:<path>:<line>:`. Strip the `<ref>:` prefix before you cite the file:line.

## 2. Sources, strongest first

1. **Written rules.** `CLAUDE.md` files at any depth, `./docs` (the masterplan), ADRs (often `docs/adr/` or `docs/decisions/`), and `README` files in the layer folders.
2. **Enforced rules.** Architecture tests (search for `NetArchTest`, `ArchUnitNET`, `ArchUnitTS`, `Types.InAssembly`, `dependency-cruiser`), lint rules (`eslint-plugin-boundaries`, `import/no-restricted-paths`, `no-restricted-imports`), `.editorconfig` analyzer severities, and `Directory.Build.props`.
3. **Inferred rules.** What most sibling files do. Section 4 says when this counts.

A written or enforced rule is a pattern even when the code does not follow it everywhere. Record the places that break it under the entry, because a change that copies a breaking file is still a finding.

## 3. Categories

Detect the stack first (`*.csproj`, `package.json`, `pyproject.toml`). Scan only the categories that apply. For each category, find the files of that kind, then read enough of them to see what they have in common. Read at least 5 files of a kind when that many exist.

| Category | What to find |
| --- | --- |
| Layout and layers | Projects or top-level folders and the references between them. Feature folders or layer folders. Which layer may import which. |
| Request flow | The chain from the entry point to the data. For example: controller → MediatR request → handler → repository. Minimal API or controllers. |
| Naming | Suffixes and file names per kind: `*Command`, `*Handler`, `*Query`, `*Dto`, `use*` hooks, `*.slice.ts`. One type per file or not. |
| Errors | `Result<T>` or exceptions, a global exception handler or middleware, the mapping from error to HTTP status, `ProblemDetails`. |
| Validation | FluentValidation in a pipeline behavior, data annotations, validation inside handlers, zod schemas on the frontend. |
| Data access | Repository per aggregate, direct `DbContext`, Marten sessions, Dapper. Where transactions start. Where migrations live. |
| Dependency injection | Registration style (an extension method per layer, assembly scanning, Scrutor) and lifetimes. |
| Cross-cutting | Where authorization is enforced (attribute, policy, pipeline behavior), logging style, options and config binding, outbound HTTP clients. |
| API contracts | DTO location, entity to DTO mapping (manual, AutoMapper, Mapster), versioning, generated clients (NSwag, OpenAPI). |
| Frontend data and state | RTK Query, React Query, or plain `fetch`. Redux, context, or local state. Where server state lives. |
| Frontend structure | Component folder layout, one component per file, hooks folder, styling approach, page versus component split. |
| Tests | Test project or folder per layer, naming, fixtures, builders, real infrastructure (Testcontainers) or mocks. |

## 4. When an inferred pattern counts

An inferred pattern counts when both are true:

- at least 3 sibling files follow it, and
- at least two thirds of the sibling files follow it.

Below that, record it under **Observations**, not as a pattern. The review never reports a violation of an observation. Inference from too few files produces false rules, and false rules produce noise in every later review.

Give every inferred entry its count, for example "12 of 13 handlers", and 2 or 3 example file:lines.

## 5. Two patterns at once

When one category has two patterns with real use (a migration in progress):

1. If a written or enforced rule names one, that one is the target.
2. If no rule exists, get the most recent `git blame` date of a few uses of each pattern:

   ```bash
   git -C <repo> blame -L <line>,<line> --porcelain <base-ref> -- <file> | grep '^author-time '
   ```

   The pattern with the more recent uses is the probable target. Mark the entry `target (inferred from dates)`, because it is a guess.
3. Record both entries. Give the old one the status `migrating-from` and the new one `migrating-to`, and link them by ID.

## 6. Pattern map format

Write the map to `~/.claude/arch-patterns/<repo-key>.md`. Get `<repo-key>` from `~/.claude/skills/arch-review/scripts/repo-key.sh <repo>`.

```markdown
# Architecture patterns: <repo-key>

- Origin: <origin URL, or "none">
- Base ref: <base-ref> at <full SHA>
- Scanned: <YYYY-MM-DD>
- Stack: <for example ".NET 8, ASP.NET Core, MediatR, EF Core; Next.js 14, RTK Query">

## <Category>

### P-<NN>: <one-line rule>

- Applies to: <path glob or file kind, for example "src/*/Application/**/*Handler.cs">
- Source: written | enforced | inferred
- Evidence: <doc file:line, test file:line, or "12 of 13 handlers" plus 2–3 example file:lines>
- Status: active | migrating-from P-<NN> | migrating-to P-<NN>
- Confirmed: no
- Known exceptions: <file:lines that break it, or "none">

## Observations

- <pattern that missed the threshold, with its count>

## Rejected

- <inferred rule that the user said is not a pattern, and the reason they gave>
```

IDs are stable. Never renumber an entry. Give a new entry the next free number.

The user edits this file by hand. `Confirmed: yes` means the user checked the entry. A `Rejected` entry means the user said it is not a pattern.

## 7. Refresh rules

When the map exists, decide what to do from its header:

```bash
git -C <repo> cat-file -e <scanned-sha>^{commit}
git -C <repo> diff --name-only <scanned-sha> <base-ref>
```

- **The scanned SHA is not in the repo** (history was rewritten): do a full scan. Carry over every `Confirmed: yes` entry and the whole `Rejected` section unchanged.
- **No files changed**: use the map as it is.
- **Files changed**: rescan only the categories whose files changed. Always rescan when a written or enforced source changed (docs, `CLAUDE.md`, architecture tests, lint config).

During a refresh:

- Never change an entry with `Confirmed: yes`. If the code no longer supports it, leave it and report the disagreement.
- Never add back a rule from `Rejected`.
- You can update the evidence and counts of an unconfirmed entry. If its rule no longer passes the threshold, move it to Observations.
- Record every change in the review report under **Pattern map changes**, so no change happens without the user seeing it.

Update the header SHA and date after the refresh.

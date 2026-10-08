# Review checks

Four checks on a diff: duplication, complexity delta, pattern precedent, and responsibility boundaries. The skill that reads this file defines the diff (a git ref, or a merge-base per repo) and where the results go. Run the checks once per repo, and run every git command against that repo (`git -C <path> …`).

## Evidence

Every check must rest on searches of the repo, not on the diff alone. Keep every file:line and command you use.

**Duplication.** List each new component, handler, endpoint, query, hook, or service class that the diff adds. For each one, search the repo for code that already does the same job:

```bash
git grep -n -i "<name or key term>" -- ':!*.lock' ':!*generated*'
git grep -n "<route, table name, action type, or event name>"
```

Search by responsibility as well as by name: the same route, the same table, the same Redux action, the same MediatR request, the same UI element.

**Complexity.** Scan the added lines for:

- locks and coordination: `lock`, `SemaphoreSlim`, `Mutex`, `Interlocked`, transactions, retries, distributed locks
- abstractions: new interfaces, base classes, generics, wrappers, factories, decorators
- indirection: new DI registrations, events and handlers, pipeline behaviors, middleware, config flags, extra call layers between the caller and the work

Also note what the diff removes, so the delta is net.

**Precedent.** Name the main pattern the diff uses (for example "repository per aggregate", "optimistic concurrency with a row version", "custom hook for fetch state"). Find up to 5 other places that use it, then get the author and date of each:

```bash
git grep -n "<pattern marker>"
git blame -L <line>,<line> --porcelain <file> | grep -E '^(author|author-time) '
```

Convert `author-time` to a `YYYY-MM-DD` date. If no other place uses the pattern, record that the diff introduces it.

**Ownership.** For each changed file, decide its layer (for example domain, application, infrastructure, API, UI) and its repo. Check the project's architecture docs (`./docs`, `CLAUDE.md`, architecture tests) for the rule that says which layer owns what. Cite the rule if you find one.

If a search finds nothing, record the search and the result "no evidence found". Never fill a table from inference. Every claim cites a file:line from the current checkout.

## Tables

Each check produces one table. All four tables are always present, even when a table has no rows.

1. **Duplication Check** — columns: new item, existing item (file:line), overlap (full, partial, none), and a one-sentence note on whether to reuse, merge, or keep both. If nothing overlaps, list the searches you ran and say "no overlap found".

2. **Complexity Delta** — columns: item, kind (lock, abstraction, indirection), added or removed, and what it buys against what it costs (for example "the `SemaphoreSlim` stops two imports writing the same batch; every caller now awaits it"). End with a one-sentence net verdict: the complexity goes up, goes down, or stays the same, and whether the gain justifies it.

3. **Pattern Precedent** — columns: file:line, author, date (from `git blame`), and a short note on whether the diff follows or departs from that usage. If the diff departs from the precedent, say how. If the diff is the first use, say so, and say that it sets the precedent.

4. **Responsibility Boundaries** — columns: behavior, owning layer, owning repo, and the file that holds it. Flag every place where logic sits in a layer that does not own it (for example business rules in a controller or in a React component, or a contract that the frontend defines and the backend must follow). Cite the architecture rule when one exists.

## Flags

A row is a flag when it shows one of these:

- Duplication: an overlap to reuse or merge
- Complexity: a cost that the gain does not justify
- Precedent: a departure from the existing usage
- Boundaries: logic in a layer that does not own it

## Summary line

One line with the flag count of each check, for example:

`Duplication: 1 overlap, Complexity: 0, Precedent: 1 departure, Boundaries: 0`

# Architecture checks

The checks that apply to any change, also where the pattern map has no entry. Each check names what to look for and how to get the evidence. Skip a check that does not apply to the change, and say that you skipped it.

These checks look at structure. Leave line-level bugs, style, duplication, and the complexity delta to `/code-review`, `/simplify`, and the review checks in `~/.claude/skills/shared/review-checks.md`.

## 1. Dependency direction

- The domain or application layer imports infrastructure: EF Core, HTTP clients, the file system, a message bus SDK.
- The change adds a cycle between projects, modules, or feature folders.
- One feature reaches into the internals of a different feature instead of through its public entry point.

Evidence: the `ProjectReference` elements in `*.csproj`, `using` and `import` lines in the changed files, and the folder of each imported file.

## 2. Responsibility placement

- Business rules in a controller, an endpoint, a React component, a reducer, or a SQL query.
- One class, handler, or component that now does several unrelated jobs.
- Validation, authorization, or mapping in a layer other than the one the codebase uses for it.

Evidence: the method bodies in the changed files, compared against where sibling features keep the same kind of logic.

## 3. Coupling and cohesion

- One feature needs edits in many unrelated modules.
- Domain entities leave the API as response bodies, or DTOs enter the domain.
- A change to a shared type or shared config forces edits in code that does not use the feature.

Evidence: `git diff --stat` grouped by module, and the callers of each changed shared type (`git grep -n "<TypeName>"`).

## 4. Abstractions

- **Premature:** an interface with one implementation and no test that substitutes it, or a generic helper with one caller.
- **Missing:** the same logic in three or more places.
- **Leaky:** callers must know the internals to use the abstraction correctly, for example they must call methods in a fixed order or catch an infrastructure exception.

Evidence: count the implementations and callers with `git grep`.

## 5. Contracts between parts

Use this check only for behavior that other code depends on: a public HTTP API, an event or message schema, a generated client, a shared package.

- A field removed or renamed, a type changed, or a status code changed.
- A backend API change with no matching update to the generated client. The skill must not generate the client. Report that codegen must run.
- A change that breaks during a rolling deploy, when old and new versions run at the same time.

Evidence: the changed DTOs, controllers, and event types, and their consumers in this repo or in other repos touched this session.

## 6. Data ownership and consistency

- A second module writes to a table, an aggregate, or an event stream that a different module owns.
- One transaction spans more than one aggregate or service.
- A database migration that the old code cannot run against, or a Marten projection change that needs a rebuild.

Evidence: the `DbSet` and repository usages, the migration files, and the projection classes in the diff.

## 7. Cross-cutting concerns

- Authorization enforced at a different layer than in sibling features, or missing on a new endpoint.
- An outbound call with no timeout, or a retry on an operation that is not idempotent.
- Error handling or logging that does not follow the strategy of the codebase.

Evidence: the attributes and policies on the new endpoints, and the HTTP client registrations.

## 8. Testability

- New logic that you cannot test without a real database or network.
- Dependencies created with `new`, static calls, or `DateTime.Now` instead of injected.

Evidence: constructors and method bodies in the changed files.

## 9. Cost to reverse

- A new library or package, a new table, a new public endpoint, or a new infrastructure component.

These are expensive to undo. The PR description or the session must give a reason for each one. If no reason exists, report it as advisory.

Evidence: the changes to `*.csproj`, `package.json`, migrations, and infrastructure files.

## 10. Performance in the design

- N+1 queries that the design causes, not a single loop.
- Many small calls across a service or a process where one call fits.
- A synchronous call where the caller does not need the result, so a queue or a background job fits.

Evidence: the call chain from the entry point to the data.

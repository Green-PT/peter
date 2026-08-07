# E2E gate

End-to-end tests drive the real thing — the real entry point, the real server or
binary, the real database. Mocks at this layer defeat the point: unit tests
already cover logic in isolation. E2E exists to catch what only integration
reveals — wiring, migrations, auth flows, serialization, the contract actually
holding.

## What E2E means here

"E2E" is not "a browser". It is *the outermost entry point a user or caller
actually touches*, exercised for real. Name the row that fits in `spec.md`:

| Project type | Entry point driven | Real dependencies |
|---|---|---|
| Web app | browser at the base URL | server + database |
| API / service | HTTP client against the running server | database, queues |
| CLI | the built binary spawned as a subprocess | real filesystem, real DB, real exit codes and stderr |
| Library / SDK | the public API, imported from a separate test package as a consumer would | whatever it integrates with |
| Data pipeline / ETL | one full run over real fixture data | real source and sink |
| Worker / cron | the job triggered through its real queue or scheduler | broker + database |

Most projects match a row. **`no-e2e` is the rare exception, not the escape
hatch** — it needs a stated reason in `spec.md`, and then every acceptance
criterion maps to an integration test instead, with that mapping recorded. A
project too awkward to drive end to end is usually a project with no seam, which
is itself the finding.

**If the harness doesn't exist yet, installing it is its own task** — the first
one in the graph, owned by the `e2e/` owner, with its own criteria ("`<cmd>`
runs a failing example spec against a migrated test DB"). Never bolt harness
setup onto a feature task; it is where the whole gate's credibility comes from.

## Why no `e2e-tester` node

E2E is a **machine gate**, not an audit. Its trust comes from determinism plus
the parent running the command — not from author independence. A builder cannot
fake a green E2E run the parent executes itself.

The flows are defined independently regardless: they come from the acceptance
criteria in `spec.md`, which the parent wrote before any code existed. The
builder writes the automation, not the bar.

## Ownership

`e2e/` has exactly one writer, named in `spec.md`:

- App renders a UI → **frontend-builder** owns `e2e/` (flows drive the UI; the
  server is exercised through it).
- Nothing renders — API, CLI, library, pipeline, worker → **backend-builder**
  owns `e2e/`.

Never both. The other builder may read the tests, never edit them.

## Coverage bar

- **Every acceptance criterion in `spec.md` maps to at least one E2E test**, or
  is explicitly marked unit-only in the spec with a reason — or the whole suite
  is `no-e2e: <reason>` and each criterion maps to an integration test instead.
  Unmapped criteria are a gate failure — that's the check that stops E2E theater.
- Every critical path end to end: sign-up → sign-in → the core action → sign-out.
- Every destructive or money-touching flow, including its confirmation step.
- Authorization negatives: a signed-out user and a wrong-tenant user are both
  refused. This is the cheapest ongoing defense against A01 regressions.
- Error paths, not just happy paths: invalid input, expired session, failed
  dependency.

## Environment

Stated in `spec.md`, no improvising:

- Real database where the project has one, isolated from dev — a container or a
  dedicated test schema.
- Migrations run from scratch before the suite. A suite that only passes against
  an already-migrated DB is not testing migrations.
- Deterministic seed data, reset between runs. Never depend on data left by a
  previous run.
- No calls to third-party production services — stub at the network boundary,
  and only there.
- Secrets come from test env vars. Never real credentials, never committed.
- **Ports are allocated, not assumed.** `spec.md` names two non-overlapping
  ranges: one the E2E suite binds, one reserved for the `ui-auditor`'s instance.
  They run against the same code at different times and must never contend for a
  port. Tell builders which ports they *may* use — a builder told only what to
  avoid may find the gate itself unrunnable and fall back to reasoning about
  tests it never executed.

## Flake policy

**A test that passes only on retry is a failing gate.** Do not add retries,
`sleep`, or `--retries=2` to get green. Flake means the app or the test has a
real race — fix the cause:

- Wait on a condition (element visible, response received, row present), never
  on a duration.
- No shared mutable state between tests; each creates what it needs.
- Order-independent. If the suite fails when shuffled, it's broken.

When the race lives in a file the task in flight cannot write — `e2e/` owned by
another builder — diagnosing it with artifacts is still this iteration's job;
the fix routes to the owner (§B step 5 attribution) and burns no loopbacks
here. "Flaky" without a diagnosis is a failing gate, not a category.

Quarantining a known-flaky test is allowed once, with the reason recorded in
`report.md` and the test still listed as unresolved. Silently deleting a failing
test is never allowed.

## Position in the loop

Runs after the cheap machine gates (unit, typecheck, lint, build) and before the
audits — no point auditing an app whose flows don't work. The parent runs the
command from `spec.md` and reads real output; a builder's claim that E2E passes
is not evidence.

## Reporting

The parent records in `report.md`: command, passed/failed/skipped counts, total
duration, and the acceptance-criteria coverage map. A skipped test is reported as
skipped, never folded into the pass count.

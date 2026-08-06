---
name: build
description: >-
  Build a production-ready feature, app, or multi-task goal from a short
  description. Small changes run one enforced loop: spec and pass/fail bars
  first, implement, machine gates (unit tests, typecheck, lint, build, E2E
  against a real server and database), then read-only OWASP Top 10:2025 and
  WCAG 2.2 AA auditors, looping until green. Bigger goals become an epic: the
  goal is decomposed into a persistent work graph (runs/<epic-id>/graph.jsonl)
  of dependency-ordered tasks, then drained autonomously on a dedicated epic
  branch — one task at a time through the same gates, one commit per task,
  discovered work filed as new tasks for later, until the epic is done or a
  stop condition fires. Use whenever the user asks to build, implement, or ship
  an app, feature, frontend, backend, or full-stack change and wants it
  production-ready, tested, e2e tested, reviewed, secure, accessible, or
  pixel-perfect — even if they never say "loop", "graph", "epic", or "audit".
license: MIT
---

# Build

Short description in, verified code out. The loop is the deliverable, not the
first draft. Nothing ships on "looks done" — it ships on parsed verdicts.

**Never write implementation code before the bars exist.** A build with no
verifier is a draft, and drafts are what this skill exists to prevent.

## 0. Gate — loop or epic?

Run the `decompose` gate. Score the seven signals there. Most tasks are a loop.

- **Loop (score 0–4)** — no subagents, no run directory, no branch, no work
  graph. Spec and bars inline, implement inline, run the machine gates (§G),
  then §A audits only if the change touches auth/data (security) or renders UI
  (a11y). Skip everything else below.
- **Epic (score 5–7)** — full-stack or multi-task work, parallel builders,
  read-only auditors, context that won't fit one window. Run Phases A–C.

Say which you picked and why, in one line. Don't build the epic because the
request sounded big. Before entering epic mode, state the estimated task count
and cost — roughly `tasks × (builders + conditional audits)` subagent runs; an
epic at the 15-task ceiling is a large multiple of a single loop build. For a
full-stack epic assume **both** audits on every task: a vertical slice touches
data and renders UI, so §B6's condition only bites for single-zone tasks.

**Probe dispatch once before Phase A.** Spawn one trivial subagent and check it
returns. Epic mode is delegation all the way down, and the "two consecutive
infrastructure/API errors" stop condition only fires after a task is claimed and
its builders are burned. If the probe fails, say so and offer the degraded run —
parent does Phase A and the machine gates inline — instead of discovering it
mid-drain. Audits are never part of a degraded run; see §A.

## Phase A — Plan (parent only, before any code)

### A0. Greenfield discovery — only when the stack isn't on disk

Fires only when both hold: the project has no stack to read (no manifest, no
source) **and** the request names none. In an existing repo the stack is a fact
on disk — asking is noise; skip to A1.

- Propose the boring default in plain words, one message: language, storage,
  how it runs. "Web app, TypeScript everywhere, SQLite so there's nothing to
  install, one command to run — fine?" Defaults-first: never a menu of
  frameworks, never a question that needs technical vocabulary to answer.
- One confirmation, then autonomy as before. This spends one of A1's two
  clarifying questions — greenfield stack choice is the canonical "wrong guess
  wastes the whole build".
- Record the confirmed stack plus a ~5-line architecture sketch (major pieces
  and what talks to what) in `spec.md`. Builders inherit it; no task re-derives
  it.

### A1. Spec and bars

Write `runs/<epic-id>/spec.md` — epic-level, shared by every task so no task
re-derives the contract. It must contain, concretely:

- **Acceptance criteria** — numbered, each checkable by a test.
- **API contract** — endpoints, payload shapes, error codes. Written *before*
  frontend and backend split, or they can't run in parallel.
- **Visual reference** — the pixel bar. One of: a design file/screenshot the user
  supplied, a URL to match, or a design spec you write and state back for
  confirmation. **"Pixel perfect" with no reference is not a bar** — degrade it
  to "matches the stated design spec" and say so.
- **Stack and commands** — exact test, typecheck, lint, build, and E2E commands.
- **E2E environment** — test database, migration and seed strategy, which builder
  owns `e2e/`. See `references/e2e-gate.md`.
- **Scope of audits** — which routes/flows the auditors must cover.

Ambiguity budget: at most 2 clarifying questions, asked together, only when a
wrong guess would waste the whole build. Otherwise pick the obvious default,
state it in `spec.md`, and proceed.

`spec.md` is the parent's to **refine** mid-run. When a gate or an audit surfaces
a contract detail the plan never settled — a validation limit, a new error code, a
clause that turns out to conflict with an audit bar — write it back in the same
iteration with a one-line reason. That keeps the contract and the code in step.
Adding capability nobody asked for is scope creep, not refinement: if the change
would add an acceptance criterion, it needs a task.

### A2. Work graph

Emit `runs/<epic-id>/graph.jsonl`: one epic record plus task records with
`deps`, `zone`, and `criteria[]`. Schema, ready-computation, and mutation rules:
`references/work-graph.md`.

- Every epic acceptance criterion maps to at least one task, or the graph is
  incomplete.
- Tasks are **vertical slices** — a user-visible increment that may touch both
  zones — not horizontal layers ("all backend" then "all frontend"). The outer
  loop is sequential; parallelism lives *inside* a task (§B step 4).
- Each task is completable in one dispatch: one deliverable, criteria checkable
  against a diff. If it isn't, split it.

### A3. Branch

Create or switch to `epic/<epic-id>` before touching anything. Never commit to
the default branch for the rest of the run. Never merge, never push — the merge
is the user's, proposed as text in `report.md`.

### A4. Bars first, then code

Per task, its acceptance tests are written before its implementation. They
fail; that's correct. A bar that can't fail isn't a bar. Every criterion maps
to at least one E2E test or is marked unit-only in `spec.md` with a reason.
Unmapped criteria fail the gate.

### A5. Commit the plan

Commit `spec.md` + `graph.jsonl` on the epic branch (`<epic-id>: plan`) before
the first dispatch — Phase B step 2 asserts a clean tree, and the plan must be
in the record before code exists. E2E flows in a dedicated final task (owned by
the `e2e/` owner), with unit/component bars per earlier task, is the intended
shape.

## Phase B — Dispatch loop

While ready tasks exist and bounds hold:

1. **Pick** the highest-priority ready task (`status: open`, every dep
   `closed`).
2. **Assert clean working tree.** Dirty → stop and report; never paper over it.
3. **Claim**: append `in_progress` to `graph.jsonl`.
4. **Implement.** Trivial and single-zone → inline. Otherwise delegate,
   in parallel where the task spans zones, contract already fixed in `spec.md`:
   - `backend-builder` — API, schema, auth, server tests
   - `frontend-builder` — UI, components, state, client tests
   Each prompt carries absolute paths, the contract, the task's `criteria[]`,
   and its zone memory (`zones/<zone>.md`). Nodes inherit nothing.
   **A parallel builder pair is one task, never two.** Two tasks dispatched at
   once share a working tree and therefore a commit, which breaks
   one-commit-per-task. When audit failures split by owner, file them as a single
   `zone: both` task — routing a failure to its owner picks the *builder*, not
   the task.
5. **Machine gates** (§G) — parent runs them. Failure → back to the owning
   builder with the actual error text, not a summary.
6. **Conditional audits** (§A) — `security-auditor` only if the task touched
   auth, data, or external input; `ui-auditor` only if it rendered UI.
7. **Adjudicate**: read `git diff` against the task's `criteria[]` — criteria
   written before the code, so this is not post-hoc rationalization.
8. **Close or loop back.** All green and criteria met → one commit with the
   task id in the message → **then** append `closed` carrying that sha. The
   close record cannot live inside the commit it names; amending to fold it in
   changes the very sha it just recorded. Let it ride in a
   `graph: close <id> @ <sha>` commit or in the next task's. Otherwise loop back
   (max 2 per gate), then it's a stop condition.
9. **File discovered work**: append new task records with `discovered-from`.
   Builders return it in `discovered[]`; the parent files it. **Filed, never
   worked in the same iteration** — that rule is what stops an autonomous run
   from sprawling.
10. **Zone memory**: builders appended their own durable facts; the parent
    appends auditors' `zone_facts` to `zones/security.md` / `zones/ui.md`.
11. **Route cross-zone contract changes now, not later.** A builder whose change
    alters what another zone depends on — a function signature, a new error code
    or status, a cookie or schema change — reports it, and the parent dispatches
    or files the other side's update in the same iteration. Ownership fences stop
    a builder from repairing what it broke on the other side of the fence, so an
    unrouted contract change is silent breakage, not isolation.

Then loop to 1. Between tasks there is no check-in — the epic runs unattended
until done, ceiling, or a stop condition.

## Phase C — Epic close

1. Full test suite once more — a regression here is a stop condition, not a
   footnote.
2. Full audit sweep: `security-auditor` + `ui-auditor` over all changed routes,
   regardless of per-task audits. Both verdicts must be `pass` to close the
   epic.
3. Append `closed` for the epic; write `runs/<epic-id>/report.md`.
4. Prune any `zones/*.md` past ~a page.
5. Print the **proposed** merge command. Never run it.

## §G. Machine gates — parent runs these, never a node

In order, on every iteration — cheap gates first, stop at the first failure:

1. unit/component tests
2. typecheck
3. lint
4. build
5. **E2E** — real server, real database, migrated from scratch, seeded.
   Bar and flake policy: `references/e2e-gate.md`

A node never reports its own tests as passing. The parent runs the commands and
reads the output.

**A test that passes only on retry is a failing gate.** Never add retries,
`sleep`, or loosened assertions to reach green — fix the race. Never delete a
failing test to close the loop.

## §A. Audit gates — read-only, structured

Only once machine gates are green. Per task: conditional (§B step 6). At epic
close: both, full scope. In loop mode: only if the change touches their scope.

- `security-auditor` — OWASP Top 10:2025. Bar: `references/security-gate.md`
- `ui-auditor` — WCAG 2.2 level AA + visual fidelity. Bar: `references/ui-gate.md`

Both are read-only by allowlist, both return
`{verdict, score, failures[{id, severity, clause, evidence, fix}]}`. The parent
parses `verdict` and branches on the field. Never on prose.

Route each failure to the node that owns the file. Security findings at
`severity: critical|high` block the build regardless of score.

**A fix is not done until its audit re-runs — a stale pass is not a pass.** This
is what the gate is for. A fix is written by the node that was just graded, under
pressure, in exactly the code the auditor flagged; fixes routinely introduce new
defects, sometimes worse than the one repaired. A one-shot audit doesn't merely
miss those — it launders a regression as a fix. Re-run over full scope after
every round. Resume the same auditor where the runtime allows: it keeps its
measurement setup and can compare against its own prior evidence, which is how it
catches regressions in its own findings. Give it the diff and tell it to be
sceptical of the changelog.

**The node that fixes a finding is never the only one testing it.** Its tests
carry the blind spot that produced the defect — a builder that fixes a focus bug
writes tests for the path it was already thinking about. The auditor's re-run is
the independent check; never substitute a builder's own green tests for it.

Auditors are the one role the parent may never fill itself. Machine gates and
even implementation can be inlined when delegation is unavailable; a verdict from
the author of the code is a different, weaker bar. Report it as not run.

## Bounds

- One task in flight at a time.
- One commit per task, never batched.
- 15 tasks closed per run — runaway backstop, not a target.
- `max_loopbacks`: 2 per gate. Then stop and report the failing clauses.
- Node types: 4. Parallel instances of one type count once.
- Each delegation carries an explicit stop condition, never "until done".
- Never commit to the default branch; never merge; never push.

## Stop conditions — halt, dispatch nothing further, report

- A task fails its gates twice (after the 2 loopbacks). Leave it `open` with
  notes on what's wrong; do not force a third pass.
- Any full-suite regression.
- A decision needs operator input: spec ambiguity, scope change, unsettled
  UX/semantics.
- Anything requiring a push, a config change, or files outside the project.
- Two consecutive infrastructure/API errors.
- The work needs a 5th specialty — re-run the `decompose` gate; never invent a
  node mid-run.

On any stop: report tasks closed, commits made, tasks filed, and the exact
failing clauses. **A failed gate reported honestly beats a passed gate that was
downgraded to make it pass.** Never relax a bar to close the loop; never mark
`pass` on a verdict the auditor didn't give.

## Done

Ship only when: machine gates green including E2E, epic-close audit verdicts
both `pass`, no unresolved `critical`/`high`. Then report, in this order:

1. What was built, in two sentences.
2. Tasks closed (id → commit sha), tasks left open or discovered for later.
3. Gate results — unit/typecheck/lint/build, E2E (passed/failed/skipped +
   acceptance-criteria coverage map), security verdict + score, UI verdict + score.
4. What was deliberately not done, any quarantined test, and any accepted-risk
   finding with its reason.
5. The proposed merge command.

## State

Run directory, `graph.jsonl`, zone memory, and the single-writer table:
`references/state.md` and `references/work-graph.md`.

## Org graph

Stable roles in `~/.claude/agents/` — the work graph in `graph.jsonl` is
per-epic and disposable; this is not (see
`decompose/references/graph-engineering.md`):

```
                    [parent — orchestrator]
             owns: gate runs, graph.jsonl, commits, adjudication
                   /      |        |       \
    backend-builder  frontend-builder  security-auditor(RO)  ui-auditor(RO)
          |               |                |                    |
      api/ + tests    ui/ + tests    security.json          ui.json
          ^               ^                |                    |
          +---------------+----------------+--------------------+
                        failures[], max 2 loopbacks
```

Auditors never fix what they find. Builders never grade their own work. The
parent never delegates gate-running or adjudication.

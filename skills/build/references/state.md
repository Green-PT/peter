# Build state

Epic mode only. In loop mode there is no run directory, no branch, no work
graph — just the repo.

## Run directory

```
runs/<epic-id>/
  spec.md            # epic-level bars, API contract, visual reference — parent writes once
  graph.jsonl        # append-only work graph — schema in work-graph.md
  log.jsonl          # append-only; parent + builders append, nobody edits
  security.json      # security-auditor verdict (latest; per-task history in log.jsonl)
  ui.json            # ui-auditor verdict (latest)
  shots/             # ui-auditor screenshots, <route>-<width>.png
  report.md          # final summary — parent only, only after the epic closes
```

`<epic-id>` is a short slug (`E-ratelimit`). A retry is a new run that
references the old one in `spec.md`, never an overwrite. The run directory is
committed with the epic branch — the plan of record travels with the code.

Code goes in the repo, not the run directory. The run directory holds the
*process* — spec, work graph, evidence, verdicts — so a failed epic is
debuggable and **resumable** after the subagent contexts are gone: fold
`graph.jsonl` and the ready tasks are exactly where the run left off.

## Single-writer table

| Path | Writer | Readers |
|---|---|---|
| `spec.md` | parent | all |
| `graph.jsonl` | parent (append-only) | all |
| repo backend paths | backend-builder | all |
| repo frontend paths | frontend-builder | all |
| `e2e/` | the builder named in `spec.md` (UI → frontend, API-only → backend) | all |
| `security.json` | parent, from security-auditor's return | parent |
| `ui.json`, `shots/` | parent, from ui-auditor's return | parent |
| `report.md` | parent | — |
| `log.jsonl` | parent + builders (append) | all |
| `zones/backend.md`, `zones/frontend.md` | the owning builder | that node, parent |
| `zones/security.md`, `zones/ui.md` | parent, from auditor `zone_facts` | that auditor, parent |
| git commits, branches | parent — one commit per task, epic branch only | all |

Two nodes never write one path. Frontend and backend split on directory, fixed
in `spec.md` before either starts — that's what makes them safe in parallel.

The fence isolates *writes*, not *consequences*. A change on one side can break a
file on the other — an async'd function whose caller lives in `e2e/`, a new error
code with no client mapping — and the owner of the broken file has no idea it
happened. Whoever makes such a change reports it; the parent routes the other
side's update in the same iteration (§B step 11). Never reach across the fence to
fix it yourself.
`e2e/` crosses both zones, so exactly one builder owns it; the other reads it
and never edits. See `e2e-gate.md`.

Builders never run `git commit` — the parent commits after adjudication, task
id in the message. Auditors are read-only by allowlist, so they cannot append
to `log.jsonl`; the parent logs their start/end around the delegation and
writes their verdict files from the returned JSON.

## Zone memory

`zones/` lives beside `runs/`, not inside one — it is cross-epic state:

- `zones/backend.md`, `zones/frontend.md` — appended by their builder.
- `zones/security.md`, `zones/ui.md` — appended by the parent from the
  auditors' `zone_facts` return field.

Durable domain facts only — the stack's conventions, where auth lives, which
component library, recurring gotchas, the threat model. Never run-specific
state. The parent prunes each past ~a page.

## Handoff

Every prompt carries absolute paths. Nodes inherit nothing — not cwd, not prior
conversation, not the epic's history:

> Read `runs/E-ratelimit/spec.md` and `zones/backend.md`. Task T2, criteria:
> ["429 responses carry Retry-After and X-RateLimit-* headers"]. Implement §3.2
> of the contract. Write only under `api/`. Append start/end to
> `runs/E-ratelimit/log.jsonl`. Return the JSON contract from your agent file.
> Stop when your tests for T2 pass; do not touch `web/`, do not commit.

## Failure isolation

A failed node leaves its output absent, not half-written. Auditors return their
verdict in the final message and let the parent write the JSON — one round
trip, no partial files that a later `pass` check might misread. A task that
stops mid-flight leaves its last `graph.jsonl` record `in_progress`; the next
run sees it, asserts the tree is clean, and re-dispatches or reports.

# Work graph — `runs/<epic-id>/graph.jsonl`

The per-epic work graph: what needs doing right now, dependency-ordered,
append-only, committed. The org graph (stable roles) lives in
`~/.claude/agents/`; terminology and the patterns adopted here:
`decompose/references/graph-engineering.md`. This file is the runtime contract.

## Records

One JSON object per line. Append-only — a status change is a **new full record
for the same `id`; the latest record for an id wins**. Nobody edits or deletes
a line; history is the audit trail.

*Full* is load-bearing. The fold keeps only the latest record, so a partial one —
`{"id":"T1","status":"in_progress"}`, or `criteria` shortened to a pointer —
silently deletes the `criteria[]` that §B7 adjudicates the diff against. Repeat
the whole payload every time; partial records are illegal.

A `closed` record is appended **after** its commit exists, and therefore rides in
a later commit — it cannot be inside the commit whose sha it carries.

```jsonl
{"id":"E-ratelimit","type":"epic","title":"Rate limiting","status":"open"}
{"id":"T1","type":"task","parent":"E-ratelimit","deps":[],"zone":"backend","prio":1,"status":"open","criteria":["429 after N reqs in window"]}
{"id":"T1","type":"task","parent":"E-ratelimit","deps":[],"zone":"backend","prio":1,"status":"in_progress","criteria":["429 after N reqs in window"]}
{"id":"T1","type":"task","parent":"E-ratelimit","deps":[],"zone":"backend","prio":1,"status":"closed","commit":"a1b2c3d","criteria":["429 after N reqs in window"]}
{"id":"T3","type":"task","parent":"E-ratelimit","deps":[],"zone":"backend","prio":2,"status":"open","discovered-from":"T1","criteria":["conn pool does not leak under load"]}
```

Fields:

| Field | Req | Meaning |
|---|---|---|
| `id` | yes | short, unique in the epic (`T1`…); epic ids `E-<slug>` |
| `type` | yes | `epic` \| `task` |
| `parent` | tasks | the epic id |
| `deps` | tasks | ids that must be `closed` before this is ready |
| `zone` | tasks | `backend` (anything that doesn't render — API, CLI, library, pipeline, infra) \| `frontend` (anything that renders) \| `both`. Path globs per zone are in `spec.md`; when they overlap, `both` means one builder owns the whole task |
| `prio` | no | 1 high … 3 low; default 2 |
| `status` | yes | `open` \| `in_progress` \| `closed` |
| `criteria` | tasks | acceptance criteria — written at filing, before any code |
| `commit` | on close | the task's single commit sha |
| `discovered-from` | discovered | the task whose run surfaced this |
| `note` | no | one line of context |

`criteria` are checkable against a diff. A task whose criteria can't fail
isn't ready to file.

## Ready

Fold the file: latest record per id. A task is **ready** iff
`status == "open"` and every id in `deps` folds to `closed`. Dispatch order:
lowest `prio`, then file order. One task in flight at a time — `ready` feeds a
sequential loop, not a fan-out; parallelism lives inside a task (two builders,
one contract).

## Mutation — bounded, logged

The work graph is dynamic; the org graph is not. The parent may, as evidence
arrives:

| Evidence | Move |
|---|---|
| Scope expands | append a new task (`discovered-from` set); if it needs a 5th *specialty*, stop — re-run the `decompose` gate |
| Tasks converge / one becomes moot | append `closed` with `note` `"merged into <id>"` or `"moot: <why>"` — never delete the line |
| Task fails its gates twice | leave `open` with a `note`; stop condition |
| Priority shifts | append the task with a new `prio` |

Every mutation is one appended line (it *is* the log of structural change) plus
the normal `log.jsonl` event. Never rewrite roles, tools, or models mid-run —
org-graph changes are a redeploy.

## Discovered work

Builders return `discovered[]` — one line per adjacent defect or opportunity
they did **not** touch. The parent files each as a task record with
`discovered-from` and criteria, in the same iteration it was reported.
Filed, never worked in the iteration that found it. It competes on `prio` like
any other task, and may reasonably outlive the epic unworked — the report
lists what's left open.

## Zone memory

`zones/backend.md`, `zones/frontend.md` — appended by their builder;
`zones/security.md`, `zones/ui.md` — appended by the parent from auditor
`zone_facts`. Durable domain facts only, never run-specific state; parent
prunes past ~a page. Cross-epic — this is what makes run 300's auditor worth
more than run 1's. Details: `references/state.md`.

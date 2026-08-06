# honey-graph-engineering

Claude Code `/build` skill with autonomous **epic mode**, plus the four specialist
subagents it dispatches.

Big goals are decomposed into a persistent work graph
(`runs/<epic-id>/graph.jsonl`, append-only) and drained on an `epic/<id>` branch —
one task at a time through the same machine gates (unit, typecheck, lint, build,
e2e against a real server and database), then read-only security and UI audits,
one commit per task, discovered work filed as new tasks.

Small changes skip all of it and run one enforced loop.

## Layout

```
skills/build/SKILL.md            the loop + epic orchestration
skills/build/references/         work-graph, state, e2e/security/ui gate specs
agents/{backend,frontend}-builder.md   zone-fenced implementers
agents/{security,ui}-auditor.md        read-only verdict-only auditors
install.sh                       sync with ~/.claude
```

Zones are defined by what the code does, not where it sits: `backend-builder`
owns everything that doesn't render — API, CLI, library, pipeline, infra —
and `frontend-builder` owns everything that does. Where a framework co-locates
both in one file, the task goes to one builder; the write fence is what makes a
parallel pair safe, and a shared file has no fence.

## Install

```bash
./install.sh
```

`~/.claude` is not version-controlled; this repo is the tracked copy.
`./install.sh pull` copies the other way, `./install.sh check` reports drift.

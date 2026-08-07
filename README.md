# honey-graph-engineering

Claude Code `/build` skill with autonomous **epic mode**, plus the four specialist
subagents it dispatches.

Big goals are decomposed into a persistent work graph
(`runs/<epic-id>/graph.jsonl`, append-only) and drained on an `epic/<id>` branch —
one task at a time through the same machine gates (unit, typecheck, lint, build,
e2e against a real server and database), then read-only security and UI audits,
one commit per task, discovered work filed as new tasks.

Small changes skip all of it and run one enforced loop.

[Honey](https://github.com/Green-PT/honey-for-devs) is the house standard:
builders write the minimum code that satisfies the spec (Lever 1), durable
prose stays terse (Lever 2), and every subagent return is an
[ESON](https://github.com/Green-PT/honey-eson) handoff (Lever 3) — the parent
branches on fields and treats declared counts as truncation checksums. ESON is
the message format only; `graph.jsonl` stays JSONL.

## Layout

```
skills/build/SKILL.md            the loop + epic orchestration
skills/build/references/         work-graph, state, eson wire format, e2e/security/ui gate specs
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

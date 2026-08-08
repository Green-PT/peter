<p align="center"><img src="assets/icon.svg" width="72" alt="a star work graph: one red parent node, four specialist nodes"></p>

# peter

**Autonomous epic builds for Claude Code — graph engineering with the bars
built in.** Describe a goal; `/build` turns it into a persistent work graph and
drains it unattended: every task through real machine gates and read-only
security and accessibility audits, one commit per task, until the epic closes
or a stop condition hands control back. Not a framework, not a runtime — a
skill, four agent files, and a JSONL contract. The parent session is the
runtime.

Free and open source, [MIT-licensed](LICENSE). Concretely: the Claude Code
`/build` skill with autonomous **epic mode**, plus the four specialist
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

## Why "peter"

Named for [Peter Steinberger](https://x.com/steipete), whose July 2026
question — "Are we still talking loops or did we shift to graphs yet?" —
sparked the graph-engineering framing this repo implements: a stable org graph
of specialist roles, a per-epic work graph of dependency-ordered tasks. The red
node in the icon is his lobster 🦞. No affiliation or endorsement — just credit
for the frame.

## License

[MIT](LICENSE). Use it, fork it, ship with it.

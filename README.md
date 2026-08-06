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
```

## Install

```bash
cp -R skills/build ~/.claude/skills/build
cp agents/*.md ~/.claude/agents/
```

`~/.claude` is not version-controlled; this repo is the tracked copy. Re-copy in
either direction after editing.

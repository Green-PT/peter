# ESON — the return wire format

Every node return in this system is ESON v1.1 (Honey Lever 3 —
[spec](https://github.com/Green-PT/honey-eson),
[honey-for-devs](https://github.com/Green-PT/honey-for-devs)). ESON is the
**message** format, never the **state** format: `graph.jsonl` stays JSONL,
dispatch prompts stay plain text.

## Grammar (condensed)

```
!eson/1                      header, first line, exact
name=cell                    scalar
name[N]                      scalar array — N lines follow, one cell each
name[N]{f1,f2}               record array — N rows follow, cells TAB-separated
```

- Names: `[A-Za-z_][A-Za-z0-9_.-]*`, unique at top level. Document ends with LF.
- A cell is a bare string unless it needs JSON: JSON-quote any cell that
  contains a TAB/CR/LF, has leading/trailing whitespace, or starts with `"`
  `[` `{` — a selector like `[data-testid=x]` must be quoted or the decoder
  rejects the document. `null`/`true`/`false` and numbers decode typed; quote
  them to keep them strings.
- Empty array: `name[0]`, no rows. Never emit `name{}` single records — this
  system's shapes are scalars and arrays only.

## Emit rules (nodes)

- Output the payload only — no preamble, no markdown fence, nothing after.
- `[N]` must equal the rows you emitted. Count before returning; a mismatch is
  a corrupted return.
- Address rows by stable `id` (`F1`…`Fn`), never by position.
- Safety carve-out: findings touching auth, money, migrations, deletes, or
  data loss keep full `clause` and `evidence` text — never slugged, never
  truncated.

## Read rules (parent)

- Branch on fields (`status=`, `verdict=`), never on prose.
- Treat every `[N]` as a checksum. Count mismatch, missing header, or ragged
  rows = malformed return.
- A malformed return is a failed dispatch: re-request once with the parse
  error verbatim; a second malformed return burns a gate loopback.
- Save auditor returns **verbatim** as `runs/<epic-id>/security.eson` /
  `ui.eson` — never hand-transcode to JSON; transcription is where fields
  drift.

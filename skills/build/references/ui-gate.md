# UI gate — WCAG 2.2 level AA + visual fidelity

Two bars, one auditor: it can be reached, and it looks right. Both need the app
actually rendered — audit the running page, not the source. Use browser tools:
`read_page` for the accessibility tree, `computer` for keyboard and screenshots,
`resize_window` for reflow and dark mode.

**Getting the app up is the parent's job, not a guess.** `spec.md` names the run
command, the base URL, and a port range reserved for this audit — separate from
the E2E suite's, so the two never contend. The parent passes all three in the
dispatch. Missing them, the auditor returns `app unreachable` and the UI bar was
not applied; that is a gate failure to report, never a quiet pass.

Report findings with a selector or file:line plus what you observed. Never flag a
criterion you did not check — mark it `not_applicable` instead.

## Perceivable

- **1.1.1** Every non-text element has a text alternative; decorative images are
  `alt=""` or `aria-hidden`, not described.
- **1.3.1** Structure is semantic: headings are `h1–h6` in order, lists are lists,
  tables have `th`, form controls have programmatic labels. Not styled `div`s.
- **1.3.2** DOM order matches visual reading order.
- **1.3.3** Instructions never rely on shape, size, or position alone ("the button
  on the right").
- **1.3.4** Works in both portrait and landscape; no orientation lock.
- **1.3.5** Inputs collecting user data use correct `autocomplete` tokens.
- **1.4.1** Color is never the only carrier of meaning (error states need text or
  icon too).
- **1.4.3** Contrast ≥ **4.5:1** for text, **3:1** for text ≥18.66px bold / 24px.
  Check every state: default, hover, focus, disabled, placeholder, and both themes.
- **1.4.4** Text scales to 200% without loss of content or function.
- **1.4.5** No images of text (logos excepted).
- **1.4.10** Reflow: no horizontal scrolling at 320px width / 400% zoom.
- **1.4.11** Non-text contrast ≥ **3:1** for UI component boundaries, icons, focus
  indicators, and chart marks.
- **1.4.12** Survives text-spacing overrides (line-height 1.5×, paragraph 2×,
  letter 0.12em, word 0.16em) without clipping.
- **1.4.13** Hover/focus popups are dismissible, hoverable, and persistent.
- **1.2.x** Media only: captions and audio description where audio/video exists.

## Operable

- **2.1.1** Every function reachable and operable by keyboard alone.
- **2.1.2** No keyboard trap — modals, embeds, and date pickers release focus.
- **2.1.4** Single-character shortcuts can be turned off or remapped.
- **2.2.1 / 2.2.2** Time limits adjustable; auto-updating or moving content can be
  paused, stopped, or hidden.
- **2.3.1** Nothing flashes more than 3×/second.
- **2.4.1** A skip link or landmark structure bypasses repeated blocks.
- **2.4.2** Every page has a unique, descriptive `<title>`.
- **2.4.3** Focus order is logical; modals trap and restore focus correctly.
- **2.4.4 / 2.4.6** Link purpose clear in context; headings and labels descriptive.
  No bare "click here" or "read more".
- **2.4.5** More than one way to find a page (nav + search/sitemap).
- **2.4.7** Focus is always visible — never `outline: none` without a replacement.
- **2.4.11 Focus Not Obscured (new in 2.2)** — the focused element is not hidden
  behind sticky headers, footers, or cookie bars.
- **2.5.1 / 2.5.2** No path-based gestures required; actions fire on up-event and
  are abortable.
- **2.5.3** Accessible name contains the visible label text.
- **2.5.4** Motion-actuated features have a non-motion alternative.
- **2.5.7 Dragging Movements (new in 2.2)** — anything draggable (sliders,
  reorder, kanban) has a single-pointer non-drag alternative.
- **2.5.8 Target Size (new in 2.2)** — pointer targets ≥ **24×24 CSS px**, or
  adequately spaced. Check icon buttons, close buttons, and table row actions.

## Understandable

- **3.1.1 / 3.1.2** `<html lang>` set; inline language changes marked.
- **3.2.1 / 3.2.2** Focus or input alone never triggers a surprise context change
  (no auto-submit on select).
- **3.2.3 / 3.2.4** Navigation order and component naming consistent across pages.
- **3.2.6 Consistent Help (new in 2.2)** — help/contact appears in the same
  relative order on every page that has it.
- **3.3.1 / 3.3.2** Errors identified in text and tied to their field; labels and
  instructions present — placeholder is not a label.
- **3.3.3** Error messages suggest the correction.
- **3.3.4** Legal, financial, and data-deleting submissions are reversible,
  checked, or confirmed. Audit the confirmation step, not the deletion — stop
  before the irreversible click, or act only on a record you created yourself.
  The database you are driving is the one the E2E gate reads next.
- **3.3.7 Redundant Entry (new in 2.2)** — information already entered in the same
  process is auto-populated or selectable, not retyped.
- **3.3.8 Accessible Authentication (new in 2.2)** — no cognitive function test
  (puzzle, memory, transcription) without an alternative. Password fields must
  allow paste and password managers.

## Robust

- **4.1.2** Every custom control exposes correct name, role, value, and state.
  Prefer native elements over ARIA. Broken ARIA is worse than none.
- **4.1.3** Status messages announced via live regions without moving focus.
  (**4.1.1 Parsing was removed in WCAG 2.2** — do not report it.)

## Visual fidelity

Bar is whatever `spec.md` names as the reference. Compare rendered output to it:

- Spacing, type scale, and color read from tokens/variables — no magic numbers
  scattered inline.
- Breakpoints in the spec all render without overflow or overlap: 320, 768, 1280.
- States implemented, not just the happy default: hover, focus-visible, active,
  disabled, loading, empty, error.
- Light and dark themes both correct if the app has a toggle.
- No layout shift on load; no scrollbar-induced jump.
- Screenshot each audited route at each breakpoint as evidence.

If the spec's reference is a design spec rather than a pixel source, judge
against the spec's stated values and say so — do not invent a pixel diff.

## Verdict

```json
{"verdict":"pass|fail","score":0,
 "failures":[{"id":"1.4.3","severity":"critical|high|medium|low",
              "clause":"contrast 4.5:1","evidence":"Button.tsx:18 — #9aa0a6 on #fff = 2.8:1",
              "fix":"darken to #5f6368 (4.6:1)"}],
 "not_applicable":["1.2.1"]}
```

`fail` if any level A criterion fails, or any `critical`/`high`.

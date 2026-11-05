# Issue labels — the scheme, and the one thing that decides it

> **The labels are not ours alone.** A board (Observatory's fleet board, or any tool that reads `gh`) renders lanes
> by label **name**. So a label is an interface with an external consumer: renaming one, or inventing a
> near-duplicate (`stage:ready`, `in-progress`, `todo`), silently drops cards into the board's `Unlabeled` lane.
> **Never rename or invent a Stage, Type, Priority or modifier label.** Create the set with
> `scripts/setup-labels.sh`; it only creates or refreshes, never renames or deletes.

## Four axes. At most one label from each.

| Axis | Labels | Rule |
| --- | --- | --- |
| **Stage** | `DesignDoc` `DesignReview` `ReadyToImplement` `ReadyToTest` `ReadyToVerify` `Verified` | **Exactly one, or none.** None = untriaged (the board's `Unlabeled` lane). |
| **Type** | `bug` `enhancement` `chore` `epic` `security` `documentation` | One. A board shows the first match in that order, so an `epic` must not also carry `enhancement`. |
| **Area** | `area:<name>` — **this repo's own list, below** | One. Local only; boards ignore these. |
| **Priority** | `north-star` | Optional and rare. Has a test (below). |

**Modifiers, only when true:** `Blocked` plus its reason — `needs-decision` (an owner call; never when a recorded
decision already answers it) or `needs-hardware` (only when no simulator, sandbox copy or fixture can show it);
`auto-filed` (an automated agent filed it, not a human); `before-public-release` (a **gate**, not a stage: one list
of everything that must happen before the repo's visibility changes).

**Board chips** — `URGENT`, `Suspended`, `TestedMac` / `TestediOS` / `TestedWindows`, `wontfix` — are free and
externally read. Leave them alone.

## There is no done stage. Closed is done.

`Verified` exists because a board has the lane. **Do not park an issue there**: close it the same day its check
passes, with a closing comment in exactly this shape:

```
Root cause: <one or two sentences — the mechanism, not the symptom>
Fix: <sha(s)>
Verified: <how, where (host/device/OS), and the NUMBERS you read>
```

A failed verification sends the **same** issue back to `ReadyToImplement`; it does not open a new one.

## Which stage, and what moves it

| Stage | Enter when | Leave when | Time-box |
| --- | --- | --- | --- |
| *(none)* | just filed | the filing session sets Type + Stage + Area | same session |
| `DesignDoc` | real work, fix **not** yet known | the doc lists build units, each naming its failing test → `ReadyToImplement`; or close as not planned | ~2 working days, one review round |
| `DesignReview` | only an owner decision is missing | the decision is recorded (a `D<n>` number) → `ReadyToImplement` | ~1 day |
| `ReadyToImplement` | fix known and agreed, sized for **one** agent lane | landed with a test seen failing first, gate green → `ReadyToVerify` | ≤3 lanes at once |
| `ReadyToTest` | *optional* — only if your repo has a separate test lane between build and verify | independent tester signs off → `ReadyToVerify` | — |
| `ReadyToVerify` | committed and deployed, **not yet verified on a real host/device** — *a green build is not a working feature* | the verifier runs the issue's `Verify:` line, posts the numbers, closes | ~24 h |

- **FastTrack:** a fix under ~1 h, in one file, with a known cause, skips `DesignDoc`. Write
  `FastTrack: <reason>` in the body. A line, not a label.
- **Owner-only checks** (something only the human can do: a real device in hand, a real account, a destructive
  real-host action) collect as lines on **one** owner-sitting issue in `ReadyToVerify`, rather than as many
  issues waiting on the same person.
- **The label moves when the work moves**, by the session doing the work. A board is only as true as its
  least-maintained label: one audit found a third of issues closed in a month still labelled `ReadyToImplement`.

## `north-star` — the only priority label, and it has a test

Write your project's north star as one sentence, in the owner's words, here:

> *"<the one sentence>"*

Apply `north-star` only if the issue stands between the project and that sentence. It exists to answer one
question — `gh issue list --label north-star` — and if it grows past ~15 open issues it has stopped discriminating
and should be re-cut rather than trusted.

## Findings go to their owner, not to a new issue

A review or audit finding you will not fix now goes onto the **existing issue that owns its class**, as a checklist
line. Open a new issue only when nobody owns the class — and then that issue *is* the owner. Watch filed-vs-closed
per week; a backlog that only grows is a signal, not a sign of diligence.

## This repo's areas

| Label | Covers |
| --- | --- |
| `area:<name>` | <what> |

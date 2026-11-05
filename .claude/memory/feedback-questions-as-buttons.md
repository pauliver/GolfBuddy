---
name: feedback-questions-as-buttons
description: Owner decisions are asked one at a time — 1–2 paragraphs from the user's view, then buttons with the recommended option first — and recorded as numbered decisions
metadata:
  type: feedback
---

Open questions go to the owner **one at a time** (skill `owner-question`):
1. A **1–2 paragraph framing** from the user's point of view: the *use* (what the user experiences), the
   *architecture* (how it works underneath), the *performance/cost* challenge.
2. The question as **buttons** (AskUserQuestion): each option 1–2 sentences on the choice, its UX impact and its
   cost impact; the **recommended option first, marked "(Rec.)"**.

**Why:** the owner asked for exactly this and reads on a phone (Observatory fans the session to every device), so a
question must make sense with nothing else on screen. Batches of four were tried first and replaced.

**How to apply:** grep the decision log first — never re-ask a decided question. Ask decisions LAST, after all work
that doesn't depend on them. Record each answer immediately as `D<n>` with the owner's words and the date. Subagents
never ask the owner; they list open questions in their report.

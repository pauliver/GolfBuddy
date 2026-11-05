---
name: feedback-measure-dont-theorise
description: An unmeasured cause is a question, not a finding — measure before asserting, name the competing explanation, and say NOT DIAGNOSED rather than guess; "flaky" is never a diagnosis
metadata:
  type: feedback
---

State a hypothesis as a question until you have measured it. Write down the competing explanation and the measurement
that would separate them; if you can't, the answer is **NOT DIAGNOSED**. Never write an unmeasured cause into a commit
message or an issue. "Flaky" is never a diagnosis — name the mechanism, or re-run under deliberate load and COUNT.

**Why:** over two days in one repo, every causal hypothesis asserted without measuring turned out to be wrong; a
network-mount probe documented as blocking "tens of seconds" actually wedged a terminal for fifteen minutes.

**How to apply:** an unexplained wait is a measurement not yet taken — check the runaway process, CPU time, load and
backups before blaming the code. Tag findings MEASURED or REASONED. Cross-check any number against a fact the tool
did not produce. Measure the thing, not its proxy.

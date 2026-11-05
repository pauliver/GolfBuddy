---
name: Work item
about: A bug, feature or chore. One lane of work, verifiable by someone who did not build it.
labels: []
---

<!--
Labels (exactly one of each; see docs/issue-labels.md — names are read by external boards, never invent new ones):
  Stage: DesignDoc | DesignReview | ReadyToImplement | ReadyToVerify      Type: bug | enhancement | chore | epic | security | documentation
  Area:  area:<one>                                                        Priority (rare): north-star
A fix under ~1h, in one file, with a known cause may skip DesignDoc: write "FastTrack: <reason>" below.
-->

## What and why
<!-- What is wrong or missing, from the USER's point of view. Numbers if you have them (measured, with how). -->

## Evidence
<!-- Logs, screenshots, the command you ran and what it printed. Tag each claim MEASURED or REASONED. -->

## Done when
<!-- Each line checkable. Name the test that must exist and must FAIL before the fix. -->
- [ ] A test that fails without the fix: `<test name>`
- [ ] The gate is green (`scripts/run-full-tests.sh`), quoted with host + OS
- [ ] Verify: <how a real host / device / user path proves it — the exact steps and the number to read>

## Docs to read / update
<!-- The design doc that fixes the what/why, and any doc this changes. -->

## Out of scope
<!-- What NOT to touch; files another lane owns. -->

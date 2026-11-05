---
name: feedback-verify-on-the-real-host
description: A green build is not a working feature — done means observed on the real host/device through the user's path; report "verified by <method>" or "NOT yet verified"
metadata:
  type: feedback
---

**A clean build and a green suite prove the tree, not the product.** Close the loop with at least one runtime
observation of the real path the user takes, and say which: a screenshot you actually looked at, a state dump, a log
line, a measured number. Report **"verified by <method>"** or **"NOT yet verified — needs <X>"**. Committed but not
verified = `ReadyToVerify`.

**Why:** the single most common trust failure across the owner's repos — about 25 "it may not have worked"
corrections in one repo alone; a feature that was "built, wired and two-OS green" while every production call failed;
"WORKING MEANS GETTING INTO GAME EVERY TIME. NEVER STOP AT THE MENUS."

**How to apply:** `ok: true` is not proof the state changed — compare before and after. A deploy is proved by a new
capability, not a version string. Manufacture the event (simulator, sandbox copy, second instance) rather than wait
for it. Never verify your own implementation — a different agent signs off.

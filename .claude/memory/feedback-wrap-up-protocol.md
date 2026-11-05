---
name: feedback-wrap-up-protocol
description: "Wrap up / what's next / are we done" is answered by RUNNING five checks — pushed, memories, issues, fresh-eyes review, nothing stray — and saying plainly what is not done
metadata:
  type: feedback
---

When the owner asks "[next steps or wrap up protocol] what's next or are we done for now?", answer each point with
where it stands, then what's next (skill `wrap-up`; mechanical half: `scripts/wrap-up-check.sh`):
1. All work committed and pushed.
2. All memories saved (in the repo) and pushed.
3. GitHub issues updated or closed (stages moved; closed with Root cause / Fix / Verified).
4. A fresh-eyes review of the work done: performance, blocking I/O, duplicate code paths, divergence from the north
   star (skill `review-fresh-eyes`), findings fixed test-first or filed on their owning issue.
5. No worktrees to merge or clean up, no rogue branches (local or origin), no stashes.

**Why:** the owner typed this checklist 44 times before it became a skill. A stretch isn't done until another session,
on another machine, can pick it up from GitHub alone.

**How to apply:** run the checks for real (`git status`, `git log origin/<b>..<b>`, `git worktree list`,
`git ls-remote --heads origin`, `git stash list`, the open issues) before answering; never from memory.

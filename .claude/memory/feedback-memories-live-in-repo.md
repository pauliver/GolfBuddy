---
name: feedback-memories-live-in-repo
description: Every memory about this project goes in .claude/memory/ in the repo and is committed; machine-local memory holds only a pointer
metadata:
  type: feedback
---

Every memory about this project lives in **`.claude/memory/`** in this repo, indexed in `MEMORY.md`, and committed.
The machine-local `~/.claude/projects/<dir>/memory/` holds only a pointer back here (or is symlinked to this folder).

**Why:** the owner works from several machines and a phone. A memory only one machine can read makes that machine
confident and the others wrong — a correct branch-promotion rule once sat in one laptop's user-level memory while two
in-repo docs told every other machine to push to `main`.

**How to apply:** write the file, add one index line, commit (check what you stage — memory edits get swept by a
blind `git add -A`). In a worktree, write to the worktree's `.claude/memory/`. Correct a wrong memory at the memory,
the same day; mark superseded ones rather than deleting them. Related: [[feedback-wrap-up-protocol]].

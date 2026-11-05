#!/usr/bin/env bash
# =====================================================================================================================
#  wrap-up-check.sh — the mechanical half of the Wrap-Up Protocol. Answers "are we done for now?" with FACTS.
#
#  A stretch of work is not done until another session — on another machine, or the owner on a phone — can pick it
#  up. This prints each check with OK / NOT DONE so the answer is measured, never remembered.
#
#  Usage: scripts/wrap-up-check.sh [base-branch]     (default: the remote's default branch)
#  Exit:  0 when every mechanical check is OK, 1 otherwise.
#
#  It does NOT do the two judgement items (memories saved; a fresh-eyes review of the work). Those are in
#  docs/way-of-working.md §Wrap-up and the /wrap-up skill.
# =====================================================================================================================
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2

base="${1:-$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')}"
base="${base:-main}"
branch="$(git branch --show-current)"
fail=0
ok()  { printf '  OK        %s\n' "$*"; }
bad() { printf '  NOT DONE  %s\n' "$*"; fail=1; }

git fetch -q --prune origin 2>/dev/null || bad "git fetch failed (offline?) — remote checks below are stale"

echo "1. Committed and pushed"
dirty="$(git status --porcelain | wc -l | tr -d ' ')"
(( dirty == 0 )) && ok "working tree clean" || bad "$dirty uncommitted path(s): git status"
if git rev-parse -q --verify "origin/$branch" >/dev/null; then
  ahead="$(git rev-list --count "origin/$branch..$branch")"
  (( ahead == 0 )) && ok "$branch is pushed" || bad "$branch is $ahead commit(s) ahead of origin/$branch"
else
  bad "$branch has no upstream on origin"
fi

echo "2. No stray work"
wt="$(git worktree list | wc -l | tr -d ' ')"
(( wt <= 1 )) && ok "no extra worktrees" || bad "$((wt-1)) extra worktree(s): git worktree list"
st="$(git stash list | wc -l | tr -d ' ')"
(( st == 0 )) && ok "no stashes" || bad "$st stash(es): git stash list"
locals="$(git for-each-ref --format='%(refname:short)' refs/heads | grep -vxE "$base|$branch|Next|main" || true)"
[[ -z "$locals" ]] && ok "no extra local branches" || bad "local branches: $(echo $locals)"
remotes="$(git ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's#refs/heads/##' \
           | grep -vxE "$base|Next|main|ReleaseCandidate-.*" || true)"
[[ -z "$remotes" ]] && ok "no extra branches on origin" || bad "origin branches: $(echo $remotes)"

echo "3. Issues (review by hand — stage labels must match reality)"
if command -v gh >/dev/null; then
  for stage in ReadyToImplement ReadyToVerify DesignDoc; do
    n="$(gh issue list --label "$stage" --state open --limit 500 --json number -q 'length' 2>/dev/null || echo '?')"
    printf '            %-17s %s open\n' "$stage" "$n"
  done
  un="$(gh issue list --state open --limit 500 --json labels \
        -q '[.[] | select([.labels[].name] | any(test("^(DesignDoc|DesignReview|ReadyTo|Verified)")) | not)] | length' \
        2>/dev/null || echo '?')"
  [[ "$un" == "0" ]] && ok "every open issue has a Stage label" || bad "$un open issue(s) with no Stage label"
fi

echo
(( fail == 0 )) && echo "Mechanical checks: ALL OK." || echo "Mechanical checks: NOT DONE — see above."
echo "Still yours to answer: memories saved (in-repo)? a fresh-eyes /work-review of this stretch?"
exit "$fail"

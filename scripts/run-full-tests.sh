#!/usr/bin/env bash
# =====================================================================================================================
#  run-full-tests.sh — THE gate. One command, the same on every OS, and the only verdict a commit is judged by.
#
#  Fill in the STEPS table for your stack. Everything else — the lock, the log, the summary, the exit code — is the
#  shape every repo of ours shares, because each piece was paid for:
#
#   * ONE command, not "the three dotnet/cargo/flutter commands". A raw command run by hand covers whatever its author
#     remembered; the gate covers every lane, every solution, every package. (Observatory once had 2,600 tests that
#     the "documented commands" never ran.)
#   * The SUMMARY prints LAST and is also written to run-full-tests-last.log (git-ignore it), so an agent — or the
#     owner on a phone — reads one block, not 4,000 lines of scrollback.
#   * Every lane reports separately with counts. "Green" with total=0 is a FAILURE: an empty lane is a lane that
#     silently stopped running.
#   * One run at a time per machine (a lock). Two concurrent gates make both verdicts — and every timing in them —
#     meaningless.
#   * Output goes outside the source tree's normal bin/obj if you dogfood the app from the tree (a rebuild must never
#     rewrite a running binary under its own mmap).
#
#  Usage: scripts/run-full-tests.sh [--fast]      (--fast: unit lane only, for iterating; NOT a commit verdict)
# =====================================================================================================================
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2

LOG="run-full-tests-last.log"
LOCK="${TMPDIR:-/tmp}/gate-$(basename "$PWD").lock"
FAST=0; [[ "${1:-}" == "--fast" ]] && FAST=1

# ---- STEPS: "name|command". Make each command print its own pass/fail counts so the log shows them. ----------
# Replace these with your stack. Keep them in the order a human would run them: build → unit → integration → others.
SIM="${SIM_NAME:-iPhone 17}"
XCB=(xcodebuild -project GolfBuddy.xcodeproj -quiet)
STEPS=(
  "build|${XCB[*]} -scheme GolfBuddy -destination 'generic/platform=iOS Simulator' build"
  "unit|${XCB[*]} -scheme GolfBuddy -destination 'platform=iOS Simulator,name=$SIM' -only-testing:GolfBuddyTests test"
  "watch|${XCB[*]} -scheme 'GolfBuddy Watch App' -destination 'generic/platform=watchOS Simulator' build"
)
(( FAST )) && STEPS=("${STEPS[@]:0:2}")

# ---- lock: refuse, don't queue ------------------------------------------------------------------------------------
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "gate: another gate is running on this machine ($LOCK). Refusing rather than queueing." >&2
  exit 3
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

sha="$(git rev-parse --short HEAD 2>/dev/null || echo no-commits)"; dirty=""; [[ -n "$(git status --porcelain)" ]] && dirty=" (+uncommitted)"
host="$(hostname -s)"; os="$(uname -s) $(uname -r)"
start=$(date +%s)
: > "$LOG"
summary=()
overall=PASS

for step in "${STEPS[@]}"; do
  name="${step%%|*}"; cmd="${step#*|}"
  echo "=== $name: $cmd" | tee -a "$LOG"
  t0=$(date +%s)
  bash -c "$cmd" >>"$LOG" 2>&1
  rc=$?
  dt=$(( $(date +%s) - t0 ))
  if (( rc == 0 )); then summary+=("$(printf '%-14s PASS  (%ss)' "$name" "$dt")")
  else summary+=("$(printf '%-14s FAIL  rc=%s (%ss)  — see %s' "$name" "$rc" "$dt" "$LOG")"); overall=FAIL; fi
done

{
  echo
  echo "================================ SUMMARY ================================"
  echo "commit: $sha$dirty   host: $host   os: $os   took: $(( $(date +%s) - start ))s"
  (( FAST )) && echo "MODE: --fast (unit only) — this is NOT a commit verdict"
  printf '%s\n' "${summary[@]}"
  echo "GATE: $overall"
  echo "Quote this block (with host + OS) when you claim green. A green gate proves the TREE, not the product."
} | tee -a "$LOG"

[[ "$overall" == PASS ]]

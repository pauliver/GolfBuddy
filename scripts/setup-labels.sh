#!/usr/bin/env bash
# =====================================================================================================================
#  setup-labels.sh — create (or refresh) the fleet SDLC labels on a GitHub repo. Idempotent.
#
#  Usage:   scripts/setup-labels.sh [owner/repo] [area:name="description" ...]
#  Example: scripts/setup-labels.sh                                   # the repo in the current directory
#           scripts/setup-labels.sh me/myrepo 'area:api=REST and MCP' 'area:ui=Screens and controls'
#
#  WHY THE NAMES ARE FIXED: labels are an API, not decoration. Observatory's fleet board (and any other tool reading
#  `gh`) renders lanes by label NAME. Renaming one — or inventing a near-duplicate like `stage:ready` — silently
#  drops cards into the board's `Unlabeled` lane on every machine. So this script only ever CREATES or REFRESHES the
#  colour/description of the canonical set. It never renames and never deletes.
#
#  Four axes, at most one label from each:  Stage · Type · Area (local) · Priority.  Modifiers only when true.
#  The scheme and the rules for moving between stages: docs/issue-labels.md.
# =====================================================================================================================
set -euo pipefail

repo="${1:-}"
if [[ -z "$repo" || "$repo" == area:* ]]; then
  repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
else
  shift
fi

vis="$(gh repo view "$repo" --json visibility -q .visibility)"
echo "repo: $repo ($vis)"

mk() {  # name colour description
  gh label create "$1" -R "$repo" --color "$2" --description "$3" --force >/dev/null && echo "  ok  $1"
}

echo "Stage (exactly one, or none = untriaged):"
mk DesignDoc        8250df "Stage - real work, but the fix is not yet known or agreed"
mk DesignReview     9a6dd7 "Stage - only an owner decision is missing"
mk ReadyToImplement d93f0b "Stage - cause known, fix agreed, sized for one lane"
mk ReadyToTest      e8a03e "Stage - built, needs independent testing (optional lane)"
mk ReadyToVerify    c5a92e "Stage - committed, NOT yet verified on a real host/device"
mk Verified         2da44e "Stage - verified; close the same day (not a parking lot)"

echo "Type (exactly one):"
mk bug           d73a4a "Something isn't working"
mk enhancement   a2eeef "New feature or request"
mk chore         cfd3d7 "Maintenance / housekeeping"
mk epic          5319e7 "A checklist of unit issues that closes when the list is empty"
mk security      b60205 "Authorization, trust boundary, secrets, or audit surface"
mk documentation 0075ca "Docs-only work"

echo "Priority (optional, sparingly):"
mk north-star 0e8a16 "Stands between us and the project's north star - keep this list short"

echo "Modifiers (only when true):"
mk Blocked               f87171 "Cannot proceed - pair with needs-decision or needs-hardware"
mk needs-decision        d93f0b "Blocked on an owner decision, not on work"
mk needs-hardware        5d4037 "Blocked on hardware or a machine not in hand"
mk auto-filed            ededed "Filed by an automated agent (e.g. the Observatory overseer), not a human"
mk before-public-release b60205 "Must be done before this repo's visibility changes"

echo "Board chips (free, externally read - leave them alone once created):"
mk URGENT        b60205 "Board renders the urgent chip"
mk Suspended     f87171 "Parked by decision - board treats it as Blocked"
mk TestedMac     2da44e "Verified on macOS - board platform chip"
mk TestediOS     2da44e "Verified on iOS - board platform chip"
mk TestedWindows 2da44e "Verified on Windows - board platform chip"

if (( $# > 0 )); then
  echo "Area (local to this repo; the board ignores these):"
  for spec in "$@"; do
    name="${spec%%=*}"; desc="${spec#*=}"; [[ "$desc" == "$spec" ]] && desc="Area"
    [[ "$name" == area:* ]] || { echo "  skip $name (areas must be named area:*)"; continue; }
    mk "$name" 1d76db "$desc"
  done
fi

echo "done. Never rename these; add areas with: $0 $repo 'area:x=what it covers'"

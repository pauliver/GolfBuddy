# CLAUDE.md — GolfBuddy

GolfBuddy is a SwiftUI golf companion for **iPhone and Apple Watch** (iOS/watchOS 26.4+): courses with per-hole hazard
maps and selectable distances, an active-round view, round history and stats, voice input on the watch, and an
offline-first course database built from OpenStreetMap data. The watch talks to the phone over WatchConnectivity.

**This repository is PUBLIC.** Nothing committed here — code, docs, memories, issues — may contain machine names,
local paths, network addresses, account names, keys or other personal details.

## Rules for working in this repo

1. **Memory lives in the repo:** `.claude/memory/` (index `MEMORY.md`, loaded below), one fact per file, committed —
   and, because this repo is public, never personal or machine-specific.
2. **Issues are the source of truth.** Labels follow `docs/issue-labels.md` (a fixed, externally read set — never
   rename or invent one; areas are `area:*`). Create them with `scripts/setup-labels.sh`.
3. **A green build is not a working feature.** Location, hazard distances, watch connectivity and voice input are only
   verified on a real iPhone + Apple Watch (or, where it can show the behaviour, the simulator pair) — report
   "verified by <method>" or "NOT yet verified". Committed-but-unverified is `ReadyToVerify`.
4. **Test first.** The test targets (`GolfBuddyTests`, `GolfBuddy Watch AppTests`) are still the Xcode templates;
   every change adds a real test that fails without it.
5. **Before any build, check the Xcode licence** after an Xcode upgrade (an un-agreed licence makes `xcrun` refuse
   before the tool runs, so the build, simulators and devices all fail together).

## Build and test

```bash
bash scripts/run-full-tests.sh        # THE gate: iOS build + unit tests, watch build
bash scripts/wrap-up-check.sh         # are we done for now? (pushed, no stray branches/worktrees, issues staged)
```
Simulator: `SIM_NAME` (default `iPhone 17`). Schemes are Xcode's auto-generated ones (`GolfBuddy`,
`GolfBuddy Watch App`).

## Course data

`scripts/export_golf_courses.py` / `scripts/export_north_america.py` export OpenStreetMap golf data into
`GolfBuddy/golf_courses.db`, which `OfflineCourseStore` reads from the app bundle. The database is **not committed**
(it is generated, ~4.5 MB). Without it, `OfflineCourseStore` returns empty results and course lookup relies on
the other sources in `CourseImportService` (e.g. its MapKit coordinate fallback).

## Where things are

| Path | What |
| --- | --- |
| `GolfBuddy/` | iPhone app (views, models, location, hazards, offline store, connectivity) |
| `GolfBuddy Watch App/` | watch app (location, voice, connectivity) |
| `UI/` | design handoff bundle — read `UI/README.md` before implementing a design |
| `COLOR_CONTRAST_AUDIT.md` | WCAG AA audit of the palette |
| `docs/issue-labels.md` | the label scheme and stage lifecycle |
| `.claude/` | committed project memory |

@.claude/memory/MEMORY.md

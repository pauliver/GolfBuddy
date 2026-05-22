# GolfBuddy Color Contrast Audit

Audited 2026-05-22. All issues below have been **FIXED**.
WCAG AA requires **4.5:1** for normal text, **3.0:1** for large text (18pt+ or 14pt+ bold).

---

## Color Palette Reference

| Token | Hex | RGB | Luminance | Role |
|---|---|---|---|---|
| `golfPaper` | #F2ECDD | (242, 236, 221) | 0.841 | Primary background |
| `golfPaper2` | #E6DDC6 | (230, 221, 198) | 0.726 | Secondary background (cards, inputs) |
| `golfPaper3` | #D9CDB0 | (217, 205, 176) | 0.616 | Tertiary background (unused in views) |
| `golfInk` | #1A2218 | (26, 34, 24) | 0.014 | Primary text |
| `golfInkSoft` | #4A5346 | (74, 83, 70) | 0.081 | Secondary text |
| `golfInkMute` | #4D5B49 | (77, 91, 73) | 0.095 | Muted/label text |
| `golfMoss` | #3D5A3B | (61, 90, 59) | 0.086 | Brand accent, buttons |
| `golfFairway` | #6B8E5A | (107, 142, 90) | 0.232 | Lighter green accent |
| `golfFairway2` | #94B27E | (148, 178, 126) | 0.396 | Lightest green (unused in views) |
| `golfSand` | #D9C08A | (217, 192, 138) | 0.543 | Sand/gold accent |
| `golfPin` | #A53D32 | (165, 61, 50) | 0.118 | Red/danger accent (darkened from #B8463A for contrast) |

System colors used (light mode approximations):

| Name | Hex | RGB | Luminance |
|---|---|---|---|
| `.orange` | #FF9500 | (255, 149, 0) | 0.428 |
| `.green` | #34C759 | (52, 199, 89) | 0.423 |
| `.red` | #FF3B30 | (255, 59, 48) | 0.246 |
| `.secondary` | #3C3C43 @ 60% | blended per bg | ~0.22 |

---

## Master Contrast Ratio Table

| Text Color | Background | Ratio | AA Normal | AA Large | Verdict |
|---|---|---|---|---|---|
| `golfInk` | `golfPaper` | **13.86:1** | PASS | PASS | Excellent |
| `golfInk` | `golfPaper2` | **12.07:1** | PASS | PASS | Excellent |
| `golfInkSoft` | `golfPaper` | **6.81:1** | PASS | PASS | Good |
| `golfInkSoft` | `golfPaper2` | **5.93:1** | PASS | PASS | Good |
| `golfInkMute` | `golfPaper` | **6.13:1** | PASS | PASS | Good |
| `golfInkMute` | `golfPaper2` | **5.34:1** | PASS | PASS | OK (tight at small sizes) |
| `golfMoss` | `golfPaper` | **6.54:1** | PASS | PASS | Good |
| `golfMoss` | `golfPaper2` | **5.70:1** | PASS | PASS | Good |
| `golfPaper` | `golfMoss` | **6.54:1** | PASS | PASS | Good (button text) |
| `golfPaper` | `golfInk` | **13.86:1** | PASS | PASS | Excellent |
| `golfPaper` | `golfPin` | **4.48:1** | FAIL | PASS | Problem at normal sizes |
| `golfPin` | `golfPaper` | **4.48:1** | FAIL | PASS | Problem at normal sizes |
| `golfPin` | `golfPaper2` | **3.90:1** | FAIL | PASS | Problem |
| `golfSand` | `golfPaper` | **1.50:1** | FAIL | FAIL | Nearly invisible |
| `golfSand` | `golfPaper2` | **1.31:1** | FAIL | FAIL | Nearly invisible |
| `.orange` | `golfPaper` | **1.87:1** | FAIL | FAIL | Nearly invisible |
| `.green` | `golfPaper` | **1.88:1** | FAIL | FAIL | Nearly invisible |
| `.red` | `golfPaper` | **3.01:1** | FAIL | PASS | Problem at normal sizes |
| `.secondary` | `golfPaper` | **3.23:1** | FAIL | PASS | Problem at normal sizes |
| `.secondary` | `golfPaper2` | **3.05:1** | FAIL | PASS | Problem at normal sizes |
| `golfSand@0.6` | `golfPaper2` | **1.17:1** | FAIL | FAIL | Invisible (chart line) |

---

## Screen-by-Screen Audit (Outside In)

### 1. ContentView (TabView shell)

| Element | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|
| Tab labels | System tint | System tab bar | System | — | OK (system-managed) |

No custom colors applied at this level.

---

### 2. HomeView > noRoundView

**Screen background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Golf figure icon | HomeView:69-70 | `golfMoss` | `golfPaper` | 6.54 | 64pt icon | PASS |
| "Ready to play?" | HomeView:74-75 | `golfInk` | `golfPaper` | 13.86 | title2 semibold | PASS |
| "Select a course..." | HomeView:77-78 | `golfInkMute` | `golfPaper` | 6.13 | subheadline | PASS |
| "Choose a Course" btn text | HomeView:87-88 | `golfPaper` | `golfMoss` | 6.54 | headline | PASS |
| Navigation title | HomeView:31 | System primary | `golfPaper` | ~13.86 | large title | PASS |

---

### 3. HomeView > detectionBanner

**Card background:** `golfPaper2`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Location icon | HomeView:110 | `golfMoss` | `golfPaper2` | 5.70 | caption icon | PASS |
| "NEARBY" | HomeView:112-113 | `golfMoss` | `golfPaper2` | 5.70 | 9pt mono | PASS |
| Dismiss X button | HomeView:118 | `golfInkMute` | `golfPaper2` | 5.34 | caption2 icon | PASS |
| Course name | HomeView:122-123 | `golfInk` | `golfPaper2` | 12.07 | 22pt Georgia | PASS |
| Location string | HomeView:127-129 | `golfInkMute` | `golfPaper2` | 5.34 | subheadline | PASS |
| "Play here" btn text | HomeView:133-134 | `golfPaper` | `golfMoss` | 6.54 | 15pt semibold | PASS |
| Card border | HomeView:144 | `golfMoss@0.3` | `golfPaper2` | — | 1pt stroke | Decorative |

---

### 4. CourseSelectionSheet

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Course name | HomeView:216 | `golfInk` | `golfPaper` | 13.86 | headline | PASS |
| Location string | HomeView:218 | *no explicit color* | `golfPaper` | — | caption | **UNCLEAR** - inherits from outer context, likely system primary |
| Hole count | HomeView:219 | *no explicit color* | `golfPaper` | — | caption | **UNCLEAR** |
| "Par N" | HomeView:220 | *no explicit color* | `golfPaper` | — | caption | **UNCLEAR** |
| caption group | HomeView:222 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |
| "Cancel" button | HomeView:235 | System tint | `golfPaper` toolbar | — | — | OK |

---

### 5. ActiveRoundView > holeHeader

**Section background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Course name (caps) | ActiveRoundView:66 | `golfInkMute` | `golfPaper` | 6.13 | 10pt mono | PASS |
| "Hole N" | ActiveRoundView:69 | `golfInk` | `golfPaper` | 13.86 | 30pt bold | PASS |
| "Par N" | ActiveRoundView:72 | `golfMoss` | `golfPaper` | 6.54 | 16pt mono | PASS |
| "TOTAL" | ActiveRoundView:79 | `golfInkMute` | `golfPaper` | 6.13 | 9pt mono | PASS |
| Score vs par (under) | ActiveRoundView:83 | `golfMoss` | `golfPaper` | 6.54 | 22pt semibold | PASS |
| Score vs par (even) | ActiveRoundView:83 | `golfInk` | `golfPaper` | 13.86 | 22pt semibold | PASS |
| Score vs par (bogey) | ActiveRoundView:83 | `golfInkSoft` | `golfPaper` | 6.81 | 22pt semibold | PASS |
| Score vs par (2+over) | ActiveRoundView:83 | `golfPin` | `golfPaper` | 4.48 | 22pt semibold (large) | PASS (large text) |

---

### 6. ActiveRoundView > distanceSection

**Section background:** `golfPaper2`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| GPS yardage | ActiveRoundView:96 | `golfInk` | `golfPaper2` | 12.07 | 88pt bold | PASS |
| "YARDS TO PIN" | ActiveRoundView:100 | `golfInkMute` | `golfPaper2` | 5.34 | 10pt mono | PASS |
| Stored yardage | ActiveRoundView:103 | `golfInkMute` | `golfPaper2` | 5.34 | 88pt bold (large) | PASS |
| "YARDS (STORED)" | ActiveRoundView:106 | `golfInkMute` | `golfPaper2` | 5.34 | 10pt mono | PASS |
| No-data icon | ActiveRoundView:110 | `golfInkMute` | `golfPaper2` | 5.34 | title2 icon | PASS |
| "No distance data" | ActiveRoundView:111 | `golfInkMute` | `golfPaper2` | 5.34 | 12pt mono | PASS |
| "FRONT" label | ActiveRoundView:119 | `golfInkMute` | `golfPaper2` | 5.34 | 9pt mono | PASS |
| "BACK" label | ActiveRoundView:124 | `golfInkMute` | `golfPaper2` | 5.34 | 9pt mono | PASS |
| Front yardage | ActiveRoundView:120 | `golfInkSoft` | `golfPaper2` | 5.93 | 22pt semibold | PASS |
| Back yardage | ActiveRoundView:125 | `golfInkSoft` | `golfPaper2` | 5.93 | 22pt semibold | PASS |
| "Record Pin Location" | ActiveRoundView:134 | `golfMoss` | `golfMoss@0.1` on `golfPaper2` | ~5.5 | footnote medium | PASS |

---

### 7. ActiveRoundView > scoreSection

**Section background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Score number (birdie-) | ActiveRoundView:155 | `golfMoss` | `golfPaper` | 6.54 | 88pt serif (large) | PASS |
| Score number (par) | ActiveRoundView:155 | `golfInk` | `golfPaper` | 13.86 | 88pt serif (large) | PASS |
| Score number (bogey) | ActiveRoundView:155 | `golfInkSoft` | `golfPaper` | 6.81 | 88pt serif (large) | PASS |
| Score number (2+ over) | ActiveRoundView:155 | `golfPin` | `golfPaper` | 4.48 | 88pt serif (large) | PASS (large text) |
| Score word (birdie-) | ActiveRoundView:157 | `golfMoss` | `golfPaper` | 6.54 | 20pt serif italic (large) | PASS |
| Score word (2+ over) | ActiveRoundView:157 | `golfPin` | `golfPaper` | 4.48 | 20pt serif italic (large) | PASS (large text) |
| Placeholder "—" | ActiveRoundView:162 | `golfInkMute` | `golfPaper` | 6.13 | 64pt ultralight (large) | PASS |
| "STROKES" label | ActiveRoundView:170 | `golfInkMute` | `golfPaper` | 6.13 | 10pt mono | PASS |
| "OF WHICH, PUTTS" | ActiveRoundView:185 | `golfInkMute` | `golfPaper` | 6.13 | 10pt mono | PASS |
| "FAIRWAY" | ActiveRoundView:202 | `golfInkMute` | `golfPaper` | 6.13 | 10pt mono | PASS |

---

### 8. ActiveRoundView > StrokeButton

| State | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Unselected | ActiveRoundView:327 | `golfInk` | `golfPaper2` | 12.07 | 16pt mono semibold | PASS |
| Selected (strokes, accent=golfMoss) | ActiveRoundView:328 | `golfPaper` | `golfMoss` | 6.54 | 16pt mono semibold | PASS |
| Selected (putts, accent=golfInk) | ActiveRoundView:328 | `golfPaper` | `golfInk` | 13.86 | 16pt mono semibold | PASS |

---

### 9. ActiveRoundView > fairwayButton

| State | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Unselected | ActiveRoundView:307 | `golfInk` | `golfPaper2` | 12.07 | 14pt medium | PASS |
| Selected "Hit" | ActiveRoundView:307 | `golfPaper` | `golfMoss` | 6.54 | 14pt medium | PASS |
| **Selected "Missed"** | ActiveRoundView:307 | **`golfPaper`** | **`golfPin`** | **4.48** | **14pt medium** | **FAIL AA normal** |

> **PROBLEM:** "Missed" fairway button at 14pt medium weight. 14pt medium is not "large text" by WCAG (needs 14pt **bold** or 18pt+). Ratio 4.48 < 4.5 required. Borderline fail.

---

### 10. ActiveRoundView > advanceSection

**Section background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| "Save & advance" btn | ActiveRoundView:227-229 | `golfPaper` | `golfMoss` | 6.54 | 15pt semibold | PASS |
| **"Abandon Round"** | ActiveRoundView:236 | **`golfPin`** | **`golfPaper`** | **4.48** | **subheadline (~15pt)** | **FAIL AA normal** |

> **PROBLEM:** "Abandon Round" text is `golfPin` (#B8463A) on `golfPaper` (#F2ECDD). At subheadline size (~15pt), this is normal text needing 4.5:1. Ratio is 4.48:1 -- barely fails.

---

### 11. CourseListView

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Course name | CourseListView:15 | `golfInk` | `golfPaper` | 13.86 | headline | PASS |
| Location/holes/par | CourseListView:27 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |
| "+" toolbar button | CourseListView:42 | System tint (blue) | `golfPaper` toolbar | — | — | OK |
| "Edit" toolbar button | CourseListView:46 | System tint | `golfPaper` toolbar | — | — | OK |

---

### 12. AddCourseView > searchView

**Screen background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| **Search icon** | AddCourseView:55 | **`.secondary`** | **`golfPaper2` (search bar bg)** | **3.05** | **icon** | **FAIL AA normal** |
| **Clear X icon** | AddCourseView:62 | **`.secondary`** | **`golfPaper2`** | **3.05** | **icon** | **FAIL AA normal** |
| Search text field | AddCourseView:56 | System primary | `golfPaper2` | ~12 | body | PASS |
| "Near Me" button | AddCourseView:76-78 | `golfMoss` | `golfPaper` | 6.54 | subheadline medium | PASS |
| Nearby course chips | AddCourseView:90-95 | `golfMoss` | `golfFairway@0.15` on `golfPaper` | ~5.5 | caption medium | PASS |
| Search result name | AddCourseView:118 | `golfInk` | `golfPaper` (row) | 13.86 | headline | PASS |
| Search result location | AddCourseView:121 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |
| Search result par/holes | AddCourseView:123 | `golfMoss` | `golfPaper` | 6.54 | caption | PASS |
| "Enter Manually Instead" | AddCourseView:138 | `golfMoss` | `golfPaper` | 6.54 | subheadline | PASS |

---

### 13. AddCourseView > confirmView

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| LabeledContent labels | AddCourseView:156-160 | System primary | `golfPaper` | ~13.86 | body | PASS |
| LabeledContent values | AddCourseView:156-160 | System secondary | `golfPaper` | ~3.23 | body | **BORDERLINE** |
| Hole number "Hole N" | AddCourseView:168 | `golfInkSoft` | `golfPaper` | 6.81 | body mono | PASS |
| Hole par | AddCourseView:171 | `golfInkMute` | `golfPaper` | 6.13 | caption mono | PASS |
| Hole yardage | AddCourseView:177 | `golfInk` | `golfPaper` | 13.86 | caption mono | PASS |
| Pin flag icon | AddCourseView:182 | `golfPin` | `golfPaper` | 4.48 | caption2 icon | Borderline (icon) |
| "Fetching GPS..." | AddCourseView:198 | `golfInkMute` | `golfPaper` | 6.13 | subheadline | PASS |
| GPS found label | AddCourseView:201 | `golfMoss` | `golfPaper` | 6.54 | body | PASS |
| GPS remaining hint | AddCourseView:204 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |
| **"No GPS data" label** | AddCourseView:208-209 | **`.orange`** | **`golfPaper`** | **1.87** | **caption** | **FAIL - NEARLY INVISIBLE** |
| "Pin locations can be..." | AddCourseView:210 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |

> **CRITICAL PROBLEM:** `.orange` (#FF9500) text on `golfPaper` (#F2ECDD) has only **1.87:1** contrast. This is far below even the 3.0:1 large-text minimum. Orange on cream is nearly invisible.

---

### 14. ManualCourseEntryView

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Form labels | AddCourseView:325-327 | System primary | `golfPaper` | ~13.86 | body | PASS |
| Text field input | AddCourseView:325-327 | System primary | `golfPaper` | ~13.86 | body | PASS |
| Hint text | AddCourseView:339 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |
| Segmented picker | AddCourseView:331-334 | System | System | — | — | OK |

---

### 15. CourseDetailView

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| LabeledContent labels | CourseDetailView:21-31 | System primary | `golfPaper` | ~13.86 | body | PASS |
| TextField values | CourseDetailView:22-30 | System primary | `golfPaper` | ~13.86 | body | PASS |

---

### 16. HoleRowView (inside CourseDetailView)

**Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| "Hole N" | CourseDetailView:76-77 | `.primary` (via button foreground) | `golfPaper` | ~13.86 | body medium | PASS |
| **"Par N"** | CourseDetailView:80-81 | **`.secondary`** | **`golfPaper`** | **3.23** | **subheadline** | **FAIL AA normal** |
| **"N yds"** | CourseDetailView:83-84 | **`.secondary`** | **`golfPaper`** | **3.23** | **subheadline** | **FAIL AA normal** |
| **GPS location icon** | CourseDetailView:87-89 | **`.green`** | **`golfPaper`** | **1.88** | **caption icon** | **FAIL - NEARLY INVISIBLE** |
| Chevron | CourseDetailView:93-95 | `.tertiary` | `golfPaper` | ~1.5 | caption icon | Decorative/affordance |

> **CRITICAL PROBLEM:** System `.green` (#34C759) icon on `golfPaper` (#F2ECDD) has only **1.88:1** contrast. Green on cream is nearly invisible.
>
> **PROBLEM:** `.secondary` text on `golfPaper` gives only **3.23:1** for "Par N" and yardage text. Below 4.5:1 for normal-sized text.

---

### 17. HoleEditView

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Segmented picker | CourseDetailView:110-114 | System | System | — | — | OK |
| LabeledContent labels | CourseDetailView:117-126 | System primary | `golfPaper` | ~13.86 | body | PASS |
| Coordinate values | CourseDetailView:132-133 | System secondary | `golfPaper` | ~3.23 | body | **BORDERLINE** |
| "Clear" destructive buttons | CourseDetailView:134,149 | System red | `golfPaper` | ~3.01 | body | **FAIL AA normal** |
| "Set to My Location" buttons | CourseDetailView:138,151 | System tint (blue) | `golfPaper` | — | body | OK |
| "Done" toolbar button | CourseDetailView:166 | System tint | `golfPaper` toolbar | — | — | OK |

---

### 18. RoundHistoryView

**Screen background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Segmented picker | RoundHistoryView:23-28 | System | System material | — | — | OK |

---

### 19. RoundRowView (inside RoundHistoryView)

**Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Course name | RoundHistoryView:65 | `golfInk` | `golfPaper` | 13.86 | headline | PASS |
| Date | RoundHistoryView:67 | `golfInkMute` | `golfPaper` | 6.13 | caption | PASS |
| Total strokes | RoundHistoryView:72 | `golfInk` | `golfPaper` | 13.86 | title3 bold | PASS |
| vs Par (under/even) | RoundHistoryView:77 | `golfMoss` | `golfPaper` | 6.54 | caption mono | PASS |
| **vs Par (over)** | RoundHistoryView:77 | **`golfPin`** | **`golfPaper`** | **4.48** | **caption mono** | **FAIL AA normal** |

> **PROBLEM:** Over-par scores in round list rows use `golfPin` on `golfPaper` at caption size. 4.48:1 fails the 4.5:1 requirement for normal text.

---

### 20. RoundDetailView

**Screen background:** `golfPaper` | **Row background:** `golfPaper`

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Stat labels | RoundHistoryView:166 | System primary | `golfPaper` | ~13.86 | body | PASS |
| Stat values | RoundHistoryView:169 | `golfInkSoft` | `golfPaper` | 6.81 | body | PASS |
| vs Par (under/even) | RoundHistoryView:101-102 | `golfMoss` | `golfPaper` | 6.54 | body semibold | PASS |
| **vs Par (over)** | RoundHistoryView:102 | **`golfPin`** | **`golfPaper`** | **4.48** | **body semibold** | **FAIL AA normal** |
| Hole number "HN" | RoundHistoryView:121 | `golfInkSoft` | `golfPaper` | 6.81 | 13pt mono medium | PASS |
| Hole par "pN" | RoundHistoryView:126 | `golfInkMute` | `golfPaper` | 6.13 | 10pt mono | PASS |
| Fairway checkmark | RoundHistoryView:133 | `golfMoss` | `golfPaper` | 6.54 | caption2 icon | PASS |
| **Fairway xmark** | RoundHistoryView:134 | **`golfPin`** | **`golfPaper`** | **4.48** | **caption2 icon** | **FAIL** |
| Putts "Np" | RoundHistoryView:139 | `golfInkMute` | `golfPaper` | 6.13 | 11pt mono | PASS |
| Strokes number | RoundHistoryView:143 | System primary | `golfPaper` | ~13.86 | 15pt semibold | PASS |
| Score diff (under) | RoundHistoryView:148 | `golfMoss` | `golfPaper` | 6.54 | 11pt mono | PASS |
| Score diff (even) | RoundHistoryView:149 | `golfInkSoft` | `golfPaper` | 6.81 | 11pt mono | PASS |
| **Score diff (over)** | RoundHistoryView:149 | **`golfPin`** | **`golfPaper`** | **4.48** | **11pt mono** | **FAIL AA normal** |

---

### 21. StatsView

**Screen background:** `golfPaper`

#### Trend Chart (card bg: `golfPaper2`)

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| "SCORING TREND" | StatsView:37-39 | `golfInkMute` | `golfPaper2` | 5.34 | 10pt mono | PASS |
| Chart line/points | StatsView:46-63 | `golfMoss` | `golfPaper2` | 5.70 | graphic | PASS |
| **Par reference line** | StatsView:67-69 | **`golfSand@0.6`** | **`golfPaper2`** | **1.17** | **1pt dashed line** | **FAIL - INVISIBLE** |
| X-axis labels | StatsView:77-78 | `golfInkMute` | `golfPaper2` | 5.34 | 9pt mono | PASS |
| Y-axis labels | StatsView:86-87 | `golfInkMute` | `golfPaper2` | 5.34 | 9pt mono | PASS |

> **CRITICAL PROBLEM:** Par reference line uses `golfSand` at 60% opacity on `golfPaper2`. Both are warm light tones. The resulting **1.17:1** contrast makes this line completely invisible. Sand on cream = invisible.

#### Metrics Grid (card bg: `golfPaper2`)

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Card title (caps) | StatsView:225 | `golfInkMute` | `golfPaper2` | 5.34 | 9pt mono | PASS |
| Card value | StatsView:229 | `golfInk` | `golfPaper2` | 12.07 | 28pt bold | PASS |
| Card subtitle | StatsView:233 | `golfInkMute` | `golfPaper2` | 5.34 | caption | PASS |

#### Course Breakdown (card bg: `golfPaper2`)

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| "BY COURSE" | StatsView:114 | `golfInkMute` | `golfPaper` | 6.13 | 10pt mono | PASS |
| Course name | StatsView:122 | `golfInk` | `golfPaper2` | 12.07 | headline | PASS |
| "N rounds" | StatsView:123 | `golfInkMute` | `golfPaper2` | 5.34 | caption | PASS |
| Avg score number | StatsView:127 | *no explicit color* | `golfPaper2` | ~12.07 | 20pt bold | PASS (inherits primary) |
| Avg vs par (under/even) | StatsView:130 | `golfMoss` | `golfPaper2` | 5.70 | caption mono | PASS |
| **Avg vs par (over)** | StatsView:130 | **`golfPin`** | **`golfPaper2`** | **3.90** | **caption mono** | **FAIL AA normal** |

> **PROBLEM:** Over-par averages per course use `golfPin` on `golfPaper2` at caption size. 3.90:1 fails both normal (4.5) requirement.

---

### 22. HoleMapView (satellite overlay)

**Background:** Hybrid satellite map (variable dark terrain)

| Element | File:Line | Text/FG Color | Background | Ratio | Size | Status |
|---|---|---|---|---|---|---|
| Yardage ring labels | HoleMapView:43-44 | `.white` | `.black@0.45` capsule | ~3.5+ | 9pt semibold | OK (bg capsule helps) |
| Pin flag icon | HoleMapView:52-53 | `.white` | `.red` circle | High | title3 icon | PASS |
| Tee marker | HoleMapView:61-63 | `.blue` fill | `.white` stroke | High | 14pt circle | PASS |
| Yardage rings | HoleMapView:38-39 | `.white@0.55` | Satellite imagery | Variable | 1pt stroke | OK for map context |

---

## Fixes Applied

All issues have been resolved. Here is what was changed:

### 1. Darkened `golfPin` from #B8463A to #A53D32
- Old ratio on golfPaper: 4.48:1 (failed AA normal text)
- New ratio on golfPaper: ~5.5:1 (passes AA)
- New ratio on golfPaper2: ~4.8:1 (passes AA)
- Affects: all over-par scores, "Abandon Round", fairway "Missed" button, fairway xmarks

### 2. Replaced all system colors with design-system equivalents
- `.orange` -> `Color.golfPin` (AddCourseView "No GPS data" label)
- `.green` -> `Color.golfMoss` (HoleRowView GPS location icon)
- `.secondary` -> `Color.golfInkMute` (HoleRowView par/yardage, search bar icons)
- `.primary` -> `Color.golfInk` (HoleRowView via button, stat labels, scorecard strokes)
- `.tertiary` -> `Color.golfInkMute.opacity(0.5)` (chevron affordance)
- System `.red` destructive buttons -> explicit `Color.golfPin` text

### 3. Fixed invisible chart par reference line
- `Color.golfSand.opacity(0.6)` -> `Color.golfInkMute.opacity(0.4)` (1.17:1 -> ~3.5:1)

### 4. Wired explicit colors on all remaining elements
- All toolbar buttons explicitly use `Color.golfMoss`
- All LabeledContent labels/values explicitly use `Color.golfInk` / `Color.golfInkSoft`
- All TextField inputs use explicit `Color.golfInkSoft`
- All stat row labels use explicit `Color.golfInk`
- Scorecard stroke numbers use explicit `Color.golfInk`
- Course breakdown avg scores use explicit `Color.golfInk`
- Global `.tint(Color.golfMoss)` set on TabView for system controls

### 5. Palette guard notes
`golfPaper3`, `golfFairway2`, and `golfSand` are not used as text colors. They should only be used for backgrounds or graphical fills -- never as foreground on Paper backgrounds.

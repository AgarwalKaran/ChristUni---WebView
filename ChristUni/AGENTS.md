# ChristUni — continuation context

Use this file when resuming work on the **ChristUni** iOS app (SwiftUI, mock data only, unofficial Christ University student companion v1).

## Product intent

- **Unofficial** student portal UI: dashboard, academics, attendance, faculty directory.
- **No real auth or APIs** — all data from [`ChristUni/Mock/MockStudentPortalData.swift`](ChristUni/Mock/MockStudentPortalData.swift) via [`StudentPortalSnapshot`](ChristUni/Models/StudentPortalSnapshot.swift).
- **UI locked to light** — [`ChristUniApp.swift`](ChristUni/ChristUniApp.swift) applies `.preferredColorScheme(.light)` so the editorial palette stays consistent.
- **Design references** live outside the synced app target: [`DesignReferences/`](DesignReferences/) at repo root (HTML/PNGs + `christ_central_ivory/DESIGN.md`). Do not move HTML/PNGs into `ChristUni/` or Xcode will copy duplicate `screen.png` / `code.html` into the bundle and break the build.

## Architecture

| Layer | Location | Notes |
|--------|-----------|--------|
| App entry | [`ChristUniApp.swift`](ChristUni/ChristUniApp.swift) | `MainTabView()` only; SwiftData/template removed. |
| Root UI | [`Views/MainTabView.swift`](ChristUni/Views/MainTabView.swift) | `ZStack`: tab content + [`FloatingTabBar`](ChristUni/Views/Components/FloatingTabBar.swift). |
| Shared state | [`ViewModels/StudentPortalState.swift`](ChristUni/ViewModels/StudentPortalState.swift) | `@Observable`; holds `snapshot`, `selectedTab`, `attendanceScope`, faculty search/filter. Injected with `.environment(portalState)`. |
| Theme | [`Theme/DesignTokens.swift`](ChristUni/Theme/DesignTokens.swift) | Hex colors, `LinearGradient.editorialPrimary`, `Radius.tabBar` (floating dock, **all corners rounded**). |
| Animations | [`Views/Components/KickstartAnimations.swift`](ChristUni/Views/Components/KickstartAnimations.swift) | `kickstartFadeUp`, `KickstartProgressBar`. |

**MVVM-ish:** thin “VM” is really `StudentPortalState`; views read `@Environment(StudentPortalState.self)` and use `@Bindable` where bindings are needed.

## Tabs and screens

1. **Home** — [`Views/Home/DashboardHomeView.swift`](ChristUni/Views/Home/DashboardHomeView.swift): header, portfolio (name, register, **mobile only**), attendance hero + **animated ring** + count-up %, programme card, today’s schedule. **No** credits / “top % of class”. Kickstart stagger on sections.
2. **Academics** — [`Views/Academics/AcademicsView.swift`](ChristUni/Views/Academics/AcademicsView.swift): gradient hero with **GPA / 4.0** + **percentage** count-up; **white progress bar** under hero only. History cards: **semester title only** (no Spring/Fall), **GPA + percentage only** — **no letter grades**, **no progress bar on semester cards**. Insight footer at bottom.
3. **Attendance** — [`Views/Attendance/AttendanceOverviewView.swift`](ChristUni/Views/Attendance/AttendanceOverviewView.swift): hero + **progress bar** for overall standing; segmented **Ongoing / Completed**; subject cards with stats — **no** per-subject progress bar. Replays subject list animation on scope change.
4. **Faculty** — [`Views/Faculty/FacultyDirectoryView.swift`](ChristUni/Views/Faculty/FacultyDirectoryView.swift): search, department chips, cards (name, department, email, cabin, campus). **No** role tags, **no** photos, **no** typewriter (removed).

## Data models (under `ChristUni/Models/`)

- **`Student`**: name, registerNumber, mobileNumber, overallAttendancePercentage, programTitle, currentSemesterLabel (no landline).
- **`AcademicOverview`**: cumulativeGPA, overallPercentage (no overall letter grade).
- **`SemesterRecord`**: displayTitle, gpa, percentage (no grade string).
- **`SubjectAttendance`**: subject, courseCode, theory/practical, conducted/present/absent, optional status chips; `percentage` computed.
- **`SemesterAttendanceBundle`**: semesterTitle, isOngoing, subjects.
- **`Faculty`**, **`TodayClass`**, **`StudentPortalSnapshot`**.

## Floating tab bar

- [`FloatingTabBar.swift`](ChristUni/Views/Components/FloatingTabBar.swift): **fully rounded** `RoundedRectangle` (`DesignTokens.Radius.tabBar`), solid fill + stroke + shadow (no `Material`). Tabs: Home, Academics, Attendance, Faculty (`MainTab` in `StudentPortalState.swift`).

## Build and repo hygiene

- **Target:** iOS (project uses recent SDK; filesystem-synced `ChristUni/` group auto-includes new Swift files).
- **[`.gitignore`](.gitignore)** at repo root: Xcode `xcuserdata`, `DerivedData`, `build`, SPM `.build`, Pods, secrets, etc.
- **Tests:** [`ChristUniTests/ChristUniTests.swift`](ChristUniTests/ChristUniTests.swift) — basic `SubjectAttendance` percentage + snapshot shape checks.

## Explicit non-goals / removed ideas

- No SwiftData / `Item` template.
- No faculty typewriter (`TypewriterFacultyBlock` deleted).
- Academics: no Latin honors, rank, credits tabs, or season labels on history.
- Attendance subject cards: no bottom progress bar (hero bar kept).

## Quick “where to change X”

| Change | File(s) |
|--------|---------|
| Mock student / lists | [`MockStudentPortalData.swift`](ChristUni/Mock/MockStudentPortalData.swift) |
| Tab order / icons | `MainTab` + `FloatingTabBar` |
| Colors / radii | [`DesignTokens.swift`](ChristUni/Theme/DesignTokens.swift) |
| Screen enter motion | Per-view `kickstarted` / `screenReady` + [`KickstartAnimations.swift`](ChristUni/Views/Components/KickstartAnimations.swift) |

---

## Latest implementation handoff (Apr 20, 2026)

- Authentication path is functional: login via `WKWebView`, cookies captured, persisted, and reused for rendered portal fetches.
- Repository now uses rendered HTML fetches (`PortalRenderedPageFetcher`) and diagnostics logging (`PortalTrace[...]`, `PortalParse ...`).
- Attendance endpoint mapping was updated from HAR evidence:
  - Current attendance: `studentWiseAttendanceSummary.do?method=getIndividualStudentWiseSubjectAndActivityAttendanceSummary`
  - Previous attendance select: `studentWiseAttendanceSummary.do?method=initPreviousStudentAttendanceSummeryChrist`
  - Previous attendance result: `POST studentWiseAttendanceSummary.do` with `method=getPreviousStudentWiseSubjectSummaryChrist`, `formName=studentWiseAttendanceSummaryForm`, `pageType=4`, and `classesId`.
- `AttendanceHTMLParser` was hardened against live DOM variations:
  - Tolerates nested tables and inline script nodes between row cells.
  - Extracts subject rows and inner attendance-type rows (Theory/Practical/Extra Curricular).
  - Handles decimal numeric cells (`39.0`) for conducted/present/absent conversion.
- Current runtime status from logs:
  - `PortalTrace[attendanceSummary]` shows `attendanceTable:true` and `subjectNameCol:true`.
  - `PortalParse` now shows `attendanceSubjects=13` (names parse successfully).
  - Prior issue was numeric fields showing zero; conversion logic was just updated to parse decimal text safely.
- Academics and Faculty remain unresolved:
  - Current traces still show shell-like markers (`marksCard:true`, `facultyTable:true`) but no data markers (`profileName:false`).
  - Need HAR-driven exact request/payload sequencing for academics result and faculty detail pages, similar to attendance workflow.

## Immediate next-session checklist

- Re-run app and verify attendance values (not just names) are non-zero after numeric conversion patch.
- If attendance is correct, proceed to academics:
  - Capture/parse HAR for semester selection + marks result submission.
  - Update repository payloads/endpoint ordering accordingly.
- Then faculty:
  - Capture/parse HAR for final faculty info request and payload.
  - Update endpoint map/repository and parser selectors.
- Keep using `PortalTrace`/`PortalParse` logs to validate each flow incrementally.

## Latest progress update (Apr 20, 2026 — evening)

- Attendance now works near end-to-end in native UI:
  - Current attendance is fetched and parsed from live portal HTML.
  - Previous-sem attendance is fetched via previous-attendance flow and shown under `Completed`.
  - Semester dropdown options are parsed from real class labels (e.g., `5CME`, `4CME`, `1CME`) with multi-response fetch support.
  - Multi-component subjects are grouped in one card (e.g., Theory + Practical + Asynchronous) and all rows are included in per-subject and hero calculations.
  - Percentages are displayed with 2 decimal places.
  - Subject code placeholders (`SUB001`, etc.) are removed from Attendance cards.
  - Ongoing/Completed segmented control is restored and functional.

- Home screen has been upgraded and wired to live data:
  - Name and class are parsed and shown.
  - Mobile and personal email parsing now targets live input fields (`mobileNo`, `contactMail`) with robust fallbacks.
  - Profile photo parsing now targets the profile image (`prohead` image) and avoids accidental `questionMark.jpg` selection.
  - Header avatar uses profile image when available; initials fallback remains.
  - Added profile card with image + key identity details.
  - Overall attendance hero uses ongoing-sem totals (not stale fallback), with 2-decimal display.
  - Program/course fallback improved when explicit course label is unavailable.
  - Removed “Today’s Schedule” section from Home per request.

- Home UX behavior enhancements completed:
  - Top identity rows (class/mobile/email) are aligned with fixed icon widths.
  - Tapping “Class …” card opens a styled quick-action sheet:
    - `Grades` routes to Academics tab.
    - `Attendance` routes to Attendance tab.
  - Tapping Home “Overall Attendance” card routes to Attendance tab.
  - Logout UI improved with icon-styled button in header and confirmation dialog.
  - Legacy top-right logout overlay in `MainTabView` removed to avoid overlap.

- Shared header behavior:
  - `ChristUniversityHeader` now supports optional `profilePhotoURL` and `onLogout`.
  - Logout button is positioned left of bell and includes confirmation prompt.
  - Header updates are wired into Home, Academics, Attendance, and Faculty views.

- Current known status from latest user validation:
  - Attendance: “works near perfectly.”
  - Home: “everything works as expected.”
  - Remaining major integration work: Academics live parsing/fetch flow, then Faculty data flow refinements if needed.

## Latest progress update (Apr 20, 2026 — late evening)

- Academics live flow is now functional end-to-end:
  - Semester options are parsed from Marks Card dropdown (`regularExamId` values).
  - Exact HAR-aligned submission payload was integrated (`method=MarksCardDisplay`, `formName=loginform`, `pageType=3`, `examType=Regular`, `regularExamId`, `suppExamId=`), which unlocked actual marks-card result pages.
  - Runtime now confirms non-zero records (`academicsRecords=3` for current account).
  - Semester cards display correctly in Academic History.

- Academics UI/UX enhancements completed:
  - Tapping a semester card opens a professionally styled detail sheet.
  - Header metrics in detail view were polished: GPA and Percentage enlarged and emphasized; Credits shown with lower visual priority.
  - Subject Breakdown rows now populate correctly from live result table.
  - Status field removed from subject rows in detail view.
  - Subject rows are tappable and open a dedicated subject-detail popup/sheet.
  - Subject popup displays CIA, Attendance, ESE, and Total marks in organized row-wise format.
  - Grade is highlighted prominently in subject popup.

- Academics parser/model expansion:
  - `SemesterRecord` now carries optional `detail`.
  - Added `SemesterRecordDetail` and `SemesterSubjectMark` rich models.
  - Parser extracts per-subject totals/credits/grade and component-wise marks fields (CIA/Attendance/ESE where available).
  - Subject row parsing was hardened against DOM variation (`<tr ...>` patterns) and summary/footer rows are filtered out.

- Home cleanup refinements completed:
  - Removed month/year leakage (e.g., `APRIL 2024`) from semester label composition.
  - Home program card subtitle now shows class (register/class label), not exam date text.
  - Profile section now shows course/program name (without date suffix).

- Current validated state:
  - Attendance: working and validated by user.
  - Home: working and validated by user.
  - Academics: cards + semester details + subject popups working and validated by user.
  - Next module to implement: Faculty live data flow.

## Next-session starting point

- Begin Faculty live-data integration:
  - Capture/verify exact request sequence for Faculty Location select and search details endpoint(s).
  - Ensure parser maps name/email/department/cabin/campus reliably from live HTML.
  - Validate with `PortalTrace[facultySelect]` (+ any faculty detail traces) and `PortalParse facultyCount=...`.
  - Then polish Faculty UI interactions if needed (search/chips/detail interactions) without breaking current styling.

*Last aligned with live portal integration and parser tuning under `ChristUni/` (Swift sources).*

## Latest context save (Apr 20, 2026 — night)

- Faculty live-data flow is now implemented and working with real session-dependent behavior:
  - Department suggestions are parsed from `deptNameList` in `facultyLocation` HTML.
  - Selecting a department triggers live `searchDetails` fetch and returns faculty for that department.
  - Local filtering works on top of selected department data (`name`, `email`, `campus`, `department`, `cabin`).
  - Missing fields render as `-`; email copy affordance is shown only when email exists.
  - Email tap copies to clipboard and shows a toast.
- Faculty session gating and UX:
  - Faculty is treated as real-time-only.
  - If session is missing/expired, Faculty tab shows only a real-time nudge card with `Login Again`.
  - Department search/filter/list UI is hidden in that state.
  - `Login Again` routes through WebView auth and refreshes data on successful cookie capture.
- Local caching:
  - Added persistent snapshot cache (`PortalSnapshotCacheStore`) to keep non-faculty data across app relaunches.
  - Snapshot cache excludes faculty by design.
  - Added `lastUpdatedAt` handling and launch toast: `Last updated X ago`.
  - Added refresh quality gate: empty/shell portal responses no longer overwrite valid cached data.
- Header behavior and refresh control:
  - Top-right bell replaced with refresh icon.
  - Refresh icon opens centered confirmation (`Login again?`) and transitions to login flow on confirm.
  - Header no longer animates on tab switches (stays visually stable).
- Profile photo caching:
  - Added `ProfilePhotoCacheStore` and in-memory `profilePhotoData` in `StudentPortalState`.
  - Photo is cached locally and reused in header to avoid repeated placeholder flicker during tab switches.
  - Header now prefers cached image data first, URL/Async fallback second.
- Faculty parser hardening:
  - Switched from class-based row parsing to row/cell parsing over all `<tr>/<td>` rows.
  - Filters only data rows with numeric serial number in first column.
  - Fixed prior alternating-row drops and compile type-inference issue with explicit closure typing.
- Build fixes included:
  - `FacultyHTMLParser`: explicit `[Faculty]` typing and closure return type to resolve generic inference error.
  - `AcademicsHTMLParser`: removed unused `examMonth` local.

## Latest context save (Apr 20, 2026 — late night, onboarding/touchups)

- Faculty parsing/status:
  - Faculty table parsing was further hardened to avoid missed alternating rows:
    - parser now scans generic `<tr>` rows and extracts `<td>` cells per row.
    - keeps only data rows with numeric serial in first cell.
    - maps name/email/department/location/campus by column position.
  - This replaced brittle class-bound row matching and fixed missing faculty entries in department results.

- Profile photo caching and header stability:
  - Added local profile photo cache (`ProfilePhotoCacheStore`) and `profilePhotoData` state.
  - On successful snapshot refresh, profile photo is fetched once and cached by URL; reused afterward.
  - Header uses cached image data first, then URL fallback.
  - Removed per-tab header enter animation so top bar remains visually stable across tab switches.

- First-launch onboarding guide:
  - Added one-time guided walkthrough in `MainTabView` with:
    - unofficial-app disclosure,
    - tab-by-tab explanations (Home/Academics/Attendance/Faculty),
    - final “Made with love by Karan (MCA 2026)” step.
  - Onboarding runs only once via persisted completion flag.

- Onboarding design upgrade (coach marks):
  - Replaced basic popup flow with professional spotlight walkthrough:
    - dimmed screen overlay,
    - circular highlight over the active tab icon,
    - modern coach card with contextual icon/title/message and step counter.
  - Navigation controls include icon-led Back/Skip/Next/Done actions.
  - Step transitions animate with directional slide+fade; spotlight movement is animated.

- Reinstall-safe onboarding trigger:
  - Added install marker file check in app support.
  - On true fresh install (marker absent), onboarding completion flag is reset to false.
  - Ensures onboarding reliably appears on first authenticated launch after reinstall.

- Final polish:
  - Added pulse/ripple animation around spotlight highlight during onboarding tab steps.
  - Includes layered ripple rings for subtle, premium focus guidance.

## Latest context save (Apr 21, 2026 — auth UX + stability pass)

- Faculty background loading reliability:
  - `StudentPortalState` now preloads faculty suggestions in background after successful authenticated refresh (`preloadFacultyInBackgroundIfNeeded`).
  - Faculty bootstrap is no longer tab-visibility dependent; quick tab switch-away no longer blocks eventual faculty readiness.
  - Added in-flight guard (`facultyTask == nil`) to avoid duplicate/racing initial faculty fetch calls.
  - Faculty task lifecycle cleanup improved (`defer { facultyTask = nil }`, explicit reset on cancel paths).
  - Reduced false session-expired UI flips by requiring repeated initial faculty fetch failures before setting `facultyNeedsRealtimeLogin = true`.

- Home attendance standing logic fix:
  - Replaced hardcoded “EXCELLENT STANDING” in `DashboardHomeView` with percentage bands:
    - `95...100`: Excellent
    - `90..<95`: Great
    - `85..<90`: Good
    - `80..<85`: Stable
    - `<80`: Low attendance
  - Low-attendance state now uses subtle yellow warning styling instead of positive-state colors.

- Pre-login entry experience added and then refined:
  - New pre-login screen introduced: `Views/Auth/PreLoginWelcomeView.swift`.
  - Current behavior is intentionally **first-install only** before WebView login.
  - Refresh icon flow and Faculty “Login Again” continue to bypass this screen and go straight to portal login.
  - Main routing is handled in `MainTabView` using persisted key `auth.prelogin.welcome.seen.v1`.

- Pre-login visual redesign + asset wiring:
  - Screen was redesigned to match provided reference style: cleaner single-card layout, sharper typography, smaller heading, premium spacing.
  - Typewriter text effect removed; replaced with subtle parallax-style ambient motion for a more professional feel.
  - Added proper logo asset integration:
    - created `ChristUni/Assets.xcassets/PreLoginLogo.imageset/`
    - copied `DesignReferences/logo.png` into the imageset as `logo.png`
    - pre-login screen now uses `Image("PreLoginLogo")`.

- Privacy notes/policy UX on pre-login:
  - Bottom-sheet privacy policy was restored and auto-opens shortly after pre-login screen appears.
  - Policy content explicitly states:
    - credentials are not stored,
    - data stays local on device,
    - app uses official portal session.
  - Fixed dismissal bug:
    - if sheet is swipe-dismissed before acceptance, user can still reopen it.
    - login CTA remains tappable and reopens policy when not accepted (instead of leaving user stuck with disabled button).
    - added explicit “View privacy notes” action for re-entry.

- Current expected state to validate on device:
  - First install -> pre-login screen -> privacy sheet auto-opens -> accept -> login to portal.
  - If privacy sheet is dismissed without acceptance -> tapping login reopens privacy sheet.
  - After first successful continue, pre-login no longer appears on normal logged-out entries unless install state is reset.
  - Faculty tab should be ready more reliably even if user quickly leaves the tab during initial load.

## Latest context save (Apr 23, 2026 — startup offline UX)

- Added non-blocking internet availability validation on app startup in `Views/MainTabView.swift`.
- Startup connectivity check now uses `NWPathMonitor` (one-time check per launch appearance).
- If internet is unavailable at startup, app shows a transient notice:
  - `No internet connection. Showing locally saved data.`
- Offline notice is informational only (does not block login UI, navigation, or tab exploration).
- Existing local snapshot/cache behavior remains unchanged; users can continue using locally available data when offline.
- Implementation cleanup:
  - monitor is cancelled and released after first path result,
  - additional cancellation occurs on `MainTabView` disappearance to avoid lingering monitor instances.

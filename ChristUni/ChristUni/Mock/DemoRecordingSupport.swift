//
//  DemoRecordingSupport.swift
//  ChristUni
//
//  MARK: Demo recording (SCREEN CAPTURE ONLY)
//  Safe on-device recordings without real portal data.
//
//  ─── Soft-disable (keep code, ship without UI) ───────────────────────────────
//  • Set `isEnabled` below to `false`.
//  • No other edits required; entry is blocked and login shows no demo control.
//
//  ─── Full removal (delete feature from codebase) ───────────────────────────
//  1. Delete these files / assets:
//     • `Mock/DemoRecordingSupport.swift` (this file)
//     • `Mock/DemoRecordingMockData.swift`
//     • `Mock/DemoRecordingProfileImage.swift`
//     • `Assets.xcassets/DemoRecordingProfile.imageset/`
//     • `Mock/mock.png` only if nothing else references it
//  2. `StudentPortalState.swift`:
//     • Remove `isDemoRecordingMode`, `enterDemoRecordingMode()`, and every
//       `guard`/branch on `isDemoRecordingMode` (refresh skip, faculty demo paths,
//       preload skip, demo profile photo assignment).
//     • Remove imports/usages of `DemoRecordingMockData` / `DemoRecordingProfileImage`.
//  3. `PortalLoginView.swift`: remove `onDemoRecordingRequested`, the demo button,
//     and `DemoRecordingSupport` checks; simplify initializer.
//  4. `MainTabView.swift`: stop passing `onDemoRecordingRequested` into the login view.
//  5. `FacultyDirectoryView.swift`: drop `showRealtimeOnly` / demo branch; use the
//     same realtime-only behavior as production (e.g. always require session rules).
//  6. Verify: `rg 'DemoRecording|isDemoRecordingMode|onDemoRecordingRequested'` → no hits.
//
//  Note: `DashboardHomeView`’s `profileCardPhotoContents` (profilePhotoData first)
//  is for live + cached sessions — not demo-specific; keep unless you want Home
//  to ignore cached photo bytes again.
//

import Foundation

enum DemoRecordingSupport {
    /// Gate for all demo-recording UI and entry points.
    static let isEnabled = true
}

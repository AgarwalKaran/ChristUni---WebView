//
//  DemoRecordingSupport.swift
//  ChristUni
//
//  MARK: Demo recording (SCREEN CAPTURE ONLY)
//  Enable for safe on-device recordings without real portal data.
//  To remove this feature completely:
//  1. Set `isEnabled` below to `false` (hides UI and blocks entry).
//  2. Delete: `DemoRecordingSupport.swift`, `DemoRecordingMockData.swift`, `DemoRecordingProfileImage.swift`,
//    `Assets.xcassets/DemoRecordingProfile.imageset`, and `Mock/mock.png` if unused.
//  3. Remove `isDemoRecordingMode` and `enterDemoRecordingMode()` from `StudentPortalState.swift`.
//  4. Remove demo branches in `selectFacultyDepartment` / `clearFacultyDepartmentSelection` / `refreshPortalData` /
//    `requestRelogin` / `logout` / `preloadFacultyInBackgroundIfNeeded`.
//  5. Revert `FacultyDirectoryView` `showRealtimeOnly` and `PortalLoginView` / `MainTabView` parameters.
//

import Foundation

enum DemoRecordingSupport {
    /// Gate for all demo-recording UI and entry points.
    static let isEnabled = true
}

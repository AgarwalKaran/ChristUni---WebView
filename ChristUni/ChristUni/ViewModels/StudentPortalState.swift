//
//  StudentPortalState.swift
//  ChristUni
//
//  Shared observable state for filters and tab selection.
//

import Foundation
import SwiftUI

enum PortalAuthState: Equatable {
    case loggedOut
    case loginInProgress
    case loadingData
    case authenticated
    case failed(String)
}

enum AttendanceSemesterScope: String, CaseIterable, Identifiable {
    case ongoing = "Ongoing"
    case completed = "Completed"
    var id: String { rawValue }
}

@MainActor @Observable
final class StudentPortalState {
    var snapshot: StudentPortalSnapshot
    var selectedTab: MainTab = .home
    var attendanceScope: AttendanceSemesterScope = .ongoing
    var selectedAttendanceBundleID: UUID?
    var facultySearchText: String = ""
    var facultyDepartmentQuery: String = ""
    var facultyDepartmentSuggestions: [String] = []
    var selectedFacultyDepartment: String?
    var isFacultyLoading: Bool = false
    var facultyNeedsRealtimeLogin: Bool = false
    var lastUpdatedAt: Date?
    var profilePhotoData: Data?
    var authState: PortalAuthState = .loggedOut
    var fetchDiagnostics: [String: String] = [:]

    private let repository: StudentPortalRepository
    private let authSessionStore: PortalAuthSessionStore
    private var refreshTask: Task<Void, Never>?
    private var facultyTask: Task<Void, Never>?
    private var facultyFetchFailureCount: Int = 0

    init(
        snapshot: StudentPortalSnapshot? = nil,
        repository: StudentPortalRepository? = nil,
        authSessionStore: PortalAuthSessionStore? = nil
    ) {
        let resolvedSnapshot = snapshot ?? MockStudentPortalData.snapshot
        let resolvedRepository = repository ?? LiveStudentPortalRepository()
        let resolvedAuthStore = authSessionStore ?? PortalAuthSessionStore()
        let cachedEnvelope = PortalSnapshotCacheStore().load()
        let profileCache = ProfilePhotoCacheStore()

        if let cached = cachedEnvelope {
            self.snapshot = cached.snapshot
            self.lastUpdatedAt = cached.updatedAt
        } else {
            self.snapshot = resolvedSnapshot
            self.lastUpdatedAt = nil
        }
        self.profilePhotoData = profileCache.loadData()
        self.repository = resolvedRepository
        self.authSessionStore = resolvedAuthStore
        if resolvedAuthStore.hasActiveSession {
            self.authState = .loadingData
        } else if cachedEnvelope != nil {
            self.authState = .authenticated
            self.facultyNeedsRealtimeLogin = true
        } else {
            self.authState = .loggedOut
        }
        if resolvedAuthStore.hasActiveSession {
            refreshPortalData()
        }
    }

    var filteredAttendanceBundle: SemesterAttendanceBundle? {
        let bundles = scopedAttendanceBundles
        if let selectedAttendanceBundleID,
           let selected = bundles.first(where: { $0.id == selectedAttendanceBundleID }) {
            return selected
        }
        return bundles.first
    }

    var scopedAttendanceBundles: [SemesterAttendanceBundle] {
        snapshot.attendanceBundles.filter { bundle in
            bundle.isOngoing == (attendanceScope == .ongoing)
        }
    }

    var facultyDepartments: [String] {
        if !facultyDepartmentSuggestions.isEmpty {
            return facultyDepartmentSuggestions
        }
        let set = Set(snapshot.faculty.map(\.department))
        return Array(set).sorted()
    }

    var matchingFacultyDepartmentSuggestions: [String] {
        let query = facultyDepartmentQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return Array(facultyDepartments.prefix(8)) }
        return facultyDepartments
            .filter { $0.lowercased().contains(query) }
            .prefix(8)
            .map { $0 }
    }

    var filteredFaculty: [Faculty] {
        guard selectedFacultyDepartment != nil, !facultyNeedsRealtimeLogin else { return [] }
        let q = facultySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return snapshot.faculty.filter { member in
            let deptOK = selectedFacultyDepartment == nil || member.department == selectedFacultyDepartment
            let searchOK = q.isEmpty
                || member.name.lowercased().contains(q)
                || member.department.lowercased().contains(q)
                || member.cabin.lowercased().contains(q)
                || member.campus.lowercased().contains(q)
                || member.email.lowercased().contains(q)
            return deptOK && searchOK
        }
    }

    var hasActivePortalSession: Bool {
        authSessionStore.hasActiveSession
    }

    func didCaptureLoginCookies(_ cookies: [HTTPCookie]) {
        do {
            try authSessionStore.persist(cookies: cookies)
            refreshPortalData()
        } catch {
            authState = .failed("Unable to save login session.")
        }
    }

    func beginLoginFlow() {
        authState = .loginInProgress
    }

    func refreshPortalData() {
        refreshTask?.cancel()
        authState = .loadingData
        refreshTask = Task { [repository, authSessionStore] in
            do {
                let payload = try await repository.fetchSnapshot()
                guard !Task.isCancelled else { return }
                let incoming = payload.snapshot
                let incomingIsMeaningful = Self.isMeaningfulSnapshot(incoming)
                if incomingIsMeaningful {
                    snapshot = incoming
                    selectedAttendanceBundleID = scopedAttendanceBundles.first?.id
                    facultyDepartmentSuggestions = Array(Set(snapshot.faculty.map(\.department))).sorted()
                    lastUpdatedAt = Date()
                    PortalSnapshotCacheStore().save(snapshot: snapshot, updatedAt: lastUpdatedAt ?? Date())
                    await cacheProfilePhotoIfNeeded(urlString: snapshot.student.profilePhotoURL)
                    facultyNeedsRealtimeLogin = !authSessionStore.hasActiveSession
                } else {
                    // Keep last good local data if portal returned an empty shell page.
                    facultyNeedsRealtimeLogin = true
                    if lastUpdatedAt == nil {
                        snapshot = incoming
                    }
                }
                fetchDiagnostics = payload.diagnostics
                authState = .authenticated
                preloadFacultyInBackgroundIfNeeded()
            } catch {
                guard !Task.isCancelled else { return }
                facultyNeedsRealtimeLogin = true
                if lastUpdatedAt != nil {
                    authState = .authenticated
                } else {
                    authState = .failed("Failed to fetch portal data. Please retry login.")
                }
            }
        }
    }

    func loadFacultySuggestionsIfNeeded() {
        guard facultyDepartmentSuggestions.isEmpty else { return }
        guard facultyTask == nil else { return }
        guard authSessionStore.hasActiveSession else {
            facultyNeedsRealtimeLogin = true
            isFacultyLoading = false
            return
        }

        // With an active session, treat initial fetch as background warm-up.
        facultyNeedsRealtimeLogin = false
        isFacultyLoading = true
        facultyTask = Task { [repository] in
            defer { facultyTask = nil }
            do {
                let payload = try await repository.fetchFacultyDirectory(department: nil, employeeName: nil)
                guard !Task.isCancelled else { return }
                guard !payload.departments.isEmpty else {
                    facultyFetchFailureCount += 1
                    if facultyFetchFailureCount >= 2 {
                        facultyNeedsRealtimeLogin = true
                    }
                    isFacultyLoading = false
                    return
                }
                facultyFetchFailureCount = 0
                facultyDepartmentSuggestions = payload.departments
                if !payload.faculty.isEmpty {
                    snapshot.faculty = payload.faculty
                }
                facultyNeedsRealtimeLogin = false
                isFacultyLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                facultyFetchFailureCount += 1
                if facultyFetchFailureCount >= 2 {
                    facultyNeedsRealtimeLogin = true
                }
                isFacultyLoading = false
            }
        }
    }

    func selectFacultyDepartment(_ department: String) {
        guard authSessionStore.hasActiveSession else {
            facultyNeedsRealtimeLogin = true
            return
        }
        facultyTask?.cancel()
        selectedFacultyDepartment = department
        facultyDepartmentQuery = department
        facultySearchText = ""
        isFacultyLoading = true
        facultyTask = Task { [repository] in
            defer { facultyTask = nil }
            do {
                let payload = try await repository.fetchFacultyDirectory(department: department, employeeName: nil)
                guard !Task.isCancelled else { return }
                guard !payload.departments.isEmpty || !payload.faculty.isEmpty else {
                    facultyNeedsRealtimeLogin = true
                    isFacultyLoading = false
                    return
                }
                if !payload.departments.isEmpty {
                    facultyDepartmentSuggestions = payload.departments
                }
                snapshot.faculty = payload.faculty
                facultyNeedsRealtimeLogin = false
                isFacultyLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                facultyNeedsRealtimeLogin = true
                isFacultyLoading = false
            }
        }
    }

    func clearFacultyDepartmentSelection() {
        facultyTask?.cancel()
        facultyTask = nil
        selectedFacultyDepartment = nil
        facultyDepartmentQuery = ""
        facultySearchText = ""
        snapshot.faculty = []
        if authSessionStore.hasActiveSession {
            loadFacultySuggestionsIfNeeded()
        } else {
            facultyNeedsRealtimeLogin = true
        }
    }

    func requestRelogin() {
        refreshTask?.cancel()
        facultyTask?.cancel()
        facultyTask = nil
        authSessionStore.clear()
        facultyNeedsRealtimeLogin = true
        authState = .loginInProgress
    }

    func lastUpdatedRelativeDescription(reference: Date = Date()) -> String? {
        guard let lastUpdatedAt else { return nil }
        let seconds = max(0, Int(reference.timeIntervalSince(lastUpdatedAt)))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60

        if days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        }
        if hours > 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        if minutes > 0 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }
        return "moments"
    }

    func logout() {
        refreshTask?.cancel()
        facultyTask?.cancel()
        facultyTask = nil
        authSessionStore.clear()
        snapshot = MockStudentPortalData.snapshot
        selectedTab = .home
        attendanceScope = .ongoing
        selectedAttendanceBundleID = nil
        facultySearchText = ""
        facultyDepartmentQuery = ""
        selectedFacultyDepartment = nil
        facultyDepartmentSuggestions = []
        isFacultyLoading = false
        facultyNeedsRealtimeLogin = false
        lastUpdatedAt = nil
        fetchDiagnostics = [:]
        facultyFetchFailureCount = 0
        authState = .loggedOut
        PortalSnapshotCacheStore().clear()
        ProfilePhotoCacheStore().clear()
        profilePhotoData = nil
    }

    private func preloadFacultyInBackgroundIfNeeded() {
        guard authSessionStore.hasActiveSession else { return }
        guard facultyDepartmentSuggestions.isEmpty else { return }
        loadFacultySuggestionsIfNeeded()
    }

    private static func isMeaningfulSnapshot(_ snapshot: StudentPortalSnapshot) -> Bool {
        let hasIdentity = snapshot.student.name != "Unavailable"
            || snapshot.student.registerNumber != "-"
            || snapshot.student.programTitle != "Unavailable"

        let hasAcademics = !snapshot.semesterRecords.isEmpty
            || snapshot.academicOverview.cumulativeGPA > 0
            || snapshot.academicOverview.overallPercentage > 0

        let hasAttendance = snapshot.attendanceBundles.contains { !$0.subjects.isEmpty }
            || snapshot.student.overallAttendancePercentage > 0

        return hasIdentity || hasAcademics || hasAttendance
    }

    private func cacheProfilePhotoIfNeeded(urlString: String?) async {
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw) else { return }

        let cache = ProfilePhotoCacheStore()
        if let cachedURL = cache.loadURLString(),
           cachedURL == raw,
           let cachedData = cache.loadData(),
           !cachedData.isEmpty {
            profilePhotoData = cachedData
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !data.isEmpty else { return }
            cache.save(data: data, urlString: raw)
            profilePhotoData = data
        } catch {
            // Ignore image fetch failures and continue with URL fallback.
        }
    }
}

enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case academics
    case attendance
    case faculty

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .academics: "Academics"
        case .attendance: "Attendance"
        case .faculty: "Faculty"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "square.grid.2x2"
        case .academics: "graduationcap"
        case .attendance: "calendar.badge.checkmark"
        case .faculty: "person.3"
        }
    }
}

//
//  AttendanceOverviewView.swift
//  ChristUni
//

import SwiftUI

struct AttendanceOverviewView: View {
    @Environment(StudentPortalState.self) private var portal

    @State private var screenReady = false
    @State private var subjectsReady = false
    @State private var heroPercentDisplay: Double = 0

    private var student: Student { portal.snapshot.student }
    private var selectedBundlePercentage: Double {
        guard let bundle = portal.filteredAttendanceBundle else { return 0 }
        let conducted = bundle.subjects.reduce(0) { $0 + $1.classesConducted }
        let present = bundle.subjects.reduce(0) { $0 + $1.present }
        guard conducted > 0 else { return 0 }
        return (Double(present) / Double(conducted)) * 100
    }
    private var groupedSubjects: [GroupedSubjectAttendance] {
        guard let bundle = portal.filteredAttendanceBundle else { return [] }
        var orderedKeys: [String] = []
        var grouped: [String: [SubjectAttendance]] = [:]

        for subject in bundle.subjects {
            let key = subject.subjectName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if grouped[key] == nil {
                orderedKeys.append(key)
                grouped[key] = []
            }
            grouped[key]?.append(subject)
        }

        return orderedKeys.compactMap { key in
            guard let entries = grouped[key], let first = entries.first else { return nil }
            return GroupedSubjectAttendance(
                id: first.id,
                subjectName: first.subjectName,
                entries: entries
            )
        }
    }

    private var initials: String {
        let parts = student.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        @Bindable var portal = portal

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ChristUniversityHeader(
                    studentInitials: initials,
                    profilePhotoURL: student.profilePhotoURL,
                    profilePhotoData: portal.profilePhotoData,
                    onLogout: portal.logout,
                    onRelogin: portal.requestRelogin
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Academic Standing")
                        .font(DesignTokens.FontStyle.label(11, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(Color.appSecondary)
                        .textCase(.uppercase)

                    HStack(alignment: .bottom) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", heroPercentDisplay))
                                .font(DesignTokens.FontStyle.headline(52, weight: .heavy))
                                .foregroundStyle(Color.appPrimary)
                                .contentTransition(.numericText())
                            Text("%")
                                .font(DesignTokens.FontStyle.headline(22, weight: .bold))
                                .foregroundStyle(Color.appSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Overall Attendance")
                                .font(DesignTokens.FontStyle.label(12, weight: .semibold))
                                .foregroundStyle(Color.appOnSurfaceVariant)
                                .textCase(.uppercase)
                            Text(portal.filteredAttendanceBundle?.semesterTitle ?? "—")
                                .font(DesignTokens.FontStyle.body(14, weight: .bold))
                                .foregroundStyle(Color.appPrimary)
                        }
                    }

                    KickstartProgressBar(
                        progress: heroPercentDisplay / 100,
                        isVisible: screenReady,
                        fill: Color.appSecondary,
                        fillDelay: 0.18
                    )
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .kickstartFadeUp(isVisible: screenReady, delay: 0.06)

                Picker("Scope", selection: $portal.attendanceScope) {
                    ForEach(AttendanceSemesterScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .kickstartFadeUp(isVisible: screenReady, delay: 0.12)

                if portal.scopedAttendanceBundles.count > 1 {
                    Picker("Semester", selection: Binding(
                        get: { portal.selectedAttendanceBundleID ?? portal.scopedAttendanceBundles.first?.id },
                        set: { portal.selectedAttendanceBundleID = $0 }
                    )) {
                        ForEach(portal.scopedAttendanceBundles) { bundle in
                            Text(bundle.semesterTitle).tag(Optional(bundle.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appPrimary)
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: screenReady, delay: 0.14)
                }

                if let bundle = portal.filteredAttendanceBundle {
                    VStack(spacing: 22) {
                        ForEach(Array(groupedSubjects.enumerated()), id: \.element.id) { index, subject in
                            subjectCard(subject, index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    Text("No attendance data for this selection.")
                        .font(DesignTokens.FontStyle.body(14, weight: .medium))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(Color.appSurface)
        .onAppear(perform: runAttendanceKickstart)
        .onChange(of: portal.attendanceScope) { _, _ in
            portal.selectedAttendanceBundleID = portal.scopedAttendanceBundles.first?.id
            withAnimation(.easeOut(duration: 0.6)) {
                heroPercentDisplay = selectedBundlePercentage
            }
            replaySubjectAnimations()
        }
        .onChange(of: portal.selectedAttendanceBundleID) { _, _ in
            withAnimation(.easeOut(duration: 0.6)) {
                heroPercentDisplay = selectedBundlePercentage
            }
            replaySubjectAnimations()
        }
    }

    private func runAttendanceKickstart() {
        let target = selectedBundlePercentage
        screenReady = false
        subjectsReady = false
        heroPercentDisplay = 0
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                screenReady = true
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.08)) {
                heroPercentDisplay = target
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86).delay(0.14)) {
                subjectsReady = true
            }
        }
    }

    private func replaySubjectAnimations() {
        subjectsReady = false
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                subjectsReady = true
            }
        }
    }

    private func subjectCard(_ subject: GroupedSubjectAttendance, index: Int) -> some View {
        let conducted = subject.entries.reduce(0) { $0 + $1.classesConducted }
        let present = subject.entries.reduce(0) { $0 + $1.present }
        let absent = subject.entries.reduce(0) { $0 + $1.absent }
        let pct = conducted > 0 ? (Double(present) / Double(conducted)) * 100 : 0
        let hasWarning = subject.entries.contains { $0.statusIsWarning }
        let stagger = 0.14 + Double(index) * 0.06

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(subject.entries.count > 1 ? "\(subject.entries.count) COMPONENTS" : "SINGLE COMPONENT")
                        .font(DesignTokens.FontStyle.label(10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(hasWarning ? Color.appSecondary : Color.appOnSurfaceVariant)

                    Text(subject.subjectName)
                        .font(DesignTokens.FontStyle.headline(20, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "%.2f%%", pct))
                        .font(DesignTokens.FontStyle.headline(24, weight: .heavy))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if hasWarning {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text("LOW ATTENDANCE")
                                .font(DesignTokens.FontStyle.label(10, weight: .bold))
                        }
                        .foregroundStyle(Color.appError)
                    }
                }
            }

            VStack(spacing: 10) {
                ForEach(Array(subject.entries.enumerated()), id: \.element.id) { _, entry in
                    componentRow(entry)
                }
                if subject.entries.count > 1 {
                    Divider().padding(.vertical, 2)
                    HStack {
                        statCell(title: "Total Conducted", value: "\(conducted)")
                        statCell(title: "Total Present", value: "\(present)")
                        statCell(title: "Total Absent", value: "\(absent)", emphasizeAbsent: absent > 0)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(22)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.appSecondary.opacity(0.1))
                .frame(width: 96, height: 96)
                .offset(x: 32, y: -32)
                .blur(radius: 20)
        }
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
        .kickstartFadeUp(isVisible: subjectsReady, delay: stagger)
    }

    private func componentRow(_ subject: SubjectAttendance) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subject.attendanceType.rawValue.uppercased())
                .font(DesignTokens.FontStyle.label(10, weight: .bold))
                .tracking(1)
                .foregroundStyle(subject.statusIsWarning ? Color.appSecondary : Color.appOnSurfaceVariant)

            HStack {
                statCell(title: "Conducted", value: "\(subject.classesConducted)")
                statCell(title: "Present", value: "\(subject.present)")
                statCell(title: "Absent", value: "\(subject.absent)", emphasizeAbsent: subject.absent > 0)
                statCell(title: "Percent", value: String(format: "%.2f%%", subject.percentage))
            }
        }
        .padding(12)
        .background(Color.appSurfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statCell(title: String, value: String, emphasizeAbsent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(DesignTokens.FontStyle.label(10, weight: .medium))
                .foregroundStyle(Color.appOnSurfaceVariant)
                .tracking(0.8)
            Text(value)
                .font(DesignTokens.FontStyle.headline(18, weight: .bold))
                .foregroundStyle(emphasizeAbsent ? Color.appSecondary : Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GroupedSubjectAttendance: Identifiable {
    let id: UUID
    let subjectName: String
    let entries: [SubjectAttendance]
}

#Preview {
    AttendanceOverviewView()
        .environment(StudentPortalState())
}

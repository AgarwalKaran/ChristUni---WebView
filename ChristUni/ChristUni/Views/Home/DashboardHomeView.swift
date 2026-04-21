//
//  DashboardHomeView.swift
//  ChristUni
//
//  Student profile dashboard — credits and class-rank lines omitted per v1 scope.
//

import SwiftUI

struct DashboardHomeView: View {
    @Environment(StudentPortalState.self) private var portal

    @State private var kickstarted = false
    @State private var ringFill: CGFloat = 0
    @State private var heroAttendanceDisplay: Double = 0
    @State private var showQuickActions = false

    private struct AttendanceStanding {
        let label: String
        let background: Color
        let foreground: Color
    }

    private var student: Student { portal.snapshot.student }
    private var ongoingAttendancePercentage: Double {
        guard let ongoing = portal.snapshot.attendanceBundles.first(where: { $0.isOngoing }) else {
            return student.overallAttendancePercentage
        }
        let conducted = ongoing.subjects.reduce(0) { $0 + $1.classesConducted }
        let present = ongoing.subjects.reduce(0) { $0 + $1.present }
        guard conducted > 0 else { return student.overallAttendancePercentage }
        return (Double(present) / Double(conducted)) * 100
    }
    private var displayProgramTitle: String {
        student.programTitle == "Unavailable" ? "Christ University Programme" : student.programTitle
    }
    private var displayMobile: String {
        let value = student.mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value.isEmpty || value == ":" || value == "-") ? "-" : value
    }
    private var displayEmail: String {
        let value = student.personalEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value.isEmpty || value == ":" || value == "-") ? "-" : value
    }

    private var initials: String {
        let parts = student.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private var attendanceStanding: AttendanceStanding {
        let pct = ongoingAttendancePercentage
        switch pct {
        case 95...100:
            return AttendanceStanding(
                label: "EXCELLENT STANDING",
                background: Color.appSecondaryContainer.opacity(0.35),
                foreground: Color.appOnSecondaryFixedVariant
            )
        case 90..<95:
            return AttendanceStanding(
                label: "GREAT STANDING",
                background: Color.appSecondaryContainer.opacity(0.28),
                foreground: Color.appOnSecondaryFixedVariant
            )
        case 85..<90:
            return AttendanceStanding(
                label: "GOOD STANDING",
                background: Color.appSurfaceLow,
                foreground: Color.appOnSurfaceVariant
            )
        case 80..<85:
            return AttendanceStanding(
                label: "STABLE STANDING",
                background: Color.appSurfaceLow,
                foreground: Color.appOnSurfaceVariant
            )
        default:
            return AttendanceStanding(
                label: "LOW ATTENDANCE",
                background: Color.yellow.opacity(0.18),
                foreground: Color.yellow.opacity(0.85)
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ChristUniversityHeader(
                    studentInitials: initials,
                    profilePhotoURL: student.profilePhotoURL,
                    profilePhotoData: portal.profilePhotoData,
                    onLogout: portal.logout,
                    onRelogin: portal.requestRelogin
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Academic Portfolio")
                        .font(DesignTokens.FontStyle.label(11, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(Color.appSecondary)
                        .textCase(.uppercase)

                    Text(student.name)
                        .font(DesignTokens.FontStyle.headline(32, weight: .heavy))
                        .foregroundStyle(Color.appPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        profileDetailRow(icon: "person.text.rectangle", text: student.registerNumber)
                        profileDetailRow(icon: "iphone", text: displayMobile)
                        profileDetailRow(icon: "envelope", text: displayEmail)
                    }
                    .font(DesignTokens.FontStyle.body(14, weight: .regular))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                }
                .padding(.horizontal, 20)
                .kickstartFadeUp(isVisible: kickstarted, delay: 0.06)

                profileCard
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.1)

                attendanceHero
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.12)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            portal.selectedTab = .attendance
                        }
                    }

                programCard
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.18)
                    .onTapGesture {
                        showQuickActions = true
                    }
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(Color.appSurface)
        .onAppear(perform: runHomeKickstart)
        .sheet(isPresented: $showQuickActions) {
            homeQuickActionsSheet
                .presentationDetents([.height(270)])
                .presentationDragIndicator(.visible)
        }
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurfaceLow)
                if let photo = student.profilePhotoURL, let url = URL(string: photo) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Text(initials)
                                .font(DesignTokens.FontStyle.headline(22, weight: .heavy))
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                } else {
                    Text(initials)
                        .font(DesignTokens.FontStyle.headline(22, weight: .heavy))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .frame(width: 88, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSurfaceHigh, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Profile")
                    .font(DesignTokens.FontStyle.label(11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .textCase(.uppercase)
                Text(student.name)
                    .font(DesignTokens.FontStyle.headline(18, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
                Text(displayProgramTitle)
                    .font(DesignTokens.FontStyle.body(13, weight: .medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                Text(displayEmail)
                    .font(DesignTokens.FontStyle.body(12, weight: .regular))
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
    }

    private func runHomeKickstart() {
        let pct = ongoingAttendancePercentage
        kickstarted = false
        ringFill = 0
        heroAttendanceDisplay = 0
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                kickstarted = true
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                heroAttendanceDisplay = pct
            }
            withAnimation(.easeOut(duration: 0.95).delay(0.16)) {
                ringFill = CGFloat(pct / 100)
            }
        }
    }

    private var attendanceHero: some View {
        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall Attendance")
                            .font(DesignTokens.FontStyle.label(12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Color.appOnSurfaceVariant)
                            .textCase(.uppercase)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.2f", heroAttendanceDisplay))
                                .font(DesignTokens.FontStyle.headline(52, weight: .black))
                                .foregroundStyle(Color.appPrimary)
                                .contentTransition(.numericText())
                            Text("%")
                                .font(DesignTokens.FontStyle.headline(26, weight: .bold))
                                .foregroundStyle(Color.appSecondary)
                        }

                        Text(attendanceStanding.label)
                            .font(DesignTokens.FontStyle.label(11, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(attendanceStanding.background)
                            .clipShape(Capsule())
                            .foregroundStyle(attendanceStanding.foreground)
                    }

                    Spacer(minLength: 8)

                    attendanceRing(progress: ringFill)
                        .frame(width: 112, height: 112)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .stroke(Color(hex: DesignTokens.ColorHex.surfaceContainerHigh).opacity(0.12), lineWidth: 1)
            )
            .shadow(
                color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
                radius: DesignTokens.Shadow.cardRadius,
                x: 0,
                y: DesignTokens.Shadow.cardY
            )

            Circle()
                .fill(Color.appPrimary.opacity(0.05))
                .frame(width: 160, height: 160)
                .offset(x: 40, y: -50)
                .blur(radius: 24)
        }
    }

    private func profileDetailRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.appOnSurfaceVariant)
                .frame(width: 18, alignment: .center)
            Text(text)
                .lineLimit(1)
        }
    }

    private func attendanceRing(progress: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.appSurfaceHigh, lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.appSecondary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 28))
                .foregroundStyle(Color.appSecondary)
        }
    }

    private var programCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurfaceLow)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(Color.appTertiary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayProgramTitle)
                    .font(DesignTokens.FontStyle.headline(16, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
                Text(student.registerNumber)
                    .font(DesignTokens.FontStyle.body(12, weight: .regular))
                    .foregroundStyle(Color.appOnSurfaceVariant)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.6))
        }
        .padding(20)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(0.03),
            radius: 8,
            x: 0,
            y: 2
        )
    }

    private var homeQuickActionsSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(DesignTokens.FontStyle.headline(20, weight: .bold))
                .foregroundStyle(Color.appPrimary)
            Text("Open your academic details directly.")
                .font(DesignTokens.FontStyle.body(13, weight: .regular))
                .foregroundStyle(Color.appOnSurfaceVariant)

            HStack(spacing: 12) {
                quickActionButton(
                    title: "Grades",
                    subtitle: "Open Academics",
                    icon: "graduationcap"
                ) {
                    showQuickActions = false
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        portal.selectedTab = .academics
                    }
                }
                quickActionButton(
                    title: "Attendance",
                    subtitle: "Open Attendance",
                    icon: "calendar.badge.checkmark"
                ) {
                    showQuickActions = false
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        portal.selectedTab = .attendance
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.appSurface)
    }

    private func quickActionButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.appSecondary)
                Text(title)
                    .font(DesignTokens.FontStyle.headline(16, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
                Text(subtitle)
                    .font(DesignTokens.FontStyle.body(12, weight: .medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(Color.appSurfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSurfaceHigh, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardHomeView()
        .environment(StudentPortalState())
}

//
//  AcademicsView.swift
//  ChristUni
//
//  Academic progression — no Latin honors, rank, credits, or season labels; GPA is /4.
//

import SwiftUI

struct AcademicsView: View {
    @Environment(StudentPortalState.self) private var portal

    @State private var kickstarted = false
    @State private var heroGPADisplay: Double = 0
    @State private var heroPercentDisplay: Double = 0
    @State private var selectedRecord: SemesterRecord?

    private var overview: AcademicOverview { portal.snapshot.academicOverview }
    private var records: [SemesterRecord] { portal.snapshot.semesterRecords }
    private var effectiveCumulativeGPA: Double {
        if overview.cumulativeGPA > 0 { return overview.cumulativeGPA }
        guard !records.isEmpty else { return 0 }
        return records.map(\.gpa).reduce(0, +) / Double(records.count)
    }
    private var effectiveOverallPercentage: Double {
        if overview.overallPercentage > 0 { return overview.overallPercentage }
        guard !records.isEmpty else { return 0 }
        return records.map(\.percentage).reduce(0, +) / Double(records.count)
    }

    private var student: Student { portal.snapshot.student }

    private var initials: String {
        let parts = student.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ChristUniversityHeader(
                    studentInitials: initials,
                    profilePhotoURL: student.profilePhotoURL,
                    profilePhotoData: portal.profilePhotoData,
                    onLogout: portal.logout,
                    onRelogin: portal.requestRelogin
                )

                hero
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.08)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Academic History")
                                .font(DesignTokens.FontStyle.headline(24, weight: .bold))
                                .foregroundStyle(Color.appPrimary)
                            Text("Detailed performance breakdown")
                                .font(DesignTokens.FontStyle.body(14, weight: .regular))
                                .foregroundStyle(Color.appOnSurfaceVariant)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.14)

                    VStack(spacing: 16) {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, row in
                            semesterCard(row, index: index)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                        selectedRecord = row
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                insightFooter
                    .padding(.horizontal, 20)
                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.2 + Double(min(records.count, 6)) * 0.05)
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(Color.appSurface)
        .onAppear(perform: runAcademicsKickstart)
        .sheet(item: $selectedRecord) { record in
            SemesterRecordDetailView(record: record)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func runAcademicsKickstart() {
        kickstarted = false
        heroGPADisplay = 0
        heroPercentDisplay = 0
        let g = effectiveCumulativeGPA
        let p = effectiveOverallPercentage
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                kickstarted = true
            }
            withAnimation(.easeOut(duration: 0.95).delay(0.08)) {
                heroGPADisplay = g
            }
            withAnimation(.easeOut(duration: 0.95).delay(0.12)) {
                heroPercentDisplay = p
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            Text("Cumulative Achievement")
                .font(DesignTokens.FontStyle.label(10, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.85))
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GPA")
                        .font(DesignTokens.FontStyle.label(10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .textCase(.uppercase)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", heroGPADisplay))
                            .font(DesignTokens.FontStyle.headline(44, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .contentTransition(.numericText())
                        Text("/ 4.0")
                            .font(DesignTokens.FontStyle.headline(16, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Percentage")
                        .font(DesignTokens.FontStyle.label(10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .textCase(.uppercase)
                    Text(String(format: "%.1f%%", heroPercentDisplay))
                        .font(DesignTokens.FontStyle.headline(44, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 4)

            KickstartProgressBar(
                progress: heroPercentDisplay / 100,
                isVisible: kickstarted,
                fill: Color.white.opacity(0.55),
                track: Color.white.opacity(0.18),
                height: 5,
                fillDelay: 0.22
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient.editorialPrimary)
                .shadow(color: Color.appPrimary.opacity(0.14), radius: 28, x: 0, y: 16)
        }
    }

    private func semesterCard(_ row: SemesterRecord, index: Int) -> some View {
        let stagger = 0.16 + Double(index) * 0.055
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(row.displayTitle.uppercased())
                    .font(DesignTokens.FontStyle.label(10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.appSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(String(format: "%.2f", row.gpa))
                    .font(DesignTokens.FontStyle.headline(30, weight: .heavy))
                    .foregroundStyle(Color.appPrimary)
                Text("GPA / 4.0")
                    .font(DesignTokens.FontStyle.label(9, weight: .medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                Text(String(format: "%.1f%%", row.percentage))
                    .font(DesignTokens.FontStyle.headline(17, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
                Text("Percentage")
                    .font(DesignTokens.FontStyle.label(9, weight: .medium))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                HStack(spacing: 4) {
                    Text("View Details")
                        .font(DesignTokens.FontStyle.label(10, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(Color.appSecondary)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
        .kickstartFadeUp(isVisible: kickstarted, delay: stagger)
    }

    private var insightFooter: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appSecondaryContainer)
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.appSecondary)
                }
            VStack(alignment: .leading, spacing: 6) {
                Text("Upward Trajectory")
                    .font(DesignTokens.FontStyle.headline(16, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
                Text("Your performance has improved steadily over recent terms. Keep the momentum.")
                    .font(DesignTokens.FontStyle.body(12, weight: .regular))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(Color.appSurfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    AcademicsView()
        .environment(StudentPortalState())
}

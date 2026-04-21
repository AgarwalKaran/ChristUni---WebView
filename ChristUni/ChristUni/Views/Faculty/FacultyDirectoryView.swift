//
//  FacultyDirectoryView.swift
//  ChristUni
//
//  Faculty list — no role tags or photos (v1).
//

import SwiftUI

struct FacultyDirectoryView: View {
    @Environment(StudentPortalState.self) private var portal

    @FocusState private var isDepartmentFieldFocused: Bool
    @FocusState private var isFacultyFilterFieldFocused: Bool
    @State private var kickstarted = false
    @State private var copiedEmailToast = false

    private var student: Student { portal.snapshot.student }

    private var initials: String {
        let parts = student.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        @Bindable var portal = portal
        let showRealtimeOnly = portal.facultyNeedsRealtimeLogin || !portal.hasActivePortalSession

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ChristUniversityHeader(
                    studentInitials: initials,
                    profilePhotoURL: student.profilePhotoURL,
                    profilePhotoData: portal.profilePhotoData,
                    onLogout: portal.logout,
                    onRelogin: portal.requestRelogin
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Faculty Directory")
                        .font(DesignTokens.FontStyle.headline(30, weight: .heavy))
                        .foregroundStyle(Color.appPrimary)
                    Text(showRealtimeOnly
                         ? "This module requires a live portal session."
                         : "Search a department, then refine by faculty details.")
                        .font(DesignTokens.FontStyle.body(15, weight: .regular))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
                .padding(.horizontal, 20)
                .kickstartFadeUp(isVisible: kickstarted, delay: 0.06)

                if showRealtimeOnly {
                    realtimeNudgeCard(portal: portal)
                        .padding(.horizontal, 20)
                        .kickstartFadeUp(isVisible: kickstarted, delay: 0.08)
                } else {
                    departmentSearchCard(portal: portal)
                        .padding(.horizontal, 20)
                        .kickstartFadeUp(isVisible: kickstarted, delay: 0.1)

                    searchField(text: $portal.facultySearchText)
                        .padding(.horizontal, 20)
                        .kickstartFadeUp(isVisible: kickstarted, delay: 0.14)

                    if portal.selectedFacultyDepartment == nil {
                        emptyFacultyState
                            .padding(.horizontal, 20)
                            .kickstartFadeUp(isVisible: kickstarted, delay: 0.18)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(portal.filteredFaculty.enumerated()), id: \.element.id) { index, member in
                                facultyCard(member)
                                    .kickstartFadeUp(isVisible: kickstarted, delay: 0.18 + Double(index) * 0.055)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(Color.appSurface)
        .onAppear {
            portal.loadFacultySuggestionsIfNeeded()
            kickstarted = false
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                    kickstarted = true
                }
            }
        }
        .overlay(alignment: .bottom) {
            if copiedEmailToast {
                Text("Email copied")
                    .font(DesignTokens.FontStyle.label(13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: copiedEmailToast)
    }

    private func departmentSearchCard(portal: StudentPortalState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "building.2")
                    .foregroundStyle(Color.appOnSurfaceVariant)
                TextField("Search department…", text: binding(for: portal))
                    .font(DesignTokens.FontStyle.body(16, weight: .regular))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($isDepartmentFieldFocused)
                if portal.isFacultyLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }

            if let selected = portal.selectedFacultyDepartment {
                HStack {
                    Text("Selected: \(selected)")
                        .font(DesignTokens.FontStyle.body(13, weight: .medium))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                    Spacer()
                    Button("Clear") {
                        portal.clearFacultyDepartmentSelection()
                        isDepartmentFieldFocused = false
                        isFacultyFilterFieldFocused = false
                    }
                        .font(DesignTokens.FontStyle.label(12, weight: .semibold))
                }
            }

            if !portal.facultyDepartmentQuery.isEmpty, portal.selectedFacultyDepartment != portal.facultyDepartmentQuery {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(portal.matchingFacultyDepartmentSuggestions, id: \.self) { department in
                        Button {
                            portal.selectFacultyDepartment(department)
                            isDepartmentFieldFocused = false
                        } label: {
                            HStack {
                                Text(department)
                                    .font(DesignTokens.FontStyle.body(14, weight: .medium))
                                    .foregroundStyle(Color.appOnSurface)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.appOnSurfaceVariant)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.appSurfaceLow)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
    }

    private func searchField(text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appOnSurfaceVariant)
            TextField("Filter by name, email, campus, department…", text: text)
                .font(DesignTokens.FontStyle.body(16, weight: .regular))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFacultyFilterFieldFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
    }

    private func binding(for portal: StudentPortalState) -> Binding<String> {
        Binding(
            get: { portal.facultyDepartmentQuery },
            set: { portal.facultyDepartmentQuery = $0 }
        )
    }

    private func facultyCard(_ member: Faculty) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(normalized(member.name))
                .font(DesignTokens.FontStyle.headline(18, weight: .bold))
                .foregroundStyle(Color.appPrimary)
                .padding(.bottom, 14)

            Divider()
                .background(Color.appSurfaceLow)

            VStack(alignment: .leading, spacing: 12) {
                row(icon: "building.columns", text: normalized(member.department))
                tappableEmailRow(member.email)
                row(icon: "door.left.hand.closed", text: normalized(member.cabin))
                row(icon: "mappin.and.ellipse", text: normalized(member.campus))
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
            radius: DesignTokens.Shadow.cardRadius,
            x: 0,
            y: DesignTokens.Shadow.cardY
        )
    }

    private func row(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.55))
                .frame(width: 22)
            Text(text)
                .font(DesignTokens.FontStyle.body(14, weight: .regular))
                .foregroundStyle(icon == "envelope" ? Color.appOnSurface : Color.appOnSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyFacultyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.8))
            Text("Select a department to view faculty list.")
                .font(DesignTokens.FontStyle.body(15, weight: .medium))
                .foregroundStyle(Color.appOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func realtimeNudgeCard(portal: StudentPortalState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This is a real-time feature.")
                .font(DesignTokens.FontStyle.headline(16, weight: .bold))
                .foregroundStyle(Color.appPrimary)
            Text("Your portal session has expired. Login again to fetch latest faculty data.")
                .font(DesignTokens.FontStyle.body(13, weight: .regular))
                .foregroundStyle(Color.appOnSurfaceVariant)
            Button("Login Again") {
                portal.requestRelogin()
            }
            .font(DesignTokens.FontStyle.label(12, weight: .semibold))
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func tappableEmailRow(_ email: String) -> some View {
        let value = normalized(email)
        let canCopy = value != "-"
        if !canCopy {
            row(icon: "envelope", text: value)
        } else {
            Button {
                #if canImport(UIKit)
                UIPasteboard.general.string = value
                #endif
                copiedEmailToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    copiedEmailToast = false
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "envelope")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.55))
                        .frame(width: 22)
                    Text(value)
                        .font(DesignTokens.FontStyle.body(14, weight: .regular))
                        .foregroundStyle(Color.appOnSurface)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func normalized(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "-" : trimmed
    }
}

#Preview {
    FacultyDirectoryView()
        .environment(StudentPortalState())
}

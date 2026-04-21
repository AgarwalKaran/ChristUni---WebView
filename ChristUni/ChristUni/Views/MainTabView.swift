//
//  MainTabView.swift
//  ChristUni
//
//  Root shell: one shared StudentPortalState + custom floating tab bar.
//

import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var portalState = StudentPortalState()
    @State private var showLastUpdatedToast = false
    @State private var hasPresentedLastUpdatedToast = false
    @State private var showOnboarding = false
    @State private var onboardingStepIndex = 0
    @State private var onboardingDirection: CGFloat = 1
    @State private var spotlightPulse = false
    @State private var showPreLoginWelcome = false

    private let onboardingDefaultsKey = "app.onboarding.completed.v1"
    private let installMarkerFilename = "christuni.install.marker"
    private let firstInstallWelcomeSeenKey = "auth.prelogin.welcome.seen.v1"

    var body: some View {
        @Bindable var portalState = portalState

        GeometryReader { geometry in
            ZStack {
                Color.appSurface.ignoresSafeArea()

                switch portalState.authState {
                case .loggedOut, .loginInProgress:
                    if portalState.authState == .loggedOut && showPreLoginWelcome {
                        PreLoginWelcomeView {
                            UserDefaults.standard.set(true, forKey: firstInstallWelcomeSeenKey)
                            showPreLoginWelcome = false
                            portalState.beginLoginFlow()
                        }
                    } else {
                        PortalLoginView { cookies in
                            portalState.didCaptureLoginCookies(cookies)
                        }
                    }
                case .loadingData:
                    ProgressView("Fetching authenticated data...")
                        .font(DesignTokens.FontStyle.body(14, weight: .medium))
                case .failed(let message):
                    VStack(spacing: 14) {
                        Text(message)
                            .font(DesignTokens.FontStyle.body(14, weight: .medium))
                            .foregroundStyle(Color.appOnSurfaceVariant)
                        HStack(spacing: 10) {
                            Button("Retry") { portalState.refreshPortalData() }
                            Button("Logout") { portalState.logout() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(24)
                case .authenticated:
                    ZStack(alignment: .bottom) {
                        Group {
                            switch portalState.selectedTab {
                            case .home:
                                DashboardHomeView()
                            case .academics:
                                AcademicsView()
                            case .attendance:
                                AttendanceOverviewView()
                            case .faculty:
                                FacultyDirectoryView()
                            }
                        }
                        .environment(portalState)

                        FloatingTabBar(selectedTab: $portalState.selectedTab)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 6)
                    }
                }

                if showLastUpdatedToast,
                   let relative = portalState.lastUpdatedRelativeDescription() {
                    VStack {
                        Spacer()
                        Text("Last updated \(relative) ago")
                            .font(DesignTokens.FontStyle.label(13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.appPrimary)
                            .foregroundStyle(Color.white)
                            .clipShape(Capsule())
                            .padding(.bottom, 118)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
                }

                if showOnboarding {
                    onboardingSpotlightOverlay(in: geometry)
                        .zIndex(1400)

                    onboardingCoachCard(portalState: portalState)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 110)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .zIndex(1401)
                }
            }
        }
        .tint(Color.appPrimary)
        .onChange(of: portalState.authState) { _, newValue in
            guard newValue == .authenticated else { return }
            presentLastUpdatedToastIfNeeded()
            startOnboardingIfNeeded(portalState: portalState)
        }
        .onAppear {
            normalizeOnboardingStateForFreshInstall()
            syncPreLoginWelcomeState()
            presentLastUpdatedToastIfNeeded()
            startOnboardingIfNeeded(portalState: portalState)
            startSpotlightPulse()
        }
        .onChange(of: portalState.authState) { _, _ in
            syncPreLoginWelcomeState()
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: showLastUpdatedToast)
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: showOnboarding)
        .animation(.easeInOut(duration: 0.28), value: onboardingStepIndex)
    }

    private func presentLastUpdatedToastIfNeeded() {
        guard !hasPresentedLastUpdatedToast else { return }
        guard portalState.authState == .authenticated else { return }
        guard portalState.lastUpdatedRelativeDescription() != nil else { return }
        hasPresentedLastUpdatedToast = true
        showLastUpdatedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showLastUpdatedToast = false
        }
    }

    private func startOnboardingIfNeeded(portalState: StudentPortalState) {
        guard portalState.authState == .authenticated else { return }
        guard !UserDefaults.standard.bool(forKey: onboardingDefaultsKey) else { return }
        guard !showOnboarding else { return }
        onboardingDirection = 1
        onboardingStepIndex = 0
        showOnboarding = true
        if let tab = onboardingSteps.first?.tab {
            portalState.selectedTab = tab
        }
    }

    @ViewBuilder
    private func onboardingCoachCard(portalState: StudentPortalState) -> some View {
        let step = onboardingSteps[onboardingStepIndex]
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: step.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 30, height: 30)
                        .background(Color.appSurfaceLow)
                        .clipShape(Circle())
                    Text(step.title)
                        .font(DesignTokens.FontStyle.headline(18, weight: .bold))
                        .foregroundStyle(Color.appPrimary)
                    Spacer()
                    Text("\(onboardingStepIndex + 1)/\(onboardingSteps.count)")
                        .font(DesignTokens.FontStyle.label(11, weight: .medium))
                        .foregroundStyle(Color.appOnSurfaceVariant)
                }

                Text(step.message)
                    .font(DesignTokens.FontStyle.body(14, weight: .regular))
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .id(onboardingStepIndex)
            .transition(
                .asymmetric(
                    insertion: .move(edge: onboardingDirection > 0 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: onboardingDirection > 0 ? .leading : .trailing).combined(with: .opacity)
                )
            )

            HStack(spacing: 12) {
                if onboardingStepIndex > 0 {
                    Button {
                        moveOnboardingStep(direction: -1, portalState: portalState)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    completeOnboarding()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)

                Button {
                    if onboardingStepIndex == onboardingSteps.count - 1 {
                        completeOnboarding()
                    } else {
                        moveOnboardingStep(direction: 1, portalState: portalState)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(onboardingStepIndex == onboardingSteps.count - 1 ? "Done" : "Next")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(DesignTokens.FontStyle.label(12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(Color.appSurfaceLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: Color.black.opacity(0.18),
            radius: 20,
            x: 0,
            y: 10
        )
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingDefaultsKey)
        showOnboarding = false
    }

    private func moveOnboardingStep(direction: Int, portalState: StudentPortalState) {
        let next = onboardingStepIndex + direction
        guard next >= 0, next < onboardingSteps.count else { return }
        onboardingDirection = direction >= 0 ? 1 : -1
        withAnimation(.easeInOut(duration: 0.24)) {
            onboardingStepIndex = next
        }
        if let tab = onboardingSteps[next].tab {
            withAnimation(.easeInOut(duration: 0.26)) {
                portalState.selectedTab = tab
            }
        }
    }

    private func normalizeOnboardingStateForFreshInstall() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let markerURL = appSupport.appendingPathComponent(installMarkerFilename)
        if !FileManager.default.fileExists(atPath: markerURL.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: markerURL.path, contents: Data("installed".utf8))
            UserDefaults.standard.set(false, forKey: onboardingDefaultsKey)
        }
    }

    private func syncPreLoginWelcomeState() {
        guard portalState.authState == .loggedOut else {
            showPreLoginWelcome = false
            return
        }

        let hasSeenWelcome = UserDefaults.standard.bool(forKey: firstInstallWelcomeSeenKey)
        showPreLoginWelcome = !hasSeenWelcome
    }

    private var onboardingSteps: [OnboardingStep] {
        [
            OnboardingStep(
                tab: .home,
                title: "Welcome to ChristUni",
                message: "This is an unofficial student companion app. It helps you quickly access your portal data in a clean, native experience.",
                icon: "sparkles"
            ),
            OnboardingStep(
                tab: .home,
                title: "Home Tab",
                message: "See your profile details, current class info, and overall attendance snapshot in one place.",
                icon: "house.fill"
            ),
            OnboardingStep(
                tab: .academics,
                title: "Academics Tab",
                message: "View semester-wise GPA and percentage, then open each semester for detailed subject-wise marks.",
                icon: "graduationcap.fill"
            ),
            OnboardingStep(
                tab: .attendance,
                title: "Attendance Tab",
                message: "Track ongoing and completed-semester attendance with subject and component-wise breakdown.",
                icon: "calendar.badge.checkmark"
            ),
            OnboardingStep(
                tab: .faculty,
                title: "Faculty Tab",
                message: "Search departments and explore faculty details. This is a real-time feature and may require active session login.",
                icon: "person.3.fill"
            ),
            OnboardingStep(
                tab: nil,
                title: "Made with Love",
                message: "Made with love by Karan (MCA 2026).",
                icon: "heart.fill"
            )
        ]
    }

    @ViewBuilder
    private func onboardingSpotlightOverlay(in geometry: GeometryProxy) -> some View {
        if let tab = onboardingSteps[onboardingStepIndex].tab {
            let center = spotlightCenter(for: tab, in: geometry)
            let radius: CGFloat = 34
            Rectangle()
                .fill(Color.black.opacity(0.62))
                .overlay {
                    Circle()
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.95), lineWidth: 2)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                        .shadow(color: Color.white.opacity(0.35), radius: 10)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(spotlightPulse ? 0 : 0.55), lineWidth: 2)
                        .frame(width: radius * 2, height: radius * 2)
                        .scaleEffect(spotlightPulse ? 1.45 : 1.02)
                        .position(center)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(spotlightPulse ? 0 : 0.35), lineWidth: 1.5)
                        .frame(width: radius * 2, height: radius * 2)
                        .scaleEffect(spotlightPulse ? 1.72 : 1.04)
                        .position(center)
                }
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.26), value: onboardingStepIndex)
        } else {
            Color.black.opacity(0.62).ignoresSafeArea()
        }
    }

    private func spotlightCenter(for tab: MainTab, in geometry: GeometryProxy) -> CGPoint {
        let count = CGFloat(MainTab.allCases.count)
        let index = CGFloat(tab.rawValue)
        let horizontalPadding: CGFloat = 12
        let barWidth = geometry.size.width - (horizontalPadding * 2)
        let x = horizontalPadding + (barWidth * ((index + 0.5) / count))
        let y = geometry.size.height - 58
        return CGPoint(x: x, y: y)
    }

    private func startSpotlightPulse() {
        guard !spotlightPulse else { return }
        withAnimation(.easeOut(duration: 1.25).repeatForever(autoreverses: false)) {
            spotlightPulse = true
        }
    }
}

private struct OnboardingStep {
    let tab: MainTab?
    let title: String
    let message: String
    let icon: String
}

#Preview {
    MainTabView()
}

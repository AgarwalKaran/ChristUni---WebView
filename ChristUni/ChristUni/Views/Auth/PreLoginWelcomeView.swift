import SwiftUI

struct PreLoginWelcomeView: View {
    let onContinue: () -> Void

    @State private var animateParallax = false
    @State private var showPrivacySheet = false
    @State private var hasAcceptedPrivacy = false

    var body: some View {
        ZStack {
            Color(hex: "f2f2f7")
                .ignoresSafeArea()

            Circle()
                .fill(Color.appPrimary.opacity(0.1))
                .frame(width: 320, height: 320)
                .blur(radius: 36)
                .offset(x: animateParallax ? 122 : 140, y: animateParallax ? -250 : -270)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateParallax)

            Circle()
                .fill(Color.appSecondaryContainer.opacity(0.22))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: animateParallax ? -118 : -138, y: animateParallax ? -218 : -196)
                .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: animateParallax)

            VStack(spacing: 18) {
                card

                Text("OFFICIAL ACADEMIC PORTAL")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .tracking(1.4)
                    .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.72))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .sheet(isPresented: $showPrivacySheet) {
            privacySheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            animateParallax = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showPrivacySheet = true
            }
        }
    }

    private var card: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 118, height: 118)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                Circle()
                    .stroke(Color.appSurfaceHigh, lineWidth: 1)
                    .frame(width: 118, height: 118)
                Image("PreLoginLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 98, height: 98)
                    .clipShape(Circle())
            }
            .padding(.top, 6)
            .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
            .offset(y: animateParallax ? -2 : 2)
            .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: animateParallax)

            VStack(spacing: 12) {
                Text("Welcome to\nChristUni")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your all-in-one companion for academics, attendance, and faculty connection. Please log in through the official university portal to continue.")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.appOnSurfaceVariant)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                privacyLine("We do not store login credentials.")
                privacyLine("Data stays locally on your device.")
                privacyLine("Uses your official portal session.")
                Text("Unofficial app, not affiliated with Christ University.")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.78))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 6)

            Button {
                if hasAcceptedPrivacy {
                    onContinue()
                } else {
                    showPrivacySheet = true
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Text("Login to Portal")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundStyle(Color.white)
                .padding(.vertical, 18)
                .background(Color.appPrimary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .opacity(hasAcceptedPrivacy ? 1 : 0.86)

            if !hasAcceptedPrivacy {
                Button("View privacy notes") {
                    showPrivacySheet = true
                }
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundStyle(Color.appOnSurfaceVariant)
                .buttonStyle(.plain)
            }
    }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "ededf2"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private var privacySheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Policy")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundStyle(Color.appPrimary)

            Text("Please review before continuing:")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundStyle(Color.appOnSurfaceVariant)

            privacySheetPoint("We do not store your login credentials.")
            privacySheetPoint("Your fetched portal data stays locally on your device.")
            privacySheetPoint("The app works using your official portal session.")

            Spacer(minLength: 8)

            Button {
                hasAcceptedPrivacy = true
                showPrivacySheet = false
            } label: {
                Text("I Understand")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .padding(22)
        .background(Color.appSurface)
    }

    private func privacyLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.78))
            Text(text)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundStyle(Color.appOnSurfaceVariant.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func privacySheetPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appSecondary)
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundStyle(Color.appOnSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PreLoginWelcomeView(onContinue: {})
}

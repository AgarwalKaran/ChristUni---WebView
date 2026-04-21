//
//  ChristUniversityHeader.swift
//  ChristUni
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ChristUniversityHeader: View {
    var studentInitials: String
    var profilePhotoURL: String? = nil
    var profilePhotoData: Data? = nil
    var onLogout: (() -> Void)? = nil
    var onRelogin: (() -> Void)? = nil
    @State private var showLogoutConfirmation = false
    @State private var showReloginConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            profileBadge

            Text("Christ University")
                .font(DesignTokens.FontStyle.headline(18, weight: .bold))
                .foregroundStyle(Color.appPrimary)

            Spacer(minLength: 0)

            if let onLogout {
                Button {
                    showLogoutConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Logout")
                            .font(DesignTokens.FontStyle.body(12, weight: .semibold))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.appSurfaceLowest)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.appSurfaceHigh, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Log out of your portal session?",
                    isPresented: $showLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Log Out", role: .destructive, action: onLogout)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You will need to sign in again to access live data.")
                }
            }

            if let onRelogin {
                Button {
                    showReloginConfirmation = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)
                .alert("Login again?", isPresented: $showReloginConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Login Again") {
                        onRelogin()
                    }
                } message: {
                    Text("You will be taken to the login screen to refresh your portal session.")
                }
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appSurface)
    }

    private var profileBadge: some View {
        ZStack {
            Circle().fill(Color.appSurfaceHigh)
            if let profilePhotoData,
               let image = UIImage(data: profilePhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let profilePhotoURL,
                      let url = URL(string: profilePhotoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.appSurfaceHigh, lineWidth: 1)
        )
    }

    private var initialsView: some View {
        Text(studentInitials)
            .font(DesignTokens.FontStyle.headline(14, weight: .bold))
            .foregroundStyle(Color.appPrimary)
    }
}

//
//  FloatingTabBar.swift
//  ChristUni
//
//  Floating dock tab bar — fully rounded “pill” card.
//

import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                            .symbolVariant(isSelected ? .fill : .none)
                        Text(tab.title)
                            .font(DesignTokens.FontStyle.label(10, weight: .medium))
                            .tracking(0.8)
                        if isSelected {
                            Circle()
                                .fill(Color.appSecondary)
                                .frame(width: 4, height: 4)
                        } else {
                            Color.clear.frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appOnSurfaceVariant.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.tabBar, style: .continuous)
                // Solid stack (no system material) so appearance matches the editorial spec.
                .fill(Color.appSurfaceLowest.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.tabBar, style: .continuous)
                        .stroke(Color.appOnSurface.opacity(0.06), lineWidth: 1)
                }
                .shadow(
                    color: Color.appPrimary.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 4
                )
        }
    }
}

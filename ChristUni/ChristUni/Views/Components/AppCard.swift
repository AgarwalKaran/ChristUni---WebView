//
//  AppCard.swift
//  ChristUni
//

import SwiftUI

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.appSurfaceLowest)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .shadow(
                color: Color.appPrimary.opacity(DesignTokens.Shadow.cardOpacity),
                radius: DesignTokens.Shadow.cardRadius,
                x: 0,
                y: DesignTokens.Shadow.cardY
            )
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }
}

//
//  KickstartAnimations.swift
//  ChristUni
//
//  Lightweight “screen open” motion — fade, rise, and optional progress fills.
//

import SwiftUI

extension View {
    /// Opacity + slight upward move when `isVisible` flips to `true`; use staggered `delay` per row.
    func kickstartFadeUp(isVisible: Bool, delay: Double = 0) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 14)
            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(delay), value: isVisible)
    }
}

/// Thin bar that grows from 0 to `progress` (0...1) when `isVisible` becomes true.
struct KickstartProgressBar: View {
    var progress: Double
    var isVisible: Bool
    var fill: Color = Color.appSecondary
    var track: Color = Color.appSurfaceHigh
    var height: CGFloat = 4
    /// Extra delay before the fill runs (useful for staggered cards).
    var fillDelay: Double = 0.12

    var body: some View {
        GeometryReader { geo in
            let width = max(0, min(1, progress)) * geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: isVisible ? width : 0)
                    .animation(.easeOut(duration: 0.85).delay(fillDelay), value: isVisible)
            }
        }
        .frame(height: height)
    }
}

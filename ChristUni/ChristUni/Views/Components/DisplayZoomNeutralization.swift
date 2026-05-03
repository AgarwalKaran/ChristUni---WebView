//
//  DisplayZoomNeutralization.swift
//  ChristUni
//
//  Keeps typography + layout proportional to Display Zoom "Standard" by neutralizing the system "zoomed/larger display" mode.
//

import SwiftUI
import UIKit

enum DisplayZoomNeutralization {
    /// Returns the portrait **minimum** logical side length Apple uses when Display Zoom is **off**, inferred from pixel `nativeBounds`.
    private static func standardPortraitMinSide(forNativeBounds native: CGRect) -> CGFloat? {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return nil }
        let w = Int(native.width.rounded(.toNearestOrAwayFromZero))
        let h = Int(native.height.rounded(.toNearestOrAwayFromZero))
        let low = Swift.min(w, h)
        let high = Swift.max(w, h)
        return nativePixelPortraitTable["\(low)x\(high)"]
    }

    /// Uniform layout scale (< 1 under Display Zoom) that brings zoomed layouts back toward standard perceived sizing.
    static func neutralizationScale(layoutSize: CGSize, screen: UIScreen = .main) -> CGFloat {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return 1 }
        guard let standardMinSide = standardPortraitMinSide(forNativeBounds: screen.nativeBounds) else { return 1 }

        let currentMinSide = Swift.min(layoutSize.width, layoutSize.height)
        guard currentMinSide.isFinite, standardMinSide.isFinite else { return 1 }

        let raw = currentMinSide / standardMinSide
        if raw > 1.002 { return 1 }
        if raw >= 1 { return min(1, raw) }

        guard raw >= 0.65 else { return 1 }
        return raw
    }

    /// Keyed by canonical `nativeBounds` pixels `min(nativeW,nativeH)xmax(...)` (hardware is unchanged across Display Zoom).
    /// Portrait **short side** in points when Zoom is **off**. Unknown panels skip neutralization.
    private static let nativePixelPortraitTable: [String: CGFloat] = [
        "640x1136": 320,
        "750x1334": 375,
        "828x1792": 414,
        "1080x1920": 414,
        "1080x2340": 360,
        "1125x2436": 375,
        "1170x2532": 390,
        "1179x2556": 393,
        "1242x2688": 414,
        "1284x2778": 428,
        "1290x2796": 430,
    ]
}

// MARK: -

struct DisplayZoomNeutralizingRoot<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let s = DisplayZoomNeutralization.neutralizationScale(layoutSize: geo.size)

            Group {
                if s < 0.997 {
                    content
                        .scaleEffect(s, anchor: .topLeading)
                        .frame(
                            width: geo.size.width / s,
                            height: geo.size.height / s,
                            alignment: .topLeading
                        )
                } else {
                    content
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }
}

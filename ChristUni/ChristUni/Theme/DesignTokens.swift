//
//  DesignTokens.swift
//  ChristUni
//
//  Visual tokens aligned with DesignReferences/christ_central_ivory/DESIGN.md (repo root, not bundled).
//

import SwiftUI

enum DesignTokens {
    /// Primary surfaces and brand colors (hex from design system).
    enum ColorHex {
        static let surface = "f9f9fe"
        static let surfaceContainerLow = "f3f3f8"
        static let surfaceContainerLowest = "ffffff"
        static let surfaceContainerHigh = "e8e8ed"
        static let primary = "001e40"
        static let primaryContainer = "003366"
        static let secondary = "735c00"
        static let onSurface = "1a1c1f"
        static let onSurfaceVariant = "43474f"
        static let tertiary = "381300"
        static let error = "ba1a1a"
        static let secondaryContainer = "fedd7b"
        static let onSecondaryFixedVariant = "574500"
    }

    enum Radius {
        static let card: CGFloat = 24
        static let pill: CGFloat = 100
        /// Floating tab dock — same radius on all corners.
        static let tabBar: CGFloat = 26
    }

    enum Shadow {
        static let cardOpacity: Double = 0.04
        static let cardRadius: CGFloat = 24
        static let cardY: CGFloat = 8
    }

    enum FontStyle {
        /// Manrope is not bundled; rounded system design approximates headline weight.
        static func headline(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .system(size: size, weight: weight, design: .default)
        }
    }
}

extension Color {
    init(hex: String, opacity: Double = 1) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255 * opacity
        )
    }

    static let appSurface = Color(hex: DesignTokens.ColorHex.surface)
    static let appSurfaceLow = Color(hex: DesignTokens.ColorHex.surfaceContainerLow)
    static let appSurfaceLowest = Color(hex: DesignTokens.ColorHex.surfaceContainerLowest)
    static let appSurfaceHigh = Color(hex: DesignTokens.ColorHex.surfaceContainerHigh)
    static let appPrimary = Color(hex: DesignTokens.ColorHex.primary)
    static let appPrimaryContainer = Color(hex: DesignTokens.ColorHex.primaryContainer)
    static let appSecondary = Color(hex: DesignTokens.ColorHex.secondary)
    static let appOnSurface = Color(hex: DesignTokens.ColorHex.onSurface)
    static let appOnSurfaceVariant = Color(hex: DesignTokens.ColorHex.onSurfaceVariant)
    static let appTertiary = Color(hex: DesignTokens.ColorHex.tertiary)
    static let appError = Color(hex: DesignTokens.ColorHex.error)
    static let appSecondaryContainer = Color(hex: DesignTokens.ColorHex.secondaryContainer)
    static let appOnSecondaryFixedVariant = Color(hex: DesignTokens.ColorHex.onSecondaryFixedVariant)
}

extension LinearGradient {
    static var editorialPrimary: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary,
                Color.appPrimaryContainer,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

//
//  DemoRecordingProfileImage.swift
//  ChristUni
//
//  Loads `Assets.xcassets/DemoRecordingProfile` (mock.png). Replace mock.png with your real photo (real pixel size, e.g. 400×400+).
//  Uses PNG encoding only (JPEG re-encoding was causing solid colour artefacts on small assets).
//

#if canImport(UIKit)
import UIKit

enum DemoRecordingProfileImage {
    /// Encoded PNG for `UIImage(data:)` and SwiftUI views.
    static func bundledPNGData() -> Data? {
        if let branded = UIImage(named: "DemoRecordingProfile") {
            let maxSidePt = Swift.max(branded.size.width, branded.size.height) * branded.scale
            if maxSidePt >= 36,
               let png = branded.pngData(),
               UIImage(data: png) != nil {
                return png
            }
        }
        return generatedNeutralPortraitPlaceholder().pngData()
    }

    /// Fallback when asset is missing or is a 1×1 “placeholder” PNG (those scale to a flat wrong colour in UI).
    private static func generatedNeutralPortraitPlaceholder() -> UIImage {
        let size = CGSize(width: 240, height: 240)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1).setFill()
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size.width * 0.18)
            path.fill()
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 96, weight: .thin)
            if let silhouette = UIImage(systemName: "person.fill", withConfiguration: symbolConfig)?
                .withTintColor(UIColor(red: 0.58, green: 0.62, blue: 0.70, alpha: 1), renderingMode: .alwaysOriginal) {
                let sz = silhouette.size
                let origin = CGPoint(x: (size.width - sz.width) / 2, y: (size.height - sz.height) / 2)
                silhouette.draw(in: CGRect(origin: origin, size: sz))
            }
        }
    }
}
#endif

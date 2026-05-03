//
//  ChristUniApp.swift
//  ChristUni
//
//  Created by Karan Agarwal on 12/04/26.
//

import SwiftUI

@main
struct ChristUniApp: App {
    var body: some Scene {
        WindowGroup {
            DisplayZoomNeutralizingRoot {
                MainTabView()
                    // Editorial palette is authored for light surfaces; keep one consistent look in any system appearance.
                    .preferredColorScheme(.light)
                    // Layout is authored for default metrics; clamp Dynamic Type so accessibility text sizes don’t reflow.
                    .dynamicTypeSize(.large ... .large)
            }
        }
    }
}

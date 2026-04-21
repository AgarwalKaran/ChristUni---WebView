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
            MainTabView()
                // Editorial palette is authored for light surfaces; keep one consistent look in any system appearance.
                .preferredColorScheme(.light)
        }
    }
}

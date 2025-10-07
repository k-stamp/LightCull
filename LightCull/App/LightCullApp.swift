//
//  LightCullApp.swift
//  LightCull
//
//  Created by Kevin Stamp on 23.09.25.
//

import SwiftUI

@main
struct LightCullApp: App {
    // Service for thumbnail management
    private let thumbnailService = ThumbnailService()

    init() {
        // Clear thumbnail cache on app startup
        // This ensures a clean state for each session
        thumbnailService.clearCache()
    }

    var body: some Scene {
        WindowGroup("LightCull") {
            MainView()
        }
    }
}

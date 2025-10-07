//
//  ScreenshotApp.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ScreenshotApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Screenshot.self,
            ScreenshotCategory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationService.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

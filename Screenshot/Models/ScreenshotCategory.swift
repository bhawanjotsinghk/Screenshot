//
//  ScreenshotCategory.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import SwiftData

@Model
final class ScreenshotCategory {
    var id: UUID
    var name: String
    var color: String // Hex color string
    var icon: String // SF Symbol name
    var dateCreated: Date
    var screenshots: [Screenshot]
    var isDefault: Bool
    var sortOrder: Int
    
    init(
        name: String,
        color: String = "#007AFF",
        icon: String = "photo",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.dateCreated = Date()
        self.screenshots = []
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    // Computed property to get screenshot count
    var screenshotCount: Int {
        return screenshots.count
    }
    
    // Method to add screenshot to category
    func addScreenshot(_ screenshot: Screenshot) {
        if !screenshots.contains(where: { $0.id == screenshot.id }) {
            screenshots.append(screenshot)
            screenshot.category = self
        }
    }
    
    // Method to remove screenshot from category
    func removeScreenshot(_ screenshot: Screenshot) {
        screenshots.removeAll { $0.id == screenshot.id }
        screenshot.category = nil
    }
    
    // Method to get recent screenshots
    func getRecentScreenshots(limit: Int = 5) -> [Screenshot] {
        return Array(screenshots.sorted { $0.dateCreated > $1.dateCreated }.prefix(limit))
    }
}

// Predefined categories
extension ScreenshotCategory {
    static let predefinedCategories: [ScreenshotCategory] = [
        ScreenshotCategory(name: "Social Media", color: "#FF69B4", icon: "message.fill", isDefault: true, sortOrder: 1),
        ScreenshotCategory(name: "Messages", color: "#3498DB", icon: "message.fill", isDefault: true, sortOrder: 2),
        ScreenshotCategory(name: "Photos", color: "#45B7D1", icon: "camera.fill", isDefault: true, sortOrder: 3),
        ScreenshotCategory(name: "Gaming", color: "#9B59B6", icon: "bolt.fill", isDefault: true, sortOrder: 4),
        ScreenshotCategory(name: "Productivity", color: "#2ECC71", icon: "calendar", isDefault: true, sortOrder: 5),
        ScreenshotCategory(name: "Documents", color: "#96CEB4", icon: "doc.text", isDefault: true, sortOrder: 6),
        ScreenshotCategory(name: "Shopping", color: "#DDA0DD", icon: "cart", isDefault: true, sortOrder: 7),
        ScreenshotCategory(name: "News", color: "#98D8C8", icon: "newspaper", isDefault: true, sortOrder: 8),
        ScreenshotCategory(name: "Entertainment", color: "#F7DC6F", icon: "tv", isDefault: true, sortOrder: 9),
        ScreenshotCategory(name: "Other", color: "#85C1E9", icon: "questionmark.circle", isDefault: true, sortOrder: 10)
    ]
}

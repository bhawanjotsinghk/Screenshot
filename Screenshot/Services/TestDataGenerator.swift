//
//  TestDataGenerator.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import SwiftData
import UIKit

class TestDataGenerator {
    static let shared = TestDataGenerator()
    
    private init() {}
    
    func generateTestScreenshots(modelContext: ModelContext) {
        print("🧪 Starting test data generation...")
        
        // Create test categories if they don't exist
        createTestCategories(modelContext: modelContext)
        
        // Generate sample screenshots
        let testScreenshots = [
            TestScreenshotData(
                fileName: "social_media_post.png",
                categoryName: "Social Media",
                description: "Instagram post about vacation",
                fileSize: Int64(1024 * 1024 * 2), // 2MB
                confidence: 0.95
            ),
            TestScreenshotData(
                fileName: "message_conversation.png",
                categoryName: "Messages",
                description: "WhatsApp chat with friends",
                fileSize: Int64(1024 * 512), // 512KB
                confidence: 0.88
            ),
            TestScreenshotData(
                fileName: "photo_memory.png",
                categoryName: "Photos",
                description: "Family photo from last weekend",
                fileSize: Int64(1024 * 1024 * 3), // 3MB
                confidence: 0.92
            ),
            TestScreenshotData(
                fileName: "document_receipt.png",
                categoryName: "Documents",
                description: "Receipt from grocery store",
                fileSize: Int64(1024 * 256), // 256KB
                confidence: 0.85
            ),
            TestScreenshotData(
                fileName: "game_screenshot.png",
                categoryName: "Gaming",
                description: "High score in mobile game",
                fileSize: Int64(1024 * 1024), // 1MB
                confidence: 0.78
            ),
            TestScreenshotData(
                fileName: "shopping_cart.png",
                categoryName: "Shopping",
                description: "Online shopping cart",
                fileSize: Int64(1024 * 384), // 384KB
                confidence: 0.82
            ),
            TestScreenshotData(
                fileName: "news_article.png",
                categoryName: "News",
                description: "Breaking news article",
                fileSize: Int64(1024 * 768), // 768KB
                confidence: 0.90
            ),
            TestScreenshotData(
                fileName: "social_story.png",
                categoryName: "Social Media",
                description: "Facebook story screenshot",
                fileSize: Int64(1024 * 1024 * 3 / 2), // 1.5MB
                confidence: 0.87
            ),
            TestScreenshotData(
                fileName: "message_group.png",
                categoryName: "Messages",
                description: "Group chat screenshot",
                fileSize: Int64(1024 * 640), // 640KB
                confidence: 0.83
            ),
            TestScreenshotData(
                fileName: "photo_sunset.png",
                categoryName: "Photos",
                description: "Beautiful sunset photo",
                fileSize: Int64(1024 * 1024 * 5 / 2), // 2.5MB
                confidence: 0.94
            )
        ]
        
        for testData in testScreenshots {
            createTestScreenshot(testData: testData, modelContext: modelContext)
        }
        
        // Save the context to persist the data
        do {
            try modelContext.save()
            print("✅ Generated \(testScreenshots.count) test screenshots and saved to database")
            // Post notification to refresh UI
            NotificationCenter.default.post(name: NSNotification.Name("ScreenshotsUpdated"), object: nil)
        } catch {
            print("❌ Failed to save test data: \(error)")
        }
    }
    
    private func createTestCategories(modelContext: ModelContext) {
        // Categories are already created by ScreenshotManager, so we don't need to create them here
        // Just ensure they exist by checking
        print("✅ Using existing categories from ScreenshotManager")
    }
    
    private func createTestScreenshot(testData: TestScreenshotData, modelContext: ModelContext) {
        print("📸 Creating test screenshot: \(testData.fileName)")
        
        // Create a realistic screenshot-sized image (iPhone-like dimensions)
        let width = 390  // iPhone 14 Pro width
        let height = 844  // iPhone 14 Pro height
        let testImage = createTestImage(size: CGSize(width: width, height: height), text: testData.fileName)
        
        guard let imageData = testImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to create image data for \(testData.fileName)")
            return
        }
        
        print("✅ Created image data for \(testData.fileName) (\(imageData.count) bytes)")
        
        // Find the category
        do {
            let allCategories = try modelContext.fetch(FetchDescriptor<ScreenshotCategory>())
            let category = allCategories.first { $0.name == testData.categoryName }
            
            // Create the screenshot
            let screenshot = Screenshot(
                imageData: imageData,
                fileName: testData.fileName,
                fileSize: Int64(imageData.count), // Use actual image data size
                width: width,
                height: height,
                dateCreated: Date().addingTimeInterval(-Double.random(in: 0...86400 * 7)), // Random date within last week
                aiDescription: testData.description,
                confidence: testData.confidence
            )
            
            // Set the category relationship
            screenshot.category = category
            
            modelContext.insert(screenshot)
            print("✅ Inserted screenshot: \(testData.fileName) into context")
            
            // Add to category if it exists
            if let category = category {
                category.addScreenshot(screenshot)
                print("✅ Added screenshot to category: \(category.name)")
            } else {
                print("⚠️ No category found for: \(testData.categoryName)")
            }
            
        } catch {
            print("Error creating test screenshot: \(error)")
        }
    }
    
    private func createTestImage(size: CGSize, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Create a more realistic screenshot-like background
            let gradientColors: [UIColor]
            switch text.lowercased() {
            case let t where t.contains("social") || t.contains("media"):
                gradientColors = [UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0), UIColor(red: 1.0, green: 0.2, blue: 0.5, alpha: 1.0)]
            case let t where t.contains("message"):
                gradientColors = [UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0), UIColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0)]
            case let t where t.contains("photo"):
                gradientColors = [UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0), UIColor(red: 0.1, green: 0.5, blue: 0.8, alpha: 1.0)]
            case let t where t.contains("game"):
                gradientColors = [UIColor(red: 0.6, green: 0.3, blue: 0.7, alpha: 1.0), UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)]
            case let t where t.contains("document"):
                gradientColors = [UIColor(red: 0.6, green: 0.8, blue: 0.7, alpha: 1.0), UIColor(red: 0.4, green: 0.7, blue: 0.6, alpha: 1.0)]
            case let t where t.contains("shopping"):
                gradientColors = [UIColor(red: 0.9, green: 0.6, blue: 0.9, alpha: 1.0), UIColor(red: 0.8, green: 0.5, blue: 0.8, alpha: 1.0)]
            case let t where t.contains("news"):
                gradientColors = [UIColor(red: 0.6, green: 0.85, blue: 0.8, alpha: 1.0), UIColor(red: 0.4, green: 0.75, blue: 0.7, alpha: 1.0)]
            default:
                gradientColors = [UIColor.systemBlue, UIColor.systemPurple]
            }
            
            let colors = gradientColors.map { $0.cgColor }
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add some decorative elements to make it look more like a screenshot
            let shapeCount = Int.random(in: 5...12)
            for _ in 0..<shapeCount {
                let rect = CGRect(
                    x: CGFloat.random(in: 0...size.width - 60),
                    y: CGFloat.random(in: 0...size.height - 60),
                    width: CGFloat.random(in: 30...60),
                    height: CGFloat.random(in: 30...60)
                )
                
                let color = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.2...0.5))
                context.cgContext.setFillColor(color.cgColor)
                
                if Bool.random() {
                context.cgContext.fillEllipse(in: rect)
                } else {
                    context.cgContext.fill(rect)
                }
            }
            
            // Add a white rectangle at the top to simulate a status bar
            let statusBarRect = CGRect(x: 0, y: 0, width: size.width, height: 30)
            UIColor.white.withAlphaComponent(0.3).setFill()
            context.cgContext.fill(statusBarRect)
            
            // Add text at the bottom
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black.withAlphaComponent(0.5),
                .strokeWidth: -3
            ]
            
            let textRect = CGRect(x: 15, y: size.height - 50, width: size.width - 30, height: 35)
            text.replacingOccurrences(of: "_", with: " ").capitalized.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    func clearAllTestData(modelContext: ModelContext) {
        do {
            // Delete all screenshots
            let screenshotRequest = FetchDescriptor<Screenshot>()
            let screenshots = try modelContext.fetch(screenshotRequest)
            for screenshot in screenshots {
                modelContext.delete(screenshot)
            }
            
            // Delete all categories except default ones
            let categoryRequest = FetchDescriptor<ScreenshotCategory>()
            let categories = try modelContext.fetch(categoryRequest)
            for category in categories {
                if !category.isDefault {
                    modelContext.delete(category)
                }
            }
            
            try modelContext.save()
            print("✅ Cleared all test data")
            // Post notification to refresh UI
            NotificationCenter.default.post(name: NSNotification.Name("ScreenshotsUpdated"), object: nil)
        } catch {
            print("Error clearing test data: \(error)")
        }
    }
}

struct TestScreenshotData {
    let fileName: String
    let categoryName: String
    let description: String
    let fileSize: Int64
    let confidence: Double
}

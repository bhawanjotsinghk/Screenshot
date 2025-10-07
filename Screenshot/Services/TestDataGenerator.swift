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
                categoryName: "Games",
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
        } catch {
            print("❌ Failed to save test data: \(error)")
        }
    }
    
    private func createTestCategories(modelContext: ModelContext) {
        let categories = [
            ("Social Media", "#FF6B6B", "person.2"),
            ("Messages", "#4ECDC4", "message"),
            ("Photos", "#45B7D1", "camera"),
            ("Documents", "#96CEB4", "doc.text"),
            ("Games", "#FFEAA7", "gamecontroller"),
            ("Shopping", "#DDA0DD", "cart"),
            ("News", "#98D8C8", "newspaper")
        ]
        
        for (name, color, icon) in categories {
            // Check if category already exists
            let request = FetchDescriptor<ScreenshotCategory>(
                predicate: #Predicate { $0.name == name }
            )
            
            do {
                let existingCategories = try modelContext.fetch(request)
                if existingCategories.isEmpty {
                    let category = ScreenshotCategory(
                        name: name,
                        color: color,
                        icon: icon
                    )
                    modelContext.insert(category)
                }
            } catch {
                print("Error checking for existing category: \(error)")
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Created test categories")
        } catch {
            print("Error saving categories: \(error)")
        }
    }
    
    private func createTestScreenshot(testData: TestScreenshotData, modelContext: ModelContext) {
        print("📸 Creating test screenshot: \(testData.fileName)")
        
        // Create a simple test image
        let testImage = createTestImage(size: CGSize(width: 300, height: 400), text: testData.fileName)
        
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
                fileSize: testData.fileSize,
                width: 300,
                height: 400,
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
            // Create a gradient background
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor
            ]
            
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add some random shapes
            let shapeCount = Int.random(in: 3...8)
            for _ in 0..<shapeCount {
                let rect = CGRect(
                    x: CGFloat.random(in: 0...size.width - 50),
                    y: CGFloat.random(in: 0...size.height - 50),
                    width: CGFloat.random(in: 20...50),
                    height: CGFloat.random(in: 20...50)
                )
                
                let color = UIColor.white.withAlphaComponent(0.3)
                context.cgContext.setFillColor(color.cgColor)
                context.cgContext.fillEllipse(in: rect)
            }
            
            // Add text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2
            ]
            
            let textRect = CGRect(x: 10, y: size.height - 40, width: size.width - 20, height: 30)
            text.draw(in: textRect, withAttributes: attributes)
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

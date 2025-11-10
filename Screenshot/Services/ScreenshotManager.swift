//
//  ScreenshotManager.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import SwiftData
import UIKit
import Photos
import PhotosUI

@MainActor
class ScreenshotManager: ObservableObject {
    @Published var screenshots: [Screenshot] = []
    @Published var categories: [ScreenshotCategory] = []
    @Published var selectedCategory: ScreenshotCategory?
    @Published var searchText = ""
    @Published var selectedTag: String?
    @Published var sortOption: SortOption = .dateCreated
    @Published var isAscending = false
    @Published var showingPhotoPicker = false
    @Published var isProcessing = false
    
    private let modelContext: ModelContext
    private let aiAnalyzer = AIImageAnalyzer()
    
    enum SortOption: String, CaseIterable {
        case dateCreated = "Date Created"
        case dateModified = "Date Modified"
        case fileName = "File Name"
        case fileSize = "File Size"
        case confidence = "AI Confidence"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
        setupDefaultCategories()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadScreenshots()
        loadCategories()
    }
    
    func refreshData() {
        loadData()
    }
    
    private func loadScreenshots() {
        let descriptor = FetchDescriptor<Screenshot>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        
        do {
            screenshots = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load screenshots: \(error)")
        }
    }
    
    private func loadCategories() {
        let descriptor = FetchDescriptor<ScreenshotCategory>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load categories: \(error)")
        }
    }
    
    private func setupDefaultCategories() {
        if categories.isEmpty {
            for category in ScreenshotCategory.predefinedCategories {
                modelContext.insert(category)
            }
            saveContext()
            loadCategories()
        }
    }
    
    // MARK: - Screenshot Management
    
    func addScreenshot(from image: UIImage, fileName: String? = nil) async {
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        // Generate filename if not provided
        let finalFileName = fileName ?? "Screenshot_\(Date().timeIntervalSince1970).png"
        
        // Get image data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        // Create screenshot object
        let screenshot = Screenshot(
            imageData: imageData,
            fileName: finalFileName,
            fileSize: Int64(imageData.count),
            width: Int(image.size.width),
            height: Int(image.size.height)
        )
        
        // Perform AI analysis
        let analysisResult = await aiAnalyzer.analyzeImage(image)
        screenshot.aiDescription = analysisResult.description
        screenshot.confidence = analysisResult.confidence
        
        // Assign to suggested category
        if let suggestedCategoryName = analysisResult.suggestedCategory,
           let category = categories.first(where: { $0.name == suggestedCategoryName }) {
            screenshot.category = category
            category.addScreenshot(screenshot)
        } else {
            // Assign to "Other" category if no match
            if let otherCategory = categories.first(where: { $0.name == "Other" }) {
                screenshot.category = otherCategory
                otherCategory.addScreenshot(screenshot)
            }
        }
        
        // Save to context
        modelContext.insert(screenshot)
        saveContext()
        
        // Reload data
        loadScreenshots()
    }
    
    func addScreenshots(from images: [UIImage]) async {
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        for image in images {
            await addScreenshot(from: image)
        }
    }
    
    func deleteScreenshot(_ screenshot: Screenshot) {
        // Remove from category
        screenshot.category?.removeScreenshot(screenshot)
        
        // Delete from context
        modelContext.delete(screenshot)
        saveContext()
        
        // Reload data
        loadScreenshots()
    }
    
    func updateScreenshot(_ screenshot: Screenshot) {
        screenshot.updateModifiedDate()
        saveContext()
        loadScreenshots()
    }
    
    // MARK: - Category Management
    
    func createCategory(name: String, color: String, icon: String) {
        let category = ScreenshotCategory(name: name, color: color, icon: icon)
        modelContext.insert(category)
        saveContext()
        loadCategories()
    }
    
    func deleteCategory(_ category: ScreenshotCategory) {
        // Move screenshots to "Other" category
        if let otherCategory = categories.first(where: { $0.name == "Other" }) {
            for screenshot in category.screenshots {
                screenshot.category = otherCategory
                otherCategory.addScreenshot(screenshot)
            }
        }
        
        modelContext.delete(category)
        saveContext()
        loadCategories()
        loadScreenshots()
    }
    
    func updateCategory(_ category: ScreenshotCategory) {
        saveContext()
        loadCategories()
    }
    
    // MARK: - Filtering and Sorting
    
    var availableTags: [String] {
        let allTags = screenshots.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    var filteredScreenshots: [Screenshot] {
        var filtered = screenshots
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category?.id == selectedCategory.id }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { screenshot in
                screenshot.fileName.localizedCaseInsensitiveContains(searchText) ||
                screenshot.aiDescription?.localizedCaseInsensitiveContains(searchText) == true ||
                screenshot.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by selected tag
        if let selectedTag = selectedTag {
            filtered = filtered.filter { $0.tags.contains(selectedTag) }
        }
        
        // Sort
        filtered.sort { (first: Screenshot, second: Screenshot) -> Bool in
            let comparison: ComparisonResult
            
            switch sortOption {
            case .dateCreated:
                comparison = first.dateCreated.compare(second.dateCreated)
            case .dateModified:
                comparison = first.dateModified.compare(second.dateModified)
            case .fileName:
                comparison = first.fileName.localizedCaseInsensitiveCompare(second.fileName)
            case .fileSize:
                comparison = first.fileSize < second.fileSize ? .orderedAscending : (first.fileSize > second.fileSize ? .orderedDescending : .orderedSame)
            case .confidence:
                let firstConfidence = first.confidence ?? 0.0
                let secondConfidence = second.confidence ?? 0.0
                comparison = firstConfidence < secondConfidence ? .orderedAscending : (firstConfidence > secondConfidence ? .orderedDescending : .orderedSame)
            }
            
            return isAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
        
        return filtered
    }
    
    // MARK: - Statistics
    
    var totalScreenshots: Int {
        return screenshots.count
    }
    
    var totalFileSize: Int64 {
        return screenshots.reduce(0) { $0 + $1.fileSize }
    }
    
    var favoriteScreenshots: [Screenshot] {
        return screenshots.filter { $0.isFavorite }
    }
    
    var recentScreenshots: [Screenshot] {
        return Array(screenshots.sorted { $0.dateCreated > $1.dateCreated }.prefix(10))
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func reanalyzeScreenshot(_ screenshot: Screenshot) async {
        guard let image = screenshot.image else { return }
        
        let analysisResult = await aiAnalyzer.analyzeImage(image)
        screenshot.aiDescription = analysisResult.description
        screenshot.confidence = analysisResult.confidence
        
        // Update category if suggested
        if let suggestedCategoryName = analysisResult.suggestedCategory,
           let category = categories.first(where: { $0.name == suggestedCategoryName }) {
            screenshot.category?.removeScreenshot(screenshot)
            screenshot.category = category
            category.addScreenshot(screenshot)
        }
        
        updateScreenshot(screenshot)
    }
    
    func batchReanalyze() async {
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        for screenshot in screenshots {
            await reanalyzeScreenshot(screenshot)
        }
    }
    
    // MARK: - AI Features Implementation
    
    /// AI Categorization: Automatically categorize screenshots using AI analysis
    func enableAICategorization() async {
        isProcessing = true
        
        defer {
            isProcessing = false
        }
        
        // Analyze all uncategorized screenshots
        let uncategorizedScreenshots = screenshots.filter { $0.category == nil }
        
        for screenshot in uncategorizedScreenshots {
            if let image = UIImage(data: screenshot.imageData) {
                let analysis = await aiAnalyzer.analyzeImage(image)
                
                // Find or create category based on AI suggestion
                if let suggestedCategory = analysis.suggestedCategory {
                    let category = findOrCreateCategory(name: suggestedCategory)
                    screenshot.category = category
                    screenshot.confidence = analysis.confidence
                    screenshot.aiDescription = analysis.description
                    
                    updateScreenshot(screenshot)
                }
            }
        }
    }
    
    /// Auto-Sort: Automatically organize new screenshots when they're added
    func autoSortNewScreenshots(_ newScreenshots: [Screenshot]) async {
        for screenshot in newScreenshots {
            if let image = UIImage(data: screenshot.imageData) {
                let analysis = await aiAnalyzer.analyzeImage(image)
                
                if let suggestedCategory = analysis.suggestedCategory {
                    let category = findOrCreateCategory(name: suggestedCategory)
                    screenshot.category = category
                    screenshot.confidence = analysis.confidence
                    screenshot.aiDescription = analysis.description
                    
                    updateScreenshot(screenshot)
                }
            }
        }
    }
    
    /// Auto-Delete Old Screenshots: Remove old screenshots to save space
    func autoDeleteOldScreenshots(olderThanDays: Int = 30) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date()) ?? Date()
        
        let oldScreenshots = screenshots.filter { screenshot in
            screenshot.dateCreated < cutoffDate
        }
        
        for screenshot in oldScreenshots {
            deleteScreenshot(screenshot)
        }
    }
    
    /// Find existing category or create new one
    private func findOrCreateCategory(name: String) -> ScreenshotCategory {
        // First try to find existing category
        if let existingCategory = categories.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existingCategory
        }
        
        // Create new category
        let newCategory = ScreenshotCategory(
            name: name,
            color: getRandomCategoryColor(),
            icon: getRandomCategoryIcon()
        )
        
        modelContext.insert(newCategory)
        categories.append(newCategory)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save new category: \(error)")
        }
        
        return newCategory
    }
    
    /// Get random color for new category
    private func getRandomCategoryColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
        return colors.randomElement() ?? "#4ECDC4"
    }
    
    /// Get random icon for new category
    private func getRandomCategoryIcon() -> String {
        let icons = ["folder", "star", "heart", "bookmark", "tag", "flag", "pin", "circle"]
        return icons.randomElement() ?? "folder"
    }
}

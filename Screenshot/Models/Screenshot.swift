//
//  Screenshot.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Screenshot {
    var id: UUID
    var imageData: Data
    var dateCreated: Date
    var dateModified: Date
    var fileName: String
    var fileSize: Int64
    var width: Int
    var height: Int
    var category: ScreenshotCategory?
    var tags: [String]
    var aiDescription: String?
    var confidence: Double?
    var isFavorite: Bool
    var notes: String?
    
    init(
        imageData: Data,
        fileName: String,
        fileSize: Int64,
        width: Int,
        height: Int,
        dateCreated: Date = Date(),
        tags: [String] = [],
        aiDescription: String? = nil,
        confidence: Double? = nil,
        isFavorite: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.fileName = fileName
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.dateCreated = dateCreated
        self.dateModified = dateCreated
        self.tags = tags
        self.aiDescription = aiDescription
        self.confidence = confidence
        self.isFavorite = isFavorite
        self.notes = notes
    }
    
    // Computed property to get UIImage from Data
    var image: UIImage? {
        return UIImage(data: imageData)
    }
    
    // Computed property for file size in human readable format
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    // Computed property for aspect ratio
    var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }
    
    // Method to update modification date
    func updateModifiedDate() {
        self.dateModified = Date()
    }
    
    // Method to add tag
    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            updateModifiedDate()
        }
    }
    
    // Method to remove tag
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        updateModifiedDate()
    }
    
    // Method to toggle favorite status
    func toggleFavorite() {
        isFavorite.toggle()
        updateModifiedDate()
    }
}

//
//  AIImageAnalyzer.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import UIKit
import Vision
import NaturalLanguage

@MainActor
class AIImageAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    
    private let visionQueue = DispatchQueue(label: "com.screenshot.vision", qos: .userInitiated)
    
    // MARK: - Image Analysis
    
    func analyzeImage(_ image: UIImage) async -> (description: String, confidence: Double, suggestedCategory: String?) {
        await MainActor.run {
            isAnalyzing = true
            analysisProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
                analysisProgress = 1.0
            }
        }
        
        return await withCheckedContinuation { continuation in
            visionQueue.async {
                self.performImageAnalysis(image) { description, confidence, suggestedCategory in
                    Task { @MainActor in
                        continuation.resume(returning: (description, confidence, suggestedCategory))
                    }
                }
            }
        }
    }
    
    private func performImageAnalysis(_ image: UIImage, completion: @escaping (String, Double, String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("Unable to analyze image", 0.0, nil)
            return
        }
        
        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                completion("Analysis failed: \(error.localizedDescription)", 0.0, nil)
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                completion("No analysis results", 0.0, nil)
                return
            }
            
            // Get top classifications
            let topObservations = observations.prefix(5)
            let descriptions = topObservations.map { "\($0.identifier): \(String(format: "%.1f", $0.confidence * 100))%" }
            let description = descriptions.joined(separator: ", ")
            
            // Calculate average confidence
            let avgConfidence: Double
            if topObservations.count > 0 {
                avgConfidence = topObservations.map { Double($0.confidence) }.reduce(0, +) / Double(topObservations.count)
            } else {
                avgConfidence = 0.0
            }
            
            // Determine suggested category based on classifications
            let suggestedCategory = self.determineCategory(from: Array(topObservations))
            
            completion(description, avgConfidence, suggestedCategory)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion("Failed to perform analysis: \(error.localizedDescription)", 0.0, nil)
        }
    }
    
    private func determineCategory(from observations: [VNClassificationObservation]) -> String? {
        let topObservation = observations.first
        
        guard let identifier = topObservation?.identifier.lowercased() else {
            return nil
        }
        
        // Category mapping based on Vision framework classifications
        let categoryMappings: [String: String] = [
            // Social Media
            "person": "Social Media",
            "people": "Social Media",
            "selfie": "Social Media",
            "portrait": "Social Media",
            
            // Messages
            "text": "Messages",
            "message": "Messages",
            "chat": "Messages",
            "conversation": "Messages",
            
            // Photos
            "photo": "Photos",
            "picture": "Photos",
            "image": "Photos",
            "photograph": "Photos",
            "landscape": "Photos",
            "nature": "Photos",
            "outdoor": "Photos",
            
            // Documents
            "document": "Documents",
            "paper": "Documents",
            "text document": "Documents",
            "receipt": "Documents",
            "invoice": "Documents",
            "form": "Documents",
            
            // Games
            "game": "Games",
            "gaming": "Games",
            "video game": "Games",
            "controller": "Games",
            
            // Shopping
            "product": "Shopping",
            "shopping": "Shopping",
            "store": "Shopping",
            "retail": "Shopping",
            "ecommerce": "Shopping",
            
            // News
            "news": "News",
            "newspaper": "News",
            "article": "News",
            "headline": "News",
            
            // Entertainment
            "movie": "Entertainment",
            "film": "Entertainment",
            "video": "Entertainment",
            "tv": "Entertainment",
            "entertainment": "Entertainment",
            
            // Work
            "office": "Work",
            "business": "Work",
            "work": "Work",
            "meeting": "Work",
            "presentation": "Work",
            "chart": "Work",
            "graph": "Work",
            "spreadsheet": "Work"
        ]
        
        // Check for exact matches first
        if let category = categoryMappings[identifier] {
            return category
        }
        
        // Check for partial matches
        for (key, category) in categoryMappings {
            if identifier.contains(key) || key.contains(identifier) {
                return category
            }
        }
        
        // Default to "Other" if no match found
        return "Other"
    }
    
    // MARK: - Text Analysis for Screenshots with Text
    
    func analyzeTextInImage(_ image: UIImage) async -> [String] {
        return await withCheckedContinuation { continuation in
            Task {
                await self.performTextRecognition(image) { textResults in
                    continuation.resume(returning: textResults)
                }
            }
        }
    }
    
    private func performTextRecognition(_ image: UIImage, completion: @escaping ([String]) -> Void) async {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            completion(recognizedStrings)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error.localizedDescription)")
            completion([])
        }
    }
    
    // MARK: - Batch Analysis
    
    func analyzeBatch(_ images: [UIImage]) async -> [(UIImage, String, Double, String?)] {
        var results: [(UIImage, String, Double, String?)] = []
        
        for (index, image) in images.enumerated() {
            let result = await analyzeImage(image)
            results.append((image, result.description, result.confidence, result.suggestedCategory))
            
            // Update progress on main actor
            await MainActor.run {
                analysisProgress = Double(index + 1) / Double(images.count)
            }
        }
        
        return results
    }
}

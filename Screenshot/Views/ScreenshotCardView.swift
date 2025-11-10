//
//  ScreenshotCardView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData
import UIKit

struct ScreenshotCardView: View {
    let screenshot: Screenshot
    @Environment(\.modelContext) private var modelContext
    @State private var showingImage = false
    @State private var showingDetailView = false
    @State private var showingDeleteAlert = false
    
    private var screenshotManager: ScreenshotManager {
        ScreenshotManager(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Container
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .aspectRatio(screenshot.aspectRatio, contentMode: .fit)
                
                if let image = screenshot.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture {
                            showingImage = true
                        }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Top right menu button
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button(action: {
                                showingDetailView = true
                            }) {
                                Label("View Details", systemImage: "info.circle")
                            }
                            
                            Button(action: {
                                screenshot.toggleFavorite()
                                screenshotManager.updateScreenshot(screenshot)
                            }) {
                                Label(
                                    screenshot.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                    systemImage: screenshot.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            
                        Button(action: {
                                shareScreenshot()
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                showingDeleteAlert = true
                        }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            // Content Info (matching the design from images)
            VStack(alignment: .leading, spacing: 8) {
                // Category tag
                if let category = screenshot.category {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: category.color))
                            .frame(width: 8, height: 8)
                        
                        Text(category.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                // Title (using AI description or filename)
                Text(screenshot.aiDescription?.isEmpty == false ? screenshot.aiDescription! : screenshot.fileName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Tags
                if !screenshot.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(screenshot.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .foregroundColor(.secondary)
                                .clipShape(Capsule())
                        }
                        
                        if screenshot.tags.count > 2 {
                            Text("+\(screenshot.tags.count - 2)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Time ago
                Text(timeAgoString(from: screenshot.dateCreated))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .fullScreenCover(isPresented: $showingImage) {
            if let image = screenshot.image {
                ImageViewerView(
                    image: image,
                    screenshot: screenshot,
                    screenshotManager: ScreenshotManager(modelContext: modelContext)
                )
            }
        }
        .sheet(isPresented: $showingDetailView) {
            ScreenshotDetailView(
                screenshot: screenshot,
                screenshotManager: ScreenshotManager(modelContext: modelContext)
            )
        }
        .alert("Delete Screenshot", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                screenshotManager.deleteScreenshot(screenshot)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this screenshot? This action cannot be undone.")
        }
    }
    
    private func shareScreenshot() {
        guard let image = screenshot.image else { return }
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: [image],
                applicationActivities: nil
            )
            
            // For iPad support
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Configure popover for iPad
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

struct ImageViewerView: View {
    let image: UIImage
    let screenshot: Screenshot
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var newTag = ""
    @State private var notes: String
    @State private var isEditingNotes = false
    @FocusState private var isNotesFocused: Bool
    
    init(image: UIImage, screenshot: Screenshot, screenshotManager: ScreenshotManager) {
        self.image = image
        self.screenshot = screenshot
        self.screenshotManager = screenshotManager
        self._notes = State(initialValue: screenshot.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Screenshot Image Section
            ZStack {
                        Color.black
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                guard lastScale != 0 else { return }
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
                                
                                // Prevent NaN values
                                if scale.isNaN || scale.isInfinite {
                                    scale = 1.0
                                }
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                if scale < 1.0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newWidth = lastOffset.width + value.translation.width
                                let newHeight = lastOffset.height + value.translation.height
                                
                                // Prevent NaN values in offset
                                offset = CGSize(
                                    width: newWidth.isNaN ? 0 : newWidth,
                                    height: newHeight.isNaN ? 0 : newHeight
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            }
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .frame(maxWidth: .infinity)
                    
                    // Tags and Notes Section
                    VStack(alignment: .leading, spacing: 24) {
                        // Tags Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                Text("Tags")
                                    .font(.system(size: 20, weight: .semibold))
                                Spacer()
                            }
                            
                            if screenshot.tags.isEmpty {
                                Text("No tags added yet")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                    ForEach(screenshot.tags, id: \.self) { tag in
                                        HStack(spacing: 8) {
                                            Text(tag)
                                                .font(.system(size: 15, weight: .medium))
                                            
                                            Button(action: {
                                                screenshot.removeTag(tag)
                                                screenshotManager.updateScreenshot(screenshot)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemBlue).opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            // Add Tag Input
                            HStack(spacing: 12) {
                                TextField("Add a tag...", text: $newTag)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button(action: {
                                    addTag()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                                .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                Text("Notes")
                                    .font(.system(size: 20, weight: .semibold))
                                Spacer()
                                
                                if !notes.isEmpty {
                                    Button(action: {
                                        isEditingNotes.toggle()
                                        if !isEditingNotes {
                                            saveNotes()
                                        } else {
                                            isNotesFocused = true
                                        }
                                    }) {
                                        Text(isEditingNotes ? "Save" : "Edit")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            if isEditingNotes || notes.isEmpty {
                                TextEditor(text: $notes)
                                    .frame(minHeight: 150)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .focused($isNotesFocused)
                                    .overlay(
                                        Group {
                                            if notes.isEmpty && !isNotesFocused {
                                                VStack {
                                                    HStack {
                                                        Text("Add notes about this screenshot...")
                                                            .foregroundColor(.secondary)
                                                            .padding(.top, 8)
                                                            .padding(.leading, 5)
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                    )
                                
                                if !notes.isEmpty {
                                    HStack {
                                        Spacer()
                                        Text("\(notes.count) characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if isEditingNotes {
                                    HStack {
                                        Button("Cancel") {
                                            notes = screenshot.notes ?? ""
                                            isEditingNotes = false
                                        }
                                        .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Button("Save") {
                                            saveNotes()
                                        }
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                    }
                                    .padding(.top, 8)
                                }
                            } else {
                                if let notesText = screenshot.notes, !notesText.isEmpty {
                                    Text(notesText)
                                        .font(.body)
                                        .padding(.vertical, 8)
                                } else {
                                    Text("No notes added yet")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                                
                                Button(action: {
                                    isEditingNotes = true
                                    isNotesFocused = true
                                }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Add Notes")
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        if isEditingNotes {
                            saveNotes()
                        }
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        screenshot.toggleFavorite()
                        screenshotManager.updateScreenshot(screenshot)
                    }) {
                        Image(systemName: screenshot.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(screenshot.isFavorite ? .red : .white)
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty && !screenshot.tags.contains(trimmedTag) {
            screenshot.addTag(trimmedTag)
            screenshotManager.updateScreenshot(screenshot)
            newTag = ""
        }
    }
    
    private func saveNotes() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        screenshot.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        screenshotManager.updateScreenshot(screenshot)
        isEditingNotes = false
        isNotesFocused = false
    }
}


#Preview {
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    let sampleScreenshot = Screenshot(
        imageData: sampleImage.jpegData(compressionQuality: 0.8) ?? Data(),
        fileName: "Sample Screenshot.png",
        fileSize: 1024000,
        width: 1080,
        height: 1920,
        aiDescription: "A sample screenshot with some text content",
        confidence: 0.85,
        isFavorite: true
    )
    
    return ScreenshotCardView(screenshot: sampleScreenshot)
        .padding()
}

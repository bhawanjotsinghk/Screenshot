//
//  ScreenshotDetailView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ScreenshotDetailView: View {
    let screenshot: Screenshot
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingImage = false
    @State private var showingEditSheet = false
    @State private var showingCategoryPicker = false
    @State private var newTag = ""
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHours") private var reminderHours = 24.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Section
                    VStack(spacing: 12) {
                        if let image = screenshot.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    showingImage = true
                                }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                screenshot.toggleFavorite()
                                screenshotManager.updateScreenshot(screenshot)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: screenshot.isFavorite ? "heart.fill" : "heart")
                                    Text(screenshot.isFavorite ? "Favorited" : "Add to Favorites")
                                }
                                .foregroundColor(screenshot.isFavorite ? .red : .blue)
                            }
                            
                            Spacer()
                            
                            Button("Reanalyze") {
                                Task {
                                    await screenshotManager.reanalyzeScreenshot(screenshot)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Basic Info
                        DetailSection(title: "File Information") {
                            VStack(spacing: 8) {
                                DetailRow(label: "Name", value: screenshot.fileName)
                                DetailRow(label: "Size", value: screenshot.fileSizeFormatted)
                                DetailRow(label: "Dimensions", value: "\(screenshot.width) × \(screenshot.height)")
                                DetailRow(label: "Created", value: formatDate(screenshot.dateCreated))
                                DetailRow(label: "Modified", value: formatDate(screenshot.dateModified))
                            }
                        }
                        
                        // Category
                        DetailSection(title: "Category") {
                            Button(action: {
                                showingCategoryPicker = true
                            }) {
                                HStack {
                                    if let category = screenshot.category {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color(hex: category.color))
                                                .frame(width: 12, height: 12)
                                            
                                            Text(category.name)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    } else {
                                        HStack {
                                            Text("No Category")
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // AI Analysis
                        if let description = screenshot.aiDescription, !description.isEmpty {
                            DetailSection(title: "AI Analysis") {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(description)
                                        .font(.body)
                                    
                                    if let confidence = screenshot.confidence {
                                        HStack {
                                            Text("Confidence:")
                                                .foregroundColor(.secondary)
                                            
                                            Text("\(Int(confidence * 100))%")
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            ProgressView(value: confidence)
                                                .frame(width: 100)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Tags
                        DetailSection(title: "Tags") {
                            VStack(alignment: .leading, spacing: 8) {
                                if screenshot.tags.isEmpty {
                                    Text("No tags")
                                        .foregroundColor(.secondary)
                                } else {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                        ForEach(screenshot.tags, id: \.self) { tag in
                                            HStack {
                                                Text(tag)
                                                    .font(.caption)
                                                
                                                Button(action: {
                                                    screenshot.removeTag(tag)
                                                    screenshotManager.updateScreenshot(screenshot)
                                                }) {
                                                    Image(systemName: "xmark")
                                                        .font(.caption2)
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.systemGray5))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                
                                // Add new tag
                                HStack {
                                    TextField("Add tag", text: $newTag)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button("Add") {
                                        if !newTag.isEmpty {
                                            screenshot.addTag(newTag)
                                            screenshotManager.updateScreenshot(screenshot)
                                            newTag = ""
                                        }
                                    }
                                    .disabled(newTag.isEmpty)
                                }
                            }
                        }
                        
                        // Notes
                        DetailSection(title: "Notes") {
                            VStack(alignment: .leading, spacing: 8) {
                                if let notes = screenshot.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.body)
                                } else {
                                    Text("No notes")
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Add Notes") {
                                    showingEditSheet = true
                                }
                                .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Screenshot Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        
                        Button("Share") {
                            // TODO: Implement sharing
                        }
                        
                        Button("Delete", role: .destructive) {
                            screenshotManager.deleteScreenshot(screenshot)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingImage) {
                if let image = screenshot.image {
                    ImageViewerView(image: image, screenshot: screenshot)
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditScreenshotView(screenshot: screenshot, screenshotManager: screenshotManager)
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(
                    selectedCategory: screenshot.category,
                    categories: screenshotManager.categories,
                    onCategorySelected: { category in
                        screenshot.category?.removeScreenshot(screenshot)
                        screenshot.category = category
                        category?.addScreenshot(screenshot)
                        screenshotManager.updateScreenshot(screenshot)
                    }
                )
            }
            .onAppear {
                scheduleScreenshotReminder()
            }
        }
    }
    
    private func scheduleScreenshotReminder() {
        guard reminderEnabled else { return }
        
        // Cancel any existing reminder for this screenshot
        NotificationService.shared.cancelScreenshotReminder(for: screenshot)
        
        // Schedule new reminder
        NotificationService.shared.scheduleScreenshotReminder(for: screenshot, after: reminderHours)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct CategoryPickerView: View {
    let selectedCategory: ScreenshotCategory?
    let categories: [ScreenshotCategory]
    let onCategorySelected: (ScreenshotCategory?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button("No Category") {
                    onCategorySelected(nil)
                    dismiss()
                }
                .foregroundColor(selectedCategory == nil ? .blue : .primary)
                
                ForEach(categories, id: \.id) { category in
                    Button(action: {
                        onCategorySelected(category)
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: category.color))
                                .frame(width: 12, height: 12)
                            
                            Text(category.name)
                            
                            Spacer()
                            
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(selectedCategory?.id == category.id ? .blue : .primary)
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditScreenshotView: View {
    let screenshot: Screenshot
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    
    init(screenshot: Screenshot, screenshotManager: ScreenshotManager) {
        self.screenshot = screenshot
        self.screenshotManager = screenshotManager
        self._notes = State(initialValue: screenshot.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notes") {
                    TextField("Add notes about this screenshot", text: $notes, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("Edit Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        screenshot.notes = notes.isEmpty ? nil : notes
                        screenshotManager.updateScreenshot(screenshot)
                        dismiss()
                    }
                }
            }
        }
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
    
    return ScreenshotDetailView(
        screenshot: sampleScreenshot,
        screenshotManager: ScreenshotManager(modelContext: ModelContext(try! ModelContainer(for: Screenshot.self, ScreenshotCategory.self)))
    )
}

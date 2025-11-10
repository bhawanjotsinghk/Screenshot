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
                            VStack(alignment: .leading, spacing: 12) {
                                if screenshot.tags.isEmpty {
                                    Text("No tags added yet")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                } else {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                                        ForEach(screenshot.tags, id: \.self) { tag in
                                            HStack(spacing: 6) {
                                                Text(tag)
                                                    .font(.system(size: 14, weight: .medium))
                                                
                                                Button(action: {
                                                    screenshot.removeTag(tag)
                                                    screenshotManager.updateScreenshot(screenshot)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemBlue).opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                
                                // Add new tag
                                HStack(spacing: 8) {
                                    TextField("Add a tag...", text: $newTag)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onSubmit {
                                            addTag()
                                        }
                                    
                                    Button(action: {
                                        addTag()
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
                        }
                        
                        // Notes
                        DetailSection(title: "Notes") {
                            VStack(alignment: .leading, spacing: 12) {
                                if let notes = screenshot.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.body)
                                        .padding(.vertical, 8)
                                } else {
                                    Text("No notes added yet")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                                
                                Button(action: {
                                    showingEditSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: screenshot.notes?.isEmpty == false ? "pencil" : "plus.circle")
                                        Text(screenshot.notes?.isEmpty == false ? "Edit Notes" : "Add Notes")
                                }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.blue)
                                }
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
                    ImageViewerView(image: image, screenshot: screenshot, screenshotManager: screenshotManager)
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
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmedTag.isEmpty {
            screenshot.addTag(trimmedTag)
            screenshotManager.updateScreenshot(screenshot)
            newTag = ""
        }
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
                    TextEditor(text: $notes)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Edit Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        screenshot.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                        screenshotManager.updateScreenshot(screenshot)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tags Editor View
struct TagsEditorView: View {
    let screenshot: Screenshot
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current Tags
                if screenshot.tags.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tag")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No tags yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add tags to organize and find this screenshot easily")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
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
                        .padding()
                    }
                }
                
                // Add Tag Section
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Enter a tag...", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button(action: {
                            addTag()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    
                    Text("Press Enter or tap + to add a tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
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
}

// MARK: - Notes Editor View
struct NotesEditorView: View {
    let screenshot: Screenshot
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var notes: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(screenshot: Screenshot, screenshotManager: ScreenshotManager) {
        self.screenshot = screenshot
        self.screenshotManager = screenshotManager
        self._notes = State(initialValue: screenshot.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextEditor(text: $notes)
                    .padding()
                    .focused($isTextFieldFocused)
                    .overlay(
                        Group {
                            if notes.isEmpty {
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
                            .padding(.trailing)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        screenshot.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                        screenshotManager.updateScreenshot(screenshot)
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
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

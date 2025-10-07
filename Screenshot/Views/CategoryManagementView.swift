//
//  CategoryManagementView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var showingAddCategory = false
    @State private var editingCategory: ScreenshotCategory?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: ScreenshotCategory?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(screenshotManager.categories.count)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("Categories")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(screenshotManager.totalScreenshots)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("Screenshots")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    
                    // Categories Grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(screenshotManager.categories, id: \.id) { category in
                            CategoryIconView(
                                category: category,
                                onEdit: {
                                    editingCategory = category
                                },
                                onDelete: {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(screenshotManager: screenshotManager)
            }
            .sheet(item: $editingCategory) { category in
                EditCategoryView(category: category, screenshotManager: screenshotManager)
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        screenshotManager.deleteCategory(category)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let category = categoryToDelete {
                    Text("Are you sure you want to delete '\(category.name)'? Screenshots in this category will be moved to 'Other'.")
                }
            }
        }
    }
}

struct CategoryIconView: View {
    let category: ScreenshotCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingActions = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(hex: category.color))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(systemName: category.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 32, weight: .medium))
            }
            .onTapGesture {
                showingActions = true
            }
            
            // Category Name
            Text(category.name)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Screenshot Count
            Text("\(category.screenshotCount) screenshots")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            if !category.isDefault {
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .actionSheet(isPresented: $showingActions) {
            ActionSheet(
                title: Text(category.name),
                message: Text("\(category.screenshotCount) screenshots"),
                buttons: [
                    .default(Text("Edit")) {
                        onEdit()
                    },
                    category.isDefault ? nil : .destructive(Text("Delete")) {
                        onDelete()
                    },
                    .cancel()
                ].compactMap { $0 }
            )
        }
    }
}

struct AddCategoryView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "photo"
    
    private let colors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9",
        "#FF9F43", "#10AC84", "#EE5A24", "#0984E3", "#6C5CE7"
    ]
    
    private let icons = [
        "photo", "person.2", "message", "camera", "doc.text",
        "gamecontroller", "cart", "newspaper", "tv", "briefcase",
        "heart", "star", "bookmark", "tag", "folder"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: selectedIcon == icon ? 2 : 0)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        screenshotManager.createCategory(
                            name: name,
                            color: selectedColor,
                            icon: selectedIcon
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditCategoryView: View {
    let category: ScreenshotCategory
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    
    private let colors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9",
        "#FF9F43", "#10AC84", "#EE5A24", "#0984E3", "#6C5CE7"
    ]
    
    private let icons = [
        "photo", "person.2", "message", "camera", "doc.text",
        "gamecontroller", "cart", "newspaper", "tv", "briefcase",
        "heart", "star", "bookmark", "tag", "folder"
    ]
    
    init(category: ScreenshotCategory, screenshotManager: ScreenshotManager) {
        self.category = category
        self.screenshotManager = screenshotManager
        self._name = State(initialValue: category.name)
        self._selectedColor = State(initialValue: category.color)
        self._selectedIcon = State(initialValue: category.icon)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: selectedIcon == icon ? 2 : 0)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        category.name = name
                        category.color = selectedColor
                        category.icon = selectedIcon
                        screenshotManager.updateCategory(category)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CategoryManagementView(
        screenshotManager: ScreenshotManager(
            modelContext: ModelContext(try! ModelContainer(for: Screenshot.self, ScreenshotCategory.self))
        )
    )
}
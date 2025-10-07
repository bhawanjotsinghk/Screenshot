//
//  ScreenshotGridView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData

struct ScreenshotGridView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var screenshotManager: ScreenshotManager
    @State private var selectedScreenshot: Screenshot?
    @State private var showingDetailView = false
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
    
    init(modelContext: ModelContext) {
        self._screenshotManager = StateObject(wrappedValue: ScreenshotManager(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact Search and Filter Bar
                CompactSearchAndFilterBar(screenshotManager: screenshotManager)
                
                // Compact Statistics Bar
                CompactStatisticsBar(screenshotManager: screenshotManager)
                
                // Screenshots Grid
                if screenshotManager.filteredScreenshots.isEmpty {
                    CompactEmptyStateView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(screenshotManager.filteredScreenshots, id: \.id) { screenshot in
                                ScreenshotCardView(screenshot: screenshot)
                                    .onTapGesture {
                                        selectedScreenshot = screenshot
                                        showingDetailView = true
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Screenshots")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Sort by Date") {
                            screenshotManager.sortOption = .dateCreated
                        }
                        Button("Sort by Name") {
                            screenshotManager.sortOption = .fileName
                        }
                        Button("Sort by Size") {
                            screenshotManager.sortOption = .fileSize
                        }
                        Button("Sort by Confidence") {
                            screenshotManager.sortOption = .confidence
                        }
                        
                        Divider()
                        
                        Button(screenshotManager.isAscending ? "Descending" : "Ascending") {
                            screenshotManager.isAscending.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Generate Test Data") {
                            TestDataGenerator.shared.generateTestScreenshots(modelContext: modelContext)
                            // Force refresh of the screenshot manager
                            screenshotManager.refreshData()
                        }
                        
                        Button("Clear All Data") {
                            TestDataGenerator.shared.clearAllTestData(modelContext: modelContext)
                            // Force refresh of the screenshot manager
                            screenshotManager.refreshData()
                        }
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                }
            }
            .sheet(isPresented: $showingDetailView) {
                if let screenshot = selectedScreenshot {
                    ScreenshotDetailView(screenshot: screenshot, screenshotManager: screenshotManager)
                }
            }
        }
    }
}

struct CompactSearchAndFilterBar: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search screenshots...", text: $screenshotManager.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                
                if !screenshotManager.searchText.isEmpty {
                    Button(action: {
                        screenshotManager.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterButton(
                        title: "All",
                        isSelected: screenshotManager.selectedCategory == nil,
                        action: {
                            screenshotManager.selectedCategory = nil
                        }
                    )
                    
                    ForEach(screenshotManager.categories, id: \.id) { category in
                        CategoryFilterButton(
                            title: category.name,
                            isSelected: screenshotManager.selectedCategory?.id == category.id,
                            color: Color(hex: category.color),
                            action: {
                                screenshotManager.selectedCategory = category
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Tag Filter (if tags are available)
            if !screenshotManager.availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TagFilterButton(
                            title: "All Tags",
                            isSelected: screenshotManager.selectedTag == nil,
                            action: {
                                screenshotManager.selectedTag = nil
                            }
                        )
                        
                        ForEach(screenshotManager.availableTags, id: \.self) { tag in
                            TagFilterButton(
                                title: tag,
                                isSelected: screenshotManager.selectedTag == tag,
                                action: {
                                    screenshotManager.selectedTag = tag
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, color: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let color = color {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? (color ?? .blue) : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct TagFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.caption2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .orange : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct CompactStatisticsBar: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        HStack(spacing: 16) {
            StatisticItem(
                title: "Total",
                value: "\(screenshotManager.totalScreenshots)",
                icon: "photo.stack"
            )
            
            Spacer()
            
            StatisticItem(
                title: "Size",
                value: formatFileSize(screenshotManager.totalFileSize),
                icon: "internaldrive"
            )
            
            Spacer()
            
            StatisticItem(
                title: "Favorites",
                value: "\(screenshotManager.favoriteScreenshots.count)",
                icon: "heart.fill"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CompactEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text("No Screenshots")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Screenshots will be automatically imported and organized with AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
    }
}

// Helper function to format file size
private func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

#Preview {
    ScreenshotGridView(modelContext: ModelContext(try! ModelContainer(for: Screenshot.self, ScreenshotCategory.self)))
}
//
//  ContentView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData
import Photos

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var selectedView = 0 // 0: All Screenshots, 1: AI Categories
    @State private var showingAutoImport = false
    @State private var hasCheckedForScreenshots = false
    @State private var isOnboardingComplete = false
    @State private var hasPermission = false
    @State private var searchText = ""
    @State private var sortOption = "Newest First"
    @State private var filterOption = "All Screenshots"
    @State private var showingFilters = false
    
    private var screenshotManager: ScreenshotManager {
        ScreenshotManager(modelContext: modelContext)
    }
    
    var body: some View {
        if !isOnboardingComplete || users.isEmpty {
            OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                .onAppear {
                    checkPermissionStatus()
                }
        } else {
            NavigationView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Main title and subtitle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Screenshots")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Auto-organized & sorted")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    // Notification action
                                    print("Notifications tapped")
                                }) {
                                    Image(systemName: "bell.badge")
                                        .foregroundColor(.red)
                                        .font(.system(size: 18))
                                }
                                
                                Button(action: {
                                    // Settings action
                                    print("Settings tapped")
                                }) {
                                    Image(systemName: "gearshape")
                                        .foregroundColor(.primary)
                                        .font(.system(size: 18))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Tab Navigation
                        HStack(spacing: 0) {
                            TabButton(
                                title: "All Screenshots",
                                icon: "grid",
                                isSelected: selectedView == 0,
                                action: { selectedView = 0 }
                            )
                            
                            TabButton(
                                title: "AI Categories",
                                icon: "brain",
                                isSelected: selectedView == 1,
                                action: { selectedView = 1 }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .background(Color(.systemBackground))
                    
                    // Content Area
                    if selectedView == 0 {
                        AllScreenshotsView(
                            screenshotManager: screenshotManager,
                            searchText: $searchText,
                            sortOption: $sortOption,
                            filterOption: $filterOption,
                            showingFilters: $showingFilters
                        )
                    } else {
                        AICategoriesView(screenshotManager: screenshotManager)
                    }
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                checkForAutoImport()
            }
            .sheet(isPresented: $showingAutoImport) {
                PhotoPickerView(screenshotManager: screenshotManager)
            }
        }
    }
    
    private func checkPermissionStatus() {
        // Safer permission checking
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let status = PHPhotoLibrary.authorizationStatus()
            self.hasPermission = status == .authorized || status == .limited
            // Only complete onboarding if user exists and has permission
            if !self.users.isEmpty && self.hasPermission {
                self.isOnboardingComplete = true
            }
        }
    }
    
    private func checkForAutoImport() {
        guard !hasCheckedForScreenshots else { return }
        hasCheckedForScreenshots = true
        
        // Safer approach - check permission with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let status = PHPhotoLibrary.authorizationStatus()
            if (status == .authorized || status == .limited) && self.screenshotManager.totalScreenshots == 0 {
                // Auto-import screenshots if none exist
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showingAutoImport = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(.systemGray6) : Color.clear)
            )
        }
    }
}

struct AllScreenshotsView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Binding var searchText: String
    @Binding var sortOption: String
    @Binding var filterOption: String
    @Binding var showingFilters: Bool
    @State private var selectedScreenshot: Screenshot?
    @State private var showingDetailView = false
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Section
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Search screenshots...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Stats and Filter Row
                HStack {
                    Text("\(screenshotManager.totalScreenshots) screenshots")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 14))
                            Text("Filters")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Sort and Filter Dropdowns
                HStack(spacing: 12) {
                    Menu {
                        Button("Newest First") { sortOption = "Newest First" }
                        Button("Oldest First") { sortOption = "Oldest First" }
                        Button("Name A-Z") { sortOption = "Name A-Z" }
                        Button("Name Z-A") { sortOption = "Name Z-A" }
                        Button("Size Largest") { sortOption = "Size Largest" }
                        Button("Size Smallest") { sortOption = "Size Smallest" }
                    } label: {
                        HStack {
                            Text(sortOption)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Menu {
                        Button("All Screenshots") { filterOption = "All Screenshots" }
                        ForEach(screenshotManager.categories, id: \.id) { category in
                            Button(category.name) { filterOption = category.name }
                        }
                    } label: {
                        HStack {
                            Text(filterOption)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Screenshots Grid
            if screenshotManager.filteredScreenshots.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No Screenshots")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Screenshots will be automatically imported and organized with AI")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
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

struct AICategoriesView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // AI Categories Header
                HStack {
                    Image(systemName: "brain")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Categories")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Automatically organized by content")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Category Cards
                LazyVStack(spacing: 12) {
                    ForEach(screenshotManager.categories, id: \.id) { category in
                        CategoryCardView(category: category)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }
}

struct CategoryCardView: View {
    let category: ScreenshotCategory
    
    var body: some View {
        HStack(spacing: 16) {
            AICategoryIconView(category: category)
            AICategoryInfoView(category: category)
            Spacer()
            AICategoryThumbnailsView(category: category)
            AICategoryArrowView()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
    }
}

struct AICategoryIconView: View {
    let category: ScreenshotCategory
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 48, height: 48)
            
            Image(systemName: category.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct AICategoryInfoView: View {
    let category: ScreenshotCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(getCategoryDescription(for: category.name))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            AICategoryStatsView(category: category)
        }
    }
    
    private func getCategoryDescription(for categoryName: String) -> String {
        switch categoryName {
        case "Social Media":
            return "Posts, stories, and social interactions"
        case "Gaming":
            return "Game achievements, scores, and moments"
        case "Messaging":
            return "Important conversations and chats"
        case "Productivity":
            return "Work, notes, and productivity apps"
        case "Photos":
            return "Camera shots and photo moments"
        case "Documents":
            return "Files, PDFs, and documents"
        case "Shopping":
            return "Shopping carts and product views"
        case "News":
            return "News articles and updates"
        case "Entertainment":
            return "Videos, music, and entertainment"
        default:
            return "Other screenshots and content"
        }
    }
}

struct AICategoryStatsView: View {
    let category: ScreenshotCategory
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(category.screenshotCount) total")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            if category.screenshotCount > 0 {
                Text("1 today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
        }
    }
}

struct AICategoryThumbnailsView: View {
    let category: ScreenshotCategory
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(category.getRecentScreenshots(limit: 2).enumerated()), id: \.offset) { index, screenshot in
                if let image = screenshot.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }
        }
    }
}

struct AICategoryArrowView: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [Screenshot.self, ScreenshotCategory.self])
}
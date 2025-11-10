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
    @State private var selectedView = 0 // 0: All Screenshots, 1: Categories
    @State private var showingAutoImport = false
    @State private var hasCheckedForScreenshots = false
    @State private var isOnboardingComplete = false
    @State private var hasPermission = false
    @State private var searchText = ""
    @State private var sortOption = "Newest First"
    @State private var filterOption = "All Screenshots"
    @State private var showingFilters = false
    @State private var showingNotifications = false
    @State private var showingSettings = false
    
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
                                    showingNotifications = true
                                }) {
                                    Image(systemName: "bell")
                                        .foregroundColor(.primary)
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    showingSettings = true
                                }) {
                                    Image(systemName: "gearshape")
                                        .foregroundColor(.primary)
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Tab Navigation
                        HStack(spacing: 12) {
                            TabButton(
                                title: "All Screenshots",
                                icon: "square.grid.2x2",
                                isSelected: selectedView == 0,
                                action: { selectedView = 0 }
                            )
                            
                            TabButton(
                                title: "Categories",
                                icon: "square.grid.2x2",
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
                        AICategoriesView(
                            screenshotManager: screenshotManager,
                            searchText: $searchText
                        )
                    }
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                checkForAutoImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScreenshotsUpdated"))) { _ in
                // Refresh the screenshot manager when data is updated
                screenshotManager.refreshData()
            }
            .sheet(isPresented: $showingAutoImport) {
                PhotoPickerView(screenshotManager: screenshotManager)
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showingSettings) {
                AppSettingsView()
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
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.primary : Color(.systemGray5))
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
            VStack(spacing: 16) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Search screenshots...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .onChange(of: searchText) { _, newValue in
                            screenshotManager.searchText = newValue
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            screenshotManager.searchText = ""
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
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    Text("\(screenshotManager.totalScreenshots) screenshots")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 14))
                            Text("Filters")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Screenshots Grid
            if screenshotManager.filteredScreenshots.isEmpty {
                VStack(spacing: 20) {
                    // Large rounded square icon with mountain/sun
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        Text("No Screenshots Yet.")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Screenshots will be automatically imported and organized with AI.")
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
        .sheet(isPresented: $showingFilters) {
            FiltersView(screenshotManager: screenshotManager)
        }
        .onAppear {
            // Sync search text with ScreenshotManager
            if searchText != screenshotManager.searchText {
                searchText = screenshotManager.searchText
            }
        }
    }
}

struct AICategoriesView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
        ScrollView {
                VStack(spacing: 20) {
                // All Categories Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                    
                        Text("All Categories")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        }
                        
                        Text("Automatically organized by content")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                    .padding(.top, 8)
                
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
            AICategoryArrowView()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct AICategoryIconView: View {
    let category: ScreenshotCategory
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: category.color))
                .frame(width: 56, height: 56)
            
            Image(systemName: getCategoryIcon(for: category.name))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func getCategoryIcon(for categoryName: String) -> String {
        switch categoryName {
        case "Social Media":
            return "message.fill"
        case "Messages", "Messaging":
            return "message.fill"
        case "Photos":
            return "camera.fill"
        default:
            return category.icon
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
            return "Posts and stories"
        case "Messages", "Messaging":
            return "Chats and conversations"
        case "Photos":
            return "Camera shots"
        case "Gaming":
            return "Game achievements, scores, and moments"
        case "Productivity":
            return "Work, notes, and productivity apps"
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
            Text("\(category.screenshotCount) total")
            .font(.system(size: 14))
                .foregroundColor(.secondary)
    }
}

struct AICategoryArrowView: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
    }
}


// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationFrequency = "Immediate"
    @State private var enableNotifications = true
    @State private var customInterval = 1
    @State private var customTimeUnit = "Minutes"
    @State private var showingCustomPicker = false
    
    private let timeUnits = ["Minutes", "Hours", "Days"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Bell Icon
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bell.badge")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Notifications")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Manage your screenshot notifications")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Settings Section
                    VStack(spacing: 24) {
                        // Enable Notifications Toggle
                        HStack {
                            Text("Enable Notifications")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $enableNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Notification Frequency (only show if enabled)
                        if enableNotifications {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Notification Frequency")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                // Frequency Options
                                VStack(spacing: 12) {
                                    // Predefined Options
                                    VStack(spacing: 8) {
                                        FrequencyOption(
                                            title: "Immediate",
                                            subtitle: "As soon as screenshots are processed",
                                            isSelected: notificationFrequency == "Immediate"
                                        ) {
                                            notificationFrequency = "Immediate"
                                            showingCustomPicker = false
                                        }
                                        
                                        FrequencyOption(
                                            title: "Hourly",
                                            subtitle: "Every hour at the top of the hour",
                                            isSelected: notificationFrequency == "Hourly"
                                        ) {
                                            notificationFrequency = "Hourly"
                                            showingCustomPicker = false
                                        }
                                        
                                        FrequencyOption(
                                            title: "Daily",
                                            subtitle: "Once per day at 9:00 AM",
                                            isSelected: notificationFrequency == "Daily"
                                        ) {
                                            notificationFrequency = "Daily"
                                            showingCustomPicker = false
                                        }
                                        
                                        FrequencyOption(
                                            title: "Custom",
                                            subtitle: "Set your own interval",
                                            isSelected: notificationFrequency == "Custom"
                                        ) {
                                            notificationFrequency = "Custom"
                                            showingCustomPicker = true
                                        }
                                    }
                                    
                                    // Custom Interval Picker (only show if Custom is selected)
                                    if showingCustomPicker {
                                        VStack(spacing: 12) {
                                            HStack {
                                                Text("Every")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                
                                                Stepper(value: $customInterval, in: 1...60) {
                                                    Text("\(customInterval)")
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.primary)
                                                }
                                                
                                                Picker("Time Unit", selection: $customTimeUnit) {
                                                    ForEach(timeUnits, id: \.self) { unit in
                                                        Text(unit).tag(unit)
                                                    }
                                                }
                                                .pickerStyle(MenuPickerStyle())
                                                .font(.system(size: 16, weight: .medium))
                                            }
                                            
                                            Text("Notifications will be sent every \(customInterval) \(customTimeUnit.lowercased())")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(8)
                                        .transition(.opacity.combined(with: .scale))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Frequency Option Component
struct FrequencyOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Settings View
struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var aiCategorization = true
    @State private var autoSort = true
    @State private var autoDelete = false
    @State private var showingAccountView = false
    @State private var isGeneratingSamples = false
    @State private var showSampleSuccessAlert = false
    
    @Query private var users: [User]
    
    private var currentUser: User? {
        users.first
    }
    
    private var screenshotManager: ScreenshotManager {
        ScreenshotManager(modelContext: modelContext)
    }
    
    private func signOut() {
        // Delete all users (sign out)
        for user in users {
            modelContext.delete(user)
        }
        
        // Save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to sign out: \(error)")
        }
        
        // Dismiss the settings view
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    if let user = currentUser {
                        HStack {
                            // Profile Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 50, height: 50)
                                
                                Text(String(user.name.prefix(1)).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(user.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Edit") {
                                showingAccountView = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                        
                        // Sign Out Button
                        Button(action: {
                            signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            
                            Text("No Account")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Create Account") {
                                showingAccountView = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("ACCOUNT")
                }
                
                Section("AI Features") {
                    Toggle("AI Categorization", isOn: $aiCategorization)
                        .onChange(of: aiCategorization) { _, newValue in
                            if newValue {
                                Task {
                                    await ScreenshotManager(modelContext: modelContext).enableAICategorization()
                                }
                            }
                        }
                    
                    Toggle("Auto-Sort", isOn: $autoSort)
                        .onChange(of: autoSort) { _, newValue in
                            // Auto-sort will be applied when new screenshots are added
                        }
                    
                    Toggle("Auto-Delete Old Screenshots", isOn: $autoDelete)
                        .onChange(of: autoDelete) { _, newValue in
                            if newValue {
                                Task {
                                    await ScreenshotManager(modelContext: modelContext).autoDeleteOldScreenshots()
                                }
                            }
                        }
                }
                
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Processing")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Screenshots are analyzed locally on your device. No data is sent to external servers.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("PRIVACY")
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text("System")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Storage") {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text("2.4 GB")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Cache") {
                        // Clear cache action
                    }
                    .foregroundColor(.red)
                }
                
                Section("Testing") {
                    Button(action: {
                        isGeneratingSamples = true
                        Task {
                            TestDataGenerator.shared.generateTestScreenshots(modelContext: modelContext)
                            await MainActor.run {
                                screenshotManager.refreshData()
                                isGeneratingSamples = false
                                showSampleSuccessAlert = true
                            }
                        }
                    }) {
                        HStack {
                            if isGeneratingSamples {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "photo.stack")
                                    .foregroundColor(.blue)
                            }
                            Text(isGeneratingSamples ? "Generating..." : "Generate Sample Screenshots")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isGeneratingSamples)
                    
                    Button(action: {
                        TestDataGenerator.shared.clearAllTestData(modelContext: modelContext)
                        screenshotManager.refreshData()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Screenshots")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAccountView) {
                AccountView(screenshotManager: ScreenshotManager(modelContext: modelContext))
            }
            .alert("Sample Data Generated", isPresented: $showSampleSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("10 sample screenshots have been generated and organized into categories.")
            }
        }
    }
}

// MARK: - Filters View
struct FiltersView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ScreenshotCategory?
    @State private var selectedTag: String?
    @State private var sortOption: ScreenshotManager.SortOption
    @State private var isAscending: Bool
    
    init(screenshotManager: ScreenshotManager) {
        self.screenshotManager = screenshotManager
        self._selectedCategory = State(initialValue: screenshotManager.selectedCategory)
        self._selectedTag = State(initialValue: screenshotManager.selectedTag)
        self._sortOption = State(initialValue: screenshotManager.sortOption)
        self._isAscending = State(initialValue: screenshotManager.isAscending)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Filters & Sort")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    resetFilters()
                }) {
                    Text("Reset")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Category Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Pick one")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        // Category Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            // All Categories Card
                            CategoryFilterCard(
                                title: "All Categories",
                                icon: "folder.fill",
                                isSelected: selectedCategory == nil,
                                color: selectedCategory == nil ? Color(red: 0.1, green: 0.13, blue: 0.17) : Color(.systemGray6)
                            ) {
                                selectedCategory = nil
                            }
                            
                            // Category Cards
                            ForEach(screenshotManager.categories, id: \.id) { category in
                                CategoryFilterCard(
                                    title: category.name,
                                    icon: getCategoryIcon(for: category.name),
                                    isSelected: selectedCategory?.id == category.id,
                                    color: selectedCategory?.id == category.id ? Color(red: 0.1, green: 0.13, blue: 0.17) : Color(.systemGray6)
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Sort Options Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sort By")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(ScreenshotManager.SortOption.allCases, id: \.self) { option in
                                SortOptionCard(
                                    title: option.displayName,
                                    subtitle: getSortSubtitle(for: option),
                                    icon: getSortIcon(for: option),
                                    isSelected: sortOption == option
                                ) {
                                    sortOption = option
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 100) // Space for bottom buttons
            }
            
            // Bottom Buttons
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    applyFilters()
                    dismiss()
                }) {
                    Text("Apply Filters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
    }
    
    private func getCategoryIcon(for categoryName: String) -> String {
        switch categoryName {
        case "Social Media":
            return "message.fill"
        case "Messages":
            return "envelope.fill"
        case "Photos":
            return "camera.fill"
        case "Documents":
            return "doc.fill"
        case "Gaming":
            return "gamecontroller.fill"
        case "Shopping":
            return "bag.fill"
        case "News":
            return "newspaper.fill"
        case "Entertainment":
            return "tv.fill"
        default:
            return "folder.fill"
        }
    }
    
    private func getSortIcon(for option: ScreenshotManager.SortOption) -> String {
        switch option {
        case .dateCreated:
            return "calendar"
        case .dateModified:
            return "clock"
        case .fileName:
            return "doc.text"
        case .fileSize:
            return "arrow.up.arrow.down"
        case .confidence:
            return "sparkles"
        }
    }
    
    private func getSortSubtitle(for option: ScreenshotManager.SortOption) -> String {
        switch option {
        case .dateCreated:
            return "When captured"
        case .dateModified:
            return "Last edited"
        case .fileName:
            return "Alphabetically"
        case .fileSize:
            return "By size"
        case .confidence:
            return "Match score"
        }
    }
    
    private func resetFilters() {
        selectedCategory = nil
        selectedTag = nil
        sortOption = .dateCreated
        isAscending = false
    }
    
    private func applyFilters() {
        screenshotManager.selectedCategory = selectedCategory
        screenshotManager.selectedTag = selectedTag
        screenshotManager.sortOption = sortOption
        screenshotManager.isAscending = isAscending
    }
}

// MARK: - Category Filter Card
struct CategoryFilterCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(height: 32)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if isSelected {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sort Option Card
struct SortOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(isSelected ? Color(red: 0.1, green: 0.13, blue: 0.17) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Screenshot.self, ScreenshotCategory.self])
}
//
//  AccountView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import SwiftData
import UserNotifications

struct AccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @ObservedObject var screenshotManager: ScreenshotManager
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingNotificationSettings = false
    
    var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(currentUser?.name.prefix(1).uppercased() ?? "U")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUser?.name ?? "User")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(currentUser?.email ?? "user@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Member since \(currentUser?.dateCreated.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Profile")
                }
                
                // App Statistics Section
                Section {
                    HStack {
                        Image(systemName: "photo.stack")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Total Screenshots")
                        Spacer()
                        Text("\(screenshotManager.totalScreenshots)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Categories")
                        Spacer()
                        Text("\(screenshotManager.categories.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("Favorites")
                        Spacer()
                        Text("\(screenshotManager.screenshots.filter { $0.isFavorite }.count)")
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Your Data")
                }
                
                // Settings Section
                Section {
                    Button(action: {
                        showingNotificationSettings = true
                    }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text("Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Preferences")
                }
                
                // About Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("About Screenshot Organizer")
                        Spacer()
                        Text("v1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        Text("Rate the App")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: currentUser)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let user: User?
    @State private var name: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("Profile Information")
                } footer: {
                    Text("Your information is stored locally on your device.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
            .onAppear {
                if let user = user {
                    name = user.name
                    email = user.email
                }
            }
        }
    }
    
    private func saveProfile() {
        if let user = user {
            user.name = name
            user.email = email
            try? modelContext.save()
        }
        dismiss()
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoImportEnabled") private var autoImportEnabled = true
    @AppStorage("aiAnalysisEnabled") private var aiAnalysisEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Auto Import Screenshots", isOn: $autoImportEnabled)
                    Toggle("AI Analysis", isOn: $aiAnalysisEnabled)
                    Toggle("Notifications", isOn: $notificationsEnabled)
                } header: {
                    Text("General")
                } footer: {
                    Text("Auto import will automatically find and import screenshots from your photo library.")
                }
                
                Section {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text("Calculating...")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Storage")
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
        }
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHours") private var reminderHours = 24.0
    @State private var notificationStatus = "Checking..."
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Screenshot Reminders", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Remind me after:")
                            HStack {
                                Slider(value: $reminderHours, in: 1...168, step: 1)
                                Text("\(Int(reminderHours)) hours")
                                    .foregroundColor(.secondary)
                                    .frame(width: 80)
                            }
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Get notified about screenshots you've viewed to help you organize them.")
                }
                
                Section {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(notificationStatus)
                            .foregroundColor(notificationStatus.contains("Authorized") ? .green : .red)
                    }
                    
                    Button("Test Notification") {
                        NotificationService.shared.scheduleTestNotification()
                    }
                    
                    if !notificationStatus.contains("Authorized") {
                        Button("Request Permission") {
                            requestNotificationPermission()
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Testing")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkNotificationStatus()
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive screenshot reminders.")
            }
        }
    }
    
    private func checkNotificationStatus() {
        NotificationService.shared.checkPermissionStatus { isAuthorized in
            self.notificationStatus = isAuthorized ? "Authorized ✅" : "Denied ❌"
        }
    }
    
    private func requestNotificationPermission() {
        NotificationService.shared.requestPermission()
        // Check status after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkNotificationStatus()
        }
    }
    
}

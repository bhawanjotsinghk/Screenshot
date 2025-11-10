import SwiftUI
import Photos
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var showingOnboarding = true
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var aiCategorization = true
    @State private var autoSort = true
    @State private var autoDelete = false
    @State private var selectedNotificationFrequency = "Immediate"
    @Binding var isOnboardingComplete: Bool
    
    private let totalSteps = 6
    
    var body: some View {
        if showingOnboarding {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBarView(currentStep: currentStep, totalSteps: totalSteps)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        WelcomeStepView()
                            .tag(0)
                        
                        ProfileStepView(userName: $userName, userEmail: $userEmail)
                            .tag(1)
                        
                        PermissionsStepView()
                            .tag(2)
                        
                        AIFeaturesStepView(
                            aiCategorization: $aiCategorization,
                            autoSort: $autoSort,
                            autoDelete: $autoDelete
                        )
                        .tag(3)
                        
                        NotificationStepView(selectedFrequency: $selectedNotificationFrequency)
                            .tag(4)
                        
                        CompletionStepView(userName: userName)
                            .tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Navigation buttons
                    NavigationButtonsView(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        showingOnboarding: $showingOnboarding,
                        isOnboardingComplete: $isOnboardingComplete,
                        userName: userName,
                        userEmail: userEmail,
                        modelContext: modelContext
                    )
                }
            }
        } else {
            ContentView()
        }
    }
}

// MARK: - Progress Bar
struct ProgressBarView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step < currentStep ? Color.primary : Color(.systemGray4))
                        .frame(width: 30, height: 4)
                }
            }
            
            Spacer()
            
            Text(stepTitle(for: currentStep))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func stepTitle(for step: Int) -> String {
        switch step {
        case 0: return "Welcome"
        case 1: return "Account"
        case 2: return "Permissions"
        case 3: return "AI Features"
        case 4: return "Notifications"
        case 5: return "Complete"
        default: return ""
        }
    }
}

// MARK: - Step 1: Welcome
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Main illustration
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(width: 200, height: 300)
                        .overlay(
                            Image(systemName: "iphone")
                                .font(.system(size: 100))
                                .foregroundColor(.primary)
                        )
                    
                    // AI badge
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "sparkles")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        Spacer()
                    }
                    .padding(20)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to ScreenSort")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Your intelligent screenshot manager that automatically organizes, categorizes, and reminds you about your captures using AI.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Feature cards
            VStack(spacing: 12) {
                FeatureCard(
                    icon: "brain",
                    title: "AI-Powered Organization",
                    subtitle: "Smart categorization and insights",
                    color: .blue
                )
                
                FeatureCard(
                    icon: "bell",
                    title: "Smart Reminders",
                    subtitle: "Never miss important screenshots",
                    color: .green
                )
                
                FeatureCard(
                    icon: "bolt",
                    title: "Auto-Sort",
                    subtitle: "Organize screenshots automatically",
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Step 2: Profile
struct ProfileStepView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 40))
                }
                
                VStack(spacing: 8) {
                    Text("Create Your Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Let's personalize your ScreenSort experience")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter your full name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    TextField("Enter your email", text: $userEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .padding(.horizontal, 20)
            
            // Privacy notice
            HStack(spacing: 12) {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy First")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Your data stays on your device. We never upload your screenshots to our servers.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - Step 3: Permissions
struct PermissionsStepView: View {
    @State private var hasPhotoPermission = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Enable Screenshot Access")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Allow ScreenSort to organize your screenshots automatically")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Visual example
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                )
                .padding(.horizontal, 20)
            
            // Permission cards
            VStack(spacing: 12) {
                Button(action: requestPhotoPermission) {
                    PermissionCard(
                        icon: "iphone",
                        title: "Photos Access",
                        subtitle: hasPhotoPermission ? "Access granted" : "Required to organize screenshots",
                        isRequired: true,
                        color: hasPhotoPermission ? .green : .orange,
                        isGranted: hasPhotoPermission
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                PermissionCard(
                    icon: "bell",
                    title: "Notifications",
                    subtitle: "Get reminders about new screenshots",
                    isRequired: false,
                    color: .blue,
                    isGranted: false
                )
            }
            .padding(.horizontal, 20)
            
            // Info box
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("What We Access")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("We only read screenshots from your Photos app. No personal photos, videos, or other data is accessed.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            checkPhotoPermissionStatus()
        }
        .alert("Photo Library Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow access to your photo library in Settings to automatically find and organize your screenshots.")
        }
    }
    
    private func checkPhotoPermissionStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        hasPhotoPermission = status == .authorized || status == .limited
    }
    
    private func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                hasPhotoPermission = status == .authorized || status == .limited
                if !hasPhotoPermission && status == .denied {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isRequired: Bool
    let color: Color
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                    Text("Granted")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text(isRequired ? "Required" : "Optional")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isRequired ? .orange : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isRequired ? Color.orange : Color.blue).opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Step 4: AI Features
struct AIFeaturesStepView: View {
    @Binding var aiCategorization: Bool
    @Binding var autoSort: Bool
    @Binding var autoDelete: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                        .font(.system(size: 40))
                }
                
                VStack(spacing: 8) {
                    Text("AI Features Setup")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Configure intelligent screenshot organization")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            // AI Features
            VStack(spacing: 16) {
                AIFeatureToggle(
                    icon: "brain",
                    title: "AI Categorization",
                    subtitle: "Automatically sort screenshots by content",
                    isOn: $aiCategorization,
                    color: .purple
                )
                
                AIFeatureToggle(
                    icon: "bolt",
                    title: "Auto-Sort",
                    subtitle: "Organize new screenshots automatically",
                    isOn: $autoSort,
                    color: .purple
                )
                
                AIFeatureToggle(
                    icon: "trash",
                    title: "Auto-Delete Old Screenshots",
                    subtitle: "Automatically remove old screenshots to save space",
                    isOn: $autoDelete,
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
            
            // Privacy notice
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct AIFeatureToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Step 5: Notifications
struct NotificationStepView: View {
    @Binding var selectedFrequency: String
    
    private let notificationOptions = [
        ("Immediate", "Get notified as soon as you take a screenshot", "bolt", Color.orange),
        ("Hourly", "Hourly summary of new screenshots", "bell", Color.blue),
        ("Daily", "Daily digest of all your screenshots", "calendar", Color.green),
        ("Never", "No notifications (you can change this later)", "", Color.gray)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "bell")
                        .foregroundColor(.orange)
                        .font(.system(size: 40))
                }
                
                VStack(spacing: 8) {
                    Text("Notification Preferences")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Choose how often you'd like to be reminded about new screenshots")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Notification options
            VStack(spacing: 12) {
                ForEach(notificationOptions, id: \.0) { option in
                    NotificationOptionCard(
                        title: option.0,
                        subtitle: option.1,
                        icon: option.2,
                        color: option.3,
                        isSelected: selectedFrequency == option.0
                    ) {
                        selectedFrequency = option.0
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct NotificationOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20))
                        .frame(width: 24)
                } else {
                    Spacer()
                        .frame(width: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 6: Completion
struct CompletionStepView: View {
    let userName: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.system(size: 50, weight: .bold))
                    
                    // Sparkle badge
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "sparkles")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                }
                
                VStack(spacing: 12) {
                    Text("You're All Set!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Welcome to ScreenSort, \(userName.isEmpty ? "User" : userName)! Your intelligent screenshot manager is ready to go.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // What happens next
            VStack(alignment: .leading, spacing: 12) {
                Text("What happens next?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        
                        Text("Screenshots will be automatically organized using AI")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("You'll receive reminders based on your preferences")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                        
                        Text("Smart insights will help you understand your usage patterns")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - Navigation Buttons
struct NavigationButtonsView: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    @Binding var showingOnboarding: Bool
    @Binding var isOnboardingComplete: Bool
    let userName: String
    let userEmail: String
    let modelContext: ModelContext
    
    var body: some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            Button(action: {
                if currentStep == totalSteps - 1 {
                    completeOnboarding()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.primary)
                .cornerRadius(8)
            }
            .disabled(currentStep == totalSteps - 1 && (userName.isEmpty || userEmail.isEmpty))
            .opacity(currentStep == totalSteps - 1 && (userName.isEmpty || userEmail.isEmpty) ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func completeOnboarding() {
        // Validate user input
        guard !userName.isEmpty && !userEmail.isEmpty else {
            return
        }
        
        // Create user account
        let user = User(name: userName, email: userEmail)
        user.isOnboardingComplete = true
        
        // Save to model context
        modelContext.insert(user)
        
        do {
            try modelContext.save()
            // Set onboarding complete flag
            isOnboardingComplete = true
        } catch {
            print("Failed to save user: \(error)")
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
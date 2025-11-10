//
//  PhotoPickerView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI
import PhotosUI
import SwiftData
import Photos

struct PhotoPickerView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    @State private var showingPermissionAlert = false
    @State private var foundScreenshots: [PHAsset] = []
    @State private var autoImportProgress = 0.0
    @State private var isAutoImporting = false
    @State private var hasScanned = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isProcessing || isAutoImporting {
                    ProcessingView(
                        screenshotManager: screenshotManager,
                        isAutoImporting: isAutoImporting,
                        progress: autoImportProgress,
                        totalCount: foundScreenshots.count
                    )
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 12) {
                            Text("Auto-Import Screenshots")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Automatically find and import all screenshots from your Photos app")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        if hasScanned {
                            VStack(spacing: 8) {
                                Text("Found \(foundScreenshots.count) screenshots")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                if foundScreenshots.count > 0 {
                                    Text("Ready to import with AI categorization")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await startAutoImport()
                            }
                        }) {
                            HStack {
                                Image(systemName: hasScanned ? "arrow.clockwise" : "magnifyingglass")
                                Text(hasScanned ? "Re-scan Photos" : "Scan for Screenshots")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing || isAutoImporting)
                        
                        if foundScreenshots.count > 0 {
                            Button(action: {
                                Task {
                                    await importAllScreenshots()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import All \(foundScreenshots.count) Screenshots")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing || isAutoImporting)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Import Screenshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Photo Library Access Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please allow access to your photo library to automatically find screenshots.")
            }
            .onAppear {
                checkPhotoPermission()
            }
        }
    }
    
    private func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus != .authorized && newStatus != .limited {
                        self.showingPermissionAlert = true
                    }
                }
            }
        } else if status != .authorized && status != .limited {
            showingPermissionAlert = true
        }
    }
    
    private func startAutoImport() async {
        isAutoImporting = true
        autoImportProgress = 0.0
        
        // Find all screenshots in the photo library
        foundScreenshots = await findScreenshots()
        hasScanned = true
        
        isAutoImporting = false
    }
    
    private func findScreenshots() async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            
            let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var screenshots: [PHAsset] = []
            
            allPhotos.enumerateObjects { asset, _, _ in
                // Check if the asset is likely a screenshot
                if isScreenshot(asset: asset) {
                    screenshots.append(asset)
                }
            }
            
            continuation.resume(returning: screenshots)
        }
    }
    
    private func isScreenshot(asset: PHAsset) -> Bool {
        // Check if the asset was created by taking a screenshot
        // Screenshots typically have specific characteristics
        guard let creationDate = asset.creationDate else { return false }
        
        // Check if it's a recent screenshot (within last 2 years)
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        if creationDate < twoYearsAgo { return false }
        
        // Check dimensions - screenshots are typically full screen
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        
        // Common iPhone screenshot dimensions
        let commonScreenshotSizes = [
            (1170, 2532), // iPhone 12/13/14 Pro
            (1179, 2556), // iPhone 12/13/14 Pro Max
            (1080, 2340), // iPhone 12/13/14 mini
            (1125, 2436), // iPhone X/XS/11 Pro
            (1242, 2688), // iPhone XS Max/11 Pro Max
            (828, 1792),  // iPhone XR/11
            (750, 1334),  // iPhone 6/7/8
            (1242, 2208), // iPhone 6/7/8 Plus
            (640, 1136),  // iPhone 5/5S/5C
            (1080, 1920), // iPhone 6/7/8 Plus (some)
        ]
        
        for (w, h) in commonScreenshotSizes {
            if (width == w && height == h) || (width == h && height == w) {
                return true
            }
        }
        
        // Additional check: if the filename contains "Screenshot" or similar
        // This is harder to check with PHAsset, but we can make educated guesses
        // based on the creation date and other metadata
        
        return false
    }
    
    private func importAllScreenshots() async {
        isProcessing = true
        autoImportProgress = 0.0
        
        let totalCount = foundScreenshots.count
        var processedCount = 0
        
        for asset in foundScreenshots {
            await importScreenshot(asset: asset)
            processedCount += 1
            if totalCount > 0 {
                autoImportProgress = Double(processedCount) / Double(totalCount)
            } else {
                autoImportProgress = 1.0
            }
        }
        
        isProcessing = false
        dismiss()
    }
    
    private func importScreenshot(asset: PHAsset) async {
        let image = await loadImage(from: asset)
        if let image = image {
            await screenshotManager.addScreenshots(from: [image])
        }
    }
    
    private func loadImage(from asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

struct ProcessingView: View {
    @ObservedObject var screenshotManager: ScreenshotManager
    let isAutoImporting: Bool
    let progress: Double
    let totalCount: Int
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isAutoImporting ? "magnifyingglass" : "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotationAngle)
                .onAppear {
                    rotationAngle = 360
                }
            
            VStack(spacing: 8) {
                Text(isAutoImporting ? "Scanning Photos" : "Processing Screenshots")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isAutoImporting ? 
                     "Finding screenshots in your photo library..." : 
                     "AI is analyzing your screenshots for automatic categorization...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if isAutoImporting {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    
                    Text("Scanning \(totalCount) photos...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if screenshotManager.isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 200)
            }
        }
        .padding()
    }
}

// MARK: - Permission Handler
class PhotoPermissionHandler: ObservableObject {
    @Published var hasPermission = false
    @Published var showingPermissionAlert = false
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        hasPermission = status == .authorized || status == .limited
    }
    
    func requestPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.hasPermission = status == .authorized || status == .limited
                if !self.hasPermission {
                    self.showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    PhotoPickerView(
        screenshotManager: ScreenshotManager(
            modelContext: ModelContext(try! ModelContainer(for: Screenshot.self, ScreenshotCategory.self))
        )
    )
}

//
//  ScreenshotCardView.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import SwiftUI

struct ScreenshotCardView: View {
    let screenshot: Screenshot
    @State private var showingImage = false
    
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
                        Button(action: {
                            // Menu action
                        }) {
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
                ImageViewerView(image: image, screenshot: screenshot)
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
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
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
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        screenshot.toggleFavorite()
                    }) {
                        Image(systemName: screenshot.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(screenshot.isFavorite ? .red : .white)
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
    
    return ScreenshotCardView(screenshot: sampleScreenshot)
        .padding()
}

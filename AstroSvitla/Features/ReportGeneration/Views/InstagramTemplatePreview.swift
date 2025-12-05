// Feature: 006-instagram-share-templates
// Description: Full-size template preview with share functionality

import SwiftUI
import UIKit

// MARK: - InstagramTemplatePreview

/// Full-size preview of a selected template with share button
struct InstagramTemplatePreview: View {
    let templateType: ShareTemplateType
    let images: [GeneratedShareImage]
    let onShare: () -> Void
    let onDismiss: () -> Void
    
    @State private var currentSlideIndex = 0
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Colors
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(red: 0.4, green: 0.4, blue: 0.45)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Template preview
                        previewSection(geometry: geometry)
                        
                        Spacer()
                        
                        // Info and actions
                        actionsSection
                    }
                }
            }
            .navigationTitle(templateType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(secondaryTextColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    @ViewBuilder
    private func previewSection(geometry: GeometryProxy) -> some View {
        if images.count == 1, let image = images.first?.image {
            // Single image preview
            singleImagePreview(image: image, geometry: geometry)
        } else if images.count > 1 {
            // Carousel preview with paging
            carouselPreview(geometry: geometry)
        } else {
            // Empty state
            emptyPreview
        }
    }
    
    private func singleImagePreview(image: UIImage, geometry: GeometryProxy) -> some View {
        let aspectRatio = templateType.dimensions.width / templateType.dimensions.height
        let maxWidth = geometry.size.width - 32
        let maxHeight = geometry.size.height * 0.7
        
        let imageWidth: CGFloat
        let imageHeight: CGFloat
        
        if aspectRatio > 1 {
            // Landscape or square
            imageWidth = min(maxWidth, maxHeight * aspectRatio)
            imageHeight = imageWidth / aspectRatio
        } else {
            // Portrait (Stories)
            imageHeight = min(maxHeight, maxWidth / aspectRatio)
            imageWidth = imageHeight * aspectRatio
        }
        
        return Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageWidth, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 16)
            .padding(.top, 16)
    }
    
    private func carouselPreview(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Carousel pager
            TabView(selection: $currentSlideIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, generatedImage in
                    Image(uiImage: generatedImage.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 16)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: geometry.size.height * 0.6)
            
            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<images.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentSlideIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentSlideIndex)
                }
            }
            
            // Slide info
            if let slideType = CarouselSlideType(rawValue: currentSlideIndex) {
                Text(slideType.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(secondaryTextColor)
            }
        }
        .padding(.top, 16)
    }
    
    private var emptyPreview: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(secondaryTextColor.opacity(0.5))
            
            Text("share.preview.unavailable")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Template info
            if templateType == .carousel {
                carouselInfo
            }
            
            // Share button
            Button {
                onShare()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("share.instagram.button")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    private var carouselInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .medium))
            
            Text("share.carousel.info")
                .font(.system(size: 14, weight: .regular))
        }
        .foregroundStyle(secondaryTextColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Single Template Preview") {
    InstagramTemplatePreview(
        templateType: .chartOnly,
        images: [],
        onShare: { },
        onDismiss: { }
    )
}

#Preview("Carousel Preview") {
    InstagramTemplatePreview(
        templateType: .carousel,
        images: [],
        onShare: { },
        onDismiss: { }
    )
}

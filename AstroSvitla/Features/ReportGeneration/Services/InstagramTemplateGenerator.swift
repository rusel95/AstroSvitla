// Feature: 006-instagram-share-templates
// Description: Service for generating Instagram template images

import SwiftUI
import UIKit

// MARK: - InstagramTemplateGenerator

/// Service responsible for rendering Instagram share template images
@MainActor
struct InstagramTemplateGenerator {
    
    // MARK: - Error Types
    
    enum TemplateError: Error, LocalizedError {
        case renderFailed
        case compressionFailed
        case exportFailed(underlying: Error)
        case missingContent
        
        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "Failed to render template image"
            case .compressionFailed:
                return "Failed to compress image data"
            case .exportFailed(let error):
                return "Failed to export image: \(error.localizedDescription)"
            case .missingContent:
                return "Missing required content for template"
            }
        }
    }
    
    // MARK: - Constants
    
    /// Maximum file size for exported images (1MB)
    private static let maxFileSize = 1_000_000
    
    /// JPEG fallback quality if PNG exceeds size limit
    private static let jpegFallbackQuality: CGFloat = 0.85
    
    // MARK: - Render Methods
    
    /// Renders the Chart Only template (9:16 Stories format)
    func renderChartOnly(
        birthDetails: BirthDetails,
        chartImage: UIImage?
    ) throws -> GeneratedShareImage {
        let template = ChartOnlyTemplate(
            birthDetails: birthDetails,
            chartImage: chartImage
        )
        
        let image = try renderTemplate(
            view: template,
            size: ShareTemplateType.chartOnly.dimensions
        )
        
        return GeneratedShareImage(
            templateType: .chartOnly,
            image: image
        )
    }
    
    /// Renders the Key Insights template (1:1 Post format)
    func renderKeyInsights(
        shareContent: ShareContent,
        birthDetails: BirthDetails,
        reportArea: ReportArea
    ) throws -> GeneratedShareImage {
        let template = KeyInsightsTemplate(
            shareContent: shareContent,
            birthDetails: birthDetails,
            reportArea: reportArea
        )
        
        let image = try renderTemplate(
            view: template,
            size: ShareTemplateType.keyInsights.dimensions
        )
        
        return GeneratedShareImage(
            templateType: .keyInsights,
            image: image
        )
    }
    
    /// Renders the Recommendations template (9:16 Stories format)
    func renderRecommendations(
        shareContent: ShareContent,
        reportArea: ReportArea
    ) throws -> GeneratedShareImage {
        let template = RecommendationsTemplate(
            shareContent: shareContent,
            reportArea: reportArea
        )
        
        let image = try renderTemplate(
            view: template,
            size: ShareTemplateType.recommendations.dimensions
        )
        
        return GeneratedShareImage(
            templateType: .recommendations,
            image: image
        )
    }
    
    /// Renders all 5 carousel slides (1:1 Post format each)
    func renderCarousel(
        shareContent: ShareContent,
        birthDetails: BirthDetails,
        reportArea: ReportArea,
        chartImage: UIImage?
    ) throws -> [GeneratedShareImage] {
        var images: [GeneratedShareImage] = []
        
        // Slide 0: Cover
        let coverTemplate = CarouselCoverSlide(
            birthDetails: birthDetails,
            chartImage: chartImage,
            reportArea: reportArea
        )
        let coverImage = try renderTemplate(
            view: coverTemplate,
            size: ShareTemplateType.carousel.dimensions
        )
        images.append(GeneratedShareImage(
            templateType: .carousel,
            slideIndex: 0,
            image: coverImage
        ))
        
        // Slide 1: Influences
        let influencesTemplate = CarouselInfluencesSlide(shareContent: shareContent)
        let influencesImage = try renderTemplate(
            view: influencesTemplate,
            size: ShareTemplateType.carousel.dimensions
        )
        images.append(GeneratedShareImage(
            templateType: .carousel,
            slideIndex: 1,
            image: influencesImage
        ))
        
        // Slide 2: Recommendations
        let recsTemplate = CarouselRecommendationsSlide(shareContent: shareContent)
        let recsImage = try renderTemplate(
            view: recsTemplate,
            size: ShareTemplateType.carousel.dimensions
        )
        images.append(GeneratedShareImage(
            templateType: .carousel,
            slideIndex: 2,
            image: recsImage
        ))
        
        // Slide 3: Analysis
        let analysisTemplate = CarouselAnalysisSlide(shareContent: shareContent)
        let analysisImage = try renderTemplate(
            view: analysisTemplate,
            size: ShareTemplateType.carousel.dimensions
        )
        images.append(GeneratedShareImage(
            templateType: .carousel,
            slideIndex: 3,
            image: analysisImage
        ))
        
        // Slide 4: CTA
        let ctaTemplate = CarouselCTASlide()
        let ctaImage = try renderTemplate(
            view: ctaTemplate,
            size: ShareTemplateType.carousel.dimensions
        )
        images.append(GeneratedShareImage(
            templateType: .carousel,
            slideIndex: 4,
            image: ctaImage
        ))
        
        return images
    }
    
    /// Renders all templates for a report
    func renderAllTemplates(
        report: GeneratedReport,
        birthDetails: BirthDetails,
        chartImage: UIImage?
    ) async throws -> [ShareTemplateType: [GeneratedShareImage]] {
        guard let shareContent = report.shareContent else {
            throw TemplateError.missingContent
        }
        
        var results: [ShareTemplateType: [GeneratedShareImage]] = [:]
        
        // Chart Only
        let chartOnly = try renderChartOnly(
            birthDetails: birthDetails,
            chartImage: chartImage
        )
        results[.chartOnly] = [chartOnly]
        
        // Key Insights
        let keyInsights = try renderKeyInsights(
            shareContent: shareContent,
            birthDetails: birthDetails,
            reportArea: report.area
        )
        results[.keyInsights] = [keyInsights]
        
        // Recommendations
        let recommendations = try renderRecommendations(
            shareContent: shareContent,
            reportArea: report.area
        )
        results[.recommendations] = [recommendations]
        
        // Carousel
        let carousel = try renderCarousel(
            shareContent: shareContent,
            birthDetails: birthDetails,
            reportArea: report.area,
            chartImage: chartImage
        )
        results[.carousel] = carousel
        
        return results
    }
    
    // MARK: - Core Rendering
    
    /// Core method to render any SwiftUI view to an image
    private func renderTemplate<V: View>(view: V, size: CGSize) throws -> UIImage {
        let renderer = ImageRenderer(
            content: view
                .frame(width: size.width, height: size.height)
        )
        
        // Use device scale for high-quality output
        renderer.scale = UIScreen.main.scale
        
        guard let uiImage = renderer.uiImage else {
            throw TemplateError.renderFailed
        }
        
        return uiImage
    }
    
    // MARK: - Image Export
    
    /// Exports image to PNG data, falling back to JPEG if needed
    func exportImageData(_ image: UIImage) throws -> Data {
        // Try PNG first (best quality)
        if let pngData = image.pngData(), pngData.count < Self.maxFileSize {
            return pngData
        }
        
        // Fall back to JPEG if PNG too large
        guard let jpegData = image.jpegData(compressionQuality: Self.jpegFallbackQuality) else {
            throw TemplateError.compressionFailed
        }
        
        return jpegData
    }
    
    /// Exports image to a temporary file
    func exportToTempFile(_ generatedImage: GeneratedShareImage) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("zorya-share-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        
        let fileURL = tempDir.appendingPathComponent(generatedImage.suggestedFilename)
        let data = try exportImageData(generatedImage.image)
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    /// Exports multiple images to temporary files (for carousel)
    func exportToTempFiles(_ images: [GeneratedShareImage]) throws -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("zorya-carousel-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )
        
        var urls: [URL] = []
        
        for generatedImage in images {
            let fileURL = tempDir.appendingPathComponent(generatedImage.suggestedFilename)
            let data = try exportImageData(generatedImage.image)
            try data.write(to: fileURL)
            urls.append(fileURL)
        }
        
        return urls
    }
    
    /// Cleans up temporary files
    func cleanupTempFiles(at urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Also remove parent directory if it's a temp directory
        if let first = urls.first {
            let parentDir = first.deletingLastPathComponent()
            if parentDir.path.contains("zorya-") {
                try? FileManager.default.removeItem(at: parentDir)
            }
        }
    }
}

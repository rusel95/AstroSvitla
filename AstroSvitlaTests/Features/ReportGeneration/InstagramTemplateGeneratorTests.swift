// Feature: 006-instagram-share-templates
// Description: Unit tests for InstagramTemplateGenerator service

import Testing
import SwiftUI
import UIKit
@testable import AstroSvitla

// MARK: - InstagramTemplateGenerator Tests

@Suite("InstagramTemplateGenerator")
struct InstagramTemplateGeneratorTests {
    
    // MARK: - Fixture Data
    
    private var testShareContent: ShareContent {
        ShareContent.preview
    }
    
    private var testBirthDetails: BirthDetails {
        BirthDetails(
            name: "Test User",
            birthDate: Date(),
            birthTime: Date(),
            location: "Kyiv, Ukraine"
        )
    }
    
    private var testReport: GeneratedReport {
        GeneratedReport(
            area: .career,
            summary: "Test summary",
            keyInfluences: ["A", "B", "C"],
            detailedAnalysis: "Test analysis",
            recommendations: ["R1", "R2", "R3"],
            knowledgeUsage: KnowledgeUsage(vectorSourceUsed: false, notes: nil),
            metadata: GenerationMetadata(
                modelName: "test",
                promptTokens: 0,
                completionTokens: 0,
                totalTokens: 0,
                estimatedCost: 0,
                processingTimeSeconds: 0,
                knowledgeSnippetsProvided: 0,
                totalSourcesCited: 0,
                vectorDatabaseSourcesCount: 0,
                externalSourcesCount: 0
            ),
            shareContent: ShareContent.preview
        )
    }
    
    // MARK: - Template Rendering Tests
    
    @Test("Renders ChartOnly template successfully")
    @MainActor
    func rendersChartOnlyTemplate() throws {
        let generator = InstagramTemplateGenerator()
        
        let image = try generator.renderChartOnly(
            birthDetails: testBirthDetails,
            chartImage: nil,
            shareContent: testShareContent
        )
        
        #expect(image.templateType == .chartOnly)
        #expect(image.slideIndex == nil)
        #expect(image.image.size.width > 0)
        #expect(image.image.size.height > 0)
    }
    
    @Test("Renders KeyInsights template successfully")
    @MainActor
    func rendersKeyInsightsTemplate() throws {
        let generator = InstagramTemplateGenerator()
        
        let image = try generator.renderKeyInsights(
            shareContent: testShareContent,
            birthDetails: testBirthDetails,
            reportArea: .career
        )
        
        #expect(image.templateType == .keyInsights)
        #expect(image.slideIndex == nil)
    }
    
    @Test("Renders Recommendations template successfully")
    @MainActor
    func rendersRecommendationsTemplate() throws {
        let generator = InstagramTemplateGenerator()
        
        let image = try generator.renderRecommendations(
            shareContent: testShareContent,
            reportArea: .career
        )
        
        #expect(image.templateType == .recommendations)
    }
    
    @Test("Renders Carousel template with 5 slides")
    @MainActor
    func rendersCarouselTemplate() throws {
        let generator = InstagramTemplateGenerator()
        
        let images = try generator.renderCarousel(
            shareContent: testShareContent,
            birthDetails: testBirthDetails,
            reportArea: .career,
            chartImage: nil
        )
        
        #expect(images.count == 5)
        
        for (index, image) in images.enumerated() {
            #expect(image.templateType == .carousel)
            #expect(image.slideIndex == index)
        }
    }
    
    @Test("Renders all templates for report")
    @MainActor
    func rendersAllTemplates() async throws {
        let generator = InstagramTemplateGenerator()
        
        let results = try await generator.renderAllTemplates(
            report: testReport,
            birthDetails: testBirthDetails,
            chartImage: nil
        )
        
        #expect(results.count == 4)
        #expect(results[.chartOnly]?.count == 1)
        #expect(results[.keyInsights]?.count == 1)
        #expect(results[.recommendations]?.count == 1)
        #expect(results[.carousel]?.count == 5)
    }
    
    // MARK: - Image Export Tests
    
    @Test("Exports image data")
    @MainActor
    func exportsImageData() throws {
        let generator = InstagramTemplateGenerator()
        
        // Create a small test image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let data = try generator.exportImageData(testImage)
        
        #expect(data.count > 0)
    }
    
    @Test("Exports to temp file")
    @MainActor
    func exportsToTempFile() throws {
        let generator = InstagramTemplateGenerator()
        
        let testImage = UIImage(systemName: "star.fill") ?? UIImage()
        let generatedImage = GeneratedShareImage(
            templateType: .chartOnly,
            image: testImage
        )
        
        let url = try generator.exportToTempFile(generatedImage)
        
        #expect(FileManager.default.fileExists(atPath: url.path))
        
        // Cleanup
        generator.cleanupTempFiles(at: [url])
    }
    
    @Test("Exports multiple to temp files")
    @MainActor
    func exportsMultipleToTempFiles() throws {
        let generator = InstagramTemplateGenerator()
        
        let testImage = UIImage(systemName: "star.fill") ?? UIImage()
        let images = (0..<3).map { index in
            GeneratedShareImage(
                templateType: .carousel,
                slideIndex: index,
                image: testImage
            )
        }
        
        let urls = try generator.exportToTempFiles(images)
        
        #expect(urls.count == 3)
        for url in urls {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
        
        // Cleanup
        generator.cleanupTempFiles(at: urls)
    }
    
    // MARK: - Cleanup Tests
    
    @Test("Cleanup removes temp files")
    @MainActor
    func cleanupRemovesTempFiles() throws {
        let generator = InstagramTemplateGenerator()
        
        let testImage = UIImage(systemName: "star.fill") ?? UIImage()
        let generatedImage = GeneratedShareImage(
            templateType: .chartOnly,
            image: testImage
        )
        
        let url = try generator.exportToTempFile(generatedImage)
        
        #expect(FileManager.default.fileExists(atPath: url.path))
        
        generator.cleanupTempFiles(at: [url])
        
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }
}

// MARK: - Template Error Tests

@Suite("TemplateError")
struct TemplateErrorTests {
    
    @Test("Error descriptions are not empty")
    func errorDescriptionsNotEmpty() {
        let errors: [InstagramTemplateGenerator.TemplateError] = [
            .renderFailed,
            .compressionFailed,
            .exportFailed(underlying: NSError(domain: "test", code: 1)),
            .missingContent
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

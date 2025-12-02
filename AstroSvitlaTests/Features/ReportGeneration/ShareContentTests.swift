// Feature: 006-instagram-share-templates
// Description: Unit tests for ShareContent model and related types

import Testing
import Foundation
import UIKit
@testable import AstroSvitla

// MARK: - ShareContent Validation Tests

@Suite("ShareContent Validation")
struct ShareContentValidationTests {
    
    @Test("Valid content passes validation")
    func validContentIsValid() {
        let content = ShareContent.preview
        #expect(content.isValid)
    }
    
    @Test("Max length content passes validation")
    func maxLengthContentIsValid() {
        let content = ShareContent.maxLengthPreview
        #expect(content.isValid)
    }
    
    @Test("Ukrainian content passes validation")
    func ukrainianContentIsValid() {
        let content = ShareContent.ukrainianPreview
        #expect(content.isValid)
    }
    
    @Test("Summary exceeding 280 chars fails validation")
    func summaryTooLongIsInvalid() {
        let content = ShareContent(
            condensedSummary: String(repeating: "X", count: 281),
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content.isValid)
    }
    
    @Test("Empty summary fails validation")
    func emptySummaryIsInvalid() {
        let content = ShareContent(
            condensedSummary: "",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content.isValid)
    }
    
    @Test("Wrong influences count fails validation")
    func wrongInfluencesCountIsInvalid() {
        // Only 2 influences
        let content1 = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content1.isValid)
        
        // 4 influences
        let content2 = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C", "D"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content2.isValid)
    }
    
    @Test("Influence exceeding 40 chars fails validation")
    func influenceTooLongIsInvalid() {
        let content = ShareContent(
            condensedSummary: "Test",
            topInfluences: [
                String(repeating: "A", count: 41),
                "B",
                "C"
            ],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content.isValid)
    }
    
    @Test("Wrong recommendations count fails validation")
    func wrongRecommendationsCountIsInvalid() {
        let content = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content.isValid)
    }
    
    @Test("Recommendation exceeding 60 chars fails validation")
    func recommendationTooLongIsInvalid() {
        let content = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: [
                String(repeating: "R", count: 61),
                "2",
                "3"
            ],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(!content.isValid)
    }
    
    @Test("Analysis highlights count validates correctly")
    func analysisHighlightsCountValidation() {
        // 2 highlights - too few
        let content1 = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2"]
        )
        #expect(!content1.isValid)
        
        // 3 highlights - valid
        let content2 = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        #expect(content2.isValid)
        
        // 4 highlights - valid
        let content3 = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3", "P4"]
        )
        #expect(content3.isValid)
        
        // 5 highlights - too many
        let content4 = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3", "P4", "P5"]
        )
        #expect(!content4.isValid)
    }
    
    @Test("Analysis highlight exceeding 50 chars fails validation")
    func analysisHighlightTooLongIsInvalid() {
        let content = ShareContent(
            condensedSummary: "Test",
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: [
                String(repeating: "H", count: 51),
                "P2",
                "P3"
            ]
        )
        #expect(!content.isValid)
    }
}

// MARK: - ShareContent Decoding Tests

@Suite("ShareContent Decoding")
struct ShareContentDecodingTests {
    
    @Test("Decodes from valid JSON")
    func decodingFromJSON() throws {
        let json = """
        {
            "condensedSummary": "Test summary",
            "topInfluences": ["☉ Sun: Test", "☽ Moon: Test", "♀ Venus: Test"],
            "topRecommendations": ["Rec 1", "Rec 2", "Rec 3"],
            "analysisHighlights": ["Point 1", "Point 2", "Point 3"]
        }
        """.data(using: .utf8)!
        
        let content = try JSONDecoder().decode(ShareContent.self, from: json)
        
        #expect(content.condensedSummary == "Test summary")
        #expect(content.topInfluences.count == 3)
        #expect(content.topRecommendations.count == 3)
        #expect(content.analysisHighlights.count == 3)
        #expect(content.isValid)
    }
    
    @Test("Encodes to JSON")
    func encodingToJSON() throws {
        let content = ShareContent.preview
        let data = try JSONEncoder().encode(content)
        let decoded = try JSONDecoder().decode(ShareContent.self, from: data)
        
        #expect(content == decoded)
    }
}

// MARK: - ShareContent Sanitization Tests

@Suite("ShareContent Sanitization")
struct ShareContentSanitizationTests {
    
    @Test("Sanitizes long summary")
    func sanitizesLongSummary() {
        let content = ShareContent(
            condensedSummary: String(repeating: "X", count: 300),
            topInfluences: ["A", "B", "C"],
            topRecommendations: ["1", "2", "3"],
            analysisHighlights: ["P1", "P2", "P3"]
        )
        
        let sanitized = content.sanitized()
        
        #expect(sanitized.condensedSummary.count <= 280)
        #expect(sanitized.condensedSummary.hasSuffix("…"))
    }
    
    @Test("Valid content unchanged after sanitization")
    func validContentUnchanged() {
        let content = ShareContent.preview
        let sanitized = content.sanitized()
        
        #expect(content == sanitized)
    }
}

// MARK: - ShareTemplateType Tests

@Suite("ShareTemplateType")
struct ShareTemplateTypeTests {
    
    @Test("All cases exist")
    func allCasesExist() {
        #expect(ShareTemplateType.allCases.count == 4)
    }
    
    @Test("ChartOnly has correct dimensions")
    func chartOnlyDimensions() {
        let template = ShareTemplateType.chartOnly
        #expect(template.dimensions == CGSize(width: 1080, height: 1920))
        #expect(template.imageCount == 1)
    }
    
    @Test("KeyInsights has correct dimensions")
    func keyInsightsDimensions() {
        let template = ShareTemplateType.keyInsights
        #expect(template.dimensions == CGSize(width: 1080, height: 1080))
        #expect(template.imageCount == 1)
    }
    
    @Test("Recommendations has correct dimensions")
    func recommendationsDimensions() {
        let template = ShareTemplateType.recommendations
        #expect(template.dimensions == CGSize(width: 1080, height: 1920))
        #expect(template.imageCount == 1)
    }
    
    @Test("Carousel has correct dimensions and image count")
    func carouselDimensions() {
        let template = ShareTemplateType.carousel
        #expect(template.dimensions == CGSize(width: 1080, height: 1080))
        #expect(template.imageCount == 5)
    }
    
    @Test("Each template has an icon")
    func templatesHaveIcons() {
        for template in ShareTemplateType.allCases {
            #expect(!template.icon.isEmpty)
        }
    }
    
    @Test("Each template has a display name")
    func templatesHaveDisplayNames() {
        for template in ShareTemplateType.allCases {
            #expect(!template.displayName.isEmpty)
        }
    }
    
    @Test("Each template has a description")
    func templatesHaveDescriptions() {
        for template in ShareTemplateType.allCases {
            #expect(!template.description.isEmpty)
        }
    }
}

// MARK: - CarouselSlideType Tests

@Suite("CarouselSlideType")
struct CarouselSlideTypeTests {
    
    @Test("All 5 carousel slides exist")
    func allSlidesExist() {
        #expect(CarouselSlideType.allCases.count == 5)
    }
    
    @Test("Slide indices are sequential")
    func slideIndicesSequential() {
        let indices = CarouselSlideType.allCases.map { $0.rawValue }
        #expect(indices == [0, 1, 2, 3, 4])
    }
    
    @Test("Each slide has a title")
    func slidesHaveTitles() {
        for slide in CarouselSlideType.allCases {
            #expect(!slide.title.isEmpty)
        }
    }
}

// MARK: - GeneratedShareImage Tests

@Suite("GeneratedShareImage")
struct GeneratedShareImageTests {
    
    @Test("Creates correct filename for single templates")
    func singleTemplateFilename() {
        let image = UIImage()
        
        let chartOnly = GeneratedShareImage(
            templateType: .chartOnly,
            image: image
        )
        #expect(chartOnly.suggestedFilename == "zorya-chart_only.png")
        
        let keyInsights = GeneratedShareImage(
            templateType: .keyInsights,
            image: image
        )
        #expect(keyInsights.suggestedFilename == "zorya-key_insights.png")
    }
    
    @Test("Creates correct filename for carousel slides")
    func carouselFilenames() {
        let image = UIImage()
        
        for index in 0..<5 {
            let slide = GeneratedShareImage(
                templateType: .carousel,
                slideIndex: index,
                image: image
            )
            #expect(slide.suggestedFilename == "zorya-carousel-\(index + 1).png")
        }
    }
    
    @Test("Carousel without slide index uses default filename")
    func carouselNoIndexFilename() {
        let image = UIImage()
        let slide = GeneratedShareImage(
            templateType: .carousel,
            slideIndex: nil,
            image: image
        )
        #expect(slide.suggestedFilename == "zorya-carousel.png")
    }
}

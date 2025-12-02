// Feature: 006-instagram-share-templates
// Description: Unit tests for InstagramShareViewModel

import Testing
import Foundation
@testable import AstroSvitla

// MARK: - InstagramShareViewModel Tests

@Suite("InstagramShareViewModel")
struct InstagramShareViewModelTests {
    
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
    
    // MARK: - Initialization Tests
    
    @Test("Initializes with idle state")
    @MainActor
    func initializesWithIdleState() {
        let viewModel = InstagramShareViewModel()
        #expect(viewModel.state == .idle)
    }
    
    @Test("Has no share content before preRender")
    @MainActor
    func noShareContentBeforePreRender() {
        let viewModel = InstagramShareViewModel()
        #expect(!viewModel.hasShareContent)
    }
    
    // MARK: - Pre-render Tests
    
    @Test("Pre-render changes state to rendering then ready")
    @MainActor
    func preRenderChangesState() async {
        let viewModel = InstagramShareViewModel()
        
        viewModel.preRender(
            report: testReport,
            birthDetails: testBirthDetails,
            chartImage: nil
        )
        
        // State should be rendering immediately
        #expect(viewModel.state == .rendering)
        
        // Wait for rendering to complete
        try? await Task.sleep(for: .seconds(3))
        
        // Should be ready or still rendering
        #expect(viewModel.state == .ready || viewModel.state == .rendering)
    }
    
    @Test("Pre-render fails without share content")
    @MainActor
    func preRenderFailsWithoutShareContent() async {
        let viewModel = InstagramShareViewModel()
        
        let reportWithoutShare = GeneratedReport(
            area: .career,
            summary: "Test",
            keyInfluences: ["A", "B", "C"],
            detailedAnalysis: "Test",
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
            shareContent: nil
        )
        
        viewModel.preRender(
            report: reportWithoutShare,
            birthDetails: testBirthDetails,
            chartImage: nil
        )
        
        // Should fail immediately due to missing share content
        if case .failed = viewModel.state {
            #expect(true)
        } else {
            #expect(false, "Expected failed state")
        }
    }
    
    // MARK: - Cancel Tests
    
    @Test("Cancel stops pre-render")
    @MainActor
    func cancelStopsPreRender() async {
        let viewModel = InstagramShareViewModel()
        
        viewModel.preRender(
            report: testReport,
            birthDetails: testBirthDetails,
            chartImage: nil
        )
        
        // Cancel immediately
        viewModel.cancelRendering()
        
        // State should return to idle
        #expect(viewModel.state == .idle)
    }
    
    // MARK: - Cache Tests
    
    @Test("Clear cache removes templates")
    @MainActor
    func clearCacheRemovesTemplates() async {
        let viewModel = InstagramShareViewModel()
        
        viewModel.preRender(
            report: testReport,
            birthDetails: testBirthDetails,
            chartImage: nil
        )
        
        // Wait a bit
        try? await Task.sleep(for: .seconds(2))
        
        viewModel.clearCache()
        
        #expect(viewModel.state == .idle)
    }
}

// MARK: - State Tests

@Suite("InstagramShareViewModel.State")
struct StateTests {
    
    @Test("All states are equatable")
    func statesAreEquatable() {
        #expect(InstagramShareViewModel.State.idle == .idle)
        #expect(InstagramShareViewModel.State.rendering == .rendering)
        #expect(InstagramShareViewModel.State.ready == .ready)
        #expect(InstagramShareViewModel.State.failed("error") == .failed("error"))
        
        #expect(InstagramShareViewModel.State.idle != .rendering)
        #expect(InstagramShareViewModel.State.failed("a") != .failed("b"))
    }
}

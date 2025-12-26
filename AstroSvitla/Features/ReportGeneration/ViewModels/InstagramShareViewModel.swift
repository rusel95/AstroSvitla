// Feature: 006-instagram-share-templates
// Description: ViewModel for managing Instagram share template state

import SwiftUI
import Observation

// MARK: - InstagramShareViewModel

/// ViewModel for managing pre-rendering and sharing of Instagram templates
@MainActor
@Observable
final class InstagramShareViewModel {
    
    // MARK: - State
    
    enum State: Equatable {
        case idle
        case rendering
        case ready
        case failed(String)
        
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.rendering, .rendering), (.ready, .ready):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    /// Current rendering state
    private(set) var state: State = .idle
    
    /// Rendered templates, keyed by template type
    private(set) var renderedTemplates: [ShareTemplateType: [GeneratedShareImage]] = [:]
    
    /// Whether share content is available
    var hasShareContent: Bool {
        report?.shareContent != nil
    }
    
    /// Whether templates are ready for sharing
    var isReady: Bool {
        state == .ready && !renderedTemplates.isEmpty
    }
    
    /// Progress for UI indicator (0.0 - 1.0)
    private(set) var renderProgress: Double = 0.0
    
    // MARK: - Private
    
    private let generator = InstagramTemplateGenerator()
    private var report: GeneratedReport?
    private var birthDetails: BirthDetails?
    private var chartImage: UIImage?
    private var renderTask: Task<Void, Never>?
    
    // MARK: - Pre-Rendering
    
    /// Pre-renders all templates in the background
    func preRender(
        report: GeneratedReport,
        birthDetails: BirthDetails,
        chartImage: UIImage?
    ) {
        // Cancel any existing render task
        renderTask?.cancel()
        
        // Store references for potential re-render
        self.report = report
        self.birthDetails = birthDetails
        self.chartImage = chartImage
        
        // Check for share content availability
        guard report.shareContent != nil else {
            state = .failed(String(localized: "share_unavailable", defaultValue: "Share not available for this report"))
            return
        }
        
        state = .rendering
        renderProgress = 0.0
        renderedTemplates = [:]
        
        renderTask = Task { [weak self] in
            await self?.performRender()
        }
    }
    
    /// Performs the actual rendering work
    private func performRender() async {
        guard let report, let birthDetails else {
            state = .failed("Missing report data")
            return
        }
        
        let templateTypes = ShareTemplateType.allCases
        let totalTemplates = templateTypes.count
        var completedTemplates = 0
        
        for templateType in templateTypes {
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            
            do {
                let images = try await renderTemplate(
                    type: templateType,
                    report: report,
                    birthDetails: birthDetails,
                    chartImage: chartImage
                )
                
                renderedTemplates[templateType] = images
                completedTemplates += 1
                renderProgress = Double(completedTemplates) / Double(totalTemplates)
                
            } catch {
                print("[InstagramShareViewModel] Failed to render \(templateType): \(error)")
                // Continue with other templates
            }
        }
        
        if renderedTemplates.isEmpty {
            state = .failed("Failed to render templates")
        } else {
            state = .ready
        }
    }
    
    /// Renders a specific template type
    private func renderTemplate(
        type: ShareTemplateType,
        report: GeneratedReport,
        birthDetails: BirthDetails,
        chartImage: UIImage?
    ) async throws -> [GeneratedShareImage] {
        guard let shareContent = report.shareContent else {
            throw InstagramTemplateGenerator.TemplateError.missingContent
        }
        
        switch type {
        case .chartOnly:
            let image = try generator.renderChartOnly(
                birthDetails: birthDetails,
                chartImage: chartImage,
                shareContent: shareContent
            )
            return [image]
            
        case .keyInsights:
            let image = try generator.renderKeyInsights(
                shareContent: shareContent,
                birthDetails: birthDetails,
                reportArea: report.area
            )
            return [image]
            
        case .recommendations:
            let image = try generator.renderRecommendations(
                shareContent: shareContent,
                reportArea: report.area
            )
            return [image]
            
        case .carousel:
            return try generator.renderCarousel(
                shareContent: shareContent,
                birthDetails: birthDetails,
                reportArea: report.area,
                chartImage: chartImage
            )
        }
    }
    
    // MARK: - Sharing
    
    /// Gets images for a specific template type
    func getImages(for templateType: ShareTemplateType) -> [GeneratedShareImage] {
        renderedTemplates[templateType] ?? []
    }
    
    /// Gets the first/thumbnail image for a template type
    func getThumbnail(for templateType: ShareTemplateType) -> UIImage? {
        renderedTemplates[templateType]?.first?.image
    }
    
    /// Exports images to temporary files for sharing
    func exportForSharing(templateType: ShareTemplateType) throws -> [URL] {
        guard let images = renderedTemplates[templateType], !images.isEmpty else {
            throw InstagramTemplateGenerator.TemplateError.missingContent
        }
        
        if images.count == 1 {
            let url = try generator.exportToTempFile(images[0])
            return [url]
        } else {
            return try generator.exportToTempFiles(images)
        }
    }
    
    /// Cleans up temporary files after sharing
    func cleanupAfterSharing(urls: [URL]) {
        generator.cleanupTempFiles(at: urls)
    }
    
    // MARK: - Lifecycle
    
    /// Cancels any ongoing render task
    func cancelRendering() {
        renderTask?.cancel()
        renderTask = nil
        state = .idle
    }
    
    /// Clears all rendered templates from memory
    func clearCache() {
        renderedTemplates = [:]
        state = .idle
    }
}

// Feature: 006-instagram-share-templates
// Description: Modal view for selecting Instagram share templates

import SwiftUI

// MARK: - InstagramShareSheet

/// Modal view displaying available Instagram share templates
struct InstagramShareSheet: View {
    @State private var viewModel: InstagramShareViewModel
    let report: GeneratedReport
    let birthDetails: BirthDetails
    let chartImage: UIImage?
    let onSelectTemplate: (ShareTemplateType, [GeneratedShareImage]) -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        report: GeneratedReport,
        birthDetails: BirthDetails,
        chartImage: UIImage?,
        onSelectTemplate: @escaping (ShareTemplateType, [GeneratedShareImage]) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: InstagramShareViewModel())
        self.report = report
        self.birthDetails = birthDetails
        self.chartImage = chartImage
        self.onSelectTemplate = onSelectTemplate
        self.onDismiss = onDismiss
    }
    
    // MARK: - Colors
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.96, green: 0.95, blue: 0.98)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(red: 0.4, green: 0.4, blue: 0.45)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color(red: 0.85, green: 0.83, blue: 0.88)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text("Share to Instagram", comment: "Share sheet title"))
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
        .task {
            viewModel.preRender(
                report: report,
                birthDetails: birthDetails,
                chartImage: chartImage
            )
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .rendering:
            loadingView
            
        case .ready:
            templateGrid
            
        case .failed(let message):
            errorView(message: message)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Preparing templates...", comment: "Loading state")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(secondaryTextColor)
            
            if viewModel.renderProgress > 0 {
                ProgressView(value: viewModel.renderProgress)
                    .frame(width: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Template Grid
    
    private var templateGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(ShareTemplateType.allCases) { templateType in
                    templateCard(for: templateType)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
    }
    
    private func templateCard(for templateType: ShareTemplateType) -> some View {
        Button {
            let images = viewModel.getImages(for: templateType)
            if !images.isEmpty {
                onSelectTemplate(templateType, images)
            }
        } label: {
            VStack(spacing: 12) {
                // Thumbnail preview
                thumbnailView(for: templateType)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                
                // Template info
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: templateType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                        
                        Text(templateType.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(primaryTextColor)
                    }
                    
                    Text(templateType.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(secondaryTextColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func thumbnailView(for templateType: ShareTemplateType) -> some View {
        if let thumbnail = viewModel.getThumbnail(for: templateType) {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Rectangle()
                    .fill(cardBackground)
                
                Image(systemName: templateType.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(secondaryTextColor.opacity(0.5))
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.orange)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(primaryTextColor)
                .multilineTextAlignment(.center)
            
            Button {
                onDismiss()
            } label: {
                Text("Close", comment: "Close button")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview("Share Sheet") {
    InstagramShareSheet(
        report: GeneratedReport(
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
        ),
        birthDetails: BirthDetails(
            name: "Test",
            birthDate: .now,
            birthTime: .now,
            location: "Kyiv"
        ),
        chartImage: nil,
        onSelectTemplate: { _, _ in },
        onDismiss: { }
    )
}

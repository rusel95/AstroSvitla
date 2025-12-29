import Foundation

extension GeneratedReport {
    /// Returns the existing shareContent if available, or generates a fallback one from the report data.
    var effectiveShareContent: ShareContent {
        if let shareContent = shareContent {
            return shareContent
        }
        
        return generateFallbackShareContent()
    }
    
    private func generateFallbackShareContent() -> ShareContent {
        // 1. Summary
        let condensedSummary = summary.truncatedForShare(maxLength: 280)
        
        // 2. Top Influences (take up to 3)
        let topInfluences = keyInfluences.prefix(3).map {
            $0.truncatedForShare(maxLength: 40)
        }
        
        // Ensure we have exactly 3 for the struct validation (it requires count == 3)
        // If we have fewer than 3, we might need to pad or duplicate?
        // Let's check ShareContent.isValid: topInfluences.count == 3
        // If the report has fewer than 3 keyInfluences, we are in trouble.
        // But usually reports have more. If not, we'll pad with empty strings or generic text?
        // Wait, ShareContent.isValid checks $0.count > 0.
        // So we need non-empty strings.
        
        var safeTopInfluences = Array(topInfluences)
        while safeTopInfluences.count < 3 {
             safeTopInfluences.append("Important Influence") // Fallback
        }
        
        // 3. Recommendations (take up to 3)
        let topRecommendations = recommendations.prefix(3).map {
            $0.truncatedForShare(maxLength: 60)
        }
        
        var safeTopRecommendations = Array(topRecommendations)
        while safeTopRecommendations.count < 3 {
            safeTopRecommendations.append("Reflect on your path") // Fallback
        }
        
        // 4. Analysis Highlights (3-4 items)
        // Try to extract from detailedAnalysis
        var analysisHighlights: [String] = []
        let sentences = detailedAnalysis
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            
        analysisHighlights = sentences.prefix(3).map {
            $0.truncatedForShare(maxLength: 50)
        }
        
        // Fallback if analysis is too short or empty
        if analysisHighlights.isEmpty {
            // Use key influences if analysis is empty
            analysisHighlights = keyInfluences.prefix(3).map {
                $0.truncatedForShare(maxLength: 50)
            }
        }
        
        // Ensure 3-4 items
        while analysisHighlights.count < 3 {
            analysisHighlights.append("Insightful analysis")
        }
        if analysisHighlights.count > 4 {
            analysisHighlights = Array(analysisHighlights.prefix(4))
        }
        
        return ShareContent(
            condensedSummary: condensedSummary,
            topInfluences: safeTopInfluences,
            topRecommendations: safeTopRecommendations,
            analysisHighlights: analysisHighlights
        )
    }
}

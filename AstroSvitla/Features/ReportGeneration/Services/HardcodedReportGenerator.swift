import Foundation

actor HardcodedReportGenerator {

    func generateReport(for area: ReportArea, birthDetails: BirthDetails, knowledgeSnippets: [String]) async throws -> GeneratedReport {
        try await Task.sleep(nanoseconds: 600_000_000) // Simulate network latency

        let summary = summary(for: area, details: birthDetails)
        let influences = keyInfluences(for: birthDetails)
        let analysis = detailedAnalysis(for: area, details: birthDetails, knowledgeSnippets: knowledgeSnippets)
        let recommendations = recommendations(for: area, knowledgeSnippets: knowledgeSnippets)

        return GeneratedReport(
            area: area,
            summary: summary,
            keyInfluences: influences,
            detailedAnalysis: analysis,
            recommendations: recommendations
        )
    }

    // MARK: - Private Helpers

    private func summary(for area: ReportArea, details: BirthDetails) -> String {
        let name = details.displayName
        let location = details.formattedLocation
        return "\(name)'s \(area.displayName.lowercased()) outlook blends the energy of a \(location) birth with steady earth-water harmonies and confident fire support."
    }

    private func keyInfluences(for details: BirthDetails) -> [String] {
        [
            "First House (Self): Aquarius 12° — inventive instincts help \(details.displayName.lowercased()) stand out.",
            "Tenth House (Legacy): Scorpio 18° — transformation through focused effort powers career milestones.",
            "Jupiter trine Moon — faith and intuition collaborate, sustaining momentum during transitions.",
            "Venus sextile Saturn — disciplined affection turns long-term commitments into a stabilizing force.",
        ]
    }

    private func detailedAnalysis(for area: ReportArea, details: BirthDetails, knowledgeSnippets: [String]) -> String {
        let knowledgeSection = makeKnowledgeSection(from: knowledgeSnippets)
        switch area {
        case .finances:
            return """
            Your second house is nourished by earthy sensibilities, encouraging practical financial plans and patient accumulation. \
            The harmony between Venus and Saturn favors steady value-building — think disciplined savings, reliable partners, and \
            well-researched investments. With Jupiter supporting your Moon, you read opportunities intuitively, especially when they \
            align with personal meaning. Aim resources toward projects that blend creativity with tangible results; your chart rewards \
            craft, refinement, and long-term focus.
            \(knowledgeSection)
            """

        case .career:
            return """
            A focused tenth house invites bold yet calculated career moves. The Scorpio Midheaven thrives on meaningful impact, asking \
            you to lead transformations others shy away from. The Aquarius first house keeps ideas inventive, while Jupiter's influence \
            ensures mentors and allies appear when you take courageous next steps. Continual learning and thoughtful networking will \
            position you for leadership where strategy, innovation, and depth intersect.
            \(knowledgeSection)
            """

        case .relationships:
            return """
            Relationships flourish when curiosity meets emotional steadiness. With Venus harmonizing Saturn, you invite partners who \
            respect structure, promises, and mutual aspirations. The supportive Moon-Jupiter flow encourages warmth and generosity, \
            especially when you share big-picture dreams. Keep communication honest and imaginative; exploring together prevents routines \
            from feeling stale and keeps the bond growing in both tenderness and purpose.
            \(knowledgeSection)
            """

        case .health:
            return """
            Wellness thrives on rhythmic routines backed by meaningful motivation. Earth-water balances steady energy levels, making \
            consistency your greatest ally. Choose practices that combine grounding with creativity — think structured movement, mindful \
            cooking, or artistic expression. Rest is non-negotiable; the Aquarius influence craves mental stimulation, so schedule downtime \
            deliberately to maintain focus and restore nervous system balance.
            \(knowledgeSection)
            """

        case .general:
            return """
            This chart tells the story of an innovator anchored by emotional intelligence. Your path forward is about weaving insight into \
            tangible outcomes, building legacies that uplift others while honoring your independent spirit. Trust the steady rhythms that \
            keep you nourished, and allow curiosity to guide bold pivots. Each milestone becomes a testament to both your resilience and \
            your willingness to lead with heart.
            \(knowledgeSection)
            """
        }
    }

    private func recommendations(for area: ReportArea, knowledgeSnippets: [String]) -> [String] {
        let supplemental = knowledgeSnippets.prefix(2)
        switch area {
        case .finances:
            return [
                "Review spending weekly to keep intentions aligned with resources.",
                "Invest in skills that blend creativity with practical application.",
                "Set quarterly milestones for savings or debt reduction.",
            ] + supplemental.map { snippet in "Використай у плануванні: \(snippet)" }

        case .career:
            return [
                "Highlight transformation stories in your portfolio or résumé.",
                "Seek mentorship with leaders known for strategic reinvention.",
                "Pitch a bold improvement project within the next 30 days.",
            ] + supplemental.map { snippet in "Зафіксуй у стратегії розвитку: \(snippet)" }

        case .relationships:
            return [
                "Plan experiences that combine novelty with meaningful dialogue.",
                "Revisit shared goals and refresh them with personal updates.",
                "Schedule regular check-ins to celebrate progress together.",
            ] + supplemental.map { snippet in "Поговоріть про аспект: \(snippet)" }

        case .health:
            return [
                "Adopt a morning ritual that activates body and creativity.",
                "Rotate nourishing meals that excite your senses.",
                "Block out digital detox evenings to reset energy and focus.",
            ] + supplemental.map { snippet in "Додай до програми відновлення: \(snippet)" }

        case .general:
            return [
                "Journal monthly about areas where curiosity is pulling you forward.",
                "Celebrate milestones publicly to invite supportive collaborators.",
                "Design a personal retreat day each quarter for strategic reflection.",
            ] + supplemental.map { snippet in "Поглиб свій аналіз темою: \(snippet)" }
        }
    }

    private func makeKnowledgeSection(from snippets: [String]) -> String {
        guard snippets.isEmpty == false else { return "" }
        let formatted = snippets.prefix(4).map { snippet in "• \(snippet)" }.joined(separator: "\n")
        return "\nАктуальні правила для цієї інтерпретації:\n\\(formatted)\n"
    }
}

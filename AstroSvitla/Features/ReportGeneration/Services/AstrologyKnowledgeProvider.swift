import Foundation

actor AstrologyKnowledgeProvider {

    func loadSnippets(
        for area: ReportArea,
        birthDetails: BirthDetails,
        natalChart: NatalChart
    ) async -> [String] {
        // TODO(T5.0.3): Replace stub with OpenAI vector store retrieval.
        // Future implementation will:
        // 1. Upload chunked rules to OpenAI Files + Vector Store (see plan P5.0).
        // 2. Query the hosted vector store for top-K matches (metadata filters).
        // 3. Return succinct Ukrainian summaries to feed the prompt.

        // Generate context from actual chart data
        let chartContext = buildChartContext(from: natalChart)

        let baseContext = chartContext

        switch area {
        case .finances:
            return baseContext + [
                "Друге домове управління вимагає планомірного створення капіталу та роботи з емоційною цінністю грошей."
            ]
        case .career:
            return baseContext + [
                "Шостий та десятий доми наголошують на потребі в роботі, де поєднуються стратегія і глибина впливу."
            ]
        case .relationships:
            return baseContext + [
                "Венера у стабільному аспекті до Сатурна підкреслює важливість довіри, ритуалів та спільних обіцянок."
            ]
        case .health:
            return baseContext + [
                "Шостий дім вимагає дисципліни в повсякденних звичках, що сприяють нервовій стабільності та відпочинку."
            ]
        case .general:
            return baseContext
        }
    }

    nonisolated private func buildChartContext(from chart: NatalChart) -> [String] {
        var context: [String] = []

        // Sun position
        if let sun = chart.planets.first(where: { $0.name == .sun }) {
            context.append("Сонце у знаку \(sun.sign.rawValue), будинок \(sun.house)")
        }

        // Moon position
        if let moon = chart.planets.first(where: { $0.name == .moon }) {
            context.append("Місяць у знаку \(moon.sign.rawValue), будинок \(moon.house)")
        }

        // Ascendant
        let ascSign = ZodiacSign.from(degree: chart.ascendant)
        context.append("Асцендент у знаку \(ascSign.rawValue)")

        // Midheaven
        let mcSign = ZodiacSign.from(degree: chart.midheaven)
        context.append("МС (Середина неба) у знаку \(mcSign.rawValue)")

        // Major aspects (limited to first 3 for brevity)
        let majorAspects = chart.aspects.prefix(3)
        for aspect in majorAspects {
            context.append("\(aspect.planet1.rawValue) у аспекті \(aspect.type.rawValue) з \(aspect.planet2.rawValue)")
        }

        // Retrograde planets
        let retrogradePlanets = chart.planets.filter { $0.isRetrograde }
        if !retrogradePlanets.isEmpty {
            let planetNames = retrogradePlanets.map { $0.name.rawValue }.joined(separator: ", ")
            context.append("Ретроградні планети: \(planetNames)")
        }

        return context
    }
}

import Foundation

actor AstrologyKnowledgeProvider {

    func loadSnippets(for area: ReportArea, birthDetails: BirthDetails) async -> [String] {
        // TODO(T5.0.3): Replace stub with OpenAI vector store retrieval.
        // Future implementation will:
        // 1. Upload chunked rules to OpenAI Files + Vector Store (see plan P5.0).
        // 2. Query the hosted vector store for top-K matches (metadata filters).
        // 3. Return succinct Ukrainian summaries to feed the prompt.

        let baseContext = [
            "Сонце у водолієвій енергії підсилює оригінальність та бажання мислити нестандартно.",
            "Скорпіон на МС означає, що трансформації в професійній сфері приносять найпотужніший ріст.",
            "Гармонійний зв'язок Юпітера з Місяцем підтримує інтуїцію і дає відчуття удачі у ключові моменти."
        ]

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
}

import Foundation
import CoreLocation

struct AIPromptBuilder {

    struct Prompt {
        let system: String
        let user: String
    }

    func makePrompt(
        for area: ReportArea,
        birthDetails: BirthDetails,
        natalChart: NatalChart,
        knowledgeSnippets: [String]
    ) -> Prompt {
        let systemMessage = """
        Ти — професійний астролог з понад 20 роками досвіду. Твоя задача — писати теплі, практичні та мотиваційні інтерпретації натальних карт українською мовою. Відповіді мають бути без згадок про гороскопи «на кожен день» та без шаблонних фраз. Пиши чітко, сучасно, з повагою до особистого шляху людини.
        """

        let knowledgeSection: String = {
            guard knowledgeSnippets.isEmpty == false else {
                return "Релевантні уривки з бази знань не знайдені для цієї теми."
            }
            let formatted = knowledgeSnippets.prefix(6).enumerated().map { index, snippet in
                "\(index + 1). \(snippet)"
            }.joined(separator: "\n")
            return "НАЙДЕАКТИВНІШІ ПРАВИЛА З ВЕКТОРНОЇ БАЗИ ЗНАНЬ:\n\(formatted)"
        }()

        let userMessage = """
        СФОРМУЙ ВІДПОВІДЬ У ФОРМАТІ JSON БЕЗ ЖОДНОГО ДОДАТКОВОГО ТЕКСТУ. Використай наступну структуру:

        {
          "summary": "1-2 речення короткого підсумку українською.",
          "key_influences": ["4 марковані пункти з ключовими впливами"],
          "detailed_analysis": "Розгорнутий аналіз 4-5 абзаців українською, з посиланням на планети/аспекти/домівки.",
          "recommendations": ["3-4 практичні поради українською, починай з дієслова."]
        }

        Вихідні дані:
        • Ім'я/позначення: \(birthDetails.displayName)
        • Дата народження: \(birthDetails.formattedBirthDate)
        • Час народження: \(birthDetails.formattedBirthTime)
        • Локація: \(birthDetails.formattedLocation)
        • Координати: \(coordinateString(from: birthDetails))
        • Часовий пояс: \(birthDetails.timeZone.identifier)

        Життєва сфера для інтерпретації: \(area.displayName) — напиши аналіз саме для цієї сфери.

        Додатковий фокус для цієї сфери:
        \(focus(for: area))

        Контекст для натальної карти (реальні розрахунки, використовуй для точного аналізу):
        \(formatNatalChartData(natalChart))

        \(knowledgeSection)

        Вимоги:
        • Використовуй тільки українську мову.
        • Поверни лише валідний JSON без додаткових пояснень.
        • Тримайся заданої структури та довжини.
        • Підлаштуй змісти пунктів під сферу \(area.displayName.lowercased()).
        """

        return Prompt(system: systemMessage, user: userMessage)
    }

    private func coordinateString(from details: BirthDetails) -> String {
        guard let coordinate = details.coordinate else {
            return "невідомі"
        }
        let formattedLatitude = format(coordinate.latitude, positiveSuffix: "N", negativeSuffix: "S")
        let formattedLongitude = format(coordinate.longitude, positiveSuffix: "E", negativeSuffix: "W")
        return "\(formattedLatitude), \(formattedLongitude)"
    }

    private func format(_ value: Double, positiveSuffix: String, negativeSuffix: String) -> String {
        let suffix = value >= 0 ? positiveSuffix : negativeSuffix
        let absolute = abs(value)
        return String(format: "%.2f°%@", absolute, suffix)
    }

    private func formatNatalChartData(_ chart: NatalChart) -> String {
        var lines: [String] = []

        // Ascendant and Midheaven
        let ascSign = ZodiacSign.from(degree: chart.ascendant)
        let mcSign = ZodiacSign.from(degree: chart.midheaven)
        lines.append("Асцендент (ASC): \(format(degree: chart.ascendant)) у \(ascSign.rawValue)")
        lines.append("Середина неба (MC): \(format(degree: chart.midheaven)) у \(mcSign.rawValue)")

        // Planets
        lines.append("\nПланети:")
        for planet in chart.planets {
            let retro = planet.isRetrograde ? " (ретроградна)" : ""
            lines.append("- \(planet.name.rawValue): \(format(degree: planet.longitude)) у \(planet.sign.rawValue), \(planet.house) дім\(retro)")
        }

        // Houses
        lines.append("\nДоми (куспіди):")
        for house in chart.houses.sorted(by: { $0.number < $1.number }) {
            lines.append("- Дім \(house.number): \(format(degree: house.cusp)) у \(house.sign.rawValue)")
        }

        // Major Aspects
        if !chart.aspects.isEmpty {
            lines.append("\nОсновні аспекти (орб <\(String(format: "%.1f", chart.aspects.first?.orb ?? 0))°):")
            for aspect in chart.aspects.prefix(8) {
                lines.append("- \(aspect.planet1.rawValue) \(aspect.type.rawValue) \(aspect.planet2.rawValue) (орб: \(String(format: "%.2f", aspect.orb))°)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func format(degree: Double) -> String {
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let degrees = Int(normalized)
        let minutes = Int((normalized - Double(degrees)) * 60)
        return "\(degrees)°\(minutes)'"
    }

    private func focus(for area: ReportArea) -> String {
        switch area {
        case .finances:
            return "Розкажи про фінансові патерни, ставлення до ресурсів, силу другого та восьмого домів, потенціал накопичення, ризики та роль цінностей."
        case .career:
            return "Опиши покликання, стиль лідерства, суспільну роль, співвідношення роботи та покликання через десятий, шостий доми, МС, Сатурн, Марс."
        case .relationships:
            return "Розкрий потреби у близькості, стиль партнерства, уроки у стосунках, взаємодію Венери й Марса, а також теми сьомого та п'ятого домів."
        case .health:
            return "Сфокусуйся на енергії тіла, психоемоційній рівновазі, звичках, впливах шостого та дванадцятого домів, ролі сонця й місяця у тонусі."
        case .general:
            return "Зроби загальний портрет: архетипи, сили характеру, ключові цикли розвитку, взаємодію основних планет і життєвих домів."
        }
    }
}

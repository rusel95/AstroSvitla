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
        knowledgeSnippets: [String],
        languageCode: String,
        languageDisplayName: String,
        repositoryContext: String
    ) -> Prompt {
        let systemMessage = """
        You are a professional astrologer with 20+ years of experience. Always respond with warm, practical, motivating interpretations tailored to the user's natal chart. Avoid daily horoscope clichés.
        Always answer in language: \(languageDisplayName) (language code: \(languageCode)).
        Project repository context:
        \(repositoryContext)
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

        let vectorInstruction: String
        if knowledgeSnippets.isEmpty {
            vectorInstruction = "Vector knowledge snippets were NOT provided. Set knowledge_usage.vector_source_used to false and explain why in notes."
        } else {
            vectorInstruction = "Vector knowledge snippets WERE provided. Reference them naturally in the analysis and set knowledge_usage.vector_source_used to true with a short note."
        }

        let userMessage = """
        СФОРМУЙ ВІДПОВІДЬ У ФОРМАТІ JSON БЕЗ ЖОДНОГО ДОДАТКОВОГО ТЕКСТУ. Використай наступну структуру:

        {
          "summary": "1-2 речення короткого підсумку українською.",
          "key_influences": ["10 марковані пунктів з ключовими впливами (ОБОВ'ЯЗКОВО для всіх планет: Сонце, Місяць, Меркурій, Венера, Марс, Юпітер, Сатурн, Уран, Нептун, Плутон)"],
          "detailed_analysis": "Розгорнутий аналіз 6-8 абзаців українською, який ОБОВ'ЯЗКОВО містить:\n1. Пояснення Асцендента (знак і значення для особистості та підходу до життя)\n2. Пояснення Середини Неба/MC (знак і значення для кар'єри, репутації та життєвого напрямку)\n3. Роз'яснення про розташування кармічних вузлів (Північний вузол - куди йти, Південний вузол - що залишити позаду), їх дома та осі домів\n4. Роз'яснення про існуючі аспекти між кармічними вузлами та іншими планетами\n5. Роз'яснення про розміщення і значення Ліліт/Чорної Місяць (знак, дім, тіньові теми)\n6. Аналіз управителів домів (особливо Асцендента, 7-го та 10-го домів): де вони знаходяться і що це означає\n7. Детальний аналіз мінімум 20 найтісніших аспектів між планетами (з посиланням на конкретні кути та орби)",
          "recommendations": ["3-4 практичні поради українською, починай з дієслова."],
          "knowledge_usage": {
            "vector_source_used": true або false,
            "notes": "Коротке пояснення українською",
            "sources": [
              {
                "book_title": "Назва книги/джерела з векторної бази",
                "author": "Автор книги (якщо відомо)",
                "section": "Розділ/секція (якщо відомо)",
                "page_range": "Сторінки (якщо відомо)",
                "snippet": "Короткий уривок/цитата з джерела, що була використана",
                "relevance_score": 0.95
              }
            ]
          }
        }

        ВАЖЛИВО: Якщо ти використовуєш знання з векторної бази, обов'язково заповни масив "sources" з конкретними джерелами, які ти використав. Вкажи назву книги, автора, розділ і короткий уривок тексту, який був використаний для відповіді.

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

        \(vectorInstruction)
        Вимоги:
        • Поверни відповідь мовою \(languageDisplayName) (код \(languageCode)).
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

        // House Rulers (key ones)
        if !chart.houseRulers.isEmpty {
            lines.append("\nУправителі домів (ключові):")
            // Show Ascendant ruler (1st house), 7th house (relationships), 10th house (career)
            for houseNum in [1, 7, 10] {
                if let ruler = chart.houseRulers.first(where: { $0.houseNumber == houseNum }) {
                    lines.append("- Дім \(houseNum) управляється \(ruler.rulingPlanet.rawValue) (у \(ruler.rulerSign.rawValue), дім \(ruler.rulerHouse))")
                }
            }
        }

        // Major Aspects (expanded to 20)
        if !chart.aspects.isEmpty {
            lines.append("\nОсновні аспекти (20 найтісніших, відсортовано за орбом):")
            for (index, aspect) in chart.aspects.prefix(20).enumerated() {
                lines.append("- \(index + 1). \(aspect.planet1.rawValue) \(aspect.type.rawValue) \(aspect.planet2.rawValue) (орб: \(String(format: "%.2f", aspect.orb))°)")
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

import SwiftUI
import Combine

@MainActor
final class AppPreferences: ObservableObject {

    enum ThemeOption: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    enum LanguageOption: String, CaseIterable, Identifiable {
        case system
        case english
        case ukrainian

        var id: String { rawValue }

        var locale: Locale {
            switch self {
            case .system:
                return Locale.current
            case .english:
                return Locale(identifier: "en")
            case .ukrainian:
                return Locale(identifier: "uk")
            }
        }
    }

    enum OpenAIModel: String, CaseIterable, Identifiable {
        case gpt4oMini = "gpt-4o-mini"
        case gpt4o = "gpt-4o"
        case gpt4Turbo = "gpt-4-turbo"
        case gpt4 = "gpt-4"
        case gpt35Turbo = "gpt-3.5-turbo"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gpt4oMini:
                return "GPT-4o Mini (швидка, дешева)"
            case .gpt4o:
                return "GPT-4o (рекомендовано)"
            case .gpt4Turbo:
                return "GPT-4 Turbo (потужна)"
            case .gpt4:
                return "GPT-4 (класична)"
            case .gpt35Turbo:
                return "GPT-3.5 Turbo (базова)"
            }
        }

        var estimatedCostPer1000Tokens: Double {
            switch self {
            case .gpt4oMini:
                return 0.0007  // $0.15 per 1M input + $0.60 per 1M output ≈ $0.0007 per 1K average
            case .gpt4o:
                return 0.0075  // $2.50 per 1M input + $10 per 1M output ≈ $0.0075 per 1K average
            case .gpt4Turbo:
                return 0.015   // $10 per 1M input + $30 per 1M output ≈ $0.015 per 1K average
            case .gpt4:
                return 0.045   // $30 per 1M input + $60 per 1M output ≈ $0.045 per 1K average
            case .gpt35Turbo:
                return 0.002   // $0.50 per 1M input + $1.50 per 1M output ≈ $0.002 per 1K average
            }
        }

        var maxTokens: Int {
            switch self {
            case .gpt4oMini:
                return 16384
            case .gpt4o:
                return 16384
            case .gpt4Turbo:
                return 4096
            case .gpt4:
                return 8192
            case .gpt35Turbo:
                return 4096
            }
        }
    }

    @Published var theme: ThemeOption {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var language: LanguageOption {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
            setAppLanguage(selectedLanguageCode)
        }
    }

    @Published var selectedModel: OpenAIModel {
        didSet { UserDefaults.standard.set(selectedModel.rawValue, forKey: Keys.openAIModel) }
    }

    var selectedColorScheme: ColorScheme? { theme.colorScheme }
    var selectedLocale: Locale { language.locale }
    var selectedLanguageCode: String {
        switch language {
        case .system:
            if let code = Locale.current.language.languageCode?.identifier {
                return code
            }
            return Locale.current.languageCode ?? "uk"
        case .english:
            return "en"
        case .ukrainian:
            return "uk"
        }
    }

    var selectedLanguageDisplayName: String {
        switch language {
        case .system:
            return Locale.current.localizedString(forLanguageCode: selectedLanguageCode) ?? "System"
        case .english:
            return "English"
        case .ukrainian:
            return "Українська"
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.theme),
           let stored = ThemeOption(rawValue: raw) {
            theme = stored
        } else {
            theme = .system
        }

        if let raw = UserDefaults.standard.string(forKey: Keys.language),
           let stored = LanguageOption(rawValue: raw) {
            language = stored
        } else {
            language = .system
        }

        if let raw = UserDefaults.standard.string(forKey: Keys.openAIModel),
           let stored = OpenAIModel(rawValue: raw) {
            selectedModel = stored
        } else {
            selectedModel = .gpt4oMini  // Default to cheapest/fastest
        }
    }

    func resetAppearance() {
        theme = .system
        language = .system
    }
}

private enum Keys {
    static let theme = "app.preferences.theme"
    static let language = "app.preferences.language"
    static let openAIModel = "app.preferences.openai_model"
}

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

    @Published var theme: ThemeOption {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var language: LanguageOption {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    var selectedColorScheme: ColorScheme? { theme.colorScheme }
    var selectedLocale: Locale { language.locale }

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
    }

    func resetAppearance() {
        theme = .system
        language = .system
    }
}

private enum Keys {
    static let theme = "app.preferences.theme"
    static let language = "app.preferences.language"
}

import Foundation

/// Global reference to app preferences for localization
/// This is set by the app on launch and updated when language preference changes
private var appLanguageCode: String?

func setAppLanguage(_ languageCode: String) {
    appLanguageCode = languageCode
    // Update AppleLanguages to override system locale for NSLocalizedString
    UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
    UserDefaults.standard.synchronize()
}

func localized(_ key: String, _ args: CVarArg...) -> String {
    let bundle: Bundle
    let locale: Locale

    // Try to use the app's preferred language bundle
    if let languageCode = appLanguageCode,
       let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
       let langBundle = Bundle(path: path) {
        bundle = langBundle
        locale = Locale(identifier: languageCode)
    } else {
        bundle = .main
        locale = Locale.current
    }

    let format = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
    if args.isEmpty {
        return format
    } else {
        return String(format: format, locale: locale, arguments: args)
    }
}

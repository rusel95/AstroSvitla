import Foundation

/// Global reference to app preferences for localization
/// This is set by the app on launch
private var appLanguageCode: String?

func setAppLanguage(_ languageCode: String) {
    appLanguageCode = languageCode
}

func localized(_ key: String, _ args: CVarArg...) -> String {
    let bundle: Bundle

    // If app language is set, use that bundle; otherwise fall back to main bundle
    if let languageCode = appLanguageCode,
       let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
       let langBundle = Bundle(path: path) {
        bundle = langBundle
    } else {
        bundle = .main
    }

    let format = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
    if args.isEmpty {
        return format
    } else {
        let locale = appLanguageCode.map { Locale(identifier: $0) } ?? Locale.current
        return String(format: format, locale: locale, arguments: args)
    }
}

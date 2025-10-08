import Foundation

func localized(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: "Localizable", bundle: .main, value: key, comment: "")
    if args.isEmpty {
        return format
    } else {
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

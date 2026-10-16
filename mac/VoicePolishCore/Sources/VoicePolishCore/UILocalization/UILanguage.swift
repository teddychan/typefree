import Foundation

/// UI display language (fork addition). Upstream's UI is hard-coded Simplified Chinese; the fork keeps
/// those literals in code and translates them at display time (see `UILocalizer`).
/// Separate from `ChineseScript`, which only changes the script of dictated text.
public enum UILanguage: String, CaseIterable {
    /// Follow macOS: the first of the user's preferred languages we support, else English.
    case system
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"

    public static let userDefaultsKey = "TypefreeUILanguage"
    /// Posted (on the main thread) after `preference` changes.
    public static let didChangeNotification = Notification.Name("TypefreeUILanguageDidChange")

    /// Options for the picker, in display order. Language names are shown in their own language
    /// (and must not be table keys, or the hooks would translate them).
    public var pickerTitle: String {
        switch self {
        case .system: return "跟随 macOS".uiLocalized
        case .english: return "English (US)"
        case .traditionalChinese: return "繁體中文（台灣）"
        case .simplifiedChinese: return "简体中文（中国大陆）"
        }
    }

    public static var preference: UILanguage {
        get { UserDefaults.standard.string(forKey: userDefaultsKey).flatMap(UILanguage.init(rawValue:)) ?? .system }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultsKey)
            UILocalizer.reloadLanguage()
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    /// The language actually shown: `preference`, with `.system` resolved.
    public static var effective: UILanguage { UILocalizer.language }

    /// Best match from macOS's preferred-language list (e.g. "zh-Hant-TW", "en-US", "zh-HK"), else English.
    public static func resolve(preferredLanguages: [String]) -> UILanguage {
        for identifier in preferredLanguages {
            let id = identifier.lowercased()
            if id == "en" || id.hasPrefix("en-") || id.hasPrefix("en_") { return .english }
            guard id == "zh" || id.hasPrefix("zh-") || id.hasPrefix("zh_") else { continue }
            if id.contains("hant") || id.contains("-tw") || id.contains("-hk") || id.contains("-mo")
                || id.contains("_tw") || id.contains("_hk") || id.contains("_mo") {
                return .traditionalChinese
            }
            return .simplifiedChinese
        }
        return .english
    }
}

public extension String {
    /// This UI string in the current UI language (`self` is upstream's Simplified Chinese text).
    var uiLocalized: String { UILocalizer.localize(self) }
}

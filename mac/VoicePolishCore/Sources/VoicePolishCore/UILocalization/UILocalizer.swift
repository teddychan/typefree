import Foundation

/// Display-time translation of upstream's Simplified Chinese UI strings (fork addition).
///
/// Upstream literals stay untouched in code. Each one is a key in `UITranslationTable`
/// (`zh-Hans source → English, Traditional Chinese (Taiwan)`). Strings built with interpolation are keys
/// with `{}` placeholders (`"已识别 {} 个字"`); what fills a placeholder is translated too, so
/// `"识别失败：{}"` around a known error text comes out fully translated. Anything without an entry is
/// shown as-is (Simplified Chinese), so a missing entry never blanks the UI.
public enum UILocalizer {
    /// Resolved language (never `.system`).
    public private(set) static var language: UILanguage = resolvedPreference()

    /// Called once per distinct Chinese string that reached the screen untranslated (English / Traditional
    /// only). The app routes it to its debug log; `UILocalizationCoverageTests` catches most cases statically.
    public static var missHandler: ((String) -> Void)?

    public static func reloadLanguage() {
        lock.lock()
        language = resolvedPreference()
        cache.removeAll()
        lock.unlock()
    }

    public static func localize(_ text: String) -> String {
        let lang = language
        guard lang != .simplifiedChinese, containsHan(text) else { return text }
        lock.lock()
        defer { lock.unlock() }
        if let hit = cache[text] { return hit }
        let translated = translate(text, lang, depth: 0)
        let result = translated ?? text
        if cache.count > 4000 { cache.removeAll() }
        cache[text] = result
        if translated == nil, !reportedMisses.contains(text) {
            reportedMisses.insert(text)
            if let missHandler {
                DispatchQueue.main.async { missHandler(text) }
            }
        }
        return result
    }

    /// Translation of `text` in `lang`, or nil when the table has nothing for it. Exposed for tests.
    public static func translation(of text: String, in lang: UILanguage) -> String? {
        if lang == .simplifiedChinese { return text }
        lock.lock()
        defer { lock.unlock() }
        return translate(text, lang, depth: 0)
    }

    /// True when `key` (a source string, `{}` for interpolations) has a table entry.
    public static func hasEntry(_ key: String) -> Bool {
        table.exact[key] != nil || table.templates.contains { $0.key == key }
    }

    // MARK: - Internals

    private static let lock = NSRecursiveLock()
    private static var cache: [String: String] = [:]
    private static var reportedMisses: Set<String> = []
    static let table = UITranslationTable.load()

    private static func resolvedPreference() -> UILanguage {
        let pref = UILanguage.preference
        return pref == .system ? UILanguage.resolve(preferredLanguages: Locale.preferredLanguages) : pref
    }

    private static let decoration = CharacterSet.whitespacesAndNewlines
        .union(CharacterSet(charactersIn: "▾▴▸◂›‹→←↑↓↗↘▷◁✓✔✗✘⚡⚠·•…\u{FE0F}"))

    static func containsHan(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) || (0x3400...0x4DBF).contains($0.value) }
    }

    private static func translate(_ text: String, _ lang: UILanguage, depth: Int) -> String? {
        if let entry = table.exact[text] { return entry.value(lang) }
        // Already translated (a setter saw its own output again): leave it.
        if table.outputs(lang).contains(text) { return text }
        guard depth < 4 else { return nil }

        // Leading/trailing whitespace around a known string.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed != text, !trimmed.isEmpty, let inner = translate(trimmed, lang, depth: depth + 1) {
            return text.replacingOccurrences(of: trimmed, with: inner)
        }

        for template in table.templates {
            guard let captures = template.match(text) else { continue }
            let filled = captures.map { translate($0, lang, depth: depth + 1) ?? $0 }
            return template.fill(template.value(lang), with: filled)
        }

        // A known string with a symbol stuck on ("保存全部数据  ▾", "✓ 已保存").
        let core = text.trimmingCharacters(in: decoration)
        if core != text, !core.isEmpty, let inner = translate(core, lang, depth: depth + 1) {
            return text.replacingOccurrences(of: core, with: inner)
        }

        // Several known lines joined together.
        if text.contains("\n") {
            let lines = text.components(separatedBy: "\n")
            var changed = false
            let out = lines.map { line -> String in
                guard containsHan(line), let t = translate(line, lang, depth: depth + 1) else { return line }
                if t != line { changed = true }
                return t
            }
            if changed { return out.joined(separator: "\n") }
        }
        return nil
    }
}

/// Parsed form of the TSV sections in `UITranslations*.swift`.
struct UITranslationTable {
    struct Entry {
        let en: String
        let zhHant: String
        func value(_ lang: UILanguage) -> String {
            switch lang {
            case .english: return en
            case .traditionalChinese: return zhHant
            case .simplifiedChinese, .system: return ""
            }
        }
    }

    struct Template {
        let key: String
        let parts: [String]       // literal pieces around the `{}` placeholders
        let entry: Entry
        var literalLength: Int { parts.reduce(0) { $0 + $1.count } }

        func value(_ lang: UILanguage) -> String { entry.value(lang) }

        /// Captured placeholder values (each non-empty), or nil when `text` doesn't fit.
        func match(_ text: String) -> [String]? {
            guard text.hasPrefix(parts[0]) else { return nil }
            return matchRest(text[text.index(text.startIndex, offsetBy: parts[0].count)...], partIndex: 1)
        }

        private func matchRest(_ rest: Substring, partIndex: Int) -> [String]? {
            let part = parts[partIndex]
            if partIndex == parts.count - 1 {
                guard rest.hasSuffix(part), rest.count > part.count else { return nil }
                return [String(rest.dropLast(part.count))]
            }
            // Lazy: try each occurrence of the next literal piece, shortest capture first.
            guard !rest.isEmpty else { return nil }
            var searchStart = rest.index(after: rest.startIndex)
            while searchStart < rest.endIndex, let r = rest.range(of: part, range: searchStart..<rest.endIndex) {
                if let tail = matchRest(rest[r.upperBound...], partIndex: partIndex + 1) {
                    return [String(rest[rest.startIndex..<r.lowerBound])] + tail
                }
                searchStart = rest.index(after: r.lowerBound)
            }
            return nil
        }

        /// Puts `values` into `{}` (in order) or `{1}`, `{2}`… (explicit, 1-based) placeholders.
        func fill(_ pattern: String, with values: [String]) -> String {
            var out = pattern
            for (i, v) in values.enumerated() {
                out = out.replacingOccurrences(of: "{\(i + 1)}", with: v)
            }
            var next = 0
            while let r = out.range(of: "{}") {
                out.replaceSubrange(r, with: next < values.count ? values[next] : "")
                next += 1
            }
            return out
        }
    }

    private(set) var exact: [String: Entry] = [:]
    private(set) var templates: [Template] = []
    private var enOutputs: Set<String> = []
    private var hantOutputs: Set<String> = []
    /// Lines that didn't parse (wrong column count); `UILocalizationTests` asserts this is empty.
    private(set) var malformedLines: [String] = []
    /// Keys defined more than once; `UILocalizationTests` asserts this is empty.
    private(set) var duplicateKeys: [String] = []

    func outputs(_ lang: UILanguage) -> Set<String> {
        lang == .english ? enOutputs : hantOutputs
    }

    static func load() -> UITranslationTable {
        var t = UITranslationTable()
        for section in UITranslationTable.sections {
            for raw in section.split(separator: "\n", omittingEmptySubsequences: true) {
                let line = String(raw)
                if line.hasPrefix("#") || line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
                let cols = line.components(separatedBy: "\t")
                guard cols.count == 3, !cols[0].isEmpty, !cols[1].isEmpty, !cols[2].isEmpty else {
                    t.malformedLines.append(line)
                    continue
                }
                let key = unescape(cols[0])
                let entry = Entry(en: unescape(cols[1]), zhHant: unescape(cols[2]))
                if key.contains("{}") {
                    if t.templates.contains(where: { $0.key == key }) { t.duplicateKeys.append(key); continue }
                    t.templates.append(Template(key: key, parts: key.components(separatedBy: "{}"), entry: entry))
                } else {
                    if t.exact[key] != nil { t.duplicateKeys.append(key); continue }
                    t.exact[key] = entry
                    t.enOutputs.insert(entry.en)
                    t.hantOutputs.insert(entry.zhHant)
                }
            }
        }
        // Most specific template first, so "已识别 {} 个字" wins over "{} 个字".
        t.templates.sort { $0.literalLength > $1.literalLength }
        return t
    }

    /// TSV cells use `\n` for a line break and `\t` for a tab.
    static func unescape(_ s: String) -> String {
        guard s.contains("\\") else { return s }
        return s.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\t", with: "\t")
    }
}

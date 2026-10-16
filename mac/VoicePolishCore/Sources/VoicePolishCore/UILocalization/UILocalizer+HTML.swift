import Foundation

/// Translation of a bundled HTML page (the 3.0 "What's New" guide, `Resources/WhatsNewGuide.html`).
/// The page is translated as text before it is loaded, so text that its script builds or types out
/// letter by letter is covered too. Units: string literals inside `<script>` / `<style>`, and text
/// nodes and attribute values elsewhere. Each unit containing Chinese is a key in `UITranslationTable.guide`.
public extension UILocalizer {
    static func localizeHTML(_ html: String) -> String {
        let lang = language
        guard lang != .simplifiedChinese else { return html }
        var out = forEachTextUnit(in: html) { unit in
            table.exact["html:" + unit]?.value(lang) ?? translation(of: unit, in: lang)
        }
        out = out.replacingOccurrences(of: "<html lang=\"zh-CN\">",
                                       with: "<html lang=\"\(lang == .english ? "en" : "zh-Hant-TW")\">")
        return out
    }

    /// The Chinese text units of an HTML page, for coverage tests.
    static func htmlTextUnits(_ html: String) -> [String] {
        var units: [String] = []
        _ = forEachTextUnit(in: html) { units.append($0); return nil }
        return units
    }

    /// Calls `transform` for each unit containing Chinese (whitespace-trimmed) and splices in its result.
    private static func forEachTextUnit(in html: String, _ transform: (String) -> String?) -> String {
        let ns = html as NSString
        var out = ""
        var cursor = 0
        let codeBlocks = try! NSRegularExpression(pattern: "<(script|style)\\b[^>]*>(.*?)</\\1>",
                                                  options: [.dotMatchesLineSeparators, .caseInsensitive])
        for block in codeBlocks.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let body = block.range(at: 2)
            out += markupPart(ns.substring(with: NSRange(location: cursor, length: body.location - cursor)), transform)
            out += codePart(ns.substring(with: body), transform)
            cursor = body.location + body.length
        }
        out += markupPart(ns.substring(from: cursor), transform)
        return out
    }

    private static let stringLiteral = try! NSRegularExpression(pattern: #"'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)""#)
    private static let textNode = try! NSRegularExpression(pattern: #">([^<>]+)<"#)
    private static let attribute = try! NSRegularExpression(pattern: #"="([^"]*)""#)

    private static func codePart(_ code: String, _ transform: (String) -> String?) -> String {
        replaceGroups(in: code, regex: stringLiteral, groups: [1, 2], transform)
    }

    private static func markupPart(_ markup: String, _ transform: (String) -> String?) -> String {
        let withText = replaceGroups(in: markup, regex: textNode, groups: [1], transform)
        return replaceGroups(in: withText, regex: attribute, groups: [1], transform)
    }

    private static func replaceGroups(in text: String, regex: NSRegularExpression, groups: [Int],
                                      _ transform: (String) -> String?) -> String {
        let ns = text as NSString
        var out = ""
        var cursor = 0
        for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            guard let r = groups.map({ m.range(at: $0) }).first(where: { $0.location != NSNotFound }) else { continue }
            let raw = ns.substring(with: r)
            guard containsHan(raw) else { continue }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let translated = transform(trimmed), translated != trimmed else { continue }
            out += ns.substring(with: NSRange(location: cursor, length: r.location - cursor))
            out += raw.replacingOccurrences(of: trimmed, with: translated)
            cursor = r.location + r.length
        }
        out += ns.substring(from: cursor)
        return out
    }
}

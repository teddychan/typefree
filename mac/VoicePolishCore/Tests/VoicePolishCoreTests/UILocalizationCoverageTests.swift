import XCTest
@testable import VoicePolishCore

/// Every Chinese string literal in the app and core sources must either have a translation in
/// `UITranslations*.swift` or be listed in `UILocalizationIgnoreList` (prompts, logs, matching keywords).
/// After an upstream pull, run:
///
///     cd mac/VoicePolishCore && swift test --filter UILocalizationCoverageTests
///
/// The failure lists each new string with its file and line. `UI_L10N_DUMP=/path/out.tsv` also writes
/// them as table lines to fill in.
final class UILocalizationCoverageTests: XCTestCase {
    static let macRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    static func sourceFiles() -> [URL] {
        let dirs = [macRoot.appendingPathComponent("Sources"),
                    macRoot.appendingPathComponent("VoicePolishCore/Sources/VoicePolishCore")]
        var files: [URL] = []
        for dir in dirs {
            let items = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
            files += items.filter { $0.pathExtension == "swift" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
        return files.filter { !UILocalizationIgnoreList.files.contains($0.lastPathComponent) }
    }

    static func untranslatedLiterals() -> [UILocalizationSourceScanner.Literal] {
        var out: [UILocalizationSourceScanner.Literal] = []
        var seen: Set<String> = []
        for url in sourceFiles() {
            guard let source = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for lit in UILocalizationSourceScanner.scan(source: source, file: url.lastPathComponent) {
                if UILocalizer.hasEntry(lit.key) || UILocalizationIgnoreList.contains(lit.key) { continue }
                if seen.insert(lit.key).inserted { out.append(lit) }
            }
        }
        let guide = macRoot.appendingPathComponent("Resources/WhatsNewGuide.html")
        if let html = try? String(contentsOf: guide, encoding: .utf8) {
            for unit in UILocalizer.htmlTextUnits(html) where !UILocalizer.hasEntry(unit) && seen.insert(unit).inserted {
                out.append(.init(key: unit, file: "WhatsNewGuide.html", line: 0))
            }
        }
        return out
    }

    func testSourcesAreFound() {
        let names = Set(Self.sourceFiles().map(\.lastPathComponent))
        XCTAssertTrue(names.contains("SettingsWindowController.swift"), "app sources not found under \(Self.macRoot.path)")
        XCTAssertTrue(names.contains("CloudASRTranscriber.swift"))
    }

    func testEveryChineseUIStringHasATranslation() throws {
        let missing = Self.untranslatedLiterals()
        if let dump = ProcessInfo.processInfo.environment["UI_L10N_DUMP"] {
            let lines = missing.map { "\($0.key.replacingOccurrences(of: "\n", with: "\\n"))\t\t\t# \($0.file):\($0.line)" }
            try lines.map { $0 + "\n" }.joined().write(toFile: dump, atomically: true, encoding: .utf8)
        }
        let report = missing.prefix(80).map { "  \($0.file):\($0.line)  \($0.key.replacingOccurrences(of: "\n", with: "\\n"))" }
        XCTAssertTrue(missing.isEmpty, """
            \(missing.count) Chinese string(s) have no UI translation. Add each to UITranslations*.swift \
            (or UILocalizationIgnoreList if it is not UI text):
            \(report.joined(separator: "\n"))
            """)
    }

    /// Ignore-list entries that no longer appear in the sources are dead weight; keep the list honest.
    func testIgnoreListHasNoStaleEntries() {
        var all: Set<String> = []
        for url in Self.sourceFiles() {
            guard let source = try? String(contentsOf: url, encoding: .utf8) else { continue }
            all.formUnion(UILocalizationSourceScanner.scan(source: source, file: url.lastPathComponent).map(\.key))
        }
        let stale = UILocalizationIgnoreList.literals.subtracting(all)
        XCTAssertTrue(stale.isEmpty, "UILocalizationIgnoreList entries not in the sources any more: \(stale.sorted())")
    }
}

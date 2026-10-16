import XCTest
#if os(macOS)
import AppKit
#endif
@testable import VoicePolishCore

/// UI display language (fork addition): table integrity, language resolution, template matching, hooks.
final class UILocalizationTests: XCTestCase {
    private var savedPreference: String?

    override func setUp() {
        super.setUp()
        savedPreference = UserDefaults.standard.string(forKey: UILanguage.userDefaultsKey)
    }

    override func tearDown() {
        if let savedPreference {
            UserDefaults.standard.set(savedPreference, forKey: UILanguage.userDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: UILanguage.userDefaultsKey)
        }
        UILocalizer.reloadLanguage()
        super.tearDown()
    }

    // MARK: Table

    func testTableParsesCleanly() {
        let t = UILocalizer.table
        XCTAssertEqual(t.malformedLines, [], "lines need exactly 3 non-empty TAB-separated columns")
        XCTAssertEqual(t.duplicateKeys, [], "each source string may appear once")
        XCTAssertGreaterThan(t.exact.count + t.templates.count, 700)
    }

    func testTranslationsKeepEveryPlaceholder() {
        func count(_ s: String) -> Int {
            s.components(separatedBy: "{}").count - 1
                + (1...9).filter { s.contains("{\($0)}") }.count
        }
        for template in UILocalizer.table.templates {
            let n = template.parts.count - 1
            XCTAssertEqual(count(template.entry.en), n, "en: \(template.key)")
            XCTAssertEqual(count(template.entry.zhHant), n, "zh-Hant: \(template.key)")
        }
    }

    func testTraditionalUsesTaiwanVocabulary() {
        // Spot checks: Taiwan terms, not character-converted mainland ones
        let forbidden = ["设置", "設置", "軟件", "默認", "視頻", "信息", "網絡", "文件夾", "賬號", "帐号", "窗口", "屏幕", "鼠標", "內存"]
        for (key, entry) in UILocalizer.table.exact {
            for word in forbidden {
                XCTAssertFalse(entry.zhHant.contains(word), "zh-Hant of “\(key)” contains “\(word)”: \(entry.zhHant)")
            }
        }
    }

    // MARK: Language

    func testResolveFollowsPreferredLanguages() {
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["en-US"]), .english)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["zh-Hant-TW", "en-US"]), .traditionalChinese)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["zh-Hant-HK"]), .traditionalChinese)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["zh-HK"]), .traditionalChinese)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["zh-Hans-CN"]), .simplifiedChinese)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["zh-CN"]), .simplifiedChinese)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["ja-JP", "zh-Hant-TW"]), .traditionalChinese)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: ["ja-JP", "fr-FR"]), .english)
        XCTAssertEqual(UILanguage.resolve(preferredLanguages: []), .english)
    }

    func testPreferenceSwitchesTheLanguage() {
        UILanguage.preference = .english
        XCTAssertEqual(UILocalizer.language, .english)
        XCTAssertEqual("设置".uiLocalized, "Settings")
        UILanguage.preference = .traditionalChinese
        XCTAssertEqual("设置".uiLocalized, "設定")
        UILanguage.preference = .simplifiedChinese
        XCTAssertEqual("设置".uiLocalized, "设置")
    }

    func testPickerShowsLanguageNamesUntranslated() {
        for language in UILanguage.allCases where language != .system {
            XCTAssertFalse(UILocalizer.hasEntry(language.pickerTitle), "\(language.pickerTitle) must not be translated")
        }
    }

    // MARK: Matching

    func testUnknownTextIsLeftAlone() {
        UILanguage.preference = .english
        XCTAssertEqual("这句不在表里".uiLocalized, "这句不在表里")
        XCTAssertEqual("Hello".uiLocalized, "Hello")
    }

    func testTemplatesFillInAndTranslateTheirValues() {
        UILanguage.preference = .english
        // "{} 项需要处理" with a number
        XCTAssertEqual(UILocalizer.translation(of: "3 项需要处理", in: .english),
                       UILocalizer.table.templates.first { $0.key == "{} 项需要处理" }?.entry.en.replacingOccurrences(of: "{}", with: "3"))
        // A value that is itself a known string is translated too
        let wrapped = UILocalizer.translation(of: "重新润色失败：润色服务未返回数据", in: .english) ?? ""
        XCTAssertFalse(UILocalizer.containsHan(wrapped), wrapped)
    }

    func testTemplateMatcher() {
        let t = UITranslationTable.Template(key: "A{}B{}C", parts: ["A", "B", "C"],
                                            entry: .init(en: "{2}-{1}", zhHant: "{}{}"))
        XCTAssertEqual(t.match("AxBy C".replacingOccurrences(of: " ", with: "")), ["x", "y"])
        XCTAssertEqual(t.match("AxxBBByyC"), ["xx", "BByy"])
        XCTAssertNil(t.match("ABC"), "placeholders must not be empty")
        XCTAssertEqual(t.fill(t.entry.en, with: ["x", "y"]), "y-x")
        XCTAssertEqual(t.fill(t.entry.zhHant, with: ["x", "y"]), "xy")
    }

    func testJoinedLinesAreTranslatedLineByLine() {
        UILanguage.preference = .english
        let out = "设置\n关于".uiLocalized
        XCTAssertEqual(out, "Settings\nAbout")
    }

    func testSymbolsStuckOnAKnownStringAreKept() {
        UILanguage.preference = .english
        XCTAssertEqual("设置  ▾".uiLocalized, "Settings  ▾")
    }

    func testOnlyRealMissesAreReported() {
        var misses: [String] = []
        UILocalizer.missHandler = { misses.append($0) }
        defer { UILocalizer.missHandler = nil }
        UILanguage.preference = .traditionalChinese
        _ = "模型".uiLocalized          // same text in both scripts: a hit, not a miss
        _ = "完全没有的一句".uiLocalized
        let done = expectation(description: "reported on main")
        DispatchQueue.main.async { done.fulfill() }
        wait(for: [done], timeout: 1)
        XCTAssertEqual(misses, ["完全没有的一句"])
    }

    func testTranslatedTextIsStable() {
        UILanguage.preference = .traditionalChinese
        let once = "设置".uiLocalized
        XCTAssertEqual(once.uiLocalized, once)
    }

    func testGuidePageIsTranslatedWhole() throws {
        let url = UILocalizationCoverageTests.macRoot.appendingPathComponent("Resources/WhatsNewGuide.html")
        let html = try String(contentsOf: url, encoding: .utf8)
        UILanguage.preference = .english
        let en = UILocalizer.localizeHTML(html)
        XCTAssertTrue(en.contains("<html lang=\"en\">"))
        XCTAssertTrue(en.contains("<b>Hold the left mouse button</b>"))
        // Only the demo's spoken Chinese commands may remain
        let leftovers = UILocalizer.htmlTextUnits(en).filter { !$0.contains("用英文") && !$0.contains("用韩文") && !$0.contains("明天下午三点") && !$0.contains("谢谢你今天帮忙") }
        XCTAssertEqual(leftovers, [])
        UILanguage.preference = .simplifiedChinese
        XCTAssertEqual(UILocalizer.localizeHTML(html), html)
    }

    // MARK: AppKit hooks

    #if os(macOS)
    func testAppKitSettersTranslate() {
        AppKitUILocalization.install()
        UILanguage.preference = .english

        XCTAssertEqual(NSTextField(labelWithString: "设置").stringValue, "Settings")
        let field = NSTextField(string: "设置")   // editable: user input, untouched
        XCTAssertEqual(field.stringValue, "设置")
        field.placeholderString = "设置"
        XCTAssertEqual(field.placeholderString, "Settings")

        XCTAssertEqual(NSButton(title: "关于", target: nil, action: nil).title, "About")
        let attributed = NSButton()
        attributed.attributedTitle = NSAttributedString(string: "关于", attributes: [.foregroundColor: NSColor.red])
        XCTAssertEqual(attributed.attributedTitle.string, "About")
        XCTAssertEqual(attributed.attributedTitle.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor, .red)

        let menu = NSMenu()
        let item = NSMenuItem(title: "关于", action: nil, keyEquivalent: "")
        menu.addItem(item)
        menu.addItem(withTitle: "设置", action: nil, keyEquivalent: "")
        XCTAssertEqual(menu.items.map(\.title), ["About", "Settings"])

        UILanguage.preference = .traditionalChinese   // menus follow a language change in place
        XCTAssertEqual(menu.items.map(\.title), ["關於", "設定"])

        let main = NSMenu()
        let editItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        main.addItem(editItem)
        editItem.submenu = NSMenu(title: "编辑")   // the menu bar shows the submenu's title
        XCTAssertEqual(editItem.submenu?.title, "編輯")

        let view = NSView()
        view.toolTip = "关于"
        XCTAssertEqual(view.toolTip, "關於")
    }

    func testChineseDateFormatsFollowTheLanguage() {
        AppKitUILocalization.install()
        let date = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 10, day: 16, hour: 9, minute: 5).date!
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月d日 HH:mm"
        UILanguage.preference = .english
        XCTAssertEqual(df.string(from: date), "Oct 16, 09:05")
        UILanguage.preference = .simplifiedChinese
        XCTAssertEqual(df.string(from: date), "10月16日 09:05")
        df.dateFormat = "yyyy-MM-dd"   // no Chinese: never touched
        UILanguage.preference = .english
        XCTAssertEqual(df.string(from: date), "2026-10-16")
    }
    #endif
}

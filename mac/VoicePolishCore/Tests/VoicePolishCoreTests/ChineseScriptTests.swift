import XCTest
@testable import VoicePolishCore

/// 中文输出字形：默认不转；简体 / 繁體逐字转换，英文数字标点不动。
final class ChineseScriptTests: XCTestCase {
    func testDefaultIsOriginal() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let config = VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore())
        XCTAssertEqual(ChineseScript.current(config: config), .original)
        config.save(value: "hant", forKey: ChineseScript.configKey)
        XCTAssertEqual(ChineseScript.current(config: config), .traditional)
        config.save(value: "garbage", forKey: ChineseScript.configKey)
        XCTAssertEqual(ChineseScript.current(config: config), .original)
    }

    func testOriginalLeavesTextAlone() {
        let mixed = "我们今天去公園"
        XCTAssertEqual(ChineseScript.original.apply(to: mixed), mixed)
    }

    func testTraditional() {
        XCTAssertEqual(ChineseScript.traditional.apply(to: "我们今天去公园，发布了 iPhone 17。"),
                       "我們今天去公園，發佈了 iPhone 17。")
    }

    func testSimplified() {
        XCTAssertEqual(ChineseScript.simplified.apply(to: "這個應用程式很好用，OK！"),
                       "这个应用程式很好用，OK！")
    }

    func testNonChineseUnchanged() {
        let english = "Hello, world 123."
        XCTAssertEqual(ChineseScript.traditional.apply(to: english), english)
        XCTAssertEqual(ChineseScript.simplified.apply(to: english), english)
    }
}

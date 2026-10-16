#if os(macOS)
import XCTest
@testable import VoicePolishCore

/// 本地 Qwen3-ASR：命令行参数、安装判定、端口、与识别版本的对应。
/// 真跑一遍（装依赖 + 加载 4.7 GB 模型 + 转写）的端到端测试默认跳过：LOCAL_ASR_E2E=1 swift test --filter LocalASRServerTests
final class LocalASRServerTests: XCTestCase {
    typealias T = CloudASRTranscriber

    func testLocalVersionMapping() {
        XCTAssertEqual(T.ASRProvider.local.defaultVersion, .local)
        XCTAssertEqual(T.ASRVersion.local.provider, .local)
        XCTAssertEqual(T.ASRVersion(rawValue: "local-qwen3-asr"), .local)
        XCTAssertEqual(T.ASRVersion.local.modelIdentifier, "Qwen/Qwen3-ASR-1.7B")
        XCTAssertTrue(T.ASRVersion.local.isSync)
        XCTAssertNil(T.ASRVersion.local.nextForFallback)
    }

    /// 默认关：选了本地模型也不算配好，提示去打开开关（而不是「填 API Key」）；打开后不用填别的
    func testLocalNeedsOnlyTheEnableSwitch() throws {
        try XCTSkipUnless(T.LLMASR.localSupported, "需要 Apple 芯片")
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let config = VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore())
        config.save(value: T.ASRVersion.local.rawValue, forKey: "bigasr_version")
        let t = T(config: config)
        XCTAssertFalse(LocalASRServer.isEnabled(config: config), "默认关")
        XCTAssertFalse(t.isConfigured(version: .local))
        XCTAssertEqual(t.ownKeyIssue(), .localModelDisabled)
        XCTAssertTrue(T.hint(for: .localModelDisabled).contains("启用本地模型"))

        config.save(bool: true, forKey: LocalASRServer.enabledConfigKey)
        XCTAssertTrue(t.isConfigured(version: .local))
        XCTAssertNil(t.ownKeyIssue())
    }

    /// 没启用：不拉起服务（不下载、不加载），如实提示
    func testDisabledLocalDoesNotStartServer() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let done = expectation(description: "done")
        var out: Result<String, Error>?
        T(config: VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore()))
            .transcribeLocal(samples: [Float](repeating: 0, count: 16000), sampleRate: 16000, enabled: false, budgetSeconds: 5) {
                out = $0; done.fulfill()
            }
        wait(for: [done], timeout: 2)
        guard case .failure(let e)? = out, case T.TranscriptionError.serverFailed(let m)? = e as? T.TranscriptionError else {
            return XCTFail("\(String(describing: out))")
        }
        XCTAssertTrue(m.contains("启用本地模型"), m)
        XCTAssertEqual(LocalASRServer.shared.state, .stopped)
    }

    func testServerArgumentsBindLocalhostWithKey() {
        let args = LocalASRServer.serverArguments(port: 51234, token: "tok")
        XCTAssertEqual(args.first, "serve")
        func value(_ flag: String) -> String? { args.firstIndex(of: flag).map { args[$0 + 1] } }
        XCTAssertEqual(value("--host"), "127.0.0.1", "只听本机，别暴露到局域网")
        XCTAssertEqual(value("--port"), "51234")
        XCTAssertEqual(value("--model"), "Qwen/Qwen3-ASR-1.7B")
        XCTAssertEqual(value("--api-key"), "tok")
        XCTAssertGreaterThan(Int(value("--rate-limit") ?? "0") ?? 0, 60)
    }

    func testInstallCommandsUsePinnedPackageInPrivateVenv() {
        let paths = LocalASRServer.Paths(base: URL(fileURLWithPath: "/tmp/x/LocalASR"))
        let cmds = LocalASRServer.installCommands(paths: paths)
        XCTAssertEqual(cmds.count, 2)
        XCTAssertEqual(cmds[0], ["venv", "--python", "3.12", "--clear", "/tmp/x/LocalASR/venv"])
        XCTAssertEqual(cmds[1], ["pip", "install", "--python", "/tmp/x/LocalASR/venv/bin/python", "mlx-qwen3-asr[serve]==0.4.4"])
    }

    func testFreeLocalPortIsUsable() throws {
        let port = try XCTUnwrap(LocalASRServer.freeLocalPort())
        XCTAssertTrue((1024...65535).contains(port))
    }

    /// 太短的片段（< 0.1 秒）服务端会 500（STFT 不够长）：直接当「没听出话」，也不该去拉起服务
    func testTooShortAudioIsNoSpeechWithoutStartingServer() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let done = expectation(description: "done")
        var out: Result<String, Error>?
        T(config: VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore()))
            .transcribeLocal(samples: [Float](repeating: 0, count: 186), sampleRate: 16000, enabled: true, budgetSeconds: 5) {
                out = $0; done.fulfill()
            }
        wait(for: [done], timeout: 2)
        guard case .failure(let e)? = out, case T.TranscriptionError.noSpeech? = e as? T.TranscriptionError else {
            return XCTFail("\(String(describing: out))")
        }
        XCTAssertEqual(LocalASRServer.shared.state, .stopped)
    }

    func testNotReadyMessageMentionsDownloadSize() {
        // 单例刚建好、没启动：给的是「正在启动」类提示，不是空串
        XCTAssertFalse(LocalASRServer.shared.notReadyMessage.isEmpty)
    }

    // MARK: - 端到端（默认跳过）

    func testEndToEndInstallStartTranscribeStop() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["LOCAL_ASR_E2E"] == "1", "设 LOCAL_ASR_E2E=1 才跑")
        try XCTSkipUnless(T.LLMASR.localSupported, "需要 Apple 芯片")
        let server = LocalASRServer.shared
        server.debugLog = { print($0) }
        server.start()
        defer { server.stop() }

        // 首次要装依赖 + 下模型，给足 30 分钟
        let deadline = Date().addingTimeInterval(1800)
        while Date() < deadline {
            if case .ready = server.state { break }
            if case .failed(let reason) = server.state { return XCTFail(reason) }
            Thread.sleep(forTimeInterval: 1)
        }
        guard case .ready = server.state else { return XCTFail("没在时限内就绪：\(server.state)") }

        // 用系统 TTS 生成一句中文（Meijia 是 macOS 自带的国语语音），转成 16 kHz 单声道
        let samples: [Float]
        do { samples = try Self.speechSamples("今天天氣很好，我們去公園散步。") } catch {
            return XCTFail("生成测试语音失败：\(error)")
        }
        print("e2e: \(samples.count) samples (\(Double(samples.count) / 16000)s)")
        let done = expectation(description: "transcribe")
        var out: Result<String, Error> = .failure(T.TranscriptionError.noData)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let config = VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore())
        config.save(bool: true, forKey: LocalASRServer.enabledConfigKey)
        T(config: config).transcribe(samples: samples, sampleRate: 16000, version: .local) { out = $0; done.fulfill() }
        wait(for: [done], timeout: 120)
        if case .failure(let error) = out { return XCTFail("识别失败：\(error)") }
        let text = try out.get()
        print("local transcript: \(text)")
        XCTAssertTrue(["天气", "天氣", "公园", "公園"].contains { text.contains($0) }, text)
    }

    private static func speechSamples(_ sentence: String) throws -> [Float] {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let aiff = dir.appendingPathComponent("s.aiff"), wav = dir.appendingPathComponent("s.wav")
        try run("/usr/bin/say", ["-v", "Meijia", "-o", aiff.path, sentence])
        try run("/usr/bin/afconvert", ["-f", "WAVE", "-d", "LEI16@16000", "-c", "1", aiff.path, wav.path])
        let data = try Data(contentsOf: wav)
        // 跳过 WAV 头：找 "data" 块
        guard let r = data.range(of: Data("data".utf8)) else { throw NSError(domain: "wav", code: 1) }
        let pcm = data[(r.upperBound + 4)...]
        return stride(from: pcm.startIndex, to: pcm.endIndex - 1, by: 2).map {
            Float(Int16(bitPattern: UInt16(pcm[$0]) | UInt16(pcm[$0 + 1]) << 8)) / 32768
        }
    }

    private static func run(_ tool: String, _ args: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw NSError(domain: tool, code: Int(p.terminationStatus)) }
    }
}
#endif

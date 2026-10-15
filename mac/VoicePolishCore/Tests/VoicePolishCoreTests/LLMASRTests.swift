import XCTest
@testable import VoicePolishCore

/// OpenAI / Gemini / 自定义网关的语音识别：配置读取、请求形状（拦截 HTTP 检查）、响应解析、错误分类。
final class LLMASRTests: XCTestCase {
    typealias T = CloudASRTranscriber
    typealias LLMASR = CloudASRTranscriber.LLMASR

    private var dir: URL!
    private var config: VoicePolishConfig!

    override func setUp() {
        super.setUp()
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        config = VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore())
        URLProtocol.registerClass(StubProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(StubProtocol.self)
        StubProtocol.reset()
        try? FileManager.default.removeItem(at: dir)
        super.tearDown()
    }

    // MARK: - 版本 / 服务商对应

    func testNewProvidersMapToSyncVersions() {
        for (provider, raw) in [(T.ASRProvider.openai, "openai"), (.gemini, "gemini"), (.custom, "custom")] {
            let v = provider.defaultVersion
            XCTAssertEqual(v.rawValue, raw)
            XCTAssertEqual(v.provider, provider)
            XCTAssertTrue(v.isSync)
            XCTAssertNil(v.nextForFallback)
            XCTAssertEqual(T.ASRVersion(rawValue: raw), v)
        }
        XCTAssertEqual(T.ASRProvider.volcano.defaultVersion, .turbo)
        XCTAssertEqual(T.ASRProvider.bailian.defaultVersion, .bailian)
    }

    func testCustomASRKeyIsKeychainSecret() {
        XCTAssertTrue(VoicePolishConfig.secretKeys.contains(LLMASR.customKeyKey))
    }

    // MARK: - 配置

    func testOpenAIConfiguredWithSharedKeyAndDefaultModel() {
        let t = T(config: config)
        XCTAssertFalse(t.isConfigured(version: .openai))
        config.save(value: "sk-test", forKey: LLMASR.openAIKeyKey)
        XCTAssertTrue(t.isConfigured(version: .openai))
        let s = T.llmASRSettings(for: .openai, config: config)
        XCTAssertEqual(s?.model, "gpt-transcribe")
        XCTAssertEqual(s?.url.absoluteString, "https://api.openai.com/v1/audio/transcriptions")
        config.save(value: " whisper-1 ", forKey: LLMASR.openAIModelKey)
        XCTAssertEqual(T.llmASRSettings(for: .openai, config: config)?.model, "whisper-1")
    }

    func testGeminiConfigured() {
        let t = T(config: config)
        XCTAssertFalse(t.isConfigured(version: .gemini))
        config.save(value: "g-key", forKey: LLMASR.geminiKeyKey)
        XCTAssertEqual(T.llmASRSettings(for: .gemini, config: config)?.model, "gemini-3.8-flash")
    }

    func testCustomNeedsURLAndModelButNotKey() {
        let t = T(config: config)
        config.save(value: "https://gw.example.com/v1", forKey: LLMASR.customBaseURLKey)
        XCTAssertFalse(t.isConfigured(version: .custom), "没填模型")
        config.save(value: "gpt-transcribe", forKey: LLMASR.customModelKey)
        XCTAssertTrue(t.isConfigured(version: .custom), "Key 可空")
        XCTAssertEqual(T.llmASRSettings(for: .custom, config: config)?.url.absoluteString, "https://gw.example.com/v1/audio/transcriptions")
        config.save(value: "gw.example.com/v1", forKey: LLMASR.customBaseURLKey)
        XCTAssertFalse(t.isConfigured(version: .custom), "没写 https://")
    }

    func testCustomEndpointKeepsFullPath() {
        XCTAssertEqual(LLMASR.customEndpoint(base: "https://gw/v1/audio/transcriptions/")?.absoluteString,
                       "https://gw/v1/audio/transcriptions")
    }

    // MARK: - 结果 / 错误

    func testSpeechResultEmptyMeansNoSpeech() {
        if case .failure(let e) = T.speechResult("  \n"), case T.TranscriptionError.noSpeech? = e as? T.TranscriptionError {} else {
            XCTFail("空结果应算无语音")
        }
        XCTAssertEqual(try? T.speechResult(" 你好 ").get(), "你好")
    }

    func testHTTPErrorClassification() {
        let auth = LLMASR.classifyHTTPError(status: 401, data: Data(#"{"error":{"message":"Incorrect API key provided: x","code":"invalid_api_key"}}"#.utf8), providerName: "X")
        guard case .serverFailed(let m) = auth else { return XCTFail("\(auth)") }
        XCTAssertEqual(m, "API Key 无效，请检查是否复制完整（invalid_api_key）")
        guard case .serverBusy = LLMASR.classifyHTTPError(status: 429, data: nil, providerName: "X") else { return XCTFail() }
        guard case .serverBusy = LLMASR.classifyHTTPError(status: 503, data: nil, providerName: "X") else { return XCTFail() }
        guard case .serverFailed(let plain) = LLMASR.classifyHTTPError(status: 404, data: Data("not json".utf8), providerName: "X") else { return XCTFail() }
        XCTAssertEqual(plain, "X 识别失败（HTTP 404）")
    }

    // MARK: - 请求形状（拦截 HTTP）

    func testOpenAIStyleSendsMultipartAndParsesText() throws {
        StubProtocol.respond(status: 200, json: #"{"text":"你好世界"}"#)
        let settings = T.LLMASRSettings(url: URL(string: "https://gw.example.com/v1/audio/transcriptions")!, apiKey: "k1", model: "m1")
        let result = run { T(config: config).transcribeOpenAIStyle(audioData: Data("AUDIO".utf8), format: "m4a",
                                                                   settings: settings, budgetSeconds: 5, completion: $0) }
        XCTAssertEqual(try result.get(), "你好世界")

        let req = try XCTUnwrap(StubProtocol.lastRequest)
        XCTAssertEqual(req.url?.absoluteString, "https://gw.example.com/v1/audio/transcriptions")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer k1")
        let contentType = try XCTUnwrap(req.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))
        let body = String(decoding: StubProtocol.lastBody, as: UTF8.self)
        XCTAssertTrue(body.contains("name=\"model\"\r\n\r\nm1\r\n"))
        XCTAssertTrue(body.contains("name=\"file\"; filename=\"audio.m4a\"\r\nContent-Type: audio/mp4\r\n\r\nAUDIO\r\n"))
        XCTAssertTrue(body.hasSuffix("--\r\n"))
    }

    func testOpenAIStyleWithoutKeySendsNoAuthHeader() throws {
        StubProtocol.respond(status: 200, json: #"{"text":""}"#)
        let settings = T.LLMASRSettings(url: URL(string: "https://gw.example.com/v1/audio/transcriptions")!, apiKey: "", model: "m")
        let result = run { T(config: config).transcribeOpenAIStyle(audioData: Data([1]), format: "wav",
                                                                   settings: settings, budgetSeconds: 5, completion: $0) }
        XCTAssertNil(StubProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization"))
        guard case .failure(let e) = result, case T.TranscriptionError.noSpeech? = e as? T.TranscriptionError else {
            return XCTFail("空 text 应算无语音（测试连接据此判通）")
        }
    }

    func testGeminiSendsInputAudioAndParsesChoices() throws {
        StubProtocol.respond(status: 200, json: #"{"choices":[{"message":{"content":"转写结果"}}]}"#)
        let settings = T.LLMASRSettings(url: LLMASR.geminiURL, apiKey: "g1", model: "gemini-x")
        let result = run { T(config: config).transcribeGemini(wavData: Data("WAV".utf8), settings: settings,
                                                              budgetSeconds: 5, completion: $0) }
        XCTAssertEqual(try result.get(), "转写结果")

        XCTAssertEqual(StubProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer g1")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: StubProtocol.lastBody) as? [String: Any])
        XCTAssertEqual(json["model"] as? String, "gemini-x")
        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.first?["role"] as? String, "system")
        let parts = try XCTUnwrap(messages.last?["content"] as? [[String: Any]])
        let audio = try XCTUnwrap(parts.first { $0["type"] as? String == "input_audio" }?["input_audio"] as? [String: Any])
        XCTAssertEqual(audio["format"] as? String, "wav")
        XCTAssertEqual(audio["data"] as? String, Data("WAV".utf8).base64EncodedString())
    }

    func testGeminiErrorArrayIsReadable() {
        StubProtocol.respond(status: 400, json: #"[{"error":{"code":400,"message":"Please pass a valid API key","status":"INVALID_ARGUMENT"}}]"#)
        let settings = T.LLMASRSettings(url: LLMASR.geminiURL, apiKey: "bad", model: "m")
        let result = run { T(config: config).transcribeGemini(wavData: Data([1]), settings: settings, budgetSeconds: 5, completion: $0) }
        guard case .failure(let e) = result, case T.TranscriptionError.serverFailed(let m)? = e as? T.TranscriptionError else {
            return XCTFail("\(result)")
        }
        XCTAssertEqual(m, "API Key 无效，请检查是否复制完整")
    }

    // MARK: - helpers

    private func run(_ body: (@escaping (Result<String, Error>) -> Void) -> Void) -> Result<String, Error> {
        let done = expectation(description: "completion")
        var out: Result<String, Error> = .failure(T.TranscriptionError.noData)
        body { out = $0; done.fulfill() }
        wait(for: [done], timeout: 5)
        return out
    }
}

/// 拦截 URLSession.shared 的请求：记下请求与请求体，回固定响应。
private final class StubProtocol: URLProtocol {
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody = Data()
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var payload = Data()

    static func respond(status: Int, json: String) { self.status = status; payload = Data(json.utf8) }
    static func reset() { lastRequest = nil; lastBody = Data(); status = 200; payload = Data() }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody ?? Self.read(request.httpBodyStream)
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.payload)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream?) -> Data {
        guard let stream else { return Data() }
        stream.open(); defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let n = stream.read(&buffer, maxLength: buffer.count)
            if n <= 0 { break }
            data.append(buffer, count: n)
        }
        return data
    }
}

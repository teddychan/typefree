import XCTest
@testable import VoicePolishCore

/// 自定义服务商：地址拼接、鉴权头、是否已配置。
final class CustomProviderTests: XCTestCase {
    typealias Custom = AIPolisher.Custom

    func testEndpointAppendsPathToBaseURL() {
        XCTAssertEqual(Custom.endpoint(base: "https://codex-proxy.aftership.me/v1", anthropic: false)?.absoluteString,
                       "https://codex-proxy.aftership.me/v1/chat/completions")
        XCTAssertEqual(Custom.endpoint(base: "https://codex-proxy.aftership.me/v1", anthropic: true)?.absoluteString,
                       "https://codex-proxy.aftership.me/v1/messages")
        // 尾斜杠、首尾空格
        XCTAssertEqual(Custom.endpoint(base: "  https://host/v1/ ", anthropic: false)?.absoluteString,
                       "https://host/v1/chat/completions")
        // 本地网关可用 http
        XCTAssertEqual(Custom.endpoint(base: "http://localhost:4000/v1", anthropic: false)?.absoluteString,
                       "http://localhost:4000/v1/chat/completions")
    }

    func testEndpointKeepsFullPath() {
        XCTAssertEqual(Custom.endpoint(base: "https://host/v1/chat/completions", anthropic: false)?.absoluteString,
                       "https://host/v1/chat/completions")
        XCTAssertEqual(Custom.endpoint(base: "https://host/v1/messages/", anthropic: true)?.absoluteString,
                       "https://host/v1/messages")
    }

    func testEndpointRejectsInvalidInput() {
        XCTAssertNil(Custom.endpoint(base: "", anthropic: false))
        XCTAssertNil(Custom.endpoint(base: "codex-proxy.aftership.me/v1", anthropic: false))   // 没写 https://
        XCTAssertNil(Custom.endpoint(base: "ftp://host/v1", anthropic: false))
    }

    func testIsConfiguredNeedsURLAndModelButNotKey() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let config = VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore())

        XCTAssertFalse(Custom.isConfigured(config: config))
        config.save(value: "https://codex-proxy.aftership.me/v1", forKey: Custom.baseURLKey)
        XCTAssertFalse(Custom.isConfigured(config: config), "没填模型")
        config.save(value: "gpt-6-luna", forKey: Custom.modelKey)
        XCTAssertTrue(Custom.isConfigured(config: config), "Key 可空")
        config.save(value: "not a url", forKey: Custom.baseURLKey)
        XCTAssertFalse(Custom.isConfigured(config: config))
    }

    /// 2026-10-16 不带 Key 打 codex-proxy.aftership.me 抓回的原文（HTTP 401，错误包在 meta 里）
    func testGatewayMetaErrorIsReadable() {
        let json: [String: Any] = ["meta": ["type": "Unauthorized", "errors": [], "code": 401, "source": "gateway",
                                            "message": "No API key found in request"], "data": [:]]
        XCTAssertEqual(AIPolisher.extractAPIErrorMessage(from: json), "API Key 无效，请检查是否复制完整")
        // 认不出的 meta 错误：保留原话
        XCTAssertEqual(AIPolisher.extractAPIErrorMessage(from: ["meta": ["type": "BadRequest", "message": "model not found"]]),
                       "model not found")
    }

    func testCustomAPIKeyIsKeychainSecret() {
        XCTAssertTrue(VoicePolishConfig.secretKeys.contains(Custom.apiKeyKey))
    }

    private func headers(provider: String, key: String) -> [String: String] {
        var request = URLRequest(url: URL(string: "https://host/v1")!)
        AIPolisher.authorize(&request, provider: provider, apiKey: key)
        return request.allHTTPHeaderFields ?? [:]
    }

    func testAuthHeaders() {
        // OpenAI 格式自定义网关：Bearer
        XCTAssertEqual(headers(provider: "custom", key: "k"), ["Authorization": "Bearer k"])
        // Anthropic 格式自定义网关：两种都带
        XCTAssertEqual(headers(provider: "custom-anthropic", key: "k"),
                       ["Authorization": "Bearer k", "x-api-key": "k", "anthropic-version": "2023-06-01"])
        // 没填 Key：不带鉴权头（Anthropic 格式仍要版本头）
        XCTAssertEqual(headers(provider: "custom", key: ""), [:])
        XCTAssertEqual(headers(provider: "custom-anthropic", key: ""), ["anthropic-version": "2023-06-01"])
        // 官方 Claude 不变：只用 x-api-key
        XCTAssertEqual(headers(provider: "claude", key: "k"), ["x-api-key": "k", "anthropic-version": "2023-06-01"])
        // 其他服务商不变：Bearer
        XCTAssertEqual(headers(provider: "openai", key: "k"), ["Authorization": "Bearer k"])
    }
}

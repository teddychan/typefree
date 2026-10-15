import XCTest
@testable import VoicePolishCore

/// 自带 Key 的 OpenAI / Gemini / Claude：请求体、响应解析、错误翻译、模型回落。
final class BYOKProviderTests: XCTestCase {

    func testProviderLookup() {
        XCTAssertEqual(AIPolisher.byokProvider("openai")?.keyConfigKey, "openai_api_key")
        XCTAssertEqual(AIPolisher.byokProvider("gemini")?.url.host, "generativelanguage.googleapis.com")
        XCTAssertEqual(AIPolisher.byokProvider("claude")?.url.absoluteString, "https://api.anthropic.com/v1/messages")
        XCTAssertNil(AIPolisher.byokProvider("qwen"))
        XCTAssertNil(AIPolisher.byokProvider(nil))
    }

    func testAPIKeysAreKeychainSecrets() {
        for p in AIPolisher.byokProviders {
            XCTAssertTrue(VoicePolishConfig.secretKeys.contains(p.keyConfigKey), p.keyConfigKey)
        }
    }

    func testConfiguredModelFallsBackToDefault() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let config = VoicePolishConfig(configDir: dir, secrets: InMemorySecretStore())
        let openai = try XCTUnwrap(AIPolisher.byokProvider("openai"))

        XCTAssertEqual(AIPolisher.configuredModel(for: openai, config: config), openai.defaultModel)
        config.save(value: "   ", forKey: openai.modelConfigKey)
        XCTAssertEqual(AIPolisher.configuredModel(for: openai, config: config), openai.defaultModel)
        config.save(value: " gpt-6.1-sol ", forKey: openai.modelConfigKey)
        XCTAssertEqual(AIPolisher.configuredModel(for: openai, config: config), "gpt-6.1-sol")
    }

    func testAnthropicBodyHoistsSystemPrompt() {
        let body = AIPolisher.anthropicBody(model: "claude-haiku-5-5", messages: [
            ["role": "system", "content": "be terse"],
            ["role": "user", "content": "hi"],
            ["role": "assistant", "content": "hello"],
            ["role": "user", "content": "again"],
        ], maxTokens: 2000, stream: true)

        XCTAssertEqual(body["model"] as? String, "claude-haiku-5-5")
        XCTAssertEqual(body["max_tokens"] as? Int, 2000)
        XCTAssertEqual(body["system"] as? String, "be terse")
        XCTAssertEqual(body["stream"] as? Bool, true)
        let roles = (body["messages"] as? [[String: Any]])?.compactMap { $0["role"] as? String }
        XCTAssertEqual(roles, ["user", "assistant", "user"])
    }

    func testAnthropicBodyOmitsEmptySystemAndStream() {
        let body = AIPolisher.anthropicBody(model: "m", messages: [["role": "user", "content": "hi"]],
                                            maxTokens: 10, stream: false)
        XCTAssertNil(body["system"])
        XCTAssertNil(body["stream"])
    }

    func testParseCompletionOpenAIShape() {
        let parsed = AIPolisher.parseCompletion([
            "choices": [["message": ["content": "  你好 \n"]]],
            "usage": ["prompt_tokens": 12, "completion_tokens": 3],
        ])
        XCTAssertEqual(parsed?.0, "你好")
        XCTAssertEqual(parsed?.1, 12)
        XCTAssertEqual(parsed?.2, 3)
    }

    func testParseCompletionAnthropicShape() {
        let parsed = AIPolisher.parseCompletion([
            "type": "message",
            "content": [["type": "text", "text": "Hello "], ["type": "text", "text": "world"]],
            "usage": ["input_tokens": 20, "output_tokens": 5],
        ])
        XCTAssertEqual(parsed?.0, "Hello world")
        XCTAssertEqual(parsed?.1, 20)
        XCTAssertEqual(parsed?.2, 5)
    }

    func testParseCompletionRejectsErrorPayload() {
        XCTAssertNil(AIPolisher.parseCompletion(["type": "error", "error": ["message": "x"]]))
    }

    /// 2026-10-15 用假 Key 打 Gemini OpenAI 兼容接口抓回的原文（HTTP 400，外面包了一层数组）
    func testJSONDictionaryUnwrapsGeminiErrorArray() {
        let wrapped: Any = [["error": ["code": 400, "message": "Please pass a valid API key", "status": "INVALID_ARGUMENT"]]]
        let json = AIPolisher.jsonDictionary(wrapped)
        XCTAssertEqual(AIPolisher.extractAPIErrorMessage(from: json), "API Key 无效，请检查是否复制完整")
    }

    func testFriendlyErrorsForNewProviders() {
        // OpenAI：Key 错（HTTP 401，2026-10-15 实测原文）
        XCTAssertEqual(
            AIPolisher.extractAPIErrorMessage(from: ["error": [
                "message": "Incorrect API key provided: sk-fake. You can find your API key at https://platform.openai.com/account/api-keys.",
                "type": "invalid_request_error", "code": "invalid_api_key"]]),
            "API Key 无效，请检查是否复制完整（invalid_api_key）")
        // Anthropic：Key 错（HTTP 401，2026-10-15 实测原文）
        XCTAssertEqual(
            AIPolisher.extractAPIErrorMessage(from: ["type": "error",
                "error": ["type": "authentication_error", "message": "invalid x-api-key"]]),
            "API Key 无效，请检查是否复制完整")
        // Anthropic：余额不足
        XCTAssertEqual(
            AIPolisher.extractAPIErrorMessage(from: ["type": "error",
                "error": ["type": "invalid_request_error",
                          "message": "Your credit balance is too low to access the Anthropic API."]]),
            "账号欠费或免费额度已用完，请到服务商控制台检查")
        // Gemini：配额用完（code 是数字，不当 tag）
        XCTAssertEqual(
            AIPolisher.extractAPIErrorMessage(from: ["error": ["code": 429, "status": "RESOURCE_EXHAUSTED",
                "message": "You exceeded your current quota, please check your plan and billing details."]]),
            "账号欠费或免费额度已用完，请到服务商控制台检查")
    }
}
